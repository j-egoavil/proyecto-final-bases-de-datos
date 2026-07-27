from datetime import date
from backend.db.connection import fetch_one, fetch_all


def usuario_baneado(id_usuario, fecha=None):
    """Retorna True si el usuario tiene un baneo activo en la fecha dada (hoy por defecto)."""
    from backend.db.connection import get_db, close_db
    if fecha is None:
        fecha = date.today()

    conn = get_db()
    try:
        row = fetch_one(conn,
            "SELECT u_linker.fn_es_usuario_baneado(%s, %s) AS resultado",
            (id_usuario, fecha))
        return bool(row['resultado']) if row else False
    finally:
        close_db(conn)


def puede_ser_tutor(id_usuario, id_materia):
    """Verifica que el usuario tenga la materia aprobada con nota >= 4.0."""
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        row = fetch_one(conn, """
            SELECT id, nota FROM materia_aprobada_tutor
            WHERE id_tutor = %s AND id_materia = %s
        """, (id_usuario, id_materia))
        return row is not None and row['nota'] >= 4.0
    finally:
        close_db(conn)


def es_tutor(id_usuario):
    """Verifica si el usuario ya esta registrado como tutor."""
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        row = fetch_one(conn,
            "SELECT id_tutor FROM tutor WHERE id_tutor = %s", (id_usuario,))
        return row is not None
    finally:
        close_db(conn)


def prerrequisito_aprobado(id_estudiante, id_materia):
    """
    Verifica si el estudiante cumple el prerrequisito de la materia.
    Si la materia no tiene prerrequisito, retorna True.
    Si tiene prerrequisito, verifica que el estudiante tenga una resena
    o una materia_aprobada_tutor que demuestre que ya la curso.
    """
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        materia = fetch_one(conn,
            "SELECT id_prerequisito FROM materia WHERE id_materia = %s",
            (id_materia,))
        if not materia or materia['id_prerequisito'] is None:
            return True

        id_pre = materia['id_prerequisito']
        aprobo = fetch_one(conn, """
            SELECT 1 FROM materia_aprobada_tutor
            WHERE id_tutor = %s AND id_materia = %s
        """, (id_estudiante, id_pre))
        return aprobo is not None
    finally:
        close_db(conn)


def obtener_baneos_activos():
    """Lista todos los baneos activos en este momento."""
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        return fetch_all(conn, """
            SELECT b.*, u.nombre, u.email
            FROM baneos b
            JOIN usuario u ON b.id_usuario = u.id_usuario
            WHERE NOW() BETWEEN b.fecha_inicio AND b.fecha_fin
            ORDER BY b.fecha_fin
        """)
    finally:
        close_db(conn)


def materias_disponibles_para_tutor(id_usuario):
    """
    Retorna las materias en las que el usuario puede ser tutor
    (nota >= 4.0 registrada en materia_aprobada_tutor).
    """
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        return fetch_all(conn, """
            SELECT m.id_materia, m.nombre, m.creditos, mat.nota
            FROM materia_aprobada_tutor mat
            JOIN materia m ON mat.id_materia = m.id_materia
            WHERE mat.id_tutor = %s AND mat.nota >= 4.0
            ORDER BY m.nombre
        """, (id_usuario,))
    finally:
        close_db(conn)