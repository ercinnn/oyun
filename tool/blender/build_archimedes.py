"""Bilim İnsanları / Arşimet — 3B model üreticisi (Blender 5.2, Blender MCP ile).

Hepsi tek bir `assets/models/archimedes.glb`'ye gider; mobilya ve karakterde
olduğu gibi **her parça isimli bir kök grup**tur ve oyun tarafı
(`lib/widgets/glb_model_library.dart`) yalnızca gereken grubu kopyalar.

Kimlikler Dart ile birebir aynı olmalıdır:
- `obj_<id>`: `lib/data/archimedes_objects.dart`'taki cisimler, gerçek
  hacimleriyle orantılı boyutta (1 birim = 10 cm, yani 1 birim³ = 1000 cm³).
- `obj_crown_gold`, `obj_crown_fake`: taçlar (`models/archimedes/crown.dart`).
- `arch_boat_<id>`: `archimedesBoats` gemileri; gövde tabanı z = 0, küpeşte
  z = `BOAT_HULL_HEIGHT[id]` (Dart'taki `_boatHullHeight` ile aynı).
- `arch_tank`, `arch_beaker`, `arch_crate`, `arch_screw` (içinde dönen
  `ScrewRotor`), `arch_field` (içinde büyüyen `Sprouts`), `arch_lab`,
  `arch_archimedes`.

Koordinatlar: z yukarı, grup kökü tabanın ortasında, **ön yüz -y**; glTF
dışa aktarımı bunu three'de y yukarı / ön yüz +z yapar. Vida istisnadır:
ekseni +x boyuncadır, kök alt ucun ekseni üzerindedir.

Kullanım (Blender MCP içinden):
    exec(open(r"...\\tool\\blender\\build_archimedes.py").read())
    build_all()
    show_all()      # dışa aktarmadan önce ŞART (gizli nesne aktarılmaz)
    roots()         # dışa aktarılacak kök adları
"""

import os

import bpy
import math

# Ortak yardımcılar (mat, box, lathe, sphere, torus, group, begin, clear,
# show_all, show_only, render_preview). MCP'den çalıştırırken `exec` öncesi
# `TOOL_DIR = r"...\tool\blender"` tanımlanmalı (`__file__` yoktur).
_HERE = globals().get("TOOL_DIR") or os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_HERE, "lab_helpers.py"), encoding="utf-8").read())

TANK_INNER = 1.6      # iç genişlik/derinlik (birim)
TANK_HEIGHT = 2.0     # 20 cm
BOAT_HULL_HEIGHT = {"rowboat": 0.35, "raft": 0.22, "sailboat": 0.45}
SCREW_LENGTH = 3.0    # 1 birim = 1 m (vida istasyonu)
SCREW_RADIUS = 0.24
FIELD_HEIGHT = 1.2


M = {}


