from flask import Blueprint

servicios_bp = Blueprint("servicios", __name__)


@servicios_bp.route("/buscar")
def buscar():
    return "Buscar servicios"


@servicios_bp.route("/<int:id_servicio>")
def detalle(id_servicio):
    return f"Detalle del servicio {id_servicio}"