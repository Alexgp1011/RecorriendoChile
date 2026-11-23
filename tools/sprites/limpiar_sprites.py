"""Limpia las hojas de sprites del policia, el ladron y la mano con el cartel.

Herramienta de pipeline, no codigo del juego. Lee las hojas ORIGINALES de
Asset/ (no las modifica) y escribe hojas nuevas en Asset/sprites/:

- cada figura se extrae por su silueta (componentes conexas del canal alfa),
  asi ningun cuadro arrastra trozos del vecino ni corta extremidades;
- el alfa queda binario (0 o 255): los originales tienen el cuerpo a 250-253,
  casi opaco, lo que Godot dibuja como transparente (orden de dibujado);
- todas las figuras de un personaje van en celdas iguales, con los pies en la
  misma linea y el cuerpo centrado por su centro de masa: no "saltan";
- el policia tiene cada fila dibujada a otra escala (reposo 245 px, caminar
  219, detencion 193): se igualan a la altura de caminar.

Luego actualiza las escenas: cada AtlasTexture conserva su id y su lugar en la
animacion (mismas animaciones, mismos cuadros, mismo orden); cambian la hoja,
el recorte y la altura del sprite para que los pies toquen el suelo de la
capsula de colision.

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

# Recortes originales de cada AtlasTexture (de las escenas antes del cambio):
# se usan solo para saber que figura mostraba cada cuadro.
PERSONAJES = {
    "policia": dict(
        escena="Scene/policia.tscn",
        hoja="Asset/Hoja de sprites de soldado antidisturbios retro.png",
        salida="Asset/sprites/policia_limpio.png",
        nodo="AnimatedSprite3D",
        pies_y=0.0,             # base de la capsula (centro 0.9, alto 1.8)
        altura_ref=219,         # altura de la fila "caminar"
        normalizar=True,
        cuadros={
            "AtlasTexture_ptbof": (0, 626, 127, 313), "AtlasTexture_tw3g5": (118, 626, 118, 313),
            "AtlasTexture_w538q": (327, 626, 109, 313), "AtlasTexture_6djkh": (0, 326, 149, 326),
            "AtlasTexture_e8evr": (140, 326, 140, 326), "AtlasTexture_63a4x": (280, 326, 140, 326),
            "AtlasTexture_5jcle": (0, 626, 127, 313), "AtlasTexture_s2ou2": (0, 0, 179, 335),
        },
        motas_en_celda=False,
    ),
    "ladron": dict(
        escena="Scene/enemy.tscn",
        hoja="Asset/flaite2.png",
        salida="Asset/sprites/ladron_limpio.png",
        nodo="AnimatedSprite3D",
        pies_y=-1.2886,         # base de la capsula (centro -0.2886, alto 2.0)
        altura_ref=None,
        normalizar=False,
        cuadros={
            "AtlasTexture_hti8k": (1584, 0, 396, 396), "AtlasTexture_44hyy": (396, 396, 396, 396),
            "AtlasTexture_0qcj2": (792, 396, 396, 396), "AtlasTexture_5op34": (1188, 396, 396, 396),
            "AtlasTexture_r6llc": (1584, 396, 396, 396), "AtlasTexture_00taw": (0, 0, 396, 396),
            "AtlasTexture_lgux2": (1584, 0, 396, 396), "AtlasTexture_r3ffy": (396, 0, 396, 396),
            "AtlasTexture_5jr7y": (1188, 0, 396, 396),
        },
        motas_en_celda=True,    # gotas de sangre de la fila de muerte
    ),
}


def solape(a, r):
    x, y, w, h = r
    ox = max(0, min(a["x1"], x + w) - max(a["x0"], x))
    oy = max(0, min(a["y1"], y + h) - max(a["y0"], y))
    return ox * oy


def binarizar(img):
    r, g, b, a = img.split()
    a = a.point(lambda v: 255 if v > UMBRAL else 0)
    return Image.merge("RGBA", (r, g, b, a))


def extraer(hoja, comps, sel):
    """Imagen RGBA con solo los pixeles de las componentes `sel`."""
    x0 = min(c["x0"] for c in sel); y0 = min(c["y0"] for c in sel)
    x1 = max(c["x1"] for c in sel); y1 = max(c["y1"] for c in sel)
    recorte = hoja.crop((x0, y0, x1, y1))
    # mascara: solo los pixeles conectados a las componentes elegidas
    mask = Image.new("L", recorte.size, 0)
    alpha = recorte.getchannel("A")
    elegidas = [c for c in sel]
    W = x1 - x0
    px_alpha = alpha.load()
    m = mask.load()
    # relleno por inundacion desde cada componente elegida dentro del recorte
    for c in elegidas:
        # semilla: un pixel que pertenece a esta componente (no el primero
        # visible de su rectangulo, que puede ser de otra: una gota de sangre)
        pila = [(c["seed"][0] - x0, c["seed"][1] - y0)]
        while pila:
            xx, yy = pila.pop()
            if m[xx, yy]:
                continue
            m[xx, yy] = 255
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = xx + dx, yy + dy
                    if 0 <= nx < W and 0 <= ny < recorte.height and not m[nx, ny] and px_alpha[nx, ny] > UMBRAL:
                        pila.append((nx, ny))
    limpio = Image.new("RGBA", recorte.size, (0, 0, 0, 0))
    limpio.paste(recorte, (0, 0), mask)
    return binarizar(limpio), (x0, y0)


def centro_masa_x(img):
    a = img.getchannel("A")
    W, H = img.size
    datos = a.tobytes()
    tot = sx = 0
    for i, v in enumerate(datos):
        if v:
            tot += 1
            sx += i % W
    return sx / tot if tot else W / 2


def procesar(nombre, cfg):
    hoja = Image.open(ROOT / cfg["hoja"]).convert("RGBA")
    comps = componentes(str(ROOT / cfg["hoja"]), UMBRAL)
    grandes = [c for c in comps if c["px"] >= 400]
    motas = [c for c in comps if c["px"] < 400]

    # figura principal de cada cuadro = la componente grande con mas solape
    figuras = {}
    for atlas_id, r in cfg["cuadros"].items():
        principal = max(grandes, key=lambda c: solape(c, r))
        sel = [principal]
        if cfg["motas_en_celda"]:
            x, y, w, h = r
            sel += [m for m in motas if x <= (m["x0"] + m["x1"]) / 2 < x + w and y <= (m["y0"] + m["y1"]) / 2 < y + h]
        clave = (principal["x0"], principal["y0"])
        figuras.setdefault(clave, dict(sel=sel, ids=[], principal=principal))
        figuras[clave]["ids"].append(atlas_id)

    # escala por fila (policia): la altura media de la fila -> altura_ref
    def fila(c):
        return round(c["y0"] / 150)
    alturas = {}
    for f in figuras.values():
        alturas.setdefault(fila(f["principal"]), []).append(f["principal"]["y1"] - f["principal"]["y0"])
    escala_fila = {k: (cfg["altura_ref"] / (sum(v) / len(v)) if cfg["normalizar"] else 1.0) for k, v in alturas.items()}

    imgs = []
    for clave, f in sorted(figuras.items()):
        img, _ = extraer(hoja, comps, f["sel"])
        s = escala_fila[fila(f["principal"])]
        if abs(s - 1) > 0.01:
            img = binarizar(img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS))
        f["img"], f["cx"], f["escala"] = img, centro_masa_x(img), s
        imgs.append(img)

    # celda comun: cabe la figura mas ancha a ambos lados de su centro de masa
    medio = max(max(f["cx"], f["img"].width - f["cx"]) for f in figuras.values())
    cw = int(2 * medio) + 2 * PAD
    ch = max(i.height for i in imgs) + 2 * PAD
    n = len(figuras)
    salida = Image.new("RGBA", (cw * n, ch), (0, 0, 0, 0))
    regiones = {}
    for i, (clave, f) in enumerate(sorted(figuras.items())):
        x = i * cw + round(cw / 2 - f["cx"])
        y = ch - PAD - f["img"].height          # pies sobre la misma linea
        salida.alpha_composite(f["img"], (x, y))
        for atlas_id in f["ids"]:
            regiones[atlas_id] = (i * cw, 0, cw, ch)
        print(f"  {nombre}: figura {i + 1} {f['img'].width}x{f['img'].height} escala {f['escala']:.3f} -> {', '.join(f['ids'])}")
    (ROOT / cfg["salida"]).parent.mkdir(parents=True, exist_ok=True)
    salida.save(ROOT / cfg["salida"])
    print(f"  {nombre}: hoja {salida.width}x{salida.height}, celda {cw}x{ch} -> {cfg['salida']}")
    return regiones, ch


def actualizar_escena(cfg, regiones, ch):
    p = ROOT / cfg["escena"]
    s = p.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in s else "\n"
    ruta = "res://" + cfg["salida"]
    if ruta in s:
        print(f"  {cfg['escena']}: ya usa {ruta}; no se cambia")
        return
    ext_id = "90_limpio"
    ultima = [l for l in s.split(nl) if l.startswith("[ext_resource")][-1]
    s = s.replace(ultima, ultima + nl + f'[ext_resource type="Texture2D" path="{ruta}" id="{ext_id}"]', 1)
    for atlas_id, (x, y, w, h) in regiones.items():
        cab = f'[sub_resource type="AtlasTexture" id="{atlas_id}"]'
        i = s.index(cab)
        j = s.index(nl + nl, i)
        blk = s[i:j]
        blk = re.sub(r'atlas = ExtResource\("[^"]+"\)', f'atlas = ExtResource("{ext_id}")', blk)
        blk = re.sub(r"region = Rect2\([^)]*\)", f"region = Rect2({x}, {y}, {w}, {h})", blk)
        s = s[:i] + blk + s[j:]
    # sprite: pies de la celda (ch - PAD) sobre la base de la capsula
    cab = re.search(r'\[node name="' + cfg["nodo"] + r'" type="AnimatedSprite3D"[^\r\n]*', s)
    i = cab.start()
    j = s.index(nl + nl, i)
    blk = s[i:j]
    px = float(re.search(r"pixel_size = ([0-9.]+)", blk).group(1))
    y = cfg["pies_y"] + (ch / 2 - PAD) * px
    blk = re.sub(r"(transform = Transform3D\(1, 0, 0, 0, 1, 0, 0, 0, 1, )([-0-9.e]+), ([-0-9.e]+), ([-0-9.e]+)\)",
                 lambda m: f"{m.group(1)}{m.group(2)}, {y:.4f}, {m.group(4)})", blk)
    if "texture_filter" not in blk:
        blk = blk.replace(f"billboard = 2", f"billboard = 2{nl}texture_filter = 0")
    if "alpha_cut" not in blk:
        blk = blk.replace(f"billboard = 2", f"billboard = 2{nl}alpha_cut = 1")
    s = s[:i] + blk + s[j:]
    p.write_text(s, encoding="utf-8", newline="")
    print(f"  {cfg['escena']}: {len(regiones)} cuadros reasignados, sprite y={y:.4f}")


def cartel():
    """Solo la mano con el cartel (la hoja tiene ademas tres punos)."""
    src = "Asset/Puños y cartel pixelado NO + CAE.png"
    hoja = Image.open(ROOT / src).convert("RGBA")
    comps = [c for c in componentes(str(ROOT / src), UMBRAL) if c["px"] >= 400]
    principal = max(comps, key=lambda c: c["px"])          # el cartel con su mano
    img, (x0, y0) = extraer(hoja, comps, [principal])
    salida = "Asset/sprites/cartel_mano.png"
    img.save(ROOT / salida)
    # mismo lugar en pantalla: el centro de la imagen nueva respecto al centro
    # de la hoja completa que mostraba antes el Sprite2D (centered = true)
    off_x = x0 + img.width / 2 - hoja.width / 2
    off_y = y0 + img.height / 2 - hoja.height / 2
    print(f"  cartel: {img.width}x{img.height} desde ({x0},{y0}), offset ({off_x:.1f}, {off_y:.1f}) -> {salida}")
    p = ROOT / "Scene/player.tscn"
    s = p.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in s else "\n"
    ruta = "res://" + salida
    if ruta in s:
        print("  Scene/player.tscn: ya usa la mano limpia; no se cambia")
        return
    ultima = [l for l in s.split(nl) if l.startswith("[ext_resource")][-1]
    s = s.replace(ultima, ultima + nl + f'[ext_resource type="Texture2D" path="{ruta}" id="91_cartel"]', 1)
    cab = re.search(r'\[node name="CartelSprite" type="Sprite2D"[^\r\n]*', s)
    i = cab.start()
    j = s.find(nl + nl, i)
    j = len(s.rstrip()) if j == -1 else j
    blk = s[i:j]
    blk = re.sub(r'texture = ExtResource\("[^"]+"\)', 'texture = ExtResource("91_cartel")', blk)
    blk += f"{nl}offset = Vector2({off_x:.1f}, {off_y:.1f})"
    s = s[:i] + blk + s[j:]
    p.write_text(s, encoding="utf-8", newline="")
    print("  Scene/player.tscn: CartelSprite usa solo la mano con el cartel")


if __name__ == "__main__":
    for nombre, cfg in PERSONAJES.items():
        regiones, ch = procesar(nombre, cfg)
        actualizar_escena(cfg, regiones, ch)
    cartel()
