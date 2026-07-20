from flask import Blueprint

reuniones_bp = Blueprint("reuniones", __name__)


@reuniones_bp.route("/agendar")
def agendar():
    return "Agendar reunion"


@reuniones_bp.route("/<int:id_reunion>/sala")
def sala(id_reunion):
    return f"Sala de reunion {id_reunion}"