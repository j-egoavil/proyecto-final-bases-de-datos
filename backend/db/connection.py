import mysql.connector
from mysql.connector import pooling
from backend.config import DB_CONFIG

_pool = None


def _get_pool():
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(
            pool_name="u_linker_pool",
            pool_size=5,
            **DB_CONFIG
        )
    return _pool


def get_db():
    """Retorna una conexion del pool con cursor de diccionario."""
    conn = _get_pool().get_connection()
    return conn


def close_db(conn):
    """Cierra la conexion si esta abierta."""
    if conn and conn.is_connected():
        conn.close()


def fetch_one(conn, query, params=None):
    """Ejecuta query y retorna un solo registro como diccionario."""
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, params or ())
    row = cursor.fetchone()
    cursor.close()
    return row


def fetch_all(conn, query, params=None):
    """Ejecuta query y retorna todos los registros como lista de diccionarios."""
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, params or ())
    rows = cursor.fetchall()
    cursor.close()
    return rows


def execute(conn, query, params=None):
    """Ejecuta INSERT/UPDATE/DELETE y retorna el cursor."""
    cursor = conn.cursor()
    cursor.execute(query, params or ())
    cursor.close()
    return cursor


def call_proc(conn, proc_name, args=None):
    """Llama a un stored procedure y retorna el cursor."""
    cursor = conn.cursor()
    cursor.callproc(proc_name, args or ())
    cursor.close()
    return cursor