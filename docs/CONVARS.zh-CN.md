# BMB ConVar 与控制台命令参考

[English](CONVARS.md) · [返回 README](../README.zh-CN.md) · [API 参考](API.zh-CN.md)

[Minecraft in GMod | Mobs](https://steamcommunity.com/sharedfiles/filedetails/?id=3774268246)（BMB）创建的全部 ConVar 和控制台命令，按用途分组。

本页根据 **BMB 1.0.0**（2026-11-20 发布的创意工坊版本）的 Lua 源码整理。名字、默认值、取值范围和标志位都用脚本对照源码核对过。说明文字描述的是代码的行为；这些设置项没有逐个在游戏里试过。

调试工具在这个版本之后（2026-11-25）重做过。改动的地方在[调试](#调试)一节里标了*1.0.0 之后*，并对照当天的 BMB 源码核对过。1.0.0 的创意工坊版本里没有这些改动。

## 表格怎么看

- **默认值**是源码里的值。方括号里的范围（例如 `32 [0–256]`）由引擎强制执行。
- **保存**表示这个 ConVar 会存档，重启后值还在。不保存的 ConVar 在服务器或游戏重启后回到默认值。
- **服务端** ConVar 只存在于服务器上。在服务器控制台里设置；单人模式或 listen 服务器的房主也可以直接设置。**客户端** ConVar 是每个玩家自己的设置。
- 以"格"为单位的距离指 Minecraft 方块。一格等于 `BMB.BS` 个 Source 单位（MineMod 默认是 36.5）。

下面大部分服务端设置在生成菜单的 **Utilities > BlockMob Base** 里也有，共六个面板：*BMB Mob Spawning*、*BMB Mob Limits*、*BMB Mob Attributes*、*BMB Fall Damage*、*BMB Climbing* 和 *BMB Fire*。这些面板直接写服务端 ConVar，所以是给房主用的。专用服务器请在服务器控制台或 `server.cfg` 里设置（本页没有在专用服务器上测试过）。

## 目录

- [生物属性](#生物属性)
- [NPC 关系](#npc-关系)
- [生物死亡奖励](#生物死亡奖励)
- [自然刷怪](#自然刷怪)
- [燃烧与阳光](#燃烧与阳光)
- [摔落伤害](#摔落伤害)
- [攀爬](#攀爬)
- [生物改动方块](#生物改动方块)
- [单个生物的设置](#单个生物的设置)
- [方块世界与寻路](#方块世界与寻路)
- [移动与物理](#移动与物理)
- [调试](#调试)
- [客户端显示](#客户端显示)
- [客户端模型调参](#客户端模型调参)
- [性能开关](#性能开关)
- [内部标记](#内部标记)
- [在你自己的生物里使用 ConVar](#在你自己的生物里使用-convar)

## 生物属性

服务端，保存。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_health_scale` | `1` [0.01–100] | 所有 BMB 生物（包括自定义生物）最大生命值的倍率。改动时，活着的生物保持原来的生命百分比。改动会在聊天栏里通知。 |
| `bmb_minecraft_difficulty` | `2` | Minecraft 难度，供那些在 Garry's Mod 里没有对应概念的规则使用：`0` 和平、`1` 简单、`2` 普通、`3` 困难。旋风人、溺尸、鹦鹉、猪灵和掠夺者会读它。其它 addon 可以用 `BMB.ResolveMinecraftDifficultyId` 钩子按生物覆盖。 |
| `bmb_damage_taken_scale` | `1` [0–10] | *1.0.0 之后。*玩家、NPC 和其他非 BMB 生物对 BMB 造成的战斗伤害倍率。 |
| `bmb_damage_dealt_scale` | `1` [0–10] | *1.0.0 之后。*BMB 对玩家、NPC 和其他非 BMB 生物造成的战斗伤害倍率。 |
| `bmb_damage_internal_scale` | `1` [0–10] | *1.0.0 之后。*两只 BMB 生物互相攻击时的伤害倍率。 |

三个滑条都在 **BMB Mob Attributes**。每次命中按攻击者和受击者选一个倍率。投射物按命中时的攻击归属计算，包括反弹火球。环境伤害和非致死中毒继续走各自的规则。

BMB 的生命值是 Minecraft 生命值 × 3.5，再 × `bmb_health_scale`。生物的 `StartHealth` 字段是乘 `bmb_health_scale` 之前的值。

## NPC 关系

*1.0.0 之后。*服务端，保存。三项分别设置，`1` 开启，`0` 关闭。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_native_npc_relations` | `1` | 开启 BMB 与受支持的原版 Source NPC 之间的关系规则和主动索敌。 |
| `bmb_vj_npc_relations` | `1` | 开启 BMB 与 VJ Base SNPC 的适配。 |
| `bmb_drg_npc_relations` | `1` | 开启 BMB 与 DrGBase NextBot 的适配。 |

关闭某项适配后，BMB 的新一轮索敌会停止追加该类 NPC，NPC 会恢复基类自己的关系规则。已经触发的反击继续由各生物的 AI 处理。分类字段和查询方法见 [API 参考](API.zh-CN.md#生物关系)。

## 生物死亡奖励

*1.0.0 之后。*服务端，保存。两项都在 **Utilities > BlockMob Base > BMB Mob Spawning** 的自然消失设置下方。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_mob_death_rewards` | `3` [0–3] | `0` 关闭全部内置死亡奖励，`1` 仅掉落物，`2` 仅经验，`3` 两者都掉。 |
| `bmb_mob_drop_lifetime` | `300` [1–3600] | 新生成的 BMB 死亡掉落物的寿命，以游戏秒计。Minecraft 物品模式每游戏秒计 20 tick。合堆时，MineMod 采用保留下来的那堆的寿命和两堆中较年轻的年龄。 |

设置适用于内置死亡奖励。繁殖经验、鸡蛋和普通 MineMod 掉落物各有自己的规则。自定义生物和掉落钩子见 [掉落物与经验](API.zh-CN.md#掉落物与经验)。

## 自然刷怪

全部是服务端、保存。自然刷怪**默认关闭**。

### 开关和上限

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_spawn_enabled` | `0` | 自然刷怪总开关。 |
| `bmb_spawn_monsters` | `1` | 刷新敌对生物（`monster` 分类）。动物和蝙蝠不受它影响。 |
| `bmb_spawn_bats` | `1` | 刷新蝙蝠。 |
| `bmb_spawn_slimes` | `1` | 在史莱姆区块里刷新史莱姆。 |
| `bmb_spawn_max` | `32` [0–256] | 自然刷出的怪物同时存活的上限。 |
| `bmb_spawn_creature_max` | `10` [0–64] | 自然刷出的动物同时存活的上限。 |
| `bmb_spawn_ambient_max` | `8` [0–64] | 自然刷出的环境生物（蝙蝠）同时存活的上限。 |
| `bmb_spawn_slime_seed` | `0` | 史莱姆区块布局的种子。同一个种子得到的区块永远相同。 |

这三个上限只统计刷怪系统自己刷出来的生物。从生成菜单手动放的不占名额。

### 时机和位置

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_spawn_interval` | `5` [0.5–60] | 怪物和蝙蝠两轮刷新之间的秒数。 |
| `bmb_spawn_creature_interval` | `20` [1–300] | 动物两轮刷新之间的秒数。 |
| `bmb_spawn_per_cycle` | `1` [1–8] | 每轮刷新的怪物数量。一群算一个。 |
| `bmb_spawn_attempts` | `12` [1–64] | 一次刷新尝试里测试的候选位置数。 |
| `bmb_spawn_min_distance` | `20` [1–64] | 生物离玩家最近多少格才能刷新。 |
| `bmb_spawn_max_distance` | `40` [2–128] | 生物离玩家最远多少格可以刷新。 |
| `bmb_spawn_max_light` | `7` [0–15] | 怪物可以刷新的最高光照等级。 |
| `bmb_spawn_allow_approximate_light` | `1` | 方块世界给不出精确光照时，接受它按天空遮挡估算的值。设为 `0` 后，没有精确光照值的位置一律拒绝。 |
| `bmb_spawn_debug` | `0` | 把每一次刷新决策打印到服务器控制台。 |

### 消失

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_spawn_despawn` | `1` | 移除离所有玩家都很远的自然刷新生物。`bmb_spawn_enabled` 为 `0` 时照样运行。 |
| `bmb_spawn_despawn_distance` | `64` [16–512] | 怪物和蝙蝠离所有玩家都超过这么多格时立即移除。 |
| `bmb_spawn_despawn_soft` | `32` [4–256] | 超过这么多格并在那里待满 30 秒后，怪物或蝙蝠每秒有 1/12 的概率被移除。 |
| `bmb_spawn_despawn_creature_distance` | `72` [16–512] | 动物离所有玩家都超过这么多格时移除。动物没有随机消失带。 |

有些生物永远不会被移除：被物理枪抓着的、被调试工具冻结的、正在执行调试移动指令或被强制指定了目标的；以及必须保留的——有名字的、被驯服的、拿着方块的末影人。

### 按类的数量上限

每个上限规定了世界里这一类生物达到多少只之后，刷怪系统就不再补充。和上面的总上限不同，这里统计的是该类所有活着的个体，手动放的也算。设为 `0` 就关闭这一类的自然刷新。取值范围都是 0–64。

| ConVar | 默认值 | | ConVar | 默认值 |
|---|---|---|---|---|
| `bmb_spawn_limit_zombie` | `5` | | `bmb_spawn_limit_sheep` | `3` |
| `bmb_spawn_limit_skeleton` | `4` | | `bmb_spawn_limit_cow` | `3` |
| `bmb_spawn_limit_spider` | `3` | | `bmb_spawn_limit_mooshroom` | `4` |
| `bmb_spawn_limit_cave_spider` | `2` | | `bmb_spawn_limit_pig` | `3` |
| `bmb_spawn_limit_creeper` | `2` | | `bmb_spawn_limit_chicken` | `3` |
| `bmb_spawn_limit_enderman` | `2` | | `bmb_spawn_limit_rabbit` | `3` |
| `bmb_spawn_limit_slime` | `1` | | `bmb_spawn_limit_parrot` | `0` |
| `bmb_spawn_limit_witch` | `2` | | `bmb_spawn_limit_fox` | `4` |
| `bmb_spawn_limit_bat` | `0` | | `bmb_spawn_limit_ocelot` | `3` |
| | | | `bmb_spawn_limit_llama` | `2` |
| | | | `bmb_spawn_limit_goat` | `3` |
| | | | `bmb_spawn_limit_panda` | `2` |

`bmb_spawn_limit_witch` 存在，但这个版本里女巫没有自然刷新条目，所以它不起作用。`bmb_spawn_limit_bat` 和 `bmb_spawn_limit_parrot` 默认是 `0`，也就是说蝙蝠和鹦鹉在你调高之前不会自然刷新。

### 命令

| 命令 | 谁能用 | 作用 |
|---|---|---|
| `bmb_spawn_now [monster\|creature\|ambient]` | 管理员 | 在一名随机的存活玩家附近尝试刷新一次并打印结果，例如 `[BMB spawn] forced monster spawn failed: outside_distance_band`。它无视 `bmb_spawn_enabled` 和 `bmb_spawn_monsters`，但仍然遵守各项上限。分类默认是 `monster`。 |
| `bmb_spawn_status` | 管理员 | 打印刷怪是否开启、三个分类的数量和上限、当前用的是哪个方块世界、一天中的时间和太阳强度。 |

`bmb_spawn_now` 可能打印的失败原因列在 [API 参考](API.zh-CN.md#失败原因)里。

## 燃烧与阳光

全部是服务端、保存。BMB 自己绘制和计时 Minecraft 风格的火焰，不使用引擎的 `Ignite`。

### 燃烧

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_sunlight_damage` | `3` [0–20] | 燃烧中的生物每一跳受到的伤害。名字里虽然有 sunlight，但对所有火源都生效。 |
| `bmb_sunlight_interval` | `1` [0.1–10] | 两跳燃烧伤害之间的秒数。同样对所有火源生效。 |
| `bmb_fire_check_interval` | `0.25` [0.05–2] | 多久更新一次燃烧状态和下面的接触火源。 |
| `bmb_fire_debug` | `0` | 记录燃烧状态、火源和接触伤害。 |

### 阳光

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_sunlight_burn` | `1` | 标记了 `BurnsInDaylight` 的生物白天在露天会着火。 |
| `bmb_sunlight_random_tick` | `1` | 使用 Minecraft 的逐 tick 随机点燃概率。设为 `0` 后，暴露在阳光下的生物在下一次检查时就着火。 |
| `bmb_sunlight_min_strength` | `0.5` [0–1] | 太阳要多强（0 是夜晚，1 是正午）才会点燃生物。 |
| `bmb_sunlight_check_interval` | `0.25` [0.1–2] | 两次日照检查之间的秒数。 |

### 岩浆和火方块

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_fire_lava` | `1` | 岩浆会点燃并伤害生物。 |
| `bmb_fire_lava_damage` | `14` [0–100] | 每一跳岩浆接触伤害。 |
| `bmb_fire_lava_interval` | `0.5` [0.1–10] | 两跳岩浆接触伤害之间的秒数。 |
| `bmb_fire_lava_seconds` | `15` [0–60] | 碰到岩浆后燃烧多少秒。 |
| `bmb_fire_blocks` | `1` | 站在火或灵魂火方块里会点燃并伤害生物。 |
| `bmb_fire_block_damage` | `3` [0–100] | 每一跳火方块接触伤害。 |
| `bmb_fire_block_interval` | `0.5` [0.1–10] | 两跳火方块接触伤害之间的秒数。 |
| `bmb_fire_block_seconds` | `8` [0–60] | 站在火方块里之后燃烧多少秒。 |

设置了 `ENT.FireImmune = true` 的生物不受本节任何一项影响。

## 摔落伤害

全部是服务端、保存。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_fall_damage` | `1` | 生物受到 Minecraft 风格的摔落伤害。 |
| `bmb_fall_damage_safe_distance` | `3` [0–64] | 生物摔多少格以内不受伤。 |
| `bmb_fall_damage_multiplier` | `3.5` [0–20] | 超出安全距离后每格的伤害。3.5 对应 BMB 放大后的生命值；设为 `1` 就是 Minecraft 的原始数值。 |
| `bmb_fall_damage_block_modifiers` | `1` | 应用 Minecraft 的落点规则：干草块和蜂蜜块 ×0.2，床 ×0.5，史莱姆块 ×0；落进水、细雪或蜘蛛网里不受伤。 |
| `bmb_fall_damage_sound` | `1` | 生物摔伤时播放摔落音效。 |
| `bmb_fall_damage_debug` | `0` | 打印每次摔落的距离、落点方块和伤害。 |

生物可以用 `ENT.FallSafeDistanceCells` 和 `ENT.FallDamageMultiplier` 按类覆盖前两项，也可以用 `ENT.FallDamageImmune = true` 完全免疫。

## 攀爬

服务端。这里是所有生物都有的爬梯子能力。蜘蛛爬墙是另一套，见[蜘蛛爬墙](#蜘蛛爬墙)。

| ConVar | 默认值 | 保存 | 作用 |
|---|---|---|---|
| `bmb_climb` | `1` | 是 | 生物像 Minecraft 里那样，走进可攀爬方块就往上爬。 |
| `bmb_climb_vines` | `0` | 是 | 把藤蔓算作可攀爬。默认关，因为 MineMod 的玩家还不能爬藤蔓。 |
| `bmb_climb_scaffolding` | `0` | 是 | 把脚手架算作可攀爬。默认关，原因同上。 |
| `bmb_climb_debug` | `0` | 否 | 打印攀爬判定。 |

## 生物改动方块

服务端，保存。这是 BMB 版的 Minecraft `mobGriefing` 规则，每种生物一个开关。设为 `0` 后该生物不再改动 MineMod 方块。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_creeper_griefing` | `1` | 苦力怕爆炸破坏方块。 |
| `bmb_enderman_griefing` | `1` | 末影人搬起和放下方块。 |
| `bmb_fireball_griefing` | `1` | 恶魂和烈焰人的火球破坏方块并点火。 |
| `bmb_ravager_griefing` | `1` | 劫掠兽撞碎碰到的树叶。 |
| `bmb_snow_golem_griefing` | `1` | 雪傀儡走过的地方留下雪层。 |
| `bmb_evoker_griefing` | `1` | 唤魔者给蓝色的羊改色。 |

## 单个生物的设置

除非表格里另有说明，都是服务端、保存。

### 苦力怕

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_creeper_fuse_time` | `1.5` | 引信时间（秒）。 |
| `bmb_creeper_swell_start_cells` | `3` | 目标离它不到这么多格时开始膨胀。 |
| `bmb_creeper_swell_continue_cells` | `7` | 目标离它超过这么多格时，已点燃的苦力怕会平息。 |
| `bmb_creeper_damage_scale` | `2.3` | 爆炸对实体伤害的倍率。 |
| `bmb_creeper_explosion_knockback` | `500` | 爆炸把玩家抛出去的力度。 |
| `bmb_creeper_block_damage_scale` | `1.0` | 爆炸对方块伤害的倍率。 |
| `bmb_creeper_step_volume` | `0.35` | 脚步声音量。`0` 为静音。 |

### 史莱姆

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_slime_split_count` | `2` | 大于 1 号的史莱姆死亡时分裂出的小史莱姆数量。 |
| `bmb_slime_hop_dist_scale` | `1` | 跳跃距离的倍率。 |
| `bmb_slime_hop_height_scale` | `1` | 跳跃高度的倍率。 |
| `bmb_slime_hop_interval_scale` | `1` | 两次跳跃之间停顿的倍率。 |
| `bmb_slime_contact_damage_scale` | `1` | 接触伤害的倍率。 |
| `bmb_slime_min_size_damage` | `0` | 最小号史莱姆的接触伤害。 |

### 末影人

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_enderman_teleport_ambient_interval` | `9` | 平静的末影人两次传送之间的平均秒数。 |
| `bmb_enderman_teleport_cooldown` | `0.6` | 两次传送之间的最短时间。 |
| `bmb_enderman_teleport_range` | `12` | 平静的末影人能传送多远（格）。 |
| `bmb_enderman_teleport_reach_range` | `6` | 被激怒的末影人传送到离目标多近的范围内（格）。 |
| `bmb_enderman_teleport_flee_range` | `12` | 躲避弹射物时传送多远（格）。 |
| `bmb_enderman_stare_range` | `64` | 多远以内能察觉玩家的注视（格）。 |
| `bmb_enderman_stare_dot_bias` | `0.025` | 玩家要多精确地看着它的头。越小越严格。 |
| `bmb_enderman_block_take_chance` | `10` | 每次检查有 1/N 的概率搬起一个方块。 |
| `bmb_enderman_block_place_chance` | `1000` | 每次检查有 1/N 的概率放下手里的方块。 |
| `bmb_enderman_block_goal_interval` | `0.10` | 上面两项检查之间的秒数。 |
| `bmb_enderman_block_debug` | `0` | 记录搬起和放置方块的决策。 |

### 狼

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_wolf_retaliate_players` | `1` | 野生的狼会攻击伤害它的玩家。 |
| `bmb_wolf_variant_lock` | *（空）* | 把所有新生成的狼锁定为同一种毛色，可以填名字或从 0 开始的序号。留空则按权重随机。 |
| `bmb_wolf_variant_weight_<variant>` | `1` | 某一种毛色的生成权重。`<variant>` 可以是 `pale`、`spotted`、`snowy`、`black`、`ashen`、`rusty`、`woods`、`chestnut` 或 `striped`。 |

### 山羊和恼鬼

| ConVar | 默认值 | 保存 | 作用 |
|---|---|---|---|
| `bmb_goat_ram_knockback_scale` | `1` [0–10] | 是 | 冲撞把目标撞飞多远的倍率。为 `1` 时成年山羊大约撞飞 5 格。 |
| `bmb_debug_goat_ram` | `0` | 否 | 打印每一次冲撞尝试和它结束的原因。 |
| `bmb_vex_phase_blocks` | `1` | 是 | 恼鬼像 Minecraft 里那样穿过方块飞行。设为 `0` 后和其它生物一样有碰撞。 |

### 蜘蛛爬墙

服务端，保存。这些参数调节 `bmb_spider` 和 `bmb_cave_spider` 的爬墙。速度和距离的单位是 Source 单位，写明"格"的除外。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_spider_climb_spike` | `1` | 蜘蛛会爬墙。 |
| `bmb_spider_climb_speed` | `105` | 爬墙速度。 |
| `bmb_spider_climb_probe_distance` | `42` | 向前探测墙壁的距离。 |
| `bmb_spider_climb_wall_clearance` | `30` | 爬墙时和墙面保持的距离。 |
| `bmb_spider_climb_mantle_forward` | `46` | 翻上顶部时向前迈的距离。 |
| `bmb_spider_climb_mantle_up` | `44` | 向上寻找顶部的距离。 |
| `bmb_spider_climb_mantle_down` | `90` | 向下寻找顶部的距离。 |
| `bmb_spider_climb_mantle_start_below` | `3` | 离边沿多近时开始翻上去。 |
| `bmb_spider_climb_mantle_speed` | `72` | 翻上顶部的速度。 |
| `bmb_spider_climb_timeout` | `7` | 一次爬墙最长持续的秒数。 |
| `bmb_spider_climb_blocked_hold_time` | `3` | 被挡住时扒在边沿上多少秒后放弃。 |
| `bmb_spider_climb_descend_speed` | `88` | 放弃后爬下来的速度。 |
| `bmb_spider_climb_descend_timeout` | `6` | 爬下来最长持续的秒数。 |
| `bmb_spider_climb_giveup_cooldown` | `4` | 放弃后多少秒才会再尝试爬墙。 |
| `bmb_spider_climb_cancel_cooldown` | `1.6` | 追击中取消爬墙后，多少秒才会再爬。 |
| `bmb_spider_climb_chase_active` | `1` | 追击时，主动走向高处目标下方的墙。 |
| `bmb_spider_climb_chase_min_target_up` | `18` | 目标至少比它高这么多，追击才会触发爬墙。 |
| `bmb_spider_climb_chase_wall_dot` | `0.1` | 墙要多正地位于蜘蛛和目标之间。 |
| `bmb_spider_climb_chase_cancel_grace` | `0.45` | 爬墙开始后多少秒内不会因为目标移动而取消。 |
| `bmb_spider_climb_chase_approach_distance` | `260` | 追击中的蜘蛛向前多远寻找可爬的墙。 |
| `bmb_spider_climb_chase_approach_timeout` | `0.45` | 单次走向那面墙最长持续的秒数。 |
| `bmb_spider_climb_chase_start_distance` | `84` | 离墙这么近时立刻开始爬。 |
| `bmb_spider_climb_max_cells` | `6` | 寻路认为可以爬的最高墙（格）。 |
| `bmb_spider_climb_edge_cost` | `2.5` | 每爬一格的寻路代价。越高蜘蛛越倾向于绕路。 |
| `bmb_spider_climb_horizontal_cells` | `2` | 寻路里离墙多少格以内可以起爬。 |
| `bmb_spider_prefer_climb_over_hop` | `0` | 爬墙和跳一格都可行时，优先爬墙。 |
| `bmb_debug_spider_climb` | `0` | 打印爬墙诊断信息。 |

## 方块世界与寻路

服务端。BMB 通过一个适配层读取方块，它有两个后端：真实的 MineMod 世界，和开发用的平面 mock 世界。

| ConVar | 默认值 | 保存 | 作用 |
|---|---|---|---|
| `bmb_use_real_world` | `1` | 是 | MineMod 已加载时使用 MineMod 世界。没加载时 BMB 回退到 mock 世界。 |
| `bmb_use_source_path` | `0` | 是 | 实验性：跟随地图的 navmesh，而不是 BMB 的方块寻路。 |
| `bmb_path_admission` | `2` | 否 | 一个服务器 tick 里最多开始多少次寻路。多出来的生物等下一个 tick。`0` 为不限。 |
| `bmb_block_cache_ttl` | `0.25` [0–5] | 是 | 方块形状查询结果缓存多少秒。`0` 关闭缓存。 |
| `bmb_block_cache_sweep` | `30` [0–300] | 是 | 多少秒整体清空一次这个缓存。`0` 为从不清空。 |
| `bmb_block_cache_max` | `120000` [1000–500000] | 是 | 缓存条目超过这个数量就整体丢弃重建。 |

### Source 地图几何

障碍不只有 MineMod 方块，地图本身的墙和静态模型也是。下面这些设置决定寻路怎么看待它们。

| ConVar | 默认值 | 保存 | 作用 |
|---|---|---|---|
| `bmb_source_geometry` | `1` | 是 | 寻路能看到地图的静态几何。设为 `0` 后只看 MineMod 方块。 |
| `bmb_source_geometry_props` | `1` | 是 | 把静态模型也算作障碍和地面。设为 `0` 后只算世界刷子。 |
| `bmb_source_geometry_inset` | `0.6` [0.2–1] | 是 | 一格需要多宽的连续空隙（格）才算可以通行。 |
| `bmb_source_geometry_support_grace` | `6` [0–18] | 是 | 地面低于格底多少单位以内，仍然算这一格的落脚面。 |
| `bmb_source_geometry_step_allowance` | `28` [0–36] | 是 | 低于这么多单位的障碍不算墙，生物会直接迈上去。 |
| `bmb_source_geometry_cache_max` | `120000` [1000–2000000] | 是 | 几何缓存保留的条目数。 |
| `bmb_source_geometry_debug` | `0` | 否 | 给管理员画出探测结果：红色是障碍，绿色是落脚面。 |
| `bmb_source_geometry_debug_radius` | `5` [1–15] | 否 | 上述可视化的水平半径（格）。 |
| `bmb_source_geometry_debug_height` | `3` [1–15] | 否 | 上述可视化的竖直半径（格）。 |

### 追击调参

服务端，除注明的以外都保存。这些参数调节追击中的生物怎样在"直接冲向目标"和"沿计算出的路径走"之间切换。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_chase_step_up` | `1` | 直接冲向目标时，遇到挡路的一格台阶会跳上去。设为 `0` 后只有沿路径走时才会上台阶。 |
| `bmb_chase_direct_resuppress_time` | `0.6` | 直冲失败后，先沿路径走多少秒再尝试直冲。 |
| `bmb_chase_cliff_memory_cooldown` | `3.0` | 一条被悬崖截断的直线，多少秒后才可以再试。 |
| `bmb_chase_cliff_memory_duration` | `25.0` | 这类失败最长记多久。 |
| `bmb_chase_cliff_memory_move_cells` | `6.0` | 生物自己移动多少格之后才重试那条直线。 |
| `bmb_chase_cliff_memory_target_cells` | `2.0` | 目标移动多少格之后生物才重试那条直线。 |
| `bmb_chase_wall_memory_cooldown` | `0.8` | 一条被墙截断的直线，多少秒后才可以再试。 |
| `bmb_chase_wall_memory_duration` | `3.0` | 这类失败最长记多久。 |
| `bmb_chase_repath_cliff_giveup_time` | `4.0` | 被悬崖挡住多少秒后放弃当前目标。 |
| `bmb_chase_hightarget_unreachable_duration` | `3.0` | 记住"附近高处的目标没有完整路径"多少秒。 |
| `bmb_chase_distance_ttl` | `1` | *不保存。* 离目标远的生物重新寻路的频率更低。设为 `0` 后所有生物用同一个间隔。 |

### 命令

| 命令 | 谁能用 | 作用 |
|---|---|---|
| `bmb_world [mock\|real]` | 管理员 | 切换后端；不带参数时打印当前用的是哪个。 |
| `bmb_block_probe [bx by bz]` | 管理员 | 打印 BMB 在某个方块里看到了什么：对准那个方块，或者传入格坐标。用来查生物为什么不肯走某个地方。 |
| `bmb_source_geometry_flush` | 管理员 | 清空地图几何缓存。 |
| `bmb_mock_show [radius\|all] [seconds]` | 所有人 | 画出你周围的 mock 世界方块。 |
| `bmb_mock_reset` | 所有人 | 在你周围重建 mock 世界。 |

## 移动与物理

服务端。除非在追查某个具体的移动 bug，否则不要动它们。

| ConVar | 默认值 | 保存 | 作用 |
|---|---|---|---|
| `bmb_safety_ceiling_clearance` | `2` | 是 | 生物向前探测墙壁时，头顶以下留出的净空（单位）。 |
| `bmb_ground_unsink` | `1` | 是 | 把陷到地面以下的生物抬回地面。 |
| `bmb_ground_unsink_eps` | `2` | 是 | 脚要低于地面多少单位才会触发上一项。 |
| `bmb_knockback_air_step` | `1` | 是 | 哪些受击会进入击飞滞空处理：`0` 都不进，`1` 只有真正的击飞，`2` 所有向上的击退。 |
| `bmb_landing_step_clamp` | `1` | 是 | 防止落地的生物陷进地面。`0` 为旧行为。 |
| `bmb_mob_separation` | `1` | 否 | 生物之间轻轻互相推开。`0` 关闭整层。 |
| `bmb_mob_separation_nudge` | `0` | 否 | 还把重叠的生物直接传送分开。会破坏客户端的平滑。 |
| `bmb_loco_engine_avoid` | `0` | 否 | 重新启用引擎自带的 NextBot 避障。对新生成的生物生效。 |
| `bmb_flight_smooth` | `1` | 是 | 飞行生物高速飞行时更频繁地更新。 |
| `bmb_flight_smooth_update` | `0.03` | 是 | 上一项使用的更新间隔（秒）。 |
| `bmb_flight_smooth_speed` | `150` | 是 | 飞行速度（单位/秒）超过它时，生物才要求上述加速更新。 |
| `bmb_flight_tick_move` | `1` | 是 | 每个服务器 tick 都移动飞行生物。 |
| `bmb_lifecycle_drive_per_tick` | `0` | 否 | 每个 tick 都下发繁殖、被食物吸引、跟随中的动物的移动。 |
| `bmb_lifecycle_drive_steer` | `1` | 否 | 上述动物先转向目标再走。 |

### 物体砸中生物

服务端，保存。砸中生物的物体按动量造成伤害。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_physics_impact_min_speed` | `90` | 比这更慢的物体被忽略。 |
| `bmb_physics_impact_min_momentum` | `18000` | 动量低于它不造成伤害。 |
| `bmb_physics_impact_momentum_scale` | `0.00026` | 超出上述阈值后，每单位动量的伤害。 |
| `bmb_physics_impact_max_damage` | `30` | 单次撞击的最大伤害。 |

## 调试

### 最常用的两个

| ConVar | 默认值 | 位置 | 作用 |
|---|---|---|---|
| `bmb_debug_hud` | `0` | 客户端，保存 | 在每只 BMB 生物头顶画两行字：类名、生命值、状态和移动模式；然后是速度、期望速度、到目标的距离和路径节点。每次跳方块之后还会短暂出现第三行。 |
| `bmb_freeze` | `0` | 服务端，不保存 | 把所有 BMB 生物定在原地。它们的 AI 停止运行，但仍然会受伤。 |

只有当某个玩家开着 `bmb_debug_hud` 时，服务器才会发送 HUD 需要的额外数据。

### 日志开关

服务端。每个开关都往服务器控制台打印。除注明的以外都会保存，所以用完记得关。

| ConVar | 记录什么 |
|---|---|
| `bmb_debug_chase` | 追击决策：找到了完整路径、部分路径还是没有路径，以及哪一道安全检查拦下了移动。 |
| `bmb_debug_melee_knockback` | 每一次近战尝试、命中和击退。 |
| `bmb_debug_ranged` | 每一次射箭及其弹道。 |
| `bmb_debug_flight` | 飞行寻路结果。 |
| `bmb_debug_flight_vel` | 飞行生物的期望速度和实际速度。 |
| `bmb_debug_hop_log` | 每一次跳方块：起跳、最高点和结果。 |
| `bmb_debug_ground_unsink` | 每一次把生物抬回地面。 |
| `bmb_debug_liquid` | 水里的生物的液体接触和浮力。 |
| `bmb_debug_knockback_launch` | *不保存。* 每一次击飞滞空的开始和结束。 |
| `bmb_debug_spider_climb` | 蜘蛛爬墙。 |
| `bmb_flee_sun_debug` | 着火的骷髅为什么去找或不去找阴凉。 |
| `bmb_fireball_debug` | 火球的生成、反弹和命中。 |
| `bmb_entity_interact_debug` | 对生物使用物品的每一步。 |
| `bmb_allay_interact_debug` | 把物品交给悦灵和取回物品。 |
| `bmb_tempt_recompute_debug` | *不保存。* 跟着食物走的动物的目的地更新。 |

有三个命令可以替你拨动日志开关。每个都接受 `0` 或 `1`，默认 `1`。仅管理员可用。

| 命令 | 设置 |
|---|---|
| `bmb_chase_debug` | `bmb_debug_chase` |
| `bmb_melee_knockback_debug` | `bmb_debug_melee_knockback` |
| `bmb_ranged_debug` | `bmb_debug_ranged` |

还有一些日志开关列在各自所属的功能下面：`bmb_spawn_debug`、`bmb_fire_debug`、`bmb_fall_damage_debug`、`bmb_climb_debug`、`bmb_enderman_block_debug`、`bmb_debug_goat_ram`、`bmb_source_geometry_debug` 和 `bmb_held_item_debug`。

另有一个不保存的服务端 ConVar，控制 HUD 的数据来源：

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_debug_nw` | `-1` | `-1` 表示只有当某个玩家开着 HUD 时才发送 HUD 的额外数据。`1` 始终发送，`0` 始终不发送。 |

### 调试命令

仅管理员可用。每个命令作用于你准星对着的 BMB 生物；没有对着的话，作用于 768 单位以内最近的一只。*1.0.0 之后*，BMB Debug 工具选中的那只排在最近的那只前面。

| 命令 | 作用 |
|---|---|
| `bmb_debug_info` | 打印类名、生命值、状态、移动模式、速度、到目标的距离和位置。 |
| `bmb_debug_health [value]` | 设置它的生命值，然后打印同样的一行。1.0.0 直接使用你给的数字；给 0 或更小的数会留下一只没有生命值却没有死的生物。*1.0.0 之后*数值被限制在 1 到 100000 之间。 |
| `bmb_debug_speed [walk] [run] [accel] [decel]` | 设置它的速度并打印出来。没写的值不改。 |
| `bmb_debug_move [seconds] [speed]` | 让它沿直线走。默认以它的奔跑速度走 5 秒。在 1.0.0 里它朝生物自己面对的方向走：有个 bug 使你看的方向没有被用上。*1.0.0 之后*它朝你看的方向走。 |
| `bmb_debug_stop` | 取消调试移动或强制逃跑。 |
| `bmb_debug_flee [seconds]` | 让它惊慌逃跑。只对有惊慌行为的生物（被动动物）有效。 |

### BMB Debug 工具

工具枪在 *BlockMob Base* 分类下有一个 **BMB Debug** 工具。左键选中一只生物。在地面上按右键让选中的生物走过去。R 键取消它的指令。其余功能的按钮都在工具面板里。

面板上的滑条是客户端 ConVar，保存：

| ConVar | 默认值 | 设置什么 |
|---|---|---|
| `bmb_debug_move_speed` | `120` | 右键移动指令的速度。 |
| `bmb_debug_flee_duration` | `5` | 强制逃跑的秒数。 |
| `bmb_debug_edit_health` | `20` | 要应用的生命值。 |
| `bmb_debug_edit_walk` | `70` | 要应用的行走速度。 |
| `bmb_debug_edit_run` | `145` | 要应用的奔跑速度。 |
| `bmb_debug_edit_accel` | `240` | 要应用的加速度。 |
| `bmb_debug_edit_decel` | `260` | 要应用的减速度。 |
| `bmb_debug_action_damage` | `7` | *1.0.0 之后。*`hurt` 动作的伤害。 |
| `bmb_debug_action_fire_seconds` | `8` | *1.0.0 之后。*`ignite` 动作的燃烧秒数。 |

面板上的按钮对选中的生物执行下面这些命令。仅管理员可用。

| 命令 | 作用 |
|---|---|
| `bmb_tool_stop` | 取消它的指令。 |
| `bmb_tool_force_flee` | 让它惊慌逃跑 `bmb_debug_flee_duration` 秒。 |
| `bmb_tool_toggle_ignore_players` | 切换它是否无视玩家。 |
| `bmb_tool_toggle_freeze` | 冻结或解冻这一只生物。 |
| `bmb_tool_force_aggro` | 让它攻击你。 |
| `bmb_tool_force_aggro_pick` | 让它攻击你下一次左键点中的生物。再执行一次取消。 |
| `bmb_tool_apply_health` | 应用 `bmb_debug_edit_health`。 |
| `bmb_tool_apply_speed` | 应用四个速度滑条。 |
| `bmb_tool_action <name>` | *1.0.0 之后。*让它做一件事，比如挨一下打或者着火。可用的名字列在下面。 |

#### 1.0.0 之后的改动

调试工具在 2026-11-25 重做过。这一小节，以及上面所有标了*1.0.0 之后*的条目，描述的是那天之后的 BMB 源码。1.0.0 的创意工坊版本里都没有。如果你的控制台不认识 `bmb_tool_action`，说明你的 BMB 还没有这些改动。

**移动指令。** 在 1.0.0 里，用右键派出去的生物可能走到一半就放弃。现在的指令是这样工作的：

- 只有站到目标所在的那一层才算到达。从目标的正下方或正上方走过不再让指令结束。飞行生物和以前一样只看水平距离。
- 连续 3.5 秒没有进展，并且已经连着三次尝试都没有进展，它才放弃。连续 14 秒没有进展时，不管尝试了几次都放弃。
- 进展指的是比这条指令期间任何时候都更靠近目标。沿着路径又走出至少一格也算，但在没有更靠近的情况下最多算 45 秒，这样绕路不会被当成卡住。
- 再按一次右键，哪怕点的是同一个位置，指令也会重新开始。
- 指令最早在右键之后 120 秒到期，并且不会早于最近一次进展之后 8 秒。这一点和 1.0.0 相同。

**提示信息。** 指令没到目标就结束时，下指令的玩家会在聊天栏里收到说明：生物放弃了（附剩余距离和它最后的移动模式）、指令超时了，或者蜘蛛开始爬墙（爬墙会丢掉指令）。提前停下的 `bmb_debug_move` 行走同样会说明原因。右键时还会立刻提示下面几种情况：

- 你点的位置 4 格以内没有生物能站的方块。这时生物会直接朝那个点走，多半走不到；
- 生物处于冻结中。解冻后它才出发，前提是指令到那时还没到期；
- 生物是被命令坐下的宠物。先让它站起来。

**屏幕显示。** 手持 BMB Debug 工具或物理枪时，只要指令还有效，选中生物的目标格会用绿色线框标出，并有一条线从生物连过去。线框标的是指令真正指向的位置，也就是工具把它挪到生物能站的方块之后的位置。指令结束后的 10 秒内，屏幕底部的 *Selected* 一行会显示 `move:` 和下面的某个结果：

| 结果 | 含义 |
|---|---|
| `arrived` | 到达了目标。 |
| `no_progress` | 放弃了。 |
| `expired` | 指令超时。 |
| `stopped` | 你用 R 键、`bmb_tool_stop` 或 `bmb_debug_stop` 取消了它。 |
| `climb` | 蜘蛛开始爬墙。 |
| `cancelled` | 别的命令接管了这只生物：强制逃跑、强制攻击或坐下。 |
| `done` | 一次 `bmb_debug_move` 行走走满了时间。 |
| `unsafe`、`blocked`、`stuck` | 一次 `bmb_debug_move` 行走提前停下：前方不安全、生物没有前进，或者引擎报告它卡住了。 |

靠步行移动的生物挂在方块的角上时，会先被挪回它所在那一格的中间。这期间它的移动模式显示为 `debug_recenter`。

**动作。** `bmb_tool_action <name>` 让选中的生物做一件事。名字写错时会打印可用的名字。面板上*应用移动调参*按钮的下面，每个名字都有一个按钮。

| 名字 | 作用 |
|---|---|
| `hurt` | 打它一下，伤害为 `bmb_debug_action_damage`。这是一次由你造成的普通攻击，所以它的反应和平时挨打一样。如果这一下被无视了（生物在不到半秒前刚挨过打，或者免疫），会告诉你。 |
| `kill` | 通过同一条伤害流程杀死它。无视这次伤害的生物不会死；半秒后再试一次。 |
| `ignite` | 把它点燃 `bmb_debug_action_fire_seconds` 秒。免疫火焰的生物点不着。 |
| `extinguish` | 把火扑灭。 |
| `tame` | 驯服它，主人是你。只对能驯服的生物有效：狼、猫和鹦鹉。 |
| `sit` | 让已驯服的宠物坐下；它正坐着的话就让它站起来。坐下会丢掉它的移动指令。 |

命令接受的伤害范围是 1 到 100000，秒数范围是 1 到 120。面板上的两个滑条分别到 200 和 60 为止。

### 其它命令

| 命令 | 谁能用 | 作用 |
|---|---|---|
| `bmb_spawn_sleeping_cat` | 管理员 | 在你瞄准的位置生成一只冻结的、趴着的猫。截图用。 |
| `bmb_spawn_sleeping_fox` | 管理员 | 生成一只冻结的、睡着的狐狸。 |
| `bmb_spawn_sitting_camel` | 管理员 | 生成一只冻结的、坐着的骆驼。 |
| `bmb_villager_reputation` | 所有人 | 打印附近的村民对你的看法。 |
| `bmb_fire_status` | 客户端 | 打印火焰材质和燃烧中生物的状态。 |
| `bmb_mc_light_debug` | 客户端 | 打印给生物打光用到的数值。 |

## 客户端显示

客户端，除注明的以外都保存。

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_language` | `auto` | BMB 菜单和消息的语言：`auto` 跟随游戏语言，也可以填 `en` 或 `zh`。 |
| `bmb_fire_max_distance` | `2000` | 距离超过这么多单位的生物不画火焰。`0` 为始终绘制。 |
| `bmb_fire_force` | `0` | *不保存。* 给所有生物画上火焰，测试用。 |
| `bmb_cl_bone_far_distance` | `1500` | 距离超过这么多单位的生物，骨骼每秒只更新约 15 次，而不是每帧。`0` 为始终每帧更新。 |
| `bmb_depth_pass_model_only` | `1` | 在深度 pass（环境光遮蔽、手电筒阴影）里只画裸模型。`0` 为旧行为。 |
| `bmb_mc_light_unit_exposure` | `1` | 用固定曝光绘制受方块光照的生物，和 MineMod 的地形一致。 |
| `bmb_mc_light_gain` | `1` | 上一项开启时，受方块光照的生物的亮度倍率。 |
| `bmb_mc_effect_light_pbr` | `1` | 使用 MineMod 的 PBR 包时，BMB 的粒子按生物的打光方式打光。 |
| `bmb_mc_effect_unit_exposure` | `1` | 受方块光照的粒子也用固定曝光绘制。 |

## 客户端模型调参

客户端，保存。这些 ConVar 用来摆放生物手里拿的东西，以及调整少数几个程序化动画。BMB 自己调好的值已经烘焙成默认值；这些 ConVar 是为了让作者能在游戏里调模型而保留的。它们只影响你自己屏幕上看到的画面。

### 手持物

每个配置有七个 ConVar：`<prefix>_pos_x`、`<prefix>_pos_y`、`<prefix>_pos_z`、`<prefix>_ang_p`、`<prefix>_ang_y`、`<prefix>_ang_r` 和 `<prefix>_scale`。有些配置还有左撇子版本，名字是 `<prefix>_lefthand_<field>`。

| 前缀 | 物品 |
|---|---|
| `bmb_pigman_sword`、`bmb_pigman_spear`、`bmb_pigman_spear_chase` | 僵尸猪灵的剑和矛 |
| `bmb_piglin_sword`、`bmb_piglin_spear`、`bmb_piglin_spear_chase`、`bmb_piglin_crossbow` | 猪灵的武器 |
| `bmb_piglin_brute_axe` | 猪灵蛮兵的斧 |
| `bmb_drowned_trident`、`bmb_drowned_fishing_rod`、`bmb_drowned_shell` | 溺尸的物品 |
| `bmb_pillager_crossbow` | 掠夺者的弩 |
| `bmb_vindicator_axe` | 卫道士的斧 |
| `bmb_wither_sword` | 凋灵骷髅的剑 |
| `bmb_allay_item`、`bmb_allay_block` | 悦灵拿着的东西 |
| `bmb_panda_item` | 熊猫拿着的东西 |

| 命令 | 作用 |
|---|---|
| `bmb_held_item_dump [profile]` | 打印某个配置当前的值。看着那只生物，或者传入配置名。 |
| `bmb_held_item_reset [profile]` | 把某个配置恢复成默认值。 |
| `bmb_held_item_debug` | 这是一个 ConVar，默认 `0`，不保存。打印手持物没有画出来的原因。 |

### 其它挂件和姿势

| ConVar | 默认值 | 调节什么 |
|---|---|---|
| `bmb_bow_off_x`、`bmb_bow_off_y`、`bmb_bow_off_z`、`bmb_bow_ang_p`、`bmb_bow_ang_y`、`bmb_bow_ang_r` | `0` | 骷髅的弓的额外偏移和旋转。 |
| `bmb_bow_scale` | `1` | 骷髅的弓的缩放。 |
| `bmb_enderman_block_forward_cells`、`bmb_enderman_block_lateral_cells`、`bmb_enderman_block_vertical_cells` | `0` | 末影人搬着的方块的偏移（格）。 |
| `bmb_enderman_block_scale` | `0.5` | 那个方块的大小（格）。 |
| `bmb_enderman_scary_head_x`、`_y`、`_z` | `0`、`11.4`、`0` | 末影人尖叫脸的头部偏移。 |
| `bmb_enderman_scary_hat_x`、`_y`、`_z` | `0`、`-11.4`、`0` | 那张脸的帽子层偏移。 |
| `bmb_enderman_creepy_jitter_scale` | `0.012` | 被激怒的末影人抖动多大（格）。 |
| `bmb_enderman_creepy_angle_jitter` | `0.2` | 它的轮廓抽动多大（度）。 |
| `bmb_snow_golem_pumpkin_x`、`_y`、`_z`、`_pitch`、`_yaw`、`_roll`、`_scale` | `0`、`5.5`、`0`、`-90`、`0`、`-90`、`0.625` | 雪傀儡的南瓜的位置。 |
| `bmb_vex_sword_x`、`_y`、`_z`、`_pitch`、`_yaw`、`_roll`、`_scale` | 调好的值 | 恼鬼的剑的位置。 |
| `bmb_wolf_body_offset_*`、`bmb_wolf_upper_body_offset_*`、`bmb_wolf_tail_offset_*` | `0` | 狼的三根骨骼的偏移。每根都有 `rot_x`、`rot_y`、`rot_z`、`pos_x`、`pos_y` 和 `pos_z`。 |
| `bmb_rabbit_head_*`、`bmb_rabbit_ears_*`、`bmb_rabbit_frontlegs_*`、`bmb_rabbit_backlegs_*`、`bmb_rabbit_tail_*` | 调好的值 | 兔子五组骨骼的偏移。每组都有 `pos_x`、`pos_y`、`pos_z`、`pitch`、`yaw` 和 `roll`。 |

| 命令 | 作用 |
|---|---|
| `bmb_enderman_block_dump`、`bmb_enderman_block_reset` | 打印或重置搬运方块的设置。 |
| `bmb_snow_golem_attachment_dump`、`bmb_snow_golem_attachment_reset` | 打印或重置南瓜的设置。 |
| `bmb_vex_sword_dump`、`bmb_vex_sword_reset` | 打印或重置恼鬼剑的设置。 |

### 蜘蛛腿

| ConVar | 默认值 | 作用 |
|---|---|---|
| `bmb_spider_leg_animation` | `1` | 给蜘蛛腿做动画。 |
| `bmb_spider_leg_swing_max` | `15` | 腿前后摆动的幅度。 |
| `bmb_spider_leg_lift_max` | `10` | 腿抬起的幅度。 |
| `bmb_spider_leg_frequency` | `1` | 步伐节奏的倍率。 |
| `bmb_spider_leg_phase_a` | `0` | A 组腿的相位（弧度）。 |
| `bmb_spider_leg_phase_b` | `3.1416` | B 组腿的相位（弧度）。 |
| `bmb_spider_leg_phase_step` | `0.7854` | 从前腿到后腿的相位步进（弧度）。 |
| `bmb_spider_leg_lift_phase` | `0` | 抬腿在一步之中的相位偏移。 |
| `bmb_spider_leg_swing_axis` | `0` | 摆动的轴：`0` pitch、`1` yaw、`2` roll。 |
| `bmb_spider_leg_lift_axis` | `2` | 抬腿的轴，编号同上。 |
| `bmb_spider_leg_solo` | `0` | 只给一条腿做动画，`1` 到 `8`。`0` 为全部。 |
| `bmb_spider_leg_axis_test` | `0` | 让一条腿绕某个轴固定在一个角度：`1` pitch、`2` yaw、`3` roll。 |
| `bmb_spider_leg_axis_test_leg` | `8` | 上述测试用哪条腿。 |
| `bmb_spider_leg_axis_test_angle` | `35` | 测试角度。 |
| `bmb_spider_leg_debug_tuning` | `0` | *不保存。* 使用实验性的调参，而不是发布版的姿势。 |
| `bmb_spider_leg<N>_group` | 每条腿不同 | 第 N 条腿（`0` 到 `7`）的步态分组：`0` 是 A，`1` 是 B。 |
| `bmb_spider_leg<N>_swing_offset` | `0` | 给第 N 条腿加上的固定摆动角。 |
| `bmb_spider_leg<N>_lift_offset` | 每条腿不同 | 给第 N 条腿加上的固定抬腿角。 |
| `bmb_spider_leg<N>_phase_offset` | `0` | 给第 N 条腿加上的相位（弧度）。 |

## 性能开关

这些开关是为了让作者对比某条代码路径开启和关闭优化时的表现。除注明的以外都不保存。请保持默认值。

| ConVar | 默认值 | 位置 | 开关什么 |
|---|---|---|---|
| `bmb_safety_memo` | `1` | 服务端 | 前方安全检查的结果在几个 tick 内复用。 |
| `bmb_carrot_reuse` | `1` | 服务端 | 路径前瞻点的可见性结果复用。 |
| `bmb_surface_profile_fast` | `1` | 服务端 | 方块适配层里完整方块的快速路径。 |
| `bmb_surface_walk_context` | `1` | 服务端 | 寻路的一步之内复用方块形状。 |
| `bmb_p1` | `1` | 服务端 | Think 维护优化的总开关。 |
| `bmb_p1_<name>` | `1` | 服务端 | 其中的一部分。`<name>` 可以是 `context`、`lookat`、`separation`、`climb`、`climb_window`、`liquid`、`unsink`、`maintenance`、`ambient`、`lookat_decision`、`liquid_gate`、`unsink_gate`、`climb_gate`、`activity` 或 `context_args`。 |
| `bmb_p1_entity_table` | `0` | 服务端 | 一项实验，因为实测更慢而关闭。 |
| `bmb_p2` | `0` | 服务端 | 内存分配优化的总开关。默认关：它降低了内存抖动，但提高了平均开销。 |
| `bmb_p2_trace`、`bmb_p2_xyz`、`bmb_p2_profiles`、`bmb_p2_flight` | `1` | 服务端 | 其中的几部分。`bmb_p2` 为 `0` 时不起作用。 |
| `bmb_p2_closures`、`bmb_p2_slice` | `0` | 服务端 | 实测更慢的几部分。 |
| `bmb_cl_anim_pose_reuse` | `1` | 客户端，保存 | 复用动画姿势表，而不是每帧新建。 |

### 性能计数器

| 名字 | 类型 | 默认值 | 位置 | 作用 |
|---|---|---|---|---|
| `bmb_perf` | ConVar | `0` | 服务端，保存 | 每隔 `bmb_perf_interval` 秒打印一次 BMB 服务端计数器的摘要。 |
| `bmb_perf_interval` | ConVar | `5` [1–60] | 服务端，保存 | 两次摘要之间的秒数。 |
| `bmb_perf_deep` | ConVar | `0` | 服务端 | 另外给生物 Think 的每一段单独计时。它本身也有开销，只在测量时开。 |
| `bmb_perf_report` | 命令 | | 管理员 | 立即打印服务端计数器。 |
| `bmb_perf_reset` | 命令 | | 管理员 | 重置服务端计数器。 |
| `bmb_cl_perf` | ConVar | `0` | 客户端，保存 | 客户端计数器：`0` 关，`1` 开，`2` 还统计骨骼写入次数。 |
| `bmb_cl_perf_interval` | ConVar | `5` | 客户端，保存 | 两次客户端摘要之间的秒数。 |
| `bmb_cl_perf_report` | 命令 | | 客户端 | 立即打印客户端计数器。 |
| `bmb_cl_perf_reset` | 命令 | | 客户端 | 重置客户端计数器。 |

## 内部标记

BMB 用自己的 ConVar 记录"旧默认值已经迁移过一次"。不要去设置它们；改动其中一个会让 BMB 再次覆盖对应的设置。

- 服务端：`bmb_spawn_limits_v2_migrated`、`bmb_spawn_limits_v3_migrated`、`bmb_spawn_distance_v2_migrated`、`bmb_spawn_default_off_migrated`、`bmb_sunlight_fire_v2_migrated`、`bmb_sunlight_fire_v3_migrated`、`bmb_sunlight_fire_v4_migrated`、`bmb_sunlight_fire_v5_migrated`、`bmb_fire_block_damage_v2_migrated`。
- 客户端：`bmb_language_auto_migrated`、`bmb_held_item_defaults_version`、`bmb_pigman_spear_split_migrated`、`bmb_pigman_spear_chase_pitch_migrated`、`bmb_panda_item_grip_20261110`、`bmb_snow_golem_pumpkin_defaults_version`、`bmb_vex_sword_defaults_version`。

## 在你自己的生物里使用 ConVar

**读取 BMB 的设置**用 `GetConVar`。要判断 `nil`，因为没装 BMB 或者在另一端时，这个 ConVar 不存在：

```lua
local difficulty = GetConVar("bmb_minecraft_difficulty")
local hard = difficulty and difficulty:GetInt() >= 3
```

**给你的生物加上自己的自然刷新上限和开关。** `BMB.NaturalSpawn.Register` 接受两个 ConVar 的*名字*，ConVar 本身由你自己创建：

```lua
if SERVER then
    CreateConVar("yourname_spawn_frost_zombie", "1", FCVAR_ARCHIVE, "Spawn Frost Zombies naturally.")
    CreateConVar("yourname_spawn_limit_frost_zombie", "4", FCVAR_ARCHIVE, "Most Frost Zombies in the world.", 0, 64)
end

BMB.NaturalSpawn.Register("yourname_frost_zombie", {
    category = "monster",
    weight = 8,
    enabledConVar = "yourname_spawn_frost_zombie",
    limitConVar = "yourname_spawn_limit_frost_zombie",
})
```

刷怪系统每次挑选类的时候都会按名字读取这两个 ConVar。上限为 `0` 时你的生物不再自然刷新。如果叫这个名字的 ConVar 不存在，对应的选项被忽略。这段代码是照着 BMB 源码写的，没有在游戏里跑过。

**你自己的 ConVar 用你自己的前缀**，不要用 `bmb_`。将来 BMB 出了同名的 ConVar 会和你的冲突。

**哪些设置已经自动覆盖你的生物。** 继承自 BMB 某个类的自定义生物就是 BMB 生物，所以下面这些不用做任何事就对它生效：`bmb_health_scale`、`bmb_freeze`、`bmb_debug_hud`、调试命令和调试工具、摔落伤害、燃烧与阳光、攀爬，以及移动和寻路的设置。按生物分的设置（`bmb_creeper_*`、`bmb_slime_*` 等）只有在你继承那种生物时才生效。
