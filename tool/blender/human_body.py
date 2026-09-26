"""Bilim İnsanları figürleri için ortak, eklemli insan gövdesi.

`lab_helpers.py`'den sonra `exec` edilir (onun `lathe`, `sphere`, `mat`
yardımcılarını kullanır). Her bilim insanının betiği `human(...)` ile gövdeyi
kurar, dönen `info` ile saçını, sakalını, eşyalarını ekler ve en sonda
`join_by_material(kök)` ile parçaları malzeme başına tek örgüde birleştirir
(oyunda çizim çağrısı azalsın diye).

Oranlar stilize ama insan oranıdır (~7,5 baş boy). Gövde parçaları eklem
noktaları arasında konik kapsüllerdir; omuz, dirsek, bilek, kalça, diz ve ayak
bileği gerçek eklem noktalarıdır ve poz bu noktalardan ileri kinematikle
hesaplanır. Eller avuç + dört iki boğumlu parmak + başparmaktır.

Koordinatlar: z yukarı, figür **-y'ye bakar** (three'de +z), ayaklar z = 0.

Poz parametreleri (derece):
- `arm_l` / `arm_r`: dict(abd=yana açma, flex=öne kaldırma, elbow=dirsek
  bükümü, palm="in"|"up"|"down"|"forward"|"back", curl=parmak kıvrımı 0-1)
- `leg_l` / `leg_r`: dict(flex=öne kaldırma, abd=yana açma, knee=diz bükümü,
  turn=ayak ucunun dışa dönüşü)
- `head`: dict(turn=sağa/sola, tilt=öne eğme)
"""

import math

from mathutils import Matrix, Quaternion, Vector

# ─────────────────────────── Temel geometri ───────────────────────────

_Z = Vector((0.0, 0.0, 1.0))


def _transform(ob, rot, offset):
    """Nesnenin köşelerini [rot] (3×3) ile döndürüp [offset] kadar taşır."""
    for v in ob.data.vertices:
        v.co = offset + rot @ Vector(v.co)
    ob.data.update()
    return ob


def _frame_to(direction):
    """z eksenini [direction]'a çeviren dönüş matrisi."""
    return _Z.rotation_difference(direction.normalized()).to_matrix()


def limb(name, a, b, ra, rb, m, n=12, cap=3):
    """[a]'dan [b]'ye konik kapsül (uçları yarım küre): kol, bacak, parmak."""
    a, b = Vector(a), Vector(b)
    d = b - a
    L = d.length
    prof = []
    for i in range(cap + 1):
        t = -math.pi / 2 + (math.pi / 2) * i / cap
        prof.append((max(0.0, ra * math.cos(t)), ra * math.sin(t)))
    for i in range(cap + 1):
        t = (math.pi / 2) * i / cap
        prof.append((max(0.0, rb * math.cos(t)), L + rb * math.sin(t)))
    ob = lathe(name, prof, m, n)
    return _transform(ob, _frame_to(d if L > 1e-9 else _Z), a)


def blob(name, c, axes, radii, m, seg=16, rings=10):
    """Eksenleri [axes] = (x, y, z birim vektörleri) olan elipsoit: avuç, ayak,
    yüz parçaları. [radii] her eksen boyunca yarıçap."""
    ob = sphere(name, 0, 0, 0, 1.0, m, seg, rings)
    rot = Matrix((axes[0], axes[1], axes[2])).transposed()
    scale = Matrix.Diagonal(Vector(radii))
    return _transform(ob, rot @ scale, Vector(c))


def _ortho(v, d):
    """[v]'nin [d]'ye dik bileşeni (birim); dejenere ise None."""
    w = v - d * v.dot(d)
    return w.normalized() if w.length > 1e-6 else None


def _rotate(v, axis, deg):
    if axis.length < 1e-9 or abs(deg) < 1e-9:
        return v.copy()
    return Quaternion(axis.normalized(), math.radians(deg)) @ v


# ─────────────────────────── Ortak malzemeler ───────────────────────────


def _face_mats(prefix):
    return dict(
        white=mat(f"{prefix}_eye_white", 0xF5F2EC, 0.35),
        iris=mat(f"{prefix}_iris", 0x3E2A1E, 0.3),
        lip=mat(f"{prefix}_lip", 0xB5655A, 0.6),
    )


