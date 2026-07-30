from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from backend.db.connection import get_db, close_db
from backend.db.queries import (
    obtener_usuario_por_id,
    actualizar_perfil,
    obtener_reuniones_estudiante,
    obtener_saldo,
    obtener_historial_tokens,   
)

usuario_bp = Blueprint("usuario", __name__)


@usuario_bp.route("/dashboard")
def dashboard():
    if "id_usuario" not in session:  
        flash("Por favor inicia sesión primero.", "warning")
        return redirect(url_for("auth.login"))

    id_usuario = session["id_usuario"]  
    conn = get_db()
    try:
        usuario = obtener_usuario_por_id(conn, id_usuario)
        saldo = obtener_saldo(conn, id_usuario)
        
        reuniones = obtener_reuniones_estudiante(conn, id_usuario, solo_pendientes=True)
        
        reuniones = sorted(reuniones, key=lambda r: (r["fecha"], r["hora_inicio"]))
    finally:
        close_db(conn)

    return render_template(
        "usuario/dashboard.html",
        usuario=usuario,
        saldo=saldo,
        reuniones=reuniones,
    )


@usuario_bp.route("/perfil", methods=["GET", "POST"])
def perfil():
    if "id_usuario" not in session:  
        flash("Por favor inicia sesión primero.", "warning")
        return redirect(url_for("auth.login"))

    id_usuario = session["id_usuario"]  
    conn = get_db()

    try:
        if request.method == "POST":
            nombre = request.form.get("nombre")
            area = request.form.get("area")

            actualizar_perfil(conn, id_usuario, nombre=nombre, area=area)

            session["nombre"] = nombre  
            if area:
                session["area"] = area

            flash("¡Perfil actualizado con éxito!", "success")
            return redirect(url_for("usuario.perfil"))

        usuario = obtener_usuario_por_id(conn, id_usuario)
        historial = obtener_historial_tokens(conn, id_usuario, limite=15)  
    finally:
        close_db(conn)

    return render_template("usuario/perfil.html", usuario=usuario, historial=historial)