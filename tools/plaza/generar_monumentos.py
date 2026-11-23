"""Genera glorieta, monumentos y arboles de la Plaza de Armas (paso 4 del plan).

Herramienta de pipeline, no codigo del juego. Escribe en Scene/plaza/:
  glorieta.tscn, farol_monumental.tscn, monumento_ecuestre.tscn, palmera.tscn,
  arbol.tscn y arboleda.tscn (las palmeras y arboles ya ubicados).
y deja en COLOCACION donde va cada pieza en world.tscn (Quiosco, Monumentos,
Arboles), para que el paso de integracion las instancie.

Perchas de Rey Palomo (cada pieza queda con su tope bajo el marcador, menos la
media altura del sprite del jefe, para que parezca posado):
  Vuelo01 -> monumento ecuestre (pedestal de canteria + estatua)
  Vuelo02 -> farol monumental de cuatro brazos (la glorieta no cabe: la
             jardinera 4 esta a 3 m)
  Vuelo03, Vuelo04 -> palmeras
La glorieta va en el cuadrante sur-oriente, sin percha.

Refugios: dentro del area de ataque solo el pedestal (decision del autor:
"pocos y en los bordes"). Lo demas es fino o mas alto que 3 m (el rayo que
ubica cada marca nace a 3 m y no detecta lo que lo rodea), o queda fuera.

Los sprites (palmera, arbol, estatua) son PROVISIONALES: tools/texturas.
Uso, desde la raiz del proyecto:  python tools/plaza/generar_monumentos.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from materiales import Materiales  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
DIR = ROOT / "Scene" / "plaza"

VUELO = {"Vuelo01": (-16.7, 6.0, -131.8), "Vuelo02": (7.6, 6.0, -128.3),
         "Vuelo03": (7.0, 6.0, -106.9), "Vuelo04": (-18.1, 6.0, -106.6)}
MEDIO_ALTO_JEFE = 1.6
ATAQUE = (-18.0, 16.0, -142.0, -111.7)      # recortado al suelo original
ALTURA_RAYO_MARCAS = 3.0                    # don_palomo.gd: buscar_suelo()
PIXEL = 0.0625                              # 16 px por metro, como las texturas

# Donde va cada pieza: (nodo de world.tscn, escena, x, z)
COLOCACION = [
    ("Escenario/PlazaDeArmas/Monumentos", "monumento_ecuestre", *(VUELO["Vuelo01"][0], VUELO["Vuelo01"][2])),
    ("Escenario/PlazaDeArmas/Monumentos", "farol_monumental", *(VUELO["Vuelo02"][0], VUELO["Vuelo02"][2])),
    ("Escenario/PlazaDeArmas/Quiosco", "glorieta", 8.5, -136.5),
    ("Escenario/PlazaDeArmas/Arboles", "arboleda", 0.0, 0.0),
]
PALMERAS = [(7.0, -106.9), (-18.1, -106.6), (-12.0, -104.5), (15.0, -104.5)]
ARBOLES = [(17.6, -110.0), (17.6, -118.0), (17.6, -126.0), (17.6, -134.0), (17.6, -140.0)]

# Topes (m sobre el suelo) y colisiones de cada pieza, para las comprobaciones
def tope_sprite(textura, pixel):
    """Altura (m) del pixel visible mas alto de un sprite apoyado en el suelo."""
    from PIL import Image
    img = Image.open(ROOT / "Asset" / "texturas" / f"{textura}.png")
    fila_arriba = img.getchannel("A").getbbox()[1]
    return (img.height - fila_arriba) * pixel


# La palmera se escala para que su copa quede justo bajo el jefe posado
LIMITE_PERCHA = 6.0 - MEDIO_ALTO_JEFE
PIXEL_PALMERA = PIXEL * min(1.0, LIMITE_PERCHA / tope_sprite("palmera", PIXEL))
# La estatua va sobre el pedestal (2.4 m): se escala igual para no pasar el limite
PEDESTAL_ALTO = 2.4
PIXEL_ESTATUA = PIXEL * min(1.0, (LIMITE_PERCHA - PEDESTAL_ALTO) / tope_sprite("estatua_ecuestre", PIXEL))
FAROL_TOPE = 4.15 + 0.25        # remate del farol monumental (centro + media altura)
TOPE = {"monumento_ecuestre": PEDESTAL_ALTO + tope_sprite("estatua_ecuestre", PIXEL_ESTATUA),
        "farol_monumental": FAROL_TOPE,
        "palmera": tope_sprite("palmera", PIXEL_PALMERA)}
COLISIONES = {   # (radio o medio ancho, alto) de lo solido
    "monumento_ecuestre": ("caja", 0.8, 1.5, 2.4), "farol_monumental": ("cilindro", 0.25, 0.25, 4.2),
    "glorieta_columna": ("cilindro", 0.15, 0.15, 3.2), "palmera": ("cilindro", 0.2, 0.2, 4.0),
    "arbol": ("cilindro", 0.2, 0.2, 2.8),
}


def f(v):
    return f"{v:.4f}".rstrip("0").rstrip(".")


def tr(x, y, z, basis="1, 0, 0, 0, 1, 0, 0, 0, 1"):
    return f"Transform3D({basis}, {f(x)}, {f(y)}, {f(z)})"


class Escena:
    def __init__(self, raiz):
        self.m = Materiales()
        self.sub, self.ext = [], []
        self.nodos = [f'[node name="{raiz}" type="Node3D"]']
        self.n = 0

    def malla(self, nombre, tipo, props, mat, pos, padre=".", sombra=True):
        self.n += 1
        mid = f"{tipo}_{self.n}"
        self.sub.append(f'[sub_resource type="{tipo}" id="{mid}"]\nmaterial = SubResource("Mat_{mat}")\n{props}')
        extra = "" if sombra else "cast_shadow = 0\n"
        self.nodos.append(f'[node name="{nombre}" type="MeshInstance3D" parent="{padre}"]\n'
                          f'transform = {tr(*pos)}\n{extra}mesh = SubResource("{mid}")')

    def cilindro(self, nombre, r_arriba, r_abajo, alto, mat, pos, lados=12, padre=".", sombra=True):
        self.malla(nombre, "CylinderMesh", f"top_radius = {f(r_arriba)}\nbottom_radius = {f(r_abajo)}\n"
                   f"height = {f(alto)}\nradial_segments = {lados}", mat, pos, padre, sombra)

    def caja(self, nombre, tam, mat, pos, padre="."):
        self.malla(nombre, "BoxMesh", f"size = Vector3({f(tam[0])}, {f(tam[1])}, {f(tam[2])})", mat, pos, padre)

    def cuerpo(self, formas):
        """StaticBody3D con formas [(tipo, a, b, alto, (x, y, z))]."""
        self.nodos.append('[node name="Colision" type="StaticBody3D" parent="."]')
        for i, (tipo, a, b, alto, pos) in enumerate(formas):
            self.n += 1
            sid = f"Forma_{self.n}"
            if tipo == "cilindro":
                self.sub.append(f'[sub_resource type="CylinderShape3D" id="{sid}"]\nheight = {f(alto)}\nradius = {f(a)}')
            else:
                self.sub.append(f'[sub_resource type="BoxShape3D" id="{sid}"]\nsize = Vector3({f(2 * a)}, {f(alto)}, {f(2 * b)})')
            self.nodos.append(f'[node name="Forma{i + 1}" type="CollisionShape3D" parent="Colision"]\n'
                              f'transform = {tr(*pos)}\nshape = SubResource("{sid}")')

    def sprite(self, nombre, textura, alto_px, base_y=0.0, pos_xz=(0.0, 0.0), padre=".", pixel=PIXEL):
        tid = self.m._textura(textura)
        y = base_y + alto_px * pixel / 2
        self.nodos.append(f'[node name="{nombre}" type="Sprite3D" parent="{padre}"]\n'
                          f'transform = {tr(pos_xz[0], y, pos_xz[1])}\npixel_size = {f(pixel)}\nbillboard = 2\n'
                          f'texture_filter = 0\nalpha_cut = 1\ntexture = ExtResource("{tid}")')

    def escribir(self, nombre):
        texto = ("[gd_scene format=3]\n\n" + "\n".join(self.ext) + ("\n" if self.ext else "")
                 + self.m.cabecera() + "\n\n".join(self.m.sub + self.sub) + "\n\n" + "\n\n".join(self.nodos) + "\n")
        (DIR / f"{nombre}.tscn").write_text(texto, encoding="utf-8", newline="\n")
        print(f"  escrito Scene/plaza/{nombre}.tscn")


def materiales(e):
    e.m.textura("canteria", "canteria")
    e.m.textura("fierro", "fierro", metros=1.0)
    e.m.textura("cupula", "cupula")
    e.m.sub.append('[sub_resource type="StandardMaterial3D" id="Mat_luz"]\nalbedo_color = Color(1, 0.92, 0.7, 1)\n'
                   'emission_enabled = true\nemission = Color(1, 0.86, 0.55, 1)\nemission_energy_multiplier = 1.5')


def glorieta():
    e = Escena("Glorieta")
    materiales(e)
    radio = 2.7
    e.cilindro("Plataforma", 3.0, 3.0, 0.15, "canteria", (0, 0.075, 0), lados=8)   # solo visual: no se puede saltar
    import math
    formas = []
    for i in range(8):
        a = math.radians(22.5 + i * 45)
        x, z = math.cos(a) * radio, math.sin(a) * radio
        e.cilindro(f"Columna{i + 1}", 0.12, 0.15, 3.2, "fierro", (x, 1.75, z), lados=8)
        formas.append(("cilindro", 0.15, 0.15, 3.2, (x, 1.75, z)))
    e.cilindro("Anillo", 3.1, 3.1, 0.25, "fierro", (0, 3.475, 0), lados=8)
    e.cilindro("Cupula", 0.0, 3.4, 1.0, "cupula", (0, 4.1, 0), lados=8)
    e.cilindro("Remate", 0.05, 0.12, 0.5, "fierro", (0, 4.85, 0), lados=6)
    e.cuerpo(formas)
    e.escribir("glorieta")


def farol_monumental():
    e = Escena("FarolMonumental")
    materiales(e)
    e.cilindro("Base", 0.4, 0.5, 0.6, "canteria", (0, 0.3, 0), lados=8)
    e.cilindro("Poste", 0.12, 0.16, 3.4, "fierro", (0, 2.3, 0), lados=8)
    for i, (dx, dz) in enumerate(((0.6, 0), (-0.6, 0), (0, 0.6), (0, -0.6))):
        e.caja(f"Brazo{i + 1}", (abs(dx) * 2 if dx else 0.06, 0.06, abs(dz) * 2 if dz else 0.06), "fierro", (dx / 2, 3.75, dz / 2))
        e.malla(f"Linterna{i + 1}", "BoxMesh", "size = Vector3(0.28, 0.38, 0.28)", "luz", (dx, 3.55, dz), sombra=False)
    e.cilindro("Remate", 0.0, 0.2, 0.5, "fierro", (0, 4.15, 0), lados=6)
    e.cuerpo([("cilindro", 0.25, 0.25, 4.2, (0, 2.1, 0))])
    e.escribir("farol_monumental")


def monumento_ecuestre():
    e = Escena("MonumentoEcuestre")
    materiales(e)
    e.caja("Zocalo", (2.2, 0.5, 3.6), "canteria", (0, 0.25, 0))
    e.caja("Pedestal", (1.6, 1.7, 3.0), "canteria", (0, 1.35, 0))
    e.caja("Cornisa", (1.8, 0.2, 3.2), "canteria", (0, 2.3, 0))
    e.sprite("Estatua", "estatua_ecuestre", 40, base_y=PEDESTAL_ALTO, pixel=PIXEL_ESTATUA)
    e.cuerpo([("caja", 0.8, 1.5, 2.4, (0, 1.2, 0)), ("caja", 1.1, 1.8, 0.5, (0, 0.25, 0))])
    e.escribir("monumento_ecuestre")


def palmera():
    e = Escena("Palmera")
    e.sprite("Sprite", "palmera", 80, pixel=PIXEL_PALMERA)
    e.cuerpo([("cilindro", 0.2, 0.2, 4.0, (0, 2.0, 0))])
    e.escribir("palmera")


def arbol():
    e = Escena("Arbol")
    e.sprite("Sprite", "arbol", 80)
    e.cuerpo([("cilindro", 0.2, 0.2, 2.8, (0, 1.4, 0))])
    e.escribir("arbol")


def arboleda():
    e = Escena("Arboleda")
    e.ext = ['[ext_resource type="PackedScene" path="res://Scene/plaza/palmera.tscn" id="escena_palmera"]',
             '[ext_resource type="PackedScene" path="res://Scene/plaza/arbol.tscn" id="escena_arbol"]']
    for i, (x, z) in enumerate(PALMERAS):
        e.nodos.append(f'[node name="Palmera{i + 1}" parent="." instance=ExtResource("escena_palmera")]\ntransform = {tr(x, 0, z)}')
    for i, (x, z) in enumerate(ARBOLES):
        e.nodos.append(f'[node name="Arbol{i + 1}" parent="." instance=ExtResource("escena_arbol")]\ntransform = {tr(x, 0, z)}')
    e.escribir("arboleda")


def comprobar():
    # Perchas: el tope queda bajo el marcador menos la media altura del jefe
    for nombre, (x, y, z) in VUELO.items():
        pieza = {"Vuelo01": "monumento_ecuestre", "Vuelo02": "farol_monumental"}.get(nombre, "palmera")
        assert TOPE[pieza] <= y - MEDIO_ALTO_JEFE + 0.01, f"{pieza} no queda bajo {nombre}"
    # Refugios dentro del area de ataque: solo el pedestal
    ax0, ax1, az0, az1 = ATAQUE
    solidos = [("monumento_ecuestre", *VUELO["Vuelo01"][::2]), ("farol_monumental", *VUELO["Vuelo02"][::2])]
    solidos += [("palmera", x, z) for x, z in PALMERAS] + [("arbol", x, z) for x, z in ARBOLES]
    import math
    for i in range(8):
        a = math.radians(22.5 + i * 45)
        solidos.append(("glorieta_columna", 8.5 + math.cos(a) * 2.7, -136.5 + math.sin(a) * 2.7))
    refugios = []
    for pieza, x, z in solidos:
        _, ax, az, alto = COLISIONES[pieza]
        dentro = ax0 < x + ax and x - ax < ax1 and az0 < z + az and z - az < az1
        if dentro and 1.2 < alto < ALTURA_RAYO_MARCAS:
            refugios.append(pieza)
    assert refugios == ["monumento_ecuestre"], f"refugios inesperados: {refugios}"
    print(f"  comprobado: perchas bajo sus marcadores; refugios nuevos = {refugios}")


if __name__ == "__main__":
    comprobar()
    for hacer in (glorieta, farol_monumental, monumento_ecuestre, palmera, arbol, arboleda):
        hacer()
