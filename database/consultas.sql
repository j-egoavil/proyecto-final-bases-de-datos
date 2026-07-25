-- ===================================================================
-- SCRIPT DE CONSULTAS SQL ANALITICAS - U-Linker
-- Organizado por niveles de complejidad (N1 al N6)
-- ===================================================================

USE u_linker;

-- -------------------------------------------------------------------
-- NIVEL N1: SELECCION Y FILTRADO
-- -------------------------------------------------------------------

-- N1-01: Reuniones finalizadas entre dos fechas
SELECT *
FROM REUNION
WHERE estado = 'Finalizada'
  AND fecha BETWEEN '2025-01-01' AND '2025-06-30';

-- N1-02: Usuarios de Ing. Sistemas con rol Tutor
SELECT id_usuario, nombre, email, area, rol, fecha_creacion
FROM USUARIO
WHERE area LIKE '%Ing. Sistemas%'
  AND rol IN ('Tutor', 'tutor', 'Ambos')
ORDER BY nombre;

-- N1-03: Usuarios baneados en un rango de fechas
SELECT u.id_usuario, u.nombre, u.email, b.motivo, b.fecha_inicio, b.fecha_fin
FROM USUARIO u
INNER JOIN BANEOS b ON u.id_usuario = b.id_usuario
WHERE b.fecha_inicio BETWEEN '2025-01-01' AND '2025-06-30'
ORDER BY b.fecha_inicio DESC;

-- -------------------------------------------------------------------
-- NIVEL N2: JOINS MULTIPLES
-- -------------------------------------------------------------------

-- N2-01: Detalle completo de reuniones (estudiante, tutor, servicio, tokens)
SELECT r.id_reunion, u_est.nombre AS estudiante, u_tut.nombre AS tutor,
       s.nombre AS servicio, s.modalidad, r.fecha, r.tokens_cobrados
FROM reunion r
INNER JOIN estudiante e ON r.id_estudiante = e.id_estudiante
INNER JOIN usuario u_est ON e.id_estudiante = u_est.id_usuario
INNER JOIN tutor t ON r.id_tutor = t.id_tutor
INNER JOIN usuario u_tut ON t.id_tutor = u_tut.id_usuario
INNER JOIN servicio s ON r.id_servicio = s.id_servicio;

-- N2-02: Tutores con materias aprobadas con nota >= 4.5
SELECT u.nombre AS tutor, m.nombre AS materia, m.creditos, mat.nota
FROM materia_aprobada_tutor mat
INNER JOIN tutor t ON mat.id_tutor = t.id_tutor
INNER JOIN usuario u ON t.id_tutor = u.id_usuario
INNER JOIN materia m ON mat.id_materia = m.id_materia
WHERE mat.nota >= 4.5;

-- N2-03: Estudiantes sin reuniones agendadas (LEFT JOIN)
SELECT u.id_usuario, u.nombre, u.email, e.semestre, u.saldo_tokens
FROM estudiante e
JOIN usuario u ON e.id_estudiante = u.id_usuario
LEFT JOIN reunion r ON e.id_estudiante = r.id_estudiante
WHERE r.id_reunion IS NULL;

-- -------------------------------------------------------------------
-- NIVEL N3: AGREGACION Y AGRUPACION
-- -------------------------------------------------------------------

-- N3-01: Promedio de calificaciones por tutor (minimo 2 resenas)
SELECT u.nombre AS tutor, COUNT(r.id_resena) AS total_resenas,
       AVG(r.calificacion) AS promedio_calculado
FROM resena r
JOIN tutor t ON r.id_tutor = t.id_tutor
JOIN usuario u ON t.id_tutor = u.id_usuario
GROUP BY t.id_tutor, u.nombre
HAVING COUNT(r.id_resena) >= 2
ORDER BY promedio_calculado DESC;

-- N3-02: Estudiantes por area y promedio de semestre
SELECT u.area, COUNT(e.id_estudiante) AS total_estudiantes,
       AVG(e.semestre) AS promedio_semestre
