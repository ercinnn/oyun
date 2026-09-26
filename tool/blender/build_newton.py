"""Bilim İnsanları / Newton — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/newton.glb`'ye gider; her parça isimli bir kök
gruptur ve oyun tarafı (`GlbModelLibrary`) yalnızca gerekeni kopyalar.

Kimlikler Dart ile birebir aynı olmalıdır:
- `fall_<id>`: `lib/data/newton_objects.dart`'taki düşen cisimler. Kule 6 m
  olduğu için cisimler görünsün diye gerçek boylarının ~3 katıdır.
- `newton_tower` (üstü z = 6), `newton_tree`, `newton_figure`.
- Prizma: `newton_room`, `newton_table` (üstü z = 0.9), `newton_lamp`
  (ışık +x yönüne, delik yüksekliği z = 0.25 masadan), `newton_prism`
  (camı oyun tarafında saydam boyanır: `prism_glass*` parçaları),
  `newton_screen` (perde düzlemi x = 0).
- Pist: `newton_cart` (hareket +x, tekerlekler `Wheel*`), `newton_box`,
  `newton_launcher` (itici; içindeki `Plunger` oyun tarafında ileri itilir).

Koordinatlar: z yukarı, grup kökü tabanın ortasında, ön yüz -y (three'de +z);
1 birim = 1 m.

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_newton.py", encoding="utf-8").read())
    build_all()
    show_all()          # dışa aktarmadan önce ŞART
    reset_positions()   # önizleme yerleşimini geri al
    roots()
"""

import os

import bpy
import math

_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())

TOWER_HEIGHT = 6.0
TABLE_TOP = 0.9

M = {}


def materials():
    M.update(
        wood=mat("nw_wood", 0xA9713F, 0.85),
        wood_dark=mat("nw_wood_dark", 0x6D4527, 0.85),
        wood_light=mat("nw_wood_light", 0xD2A56C, 0.8),
        iron=mat("nw_iron", 0x5F6A72, 0.4, metal=0.8),
        brass=mat("nw_brass", 0xC9A227, 0.35, metal=0.9),
        red=mat("nw_red", 0xC62828, 0.6),
        apple=mat("nw_apple", 0xD7263D, 0.5),
        leaf=mat("nw_leaf", 0x4CAF50, 0.75),
        leaf_dark=mat("nw_leaf_dark", 0x2E7D32, 0.8),
        bark=mat("nw_bark", 0x6D4C41, 0.95),
        feather=mat("nw_feather", 0xF5F5F5, 0.9),
        quill=mat("nw_quill", 0xBDBDBD, 0.6),
        bowling=mat("nw_bowling", 0x283593, 0.25),
        tennis=mat("nw_tennis", 0xD4E157, 0.9),
        tennis_line=mat("nw_tennis_line", 0xFAFAFA, 0.9),
        paper=mat("nw_paper", 0xFAFAF2, 0.95),
        paper_line=mat("nw_paper_line", 0x90CAF9, 0.95),
        balloon=mat("nw_balloon", 0xE91E63, 0.35),
        string=mat("nw_string", 0xEEEEEE, 0.9),
        stone=mat("nw_stone", 0x9E9E9E, 0.95),
        skin=mat("nw_skin", 0xE8B48F, 0.7),
        wig=mat("nw_wig", 0x8D6E63, 0.95),
        coat=mat("nw_coat", 0x3E2723, 0.85),
        coat_trim=mat("nw_coat_trim", 0xC9A227, 0.5, metal=0.6),
        cravat=mat("nw_cravat", 0xFAFAFA, 0.8),
        stocking=mat("nw_stocking", 0xEEEEEE, 0.8),
        shoe=mat("nw_shoe", 0x212121, 0.5),
        eye=mat("nw_eye", 0x212121, 0.4),
        glass=mat("nw_glass", 0xB3E5FC, 0.1),
        wall=mat("nw_wall", 0xEFE6D6, 0.95),
        floor=mat("nw_floor", 0x8D6E63, 0.9),
        shutter=mat("nw_shutter", 0x5D4037, 0.9),
        lantern=mat("nw_lantern", 0x37474F, 0.5, metal=0.5),
        flame=mat("nw_flame", 0xFFD54F, 0.4, emit=0.8),
        screen=mat("nw_screen", 0xFFFFFF, 0.95),
        book1=mat("nw_book1", 0x1565C0, 0.8),
        book2=mat("nw_book2", 0x8E24AA, 0.8),
        book3=mat("nw_book3", 0xEF6C00, 0.8),
        cart=mat("nw_cart", 0x1E88E5, 0.55),
        cart_trim=mat("nw_cart_trim", 0xFDD835, 0.55),
        tire=mat("nw_tire", 0x263238, 0.7),
        box=mat("nw_box", 0xC68A4E, 0.85),
        box_band=mat("nw_box_band", 0x6D4C41, 0.85),
        spring=mat("nw_spring", 0xB0BEC5, 0.3, metal=0.9),
        launcher=mat("nw_launcher", 0x455A64, 0.6),
    )


