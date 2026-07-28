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


