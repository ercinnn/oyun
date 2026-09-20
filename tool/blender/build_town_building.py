import bpy, bmesh, math

coll = bpy.context.scene.collection


def _set(bsdf, names, value):
    for n in names:
        if n in bsdf.inputs:
            bsdf.inputs[n].default_value = value
            return True
    return False


def mat(name, hexcolor, rough=0.8, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = ((hexcolor >> 16) & 255) / 255, ((hexcolor >> 8) & 255) / 255, (hexcolor & 255) / 255, 1
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough
    if emit > 0:
        _set(b, ["Emission Color", "Emission"], c)
        _set(b, ["Emission Strength"], emit)
    return m


def clear(prefix):
    for o in [o for o in bpy.data.objects if o.name.startswith(prefix + "_")]:
        bpy.data.objects.remove(o, do_unlink=True)


def _finish(me, name, m):
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(m)
    coll.objects.link(ob)
    return ob


def box(name, x0, y0, z0, x1, y1, z1, m):
    v = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    f = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    me = bpy.data.meshes.new(name); me.from_pydata(v, [], f); me.update()
    return _finish(me, name, m)


def poly(name, verts, faces, m):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    return _finish(me, name, m)


def disc(name, r, y, m, n=20):
    verts = [(0, y, 0)] + [(r*math.cos(2*math.pi*i/n), y, r*math.sin(2*math.pi*i/n)) for i in range(n)]
    faces = [(0, 1+(i+1) % n, 1+i) for i in range(n)]
    return poly(name, verts, faces, m)


def build(prefix, W, D, door_col, pal, kind):
    """W x D kare; ön yüz y=-D (kapı), köşe orijinde. door_col: kapının sütunu."""
    clear(prefix)
    P = prefix
    M = {
        "wall":   mat(P+"_Wall",   pal["wall"]),
        "trim":   mat(P+"_Trim",   pal["trim"]),
        "plinth": mat(P+"_Plinth", 0x90A4AE),
        "roof":   mat(P+"_Roof",   pal["roof"]),
        "edge":   mat(P+"_RoofEdge", pal["edge"]),
        "door":   mat(P+"_Door",   pal.get("door", 0x6D4C41)),
        "glass":  mat(P+"_Glass",  pal.get("glass", 0x81D4FA), rough=0.15,
                      emit=pal.get("glass_emit", 0.0)),
        "aw1":    mat(P+"_AwningA", pal.get("aw1", 0xEC407A)),
        "aw2":    mat(P+"_AwningB", pal.get("aw2", 0xFFFFFF)),
        "sign":   mat(P+"_Sign",   pal.get("sign", 0xFFD54F), emit=pal.get("sign_emit", 0.0)),
        "knob":   mat(P+"_Knob",   0xFFCA28),
    }
    WALL, PL, RH, o = 2.0, 0.14, 0.95, 0.22
    FY = -D
    DX = door_col + 0.5

    box(P+"_Plinth", -0.04, -D-0.04, 0, W+0.04, 0.04, PL, M["plinth"])
    box(P+"_Walls", 0, -D, PL, W, 0, WALL, M["wall"])
    c = 0.09
    for i, (cx, cy) in enumerate([(0, -D), (W-c, -D), (0, -c), (W-c, -c)]):
        box(f"{P}_Corner{i}", cx-0.005, cy-0.005, PL, cx+c+0.005, cy+c+0.005, WALL, M["trim"])
    box(P+"_Cornice", -0.06, -D-0.06, WALL-0.13, W+0.06, 0.06, WALL, M["trim"])

    # --- Çatı
    e = [(-o, -D-o, WALL), (W+o, -D-o, WALL), (W+o, o, WALL), (-o, o, WALL)]
    cx, cy = W/2, -D/2
    if W > D:
        half = (W-D)/2
        r1, r2 = (cx-half, cy, WALL+RH), (cx+half, cy, WALL+RH)
        faces = [(0, 1, 5, 4), (1, 2, 5), (2, 3, 4, 5), (3, 0, 4)]
    elif D > W:
        half = (D-W)/2
        r1, r2 = (cx, cy-half, WALL+RH), (cx, cy+half, WALL+RH)
        faces = [(0, 1, 5), (1, 2, 5, 4), (2, 3, 4), (3, 0, 4, 5)]
        # front(-y) tri, right quad, back tri, left quad (kiriş Y boyunca)
        faces = [(0, 1, 4), (1, 2, 5, 4), (2, 3, 5), (3, 0, 4, 5)]
    else:
        r1 = r2 = (cx, cy, WALL+RH)
        faces = None
    if faces is None:  # piramit
        verts = e + [r1]
        poly(P+"_Roof", verts, [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)], M["roof"])
    else:
        poly(P+"_Roof", e + [r1, r2], faces, M["roof"])
    t = 0.07
    box(P+"_RoofEdgeFront", -o, -D-o, WALL-t, W+o, -D-o+0.06, WALL, M["edge"])
    box(P+"_RoofEdgeBack",  -o, o-0.06, WALL-t, W+o, o, WALL, M["edge"])
    box(P+"_RoofEdgeLeft",  -o, -D-o, WALL-t, -o+0.06, o, WALL, M["edge"])
    box(P+"_RoofEdgeRight", W+o-0.06, -D-o, WALL-t, W+o, o, WALL, M["edge"])

    # --- Kapı
    DW, DH = 0.86, 1.42
    frame_m = M["trim"] if kind != "arcade" else mat(P+"_NeonFrame", 0x00E5FF, emit=6.0)
    box(P+"_DoorFrame", DX-DW/2-0.09, FY-0.05, PL, DX+DW/2+0.09, FY+0.02, PL+DH+0.09, frame_m)
    box(P+"_Door", DX-DW/2, FY-0.09, PL, DX+DW/2, FY-0.02, PL+DH, M["door"])
    box(P+"_DoorPanelA", DX-DW/2+0.1, FY-0.115, PL+0.12, DX+DW/2-0.1, FY-0.09, PL+0.62, M["door"])
    box(P+"_DoorPanelB", DX-DW/2+0.1, FY-0.115, PL+0.76, DX+DW/2-0.1, FY-0.09, PL+DH-0.12, M["door"])
    box(P+"_Knob", DX+DW/2-0.2, FY-0.14, PL+0.7, DX+DW/2-0.13, FY-0.09, PL+0.77, M["knob"])
    box(P+"_Step", DX-0.62, FY-0.3, 0, DX+0.62, FY, 0.07, M["plinth"])

    # --- Pencereler
    ww, wh, z0 = 0.62, 0.78, 0.85
    shutter = mat(P+"_Shutter", 0x2E7D32)
    soil = mat(P+"_Soil", 0x6D4C41)
    red = mat(P+"_FlowerA", 0xFF5252)
    yellow = mat(P+"_FlowerB", 0xFFEB3B)

    def win_front(cx_, n):
        box(n+"_Frame", cx_-ww/2-0.07, FY-0.05, z0-0.07, cx_+ww/2+0.07, FY+0.02, z0+wh+0.07, M["trim"])
        box(n+"_Glass", cx_-ww/2, FY-0.07, z0, cx_+ww/2, FY-0.02, z0+wh, M["glass"])
        box(n+"_BarV", cx_-0.02, FY-0.085, z0, cx_+0.02, FY-0.05, z0+wh, M["trim"])
        box(n+"_BarH", cx_-ww/2, FY-0.085, z0+wh/2-0.02, cx_+ww/2, FY-0.05, z0+wh/2+0.02, M["trim"])
        box(n+"_Sill", cx_-ww/2-0.12, FY-0.14, z0-0.12, cx_+ww/2+0.12, FY, z0-0.05, M["trim"])
        if kind == "home":
            box(n+"_ShL", cx_-ww/2-0.27, FY-0.06, z0-0.07, cx_-ww/2-0.09, FY, z0+wh+0.07, shutter)
            box(n+"_ShR", cx_+ww/2+0.09, FY-0.06, z0-0.07, cx_+ww/2+0.27, FY, z0+wh+0.07, shutter)
            box(n+"_Box", cx_-ww/2-0.02, FY-0.2, z0-0.3, cx_+ww/2+0.02, FY-0.02, z0-0.12, soil)
            for k in range(4):
                fx = cx_-ww/2+0.08+k*(ww-0.16)/3
                box(f"{n}_Fl{k}", fx-0.05, FY-0.17, z0-0.12, fx+0.05, FY-0.07, z0-0.01,
                    red if k % 2 == 0 else yellow)

    def win_side(cy_, n):
        box(n+"_Frame", W-0.02, cy_-ww/2-0.07, z0-0.07, W+0.05, cy_+ww/2+0.07, z0+wh+0.07, M["trim"])
        box(n+"_Glass", W+0.02, cy_-ww/2, z0, W+0.07, cy_+ww/2, z0+wh, M["glass"])
        box(n+"_BarV", W+0.05, cy_-0.02, z0, W+0.085, cy_+0.02, z0+wh, M["trim"])
        box(n+"_BarH", W+0.05, cy_-ww/2, z0+wh/2-0.02, W+0.085, cy_+ww/2, z0+wh/2+0.02, M["trim"])

    for i in range(W):
        if i != door_col:
            win_front(i+0.5, f"{P}_WinF{i}")
    for i in range(D):
        win_side(-(i+0.5), f"{P}_WinS{i}")

    # --- Tür özel parçalar
    def awning(cx_, aw_w, stripes, out=0.55, up=0.42):
        sw = aw_w/stripes
        xs = cx_-aw_w/2
        zt, zb = PL+DH+up, PL+DH+0.06
        for k in range(stripes):
            xa, xb = xs+k*sw, xs+(k+1)*sw
            m_ = M["aw1"] if k % 2 == 0 else M["aw2"]
            poly(f"{P}_Awning{k}", [(xa, FY, zt), (xb, FY, zt), (xb, FY-out, zb), (xa, FY-out, zb)], [(0, 3, 2, 1)], m_)
            box(f"{P}_AwningLip{k}", xa, FY-out-0.03, zb-0.05, xb, FY-out, zb+0.02, m_)

    if kind == "market":
        awning(DX, 2.0, 9, out=0.6)
        # Kasa tezgâhı (cepheye yaslı, kapının solunda ön pencerenin altında).
        crate = mat(P+"_Crate", 0xA1887F)
        fruit_a = mat(P+"_FruitA", 0xE53935)
        fruit_b = mat(P+"_FruitB", 0x7CB342)
        for cx_, fm in [(0.5, fruit_a), (1.5, fruit_b)]:
            if int(cx_) == door_col:
                continue
            box(f"{P}_Crate{int(cx_)}", cx_-0.3, FY-0.36, 0, cx_+0.3, FY-0.06, 0.26, crate)
            for k in range(3):
                bx = cx_-0.18+k*0.18
                box(f"{P}_Fr{int(cx_)}_{k}", bx-0.07, FY-0.3, 0.26, bx+0.07, FY-0.16, 0.4, fm)
    elif kind == "wardrobe":
        awning(DX, 1.5, 7)
    elif kind == "home":
        # Baca.
        brick = mat(P+"_Brick", 0xB0574A)
        cap = mat(P+"_ChimneyCap", 0x6D2F27)
        cx0 = W*0.72
        box(P+"_Chimney", cx0, -D*0.62, WALL+0.3, cx0+0.34, -D*0.62+0.34, WALL+RH+0.55, brick)
        box(P+"_ChimneyCap", cx0-0.04, -D*0.62-0.04, WALL+RH+0.55, cx0+0.38, -D*0.62+0.38, WALL+RH+0.63, cap)
    elif kind == "arcade":
        neon = mat(P+"_Neon", 0x00E5FF, emit=6.0)
        box(P+"_NeonStrip", -0.02, FY-0.07, WALL-0.24, W+0.02, FY-0.03, WALL-0.19, neon)
        bulb_a = mat(P+"_BulbA", 0xFFEB3B, emit=5.0)
        bulb_b = mat(P+"_BulbB", 0xFF4081, emit=5.0)
        n = W*4
        for k in range(n):
            bx = (k+0.5)*W/n
            box(f"{P}_Bulb{k}", bx-0.04, FY-0.09, WALL-0.09, bx+0.04, FY-0.02, WALL-0.02,
                bulb_a if k % 2 == 0 else bulb_b)

    # --- Çatı levhası (eğime paralel)
    if W >= D:
        run = D/2 + o
        mid_y = (-D-o + -D/2)/2
        sx = W/2
    else:
        run = D/2 + o  # ön kenar -> kiriş uç noktası bölgesi
        mid_y = (-D-o + -D/2)/2
        sx = W/2
    theta = math.atan2(RH, run)
    ny, nz = -math.sin(theta), math.cos(theta)
    ring = disc(P+"_Sign", 0.34, 0.0, M["trim"])
    face = disc(P+"_SignFace", 0.27, -0.012, M["sign"])
    face.parent = ring
    ring.location = (sx, mid_y + ny*0.03, WALL + RH/2 + nz*0.03)
    ring.rotation_euler = (-(math.pi/2 - theta), 0, 0)
    return [o_.name for o_ in bpy.data.objects if o_.name.startswith(P+"_")]


def show_only(prefix):
    for o_ in bpy.data.objects:
        if o_.type == "MESH":
            o_.hide_viewport = not o_.name.startswith(prefix + "_")
            o_.hide_set(o_.hide_viewport)


def select_prefix(prefix):
    for o_ in bpy.context.view_layer.objects:
        o_.select_set(o_.name.startswith(prefix + "_") and not o_.hide_get())
    return [o_.name for o_ in bpy.context.selected_objects]


def frame_view(W, D):
    from mathutils import Euler, Vector
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                sp = area.spaces.active
                sp.shading.type = "MATERIAL"
                r3d = sp.region_3d
                r3d.view_perspective = "PERSP"
                r3d.view_location = Vector((W/2, -D/2, 1.2))
                r3d.view_distance = 11
                r3d.view_rotation = Euler((math.radians(68), 0, math.radians(20)), "XYZ").to_quaternion()
                area.tag_redraw()