def materials():
    M.update(
        stone=mat("arch_stone", 0x8D8A85, 0.95),
        wood=mat("arch_wood", 0xB07A45, 0.85),
        wood_dark=mat("arch_wood_dark", 0x7A4E2A, 0.85),
        cork=mat("arch_cork", 0xC89B63, 0.95),
        apple=mat("arch_apple", 0xD7263D, 0.55),
        leaf=mat("arch_leaf", 0x4CAF50, 0.7),
        stem=mat("arch_stem", 0x5D4037, 0.9),
        iron=mat("arch_iron", 0x5F6A72, 0.35, metal=0.9),
        brass=mat("arch_brass", 0xC9A227, 0.35, metal=0.9),
        ball=mat("arch_ball", 0x1E88E5, 0.45),
        ball_stripe=mat("arch_ball_stripe", 0xFFFFFF, 0.45),
        ice=mat("arch_ice", 0xCFEFFF, 0.15, emit=0.08),
        coin=mat("arch_coin", 0xD4AF37, 0.3, metal=1.0),
        clay=mat("arch_clay", 0xF28C28, 0.9),
        gold=mat("arch_gold", 0xF2C230, 0.25, metal=1.0),
        fake=mat("arch_fake_gold", 0xD9C58A, 0.35, metal=0.9),
        gem=mat("arch_gem", 0xC62828, 0.2),
        marble=mat("arch_marble", 0xECE6DA, 0.6),
        marble_dark=mat("arch_marble_dark", 0xCFC6B4, 0.7),
        terracotta=mat("arch_terracotta", 0xC0643A, 0.85),
        frame=mat("arch_frame", 0x455A64, 0.5, metal=0.4),
        glass_rim=mat("arch_glass_rim", 0xB3E5FC, 0.2),
        white=mat("arch_white", 0xFAFAFA, 0.6),
        tick=mat("arch_tick", 0x263238, 0.6),
        sail=mat("arch_sail", 0xF5EBDD, 0.9),
        sail_stripe=mat("arch_sail_stripe", 0x1565C0, 0.9),
        rope=mat("arch_rope", 0xA1887F, 0.95),
        soil=mat("arch_soil", 0x6D4C33, 0.95),
        grass=mat("arch_grass", 0x7CB342, 0.9),
        sprout=mat("arch_sprout", 0x43A047, 0.7),
        skin=mat("arch_skin", 0xE0A77F, 0.7),
        beard=mat("arch_beard", 0xEEEEEE, 0.9),
        robe=mat("arch_robe", 0xF1ECE2, 0.85),
        robe_trim=mat("arch_robe_trim", 0x1565C0, 0.8),
        laurel=mat("arch_laurel", 0x558B2F, 0.7),
        eye=mat("arch_eye", 0x212121, 0.4),
        crate=mat("arch_crate", 0xC68A4E, 0.85),
        crate_band=mat("arch_crate_band", 0x6D4C41, 0.85),
    )


# ─────────────────────────── Cisimler ───────────────────────────
# Boyutlar hacimle orantılı: V (cm³) / 1000 = birim³.


def build_objects():
    begin("obj_stone")
    sphere("stone_body", 0, 0, 0.26, 0.36, M["stone"], 9, 6, sz=0.72, sy=0.85)

    begin("obj_wood")
    box("wood_body", 0, 0, 0, 0.8, 0.5, 0.5, M["wood"])
    for i, x in enumerate((-0.25, 0.05, 0.3)):
        box(f"wood_grain{i}", x, -0.251, 0.08, 0.03, 0.004, 0.34, M["wood_dark"])

    begin("obj_cork")
    cyl("cork_body", 0, 0, 0, 0.16, 0.34, M["cork"], 16, r_top=0.14)

    begin("obj_apple")
    lathe("apple_body", [(0, 0.03), (0.2, 0.0), (0.33, 0.12), (0.39, 0.33),
                         (0.34, 0.54), (0.2, 0.64), (0.07, 0.6), (0, 0.56)],
          M["apple"], 22)
    cyl("apple_stem", 0, 0, 0.56, 0.025, 0.16, M["stem"], 6)
    sphere("apple_leaf", 0.1, 0, 0.7, 0.1, M["leaf"], 8, 5, sz=0.25, sy=0.5)

    begin("obj_iron_ball")
    sphere("iron_body", 0, 0, 0.2, 0.2, M["iron"], 18, 10)

    begin("obj_key")
    torus("key_bow", -0.2, 0, 0.03, 0.1, 0.03, M["brass"], 16, 6)
    box("key_shaft", 0.1, 0, 0.0, 0.4, 0.05, 0.05, M["brass"])
    box("key_bit1", 0.22, -0.05, 0.0, 0.05, 0.08, 0.05, M["brass"])
    box("key_bit2", 0.29, -0.04, 0.0, 0.04, 0.06, 0.05, M["brass"])

    begin("obj_ball")
    sphere("ball_body", 0, 0, 0.34, 0.34, M["ball"], 20, 12)
    torus("ball_stripe", 0, 0, 0.34, 0.335, 0.025, M["ball_stripe"], 28, 6)

    begin("obj_ice")
    box("ice_body", 0, 0, 0, 0.37, 0.37, 0.37, M["ice"])

    begin("obj_coin")
    cyl("coin_body", 0, 0, 0, 0.13, 0.025, M["coin"], 20)

    begin("obj_clay_ball")
    sphere("clay_ball_body", 0, 0, 0.31, 0.31, M["clay"], 18, 10)

    begin("obj_clay_bowl")
    # Kase: dış profil + iç profil (et kalınlığı 0.05); ağız açık.
    outer = [(0.0, 0.0), (0.3, 0.02), (0.48, 0.14), (0.56, 0.32)]
    inner = [(0.51, 0.32), (0.43, 0.17), (0.27, 0.07), (0.0, 0.06)]
    lathe("clay_bowl_body", outer + inner, M["clay"], 26)

    for fake in (False, True):
        begin("obj_crown_fake" if fake else "obj_crown_gold")
        m = M["fake"] if fake else M["gold"]
        s = 1.08 if fake else 1.0  # sahte taç biraz daha büyük
        R = 0.27 * s
        lathe(f"crown_band{int(fake)}",
              [(R, 0), (R, 0.14 * s), (R - 0.04, 0.14 * s), (R - 0.04, 0)],
              m, 28)
        for i in range(7):
            a = 2 * math.pi * i / 7
            x, y = R * math.cos(a) * 0.93, R * math.sin(a) * 0.93
            ob = cyl(f"crown_point{int(fake)}_{i}", x, y, 0.13 * s, 0.05 * s,
                     0.14 * s, m, 4, r_top=0.0)
            sphere(f"crown_gem{int(fake)}_{i}", R * 1.0 * math.cos(a),
                   R * 1.0 * math.sin(a), 0.07 * s, 0.028, M["gem"], 8, 5)


