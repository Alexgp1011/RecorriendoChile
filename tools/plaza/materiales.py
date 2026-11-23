"""Materiales comunes de la Plaza de Armas para los generadores de tools/plaza/.

Cada material es un color plano o una textura pixel art de Asset/texturas/
(tools/texturas/generar_texturas.py) proyectada en coordenadas del mundo
(triplanar): una repeticion cada 2 m en todas las piezas, sin importar su
tamano, y filtrado de vecino mas cercano (pixel art nitido, con mipmaps para la
distancia). Asi todos los edificios comparten escala de pixel.
"""

METROS_POR_REPETICION = 2.0
FILTRO_NEAREST_MIPMAPS = 2   # BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS


class Materiales:
    """Acumula ext_resources de textura y sub_resources de material."""

    def __init__(self):
        self.ext = []
        self.sub = []
        self._tex = {}

    def _textura(self, nombre):
        if nombre not in self._tex:
            tid = f"tex_{nombre}"
            self._tex[nombre] = tid
            self.ext.append(f'[ext_resource type="Texture2D" path="res://Asset/texturas/{nombre}.png" id="{tid}"]')
        return self._tex[nombre]

    def plano(self, mid, color, rugosidad=0.95):
        r, g, b = color
        self.sub.append(f'[sub_resource type="StandardMaterial3D" id="Mat_{mid}"]\n'
                        f'albedo_color = Color({r}, {g}, {b}, 1)\nroughness = {rugosidad}')

    def textura(self, mid, nombre_textura, tinte=(1.0, 1.0, 1.0), rugosidad=0.95,
                metros=METROS_POR_REPETICION):
        tid = self._textura(nombre_textura)
        r, g, b = tinte
        escala = 1.0 / metros
        self.sub.append(f'[sub_resource type="StandardMaterial3D" id="Mat_{mid}"]\n'
                        f'albedo_color = Color({r}, {g}, {b}, 1)\n'
                        f'albedo_texture = ExtResource("{tid}")\nroughness = {rugosidad}\n'
                        f'texture_filter = {FILTRO_NEAREST_MIPMAPS}\n'
                        f'uv1_scale = Vector3({escala}, {escala}, {escala})\n'
                        f'uv1_triplanar = true\nuv1_world_triplanar = true')

    def cabecera(self):
        """Lineas de ext_resource, para ir antes de los sub_resource."""
        return "\n".join(self.ext) + ("\n\n" if self.ext else "")
