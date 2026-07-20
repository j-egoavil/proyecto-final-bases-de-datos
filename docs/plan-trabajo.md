# Plan de Trabajo y Repartición de Tareas

> Equipo de 6 personas — Proyecto Final Bases de Datos

---

## Roles

| # | Rol curso | Rol técnico | Archivos principales |
|---|-----------|-------------|---------------------|
| **P1** | Líder Técnico | Integración + Backend de soporte | `app.py`, `README.md`, revisión de merges |
| **P2** | Modelador | DBA — Schema físico (DDL) | `database/schema.sql`, `database/seed.sql` |
| **P3** | Programador SQL | DBA — Lógica del motor (triggers/SPs) | `database/procedures.sql` |
| **P4** | Documentador | Backend — Capa de datos | `backend/db/`, `backend/services/` |
| **P5** | — | Backend — Rutas y API | `backend/routes/` |
| **P6** | — | Frontend — Templates y UX | `frontend/` |

> Nota: Los roles "Documentador" y "Presentador" del curso se reparten entre los integrantes según la sesión. P4 (Documentador) además del código mantiene la documentación de cada entrega. El presentador rota por sesión.

---

## Tareas por persona

### P1 — Líder Técnico (Integración)

**Objetivo:** Que todas las piezas encajen. La app corre de punta a punta.

| # | Tarea | Semana |
|---|-------|--------|
| 1 | Crear repositorio, estructura de carpetas, `.gitignore`, `requirements.txt` | S1 |
| 2 | Configurar `app.py` con Flask, registrar todos los blueprints, configurar `config.py` | S1 |
| 3 | Probar conexión Flask → MySQL desde `app.py` | S2 |
| 4 | Integrar rutas de P5 con queries de P4 y templates de P6 | S2-S3 |
| 5 | Implementar autenticación (Flask-Login): login, registro, sesiones, hash de contraseñas | S2 |
| 6 | Revisar merges de todos, resolver conflictos, mantener `main` estable | S1-S4 |
| 7 | Probar flujos completos: registro → postular tutor → crear servicio → agendar reunión → cobro tokens | S3-S4 |
| 8 | Escribir `README.md` final con instrucciones de instalación y uso | S4 |
| 9 | Preparar despliegue/demo para la presentación final | S4 |

**Dependencias:** P2 (schema listo para probar conexión), P4 (queries para probar flujos).

---

### P2 — Modelador (DBA — Schema)

**Objetivo:** Base de datos normalizada y lista con datos de prueba.

| # | Tarea | Semana |
|---|-------|--------|
| 1 | Escribir `database/schema.sql`: DDL de las 9 tablas con PKs, FKs, constraints, CHECK, índices | S1 |
| 2 | Validar herencia 1:1: `usuario` → `estudiante`, `usuario` → `tutor` (FK con PK simultánea) | S1 |
| 3 | Validar auto-relación en `materia` (`id_prerrequisito` → `id_materia`) | S1 |
| 4 | Agregar constraints: `CHECK (nota >= 4.0)` en `materia_aprobada_tutor`, `CHECK (cantidad > 0)` en `movimiento_token` | S1 |
| 5 | Crear índices para consultas frecuentes: email, fechas de reuniones, baneos activos | S2 |
| 6 | Escribir `database/seed.sql`: datos de prueba realistas | S2 |
| 7 | Datos de seed mínimos: 20 usuarios, 5 tutores, 8 materias (2 con prerrequisitos), 15 servicios, varias reuniones | S2 |
| 8 | Corregir schema según feedback de P3 (triggers que fallen por constraints) | S2-S3 |
| 9 | Script final unificado: `schema.sql` + `seed.sql` ejecutables en orden | S4 |

**Dependencias:** Ninguna (es la base de todo). P3 necesita el schema para escribir triggers.

**Revisar con P3:** Nombres exactos de columnas para que triggers y SPs referencien correctamente.

---

### P3 — Programador SQL (DBA — Lógica)

**Objetivo:** Toda la inteligencia de negocio vive en el motor MySQL.