# ─────────────────────────── Deney düzeneği ───────────────────────────


def build_tank():
    """İnce opak çerçeveli su kabı (cam yok: saydam yüzey sıralaması sorun
    çıkarıyor). İç ölçü TANK_INNER × TANK_INNER × TANK_HEIGHT; ön-üst kenarda
    ölçü kabına su akıtan bir oluk ve sol ön dikmede cm çizgileri."""
    begin("arch_tank")
    w = TANK_INNER / 2
    t = 0.06
    box("tank_base", 0, 0, -0.12, TANK_INNER + 2 * t, TANK_INNER + 2 * t, 0.12,
        M["frame"])
    for i, (x, y) in enumerate(((-w - t / 2, -w - t / 2), (w + t / 2, -w - t / 2),
                                (w + t / 2, w + t / 2), (-w - t / 2, w + t / 2))):
        box(f"tank_post{i}", x, y, 0, t, t, TANK_HEIGHT, M["frame"])
    # Üst kenar.
    box("tank_rim_f", 0, -w - t / 2, TANK_HEIGHT - t, TANK_INNER + 2 * t, t, t,
        M["frame"])
    box("tank_rim_b", 0, w + t / 2, TANK_HEIGHT - t, TANK_INNER + 2 * t, t, t,
        M["frame"])
    box("tank_rim_l", -w - t / 2, 0, TANK_HEIGHT - t, t, TANK_INNER, t, M["frame"])
    box("tank_rim_r", w + t / 2, 0, TANK_HEIGHT - t, t, TANK_INNER, t, M["frame"])
    # Arka "cam": opak, açık mavi bir pano — su seviyesi arkadan okunaklı olsun.
    box("tank_back", 0, w + t, 0, TANK_INNER, 0.02, TANK_HEIGHT, M["glass_rim"])
    # Cetvel: sol ön dikmede her 1 cm (0.1 birim) bir çizgi, 5 cm'de uzun.
    box("tank_ruler", -w + 0.06, -w - 0.005, 0, 0.1, 0.01, TANK_HEIGHT, M["white"])
    for i in range(1, 20):
        long = i % 5 == 0
        box(f"tank_tick{i}", -w + 0.06 - (0.0 if long else 0.02), -w - 0.012,
            i * 0.1 - 0.006, 0.09 if long else 0.05, 0.004, 0.012, M["tick"])
    # Oluk.
    box("tank_spout", w - 0.25, -w - t - 0.12, TANK_HEIGHT - 0.1, 0.18, 0.26,
        0.04, M["frame"])


