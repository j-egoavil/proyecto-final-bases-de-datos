-- ===================================================================
-- SCRIPT PL/SQL - Proyecto: U-Linker
-- Funciones, Procedimientos y Triggers
-- ===================================================================

USE u_linker;

-- -------------------------------------------------------------------
-- 1. FUNCIONES ALMACENADAS
-- -------------------------------------------------------------------

-- Funcion 1: fn_verificar_saldo_estudiante
DELIMITER $$

DROP FUNCTION IF EXISTS u_linker.fn_verificar_saldo_estudiante$$

CREATE FUNCTION u_linker.fn_verificar_saldo_estudiante(
    p_id_estudiante INT,
    p_id_servicio INT
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_tokens_servicio INT DEFAULT 0;
    DECLARE v_tokens_disponibles_user INT DEFAULT 0;

    SELECT precio_tokens INTO v_tokens_servicio
    FROM u_linker.servicio
    WHERE id_servicio = p_id_servicio;

    SELECT saldo_tokens INTO v_tokens_disponibles_user
    FROM u_linker.usuario
    WHERE id_usuario = p_id_estudiante;

    IF v_tokens_disponibles_user >= v_tokens_servicio THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

DELIMITER ;

-- Funcion 2: fn_es_usuario_baneado
DELIMITER $$

DROP FUNCTION IF EXISTS u_linker.fn_es_usuario_baneado$$

CREATE FUNCTION u_linker.fn_es_usuario_baneado(
    p_id_usuario INT,
    p_fecha DATE
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_esta_baneado INT DEFAULT 0;

    SELECT EXISTS(
        SELECT 1
        FROM u_linker.baneos
        WHERE id_usuario = p_id_usuario
          AND p_fecha BETWEEN fecha_inicio AND fecha_fin
    ) INTO v_esta_baneado;

    IF v_esta_baneado = 1 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

DELIMITER ;

-- -------------------------------------------------------------------
-- 2. PROCEDIMIENTOS ALMACENADOS
-- -------------------------------------------------------------------

-- Procedimiento 1: pr_agendar_tutoria
DELIMITER $$

DROP PROCEDURE IF EXISTS u_linker.pr_agendar_tutoria$$

CREATE PROCEDURE u_linker.pr_agendar_tutoria(
    IN p_id_estudiante INT,
    IN p_id_tutor INT,
    IN p_id_servicio INT,
    IN p_fecha DATE,
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME
)
BEGIN
    DECLARE v_precio INT DEFAULT 0;
    DECLARE v_tiene_saldo BOOLEAN DEFAULT FALSE;

    -- Validacion 1: Baneo
    IF u_linker.fn_es_usuario_baneado(p_id_estudiante, p_fecha) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El estudiante tiene una sancion activa en la fecha seleccionada.';
    END IF;

    -- Validacion 2: Saldo
    SET v_tiene_saldo = u_linker.fn_verificar_saldo_estudiante(p_id_estudiante, p_id_servicio);

    IF NOT v_tiene_saldo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El estudiante no tiene suficientes tokens para este servicio.';
    END IF;

    -- Obtener precio
    SELECT precio_tokens INTO v_precio
    FROM u_linker.servicio
    WHERE id_servicio = p_id_servicio;

    -- Registrar reunion
    INSERT INTO u_linker.reunion (
        id_estudiante, id_tutor, id_servicio,
        fecha, hora_inicio, hora_fin,
        estado, tokens_cobrados
    ) VALUES (
        p_id_estudiante, p_id_tutor, p_id_servicio,
        p_fecha, p_hora_inicio, p_hora_fin,
        'Agendada', v_precio
    );

    -- Descontar tokens al estudiante
    UPDATE u_linker.usuario
    SET saldo_tokens = saldo_tokens - v_precio
    WHERE id_usuario = p_id_estudiante;

    -- Sumar tokens al tutor
    UPDATE u_linker.usuario
    SET saldo_tokens = saldo_tokens + v_precio
    WHERE id_usuario = p_id_tutor;

    -- Auditoria
    INSERT INTO u_linker.movimiento_token (id_usuario, cantidad, fecha)
    VALUES (p_id_estudiante, -v_precio, NOW());

    INSERT INTO u_linker.movimiento_token (id_usuario, cantidad, fecha)
    VALUES (p_id_tutor, v_precio, NOW());
END$$

DELIMITER ;

-- Procedimiento 2: pr_asignar_datos_usuario
DELIMITER $$

DROP PROCEDURE IF EXISTS u_linker.pr_asignar_datos_usuario$$

CREATE PROCEDURE u_linker.pr_asignar_datos_usuario(
    IN p_nombre VARCHAR(150),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_area VARCHAR(100),
    IN p_semestre INT
)
BEGIN
    DECLARE v_id_nuevo INT;

    START TRANSACTION;
        INSERT INTO u_linker.usuario (nombre, email, password, area, rol, saldo_tokens, fecha_creacion)
        VALUES (p_nombre, p_email, p_password, p_area, 'Estudiante', 15, CURRENT_DATE);

        SET v_id_nuevo = LAST_INSERT_ID();

        INSERT INTO u_linker.estudiante (id_estudiante, semestre)
        VALUES (v_id_nuevo, p_semestre);

        INSERT INTO u_linker.movimiento_token (id_usuario, cantidad, fecha)
        VALUES (v_id_nuevo, 15, NOW());
    COMMIT;
END$$

DELIMITER ;

-- -------------------------------------------------------------------
-- 3. TRIGGERS
-- -------------------------------------------------------------------

-- Trigger 1: Trg_actualizar_calificacion_tutor
DELIMITER $$

DROP TRIGGER IF EXISTS u_linker.Trg_actualizar_calificacion_tutor$$

CREATE TRIGGER u_linker.Trg_actualizar_calificacion_tutor
AFTER INSERT ON u_linker.resena
FOR EACH ROW
BEGIN
    DECLARE v_promedio FLOAT;

    SELECT AVG(calificacion) INTO v_promedio
    FROM u_linker.resena
    WHERE id_tutor = NEW.id_tutor;

    UPDATE u_linker.tutor
    SET calif_promedio = IFNULL(v_promedio, 0.0)
    WHERE id_tutor = NEW.id_tutor;
END$$

DELIMITER ;

-- Trigger 2: Trg_reserva_cancelada (reembolso si se cancela con >24h de anticipacion)
DELIMITER $$

DROP TRIGGER IF EXISTS u_linker.Trg_reserva_cancelada$$

CREATE TRIGGER u_linker.Trg_reserva_cancelada
AFTER UPDATE ON u_linker.reunion
FOR EACH ROW
BEGIN
    DECLARE v_horas_diferencia INT;
    DECLARE v_fecha_inicio_reunion DATETIME;

    IF OLD.estado <> 'Cancelada' AND NEW.estado = 'Cancelada' THEN
        SET v_fecha_inicio_reunion = CAST(CONCAT(NEW.fecha, ' ', NEW.hora_inicio) AS DATETIME);
        SET v_horas_diferencia = TIMESTAMPDIFF(HOUR, NOW(), v_fecha_inicio_reunion);

        IF v_horas_diferencia >= 24 THEN
            -- Reembolso al estudiante
            UPDATE u_linker.usuario
            SET saldo_tokens = saldo_tokens + NEW.tokens_cobrados
            WHERE id_usuario = NEW.id_estudiante;

            UPDATE u_linker.usuario
            SET saldo_tokens = saldo_tokens - NEW.tokens_cobrados
            WHERE id_usuario = NEW.id_tutor;

            INSERT INTO u_linker.movimiento_token (id_usuario, cantidad, fecha)
            VALUES (NEW.id_estudiante, NEW.tokens_cobrados, NOW());
        END IF;
    END IF;
END$$

DELIMITER ;

-- -------------------------------------------------------------------
-- BLOQUES DE COMPROBACION
-- -------------------------------------------------------------------

-- Recalcular calif_promedio reales (los valores precargados no coinciden)
UPDATE tutor t
SET calif_promedio = (
    SELECT IFNULL(AVG(calificacion), 0.0)
    FROM resena r
    WHERE r.id_tutor = t.id_tutor
);