def rotated(ob, loc, rot):
    """Orijinde kurulmuş parçayı döndürüp yerine koyar (bkz. yardımcıların
    başındaki tuzak notu)."""
    ob.rotation_euler = rot
    ob.location = loc
    return ob


# ─────────────────────────── Düşen cisimler ───────────────────────────


def build_fall_objects():
    begin("fall_apple")
    lathe("fall_apple_body", [(0, 0.02), (0.07, 0.0), (0.12, 0.05), (0.14, 0.12),
                              (0.12, 0.2), (0.07, 0.23), (0.02, 0.21), (0, 0.2)],
          M["apple"], 20)
    cyl("fall_apple_stem", 0, 0, 0.2, 0.01, 0.07, M["bark"], 6)
    sphere("fall_apple_leaf", 0.04, 0, 0.26, 0.045, M["leaf"], 8, 5, sz=0.25, sy=0.5)

    begin("fall_feather")
    # Tüy: yere paralel yatan uzun, ince, hafif kavisli yaprak + sap.
    rotated(cyl("fall_feather_quill", 0, 0, 0, 0.008, 0.55, M["quill"], 6),
            (-0.28, 0, 0.03), (0, math.pi / 2, 0))
    verts, faces = [], []
    n = 10
    for i in range(n + 1):
        u = i / n
        x = -0.2 + u * 0.47
        w = 0.07 * math.sin(math.pi * min(1.0, u * 1.1)) + 0.01
        z = 0.03 + 0.04 * math.sin(math.pi * u)
        verts += [(x, -w, z), (x, w, z)]
    for i in range(n):
        a, b = 2 * i, 2 * (i + 1)
        faces += [(a, b, b + 1, a + 1), (a + 1, b + 1, b, a)]
    poly("fall_feather_vane", verts, faces, M["feather"])

    begin("fall_hammer")
    rotated(cyl("fall_hammer_handle", 0, 0, 0, 0.025, 0.55, M["wood"], 8),
            (-0.3, 0, 0.05), (0, math.pi / 2, 0))
    box("fall_hammer_head", 0.25, 0, 0.0, 0.1, 0.26, 0.1, M["iron"])

    begin("fall_bowling")
    sphere("fall_bowling_body", 0, 0, 0.3, 0.3, M["bowling"], 22, 12)
    for i, (x, y) in enumerate(((0.06, -0.25), (-0.05, -0.26), (0.0, -0.2))):
        sphere(f"fall_bowling_hole{i}", x, y - 0.03, 0.42, 0.035, M["tire"], 8, 5)

    begin("fall_tennis")
    sphere("fall_tennis_body", 0, 0, 0.1, 0.1, M["tennis"], 16, 10)
    torus("fall_tennis_seam", 0, 0, 0.1, 0.098, 0.006, M["tennis_line"], 24, 4)

    begin("fall_paper_flat")
    box("fall_paper_flat_sheet", 0, 0, 0, 0.6, 0.45, 0.006, M["paper"])
    for i in range(5):
        box(f"fall_paper_flat_line{i}", 0, -0.15 + i * 0.07, 0.006, 0.5, 0.008, 0.001,
            M["paper_line"])

    begin("fall_paper_ball")
    sphere("fall_paper_ball_body", 0, 0, 0.14, 0.15, M["paper"], 7, 5)

    begin("fall_balloon")
    lathe("fall_balloon_body", [(0, 0.12), (0.06, 0.13), (0.2, 0.26), (0.26, 0.45),
                                (0.2, 0.64), (0.0, 0.7)], M["balloon"], 20)
    cyl("fall_balloon_knot", 0, 0, 0.09, 0.025, 0.04, M["balloon"], 8, r_top=0.005)
    cyl("fall_balloon_string", 0, 0, 0.0, 0.004, 0.1, M["string"], 4)


