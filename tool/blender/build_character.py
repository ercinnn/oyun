"""Renkli Kasaba karakteri: tüm mağaza varyantlarıyla tek bir model.

Blender'da çalıştırılır (Blender MCP `execute_blender_code` ile ya da Scripting
sekmesinde). `build()` sahneyi kurar, `preview(...)` bir kombinasyonu gösterir,
`export_glb(path)` GLB yazar.

Sözleşme (oyun kodu `lib/widgets/avatar_model.dart` buna dayanır):
- Karakter **Blender -Y'ye bakar** (glTF/three'de +z), ayakları z=0'da, boyu ~1,35.
- Pivot düğümleri: `Body`, `Head`, `ArmL`, `ArmR`, `LegL`, `LegR`, `WingL`, `WingR`.
- Varyant grupları adı `hair_*`, `outfit_*`, `hat_*`, `acc_*` (mağaza kimlikleri);
  aynı varyantın farklı pivotlara ait parçaları `outfit_space@head` gibi
  `@parça` soneki taşır. Oyun `@`'ten önceki kısma bakar.
- Boyanan malzemeler: `Skin`, `SkinDark`, `Hair`, `Outfit`, `OutfitLight`,
  `OutfitDark`. Diğerleri sabittir.

Kod, oyundaki `Avatar3D` (three ilkel şekilleri) ile aynı ölçüleri kullanır;
geometri three eksenlerinde (x sağ, y yukarı, z öne) üretilip Blender'a
`(x, y, z) -> (x, -z, y)` ile çevrilir.
"""
import bpy, bmesh, math
from mathutils import Matrix, Vector

PI = math.pi
coll = bpy.context.scene.collection


def to_b(v):
    return (v[0], -v[2], v[1])


# ── Malzemeler ─────────────────────────────────────────────────────────────
_MATS = {}