| # | Tarea | Semana |
|---|-------|--------|
| 1 | Escribir `database/procedures.sql` con todos los triggers, SPs y vistas | S1-S2 |
| 2 | **Triggers (6):** | |
|   | `trg_validar_materia_tutor`: BEFORE INSERT en `materia_aprobada_tutor` → rechazar si `nota < 4.0` | S1 |
|   | `trg_validar_servicio`: BEFORE INSERT en `servicio` → verificar `materia_aprobada_tutor` | S1 |
|   | `trg_validar_baneo_servicio`: BEFORE INSERT en `servicio` → rechazar si tutor baneado | S1 |
|   | `trg_validar_baneo_reunion`: BEFORE INSERT en `reunion` → rechazar si estudiante baneado | S1 |
|   | `trg_control_saldo`: BEFORE INSERT en `reunion` → verificar saldo ≥ `precio_tokens` | S2 |
|   | `trg_cobro_tokens`: AFTER UPDATE en `reunion` → cuando `estado = 'Finalizada'`, insertar movimientos | S2 |
|   | `trg_validar_prerrequisito`: BEFORE INSERT en `reunion` → verificar prerrequisito aprobado | S2 |
| 3 | **Stored Procedures (5):** | |
|   | `sp_saldo_tokens(id_usuario)`: cálculo de saldo actual | S2 |
|   | `sp_tutores_disponibles(id_materia)`: tutores con materia aprobada y sin baneo | S2 |
|   | `sp_historial_reuniones(id_usuario, fecha_inicio, fecha_fin)`: consultas por rango | S2 |
|   | `sp_ranking_tutores()`: ordenados por calificación y cantidad | S2 |
|   | `sp_materias_con_prerrequisitos()`: recorre jerarquía de prerrequisitos | S2 |
| 4 | **Vistas (6):** | |
|   | `vw_saldo_usuarios` | S2 |
|   | `vw_tutores_activos` | S2 |
|   | `vw_servicios_disponibles` | S2 |
|   | `vw_reuniones_pendientes` | S2 |
|   | `vw_historial_transacciones` | S2 |
|   | `vw_usuarios_baneados` | S2 |
| 5 | Probar triggers con casos límite (nota < 4.0, saldo insuficiente, baneo activo) | S2-S3 |
| 6 | Script `test_procedures.sql` con casos de prueba documentados | S3 |
| 7 | Ajustar SPs según feedback de P4 (queries que necesiten optimización) | S3-S4 |

**Dependencias:** P2 (schema debe existir para crear triggers/SPs). P4 consume los SPs y vistas.

**Entregables:** `database/procedures.sql`, `database/test_procedures.sql`.

---

### P4 — Documentador (Backend — Capa de Datos)

**Objetivo:** Capa de acceso a datos. Todo lo que toca MySQL pasa por acá. **También mantiene la documentación de cada entrega del curso.**

| # | Tarea | Semana |
|---|-------|--------|
| 1 | Implementar `backend/db/connection.py`: pool de conexiones, `get_db()`, `close_db()` | S1 |
| 2 | Implementar `backend/db/queries.py`: funciones que encapsulan **todas** las consultas SQL | S2-S3 |
|   | `crear_usuario()`, `obtener_usuario_por_email()`, `obtener_usuario_por_id()` | S2 |
|   | `registrar_estudiante()`, `registrar_tutor()` | S2 |
|   | `crear_servicio()`, `obtener_servicios_por_materia()`, `obtener_servicios_por_tutor()` | S2 |
|   | `agendar_reunion()`, `obtener_reuniones_estudiante()`, `obtener_reuniones_tutor()` | S2 |
|   | `actualizar_estado_reunion()` (dispara el trigger de cobro) | S2 |
|   | `obtener_materias()`, `obtener_prerrequisitos()` | S2 |
|   | `obtener_baneos_activos()` | S3 |
| 3 | Implementar `backend/services/tokens.py`: | S2-S3 |
|   | `obtener_saldo(id_usuario)` → llama a `sp_saldo_tokens` | S2 |
|   | `inicializar_tokens(id_usuario)` → otorga 50 tokens iniciales | S2 |
|   | `puede_pagar(id_usuario, precio)` → compara saldo | S3 |
| 4 | Implementar `backend/services/validaciones.py`: | S2-S3 |
|   | `usuario_baneado(id_usuario)` → consulta baneos activos | S2 |
|   | `puede_ser_tutor(id_usuario, id_materia)` → verifica `materia_aprobada_tutor` con nota ≥ 4.0 | S2 |
|   | `prerrequisito_aprobado(id_estudiante, id_materia)` → recorre cadena de prerrequisitos | S3 |
| 5 | Documentar `docs/sesion1/entregable_s1.md` (exportar a PDF con Overleaf) | S1 |
| 6 | Documentar entregable Sesión 2 (diseño lógico/físico) cuando corresponda | S2 |
| 7 | Documentar entregable Sesión 3 y Sesión 4 | S3-S4 |
| 8 | Mantener `README.md` actualizado con P1 | S1-S4 |

