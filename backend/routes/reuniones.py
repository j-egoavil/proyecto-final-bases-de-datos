from datetime import date

from flask import Blueprint, render_template, request, redirect, url_for, session, flash

from backend.db.connection import get_db, close_db
from backend.db.queries import (
    obtener_reuniones_estudiante,
    obtener_reuniones_tutor,
    obtener_reunion_por_id,
    cancelar_reunion,
    finalizar_reunion,
    crear_resena,
    obtener_servicio_por_id,
)

reuniones_bp = Blueprint("reuniones", __name__)


def _login_required():
    if not session.get("id_usuario"):
        flash("Debes iniciar sesion para acceder", "error")
        return False
    return True


@reuniones_bp.route("/mis-reuniones")
def mis_reuniones():
    if not _login_required():
        return redirect(url_for("auth.login"))

    id_usuario = session["id_usuario"]
    rol = session.get("rol", "")

    conn = get_db()
    try:
        if rol.lower() == "tutor":
            reuniones = obtener_reuniones_tutor(conn, id_usuario)
            pendientes = obtener_reuniones_tutor(conn, id_usuario, solo_pendientes=True)
        else:
            reuniones = obtener_reuniones_estudiante(conn, id_usuario)
            pendientes = obtener_reuniones_estudiante(conn, id_usuario, solo_pendientes=True)
    finally:
        close_db(conn)

    return render_template(
        "reuniones/mis-reuniones.html",
        reuniones=reuniones,
        pendientes=pendientes,
        hoy=date.today(),
    )


@reuniones_bp.route("/<int:id_reunion>/cancelar", methods=["POST"])
def cancelar(id_reunion):
    if not _login_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        reunion = obtener_reunion_por_id(conn, id_reunion)
        if not reunion:
            flash("Reunion no encontrada", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if reunion["estado"] != "Agendada":
            flash("Solo se pueden cancelar reuniones en estado Agendada", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        id_usuario = session["id_usuario"]
        if id_usuario not in (reunion["id_estudiante"], reunion["id_tutor"]):
            flash("No tienes permiso para cancelar esta reunion", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        cancelar_reunion(conn, id_reunion)
        flash("Reunion cancelada. Los tokens seran reembolsados automaticamente.", "success")
    finally:
        close_db(conn)

    return redirect(url_for("reuniones.mis_reuniones"))


@reuniones_bp.route("/<int:id_reunion>/finalizar", methods=["POST"])
def finalizar(id_reunion):
    if not _login_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        reunion = obtener_reunion_por_id(conn, id_reunion)
        if not reunion:
            flash("Reunion no encontrada", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if reunion["estado"] != "Agendada":
            flash("Solo se pueden finalizar reuniones en estado Agendada", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if session.get("rol", "").lower() != "tutor":
            flash("Solo el tutor puede finalizar una reunion", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        finalizar_reunion(conn, id_reunion)
        flash("Reunion finalizada con exito", "success")
    finally:
        close_db(conn)

    return redirect(url_for("reuniones.mis_reuniones"))


@reuniones_bp.route("/<int:id_reunion>/resenar", methods=["POST"])
def resenar(id_reunion):
    if not _login_required():
        return redirect(url_for("auth.login"))

    calificacion = request.form.get("calificacion", type=float)
    texto = request.form.get("texto") or None

    conn = get_db()
    try:
        reunion = obtener_reunion_por_id(conn, id_reunion)
        if not reunion:
            flash("Reunion no encontrada", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if reunion["estado"] != "Finalizada":
            flash("Solo se pueden resenar reuniones finalizadas", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if session["id_usuario"] != reunion["id_estudiante"]:
            flash("Solo el estudiante puede dejar una resena", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        if not calificacion or not (1 <= calificacion <= 5):
            flash("La calificacion debe ser entre 1 y 5", "error")
            return redirect(url_for("reuniones.mis_reuniones"))

        servicio = obtener_servicio_por_id(conn, reunion["id_servicio"])
        crear_resena(
            conn,
            id_estudiante=reunion["id_estudiante"],
            id_tutor=reunion["id_tutor"],
            id_materia=servicio["id_materia"],
            calificacion=calificacion,
            texto=texto,
        )
        flash("Resena enviada correctamente", "success")
    finally:
        close_db(conn)

    return redirect(url_for("reuniones.mis_reuniones"))