def build_beaker():
    """Taşan suyun toplandığı ölçü kabı: taban, üst halka, dikmeler, çizgiler.
    Su silindiri oyun tarafında çizilir."""
    begin("arch_beaker")
    r, h = 0.32, 0.9
    cyl("beaker_base", 0, 0, 0, r + 0.03, 0.04, M["frame"], 20)
    torus("beaker_rim", 0, 0, h, r, 0.018, M["glass_rim"], 24, 6)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        cyl(f"beaker_post{i}", r * math.cos(a), r * math.sin(a), 0, 0.015, h,
            M["glass_rim"], 6)
    for i in range(1, 9):
        box(f"beaker_tick{i}", 0, -r - 0.012, i * 0.1, 0.1 if i % 2 == 0 else 0.05,
            0.006, 0.012, M["tick"])


def build_crate():
    begin("arch_crate")
    s = 0.3
    box("crate_body", 0, 0, 0, s, s, s, M["crate"])
    for i, z in enumerate((0.03, s - 0.07)):
        box(f"crate_band{i}", 0, 0, z, s + 0.012, s + 0.012, 0.04, M["crate_band"])


def build_boats():
    # Kayık: sivri burunlu, açık gövde.
    begin("arch_boat_rowboat")
    H = BOAT_HULL_HEIGHT["rowboat"]
    L, W = 1.8, 0.7
    prof = []
    n = 9
    for i in range(n + 1):
        x = -L / 2 + L * i / n
        taper = math.cos((x / (L / 2)) * math.pi / 2) ** 0.6
        prof.append((x, W / 2 * max(taper, 0.05)))
    _hull("rowboat_hull", prof, H, M["wood"], M["wood_dark"])
    for i, x in enumerate((-0.35, 0.3)):
        box(f"rowboat_seat{i}", x, 0, H * 0.55, 0.14, W * 0.8, 0.04, M["wood_dark"])

    # Sal: kütüklerden.
    begin("arch_boat_raft")
    H = BOAT_HULL_HEIGHT["raft"]
    for i in range(6):
        y = -0.55 + i * 0.22
        ob = cyl(f"raft_log{i}", 0, 0, 0, H / 2, 1.6, M["wood"], 10)
        ob.rotation_euler = (0, math.pi / 2, 0)
        ob.location = (-0.8, y, H / 2)
    for i, x in enumerate((-0.6, 0.6)):
        box(f"raft_tie{i}", x, 0, H - 0.02, 0.08, 1.34, 0.04, M["rope"])

    # Yelkenli: posterdeki gibi — geniş gövde, direk, çizgili yelken.
    begin("arch_boat_sailboat")
    H = BOAT_HULL_HEIGHT["sailboat"]
    L, W = 2.4, 1.0
    prof = []
    for i in range(n + 1):
        x = -L / 2 + L * i / n
        u = x / (L / 2)
        taper = (1 - max(0.0, u) ** 2.2) ** 0.5 if u > 0 else (1 - (-u) ** 4) ** 0.35
        prof.append((x, W / 2 * max(taper, 0.06)))
    _hull("sailboat_hull", prof, H, M["wood"], M["wood_dark"])
    cyl("sail_mast", 0.05, 0, 0.05, 0.035, 2.0, M["wood_dark"], 8)
    box("sail_boom", -0.3, 0, 0.62, 0.8, 0.04, 0.04, M["wood_dark"])
    # Yelken: direkle bumba arasında dörtgen, iki mavi şerit.
    for i, (z0, z1, m) in enumerate(((0.66, 1.2, M["sail"]), (1.2, 1.36, M["sail_stripe"]),
                                     (1.36, 1.78, M["sail"]), (1.78, 1.9, M["sail_stripe"]))):
        poly(f"sail_{i}", [(0.02, 0, z0), (-0.68 + (z0 - 0.66) * 0.45, 0, z0),
                           (-0.68 + (z1 - 0.66) * 0.45, 0, z1), (0.02, 0, z1)],
             [(0, 1, 2, 3), (3, 2, 1, 0)], m)
    poly("sail_flag", [(0.07, 0, 2.02), (0.4, 0, 1.95), (0.07, 0, 1.88)],
         [(0, 1, 2), (2, 1, 0)], M["apple"])


