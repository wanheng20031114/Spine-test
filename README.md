# Spine-test

用 AI 生成原创角色分件，再用 Godot 4.6 原生骨骼搭建可操作的横版测试场景。

现在有两位可切换角色：白发兽耳战术干员，以及穿白衬衫、深色百褶裙的黑长直少女。新角色的清秀气质参考千反田爱瑠；两人都保持明日方舟战斗小人方向的比例和线条。角色图由内置 image_gen 生成。黑长直角色已按严格侧视重做：16 类分别生成的透明素材、20 个 Bone2D、独立手腕与脚踝、4 种手型，以及连续的长发蒙皮网格。两人的 AnimationPlayer 关键帧都可在编辑器中修改；白发角色保留原有 14 骨骼结构。

默认登场的是黑长直少女，按 **F2** 或点击右侧角色名称按钮切换。

![黑长直少女侧视重做](docs/profile-review.png)

[连续动作演示](docs/profile-motion.mp4) · [动作自然度研究与实施记录](docs/animation-research.md) · [新版素材说明](docs/profile-assets.md)

## 运行

1. 使用 **Godot 4.6.x** 导入本目录的 `project.godot`。
2. 等待素材导入完成，按 **F5** 运行主场景。
3. 向右移动靠近训练靶后挥剑，或切换弓在远处射击。左侧也有训练靶，可验证反向动作。

工程使用 Godot 自带的 2D 骨骼与动画系统，不依赖 Spine 插件、Spine 许可证或第三方运行库；不包含 `.spine` 专有工程。

## 操作

| 操作 | 默认映射 |
| --- | --- |
| 横向移动 | A / D |
| 瞄准和左右朝向 | 鼠标移动 |
| 挥剑 | 剑模式单击鼠标左键 |
| 拉弓 / 放箭 | 弓模式按住左键 / 松开左键 |
| 切换剑和弓 | Q |
| 切换角色 | F2 / 右侧角色名称按钮 |
| 显示或隐藏骨骼辅助线 | F1 |
| 打开或关闭部件预览 | Tab |
| 重置角色、箭矢和命中统计 | R |

所有映射均定义在 **项目 → 项目设置 → 输入映射**，代码通过 action 名称读取。拉弓中可以慢速移动；蓄满约需 0.8 秒，蓄力影响箭速和伤害。切换武器、切换角色、打开部件图或窗口失焦会取消当前攻击。切换角色保留当前位置、所持武器和骨骼显示状态，未选中的角色由 Godot 原生处理模式停用。打开部件图时暂停角色移动和攻击，F2 可直接比较两套素材。

## 修改角色与动画

打开 `scenes/schoolgirl_rig.tscn` 编辑新角色，或打开 `scenes/operator_rig.tscn` 编辑白发角色：

- `Skeleton2D` 下的 `Hips` 是根骨骼，包含躯干、头发、衣摆、两侧腿和手臂。
- 身体和武器分件使用骨骼下的 `Sprite2D`，可直接调整位置、缩放、关节轴心及 Z 层级。新角色的长发使用 `Polygon2D` 和 3 段骨骼权重，避免整片僵硬旋转。
- `Locomotion` 保存 `idle`、`walk`；`Actions` 保存 `sword_idle`、`sword_walk`、`slash`、`bow_ready`、`bow_draw`、`bow_release`。
- 行走与上半身动作使用互不覆盖的动画轨道。新角色步行循环为 0.6 秒，动画速度跟随实际水平位移，后退时反向播放。弓弦是 `Line2D`；新角色的中点跟随拉弦指尖下的 `StringNock` 标记，箭矢从该位置释放。
- 所有节点、靶子和 12 个箭矢实例都预先保存在 `.tscn` 中，游戏运行时不拼装角色节点。

