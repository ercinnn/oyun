"""Bilim İnsanları / Marie Curie — 3B model üreticisi (Blender 5.2, Blender MCP).

Hepsi tek bir `assets/models/curie.glb`'ye gider; her parça isimli bir kök
gruptur (`GlbModelLibrary`).

Kimlikler Dart ile aynı olmalıdır (kodun adla aradığı iç düğümler parantezde):
- `curie_figure` (yüzü -y, 1.65 boy), `curie_lab` (tezgâh üstü z = 0.85).
- `curie_sample_<id>`: `lib/data/curie_samples.dart` numuneleri; radyumun
  ışıyan içi `sample_glow` (kod parlatır). Adı `_glass` ile biten parçaları
  oyun saydam boyar (içi görünsün).
- `curie_counter` (`Needle`: kadran ibresi, ön yüzde, y ekseni etrafında
  döner = three'de z), `curie_probe` (sonda; ucu +x yönünde, x = 0.25).
- `curie_source` (kurşun kap; ağzı +x yönünde, ağız merkezi z = 0.12).
- `curie_bed` (tedavi masası + yatan hasta; gövde merkezi x = 0, z = 0.95),
  `curie_gantry` (hastanın gövdesini saran dik halka, merkez z = 0.95).

Koordinatlar: z yukarı, ön yüz -y (three'de +z), 1 birim = 1 m.

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_curie.py", encoding="utf-8").read())
    build_all(); show_all(); reset_positions(); roots()
"""

import os

import bpy
import math

_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())
exec(open(os.path.join(_HERE, "human_body.py"), encoding="utf-8").read())

M = {}


def materials():
    M.update(
        skin=mat("cu_skin", 0xEBC3A5, 0.7),
        hair=mat("cu_hair", 0x5D4037, 0.85),
        dress=mat("cu_dress", 0x263238, 0.85),
        coat=mat("cu_coat", 0xF5F5F5, 0.8),
        eye=mat("cu_eye", 0x212121, 0.4),
        shoe=mat("cu_shoe", 0x1B1B1B, 0.6),
        wood=mat("cu_wood", 0x8D6E63, 0.8),
        wood_dark=mat("cu_wood_dark", 0x5D4037, 0.85),
        floor=mat("cu_floor", 0x9E9E9E, 0.9),
        wall=mat("cu_wall", 0xD7CCC8, 0.95),
        glass=mat("cu_glass", 0xB3E5FC, 0.15),
        liquid_blue=mat("cu_liquid_blue", 0x4FC3F7, 0.3),
        liquid_green=mat("cu_liquid_green", 0x81C784, 0.3),
        liquid_pink=mat("cu_liquid_pink", 0xF48FB1, 0.3),
        glow=mat("cu_sample_glow", 0x2E7D32, 0.4),
        pale=mat("cu_pale", 0xE0E0E0, 0.5),
        rock_dark=mat("cu_rock_dark", 0x2B2B2B, 0.95),
        rock_grey=mat("cu_rock_grey", 0x9E9E9E, 0.95),
        speck=mat("cu_speck", 0xF5F5F5, 0.9),
        yellow=mat("cu_yellow", 0xFDD835, 0.8),
        salt=mat("cu_salt", 0xFAFAFA, 0.9),
        dish=mat("cu_dish", 0xECEFF1, 0.3),
        metal=mat("cu_metal", 0x90A4AE, 0.35, metal=0.8),
        box=mat("cu_box", 0x455A64, 0.6),
        dial=mat("cu_dial", 0xFFF8E1, 0.7),
        needle=mat("cu_needle", 0xD32F2F, 0.5),
        tick=mat("cu_tick", 0x212121, 0.6),
        lead=mat("cu_lead", 0x546E7A, 0.5, metal=0.4),
        hazard=mat("cu_hazard", 0xFDD835, 0.6),
        black=mat("cu_black", 0x212121, 0.6),
        bed=mat("cu_bed", 0xECEFF1, 0.6),
        sheet=mat("cu_sheet", 0x90CAF9, 0.8),
        gown=mat("cu_gown", 0xB3E5FC, 0.85),
        gantry=mat("cu_gantry", 0xFAFAFA, 0.4),
        gantry_trim=mat("cu_gantry_trim", 0x26A69A, 0.5),
    )


def rotated(ob, loc, rot):
    ob.rotation_euler = rot
    ob.location = loc
    return ob


