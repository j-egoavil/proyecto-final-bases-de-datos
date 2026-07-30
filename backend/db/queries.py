from backend.db.connection import fetch_one, fetch_all, execute, call_proc


# =====================================================================
# USUARIOS
# =====================================================================

def crear_usuario(conn, nombre, email, password, area, rol='estudiante'):
    """Inserta un usuario base (sin estudiante/tutor aun)."""
    cursor = execute(conn, """
        INSERT INTO usuario (nombre, email, password, area, rol, saldo_tokens, fecha_creacion)
        VALUES (%s, %s, %s, %s, %s, 0, CURRENT_DATE)
    """, (nombre, email, password, area, rol))
    conn.commit()
    return cursor.lastrowid  


def registrar_usuario_completo(conn, nombre, email, password, area, semestre):
    """Usa pr_asignar_datos_usuario: crea usuario, estudiante y otorga 15 tokens."""
    call_proc(conn, 'pr_asignar_datos_usuario',
              (nombre, email, password, area, semestre))
    conn.commit()
    row = fetch_one(conn, "SELECT MAX(id_usuario) AS id FROM usuario")
    return row['id'] if row else None


def obtener_usuario_por_email(conn, email):
    return fetch_one(conn,
        "SELECT * FROM usuario WHERE email = %s", (email,))


def obtener_usuario_por_id(conn, id_usuario):
    return fetch_one(conn,
        "SELECT * FROM usuario WHERE id_usuario = %s", (id_usuario,))


def obtener_saldo(conn, id_usuario):
    row = fetch_one(conn,
        "SELECT saldo_tokens FROM usuario WHERE id_usuario = %s", (id_usuario,))
    return row['saldo_tokens'] if row else 0


def actualizar_perfil(conn, id_usuario, nombre=None, area=None, perfil_foto=None):
    campos = []
    params = []
    if nombre:
        campos.append("nombre = %s")
        params.append(nombre)
    if area:
        campos.append("area = %s")
        params.append(area)
    if perfil_foto:
        campos.append("perfil_foto = %s")
        params.append(perfil_foto)
    if campos:
        params.append(id_usuario)
        execute(conn, f"UPDATE usuario SET {', '.join(campos)} WHERE id_usuario = %s", params)
        conn.commit()


def actualizar_rol(conn, id_usuario, rol):
    execute(conn, "UPDATE usuario SET rol = %s WHERE id_usuario = %s", (rol, id_usuario))
    conn.commit()


# =====================================================================
# ESTUDIANTES
# =====================================================================

def obtener_estudiante_por_id(conn, id_estudiante):
    return fetch_one(conn, """
        SELECT u.*, e.semestre
        FROM usuario u
        JOIN estudiante e ON u.id_usuario = e.id_estudiante
        WHERE e.id_estudiante = %s
    """, (id_estudiante,))


def obtener_estudiantes(conn):
    return fetch_all(conn, """
        SELECT u.id_usuario, u.nombre, u.email, u.area, e.semestre, u.saldo_tokens
        FROM usuario u
        JOIN estudiante e ON u.id_usuario = e.id_estudiante
        ORDER BY u.nombre
    """)


def obtener_resumen_estudiante(conn, id_estudiante):
    return fetch_one(conn, """
        SELECT * FROM vw_resumen_estudiante WHERE id_estudiante = %s
    """, (id_estudiante,))


# =====================================================================
# TUTORES
# =====================================================================

def registrar_tutor(conn, id_usuario, descripcion):
    execute(conn, """
        INSERT INTO tutor (id_tutor, descripcion, calif_promedio)
        VALUES (%s, %s, 0.0)
    """, (id_usuario, descripcion))
    conn.commit()


