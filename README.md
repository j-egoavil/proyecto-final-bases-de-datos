# Plataforma de Tutorías Universitarias P2P y Gestión de Fichas Académicas

> *"Sistema descentralizado de tutorías basado en una economía interna de tokens"*

Proyecto final — Bases de Datos, Universidad Nacional de Colombia.

---

## Tabla de Contenidos

1. [Descripción del Dominio](#descripción-del-dominio)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Reglas de Negocio](#reglas-de-negocio)
4. [Diagrama Entidad-Relación](#diagrama-entidad-relación)
5. [Diccionario de Datos Preliminar](#diccionario-de-datos-preliminar)
6. [Lógica en Base de Datos](#lógica-en-base-de-datos)
7. [División del Equipo](#división-del-equipo)
8. [Cronograma y Entregables](#cronograma-y-entregables)
9. [Instalación](#instalación)
10. [Rúbrica de Evaluación](#rúbrica-de-evaluación)

---

## Descripción del Dominio

Plataforma web P2P que conecta estudiantes universitarios para el intercambio de tutorías académicas. Opera bajo una **economía interna de tokens**: los estudiantes obtienen tokens al servir como tutores y los gastan para recibir tutorías de otros, eliminando transacciones monetarias y fomentando la cooperación académica.

**¿Por qué una base de datos relacional?** La alta interconectividad entre usuarios, materias, servicios y transacciones de tokens exige un motor relacional que garantice:
- **ACID**: Consistencia estricta en balances de tokens (sin saldos negativos ni duplicidades).
- **Integridad referencial**: Validación de prerrequisitos entre materias, historial de penalizaciones y relaciones jerárquicas usuario-estudiante-tutor.
- **Consultas analíticas**: Rankings de tutores, balances históricos, métricas de uso por período.

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Base de datos | MySQL 8.0+ |
| Backend | Python 3 + Flask |
| Frontend | Bootstrap 5 + Jinja2 |
| Conector MySQL | mysql-connector-python |
| Tiempo real | Flask-SocketIO (chat en reuniones) |

---

## Reglas de Negocio

> **Requisito del curso:** Mínimo 5 reglas en lenguaje natural, cada una indicando entidades involucradas y restricción.

### RN-01: Especialización Exclusiva Condicionada de Roles
Un usuario puede actuar como estudiante, y opcionalmente registrarse como tutor si cumple los requisitos. La entidad `TUTOR` hereda de `USUARIO` mediante relación de herencia 1:1.

- **Entidades:** USUARIO, ESTUDIANTE, TUTOR
- **Restricción:** Todo registro en TUTOR debe estar mapeado a un `id_usuario` existente y activo.

### RN-02: Aprobación Académica Previa para Oferta de Servicios
Un tutor solo puede crear un SERVICIO para una MATERIA si posee un registro en `MATERIA_APROBADA_TUTOR` con nota ≥ 4.0 en dicha materia.

- **Entidades:** TUTOR, MATERIA, MATERIA_APROBADA_TUTOR, SERVICIO
- **Restricción:** Se bloquea la inserción del servicio si la tupla (tutor, materia) no existe o `nota < 4.0`.

### RN-03: Control de Flujo Financiero y Saldos de Tokens
Un estudiante solo agenda una REUNION si su saldo de tokens (∑ ingresos − ∑ egresos en `MOVIMIENTO_TOKEN`) es ≥ al `precio_tokens` del SERVICIO. Al finalizar, se debitan tokens del estudiante y se acreditan al tutor.

- **Entidades:** ESTUDIANTE, TUTOR, REUNION, MOVIMIENTO_TOKEN
- **Restricción:** Bloqueo de agendamiento si saldo insuficiente. Transacción atómica de cobro.

### RN-04: Validación de Prerrequisitos (Auto-relación en MATERIA)
Una MATERIA puede tener un prerrequisito vía el atributo autorreferencial `id_prerrequisito`. Un estudiante solo agenda reunión para una materia avanzada si ha aprobado su prerrequisito.

- **Entidades:** MATERIA, SERVICIO, REUNION, ESTUDIANTE
- **Restricción:** Restricción de integridad relacional reflexiva. Consulta recursiva del plan de estudios.

### RN-05: Inhabilitación Activa por Historial de Penalizaciones
Un usuario con un registro activo en `BANEOS` cuya fecha actual esté dentro de `[fecha_inicio, fecha_fin]` tiene suspendida toda acción: crear servicios, agendar tutorías, transferir tokens.

- **Entidades:** USUARIO, BANEOS, REUNION, SERVICIO
- **Restricción:** Bloqueo temporal de privilegios según rango de fechas del baneo.

---

## Diagrama Entidad-Relación

### Resumen del modelo

```
                    ┌──────────┐
                    │  USUARIO │ (entidad padre)
                    └────┬─────┘
                         │ 1:1 (herencia)
              ┌──────────┴──────────┐
              ▼                     ▼
        ┌───────────┐        ┌──────────┐
        │ESTUDIANTE │        │  TUTOR   │
        └─────┬─────┘        └────┬─────┘
              │                   │
              │    ┌──────────────┤
              │    │ M:N          │ M:N
              │    │ (nota)       │
              │    ▼              ▼
              │ ┌──────────────────────┐
              │ │MATERIA_APROBADA_TUTOR│
              │ └──────────────────────┘
              │                   │
              ▼                   ▼
        ┌───────────┐     ┌──────────┐
        │  REUNION  │◄────│ SERVICIO │
        │ (fecha,   │     │(precio,  │
        │  estado,  │     │ modalidad│
        │  tokens)  │     │          │
        └───────────┘     └──────────┘
              │                   │
              │                   │
              ▼                   ▼
        ┌──────────┐      ┌──────────┐
        │  MATERIA │◄─────│  MATERIA │ (auto-relación: id_prerrequisito)
        └──────────┘      └──────────┘

  USUARIO ───1:N─── BANEOS
  USUARIO ───1:N─── MOVIMIENTO_TOKEN
```

### Requisitos del curso cumplidos

| Requisito | Cumplimiento |
|-----------|-------------|
| ≥ 8 entidades | **9 entidades** — USUARIO, ESTUDIANTE, TUTOR, MATERIA, MATERIA_APROBADA_TUTOR, SERVICIO, REUNION, BANEOS, MOVIMIENTO_TOKEN |
| ≥ 2 relaciones M:N con atributos | **2** — MATERIA_APROBADA_TUTOR (`nota`), REUNION (`fecha`, `hora_inicio`, `hora_fin`, `estado`, `tokens_cobrados`) |
| ≥ 1 auto-relación o jerarquía | **2** — Jerarquía USUARIO→ESTUDIANTE / USUARIO→TUTOR (1:1) + Auto-relación MATERIA (`id_prerrequisito`) |
| Datos temporales | **Sí** — REUNION (fecha/hora), BANEOS (rango fechas), MOVIMIENTO_TOKEN (fecha) |
| ≥ 5 reglas de negocio | **5** — Ver sección anterior |

### Entidades

| # | Entidad | Tipo | Descripción |
|---|---------|------|-------------|
| 1 | `usuario` | Maestra | Datos base de cualquier usuario del sistema |
| 2 | `estudiante` | Subclase (1:1 con usuario) | Usuario que puede agendar tutorías |
| 3 | `tutor` | Subclase (1:1 con usuario) | Usuario habilitado para dictar tutorías |
| 4 | `materia` | Maestra | Catálogo de materias, con auto-relación de prerrequisitos |
| 5 | `materia_aprobada_tutor` | Asociativa (M:N) | Valida que un tutor aprobó la materia con nota ≥ 4.0 |
| 6 | `servicio` | Transaccional | Oferta de tutoría: tutor, materia, precio en tokens, modalidad |
| 7 | `reunion` | Transaccional (M:N) | Cita agendada entre estudiante y servicio |
| 8 | `baneos` | Transaccional | Sanciones temporales a usuarios |
| 9 | `movimiento_token` | Transaccional | Registro inmutable de cada transacción de tokens |

---

## Diccionario de Datos Preliminar

> Formato exigido por el curso: Entidad, Atributo, Tipo sugerido, Restricción, Descripción.

### usuario

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_usuario` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador único del usuario |
| `nombre` | VARCHAR(150) | NOT NULL | Nombre completo |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL | Correo institucional |
| `password` | VARCHAR(255) | NOT NULL | Contraseña encriptada (hash) |
| `area` | VARCHAR(100) | NOT NULL | Carrera o plan curricular |
| `rol` | VARCHAR(30) | NOT NULL | Rol primario (estudiante / admin) |
| `fecha_creacion` | DATE | NOT NULL | Fecha de alta en el sistema |

### estudiante

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_estudiante` | INT | PK, FK → usuario(id_usuario), NOT NULL | ID vinculado al usuario (herencia 1:1) |
| `semestre` | INT | NOT NULL | Semestre actual |

### tutor

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_tutor` | INT | PK, FK → usuario(id_usuario), NOT NULL | ID vinculado al usuario (herencia 1:1) |
| `descripcion` | TEXT | NULL | Biografía y experiencia del tutor |
| `calif_promedio` | FLOAT | DEFAULT 0.0 | Calificación acumulada histórica |

### materia

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_materia` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador único de la asignatura |
| `nombre` | VARCHAR(100) | UNIQUE, NOT NULL | Nombre oficial |
| `creditos` | INT | NOT NULL | Peso en créditos académicos |
| `id_prerrequisito` | INT | FK → materia(id_materia), NULL | Auto-relación: materia prerrequisito |

### materia_aprobada_tutor

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador único de validación |
| `id_tutor` | INT | FK → tutor(id_tutor), NOT NULL | Tutor que aprobó la asignatura |
| `id_materia` | INT | FK → materia(id_materia), NOT NULL | Asignatura aprobada |
| `nota` | FLOAT | CHECK (nota ≥ 4.0), NOT NULL | Calificación obtenida |

### servicio

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_servicio` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador de la oferta académica |
| `id_tutor` | INT | FK → tutor(id_tutor), NOT NULL | Tutor que oferta el servicio |
| `id_materia` | INT | FK → materia(id_materia), NOT NULL | Asignatura del servicio |
| `nombre` | VARCHAR(120) | NOT NULL | Título de la oferta |
| `precio_tokens` | INT | NOT NULL | Costo en tokens por sesión |
| `modalidad` | VARCHAR(50) | NOT NULL | Virtual / Presencial / Híbrido |
| `descripcion` | TEXT | NULL | Temas clave del servicio |

### reunion

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_reunion` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador de la cita agendada |
| `id_tutor` | INT | FK → tutor(id_tutor), NOT NULL | Tutor asignado |
| `id_estudiante` | INT | FK → estudiante(id_estudiante), NOT NULL | Estudiante que recibe la tutoría |
| `id_servicio` | INT | FK → servicio(id_servicio), NOT NULL | Servicio del cual se deriva la cita |
| `fecha` | DATE | NOT NULL | Fecha de la reunión |
| `hora_inicio` | TIME | NOT NULL | Hora pactada de inicio |
| `hora_fin` | TIME | NOT NULL | Hora pactada de finalización |
| `tema` | VARCHAR(255) | NULL | Subtema específico a tratar |
| `estado` | VARCHAR(30) | NOT NULL | Agendada / Finalizada / Cancelada |
| `tokens_cobrados` | INT | NOT NULL | Total de tokens debitados |

### baneos

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_baneo` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador único de sanción |
| `id_usuario` | INT | FK → usuario(id_usuario), NOT NULL | Usuario sancionado |
| `motivo` | TEXT | NOT NULL | Causa de la inhabilitación |
| `fecha_inicio` | DATETIME | NOT NULL | Inicio del baneo |
| `fecha_fin` | DATETIME | NOT NULL | Fin de la sanción |

### movimiento_token

| Atributo | Tipo sugerido | Restricción | Descripción |
|----------|--------------|-------------|-------------|
| `id_movimiento` | INT | PK, NOT NULL, AUTO_INCREMENT | Identificador único de transacción |
| `id_usuario` | INT | FK → usuario(id_usuario), NOT NULL | Usuario involucrado |
| `id_reunion` | INT | FK → reunion(id_reunion), NULL | Reunión asociada (si aplica) |
| `tipo` | VARCHAR(20) | NOT NULL | 'ingreso' o 'egreso' |
| `cantidad` | INT | CHECK (cantidad > 0), NOT NULL | Cantidad de tokens (valor absoluto) |
| `fecha` | DATETIME | NOT NULL | Estampa de tiempo de la transacción |

---

## Lógica en Base de Datos

### Triggers

| Trigger | Evento | Regla | Función |
|---------|--------|------|---------|
| `trg_validar_materia_tutor` | BEFORE INSERT ON materia_aprobada_tutor | RN-02 | Rechaza si `nota < 4.0` |
| `trg_validar_servicio` | BEFORE INSERT ON servicio | RN-02 | Verifica que exista `materia_aprobada_tutor` para ese (tutor, materia) |
| `trg_control_saldo` | BEFORE INSERT ON reunion | RN-03 | Calcula saldo del estudiante y rechaza si es insuficiente |
| `trg_cobro_tokens` | AFTER UPDATE ON reunion | RN-03 | Cuando `estado` = 'Finalizada', genera MOVIMIENTO_TOKEN para estudiante (-) y tutor (+) |
| `trg_validar_baneo` | BEFORE INSERT ON reunion, servicio | RN-05 | Rechaza si el usuario tiene un baneo activo |
| `trg_validar_prerrequisito` | BEFORE INSERT ON reunion | RN-04 | Verifica que el estudiante haya aprobado el prerrequisito de la materia |

### Stored Procedures

| SP | Función |
|----|---------|
| `sp_saldo_tokens(id_usuario)` | Retorna saldo actual: SUM(ingresos) − SUM(egresos) |
| `sp_tutores_disponibles(id_materia)` | Busca tutores con materia aprobada (nota ≥ 4.0) que no estén baneados |
| `sp_historial_reuniones(id_usuario, fecha_inicio, fecha_fin)` | Historial de reuniones por rango de fechas |
| `sp_ranking_tutores()` | Tutores ordenados por calif_promedio y cantidad de reuniones |
| `sp_materias_con_prerrequisitos()` | Recorre la jerarquía de prerrequisitos de materias |

### Vistas

| Vista | Uso |
|-------|-----|
| `vw_saldo_usuarios` | Saldo actual de tokens por usuario |
| `vw_tutores_activos` | Tutores no baneados con sus materias y calificación |
| `vw_servicios_disponibles` | Servicios activos con info de tutor, materia y precio |
| `vw_reuniones_pendientes` | Reuniones agendadas para hoy/futuro |
| `vw_historial_transacciones` | MOVIMIENTO_TOKEN con nombres de usuario y tipo |
| `vw_usuarios_baneados` | Usuarios con baneos activos y fecha de fin |

---

## División del Equipo

**6 integrantes.** Roles según lo exigido por el curso + back/front.

| Rol curso | Persona | Responsabilidades técnicas |
|-----------|---------|---------------------------|
| **Líder Técnico** | Persona 1 | Coordina merges, integración back-front, repositorio, revisa calidad |
| **Modelador** | Persona 2 | `database/schema.sql` — DDL completo, ER, diccionario de datos |
| **Programador SQL** | Persona 3 | `database/procedures.sql` — Triggers, SPs, Vistas |
| **Documentador / Backend 1** | Persona 4 | `backend/db/` + `backend/services/` — Conexión, queries, lógica de tokens |
| **Backend 2 / Presentador** | Persona 5 | `backend/app.py` + `backend/routes/` — API Flask |
| **Frontend** | Persona 6 | `frontend/` — Templates Bootstrap, UX de todas las vistas |

---

## Cronograma y Entregables

### Entregables del curso

| Sesión | Entregable | Peso | Contenido |
|--------|-----------|------|-----------|
| **S1** | Diseño conceptual | 15% | Reglas de negocio, diagrama E-R, diccionario de datos |
| **S2** | Diseño lógico/físico | — | DDL, normalización, constraints |
| **S3-S4** | Implementación | — | App funcional, triggers, SPs, frontend |

### Plan de trabajo por semana

| Semana | Modelador (P2) | Prog. SQL (P3) | Backend 1 (P4) | Backend 2 (P5) | Frontend (P6) | Líder (P1) |
|--------|---------------|----------------|----------------|----------------|---------------|------------|
| **1** | Schema DDL + seed.sql | Triggers, SPs | Conexión DB, modelos | — | — | Revisión S1, setup repo |
| **2** | Afinar DDL, índices | Depurar triggers/SPs, vistas | Servicios: tokens, matchmaking | Rutas Flask: auth, usuario, estudiante | Layout base, login, registro | Integración back-db |
| **3** | Soporte | Soporte | Soporte | Rutas: tutor, servicios, reuniones | Dashboard, buscador, perfil tutor | Integración front-back |
| **4** | Pruebas de integridad | Pruebas de triggers | Pruebas de flujo | Pruebas de API | Correcciones UI | Merge final, README |

### Estructura del repositorio

```
proyecto final bases de datos/
├── README.md                  ← Este documento
├── requirements.txt           ← Dependencias Python
├── .env.example               ← Template de variables de entorno
├── .gitignore
├── docs/
│   └── sesion1/
│       └── entregable_s1.md   ← Reglas, ER, diccionario (para exportar a PDF)
├── database/
│   ├── schema.sql             ← DDL completo (Modelador)
│   ├── procedures.sql         ← Triggers, SPs, Vistas (Programador SQL)
│   └── seed.sql               ← Datos de prueba
├── backend/
│   ├── __init__.py
│   ├── app.py                 ← Aplicación Flask principal
│   ├── config.py              ← Variables de entorno
│   ├── db/
│   │   ├── __init__.py
│   │   ├── connection.py      ← Conexión MySQL
│   │   └── queries.py         ← Consultas y llamadas a SPs
│   ├── models/
│   │   └── __init__.py        ← Clases de modelo
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py            ← Login, registro, logout
│   │   ├── usuario.py         ← Perfil, historial
│   │   ├── tutor.py           ← Postularse, gestionar servicios
│   │   ├── servicios.py       ← Buscar, crear, ver servicios
│   │   ├── reuniones.py       ← Agendar, cancelar, historial
│   │   └── admin.py           ← Dashboard, baneos, métricas
│   └── services/
│       ├── __init__.py
│       ├── tokens.py          ← Lógica de saldo y transacciones
│       └── validaciones.py    ← Prerrequisitos, baneos, requisitos tutor
└── frontend/
    ├── templates/
    │   ├── base.html
    │   ├── auth/
    │   │   ├── login.html
    │   │   └── registro.html
    │   ├── usuario/
    │   │   ├── dashboard.html
    │   │   └── perfil.html
    │   ├── tutor/
    │   │   ├── postular.html
    │   │   └── mis-servicios.html
    │   ├── servicios/
    │   │   ├── buscar.html
    │   │   └── detalle.html
    │   ├── reuniones/
    │   │   ├── agendar.html
    │   │   └── sala.html
    │   └── admin/
    │       └── dashboard.html
    └── static/
        ├── css/
        │   └── style.css
        └── js/
            └── main.js
```

---

## Instalación

```bash
# 1. Clonar el repo
git clone <url-del-repo>
cd "proyecto final bases de datos"

# 2. Crear entorno virtual
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar variables de entorno
cp .env.example .env
# Editar .env con credenciales de MySQL

# 5. Ejecutar scripts SQL en orden
mysql -u root -p < database/schema.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/seed.sql

# 6. Ejecutar la aplicación
python backend/app.py
# Abrir http://localhost:5000
```

---

## Rúbrica de Evaluación

### Sesión 1 — Diseño Conceptual (15%)

| Aspecto | Pts | Entregable asociado |
|---------|-----|---------------------|
| Pertinencia de la temática | 2 | Descripción del dominio |
| Reglas de negocio | 3 | 5 reglas (RN-01 a RN-05) |
| Entidades y atributos | 3 | 9 entidades con PKs y atributos |
| Relaciones y cardinalidades | 3 | M:N, herencia, auto-relación |
| Diccionario de datos | 2 | Tabla formato estándar |
| Defensa ante el docente | 2 | Presentación oral |

### Proyecto completo (100%)

> Pendiente — rúbrica de sesiones S2, S3, S4 por definir por el docente.