def build_figure():
    """Marie Curie — eklemli insan gövdesi (`human_body.py`): yere kadar koyu
    etek, beyaz laboratuvar önlüğü, koyu kahve saç topuzu; sağ elinde bir cam
    şişe. Yüzü -y, 1.65 boy."""
    root = begin("curie_figure")
    info = human(
        "cf", height=1.65, female=True, skin=M["skin"], top=M["coat"], pants=M["dress"],
        shoe=M["shoe"], brow=M["hair"], collar=M["dress"],
        coat=dict(m=M["coat"], bottom=0.52, flare=1.2, open=M["dress"], open_w=0.06),
        skirt=dict(m=M["dress"], bottom=0.02, flare=1.32),
        arm_r=dict(abd=12, flex=55, elbow=50, palm="up", curl=0.45),
        arm_l=dict(abd=10, elbow=16, curl=0.35),
        leg_l=dict(knee=4), leg_r=dict(knee=4))
    r, A = info["r"], info["attach_head"]
    # Saç: başı saran koyu kahve saç + tepede arkada topuz.
    hair_cap("cf_hair", info, M["hair"], back=0.1, lift=0.2, size=1.1, sz=1.18, sx=1.06)
    A(sphere("cf_bun", 0, r * 0.8, r * 1.05, r * 0.45, M["hair"], 12, 8))
    # Cam şişe: sağ avucun üstünde, içinde yeşil sıvı.
    g = info["grip_r"]
    lathe("cf_flask", [(0.0, 0.0), (0.045, 0.004), (0.045, 0.055), (0.016, 0.1),
                       (0.016, 0.14), (0.0, 0.14)], M["glass"], 14, g.x, g.y, g.z - 0.01)
    lathe("cf_flask_liquid", [(0.0, 0.002), (0.041, 0.006), (0.041, 0.045), (0.0, 0.045)],
          M["liquid_green"], 14, g.x, g.y, g.z - 0.01)
    join_by_material(root)


def build_lab():
    begin("curie_lab")
    box("cl_floor", 0, 0, -0.06, 8, 5, 0.06, M["floor"])
    box("cl_wall", 0, 2.4, 0, 8, 0.2, 3.2, M["wall"])
    box("cl_bench_top", 0, 0.3, 0.8, 3.2, 1.0, 0.05, M["wood"])
    for i, (x, y) in enumerate(((-1.5, -0.15), (1.5, -0.15), (1.5, 0.75), (-1.5, 0.75))):
        box(f"cl_bench_leg{i}", x, y, 0, 0.08, 0.08, 0.8, M["wood_dark"])
    # Duvar rafları ve cam kaplar.
    liquids = (M["liquid_blue"], M["liquid_green"], M["liquid_pink"])
    for r in range(2):
        z = 1.4 + r * 0.55
        box(f"cl_shelf{r}", 0, 2.2, z, 3.0, 0.3, 0.04, M["wood"])
        for k in range(7):
            x = -1.3 + k * 0.42
            lathe(f"cl_bottle{r}_{k}", [(0.0, z + 0.04), (0.06, z + 0.045), (0.06, z + 0.22),
                                        (0.025, z + 0.28), (0.025, z + 0.33), (0.0, z + 0.33)],
                  M["glass"], 12, x, 2.2, 0)
            lathe(f"cl_liquid{r}_{k}", [(0.0, z + 0.045), (0.055, z + 0.05), (0.055, z + 0.15),
                                        (0.0, z + 0.15)], liquids[(k + r) % 3], 12, x, 2.2, 0)


def _dish(prefix, m_top):
    cyl(f"{prefix}_dish", 0, 0, 0, 0.09, 0.02, M["dish"], 18)
    lathe(f"{prefix}_pile", [(0.0, 0.02), (0.07, 0.02), (0.04, 0.05), (0.0, 0.065)],
          m_top, 16)


def _vial(prefix, m_inside, inside_name=None):
    cyl(f"{prefix}_stand", 0, 0, 0, 0.05, 0.015, M["wood_dark"], 14)
    lathe(f"{prefix}_glass", [(0.0, 0.015), (0.03, 0.02), (0.03, 0.15), (0.0, 0.15)],
          M["glass"], 14)
    lathe(inside_name or f"{prefix}_inside", [(0.0, 0.02), (0.027, 0.022), (0.027, 0.07),
                                              (0.0, 0.07)], m_inside, 14)
    cyl(f"{prefix}_cap", 0, 0, 0.15, 0.033, 0.025, M["black"], 14)


def build_samples():
    begin("curie_sample_radium")
    _vial("csr", M["glow"], "sample_glow")
    begin("curie_sample_polonium")
    _vial("csp", M["pale"])
    begin("curie_sample_pitchblende")
    sphere("csb_rock", 0, 0, 0.05, 0.075, M["rock_dark"], 7, 5, sz=0.7, sx=1.2)
    begin("curie_sample_uranium")
    _dish("csu", M["yellow"])
    begin("curie_sample_granite")
    sphere("csg_rock", 0, 0, 0.05, 0.07, M["rock_grey"], 7, 5, sz=0.75, sy=0.9)
    for i, (x, y, z) in enumerate(((0.03, -0.055, 0.06), (-0.04, -0.05, 0.05), (0.0, -0.06, 0.08))):
        sphere(f"csg_speck{i}", x, y, z, 0.012, M["speck"], 6, 4)
    begin("curie_sample_salt")
    _dish("css", M["salt"])


