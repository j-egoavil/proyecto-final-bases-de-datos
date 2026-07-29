# Plan de Trabajo — Division 2-2-2

> U-Linker | 6 personas | Division: 2 DB + 2 Backend + 2 Frontend

---

## Roles y responsables

| # | Area | Enfoque | Archivos clave |
|---|------|---------|---------------|
| **P1** | Base de Datos | DDL + seed + ajustes schema | `database/schema.sql`, `database/seed.sql` |
| **P2** | Base de Datos | PL/SQL + consultas + pruebas | `database/procedures.sql`, `database/consultas.sql` |
| **P3** | Backend | Capa de datos (queries + servicios + modelo) | `backend/db/`, `backend/services/`, `backend/models/` |
| **P4** | Backend | Rutas Flask + app principal | `backend/app.py`, `backend/routes/` |
| **P5** | Frontend | Auth + usuario + admin | `frontend/templates/auth/`, `usuario/`, `admin/` |
| **P6** | Frontend | Tutor + servicios + reuniones | `frontend/templates/tutor/`, `servicios/`, `reuniones/` |

---

## Estado actual (post-Entrega 3)

### Completado

- [x] Schema DDL con 10 tablas, FK, CHECK, UNIQUE (P1)
- [x] Seed data: 124 usuarios, 15 materias, 20 tutores, 30 servicios, 1051 reuniones, 80 resenas, 15 baneos, 150+ movimientos token (P1)
- [x] 2 funciones: `fn_verificar_saldo_estudiante`, `fn_es_usuario_baneado` (P2)
- [x] 2 procedimientos: `pr_agendar_tutoria`, `pr_asignar_datos_usuario` (P2)
- [x] 2 triggers: `Trg_actualizar_calificacion_tutor`, `Trg_reserva_cancelada` (P2)
- [x] Bateria de 16 consultas N1-N6 + 2 vistas (P2)
- [x] Capa de datos P3: conexion, queries, servicios, modelo User, doc P4 (P3)
- [x] Test de integracion P3: 24/24 pruebas OK (`backend/test_p3.py`) (P3)

### Pendiente — Backend (P3 + P4)

- [x] Conexion Flask → MySQL (`backend/db/connection.py`) — P3
- [x] Funciones de queries que llaman SPs y consultas — P3
- [x] Servicios: `tokens.py` (saldo, transferencias), `validaciones.py` (baneos, prerrequisitos) — P3
- [x] Modelo User para Flask-Login (`backend/models/user.py`) — P3
- [x] Documentacion de capa de datos para P4 (`backend/documentacion-p4.md`) — P3
- [x] Ruta `auth.py`: registro con `pr_asignar_datos_usuario`, login, logout
- [x] Ruta `usuario.py`: dashboard (saldo, proximas reuniones, perfil)
- [x] Ruta `tutor.py`: postular, crear servicio, mis servicios
- [x] Ruta `servicios.py`: buscar, detalle, agendar con `pr_agendar_tutoria`
- [x] Ruta `reuniones.py`: mis reuniones, cancelar, finalizar
- [x] Ruta `admin.py`: dashboard, baneos, metricas

### Pendiente — Frontend (P5 + P6)

- [ ] `base.html` — layout con navbar (segun rol), muestra saldo tokens
- [x] `auth/login.html` + `registro.html`
- [ ] `usuario/dashboard.html` — tarjeta de saldo, reuniones pendientes
- [ ] `usuario/perfil.html` — datos, historial
- [ ] `tutor/postular.html` + `mis-servicios.html`
- [x] `servicios/buscar.html` — filtros por materia, modalidad, precio
- [x] `servicios/detalle.html` — boton "Agendar"
- [ ] `reuniones/agendar.html` — fecha, hora, tema
- [ ] `admin/dashboard.html` — metricas, ranking tutores, gestion baneos
- [ ] `static/css/style.css` + `static/js/main.js`

---

## Orden de implementacion por funcionalidad

Cada funcionalidad sigue esta cadena: **DB lista → queries → ruta → template**

### Backend (P3 + P4)

| Orden | Funcionalidad | Quien | Depende de |
|-------|--------------|-------|-----------|
| 1 | Conexion MySQL (`connection.py`) | P3 | — |
| 2 | `config.py` + variables de entorno | P3 | — |
| 3 | `app.py` base (Flask, blueprints, secret key) | P4 | P3 |
| 4 | Queries de auth (crear usuario, obtener por email) | P3 | schema |
| 5 | Ruta `auth.py` (registro con `pr_asignar_datos_usuario`, login) | P4 | P3 |
| 6 | Queries de usuario (saldo, perfil, historial) | P3 | schema |
| 7 | Ruta `usuario.py` (dashboard, perfil) | P4 | P3 |
| 8 | Servicio `validaciones.py` (baneos, prerrequisitos) | P3 | schema |
| 9 | Servicio `tokens.py` (obtener saldo, puede pagar) | P3 | schema |
| 10 | Queries de servicios (buscar, detalle, crear) | P3 | schema |
| 11 | Ruta `servicios.py` (buscar, detalle, agendar con SP) | P4 | P3 |
| 12 | Ruta `tutor.py` (postular, crear servicio) | P4 | P3 |
| 13 | Ruta `reuniones.py` (listar, cancelar, finalizar) | P4 | P3 |
| 14 | Ruta `admin.py` (dashboard, baneos) | P4 | P3 |

