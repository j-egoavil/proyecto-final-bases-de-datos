# U-Linker — Plataforma de Tutorias Universitarias P2P

> *"Sistema descentralizado de tutorias basado en una economia interna de tokens"*

Proyecto final — Bases de Datos, Universidad Nacional de Colombia.

**Equipo:** Juan Esteban Infante, Emilio Esteban Molina, Juan Sebastian Basabe, Deisy Viviana Lara, Juan Daniel Egoavil, Camilo Andres Pineros.

---

## Stack

| Capa | Tecnologia |
|------|-----------|
| Base de datos | MySQL 8.0+ |
| Backend | Python 3 + Flask |
| Frontend | Bootstrap 5 + Jinja2 |
| Conector | mysql-connector-python |

---

## Estado de Entregas

| Sesion | Entregable | Estado |
|--------|-----------|--------|
| **S1** | Disenio conceptual (reglas, ER, diccionario) | Entregado |
| **S2** | Disenio logico/fisico (DDL, normalizacion) | Entregado |
| **S3** | Implementacion BD (triggers, SPs, consultas, seed) | **Completado** |
| **S4** | App web funcional (Flask + frontend) | Pendiente |

---

## Estructura del Proyecto

```
proyecto final bases de datos/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── docs/
│   ├── sesion1/
│   │   └── entregable_s1.md
│   └── plan-trabajo.md
├── database/
│   ├── schema.sql          # DDL — 10 tablas con FK, CHECK, UNIQUE
│   ├── procedures.sql      # 2 funciones, 2 SPs, 2 triggers
│   ├── consultas.sql       # Bateria N1-N6: filtros, joins, agregacion, subconsultas, ventanas, vistas
│   └── seed.sql            # 123 usuarios, 15 materias, 20 tutores, 30 servicios, 1050 reuniones, 80 resenas, 15 baneos
├── backend/
│   ├── app.py
│   ├── config.py
│   ├── db/
│   │   ├── connection.py
│   │   └── queries.py
│   ├── routes/
│   │   ├── auth.py
│   │   ├── usuario.py
│   │   ├── tutor.py
│   │   ├── servicios.py
│   │   ├── reuniones.py
│   │   └── admin.py
│   └── services/
│       ├── tokens.py
│       └── validaciones.py
└── frontend/
    ├── templates/
    │   ├── base.html
    │   ├── auth/
    │   ├── usuario/
    │   ├── tutor/
    │   ├── servicios/
    │   ├── reuniones/
    │   └── admin/
    └── static/
        ├── css/
        └── js/
```

---

## Modelo de Datos (10 tablas)

| # | Tabla | Tipo | Descripcion |
|---|-------|------|-------------|
| 1 | `usuario` | Maestra | Datos base: nombre, email, area, rol, saldo_tokens |
| 2 | `estudiante` | Subclase 1:1 | FK a usuario, semestre |
| 3 | `tutor` | Subclase 1:1 | FK a usuario, descripcion, calif_promedio |
| 4 | `materia` | Maestra | Auto-relacion: id_prerequisito |
| 5 | `materia_aprobada_tutor` | M:N | Tutores que aprobaron materias con nota >= 4.0 |
| 6 | `servicio` | Transaccional | Oferta de tutoria con precio en tokens |
| 7 | `reunion` | Transaccional | Cita agendada (1050 registros de seed) |
| 8 | `resena` | Transaccional | Evaluacion de tutor (calificacion 1-5) |
| 9 | `baneos` | Transaccional | Sanciones con rango de fechas |
| 10 | `movimiento_token` | Auditoria | Registro inmutable de transacciones |

### Diferencias clave vs disenio inicial

- `usuario.saldo_tokens` desnormalizado para performance (se actualiza en cada transaccion)
- `movimiento_token` simplificado: solo `id_usuario`, `cantidad` (+ o -), `fecha`
- Nueva tabla `resena`: evaluacion independiente de reunion, con UNIQUE(estudiante, tutor, materia)
- Sin FK `id_reunion` en `movimiento_token` — la auditoria es generica

---

## Logica en Base de Datos (Entrega 3)

### Funciones (2)

| Funcion | Parametros | Retorna | Proposito |
|---------|-----------|---------|-----------|
| `fn_verificar_saldo_estudiante` | id_estudiante, id_servicio | BOOLEAN | ¿Tiene tokens suficientes? |
| `fn_es_usuario_baneado` | id_usuario, fecha | BOOLEAN | ¿Tiene baneo activo en esa fecha? |

### Procedimientos (2)

| SP | Proposito |
|----|-----------|
| `pr_agendar_tutoria` | Valida baneo + saldo, inserta reunion, transfiere tokens, registra movimientos |
| `pr_asignar_datos_usuario` | Crea usuario + estudiante en transaccion, otorga 15 tokens iniciales |

### Triggers (2)

| Trigger | Evento | Proposito |
|---------|--------|-----------|
| `Trg_actualizar_calificacion_tutor` | AFTER INSERT ON resena | Recalcula calif_promedio del tutor |
| `Trg_reserva_cancelada` | AFTER UPDATE ON reunion | Si se cancela con >24h, reembolsa tokens |

---

## Consultas Analiticas

| Nivel | Tipo | Cantidad |
|-------|------|----------|
| N1 | Seleccion y filtrado | 3 consultas |
| N2 | Joins multiples | 3 consultas |
| N3 | Agregacion y agrupacion | 3 consultas |
| N4 | Subconsultas (CTE, correlacionada, EXISTS) | 3 consultas |
| N5 | Funciones de ventana (DENSE_RANK, SUM OVER) | 2 consultas |
| N6 | Vistas | 2 vistas (`vw_resumen_estudiante`, `vw_desempeno_tutores`) |

---

## Division del Equipo (6 personas — 2-2-2)

| Area | Personas | Responsabilidades |
|------|----------|-------------------|
| **Base de Datos** | P1 + P2 | DDL, triggers, SPs, seed, consultas, vistas **(completado S3)** |
| **Backend** | P3 + P4 | Flask, rutas, queries, servicios, integracion |
| **Frontend** | P5 + P6 | Templates Bootstrap, UX, formularios, dashboards |

---

## Instalacion

```bash
# 1. Base de datos
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
mysql -u root -p < database/procedures.sql

# 2. Backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python backend/app.py
```

---

## Flujo principal del sistema

```
1. Registro (pr_asignar_datos_usuario) → 15 tokens iniciales
2. Estudiante busca servicios → elige uno
3. pr_agendar_tutoria:
   ├── fn_es_usuario_baneado() → rechaza si tiene baneo
   ├── fn_verificar_saldo_estudiante() → rechaza si saldo insuficiente
   ├── INSERT reunion ('Agendada')
   ├── UPDATE usuario: saldo_tokens -= precio
   ├── UPDATE tutor: saldo_tokens += precio
   └── INSERT movimiento_token x2
4. Al finalizar reunion:
   └── Estudiante deja resena → Trg_actualizar_calificacion_tutor recalcula promedio
5. Si cancela con >24h:
   └── Trg_reserva_cancelada → reembolso automatico
```