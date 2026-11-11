# 黑长直少女素材记录

使用内置 `image_gen` 对第一位角色的图集制作新角色变体，原图只作为格位、画法和武器轮廓参考。白衬衫、深色百褶裙、齐刘海黑长直、紫色眼睛；气质参考千反田爱瑠，角色设计为原创。原有白发角色素材未覆盖。

- 原图：`assets/schoolgirl/parts_atlas.png`，1254 × 1254 RGBA，完全透明像素约 47.66%。
- 独立部件：同目录 16 张 PNG；`parts.json` 记录每个格位与裁切边界。
- 图集的实际横向留白有偏移，切分行边界为 `0, 327, 636, 938, 1254`，避免截断头发和袖口。
- 仅按现有 Alpha 检查留白、切分、补透明边和无损保存；没有按 RGB 重建 Alpha。
- `coat_tail.png` 在该角色中是后裙摆；命名沿用公共骨骼槽位。
- `scenes/schoolgirl_rig.tscn` 继承公共骨骼与动画，保存独立的贴图、轴心、缩放和长发遮挡层级。

重新切分：

```powershell
python tools/split_atlas.py assets/schoolgirl --rows 0 327 636 938 1254
```

## 最终提示词

```text
Use case: precise-object-edit / stylized-concept
Asset type: new character variant of a production 4-by-4 cutout parts atlas for Godot Skeleton2D. True transparent RGBA.
Input image 1 is the EXISTING white-haired wolf-ear operator parts atlas, used as the edit target for its 4x4 layout, cohesive linework, cel shading, chibi proportions, rigging part definitions, and weapon silhouettes.
Create a DIFFERENT original character in a NEW atlas, preserving exactly the same 4 columns x 4 rows and cell order. Replace the character identity and clothing throughout all body parts.
New character: a gentle, curious Japanese schoolgirl with long, sleek, straight jet-black hair, neat straight eyebrow-length bangs, large luminous soft violet eyes, a delicate friendly face with a tiny curious smile, NO animal ears. Her feel is somewhat reminiscent of Eru Chitanda from Hyouka, without being an exact reproduction. Retain the polished Arknights-inspired battle-chibi rendering of the reference. Modest white long-sleeved collared blouse, a small navy ribbon at the collar, dark navy knee-length pleated skirt, black opaque knee-high socks, simple dark brown loafers. Bare natural hands, no gloves, no armor or tactical pouches. All views point RIGHT in a subtle three-quarter side view. The long hair is an important visible silhouette.
EXACT cell contents, row-major:
Row 1: 1 HEAD ONLY including face, bangs and short front side locks; no body, no neck, no animal ears, no long rear curtain (that is in next cell). 2 ONE complete REAR HAIR piece: a crown at the top and a long narrow straight curtain of glossy jet-black hair down to waist level, subtle cool violet highlights, gently tapered straight ends, no face or body, no opening/hole in the middle. 3 TORSO ONLY from neck through the white blouse to the entire dark pleated skirt, no head, arms or legs, with fully drawn hidden areas for joints. 4 A separate dark navy REAR SKIRT PANEL, small trapezoid with vertical pleats, waist at top and hem at bottom, NOT a coat tail.
Row 2: 5 FAR upper arm in white blouse sleeve, shoulder top elbow bottom. 6 FAR forearm in white blouse sleeve and cuff plus closed natural bare hand, elbow top hand bottom. 7 NEAR upper arm in white blouse sleeve. 8 NEAR forearm in white blouse sleeve and cuff plus bare weapon-gripping hand. All limb parts straight vertically, soft round joint ends with enough opaque overlap.
Row 3: 9 FAR thigh, a modest simple skin-tone leg segment with a dark sock band at lower edge, hip top knee bottom. 10 FAR lower leg: black knee-high sock and brown loafer, knee at top sole bottom, toes RIGHT. 11 NEAR thigh matching cell 9. 12 NEAR lower leg with black sock and brown loafer matching cell 10.
Row 4: 13 ONE complete elegant silver straight SWORD with black grip and restrained blue accent, blade UP, grip bottom; keep the reference's exact proportions and orientation. 14 ONE dark graphite and silver RECURVE BOW, tips top and bottom to the LEFT, central grip further RIGHT, exactly the reference orientation and shape, NO STRING; it will be drawn by Godot. 15 ONE complete slim ARROW, horizontal, feathers LEFT, blue tip RIGHT, same reference proportions. 16 ONE small bare HAND with fingers curled in a bowstring-pulling gesture, wrist left fingers right, no glove.
Keep 16 strictly isolated individual parts in a regular square 4x4 grid, exactly one part per cell. Each is centered in its cell with wide transparent gutters, full silhouette inside its cell, none touching adjacent cells. No extra pieces, no assembled character, no labels, no letters, no drawn grid, no white background, no checkerboard, no logos or watermark. A solidly filled crown/back hair mass is essential for clean layering. The head should read as 45% of the assembled chibi height; parts may be independently scaled in their cells. Output genuinely transparent alpha, preserve crisp painted edges and the reference's quality.
```