def postular_tutor(conn, id_usuario, descripcion, materias_aprobadas):
    """
    materias_aprobadas: lista de dicts [{'id_materia': 1, 'nota': 4.5}, ...]
    Registra al usuario como tutor y agrega sus materias aprobadas.
    Actualiza el rol del usuario.
    """
    registrar_tutor(conn, id_usuario, descripcion)
    actualizar_rol(conn, id_usuario, 'tutor')
    for m in materias_aprobadas:
        execute(conn, """
            INSERT INTO materia_aprobada_tutor (id_tutor, id_materia, nota)
            VALUES (%s, %s, %s)
        """, (id_usuario, m['id_materia'], m['nota']))
    conn.commit()


def obtener_tutor_por_id(conn, id_tutor):
    return fetch_one(conn, """
        SELECT u.*, t.descripcion, t.calif_promedio
        FROM usuario u
        JOIN tutor t ON u.id_usuario = t.id_tutor
        WHERE t.id_tutor = %s
    """, (id_tutor,))


def obtener_tutores(conn):
    return fetch_all(conn, """
        SELECT u.id_usuario, u.nombre, u.email, u.area, t.descripcion, t.calif_promedio
        FROM usuario u
        JOIN tutor t ON u.id_usuario = t.id_tutor
        ORDER BY t.calif_promedio DESC
    """)


def obtener_materias_tutor(conn, id_tutor):
    return fetch_all(conn, """
        SELECT m.id_materia, m.nombre, m.creditos, mat.nota
        FROM materia_aprobada_tutor mat
        JOIN materia m ON mat.id_materia = m.id_materia
        WHERE mat.id_tutor = %s
    """, (id_tutor,))


def obtener_desempeno_tutores(conn, limit=50, offset=0):
    query = """
        SELECT * 
        FROM vw_desempeno_tutores
        LIMIT %s OFFSET %s
    """
    return fetch_all(conn, query, (limit, offset))

def obtener_perfil_tutor_completo(conn, id_tutor):
    """Usa vw_perfil_tutor: una fila por cada materia que domina el tutor.
    Lista vacía = el usuario todavía no se ha postulado como tutor."""
    return fetch_all(conn, "SELECT * FROM vw_perfil_tutor WHERE id_tutor = %s", (id_tutor,))

def agregar_materia_tutor(conn, id_tutor, id_materia, nota):
    """Agrega una materia aprobada adicional a un tutor ya existente."""
    execute(conn, """
        INSERT INTO materia_aprobada_tutor (id_tutor, id_materia, nota)
        VALUES (%s, %s, %s)
    """, (id_tutor, id_materia, nota))
    conn.commit()


# =====================================================================
# MATERIAS
# =====================================================================

def obtener_materias(conn):
    return fetch_all(conn, """
        SELECT id_materia, nombre, creditos, id_prerequisito
        FROM materia ORDER BY nombre
    """)


def obtener_materia_por_id(conn, id_materia):
    return fetch_one(conn,
        "SELECT * FROM materia WHERE id_materia = %s", (id_materia,))


def obtener_prerrequisito(conn, id_materia):
    """Retorna la materia prerrequisito si existe."""
    return fetch_one(conn, """
        SELECT m2.*
        FROM materia m1
        LEFT JOIN materia m2 ON m1.id_prerequisito = m2.id_materia
        WHERE m1.id_materia = %s
    """, (id_materia,))


# =====================================================================
# SERVICIOS
# =====================================================================

