import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "Lara2005."),
    "database": os.getenv("DB_NAME", "u_linker"),
}

SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "clave-secreta-temporal")
DEBUG = os.getenv("FLASK_DEBUG", "True").lower() == "true"
