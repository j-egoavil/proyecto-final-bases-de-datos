from flask import Flask, session
from backend.config import SECRET_KEY, DEBUG
from backend.routes.auth import auth_bp
from backend.routes.servicios import servicios_bp
from backend.routes.reuniones import reuniones_bp
from backend.routes.admin import admin_bp
from backend.routes.usuario import usuario_bp
from backend.routes.tutor import tutor_bp
from backend.db.connection import get_db, close_db
from backend.db.queries import obtener_saldo

app = Flask(
    __name__,
    template_folder="../frontend/templates",
    static_folder="../frontend/static",
)
app.secret_key = SECRET_KEY

app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(servicios_bp, url_prefix="/servicios")
app.register_blueprint(reuniones_bp, url_prefix="/reuniones")
app.register_blueprint(admin_bp, url_prefix="/admin")
app.register_blueprint(usuario_bp, url_prefix="/usuario")
app.register_blueprint(tutor_bp, url_prefix="/tutor")

@app.context_processor
def inject_saldo_actual():
    id_usuario = session.get("id_usuario")
    if not id_usuario:
        return {}
    conn = get_db()
    try:
        saldo = obtener_saldo(conn, id_usuario)
    finally:
        close_db(conn)
    return {"saldo_actual": saldo}


@app.route("/")
def index():
    return "P2P-Shield API corriendo"


if __name__ == "__main__":
    app.run(debug=DEBUG)
