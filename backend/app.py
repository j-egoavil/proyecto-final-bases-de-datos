from flask import Flask
from backend.config import SECRET_KEY, DEBUG

app = Flask(
    __name__,
    template_folder="../frontend/templates",
    static_folder="../frontend/static",
)
app.secret_key = SECRET_KEY


@app.route("/")
def index():
    return "P2P-Shield API corriendo"


if __name__ == "__main__":
    app.run(debug=DEBUG)