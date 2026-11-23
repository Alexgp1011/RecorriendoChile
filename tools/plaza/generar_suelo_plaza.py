"""Genera el suelo decorado de la Plaza de Armas (paso 3 del plan).

Herramienta de pipeline, no codigo del juego. Escribe:
  - Scene/plaza/banca.tscn: banca verde de madera y fierro (colision baja, 0.9 m)
  - Scene/plaza/suelo_plaza.tscn: pavimento con senderos (Asset/texturas/
    pavimento_plaza.png, un plano de 40 x 40 m sobre SueloPlaza), pasto y flores
    sobre las 4 jardineras existentes, y 8 bancas junto a los senderos.

Se instancia en Escenario/PlazaDeArmas con transformacion identidad (coordenadas
del mundo). El pavimento, el pasto y las flores son solo visuales: el suelo con
colision sigue siendo SueloPlaza, asi que las marcas rojas de Rey Palomo caen
igual. Las bancas miden 0.9 m (< 1.2 m): no dan refugio. El generador comprueba
que ninguna banca se cruce con una jardinera.

Uso, desde la raiz del proyecto:  python tools/plaza/generar_suelo_plaza.py
"""
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from materiales import FILTRO_NEAREST_MIPMAPS, Materiales  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT_BANCA = ROOT / "Scene" / "plaza" / "banca.tscn"
OUT_SUELO = ROOT / "Scene" / "plaza" / "suelo_plaza.tscn"

WORLD = ROOT / "Scene" / "world.tscn"


def leer_caja(nombre):
    """Centro (x, y, z) y tamano (x, y, z) de un CSGBox3D de world.tscn, sin redondear:
    asi el decorado no se desincroniza si se mueve en el editor."""
    texto = WORLD.read_text(encoding="utf-8")
    i = texto.index(f'[node name="{nombre}" type="CSGBox3D"')
    bloque = texto[i:texto.find("[node ", i + 10)]
    t = bloque.split("transform = Transform3D(")[1].split(")")[0].split(",")
    tam = bloque.split("size = Vector3(")[1].split(")")[0].split(",")
    return tuple(float(v) for v in t[9:12]), tuple(float(v) for v in tam)


_suelo_c, _suelo_t = leer_caja("SueloPlaza")
PLAZA_CENTRO = (_suelo_c[0], _suelo_c[2])
SUELO_ARRIBA = _suelo_c[1] + _suelo_t[1] / 2       # cara superior de SueloPlaza
# Jardineras de world.tscn: nombre, centro (x, z); tamano y cara superior comunes
JARDINERAS = []
for _n in ("Jardinera1", "Jardinera2", "Jardinera3", "Jardinera4"):
    _c, _t = leer_caja(_n)
    JARDINERAS.append((_n, (_c[0], _c[2])))
JARDINERA_TAM = (_t[0], _t[2])
JARDINERA_ARRIBA = _c[1] + _t[1] / 2

FLORES_POR_JARDINERA = 6
# Bancas: (x, z, orientacion). La banca mira a +z local; orientacion = hacia
# donde mira en el mundo.
BANCAS = [
    (-12.0, -119.6, "-z"), (10.0, -119.6, "-z"),
    (-12.0, -124.4, "+z"), (12.0, -124.4, "+z"),
    (-3.4, -108.0, "+x"), (1.4, -108.0, "-x"),
    (-3.4, -136.0, "+x"), (1.4, -136.0, "-x"),
]
BASE_ORIENTACION = {   # filas de la base: gira +z local hacia la direccion pedida
    "+z": "1, 0, 0, 0, 1, 0, 0, 0, 1", "-z": "-1, 0, 0, 0, 1, 0, 0, 0, -1",
    "+x": "0, 0, 1, 0, 1, 0, -1, 0, 0", "-x": "0, 0, -1, 0, 1, 0, 1, 0, 0",
}
BANCA_LARGO, BANCA_FONDO = 1.8, 0.55


def f(v):
    return f"{v:.4f}".rstrip("0").rstrip(".")


def generar_banca():
    mats = Materiales()
    mats.textura("madera", "madera_banca", metros=1.0)
    mats.textura("fierro", "fierro", metros=1.0)
    sub = mats.sub + [
        '[sub_resource type="BoxMesh" id="Asiento"]\nmaterial = SubResource("Mat_madera")\nsize = Vector3(1.8, 0.08, 0.5)',
        '[sub_resource type="BoxMesh" id="Respaldo"]\nmaterial = SubResource("Mat_madera")\nsize = Vector3(1.8, 0.36, 0.06)',
        '[sub_resource type="BoxMesh" id="Pata"]\nmaterial = SubResource("Mat_fierro")\nsize = Vector3(0.08, 0.86, 0.5)',
        '[sub_resource type="BoxShape3D" id="Forma"]\nsize = Vector3(1.8, 0.9, 0.55)',
    ]
    nodos = [
        '[node name="Banca" type="Node3D"]',
        '[node name="Asiento" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.45, 0)\nmesh = SubResource("Asiento")',
        '[node name="Respaldo" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 0.966, -0.259, 0, 0.259, 0.966, 0, 0.72, -0.24)\nmesh = SubResource("Respaldo")',
        '[node name="PataIzq" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.8, 0.43, 0)\nmesh = SubResource("Pata")',
        '[node name="PataDer" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.8, 0.43, 0)\nmesh = SubResource("Pata")',
        '[node name="Colision" type="StaticBody3D" parent="."]',
        '[node name="Forma" type="CollisionShape3D" parent="Colision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.45, 0)\nshape = SubResource("Forma")',
    ]
    texto = "[gd_scene format=3]\n\n" + mats.cabecera() + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodos) + "\n"
    OUT_BANCA.write_text(texto, encoding="utf-8", newline="\n")
    print(f"escrito {OUT_BANCA.relative_to(ROOT)}")