# ─────────────────────────── Uzuvlar ───────────────────────────


def _arm_points(side, sh, u, pose):
    """Omuz [sh]'den dirsek, bilek ve el çerçevesini hesaplar."""
    abd = pose.get("abd", 8)
    flex = pose.get("flex", 0)
    elbow = pose.get("elbow", 12)
    q_abd = Quaternion(Vector((0, 1, 0)), math.radians(-side * abd))
    q_flex = Quaternion(Vector((1, 0, 0)), math.radians(-flex))
    q = q_flex @ q_abd
    up = q @ Vector((0, 0, -1))  # üst kol yönü
    bend = q @ Vector((0, -1, 0))  # kolun "önü": dirsek o yana kıvrılır
    fore = _rotate(up, up.cross(bend), elbow)
    upper_len, fore_len = 1.32 * u, 1.12 * u
    el = sh + up * upper_len
    wr = el + fore * fore_len
    palm = {
        "in": Vector((-side, 0, 0)),
        "up": Vector((0, 0, 1)),
        "down": Vector((0, 0, -1)),
        "forward": Vector((0, -1, 0)),
        "back": Vector((0, 1, 0)),
    }[pose.get("palm", "in")]
    n = _ortho(palm, fore) or _ortho(Vector((-side, 0, 0)), fore) or Vector((0, 1, 0))
    w = fore.cross(n).normalized()
    return el, wr, fore, n, w


def _hand(prefix, side, wr, d, n, w, u, m, curl, thumb_m=None):
    """Bilekte avuç + 4 parmak (2 boğum) + başparmak. [d] parmak yönü,
    [n] avuç içinin baktığı yön, [w] boğumlar boyunca yön."""
    palm_len, palm_w, palm_t = 0.4 * u, 0.19 * u, 0.08 * u
    pc = wr + d * (palm_len * 0.55)
    blob(f"{prefix}_palm", pc, (w, n, d), (palm_w, palm_t, palm_len * 0.6), m, 12, 8)
    knuckle = pc + d * (palm_len * 0.5)
    fr = 0.042 * u
    lengths = (0.2, 0.23, 0.22, 0.17)
    for i, k in enumerate((-0.72, -0.24, 0.24, 0.72)):
        # Başparmak -side·w tarafında: serçe parmak onun tersinde.
        base = knuckle + w * (k * palm_w * 0.85) - n * (0.01 * u)
        seg = lengths[i if side > 0 else 3 - i] * u
        # Kıvrım: parmak yönü avuç içine doğru döner (eksen d × n).
        d1 = _rotate(d, d.cross(n), 35 * curl)
        p1 = base + d1 * seg * 0.55
        d2 = _rotate(d1, d1.cross(n), 55 * curl)
        p2 = p1 + d2 * seg * 0.45
        limb(f"{prefix}_f{i}a", base, p1, fr, fr * 0.92, m, 6, 2)
        limb(f"{prefix}_f{i}b", p1, p2, fr * 0.92, fr * 0.8, m, 6, 2)
    tside = -side
    tb = wr + d * (palm_len * 0.35) + w * (tside * palm_w * 0.8)
    td = (d * 0.72 + w * (tside * 0.32) + n * 0.36).normalized()
    t1 = tb + td * 0.14 * u
    td2 = (td + n * (0.6 * curl)).normalized()
    t2 = t1 + td2 * 0.12 * u
    limb(f"{prefix}_th_a", tb, t1, fr * 1.15, fr, m, 6, 2)
    limb(f"{prefix}_th_b", t1, t2, fr, fr * 0.85, m, 6, 2)
    # Tutma noktası: avucun önünde (eşya buraya konur).
    return pc + n * (0.16 * u) + d * (0.05 * u)


def _leg_points(side, hip, u, pose):
    flex = pose.get("flex", 0)
    abd = pose.get("abd", 3)
    knee = pose.get("knee", 4)
    q = Quaternion(Vector((1, 0, 0)), math.radians(-flex)) @ Quaternion(
        Vector((0, 1, 0)), math.radians(-side * abd))
    th = q @ Vector((0, 0, -1))
    back = q @ Vector((0, 1, 0))
    sh = _rotate(th, th.cross(back), knee)
    kn = hip + th * (1.84 * u)
    an = kn + sh * (1.8 * u)
    return kn, an, sh