# ─────────────────────────── Bahçe: kule, ağaç, Newton ───────────────────────────


def build_tower():
    """6 m'lik ahşap bırakma kulesi: dört dikme, her 1,5 m'de kuşak, tepede
    platform ve iki küçük kapak. Cisimler tepede x = ±0.35'te tutulur."""
    begin("newton_tower")
    h, w = TOWER_HEIGHT, 1.2
    for i, (x, y) in enumerate(((-w / 2, -w / 2), (w / 2, -w / 2),
                                (w / 2, w / 2), (-w / 2, w / 2))):
        box(f"tower_post{i}", x, y, 0, 0.12, 0.12, h + 0.3, M["wood"])
    for k in range(1, 5):
        z = k * 1.5 - 0.06
        box(f"tower_ring_f{k}", 0, -w / 2, z, w, 0.08, 0.08, M["wood_dark"])
        box(f"tower_ring_b{k}", 0, w / 2, z, w, 0.08, 0.08, M["wood_dark"])
        box(f"tower_ring_l{k}", -w / 2, 0, z, 0.08, w, 0.08, M["wood_dark"])
        box(f"tower_ring_r{k}", w / 2, 0, z, 0.08, w, 0.08, M["wood_dark"])
    # Tepe: kolları dışa uzanan kiriş (cisimler kulenin dışından düşsün).
    box("tower_arm", 0, 0, h, 2.4, 0.16, 0.12, M["wood_dark"])
    for side in (-1, 1):
        box(f"tower_hook{side}", side * 0.95, 0, h - 0.12, 0.06, 0.06, 0.12, M["iron"])
    # Yükseklik cetveli (her metrede bir kırmızı çizgi) ön sol dikmede.
    for k in range(1, 7):
        box(f"tower_mark{k}", -w / 2, -w / 2 - 0.07, k - 0.02, 0.18, 0.02, 0.04, M["red"])
    # Zemin minderi (iniş yeri).
    box("tower_pad", 0, 0, 0, 2.6, 1.4, 0.04, M["stone"])


def build_tree():
    begin("newton_tree")
    lathe("tree_trunk", [(0.3, 0.0), (0.22, 0.4), (0.18, 1.6), (0.14, 2.4), (0.0, 2.45)],
          M["bark"], 12)
    for i, (x, y, z, r) in enumerate(((0, 0, 2.7, 1.1), (0.7, 0.2, 2.4, 0.75),
                                      (-0.7, -0.1, 2.5, 0.8), (0.1, -0.4, 3.3, 0.7))):
        sphere(f"tree_crown{i}", x, y, z, r, M["leaf_dark"] if i % 2 else M["leaf"], 12, 8)
    for i, (x, y, z) in enumerate(((0.5, -0.9, 2.3), (-0.6, -0.75, 2.6), (0.9, -0.3, 2.0),
                                   (-0.2, -1.05, 2.9), (0.3, -0.6, 3.5))):
        sphere(f"tree_apple{i}", x, y, z, 0.09, M["apple"], 10, 6)