def crear_servicio(conn, id_tutor, id_materia, nombre, precio_tokens, modalidad, descripcion):
    cursor = execute(conn, """
        INSERT INTO servicio (id_tutor, id_materia, nombre, precio_tokens, modalidad, descripcion)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (id_tutor, id_materia, nombre, precio_tokens, modalidad, descripcion))
    conn.commit()
    return cursor.lastrowid  


def obtener_servicios(conn, id_materia=None, modalidad=None, precio_max=None, limit=50, offset=0):
    query = """
        SELECT s.*, u.nombre AS tutor_nombre, m.nombre AS materia_nombre,
               t.calif_promedio
        FROM servicio s
        JOIN tutor t ON s.id_tutor = t.id_tutor
        JOIN usuario u ON t.id_tutor = u.id_usuario
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE 1=1
    """
    params = []
    
    if id_materia:
        query += " AND s.id_materia = %s"
        params.append(id_materia)
    if modalidad:
        query += " AND s.modalidad = %s"
        params.append(modalidad)
    if precio_max:
        query += " AND s.precio_tokens <= %s"
        params.append(precio_max)
        
    query += " ORDER BY t.calif_promedio DESC"
    
    # Se agrega la lógica de paginación
    query += " LIMIT %s OFFSET %s"
    params.extend([limit, offset])
    
    return fetch_all(conn, query, params)


def obtener_servicio_por_id(conn, id_servicio):
    return fetch_one(conn, """
        SELECT s.*, u.nombre AS tutor_nombre, m.nombre AS materia_nombre,
               t.descripcion AS tutor_descripcion, t.calif_promedio
        FROM servicio s
        JOIN tutor t ON s.id_tutor = t.id_tutor
        JOIN usuario u ON t.id_tutor = u.id_usuario
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE s.id_servicio = %s
    """, (id_servicio,))


def obtener_servicios_por_tutor(conn, id_tutor):
    return fetch_all(conn, """
        SELECT s.*, m.nombre AS materia_nombre
        FROM servicio s
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE s.id_tutor = %s
        ORDER BY s.nombre
    """, (id_tutor,))


# =====================================================================
# REUNIONES
# =====================================================================

def agendar_reunion(conn, id_estudiante, id_tutor, id_servicio,
                    fecha, hora_inicio, hora_fin, tema=None):
    """Usa el stored procedure pr_agendar_tutoria."""
    call_proc(conn, 'pr_agendar_tutoria',
              (id_estudiante, id_tutor, id_servicio,
               fecha, hora_inicio, hora_fin))
    conn.commit()


def obtener_reuniones_estudiante(conn, id_estudiante, solo_pendientes=False):
    query = """
        SELECT r.*, u.nombre AS tutor_nombre, s.nombre AS servicio_nombre,
               m.nombre AS materia_nombre, s.modalidad
        FROM reunion r
        JOIN usuario u ON r.id_tutor = u.id_usuario
        JOIN servicio s ON r.id_servicio = s.id_servicio
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE r.id_estudiante = %s
    """
    if solo_pendientes:
        query += " AND r.estado = 'Agendada'"
    query += " ORDER BY r.fecha DESC, r.hora_inicio DESC"
    return fetch_all(conn, query, (id_estudiante,))


def obtener_reuniones_tutor(conn, id_tutor, solo_pendientes=False):
    query = """
        SELECT r.*, u.nombre AS estudiante_nombre, s.nombre AS servicio_nombre,
               m.nombre AS materia_nombre
        FROM reunion r
        JOIN usuario u ON r.id_estudiante = u.id_usuario
        JOIN servicio s ON r.id_servicio = s.id_servicio
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE r.id_tutor = %s
    """
    if solo_pendientes:
        query += " AND r.estado = 'Agendada'"
    query += " ORDER BY r.fecha DESC, r.hora_inicio DESC"
    return fetch_all(conn, query, (id_tutor,))


def obtener_reunion_por_id(conn, id_reunion):
    return fetch_one(conn, """
        SELECT r.*,
               u_est.nombre AS estudiante_nombre,
               u_tut.nombre AS tutor_nombre,
               s.nombre AS servicio_nombre,
               m.nombre AS materia_nombre
        FROM reunion r
        JOIN usuario u_est ON r.id_estudiante = u_est.id_usuario
        JOIN usuario u_tut ON r.id_tutor = u_tut.id_usuario
        JOIN servicio s ON r.id_servicio = s.id_servicio
        JOIN materia m ON s.id_materia = m.id_materia
        WHERE r.id_reunion = %s
    """, (id_reunion,))


def cancelar_reunion(conn, id_reunion):
    """Cambia estado a Cancelada. El trigger Trg_reserva_cancelada maneja reembolsos."""
    execute(conn,
        "UPDATE reunion SET estado = 'Cancelada' WHERE id_reunion = %s",
        (id_reunion,))
    conn.commit()


def finalizar_reunion(conn, id_reunion):
    """Cambia estado a Finalizada."""
    execute(conn,
        "UPDATE reunion SET estado = 'Finalizada' WHERE id_reunion = %s",
        (id_reunion,))
    conn.commit()

def obtener_ultima_reunion_id(conn, id_estudiante):
    row = fetch_one(conn, "SELECT MAX(id_reunion) AS id FROM reunion WHERE id_estudiante = %s", (id_estudiante,))
    return row["id"] if row else None


def actualizar_tema_reunion(conn, id_reunion, tema):
    execute(conn, "UPDATE reunion SET tema = %s WHERE id_reunion = %s", (tema, id_reunion))
    conn.commit()


# =====================================================================
# RESENIAS
# =====================================================================

def crear_resena(conn, id_estudiante, id_tutor, id_materia, calificacion, texto=None):
    """Crea una resena. El trigger actualiza calif_promedio del tutor."""
    cursor = execute(conn, """
        INSERT INTO resena (id_estudiante, id_tutor, id_materia, calificacion, texto)
        VALUES (%s, %s, %s, %s, %s)
    """, (id_estudiante, id_tutor, id_materia, calificacion, texto))
    conn.commit()
    return cursor.lastrowid  


def obtener_resenas_tutor(conn, id_tutor):
    return fetch_all(conn, """
        SELECT r.*, u.nombre AS estudiante_nombre, m.nombre AS materia_nombre
        FROM resena r
        JOIN usuario u ON r.id_estudiante = u.id_usuario
        JOIN materia m ON r.id_materia = m.id_materia
        WHERE r.id_tutor = %s
        ORDER BY r.id_resena DESC
    """, (id_tutor,))


# =====================================================================
# BANEOS
# =====================================================================

def obtener_baneos_usuario(conn, id_usuario):
    return fetch_all(conn, """
        SELECT * FROM baneos
        WHERE id_usuario = %s
        ORDER BY fecha_inicio DESC
    """, (id_usuario,))


def crear_baneo(conn, id_usuario, motivo, fecha_inicio, fecha_fin):
    execute(conn, """
        INSERT INTO baneos (id_usuario, motivo, fecha_inicio, fecha_fin)
        VALUES (%s, %s, %s, %s)
    """, (id_usuario, motivo, fecha_inicio, fecha_fin))
    conn.commit()


# =====================================================================
# MOVIMIENTOS DE TOKENS
# =====================================================================

def obtener_movimientos_usuario(conn, id_usuario):
    return fetch_all(conn, """
        SELECT * FROM movimiento_token
        WHERE id_usuario = %s
        ORDER BY fecha DESC
    """, (id_usuario,))


def obtener_historial_tokens(conn, id_usuario, limite=20):
    return fetch_all(conn, """
        SELECT * FROM movimiento_token
        WHERE id_usuario = %s
        ORDER BY fecha DESC
        LIMIT %s
    """, (id_usuario, limite))


# =====================================================================
# ADMIN / METRICAS
# =====================================================================

def obtener_estadisticas_generales(conn):
    stats = {}
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM usuario")
    stats['total_usuarios'] = row['total'] if row else 0
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM tutor")
    stats['total_tutores'] = row['total'] if row else 0
    row = fetch_one(conn, """
        SELECT COUNT(*) AS total FROM reunion WHERE estado = 'Finalizada'
    """)
    stats['total_reuniones_finalizadas'] = row['total'] if row else 0
    row = fetch_one(conn, """
        SELECT COALESCE(SUM(tokens_cobrados), 0) AS total
        FROM reunion WHERE estado = 'Finalizada'
    """)
    stats['total_tokens_movidos'] = row['total'] if row else 0
    row = fetch_one(conn, """
        SELECT COUNT(*) AS total FROM baneos
        WHERE NOW() BETWEEN fecha_inicio AND fecha_fin
    """)
    stats['baneos_activos'] = row['total'] if row else 0
    return stats
