import mysql.connector
from datetime import datetime, date

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
    agendar_reunion,                 
    obtener_ultima_reunion_id,       
    actualizar_tema_reunion,
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
        try:  
            crear_resena(
                conn,
                id_estudiante=reunion["id_estudiante"],
                id_tutor=reunion["id_tutor"],
                id_materia=servicio["id_materia"],
                calificacion=calificacion,
                texto=texto,
            )
            flash("Resena enviada correctamente", "success")
        except mysql.connector.IntegrityError:
            conn.rollback()
            flash("Ya dejaste una reseña para este tutor en esta materia.", "warning")
    finally:
        close_db(conn)

    return redirect(url_for("reuniones.mis_reuniones"))

@reuniones_bp.route("/agendar/<int:id_servicio>", methods=["GET", "POST"])
def agendar(id_servicio):
    if not _login_required():
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        servicio = obtener_servicio_por_id(conn, id_servicio)
        if not servicio:
            flash("Servicio no encontrado", "error")
            return redirect(url_for("servicios.buscar"))

        if session["id_usuario"] == servicio["id_tutor"]:
            flash("No puedes agendar una tutoría contigo mismo.", "error")
            return redirect(url_for("servicios.detalle", id_servicio=id_servicio))

        if request.method == "POST":
            fecha = request.form.get("fecha")
            hora_inicio = request.form.get("hora_inicio")
            hora_fin = request.form.get("hora_fin")
            tema = request.form.get("tema") or None

            fecha_hora_inicio = datetime.strptime(f"{fecha} {hora_inicio}", "%Y-%m-%d %H:%M")

            if fecha_hora_inicio <= datetime.now():
                flash("No puedes agendar una tutoría en una fecha u hora que ya pasó.", "error")
                return render_template("reuniones/agendar.html", servicio=servicio, hoy=date.today().isoformat())

            try:
                agendar_reunion(
                    conn,
                    id_estudiante=session["id_usuario"],
                    id_tutor=servicio["id_tutor"],
                    id_servicio=id_servicio,
                    fecha=fecha,
                    hora_inicio=hora_inicio,
                    hora_fin=hora_fin,
                )
                if tema:
                    id_reunion = obtener_ultima_reunion_id(conn, session["id_usuario"])
                    if id_reunion:
                        actualizar_tema_reunion(conn, id_reunion, tema)

                flash("¡Tutoría agendada con éxito!", "success")
                return redirect(url_for("reuniones.mis_reuniones"))
            except mysql.connector.Error as e:
                flash(f"No se pudo agendar: {e.msg}", "error")
    finally:
        close_db(conn)

    return render_template("reuniones/agendar.html", servicio=servicio, hoy=date.today().isoformat())