def build_newton_figure():
    """Newton: omuzlarına dökülen uzun kıvırcık peruk, koyu ceket, beyaz
    kravat, diz altı pantolon + beyaz çorap. Yüzü -y'ye bakar, 1.8 boy; sol
    elinde bir elma."""
    begin("newton_figure")
    for side in (-1, 1):
        cyl(f"nf_leg{side}", side * 0.11, 0, 0.05, 0.065, 0.5, M["stocking"], 10)
        box(f"nf_shoe{side}", side * 0.11, -0.05, 0, 0.12, 0.24, 0.07, M["shoe"])
        box(f"nf_buckle{side}", side * 0.11, -0.17, 0.035, 0.06, 0.01, 0.03, M["coat_trim"])
    lathe("nf_coat", [(0.0, 0.5), (0.34, 0.5), (0.3, 0.8), (0.26, 1.2), (0.28, 1.36),
                      (0.14, 1.44), (0.0, 1.45)], M["coat"], 20)
    for i in range(5):
        sphere(f"nf_button{i}", 0, -0.27 + i * 0.004, 0.72 + i * 0.13, 0.022,
               M["coat_trim"], 8, 5)
    # Kravat.
    lathe("nf_cravat", [(0.0, 1.22), (0.09, 1.28), (0.1, 1.42), (0.0, 1.46)],
          M["cravat"], 12, 0, -0.16, 0)
    sphere("nf_head", 0, 0, 1.6, 0.16, M["skin"], 16, 10)
    sphere("nf_nose", 0, -0.16, 1.58, 0.03, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"nf_eye{side}", side * 0.06, -0.14, 1.63, 0.02, M["eye"], 8, 5)
    # Peruk: tepede başlık + iki yanda omuza inen kıvırcık lüleler.
    sphere("nf_wig_top", 0, 0.02, 1.64, 0.18, M["wig"], 16, 9, sz=0.85)
    k = 0
    for side in (-1, 1):
        for j in range(4):
            sphere(f"nf_curl{k}", side * 0.17, 0.02 + (j % 2) * 0.05, 1.55 - j * 0.1,
                   0.075, M["wig"], 10, 6)
            k += 1
    for j in range(3):
        sphere(f"nf_curl_back{j}", (j - 1) * 0.1, 0.13, 1.5 - j * 0.04, 0.08, M["wig"], 10, 6)
    # Kollar: sağ yanda, sol öne uzanmış avucunda elma.
    rotated(cyl("nf_arm_r", 0, 0, 0, 0.06, 0.55, M["coat"], 8), (0.31, 0, 0.75), (0, -0.12, 0))
    sphere("nf_hand_r", 0.34, 0, 0.72, 0.055, M["skin"], 8, 5)
    rotated(cyl("nf_arm_l", 0, 0, 0, 0.06, 0.5, M["coat"], 8), (-0.3, 0, 1.28), (1.9, 0, 0))
    sphere("nf_hand_l", -0.34, -0.45, 1.1, 0.055, M["skin"], 8, 5)
    sphere("nf_apple", -0.34, -0.47, 1.19, 0.07, M["apple"], 10, 6)


# ─────────────────────────── Prizma odası ───────────────────────────


def build_room():
    """Newton'un karanlık odası: zemin, arka duvar, pencere kepengindeki
    küçük delik, kitaplık. Arka duvar y = 2.2, zemin 8 × 5."""
    begin("newton_room")
    for i in range(8):
        box(f"room_board{i}", -3.5 + i, 0, -0.08, 0.98, 5, 0.08,
            M["floor"] if i % 2 else M["wood_dark"])
    box("room_wall", 0, 2.3, 0, 8, 0.2, 3.4, M["wall"])
    box("room_wall_l", -4.1, 0, 0, 0.2, 5, 3.4, M["wall"])
    # Pencere + kapalı kepenk, ortasında ışık deliği.
    box("room_window", -3.0, 2.19, 1.2, 1.2, 0.04, 1.4, M["glass"])
    box("room_shutter_l", -3.3, 2.16, 1.2, 0.58, 0.05, 1.4, M["shutter"])
    box("room_shutter_r", -2.7, 2.16, 1.2, 0.58, 0.05, 1.4, M["shutter"])
    cyl("room_hole", -3.0, 2.13, 1.85, 0.04, 0.01, M["flame"], 10)
    # Kitaplık.
    box("room_shelf", 2.8, 2.0, 0, 1.6, 0.4, 2.2, M["wood_dark"])
    books = (M["book1"], M["book2"], M["book3"], M["red"])
    k = 0
    for row in range(3):
        z = 0.15 + row * 0.7
        box(f"room_shelf_board{row}", 2.8, 1.85, z - 0.04, 1.5, 0.3, 0.04, M["wood"])
        for j in range(9):
            hgt = 0.34 + ((j * 7 + row * 3) % 5) * 0.04
            box(f"room_book{k}", 2.2 + j * 0.14, 1.85, z, 0.11, 0.24, hgt, books[(j + row) % 4])
            k += 1


