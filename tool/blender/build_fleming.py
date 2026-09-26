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
    """Alexander Fleming: arkaya taranmış kır saç, yuvarlak gözlük, papyon,
    beyaz laboratuvar önlüğü."""
    begin("fleming_figure")
    for side in (-1, 1):
        cyl(f"flf_leg{side}", side * 0.1, 0, 0.05, 0.07, 0.62, M["trousers"], 10)
        box(f"flf_shoe{side}", side * 0.1, -0.05, 0, 0.11, 0.25, 0.06, M["shoe"])
    lathe("flf_coat", [(0.0, 0.5), (0.3, 0.5), (0.26, 0.9), (0.25, 1.35), (0.14, 1.46),
                       (0.0, 1.48)], M["coat"], 20)
    box("flf_shirt", 0, -0.2, 1.28, 0.12, 0.04, 0.18, M["shirt"])
    for side in (-1, 1):
        poly(f"flf_bow{side}", [(0, -0.225, 1.4), (side * 0.07, -0.225, 1.44),
                                (side * 0.07, -0.225, 1.36)],
             [(0, 1, 2), (2, 1, 0)], M["bow"])
    cyl("flf_neck", 0, 0, 1.44, 0.055, 0.08, M["skin"], 10)
    sphere("flf_head", 0, 0, 1.6, 0.14, M["skin"], 16, 10, sz=1.1)
    sphere("flf_nose", 0, -0.14, 1.58, 0.026, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"flf_eye{side}", side * 0.05, -0.125, 1.62, 0.016, M["eye"], 8, 5)
        rotated(torus(f"flf_lens{side}", 0, 0, 0, 0.035, 0.006, M["glasses"], 16, 5),
                (side * 0.05, -0.135, 1.62), (math.pi / 2, 0, 0))
    box("flf_bridge", 0, -0.137, 1.62, 0.03, 0.006, 0.006, M["glasses"])
    sphere("flf_hair", 0, 0.03, 1.68, 0.145, M["hair"], 14, 8, sz=0.65)
    rotated(cyl("flf_arm_r", 0, 0, 0, 0.06, 0.58, M["coat"], 8), (0.28, 0, 0.8), (0, -0.1, 0))
    sphere("flf_hand_r", 0.3, 0, 0.77, 0.05, M["skin"], 8, 5)
    rotated(cyl("flf_arm_l", 0, 0, 0, 0.06, 0.5, M["coat"], 8), (-0.27, 0, 1.32), (1.9, 0, 0))
    sphere("flf_hand_l", -0.27, -0.47, 1.15, 0.05, M["skin"], 8, 5)
    # Elinde küçük bir petri kabı.
    cyl("flf_dish", -0.27, -0.5, 1.19, 0.07, 0.015, M["glass"], 16)
    cyl("flf_dish_agar", -0.27, -0.5, 1.195, 0.064, 0.008, M["agar"], 16)


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