def _hull(name, profile, H, m, m_rim):
    """Profil: [(x, yarı-genişlik)]. Tabanı dar, yanları eğimli, içi açık,
    kalın küpeşteli tekne gövdesi."""
    k = len(profile)
    verts = []
    # 0: dış taban (daraltılmış), 1: dış küpeşte, 2: iç küpeşte, 3: iç taban
    for (x, hw) in profile:
        verts += [(x, -hw * 0.55, 0.0), (x, hw * 0.55, 0.0)]
    for (x, hw) in profile:
        verts += [(x, -hw, H), (x, hw, H)]
    t = 0.05
    for (x, hw) in profile:
        verts += [(x, -max(hw - t, 0.0), H), (x, max(hw - t, 0.0), H)]
    for (x, hw) in profile:
        verts += [(x, -max(hw * 0.55 - t, 0.0), 0.06), (x, max(hw * 0.55 - t, 0.0), 0.06)]
    B, R, I, F = 0, 2 * k, 4 * k, 6 * k
    faces = []
    for i in range(k - 1):
        a, b = 2 * i, 2 * (i + 1)
        faces.append((B + a, B + b, B + b + 1, B + a + 1))           # taban
        faces.append((B + a, R + a, R + b, B + b))                   # sol dış
        faces.append((B + a + 1, B + b + 1, R + b + 1, R + a + 1))   # sağ dış
        faces.append((R + a, I + a, I + b, R + b))                   # sol küpeşte
        faces.append((R + a + 1, R + b + 1, I + b + 1, I + a + 1))   # sağ küpeşte
        faces.append((I + a, F + a, F + b, I + b))                   # sol iç
        faces.append((I + a + 1, I + b + 1, F + b + 1, F + a + 1))   # sağ iç
        faces.append((F + a, F + a + 1, F + b + 1, F + b))           # iç taban
    # Kıç ve baş kapakları.
    for (a, flip) in ((0, False), (2 * (k - 1), True)):
        q = [B + a, B + a + 1, R + a + 1, R + a]
        faces.append(tuple(reversed(q)) if flip else tuple(q))
    poly(name, verts, faces, m)
    # Küpeşte şeridi (koyu).
    for i in range(k - 1):
        (x0, h0), (x1, h1) = profile[i], profile[i + 1]
        for side in (-1, 1):
            poly(f"{name}_rim{i}_{side}",
                 [(x0, side * h0, H - 0.05), (x1, side * h1, H - 0.05),
                  (x1, side * (h1 + 0.012), H + 0.005), (x0, side * (h0 + 0.012), H + 0.005)],
                 [(0, 1, 2, 3), (3, 2, 1, 0)], m_rim)


def build_screw():
    """Arşimet vidası. Ekseni +x; kök alt uçtadır. `ScrewRotor` (sarmal +
    mil + kol) oyun tarafında kendi x ekseni etrafında döner; dış kafes
    (`screw_cage_*`) sabit kalır."""
    global _parent
    root = begin("arch_screw")
    L, R = SCREW_LENGTH, SCREW_RADIUS
    # Kafes: 6 uzun çıta + 5 halka.
    for i in range(6):
        a = 2 * math.pi * i / 6
        ob = cyl(f"screw_cage_slat{i}", 0, 0, 0, 0.025, L, M["wood_dark"], 6)
        ob.rotation_euler = (0, math.pi / 2, 0)
        ob.location = (0, R * math.cos(a), R * math.sin(a))
    for i in range(5):
        ob = torus(f"screw_cage_ring{i}", 0, 0, 0, R, 0.03, M["frame"], 24, 6)
        ob.rotation_euler = (0, math.pi / 2, 0)
        ob.location = (0.05 + i * (L - 0.1) / 4, 0, 0)
    rotor = group("ScrewRotor")
    rotor.parent = root
    _parent = rotor
    ob = cyl("screw_shaft", 0, 0, 0, 0.05, L + 0.5, M["wood_dark"], 10)
    ob.rotation_euler = (0, math.pi / 2, 0)
    ob.location = (-0.05, 0, 0)
    # Sarmal kanat: iki turdan fazla, iç yarıçap milde, dış yarıçap kafeste.
    turns, steps = 6, 6 * 24
    r0, r1, th = 0.05, R - 0.03, 0.03
    verts, faces = [], []
    for s in range(steps + 1):
        u = s / steps
        a = 2 * math.pi * turns * u
        x = 0.05 + u * (L - 0.1)
        for (r, dx) in ((r0, 0), (r1, 0), (r1, th), (r0, th)):
            verts.append((x + dx, r * math.cos(a), r * math.sin(a)))
    for s in range(steps):
        a0, a1 = 4 * s, 4 * (s + 1)
        for j in range(4):
            j2 = (j + 1) % 4
            faces.append((a0 + j, a0 + j2, a1 + j2, a1 + j))
    faces.append((0, 3, 2, 1))
    faces.append((4 * steps, 4 * steps + 1, 4 * steps + 2, 4 * steps + 3))
    poly("screw_blade", verts, faces, M["wood"], smooth=True)
    # Kol: üst uçta dirsek + tutamak.
    box("screw_crank_arm", L + 0.4, 0, -0.03, 0.06, 0.06, 0.4, M["iron"])
    ob = cyl("screw_crank_handle", 0, 0, 0, 0.035, 0.28, M["wood_dark"], 8)
    ob.rotation_euler = (0, math.pi / 2, 0)
    ob.location = (L + 0.4, 0, 0.35)
    _parent = root


