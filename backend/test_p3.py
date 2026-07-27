"""Script de prueba para verificar capa de datos (P3)."""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.db.connection import get_db, close_db, fetch_one, fetch_all
from backend.db.queries import (
    obtener_usuario_por_email, obtener_usuario_por_id, obtener_saldo,
    obtener_servicios, obtener_servicio_por_id, obtener_materias,
    obtener_reuniones_estudiante, obtener_estadisticas_generales,
    obtener_desempeno_tutores, obtener_resumen_estudiante,
)
from backend.services.tokens import obtener_saldo as svc_saldo, puede_pagar
from backend.services.validaciones import usuario_baneado, es_tutor, obtener_baneos_activos
from backend.models import User

errores = 0

def check(desc, ok):
    global errores
    status = "OK" if ok else "FALLO"
    if not ok:
        errores += 1
    print(f"  [{status}] {desc}")

print("=== Pruebas Capa de Datos (P3) ===\n")

conn = get_db()
try:
    # 1. Conexion + tablas pobladas
    print("1. Conexion y datos:")
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM usuario")
    check(f"usuarios: {row['total']}", row['total'] > 0)
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM tutor")
    check(f"tutores: {row['total']}", row['total'] > 0)
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM servicio")
    check(f"servicios: {row['total']}", row['total'] > 0)
    row = fetch_one(conn, "SELECT COUNT(*) AS total FROM reunion")
    check(f"reuniones: {row['total']}", row['total'] > 0)

    # 2. Queries de usuario
    print("\n2. Queries de usuario:")
    user_row = obtener_usuario_por_email(conn, "usuario_21@unal.edu.co")
    check(f"obtener_usuario_por_email: {user_row is not None}", user_row is not None)
    if user_row:
        uid = user_row['id_usuario']
        check(f"nombre={user_row['nombre']}", user_row['nombre'] == 'Mateo Flores')
        user2 = obtener_usuario_por_id(conn, uid)
        check(f"obtener_usuario_por_id coincide", user2 is not None)
        saldo = obtener_saldo(conn, uid)
        check(f"obtener_saldo retorna int", isinstance(saldo, int))
        resumen = obtener_resumen_estudiante(conn, uid)
        check(f"vw_resumen_estudiante existe", resumen is not None)

    # 3. Modelo User
    print("\n3. Modelo User (Flask-Login):")
    if user_row:
        u = User(user_row)
        check(f"User.id = {u.id}", u.id == uid)
        check(f"User.nombre = {u.nombre}", u.nombre == 'Mateo Flores')
        check(f"User.es_estudiante()", u.es_estudiante())
        check(f"User.is_authenticated (UserMixin)", u.is_authenticated)
        check(f"User.get_id() = '{u.get_id()}'", u.get_id() == str(uid))

    # 4. Queries de servicios
    print("\n4. Queries de servicios:")
    servicios = obtener_servicios(conn)
    check(f"obtener_servicios retorna {len(servicios)}", len(servicios) > 0)
    if servicios:
        s = obtener_servicio_por_id(conn, servicios[0]['id_servicio'])
        check(f"obtener_servicio_por_id: {s is not None}", s is not None)
        check(f"tiene tutor_nombre", 'tutor_nombre' in s)
        check(f"tiene materia_nombre", 'materia_nombre' in s)

    # 5. Queries con filtros
    print("\n5. Queries con filtros:")
    materias = obtener_materias(conn)
    check(f"obtener_materias: {len(materias)}", len(materias) > 0)
    if materias:
        s_filtrados = obtener_servicios(conn, id_materia=materias[0]['id_materia'])
        check(f"servicios filtrados por materia: {len(s_filtrados)}", isinstance(s_filtrados, list))

    # 6. Reuniones y metricas
    print("\n6. Reuniones y metricas:")
    stats = obtener_estadisticas_generales(conn)
    check(f"total_usuarios={stats['total_usuarios']}", stats['total_usuarios'] > 0)
    check(f"total_tutores={stats['total_tutores']}", stats['total_tutores'] > 0)
    tutores_desp = obtener_desempeno_tutores(conn)
    check(f"vw_desempeno_tutores: {len(tutores_desp)}", len(tutores_desp) > 0)

    # 7. Servicio tokens
    print("\n7. Servicio tokens:")
    if user_row:
        saldo_svc = svc_saldo(uid)
        check(f"svc saldo={saldo_svc}", isinstance(saldo_svc, int))
        check(f"puede_pagar(10) = {puede_pagar(uid, 10)}", isinstance(puede_pagar(uid, 10), bool))

    # 8. Servicio validaciones
    print("\n8. Servicio validaciones:")
    if user_row:
        check(f"usuario_baneado retorna bool", isinstance(usuario_baneado(uid), bool))
    baneos = obtener_baneos_activos()
    check(f"obtener_baneos_activos: {len(baneos)} baneos", isinstance(baneos, list))

finally:
    close_db(conn)

print(f"\n=== Resultado: {errores} errores ===")