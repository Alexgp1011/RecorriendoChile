"""Genera las texturas pixel art de la Plaza de Armas en Asset/texturas/.

Herramienta de pipeline, no codigo del juego. Pixel art de baja resolucion con
una paleta comun (PALETA), a 16 px por metro: una textura repetible de 32 px
cubre 2 m. Todo es determinista (semilla fija): volver a ejecutar da los mismos
archivos.

Repetibles (32x32, 2 m): canteria, estuco, estuco_ocre, estuco_gris, teja,
fierro, cortina, toldo, madera_banca, pasto, granito, cupula.
Unicas: pavimento_plaza.png (640x640 = 40 x 40 m, el suelo entero de la plaza,
con senderos en cruz, anillo central y borde) y flor.png (sprite con fondo
transparente para las jardineras).

Uso, desde la raiz del proyecto:  python tools/texturas/generar_texturas.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Asset" / "texturas"
PX_POR_M = 16

# Paleta comun: todas las texturas toman sus colores de aqui.
PALETA = {
    "piedra": [(212, 198, 172), (196, 181, 155), (180, 166, 141), (160, 147, 124)],
    "junta_piedra": (122, 112, 96),
    "estuco": [(214, 196, 160), (204, 186, 150), (194, 176, 141)],
    "ocre": [(208, 168, 106), (196, 156, 96), (184, 144, 86)],
    "gris": [(188, 188, 182), (176, 176, 170), (164, 164, 158)],
    "teja": [(168, 92, 66), (150, 78, 56), (128, 64, 46)],
    "junta_teja": (92, 46, 34),
    "fierro": [(44, 50, 47), (34, 38, 36), (24, 27, 26)],
    "brillo_fierro": (78, 86, 82),
    "cortina": [(150, 152, 156), (128, 130, 134), (104, 106, 110)],
    "toldo": [(170, 44, 38), (232, 226, 214)],
    "madera": [(52, 112, 70), (42, 94, 58), (34, 78, 48)],
    "junta_madera": (20, 40, 26),
    "pasto": [(76, 128, 54), (92, 146, 62), (64, 108, 44), (108, 160, 72)],
    "granito": [(172, 170, 162), (158, 156, 150), (144, 142, 137), (130, 128, 124)],
    "junta_granito": (96, 94, 90),
    "sendero": [(206, 186, 152), (192, 172, 140), (176, 156, 126)],
    "junta_sendero": (138, 120, 96),
    "cupula": [(122, 146, 140), (106, 128, 123), (90, 110, 106)],
    "flores": [(206, 46, 52), (238, 196, 52), (228, 110, 160), (240, 240, 232)],
    "tallo": (48, 96, 40),
}


def ruido(img, rnd, colores, densidad=1.0):
    """Rellena con colores de la paleta, pixel a pixel (con algo de grano)."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if rnd.random() < densidad:
                px[x, y] = rnd.choice(colores)