def build_field():
    """Nehir kenarındaki yüksek tarla: üstü FIELD_HEIGHT'te, 2.2 × 2.2.
    `Sprouts` grubu oyun tarafında su geldikçe z ölçeğiyle büyür."""
    global _parent
    root = begin("arch_field")
    box("field_bank", 0, 0, 0, 2.4, 2.4, FIELD_HEIGHT - 0.1, M["grass"])
    box("field_soil", 0, 0, FIELD_HEIGHT - 0.1, 2.2, 2.2, 0.1, M["soil"])
    # Suyun döküldüğü küçük ark (sol kenardan içeri).
    box("field_channel", -0.95, 0, FIELD_HEIGHT - 0.02, 0.3, 1.6, 0.02, M["frame"])
    sprouts = group("Sprouts")
    sprouts.parent = root
    sprouts.location = (0, 0, FIELD_HEIGHT)
    _parent = sprouts
    k = 0
    for row in range(5):
        for col in range(4):
            x, y = -0.55 + col * 0.42, -0.8 + row * 0.4
            cyl(f"sprout_stem{k}", x, y, 0, 0.02, 0.22, M["sprout"], 5)
            sphere(f"sprout_leaf{k}", x, y, 0.22, 0.08, M["sprout"], 6, 4,
                   sz=0.5, sx=1.4, sy=0.6)
            k += 1
    _parent = root


def build_lab():
    """Antik atölye zemini: mermer döşeme, arkada sütunlar, tank için taş
    masa. Masa üstü z = 0.9; tank(lar) oyun tarafında masaya konur."""
    begin("arch_lab")
    for i in range(6):
        for j in range(3):
            m = M["marble"] if (i + j) % 2 == 0 else M["marble_dark"]
            box(f"lab_tile{i}_{j}", -5 + i * 2 + 1, -1 + j * 2 - 1, -0.1, 2, 2, 0.1, m)
    for i, x in enumerate((-4.2, -1.4, 1.4, 4.2)):
        cyl(f"lab_column_base{i}", x, 2.3, 0, 0.42, 0.18, M["marble_dark"], 16)
        lathe(f"lab_column{i}", [(0.32, 0.18), (0.3, 1.8), (0.28, 3.2)],
              M["marble"], 16, x, 2.3, 0)
        box(f"lab_column_cap{i}", x, 2.3, 3.38, 0.8, 0.8, 0.16, M["marble_dark"])
    box("lab_beam", 0, 2.3, 3.54, 9.4, 0.8, 0.3, M["marble"])
    box("lab_table", 0, -0.2, 0, 4.4, 2.2, 0.9, M["marble_dark"])
    box("lab_table_top", 0, -0.2, 0.9 - 0.08, 4.6, 2.4, 0.08, M["marble"])
    # Arkada birkaç amfora (atmosfer).
    for i, x in enumerate((-3.2, 3.3)):
        lathe(f"lab_amphora{i}", [(0.0, 0.0), (0.12, 0.02), (0.3, 0.35),
                                  (0.26, 0.7), (0.09, 0.82), (0.11, 0.95), (0.0, 0.95)],
              M["terracotta"], 16, x, 1.5, 0)


