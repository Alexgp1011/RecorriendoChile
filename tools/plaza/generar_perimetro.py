"""Genera Scene/plaza/perimetro.tscn: los edificios y el suelo alrededor de la Plaza de Armas.

Herramienta de pipeline, no codigo del juego. Paso 2 del plan de la Plaza:
volumenes 3D a escala, colores planos (las texturas pixel art vienen despues).

Se instancia en Escenario/PlazaDeArmas/Perimetro con transformacion identidad:
las coordenadas son las del mundo. Lados (la Catedral ocupa el poniente, x < -21):
  - sur (z < -142): edificio historico con torre del reloj
  - oriente (x > 19): edificio de portales, con soportales transitables
  - esquina norponiente: entre la torre norte de la Catedral y la entrada
  - fin de Ahumada (z -84 a -102): los dos edificios que flanquean la entrada

Restricciones (comprobadas con assert):
  - nada solido dentro del area de ataque de Rey Palomo (x -18..16, z -145.7..-111.7
    alrededor de la arena) -> no agrega refugios;
  - los trayectos de vuelo de Rey Palomo entre sus marcadores no atraviesan
    ningun edificio (el flanco izquierdo de Ahumada queda bajo: 4.5 m).

Uso, desde la raiz del proyecto:  python tools/plaza/generar_perimetro.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Scene" / "plaza" / "perimetro.tscn"

# Marcadores de vuelo de Rey Palomo (world.tscn) y area de ataque
VUELO = {
    "Vuelo01": (-16.7, 6.0, -131.8), "Vuelo02": (7.6, 6.0, -128.3),
    "Vuelo03": (7.0, 6.0, -106.9), "Vuelo04": (-18.1, 6.0, -106.6),
    "Vuelo05": (-7.7, 12.0, -87.6), "Vuelo06": (-10.3, 18.0, -43.5),
}
CRUZ = (-20.7, 20.3, -123.3)
# Area de ataque (cuadrado de 34 m en la arena) recortada al suelo original de la
# plaza (x -21..19, z -142..-102): fuera de ese suelo las marcas ya se descartaban
# antes, asi que un edificio ahi no quita ninguna marca que antes existiera.
ATAQUE = (-18.0, 16.0, -142.0, -111.7)   # x0, x1, z0, z1
MEDIO_ALTO_JEFE = 1.6                     # media altura aprox. del sprite de Rey Palomo

COLORES = {
    "estuco": (0.80, 0.72, 0.58), "estuco_ocre": (0.78, 0.62, 0.40),
    "estuco_gris": (0.70, 0.70, 0.68), "moldura": (0.90, 0.86, 0.78),
    "ventana": (0.10, 0.11, 0.14), "puerta": (0.22, 0.15, 0.10),
    "cortina": (0.45, 0.46, 0.48), "toldo": (0.55, 0.16, 0.14),
    "techo": (0.40, 0.33, 0.28), "reloj": (0.93, 0.92, 0.85),
    "aguja": (0.08, 0.08, 0.08), "suelo": (0.62, 0.60, 0.56),
}

sub, nodos, mallas = [], ['[node name="PerimetroPlaza" type="Node3D"]'], {}
solidos = []   # (nombre, x0, x1, y0, y1, z0, z1) de todo lo que tiene colision


def f(v):
    return f"{v:.3f}".rstrip("0").rstrip(".")


def vec(*v):
    return "Vector3(" + ", ".join(f(x) for x in v) + ")"


def tr(x, y, z, basis="1, 0, 0, 0, 1, 0, 0, 0, 1"):
    return f"Transform3D({basis}, {f(x)}, {f(y)}, {f(z)})"


def solido(nombre, x0, x1, y0, y1, z0, z1, color, padre="."):
    """Volumen con colision (CSGBox3D), dado por sus limites."""
    solidos.append((nombre, x0, x1, y0, y1, z0, z1))
    nodos.append(f'[node name="{nombre}" type="CSGBox3D" parent="{padre}"]\n'
                 f'transform = {tr((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)}\nuse_collision = true\n'
                 f'size = {vec(x1 - x0, y1 - y0, z1 - z0)}\nmaterial = SubResource("Mat_{color}")')


def malla(nombre, tipo, props, color, centro, padre=".", basis="1, 0, 0, 0, 1, 0, 0, 0, 1"):
    clave = (tipo, props, color)
    if clave not in mallas:
        mallas[clave] = f"{tipo}_{len(mallas)}"
        sub.append(f'[sub_resource type="{tipo}" id="{mallas[clave]}"]\nmaterial = SubResource("Mat_{color}")\n{props}')
    nodos.append(f'[node name="{nombre}" type="MeshInstance3D" parent="{padre}"]\n'
                 f'transform = {tr(*centro, basis=basis)}\nmesh = SubResource("{mallas[clave]}")')


def caja(nombre, centro, tam, color, padre="."):
    malla(nombre, "BoxMesh", f"size = {vec(*tam)}", color, centro, padre)


def grupo(nombre):
    nodos.append(f'[node name="{nombre}" type="Node3D" parent="."]')


def ventanas(padre, eje, plano, a0, a1, pisos, alto_piso, y0, ancho=1.3, alto=1.8, paso=3.0, signo=1, prefijo="Ventana"):
    """Ventanas oscuras sobre una fachada. eje='x': la fachada mira a +/-x en x=plano
    y las ventanas avanzan por z de a0 a a1; eje='z': mira a +/-z y avanzan por x."""
    n = 0
    for p in range(pisos):
        y = y0 + p * alto_piso + alto_piso * 0.55
        a = a0 + paso / 2
        while a < a1 - paso / 2 + 0.01:
            n += 1
            if eje == "x":
                caja(f"{prefijo}{n}", (plano + signo * 0.05, y, a), (0.1, alto, ancho), "ventana", padre)
            else:
                caja(f"{prefijo}{n}", (a, y, plano + signo * 0.05), (ancho, alto, 0.1), "ventana", padre)
            a += paso


def main():
    for nombre, (r, g, b) in COLORES.items():
        sub.append(f'[sub_resource type="StandardMaterial3D" id="Mat_{nombre}"]\n'
                   f'albedo_color = Color({r}, {g}, {b}, 1)\nroughness = 0.95')

    # --- Suelo alrededor (por debajo del de la plaza y de Ahumada) -------------
    nodos.append('[node name="SueloPerimetro" type="CSGBox3D" parent="."]\n'
                 f'transform = {tr(-6.0, -0.22, -122.0)}\nuse_collision = true\n'
                 f'size = {vec(84.0, 0.3, 76.0)}\nmaterial = SubResource("Mat_suelo")')

    # --- Sur: edificio historico con torre del reloj ---------------------------
    grupo("EdificioReloj")
    solido("Cuerpo", -46.0, 33.0, 0.0, 13.0, -156.0, -142.5, "estuco", "EdificioReloj")
    caja("Cornisa", (-6.5, 13.2, -142.2), (79.0, 0.5, 0.8), "moldura", "EdificioReloj")
    caja("Imposta", (-6.5, 4.6, -142.35), (79.0, 0.3, 0.5), "moldura", "EdificioReloj")
    ventanas("EdificioReloj", "z", -142.5, -46.0, 33.0, 2, 4.4, 4.6, signo=1)
    for i, x in enumerate(range(-40, 30, 6)):
        caja(f"Puerta{i + 1}", (x + 1.5, 1.6, -142.45), (1.8, 3.2, 0.1), "puerta", "EdificioReloj")
    solido("Torre", -4.0, 2.0, 13.0, 24.0, -148.5, -142.5, "estuco", "EdificioReloj")
    caja("TorreRemate", (-1.0, 24.3, -145.5), (6.6, 0.6, 6.6), "moldura", "EdificioReloj")
    malla("TorreTecho", "CylinderMesh", "top_radius = 0.0\nbottom_radius = 4.3\nheight = 3.5\nradial_segments = 4",
          "techo", (-1.0, 26.35, -145.5), "EdificioReloj", basis="0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071")
    # Esfera del reloj mirando a la plaza (+z): cilindro plano girado 90 grados en X
    malla("Reloj", "CylinderMesh", "top_radius = 1.6\nbottom_radius = 1.6\nheight = 0.12\nradial_segments = 16",
          "reloj", (-1.0, 19.5, -142.4), "EdificioReloj", basis="1, 0, 0, 0, 0, -1, 0, 1, 0")
    caja("AgujaHora", (-1.0, 19.9, -142.3), (0.15, 0.9, 0.05), "aguja", "EdificioReloj")
    caja("AgujaMinuto", (-0.45, 19.5, -142.3), (1.1, 0.12, 0.05), "aguja", "EdificioReloj")

    # --- Oriente: edificio de portales con soportales ---------------------------
    grupo("Portales")
    solido("Pisos", 19.2, 33.0, 5.0, 15.0, -142.5, -102.0, "estuco_ocre", "Portales")
    solido("Locales", 22.0, 33.0, 0.0, 5.0, -142.5, -102.0, "estuco_ocre", "Portales")
    caja("Cornisa", (19.0, 15.2, -122.25), (0.8, 0.5, 40.5), "moldura", "Portales")
    caja("Viga", (19.3, 4.75, -122.25), (0.4, 0.5, 40.5), "moldura", "Portales")
    z = -140.5
    n = 0
    while z <= -103.5:
        n += 1
        solido(f"Pilar{n}", 19.3, 19.9, 0.0, 5.0, z - 0.3, z + 0.3, "moldura", "Portales")
        caja(f"Vitrina{n}", (22.05 - 0.1, 1.9, z + 1.5), (0.1, 2.8, 2.0), "ventana", "Portales")
        z += 3.0
    ventanas("Portales", "x", 19.2, -142.5, -102.0, 3, 3.3, 5.0, signo=-1)

    # --- Esquina norponiente, junto a la torre norte de la Catedral -------------
    grupo("EsquinaNorponiente")
    solido("Cuerpo", -46.0, -21.5, 0.0, 14.0, -108.3, -96.0, "estuco_gris", "EsquinaNorponiente")
    caja("Cornisa", (-21.1, 14.2, -102.15), (0.8, 0.5, 12.3), "moldura", "EsquinaNorponiente")
    ventanas("EsquinaNorponiente", "x", -21.5, -108.3, -96.0, 4, 3.4, 0.0, signo=1)

    # --- Fin de Ahumada: los dos edificios que flanquean la entrada --------------
    # Izquierdo bajo (4.5 m): los vuelos de Vuelo04 a Vuelo05/06 pasan a ~7 m por aqui.
    grupo("FlancoIzquierdo")
    solido("Locales", -21.5, -9.0, 0.0, 4.5, -102.0, -84.0, "estuco", "FlancoIzquierdo")
    for i, zc in enumerate((-99.0, -94.5, -90.0, -85.5)):
        caja(f"Cortina{i + 1}", (-8.95, 1.5, zc), (0.1, 3.0, 3.6), "cortina", "FlancoIzquierdo")
        caja(f"Toldo{i + 1}", (-8.5, 3.4, zc), (1.0, 0.12, 3.8), "toldo", "FlancoIzquierdo")
    caja("Cornisa", (-9.2, 4.65, -93.0), (0.5, 0.3, 18.0), "moldura", "FlancoIzquierdo")
    grupo("FlancoDerecho")
    solido("Cuerpo", 9.0, 19.0, 0.0, 14.0, -102.0, -84.0, "estuco_ocre", "FlancoDerecho")
    caja("Cornisa", (8.8, 14.2, -93.0), (0.5, 0.5, 18.0), "moldura", "FlancoDerecho")
    ventanas("FlancoDerecho", "x", 9.0, -102.0, -84.0, 3, 3.4, 3.6, signo=-1)
    for i, zc in enumerate((-98.5, -93.0, -87.5)):
        caja(f"Cortina{i + 1}", (8.95, 1.5, zc), (0.1, 3.0, 4.0), "cortina", "FlancoDerecho")
    ventanas("FlancoDerecho", "z", -102.0, 9.0, 19.0, 3, 3.4, 3.6, signo=1, prefijo="VentanaPlaza")

    comprobar()
    # Godot no carga bien dos hijos con el mismo nombre: detenerse si los hay.
    vistos = set()
    for bloque in nodos:
        cab = bloque.split("\n", 1)[0]
        nombre = cab.split('name="')[1].split('"')[0]
        padre = cab.split('parent="')[1].split('"')[0] if 'parent="' in cab else ""
        assert (padre, nombre) not in vistos, f"nombre repetido: {padre}/{nombre}"
        vistos.add((padre, nombre))
    out = "[gd_scene format=3]\n\n" + "\n\n".join(sub) + "\n\n" + "\n\n".join(nodos) + "\n"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(out, encoding="utf-8", newline="\n")
    print(f"escrito {OUT.relative_to(ROOT)}: {len(nodos)} nodos, {len(solidos)} volumenes con colision")


def comprobar():
    ax0, ax1, az0, az1 = ATAQUE
    for n, x0, x1, y0, y1, z0, z1 in solidos:
        dentro = x0 < ax1 and x1 > ax0 and z0 < az1 and z1 > az0 and y1 > 1.2
        assert not dentro, f"{n} seria un refugio dentro del area de ataque"
    # Trayectos rectos entre cualquier par de marcadores (y hacia la cruz):
    # el jefe, con su media altura, no debe atravesar ningun volumen.
    puntos = dict(VUELO, Cruz=CRUZ)
    nombres = list(puntos)
    for i, a in enumerate(nombres):
        for b in nombres[i + 1:]:
            pa, pb = puntos[a], puntos[b]
            for k in range(201):
                t = k / 200
                x, y, z = (pa[j] + (pb[j] - pa[j]) * t for j in range(3))
                for n, x0, x1, y0, y1, z0, z1 in solidos:
                    if x0 < x < x1 and z0 < z < z1 and y - MEDIO_ALTO_JEFE < y1 and y + MEDIO_ALTO_JEFE > y0:
                        raise AssertionError(f"el vuelo {a}->{b} atraviesa {n} en ({x:.1f}, {y:.1f}, {z:.1f})")


if __name__ == "__main__":
    main()
