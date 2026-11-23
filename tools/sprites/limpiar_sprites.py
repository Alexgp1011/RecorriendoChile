"""Genera las hojas limpias y las SpriteFrames del policia y el ladron, y la
mano con el cartel.

Herramienta de pipeline, no codigo del juego. Lee las hojas ORIGINALES de
Asset/ (no las modifica) y escribe en Asset/sprites/:

- <personaje>_limpio.png: cada figura extraida por su silueta (componentes
  conexas del alfa), sin trozos de cuadros vecinos ni extremidades cortadas;
  alfa binario (los originales estan a 250-253, casi opacos, y Godot los
  dibuja como transparentes); celdas iguales con los pies en la misma linea
  y el cuerpo centrado por su centro de masa.
- <personaje>_frames.tres: SpriteFrames con todas las animaciones.

Policia: cada grupo de la hoja esta dibujado a otra escala (reposo 245 px,
caminar 219, detencion 193-203): todos se igualan a 219. La hoja trae vistas
de frente, de espaldas y de lado (mirando a la derecha; la izquierda es la
misma con flip_h, lo decide Policia_Visual.gd).

Las animaciones que ya existian conservan sus cuadros, orden, velocidad y
bucle. Las escenas pasan a usar el .tres y el sprite se coloca con los pies
en la base de la capsula de colision.

Uso, desde la raiz del proyecto:  python tools/sprites/limpiar_sprites.py
"""
import re
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from componentes import componentes  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
UMBRAL = 127      # alfa minimo para contar como figura
PAD = 4           # margen transparente alrededor de cada figura en su celda

# Figuras: nombre -> (x0, y0) de su silueta en la hoja original, y grupo de
# escala (las figuras de un grupo se escalan juntas a la altura de referencia).
POLICIA = dict(
    escena="Scene/policia.tscn", hoja="Asset/Hoja de sprites de soldado antidisturbios retro.png",
    nombre="policia", pies_y=0.0,   # base de la capsula (centro 0.9, alto 1.8)
    altura_ref=219, motas_en_celda=None,
    figuras={
        "reposo": (32, 72, "reposo"),
        "frente1": (23, 386, "caminar"), "frente2": (155, 386, "caminar"), "frente3": (280, 386, "caminar"),
        "lado1": (438, 385, "caminar"), "lado2": (571, 387, "caminar"), "lado3": (696, 386, "caminar"),
        "espalda1": (862, 386, "caminar"), "espalda2": (985, 385, "caminar"), "espalda3": (1111, 385, "caminar"),
        "det_frente1": (15, 690, "det_frente"), "det_frente2": (129, 690, "det_frente"),
        "det_frente4": (326, 690, "det_frente"),
        "det_lado1": (447, 686, "det_lado"), "det_lado2": (563, 686, "det_lado"), "det_lado3": (677, 686, "det_lado"),
        "det_espalda1": (851, 685, "det_espalda"), "det_espalda2": (978, 685, "det_espalda"),
        "det_espalda3": (1108, 685, "det_espalda"),
    },
    # nombre: (figuras, velocidad, bucle). Las cuatro primeras son las que ya
    # tenia el juego (vista de frente), con sus mismos cuadros.
    animaciones={
        "arrest": (["det_frente1", "det_frente2", "det_frente4"], 5.0, True),
        "chase": (["frente1", "frente2", "frente3", "det_frente1"], 5.0, True),
        "idle": (["reposo"], 5.0, True),
        "walk": (["frente1", "frente2", "frente3"], 4.0, True),
        "arrest_espalda": (["det_espalda1", "det_espalda2", "det_espalda3"], 5.0, False),
        "arrest_lado": (["det_lado1", "det_lado2", "det_lado3"], 5.0, False),
        "chase_espalda": (["espalda1", "espalda2", "espalda3"], 5.0, True),
        "chase_lado": (["lado1", "lado2", "lado3"], 5.0, True),
        "idle_espalda": (["espalda2"], 5.0, True),
        "idle_lado": (["lado2"], 5.0, True),
        "walk_espalda": (["espalda1", "espalda2", "espalda3"], 4.0, True),
        "walk_lado": (["lado1", "lado2", "lado3"], 4.0, True),
    },
)
LADRON = dict(
    escena="Scene/enemy.tscn", hoja="Asset/flaite2.png",
    nombre="ladron", pies_y=-1.2886,   # base de la capsula (centro -0.2886, alto 2.0)
    altura_ref=None, motas_en_celda=396,   # gotas de sangre de su celda de 396 px
    figuras={
        "guardia": (106, 42, None), "paso_a": (455, 42, None), "embestida": (884, 33, None),
        "paso_b": (1263, 39, None), "paso_c": (1652, 42, None),
        "muerte1": (478, 439, None), "muerte2": (868, 454, None),
        "muerte3": (1241, 492, None), "muerte4": (1608, 617, None),
    },
    animaciones={
        "death": (["paso_c", "muerte1", "muerte2", "muerte3", "muerte4"], 8.0, False),
        "walk": (["guardia", "paso_c", "paso_a", "paso_b"], 5.0, True),
        "robo": (["embestida"], 5.0, False),
    },
)


