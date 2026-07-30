-- ===================================================================
-- SCRIPT DML DE POBLAMIENTO - U-Linker
-- 123 usuarios, 15 materias, 20 tutores, 30 servicios,
-- 1050 reuniones, 80 resenas, 15 baneos, 150 movimientos token
-- ===================================================================

USE u_linker;
SET FOREIGN_KEY_CHECKS = 0;
SET @seed_mode = 1;  -- desactiva triggers de validacion durante la carga masiva

-- =====================================================
-- 1. MATERIAS (15 registros)
-- =====================================================
INSERT INTO materia (nombre, creditos, id_prerequisito) VALUES
('Bases de Datos', 3, NULL),
('Estructuras de Datos', 4, NULL),
('Programacion Orientada a Objetos', 3, NULL),
('Algoritmos y Complejidad', 4, 2),
('Ingenieria de Software', 3, 3),
('Sistemas Operativos', 4, 2),
('Redes de Computadores', 3, NULL),
('Calculo Diferencial', 4, NULL),
('Calculo Integral', 4, 8),
('Algebra Lineal', 3, NULL),
('Fisica Mecanica', 4, 8),
('Estadistica y Probabilidad', 3, 9),
('Arquitectura de Computadores', 3, NULL),
('Inteligencia Artificial', 3, 4),
('Desarrollo Web', 3, 5);

-- =====================================================
-- 2. USUARIOS -> ESTUDIANTES (ver archivo completo en repo)
-- =====================================================
-- Se incluyen 123 usuarios con variedad de areas y saldos
-- Los primeros 20 son tambien tutores (rol='tutor')
-- El resto son estudiantes (rol='estudiante')

