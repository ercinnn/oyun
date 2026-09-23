"""Renkli Kasaba — oda mobilyası üreticisi (Blender 5.2, Blender MCP ile).

Odadaki 9 mobilyayı tek bir `assets/models/furniture.glb`'ye üretir; karakterde
olduğu gibi **tüm parçalar aynı dosyada** isimli gruplar olarak durur
(`furn_bed`, `furn_sofa`, …) ve oyun tarafı (`lib/widgets/furniture_model.dart`)
yalnızca gereken grubu kopyalar.

Kimlikler `lib/models/town/shop_catalog.dart` ile **birebir aynı** olmalıdır;
ayak izi (kare) ve yükseklik de oradaki `width`/`depth`/`height` ile uyuşmalı,
yoksa oda çarpışma denetimi ile görüntü birbirini tutmaz.

Koordinatlar (bina üreticisiyle aynı sözleşme): ayak izi x∈[0,W], y∈[-D,0],
z yukarı ve 0'dan başlar. glTF dışa aktarımı Blender Z-up'ı Y-up'a çevirir, yani
Blender `y = -three_z`: **ön yüz y = -D tarafıdır** (kameranın baktığı yön).

Kullanım (Blender MCP içinden):
    exec(open(r"...\\tool\\blender\\build_furniture.py").read())
    build_all()                 # hepsini kur
    show_only("furn_sofa")      # tek parçayı incele
    frame_view(2, 1)
    show_all()                  # dışa aktarmadan önce ŞART (gizli nesne aktarılmaz)
    # sonra: export_scene(object_names=[...roots()...], apply_modifiers=True)
"""

import bpy
import bmesh
import math

coll = bpy.context.scene.collection


# ─────────────────────────── Malzeme / ilkel şekiller ───────────────────────────


def _set(bsdf, names, value):
    for n in names:
        if n in bsdf.inputs:
            bsdf.inputs[n].default_value = value
            return True
    return False


def mat(name, hexcolor, rough=0.8, emit=0.0, metal=0.0, alpha=1.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = ((hexcolor >> 16) & 255) / 255, ((hexcolor >> 8) & 255) / 255, (hexcolor & 255) / 255, 1
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough
    if "Metallic" in b.inputs:
        b.inputs["Metallic"].default_value = metal
    if emit > 0:
        _set(b, ["Emission Color", "Emission"], c)
        _set(b, ["Emission Strength"], emit)
    if alpha < 1.0:
        _set(b, ["Alpha"], alpha)
        # Karıştırma yöntemi Blender sürümleri arasında ad değiştirdi
        # (`blend_method` → `surface_render_method`); glTF dışa aktarıcı
        # alphaMode'u buna bakarak yazdığı için hangisi varsa o kurulur.
        for attr, value in (("surface_render_method", "BLENDED"),
                            ("blend_method", "BLEND")):
            if hasattr(m, attr):
                try:
                    setattr(m, attr, value)
                except TypeError:
                    pass
    return m


_current_parent = None


def _finish(me, name, m):
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(m)
    coll.objects.link(ob)
    if _current_parent is not None:
        ob.parent = _current_parent
    return ob


def box(name, x0, y0, z0, x1, y1, z1, m):
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(v, [], f)
    me.update()
    return _finish(me, name, m)


def poly(name, verts, faces, m):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    return _finish(me, name, m)


def frustum(name, cx, cy, z0, z1, r0, r1, m, n=20):
    """z0'da r0, z1'de r1 yarıçaplı kapalı koni gövdesi (silindir: r0 == r1)."""
    bottom = [(cx + r0 * math.cos(2 * math.pi * i / n), cy + r0 * math.sin(2 * math.pi * i / n), z0)
              for i in range(n)]
    top = [(cx + r1 * math.cos(2 * math.pi * i / n), cy + r1 * math.sin(2 * math.pi * i / n), z1)
           for i in range(n)]
    verts = bottom + top + [(cx, cy, z0), (cx, cy, z1)]
    cb, ct = 2 * n, 2 * n + 1
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))       # yan
        faces.append((cb, j, i))                 # alt kapak
        faces.append((ct, n + i, n + j))         # üst kapak
    return poly(name, verts, faces, m)


