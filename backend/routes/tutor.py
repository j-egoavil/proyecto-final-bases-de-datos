from flask import Blueprint

tutor_bp = Blueprint("tutor", __name__)


@tutor_bp.route("/postular")
def postular():
    return "Postularse como tutor"


@tutor_bp.route("/mis-servicios")
def mis_servicios():
    return "Mis servicios"