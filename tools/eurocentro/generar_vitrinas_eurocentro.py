"""Genera Scene/eurocentro/vitrinas_eurocentro.tscn: el contenido de las dos
vitrinas exteriores del Eurocentro (fondo iluminado, estantes, productos y
afiches con el tema de los locales de la galeria).

Herramienta de pipeline, no codigo del juego. Todo es visual (MeshInstance3D y
Label3D, sin colision). La escena se instancia como hija de
Escenario/Galeriacomercial/DecoracionEurocentro, asi que las coordenadas son
locales a ese nodo: la vitrina mira hacia -X (la calle), Z recorre su ancho.

Uso, desde la raiz del proyecto:
    python tools/eurocentro/generar_vitrinas_eurocentro.py
"""
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Scene" / "eurocentro" / "vitrinas_eurocentro.tscn"

# Cada vitrina: nombre, x del fondo (cara del marco), centro z, ancho, base y
# alto del vidrio, alturas de estantes, afiches (texto, color fondo, color texto).
VITRINAS = [
    dict(nombre="ExhibicionIzquierda", x_fondo=-0.459, z=-9.48, ancho=5.3,
         y0=0.625, alto=2.85, estantes=[1.1, 1.8],
         afiches=[("OFERTAS", "c62828", "ffeb3b"), ("RETRO", "283593", "ffffff"),
                  ("GAMER", "1b5e20", "b9f6ca")]),
    dict(nombre="ExhibicionDerecha", x_fondo=-0.47, z=6.5255, ancho=11.2,
         y0=0.325, alto=2.85, estantes=[0.8, 1.5],
         afiches=[("ANIME", "ad1457", "ffffff"), ("MANGA", "212121", "ffffff"),
                  ("CARTAS TCG", "0d47a1", "ffd54f"), ("FIGURAS", "4a148c", "e1bee7"),
                  ("COSPLAY", "e65100", "ffffff")]),
]
COLORES_PRODUCTO = ["e53935", "1e88e5", "fdd835", "43a047", "8e24aa", "fb8c00", "eceff1", "00acc1"]

# Rotacion para que un Label3D (normal +Z) mire hacia -X: Ry(-90), por filas.
MIRA_CALLE = "0, 0, -1, 0, 1, 0, 1, 0, 0"


def col(h: str, a: float = 1.0) -> str:
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, {a})"