def sphere(name, cx, cy, cz, r, m, rings=8, segs=12, sx=1.0, sy=1.0, sz=1.0):
    """Eksenlerde ölçeklenebilir UV küre (sx/sy/sz ile elipsoit)."""
    verts = [(cx, cy, cz + r * sz)]
    for i in range(1, rings):
        phi = math.pi * i / rings
        for j in range(segs):
            th = 2 * math.pi * j / segs
            verts.append((
                cx + r * sx * math.sin(phi) * math.cos(th),
                cy + r * sy * math.sin(phi) * math.sin(th),
                cz + r * sz * math.cos(phi),
            ))
    verts.append((cx, cy, cz - r * sz))
    last = len(verts) - 1
    faces = []
    for j in range(segs):
        faces.append((0, 1 + (j + 1) % segs, 1 + j))
    for i in range(rings - 2):
        a = 1 + i * segs
        b = 1 + (i + 1) * segs
        for j in range(segs):
            k = (j + 1) % segs
            faces.append((a + j, a + k, b + k, b + j))
    a = 1 + (rings - 2) * segs
    for j in range(segs):
        faces.append((last, a + j, a + (j + 1) % segs))
    return poly(name, verts, faces, m)


def leaf(name, cx, cy, cz, length, width, tilt, yaw, m):
    """Dibinden eğik, uzun bir yaprak (elipsoit).

    Şekil orijinde, tabanı z = 0 olacak biçimde kurulur; eğim ve yön **nesne
    dönüşüyle** verilir, böylece dönüş yaprağın sapa bağlandığı noktadan olur
    (şekli doğrudan döndürmek gövdeyi de kaydırırdı)."""
    ob = sphere(name, 0, 0, length / 2, 1.0, m, rings=6, segs=8,
                sx=width, sy=width * 0.42, sz=length / 2)
    ob.location = (cx, cy, cz)
    ob.rotation_euler = (0.0, tilt, yaw)
    return ob


# ─────────────────────────── Parça yönetimi ───────────────────────────

# Kimlik → (kare genişliği, kare derinliği); shop_catalog.dart ile aynı olmalı.
FOOTPRINTS = {
    "furn_bed": (2, 1),
    "furn_rug": (2, 2),
    "furn_lamp": (1, 1),
    "furn_sofa": (2, 1),
    "furn_table": (2, 1),
    "furn_plant": (1, 1),
    "furn_tv": (1, 1),
    "furn_books": (1, 1),
    "furn_aquarium": (1, 1),
}


def clear(prefix):
    for o in [o for o in bpy.data.objects
              if o.name == prefix or o.name.startswith(prefix + "_")]:
        bpy.data.objects.remove(o, do_unlink=True)


def _begin(prefix):
    """Parçanın kök boş nesnesini (Empty) kurar; sonraki şekiller ona bağlanır."""
    global _current_parent
    clear(prefix)
    root = bpy.data.objects.new(prefix, None)
    root.empty_display_size = 0.2
    coll.objects.link(root)
    _current_parent = root
    return root


def _end():
    global _current_parent
    _current_parent = None


def roots():
    """Dışa aktarılacak kök nesnelerin adları."""
    return [p for p in FOOTPRINTS if bpy.data.objects.get(p)]


# ─────────────────────────── Mobilyalar ───────────────────────────