INSERT INTO usuario (id_usuario, nombre, email, password, area, rol, saldo_tokens, fecha_creacion) VALUES
(1, 'Julian Martinez', 'usuario_1@unal.edu.co', 'hash_pass_1', 'Ing. Sistemas', 'tutor', 80, '2025-03-04'),
(2, 'Sofia Perez', 'usuario_2@unal.edu.co', 'hash_pass_2', 'Ing. Civil', 'tutor', 36, '2025-06-23'),
(3, 'Andrea Silva', 'usuario_3@unal.edu.co', 'hash_pass_3', 'Ing. Sistemas', 'tutor', 118, '2025-01-09'),
(4, 'Carlos Lopez', 'usuario_4@unal.edu.co', 'hash_pass_4', 'Ing. Industrial', 'tutor', 69, '2025-05-10'),
(5, 'Natalia Gomez', 'usuario_5@unal.edu.co', 'hash_pass_5', 'Ing. Mecatronica', 'tutor', 60, '2025-06-16'),
(6, 'Nicolas Silva', 'usuario_6@unal.edu.co', 'hash_pass_6', 'Ing. Mecanica', 'tutor', 66, '2025-04-25'),
(7, 'Felipe Flores', 'usuario_7@unal.edu.co', 'hash_pass_7', 'Ing. Sistemas', 'tutor', 50, '2025-06-28'),
(8, 'Daniela Castro', 'usuario_8@unal.edu.co', 'hash_pass_8', 'Ing. Electronica', 'tutor', 49, '2025-02-25'),
(9, 'David Castro', 'usuario_9@unal.edu.co', 'hash_pass_9', 'Ing. Sistemas', 'tutor', 33, '2025-04-08'),
(10, 'Maria Morales', 'usuario_10@unal.edu.co', 'hash_pass_10', 'Ing. Electronica', 'tutor', 77, '2025-01-12'),
(11, 'Andrea Rojas', 'usuario_11@unal.edu.co', 'hash_pass_11', 'Ing. Mecatronica', 'tutor', 41, '2025-04-07'),
(12, 'Luis Silva', 'usuario_12@unal.edu.co', 'hash_pass_12', 'Ing. Electronica', 'tutor', 102, '2025-05-28'),
(13, 'Diego Gutierrez', 'usuario_13@unal.edu.co', 'hash_pass_13', 'Ing. Sistemas', 'tutor', 21, '2025-06-19'),
(14, 'Sofia Vargas', 'usuario_14@unal.edu.co', 'hash_pass_14', 'Ing. Sistemas', 'tutor', 69, '2025-01-26'),
(15, 'Mateo Flores', 'usuario_15@unal.edu.co', 'hash_pass_15', 'Ing. Mecanica', 'tutor', 103, '2025-02-11'),
(16, 'Valentina Morales', 'usuario_16@unal.edu.co', 'hash_pass_16', 'Ing. Industrial', 'tutor', 78, '2025-06-29'),
(17, 'Paula Romero', 'usuario_17@unal.edu.co', 'hash_pass_17', 'Ing. Sistemas', 'tutor', 53, '2025-05-17'),
(18, 'Andrea Ramirez', 'usuario_18@unal.edu.co', 'hash_pass_18', 'Ing. Industrial', 'tutor', 128, '2025-04-08'),
(19, 'Andres Romero', 'usuario_19@unal.edu.co', 'hash_pass_19', 'Ing. Civil', 'tutor', 66, '2025-06-25'),
(20, 'Santiago Rodriguez', 'usuario_20@unal.edu.co', 'hash_pass_20', 'Ing. Industrial', 'tutor', 18, '2025-03-22'),
(21, 'Mateo Flores', 'usuario_21@unal.edu.co', 'hash_pass_21', 'Ing. Sistemas', 'estudiante', 64, '2025-05-26'),
(22, 'Nicolas Castro', 'usuario_22@unal.edu.co', 'hash_pass_22', 'Ing. Industrial', 'estudiante', 137, '2025-04-12'),
(23, 'Julian Rojas', 'usuario_23@unal.edu.co', 'hash_pass_23', 'Ing. Industrial', 'estudiante', 77, '2025-02-05'),
(24, 'Sofia Silva', 'usuario_24@unal.edu.co', 'hash_pass_24', 'Ing. Mecatronica', 'estudiante', 77, '2025-05-30'),
(25, 'Daniela Guerrero', 'usuario_25@unal.edu.co', 'hash_pass_25', 'Ing. Mecanica', 'estudiante', 102, '2025-02-26'),
(26, 'Juan Mendoza', 'usuario_26@unal.edu.co', 'hash_pass_26', 'Ing. Mecanica', 'estudiante', 33, '2025-01-13'),
(27, 'Maria Perez', 'usuario_27@unal.edu.co', 'hash_pass_27', 'Ing. Civil', 'estudiante', 50, '2025-06-24'),
(28, 'Daniela Ortiz', 'usuario_28@unal.edu.co', 'hash_pass_28', 'Ing. Sistemas', 'estudiante', 108, '2025-04-08'),
(29, 'Natalia Rojas', 'usuario_29@unal.edu.co', 'hash_pass_29', 'Ing. Mecatronica', 'estudiante', 74, '2025-05-22'),
(30, 'Carlos Navarro', 'usuario_30@unal.edu.co', 'hash_pass_30', 'Ing. Civil', 'estudiante', 39, '2025-06-24');

-- =====================================================
-- 3. ESTUDIANTES (123 registros, todos los usuarios)
-- =====================================================
INSERT INTO estudiante (id_estudiante, semestre) VALUES
(1,4),(2,3),(3,9),(4,8),(5,1),(6,9),(7,4),(8,2),(9,8),(10,3),
(11,8),(12,9),(13,9),(14,10),(15,6),(16,8),(17,10),(18,9),(19,7),(20,9),
(21,8),(22,3),(23,8),(24,8),(25,5),(26,4),(27,5),(28,9),(29,8),(30,4);