**Dependencias:** P2 (schema) y P3 (SPs, vistas) deben existir para implementar queries.

**Entregables:** `backend/db/`, `backend/services/`, `docs/sesion*/`.

---

### P5 — Backend (Rutas y API)

**Objetivo:** Todas las rutas Flask funcionando. La app responde a requests y renderiza templates.

| # | Tarea | Semana |
|---|-------|--------|
| 1 | Configurar estructura de blueprints en `backend/routes/__init__.py` | S1 |
| 2 | `backend/routes/auth.py`: | S2 |
|   | `POST /auth/registro` — crear usuario + estudiante + tokens iniciales | S2 |
|   | `POST /auth/login` — autenticar, iniciar sesión Flask-Login | S2 |
|   | `GET /auth/logout` — cerrar sesión | S2 |
| 3 | `backend/routes/usuario.py`: | S2 |
|   | `GET /dashboard` — resumen: saldo tokens, próximas reuniones, servicios recomendados | S2 |
|   | `GET /perfil` — datos del usuario, historial | S2 |
|   | `GET /perfil/editar` + `POST /perfil/editar` | S2 |
| 4 | `backend/routes/tutor.py`: | S3 |
|   | `GET /tutor/postular` — formulario de postulación | S3 |
|   | `POST /tutor/postular` — registrar tutor + materia_aprobada_tutor | S3 |
|   | `GET /tutor/mis-servicios` — CRUD de servicios del tutor | S3 |
|   | `POST /tutor/crear-servicio` | S3 |
| 5 | `backend/routes/servicios.py`: | S3 |
|   | `GET /servicios` — listado con filtros: materia, modalidad, precio | S3 |
|   | `GET /servicios/<id>` — detalle del servicio | S3 |
|   | `POST /servicios/<id>/agendar` — crear reunión (valida saldo, baneos, prerrequisitos) | S3 |
| 6 | `backend/routes/reuniones.py`: | S3 |
|   | `GET /reuniones` — mis reuniones (estudiante o tutor) | S3 |
|   | `GET /reuniones/<id>` — detalle con opción de cancelar o marcar finalizada | S3 |
|   | `POST /reuniones/<id>/cancelar` | S3 |
|   | `POST /reuniones/<id>/finalizar` — dispara trigger de cobro | S3 |
| 7 | `backend/routes/admin.py`: | S3 |
|   | `GET /admin/dashboard` — métricas, ranking tutores | S3 |
|   | `POST /admin/banear` — crear baneo | S3 |
| 8 | Probar todas las rutas con Postman o requests manuales | S3-S4 |
| 9 | Manejar errores con try/except, mensajes flash para el frontend | S4 |

**Dependencias:** P4 (queries y services deben existir). P6 (templates para renderizar).

**Entregable:** `backend/routes/` completo y funcional.

---

### P6 — Frontend (Templates y UX)

**Objetivo:** Interfaces usables con Bootstrap 5. El usuario puede navegar y usar la app sin fricción.