def build_bed():
    _begin("furn_bed")
    wood = mat("Furn_BedWood", 0x8D6E63)
    dark = mat("Furn_BedWoodDark", 0x6D4C41)
    sheet = mat("Furn_BedSheet", 0xFAFAFA, rough=0.9)
    quilt = mat("Furn_BedQuilt", 0x5C6BC0, rough=0.9)
    quilt2 = mat("Furn_BedQuiltTrim", 0x7986CB, rough=0.9)
    # Yastık çarşafla aynı beyaz olunca hiç seçilmiyordu: belirgin biçimde
    # farklı (açık lila) ve daha kalın.
    pillowM = mat("Furn_BedPillow", 0xC5CAE9, rough=0.95)
    # Ayaklar.
    for i, (x, y) in enumerate([(0.06, -0.94), (1.86, -0.94), (0.06, -0.14), (1.86, -0.14)]):
        box(f"furn_bed_Leg{i}", x, y, 0, x + 0.08, y + 0.08, 0.14, dark)
    # Karyola ve şilte.
    box("furn_bed_Frame", 0.03, -0.97, 0.12, 1.97, -0.03, 0.28, wood)
    box("furn_bed_Mattress", 0.07, -0.93, 0.28, 1.93, -0.07, 0.42, sheet)
    # Yorgan (ayak ucundan başlar) ve kıvrımı.
    box("furn_bed_Quilt", 0.07, -0.93, 0.41, 1.34, -0.07, 0.49, quilt)
    box("furn_bed_QuiltFold", 1.34, -0.93, 0.41, 1.46, -0.07, 0.52, quilt2)
    # Yastık (baş ucu x = 2 tarafı).
    sphere("furn_bed_Pillow", 1.66, -0.50, 0.47, 0.20, pillowM, sx=0.9, sy=1.7, sz=0.62)
    # Başlık ve ayak tahtası.
    box("furn_bed_Head", 1.90, -0.97, 0.12, 1.99, -0.03, 0.56, wood)
    box("furn_bed_HeadTop", 1.88, -0.99, 0.52, 2.01, -0.01, 0.58, dark)
    box("furn_bed_Foot", 0.01, -0.97, 0.12, 0.10, -0.03, 0.34, wood)
    _end()


def build_rug():
    _begin("furn_rug")
    base = mat("Furn_RugBase", 0xE57373, rough=0.95)
    inner = mat("Furn_RugInner", 0xFFCDD2, rough=0.95)
    core = mat("Furn_RugCore", 0xEF9A9A, rough=0.95)
    fringe = mat("Furn_RugFringe", 0xFFEBEE, rough=0.95)
    box("furn_rug_Base", 0.03, -1.97, 0.004, 1.97, -0.03, 0.022, base)
    box("furn_rug_Inner", 0.20, -1.80, 0.022, 1.80, -0.20, 0.028, inner)
    box("furn_rug_Core", 0.45, -1.55, 0.028, 1.55, -0.45, 0.034, core)
    # Saçaklar (iki kenarda).
    for i in range(12):
        x = 0.12 + i * 0.155
        box(f"furn_rug_FrA{i}", x, -1.99, 0.004, x + 0.09, -1.95, 0.016, fringe)
        box(f"furn_rug_FrB{i}", x, -0.05, 0.004, x + 0.09, -0.01, 0.016, fringe)
    _end()


def build_lamp():
    _begin("furn_lamp")
    metal = mat("Furn_LampMetal", 0x455A64, rough=0.4, metal=0.6)
    # Yayılım bilerek **düşük**: 1,6'da abajur bembeyaz yanıyor ve biçimi
    # (hatta beyaz zeminde kendisi) kayboluyordu.
    shade = mat("Furn_LampShade", 0xFFE082, rough=0.6, emit=0.35)
    bulb = mat("Furn_LampBulb", 0xFFFDE7, emit=0.9)
    frustum("furn_lamp_Base", 0.5, -0.5, 0.0, 0.05, 0.24, 0.20, metal)
    frustum("furn_lamp_BaseTop", 0.5, -0.5, 0.05, 0.09, 0.14, 0.09, metal)
    frustum("furn_lamp_Pole", 0.5, -0.5, 0.09, 0.84, 0.028, 0.028, metal, n=10)
    sphere("furn_lamp_Bulb", 0.5, -0.5, 0.95, 0.07, bulb, rings=6, segs=10)
    # Abajur: altta geniş, üstte dar.
    frustum("furn_lamp_Shade", 0.5, -0.5, 0.84, 1.16, 0.30, 0.19, shade)
    _end()


