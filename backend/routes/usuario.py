from flask import Blueprint

usuario_bp = Blueprint("usuario", __name__)


@usuario_bp.route("/dashboard")
def dashboard():
    return "Dashboard del usuario"


@usuario_bp.route("/perfil")
def perfil():
    return "Perfil del usuario"