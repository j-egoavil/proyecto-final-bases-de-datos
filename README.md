# P2P-Shield — Sistema Colaborativo de Alerta Temprana y Tutorías

Proyecto final de Bases de Datos.

## Resumen

Plataforma web que conecta estudiantes en riesgo académico con tutores pares de excelencia. El sistema detecta automáticamente estudiantes con notas bajas y recomienda tutores compatibles según materia, desempeño y horarios. Soporta sesiones gratuitas (video pregrabado/streaming) y premium (chat en vivo).

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Base de datos | MySQL 8.0+ |
| Backend | Python 3 + Flask |
| Frontend | Bootstrap 5 + Jinja2 |
| Conector MySQL | mysql-connector-python |
| Chat en vivo | Flask-SocketIO |

---

## Estructura del Proyecto

```
proyecto final bases de datos/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── database/
│   ├── schema.sql          # DDL completo (tablas, constraints, índices)
│   ├── procedures.sql      # Triggers, Stored Procedures, Vistas
│   └── seed.sql            # Datos de prueba
├── backend/
│   ├── __init__.py
│   ├── app.py              # Aplicación Flask principal
│   ├── config.py           # Configuración (variables de entorno)
│   ├── db/
│   │   ├── __init__.py
│   │   ├── connection.py   # Conexión a MySQL
│   │   └── queries.py      # Consultas SQL y llamadas a SPs
│   ├── models/
│   │   └── __init__.py     # Clases de modelo
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py         # Login, registro, logout
│   │   ├── estudiante.py   # Perfil, notas, horarios, alertas
│   │   ├── tutor.py        # Postulación, gestión de sesiones
│   │   ├── tutorias.py     # Búsqueda, inscripción, chat
│   │   └── admin.py        # Dashboard y métricas
│   └── services/
│       ├── __init__.py
│       ├── matchmaking.py  # Motor de recomendación de tutores
│       └── alertas.py      # Procesamiento de alertas académicas
└── frontend/
    ├── templates/
    │   ├── base.html
    │   ├── auth/
    │   │   ├── login.html
    │   │   └── registro.html
    │   ├── estudiante/
    │   │   ├── dashboard.html
    │   │   └── perfil.html
    │   ├── tutor/
    │   │   ├── postular.html
    │   │   └── mis-sesiones.html
    │   ├── tutorias/
    │   │   ├── buscar.html
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

## Modelo Entidad-Relación (13 tablas)

### Herencia por tabla de clase

```
persona ───1:1─── estudiante ───1:1─── tutor_perfil
```

| # | Tabla | Propósito |
|---|-------|-----------|
| 1 | `persona` | Datos base de cualquier usuario (nombre, email, contraseña, rol) |
| 2 | `estudiante` | Extiende persona: semestre, carrera, horas balance, estado de riesgo |
| 3 | `tutor_perfil` | Extiende estudiante: descripción, calificación promedio, activo |
| 4 | `materia` | Catálogo de materias (código, nombre, créditos) |
| 5 | `horario_estudiante` | Horarios semanales por estudiante y materia |
| 6 | `nota` | Calificaciones históricas por estudiante y materia |
| 7 | `tutor_materia` | Materias que un tutor está habilitado a enseñar (requiere nota ≥ 4.2) |
| 8 | `sesion_tutoria` | Sesión programada: tutor, materia, fecha, tipo (gratuita/premium), cupos |
| 9 | `inscripcion` | Estudiante inscrito a una sesión, asistencia, calificación al tutor |
| 10 | `mensaje_chat` | Mensajes del chat en vivo de sesiones premium |
| 11 | `suscripcion` | Tipo de membresía del estudiante (gratis/premium) |
| 12 | `alerta` | Alerta generada por nota baja, con nivel de riesgo |
| 13 | `evaluacion_tutor` | Evaluación post-sesión (puntuación, comentario) |

---

## Lógica en Base de Datos

### Triggers (4)

| Trigger | Evento | Función |
|---------|--------|---------|
| `trg_alerta_nota_baja` | AFTER INSERT/UPDATE ON nota | Si nota < 3.0 genera alerta y actualiza estado_riesgo del estudiante |
| `trg_validar_tutor` | BEFORE INSERT ON tutor_materia | Rechaza si el estudiante no tiene nota ≥ 4.2 en esa materia |
| `trg_control_cupo` | BEFORE INSERT ON inscripcion | Rechaza si la sesión ya está llena; si pasa, incrementa cupo_actual |
| `trg_actualizar_horas` | AFTER UPDATE ON inscripcion | Al marcar asistencia, actualiza horas_recibidas y horas_tutoreadas |

### Stored Procedures (3)

| SP | Función |
|----|---------|
| `sp_matchmaking(id_estudiante)` | Encuentra tutores compatibles por materia, nota y horario |
| `sp_balance_horas(id_estudiante)` | Calcula balance de horas dadas vs recibidas |
| `sp_metricas_admin()` | Agregados para el dashboard administrativo |

### Vistas (4)

| Vista | Uso |
|-------|-----|
| `vw_estudiantes_riesgo` | Dashboard admin: semáforo de riesgo |
| `vw_tutores_disponibles` | Buscador de tutorías para estudiantes |
| `vw_sesiones_abiertas` | Sesiones con cupos disponibles |
| `vw_rendimiento_tutores` | Métricas de calidad de tutores |

---

## División del Equipo (6 personas)

| Rol | Responsable | Entregable principal |
|-----|-------------|---------------------|
| **DBA 1** | Persona A | `database/schema.sql` — DDL completo |
| **DBA 2** | Persona B | `database/procedures.sql` — Triggers, SPs, Vistas |
| **Backend 1** | Persona C | `backend/db/` + `backend/services/` — Capa de datos y lógica |
| **Backend 2** | Persona D | `backend/app.py` + `backend/routes/` — API y rutas |
| **Frontend 1** | Persona E | Templates: auth, estudiante, perfil |
| **Frontend 2** | Persona F | Templates: tutor, tutorías, admin |

Un integrante asume el rol de **líder técnico**: revisa merges, asegura integración backend-frontend, y coordina el script unificado final.

---

## Cronograma (4 semanas)

| Semana | DBA 1 | DBA 2 | Backend 1 | Backend 2 | Frontend 1 | Frontend 2 |
|--------|-------|-------|-----------|-----------|------------|------------|
| **1** | Schema físico (DDL) | Triggers, SPs, Vistas | Conexión DB, modelos | — | — | — |
| **2** | Datos de prueba (DML) | Depurar triggers/SPs | matchmaking, alertas | Rutas Flask | Layout base, login, dashboard | Layout base, admin |
| **3** | Afinar índices | Soporte | Soporte integración | Terminar rutas | Buscador, perfil tutor | Sala tutoría, chat |
| **4** | Integración final y pruebas | Integración final y pruebas | Pruebas de flujo | Pruebas de flujo | Correcciones UI | Correcciones UI |

---

## Instalación

```bash
# 1. Clonar el repo
git clone <url-del-repo>
cd "proyecto final bases de datos"

# 2. Crear entorno virtual
python -m venv venv
venv\Scripts\activate    # Windows

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de MySQL

# 5. Crear la base de datos
mysql -u root -p < database/schema.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/seed.sql

# 6. Ejecutar la aplicación
python backend/app.py
```

---

## Funcionalidades Principales

- Detección automática de estudiantes en riesgo (nota < 3.0)
- Motor de matchmaking: recomienda tutores por materia, compatibilidad de horario y desempeño
- Postulación a tutor con validación automática (nota ≥ 4.2 en la materia)
- Sistema de balance de horas (tutoreadas vs recibidas)
- Sesiones gratuitas (video pregrabado) y premium (chat en vivo)
- Dashboard administrativo con semáforos de riesgo y métricas de retención
- Evaluación de tutores post-sesión