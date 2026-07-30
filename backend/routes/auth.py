from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash

from backend.db.connection import get_db, close_db
from backend.db.queries import obtener_usuario_por_email, registrar_usuario_completo

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")

        conn = get_db()
        try:
            usuario = obtener_usuario_por_email(conn, email)
        finally:
            close_db(conn)

        if usuario and usuario["password"] == password:
            session["id_usuario"] = usuario["id_usuario"]
            session["nombre"] = usuario["nombre"]
            session["rol"] = usuario["rol"]
            session["saldo_tokens"] = usuario["saldo_tokens"]
            flash("Bienvenido de nuevo", "success")
            return redirect(url_for("servicios.buscar"))

        flash("Email o contraseña incorrectos", "error")

    return render_template("auth/login.html")


@auth_bp.route("/registro", methods=["GET", "POST"])
def registro():
    if request.method == "POST":
        nombre = request.form.get("nombre")
        email = request.form.get("email")
        password = request.form.get("password")
        area = request.form.get("area")
        semestre = request.form.get("semestre")

        conn = get_db()
        try:
            if obtener_usuario_por_email(conn, email):
                flash("Ya existe una cuenta con ese email", "error")
                return render_template("auth/registro.html")

            id_usuario = registrar_usuario_completo(
                conn, nombre, email, password, area, int(semestre)
            )
        finally:
            close_db(conn)

        session["id_usuario"] = id_usuario
        session["nombre"] = nombre
        session["rol"] = "Estudiante"
        session["saldo_tokens"] = 15  # otorgados por pr_asignar_datos_usuario

        flash("Cuenta creada. ¡Bienvenido!", "success")
        return redirect(url_for("servicios.buscar"))

    return render_template("auth/registro.html")


@auth_bp.route("/logout")
def logout():
    session.clear()
    flash("Sesión cerrada", "success")
    return redirect(url_for("auth.login"))