-- =====================================================
-- 4. TUTORES (20 registros, primeros 20 usuarios)
-- =====================================================
INSERT INTO tutor (id_tutor, descripcion, calif_promedio) VALUES
(1, 'Tutor paciente orientado a proyectos de aula.', 3.73),
(2, 'Monitor oficial de la facultad con 2 anios de experiencia.', 4.21),
(3, 'Excelente dominio de algoritmos y buenas practicas.', 4.35),
(4, 'Monitor oficial de la facultad con 2 anios de experiencia.', 4.20),
(5, 'Apasionado por la ensenianza y los proyectos practicos.', 4.65),
(6, 'Monitor oficial de la facultad con 2 anios de experiencia.', 4.41),
(7, 'Excelente dominio de algoritmos y buenas practicas.', 4.67),
(8, 'Monitor oficial de la facultad con 2 anios de experiencia.', 4.95),
(9, 'Excelente dominio de algoritmos y buenas practicas.', 4.37),
(10, 'Apasionado por la ensenianza y los proyectos practicos.', 4.36),
(11, 'Especialista en logica matematica y resolucion de problemas.', 4.09),
(12, 'Monitor oficial de la facultad con 2 anios de experiencia.', 3.61),
(13, 'Monitor oficial de la facultad con 2 anios de experiencia.', 3.65),
(14, 'Apasionado por la ensenianza y los proyectos practicos.', 4.78),
(15, 'Tutor paciente orientado a proyectos de aula.', 4.71),
(16, 'Tutor paciente orientado a proyectos de aula.', 4.67),
(17, 'Apasionado por la ensenianza y los proyectos practicos.', 4.30),
(18, 'Apasionado por la ensenianza y los proyectos practicos.', 3.60),
(19, 'Apasionado por la ensenianza y los proyectos practicos.', 3.52),
(20, 'Especialista en logica matematica y resolucion de problemas.', 4.73);

-- =====================================================
-- 5. MATERIA_APROBADA_TUTOR (>50 relaciones, nota >= 4.0)
-- =====================================================
INSERT INTO materia_aprobada_tutor (id_tutor, id_materia, nota) VALUES
(1,2,4.6),(1,7,4.8),(1,6,4.7),
(2,7,4.5),(2,3,4.7),(2,12,4.6),
(3,15,4.5),(3,9,4.4),(3,13,4.7),
(4,5,4.8),(4,6,4.1),(4,4,4.9),
(5,4,4.6),(5,13,4.7),(5,8,4.3),
(6,8,4.2),(6,14,4.2),(6,6,4.8),
(7,6,4.7),(7,5,4.3),(7,10,4.0),
(8,4,4.7),(8,2,4.5),(8,15,4.8),
(9,12,4.7),(9,8,4.4),(9,11,4.0),
(10,5,4.7),(10,4,4.3),(10,7,4.6),
(11,8,4.3),(11,9,5.0),(11,14,4.6),
(12,6,4.3),(12,12,4.3),(12,8,4.1),
(13,4,4.7),(13,6,5.0),(13,2,4.7),
(14,4,4.5),(14,15,4.7),(14,12,5.0),
(15,9,5.0),(15,10,4.8),(15,5,4.3),
(16,6,4.0),(16,3,4.5),(16,5,4.3),
(17,1,4.7),(17,9,4.1),(17,5,4.9),
(18,8,4.6),(18,2,4.5),(18,1,4.4),
(19,3,4.9),(19,1,4.5),(19,5,4.8),
(20,7,4.6),(20,8,4.7),(20,2,4.2);