def build_archimedes():
    """Sakallı, togalı Arşimet; yüzü -y'ye bakar, 1.75 boyunda, sağ eli
    havada ("Evreka!")."""
    begin("arch_archimedes")
    lathe("arch_robe", [(0.0, 0.0), (0.42, 0.0), (0.36, 0.6), (0.28, 1.2),
                        (0.2, 1.38), (0.0, 1.4)], M["robe"], 20)
    torus("arch_robe_hem", 0, 0, 0.06, 0.41, 0.03, M["robe_trim"], 24, 6)
    # Omuzdan çapraz şerit.
    # Döndürülen parçalar orijinde kurulup sonra yerine taşınır (dönüş
    # nesnenin orijini etrafında olur).
    ob = box("arch_sash", 0, 0, -0.4, 0.12, 0.05, 0.8, M["robe_trim"])
    ob.location = (0, -0.29, 1.0)
    ob.rotation_euler = (0.12, 0.55, 0)
    sphere("arch_head", 0, 0, 1.56, 0.18, M["skin"], 16, 10)
    sphere("arch_nose", 0, -0.18, 1.55, 0.035, M["skin"], 8, 5)
    for side in (-1, 1):
        sphere(f"arch_eye{side}", side * 0.065, -0.155, 1.6, 0.022, M["eye"], 8, 5)
        sphere(f"arch_brow{side}", side * 0.07, -0.16, 1.645, 0.045, M["beard"], 8, 4, sz=0.35)
    sphere("arch_beard", 0, -0.08, 1.4, 0.17, M["beard"], 14, 8, sz=1.25, sy=0.8)
    sphere("arch_hair", 0, 0.03, 1.6, 0.19, M["beard"], 14, 8, sz=0.85, sx=1.02)
    torus("arch_laurel", 0, 0, 1.68, 0.18, 0.03, M["laurel"], 20, 6)
    # Kollar: sol aşağıda, sağ yukarıda.
    ob = cyl("arch_arm_l", 0, 0, 0, 0.06, 0.55, M["robe"], 8)
    ob.location = (-0.3, 0, 0.72)
    ob.rotation_euler = (0, -0.25, 0)
    sphere("arch_hand_l", -0.36, 0, 0.68, 0.06, M["skin"], 8, 5)
    ob = cyl("arch_arm_r", 0, 0, 0, 0.06, 0.55, M["robe"], 8)
    ob.location = (0.3, 0, 1.22)
    ob.rotation_euler = (0, 0.45, 0)
    sphere("arch_hand_r", 0.54, 0, 1.72, 0.06, M["skin"], 8, 5)
    for side in (-1, 1):
        box(f"arch_sandal{side}", side * 0.12, -0.12, 0, 0.12, 0.24, 0.04, M["stem"])


# ─────────────────────────── Toplu işlemler ───────────────────────────

ROOT_PREFIXES = ("obj_", "arch_")


def roots():
    return roots_with(ROOT_PREFIXES)


def build_all():
    clear()
    materials()
    build_objects()
    build_tank()
    build_beaker()
    build_crate()
    build_boats()
    build_screw()
    build_field()
    build_lab()
    build_archimedes()
    layout_preview()
    return roots()


def layout_preview():
    """İnceleme için kökleri yan yana dizer. Dışa aktarmadan önce
    `reset_positions()` çağrılmalı: oyun her grubu kendi yerleştirir."""
    x = 0.0
    for name in roots():
        ob = bpy.data.objects[name]
        if name == "arch_lab":
            ob.location = (0, 8, 0)
            continue
        ob.location = (x, 0, 0)
        x += 3.2 if name.startswith(("arch_screw", "arch_field", "arch_boat")) else 1.4


def reset_positions():
    for name in roots():
        bpy.data.objects[name].location = (0, 0, 0)
