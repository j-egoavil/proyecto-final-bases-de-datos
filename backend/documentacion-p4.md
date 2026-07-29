# Documentacion para P4 — Rutas Flask

> Capa de datos (P3) completada. Este documento describe todo lo que P4 necesita para implementar las rutas.

---

## 0. Setup del entorno y verificacion

### Crear entorno virtual e instalar dependencias

```powershell
# Desde la raiz del proyecto
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Configurar variables de entorno

Copia `.env.example` a `.env` y editalo con tus credenciales:

```powershell
Copy-Item .env.example .env
```

```ini
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password_real
DB_NAME=u_linker
FLASK_SECRET_KEY=clave-aleatoria-segura
FLASK_DEBUG=True
```

### Verificar que la capa de datos funciona

```powershell
# Desde la raiz del proyecto
.\.venv\Scripts\python.exe backend\test_p3.py
```

Salida esperada: `=== Resultado: 0 errores ===`

> **Nota:** Si falla alguna vista, ejecuta `database/Views.sql` contra tu instancia MySQL.

---

## 1. Como obtener una conexion a la BD

Usar el context manager manual desde las rutas:

```python
from backend.db.connection import get_db, close_db

conn = get_db()
try:
    # ... usar queries ...
finally:
    close_db(conn)
```

---

## 2. Modelo User (Flask-Login)

```python
from backend.models import User
```

### Constructor

```python
user = User(dict_row)
```

`dict_row` es lo que retorna cualquier `fetch_one` de queries (diccionario con las columnas de la tabla `usuario`).

### Atributos

| Atributo | Tipo | Descripcion |
|----------|------|-------------|
| `user.id` | int | Alias de `id_usuario`, usado por Flask-Login |
| `user.id_usuario` | int | PK de la tabla usuario |
| `user.nombre` | str | Nombre completo |
| `user.email` | str | Correo (unico) |
| `user.password` | str | Hash de la contrasena |
| `user.perfil_foto` | str or None | Ruta de foto de perfil |
| `user.area` | str | Area academica |
| `user.rol` | str | Rol: 'Estudiante', 'Tutor', 'Ambos', 'admin' |
| `user.saldo_tokens` | int | Saldo actual de tokens |
| `user.fecha_creacion` | date | Fecha de registro |

### Metodos de conveniencia

| Metodo | Retorna | Logica |
|--------|---------|--------|
| `user.es_estudiante()` | bool | rol en ('estudiante', 'ambos') |
| `user.es_tutor()` | bool | rol en ('tutor', 'ambos') |
| `user.es_admin()` | bool | rol == 'admin' |

`UserMixin` ya provee `is_authenticated`, `is_active`, `is_anonymous`, `get_id()`.

### User loader (necesario en app.py)

P4 debe configurar Flask-Login asi:

```python
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from backend.models import User
from backend.db.queries import obtener_usuario_por_email, obtener_usuario_por_id
from backend.db.connection import get_db, close_db
from werkzeug.security import check_password_hash, generate_password_hash

login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.init_app(app)

@login_manager.user_loader
def load_user(user_id):
    conn = get_db()
    try:
        row = obtener_usuario_por_id(conn, int(user_id))
        return User(row) if row else None
    finally:
        close_db(conn)
```

---

## 3. Catalogo de queries disponibles

Todas estan en `backend.db.queries`. Reciben `conn` como primer parametro.

### USUARIOS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `crear_usuario(conn, nombre, email, password, area, rol='estudiante')` | basicos + rol | `int` (id nuevo) | Inserta solo en `usuario`. Usar `registrar_usuario_completo` para registro normal |
| `registrar_usuario_completo(conn, nombre, email, password, area, semestre)` | basicos + semestre | `int` (id nuevo) | **Usar esta para registro**. Llama `pr_asignar_datos_usuario`. Crea usuario + estudiante + otorga 15 tokens |
| `obtener_usuario_por_email(conn, email)` | email | `dict or None` | Para login |
| `obtener_usuario_por_id(conn, id_usuario)` | id | `dict or None` | Para user loader |
| `obtener_saldo(conn, id_usuario)` | id | `int` | Saldo actual de tokens |
| `actualizar_perfil(conn, id_usuario, nombre=None, area=None, perfil_foto=None)` | id + campos opcionales | — | Solo actualiza campos no-None |
| `actualizar_rol(conn, id_usuario, rol)` | id + nuevo rol | — | Usar al postularse como tutor |

### ESTUDIANTES

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_estudiante_por_id(conn, id_estudiante)` | id | `dict or None` | JOIN con usuario, incluye semestre |
| `obtener_estudiantes(conn)` | — | `list[dict]` | Todos los estudiantes con su info |
| `obtener_resumen_estudiante(conn, id_estudiante)` | id | `dict or None` | Usa vista `vw_resumen_estudiante`. Incluye total_reuniones, resenas_otorgadas |