def build_sofa():
    _begin("furn_sofa")
    body = mat("Furn_SofaBody", 0x26A69A, rough=0.9)
    cushion = mat("Furn_SofaCushion", 0x4DB6AC, rough=0.9)
    dark = mat("Furn_SofaDark", 0x00897B, rough=0.9)
    leg = mat("Furn_SofaLeg", 0x5D4037)
    for i, (x, y) in enumerate([(0.10, -0.86), (1.83, -0.86), (0.10, -0.17), (1.83, -0.17)]):
        box(f"furn_sofa_Leg{i}", x, y, 0, x + 0.07, y + 0.07, 0.10, leg)
    # Oturak tabanı, sırtlık (arka = y ≈ 0) ve kolluklar.
    box("furn_sofa_Base", 0.05, -0.92, 0.10, 1.95, -0.06, 0.32, body)
    box("furn_sofa_Back", 0.05, -0.22, 0.10, 1.95, -0.06, 0.64, body)
    box("furn_sofa_BackTop", 0.03, -0.24, 0.60, 1.97, -0.04, 0.66, dark)
    box("furn_sofa_ArmL", 0.05, -0.92, 0.10, 0.26, -0.06, 0.46, body)
    box("furn_sofa_ArmR", 1.74, -0.92, 0.10, 1.95, -0.06, 0.46, body)
    box("furn_sofa_ArmTopL", 0.03, -0.94, 0.42, 0.28, -0.04, 0.48, dark)
    box("furn_sofa_ArmTopR", 1.72, -0.94, 0.42, 1.97, -0.04, 0.48, dark)
    # Minderler: iki oturma, iki sırt.
    for i, (x0, x1) in enumerate([(0.29, 0.98), (1.02, 1.71)]):
        box(f"furn_sofa_Seat{i}", x0, -0.88, 0.32, x1, -0.24, 0.43, cushion)
        # Sırtlığın **önüne**: içine yazılırsa sırtlık gövdesinde kaybolur.
        box(f"furn_sofa_BackCushion{i}", x0, -0.44, 0.30, x1, -0.26, 0.58, cushion)
    _end()


def build_table():
    _begin("furn_table")
    top = mat("Furn_TableTop", 0x8D6E63, rough=0.55)
    apron = mat("Furn_TableApron", 0x6D4C41)
    bowl = mat("Furn_TableBowl", 0xECEFF1, rough=0.5)
    fruitA = mat("Furn_TableFruitA", 0xE53935)
    fruitB = mat("Furn_TableFruitB", 0xFDD835)
    for i, (x, y) in enumerate([(0.10, -0.87), (1.81, -0.87), (0.10, -0.22), (1.81, -0.22)]):
        box(f"furn_table_Leg{i}", x, y, 0, x + 0.09, y + 0.09, 0.34, apron)
    box("furn_table_Apron", 0.12, -0.86, 0.30, 1.88, -0.14, 0.40, apron)
    box("furn_table_Top", 0.02, -0.96, 0.40, 1.98, -0.04, 0.48, top)
    # Üstünde meyve kâsesi (parça cansız durmasın).
    frustum("furn_table_Bowl", 1.0, -0.5, 0.48, 0.58, 0.10, 0.17, bowl, n=16)
    sphere("furn_table_FruitA", 0.95, -0.52, 0.575, 0.055, fruitA, rings=6, segs=10)
    sphere("furn_table_FruitB", 1.06, -0.47, 0.575, 0.05, fruitB, rings=6, segs=10)
    _end()


def build_plant():
    _begin("furn_plant")
    pot = mat("Furn_PlantPot", 0xBF5F4A, rough=0.85)
    rim = mat("Furn_PlantRim", 0xA24A38, rough=0.85)
    soil = mat("Furn_PlantSoil", 0x4E342E, rough=1.0)
    stem = mat("Furn_PlantStem", 0x2E7D32)
    leafA = mat("Furn_PlantLeafA", 0x43A047)
    leafB = mat("Furn_PlantLeafB", 0x66BB6A)
    frustum("furn_plant_Pot", 0.5, -0.5, 0.0, 0.30, 0.17, 0.25, pot)
    frustum("furn_plant_Rim", 0.5, -0.5, 0.30, 0.35, 0.27, 0.27, rim)
    frustum("furn_plant_Soil", 0.5, -0.5, 0.31, 0.33, 0.23, 0.23, soil, n=16)
    frustum("furn_plant_Stem", 0.5, -0.5, 0.31, 0.46, 0.035, 0.028, stem, n=8)
    # Saptan dışa açılan 6 uzun yaprak (ilk hâlde üst üste küreler vardı ve
    # bitki dondurma külahına benziyordu). Sabit desen, rastgelelik yok.
    for i in range(6):
        yaw = i * math.pi / 3
        tilt = 0.52 + (i % 2) * 0.26
        length = 0.50 - (i % 3) * 0.05
        leaf(
            f"furn_plant_Leaf{i}",
            0.5, -0.5, 0.42,
            length, 0.085, tilt, yaw,
            leafA if i % 2 == 0 else leafB,
        )
    _end()


