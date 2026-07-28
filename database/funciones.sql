USE u_linker;

-- -------------------------------------------------------------------
--  FUNCIONES ALMACENADAS
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