def M(name, hexcolor, rough=0.85, alpha=1.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = ((hexcolor >> 16) & 255) / 255, ((hexcolor >> 8) & 255) / 255, (hexcolor & 255) / 255, 1
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            try:
                setattr(m, attr, val)
            except Exception:
                pass
    _MATS[name] = m
    return m


def make_materials():
    for n, c in {
        "Skin": 0xE0AC69, "SkinDark": 0xC68642, "Hair": 0x2B1B10,
        "Outfit": 0x1E88E5, "OutfitLight": 0x64B5F6, "OutfitDark": 0x1565C0,
        "Pants": 0x455A64, "PantsSuit": 0x37474F, "White": 0xECEFF1,
        "Shoe": 0x37474F, "ShoeLight": 0xCFD8DC, "Dark": 0x1B1B1B,
        "Blush": 0xFF8A80, "Mouth": 0x8D3B3B, "Red": 0xD32F2F,
        "Green": 0x69F0AE, "Gray": 0xB0BEC5, "Gold": 0xFFC107,
        "Purple": 0xE040FB, "Pink": 0xEC407A, "Yellow": 0xFFEB3B,
        "Party": 0xAB47BC, "Brown": 0x795548, "BrownLight": 0x8D6E63,
        "BrownDark": 0x4E342E, "CapRed": 0xE53935, "CapRedDark": 0xB71C1C,
        "Blue": 0x29B6F6, "WingBlue": 0xE1F5FE, "Headphone": 0x424242,
        "GlassDark": 0x263238,
    }.items():
        M(n, c)
    M("Helmet", 0x81D4FA, rough=0.1, alpha=0.22)


# ── İlkel şekiller (three eksenlerinde; (verts, faces, kapak_yüzleri)) ─────
def sphere(r, nu=16, nv=10, tlen=PI):
    full = abs(tlen - PI) < 1e-6
    last = nv - 1 if full else nv
    v = [(0, r, 0)]
    for j in range(1, last + 1):
        th = tlen * j / nv
        y, rr = r * math.cos(th), r * math.sin(th)
        for i in range(nu):
            a = 2 * PI * i / nu
            v.append((rr * math.cos(a), y, rr * math.sin(a)))
    f, caps = [], []
    for i in range(nu):
        f.append((0, 1 + i, 1 + (i + 1) % nu))
    for j in range(1, last):
        b0, b1 = 1 + (j - 1) * nu, 1 + j * nu
        for i in range(nu):
            f.append((b0 + i, b1 + i, b1 + (i + 1) % nu, b0 + (i + 1) % nu))
    if full:
        v.append((0, -r, 0))
        bot = len(v) - 1
        b0 = 1 + (last - 1) * nu
        for i in range(nu):
            f.append((b0 + i, bot, b0 + (i + 1) % nu))
    else:
        v.append((0, r * math.cos(tlen), 0))
        c = len(v) - 1
        b0 = 1 + (last - 1) * nu
        for i in range(nu):
            caps.append(len(f))
            f.append((b0 + i, c, b0 + (i + 1) % nu))
    return v, f, caps


def cyl(rt, rb, h, seg=14):
    v, f, caps = [], [], []
    hy = h / 2
    for i in range(seg):
        a = 2 * PI * i / seg
        v.append((rb * math.cos(a), -hy, rb * math.sin(a)))
    apex = rt <= 1e-9
    if apex:
        v.append((0, hy, 0))
    else:
        for i in range(seg):
            a = 2 * PI * i / seg
            v.append((rt * math.cos(a), hy, rt * math.sin(a)))
    for i in range(seg):
        j = (i + 1) % seg
        if apex:
            f.append((i, seg, j))
        else:
            f.append((i, seg + i, seg + j, j))
    # alt kapak
    v.append((0, -hy, 0)); cb = len(v) - 1
    for i in range(seg):
        caps.append(len(f)); f.append((cb, (i + 1) % seg, i))
    if not apex:
        v.append((0, hy, 0)); ct = len(v) - 1
        for i in range(seg):
            caps.append(len(f)); f.append((ct, seg + i, seg + (i + 1) % seg))
    return v, f, caps


def box(w, h, d):
    x, y, z = w / 2, h / 2, d / 2
    v = [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    f = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    return v, f, []


def arc(R, tube, arclen, seg=18, rseg=6):
    closed = abs(arclen - 2 * PI) < 1e-6
    n = seg if closed else seg + 1
    v, f, caps = [], [], []
    for k in range(n):
        t = arclen * k / seg
        nx, ny = math.cos(t), math.sin(t)
        for p in range(rseg):
            a = 2 * PI * p / rseg
            ca, sa = math.cos(a), math.sin(a)
            v.append(((R + tube * ca) * nx, (R + tube * ca) * ny, tube * sa))
    rings = n if closed else n - 1
    for k in range(rings):
        k2 = (k + 1) % n
        for p in range(rseg):
            p2 = (p + 1) % rseg
            f.append((k*rseg+p, k2*rseg+p, k2*rseg+p2, k*rseg+p2))
    if not closed:
        for end, ring in ((0, 0), (1, n - 1)):
            t = arclen * ring / seg
            v.append((R * math.cos(t), R * math.sin(t), 0)); c = len(v) - 1
            for p in range(rseg):
                p2 = (p + 1) % rseg
                caps.append(len(f))
                f.append((c, ring*rseg+p2, ring*rseg+p) if end == 0 else (c, ring*rseg+p, ring*rseg+p2))
    return v, f, caps


# ── Sahne yardımcıları ─────────────────────────────────────────────────────
def empty(name, pos=(0, 0, 0), parent=None):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "PLAIN_AXES"
    e.empty_display_size = 0.05
    e.location = to_b(pos)
    coll.objects.link(e)
    bpy.context.view_layer.update()
    if parent is not None:
        e.parent = parent
        e.matrix_parent_inverse = parent.matrix_world.inverted()
    return e


def part(name, prim, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1),
         parent=None, smooth=True, round_=False, open_=False):
    verts, faces, caps = prim
    R = Matrix.Rotation(rot[0], 3, "X") @ Matrix.Rotation(rot[1], 3, "Y") @ Matrix.Rotation(rot[2], 3, "Z")
    out = []
    for vx, vy, vz in verts:
        w = R @ Vector((vx * scale[0], vy * scale[1], vz * scale[2]))
        out.append(to_b((w.x + pos[0], w.y + pos[1], w.z + pos[2])))
    bm = bmesh.new()
    bv = [bm.verts.new(p) for p in out]
    fs = [bm.faces.new([bv[i] for i in f]) for f in faces]
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    if open_ and caps:
        bmesh.ops.delete(bm, geom=[fs[i] for i in caps], context="FACES")
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(_MATS[mat] if isinstance(mat, str) else mat)
    if round_:
        mod = ob.modifiers.new("Round", "SUBSURF")
        mod.levels = 2; mod.render_levels = 2
    coll.objects.link(ob)
    if parent is not None:
        ob.parent = parent
        ob.matrix_parent_inverse = parent.matrix_world.inverted()
    return ob


def clear():
    for o in list(bpy.data.objects):
        if o.name == "Character" or o.get("_char"):
            bpy.data.objects.remove(o, do_unlink=True)


def H(x, y, z):
    """Baş yerel koordinatı → dünya."""
    return (x, 1.1 + y, z)


# ── Karakter ───────────────────────────────────────────────────────────────
def build():
    clear()
    make_materials()
    created = []

    def E(name, pos=(0, 0, 0), parent=None):
        e = empty(name, pos, parent)
        e["_char"] = True
        created.append(e)
        return e

    def P(name, prim, mat, **kw):
        ob = part(name, prim, mat, **kw)
        ob["_char"] = True
        created.append(ob)
        return ob

    root = E("Character")
    body = E("Body", (0, 0, 0), root)
    head = E("Head", (0, 1.1, 0), body)
    legs = {s: E("LegL" if s < 0 else "LegR", (s * 0.1, 0.44, 0), root) for s in (-1, 1)}
    arms = {s: E("ArmL" if s < 0 else "ArmR", (s * 0.28, 0.87, 0), body) for s in (-1, 1)}
    OUTFITS = ("tee", "dress", "hoodie", "suit", "space")

    # ── Gövde: her kıyafetin kendi gövdesi
    def torso(g, color, width, name):
        P(name + "_torso", cyl(width * 0.95, width, 0.46, 18), color, pos=(0, 0.67, 0), scale=(1, 1, 0.66), parent=g)
        P(name + "_shoulders", sphere(width * 0.95, 14, 8), color, pos=(0, 0.9, 0), scale=(1, 0.32, 0.66), parent=g)

    for o in OUTFITS:
        g = E(f"outfit_{o}@body", (0, 0, 0), body)
        n = f"{o}_b"
        if o == "tee":
            torso(g, "Outfit", 0.215, n)
            P(n + "_belt", cyl(0.215, 0.215, 0.05, 18), "Pants", pos=(0, 0.46, 0), scale=(1, 1, 0.68), parent=g)
        elif o == "dress":
            torso(g, "Outfit", 0.215, n)
            P(n + "_skirt", cyl(0.0, 0.34, 0.4, 24), "Outfit", pos=(0, 0.31, 0), parent=g, open_=False)
            P(n + "_hem", cyl(0.343, 0.343, 0.03, 24), "OutfitLight", pos=(0, 0.115, 0), parent=g)
        elif o == "hoodie":
            torso(g, "Outfit", 0.245, n)
            P(n + "_belt", cyl(0.245, 0.245, 0.05, 18), "Pants", pos=(0, 0.46, 0), scale=(1, 1, 0.68), parent=g)
            P(n + "_hood", sphere(0.16, 12, 8), "OutfitLight", pos=(0, 0.93, -0.13), scale=(1, 0.7, 1), parent=g)
            P(n + "_pocket", box(0.2, 0.11, 0.03), "OutfitLight", pos=(0, 0.55, 0.155), parent=g)
            for sx in (-0.05, 0.05):
                P(n + f"_string{sx}", cyl(0.012, 0.012, 0.13, 6), "White", pos=(sx, 0.8, 0.15), parent=g)
        elif o == "suit":
            torso(g, "Outfit", 0.215, n)
            P(n + "_belt", cyl(0.215, 0.215, 0.05, 18), "PantsSuit", pos=(0, 0.46, 0), scale=(1, 1, 0.68), parent=g)
            P(n + "_shirt", box(0.12, 0.34, 0.02), "White", pos=(0, 0.72, 0.15), parent=g)
            P(n + "_tie", box(0.035, 0.22, 0.022), "Red", pos=(0, 0.7, 0.16), parent=g)
            P(n + "_knot", box(0.06, 0.05, 0.022), "Red", pos=(0, 0.82, 0.16), parent=g)
            for s in (-1, 1):
                P(n + f"_lapel{s}", box(0.05, 0.3, 0.02), "OutfitLight", pos=(s * 0.085, 0.72, 0.152), rot=(0, 0, s * 0.18), parent=g)
        elif o == "space":
            torso(g, "White", 0.215, n)
            P(n + "_panel", box(0.2, 0.17, 0.03), "Outfit", pos=(0, 0.72, 0.15), parent=g)
            P(n + "_btnA", cyl(0.022, 0.022, 0.03, 8), "Red", pos=(-0.05, 0.74, 0.168), rot=(PI / 2, 0, 0), parent=g)
            P(n + "_btnB", cyl(0.022, 0.022, 0.03, 8), "Green", pos=(0.05, 0.74, 0.168), rot=(PI / 2, 0, 0), parent=g)
            P(n + "_pack", box(0.3, 0.38, 0.13), "Gray", pos=(0, 0.7, -0.19), parent=g, smooth=False, round_=True)
    P("neck", cyl(0.065, 0.07, 0.09, 10), "Skin", pos=(0, 0.95, 0), parent=body)

    # ── Bacaklar
    for s, leg in legs.items():
        for o in OUTFITS:
            g = E(f"outfit_{o}@leg{'L' if s < 0 else 'R'}", (0, 0, 0), leg)
            mat = {"dress": "Skin", "suit": "PantsSuit", "space": "White"}.get(o, "Pants")
            shoe = "ShoeLight" if o == "space" else "Shoe"
            P(f"{o}_leg{s}", cyl(0.07, 0.062, 0.34, 10), mat, pos=(s * 0.1, 0.27, 0), parent=g)
            P(f"{o}_shoe{s}", box(0.15, 0.09, 0.25), shoe, pos=(s * 0.1, 0.055, 0.04), parent=g, round_=True)

    # ── Kollar
    for s, arm in arms.items():
        ax = s * 0.28
        for o in OUTFITS:
            g = E(f"outfit_{o}@arm{'L' if s < 0 else 'R'}", (0, 0, 0), arm)
            n = f"{o}_a{s}"
            if o in ("tee", "dress"):
                P(n + "_sleeve", cyl(0.068, 0.064, 0.13, 10), "Outfit", pos=(ax, 0.805, 0), parent=g)
                P(n + "_fore", cyl(0.055, 0.05, 0.23, 10), "Skin", pos=(ax, 0.645, 0), parent=g)
                P(n + "_hand", sphere(0.062, 10, 8), "Skin", pos=(ax, 0.5, 0), parent=g)
                P(n + "_ball", sphere(0.068, 10, 8), "Outfit", pos=(ax, 0.87, 0), parent=g)
            elif o == "space":
                P(n + "_sleeve", cyl(0.065, 0.058, 0.34, 10), "White", pos=(ax, 0.70, 0), parent=g)
                P(n + "_hand", sphere(0.064, 10, 8), "Outfit", pos=(ax, 0.5, 0), parent=g)
                P(n + "_ball", sphere(0.068, 10, 8), "White", pos=(ax, 0.87, 0), parent=g)
            else:
                P(n + "_sleeve", cyl(0.065, 0.058, 0.34, 10), "Outfit", pos=(ax, 0.70, 0), parent=g)
                P(n + "_hand", sphere(0.062, 10, 8), "Skin", pos=(ax, 0.5, 0), parent=g)
                P(n + "_ball", sphere(0.068, 10, 8), "Outfit", pos=(ax, 0.87, 0), parent=g)

    # ── Baş
    P("head", sphere(0.25, 24, 16), "Skin", pos=H(0, 0, 0), scale=(1, 0.96, 1), parent=head)
    for s in (-1, 1):
        P(f"ear{s}", sphere(0.05, 8, 6), "Skin", pos=H(s * 0.245, -0.01, 0), scale=(0.5, 1, 1), parent=head)
        P(f"eye{s}", sphere(0.036, 10, 8), "Dark", pos=H(s * 0.088, 0.01, 0.222), scale=(1, 1, 0.55), parent=head)
        P(f"shine{s}", sphere(0.012, 6, 5), "White", pos=H(s * 0.088 + 0.012, 0.028, 0.244), parent=head)
        P(f"brow{s}", box(0.07, 0.014, 0.014), "Hair", pos=H(s * 0.088, 0.078, 0.232), rot=(0, 0, s * -0.12), parent=head, smooth=False)
        P(f"cheek{s}", sphere(0.038, 8, 6), "Blush", pos=H(s * 0.15, -0.06, 0.195), scale=(1, 1, 0.4), parent=head)
    P("nose", sphere(0.024, 8, 6), "SkinDark", pos=H(0, -0.025, 0.243), scale=(1, 1, 0.7), parent=head)
    P("mouth", arc(0.045, 0.008, PI, 14, 6), "Mouth", pos=H(0, -0.055, 0.232), rot=(0, 0, PI), parent=head)

    # ── Saç (kubbe ortak; stil parçaları gruplarda)
    P("hair_dome", sphere(0.268, 20, 12, PI * 0.56), "Hair", pos=H(0, 0.02, -0.012), parent=head, open_=True)
    g = E("hair_short", (0, 0, 0), head)
    P("hs_fringe", box(0.34, 0.06, 0.04), "Hair", pos=H(0, 0.17, 0.21), parent=g)
    for s in (-1, 1):
        P(f"hs_side{s}", box(0.045, 0.14, 0.1), "Hair", pos=H(s * 0.245, 0.02, -0.02), parent=g)
    g = E("hair_long", (0, 0, 0), head)
    P("hl_back", box(0.5, 0.56, 0.1), "Hair", pos=H(0, -0.18, -0.2), parent=g, round_=True)
    for s in (-1, 1):
        P(f"hl_side{s}", box(0.06, 0.4, 0.14), "Hair", pos=H(s * 0.24, -0.12, -0.06), parent=g, round_=True)
    P("hl_fringe", box(0.34, 0.05, 0.04), "Hair", pos=H(0, 0.17, 0.21), parent=g)
    g = E("hair_bun", (0, 0, 0), head)
    P("hb_bun", sphere(0.115, 14, 10), "Hair", pos=H(0, 0.3, -0.06), parent=g)
    P("hb_tie", cyl(0.06, 0.06, 0.04, 10), "Pink", pos=H(0, 0.235, -0.045), parent=g)
    P("hb_fringe", box(0.3, 0.05, 0.04), "Hair", pos=H(0, 0.17, 0.21), parent=g)
    g = E("hair_spiky", (0, 0, 0), head)
    for i in range(8):
        a = i / 8 * 2 * PI
        P(f"hp_spike{i}", cyl(0.0, 0.06, 0.2, 8), "Hair", pos=H(math.cos(a) * 0.17, 0.24, math.sin(a) * 0.17),
          rot=(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), parent=g)
    P("hp_top", cyl(0.0, 0.07, 0.24, 8), "Hair", pos=H(0, 0.3, 0), parent=g)
    g = E("hair_curly", (0, 0, 0), head)
    for i in range(10):
        a = i / 10 * 2 * PI
        P(f"hc_curl{i}", sphere(0.085, 10, 8), "Hair", pos=H(math.cos(a) * 0.22, 0.1 + (0.02 if i % 2 == 0 else 0), math.sin(a) * 0.2 - 0.02), parent=g)
    for i in range(4):
        a = i / 4 * 2 * PI + 0.4
        P(f"hc_top{i}", sphere(0.09, 10, 8), "Hair", pos=H(math.cos(a) * 0.1, 0.25, math.sin(a) * 0.1), parent=g)

    # ── Şapkalar
    g = E("hat_cap", (0, 0, 0), head)
    P("hc_dome", sphere(0.28, 20, 10, PI * 0.5), "CapRed", pos=H(0, 0.05, 0), parent=g, open_=True)
    P("hc_brim", box(0.3, 0.025, 0.19), "CapRedDark", pos=H(0, 0.075, 0.27), rot=(0.15, 0, 0), parent=g, round_=True)
    P("hc_button", sphere(0.03, 8, 6), "White", pos=H(0, 0.3, 0), parent=g)
    g = E("hat_party", (0, 0, 0), head)
    P("hp_cone", cyl(0.0, 0.17, 0.4, 16), "Party", pos=H(0, 0.42, 0), rot=(0, 0, 0.08), parent=g)
    for i in range(3):
        P(f"hp_band{i}", cyl(0.15 - i * 0.04, 0.155 - i * 0.04, 0.03, 16), "Yellow", pos=H(0, 0.3 + i * 0.1, 0), parent=g)
    P("hp_pom", sphere(0.05, 8, 6), "Pink", pos=H(0.03, 0.63, 0), parent=g)
    g = E("hat_cowboy", (0, 0, 0), head)
    P("hw_brim", cyl(0.42, 0.42, 0.025, 28), "BrownLight", pos=H(0, 0.19, 0), parent=g)
    P("hw_crown", cyl(0.2, 0.235, 0.2, 22), "Brown", pos=H(0, 0.3, 0), parent=g)
    P("hw_band", cyl(0.238, 0.238, 0.04, 22), "BrownDark", pos=H(0, 0.23, 0), parent=g)
    g = E("hat_crown", (0, 0, 0), head)
    P("hk_ring", cyl(0.21, 0.23, 0.12, 22), "Gold", pos=H(0, 0.29, 0), parent=g, open_=True)
    for i in range(5):
        a = i / 5 * 2 * PI
        P(f"hk_tip{i}", cyl(0.0, 0.045, 0.13, 8), "Gold", pos=H(math.cos(a) * 0.19, 0.4, math.sin(a) * 0.19), parent=g)
        P(f"hk_gem{i}", sphere(0.022, 6, 5), "Red" if i % 2 == 0 else "Blue", pos=H(math.cos(a) * 0.19, 0.47, math.sin(a) * 0.19), parent=g)

    # ── Aksesuarlar
    g = E("acc_glasses", (0, 0, 0), head)
    for s in (-1, 1):
        P(f"ag_ring{s}", arc(0.068, 0.011, 2 * PI, 18, 6), "GlassDark", pos=H(s * 0.09, 0.012, 0.238), parent=g)
        P(f"ag_temple{s}", box(0.012, 0.012, 0.2), "GlassDark", pos=H(s * 0.158, 0.012, 0.14), parent=g, smooth=False)
    P("ag_bridge", box(0.05, 0.012, 0.012), "GlassDark", pos=H(0, 0.02, 0.24), parent=g, smooth=False)
    g = E("acc_headphones", (0, 0, 0), head)
    P("ah_band", arc(0.27, 0.02, PI, 24, 8), "Headphone", pos=H(0, 0.02, 0), parent=g)
    for s in (-1, 1):
        P(f"ah_cup{s}", cyl(0.085, 0.085, 0.07, 16), "Red", pos=H(s * 0.27, 0, 0), rot=(0, 0, PI / 2), parent=g)
        P(f"ah_pad{s}", cyl(0.06, 0.06, 0.075, 16), "Headphone", pos=H(s * 0.275, 0, 0), rot=(0, 0, PI / 2), parent=g)
    g = E("acc_necklace@body", (0, 0, 0), body)
    P("an_chain", arc(0.115, 0.011, 2 * PI, 20, 6), "Gold", pos=(0, 0.905, 0.02), rot=(PI / 2 + 0.5, 0, 0), parent=g)
    P("an_gem", sphere(0.03, 8, 6), "Purple", pos=(0, 0.8, 0.13), parent=g)
    g = E("acc_wings@body", (0, 0, 0), body)
    for s in (-1, 1):
        w = E("WingL" if s < 0 else "WingR", (s * 0.12, 0.85, -0.2), g)
        P(f"aw_a{s}", sphere(1, 14, 10), "White", pos=(s * 0.29, 0.9, -0.2), rot=(0, 0, s * -0.5), scale=(0.04, 0.32, 0.17), parent=w)
        P(f"aw_b{s}", sphere(1, 14, 10), "WingBlue", pos=(s * 0.39, 0.79, -0.2), rot=(0, 0, s * -0.9), scale=(0.035, 0.22, 0.13), parent=w)

    # ── Astronot başı (kask + yaka)
    g = E("outfit_space@head", (0, 0, 0), head)
    P("os_helmet", sphere(0.36, 22, 14), "Helmet", pos=H(0, 0.02, 0), parent=g)
    P("os_collar", cyl(0.2, 0.22, 0.05, 18), "White", pos=H(0, -0.27, 0), parent=g)
    return created


# ── Önizleme ve dışa aktarma ───────────────────────────────────────────────
def _variant_base(name):
    return name.split(".")[0].split("@")[0]


def preview(hair="hair_short", outfit="outfit_tee", hat="hat_none", acc="acc_none"):
    chosen = {hair, outfit, hat, acc}
    for o in bpy.data.objects:
        if not o.get("_char"):
            continue
        base = _variant_base(o.name)
        if base.startswith(("hair_", "outfit_", "hat_", "acc_")) and o.type == "EMPTY":
            on = base in chosen
            for c in [o] + list(o.children_recursive):
                c.hide_set(not on)
                c.hide_viewport = not on
        # sahnedeki tüm gizli olmayanlar kalsın


def show_all():
    for o in bpy.data.objects:
        if o.get("_char"):
            o.hide_set(False)
            o.hide_viewport = False
            o.hide_render = False


def look(front=True):
    from mathutils import Euler
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                sp = area.spaces.active
                sp.shading.type = "MATERIAL"
                r3d = sp.region_3d
                r3d.view_perspective = "PERSP"
                r3d.view_location = Vector((0, 0, 0.68))
                r3d.view_distance = 3.6
                r3d.view_rotation = Euler((math.radians(84), 0, math.radians(20 if front else 200)), "XYZ").to_quaternion()
                area.tag_redraw()
