LUSE u_linker;

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
-- Procedimiento 3

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_tutorias_pendientes $$

CREATE PROCEDURE sp_tutorias_pendientes(
    IN p_id_usuario INT
)
BEGIN

    SELECT r.id_reunion,ue.nombre AS estudiante,
        ut.nombre AS tutor, s.nombre AS servicio,
        m.nombre AS materia,r.fecha,
        r.hora_inicio, r.hora_fin, r.tema, r.estado,r.tokens_cobrados
	FROM reunion r
	INNER JOIN usuario ue
        ON r.id_estudiante = ue.id_usuario
    INNER JOIN usuario ut
        ON r.id_tutor = ut.id_usuario
    INNER JOIN servicio s
        ON r.id_servicio = s.id_servicio
    INNER JOIN materia m
        ON s.id_materia = m.id_materia
    WHERE
        (r.id_estudiante = p_id_usuario
        OR
        r.id_tutor = p_id_usuario)
        AND r.estado='Agendada'
    ORDER BY
        r.fecha ASC,
        r.hora_inicio ASC;
END $$

DELIMITER ;
-- Procedimiento 4 

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_tutores_disponibles $$

CREATE PROCEDURE sp_tutores_disponibles(
    IN p_id_materia INT
)
BEGIN

    SELECT t.id_tutor, u.nombre, u.email,
        u.area,
        mat.nota,
        t.calif_promedio
    FROM materia_aprobada_tutor mat
    INNER JOIN tutor t
        ON mat.id_tutor = t.id_tutor
    INNER JOIN usuario u
        ON t.id_tutor = u.id_usuario
    WHERE mat.id_materia = p_id_materia
      AND mat.nota >= 4.0
      AND fn_es_usuario_baneado(u.id_usuario, CURDATE()) = FALSE
    ORDER BY
        t.calif_promedio DESC,
        mat.nota DESC;

END $$

DELIMITER ;

-- Procedimiento 5

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_ranking_tutores $$

CREATE PROCEDURE sp_ranking_tutores()
BEGIN

    SELECT t.id_tutor,u.nombre,u.area,
        t.calif_promedio,
        COUNT(r.id_reunion) AS total_finalizadas
    FROM tutor t
    INNER JOIN usuario u
        ON t.id_tutor = u.id_usuario
    LEFT JOIN reunion r
        ON t.id_tutor = r.id_tutor
        AND r.estado = 'Finalizada'
    GROUP BY t.id_tutor, u.nombre, u.area,t.calif_promedio
    ORDER BY
        t.calif_promedio DESC,
        total_finalizadas DESC;

END $$

DELIMITER ;
-- Procedimiento 6: sp_materias_con_prerrequisitos

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_materias_con_prerrequisitos $$
CREATE PROCEDURE sp_materias_con_prerrequisitos()
BEGIN
	WITH RECURSIVE cadena_prerrequisitos AS (

        SELECT id_materia,nombre,id_prerequisito,1 AS nivel
        FROM materia
        WHERE id_prerequisito IS NULL
		UNION ALL
        SELECT m.id_materia,m.nombre, m.id_prerequisito, cp.nivel + 1
		FROM materia m
        INNER JOIN cadena_prerrequisitos cp
            ON m.id_prerequisito = cp.id_materia

    )

    SELECT *
    FROM cadena_prerrequisitos
    ORDER BY nivel, nombre;

END $$

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
