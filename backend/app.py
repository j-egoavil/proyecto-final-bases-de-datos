from flask import Flask
from backend.config import SECRET_KEY, DEBUG
from backend.routes.auth import auth_bp
from backend.routes.servicios import servicios_bp
from backend.routes.reuniones import reuniones_bp
from backend.routes.admin import admin_bp
from backend.routes.usuario import usuario_bp
from backend.routes.tutor import tutor_bp

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


@app.route("/")
def index():
    return "P2P-Shield API corriendo"


if __name__ == "__main__":
    app.run(debug=DEBUG)