def ladrillos(ancho, alto, fila, largo, colores, junta, rnd, desfase=True):
    """Aparejo de bloques: filas de alto `fila` y piezas de `largo` px."""
    img = Image.new("RGB", (ancho, alto))
    px = img.load()
    for y in range(alto):
        nfila = y // fila
        off = (largo // 2) if (desfase and nfila % 2) else 0
        for x in range(ancho):
            pieza = ((x + off) // largo, nfila)
            base = colores[hash((pieza, 7)) % len(colores)]
            if y % fila == 0 or (x + off) % largo == 0:
                px[x, y] = junta
            else:
                c = base if rnd.random() > 0.12 else rnd.choice(colores)
                px[x, y] = c
    return img


def canteria(rnd):
    return ladrillos(32, 32, 8, 16, PALETA["piedra"], PALETA["junta_piedra"], rnd)


def estuco(rnd, clave):
    img = Image.new("RGB", (32, 32))
    ruido(img, rnd, PALETA[clave])
    # una linea de junta horizontal cada 2 m (la textura entera): piso a piso
    d = ImageDraw.Draw(img)
    d.line([(0, 31), (31, 31)], fill=PALETA[clave][-1])
    return img


def teja(rnd):
    img = Image.new("RGB", (32, 32), PALETA["junta_teja"])
    px = img.load()
    for fila in range(4):
        y0 = fila * 8
        off = 4 if fila % 2 else 0
        for x in range(32):
            for dy in range(7):
                # tejas redondeadas: la parte baja de cada pieza es mas oscura
                local = (x + off) % 8
                if dy == 6 and local in (0, 7):
                    continue
                c = PALETA["teja"][0] if dy < 3 else PALETA["teja"][1] if dy < 6 else PALETA["teja"][2]
                if rnd.random() < 0.08:
                    c = rnd.choice(PALETA["teja"])
                px[x, y0 + dy] = c
    return img


def fierro(rnd):
    img = Image.new("RGB", (32, 32))
    ruido(img, rnd, PALETA["fierro"])
    px = img.load()
    for _ in range(10):
        px[rnd.randrange(32), rnd.randrange(32)] = PALETA["brillo_fierro"]
    return img


def cortina(rnd):
    img = Image.new("RGB", (32, 32))
    px = img.load()
    for y in range(32):
        c = PALETA["cortina"][0] if y % 4 == 0 else PALETA["cortina"][1] if y % 4 < 3 else PALETA["cortina"][2]
        for x in range(32):
            px[x, y] = c
    return img


def toldo(rnd):
    img = Image.new("RGB", (32, 32))
    px = img.load()
    for y in range(32):
        for x in range(32):
            px[x, y] = PALETA["toldo"][(x // 4) % 2]
    return img


def madera_banca(rnd):
    img = Image.new("RGB", (32, 32))
    px = img.load()
    for y in range(32):
        for x in range(32):
            if y % 8 == 7:
                px[x, y] = PALETA["junta_madera"]
            else:
                px[x, y] = PALETA["madera"][0] if rnd.random() > 0.25 else rnd.choice(PALETA["madera"])
    return img


def pasto(rnd):
    img = Image.new("RGB", (32, 32))
    ruido(img, rnd, PALETA["pasto"])
    return img


def granito(rnd):
    return ladrillos(32, 32, 16, 16, PALETA["granito"], PALETA["junta_granito"], rnd, desfase=False)


def cupula(rnd):
    return ladrillos(32, 32, 4, 8, PALETA["cupula"], PALETA["cupula"][-1], rnd)


def pavimento_plaza(rnd):
    """Suelo entero de la plaza: x -21..19, z -142..-102 (40 m, 640 px).
    Fila 0 = z -142, columna 0 = x -21 (como lo mapea suelo_plaza.tscn)."""
    lado = 40 * PX_POR_M
    base = granito(rnd)
    camino = ladrillos(32, 32, 8, 16, PALETA["sendero"], PALETA["junta_sendero"], rnd)
    img = Image.new("RGB", (lado, lado))
    for ty in range(0, lado, 32):
        for tx in range(0, lado, 32):
            img.paste(base, (tx, ty))
    capa_camino = Image.new("RGB", (lado, lado))
    for ty in range(0, lado, 32):
        for tx in range(0, lado, 32):
            capa_camino.paste(camino, (tx, ty))
    mascara = Image.new("L", (lado, lado), 0)
    d = ImageDraw.Draw(mascara)
    m = PX_POR_M
    cx, cz = (-1 + 21) * m, (-122 + 142) * m          # centro de la plaza
    d.rectangle([cx - int(1.5 * m), 0, cx + int(1.5 * m), lado], fill=255)      # sendero norte-sur
    d.rectangle([0, cz - int(1.5 * m), lado, cz + int(1.5 * m)], fill=255)      # sendero oriente-poniente
    d.rectangle([0, 0, lado, 2 * m], fill=255)                                  # borde perimetral
    d.rectangle([0, lado - 2 * m, lado, lado], fill=255)
    d.rectangle([0, 0, 2 * m, lado], fill=255)
    d.rectangle([lado - 2 * m, 0, lado, lado], fill=255)
    d.ellipse([cx - 6 * m, cz - 6 * m, cx + 6 * m, cz + 6 * m], fill=255)        # anillo central
    img.paste(capa_camino, (0, 0), mascara)
    # roseta central: circulos concentricos de granito oscuro
    di = ImageDraw.Draw(img)
    for r, c in ((4.0, PALETA["junta_granito"]), (3.6, PALETA["granito"][0]), (1.2, PALETA["junta_granito"]),
                 (0.9, PALETA["granito"][3])):
        di.ellipse([cx - r * m, cz - r * m, cx + r * m, cz + r * m], fill=c)
    di.ellipse([cx - 6 * m, cz - 6 * m, cx + 6 * m, cz + 6 * m], outline=PALETA["junta_sendero"])
    return img


def flor(rnd):
    """Mata de flores (16x16, fondo transparente)."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = img.load()
    for x in range(2, 14, 2):
        alto = rnd.randint(5, 10)
        for y in range(15, 15 - alto, -1):
            px[x, y] = PALETA["tallo"] + (255,)
        c = rnd.choice(PALETA["flores"]) + (255,)
        top = 15 - alto
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, -1)):
            if 0 <= x + dx < 16 and 0 <= top + dy < 16:
                px[x + dx, top + dy] = c
    return img


def palmera(rnd):
    """PROVISIONAL (se reemplaza por arte de /asset-spec). 48x80 px = 3 x 5 m."""
    img = Image.new("RGBA", (48, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    tronco = [(118, 92, 62, 255), (98, 74, 48, 255), (82, 60, 38, 255)]
    for y in range(22, 80):
        x = 24 + int(2 * ((80 - y) / 58) ** 2)          # leve curva
        for dx in (-2, -1, 0, 1):
            c = tronco[0] if dx < 0 else tronco[1]
            if y % 4 == 0:
                c = tronco[2]                             # anillos del tronco
            img.putpixel((x + dx, y), c)
    verdes = [(54, 120, 52, 255), (72, 146, 62, 255), (40, 96, 42, 255)]
    cx, cy = 26, 22
    for ang_deg in range(0, 360, 18):
        a = math.radians(ang_deg)
        largo = rnd.randint(15, 21)
        for t in range(largo):
            caida = (t / largo) ** 2 * 7                   # las hojas caen hacia afuera
            x = int(cx + math.cos(a) * t)
            y = int(cy + math.sin(a) * t * 0.55 + caida)
            for dy in (-1, 0, 1):
                if 0 <= x < 48 and 0 <= y + dy < 80:
                    img.putpixel((x, y + dy), verdes[(t + dy) % 3])
    d.ellipse([cx - 3, cy - 2, cx + 3, cy + 3], fill=(96, 78, 44, 255))   # cocos
    return img


def arbol(rnd):
    """PROVISIONAL (se reemplaza por arte de /asset-spec). 64x80 px = 4 x 5 m."""
    img = Image.new("RGBA", (64, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([29, 44, 34, 79], fill=(98, 74, 48, 255))
    d.rectangle([29, 44, 30, 79], fill=(118, 92, 62, 255))
    hojas = [(46, 104, 46, 255), (62, 128, 56, 255), (36, 86, 38, 255), (84, 150, 70, 255)]
    for _ in range(26):
        x, y, r = rnd.randint(12, 52), rnd.randint(8, 46), rnd.randint(7, 11)
        d.ellipse([x - r, y - r, x + r, y + r], fill=rnd.choice(hojas[:3]))
    for _ in range(40):
        x, y = rnd.randint(8, 56), rnd.randint(4, 50)
        if img.getpixel((x, y))[3]:
            img.putpixel((x, y), hojas[3])
    return img


def estatua_ecuestre(rnd):
    """PROVISIONAL (se reemplaza por arte de /asset-spec). Jinete a caballo, bronce
    patinado. 40x40 px = 2.5 x 2.5 m."""
    img = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bronce, sombra, luz = (70, 104, 92, 255), (48, 74, 66, 255), (104, 140, 124, 255)
    d.ellipse([8, 18, 30, 29], fill=bronce)                          # cuerpo del caballo
    for x0 in (10, 14, 24, 27):                                      # patas
        d.rectangle([x0, 27, x0 + 2, 39], fill=sombra)
    d.polygon([(26, 21), (31, 10), (35, 11), (33, 22)], fill=bronce)  # cuello
    d.polygon([(31, 10), (38, 13), (37, 16), (32, 14)], fill=bronce)  # cabeza
    d.polygon([(8, 22), (3, 30), (5, 31), (10, 25)], fill=sombra)    # cola
    d.rectangle([17, 8, 22, 19], fill=bronce)                        # jinete
    d.ellipse([17, 2, 22, 8], fill=bronce)                           # cabeza del jinete
    d.line([(22, 10), (28, 4)], fill=bronce, width=2)                # brazo en alto
    for x, y in ((18, 9), (12, 20), (28, 13)):
        img.putpixel((x, y), luz)
    return img


TEXTURAS = {
    "canteria": canteria, "estuco": lambda r: estuco(r, "estuco"),
    "estuco_ocre": lambda r: estuco(r, "ocre"), "estuco_gris": lambda r: estuco(r, "gris"),
    "teja": teja, "fierro": fierro, "cortina": cortina, "toldo": toldo,
    "madera_banca": madera_banca, "pasto": pasto, "granito": granito, "cupula": cupula,
    "pavimento_plaza": pavimento_plaza, "flor": flor,
    # Sprites PROVISIONALES: se reemplazan por el arte definitivo de /asset-spec.
    "palmera": palmera, "arbol": arbol, "estatua_ecuestre": estatua_ecuestre,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for nombre, hacer in TEXTURAS.items():
        rnd = random.Random(f"recorriendo-chile:{nombre}")
        img = hacer(rnd)
        img.save(OUT / f"{nombre}.png")
        print(f"  {nombre}.png {img.width}x{img.height}")


if __name__ == "__main__":
    main()
