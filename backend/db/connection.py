import mysql.connector
from backend.config import DB_CONFIG


def get_db():
    """Retorna una conexion a la base de datos MySQL."""
    conn = mysql.connector.connect(**DB_CONFIG)
    return conn


def close_db(conn):
    """Cierra la conexion si esta abierta."""
    if conn and conn.is_connected():
        conn.close()