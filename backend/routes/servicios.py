from flask import Blueprint, render_template, request

from backend.db.connection import get_db, close_db
from backend.db.queries import obtener_servicios, obtener_materias, obtener_servicio_por_id

servicios_bp = Blueprint("servicios", __name__)


@servicios_bp.route("/buscar")
def buscar():
    id_materia = request.args.get("id_materia", type=int)
    modalidad = request.args.get("modalidad") or None
    precio_max = request.args.get("precio_max", type=int)

    conn = get_db()
    try:
        materias = obtener_materias(conn)
        servicios = obtener_servicios(
            conn, id_materia=id_materia, modalidad=modalidad, precio_max=precio_max
        )
    finally:
        close_db(conn)

    return render_template(
        "servicios/buscar.html",
        materias=materias,
        servicios=servicios,
        filtros={"id_materia": id_materia, "modalidad": modalidad, "precio_max": precio_max},
    )


@servicios_bp.route("/<int:id_servicio>")
def detalle(id_servicio):
    conn = get_db()
    try:
        servicio = obtener_servicio_por_id(conn, id_servicio)
    finally:
        close_db(conn)

    return render_template("servicios/detalle.html", servicio=servicio)
