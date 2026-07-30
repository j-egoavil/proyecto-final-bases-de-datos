from flask import Blueprint, render_template, request, redirect, url_for, session, flash
import mysql.connector

from backend.db.connection import get_db, close_db
from backend.db.queries import (
    obtener_servicios, obtener_materias, obtener_servicio_por_id, agendar_reunion,
)

servicios_bp = Blueprint("servicios", __name__)


@servicios_bp.route("/buscar")
def buscar():
    id_materia = request.args.get("id_materia", type=int)
    modalidad = request.args.get("modalidad") or None
    precio_max = request.args.get("precio_max", type=int)

    conn = get_db()
    try:
        materias = obtener_materias(conn)
        servicios = obtener_servicios(
            conn, id_materia=id_materia, modalidad=modalidad, precio_max=precio_max
        )
    finally:
        close_db(conn)

    return render_template(
        "servicios/buscar.html",
        materias=materias,
        servicios=servicios,
        filtros={"id_materia": id_materia, "modalidad": modalidad, "precio_max": precio_max},
    )


@servicios_bp.route("/<int:id_servicio>")
def detalle(id_servicio):
    conn = get_db()
    try:
        servicio = obtener_servicio_por_id(conn, id_servicio)
    finally:
        close_db(conn)
    return render_template("servicios/detalle.html", servicio=servicio)


@servicios_bp.route("/<int:id_servicio>/agendar", methods=["POST"])
def agendar(id_servicio):
    if not session.get("id_usuario"):
        flash("Debes iniciar sesión para agendar", "error")
        return redirect(url_for("auth.login"))

    fecha = request.form.get("fecha")
    hora_inicio = request.form.get("hora_inicio")
    hora_fin = request.form.get("hora_fin")

    conn = get_db()
    try:
        servicio = obtener_servicio_por_id(conn, id_servicio)

        # un tutor no puede agendar su propio servicio
        if session["id_usuario"] == servicio["id_tutor"]:
            flash("No puedes agendar una tutoría contigo mismo.", "error")
            return redirect(url_for("servicios.detalle", id_servicio=id_servicio))

        agendar_reunion(
            conn,
            id_estudiante=session["id_usuario"],
            id_tutor=servicio["id_tutor"],
            id_servicio=id_servicio,
            fecha=fecha,
            hora_inicio=hora_inicio,
            hora_fin=hora_fin,
        )
        flash("¡Tutoría agendada con éxito!", "success")
    except mysql.connector.Error as e:
        flash(f"No se pudo agendar: {e.msg}", "error")
    finally:
        close_db(conn)

    return redirect(url_for("servicios.detalle", id_servicio=id_servicio))