USE u_linker;

-- -------------------------------------------------------------------
-- VISTAS
-- -------------------------------------------------------------------

-- Vista 1: vw_resumen_estudiante (usada por backend P3/P4)
DROP VIEW IF EXISTS vw_resumen_estudiante;

CREATE OR REPLACE VIEW vw_resumen_estudiante AS
SELECT e.id_estudiante, u.nombre, u.email, u.area, e.semestre, u.saldo_tokens,
       COUNT(DISTINCT r.id_reunion) AS total_reuniones_agendadas,
       COUNT(DISTINCT res.id_resena) AS resenas_otorgadas
FROM estudiante e
JOIN usuario u ON e.id_estudiante = u.id_usuario
LEFT JOIN reunion r ON e.id_estudiante = r.id_estudiante
LEFT JOIN resena res ON e.id_estudiante = res.id_estudiante
GROUP BY e.id_estudiante, u.nombre, u.email, u.area, e.semestre, u.saldo_tokens;

-- Vista 2: vw_desempeno_tutores (usada por backend P3/P4)
DROP VIEW IF EXISTS vw_desempeno_tutores;

CREATE OR REPLACE VIEW vw_desempeno_tutores AS
SELECT t.id_tutor, u.nombre AS tutor, u.area, t.calif_promedio,
       COUNT(DISTINCT mat.id_materia) AS materias_aprobadas,
       COUNT(DISTINCT s.id_servicio) AS servicios_activos,
       COUNT(DISTINCT r.id_reunion) AS tutorias_completadas
FROM tutor t
JOIN usuario u ON t.id_tutor = u.id_usuario
LEFT JOIN materia_aprobada_tutor mat ON t.id_tutor = mat.id_tutor
LEFT JOIN servicio s ON t.id_tutor = s.id_tutor
LEFT JOIN reunion r ON t.id_tutor = r.id_tutor AND r.estado = 'Finalizada'
GROUP BY t.id_tutor, u.nombre, u.area, t.calif_promedio;

-- Vista 3: vw_dashboard_general

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

-- Vista 4: vw_materias_demandadas

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

-- Vista 5: vw_perfil_tutor

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
    