def main() -> None:
    rnd = random.Random(7)   # semilla fija: el resultado es siempre el mismo
    sub, nodes = [], ['[node name="VitrinasEurocentro" type="Node3D"]']
    sub.append('[sub_resource type="StandardMaterial3D" id="MatFondo"]\n'
               'albedo_color = Color(1, 0.95, 0.85, 1)\nemission_enabled = true\n'
               'emission = Color(1, 0.92, 0.78, 1)\nemission_energy_multiplier = 0.45')
    sub.append('[sub_resource type="StandardMaterial3D" id="MatEstante"]\n'
               'albedo_color = Color(0.82, 0.84, 0.86, 1)\nmetallic = 0.6\nroughness = 0.3')
    for i, c in enumerate(COLORES_PRODUCTO):
        sub.append(f'[sub_resource type="StandardMaterial3D" id="MatProd{i}"]\nalbedo_color = {col(c)}\nroughness = 0.6')
    mat_afiche = {}

    for v in VITRINAS:
        n = v["nombre"]
        x0, z0, w = v["x_fondo"], v["z"], v["ancho"]
        yc = v["y0"] + v["alto"] / 2
        nodes.append(f'[node name="{n}" type="Node3D" parent="."]')
        # Fondo iluminado
        sub.append(f'[sub_resource type="BoxMesh" id="Fondo_{n}"]\nmaterial = SubResource("MatFondo")\n'
                   f'size = Vector3(0.01, {v["alto"] - 0.1:.3f}, {w:.3f})')
        nodes.append(f'[node name="Fondo" type="MeshInstance3D" parent="{n}"]\n'
                     f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x0 - 0.006:.4f}, {yc:.4f}, {z0})\n'
                     f'cast_shadow = 0\nmesh = SubResource("Fondo_{n}")')
        # Estantes con productos
        sub.append(f'[sub_resource type="BoxMesh" id="Estante_{n}"]\nmaterial = SubResource("MatEstante")\n'
                   f'size = Vector3(0.08, 0.03, {w - 0.1:.3f})')
        for ei, ey in enumerate(v["estantes"]):
            nodes.append(f'[node name="Estante{ei + 1}" type="MeshInstance3D" parent="{n}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x0 - 0.05:.4f}, {ey}, {z0})\n'
                         f'mesh = SubResource("Estante_{n}")')
            z = z0 - w / 2 + 0.2
            pi = 0
            while z < z0 + w / 2 - 0.2:
                pw, ph = rnd.uniform(0.12, 0.28), rnd.uniform(0.12, 0.32)
                pid = f"Prod_{n}_{ei}_{pi}"
                sub.append(f'[sub_resource type="BoxMesh" id="{pid}"]\n'
                           f'material = SubResource("MatProd{rnd.randrange(len(COLORES_PRODUCTO))}")\n'
                           f'size = Vector3(0.06, {ph:.3f}, {pw:.3f})')
                nodes.append(f'[node name="Producto{ei + 1}_{pi + 1}" type="MeshInstance3D" parent="{n}"]\n'
                             f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x0 - 0.05:.4f}, {ey + 0.015 + ph / 2:.4f}, {z + pw / 2:.4f})\n'
                             f'mesh = SubResource("{pid}")')
                z += pw + rnd.uniform(0.05, 0.14)
                pi += 1
        # Afiches en la franja superior
        top = v["estantes"][-1] + 0.15
        alto_af = min(0.9, v["y0"] + v["alto"] - 0.12 - top)
        y_af = top + alto_af / 2
        k = len(v["afiches"])
        ancho_af = min(1.3, (w - 0.3) / k - 0.25)
        for ai, (texto, bg, fg) in enumerate(v["afiches"]):
            if bg not in mat_afiche:
                mat_afiche[bg] = f"MatAfiche_{bg}"
                sub.append(f'[sub_resource type="StandardMaterial3D" id="MatAfiche_{bg}"]\nalbedo_color = {col(bg)}\nroughness = 0.7')
            aid = f"Afiche_{n}_{ai}"
            sub.append(f'[sub_resource type="BoxMesh" id="{aid}"]\nmaterial = SubResource("{mat_afiche[bg]}")\n'
                       f'size = Vector3(0.02, {alto_af:.3f}, {ancho_af:.3f})')
            za = z0 - w / 2 + (ai + 0.5) * (w / k)
            nodes.append(f'[node name="Afiche{ai + 1}" type="MeshInstance3D" parent="{n}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x0 - 0.04:.4f}, {y_af:.4f}, {za:.4f})\n'
                         f'mesh = SubResource("{aid}")')
            pixel = min(alto_af * 0.45 / 64, ancho_af * 0.85 / (0.78 * 64 * len(texto)))
            nodes.append(f'[node name="Texto" type="Label3D" parent="{n}/Afiche{ai + 1}"]\n'
                         f'transform = Transform3D({MIRA_CALLE}, -0.011, 0, 0)\n'
                         f'pixel_size = {pixel:.5f}\ndouble_sided = false\ntexture_filter = 0\n'
                         f'modulate = {col(fg)}\noutline_size = 0\ntext = "{texto}"\nfont_size = 64')
        # Tira de luz superior
        sub.append(f'[sub_resource type="BoxMesh" id="Luz_{n}"]\nmaterial = SubResource("MatFondo")\n'
                   f'size = Vector3(0.04, 0.03, {w - 0.1:.3f})')
        nodes.append(f'[node name="TiraLuz" type="MeshInstance3D" parent="{n}"]\n'
                     f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x0 - 0.04:.4f}, {v["y0"] + v["alto"] - 0.08:.4f}, {z0})\n'
                     f'cast_shadow = 0\nmesh = SubResource("Luz_{n}")')

    out = "[gd_scene format=3]\n\n" + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodes) + "\n"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(out, encoding="utf-8", newline="\n")
    print(f"escrito {OUT.relative_to(ROOT)}: {len(nodes) - 1} nodos")


if __name__ == "__main__":
    main()
