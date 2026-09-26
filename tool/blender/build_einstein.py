"""Bilim İnsanları / Einstein — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/einstein.glb`'ye gider; her parça isimli bir kök
gruptur (`GlbModelLibrary`).

Kimlikler Dart ile aynı olmalıdır (kodun adla aradığı iç düğümler parantezde):
- `einstein_figure` (yüzü -y, 1.75 boy; dağınık beyaz saç, bıyık, gri hırka).
- `einstein_board` (kara tahta, üstünde tebeşirle "E=mc²").
- `einstein_frame` (örtünün kare çerçevesi: kenar ±6, üst z = 0; ayaklar
  z = -5'e iner. Örtünün kendisi oyun tarafında kodla çizilir).
- `einstein_clock` (ışık saati: aynalar z = 0.15 ve z = 1.15; foton kodla).
- `einstein_ship` (roket, burnu +x yönünde; merkez orijinde).
- `einstein_pedestal` (kaide, üstü z = 1.0), `einstein_house` (`window`),
  `einstein_campfire` (`flame`).

Koordinatlar: z yukarı, ön yüz -y (three'de +z), 1 birim = 1 m.

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_einstein.py", encoding="utf-8").read())
    build_all(); show_all(); reset_positions(); roots()
"""

import os

import bpy
import math

_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())

M = {}


def materials():
    M.update(
        skin=mat("es_skin", 0xE8B896, 0.7),
        hair=mat("es_hair", 0xF5F5F5, 0.95),
        sweater=mat("es_sweater", 0x78909C, 0.9),
        shirt=mat("es_shirt", 0xFAFAFA, 0.8),
        trousers=mat("es_trousers", 0x6D4C41, 0.85),
        shoe=mat("es_shoe", 0x3E2723, 0.6),
        eye=mat("es_eye", 0x212121, 0.4),
        board=mat("es_board", 0x1B3B2A, 0.9),
        chalk=mat("es_chalk", 0xF5F5F5, 0.9),
        wood=mat("es_wood", 0x8D6E63, 0.8),
        wood_dark=mat("es_wood_dark", 0x5D4037, 0.85),
        frame=mat("es_frame", 0x37474F, 0.5, metal=0.4),
        mirror=mat("es_mirror", 0xCFD8DC, 0.1, metal=1.0),
        clock_base=mat("es_clock_base", 0x455A64, 0.5),
        post=mat("es_post", 0x90A4AE, 0.3, metal=0.6),
        hull=mat("es_hull", 0xECEFF1, 0.4, metal=0.3),
        stripe=mat("es_stripe", 0xE53935, 0.5),
        glass=mat("es_glass", 0x81D4FA, 0.1),
        nozzle=mat("es_nozzle", 0x546E7A, 0.4, metal=0.7),
        marble=mat("es_marble", 0xECEFF1, 0.5),
        marble_dark=mat("es_marble_dark", 0xB0BEC5, 0.6),
        house=mat("es_house", 0xF1E3C8, 0.9),
        roof=mat("es_roof", 0x5C6BC0, 0.85),
        window=mat("es_window", 0x37474F, 0.4),
        log=mat("es_log", 0x6D4C41, 0.9),
        flame=mat("es_flame", 0xFF9800, 0.4, emit=1.0),
        stone=mat("es_stone", 0x9E9E9E, 0.9),
    )


def rotated(ob, loc, rot):
    ob.rotation_euler = rot
    ob.location = loc
    return ob