FROM estudiante e
JOIN usuario u ON e.id_estudiante = u.id_usuario
GROUP BY u.area
HAVING COUNT(e.id_estudiante) > 0
ORDER BY total_estudiantes DESC;

-- N3-03: Recaudacion total de tokens por modalidad de servicio
SELECT s.modalidad, COUNT(r.id_reunion) AS total_reuniones,
       SUM(r.tokens_cobrados) AS total_tokens
FROM servicio s
JOIN reunion r ON s.id_servicio = r.id_servicio
WHERE r.estado = 'Finalizada'
GROUP BY s.modalidad;

-- -------------------------------------------------------------------
-- NIVEL N4: SUBCONSULTAS
-- -------------------------------------------------------------------

-- N4-01 (CTE): Top 3 tutores con mayores ingresos en tokens
WITH IngresosTutores AS (
    SELECT id_tutor, COUNT(id_reunion) AS total_citas,
           SUM(tokens_cobrados) AS tokens_generados
    FROM reunion
    WHERE estado = 'Finalizada'
    GROUP BY id_tutor
)
SELECT u.nombre AS tutor, it.total_citas, it.tokens_generados
FROM IngresosTutores it
JOIN tutor t ON it.id_tutor = t.id_tutor
JOIN usuario u ON t.id_tutor = u.id_usuario
ORDER BY it.tokens_generados DESC
LIMIT 3;

-- N4-02 (Correlacionada): Estudiantes que gastaron mas que el promedio
SELECT u.id_usuario, u.nombre, SUM(r.tokens_cobrados) AS gasto_tokens
FROM estudiante e
JOIN usuario u ON e.id_estudiante = u.id_usuario
JOIN reunion r ON e.id_estudiante = r.id_estudiante
GROUP BY e.id_estudiante, u.id_usuario, u.nombre
HAVING SUM(r.tokens_cobrados) > (
    SELECT AVG(sub.total_tokens)
    FROM (
        SELECT SUM(r2.tokens_cobrados) AS total_tokens
        FROM reunion r2
        GROUP BY r2.id_estudiante
    ) sub
);

-- N4-03 (EXISTS): Usuarios sin sanciones en baneos
SELECT u.id_usuario, u.nombre, u.email, u.rol
FROM usuario u
WHERE NOT EXISTS (
    SELECT 1 FROM baneos b WHERE b.id_usuario = u.id_usuario
);

-- -------------------------------------------------------------------
-- NIVEL N5: FUNCIONES DE VENTANA (ANALITICA)
-- -------------------------------------------------------------------

-- N5-01: Ranking de tutores por area segun calificacion
SELECT u.area, u.nombre AS tutor, t.calif_promedio,
       DENSE_RANK() OVER (PARTITION BY u.area ORDER BY t.calif_promedio DESC) AS posicion_area
FROM tutor t
JOIN usuario u ON t.id_tutor = u.id_usuario;

-- N5-02: Evolucion historica del flujo de tokens
SELECT DATE(fecha) AS fecha,
       SUM(cantidad) AS balance_diario,
       SUM(SUM(cantidad)) OVER (ORDER BY DATE(fecha)) AS acumulado_historico
FROM movimiento_token
GROUP BY DATE(fecha)
ORDER BY fecha ASC;

-- -------------------------------------------------------------------
-- NIVEL N6: VISTAS
-- -------------------------------------------------------------------

-- N6-01: Vista resumen de estudiante (saldo, actividad, resenas)
CREATE OR REPLACE VIEW vw_resumen_estudiante AS
SELECT e.id_estudiante, u.nombre, u.email, u.area, e.semestre, u.saldo_tokens,
       COUNT(DISTINCT r.id_reunion) AS total_reuniones_agendadas,
       COUNT(DISTINCT res.id_resena) AS resenas_otorgadas
FROM estudiante e
JOIN usuario u ON e.id_estudiante = u.id_usuario
LEFT JOIN reunion r ON e.id_estudiante = r.id_estudiante
LEFT JOIN resena res ON e.id_estudiante = res.id_estudiante
GROUP BY e.id_estudiante, u.nombre, u.email, u.area, e.semestre, u.saldo_tokens;

-- N6-02: Vista de desempeno de tutores
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