def binarizar(img):
    r, g, b, a = img.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: 255 if v > UMBRAL else 0)))


def extraer(hoja, sel):
    """RGBA con solo los pixeles conectados a las componentes `sel`."""
    x0 = min(c["x0"] for c in sel); y0 = min(c["y0"] for c in sel)
    x1 = max(c["x1"] for c in sel); y1 = max(c["y1"] for c in sel)
    recorte = hoja.crop((x0, y0, x1, y1))
    W, H = recorte.size
    alpha = recorte.getchannel("A").load()
    mask = Image.new("L", recorte.size, 0)
    m = mask.load()
    for c in sel:
        # semilla: un pixel de esta componente (no el primero visible de su
        # rectangulo, que puede ser de otra: una gota de sangre)
        pila = [(c["seed"][0] - x0, c["seed"][1] - y0)]
        while pila:
            xx, yy = pila.pop()
            if m[xx, yy]:
                continue
            m[xx, yy] = 255
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = xx + dx, yy + dy
                    if 0 <= nx < W and 0 <= ny < H and not m[nx, ny] and alpha[nx, ny] > UMBRAL:
                        pila.append((nx, ny))
    limpio = Image.new("RGBA", recorte.size, (0, 0, 0, 0))
    limpio.paste(recorte, (0, 0), mask)
    return binarizar(limpio), (x0, y0)


def centro_masa_x(img):
    W = img.width
    tot = sx = 0
    for i, v in enumerate(img.getchannel("A").tobytes()):
        if v:
            tot += 1
            sx += i % W
    return sx / tot if tot else W / 2


def procesar(cfg):
    hoja = Image.open(ROOT / cfg["hoja"]).convert("RGBA")
    comps = componentes(str(ROOT / cfg["hoja"]), UMBRAL)
    grandes = [c for c in comps if c["px"] >= 400]
    motas = [c for c in comps if c["px"] < 400]

    figs = {}
    for nombre, (fx, fy, grupo) in cfg["figuras"].items():
        principal = min(grandes, key=lambda c: abs(c["x0"] - fx) + abs(c["y0"] - fy))
        assert abs(principal["x0"] - fx) + abs(principal["y0"] - fy) <= 6, (nombre, principal)
        sel = [principal]
        celda = cfg["motas_en_celda"]
        if celda and principal["y0"] >= celda:          # solo la fila de muerte
            cx0, cy0 = (principal["x0"] // celda) * celda, (principal["y0"] // celda) * celda
            sel += [m for m in motas if cx0 <= (m["x0"] + m["x1"]) / 2 < cx0 + celda
                    and cy0 <= (m["y0"] + m["y1"]) / 2 < cy0 + celda]
        figs[nombre] = dict(sel=sel, principal=principal, grupo=grupo)

    # escala por grupo: altura media del grupo -> altura_ref
    escala = {}
    if cfg["altura_ref"]:
        grupos = {}
        for f in figs.values():
            grupos.setdefault(f["grupo"], []).append(f["principal"]["y1"] - f["principal"]["y0"])
        escala = {g: cfg["altura_ref"] / (sum(v) / len(v)) for g, v in grupos.items()}

    for nombre, f in figs.items():
        img, _ = extraer(hoja, f["sel"])
        s = escala.get(f["grupo"], 1.0)
        if abs(s - 1) > 0.01:
            img = binarizar(img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS))
        f["img"], f["cx"] = img, centro_masa_x(img)

    medio = max(max(f["cx"], f["img"].width - f["cx"]) for f in figs.values())
    cw = int(2 * medio) + 2 * PAD
    ch = max(f["img"].height for f in figs.values()) + 2 * PAD
    salida = Image.new("RGBA", (cw * len(figs), ch), (0, 0, 0, 0))
    for i, (nombre, f) in enumerate(figs.items()):
        salida.alpha_composite(f["img"], (i * cw + round(cw / 2 - f["cx"]), ch - PAD - f["img"].height))
        f["region"] = (i * cw, 0, cw, ch)
    hoja_out = f"Asset/sprites/{cfg['nombre']}_limpio.png"
    (ROOT / hoja_out).parent.mkdir(parents=True, exist_ok=True)
    salida.save(ROOT / hoja_out)
    print(f"  {cfg['nombre']}: {len(figs)} figuras, celda {cw}x{ch} -> {hoja_out}")

    # SpriteFrames
    tres = [f'[gd_resource type="SpriteFrames" format=3]', "",
            f'[ext_resource type="Texture2D" path="res://{hoja_out}" id="1_hoja"]', ""]
    for nombre, f in figs.items():
        x, y, w, h = f["region"]
        tres += [f'[sub_resource type="AtlasTexture" id="Cuadro_{nombre}"]', 'atlas = ExtResource("1_hoja")',
                 f"region = Rect2({x}, {y}, {w}, {h})", ""]
    anims = []
    for nombre, (cuadros, vel, bucle) in cfg["animaciones"].items():
        frames = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("Cuadro_%s")\n}' % c for c in cuadros)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                     % (frames, "true" if bucle else "false", nombre, vel))
    tres += ["[resource]", "animations = [" + ", ".join(anims) + "]", ""]
    tres_out = f"Asset/sprites/{cfg['nombre']}_frames.tres"
    (ROOT / tres_out).write_text("\n".join(tres), encoding="utf-8", newline="\n")
    print(f"  {cfg['nombre']}: {len(cfg['animaciones'])} animaciones -> {tres_out}")
    return tres_out, ch