# ─────────────────────────── İnsan ───────────────────────────


def human(prefix, *, height=1.75, build=1.0, female=False, skin, top,
          sleeve=None, pants, shoe, shin=None, coat=None, skirt=None,
          collar=None, cuff=None, belt=None, arm_l=None, arm_r=None,
          leg_l=None, leg_r=None, head=None, brow=None, nose_scale=1.0,
          head_scale=1.1):
    """Eklemli bir insan gövdesi kurar (yüzü -y). Malzemeler `mat` nesneleri:
    [top] gövde/ceket, [sleeve] kollar (varsayılan [top]), [pants] uyluk,
    [shin] baldır (varsayılan [pants]; Newton'un çorapları için), [shoe].
    [coat] = dict(m, bottom=z, flare=çarpan, open=ön şerit malzemesi|None):
    göğüsten aşağı inen etek/cüppe/önlük. [skirt] = dict(m, bottom, flare):
    belden aşağı etek. [collar]/[cuff] boyun ve bilek halkalarının malzemesi.

    Dönüş: `info` sözlüğü — `head_c` (baş merkezi), `head_r`, `u` (baş birimi),
    `attach_head(ob)` (baş-yerel koordinatta kurulmuş nesneyi başın dönüşüyle
    yerine taşır), `grip_l/grip_r` (avucun önündeki tutma noktası),
    `hand_frame_l/r` = (bilek, parmak yönü, avuç yönü, boğum yönü),
    `neck_front`, `chest_front_y`, `shoulder_z`, `waist_z`, `hip_z`."""
    H = height
    u = H / 7.5
    k = build
    sleeve = sleeve or top
    shin = shin or pants
    fm = _face_mats(prefix)
    arm_l = arm_l or {}
    arm_r = arm_r or {}
    leg_l = leg_l or {}
    leg_r = leg_r or {}
    head = head or {}

    # ── Bacaklar önce: bükülen diz ayak bileğini yükseltir; tüm figür, en alçak
    # ayak bileği yerde olacak şekilde aşağı kaydırılır.
    hip_z = 3.96 * u
    hip_x = (0.4 if female else 0.36) * u * k
    legs = {}
    for side, pose in ((-1, leg_l), (1, leg_r)):
        hip = Vector((side * hip_x, 0.0, hip_z))
        kn, an, sh = _leg_points(side, hip, u, pose)
        legs[side] = (hip, kn, an, sh, pose)
    ankle_z = 0.32 * u
    dz = ankle_z - min(v[2][2] for v in legs.values())
    off = Vector((0, 0, dz))

    thigh_r0, thigh_r1 = 0.4 * u * k, 0.27 * u * k
    calf_r0, calf_r1 = 0.26 * u * k, 0.15 * u * k
    for side, (hip, kn, an, sh, pose) in legs.items():
        s = "l" if side < 0 else "r"
        hip, kn, an = hip + off, kn + off, an + off
        limb(f"{prefix}_thigh_{s}", hip, kn, thigh_r0, thigh_r1, pants, 14)
        # Diz: hafif şişkin eklem + önde diz kapağı.
        sphere(f"{prefix}_knee_{s}", kn.x, kn.y, kn.z, 0.27 * u * k, pants, 14, 8)
        # Diz kapağı: önde hafif çıkıntı.
        cap = kn + (_ortho(Vector((0, -1, 0)), sh) or Vector((0, -1, 0))) * (0.13 * u * k)
        sphere(f"{prefix}_kneecap_{s}", cap.x, cap.y, cap.z, 0.14 * u * k, pants, 10, 6)
        limb(f"{prefix}_shin_{s}", kn, an, calf_r0, calf_r1, shin, 14)
        # Baldır kası: arkada, dizin biraz altında.
        calf_c = kn + sh * (0.6 * u) + Vector((0, 0.035 * u, 0))
        blob(f"{prefix}_calf_{s}", calf_c, (Vector((1, 0, 0)), Vector((0, 1, 0)), sh),
             (0.22 * u * k, 0.23 * u * k, 0.6 * u), shin, 14, 8)
        sphere(f"{prefix}_ankle_{s}", an.x, an.y, an.z, 0.15 * u * k, shin, 10, 6)
        # Ayak (ayakkabı): ayak bileğinden öne uzanan elipsoit + taban.
        turn = math.radians(pose.get("turn", 8) * side)
        toe = Vector((math.sin(turn), -math.cos(turn), 0.0))
        toe = _ortho(toe, sh) or toe
        up = -sh  # ayağın üstü baldıra doğru
        side_ax = toe.cross(up).normalized()
        fc = an + toe * (0.36 * u) - up * (0.18 * u)
        blob(f"{prefix}_foot_{s}", fc, (side_ax, toe, up),
             (0.2 * u, 0.6 * u, 0.2 * u), shoe, 14, 8)
        blob(f"{prefix}_sole_{s}", fc - up * (0.13 * u), (side_ax, toe, up),
             (0.21 * u, 0.62 * u, 0.06 * u), shoe, 14, 6)

    # ── Gövde: eliptik kesitli döndürme yüzeyleri (derinlik genişliğin
    # ~%64'ü). Leğen (kasık → bel) pantolon malzemesinde, üst gövde onun
    # üstünde; gömlek pantolonun içine sokulmuş gibi bel pantolonda biraz
    # daha geniştir.
    z = lambda f: f * u + dz  # noqa: E731  (baş birimi → yükseklik)
    wide = 1.08 if female else 1.0
    chest = 0.92 if female else 1.0
    pelvis = [
        (0.0, z(3.6)),
        (0.56 * k * wide, z(3.62)),
        (0.78 * k * wide, z(3.84)),
        (0.8 * k * wide, z(4.1)),    # kalça
        (0.72 * k * wide, z(4.42)),
        (0.66 * k, z(4.72)),         # bel (pantolon kemeri)
        (0.0, z(4.74)),
    ]
    upper = [
        (0.0, z(4.54)),
        (0.62 * k, z(4.56)),
        (0.64 * k, z(4.85)),
        (0.72 * k * chest, z(5.2)),
        (0.8 * k * chest, z(5.55)),   # göğüs
        (0.82 * k * chest, z(5.85)),
        (0.74 * k * chest, z(6.05)),  # omuz başı
        (0.5 * k, z(6.2)),
        (0.3, z(6.28)),
    ]
    surfaces = []  # (profil [(yarıçap, z)], derinlik oranı): ön yüzey için
    for tag, prof, m_ in (("pelvis", pelvis, pants), ("torso", upper, top)):
        surfaces.append(([(r * u, h) for r, h in prof], 0.64))
        ob = lathe(f"{prefix}_{tag}", [(r * u, h) for r, h in prof], m_, 22)
        for v in ob.data.vertices:
            v.co.y *= 0.64
        ob.data.update()
    if belt is not None:
        ring = torus(f"{prefix}_belt", 0, 0, 0, 0.66 * u * k, 0.05 * u, belt, 26, 6)
        for v in ring.data.vertices:
            v.co.y *= 0.66
        _transform(ring, Matrix.Identity(3), Vector((0, 0, z(4.68))))
    # Trapez: boyundan omuzlara inen eğim.
    blob(f"{prefix}_trap", (0, 0.05 * u, z(6.1)), (Vector((1, 0, 0)), Vector((0, 1, 0)),
         Vector((0, 0, 1))), (0.62 * u * k, 0.32 * u * k, 0.2 * u), top, 16, 8)

    # ── Kollar ve eller.
    sh_z = z(5.98)
    sh_x = (0.84 if not female else 0.76) * u * k
    info = dict(u=u, dz=dz, shoulder_z=sh_z, waist_z=z(4.75), hip_z=z(3.95),
                chest_front_y=-0.74 * u * k * 0.64)
    upper_r0, upper_r1 = 0.25 * u * k, 0.2 * u * k
    fore_r0, fore_r1 = 0.2 * u * k, 0.13 * u * k
    for side, pose in ((-1, arm_l), (1, arm_r)):
        s = "l" if side < 0 else "r"
        shp = Vector((side * sh_x, 0.0, sh_z))
        el, wr, fore, n, w = _arm_points(side, shp, u, pose)
        # Deltoid: omzu yuvarlatan kas.
        dc = shp + Vector((-side * 0.05 * u, 0, -0.04 * u))
        blob(f"{prefix}_delt_{s}", dc, (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))),
             (0.27 * u * k, 0.25 * u * k, 0.3 * u * k), sleeve, 12, 8)
        limb(f"{prefix}_upper_{s}", shp, el, upper_r0, upper_r1, sleeve, 12)
        sphere(f"{prefix}_elbow_{s}", el.x, el.y, el.z, 0.205 * u * k, sleeve, 10, 6)
        limb(f"{prefix}_fore_{s}", el, wr, fore_r0, fore_r1, sleeve, 12)
        if cuff is not None:
            ring = torus(f"{prefix}_cuff_{s}", 0, 0, 0, 0.125 * u * k, 0.03 * u, cuff, 14, 6)
            _transform(ring, _frame_to(fore), wr - fore * (0.08 * u))
        limb(f"{prefix}_wrist_{s}", wr - fore * (0.05 * u), wr + fore * (0.05 * u),
             0.1 * u, 0.1 * u, skin, 8, 2)
        grip = _hand(f"{prefix}_hand_{s}", side, wr, fore, n, w, u, skin,
                     pose.get("curl", 0.35))
        info[f"grip_{s}"] = grip
        info[f"hand_frame_{s}"] = (wr, fore, n, w)
        info[f"elbow_{s}"] = el

    # ── Önlük / ceket ([coat]: omuzdan iner, gövdeyi sarar) ve etek / cüppe
    # ([skirt]: belden iner). Kesit eliptik; alt uç [bottom]'a kadar [flare]
    # oranında genişler.
    strips = []
    for name, spec in (("coat", coat), ("skirt", skirt)):
        if spec is None:
            continue
        bottom = spec.get("bottom", 0.4)
        flare = spec.get("flare", 1.25)
        if name == "coat":
            depth = 0.68
            prof = [(0.52 * k, z(6.2)), (0.8 * k * chest, z(6.0)),
                    (0.86 * k * chest, z(5.6)), (0.8 * k, z(5.0)), (0.84 * k * wide, z(4.4))]
        else:
            depth = 0.7
            prof = [(0.66 * k, z(4.78)), (0.76 * k * wide, z(4.3)),
                    (0.8 * k * wide, z(3.9))]
        prof = [(rr * u, zz) for rr, zz in prof]
        r_base, z_base = prof[-1]
        steps = 6
        for i in range(1, steps + 1):
            t = i / steps
            prof.append((r_base * (1 + (flare - 1) * t), z_base + (bottom - z_base) * t))
        surfaces.append((prof, depth))
        c = lathe(f"{prefix}_{name}", prof, spec["m"], 26)
        for v in c.data.vertices:
            v.co.y *= depth
        c.data.update()
        if spec.get("hem") is not None:
            ring = torus(f"{prefix}_{name}_hem", 0, 0, 0, prof[-1][0], 0.035 * u,
                         spec["hem"], 30, 6)
            for v in ring.data.vertices:
                v.co.y *= depth
            _transform(ring, Matrix.Identity(3), Vector((0, 0, bottom + 0.02 * u)))
        if spec.get("open") is not None:
            strips.append((f"{prefix}_{name}_front", prof[0][1] - 0.02 * u, bottom + 0.01,
                           spec.get("open_w", 0.12) * u * 2, spec["open"]))

    def front_y(zz, x=0.0):
        """Gövdenin (ve varsa önlük/eteğin) [zz] yüksekliğinde, [x]'teki ön
        yüzeyinin y'si (en öndeki katman)."""
        best = 0.0
        for prof, depth in surfaces:
            pts = sorted(prof, key=lambda p: p[1])
            for (r0, z0), (r1, z1) in zip(pts, pts[1:]):
                if z0 <= zz <= z1 and z1 > z0:
                    rr = r0 + (r1 - r0) * (zz - z0) / (z1 - z0)
                    if abs(x) < rr:
                        y = -depth * math.sqrt(rr * rr - x * x)
                        best = min(best, y)
        return best

    info["front_y"] = front_y
    # Önlük açıklığı / düğme şeridi: en öndeki yüzeyi izleyen şerit.
    for sname, z_hi, z_lo, width, m_ in strips:
        front_band(sname, info, (0.0, z_hi), (0.0, z_lo), width, m_, 14)

    # ── Boyun ve baş.
    neck_a = Vector((0, 0.02 * u, z(6.05)))
    neck_b = Vector((0, 0.03 * u, z(6.55)))
    limb(f"{prefix}_neck", neck_a, neck_b, 0.3 * u, 0.26 * u, skin, 12)
    if collar is not None:
        ring = torus(f"{prefix}_collar", 0, 0, 0, 0.3 * u, 0.06 * u, collar, 18, 6)
        _transform(ring, Matrix.Identity(3), Vector((0, 0.01 * u, z(6.22))))
    info["neck_front"] = Vector((0, -0.24 * u, z(6.25)))

    # Baş, çocuklara sıcak görünsün diye gerçek orandan biraz büyük
    # ([head_scale]); tepesi yine [height]'tadır.
    r = 0.37 * u * head_scale
    hc = Vector((0, 0.0, H - 1.25 * r + dz))
    info["head_c"] = hc
    info["head_r"] = r
    turn = math.radians(head.get("turn", 0))
    tilt = math.radians(head.get("tilt", 0))
    head_rot = (Matrix.Rotation(turn, 3, "Z") @ Matrix.Rotation(-tilt, 3, "X"))

    def attach_head(ob):
        """Baş-yerel koordinatta (baş merkezi orijin, yüz -y) kurulmuş
        nesneyi başın dönüşüyle yerine taşır."""
        return _transform(ob, head_rot, hc)

    info["attach_head"] = attach_head
    X, Y, Zv = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
    u = r / 0.37  # yüz ölçüleri başın boyuna göre
    # Kafatası + çene: yumurta biçimi; çene hafifçe aşağı ve öne daralır.
    attach_head(blob(f"{prefix}_skull", (0, 0.03 * u, 0.05 * u), (X, Y, Zv),
                     (r, r * 1.1, r * 1.2), skin, 20, 14))
    attach_head(blob(f"{prefix}_jaw", (0, -0.04 * u, -0.2 * u), (X, Y, Zv),
                     (r * 0.8, r * 0.86, r * 0.72), skin, 16, 10))
    attach_head(blob(f"{prefix}_chin", (0, -0.2 * u, -0.4 * u), (X, Y, Zv),
                     (r * 0.34, r * 0.3, r * 0.2), skin, 10, 6))
    # Elmacık kemikleri.
    for side in (-1, 1):
        attach_head(blob(f"{prefix}_cheek{side}", (side * r * 0.48, -r * 0.6, -0.08 * u),
                         (X, Y, Zv), (r * 0.24, r * 0.24, r * 0.2), skin, 10, 6))
    # Kulaklar.
    for side in (-1, 1):
        attach_head(blob(f"{prefix}_ear{side}", (side * r * 0.98, 0.03 * u, -0.02 * u),
                         (X, Y, Zv), (r * 0.12, r * 0.22, r * 0.3), skin, 10, 6))
    # Burun: kemer + uç + iki kanat.
    ns = nose_scale
    attach_head(blob(f"{prefix}_nose", (0, -r * 1.0, -0.06 * u), (X, Y, Zv),
                     (r * 0.11 * ns, r * 0.14 * ns, r * 0.28 * ns), skin, 10, 8))
    attach_head(blob(f"{prefix}_nose_tip", (0, -r * 1.08, -0.15 * u), (X, Y, Zv),
                     (r * 0.14 * ns, r * 0.12 * ns, r * 0.11 * ns), skin, 10, 6))
    # Gözler: beyaz + iris, üstte kaş.
    for side in (-1, 1):
        ex = side * r * 0.36
        attach_head(blob(f"{prefix}_eyeball{side}", (ex, -r * 0.92, 0.05 * u), (X, Y, Zv),
                         (r * 0.16, r * 0.1, r * 0.11), fm["white"], 12, 8))
        attach_head(sphere(f"{prefix}_iris{side}", ex, -r * 1.0, 0.05 * u, r * 0.075,
                           fm["iris"], 10, 6))
        if brow is not None:
            attach_head(blob(f"{prefix}_brow{side}", (ex, -r * 1.0, 0.2 * u), (X, Y, Zv),
                             (r * 0.22, r * 0.07, r * 0.055), brow, 10, 5))
    # Ağız: ince dudaklar.
    attach_head(blob(f"{prefix}_lips", (0, -r * 0.9, -0.3 * u), (X, Y, Zv),
                     (r * 0.24, r * 0.07, r * 0.05), fm["lip"], 12, 6))
    info["r"] = r
    return info


