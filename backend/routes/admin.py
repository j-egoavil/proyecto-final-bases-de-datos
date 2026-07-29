from datetime import date, datetime

from flask import Blueprint, render_template, request, redirect, url_for, session, flash

from backend.db.connection import get_db, close_db
from backend.db.queries import (
    obtener_estadisticas_generales,
    obtener_desempeno_tutores,
    obtener_baneos_usuario,
    crear_baneo,
    obtener_estudiantes,
    obtener_tutores,
)
from backend.services.tokens import obtener_balance_historico

admin_bp = Blueprint("admin", __name__)


def _admin_required():
    if not session.get("id_usuario"):
        flash("Debes iniciar sesion como administrador", "error")
        return False
    if session.get("rol", "").lower() != "admin":
        flash("Acceso restringido a administradores", "error")
        return False
    return True


@admin_bp.route("/dashboard")
def dashboard():
    if not _admin_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        estadisticas = obtener_estadisticas_generales(conn)
        desempeno = obtener_desempeno_tutores(conn)
        balance = obtener_balance_historico(conn)
        baneos = _obtener_baneos_activos(conn)
    finally:
        close_db(conn)

    return render_template(
        "admin/dashboard.html",
        estadisticas=estadisticas,
        desempeno=desempeno,
        balance=balance,
        baneos=baneos,
    )


@admin_bp.route("/baneos")
def baneos():
    if not _admin_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        baneos_activos = _obtener_baneos_activos(conn)
        estudiantes = obtener_estudiantes(conn)
        tutores_list = obtener_tutores(conn)
    finally:
        close_db(conn)

    return render_template(
        "admin/baneos.html",
        baneos=baneos_activos,
        estudiantes=estudiantes,
        tutores=tutores_list,
    )


@admin_bp.route("/baneos/crear", methods=["POST"])
def crear_baneo_route():
    if not _admin_required():
        return redirect(url_for("auth.login"))

    id_usuario = request.form.get("id_usuario", type=int)
    motivo = request.form.get("motivo")
    fecha_inicio = request.form.get("fecha_inicio")
    fecha_fin = request.form.get("fecha_fin")

    if not all([id_usuario, motivo, fecha_inicio, fecha_fin]):
        flash("Todos los campos son obligatorios", "error")
        return redirect(url_for("admin.baneos"))

    if fecha_inicio > fecha_fin:
        flash("La fecha de fin no puede ser anterior a la de inicio", "error")
        return redirect(url_for("admin.baneos"))

    conn = get_db()
    try:
        crear_baneo(conn, id_usuario, motivo, fecha_inicio, fecha_fin)
        flash("Baneo aplicado correctamente", "success")
    except Exception as e:
        flash(f"Error al crear baneo: {e}", "error")
    finally:
        close_db(conn)

    return redirect(url_for("admin.baneos"))


@admin_bp.route("/baneos/<int:id_usuario>/levantar", methods=["POST"])
def levantar_baneo(id_usuario):
    if not _admin_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        from backend.db.connection import execute
        execute(conn, """
            UPDATE baneos
            SET fecha_fin = NOW()
            WHERE id_usuario = %s
              AND NOW() BETWEEN fecha_inicio AND fecha_fin
        """, (id_usuario,))
        conn.commit()
        flash("Baneo levantado correctamente", "success")
    except Exception as e:
        flash(f"Error al levantar baneo: {e}", "error")
    finally:
        close_db(conn)

    return redirect(url_for("admin.baneos"))


def _obtener_baneos_activos(conn):
    from backend.db.connection import fetch_all
    return fetch_all(conn, """
        SELECT b.*, u.nombre, u.email
        FROM baneos b
        JOIN usuario u ON b.id_usuario = u.id_usuario
        WHERE NOW() BETWEEN b.fecha_inicio AND b.fecha_fin
        ORDER BY b.fecha_fin
    """)