def build_figure():
    begin("einstein_figure")
    for side in (-1, 1):
        cyl(f"ef_leg{side}", side * 0.1, 0, 0.05, 0.075, 0.8, M["trousers"], 10)
        box(f"ef_shoe{side}", side * 0.1, -0.05, 0, 0.11, 0.25, 0.06, M["shoe"])
    lathe("ef_body", [(0.0, 0.8), (0.24, 0.8), (0.27, 1.1), (0.26, 1.42), (0.14, 1.5),
                      (0.0, 1.52)], M["sweater"], 20)
    box("ef_shirt", 0, -0.21, 1.3, 0.1, 0.04, 0.18, M["shirt"])
    cyl("ef_neck", 0, 0, 1.48, 0.06, 0.08, M["skin"], 10)
    sphere("ef_head", 0, 0, 1.64, 0.14, M["skin"], 16, 10, sz=1.1)
    sphere("ef_nose", 0, -0.14, 1.62, 0.028, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"ef_eye{side}", side * 0.05, -0.12, 1.66, 0.017, M["eye"], 8, 5)
        sphere(f"ef_brow{side}", side * 0.055, -0.125, 1.695, 0.03, M["hair"], 8, 4, sz=0.4, sx=1.4)
    sphere("ef_moustache", 0, -0.13, 1.57, 0.065, M["hair"], 10, 6, sz=0.45, sx=1.5)
    # Dağınık beyaz saç: başın arkasında ve yanlarında kabarık yumaklar.
    tufts = [(0.0, 0.06, 1.74, 0.13), (-0.12, 0.04, 1.7, 0.1), (0.12, 0.04, 1.7, 0.1),
             (-0.15, -0.01, 1.62, 0.08), (0.15, -0.01, 1.62, 0.08), (0.0, 0.12, 1.62, 0.11),
             (-0.08, 0.1, 1.78, 0.08), (0.08, 0.1, 1.78, 0.08), (-0.17, 0.06, 1.55, 0.06),
             (0.17, 0.06, 1.55, 0.06)]
    for i, (x, y, z, r) in enumerate(tufts):
        sphere(f"ef_tuft{i}", x, y, z, r, M["hair"], 10, 6)
    rotated(cyl("ef_arm_r", 0, 0, 0, 0.065, 0.6, M["sweater"], 8), (0.29, 0, 0.85), (0, -0.1, 0))
    sphere("ef_hand_r", 0.31, 0, 0.82, 0.05, M["skin"], 8, 5)
    # Sol el tahtaya işaret eder gibi yukarıda.
    # y ekseni etrafında −0.9: kol yukarı ve dışa (−x) uzanır.
    rotated(cyl("ef_arm_l", 0, 0, 0, 0.065, 0.55, M["sweater"], 8), (-0.28, 0, 1.38), (0, -0.9, 0))
    sphere("ef_hand_l", -0.71, 0, 1.73, 0.05, M["skin"], 8, 5)
    box("ef_chalk", -0.78, 0, 1.75, 0.06, 0.015, 0.015, M["chalk"])


def _text(name, body, size, loc, m):
    """Blender yazı nesnesini düz örgüye çevirir (tahtaya tebeşir yazı)."""
    curve = bpy.data.curves.new(name, type="FONT")
    curve.body = body
    curve.size = size
    curve.extrude = 0.004
    curve.align_x = "CENTER"
    ob = bpy.data.objects.new(name, curve)
    coll.objects.link(ob)
    ob.rotation_euler = (math.pi / 2, 0, 0)
    ob.location = loc
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(deps))
    matrix = ob.matrix_world.copy()
    bpy.data.objects.remove(ob, do_unlink=True)
    me.transform(matrix)
    mesh_ob = bpy.data.objects.new(name, me)
    mesh_ob.data.materials.append(m)
    coll.objects.link(mesh_ob)
    if _parent is not None:
        mesh_ob.parent = _parent
    return mesh_ob


def build_board():
    begin("einstein_board")
    box("eb_board", 0, 0, 0.9, 2.0, 0.06, 1.1, M["board"])
    box("eb_frame_t", 0, 0, 2.0, 2.1, 0.08, 0.06, M["wood"])
    box("eb_frame_b", 0, -0.02, 0.86, 2.1, 0.12, 0.05, M["wood"])
    for side in (-1, 1):
        box(f"eb_leg{side}", side * 0.95, 0, 0, 0.06, 0.06, 2.0, M["wood_dark"])
        box(f"eb_foot{side}", side * 0.95, 0, 0, 0.1, 0.6, 0.05, M["wood_dark"])
    _text("eb_formula", "E=mc", 0.42, (-0.12, -0.035, 1.3), M["chalk"])
    _text("eb_square", "2", 0.22, (0.37, -0.035, 1.58), M["chalk"])
    # Birkaç tebeşir çizgisi (hesap karalaması).
    for i in range(3):
        box(f"eb_scribble{i}", -0.55 + i * 0.1, -0.035, 1.05 - i * 0.05, 0.5 - i * 0.08, 0.004, 0.012, M["chalk"])


def build_frame():
    begin("einstein_frame")
    s = 6.0
    for i, (x, y, w, d) in enumerate(((0, -s, 2 * s + 0.2, 0.2), (0, s, 2 * s + 0.2, 0.2),
                                      (-s, 0, 0.2, 2 * s), (s, 0, 0.2, 2 * s))):
        box(f"efr_rim{i}", x, y, -0.1, w, d, 0.2, M["frame"])
    for i, (x, y) in enumerate(((-s, -s), (s, -s), (s, s), (-s, s))):
        box(f"efr_leg{i}", x, y, -5.0, 0.2, 0.2, 5.0, M["frame"])


