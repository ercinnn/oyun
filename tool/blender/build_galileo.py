"""Bilim İnsanları / Galileo — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/galileo.glb`'ye gider; her parça isimli bir kök
gruptur (`GlbModelLibrary`).

Kimlikler Dart ile aynı olmalıdır:
- `galileo_figure`: sakallı, siyah cüppeli Galileo (yüzü -y, 1.75 boy).
- `galileo_telescope`: ahşap ayak üstünde deri kaplı tüp. `TubeTilt` (ayak
  tepesinde, y ekseni etrafında 25° yukarı eğik) içinde dış tüp ve oyun
  tarafında tüp ekseni (-x) boyunca kaydırılan `DrawTube` (göz merceği
  tarafı) vardır: odak ayarı gerçekten görünsün.
- `galileo_balcony`: 7 × 4 taş teras, arkada korkuluk (y = +1.8), iki sütun.
- `galileo_desk`: masa, açık defter (Jüpiter çizimleri), mum, tüy kalem.
- `galileo_jupiter`: kuşaklı Jüpiter, yarıçap 1, merkez z = 0.

Koordinatlar: z yukarı, ön yüz -y (three'de +z); 1 birim = 1 m (Jüpiter hariç).

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_galileo.py", encoding="utf-8").read())
    build_all(); show_all(); reset_positions(); roots()
"""

import os

import bpy
import math

_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())

TILT_DEG = 25

M = {}


def materials():
    M.update(
        skin=mat("gl_skin", 0xE0A77F, 0.7),
        beard=mat("gl_beard", 0xB8AFA6, 0.9),
        hair=mat("gl_hair", 0x9E9690, 0.9),
        robe=mat("gl_robe", 0x1F1F24, 0.85),
        fur=mat("gl_fur", 0x6D5A4A, 0.95),
        collar=mat("gl_collar", 0xF5F2EA, 0.8),
        eye=mat("gl_eye", 0x212121, 0.4),
        shoe=mat("gl_shoe", 0x3E2723, 0.6),
        leather=mat("gl_leather", 0x8B3A2B, 0.7),
        leather_dark=mat("gl_leather_dark", 0x5A2419, 0.75),
        gold=mat("gl_gold", 0xD4AF37, 0.35, metal=0.9),
        lens=mat("gl_lens", 0x9FD3F0, 0.08),
        wood=mat("gl_wood", 0x8D5A34, 0.8),
        wood_dark=mat("gl_wood_dark", 0x5D3A22, 0.85),
        stone=mat("gl_stone", 0xD8CBB3, 0.9),
        stone_dark=mat("gl_stone_dark", 0xB9A98C, 0.9),
        paper=mat("gl_paper", 0xF3E9D2, 0.95),
        ink=mat("gl_ink", 0x3B2F2F, 0.8),
        wax=mat("gl_wax", 0xF7F1E1, 0.8),
        flame=mat("gl_flame", 0xFFC107, 0.4, emit=1.0),
        quill=mat("gl_quill", 0xF5F5F5, 0.9),
        j_light=mat("gl_j_light", 0xE9D7B4, 0.8),
        j_band=mat("gl_j_band", 0xC08B5C, 0.8),
        j_dark=mat("gl_j_dark", 0x9C6B45, 0.85),
        j_spot=mat("gl_j_spot", 0xC0503A, 0.8),
    )


def rotated(ob, loc, rot):
    ob.rotation_euler = rot
    ob.location = loc
    return ob


