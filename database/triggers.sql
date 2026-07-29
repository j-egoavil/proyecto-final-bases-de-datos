-- -------------------------------------------------------------------
--  TRIGGERS
-- -------------------------------------------------------------------

USE u_linker;
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

-- Trigger 3 : Validamos que la materia solo se pueda ingresar con nota suficiente
USE u_linker;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_validar_materia_tutor $$
CREATE TRIGGER trg_validar_materia_tutor
BEFORE INSERT ON materia_aprobada_tutor
FOR EACH ROW
BEGIN
    IF new.nota < 4.0 THEN 
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se puede ser tutor de una materia si la nota es menor a 4.0';
    END IF;    
    
END$$
DELIMITER ;

-- Trigger 4 : Valida que el tutor si tenga inscrita esa materia como aprobada y apta 
USE u_linker;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_validar_servicio $$

CREATE TRIGGER trg_validar_servicio
BEFORE INSERT ON servicio
FOR EACH ROW
BEGIN
    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM materia_aprobada_tutor
    WHERE id_tutor = NEW.id_tutor -- cuenta si coinciden las materias y los tutores 
      AND id_materia = NEW.id_materia;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tutor no tiene registrada esa materia como aprobada.';
    END IF;
END $$

DELIMITER ;

-- Trigger 5: trg_validar_baneo_reunion (RN-05 a nivel de tabla, redundante con pr_agendar_tutoria)
USE u_linker;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_validar_baneo_reunion$$

CREATE TRIGGER trg_validar_baneo_reunion
BEFORE INSERT ON reunion
FOR EACH ROW
BEGIN
    IF u_linker.fn_es_usuario_baneado(NEW.id_estudiante, NEW.fecha) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estudiante tiene una sancion activa en la fecha seleccionada.';
    END IF;

    IF u_linker.fn_es_usuario_baneado(NEW.id_tutor, NEW.fecha) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tutor tiene una sancion activa en la fecha seleccionada.';
    END IF;
END$$

DELIMITER ;

-- Trigger 6: trg_validar_baneo_servicio (RN-05 a nivel de tabla, mismo caso de redundancia)
USE u_linker;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_validar_baneo_servicio$$

CREATE TRIGGER trg_validar_baneo_servicio
BEFORE INSERT ON servicio
FOR EACH ROW
BEGIN
    IF u_linker.fn_es_usuario_baneado(NEW.id_tutor, CURDATE()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El tutor tiene una sancion activa y no puede publicar servicios.';
    END IF;
END$$

DELIMITER ;

-- Trigger 7: trg_control_saldo (RN-03 a nivel de tabla, redundante con pr_agendar_tutoria)
USE u_linker;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_control_saldo$$

CREATE TRIGGER trg_control_saldo
BEFORE INSERT ON reunion
FOR EACH ROW
BEGIN
    IF NOT u_linker.fn_verificar_saldo_estudiante(NEW.id_estudiante, NEW.id_servicio) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estudiante no tiene suficientes tokens para este servicio.';
    END IF;
END$$

DELIMITER ;

-- Trigger 8
USE u_linker;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_saldo_tokens$$

CREATE PROCEDURE sp_saldo_tokens(
    IN p_usuario_id INT,
    OUT p_saldo_usuario INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_saldo_usuario = NULL;
    END;

    SELECT IFNULL(SUM(cantidad), 0)
    INTO p_saldo_usuario
    FROM movimiento_token
    WHERE id_usuario = p_usuario_id;

END$$

DELIMITER ;
