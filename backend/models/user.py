from flask_login import UserMixin


class User(UserMixin):
    def __init__(self, row):
        self.id = row['id_usuario']
        self.id_usuario = row['id_usuario']
        self.nombre = row['nombre']
        self.email = row['email']
        self.password = row['password']
        self.perfil_foto = row.get('perfil_foto')
        self.area = row['area']
        self.rol = row['rol']
        self.saldo_tokens = row['saldo_tokens']
        self.fecha_creacion = row.get('fecha_creacion')

    def es_estudiante(self):
        return self.rol.lower() in ('estudiante', 'ambos')

    def es_tutor(self):
        return self.rol.lower() in ('tutor', 'ambos')

    def es_admin(self):
        return self.rol.lower() == 'admin'