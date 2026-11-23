"""Genera Scene/plaza/catedral.tscn: la Catedral Metropolitana de la Plaza de Armas.

Herramienta de pipeline, no codigo del juego. Paso 1 del plan de la Plaza
(design/game-brief.md): volumenes 3D a escala, colores planos; las texturas
pixel art llegan despues (generadas por codigo).

La escena se instancia en Escenario/PlazaDeArmas/Catedral con transformacion
identidad, asi que las coordenadas de aqui son las del mundo. Todo se mide desde
la cruz (PuntoCruzCatedral, 20.3 m): el vertice del fronton queda debajo, para
que Rey Palomo se pose sobre la cruz. Nada entra en el area de ataque de Rey
Palomo (x >= -18, cuadrado de 34 m centrado en la arena), asi que no agrega
refugios contra la lluvia de marcas rojas.

Uso, desde la raiz del proyecto:  python tools/plaza/generar_catedral.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from materiales import Materiales  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Scene" / "plaza" / "catedral.tscn"

# --- Referencias del mundo -------------------------------------------------
CRUZ = (-20.7476, 20.2987, -123.2868)   # PuntoCruzCatedral en world.tscn
FX = -21.5          # plano de la fachada (borde poniente del suelo de la plaza)
CZ = CRUZ[2]        # eje de la fachada
LIMITE_ATAQUE_X = -18.0   # el area de ataque empieza aqui (no entrar)

# --- Medidas (m) -------------------------------------------------------------
NAVE_FONDO = 24.5
NAVE_ALTO = 15.0
NAVE_ANCHO = 20.0
TORRE_LADO = 6.0
TORRE_ALTO = 24.0
TORRE_DESDE_EJE = 12.0          # centro de cada torre respecto al eje
FRONTON_ANCHO = 14.0
FRONTON_BASE = NAVE_ALTO + 0.5  # sobre la cornisa
FRONTON_VERTICE = 19.8          # justo debajo de la cruz (20.3)
PODIO_ALTO = 1.2
COLUMNA_RADIO = 0.5
REJA_X = -18.15
REJA_ALTO = 1.6

COLORES = {
    "piedra": (0.80, 0.74, 0.64), "piedra_sombra": (0.66, 0.60, 0.52),
    "puerta": (0.22, 0.15, 0.10), "ventana": (0.10, 0.11, 0.14),
    "techo": (0.42, 0.45, 0.48), "cupula": (0.50, 0.56, 0.58),
    "cruz": (0.30, 0.30, 0.32), "reja": (0.08, 0.09, 0.08),
}

# Material -> (textura de Asset/texturas, tinte). El resto queda en color plano.
TEXTURIZADO = {
    "piedra": ("canteria", (1.0, 1.0, 1.0)),
    "piedra_sombra": ("canteria", (0.82, 0.8, 0.77)),
    "techo": ("teja", (1.0, 1.0, 1.0)),
    "cupula": ("cupula", (1.0, 1.0, 1.0)),
    "cruz": ("fierro", (1.0, 1.0, 1.0)),
    "reja": ("fierro", (1.0, 1.0, 1.0)),
}

CABECERA = ""

sub, nodos = [], ['[node name="CatedralMetropolitana" type="Node3D"]']
mallas = {}


def f(v):
    return f"{v:.3f}".rstrip("0").rstrip(".")


def vec(x, y, z):
    return f"Vector3({f(x)}, {f(y)}, {f(z)})"


def tr(x, y, z, basis="1, 0, 0, 0, 1, 0, 0, 0, 1"):
    return f"Transform3D({basis}, {f(x)}, {f(y)}, {f(z)})"


def csg_caja(nombre, centro, tam, color, padre="."):
    nodos.append(f'[node name="{nombre}" type="CSGBox3D" parent="{padre}"]\n'
                 f'transform = {tr(*centro)}\nuse_collision = true\n'
                 f'size = {vec(*tam)}\nmaterial = SubResource("Mat_{color}")')


def csg_cilindro(nombre, centro, radio, alto, color, padre="."):
    nodos.append(f'[node name="{nombre}" type="CSGCylinder3D" parent="{padre}"]\n'
                 f'transform = {tr(*centro)}\nuse_collision = true\nradius = {f(radio)}\n'
                 f'height = {f(alto)}\nsides = 12\nmaterial = SubResource("Mat_{color}")')


def malla(nombre, tipo, props, color, centro, padre=".", basis="1, 0, 0, 0, 1, 0, 0, 0, 1"):
    clave = (tipo, props, color)
    if clave not in mallas:
        mid = f"{tipo}_{len(mallas)}"
        mallas[clave] = mid
        sub.append(f'[sub_resource type="{tipo}" id="{mid}"]\nmaterial = SubResource("Mat_{color}")\n{props}')
    nodos.append(f'[node name="{nombre}" type="MeshInstance3D" parent="{padre}"]\n'
                 f'transform = {tr(*centro, basis=basis)}\nmesh = SubResource("{mallas[clave]}")')


def caja(nombre, centro, tam, color, padre="."):
    malla(nombre, "BoxMesh", f"size = {vec(*tam)}", color, centro, padre)


def main():
    # Colores planos -> texturas pixel art donde las hay (tools/plaza/materiales.py)
    mats = Materiales()
    for nombre, color in COLORES.items():
        if nombre in TEXTURIZADO:
            textura, tinte = TEXTURIZADO[nombre]
            mats.textura(nombre, textura, tinte)
        else:
            mats.plano(nombre, color)
    sub[:0] = mats.sub
    global CABECERA
    CABECERA = mats.cabecera()

    # Nave y techo
    csg_caja("Nave", (FX - NAVE_FONDO / 2, NAVE_ALTO / 2, CZ), (NAVE_FONDO, NAVE_ALTO, NAVE_ANCHO), "piedra")
    caja("TechoNave", (FX - NAVE_FONDO / 2 - 0.5, NAVE_ALTO + 0.6, CZ), (NAVE_FONDO - 1.0, 1.2, NAVE_ANCHO + 0.6), "techo")
    caja("Cornisa", (FX + 0.3, NAVE_ALTO + 0.25, CZ), (1.2, 0.5, NAVE_ANCHO - 2.0), "piedra_sombra")

    # Fronton triangular (PrismMesh: triangulo en XY, girado para mirar a +X) y la cruz
    alto_fronton = FRONTON_VERTICE - FRONTON_BASE
    malla("Fronton", "PrismMesh", f"size = {vec(FRONTON_ANCHO, alto_fronton, 1.0)}", "piedra",
          (FX + 0.5, FRONTON_BASE + alto_fronton / 2, CZ), basis="0, 0, 1, 0, 1, 0, -1, 0, 0")
    nodos.append('[node name="Cruz" type="Node3D" parent="."]\n'
                 f'transform = {tr(FX + 0.5, FRONTON_VERTICE, CZ)}')
    caja("Palo", (0, 1.0, 0), (0.25, 2.0, 0.25), "cruz", padre="Cruz")
    caja("Travesano", (0, 1.4, 0), (0.25, 0.25, 1.2), "cruz", padre="Cruz")

    # Torres campanario con cupula y cruz
    for lado, signo in (("Sur", -1), ("Norte", 1)):
        tz = CZ + signo * TORRE_DESDE_EJE
        tx = FX - TORRE_LADO / 2
        t = f"Torre{lado}"
        csg_caja(t, (tx, TORRE_ALTO / 2, tz), (TORRE_LADO, TORRE_ALTO, TORRE_LADO), "piedra")
        for i, dz in enumerate((-TORRE_LADO / 2 + 0.25, TORRE_LADO / 2 - 0.25)):
            caja(f"{t}Pilastra{i + 1}", (FX + 0.2, TORRE_ALTO / 2, tz + dz), (0.4, TORRE_ALTO, 0.5), "piedra_sombra")
        caja(f"{t}Campanario", (FX + 0.04, 20.5, tz), (0.1, 2.8, 2.4), "ventana")
        caja(f"{t}Ventana1", (FX + 0.04, 9.5, tz), (0.1, 3.0, 1.4), "ventana")
        caja(f"{t}Ventana2", (FX + 0.04, 14.5, tz), (0.1, 2.4, 1.4), "ventana")
        caja(f"{t}Remate", (tx, TORRE_ALTO + 0.3, tz), (TORRE_LADO + 0.6, 0.6, TORRE_LADO + 0.6), "piedra_sombra")
        malla(f"{t}Tambor", "CylinderMesh", "top_radius = 2.2\nbottom_radius = 2.4\nheight = 2.4\nradial_segments = 12",
              "piedra", (tx, TORRE_ALTO + 1.8, tz))
        malla(f"{t}Cupula", "CylinderMesh", "top_radius = 0.0\nbottom_radius = 2.6\nheight = 3.2\nradial_segments = 12",
              "cupula", (tx, TORRE_ALTO + 4.6, tz))
        nodos.append(f'[node name="{t}Cruz" type="Node3D" parent="."]\n'
                     f'transform = {tr(tx, TORRE_ALTO + 6.2, tz)}')
        caja("Palo", (0, 0.6, 0), (0.18, 1.2, 0.18), "cruz", padre=f"{t}Cruz")
        caja("Travesano", (0, 0.85, 0), (0.18, 0.18, 0.7), "cruz", padre=f"{t}Cruz")

    # Portico: podio, escalinata, columnas, entablamento
    ancho_portico = 16.0
    csg_caja("Podio", (FX + 1.05, PODIO_ALTO / 2, CZ), (2.1, PODIO_ALTO, ancho_portico), "piedra_sombra")
    csg_caja("Peldano2", (FX + 2.4, 0.4, CZ), (0.6, 0.8, ancho_portico), "piedra_sombra")
    csg_caja("Peldano1", (FX + 3.0, 0.2, CZ), (0.6, 0.4, ancho_portico), "piedra_sombra")
    alto_columna = 10.0
    for i, dz in enumerate((-6.0, -3.6, -1.2, 1.2, 3.6, 6.0)):
        csg_cilindro(f"Columna{i + 1}", (FX + 1.2, PODIO_ALTO + alto_columna / 2, CZ + dz),
                     COLUMNA_RADIO, alto_columna, "piedra")
    caja("Entablamento", (FX + 1.0, PODIO_ALTO + alto_columna + 0.5, CZ), (1.6, 1.0, 14.0), "piedra_sombra")

    # Puertas
    caja("PuertaPrincipal", (FX + 0.05, PODIO_ALTO + 2.6, CZ), (0.1, 5.2, 3.0), "puerta")
    for i, dz in enumerate((-4.8, 4.8)):
        caja(f"PuertaLateral{i + 1}", (FX + 0.05, PODIO_ALTO + 2.0, CZ + dz), (0.1, 4.0, 2.2), "puerta")

    # Reja del atrio, con puerta central abierta (4 m)
    nodos.append('[node name="RejaAtrio" type="Node3D" parent="."]')
    tramos = [(CZ - 9.5, CZ - 2.0), (CZ + 2.0, CZ + 9.5)]
    for n, (z0, z1) in enumerate(tramos):
        largo = z1 - z0
        zc = (z0 + z1) / 2
        csg_caja(f"Tramo{n + 1}", (REJA_X, REJA_ALTO / 2, zc), (0.12, REJA_ALTO, largo), "reja", padre="RejaAtrio")
        for p, zp in enumerate((z0, z1)):
            caja(f"Pilar{n + 1}_{p + 1}", (REJA_X, 1.1, zp), (0.5, 2.2, 0.5), "piedra_sombra", padre="RejaAtrio")

    # Solo cuenta lo que tiene colision: el tramo de reja (0.12 m) y el peldano 1.
    assert REJA_X + 0.06 < LIMITE_ATAQUE_X and FX + 3.3 < LIMITE_ATAQUE_X, "la catedral invade el area de ataque"

    out = "[gd_scene format=3]\n\n" + CABECERA + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodos) + "\n"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(out, encoding="utf-8", newline="\n")
    print(f"escrito {OUT.relative_to(ROOT)}: {len(nodos)} nodos, {len(mallas)} mallas")


if __name__ == "__main__":
    main()
