pgit log -1 --pretty=fullKLUSE u_linker;

-- -------------------------------------------------------------------
-- PROCEDIMIENTOS ALMACENADOS
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
-- BLOQUES DE COMPROBACION
-- -------------------------------------------------------------------

-- Recalcular calif_promedio reales (los valores precargados no coinciden)
UPDATE tutor t
SET calif_promedio = (
    SELECT IFNULL(AVG(calificacion), 0.0)
    FROM resena r
    WHERE r.id_tutor = t.id_tutor
);