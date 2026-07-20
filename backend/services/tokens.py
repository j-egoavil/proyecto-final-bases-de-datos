def crear_transferencia(conn, id_usuario, tipo, cantidad, id_reunion=None):
    """Registra un movimiento de tokens (ingreso/egreso)."""
    pass


def obtener_saldo(conn, id_usuario):
    """SUM(ingresos) - SUM(egresos) para un usuario."""
    pass


def inicializar_tokens(conn, id_usuario, cantidad_inicial=50):
    """Otorga tokens iniciales a un usuario nuevo."""
    pass