# ─────────────────────────── Birleştirme ───────────────────────────


def join_by_material(root):
    """[root] altındaki örgüleri malzeme başına tek örgüde birleştirir (oyunda
    daha az çizim çağrısı). Parçaların yerel dönüşümleri köşelere işlenir."""
    import bmesh
    objs = [o for o in root.children_recursive if o.type == "MESH"]
    by = {}
    for o in objs:
        name = o.data.materials[0].name if o.data.materials else "_none"
        by.setdefault(name, []).append(o)
    for mname, lst in by.items():
        bm = bmesh.new()
        for o in lst:
            me = o.data.copy()
            me.transform(o.matrix_basis)
            bm.from_mesh(me)
            bpy.data.meshes.remove(me)
        me = bpy.data.meshes.new(f"{root.name}_{mname}")
        bm.to_mesh(me)
        bm.free()
        if mname in bpy.data.materials:
            me.materials.append(bpy.data.materials[mname])
        ob = bpy.data.objects.new(f"{root.name}_{mname}", me)
        coll.objects.link(ob)
        ob.parent = root
        for o in lst:
            bpy.data.objects.remove(o, do_unlink=True)
    return root


# ─────────────────────────── Baş eklentileri ───────────────────────────


def hair_cap(name, info, m, back=0.12, lift=0.2, size=1.08, sz=1.15, sx=1.0):
    """Başın tepesini ve arkasını örten saç; alın ve yüz açık kalır.
    Kafatasının tepesi baş-yerel z ≈ 1.34·r'dedir; başlık bunun üstüne
    çıkmalı (lift + size·sz > 1.34), yoksa kafatasının içinde kalır."""
    r = info["r"]
    return info["attach_head"](sphere(name, 0, back * r, lift * r, size * r, m, 18, 10,
                                      sz=sz, sx=sx))