def comprobar_bancas():
    for x, z, o in BANCAS:
        lx, lz = (BANCA_LARGO, BANCA_FONDO) if o in ("+z", "-z") else (BANCA_FONDO, BANCA_LARGO)
        for nombre, (jx, jz) in JARDINERAS:
            jlx, jlz = JARDINERA_TAM
            cruza = abs(x - jx) < (lx + jlx) / 2 and abs(z - jz) < (lz + jlz) / 2
            assert not cruza, f"la banca en ({x}, {z}) se cruza con {nombre}"


def generar_suelo():
    comprobar_bancas()
    mats = Materiales()
    mats.textura("pasto", "pasto")
    # El pavimento es una textura unica de 40 m: UV normales del plano, no triplanar.
    tid = mats._textura("pavimento_plaza")
    mats.sub.append(f'[sub_resource type="StandardMaterial3D" id="Mat_pavimento"]\n'
                    f'albedo_texture = ExtResource("{tid}")\nroughness = 0.95\n'
                    f'texture_filter = {FILTRO_NEAREST_MIPMAPS}')
    tflor = mats._textura("flor")
    ext = [f'[ext_resource type="PackedScene" path="res://Scene/plaza/banca.tscn" id="escena_banca"]']
    sub = mats.sub + [
        '[sub_resource type="QuadMesh" id="Pavimento"]\nmaterial = SubResource("Mat_pavimento")\nsize = Vector2(40, 40)',
        f'[sub_resource type="QuadMesh" id="Pasto"]\nmaterial = SubResource("Mat_pasto")\nsize = Vector2({JARDINERA_TAM[0] - 0.4}, {JARDINERA_TAM[1] - 0.4})',
    ]
    # Plano tumbado mirando hacia arriba: filas de Rx(-90). La fila 0 de la
    # textura queda en z -142 y la columna 0 en x -21 (ver generar_texturas.py).
    tumbado = "1, 0, 0, 0, 0, 1, 0, -1, 0"
    nodos = ['[node name="SueloPlazaDecorado" type="Node3D"]',
             f'[node name="Pavimento" type="MeshInstance3D" parent="."]\n'
             f'transform = Transform3D({tumbado}, {f(PLAZA_CENTRO[0])}, {f(SUELO_ARRIBA + 0.015)}, {f(PLAZA_CENTRO[1])})\n'
             f'cast_shadow = 0\nmesh = SubResource("Pavimento")',
             '[node name="Jardineras" type="Node3D" parent="."]']
    rnd = random.Random("recorriendo-chile:flores")
    for nombre, (jx, jz) in JARDINERAS:
        nodos.append(f'[node name="{nombre}" type="Node3D" parent="Jardineras"]\n'
                     f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {f(jx)}, {f(JARDINERA_ARRIBA)}, {f(jz)})')
        nodos.append(f'[node name="Pasto" type="MeshInstance3D" parent="Jardineras/{nombre}"]\n'
                     f'transform = Transform3D({tumbado}, 0, 0.01, 0)\ncast_shadow = 0\nmesh = SubResource("Pasto")')
        for i in range(FLORES_POR_JARDINERA):
            fx = rnd.uniform(-JARDINERA_TAM[0] / 2 + 0.5, JARDINERA_TAM[0] / 2 - 0.5)
            fz = rnd.uniform(-JARDINERA_TAM[1] / 2 + 0.5, JARDINERA_TAM[1] / 2 - 0.5)
            nodos.append(f'[node name="Flor{i + 1}" type="Sprite3D" parent="Jardineras/{nombre}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {f(fx)}, 0.26, {f(fz)})\n'
                         f'pixel_size = 0.03125\nbillboard = 2\ntexture_filter = 0\nalpha_cut = 1\n'
                         f'texture = ExtResource("{tflor}")')
    nodos.append('[node name="Bancas" type="Node3D" parent="."]')
    for i, (x, z, o) in enumerate(BANCAS):
        nodos.append(f'[node name="Banca{i + 1}" parent="Bancas" instance=ExtResource("escena_banca")]\n'
                     f'transform = Transform3D({BASE_ORIENTACION[o]}, {f(x)}, {f(SUELO_ARRIBA)}, {f(z)})')
    texto = ("[gd_scene format=3]\n\n" + "\n".join(ext) + "\n" + mats.cabecera()
             + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodos) + "\n")
    OUT_SUELO.write_text(texto, encoding="utf-8", newline="\n")
    print(f"escrito {OUT_SUELO.relative_to(ROOT)}: {len(BANCAS)} bancas, "
          f"{len(JARDINERAS) * FLORES_POR_JARDINERA} matas de flores")


if __name__ == "__main__":
    generar_banca()
    generar_suelo()