def build_counter():
    """Geiger sayacı: kutu, ön yüzde kadran ve dönen `Needle`, tutamak."""
    global _parent
    root = begin("curie_counter")
    box("cc_body", 0, 0, 0, 0.3, 0.18, 0.2, M["box"])
    box("cc_handle", 0, 0, 0.2, 0.2, 0.04, 0.03, M["black"])
    for side in (-1, 1):
        box(f"cc_handle_post{side}", side * 0.09, 0, 0.2, 0.02, 0.04, 0.05, M["black"])
    rotated(cyl("cc_dial", 0, 0, 0, 0.07, 0.006, M["dial"], 24), (-0.04, -0.09, 0.11), (math.pi / 2, 0, 0))
    for i in range(7):
        a = math.radians(-60 + i * 20)
        box(f"cc_tick{i}", -0.04 + 0.058 * math.sin(a), -0.097, 0.11 + 0.058 * math.cos(a) - 0.006,
            0.004, 0.003, 0.012, M["tick"])
    needle = group("Needle")
    needle.parent = root
    needle.location = (-0.04, -0.098, 0.11)
    _parent = needle
    box("cc_needle", 0, 0, 0, 0.005, 0.003, 0.055, M["needle"])
    sphere("cc_hub", 0, 0, 0, 0.008, M["black"], 8, 5)
    _parent = root
    rotated(cyl("cc_speaker", 0, 0, 0, 0.03, 0.002, M["black"], 12), (0.09, -0.091, 0.1), (math.pi / 2, 0, 0))


def build_probe():
    """Sonda: tutamak + ince metal tüp; ucu +x yönünde (x = 0.25)."""
    begin("curie_probe")
    rotated(cyl("cp_handle", 0, 0, 0, 0.02, 0.1, M["black"], 10), (-0.1, 0, 0.03), (0, math.pi / 2, 0))
    rotated(cyl("cp_tube", 0, 0, 0, 0.016, 0.25, M["metal"], 12), (0.0, 0, 0.03), (0, math.pi / 2, 0))
    rotated(cyl("cp_window", 0, 0, 0, 0.018, 0.01, M["dial"], 12), (0.25, 0, 0.03), (0, math.pi / 2, 0))


def build_source():
    """Kurşun kap: ağzı +x yönünde (merkez z = 0.12); üstünde radyasyon işareti."""
    begin("curie_source")
    box("cs_block", 0, 0, 0, 0.24, 0.24, 0.24, M["lead"])
    box("cs_mouth", 0.121, 0, 0.09, 0.004, 0.06, 0.06, M["black"])
    cyl("cs_sign", 0, 0, 0.24, 0.07, 0.004, M["hazard"], 18)
    for k in range(3):
        a = k * 2 * math.pi / 3
        poly(f"cs_blade{k}",
             [(0.0, 0.0, 0.246), (0.06 * math.cos(a), 0.06 * math.sin(a), 0.246),
              (0.06 * math.cos(a + 1.05), 0.06 * math.sin(a + 1.05), 0.246)],
             [(0, 1, 2)], M["black"])


def build_bed():
    """Tedavi masası ve üstünde sırtüstü yatan hasta (başı -x, ayağı +x)."""
    begin("curie_bed")
    box("cb_top", 0, 0, 0.75, 2.0, 0.6, 0.08, M["bed"])
    box("cb_pillar", 0.5, 0, 0, 0.3, 0.3, 0.75, M["gantry"])
    box("cb_sheet", 0.3, 0, 0.83, 1.2, 0.56, 0.1, M["sheet"])
    lathe("cb_body", [(0.0, -0.35), (0.16, -0.33), (0.18, 0.0), (0.16, 0.33), (0.0, 0.35)],
          M["gown"], 16, 0, 0, 0).rotation_euler = (0, math.pi / 2, 0)
    bpy.data.objects["cb_body"].location = (-0.15, 0, 0.95)
    sphere("cb_head", -0.62, 0, 0.93, 0.1, M["skin"], 14, 8)
    sphere("cb_hair", -0.66, 0, 0.95, 0.1, M["hair"], 12, 7, sz=0.7)


def build_gantry():
    """Hastanın gövdesini saran dik halka (merkez z = 0.95, ekseni x)."""
    begin("curie_gantry")
    rotated(torus("cg_ring", 0, 0, 0, 0.85, 0.12, M["gantry"], 40, 12), (0, 0, 0.95), (0, math.pi / 2, 0))
    rotated(torus("cg_trim", 0, 0, 0, 0.72, 0.02, M["gantry_trim"], 40, 6), (-0.1, 0, 0.95), (0, math.pi / 2, 0))
    box("cg_foot", 0, 0, 0, 0.4, 1.6, 0.12, M["gantry"])


ROOT_PREFIXES = ("curie_",)


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_figure()
    build_lab()
    build_samples()
    build_counter()
    build_probe()
    build_source()
    build_bed()
    build_gantry()
    x = 0.0
    for name in roots():
        bpy.data.objects[name].location = (x, 0, 0)
        x += 9 if name == "curie_lab" else 2.5
    return roots()


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
