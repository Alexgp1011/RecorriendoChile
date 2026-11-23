"""Silhouette analysis for sprite sheets (Pillow only, no numpy).

componentes(path, umbral) -> list of dicts {x0,y0,x1,y1,px,cx,seed}: 8-connected
regions of alpha > umbral, with bbox (x1/y1 exclusive), pixel count and the
alpha-weighted horizontal centre of mass. seed = (x, y) of one pixel that
belongs to the region (a bbox can also contain pixels of other regions). Tool code, not game code.
"""
from PIL import Image


def componentes(path, umbral=127):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    alpha = im.getchannel("A").tobytes()
    vis = bytearray(W * H)
    out = []
    for start in range(W * H):
        if vis[start] or alpha[start] <= umbral:
            continue
        stack = [start]
        vis[start] = 1
        x0 = y0 = 10 ** 9
        x1 = y1 = -1
        n = 0
        sx = 0
        while stack:
            p = stack.pop()
            y, x = divmod(p, W)
            n += 1
            sx += x
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
            for dy in (-1, 0, 1):
                yy = y + dy
                if yy < 0 or yy >= H:
                    continue
                base = yy * W
                for dx in (-1, 0, 1):
                    xx = x + dx
                    if 0 <= xx < W:
                        q = base + xx
                        if not vis[q] and alpha[q] > umbral:
                            vis[q] = 1
                            stack.append(q)
        sy0, sx0 = divmod(start, W)
        out.append(dict(x0=x0, y0=y0, x1=x1 + 1, y1=y1 + 1, px=n, cx=sx / n, seed=(sx0, sy0)))
    return out