### TUTORES

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `registrar_tutor(conn, id_usuario, descripcion)` | id + descripcion | — | Solo inserta en tabla tutor |
| `postular_tutor(conn, id_usuario, descripcion, materias_aprobadas)` | id + desc + lista materias | — | **Usar esta para postular**. Registra tutor + materias + cambia rol |
| `obtener_tutor_por_id(conn, id_tutor)` | id | `dict or None` | JOIN con usuario |
| `obtener_tutores(conn)` | — | `list[dict]` | Todos, ordenados por calif_promedio DESC |
| `obtener_materias_tutor(conn, id_tutor)` | id | `list[dict]` | Materias que el tutor tiene aprobadas |
| `obtener_desempeno_tutores(conn)` | — | `list[dict]` | Vista `vw_desempeno_tutores` |

### MATERIAS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_materias(conn)` | — | `list[dict]` | Todas las materias |
| `obtener_materia_por_id(conn, id_materia)` | id | `dict or None` | Una materia |
| `obtener_prerrequisito(conn, id_materia)` | id | `dict or None` | Materia prerrequisito (si tiene) |

### SERVICIOS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `crear_servicio(conn, id_tutor, id_materia, nombre, precio_tokens, modalidad, descripcion)` | completos | `int` (id nuevo) | Crea un servicio de tutoria |
| `obtener_servicios(conn, id_materia=None, modalidad=None, precio_max=None)` | filtros opcionales | `list[dict]` | Buscador con filtros. Incluye tutor_nombre, materia_nombre, calif_promedio |
| `obtener_servicio_por_id(conn, id_servicio)` | id | `dict or None` | Detalle completo con tutor y materia |
| `obtener_servicios_por_tutor(conn, id_tutor)` | id | `list[dict]` | Servicios de un tutor especifico |

### REUNIONES

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `agendar_reunion(conn, id_estudiante, id_tutor, id_servicio, fecha, hora_inicio, hora_fin, tema=None)` | completos | — | **Llama `pr_agendar_tutoria`**. Valida baneo y saldo automaticamente. Descuenta tokens |
| `obtener_reuniones_estudiante(conn, id_estudiante, solo_pendientes=False)` | id + filtro | `list[dict]` | Reuniones del estudiante |
| `obtener_reuniones_tutor(conn, id_tutor, solo_pendientes=False)` | id + filtro | `list[dict]` | Reuniones del tutor |
| `obtener_reunion_por_id(conn, id_reunion)` | id | `dict or None` | Detalle completo con nombres |
| `cancelar_reunion(conn, id_reunion)` | id | — | Cambia estado a Cancelada. **Trigger `Trg_reserva_cancelada`** maneja reembolso si >24h |
| `finalizar_reunion(conn, id_reunion)` | id | — | Cambia estado a Finalizada |

### RESENIAS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `crear_resena(conn, id_estudiante, id_tutor, id_materia, calificacion, texto=None)` | completos | `int` (id nuevo) | **Trigger `Trg_actualizar_calificacion_tutor`** recalcula promedio |
| `obtener_resenas_tutor(conn, id_tutor)` | id | `list[dict]` | Resenas recibidas por un tutor |

### BANEOS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_baneos_usuario(conn, id_usuario)` | id | `list[dict]` | Historial de baneos |
| `crear_baneo(conn, id_usuario, motivo, fecha_inicio, fecha_fin)` | completos | — | Crea un baneo (admin) |

### MOVIMIENTOS DE TOKENS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_movimientos_usuario(conn, id_usuario)` | id | `list[dict]` | Todos los movimientos |
| `obtener_historial_tokens(conn, id_usuario, limite=20)` | id + limite | `list[dict]` | Ultimos N movimientos |