def build_tv():
    _begin("furn_tv")
    cab = mat("Furn_TvCabinet", 0x4E342E, rough=0.7)
    cabTop = mat("Furn_TvCabinetTop", 0x6D4C41, rough=0.7)
    knob = mat("Furn_TvKnob", 0xBDBDBD, rough=0.4, metal=0.5)
    bezel = mat("Furn_TvBezel", 0x263238, rough=0.45)
    screen = mat("Furn_TvScreen", 0x4FC3F7, rough=0.2, emit=1.4)
    stand = mat("Furn_TvStand", 0x37474F, rough=0.5, metal=0.3)
    # Sehpa (ön yüz y = -0.7 tarafına bakar).
    box("furn_tv_Cabinet", 0.08, -0.70, 0.02, 0.92, -0.16, 0.30, cab)
    box("furn_tv_CabinetTop", 0.05, -0.73, 0.30, 0.95, -0.13, 0.36, cabTop)
    box("furn_tv_Drawer", 0.14, -0.72, 0.08, 0.86, -0.70, 0.24, cabTop)
    box("furn_tv_Knob", 0.46, -0.75, 0.14, 0.54, -0.71, 0.18, knob)
    # Ayak + ekran paneli.
    box("furn_tv_StandNeck", 0.44, -0.50, 0.36, 0.56, -0.38, 0.46, stand)
    box("furn_tv_StandFoot", 0.30, -0.56, 0.36, 0.70, -0.32, 0.39, stand)
    box("furn_tv_Bezel", 0.06, -0.46, 0.44, 0.94, -0.40, 0.88, bezel)
    box("furn_tv_Screen", 0.09, -0.475, 0.47, 0.91, -0.455, 0.85, screen)
    _end()


def build_books():
    _begin("furn_books")
    frame = mat("Furn_BookFrame", 0xA1887F, rough=0.75)
    backM = mat("Furn_BookBack", 0x8D6E63, rough=0.85)
    shelfM = mat("Furn_BookShelf", 0xBCAAA4, rough=0.75)
    spines = [
        mat("Furn_BookA", 0xE53935),
        mat("Furn_BookB", 0x1E88E5),
        mat("Furn_BookC", 0x43A047),
        mat("Furn_BookD", 0xFDD835),
        mat("Furn_BookE", 0x8E24AA),
        mat("Furn_BookF", 0xFB8C00),
    ]
    # Yan duvarlar, arkalık ve raflar.
    box("furn_books_SideL", 0.08, -0.40, 0.0, 0.15, -0.04, 1.48, frame)
    box("furn_books_SideR", 0.85, -0.40, 0.0, 0.92, -0.04, 1.48, frame)
    box("furn_books_Back", 0.15, -0.09, 0.0, 0.85, -0.04, 1.48, backM)
    box("furn_books_Top", 0.05, -0.43, 1.42, 0.95, -0.01, 1.50, frame)
    levels = [0.05, 0.40, 0.75, 1.10]
    for i, z in enumerate(levels):
        box(f"furn_books_Shelf{i}", 0.15, -0.40, z, 0.85, -0.04, z + 0.045, shelfM)
        # Kitaplar: değişken kalınlık/boy, sabit desen (rastgelelik yok).
        x = 0.18
        k = 0
        while x < 0.80 and k < 7:
            width = 0.055 + ((i * 3 + k) % 3) * 0.022
            height = 0.22 + ((i * 5 + k) % 4) * 0.026
            if x + width > 0.82:
                break
            box(f"furn_books_B{i}_{k}", x, -0.36, z + 0.045, x + width, -0.12,
                z + 0.045 + height, spines[(i * 2 + k) % len(spines)])
            x += width + 0.012
            k += 1
    _end()