| # | Tarea | Semana |
|---|-------|--------|
| 1 | `frontend/templates/base.html` — layout base con navbar (cambia según rol: estudiante/tutor/admin, muestra saldo tokens) | S2 |
| 2 | `frontend/static/css/style.css` — estilos personalizados sobre Bootstrap | S2 |
| 3 | `frontend/static/js/main.js` — lógica de frontend (confirmaciones, AJAX si se requiere) | S2 |
| 4 | `frontend/templates/auth/login.html` + `registro.html` — formularios con validación HTML5 | S2 |
| 5 | `frontend/templates/usuario/dashboard.html`: | S2-S3 |
|   | Tarjeta de saldo tokens | S2 |
|   | Próximas reuniones (tabla con fecha, tutor, materia, estado) | S3 |
|   | Servicios recomendados (según área/carrera) | S3 |
|   | Alertas si tiene baneo activo | S3 |
| 6 | `frontend/templates/usuario/perfil.html` — datos personales, historial de tutorías | S3 |
| 7 | `frontend/templates/tutor/postular.html` — formulario: seleccionar materia, subir nota | S3 |
| 8 | `frontend/templates/tutor/mis-servicios.html` — tabla con servicios creados, botón crear nuevo | S3 |
| 9 | `frontend/templates/servicios/buscar.html`: | S3 |
|   | Filtros: materia (dropdown), modalidad, rango de precio en tokens | S3 |
|   | Resultados como tarjetas (card): nombre tutor, materia, precio, modalidad, calificación | S3 |
| 10 | `frontend/templates/servicios/detalle.html` — info completa + botón "Agendar reunión" | S3 |
| 11 | `frontend/templates/reuniones/agendar.html` — formulario: fecha, hora, tema | S3 |
| 12 | `frontend/templates/reuniones/sala.html` — detalle de reunión, chat (si aplica), botones cancelar/finalizar | S3 |
| 13 | `frontend/templates/admin/dashboard.html` — métricas, tabla de usuarios, ranking tutores, gestión de baneos | S3-S4 |
| 14 | Responsive design: probar en mobile y desktop | S4 |
| 15 | Mensajes flash para feedback (éxito/error en operaciones) | S4 |

**Dependencias:** P5 (rutas definidas para saber qué datos llegan a cada template). P1 (integración Flask-Login para `current_user` en templates).

**Entregable:** `frontend/` completo con todos los templates funcionales.

---

## Dependencias entre personas

```
Semana 1:
  P2 (schema) ─────────────────────────────────────────────┐
  P3 (triggers/SPs) ─── espera schema de P2                │
  P1 (app.py, auth, repo) ─────────────────────────────────┤
  P4 (db connection) ─── espera schema de P2                │
  P5 (blueprints base) ────────────────────────────────────┤
  P6 (—)                                                    │
                                                            │
Semana 2:                                                   │
  P2 (seed.sql) ───────────────────────────────────────────┤
  P3 (terminar SPs/vistas) ────────────────────────────────┤
  P4 (queries + services) ─── depende de P2 y P3 ──────────┤
  P5 (rutas auth, usuario) ─── depende de P4 ──────────────┤
  P6 (templates auth, dashboard) ─── depende de P5 ────────┤
  P1 (integrar P4 + P5 + P6) ◄── todos convergen acá ─────┘

Semana 3:
  P2 (índices, ajustes) ───────────────────────────────────┐
  P3 (probar triggers, test SQL) ──────────────────────────┤
  P4 (soporte queries) ────────────────────────────────────┤
  P5 (rutas tutor, servicios, reuniones, admin) ───────────┤
  P6 (templates tutor, servicios, reuniones, admin) ───────┤
  P1 (integrar todo, probar flujos) ◄──────────────────────┘

Semana 4:
  Todos: pruebas, correcciones, documentación, demo
  P1: merge final, README, preparar presentación
```

---

## Flujo de desarrollo por funcionalidad

Cada funcionalidad sigue este orden de implementación:

```
1. P2/P3: Base de datos lista (tablas, triggers, SPs)
       ↓
2. P4: Funciones de acceso a datos (queries.py + services)
       ↓
3. P5: Ruta Flask que usa las funciones de P4
       ↓
4. P6: Template HTML que renderiza la ruta de P5
       ↓
5. P1: Prueba el flujo completo, reporta bugs
```

**Orden de funcionalidades:**

