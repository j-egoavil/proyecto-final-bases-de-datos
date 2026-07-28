from backend.db.connection import fetch_one, call_proc


def obtener_saldo(id_usuario):
    """Retorna el saldo actual de tokens del usuario desde la tabla usuario."""
    from backend.db.connection import get_db, close_db
    conn = get_db()
    try:
        row = fetch_one(conn,
            "SELECT saldo_tokens FROM usuario WHERE id_usuario = %s",
            (id_usuario,))
        return row['saldo_tokens'] if row else 0
    finally:
        close_db(conn)


def puede_pagar(id_usuario, precio):
    """Verifica si el usuario tiene saldo suficiente para pagar."""
    return obtener_saldo(id_usuario) >= precio


def verificar_saldo_servicio(id_estudiante, id_servicio):
    """Usa la funcion almacenada fn_verificar_saldo_estudiante."""
    from backend.db.connection import get_db, close_db, fetch_one
    conn = get_db()
    try:
        row = fetch_one(conn,
            "SELECT u_linker.fn_verificar_saldo_estudiante(%s, %s) AS resultado",
            (id_estudiante, id_servicio))
        return bool(row['resultado']) if row else False
    finally:
        close_db(conn)


def obtener_movimientos(id_usuario, limite=20):
    """Historial de movimientos de tokens del usuario."""
    from backend.db.connection import get_db, close_db, fetch_all
    conn = get_db()
    try:
        return fetch_all(conn, """
            SELECT id_movimiento, cantidad, fecha
            FROM movimiento_token
            WHERE id_usuario = %s
            ORDER BY fecha DESC
            LIMIT %s
        """, (id_usuario, limite))
    finally:
        close_db(conn)


def obtener_balance_historico():
    """Evolucion historica del flujo de tokens (para dashboard admin)."""
    from backend.db.connection import get_db, close_db, fetch_all
    conn = get_db()
    try:
        return fetch_all(conn, """
            SELECT DATE(fecha) AS fecha,
                   SUM(cantidad) AS balance_diario,
                   SUM(SUM(cantidad)) OVER (ORDER BY DATE(fecha)) AS acumulado
            FROM movimiento_token
            GROUP BY DATE(fecha)
            ORDER BY fecha ASC
        """)
    finally:
        close_db(conn)