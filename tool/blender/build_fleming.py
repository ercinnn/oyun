"""Bilim İnsanları / Fleming — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/fleming.glb`'ye gider; her parça isimli bir kök
gruptur (`GlbModelLibrary`).

Kimlikler Dart ile aynı olmalıdır (kodun adla aradığı iç düğümler parantezde):
- `fleming_figure` (yüzü -y, 1.72 boy; papyon, gözlük, beyaz önlük).
- `fleming_lab` (tezgâh üstü z = 0.85, arkada raflar ve pencere).
- `fleming_dish` (petri kabı, gerçeğin ~4 katı: yarıçap 0.35; agar yüzeyi
  `agar` z = 0.04; kapak `Lid` kök grubun çocuğu, oyun kapağı kaldırır).
  Koloniler, küf ve temiz halka oyun tarafında agarın üstüne çizilir.
  Adı `_glass` ile biten cam parçaları oyun saydam boyar (agar görünsün).
- `fleming_microscope`, `fleming_sink` (lavabo + sabun), `fleming_bottle`
  (ilaç şişesi, etiketli).

Koordinatlar: z yukarı, ön yüz -y (three'de +z), 1 birim = 1 m.

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_fleming.py", encoding="utf-8").read())
    build_all(); show_all(); reset_positions(); roots()
"""

import os

import bpy
import math

_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())
exec(open(os.path.join(_HERE, "human_body.py"), encoding="utf-8").read())

M = {}
DISH_R = 0.35


def materials():
    M.update(
        skin=mat("fl_skin", 0xE8BC98, 0.7),
        hair=mat("fl_hair", 0xBDBDBD, 0.9),
        coat=mat("fl_coat", 0xF5F5F5, 0.8),
        trousers=mat("fl_trousers", 0x37474F, 0.85),
        shoe=mat("fl_shoe", 0x212121, 0.6),
        bow=mat("fl_bow", 0x8E24AA, 0.6),
        shirt=mat("fl_shirt", 0xFAFAFA, 0.8),
        glasses=mat("fl_glasses", 0x212121, 0.4),
        eye=mat("fl_eye", 0x212121, 0.4),
        wood=mat("fl_wood", 0x8D6E63, 0.8),
        wood_dark=mat("fl_wood_dark", 0x5D4037, 0.85),
        floor=mat("fl_floor", 0x90A4AE, 0.9),
        wall=mat("fl_wall", 0xE8E0D0, 0.95),
        glass=mat("fl_glass", 0xB3E5FC, 0.1),
        frame=mat("fl_frame", 0xFAFAFA, 0.6),
        sky=mat("fl_sky", 0x81D4FA, 0.4),
        agar=mat("fl_agar", 0xF2D38A, 0.5),
        metal=mat("fl_metal", 0x90A4AE, 0.35, metal=0.8),
        black=mat("fl_black", 0x263238, 0.5),
        sink=mat("fl_sink", 0xECEFF1, 0.3),
        soap=mat("fl_soap", 0x4DB6AC, 0.4),
        bottle=mat("fl_bottle", 0x8D6E63, 0.25),
        label=mat("fl_label", 0xFFFFFF, 0.8),
        cap=mat("fl_cap", 0xE53935, 0.5),
        liquid=mat("fl_liquid", 0x4FC3F7, 0.3),
    )


def rotated(ob, loc, rot):
    ob.rotation_euler = rot
    ob.location = loc
    return ob


def build_figure():
    """Alexander Fleming — eklemli insan gövdesi (`human_body.py`): arkaya
    taranmış kır saç, yuvarlak gözlük, mor papyon, beyaz laboratuvar önlüğü;
    sol avucunda küçük bir petri kabı. Yüzü -y, 1.72 boy."""
    root = begin("fleming_figure")
    info = human(
        "flf", height=1.72, skin=M["skin"], top=M["coat"], pants=M["trousers"],
        shoe=M["shoe"], brow=M["hair"], collar=M["shirt"], cuff=M["coat"],
        coat=dict(m=M["coat"], bottom=0.55, flare=1.15, open=M["trousers"], open_w=0.08),
        arm_l=dict(abd=15, flex=50, elbow=58, palm="up", curl=0.35),
        arm_r=dict(abd=9, elbow=16, curl=0.35),
        leg_l=dict(knee=5, turn=10), leg_r=dict(flex=5, knee=4, turn=10))
    r, A = info["r"], info["attach_head"]
    nf = info["neck_front"]
    # Papyon: iki kanat + düğüm, boynun önünde.
    X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
    c = nf + Vector((0, -0.025, -0.03))
    for side in (-1, 1):
        blob(f"flf_bow{side}", c + Vector((side * 0.035, 0, 0)), (X, Y, Z),
             (0.035, 0.012, 0.025), M["bow"], 10, 6)
    blob("flf_bow_knot", c + Vector((0, -0.006, 0)), (X, Y, Z), (0.014, 0.013, 0.016),
         M["bow"], 8, 5)
    # Yuvarlak gözlük: iki çerçeve + köprü.
    for side in (-1, 1):
        face_ring(f"flf_lens{side}", info, side * 0.36, -1.1, 0.135, 0.2, 0.028, M["glasses"])
    A(box("flf_bridge", 0, -r * 1.12, r * 0.12, r * 0.3, r * 0.04, r * 0.04, M["glasses"]))
    # Arkaya taranmış kır saç.
    hair_cap("flf_hair", info, M["hair"], back=0.14, lift=0.2, size=1.07, sz=1.14)
    # Petri kabı: sol avucun üstünde.
    g = info["grip_l"]
    cyl("flf_dish", g.x, g.y, g.z, 0.055, 0.014, M["glass"], 18)
    cyl("flf_dish_agar", g.x, g.y, g.z + 0.003, 0.05, 0.007, M["agar"], 18)
    join_by_material(root)