| Orden | Funcionalidad | ¿Quién la completa? |
|-------|--------------|---------------------|
| 1 | Registro y login | P2 → P4 → P5 → P6 → P1 |
| 2 | Dashboard (saldo, perfil) | P3 → P4 → P5 → P6 → P1 |
| 3 | Postularse como tutor | P2 → P4 → P5 → P6 → P1 |
| 4 | Crear y buscar servicios | P3 → P4 → P5 → P6 → P1 |
| 5 | Agendar reunión (validaciones) | P3 → P4 → P5 → P6 → P1 |
| 6 | Finalizar reunión (cobro tokens) | P3 → P4 → P5 → P6 → P1 |
| 7 | Admin dashboard y baneos | P3 → P4 → P5 → P6 → P1 |

---

## Herramientas y convenciones

| Aspecto | Acuerdo |
|---------|---------|
| **Control de versiones** | Git + GitHub. Rama `main` protegida. Cada persona trabaja en su rama (`p2-schema`, `p3-sp`, `p4-backend`, etc.) |
| **Merge a main** | Solo P1 (líder) mergea a `main` después de revisar |
| **Base de datos** | MySQL 8.0+. Nombre de la BD: `p2p_shield` |
| **Python** | 3.10+. Entorno virtual (`venv`). Dependencias en `requirements.txt` |
| **Formato SQL** | Tablas y columnas en **minúsculas con snake_case**. Comentarios en español. |
| **Formato Python** | Funciones en español descriptivas. Sin tipo de retorno obligatorio. |
| **Comunicación** | Grupo de WhatsApp/Discord. Dailies rápidas al empezar cada sesión de trabajo. |

---

## Semanas clave y deadlines

| Semana | Fecha aprox. | Hito |
|--------|-------------|------|
| **S1** | 16-22 Jul | Schema listo (P2). Triggers base (P3). Conexión DB (P4). App Flask corriendo (P1). **Entregable S1: diseño conceptual.** |
| **S2** | 23-29 Jul | SPs y vistas completos (P3). Queries + services (P4). Auth + dashboard (P5+P6). |
| **S3** | 30 Jul - 5 Ago | Todas las rutas y templates terminados. Flujos completos funcionales. |
| **S4** | 6-12 Ago | Pruebas, correcciones, documentación final. **Demo y entrega.** |

---

## ¿Cómo saber si voy bien?

### P2 (Modelador)
- [ ] `schema.sql` ejecuta sin errores en MySQL
- [ ] `seed.sql` inserta datos de prueba sin violar constraints
- [ ] Las 9 tablas tienen PKs, FKs y CHECKs definidos

### P3 (Programador SQL)
- [ ] Los 7 triggers disparan correctamente con datos de prueba
- [ ] Los 5 SPs retornan resultados esperados
- [ ] Las 6 vistas se pueden consultar con `SELECT *`
- [ ] Intentar violar una regla de negocio lanza error (no solo lo ignora)

### P4 (Backend — Capa de datos)
- [ ] `connection.py` conecta y cierra sin errores
- [ ] Cada función en `queries.py` ejecuta la consulta correcta
- [ ] `tokens.py` calcula saldos correctos con datos de seed
- [ ] `validaciones.py` rechaza correctamente baneos y prerrequisitos

### P5 (Backend — Rutas)
- [ ] Cada ruta responde con HTTP 200 (o el código esperado)
- [ ] Los formularios persisten datos en la BD
- [ ] Los errores muestran mensajes flash al usuario

### P6 (Frontend)
- [ ] Todos los templates extienden `base.html`
- [ ] La app se ve bien en pantalla de escritorio (1920px)
- [ ] Los formularios validan campos obligatorios en el frontend
- [ ] El dashboard del usuario muestra su saldo de tokens real

### P1 (Líder)
- [ ] `python backend/app.py` levanta la app sin errores
- [ ] El flujo completo registro → tutor → servicio → reunión → cobro funciona de inicio a fin
- [ ] `README.md` tiene instrucciones claras para instalar y ejecutar
- [ ] El repo está limpio (sin archivos innecesarios, `.env` en `.gitignore`)