def build_figure():
    begin("galileo_figure")
    lathe("gf_robe", [(0.0, 0.0), (0.4, 0.0), (0.36, 0.5), (0.3, 1.0), (0.3, 1.3),
                      (0.18, 1.42), (0.0, 1.44)], M["robe"], 22)
    # Kürk yaka + beyaz iç yaka.
    torus("gf_fur", 0, 0, 1.36, 0.24, 0.07, M["fur"], 24, 8)
    lathe("gf_collar", [(0.0, 1.38), (0.14, 1.4), (0.15, 1.45), (0.0, 1.47)],
          M["collar"], 14, 0, -0.04, 0)
    # Cüppenin önünde koyu bir şerit ve düğmeler.
    box("gf_front", 0, -0.33, 0.1, 0.06, 0.02, 1.15, M["fur"])
    for side in (-1, 1):
        box(f"gf_shoe{side}", side * 0.12, -0.1, 0, 0.12, 0.24, 0.06, M["shoe"])
    sphere("gf_head", 0, 0, 1.6, 0.16, M["skin"], 16, 10)
    sphere("gf_nose", 0, -0.16, 1.59, 0.03, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"gf_eye{side}", side * 0.06, -0.14, 1.63, 0.02, M["eye"], 8, 5)
    # Kır sakal ve bıyık, arkaya taranmış seyrek saç.
    sphere("gf_beard", 0, -0.08, 1.46, 0.15, M["beard"], 14, 8, sz=1.2, sy=0.8)
    sphere("gf_moustache", 0, -0.15, 1.53, 0.07, M["beard"], 10, 6, sz=0.35, sx=1.4)
    sphere("gf_hair", 0, 0.04, 1.63, 0.165, M["hair"], 14, 8, sz=0.8)
    # Kollar: sağ yanda, sol eli öne uzanmış (teleskoba dokunur gibi).
    rotated(cyl("gf_arm_r", 0, 0, 0, 0.07, 0.55, M["robe"], 8), (0.31, 0, 0.75), (0, -0.12, 0))
    sphere("gf_hand_r", 0.34, 0, 0.72, 0.055, M["skin"], 8, 5)
    rotated(cyl("gf_arm_l", 0, 0, 0, 0.07, 0.5, M["robe"], 8), (-0.3, 0, 1.28), (1.9, 0, 0))
    sphere("gf_hand_l", -0.3, -0.47, 1.1, 0.055, M["skin"], 8, 5)


def build_telescope():
    """Ayak tepesi z = 1.2. Tüp ekseni `TubeTilt`'in yerel x'i: objektif +x
    ucunda (x = +0.55), göz merceği -x ucunda. `DrawTube` yerel x = 0'da
    içeride; oyun onu -x yönünde en çok 0.5 kaydırır."""
    global _parent
    root = begin("galileo_telescope")
    # Üç ayaklı sehpa.
    for i in range(3):
        a = 2 * math.pi * i / 3 + math.pi / 2
        leg = cyl(f"gt_leg{i}", 0, 0, 0, 0.025, 1.25, M["wood_dark"], 6)
        leg.rotation_euler = (0.28 * math.sin(a), -0.28 * math.cos(a), 0)
        leg.location = (0.32 * math.cos(a), 0.32 * math.sin(a), 0)
    cyl("gt_head", 0, 0, 1.12, 0.07, 0.1, M["wood"], 10)

    tilt = group("TubeTilt")
    tilt.parent = root
    tilt.location = (0, 0, 1.24)
    tilt.rotation_euler = (0, -math.radians(TILT_DEG), 0)
    _parent = tilt
    # Dış tüp (x: -0.35 … +0.55), altın şeritler, objektif ağzı.
    rotated(cyl("gt_tube", 0, 0, 0, 0.055, 0.9, M["leather"], 18, r_top=0.065),
            (-0.35, 0, 0), (0, math.pi / 2, 0))
    for i, x in enumerate((-0.33, 0.05, 0.5)):
        rotated(cyl(f"gt_band{i}", 0, 0, 0, 0.068, 0.03, M["gold"], 18),
                (x, 0, 0), (0, math.pi / 2, 0))
    rotated(cyl("gt_objective", 0, 0, 0, 0.058, 0.01, M["lens"], 18),
            (0.55, 0, 0), (0, math.pi / 2, 0))
    # Kaydırılan iç tüp + göz merceği.
    draw = group("DrawTube")
    draw.parent = tilt
    _parent = draw
    rotated(cyl("gt_draw", 0, 0, 0, 0.045, 0.6, M["leather_dark"], 16),
            (-0.6, 0, 0), (0, math.pi / 2, 0))
    rotated(cyl("gt_eyecap", 0, 0, 0, 0.05, 0.04, M["gold"], 16),
            (-0.62, 0, 0), (0, math.pi / 2, 0))
    rotated(cyl("gt_eyepiece", 0, 0, 0, 0.03, 0.005, M["lens"], 12),
            (-0.625, 0, 0), (0, math.pi / 2, 0))
    _parent = root


