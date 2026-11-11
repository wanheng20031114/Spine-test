"""Author native Godot scenes. No runtime node construction or raster drawing.

The two-link solves below bake editable AnimationPlayer keys at authoring time.
Feet are authored in ground space; hands and weapons share measured grip pivots.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/schoolgirl_profile"
SIZES = json.loads((ART / "parts.json").read_text(encoding="utf-8"))
PI = math.pi
H = "Skeleton2D/Hips"
T = H + "/Torso"
HEAD = T + "/Head"
A = T + "/ArmAim"
N = A + "/NearUpper"
F = A + "/FarUpper"
NH = N + "/NearLower/Hand"
FH = F + "/FarLower/Hand"
HAIR = HEAD + "/Hair"
nodes = []
resources = []
layout = {}


def num(value):
    return f"{value:.7f}".rstrip("0").rstrip(".") or "0"


def value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, tuple):
        return "Vector2(" + ", ".join(num(n) for n in v) + ")"
    if isinstance(v, (float, int)):
        return num(v)
    return v


def node(path, kind, props=None, groups=""):
    name = path.rsplit("/", 1)[-1]
    parent = path.rsplit("/", 1)[0] if "/" in path else "."
    header = f'[node name="{name}" type="{kind}" parent="{parent}"{groups}]'
    nodes.append(header + "\n" + "\n".join(f"{k} = {value(v)}" for k, v in (props or {}).items()) + "\n")


def bone(path, pos, length, z=0, down=True):
    x, y = pos
    node(path, "Bone2D", {"position": pos, "rest": f"Transform2D(1, 0, 0, 1, {x}, {y})",
                          "auto_calculate_length_and_angle": False, "length": length,
                          "bone_angle": PI / 2 if down else -PI / 2, "z_index": z})
    node(path + "/Guide", "Line2D", {"visible": False, "z_index": 60,
         "points": f"PackedVector2Array(0, 0, 0, {length if down else -length})", "width": 1.2,
         "default_color": "Color(0.4, 1, 0.8, 0.9)"}, ' groups=["bone_guides"]')


def sprite(path, part, pos, height=None, width=None, z=0, tint=1.0, visible=True, x_scale=1.0):
    w, h = SIZES[part]["size"]
    scale = height / h if height else width / w
    node(path, "Sprite2D", {"texture": f'ExtResource("{part}")', "centered": False,
         "position": pos, "scale": (scale * x_scale, scale), "z_index": z,
         "self_modulate": f"Color({tint}, {tint}, {tint}, 1)", "visible": visible})
    layout[path] = {"part": part, "offset": pos, "scale": [scale * x_scale, scale],
                    "rendered_size": [round(w * scale * x_scale, 3), round(h * scale, 3)]}


def solve(target, first, second, bend):
    """FK rotations for a fixed-length two-bone chain initially pointing down."""
    x, y = target
    distance = math.hypot(x, y)
    assert abs(first - second) < distance < first + second, target
    theta = math.atan2(y, x)
    angle = theta + bend * math.acos((first * first + distance * distance - second * second) / (2 * first * distance))
    ex, ey = first * math.cos(angle), first * math.sin(angle)
    lower_angle = math.atan2(y - ey, x - ex)
    relative = (lower_angle - angle + PI) % (2 * PI) - PI
    return angle - PI / 2, relative


def animation(name, duration, loop, times, tracks, prefix):
    rid = prefix + "_" + name
    lines = [f'[sub_resource type="Animation" id="{rid}"]', f'resource_name = "{name}"',
             f"length = {num(duration)}", f"loop_mode = {1 if loop else 0}"]
    for i, (path, vals) in enumerate(tracks.items()):
        discrete = isinstance(vals[0], bool)
        lines += [f'tracks/{i}/type = "value"', f'tracks/{i}/path = NodePath("{path}")',
                  f'tracks/{i}/interp = {0 if discrete else 1}',
                  f'tracks/{i}/keys = {{',
                  '"times": PackedFloat32Array(' + ", ".join(num(t) for t in times) + '),',
                  '"transitions": PackedFloat32Array(' + ", ".join("1" for _ in times) + '),',
                  f'"update": {1 if discrete else 0},',
                  '"values": [' + ", ".join(value(v) for v in vals) + ']\n}']
    resources.append("\n".join(lines) + "\n")
    return rid


def append(tracks, path, v):
    tracks.setdefault(path, []).append(v)


def locomotion(name):
    walking = name == "walk"
    duration = 0.6 if walking else 2.4
    count = 48
    times = [duration * i / count for i in range(count + 1)]
    tracks = {}
    for time in times:
        phase = time / duration
        hip_y = -72 + 1.8 * math.cos(4 * PI * phase) if walking else -77 + 0.25 * math.sin(2 * PI * phase)
        append(tracks, H + ":position", (0, hip_y))
        for side, offset, base_x in [("Near", 0, 3), ("Far", 0.5, -3)]:
            p = (phase + offset) % 1
            if walking:
                # 48 px ground travel over 0.3 s = 160 px/s. During stance,
                # local backward motion cancels actual CharacterBody2D travel.
                if p <= 0.5:
                    foot_x, foot_y = 24 - 96 * p, -9
                else:
                    u = (p - 0.5) * 2
                    foot_x = -24 + 48 * (6 * u * u - 4 * u * u * u - u)
                    foot_y = -9 - 16 * math.sin(PI * u) ** 2
            else:
                foot_x, foot_y = (6 if side == "Near" else -7), -9
            upper, lower = solve((foot_x - base_x, foot_y - hip_y), 36, 33, -1)
            leg = H + "/" + side + "Thigh"
            append(tracks, leg + ":rotation", upper)
            append(tracks, leg + "/Shin:rotation", lower)
            append(tracks, leg + "/Shin/Foot:rotation", -upper - lower)
        amplitude = 0.045 if walking else 0.009
        append(tracks, H + "/Coat:rotation", amplitude * math.sin(2 * PI * phase - 0.7))
        append(tracks, HAIR + "/HairMid:rotation", amplitude * math.sin(2 * PI * phase - 0.9))
        append(tracks, HAIR + "/HairMid/HairTip:rotation", amplitude * 0.8 * math.sin(2 * PI * phase - 1.5))
    return animation(name, duration, True, times, tracks, "loc")


def smooth(a, b, u):
    u = u * u * (3 - 2 * u)
    return a + (b - a) * u


def sample_keys(keys, t):
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t <= t1:
            return tuple(smooth(a, b, (t - t0) / (t1 - t0)) for a, b in zip(v0, v1))
    return keys[-1][1]


def action(name):
    duration = {"sword_idle": 2.4, "sword_walk": 0.6, "slash": 0.5,
                "bow_ready": 2.4, "bow_draw": 0.8, "bow_release": 0.25}[name]
    loop = name in ["sword_idle", "sword_walk", "bow_ready"]
    count = max(20, round(duration * 60))
    times = [duration * i / count for i in range(count + 1)]
    tracks = {}
    slash_keys = [(0, (35, 36, 0.67, 0)), (.11, (46, 18, 0, -.09)),
                  (.20, (10, 45, 1.35, .11)), (.29, (2, 47, 1.8, .14)),
                  (.50, (35, 36, .67, 0))]
    for time in times:
        phase = time / duration
        bow = name.startswith("bow")
        torso = 0.0
        hand_angle = 0.67
        near = (35, 36)
        far_upper, far_lower = 0.18, -0.25
        far_hand_angle = far_upper + far_lower + PI / 2
        if name == "sword_idle":
            near = (35, 36 + 0.5 * math.sin(2 * PI * phase))
            torso = 0.006 * math.sin(2 * PI * phase)
        elif name == "sword_walk":
            near = (34 + 2.5 * math.sin(2 * PI * phase), 35 - 1.2 * math.cos(2 * PI * phase))
            hand_angle += 0.06 * math.sin(2 * PI * phase)
            far_upper = -0.45 * math.sin(2 * PI * phase)
            torso = .025 + .015 * math.sin(4 * PI * phase)
            far_hand_angle = far_upper + far_lower + PI / 2
        elif name == "slash":
            nx, ny, hand_angle, torso = sample_keys(slash_keys, time)
            near = (nx, ny)
            far_upper = .18 + torso * 3
            far_hand_angle = far_upper + far_lower + PI / 2
        if bow:
            near, hand_angle = (54, -3), 0.0
            far_x = 32.0
            if name == "bow_draw":
                far_x = smooth(32, 18, phase)
            elif name == "bow_release":
                far_x = sample_keys([(0, (18,)), (.06, (14,)), (.25, (32,))], time)[0]
            far_upper, far_lower = solve((far_x + 3, -3), 20, 36, -1)
            far_hand_angle = 0.0
        near_upper, near_lower = solve((near[0] - 3, near[1]), 28, 28, 1)
        for path, angle in [(N, near_upper), (N + "/NearLower", near_lower),
                            (NH, hand_angle - near_upper - near_lower),
                            (F, far_upper), (F + "/FarLower", far_lower),
                            (FH, far_hand_angle - far_upper - far_lower)]:
            append(tracks, path + ":rotation", angle)
        append(tracks, T + ":rotation", torso)
        append(tracks, HEAD + ":rotation", -torso * .8)
        append(tracks, HAIR + ":rotation", -torso * .65)
        append(tracks, FH + "/RelaxedHand:visible", not bow or name == "bow_release")
        append(tracks, FH + "/PullHand:visible", bow and name != "bow_release")
    return animation(name, duration, loop, times, tracks, "act")


def build():
    loc = {name: locomotion(name) for name in ["idle", "walk"]}
    acts = {name: action(name) for name in ["sword_idle", "sword_walk", "slash", "bow_ready", "bow_draw", "bow_release"]}
    for library, entries in [("loc", loc), ("act", acts)]:
        resources.append(f'[sub_resource type="AnimationLibrary" id="{library}_lib"]\n_data = {{' +
                         ", ".join(f'"{name}": SubResource("{rid}")' for name, rid in entries.items()) + '}\n')
    node("Skeleton2D", "Skeleton2D")
    bone(H, (0, -77), 57, down=False)
    bone(H + "/Coat", (0, -12), 40, z=6)
    sprite(H + "/Coat/Artwork", "skirt", (-20, -3), height=43)
    for side, x, z, tint in [("Far", -3, -3, .82), ("Near", 3, 2, 1.0)]:
        leg = H + "/" + side + "Thigh"
        bone(leg, (x, 0), 36, z=z)
        sprite(leg + "/Artwork", "thigh", (-7.2, -7), height=46, tint=tint)
        bone(leg + "/Shin", (0, 36), 33)
        sprite(leg + "/Shin/Artwork", "shin", (-4.4, -6), height=42, z=-1, tint=tint)
        bone(leg + "/Shin/Foot", (0, 33), 14)
        sprite(leg + "/Shin/Foot/Artwork", "foot", (-5.0, -5), height=14, tint=tint)
        node(leg + "/Shin/Foot/Sole", "Marker2D", {"position": (4, 9)})
    bone(T, (0, 0), 64, z=4, down=False)
    sprite(T + "/Artwork", "torso", (-14, -75), height=70)
    bone(HEAD, (0, -64), 70, z=8, down=False)
    sprite(HEAD + "/Artwork", "head", (-57, -103), height=118)
    bone(HAIR, (-26, -83), 63)
    bone(HAIR + "/HairMid", (0, 63), 62)
    bone(HAIR + "/HairMid/HairTip", (0, 62), 45)
    bone(A, (0, -57), 30, down=False)
    for side, x, z, tint in [("Far", -3, -5, .82), ("Near", 3, 10, 1.0)]:
        arm = A + "/" + side + "Upper"
        lower = arm + "/" + side + "Lower"
        upper_length, lower_length = (20, 36) if side == "Far" else (28, 28)
        bone(arm, (x, 0), upper_length, z=z)
        sprite(arm + "/Artwork", "upper_arm", (-7.0, -7), height=upper_length + 14, tint=tint)
        bone(lower, (0, upper_length), lower_length)
        sprite(lower + "/Artwork", "forearm", (-4.9, -6), height=lower_length + 9, z=-1, tint=tint)
        bone(lower + "/Hand", (0, lower_length), 10)
    sprite(FH + "/RelaxedHand", "hand_relaxed", (-.7, -3), width=13, tint=.90)
    sprite(FH + "/PullHand", "hand_pull", (-.5, -4.2), width=13, z=12, tint=.95, visible=False)
    node(FH + "/StringNock", "Marker2D", {"position": (12, -1)})
    node(NH + "/Sword", "Node2D")
    sprite(NH + "/Sword/Artwork", "sword", (-1.15, -89.25), height=100, z=-1)
    sprite(NH + "/Sword/GripHand", "hand_sword", (-.5, -5.8), width=10.5, z=1)
    node(NH + "/Sword/Grip", "Marker2D", {"position": (7.3, -1.3)})
    node(NH + "/Bow", "Node2D", {"visible": False})
    sprite(NH + "/Bow/Artwork", "bow", (-6.7, -60.4), height=120, z=-1, x_scale=.6)
    sprite(NH + "/Bow/GripHand", "hand_bow", (-1.8, -5.8), width=12, z=1)
    node(NH + "/Bow/Grip", "Marker2D", {"position": (7.5, -1)})
    node(NH + "/Bow/String", "Line2D", {"points": "PackedVector2Array(-5.7, -58.5, -12, -1, -5.7, 57)",
         "width": .85, "default_color": "Color(0.80, 0.87, 0.95, 1)", "antialiased": True})
    sprite(NH + "/Bow/NockedArrow", "arrow", (-12, -3), width=90)
    # Continuous native weighted mesh: no image resampling or alpha modification.
    points, uvs, polygons, weights = [], [], [], [[], [], []]
    w, h = SIZES["hair_back"]["size"]
    for row in range(9):
        yy = row / 8
        mix = max(0, min(2, (yy - .12) * 2.5))
        influence = [max(0, 1 - abs(mix - index)) for index in range(3)]
        for col in range(3):
            xx = col / 2
            points += [-51 + xx * 49, -235 + yy * 184]
            uvs += [xx * w, yy * h]
            for index in range(3):
                weights[index].append(influence[index])
    for row in range(8):
        for col in range(2):
            i = row * 3 + col
            polygons.append(f"PackedInt32Array({i}, {i + 1}, {i + 4}, {i + 3})")
    hair_paths = [HAIR, HAIR + "/HairMid", HAIR + "/HairMid/HairTip"]
    bones = []
    for path, ws in zip(hair_paths, weights):
        bones += [f'NodePath("{path.removeprefix("Skeleton2D/")}")',
                  "PackedFloat32Array(" + ", ".join(num(n) for n in ws) + ")"]
    node("HairMesh", "Polygon2D", {"texture": 'ExtResource("hair_back")', "z_index": -8,
         "skeleton": 'NodePath("../Skeleton2D")',
         "polygon": "PackedVector2Array(" + ", ".join(num(n) for n in points) + ")",
         "uv": "PackedVector2Array(" + ", ".join(num(n) for n in uvs) + ")",
         "polygons": "[" + ", ".join(polygons) + "]", "bones": "[" + ", ".join(bones) + "]"})
    node("Locomotion", "AnimationPlayer", {"libraries": '{&"": SubResource("loc_lib")}', 'autoplay': '"idle"'})
    node("Actions", "AnimationPlayer", {"libraries": '{&"": SubResource("act_lib")}', 'autoplay': '"sword_idle"'})
    ext = [f'[ext_resource type="Texture2D" path="res://assets/schoolgirl_profile/{name}.png" id="{name}"]' for name in SIZES]
    text = "[gd_scene format=3]\n\n" + "\n\n".join(ext + resources)
    text += '\n[node name="SchoolgirlRig" type="Node2D"]\n\n' + "\n".join(nodes)
    (ROOT / "scenes/schoolgirl_rig.tscn").write_text(text, encoding="utf-8")
    (ART / "rig_layout.json").write_text(json.dumps(layout, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    build_parts_grid()
    print(f"Authored {len(nodes)} native nodes; 20 bones; 16 separate source images.")


def build_parts_grid():
    ext = [f'[ext_resource type="Texture2D" path="res://assets/schoolgirl_profile/{name}.png" id="{name}"]' for name in SIZES]
    ext.append('[ext_resource type="Font" path="res://assets/ui_font.tres" id="font"]')
    labels = ["头部", "后发", "侧面上衣", "独立裙摆", "上臂", "前臂无手", "大腿", "小腿长袜",
              "独立鞋", "持剑手", "握弓手", "拉弦手", "放松手", "剑", "弓无弦", "箭"]
    text = '[gd_scene format=3]\n\n' + "\n\n".join(ext)
    text += '\n\n[node name="ProfileParts" type="GridContainer"]\ncolumns = 4\ntheme_override_constants/h_separation = 18\ntheme_override_constants/v_separation = 12\n'
    for i, (name, label) in enumerate(zip(SIZES, labels)):
        text += f'\n[node name="{name}" type="VBoxContainer" parent="."]\ncustom_minimum_size = Vector2(196, 154)\nmouse_filter = 2\n'
        text += f'\n[node name="Image" type="TextureRect" parent="{name}"]\ncustom_minimum_size = Vector2(196, 126)\ntexture = ExtResource("{name}")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n'
        text += f'\n[node name="Caption" type="Label" parent="{name}"]\ntext = "{i + 1:02d}  {label}"\nhorizontal_alignment = 1\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = 14\n'
    (ROOT / "scenes/profile_parts.tscn").write_text(text, encoding="utf-8")


if __name__ == "__main__":
    build()