def build_table():
    begin("newton_table")
    box("table_top", 0, 0, TABLE_TOP - 0.06, 3.6, 1.2, 0.06, M["wood"])
    for i, (x, y) in enumerate(((-1.65, -0.5), (1.65, -0.5), (1.65, 0.5), (-1.65, 0.5))):
        box(f"table_leg{i}", x, y, 0, 0.1, 0.1, TABLE_TOP - 0.06, M["wood_dark"])


def build_lamp():
    """Fener: ışık +x yüzündeki dar yarıktan çıkar; yarığın merkezi
    (x = 0.2, z = 0.25). Taban z = 0 (masanın üstüne konur)."""
    begin("newton_lamp")
    box("lamp_body", 0, 0, 0, 0.4, 0.34, 0.42, M["lantern"])
    box("lamp_roof", 0, 0, 0.42, 0.46, 0.4, 0.05, M["lantern"])
    cyl("lamp_chimney", 0, 0, 0.47, 0.05, 0.12, M["lantern"], 10)
    box("lamp_slit", 0.201, 0, 0.18, 0.004, 0.03, 0.14, M["flame"])
    cyl("lamp_flame", 0, -0.171, 0.12, 0.04, 0.12, M["flame"], 10, r_top=0.0)


def build_prism():
    """Eşkenar üçgen kesitli cam prizma (tepe açısı 60°), ayakta; yüksekliği
    0.36. Cam parçaları `prism_glass*` adlıdır (oyun saydam boyar)."""
    begin("newton_prism")
    s, hgt = 0.34, 0.36
    r = s / math.sqrt(3)
    tri = [(r * math.cos(a), r * math.sin(a))
           for a in (math.pi, math.pi / 3, -math.pi / 3)]
    v = [(x, y, 0.03) for x, y in tri] + [(x, y, 0.03 + hgt) for x, y in tri]
    f = [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)]
    poly("prism_glass", v, f, M["glass"])
    cyl("prism_base", 0, 0, 0, 0.24, 0.03, M["wood_dark"], 16)


def build_screen():
    """Beyaz perde: yüzey x = 0 düzleminde, -x'e bakar; genişlik (y) 1.4,
    yükseklik 1.0, altı z = 0.1."""
    begin("newton_screen")
    box("screen_sheet", 0.01, 0, 0.1, 0.02, 1.4, 1.0, M["screen"])
    box("screen_frame_t", 0.02, 0, 1.1, 0.05, 1.46, 0.04, M["wood_dark"])
    box("screen_frame_b", 0.02, 0, 0.06, 0.05, 1.46, 0.04, M["wood_dark"])
    for side in (-1, 1):
        box(f"screen_foot{side}", 0.02, side * 0.7, 0, 0.3, 0.05, 0.04, M["wood_dark"])
        box(f"screen_post{side}", 0.03, side * 0.72, 0, 0.04, 0.04, 1.12, M["wood_dark"])


# ─────────────────────────── İtme pisti ───────────────────────────


