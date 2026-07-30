from flask import Blueprint, render_template, request, redirect, url_for, session, flash
import mysql.connector

from backend.db.connection import get_db, close_db
from backend.db.queries import (
    obtener_servicios, obtener_materias, obtener_servicio_por_id, agendar_reunion,
)

servicios_bp = Blueprint("servicios", __name__)


@servicios_bp.route("/buscar")
def buscar():
    id_materia = request.args.get("id_materia", type=int)
    modalidad = request.args.get("modalidad") or None
    precio_max = request.args.get("precio_max", type=int)
    
    # 1. Capturamos la página actual (por defecto es 1)
    page = request.args.get("page", 1, type=int)
    per_page = 50
    offset = (page - 1) * per_page

    conn = get_db()
    try:
        materias = obtener_materias(conn)
        # 2. Le pasamos el limit (per_page) y offset a tu función de queries
        servicios = obtener_servicios(
            conn, 
            id_materia=id_materia, 
            modalidad=modalidad, 
            precio_max=precio_max,
            limit=per_page,
            offset=offset
        )
    finally:
        close_db(conn)

    return render_template(
        "servicios/buscar.html",
        materias=materias,
        servicios=servicios,
        filtros={"id_materia": id_materia, "modalidad": modalidad, "precio_max": precio_max},
        page=page  # 3. Mandamos la página al HTML para que funcionen los botones
    )


@servicios_bp.route("/<int:id_servicio>")
def detalle(id_servicio):
    conn = get_db()
    try:
        servicio = obtener_servicio_por_id(conn, id_servicio)
    finally:
        close_db(conn)
    return render_template("servicios/detalle.html", servicio=servicio)