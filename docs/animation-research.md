# Spine 分件角色如何行动更自然

本次研究服务于黑长直角色的严格侧视重做。优先级是接触位置、可读的关键姿势、动作节奏，最后再添加头发和裙摆的跟随运动。增加骨骼或关键帧数量本身不能保证自然；素材的视角、关节覆盖和轴心必须先正确。

## 资料与本工程的取舍

| 来源 | 资料中的要点 | 本工程如何采用 |
| --- | --- | --- |
| Kovar、Gleicher、Schreiner，2002，[Footskate Cleanup for Motion Capture Editing](https://research.cs.wisc.edu/graphics/Gallery/kovar.vol/Cleanup/cleanup.pdf)，SCA，97–104 页，[DOI](https://doi.org/10.1145/545261.545277) | 运动编辑后的脚滑需要接触约束处理；约束切换要平滑，腿接近伸直时要防止膝部突跳。 | 在地面空间设计脚底轨迹，再离线求解两段腿骨、烘焙关键帧。仅采用接触和连续性原则，没有复现论文完整算法，也未采用其可变腿长处理。 |
| Spine 官方 [IK constraints](https://esotericsoftware.com/spine-ik-constraints) | IK 从末端目标求解骨链；softness 可缓和接近完全伸直时的突变。 | 脚底和手的接触点先确定，再求肩肘或髋膝角度。采用固定骨长，并约束目标在可达范围内；这里没有运行 Spine IK，也没有实现其 softness 算法。 |
| Spine 官方 [Animating](https://esotericsoftware.com/spine-animating) 与 [Anticipation](https://esotericsoftware.com/blog/Anticipation-Animating-with-Spine-7) | 先做好主要姿势，再调整时序和过渡；游戏中的预备动作需要兼顾输入响应。 | 剑击用明确的预备、发力、随势和恢复姿势，发力段快于恢复段。先检查轮廓、手腕与剑的位置，再增加细小运动。 |
| Spine 官方 [Weights](https://esotericsoftware.com/spine-weights)、[Meshes](https://esotericsoftware.com/spine-meshes) | 网格拓扑和权重决定弯曲效果；绑定后应测试最大运动范围。 | 肢体端部预留遮挡区，手腕和脚踝分开。长发采用连续网格和 3 段权重，避免断开的发片；仍需在大幅姿势中检查轮廓和穿插。 |
| Spine 官方 [Follow through and overlapping action](https://esotericsoftware.com/blog/Follow-through-and-overlapping-action-Animating-with-Spine-8) | 不同部位错开启动和停止，可表现惯性与柔软程度。 | 裙摆、发中和发尾使用不同相位、小幅跟随；不让每个部位同时向同一方向摆动。 |
| Godot 4.6 [Cutout animation](https://docs.godotengine.org/en/4.6/tutorials/animation/cutout_animation.html)、[2D skeletons](https://docs.godotengine.org/en/4.6/tutorials/animation/2d_skeletons.html) | 原生节点可组织分件，骨骼与多边形权重可驱动变形。 | 使用 `.tscn` 中的 Bone2D、Sprite2D、Polygon2D 和 AnimationPlayer；编辑器中可逐个调整，不依赖 Spine 运行库。 |

Godot 4.6 的 [SkeletonModification2DTwoBoneIK](https://docs.godotengine.org/en/4.6/classes/class_skeletonmodification2dtwoboneik.html) 标为 Experimental。本次平地、固定动作范围适合离线计算：求解结果保存为普通动画轨道，便于在编辑器中审查和修改。将来若加入斜坡、攀爬或移动目标接触，再评估运行时 IK 的必要性。

## 实际修改

**统一素材与关节。** 重新分别生成 16 类右向侧面素材；头、躯干、裙摆、四种手型、鞋和武器都有独立文件。关节轴心放在重叠区域，前臂不再连着固定手型，小腿不再连着固定鞋。近远侧肢体使用独立骨链；同款贴图通过层级和轻微明暗区分。左右朝向由整个绑定镜像，避免混用正面和侧面素材。

**按脚底接触设计步态。** 一周期 0.6 秒，单脚支撑期 0.3 秒；这段时间脚在角色局部向后移动 48 像素，与角色 160 像素/秒的前进抵消。髋部上下运动后重新求解腿角度，脚踝补偿腿的旋转，使支撑鞋底保持水平。抬脚轨迹与支撑段平滑衔接；播放速度跟随实际位移，后退时反向播放。这些参数是本角色的制作选择，不是论文规定的标准值。

**把手与武器当成接触约束。** 剑柄、弓柄分别校准到对应手掌的图像握点；手腕独立旋转，减少前臂贴图被迫承担所有转动。拉弦指尖有独立 `StringNock`，弦和搭箭位置共同跟随它。动作调整后对整段动画采样，避免只在一张截图里对齐。

**给动作明确节奏。** 当前剑击长 0.5 秒：0.11 秒到预备姿势，0.20 秒进入发力姿势，0.29 秒随势，0.50 秒恢复。躯干参与发力，头部做小幅反向补偿；头发和裙摆保持较小的延迟运动。拉弓在 0.8 秒内逐渐增加拉距，释放有短暂回弹。这些时长应继续结合实际操作反馈调节。

## 本轮验收与边界

在 Godot 4.6.3 中通过 43 项玩法检查和 8 项姿势检查，并渲染了[关键姿势图](profile-review.png)与[连续操作视频](profile-motion.mp4)。姿势测试使用贴图内独立测量的握点，不只比较同一节点下的标记。

| 检查 | 本轮结果 |
| --- | --- |
| 匀速支撑期脚底水平漂移，双向镜像 | 最大约 0.0032 px |
| 支撑鞋底与地面高度误差 | 最大约 0.0194 px |
| 整段挥剑中剑柄与手掌偏差 | 最大约 0.852 px |
| 挥剑手腕相对前臂偏转 | 最大约 44.81° |
| 拉弓全程弓柄与手掌偏差 | 最大约 0.045 px |
| 拉弦指尖与弦扣偏差 | 最大约 0.194 px |

以上数字说明所测接触位置保持一致，不是动作自然度的评分。步态测量覆盖匀速循环和镜像，尚未覆盖启停混合中的锁脚：当前启停有 0.12 秒混合。拉弓采用侧视轮廓取舍，远侧肢体长度和遮挡经过风格化调整；它不是人体运动学仿真。长发已有蒙皮，袖子和裙摆仍主要靠刚性分件旋转，没有布料碰撞。后续评审应先看启停、急转、极限瞄准和连续攻击中的滑步、穿插与轮廓，再决定是否增加 IK 或变形网格。