def build_lab():
    begin("fleming_lab")
    box("fll_floor", 0, 0, -0.06, 8, 5, 0.06, M["floor"])
    box("fll_wall", 0, 2.4, 0, 8, 0.2, 3.2, M["wall"])
    box("fll_bench_top", 0, 0.3, 0.8, 3.4, 1.0, 0.05, M["wood"])
    for i, (x, y) in enumerate(((-1.6, -0.15), (1.6, -0.15), (1.6, 0.75), (-1.6, 0.75))):
        box(f"fll_bench_leg{i}", x, y, 0, 0.08, 0.08, 0.8, M["wood_dark"])
    # Pencere (Fleming'in laboratuvarı Londra'da, St Mary's Hastanesi'ndeydi).
    box("fll_window", 2.2, 2.29, 1.3, 1.2, 0.02, 1.0, M["sky"])
    for i, (x, z, w, h) in enumerate(((2.2, 1.28, 1.26, 0.05), (2.2, 2.28, 1.26, 0.05),
                                      (1.6, 1.3, 0.05, 1.0), (2.8, 1.3, 0.05, 1.0),
                                      (2.2, 1.3, 0.04, 1.0), (2.2, 1.78, 1.2, 0.04))):
        box(f"fll_window_frame{i}", x, 2.27, z, w, 0.04, h, M["frame"])
    for r in range(2):
        z = 1.4 + r * 0.5
        box(f"fll_shelf{r}", -1.6, 2.2, z, 2.4, 0.3, 0.04, M["wood"])
        for k in range(6):
            x = -2.6 + k * 0.4
            lathe(f"fll_jar{r}_{k}", [(0.0, z + 0.04), (0.08, z + 0.045), (0.08, z + 0.24),
                                      (0.0, z + 0.25)], M["glass"], 12, x, 2.2, 0)


def build_dish():
    """Petri kabı: cam taban + halka, agar yüzeyi `agar`, kapak `Lid`."""
    global _parent
    root = begin("fleming_dish")
    lathe("fld_base_glass", [(0.0, 0.0), (DISH_R, 0.0), (DISH_R, 0.06), (DISH_R - 0.01, 0.06),
                       (DISH_R - 0.01, 0.008), (0.0, 0.008)], M["glass"], 32)
    cyl("agar", 0, 0, 0.008, DISH_R - 0.015, 0.032, M["agar"], 32)
    lid = group("Lid")
    lid.parent = root
    _parent = lid
    lathe("fld_lid_glass", [(0.0, 0.075), (DISH_R + 0.015, 0.075), (DISH_R + 0.015, 0.03),
                      (DISH_R + 0.005, 0.03), (DISH_R + 0.005, 0.067), (0.0, 0.067)],
          M["glass"], 32)
    _parent = root


def build_microscope():
    begin("fleming_microscope")
    box("flm_base", 0, 0, 0, 0.22, 0.28, 0.04, M["black"])
    rotated(box("flm_arm", 0, 0, 0, 0.05, 0.05, 0.36, M["black"]), (0, 0.1, 0.04), (0.35, 0, 0))
    box("flm_stage", 0, -0.02, 0.14, 0.16, 0.14, 0.02, M["black"])
    rotated(cyl("flm_tube", 0, 0, 0, 0.025, 0.2, M["metal"], 12), (0, -0.02, 0.2), (0.25, 0, 0))
    cyl("flm_eyepiece", 0, 0.03, 0.39, 0.02, 0.05, M["black"], 10)


def build_sink():
    begin("fleming_sink")
    box("fls_cabinet", 0, 0, 0, 0.7, 0.5, 0.8, M["wood"])
    box("fls_basin", 0, 0, 0.8, 0.6, 0.42, 0.08, M["sink"])
    rotated(cyl("fls_tap", 0, 0, 0, 0.015, 0.2, M["metal"], 8), (0, 0.18, 0.88), (0, 0, 0))
    rotated(cyl("fls_spout", 0, 0, 0, 0.012, 0.12, M["metal"], 8), (0, 0.18, 1.07), (-1.57, 0, 0))
    lathe("fls_soap", [(0.0, 0.88), (0.04, 0.88), (0.04, 1.0), (0.015, 1.03), (0.015, 1.07),
                       (0.0, 1.07)], M["soap"], 12, 0.22, 0.12, 0)


def build_bottle():
    begin("fleming_bottle")
    lathe("flb_body", [(0.0, 0.0), (0.06, 0.0), (0.06, 0.16), (0.03, 0.2), (0.025, 0.23),
                       (0.0, 0.23)], M["bottle"], 16)
    lathe("flb_label", [(0.0605, 0.04), (0.0605, 0.12)], M["label"], 16)
    cyl("flb_cap", 0, 0, 0.22, 0.03, 0.03, M["cap"], 12)


ROOT_PREFIXES = ("fleming_",)


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_figure()
    build_lab()
    build_dish()
    build_microscope()
    build_sink()
    build_bottle()
    x = 0.0
    for name in roots():
        bpy.data.objects[name].location = (x, 0, 0)
        x += 9 if name == "fleming_lab" else 2.0
    return roots()


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