def build_cart():
    """Oyuncak araba: gövde 0.6 × 0.36, yükü taşıyan kasa üstü z = 0.3,
    dört tekerlek `Wheel*` (oyun tarafında döndürülür, ekseni y)."""
    global _parent
    root = begin("newton_cart")
    box("cart_body", 0, 0, 0.1, 0.62, 0.36, 0.14, M["cart"])
    box("cart_rim_f", 0.3, 0, 0.24, 0.03, 0.36, 0.06, M["cart_trim"])
    box("cart_rim_b", -0.3, 0, 0.24, 0.03, 0.36, 0.06, M["cart_trim"])
    box("cart_bumper", -0.33, 0, 0.12, 0.05, 0.3, 0.08, M["tire"])
    for i, (x, y) in enumerate(((-0.2, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2))):
        wheel = group(f"Wheel{i}")
        wheel.parent = root
        wheel.location = (x, y, 0.08)
        _parent = wheel
        rotated(cyl(f"cart_tire{i}", 0, 0, 0, 0.08, 0.05, M["tire"], 16),
                (0, 0.025 if y < 0 else -0.025, 0), (math.pi / 2, 0, 0))
        rotated(cyl(f"cart_hub{i}", 0, 0, 0, 0.035, 0.06, M["cart_trim"], 10),
                (0, 0.03 if y < 0 else -0.03, 0), (math.pi / 2, 0, 0))
        _parent = root


def build_box():
    begin("newton_box")
    s = 0.24
    box("nbox_body", 0, 0, 0, s, s, s, M["box"])
    for i, z in enumerate((0.02, s - 0.06)):
        box(f"nbox_band{i}", 0, 0, z, s + 0.01, s + 0.01, 0.04, M["box_band"])
    box("nbox_label", 0, -s / 2 - 0.006, 0.08, 0.1, 0.004, 0.08, M["paper"])


def build_launcher():
    """Yaylı itici: taban +x yüzü x = 0'da, arabayı +x'e iter. İçindeki
    `Plunger` (tokmak + yay) oyun tarafında x boyunca kaydırılır."""
    global _parent
    root = begin("newton_launcher")
    box("launcher_base", -0.35, 0, 0, 0.7, 0.4, 0.08, M["launcher"])
    box("launcher_back", -0.66, 0, 0.08, 0.08, 0.4, 0.3, M["launcher"])
    plunger = group("Plunger")
    plunger.parent = root
    _parent = plunger
    box("launcher_pad", -0.02, 0, 0.1, 0.04, 0.3, 0.16, M["red"])
    # Yay: x ekseni boyunca sarmal tel.
    verts, faces = [], []
    turns, steps, r, tube = 6, 96, 0.06, 0.012
    x0, x1 = -0.62, -0.04
    ring = 6
    for s in range(steps + 1):
        u = s / steps
        a = 2 * math.pi * turns * u
        cx, cy, cz = x0 + (x1 - x0) * u, r * math.cos(a), 0.18 + r * math.sin(a)
        for k in range(ring):
            b = 2 * math.pi * k / ring
            verts.append((cx + tube * math.cos(b), cy + tube * math.sin(b) * math.cos(a),
                          cz + tube * math.sin(b) * math.sin(a)))
    for s in range(steps):
        for k in range(ring):
            k2 = (k + 1) % ring
            faces.append((s * ring + k, s * ring + k2, (s + 1) * ring + k2, (s + 1) * ring + k))
    poly("launcher_spring", verts, faces, M["spring"], smooth=True)
    _parent = root


# ─────────────────────────── Toplu işlemler ───────────────────────────

ROOT_PREFIXES = ("fall_", "newton_")


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_fall_objects()
    build_tower()
    build_tree()
    build_newton_figure()
    build_room()
    build_table()
    build_lamp()
    build_prism()
    build_screen()
    build_cart()
    build_box()
    build_launcher()
    layout_preview()
    return roots()


def layout_preview():
    """İnceleme için kökleri yan yana dizer; dışa aktarmadan önce
    `reset_positions()`."""
    x = 0.0
    for name in roots():
        ob = bpy.data.objects[name]
        ob.location = (x, 0, 0)
        big = name in ("newton_room", "newton_tower", "newton_tree", "newton_table")
        x += 8.5 if name == "newton_room" else (3.2 if big else 1.2)


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