`scenes/schoolgirl_rig.tscn` 是独立的原生场景。近远侧手臂、腿、手腕和脚踝各自控制，复用同款侧面贴图；远侧略暗以区分遮挡。手型按持剑、握弓、拉弦、放松分别切换。`scenes/schoolgirl.tscn` 可单独打开编辑，和白发角色共用操作逻辑。角色名称、移动速度、箭矢贴图和弦扣路径通过场景导出属性配置。

`assets/schoolgirl_profile/` 保存新版独立 PNG、原始 RGBA 图片、裁切坐标和绑定布局；[完整提示词](docs/profile-prompts.json) 随工程保存。新版部件预览是 `scenes/profile_parts.tscn` 中的原生网格。`assets/operator/` 保存白发角色素材，`assets/schoolgirl/` 保留旧黑长直素材作为历史记录；旧版说明见 [白发素材记录](docs/asset-source.md) 和 [旧黑长直素材记录](docs/schoolgirl-assets.md)。

重建新版素材需要 Python 和 Pillow。工具只根据已有 Alpha 裁掉外边距、补透明边，裁切区域内的 RGBA 像素保持不变。场景工具在离线阶段计算两段骨骼姿势并烘焙为原生关键帧，运行时不创建节点。

```powershell
python tools/prepare_profile_art.py
python tools/build_profile_rig.py
```

第二条命令会覆盖 `schoolgirl_rig.tscn`、`profile_parts.tscn` 和 `rig_layout.json`。在编辑器手动调整后，应先提交或保存这些调整，再决定是否重建。

## 验证

在 Windows PowerShell 7 中运行：

```powershell
pwsh -NoProfile -File tools/check.ps1
```

也可指定 Godot 可执行文件：

```powershell
pwsh -NoProfile -File tools/check.ps1 -Godot 'D:\Godot\Godot.exe'
```

检查脚本先导入工程，再运行玩法和新角色姿势检查。43 项玩法检查覆盖原生键鼠映射、双向移动与射击、剑击、蓄力、切换取消、部件面板、失焦、重置，以及两位角色切换后的素材和战斗。8 项姿势检查覆盖匀速支撑脚接触、剑柄与手掌连接、手腕角度、弓柄和拉弦指尖连接、搭箭高度，以及长发网格结构。测试进程限时并自动退出，日志保存在忽略提交的 `.local/` 中。

已在 Godot **4.6.3 stable** / Windows 中通过 51 项检查，并通过 OpenGL 渲染关键姿势和连续操作演示。匀速支撑期的脚底水平漂移约 0.0032 像素，整段剑击的图像握点偏差约 0.852 像素；这些数值验证接触位置，不能代替动作观感评审。启停使用 0.12 秒动画混合，尚未实现跨状态的脚底锁定；当前为固定平地训练场，侧视角色使用左右镜像，未制作斜坡步态和八方向贴图。

直接运行 `tests/profile_review.tscn` 可查看六个关键姿势；`tests/profile_motion.tscn` 会模拟连续键鼠操作并自动退出。其截图与录像流程使用 Godot 原生渲染，参见 [素材与验证说明](docs/profile-assets.md)。

## 采用的 Godot 原生能力

- [Cutout animation](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html)：分件、关节和层级。
- [Skeleton2D](https://docs.godotengine.org/en/4.6/classes/class_skeleton2d.html) / [Bone2D](https://docs.godotengine.org/en/4.6/classes/class_bone2d.html)：原生骨骼。
- [AnimationPlayer](https://docs.godotengine.org/en/4.6/classes/class_animationplayer.html)：编辑器关键帧动画。
- [InputEvent / InputMap](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html)：输入映射与事件分发。
- [CharacterBody2D](https://docs.godotengine.org/en/4.6/classes/class_characterbody2d.html)、[Area2D](https://docs.godotengine.org/en/4.6/classes/class_area2d.html)、[RayCast2D](https://docs.godotengine.org/en/4.6/classes/class_raycast2d.html)：角色移动、近战命中与箭矢连续路径检测。