def build_clock():
    """Işık saati: altta ve üstte ayna, iki ince dikme."""
    begin("einstein_clock")
    box("ec_base", 0, 0, 0, 0.5, 0.5, 0.08, M["clock_base"])
    cyl("ec_mirror_low", 0, 0, 0.1, 0.18, 0.05, M["mirror"], 20)
    cyl("ec_mirror_high", 0, 0, 1.15, 0.18, 0.05, M["mirror"], 20)
    for side in (-1, 1):
        box(f"ec_post{side}", side * 0.2, 0, 0.08, 0.03, 0.03, 1.15, M["post"])
    box("ec_top", 0, 0, 1.2, 0.48, 0.06, 0.04, M["post"])


def build_ship():
    """Roket: burnu +x yönünde, gövde ekseni x."""
    begin("einstein_ship")
    rotated(lathe("es_body", [(0.0, -0.9), (0.28, -0.85), (0.3, -0.2), (0.3, 0.4),
                             (0.22, 0.75), (0.0, 1.0)], M["hull"], 22), (0, 0, 0), (0, math.pi / 2, 0))
    rotated(cyl("es_band", 0, 0, 0, 0.305, 0.12, M["stripe"], 22), (0.1, 0, 0), (0, math.pi / 2, 0))
    rotated(cyl("es_window", 0, 0, 0, 0.11, 0.02, M["glass"], 16), (0.35, -0.29, 0.05), (math.pi / 2, 0, 0))
    rotated(cyl("es_nozzle", 0, 0, 0, 0.18, 0.2, M["nozzle"], 16, r_top=0.24), (-1.05, 0, 0), (0, math.pi / 2, 0))
    for k in range(3):
        a = k * 2 * math.pi / 3
        verts = [(-0.85, 0.28 * math.cos(a), 0.28 * math.sin(a)),
                 (-0.4, 0.28 * math.cos(a), 0.28 * math.sin(a)),
                 (-0.95, 0.55 * math.cos(a), 0.55 * math.sin(a))]
        poly(f"es_fin{k}", verts, [(0, 1, 2), (2, 1, 0)], M["stripe"])


def build_pedestal():
    begin("einstein_pedestal")
    box("ep_base", 0, 0, 0, 0.6, 0.6, 0.1, M["marble_dark"])
    lathe("ep_column", [(0.2, 0.1), (0.17, 0.5), (0.17, 0.85), (0.22, 0.9)], M["marble"], 16)
    box("ep_top", 0, 0, 0.9, 0.5, 0.5, 0.1, M["marble_dark"])


def build_house():
    begin("einstein_house")
    box("eh_body", 0, 0, 0, 0.5, 0.5, 0.4, M["house"])
    verts = [(-0.28, -0.28, 0.4), (0.28, -0.28, 0.4), (0.28, 0.28, 0.4), (-0.28, 0.28, 0.4),
             (-0.28, 0, 0.65), (0.28, 0, 0.65)]
    poly("eh_roof", verts, [(0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5)], M["roof"])
    box("window", 0, -0.255, 0.14, 0.2, 0.02, 0.14, M["window"])


def build_campfire():
    begin("einstein_campfire")
    for k in range(5):
        cyl(f"ecf_stone{k}", 0.3 * math.cos(k * 1.26), 0.3 * math.sin(k * 1.26), 0, 0.08, 0.08,
            M["stone"], 8)
    for k in range(3):
        ob = cyl(f"ecf_log{k}", 0, 0, 0, 0.04, 0.45, M["log"], 8)
        rotated(ob, (0.2 * math.cos(k * 2.1), 0.2 * math.sin(k * 2.1), 0.03), (1.2, 0, k * 2.1))
    cyl("flame", 0, 0, 0.05, 0.12, 0.35, M["flame"], 10, r_top=0.0)


ROOT_PREFIXES = ("einstein_",)


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_figure()
    build_board()
    build_frame()
    build_clock()
    build_ship()
    build_pedestal()
    build_house()
    build_campfire()
    x = 0.0
    for name in roots():
        bpy.data.objects[name].location = (x, 0, 0)
        x += 14 if name == "einstein_frame" else 3.0
    return roots()


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