### ADMIN / METRICAS

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_estadisticas_generales(conn)` | — | `dict` | total_usuarios, total_tutores, total_reuniones_finalizadas, total_tokens_movidos, baneos_activos |

---

## 4. Servicios disponibles

### `backend.services.tokens`

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `obtener_saldo(id_usuario)` | id | `int` | No necesita `conn`, maneja su propia conexion |
| `puede_pagar(id_usuario, precio)` | id + precio | `bool` | Saldo >= precio? |
| `verificar_saldo_servicio(id_estudiante, id_servicio)` | ids | `bool` | Usa `fn_verificar_saldo_estudiante` |
| `obtener_movimientos(id_usuario, limite=20)` | id + limite | `list[dict]` | Historial de movimientos |
| `obtener_balance_historico()` | — | `list[dict]` | Flujo diario de tokens (para admin) |

### `backend.services.validaciones`

| Funcion | Parametros | Retorna | Notas |
|---------|-----------|---------|-------|
| `usuario_baneado(id_usuario, fecha=None)` | id + fecha opcional | `bool` | Usa `fn_es_usuario_baneado`. Sin fecha = hoy |
| `puede_ser_tutor(id_usuario, id_materia)` | ids | `bool` | Tiene la materia aprobada con nota >= 4.0? |
| `es_tutor(id_usuario)` | id | `bool` | Ya esta registrado en tabla tutor? |
| `prerrequisito_aprobado(id_estudiante, id_materia)` | ids | `bool` | Cumple el prerrequisito? Sin prerequisito = True |
| `obtener_baneos_activos()` | — | `list[dict]` | Baneos vigentes ahora (para admin) |
| `materias_disponibles_para_tutor(id_usuario)` | id | `list[dict]` | Materias donde puede ser tutor (nota >= 4.0) |

---

## 5. Stored Procedures y Funciones en MySQL

### Procedimientos

| SP | Parametros | Que hace |
|----|-----------|----------|
| `pr_asignar_datos_usuario` | nombre, email, password, area, semestre | Crea usuario + estudiante + otorga 15 tokens (en una transaccion) |
| `pr_agendar_tutoria` | id_estudiante, id_tutor, id_servicio, fecha, hora_inicio, hora_fin | Valida baneo + saldo, crea reunion, descuenta tokens del estudiante, suma tokens al tutor, registra movimientos |

### Funciones

| Funcion | Parametros | Retorna | Que hace |
|---------|-----------|---------|----------|
| `fn_verificar_saldo_estudiante` | id_estudiante, id_servicio | BOOLEAN | Saldo >= precio del servicio? |
| `fn_es_usuario_baneado` | id_usuario, fecha | BOOLEAN | Baneo activo en esa fecha? |

### Triggers (se disparan automaticamente)

| Trigger | Evento | Que hace |
|---------|--------|----------|
| `Trg_actualizar_calificacion_tutor` | AFTER INSERT en resena | Recalcula calif_promedio del tutor |
| `Trg_reserva_cancelada` | AFTER UPDATE en reunion (a Cancelada) | Si faltan >= 24h, reembolsa tokens al estudiante |
| `trg_validar_materia_tutor` | BEFORE INSERT en materia_aprobada_tutor | Rechaza si nota < 4.0 |
| `trg_validar_servicio` | BEFORE INSERT en servicio | Rechaza si el tutor no tiene la materia aprobada |
| `trg_validar_baneo_reunion` | BEFORE INSERT en reunion | Rechaza si estudiante o tutor estan baneados |
| `trg_validar_baneo_servicio` | BEFORE INSERT en servicio | Rechaza si el tutor esta baneado |
| `trg_control_saldo` | BEFORE INSERT en reunion | Rechaza si el estudiante no tiene saldo suficiente |

### Vistas

| Vista | Contenido |
|-------|-----------|
| `vw_resumen_estudiante` | id_estudiante, nombre, email, area, semestre, saldo_tokens, total_reuniones, resenas_otorgadas |
| `vw_desempeno_tutores` | id_tutor, tutor, area, calif_promedio, materias_aprobadas, servicios_activos, tutorias_completadas |
| `vw_dashboard_general` | Estadisticas agrupadas por area (estudiantes, tutores, reuniones, tokens, calif promedio) |
| `vw_materias_demandadas` | Materias con mas reuniones, tutores ofertando y tokens generados |
| `vw_perfil_tutor` | Perfil de tutor con materias aprobadas |

Todas las vistas estan en `database/Views.sql`. Si alguna falta, ejecutar todo el archivo Views.sql contra la BD.

---

## 6. Manejo de errores

Los stored procedures lanzan `SIGNAL SQLSTATE '45000'` con mensajes en espanol:

- `'Error: El estudiante tiene una sancion activa en la fecha seleccionada.'`
- `'Error: El estudiante no tiene suficientes tokens para este servicio.'`

P4 debe capturarlos asi:

```python
from mysql.connector import Error as MySQLError

try:
    agendar_reunion(conn, id_estudiante, id_tutor, id_servicio, fecha, hi, hf)
    flash("Tutoria agendada con exito", "success")
except MySQLError as e:
    flash(str(e), "error")
```

---

## 7. Flujos completos de ejemplo

### Registro de usuario

```python
from werkzeug.security import generate_password_hash
from backend.db.queries import registrar_usuario_completo

password_hash = generate_password_hash(password)
id_nuevo = registrar_usuario_completo(conn, nombre, email, password_hash, area, semestre)
```

### Login

```python
from werkzeug.security import check_password_hash
from backend.db.queries import obtener_usuario_por_email
from backend.models import User
from flask_login import login_user

row = obtener_usuario_por_email(conn, email)
if row and check_password_hash(row['password'], password):
    user = User(row)
    login_user(user)
```

### Agendar tutoria

```python
from backend.db.queries import agendar_reunion, obtener_servicio_por_id
from mysql.connector import Error as MySQLError

servicio = obtener_servicio_por_id(conn, id_servicio)

try:
    agendar_reunion(conn,
        id_estudiante=current_user.id_usuario,
        id_tutor=servicio['id_tutor'],
        id_servicio=id_servicio,
        fecha=fecha,
        hora_inicio=hora_inicio,
        hora_fin=hora_fin,
        tema=tema
    )
except MySQLError as e:
    # El SP ya valida baneo y saldo
    flash(str(e), "error")
```

### Cancelar reunion

```python
from backend.db.queries import cancelar_reunion

cancelar_reunion(conn, id_reunion)
# Trigger Trg_reserva_cancelada maneja reembolso automaticamente
```

### Crear resena

```python
from backend.db.queries import crear_resena

crear_resena(conn, id_estudiante, id_tutor, id_materia, calificacion, texto)
# Trigger Trg_actualizar_calificacion_tutor recalcula promedio
```