def actualizar_escena(cfg, tres_out, ch):
    p = ROOT / cfg["escena"]
    s = p.read_text(encoding="utf-8")
    nl = "\n"
    s = s.replace("\r\n", "\n")
    ruta = "res://" + tres_out
    bloques = s.split(nl + nl)
    if ruta not in s:
        # quitar las SpriteFrames y AtlasTexture incrustadas y la hoja que usaban
        bloques = [b for b in bloques if not re.match(r'\[sub_resource type="(SpriteFrames|AtlasTexture)"', b)]
        s = (nl + nl).join(bloques)
        for l in [l for l in s.split(nl) if l.startswith("[ext_resource") and "/sprites/" in l and "_limpio.png" in l]:
            s = s.replace(l + nl, "")
        ultima = [l for l in s.split(nl) if l.startswith("[ext_resource")][-1]
        s = s.replace(ultima, ultima + nl + f'[ext_resource type="SpriteFrames" path="{ruta}" id="92_frames"]', 1)
        s = re.sub(r'sprite_frames = SubResource\("[^"]+"\)', 'sprite_frames = ExtResource("92_frames")', s)
        assert 'SubResource("Atlas' not in s and 'SubResource("SpriteFrames' not in s
    # sprite: pies de la celda (ch - PAD) sobre la base de la capsula
    cab = re.search(r'\[node name="AnimatedSprite3D" type="AnimatedSprite3D"[^\n]*', s)
    i = cab.start()
    j = s.index(nl + nl, i)
    blk = s[i:j]
    px = float(re.search(r"pixel_size = ([0-9.]+)", blk).group(1))
    y = cfg["pies_y"] + (ch / 2 - PAD) * px
    blk = re.sub(r"(transform = Transform3D\(1, 0, 0, 0, 1, 0, 0, 0, 1, )([-0-9.e]+), ([-0-9.e]+), ([-0-9.e]+)\)",
                 lambda m: f"{m.group(1)}{m.group(2)}, {y:.4f}, {m.group(4)})", blk)
    for prop in ("texture_filter = 0", "alpha_cut = 1"):
        if prop.split(" =")[0] not in blk:
            blk = blk.replace("billboard = 2", f"billboard = 2{nl}{prop}")
    s = s[:i] + blk + s[j:]
    p.write_text(s, encoding="utf-8", newline="\n")
    print(f"  {cfg['escena']}: usa {tres_out}, sprite y={y:.4f}")


def cartel():
    """Solo la mano con el cartel (la hoja tiene ademas tres punos)."""
    src = "Asset/Puños y cartel pixelado NO + CAE.png"
    hoja = Image.open(ROOT / src).convert("RGBA")
    comps = [c for c in componentes(str(ROOT / src), UMBRAL) if c["px"] >= 400]
    principal = max(comps, key=lambda c: c["px"])          # el cartel con su mano
    img, (x0, y0) = extraer(hoja, [principal])
    salida = "Asset/sprites/cartel_mano.png"
    img.save(ROOT / salida)
    off_x = x0 + img.width / 2 - hoja.width / 2
    off_y = y0 + img.height / 2 - hoja.height / 2
    print(f"  cartel: {img.width}x{img.height}, offset ({off_x:.1f}, {off_y:.1f}) -> {salida}")
    p = ROOT / "Scene/player.tscn"
    s = p.read_text(encoding="utf-8").replace("\r\n", "\n")
    if "res://" + salida in s:
        print("  Scene/player.tscn: ya usa la mano limpia")
        return
    ultima = [l for l in s.split("\n") if l.startswith("[ext_resource")][-1]
    s = s.replace(ultima, ultima + "\n" + f'[ext_resource type="Texture2D" path="res://{salida}" id="91_cartel"]', 1)
    cab = re.search(r'\[node name="CartelSprite" type="Sprite2D"[^\n]*', s)
    i = cab.start()
    j = s.find("\n\n", i)
    j = len(s.rstrip()) if j == -1 else j
    blk = re.sub(r'texture = ExtResource\("[^"]+"\)', 'texture = ExtResource("91_cartel")', s[i:j])
    blk += f"\noffset = Vector2({off_x:.1f}, {off_y:.1f})"
    p.write_text(s[:i] + blk + s[j:], encoding="utf-8", newline="\n")
    print("  Scene/player.tscn: CartelSprite usa solo la mano con el cartel")


if __name__ == "__main__":
    for cfg in (POLICIA, LADRON):
        tres_out, ch = procesar(cfg)
        actualizar_escena(cfg, tres_out, ch)
    cartel()
