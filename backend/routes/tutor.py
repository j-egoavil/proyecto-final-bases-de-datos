from flask import Blueprint, request, redirect, url_for, session, flash, render_template
from backend.db.connection import get_db, close_db
from backend.db.queries import (
    postular_tutor,
    crear_servicio,
    obtener_servicios_por_tutor,
    obtener_materias
)

tutor_bp = Blueprint("tutor", __name__)

@tutor_bp.route("/postular", methods=["GET", "POST"])
def postular():
    if "user_id" not in session:
        flash("Inicia sesión para postularte como tutor.", "warning")
        return redirect(url_for("auth.login"))

    conn = get_db()
    try:
        if request.method == "POST":
            id_usuario = session["user_id"]
            descripcion = request.form.get("descripcion")
            

            id_materia = request.form.get("id_materia")
            nota = request.form.get("nota")

            materias_aprobadas = []
            if id_materia and nota:
                materias_aprobadas.append({
                    "id_materia": int(id_materia), 
                    "nota": float(nota)
                })

        
            postular_tutor(conn, id_usuario, descripcion, materias_aprobadas)
            
            flash("¡Te has postulado como tutor con éxito!", "success")
            return redirect(url_for("usuario.dashboard"))

        materias = obtener_materias(conn)
    finally:
        close_db(conn)

    return render_template("tutor/postular.html", materias=materias)


@tutor_bp.route("/crear-servicio", methods=["GET", "POST"])
def crear_nuevo_servicio():
    if "user_id" not in session:
        flash("Inicia sesión para crear un servicio.", "warning")
        return redirect(url_for("auth.login"))

    id_tutor = session["user_id"]
    conn = get_db()
    
    try:
        if request.method == "POST":
            id_materia = request.form.get("id_materia")
            nombre = request.form.get("nombre")
            precio_tokens = request.form.get("precio_tokens")
            modalidad = request.form.get("modalidad") # Virtual / Presencial
            descripcion = request.form.get("descripcion")


            crear_servicio(
                conn, 
                id_tutor=id_tutor, 
                id_materia=int(id_materia), 
                nombre=nombre, 
                precio_tokens=int(precio_tokens), 
                modalidad=modalidad, 
                descripcion=descripcion
            )

            flash("¡Servicio creado exitosamente!", "success")
            return redirect(url_for("tutor.mis_servicios"))

        materias = obtener_materias(conn)
    finally:
        close_db(conn)

    return render_template("tutor/crear_servicio.html", materias=materias)


@tutor_bp.route("/mis-servicios", methods=["GET"])
def mis_servicios():
    if "user_id" not in session:
        flash("Inicia sesión para ver tus servicios.", "warning")
        return redirect(url_for("auth.login"))

    id_tutor = session["user_id"]
    conn = get_db()
    try:

        servicios = obtener_servicios_por_tutor(conn, id_tutor)
    finally:
        close_db(conn)

    return render_template("tutor/mis_servicios.html", servicios=servicios)