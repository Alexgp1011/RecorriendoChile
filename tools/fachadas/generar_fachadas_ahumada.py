"""Genera Scene/fachadas/fachadas_ahumada.tscn: las fachadas de Paseo Ahumada.

Herramienta de pipeline (no es codigo del juego). Lee las imagenes de fachada,
las recorta a su silueta (canal alfa), las coloca a escala real sin estirarlas
sobre la cara de cada CSGBox3D de Escenario/Edificios, y anade relieve 3D:
pilastras, cornisa de remate, imposta sobre el piso comercial y letreros 3D
(con nombres ficticios) encima de los letreros de marcas reales de la imagen.

Todo es visual: MeshInstance3D y Label3D, sin colision. La escena se instancia
en la raiz de world.tscn, fuera de Escenario, para que no entre en el grupo
"geometria_navegacion" del que se hornea la navegacion.

Uso, desde la raiz del proyecto:
    python tools/fachadas/generar_fachadas_ahumada.py
Requiere Pillow. Vuelve a ejecutarlo tras cambiar las tablas de abajo.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Scene" / "fachadas" / "fachadas_ahumada.tscn"

# --- Medidas del mundo (de world.tscn, Escenario/Edificios) -----------------
BOX_HALF_X = 5.0          # CSGBox3D size.x = 10
BOX_HEIGHT = 14.0         # CSGBox3D size.y = 14, base en y = 0
SLOT_WIDTH = 10.0         # cada cara de 20 m lleva dos modulos de 10 m
IMG_MAX_W = 9.6           # deja 0.2 m por lado para las pilastras
IMG_MAX_H = 13.3          # deja sitio a la cornisa de remate
GROUND_Y = 0.01           # cara superior de Escenario/Calle/Suelopeatonal

# --- Imagenes: (archivo, ancho del preview usado para medir, linea del piso
#     comercial en px del preview de 700 de alto, letreros a tapar en px del
#     preview: (x0, y0, x1, y1)) --------------------------------------------
IMAGES = {
    "plaza": ("Asset/Fachada pixel art del Edificio Plaza.png", 525, 518, [
        (96, 524, 138, 565), (218, 524, 262, 565),
        (50, 570, 165, 608), (235, 572, 297, 610), (305, 572, 472, 608)]),
    "caribe": ("Asset/Fachada pixel art del Café Caribe.png", 560, 500, [
        (38, 525, 112, 583), (35, 592, 113, 614),
        (366, 523, 520, 540), (363, 576, 540, 604)]),
    "falabella": ("Asset/Fachada histórica con tiendas Falabella y Belsport.png", 525, 462, [
        (285, 558, 378, 590), (410, 478, 490, 555)]),
    "modernista": ("Asset/Fachada modernista en pixel art.png", 467, 518, [
        (214, 565, 284, 588), (290, 565, 364, 588), (370, 565, 442, 588)]),
    "neoclasica": ("Asset/Fachada neoclásica con banderas chilenas.png", 560, 452, []),
}
PREVIEW_H = 700

# --- Edificios: (nombre, centro x, centro z, lado, modulos) -----------------
# lado "izq": cara hacia +X en x = -9; lado "der": cara hacia -X en x = +9.
BUILDINGS = [
    ("Edificio_Izq1", -14, -12, "izq", ["plaza", "modernista"]),
    ("Edificio_Izq2", -14, -35, "izq", ["caribe", "neoclasica"]),
    ("Edificio_Izq3", -14, -59, "izq", ["falabella", "plaza"]),
    ("Edificio_Der1", 14, -12, "der", ["modernista", "caribe"]),
    ("Edificio_Der2", 14, -73, "der", ["neoclasica", "falabella"]),
]

# Nombres ficticios para los letreros (se reparten en orden, sin repetirse
# hasta agotar la lista) y sus colores (fondo, texto).
SIGN_NAMES = [
    "FARMACIA EL ROBLE", "SANGUCHES DON TITO", "HELADOS NEVADA",
    "COMPLETOS LA PICADA", "TELEFONIA CONDOR", "CELULARES AUSTRAL",
    "BANCO CORDILLERA", "ZAPATILLAS VELOZ", "TIENDAS MAPOCHO",
    "LIBRERIA EL PUENTE", "OPTICA LA LUPA", "CAMBIO ALAMEDA",
    "JUGOS LA FRUTA", "PAQUETERIA EL SUR", "BAZAR SANTA LUCIA",
    "RELOJERIA EL TIEMPO", "SEGUROS ACONCAGUA", "PERFUMERIA AROMA",
    "REPUESTOS ANDES",
]
SIGN_COLORS = [
    ("1d5f3a", "ffffff"), ("b3261e", "ffd84a"), ("1f3c88", "ffffff"),
    ("f2efe6", "7a1f2b"), ("e0a526", "2b1a0a"), ("2b2b2b", "5ce1e6"),
]


def hex_color(h: str) -> str:
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, 1)"


def rgb_color(c, k=1.0) -> str:
    return f"Color({min(c[0]*k/255,1):.3f}, {min(c[1]*k/255,1):.3f}, {min(c[2]*k/255,1):.3f}, 1)"


def basis_for(side: str) -> str:
    # Filas de la base (Godot serializa Transform3D por filas). La normal de un
    # QuadMesh/Label3D es +Z local; el eje u de la imagen es +X local.
    if side == "izq":   # Ry(+90): +Z -> +X, +X -> -Z
        return "0, 0, 1, 0, 1, 0, -1, 0, 0"
    return "0, 0, -1, 0, 1, 0, 1, 0, 0"  # Ry(-90): +Z -> -X, +X -> +Z


def f(v: float) -> str:
    return f"{v:.4f}".rstrip("0").rstrip(".") if "." in f"{v:.4f}" else str(v)


def main() -> None:
    info = {}
    for key, (path, pw, gf_line, signs) in IMAGES.items():
        im = Image.open(ROOT / path)
        W, H = im.size
        x0, y0, x1, y1 = im.split()[3].point(lambda v: 255 if v > 128 else 0).getbbox()
        bw, bh = x1 - x0, y1 - y0
        aspect = bw / bh
        w = min(IMG_MAX_W, IMG_MAX_H * aspect)
        h = w / aspect
        rgb = im.convert("RGB")
        wall = rgb.crop((int(W * .15), int(H * .25), int(W * .85), int(H * .6))).resize((1, 1), Image.BOX).getpixel((0, 0))
        sx = W / pw          # px del preview -> px de la imagen
        sy = H / PREVIEW_H

        def to_local(px, py):
            u = (px * sx - x0) / bw
            v = (py * sy - y0) / bh
            return (u - 0.5) * w, (1 - v) * h

        info[key] = dict(path=path, W=W, H=H, crop=(x0, y0, bw, bh), w=w, h=h, wall=wall,
                         gf_y=to_local(0, gf_line)[1],
                         signs=[(to_local(a, b), to_local(c, d)) for a, b, c, d in signs])

    ext, sub, nodes = [], [], []
    tex_id = {}
    for i, key in enumerate(info):
        tex_id[key] = f"{i + 1}_tex_{key}"
        ext.append(f'[ext_resource type="Texture2D" path="res://{info[key]["path"]}" id="{tex_id[key]}"]')

    # Materiales y mallas de cada imagen.
    for key, d in info.items():
        x0, y0, bw, bh = d["crop"]
        sub.append(f'[sub_resource type="StandardMaterial3D" id="Mat_{key}"]\n'
                   f'transparency = 2\nalpha_scissor_threshold = 0.5\n'
                   f'albedo_texture = ExtResource("{tex_id[key]}")\n'
                   f'roughness = 1.0\ntexture_filter = 4\n'
                   f'uv1_scale = Vector3({bw / d["W"]:.6f}, {bh / d["H"]:.6f}, 1)\n'
                   f'uv1_offset = Vector3({x0 / d["W"]:.6f}, {y0 / d["H"]:.6f}, 0)')
        sub.append(f'[sub_resource type="QuadMesh" id="Quad_{key}"]\n'
                   f'material = SubResource("Mat_{key}")\nsize = Vector2({d["w"]:.4f}, {d["h"]:.4f})')
        sub.append(f'[sub_resource type="StandardMaterial3D" id="MatRelieve_{key}"]\n'
                   f'albedo_color = {rgb_color(d["wall"], 0.85)}\nroughness = 0.95')
        sub.append(f'[sub_resource type="BoxMesh" id="Imposta_{key}"]\n'
                   f'material = SubResource("MatRelieve_{key}")\nsize = Vector3({d["w"]:.4f}, 0.18, 0.22)')

    sub.append('[sub_resource type="BoxMesh" id="Pilastra"]\nmaterial = SubResource("MatPilastra")\nsize = Vector3(0.4, 14, 0.35)')
    sub.insert(len(sub) - 1, '[sub_resource type="StandardMaterial3D" id="MatPilastra"]\nalbedo_color = Color(0.55, 0.5, 0.46, 1)\nroughness = 0.95')
    sub.append('[sub_resource type="StandardMaterial3D" id="MatCornisa"]\nalbedo_color = Color(0.62, 0.58, 0.53, 1)\nroughness = 0.95')
    sub.append('[sub_resource type="BoxMesh" id="Cornisa"]\nmaterial = SubResource("MatCornisa")\nsize = Vector3(10.2, 0.4, 0.55)')
    for ci, (bg, _) in enumerate(SIGN_COLORS):
        sub.append(f'[sub_resource type="StandardMaterial3D" id="MatLetrero_{ci}"]\nalbedo_color = {hex_color(bg)}\nroughness = 0.6')

    nodes.append('[node name="FachadasAhumada" type="Node3D"]')
    sign_n = 0
    box_n = 0
    for name, cx, cz, side, slots in BUILDINGS:
        fx = cx + (BOX_HALF_X if side == "izq" else -BOX_HALF_X)
        nodes.append(f'[node name="{name}" type="Node3D" parent="."]\n'
                     f'transform = Transform3D({basis_for(side)}, {fx}, 0, {cz})')
        for px in (-SLOT_WIDTH, 0, SLOT_WIDTH):
            nodes.append(f'[node name="Pilastra{box_n}" type="MeshInstance3D" parent="{name}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {f(px)}, 7, 0.175)\nmesh = SubResource("Pilastra")')
            box_n += 1
        for si, key in enumerate(slots):
            d = info[key]
            sxc = (si - 0.5) * SLOT_WIDTH
            mod = f"{name}/Modulo{si + 1}"
            nodes.append(f'[node name="Modulo{si + 1}" type="Node3D" parent="{name}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {f(sxc)}, 0, 0)')
            nodes.append(f'[node name="Imagen" type="MeshInstance3D" parent="{mod}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {d["h"] / 2 + GROUND_Y:.4f}, 0.04)\n'
                         f'cast_shadow = 0\nmesh = SubResource("Quad_{key}")')
            nodes.append(f'[node name="Cornisa" type="MeshInstance3D" parent="{mod}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {BOX_HEIGHT - 0.2}, 0.275)\nmesh = SubResource("Cornisa")')
            nodes.append(f'[node name="Imposta" type="MeshInstance3D" parent="{mod}"]\n'
                         f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {d["gf_y"] + GROUND_Y:.4f}, 0.11)\nmesh = SubResource("Imposta_{key}")')
            for li, ((ax, ay), (bx, by)) in enumerate(d["signs"]):
                sw, sh = (bx - ax) * 1.06 + 0.06, (ay - by) * 1.1 + 0.06
                mx, my = (ax + bx) / 2, (ay + by) / 2 + GROUND_Y
                bg, fg = SIGN_COLORS[sign_n % len(SIGN_COLORS)]
                text = SIGN_NAMES[sign_n % len(SIGN_NAMES)]
                mesh_id = f"LetreroMesh_{sign_n}"
                sub.append(f'[sub_resource type="BoxMesh" id="{mesh_id}"]\n'
                           f'material = SubResource("MatLetrero_{sign_n % len(SIGN_COLORS)}")\n'
                           f'size = Vector3({sw:.4f}, {sh:.4f}, 0.1)')
                # Ajusta el texto al letrero: ancho aprox. 0.6 * font_size px por letra.
                font_size = 64
                lines = [text] if sw / max(sh, 0.01) > 3 else text.split(" ", 1)
                longest = max(len(t) for t in lines)
                pixel = min(sh * 0.75 / (font_size * 1.25 * len(lines)), sw * 0.9 / (0.62 * font_size * longest))
                sign = f"{mod}/Letrero{li + 1}"
                nodes.append(f'[node name="Letrero{li + 1}" type="MeshInstance3D" parent="{mod}"]\n'
                             f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {mx:.4f}, {my:.4f}, 0.1)\nmesh = SubResource("{mesh_id}")')
                label_text = "\\n".join(lines)
                nodes.append(f'[node name="Texto" type="Label3D" parent="{sign}"]\n'
                             f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.052)\n'
                             f'pixel_size = {pixel:.5f}\ndouble_sided = false\ntexture_filter = 0\n'
                             f'modulate = {hex_color(fg)}\noutline_size = 0\n'
                             f'text = "{label_text}"\nfont_size = {font_size}')
                sign_n += 1

    out = "[gd_scene format=3]\n\n" + "\n".join(ext) + "\n\n" + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodes) + "\n"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(out, encoding="utf-8", newline="\n")
    print(f"escrito {OUT.relative_to(ROOT)}: {len(BUILDINGS)} edificios, {sign_n} letreros")
    for key, d in info.items():
        print(f"  {key}: {d['w']:.2f} x {d['h']:.2f} m, imposta y={d['gf_y']:.2f}, letreros {len(d['signs'])}")


if __name__ == "__main__":
    main()