def build_aquarium():
    _begin("furn_aquarium")
    cab = mat("Furn_AqCabinet", 0x5D4037, rough=0.75)
    frameM = mat("Furn_AqFrame", 0x37474F, rough=0.5, metal=0.4)
    # Su **saydam**: opak bir gövdeyle çakıl, bitki ve balıklar tamamen
    # kayboluyordu (akvaryumun bütün anlamı içinin görünmesi).
    water = mat("Furn_AqWater", 0x4FC3F7, rough=0.1, alpha=0.3)
    gravel = mat("Furn_AqGravel", 0xA1887F, rough=1.0)
    weed = mat("Furn_AqWeed", 0x2E7D32)
    fishA = mat("Furn_AqFishA", 0xFF7043)
    fishB = mat("Furn_AqFishB", 0xFFD54F)
    lid = mat("Furn_AqLid", 0x263238, rough=0.6)
    box("furn_aquarium_Cabinet", 0.10, -0.66, 0.02, 0.90, -0.14, 0.30, cab)
    box("furn_aquarium_CabinetTop", 0.07, -0.69, 0.30, 0.93, -0.11, 0.35, cab)
    box("furn_aquarium_Gravel", 0.12, -0.64, 0.35, 0.88, -0.16, 0.46, gravel)
    # İçindekiler sudan önce kurulur (dışa aktarım sırası çizim sırasını
    # etkilemez, ama okunurluk için içten dışa yazılıyor).
    frustum("furn_aquarium_WeedA", 0.28, -0.30, 0.44, 0.70, 0.04, 0.015, weed, n=8)
    frustum("furn_aquarium_WeedB", 0.70, -0.52, 0.44, 0.62, 0.032, 0.012, weed, n=8)
    frustum("furn_aquarium_WeedC", 0.44, -0.55, 0.44, 0.58, 0.03, 0.012, weed, n=8)
    sphere("furn_aquarium_FishA", 0.38, -0.44, 0.61, 0.095, fishA, rings=6, segs=10, sx=1.5, sz=0.7)
    sphere("furn_aquarium_FishB", 0.66, -0.26, 0.51, 0.072, fishB, rings=6, segs=10, sx=1.5, sz=0.7)
    box("furn_aquarium_Water", 0.12, -0.64, 0.46, 0.88, -0.16, 0.74, water)
    # Cam çerçevesi: dört dikey direk + üst kapak.
    for i, (x, y) in enumerate([(0.11, -0.65), (0.87, -0.65), (0.11, -0.17), (0.87, -0.17)]):
        box(f"furn_aquarium_Post{i}", x, y, 0.35, x + 0.02, y + 0.02, 0.76, frameM)
    box("furn_aquarium_Lid", 0.09, -0.67, 0.75, 0.91, -0.13, 0.78, lid)
    _end()


BUILDERS = {
    "furn_bed": build_bed,
    "furn_rug": build_rug,
    "furn_lamp": build_lamp,
    "furn_sofa": build_sofa,
    "furn_table": build_table,
    "furn_plant": build_plant,
    "furn_tv": build_tv,
    "furn_books": build_books,
    "furn_aquarium": build_aquarium,
}


def build_all():
    for fn in BUILDERS.values():
        fn()
    return roots()


# ─────────────────────────── Görüntüleme yardımcıları ───────────────────────────


def show_only(prefix):
    """Yalnızca [prefix] parçasını bırak. `hide_render` de kapatılır: sahnede
    hepsi orijinde üst üste durduğu için render'da da gizlenmeleri gerekir
    (`hide_viewport` render'ı etkilemez — bu bir kez atlandı ve tüm parçalar
    aynı karede üst üste çıktı)."""
    for o in bpy.data.objects:
        hide = not (o.name == prefix or o.name.startswith(prefix + "_"))
        # Işık ve kamera her zaman açık kalmalı.
        if o.type in {"LIGHT", "CAMERA"}:
            hide = False
        o.hide_viewport = hide
        o.hide_render = hide
        o.hide_set(hide)


def show_all():
    """Dışa aktarmadan önce ŞART: gizli nesneler GLB'ye girmez."""
    for o in bpy.data.objects:
        o.hide_viewport = False
        o.hide_render = False
        o.hide_set(False)


def select_prefix(prefix):
    for o in bpy.context.view_layer.objects:
        o.select_set((o.name == prefix or o.name.startswith(prefix + "_")) and not o.hide_get())
    return [o.name for o in bpy.context.selected_objects]