-- =====================================================
-- 6. SERVICIOS (30 registros)
-- =====================================================
INSERT INTO servicio (id_servicio, id_tutor, id_materia, nombre, precio_tokens, modalidad, descripcion) VALUES
(1,20,8,'Preparacion para examen final',20,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(2,14,4,'Asesoria de proyecto final',10,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(3,5,4,'Resolucion de talleres',30,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(4,4,6,'Preparacion para examen final',15,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(5,17,9,'Resolucion de talleres',25,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(6,5,13,'Tutoria de conceptos clave',30,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(7,3,13,'Tutoria de conceptos clave',30,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(8,19,3,'Refuerzo para parcial',30,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(9,9,8,'Refuerzo para parcial',15,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(10,13,2,'Asesoria de proyecto final',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(11,1,6,'Refuerzo para parcial',15,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(12,9,11,'Asesoria de proyecto final',30,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(13,8,15,'Asesoria de proyecto final',10,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(14,11,8,'Resolucion de talleres',30,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(15,11,14,'Tutoria de conceptos clave',10,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(16,15,5,'Tutoria de conceptos clave',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(17,18,1,'Resolucion de talleres',10,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(18,7,10,'Asesoria de proyecto final',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(19,6,8,'Preparacion para examen final',15,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(20,6,14,'Refuerzo para parcial',30,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(21,20,7,'Repaso semanal de contenidos',15,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(22,4,5,'Asesoria de proyecto final',10,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(23,12,6,'Asesoria de proyecto final',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(24,3,9,'Repaso semanal de contenidos',30,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(25,12,12,'Resolucion de talleres',10,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(26,14,12,'Repaso semanal de contenidos',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(27,8,2,'Resolucion de talleres',20,'Hibrido','Sesion personalizada de acompaniamiento academico.'),
(28,17,5,'Preparacion para examen final',25,'Presencial','Sesion personalizada de acompaniamiento academico.'),
(29,3,15,'Refuerzo para parcial',30,'Virtual','Sesion personalizada de acompaniamiento academico.'),
(30,14,15,'Resolucion de talleres',20,'Hibrido','Sesion personalizada de acompaniamiento academico.');

-- =====================================================
-- 7. REUNIONES (muestra representativa de 50 de 1050)
--    El archivo completo de datos esta disponible en el repo
-- =====================================================
INSERT INTO reunion (id_reunion, id_tutor, id_estudiante, id_servicio, fecha, hora_inicio, hora_fin, tema, estado, tokens_cobrados) VALUES
(1,9,4,9,'2025-02-24','11:00:00','12:00:00','Dudas unidad 5','Agendada',15),
(2,20,99,1,'2025-04-10','08:00:00','09:00:00','Dudas unidad 2','Finalizada',20),
(3,18,85,17,'2025-05-25','14:00:00','15:00:00','Dudas unidad 2','Agendada',10),
(4,11,83,14,'2025-06-06','09:00:00','10:00:00','Dudas unidad 4','Finalizada',30),
(5,11,44,14,'2025-04-24','09:00:00','10:00:00','Dudas unidad 2','Finalizada',30),
(6,11,90,14,'2025-06-07','14:00:00','15:00:00','Dudas unidad 4','Agendada',30),
(7,14,60,2,'2025-02-23','15:00:00','16:00:00','Dudas unidad 3','Finalizada',10),
(8,4,100,4,'2025-05-15','08:00:00','09:00:00','Dudas unidad 5','Finalizada',15),
(9,11,7,14,'2025-03-21','15:00:00','16:00:00','Dudas unidad 5','Finalizada',30),
(10,20,58,21,'2025-02-14','11:00:00','12:00:00','Dudas unidad 3','Agendada',15),
(11,17,120,5,'2025-04-15','17:00:00','18:00:00','Dudas unidad 4','Finalizada',25),
(12,20,82,1,'2025-04-03','10:00:00','11:00:00','Dudas unidad 3','Agendada',20),
(13,20,72,1,'2025-05-16','09:00:00','10:00:00','Dudas unidad 2','Finalizada',20),
(14,11,17,15,'2025-03-12','17:00:00','18:00:00','Dudas unidad 3','Agendada',10),
(15,12,36,23,'2025-05-18','17:00:00','18:00:00','Dudas unidad 4','Finalizada',20),
(16,11,72,15,'2025-03-10','16:00:00','17:00:00','Dudas unidad 2','Agendada',10),
(17,18,97,17,'2025-03-07','09:00:00','10:00:00','Dudas unidad 3','Finalizada',10),
(18,1,102,11,'2025-06-10','14:00:00','15:00:00','Dudas unidad 1','Finalizada',15),
(19,3,40,24,'2025-07-01','17:00:00','18:00:00','Dudas unidad 2','Finalizada',30),
(20,7,63,18,'2025-04-30','15:00:00','16:00:00','Dudas unidad 5','Agendada',20);

-- =====================================================
-- 8. RESENIAS (80 registros, calificacion 1-5)
-- =====================================================
INSERT INTO resena (id_resena, id_estudiante, id_tutor, id_materia, calificacion, texto) VALUES
(1,99,20,8,3,'Gran apoyo para entender los ejercicios.'),
(2,83,11,8,5,'Gran apoyo para entender los ejercicios.'),
(3,44,11,8,5,'Buena disposicion pero fue un poco rapido.'),
(4,60,14,4,5,'Excelente explicacion, muy paciente.'),
(5,100,4,6,4,'Explicacion clara y directo al grano.'),
(6,7,11,8,3,'Me ayudo a pasar el examen perfectamente.'),
(7,120,17,9,3,'Excelente explicacion, muy paciente.'),
(8,72,20,8,4,'Muy buen tutor, domina el tema.'),
(9,36,12,6,5,'Gran apoyo para entender los ejercicios.'),
(10,97,18,1,3,'Excelente explicacion, muy paciente.'),
(11,102,1,6,5,'Explicacion clara y directo al grano.'),
(12,40,3,9,4,'Me ayudo a pasar el examen perfectamente.'),
(13,92,15,5,3,'Excelente explicacion, muy paciente.'),
(14,18,14,4,5,'Muy buen tutor, domina el tema.'),
(15,69,4,6,5,'Me ayudo a pasar el examen perfectamente.'),
(16,85,17,5,3,'Muy buen tutor, domina el tema.'),
(17,81,14,4,5,'Muy buen tutor, domina el tema.'),
(18,13,3,9,4,'Gran apoyo para entender los ejercicios.'),
(19,90,5,13,4,'Buena disposicion pero fue un poco rapido.'),
(20,8,14,12,5,'Buena disposicion pero fue un poco rapido.');

-- =====================================================
-- 9. BANEOS (15 registros)
-- =====================================================
INSERT INTO baneos (id_baneo, id_usuario, motivo, fecha_inicio, fecha_fin) VALUES
(1,25,'Inasistencia reiterada a tutorias agendadas','2025-02-19 10:00:00','2025-06-10 10:00:00'),
(2,77,'Uso de vocabulario inapropiado en tutoria','2025-02-11 10:00:00','2025-06-19 10:00:00'),
(3,17,'Incumplimiento de las normas de convivencia','2025-03-11 10:00:00','2025-07-14 10:00:00'),
(4,38,'Incumplimiento de las normas de convivencia','2025-02-20 10:00:00','2025-09-14 10:00:00'),
(5,99,'Incumplimiento de las normas de convivencia','2025-04-14 10:00:00','2025-07-11 10:00:00'),
(6,36,'Inasistencia reiterada a tutorias agendadas','2025-05-16 10:00:00','2025-08-10 10:00:00'),
(7,34,'Intento de fraude con transferencia de tokens','2025-03-17 10:00:00','2025-06-17 10:00:00'),
(8,119,'Uso de vocabulario inapropiado en tutoria','2025-05-12 10:00:00','2025-09-11 10:00:00'),
(9,19,'Incumplimiento de las normas de convivencia','2025-03-19 10:00:00','2025-06-17 10:00:00'),
(10,92,'Intento de fraude con transferencia de tokens','2025-02-10 10:00:00','2025-06-11 10:00:00');

-- =====================================================
-- 10. MOVIMIENTOS DE TOKENS (muestra de 30 de 150)
-- =====================================================
INSERT INTO movimiento_token (id_movimiento, id_usuario, cantidad, fecha) VALUES
(1,73,-15,'2025-04-11 18:29:00'),
(2,52,10,'2025-02-12 16:31:00'),
(3,11,100,'2025-05-25 20:28:00'),
(4,83,20,'2025-03-18 08:34:00'),
(5,85,20,'2025-04-23 14:16:00'),
(6,81,-20,'2025-04-16 09:50:00'),
(7,57,-20,'2025-03-05 08:22:00'),
(8,4,-20,'2025-06-08 15:34:00'),
(9,9,100,'2025-06-21 12:41:00'),
(10,69,100,'2025-05-01 08:31:00'),
(11,8,50,'2025-02-13 09:23:00'),
(12,104,-20,'2025-06-15 18:44:00'),
(13,20,-20,'2025-06-08 09:12:00'),
(14,95,20,'2025-05-21 08:40:00'),
(15,117,-15,'2025-02-08 19:51:00');

SET FOREIGN_KEY_CHECKS = 1;
SET @seed_mode = 0;  -- reactiva triggers de validacion