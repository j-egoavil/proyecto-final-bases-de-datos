import mysql.connector
from flask import Blueprint, request, redirect, url_for, session, flash, render_template
from backend.db.connection import get_db, close_db
from backend.db.queries import (
    postular_tutor,
    crear_servicio,
    obtener_servicios_por_tutor,
    obtener_materias,
    obtener_materias_tutor,               
    obtener_perfil_tutor_completo,         
)
from backend.db.queries import agregar_materia_tutor  

tutor_bp = Blueprint("tutor", __name__)


@tutor_bp.route("/postular", methods=["GET", "POST"])
def postular():
    if "id_usuario" not in session:
        flash("Inicia sesión para postularte como tutor.", "warning")
        return redirect(url_for("auth.login"))

    id_usuario = session["id_usuario"]
    conn = get_db()
    try:
        if obtener_perfil_tutor_completo(conn, id_usuario):
            flash("Ya estás registrado como tutor.", "success")
            return redirect(url_for("tutor.mis_servicios"))

        if request.method == "POST":
            descripcion = request.form.get("descripcion")
            materia_ids = request.form.getlist("id_materia[]")  
            notas = request.form.getlist("nota[]")              

            materias_aprobadas = []
            for id_materia, nota in zip(materia_ids, notas):
                if not id_materia or not nota:
                    continue
                nota_float = float(nota)
                if nota_float < 4.0:
                    flash(
                        f"No puedes postular una materia con nota menor a 4.0 "
                        f"(ingresaste {nota_float}).",
                        "error",
                    )
                    materias = obtener_materias(conn)
                    return render_template("tutor/postular.html", materias=materias)
                materias_aprobadas.append({"id_materia": int(id_materia), "nota": nota_float})

            if not materias_aprobadas:
                flash("Debes agregar al menos una materia aprobada.", "error")
                materias = obtener_materias(conn)
                return render_template("tutor/postular.html", materias=materias)

            try:
                postular_tutor(conn, id_usuario, descripcion, materias_aprobadas)
            except mysql.connector.Error as e:
                conn.rollback()
                flash(f"No se pudo completar la postulación: {e.msg}", "error")
                materias = obtener_materias(conn)
                return render_template("tutor/postular.html", materias=materias)

            session["rol"] = "tutor"
            flash("¡Te has postulado como tutor con éxito!", "success")
            return redirect(url_for("tutor.mis_servicios"))

        materias = obtener_materias(conn)
    finally:
        close_db(conn)

    return render_template("tutor/postular.html", materias=materias)


@tutor_bp.route("/crear-servicio", methods=["GET", "POST"])
def crear_nuevo_servicio():
    if "id_usuario" not in session:  
        flash("Inicia sesión para crear un servicio.", "warning")
        return redirect(url_for("auth.login"))

    id_tutor = session["id_usuario"]  
    conn = get_db()

    try:
        # verificar que el usuario ya sea tutor antes de dejarlo crear un servicio
        if not obtener_perfil_tutor_completo(conn, id_tutor):
            flash("Primero debes postularte como tutor.", "warning")
            return redirect(url_for("tutor.postular"))

        materias_tutor = obtener_materias_tutor(conn, id_tutor)  

        if request.method == "POST":
            id_materia = request.form.get("id_materia")
            nombre = request.form.get("nombre")
            precio_tokens = request.form.get("precio_tokens")
            modalidad = request.form.get("modalidad")
            descripcion = request.form.get("descripcion")

            try:  
                crear_servicio(
                    conn,
                    id_tutor=id_tutor,
                    id_materia=int(id_materia),
                    nombre=nombre,
                    precio_tokens=int(precio_tokens),
                    modalidad=modalidad,
                    descripcion=descripcion,
                )
                flash("¡Servicio creado exitosamente!", "success")
                return redirect(url_for("tutor.mis_servicios"))
            except mysql.connector.Error as e:
                conn.rollback()
                flash(f"No se pudo crear el servicio: {e.msg}", "error")
    finally:
        close_db(conn)

    return render_template("tutor/crear_servicio.html", materias=materias_tutor)


@tutor_bp.route("/mis-servicios", methods=["GET"])
def mis_servicios():
    if "id_usuario" not in session:  
        flash("Inicia sesión para ver tus servicios.", "warning")
        return redirect(url_for("auth.login"))

    id_tutor = session["id_usuario"]  
    conn = get_db()
    try:
        perfil = obtener_perfil_tutor_completo(conn, id_tutor)  
        if not perfil:
            flash("Primero debes postularte como tutor.", "warning")
            return redirect(url_for("tutor.postular"))

        servicios = obtener_servicios_por_tutor(conn, id_tutor)
    finally:
        close_db(conn)

    return render_template("tutor/mis_servicios.html", perfil=perfil, servicios=servicios)

@tutor_bp.route("/agregar-materia", methods=["GET", "POST"])
def agregar_materia():
    if "id_usuario" not in session:
        flash("Inicia sesión para continuar.", "warning")
        return redirect(url_for("auth.login"))

    id_tutor = session["id_usuario"]
    conn = get_db()
    try:
        if not obtener_perfil_tutor_completo(conn, id_tutor):
            flash("Primero debes postularte como tutor.", "warning")
            return redirect(url_for("tutor.postular"))

        if request.method == "POST":
            id_materia = request.form.get("id_materia", type=int)
            nota = request.form.get("nota", type=float)

            if nota is None or nota < 4.0:
                flash("La nota debe ser mayor o igual a 4.0.", "error")
                materias = obtener_materias(conn)
                return render_template("tutor/agregar_materia.html", materias=materias)

            try:
                agregar_materia_tutor(conn, id_tutor, id_materia, nota)
                flash("Materia agregada con éxito.", "success")
                return redirect(url_for("tutor.mis_servicios"))
            except mysql.connector.Error as e:
                conn.rollback()
                # Esto captura sobre todo uq_mat_tutor: intentar agregar la misma materia dos veces
                flash(f"No se pudo agregar la materia: {e.msg}", "error")

        materias = obtener_materias(conn)
    finally:
        close_db(conn)

    return render_template("tutor/agregar_materia.html", materias=materias)