def build_balcony():
    begin("galileo_balcony")
    for i in range(7):
        for j in range(4):
            m = M["stone"] if (i + j) % 2 == 0 else M["stone_dark"]
            box(f"gb_tile{i}_{j}", -3 + i, -1.5 + j, -0.12, 0.98, 0.98, 0.12, m)
    # Arka korkuluk: alt/üst kiriş + babalar.
    box("gb_rail_base", 0, 1.8, 0, 7, 0.3, 0.12, M["stone_dark"])
    box("gb_rail_top", 0, 1.8, 0.9, 7, 0.34, 0.1, M["stone_dark"])
    for i in range(22):
        x = -3.3 + i * 0.315
        lathe(f"gb_baluster{i}", [(0.07, 0.12), (0.1, 0.3), (0.05, 0.5), (0.09, 0.7),
                                  (0.06, 0.9)], M["stone"], 10, x, 1.8, 0)
    for side in (-1, 1):
        cyl(f"gb_col_base{side}", side * 3.2, 1.8, 0, 0.3, 0.2, M["stone_dark"], 14)
        lathe(f"gb_col{side}", [(0.22, 0.2), (0.2, 2.5), (0.18, 3.4)], M["stone"], 14,
              side * 3.2, 1.8, 0)
        box(f"gb_col_cap{side}", side * 3.2, 1.8, 3.4, 0.6, 0.6, 0.14, M["stone_dark"])


def build_desk():
    begin("galileo_desk")
    box("gd_top", 0, 0, 0.72, 1.3, 0.7, 0.06, M["wood"])
    for i, (x, y) in enumerate(((-0.6, -0.3), (0.6, -0.3), (0.6, 0.3), (-0.6, 0.3))):
        box(f"gd_leg{i}", x, y, 0, 0.07, 0.07, 0.72, M["wood_dark"])
    # Açık defter: iki sayfa, sağ sayfada Galileo'nun çizimleri gibi O ve *'lar.
    for side in (-1, 1):
        rotated(box(f"gd_page{side}", 0, 0, 0, 0.26, 0.34, 0.012, M["paper"]),
                (side * 0.14, -0.05, 0.785), (0, side * -0.06, 0))
    for row in range(4):
        y = -0.17 + row * 0.08
        sphere(f"gd_jup{row}", 0.14, y, 0.8, 0.012, M["ink"], 8, 5, sz=0.3)
        for k, dx in enumerate(((-0.07, 0.05), (-0.04, 0.08), (0.06, 0.1), (-0.09, 0.03))[row]):
            sphere(f"gd_star{row}_{k}", 0.14 + dx, y, 0.8, 0.006, M["ink"], 6, 4, sz=0.3)
    # Mum + alev, tüy kalem.
    cyl("gd_candle_plate", -0.45, 0.15, 0.78, 0.07, 0.015, M["gold"], 12)
    cyl("gd_candle", -0.45, 0.15, 0.795, 0.03, 0.18, M["wax"], 10)
    sphere("gd_flame", -0.45, 0.15, 1.0, 0.022, M["flame"], 8, 6, sz=1.8)
    rotated(cyl("gd_quill", 0, 0, 0, 0.006, 0.3, M["quill"], 5), (0.45, 0.12, 0.78), (0.9, 0, 0.5))
    cyl("gd_inkpot", 0.45, 0.18, 0.75, 0.035, 0.05, M["ink"], 10)


def build_jupiter():
    """Kuşaklı Jüpiter: **tek** pürüzsüz küre, kuşaklar yüz başına malzemeyle
    boyanır (ayrı ayrı döndürme yüzeyleri her kuşağı şişkin bir halka gibi
    gölgelendiriyordu) + Büyük Kırmızı Leke."""
    begin("galileo_jupiter")
    ob = sphere("gj_body", 0, 0, 0, 1.0, M["j_light"], 40, 36)
    bands = [(-90, -60, "j_band"), (-60, -35, "j_light"), (-35, -18, "j_dark"),
             (-18, -6, "j_light"), (-6, 8, "j_band"), (8, 22, "j_light"),
             (22, 38, "j_dark"), (38, 60, "j_light"), (60, 90, "j_band")]
    slots = []
    for _, _, m in bands:
        if M[m] not in slots:
            slots.append(M[m])
    ob.data.materials.clear()
    for m in slots:
        ob.data.materials.append(m)
    for poly_ in ob.data.polygons:
        lat = math.degrees(math.asin(max(-1.0, min(1.0, poly_.center.z))))
        for lat0, lat1, m in bands:
            if lat0 <= lat <= lat1:
                poly_.material_index = slots.index(M[m])
                break
    sphere("gj_spot", 0.0, -0.93, -0.36, 0.14, M["j_spot"], 12, 8, sz=0.55, sx=1.5, sy=0.4)


ROOT_PREFIXES = ("galileo_",)


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_figure()
    build_telescope()
    build_balcony()
    build_desk()
    build_jupiter()
    x = 0.0
    for name in roots():
        bpy.data.objects[name].location = (x, 0, 0)
        x += 8 if name == "galileo_balcony" else 2.5
    return roots()


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
