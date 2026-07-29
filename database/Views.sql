USE u_linker;

-- -------------------------------------------------------------------
-- VISTAS
-- -------------------------------------------------------------------

-- Vista 1: vw_dashboard_general

DROP VIEW IF EXISTS vw_dashboard_general;

CREATE OR REPLACE VIEW vw_dashboard_general AS

SELECT
    u.area,
    COUNT(DISTINCT CASE WHEN u.rol = 'Estudiante' THEN u.id_usuario END) AS total_estudiantes,
    COUNT(DISTINCT CASE WHEN u.rol = 'Tutor' THEN u.id_usuario END) AS total_tutores,
    COUNT(DISTINCT r.id_reunion) AS total_reuniones,
    SUM(CASE WHEN r.estado = 'Finalizada' THEN r.tokens_cobrados ELSE 0 END) AS tokens_movidos,
    AVG(t.calif_promedio) AS calif_promedio_area
FROM usuario u
LEFT JOIN reunion r
    ON u.id_usuario = r.id_estudiante
LEFT JOIN tutor t
    ON u.id_usuario = t.id_tutor
GROUP BY
    u.area;

-- -------------------------------------------------------------------

-- Vista 2: vw_materias_demandadas

DROP VIEW IF EXISTS vw_materias_demandadas;

CREATE OR REPLACE VIEW vw_materias_demandadas AS

SELECT
    m.id_materia,
    m.nombre AS materia,
    COUNT(r.id_reunion) AS total_reuniones,
    COUNT(DISTINCT s.id_tutor) AS tutores_ofertando,
    SUM(r.tokens_cobrados) AS tokens_generados
FROM materia m
INNER JOIN servicio s
    ON m.id_materia = s.id_materia
INNER JOIN reunion r
    ON s.id_servicio = r.id_servicio
WHERE r.estado = 'Finalizada'
GROUP BY
    m.id_materia,
    m.nombre
ORDER BY
    total_reuniones DESC;

-- -------------------------------------------------------------------

-- Vista 3: vw_perfil_tutor

DROP VIEW IF EXISTS vw_perfil_tutor;

CREATE OR REPLACE VIEW vw_perfil_tutor AS

SELECT
    t.id_tutor,
    u.nombre,
    u.area,
    t.calif_promedio,
    m.id_materia,
    m.nombre AS materia
FROM tutor t
INNER JOIN usuario u
    ON t.id_tutor = u.id_usuario
INNER JOIN materia_aprobada_tutor mat
    ON t.id_tutor = mat.id_tutor
INNER JOIN materia m
    ON mat.id_materia = m.id_materia;
    