def face_ring(name, info, x, y, z, R, t, m):
    """Yüze dönük (ekseni y) halka, baş-yerel r biriminde: gözlük camı."""
    r = info["r"]
    ring = torus(name, 0, 0, 0, R * r, t * r, m, 16, 5)
    _transform(ring, Matrix.Rotation(math.pi / 2, 3, "X"), Vector((x * r, y * r, z * r)))
    return info["attach_head"](ring)


def front_band(name, info, a, b, width, m, steps=10, lift=0.006, thick=0.006):
    """Gövdenin önünde, yüzeye yapışık ince şerit: [a] ve [b] = (x, z). Çapraz
    şerit, kravat, düğme şeridi için. Kapalı bir örgüdür (her yönden görünür)."""
    fy = info["front_y"]
    dx, dz = b[0] - a[0], b[1] - a[1]
    L = math.hypot(dx, dz) or 1.0
    nx, nz = -dz / L * width / 2, dx / L * width / 2
    verts, faces = [], []
    for i in range(steps + 1):
        t = i / steps
        x = a[0] + dx * t
        zz = a[1] + dz * t
        ring = []
        for sgn in (-1, 1):
            px, pz = x + sgn * nx, zz + sgn * nz
            y = fy(pz, px) - lift
            ring.append((px, y - thick, pz))
            ring.append((px, y, pz))
        # sıra: sol-ön, sol-arka, sağ-ön, sağ-arka → döngü: 0,2,3,1
        verts += [ring[0], ring[2], ring[3], ring[1]]
        if i:
            o, p_ = 4 * i, 4 * (i - 1)
            for k2 in range(4):
                k3 = (k2 + 1) % 4
                faces.append((p_ + k2, p_ + k3, o + k3, o + k2))
    faces.append((0, 1, 2, 3))
    last = 4 * steps
    faces.append((last + 3, last + 2, last + 1, last))
    return poly(name, verts, faces, m)
