# 素材来源与生成提示词

本项目角色由内置 image_gen 工具生成；没有使用 CLI 或外部素材。原始图为 1254 × 1254 RGBA，透明像素约 59.47%。工具未严格遵循提示词中的 2048 尺寸，因此按实际尺寸切分。

原图：`assets/operator/parts_atlas.png`。分件：同目录 16 张 PNG。`tools/split_atlas.py` 仅执行网格切分、Alpha 外边距裁切、透明补边及无损保存，不按 RGB 推算透明度。

角色为原创白发兽耳干员；参考明日方舟战斗小人的比例、线条和战术服视觉方向，没有使用现成角色图。项目名指分件骨骼流程；本工程使用 Godot 原生骨骼，不包含 Spine 专有工程或运行库。

## 最终提示词

```text
Use case: stylized-concept
Asset type: ONE production-ready 2D cutout character PARTS ATLAS for Godot Skeleton2D, not animation frames. Native transparent RGBA.
Create a square 2048 by 2048 pixel texture atlas, precisely 4 columns by 4 rows, 16 equal square cells, each cell contains EXACTLY ONE separated part. No drawn grid, no labels, no text. Generous transparent gap in every cell; no overlap or crossing cell boundaries.
Subject: an original female chibi tactical operator, white/silver short hair, white wolf ears, amber eyes, charcoal black tactical jacket and fitted shorts, white accents, restrained luminous cyan trim, black gloves, dark boots. Arknights-inspired in-game chibi battle sprite proportions, clean confident dark contours, detailed anime cel shading, high readability. Side-view game: all visible surfaces consistently face RIGHT in subtle three-quarter side profile. Cute serious expression. Not a known character.
The exact row-major contents:
ROW 1: (1) HEAD ONLY with face, bangs and both wolf ears, no neck/body, looking right; (2) REAR HAIR ONLY silver rear bob hair mass with side locks, hidden central scalp filled in; (3) TORSO ONLY including neck, jacket body, waist belt, shorts/hip, but NO head, NO arms, NO legs, silhouette complete behind limbs; (4) one separate flowing split black COAT TAIL with cyan lining, hanging downward, usable behind hip.
ROW 2: (5) FAR upper arm sleeve, shoulder at top elbow at bottom, straight vertical; (6) FAR forearm including clenched gloved hand, elbow top hand bottom, straight vertical; (7) NEAR upper arm sleeve shoulder top elbow bottom, straight vertical; (8) NEAR forearm including clenched weapon-gripping gloved hand elbow top hand bottom, straight vertical.
ROW 3: (9) FAR thigh, short upper leg, hip at top knee bottom, straight vertical; (10) FAR lower leg INCLUDING BOOT, knee at top sole bottom and boot toes pointing right; (11) NEAR thigh, short upper leg, hip top knee bottom; (12) NEAR lower leg INCLUDING BOOT, knee top sole bottom, boot toes right.
ROW 4: (13) tactical SWORD single complete weapon, straight silver/cyan blade pointing UP, grip at bottom; (14) futuristic RECURVE BOW facing RIGHT, vertical, grip at center, bow tips at top and bottom LEFT and curved riser to RIGHT, dark graphite and cyan, NO bowstring (will be animated in engine); (15) ONE slim complete ARROW horizontal, tail LEFT tip RIGHT, cyan arrowhead and white fletching; (16) ONE separate open gloved HAND with fingers curled in bowstring-pulling gesture, wrist at left fingers at right.
Each part is centered in its own cell and large enough to retain line detail, but parts may have independent scale; consistent design/materials/lighting across all cells. Rigging overlap: rounded filled shoulder, elbow, knee and hip ends, no hollow gaps or exposed cut surfaces; sleeve and joint ends should overlap cleanly. Draw actual complete pieces. Head size visually about 45% of assembled character height; limbs short and chibi. Artwork floats directly on true transparent alpha background, not a painted checkerboard or solid color. No ground plane, no shadows outside parts, no full character preview, no duplicate body assemblies, no border, no text, no logos, no watermark.
```
