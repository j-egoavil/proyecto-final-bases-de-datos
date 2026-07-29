from flask import Flask
from backend.config import SECRET_KEY, DEBUG
from backend.routes.auth import auth_bp
from backend.routes.servicios import servicios_bp

app = Flask(
    __name__,
    template_folder="../frontend/templates",
    static_folder="../frontend/static",
)
app.secret_key = SECRET_KEY

app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(servicios_bp, url_prefix="/servicios")


@app.route("/")
def index():
    return "P2P-Shield API corriendo"


if __name__ == "__main__":
    app.run(debug=DEBUG)