def render_thumbs(out_dir, size=256):
    """Her parçayı izometrik açıdan saydam zeminli PNG olarak render eder.

    Market ve envanter listelerinde emoji yerine bunlar gösterilir; oda 3B
    olduğu için önizlemenin de aynı modellerden gelmesi tutarlılığı sağlar
    (liste içinde 9 ayrı WebGL sahnesi açmak yerine hazır resim).
    """
    import os
    from mathutils import Vector

    scene = bpy.context.scene
    r = scene.render
    r.resolution_x = size
    r.resolution_y = size
    r.resolution_percentage = 100
    r.film_transparent = True
    fmt = r.image_settings
    formats = [i.identifier for i in fmt.bl_rna.properties["file_format"].enum_items]
    if "PNG" in formats:
        fmt.file_format = "PNG"
    modes = [i.identifier for i in fmt.bl_rna.properties["color_mode"].enum_items]
    if "RGBA" in modes:
        fmt.color_mode = "RGBA"

    # Renk dönüşümü **Standard**: Blender'ın varsayılan AgX'i renkleri gözle
    # görülür biçimde soluklaştırıyor, oysa oyundaki three_js render'ı ton
    # eşlemesi yapmıyor — önizleme oyunda görünenle aynı renkte olmalı.
    # `view_transform` OCIO ile gelen **dinamik** bir enum: `enum_items` boş
    # döner, bu yüzden "geçerli mi" diye bakılamaz (bkz. `render.engine` için
    # aynı uyarı). Doğrudan atanır, kabul edilmezse olduğu gibi bırakılır.
    vs = scene.view_settings
    try:
        vs.view_transform = "Standard"
    except TypeError:
        pass
    try:
        vs.look = "None"
    except TypeError:
        pass

    # Dünya ışığı (dolgu) — parçanın gölgede kalan yüzleri de okunsun.
    world = scene.world or bpy.data.worlds.new("ThumbWorld")
    scene.world = world
    world.use_nodes = True
    bg = next((n for n in world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg is not None:
        bg.inputs[0].default_value = (1, 1, 1, 1)
        bg.inputs[1].default_value = 0.3

    sun = bpy.data.objects.get("ThumbSun")
    if sun is None:
        data = bpy.data.lights.new("ThumbSunData", type="SUN")
        sun = bpy.data.objects.new("ThumbSun", data)
        coll.objects.link(sun)
    sun.data.energy = 1.7
    sun.location = (4, -5, 6)
    sun.rotation_euler = Vector((math.radians(52), 0, math.radians(38)))

    cam = bpy.data.objects.get("ThumbCam")
    if cam is None:
        data = bpy.data.cameras.new("ThumbCamData")
        cam = bpy.data.objects.new("ThumbCam", data)
        coll.objects.link(cam)
    cam.data.type = "ORTHO"
    scene.camera = cam

    os.makedirs(out_dir, exist_ok=True)
    written = []
    for prefix, (W, D) in FOOTPRINTS.items():
        if bpy.data.objects.get(prefix) is None:
            continue
        # Parçanın gerçek yüksekliği: alt nesnelerin kutu sınırından.
        top = 0.0
        for o in bpy.data.objects:
            if o.name.startswith(prefix + "_") and o.type == "MESH":
                for v in o.bound_box:
                    top = max(top, (o.matrix_world @ Vector(v))[2])
        height = max(top, 0.2)
        show_only(prefix)
        sun.hide_viewport = False
        sun.hide_set(False)
        cam.hide_viewport = False
        cam.hide_set(False)
        target = Vector((W / 2, -D / 2, height / 2))
        # İzometrik yön: sağ-ön-üst. Ortografik ölçek parçayı tam doldurur.
        offset = Vector((1.0, -1.0, 0.85)).normalized() * 10
        cam.location = target + offset
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        cam.data.ortho_scale = max(W, D, height) * 1.45 + 0.25
        path = os.path.join(out_dir, prefix + ".png")
        r.filepath = path
        bpy.ops.render.render(write_still=True)
        written.append(path)
    show_all()
    return written


def frame_view(W=2, D=1, height=0.9):
    from mathutils import Euler, Vector
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                sp = area.spaces.active
                sp.shading.type = "MATERIAL"
                r3d = sp.region_3d
                r3d.view_perspective = "PERSP"
                r3d.view_location = Vector((W / 2, -D / 2, height / 2))
                r3d.view_distance = max(W, D) * 2.6 + 1.2
                r3d.view_rotation = Euler(
                    (math.radians(68), 0, math.radians(30)), "XYZ"
                ).to_quaternion()
                area.tag_redraw()
