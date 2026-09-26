"""Bilim İnsanları / Tesla — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/tesla.glb`'ye gider; her parça isimli bir kök
gruptur (`GlbModelLibrary`).

Kimlikler Dart ile aynı olmalıdır (kodun adla aradığı iç düğümler parantezde):
- `tesla_figure` (yüzü -y, 1.85 boy), `tesla_lab` (zemin + tezgâh, tezgâh üstü
  z = 0.85).
- `tesla_generator` (`Rotor`: tel bobin + mil + kol, x ekseni etrafında
  döner; ekseni z = 0.2; mıknatıslar bobinin üstünde/altında), `tesla_bulb` (`bulb_glass`), `tesla_leds`
  (`led_red`, `led_green`), `tesla_battery`.
- `tesla_plant` (Niagara'daki gibi hidroelektrik santral), `tesla_transformer`,
  `tesla_pylon` (kol yüksekliği z = 4), `tesla_house` (`window0`, `window1`).
- `tesla_coil` (tepe halkası z = 1.6), `tesla_lamp` (`lamp_tube`).
Kodun yeniden boyadığı parçalar (cam, LED, pencere, lamba tüpü) kendine ait
malzeme taşır; oyun onlara tek başına bir malzeme verir.

Koordinatlar: z yukarı, ön yüz -y (three'de +z), 1 birim = 1 m.

Kullanım (Blender MCP içinden):
    TOOL_DIR = r"...\\tool\\blender"
    exec(open(TOOL_DIR + r"\\build_tesla.py", encoding="utf-8").read())
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
        skin=mat("ts_skin", 0xE8BC98, 0.7),
        hair=mat("ts_hair", 0x1B1B1F, 0.8),
        suit=mat("ts_suit", 0x23252B, 0.8),
        shirt=mat("ts_shirt", 0xF5F5F5, 0.8),
        tie=mat("ts_tie", 0x4A148C, 0.7),
        eye=mat("ts_eye", 0x212121, 0.4),
        shoe=mat("ts_shoe", 0x111111, 0.5),
        wood=mat("ts_wood", 0x8D5A34, 0.8),
        wood_dark=mat("ts_wood_dark", 0x5D3A22, 0.85),
        floor=mat("ts_floor", 0x6D4C41, 0.9),
        wall=mat("ts_wall", 0x8D6E63, 0.95),
        brick=mat("ts_brick", 0xA1553A, 0.9),
        copper=mat("ts_copper", 0xC77B30, 0.35, metal=0.9),
        iron=mat("ts_iron", 0x607D8B, 0.4, metal=0.8),
        steel=mat("ts_steel", 0x90A4AE, 0.35, metal=0.8),
        magnet_n=mat("ts_magnet_n", 0xD32F2F, 0.5),
        magnet_s=mat("ts_magnet_s", 0x1976D2, 0.5),
        black=mat("ts_black", 0x212121, 0.6),
        white=mat("ts_white", 0xFAFAFA, 0.7),
        brass=mat("ts_brass", 0xC9A227, 0.35, metal=0.9),
        glass_bulb=mat("ts_bulb_glass", 0xFFF8E1, 0.2),
        filament=mat("ts_filament", 0x6D4C41, 0.5),
        led_red=mat("ts_led_red", 0x7F1D1D, 0.3),
        led_green=mat("ts_led_green", 0x1B5E20, 0.3),
        board=mat("ts_board", 0x2E7D32, 0.8),
        battery=mat("ts_battery", 0x37474F, 0.6),
        battery_top=mat("ts_battery_top", 0xC77B30, 0.4, metal=0.8),
        stone=mat("ts_stone", 0xBCAAA4, 0.9),
        roof=mat("ts_roof", 0x6D4C41, 0.85),
        roof_red=mat("ts_roof_red", 0xB23A48, 0.85),
        window=mat("ts_window", 0x37474F, 0.4),
        window1=mat("ts_window1", 0x37474F, 0.4),
        door=mat("ts_door", 0x5D4037, 0.8),
        house=mat("ts_house", 0xF1E3C8, 0.9),
        water=mat("ts_water", 0x4FC3F7, 0.2),
        insulator=mat("ts_insulator", 0xE0E0E0, 0.3),
        coil_white=mat("ts_coil_white", 0xECEFF1, 0.5),
        lamp_tube=mat("ts_lamp_tube", 0xE0F7FA, 0.2),
    )


def rotated(ob, loc, rot):
    ob.rotation_euler = rot
    ob.location = loc
    return ob


def build_figure():
    """Nikola Tesla: uzun boylu ve zayıf, koyu takım elbise, beyaz yaka,
    mor kravat, ortadan ayrılmış siyah saç ve bıyık."""
    begin("tesla_figure")
    for side in (-1, 1):
        cyl(f"tf_leg{side}", side * 0.1, 0, 0.05, 0.065, 0.85, M["suit"], 10)
        box(f"tf_shoe{side}", side * 0.1, -0.05, 0, 0.11, 0.26, 0.06, M["shoe"])
    lathe("tf_body", [(0.0, 0.85), (0.22, 0.85), (0.24, 1.2), (0.25, 1.5),
                      (0.13, 1.58), (0.0, 1.6)], M["suit"], 20)
    # Gömlek ve kravat (önde).
    box("tf_shirt", 0, -0.2, 1.3, 0.12, 0.04, 0.28, M["shirt"])
    box("tf_tie", 0, -0.22, 1.25, 0.05, 0.03, 0.3, M["tie"])
    cyl("tf_neck", 0, 0, 1.56, 0.06, 0.1, M["skin"], 10)
    sphere("tf_head", 0, 0, 1.73, 0.14, M["skin"], 16, 10, sz=1.12)
    sphere("tf_nose", 0, -0.14, 1.72, 0.025, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"tf_eye{side}", side * 0.05, -0.12, 1.76, 0.018, M["eye"], 8, 5)
        # Ortadan ayrılmış saç: iki yarım kubbe.
        sphere(f"tf_hair{side}", side * 0.06, 0.02, 1.83, 0.12, M["hair"], 12, 7,
               sz=0.55, sx=0.9)
    sphere("tf_moustache", 0, -0.13, 1.67, 0.06, M["hair"], 10, 6, sz=0.3, sx=1.5)
    rotated(cyl("tf_arm_r", 0, 0, 0, 0.055, 0.62, M["suit"], 8), (0.27, 0, 0.9), (0, -0.08, 0))
    sphere("tf_hand_r", 0.29, 0, 0.87, 0.05, M["skin"], 8, 5)
    rotated(cyl("tf_arm_l", 0, 0, 0, 0.055, 0.55, M["suit"], 8), (-0.26, 0, 1.46), (1.9, 0, 0))
    sphere("tf_hand_l", -0.26, -0.52, 1.28, 0.05, M["skin"], 8, 5)


def build_lab():
    begin("tesla_lab")
    for i in range(8):
        box(f"tl_board{i}", -3.5 + i, 0, -0.06, 0.98, 5, 0.06,
            M["floor"] if i % 2 else M["wood_dark"])
    box("tl_wall", 0, 2.4, 0, 8, 0.2, 3.2, M["brick"])
    box("tl_bench_top", 0, 0.4, 0.8, 3.2, 1.0, 0.05, M["wood"])
    for i, (x, y) in enumerate(((-1.5, -0.05), (1.5, -0.05), (1.5, 0.85), (-1.5, 0.85))):
        box(f"tl_bench_leg{i}", x, y, 0, 0.08, 0.08, 0.8, M["wood_dark"])


def build_generator():
    """Tahta taban üstünde at nalı mıknatıs (üstte kırmızı N, altta mavi S) ve
    kutupların arasında dönen dikdörtgen tel bobin. `Rotor` ekseni x, z = 0.2; kol +x ucunda."""
    global _parent
    root = begin("tesla_generator")
    box("tg_base", 0, 0, 0, 0.7, 0.42, 0.04, M["wood"])
    # At nalı mıknatıs: kutuplar bobinin altında (mavi S) ve üstünde (kırmızı
    # N), arkada demir boyunduruk. Önde mıknatıs yok ki dönen bobin görünsün.
    box("tg_magnet_s", 0, 0.02, 0.04, 0.26, 0.24, 0.035, M["magnet_s"])
    box("tg_magnet_n", 0, 0.02, 0.345, 0.26, 0.24, 0.05, M["magnet_n"])
    box("tg_yoke", 0, 0.16, 0.04, 0.26, 0.05, 0.355, M["iron"])
    box("tg_label_n", 0, -0.101, 0.355, 0.06, 0.004, 0.03, M["white"])
    for side in (-1, 1):
        box(f"tg_bearing{side}", side * 0.28, 0, 0.04, 0.04, 0.08, 0.2, M["iron"])
    rotor = group("Rotor")
    rotor.parent = root
    rotor.location = (0, 0, 0.2)
    _parent = rotor
    rotated(cyl("tg_shaft", 0, 0, 0, 0.012, 0.72, M["steel"], 8), (-0.34, 0, 0), (0, math.pi / 2, 0))
    # Bobin: dikdörtgen çerçeve üstünde birkaç sarım.
    for k in range(4):
        off = (k - 1.5) * 0.012
        box(f"tg_loop_t{k}", 0, off, 0.1, 0.24, 0.008, 0.01, M["copper"])
        box(f"tg_loop_b{k}", 0, off, -0.11, 0.24, 0.008, 0.01, M["copper"])
        box(f"tg_loop_l{k}", -0.12, off, -0.11, 0.01, 0.008, 0.22, M["copper"])
        box(f"tg_loop_r{k}", 0.115, off, -0.11, 0.01, 0.008, 0.22, M["copper"])
    for i, x in enumerate((-0.22, -0.18)):
        rotated(cyl(f"tg_slip{i}", 0, 0, 0, 0.03, 0.015, M["copper"], 16), (x, 0, 0), (0, math.pi / 2, 0))
    box("tg_crank_arm", 0.38, 0, -0.02, 0.02, 0.02, 0.14, M["iron"])
    rotated(cyl("tg_crank_handle", 0, 0, 0, 0.015, 0.08, M["wood_dark"], 8), (0.38, 0, 0.11), (0, math.pi / 2, 0))
    _parent = root


def build_bulb():
    begin("tesla_bulb")
    cyl("tb_base", 0, 0, 0, 0.06, 0.03, M["wood_dark"], 14)
    cyl("tb_socket", 0, 0, 0.03, 0.025, 0.05, M["brass"], 12)
    lathe("bulb_glass", [(0.0, 0.07), (0.02, 0.075), (0.045, 0.11), (0.05, 0.14),
                         (0.04, 0.17), (0.0, 0.18)], M["glass_bulb"], 18)
    box("tb_filament", 0, 0, 0.1, 0.02, 0.004, 0.035, M["filament"])


def build_leds():
    begin("tesla_leds")
    box("tled_board", 0, 0, 0, 0.16, 0.08, 0.012, M["board"])
    for x, name, m in ((-0.04, "led_red", "led_red"), (0.04, "led_green", "led_green")):
        cyl(f"{name}_leg", x, 0, 0.012, 0.004, 0.02, M["steel"], 6)
        lathe(name, [(0.0, 0.03), (0.014, 0.03), (0.014, 0.05), (0.01, 0.058), (0.0, 0.06)],
              M[m], 12, x, 0, 0)


def build_battery():
    begin("tesla_battery")
    cyl("tbat_body", 0, 0, 0, 0.06, 0.2, M["battery"], 16)
    cyl("tbat_top", 0, 0, 0.2, 0.06, 0.02, M["battery_top"], 16)
    cyl("tbat_plus", 0, 0, 0.22, 0.02, 0.02, M["battery_top"], 10)
    box("tbat_label", 0, -0.059, 0.08, 0.05, 0.004, 0.05, M["white"])


def build_scope():
    begin("tesla_scope")
    box("tsc_body", 0, 0, 0, 0.4, 0.3, 0.28, M["iron"])
    cyl("tsc_screen", 0, 0, 0, 0.1, 0.01, M["board"], 20).rotation_euler = (math.pi / 2, 0, 0)
    bpy.data.objects["tsc_screen"].location = (-0.06, -0.15, 0.15)
    for i in range(3):
        cyl(f"tsc_knob{i}", 0, 0, 0, 0.018, 0.02, M["black"], 10).rotation_euler = (math.pi / 2, 0, 0)
        bpy.data.objects[f"tsc_knob{i}"].location = (0.12, -0.15, 0.06 + i * 0.07)


def build_plant():
    """Niagara'daki gibi hidroelektrik santral: taş bina, kemerli pencereler,
    yanında su borusu ve türbin çarkı."""
    begin("tesla_plant")
    box("tp_building", 0, 0, 0, 3.0, 2.0, 2.0, M["stone"])
    lathe("tp_roof", [(1.9, 2.0), (0.0, 2.9)], M["roof"], 4, 0, 0, 0, smooth=False).rotation_euler = (0, 0, math.pi / 4)
    for i in range(4):
        box(f"tp_window{i}", -1.1 + i * 0.73, -1.01, 0.8, 0.4, 0.02, 0.8, M["window"])
    box("tp_door", 0.0, -1.01, 0, 0.5, 0.02, 0.9, M["door"])
    # Borudan gelen su ve çark.
    rotated(cyl("tp_pipe", 0, 0, 0, 0.18, 2.5, M["iron"], 12), (-2.6, 0, 2.8), (0, 2.2, 0))
    rotated(cyl("tp_wheel", 0, 0, 0, 0.6, 0.15, M["iron"], 16), (-1.9, -0.6, 0.7), (math.pi / 2, 0, 0))
    box("tp_water", -2.3, 0, 0, 1.2, 2.2, 0.08, M["water"])


def build_transformer():
    """Demir çekirdek (kare halka) ve iki bakır bobin: solda ince (birinci),
    sağda kalın (ikinci)."""
    begin("tesla_transformer")
    box("tt_base", 0, 0, 0, 1.0, 0.6, 0.1, M["iron"])
    for i, (x, z, w, h) in enumerate(((0, 0.1, 0.8, 0.12), (0, 0.9, 0.8, 0.12),
                                      (-0.34, 0.1, 0.12, 0.92), (0.34, 0.1, 0.12, 0.92))):
        box(f"tt_core{i}", x, 0, z, w, 0.14, h, M["steel"])
    cyl("tt_coil1", -0.34, 0, 0.3, 0.12, 0.5, M["copper"], 16)
    cyl("tt_coil2", 0.34, 0, 0.26, 0.15, 0.58, M["copper"], 16)
    for i, z in enumerate((0.34, 0.46, 0.58, 0.7)):
        torus(f"tt_turn2_{i}", 0.34, 0, z, 0.15, 0.012, M["brass"], 16, 4)


def build_pylon():
    begin("tesla_pylon")
    h = 4.0
    for i, (x, y) in enumerate(((-0.4, -0.4), (0.4, -0.4), (0.4, 0.4), (-0.4, 0.4))):
        lathe(f"tpy_post{i}", [(0.04, 0.0), (0.03, h)], M["iron"], 6, x * 1.0, y * 1.0, 0, smooth=False)
    for k in range(1, 4):
        z = k * 1.0
        box(f"tpy_ring_f{k}", 0, -0.4, z, 0.8, 0.04, 0.04, M["iron"])
        box(f"tpy_ring_b{k}", 0, 0.4, z, 0.8, 0.04, 0.04, M["iron"])
        box(f"tpy_ring_l{k}", -0.4, 0, z, 0.04, 0.8, 0.04, M["iron"])
        box(f"tpy_ring_r{k}", 0.4, 0, z, 0.04, 0.8, 0.04, M["iron"])
    box("tpy_arm", 0, 0, h, 0.12, 2.0, 0.1, M["iron"])
    for side in (-1, 1):
        cyl(f"tpy_insulator{side}", 0, side * 0.9, h - 0.25, 0.04, 0.25, M["insulator"], 8)


def build_house():
    begin("tesla_house")
    box("th_body", 0, 0, 0, 0.9, 0.8, 0.7, M["house"])
    verts = [(-0.5, -0.45, 0.7), (0.5, -0.45, 0.7), (0.5, 0.45, 0.7), (-0.5, 0.45, 0.7),
             (-0.5, 0, 1.1), (0.5, 0, 1.1)]
    poly("th_roof", verts, [(0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5)], M["roof_red"])
    box("th_door", 0.25, -0.41, 0, 0.18, 0.02, 0.36, M["door"])
    box("window0", -0.22, -0.41, 0.35, 0.2, 0.02, 0.18, M["window"])
    box("window1", 0.0, -0.41, 0.45, 0.14, 0.02, 0.14, M["window1"])


def build_coil():
    """Tesla bobini: taban, düz sarmal birinci bobin, uzun beyaz ikinci bobin
    (bakır çizgilerle) ve tepede halka (z = 1.6)."""
    begin("tesla_coil")
    box("tc_base", 0, 0, 0, 0.8, 0.8, 0.12, M["wood_dark"])
    for i in range(4):
        torus(f"tc_primary{i}", 0, 0, 0.18, 0.2 + i * 0.05, 0.012, M["copper"], 24, 5)
    cyl("tc_secondary", 0, 0, 0.12, 0.09, 1.3, M["coil_white"], 18)
    for i in range(20):
        torus(f"tc_winding{i}", 0, 0, 0.2 + i * 0.06, 0.091, 0.004, M["copper"], 18, 4)
    cyl("tc_neck", 0, 0, 1.42, 0.03, 0.14, M["steel"], 8)
    torus("tc_toroid", 0, 0, 1.6, 0.26, 0.09, M["steel"], 28, 12)


def build_lamp():
    """Ayaklı tutucuda dik duran floresan tüp (`lamp_tube`, 0.6 m)."""
    begin("tesla_lamp")
    cyl("tlm_base", 0, 0, 0, 0.12, 0.03, M["wood_dark"], 14)
    cyl("tlm_rod", 0, 0, 0.03, 0.012, 0.5, M["iron"], 8)
    box("tlm_clamp", 0, 0, 0.5, 0.06, 0.06, 0.05, M["black"])
    cyl("lamp_tube", 0, 0, 0.55, 0.025, 0.6, M["lamp_tube"], 14)
    cyl("tlm_cap", 0, 0, 1.15, 0.03, 0.03, M["steel"], 10)


ROOT_PREFIXES = ("tesla_",)


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_figure()
    build_lab()
    build_generator()
    build_bulb()
    build_leds()
    build_battery()
    build_scope()
    build_plant()
    build_transformer()
    build_pylon()
    build_house()
    build_coil()
    build_lamp()
    x = 0.0
    for name in roots():
        bpy.data.objects[name].location = (x, 0, 0)
        x += 9 if name in ("tesla_lab", "tesla_plant") else 2.5
    return roots()


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
