"""Bilim İnsanları 3B modelleri için ortak Blender yardımcıları.

`build_archimedes.py` ve `build_newton.py` bunu çalıştırır (her betiğin
başında `exec`). İçerik: malzeme, ilkel şekiller (kutu, döndürme yüzeyi,
küre, halka), grup kökü, toplu göster/gizle ve render önizlemesi.

Tuzaklar (Arşimet'te bulundu): nesnenin `scale`/`rotation_euler`'i grubun
orijinine göre uygulanır; ölçek köşelere işlenir (`sphere(..., sx, sy, sz)`),
döndürülecek parça orijinde kurulup sonra `location` ile taşınır.
"""

import bpy
import bmesh
import math

coll = bpy.context.scene.collection

# ─────────────────────────── Malzeme ───────────────────────────


def mat(name, hexcolor, rough=0.8, metal=0.0, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = (((hexcolor >> 16) & 255) / 255, ((hexcolor >> 8) & 255) / 255,
         (hexcolor & 255) / 255, 1)
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough
    if "Metallic" in b.inputs:
        b.inputs["Metallic"].default_value = metal
    if emit > 0:
        for n in ("Emission Color", "Emission"):
            if n in b.inputs:
                b.inputs[n].default_value = c
                break
        if "Emission Strength" in b.inputs:
            b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = c
    return m


# ─────────────────────────── İlkel şekiller ───────────────────────────

_parent = None


def _finish(me, name, m, smooth=False):
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(m)
    coll.objects.link(ob)
    if _parent is not None:
        ob.parent = _parent
    return ob


def poly(name, verts, faces, m, smooth=False):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    return _finish(me, name, m, smooth)


def box(name, cx, cy, z0, sx, sy, sz, m):
    """Tabanı z0'da, ortası (cx, cy) olan kutu."""
    x0, x1 = cx - sx / 2, cx + sx / 2
    y0, y1 = cy - sy / 2, cy + sy / 2
    z1 = z0 + sz
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5),
         (2, 3, 7, 6), (3, 0, 4, 7)]
    return poly(name, v, f, m)


def lathe(name, profile, m, n=24, cx=0.0, cy=0.0, z=0.0, smooth=True):
    """(yarıçap, yükseklik) profilini z ekseni etrafında döndürür. Profilin
    ilk/son noktası yarıçap 0 ise kapak kendiliğinden kapanır; değilse kapak
    yüzü eklenir."""
    verts, faces = [], []
    rings = len(profile)
    for (r, h) in profile:
        for i in range(n):
            a = 2 * math.pi * i / n
            verts.append((cx + r * math.cos(a), cy + r * math.sin(a), z + h))
    for j in range(rings - 1):
        for i in range(n):
            k = (i + 1) % n
            faces.append((j * n + i, j * n + k, (j + 1) * n + k, (j + 1) * n + i))
    if profile[0][0] > 1e-6:
        faces.append(tuple(reversed(range(n))))
    if profile[-1][0] > 1e-6:
        faces.append(tuple((rings - 1) * n + i for i in range(n)))
    return poly(name, verts, faces, m, smooth)


def cyl(name, cx, cy, z0, r, h, m, n=20, r_top=None):
    rt = r if r_top is None else r_top
    return lathe(name, [(r, 0), (rt, h)], m, n, cx, cy, z0, smooth=False)


def sphere(name, cx, cy, cz, r, m, seg=20, rings=12, sz=1.0, sx=1.0, sy=1.0):
    """Küre/elipsoit. Ölçek **köşelere** işlenir: nesnenin `scale`'i grubun
    orijinine göre uygulandığı için parçayı yerinden kaydırırdı."""
    prof = []
    for j in range(rings + 1):
        t = math.pi * j / rings
        prof.append((max(0.0, r * math.sin(t)), -r * math.cos(t) * sz))
    ob = lathe(name, prof, m, seg, 0, 0, 0)
    for v in ob.data.vertices:
        v.co = (cx + v.co.x * sx, cy + v.co.y * sy, cz + v.co.z)
    return ob


def torus(name, cx, cy, cz, R, r, m, n=28, k=10):
    verts, faces = [], []
    for i in range(n):
        a = 2 * math.pi * i / n
        for j in range(k):
            b = 2 * math.pi * j / k
            rr = R + r * math.cos(b)
            verts.append((cx + rr * math.cos(a), cy + rr * math.sin(a),
                          cz + r * math.sin(b)))
    for i in range(n):
        for j in range(k):
            i2, j2 = (i + 1) % n, (j + 1) % k
            faces.append((i * k + j, i2 * k + j, i2 * k + j2, i * k + j2))
    return poly(name, verts, faces, m, smooth=True)


def group(name):
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_size = 0.3
    coll.objects.link(ob)
    return ob


def begin(name):
    global _parent
    _parent = None
    g = group(name)
    _parent = g
    return g



# ─────────────────────────── Toplu işlemler ───────────────────────────


def clear():
    """Sahnedeki her şeyi siler (önizleme kamerası hariç)."""
    for ob in list(bpy.data.objects):
        if ob.name == "SnapCam":
            continue
        bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)


def roots_with(prefixes):
    return sorted(o.name for o in bpy.data.objects
                  if o.parent is None and o.name.startswith(tuple(prefixes)))


def show_all():
    for ob in bpy.data.objects:
        ob.hide_viewport = False
        ob.hide_render = False
        ob.hide_set(False)


def show_only(prefix):
    for ob in bpy.data.objects:
        top = ob
        while top.parent is not None:
            top = top.parent
        hidden = not top.name.startswith(prefix)
        ob.hide_set(hidden)
        ob.hide_render = hidden


def render_preview(names, path, dist=6.0, az=-0.6, elev=0.45, res=(900, 600)):
    """Verilen kökleri çerçeveleyen bir kamerayla Workbench render'ı alıp
    [path]'e yazar. (MCP'nin görünüm görüntüsü bazı eklenti sürümlerinde eski
    kareyi döndürüyor; render her zaman günceldir.)"""
    from mathutils import Vector
    bpy.context.view_layer.update()  # yeni konumlar matrix_world'e geçsin
    pts = []
    for n in names:
        stack = [bpy.data.objects[n]]
        while stack:
            o = stack.pop()
            stack += list(o.children)
            if o.type == "MESH":
                pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    c = (lo + hi) / 2
    sc = bpy.context.scene
    cam = bpy.data.objects.get("SnapCam")
    if cam is None:
        cam = bpy.data.objects.new("SnapCam", bpy.data.cameras.new("SnapCam"))
        sc.collection.objects.link(cam)
    d = Vector((math.sin(az) * math.cos(elev), -math.cos(az) * math.cos(elev),
                math.sin(elev)))
    cam.location = c + d * dist
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    try:
        sc.render.engine = "BLENDER_WORKBENCH"
    except TypeError as e:
        print(e)
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path