### Frontend (P5 + P6)

| Orden | Template | Quien | Depende de |
|-------|----------|-------|-----------|
| 1 | `base.html` (layout, navbar por rol) | P5 | — |
| 2 | `auth/login.html` | P5 | ruta auth |
| 3 | `auth/registro.html` | P5 | ruta auth |
| 4 | `usuario/dashboard.html` (saldo, reuniones) | P5 | ruta usuario |
| 5 | `usuario/perfil.html` | P5 | ruta usuario |
| 6 | `servicios/buscar.html` (filtros, tarjetas) | P6 | ruta servicios |
| 7 | `servicios/detalle.html` (boton agendar) | P6 | ruta servicios |
| 8 | `tutor/postular.html` | P6 | ruta tutor |
| 9 | `tutor/mis-servicios.html` | P6 | ruta tutor |
| 10 | `reuniones/agendar.html` | P6 | ruta reuniones |
| 11 | `admin/dashboard.html` (metricas, ranking) | P5 | ruta admin |
| 12 | CSS + JS (estilos, confirmaciones AJAX) | P5+P6 | todos |

---

## Checklist por persona

### P1 (DB — Schema y Seed)
- [x] `schema.sql` ejecuta sin errores en MySQL
- [x] `seed.sql` inserta datos sin violar constraints
- [ ] Ajustar schema segun necesidades del backend (nuevos indices, columnas extra)

### P2 (DB — PL/SQL y Consultas)
- [x] 2 funciones retornan resultados correctos
- [x] 2 SPs ejecutan sin errores (`pr_agendar_tutoria`, `pr_asignar_datos_usuario`)
- [x] 2 triggers disparan correctamente
- [x] 16 consultas N1-N6 + 2 vistas probadas
- [ ] Agregar SPs adicionales si el backend los necesita

### P3 (Backend — Capa de datos)
- [x] `connection.py` conecta a MySQL sin errores
- [x] Cada funcion en `queries.py` ejecuta la consulta/sp correcta
- [x] `tokens.py` calcula saldos con los datos de seed
- [x] `validaciones.py` detecta baneos activos correctamente
- [x] `models/user.py` — modelo User para Flask-Login (`UserMixin`)
- [x] `documentacion-p4.md` — guia completa de uso para P4

### P4 (Backend — Rutas Flask)
- [ ] `python backend/app.py` levanta sin errores
- [ ] Registro de usuario persiste en BD (llama a `pr_asignar_datos_usuario`)
- [ ] Login/logout con Flask-Login funcional
- [ ] Agendar tutoria valida baneo y saldo (llama a `pr_agendar_tutoria`)
- [ ] Cada ruta responde HTTP 200 o errores con mensajes flash

### P5 (Frontend — Auth, Usuario, Admin)
- [ ] Templates extienden `base.html`
- [ ] Navbar cambia segun `current_user.rol`
- [ ] Dashboard muestra saldo real de tokens
- [ ] Admin dashboard consume `vw_desempeno_tutores`

### P6 (Frontend — Tutor, Servicios, Reuniones)
- [ ] Buscador de servicios con filtros funcionales
- [ ] Formulario de agendar reunion con validacion HTML5
- [ ] Postulacion de tutor guarda en BD
- [ ] Listado de mis servicios y mis reuniones funcional

---

## Flujo de datos Backend ↔ MySQL

```
POST /auth/registro
  → pr_asignar_datos_usuario(nombre, email, pass, area, semestre)

GET /dashboard
  → SELECT saldo_tokens FROM usuario WHERE id_usuario = ?
  → SELECT * FROM vw_resumen_estudiante WHERE id_estudiante = ?

POST /servicios/<id>/agendar
  → fn_es_usuario_baneado(id_estudiante, fecha)
  → fn_verificar_saldo_estudiante(id_estudiante, id_servicio)
  → CALL pr_agendar_tutoria(estudiante, tutor, servicio, fecha, hi, hf)

PATCH /reuniones/<id>/cancelar
  → UPDATE reunion SET estado = 'Cancelada' WHERE id_reunion = ?
  → Trg_reserva_cancelada se dispara automaticamente

POST /resenas
  → INSERT INTO resena (estudiante, tutor, materia, calificacion, texto)
  → Trg_actualizar_calificacion_tutor recalcula calif_promedio

GET /admin
  → SELECT * FROM vw_desempeno_tutores
  → SELECT * FROM vw_resumen_estudiante WHERE saldo_tokens < 10
```

---

## Convenciones

| Aspecto | Acuerdo |
|---------|---------|
| **Ramas Git** | `main` (protegida), `backend-p3`, `backend-p4`, `frontend-p5`, `frontend-p6` |
| **Merge a main** | Solo despues de revision cruzada |
| **DB name** | `u_linker` |
| **SP calls** | Usar `cursor.callproc('pr_agendar_tutoria', args)` |
| **Errores** | Backend captura `SIGNAL SQLSTATE` y muestra mensaje flash |
| **Auth** | Flask-Login con `current_user`, hash de passwords con `werkzeug` |
