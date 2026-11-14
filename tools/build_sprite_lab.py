"""Offline scene authoring; all game and inspector nodes are saved in .tscn."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
nodes = []


def node(name, kind, parent=".", props=""):
    nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n{props}\n')


def rect(name, box, color, parent="HUD"):
    x, y, w, h = box
    node(name, "ColorRect", parent, f"offset_left = {x}\noffset_top = {y}\noffset_right = {x+w}\noffset_bottom = {y+h}\ncolor = Color{color}\nmouse_filter = 2")


def label(name, text, box, size=18, color="(0.74, 0.86, 0.87, 1)", parent="HUD"):
    x, y, w, h = box
    text = text.replace("\n", "\\n")
    node(name, "Label", parent, f'offset_left = {x}\noffset_top = {y}\noffset_right = {x+w}\noffset_bottom = {y+h}\ntext = "{text}"\nmouse_filter = 2\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = {size}\ntheme_override_colors/font_color = Color{color}')


def button(name, text, box, parent="HUD"):
    x, y, w, h = box
    node(name, "Button", parent, f'offset_left = {x}\noffset_top = {y}\noffset_right = {x+w}\noffset_bottom = {y+h}\ntext = "{text}"\nfocus_mode = 0\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = 16\ntheme_override_styles/normal = SubResource("button")\ntheme_override_styles/hover = SubResource("hover")')


def build():
    header = '''[gd_scene format=3]
[ext_resource type="Script" path="res://scripts/sprite_lab.gd" id="script"]
[ext_resource type="PackedScene" path="res://scenes/sprite_schoolgirl.tscn" id="actor"]
[ext_resource type="PackedScene" path="res://scenes/target.tscn" id="target"]
[ext_resource type="PackedScene" path="res://scenes/arrow.tscn" id="arrow"]
[ext_resource type="Font" path="res://assets/ui_font.tres" id="font"]
[ext_resource type="SpriteFrames" path="res://assets/schoolgirl_frames/schoolgirl_frames.tres" id="frames"]
[ext_resource type="Texture2D" path="res://assets/schoolgirl_frames/idle_sword.png" id="sheet"]
[sub_resource type="RectangleShape2D" id="floor"]
size = Vector2(1110, 36)
[sub_resource type="StyleBoxFlat" id="button"]
bg_color = Color(0.10, 0.18, 0.23, 1)
border_width_left = 1
border_width_right = 1
border_width_top = 1
border_width_bottom = 1
border_color = Color(0.27, 0.42, 0.48, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_left = 4
corner_radius_bottom_right = 4
[sub_resource type="StyleBoxFlat" id="hover"]
bg_color = Color(0.16, 0.31, 0.34, 1)
[node name="SpriteLab" type="Node2D"]
script = ExtResource("script")
'''
    node("World", "Node2D")
    rect("Background", (0, 0, 1440, 900), "(0.027, 0.043, 0.059, 1)", "World")
    rect("Arena", (24, 150, 1086, 568), "(0.045, 0.075, 0.096, 1)", "World")
    for i in range(16):
        node(f"Grid{i}", "Line2D", "World", f"points = PackedVector2Array({62+i*64}, 150, {62+i*64}, 718)\nwidth = 1\ndefault_color = Color(0.15, 0.25, 0.29, 0.25)")
    node("GroundLine", "Line2D", "World", "points = PackedVector2Array(24, 658, 1110, 658)\nwidth = 2\ndefault_color = Color(0.43, 0.83, 0.78, 1)")
    node("Floor", "StaticBody2D", props="position = Vector2(567, 676)\ncollision_layer = 1\ncollision_mask = 2")
    node("Shape", "CollisionShape2D", "Floor", 'shape = SubResource("floor")')
    nodes.append('[node name="Actor" parent="." instance=ExtResource("actor")]\nposition = Vector2(410, 658)\n')
    for name, x, y, scale in [("TargetLeft", 160, 658, 1), ("TargetNear", 850, 658, 1), ("TargetHigh", 945, 320, .7), ("TargetLow", 610, 693, .55)]:
        nodes.append(f'[node name="{name}" parent="." instance=ExtResource("target")]\nposition = Vector2({x}, {y})\nscale = Vector2({scale}, {scale})\n')
    node("Arrows", "Node2D")
    for i in range(12):
        nodes.append(f'[node name="Arrow{i+1:02}" parent="Arrows" instance=ExtResource("arrow")]\n')
    node("AimGuide", "Line2D", props="points = PackedVector2Array(145, 0, 175, 0, 166, -5, 175, 0, 166, 5)\nwidth = 1.5\ndefault_color = Color(0.9, 0.73, 0.40, 0.8)\nz_index = 20")
    node("HUD", "CanvasLayer")
    label("Kicker", "AI SPRITES  /  ANIMATION STUDY", (32, 22, 700, 25), 14, "(0.48, 0.86, 0.80, 1)")
    label("Title", "SPRITE / MOTION LAB", (30, 52, 950, 55), 40, "(0.85, 0.94, 0.94, 1)")
    label("Subtitle", "黑长直少女 · 逐帧动画试验场", (33, 116, 850, 30), 18)
    button("Skeleton", "骨骼版  / F3", (1160, 80, 235, 46))
    label("StageLabel", "01 / 移动、跳跃与三档射箭", (48, 172, 680, 30), 19)
    label("StageHint", "鼠标位置选择 上 / 中 / 下；左右自动镜像", (48, 213, 880, 28), 15, "(0.40, 0.60, 0.66, 1)")
    rect("Side", (1134, 150, 274, 568), "(0.064, 0.103, 0.126, 1)")
    rect("Accent", (1134, 150, 3, 52), "(0.48, 0.9, 0.80, 1)")
    label("SideTitle", "角色状态", (1158, 173, 220, 32), 22)
    label("Weapon", "01 / 直剑", (1158, 228, 230, 35), 25, "(0.56, 0.95, 0.86, 1)")
    label("State", "待机", (1158, 280, 230, 27), 18)
    label("Aim", "瞄准 / 平", (1158, 324, 230, 27), 16)
    label("Animation", "idle_sword", (1158, 372, 230, 55), 15, "(0.46, 0.68, 0.73, 1)")
    node("Charge", "ProgressBar", "HUD", "offset_left = 1158\noffset_top = 452\noffset_right = 1384\noffset_bottom = 462\nshow_percentage = false\nmouse_filter = 2")
    label("Stats", "", (1158, 487, 230, 88), 17)
    button("Inspect", "逐帧查看 TAB", (1158, 601, 226, 42))
    button("Reset", "重置  R", (1158, 654, 226, 40))
    label("Hint", "落地后左键攻击 · Q 切换武器 · 按住拉弓，松开放箭", (48, 737, 1320, 30), 19)
    for i, (key, caption) in enumerate([("A / D", "横向移动"), ("SPACE", "跳跃 / 落地缓冲"), ("鼠标", "朝向 / 三档瞄准"), ("左键", "挥剑 / 拉弓放箭"), ("Q", "切换剑与弓"), ("TAB", "检查所有动作")]):
        x = 24 + i * 234
        rect(f"KeyCard{i}", (x, 790, 222, 72), "(0.07, 0.115, 0.14, 1)")
        label(f"Key{i}", key, (x+18, 800, 194, 28), 20, "(0.61, 0.93, 0.87, 1)")
        label(f"Caption{i}", caption, (x+18, 834, 194, 24), 14, "(0.45, 0.66, 0.72, 1)")
    label("Footer", "13 组动作 · 104 张原始帧 · 同角色 / 严格侧面 / 左右镜像", (32, 874, 1350, 23), 13, "(0.36, 0.57, 0.65, 1)")
    node("Inspector", "Control", "HUD", "visible = false\noffset_right = 1440\noffset_bottom = 900\nmouse_filter = 0")
    parent = "HUD/Inspector"
    rect("Shade", (0, 0, 1440, 900), "(0.025, 0.041, 0.057, 1)", parent)
    label("Title", "FRAME STUDY / 逐帧检查", (45, 28, 1000, 56), 32, parent=parent)
    label("Hint", "选择动作、暂停或拖动帧序号；TAB 返回操作", (48, 92, 1100, 28), 17, parent=parent)
    items = ["持剑待机", "持剑行走", "持剑跳跃", "挥剑", "持弓待机", "持弓行走", "持弓跳跃", "平射拉弓", "平射释放", "上射拉弓", "上射释放", "下射拉弓", "下射释放"]
    props = 'offset_left = 48\noffset_top = 146\noffset_right = 470\noffset_bottom = 191\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = 19\nitem_count = 13\nselected = 0\n'
    props += "\n".join(f'popup/item_{i}/text = "{i+1:02} {text}"\npopup/item_{i}/id = {i}' for i, text in enumerate(items))
    node("Selector", "OptionButton", parent, props)
    rect("PreviewBackground", (48, 214, 422, 478), "(0.085, 0.13, 0.16, 1)", parent)
    node("Preview", "AnimatedSprite2D", parent, 'position = Vector2(235, 651)\nscale = Vector2(0.95, 0.95)\nsprite_frames = ExtResource("frames")\nanimation = &"idle_sword"\noffset = Vector2(0, -208)')
    node("Baseline", "Line2D", parent, "points = PackedVector2Array(64, 651, 452, 651)\nwidth = 1\ndefault_color = Color(0.4, 0.75, 0.7, 0.7)")
    label("SheetTitle", "对齐后的透明精灵图 / 4 × 2", (525, 150, 800, 40), 20, parent=parent)
    rect("SheetBackground", (516, 214, 876, 438), "(0.12, 0.17, 0.20, 1)", parent)
    node("Sheet", "TextureRect", parent, 'offset_left = 516\noffset_top = 214\noffset_right = 1392\noffset_bottom = 652\ntexture = ExtResource("sheet")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2')
    label("FrameLabel", "FRAME 01 / 08", (525, 680, 800, 40), 20, parent=parent)
    node("Timeline", "HSlider", parent, "offset_left = 525\noffset_top = 739\noffset_right = 1370\noffset_bottom = 772\nmax_value = 7\nstep = 1")
    button("Play", "暂停", (48, 723, 126, 44), parent)
    button("Step", "下一帧", (187, 723, 126, 44), parent)
    button("Mirror", "左右镜像", (326, 723, 144, 44), parent)
    button("Close", "返回操作 / TAB", (48, 800, 422, 46), parent)
    label("Footer", "每帧保留生图原始 RGBA；统一脚底与画布，仅做裁切、对齐和无损打包。", (525, 813, 860, 35), 16, parent=parent)
    connections = [("HUD/Skeleton", "pressed", "_open_skeleton"), ("HUD/Inspect", "pressed", "_toggle_inspector"), ("HUD/Reset", "pressed", "_reset_lab"), (parent+"/Close", "pressed", "_toggle_inspector"), (parent+"/Selector", "item_selected", "_select_animation"), (parent+"/Play", "pressed", "_toggle_preview"), (parent+"/Step", "pressed", "_step"), (parent+"/Mirror", "pressed", "_mirror_preview"), (parent+"/Timeline", "value_changed", "_scrub")]
    footer = "\n".join(f'[connection signal="{sig}" from="{path}" to="." method="{method}"]' for path, sig, method in connections)
    (ROOT / "scenes/sprite_lab.tscn").write_text(header + "\n" + "\n".join(nodes) + "\n" + footer + "\n", encoding="utf-8")
    print("SPRITE_SCENE_AUTHORED")


if __name__ == "__main__":
    build()
