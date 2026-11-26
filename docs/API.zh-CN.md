# BMB 自定义生物 API 参考

[English](API.md) · [返回 README](../README.zh-CN.md) · [ConVar 参考](CONVARS.zh-CN.md)

在 [Minecraft in GMod | Mobs](https://steamcommunity.com/sharedfiles/filedetails/?id=3774268246)（BMB）里，自定义生物能设置什么、重写什么、调用什么。请先读 [README](../README.zh-CN.md)：它一步步做出一只能用的生物。本页是你想做得更多时用来查的表。

## 本页的状态

- 除标为*1.0.0 之后*的条目外，本页描述的是 **BMB 1.0.0**，即 2026-11-20 发布的创意工坊版本。这些名字用脚本对照该版本的 Lua 源码核对过；后续新增条目对照更新后的源码核对。
- BMB **还没有稳定的 API**。本页写的是代码现在的行为，不保证以后不变。BMB 每次更新后请重新测试你的生物。
- 本页列出三类东西，依赖它们的风险并不一样：

  | 类别 | 是什么 | 变动的可能 |
  |---|---|---|
  | **字段** | `ENT` 上的数值和开关，例如 `ENT.StartHealth`。 | 最小。BMB 自己的生物也是这么写的。 |
  | **钩子** | 你定义了、BMB 就会在你的生物上调用的函数，例如 `ENT:OnBMBMeleeHit`。 | 不大，理由同上。 |
  | **内部接口** | `BMB.` 下面和实体上你能碰到的其它一切。 | 任何一次更新都可能改。 |

- 本页的大部分内容还在游戏里实际跑过。2026-11-25 用这个版本开了一局单人游戏，运行了页面上的代码示例，并对本页的说法做了 182 项检查，其中 181 项通过。没通过的那一项是关于 `MoveToWorldPosition` 的，[移动方法](#移动方法)一节现在写的是游戏里的实际行为。每个代码示例后面都注明了有没有跑过。
- 没跑过的部分是照源码写的，包括各个字段表、被动动物的钩子、大部分游戏钩子，以及 listen 服务器和专用服务器上的一切。
- 有少数条目标了*1.0.0 之后*。其中 2026-11-25 的条目描述了调试工具重做和村民索敌修复。这些改动已在 BMB 源码中，但不在 1.0.0 的创意工坊版本里。这些条目对照源码核对过，没有为本页做游戏内验证。

## 目录

- [BMB 代码在哪一端运行](#bmb-代码在哪一端运行)
- [类的继承关系](#类的继承关系)
- [生物的一生](#生物的一生)
- [字段](#字段)
- [可以定义的钩子](#可以定义的钩子)
- [可以调用的方法](#可以调用的方法)
- [行为模块](#行为模块)
- [全局函数](#全局函数)
- [自然刷怪](#自然刷怪)
- [生物关系](#生物关系)
- [燃烧](#燃烧)
- [状态效果](#状态效果)
- [方块世界](#方块世界)
- [掉落物与经验](#掉落物与经验)
- [调试工具的指令](#调试工具的指令)
- [BMB 触发的游戏钩子](#bmb-触发的游戏钩子)
- [联网变量](#联网变量)

## BMB 代码在哪一端运行

BMB 的 `lua/autorun/bmb_autorun.lua` 创建全局表 `BMB`。表里有什么取决于在哪一端：

| 在哪里可用 | 表和函数 |
|---|---|
| 服务端和客户端 | `BMB.Version`、`BMB.BS`、`BMB.GetBlockSize`、`BMB.GetHealthScale`、`BMB.ScaleMobHealth`、生物注册表（`BMB.ForEachMob` 等）、`BMB.L`、`BMB.GetLanguage` |
| 仅服务端 | `BMB.Behaviors`、`BMB.NaturalSpawn`、`BMB.MobRelations`、`BMB.NPCRelations`（*1.0.0 之后*）、`BMB.Fire`、`BMB.Status`、`BMB.BlockWorld`、`BMB.Pathfinder`、`BMB.Loot`、`BMB.Targeting` |

Garry's Mod 加载 addon 的方式带来两条时机上的规则：

- **在实体文件里**，`BMB` 已经存在。实体文件在所有 addon 的 autorun 文件之后加载，所以在文件开头用 `BMB.BS` 和 `DEFINE_BASECLASS("bmb_zombie")` 是安全的。
- **在 autorun 文件里**，`BMB` 可能还不存在，因为 addon 的加载顺序没有保证。像示例那样，把注册放进 `InitPostEntity` 钩子里。

生物的逻辑在服务端运行。客户端负责绘制生物和驱动骨骼动画。本页的方法没有特别说明的都是服务端的。

## 类的继承关系

```
base_nextbot
└─ bmb_base_mob                所有生物共用的部分：移动、伤害、死亡、渲染
   ├─ bmb_zombie               近战怪物
   │  ├─ bmb_husk
   │  ├─ bmb_drowned
   │  ├─ bmb_zombie_villager
   │  └─ bmb_zombie_pigman
   ├─ bmb_skeleton             远程怪物
   │  ├─ bmb_stray
   │  ├─ bmb_bogged
   │  ├─ bmb_parched
   │  └─ bmb_wither_skeleton
   ├─ bmb_spider
   │  └─ bmb_cave_spider
   ├─ bmb_slime
   │  └─ bmb_magma_cube
   ├─ bmb_silverfish
   │  └─ bmb_endermite
   ├─ bmb_passive_animal       受伤时惊慌逃跑，平时游荡
   │  ├─ bmb_sheep, bmb_pig, bmb_chicken, bmb_rabbit
   │  ├─ bmb_cow
   │  │  └─ bmb_mooshroom
   │  ├─ bmb_cat, bmb_ocelot, bmb_fox, bmb_goat, bmb_panda, bmb_polar_bear
   │  ├─ bmb_armadillo, bmb_sniffer, bmb_camel, bmb_camel_husk
   │  ├─ bmb_llama, bmb_trader_llama
   │  └─ bmb_villager, bmb_wandering_trader, bmb_copper_golem
   └─ 直接继承 bmb_base_mob：
      bmb_creeper, bmb_enderman, bmb_wolf, bmb_bee, bmb_bat, bmb_witch,
      bmb_blaze, bmb_ghast, bmb_happy_ghast, bmb_phantom, bmb_vex, bmb_allay,
      bmb_parrot, bmb_breeze, bmb_evoker, bmb_vindicator, bmb_pillager,
      bmb_ravager, bmb_piglin, bmb_piglin_brute, bmb_hoglin, bmb_zoglin,
      bmb_iron_golem, bmb_snow_golem, bmb_shulker, bmb_warden, bmb_creaking
```

本示例只用过 `bmb_zombie` 做父类。如果你选别的父类，先读它的文件。要留意这几点：

- **AI 函数。** 每个家族的 `RunBehaviour` 循环都调用一个函数来做决策，要重写的就是它。函数名每个家族不同：`RunBMBZombieAI`（僵尸家族）、`RunBMBSkeletonAI`（骷髅家族）、`RunBMBSpiderAI`、`RunBMBCreeperAI`、`RunBMBSlimeAI`、`RunBMBWolfAI`、`RunBMBEndermanAI` 等等。被动动物没有这样的函数，见[被动动物](#被动动物)。
- **按类名登记的数据。** 有些生物按自己的类名查东西（音效组、幼年模型、掉落表）。子类换了类名就查不到这些条目。僵尸查音效时会退回到 `ENT.Sounds`，所以在僵尸上重写 `ENT.Sounds` 是有效的。
- **代码在哪里。** 较早的生物把所有代码放在 `lua/entities/bmb_<名字>.lua` 里。较新的生物拆分到 `lua/bmb/mobs/<名字>/` 下，实体文件只负责把这些部分包含进来。

## 生物的一生

### 生成

Garry's Mod 会在两端都调用 `ENT:Initialize()`。在客户端，BMB 的版本立刻返回。在服务端它调用 `self:BaseInitialize()`，后者会：

1. 用 `self.Model` 设置模型，用 `self.CollisionMins` / `self.CollisionMaxs` 设置碰撞箱；
2. 把生命值设为 `self.StartHealth` × 服务器的 `bmb_health_scale`；
3. 把 `StepHeight`、`TurnRate`、`Acceleration`、`Deceleration` 和 `WalkSpeed` 写进 NextBot 的 locomotion；
4. 选定方块世界（加载了 MineMod 就用它的）；
5. 发布初始的[联网变量](#联网变量)。

僵尸的 `Initialize` 随后把状态设为 `idle`，并重置索敌和音效的计时。所以你自己的 `Initialize` 必须先调用 `BaseClass.Initialize(self)`。

`BaseInitialize` 之后，`self.StartHealth` 是缩放后的生命值，`self.BMBBaseHealth` 是你写的原值。

### 行为协程

`ENT:RunBehaviour()` 是标准的 NextBot 协程，在服务端运行。BMB 的每个家族都把它写成同一个循环：

```lua
while true do
    if self.BMBDead then return
    elseif self:MaintainBMBFreeze() then coroutine.wait(0.05)      -- bmb_freeze、调试工具
    elseif self.BMBHeld then ...                                    -- 物理枪
    elseif self:RunBMBKnockback() then ...                          -- 刚被打中
    elseif self:RunBMBDebugMove() then ...                          -- 调试工具下的命令
    elseif self:RunBMBStrandedRecovery() then ...                   -- 站在了不该站的位置
    else self:RunBMBZombieAI() end                                  -- 这个家族的 AI 函数

    coroutine.yield()
end
```

请重写 AI 函数而不是 `RunBehaviour`，这样你的生物仍然会处理它上面那几种状态。

AI 函数运行在协程里。`MoveToWorldPosition`、`InterruptibleWait` 这类调用是阻塞的：移动或等待结束后才返回。AI 函数返回后马上又会被调用，所以它每次只做一次决策的事，然后返回。

协程多久恢复一次由引擎决定，不由 BMB 决定。按 BMB 自己的测量，单人模式下每个 tick 恢复一次，listen 服务器上大约每秒十次。在为本页做的单人测试里，帧率限制在 60，协程每秒恢复 60 次。不要假设一次 `coroutine.yield()` 就是一个 tick。

### Think

`ENT:Think()` 在两端每个 tick 都运行，做大量的维护工作：服务端有视线控制、液体、摔落伤害、跳方块、空闲音效等等；客户端有骨骼动画。如果你重写 `Think`，要调用父类的版本并返回它的返回值：

```lua
function ENT:Think()
    -- 你自己每个 tick 要做的事
    return BaseClass.Think(self)
end
```

*在游戏里跑过，服务端和客户端都跑过。*

### 受到伤害

服务端的 `ENT:OnTakeDamage(damageInfo)` 按顺序走下面这些步骤。任何一步都可以让流程到此为止。

1. 已经死亡的生物、0 或更低的伤害会被忽略。
2. **引擎的火焰伤害会被忽略。** `DMG_BURN` 或 `DMG_SLOWBURN` 类型的伤害如果不是来自 BMB 自己的燃烧系统，就被丢弃。所以 `Entity:Ignite()` 伤不到 BMB 生物；请用 [`BMB.Fire.Ignite`](#燃烧)。
3. 应用来自 MineMod 的药水免疫。
4. 如果你定义了 `self:IsBMBDamageImmune(damageInfo)`，就调用它。返回 `true` 会丢弃这次伤害，不产生其它效果。
5. 如果生物在不到 `DamageInvulnerabilityTime`（0.5 秒）之前刚被打中，伤害被丢弃。火焰等环境伤害跳过这项检查。
6. 伤害被接受：无敌窗口开始，生物闪红 `HurtFlashTime` 这么久，并调用 `self:OnBMBHurtSound(damageInfo)`。
7. 生命值减少。
8. 如果生命值到了 0，调用 `self:OnKilled(damageInfo)`。否则生物被击退，当前的移动被打断，能[还手](#索敌)就还手，并调用 `self:OnBMBInjured(damageInfo, wasFleeing)`。

### 死亡过程

`OnKilled` 调用 `self:BeginBMBDeath(damageInfo)`，每只生物只执行一次：

1. 清除状态效果。生物停止移动、不再有碰撞，状态变成 `dead`。从这里开始 `self.BMBDead` 是 `true`。
2. 致命一击会把尸体推出一小段距离。
3. 触发标准的 `OnNPCKilled` 游戏钩子，参数是生物、攻击者和造成伤害的实体。
4. 掷出掉落物（仅限 BMB 自己的类，见[掉落物与经验](#掉落物与经验)）。
5. `DeathRemoveDelay` 秒之后（默认 1.0）调用 `self:OnBMBDeathCleanup(corpse)`，播放死亡烟雾，掉落物出现，实体被移除。

这一秒里尸体倒下的动作，是由该家族的骨骼代码在客户端绘制的。

## 字段

在实体文件里写成 `ENT.名字 = 值`。没写的字段沿用父类的值。*基类*一列是 `bmb_base_mob` 上的值，*僵尸*一列是 `bmb_zombie` 上的值。速度是 Source 单位/秒；距离是 Source 单位，名字以 `Cells` 结尾的除外（单位是格）；时间是秒。

带注释的完整列表在 BMB 的 `lua/bmb/base/sh_defaults.lua`（所有生物）和 `lua/entities/bmb_zombie.lua` 的开头（僵尸家族）。

### 身份

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `Model` | `models/kleiner.mdl` | 僵尸模型 | 模型路径。 |
| `IsBMBMob` | `true` | | 标记这个实体是 BMB 生物。不要改。 |
| `IsUndead` | 未设置 | `true` | 亡灵生物免疫中毒。`BurnsInDaylight` 也要求它为 `true`。 |
| `BurnsInDaylight` | 未设置 | `true` | 白天在露天处会着火。只有 `IsUndead` 为 `true` 时才起作用。 |
| `FireImmune` | `false` | | 不会被阳光、岩浆或火方块点燃。 |
| `BMBMinecraftEnemy` | 未设置 | | `true` 或 `false` 决定这只生物算不算 Minecraft 的怪物。见[生物关系](#生物关系)。 |
| `SupportsForcedFlee` | `false` | | 被动动物上是 `true`。告诉调试工具这只生物有惊慌逃跑的行为。 |

### 生命值与受击

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `StartHealth` | 20 | 70 | 乘 `bmb_health_scale` 之前的生命值。BMB 用的是 Minecraft 生命值 × 3.5。 |
| `DamageInvulnerabilityTime` | 0.5 | | 一次伤害被接受之后，忽略后续伤害的时间。 |
| `HurtFlashTime` | 0.5 | | 生物闪红的时长。 |
| `RetaliateOnDamage` | `true` | | 攻击伤害它的对象。需要有 `CanBMBTarget`。被动动物把它设为 `false`。 |
| `RetaliateSameClass` | `true` | | 对同类也会还手。 |
| `KnockbackMinSpeed` | 150 | | 被打中时击退速度的下限。 |
| `KnockbackMaxSpeed` | 320 | | 被打中时击退速度的上限。 |
| `KnockbackDamageSpeedScale` | 8 | | 每点伤害增加的击退速度。 |
| `KnockbackDuration` | 0.12 | | 击退接管移动的时长。 |
| `KnockbackUseJump` | `true` | | 被击退时把生物抬离地面。 |
| `FallDamageImmune` | `false` | | 不受摔落伤害。 |
| `FallSafeDistanceCells` | `nil` | | 摔落多少格以内不受伤。`nil` 表示用 `bmb_fall_damage_safe_distance`。 |
| `FallDamageMultiplier` | `nil` | | 摔落伤害倍率。`nil` 表示用 `bmb_fall_damage_multiplier`。 |
| `CanFloatInWater` | `true` | `false` | 在水里会浮起来。僵尸和骷髅会下沉，在水底行走。 |

### 移动

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `WalkSpeed` | 80 | 约 71 | 游荡速度。 |
| `RunSpeed` | 120 | 约 71 | 追击和逃跑的速度。 |
| `Acceleration` | 420 | 420 | |
| `Deceleration` | 650 | 650 | |
| `TurnRate` | 400 | | 最快转向速度，度/秒。 |
| `TurnInPlaceAngle` | 110 | 170 | 目标在身后超过这么多度时，先原地转身再走。 |
| `CollisionMins`、`CollisionMaxs` | 宽 ±16，高 48 | 0.6 × 1.95 格 | 碰撞箱。寻路用它判断生物能不能通过。 |
| `StepHeight` | 28 | | 不用跳就能走上去的最大台阶高度。特意设在半砖之上、整格之下。 |
| `MaxPathDropCells` | 3 | | 寻路愿意规划的最大下落高度，以格计。 |
| `MobSeparationEnabled` | `true` | | 和其它生物重叠时会被互相推开。 |

### 索敌

供 `BMB.Behaviors.SeekTarget` 使用。

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `TargetRange` | 未设置（按 900 算） | 35 格 | 多远能发现目标。 |
| `TargetLoseRange` | 未设置（`TargetRange` × 1.25） | 35 格 | 已有的目标在多远以内不会丢。 |
| `TargetScanInterval` | 未设置（0.35） | 0.35 | 两次搜索新目标之间的时间。 |
| `TargetRequireLineOfSight` | 未设置 | `false` | 必须看得见才会选为目标。已有的目标看不见之后还会保留一段时间。 |
| `TargetVillagers` | 未设置（关闭） | `true` | *1.0.0 之后。*把村民和流浪商人加入共用的自然索敌候选。见[村民目标](#村民目标100-之后)。 |
| `TargetUnseenMemoryTicks` | 60 | | 看不见目标后还记得它多久，单位 1/20 秒。只在要求视线时有用。 |
| `RetaliationUnseenMemoryTicks` | 300 | | 同上，针对它正在还手的目标。 |

### 追击

供 `BMB.Behaviors.Chase` 使用。

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `ChasePreferDirect` | 未设置 | `true` | 看得见目标且中间没有阻挡时直接冲过去，而不是沿算出来的路径走。 |
| `ChaseDirectMaxDistanceCells` | 未设置 | 6 | 目标在多远以内才会直冲。 |
| `ChaseDirectProbeCells` | 未设置（4） | 4 | 直冲时向前探多远来检查墙和落差。 |
| `ChaseSegmentTimeout` | 未设置 | 2.0 | 沿一条算好的路径最多走多久就重新规划。 |
| `ChaseStepUpHopEnabled` | `true` | | 直冲途中遇到一格高的台阶会跳上去。 |

### 近战

供 `BMB.Behaviors.MeleeAttack` 使用。

| 字段 | 未设置时的默认值 | 僵尸 | 含义 |
|---|---|---|---|
| `AttackRange` | 一格 | 60 | 水平攻击距离。 |
| `AttackVerticalRange` | `AttackRange` × 0.65 | 28 | 能打到的高度差。 |
| `AttackDamage` | 2 | 10.5 | 每次命中的伤害。 |
| `AttackDamageType` | `DMG_SLASH` | | 伤害类型。 |
| `AttackCooldown` | 1.0 | 1.0 | 两次挥击之间的时间。 |
| `AttackHitDelay` | 0.25 | 0 | 从开始挥击到命中生效的延迟。 |
| `AttackHitSlop` | 0.35 格 | 16 | 命中生效时额外放宽的距离，这样目标后退一步也还是会被打中。 |
| `AttackMoveSpeed` | `RunSpeed` | 约 71 | 挥击时保持的速度。请让它等于 `RunSpeed`。 |
| `AttackKnockback` | 0 | 150 | 对受害者的水平击退。 |
| `AttackVerticalKnockback` | 0 | 155 | 对受害者的向上击退。 |
| `AttackGroundedVerticalKnockback` | `AttackVerticalKnockback` | 190 | 对站在地面上的玩家的向上击退。 |

### 游荡与逃跑

供 `BMB.Behaviors.Wander` 和 `BMB.Behaviors.Flee` 使用。

| 字段 | 未设置时的默认值 | 僵尸 | 被动动物 | 含义 |
|---|---|---|---|---|
| `WanderDistanceMinCells` | 2 | 2 | 3 | 一次散步的最短距离，以格计。 |
| `WanderDistanceMaxCells` | 5 | 5 | 8 | 一次散步的最长距离，以格计。 |
| `WanderPauseMin` | 6.0 | 0.5 | 6.0 | 散步后最短的停留时间。 |
| `WanderPauseMax` | 14.0 | 1.8 | 14.0 | 散步后最长的停留时间。 |
| `FleeDurationMin` | | | 3.5 | 受伤后最短的惊慌时间。 |
| `FleeDurationMax` | | | 5.0 | 受伤后最长的惊慌时间。 |
| `FleePanicRadiusCells` | 5 | | 5 | 在多远的范围内选逃跑的落点。 |
| `FleeGiveUpFailures` | 4 | | 4 | 连续失败这么多次后不再惊慌。 |

### 音效

| 字段 | 僵尸 | 含义 |
|---|---|---|
| `Sounds` | 五个列表 | 僵尸家族。一个表，里面有 `Say`、`Hurt`、`Death`、`Step` 和 `Hit` 这几个列表。合并时的坑见 README 的*音效*一节。 |
| `AmbientSoundIntervalTicks` | 80 | 一次空闲音效之后的安静时间，单位 1/20 秒。过了这段时间，下一次发声的概率每个 tick 都在增加。 |
| `AmbientSoundChanceDenominator` | 1000 | 越大，空闲音效越少。 |
| `StepSoundDistance` | 26 | 每走多远播放一次脚步声。 |
| `StepSoundVolumeMin`、`StepSoundVolumeMax` | 0.15 | 低速和全速时的脚步声音量。 |

### 死亡

| 字段 | 基类 | 含义 |
|---|---|---|
| `DeathRemoveDelay` | 1.0 | 尸体停留的秒数。`false` 表示永远保留。 |
| `DeathPoofEffect` | `bmb_death_poof` | 尸体消失时播放的特效。`false` 表示不播放。 |
| `DeathKeepRed` | `true` | 尸体保持红色。 |
| `DeathKnockbackEnabled` | `true` | 致命一击会推动尸体。 |
| `UseRagdollOnDeath` | `false` | 改为变成布娃娃。 |
| `UsePhysicsCorpseOnDeath` | `false` | 改为留下一个用该模型的物理道具。 |

### 张望

| 字段 | 基类 | 僵尸 | 含义 |
|---|---|---|---|
| `LookAtEnabled` | `true` | | 时不时看一眼附近的玩家。 |
| `LookAtHeadBoneName` | `head` | | 被转动的骨骼。 |
| `LookAtRangeCells` | 8 | | 玩家要离得多近。 |
| `LookAtYawLimit` | 70 | | 头向两侧最多转多少度。 |
| `LookAtPitchLimit` | 24 | 40 | 头上下最多倾斜多少度。 |
| `LookAtPitchSign` | `nil` | -1 | 如果你的模型头部倾斜的方向反了，设为 -1 或 1。 |
| `LookAtEyeHeight` | 0 | 1.74 格 | 头部离脚底的高度。 |
| `LookAroundEnabled` | `true` | | 空闲时四处张望。 |

### 动画

BMB 的大多数生物是在客户端用 Lua 旋转骨骼来做动画的，所以模型不需要行走动作。僵尸家族用到这些字段：

| 字段 | 僵尸 | 含义 |
|---|---|---|
| `BipedLegSwingMax` | 38 | 腿摆动的幅度，以度计。 |
| `BipedArmForwardAngle` | -80 | 空闲时手臂的角度。 |
| `ZombieChaseArmAngle` | -120 | 追击时手臂的角度。 |
| `AttackKeyframeDuration` | 0.3 | 挥击动画的时长。 |
| `LimbSwingPhaseScale` | 0.12 | 同样的速度下腿摆动得多快。 |
| `DeathTipDuration` | 0.55 | 尸体倒下所用的时间。 |

模型自带动画序列的生物可以改用 `ENT.AnimationSequences`：一个把 `idle`、`walk`、`run`、`attack`、`hurt` 和 `death` 对应到模型里序列名的表。缺少的条目退回到 `idle`。

## 可以定义的钩子

BMB 会在你的生物上调用这些函数。

重写钩子时要看*僵尸已有*这一列。写着**是**的，`bmb_zombie` 或基类已经定义了这个钩子：除非你就是要替换它，否则请通过 `BaseClass` 调用父类的版本。写着**否**的，你上面没有任何类定义它，`BaseClass.TheHook` 是 `nil`，所以直接写你自己的，不要调用父类。

### 所有生物

| 钩子 | 哪一端 | 僵尸已有 | BMB 什么时候调用 | 返回什么 |
|---|---|---|---|---|
| `ENT:Initialize()` | 两端 | 是 | 生成时。 | |
| `ENT:RunBehaviour()` | 服务端 | 是 | 一次。它就是行为协程。 | |
| `ENT:Think()` | 两端 | 是 | 每个 tick。 | 父类返回什么就返回什么。 |
| `ENT:CanBMBTarget(target)` | 服务端 | 是 | 每次选定目标或重新检查目标时。 | `true` 表示允许。没有这个钩子的生物永远不会还手。 |
| `ENT:FindBMBPriorityTarget(range)` | 服务端 | 否 | 每次搜索目标时，在常规搜索之前。 | 它优先选择的目标，还可以再返回一个用来检查它的距离。没有就返回 `nil`。 |
| `ENT:IsBMBDamageImmune(damageInfo)` | 服务端 | 否 | 每次伤害事件，在无敌时间检查之前。 | `true` 表示忽略这次伤害。 |
| `ENT:OnBMBHurtSound(damageInfo)` | 服务端 | 是 | 伤害被接受时，生命值减少之前。致命一击也会调用。 | |
| `ENT:OnBMBInjured(damageInfo, wasFleeing)` | 服务端 | 否 | 生物挨了一下但没死之后。被动动物定义了它：它们就是在这里开始惊慌的。 | |
| `ENT:OnKilled(damageInfo)` | 服务端 | 是 | 受到致命一击时。基类的版本调用 `BeginBMBDeath`。 | |
| `ENT:OnBMBDeathCleanup(corpse)` | 服务端 | 否 | 尸体被移除之前的一刻。`corpse` 是物理道具，如果生成了的话。 | |
| `ENT:OnBMBStateChanged(oldState, newState)` | 服务端 | 否 | `SetBMBState` 改变了状态时。 | |
| `ENT:OnBMBFreezeStarted(now)`、`ENT:OnBMBFreezeEnded(now)` | 服务端 | 否 | 生物被 `bmb_freeze` 或调试工具冻结、解冻时。 | |
| `ENT:OnBMBHeldStarted(now)`、`ENT:OnBMBHeldEnded(now)` | 服务端 | 否 | 物理枪抓起、放下它时。 | |
| `ENT:MaybePlayIdleSound()` | 服务端 | 是 | 由 `Think` 调用，每秒最多 20 次。 | |
| `ENT:GetBMBForcedLookTarget()` | 服务端 | 是 | 由视线控制调用。 | 头部要一直盯着的实体，或 `nil`。 |
| `ENT:IsBMBWanderDestinationAllowed(destination)` | 服务端 | 否 | `Wander` 每考虑一个落点时。 | `false` 表示拒绝这个点。 |
| `ENT:TryBMBMoveOverride(reason, target)` | 服务端 | 是 | 一次移动的每个 tick。 | 如果这个 tick 你自己移动了生物，返回 `true`。 |
| `ENT:ConfigureBMBPathfinderOptions(pathOptions, destination, moveOptions)` | 服务端 | 否 | 每次寻路之前。 | 直接修改 `pathOptions`。 |
| `ENT:IsBMBMinecraftEnemy(context)` | 服务端 | 否 | 别的生物询问它是不是怪物时。 | `true` 或 `false`。返回 `nil` 则交给后面的检查。 |
| `ENT:RequiresBMBPersistence()` | 两端 | 是 | 由自然刷怪的清除（despawn）流程调用。 | `true` 表示永远不清除这只生物。 |
| `ENT:GetBMBDuplicatorState()`、`ENT:RestoreBMBDuplicatorState(state)` | 服务端 | 否 | 复制器或存档复制这只生物时。 | 一个表，装着你自己要带过去的状态。 |
| `ENT:UpdateBMBVisualBones()` | 客户端 | 是 | 每次更新生物骨骼的那一帧。 | |

### 近战生物

这两个钩子僵尸都定义了。

| 钩子 | BMB 什么时候调用 |
|---|---|
| `ENT:OnBMBMeleeHit(target, damageInfo)` | 一次命中造成了伤害和击退之后，紧接着调用。 |
| `ENT:PlayBMBMeleeGesture(target)` | 挥击开始时。僵尸用它启动手臂动画。 |

### 僵尸家族

这两个钩子僵尸都定义了。

| 钩子 | BMB 什么时候调用 |
|---|---|
| `ENT:RunBMBZombieAI()` | 由行为循环调用。见 README 的*自己的状态机*一节。 |
| `ENT:GetBMBZombieSounds()` | 每次挑选音效时。返回含有 `Say`、`Hurt`、`Death`、`Step` 和 `Hit` 的表。 |

### 被动动物

`bmb_passive_animal` 的整个行为循环都在 `BMB.Behaviors.PassiveAnimal.Run` 里，没有可以重写的 AI 函数，而是提供下面这些钩子。基类一个都没有定义，所以不要调用父类的版本：

| 钩子 | BMB 什么时候调用 |
|---|---|
| `ENT:OnBMBPassiveInitialized()` | `Initialize` 的最后。 |
| `ENT:RunBMBPassiveSpecialBehavior()` | 动物没有在惊慌、繁殖或跟随食物时，在游荡之前调用。如果这一轮你做了事，返回 `true`。 |
| `ENT:StopBMBPassiveSpecialBehavior(reason)` | 有更紧急的事（比如惊慌）接管时。 |
| `ENT:PrepareBMBPassivePanic()` | 即将开始逃跑时。 |
| `ENT:PrepareBMBPassiveWander()` | 即将开始游荡时。 |

它的音效来自 `ENT.PassiveSoundSets`：一个按变种名存放音效组的表，每组有 `Ambient`、`Hurt`、`Death`、`Step` 这样的列表。

### 示例

**对状态变化做出反应。** 追击时发光：

```lua
function ENT:OnBMBStateChanged(oldState, newState)
    self:SetNWBool("EmberAngry", newState == "chase" or newState == "attack")
end
```

*在游戏里跑过。*

**无视某一种伤害。** 一只不怕爆炸的生物：

```lua
function ENT:IsBMBDamageImmune(damageInfo)
    return damageInfo:IsDamageType(DMG_BLAST)
end
```

*在游戏里跑过。*

**偏好某一种猎物。** 先找最近的羊，再考虑玩家：

```lua
function ENT:FindBMBPriorityTarget(range)
    local best, bestDistance = nil, range * range
    BMB.ForEachMobOfClass("bmb_sheep", function(sheep)
        local distance = sheep:GetPos():DistToSqr(self:GetPos())
        if not sheep.BMBDead and distance < bestDistance then
            best, bestDistance = sheep, distance
        end
    end)
    return best
end
```

僵尸的 `CanBMBTarget` 接受任何活着的玩家、NPC 或 NextBot，所以不需要改别的。*在游戏里跑过：僵尸选中了一只羊并打中了它。*

## 可以调用的方法

在你的生物上以 `self:Name(...)` 的形式调用。没有标注的都是服务端的。

### 状态

| 方法 | 作用 |
|---|---|
| `SetBMBState(state)` | 设置状态名。客户端用它挑选动画，调试 HUD 也会显示它。生物死亡后调用无效。常见的名字：`idle`、`wander`、`chase`、`attack`、`flee`、`aim`、`knockback`、`held`、`frozen`、`dead`。也可以用你自己的名字。 |
| `SetBMBMoveMode(mode)` | 设置调试 HUD 上显示的更细的移动标签。BMB 的移动代码会替你设置。 |
| `IsBMBFleeing()` | 状态是 `flee` 时为 `true`。 |
| `IsBMBHeld()` | 被物理枪抓着时为 `true`。 |
| `IsBMBKnockbackActive()` | 被打中后短暂的击退期间为 `true`。 |
| `IsBMBOnGround()` | 脚下有东西时为 `true`。 |
| `IsBMBInDamageInvulnerability()` | 一次伤害被接受后的无敌窗口内为 `true`。 |
| `GetBMBBlockSize()` | 一格的边长，Source 单位。两端可用。 |

可以读取的字段：`self.State`、`self.BMBDead`、`self.BMBHeld`、`self.TargetEntity`（敌对生物当前的目标）。

### 等待

| 方法 | 作用 |
|---|---|
| `InterruptibleWait(seconds)` | 原地站这么久。时间到了返回 `true`；如果移动被打断（比如被打中），立刻返回 `false`。只能在协程里用。 |

稍长一点的等待都请用它而不是 `coroutine.wait`，这样生物受伤时会有反应。

### 移动方法

这些方法都必须在行为协程里调用。每个都会阻塞到移动结束。

| 方法 | 作用 |
|---|---|
| `MoveToWorldPosition(destination, speed, options)` | 寻找一条通往某个世界坐标的路径并沿着它走。到达时返回 `true`。以下情况返回 `false`：没有路径、移动被挡住或被打断、生物被抓着或正在被击退，或者路径在到达之前过期了（见下文）。 |
| `MoveAlongDirection(direction, speed, options)` | 朝一个方向走 `options.duration` 秒（默认 1.0），遇到墙和落差会停下。 |
| `FaceTarget(position)` | 按 `TurnRate` 转向某个位置。不阻塞。 |
| `InterruptBMBMovement()` | 让正在进行的移动返回 `false`。在协程外面调用，比如在伤害钩子里。 |

**调用一次 `MoveToWorldPosition` 走不了多远。** BMB 在找到路径 0.75 秒后就把它作废（`BMB.Config.PathCacheTTL`），这样生物才能察觉到有方块被放置或破坏。如果这时生物还没到，调用返回 `false`（带 `acceptPartial` 时返回 `true`）。正在进行的跳跃或下落会先做完。按僵尸的速度，一次调用大约能走一格半。在 AI 函数的下一轮里再调用一次，它会找一条新路径；BMB 自己的追击就是这样工作的。想让一次调用走得更远，就传 `pathCacheTTL`。

`MoveToWorldPosition` 的选项：

| 选项 | 含义 |
|---|---|
| `skipSourcePath` | 传 `true`。它跳过一个默认关闭的实验性路径跟随器；BMB 自己的行为总是传它。 |
| `goalTolerance` | 离多近算到达。默认半格。 |
| `timeout` | 这次移动的最长时间。默认根据路径长度和速度算出来。 |
| `pathCacheTTL` | 路径在多少秒后过期、调用随之返回。默认用生物的 `PathCacheTTL` 字段；生物没有这个字段就是 0.75。走向一个不会动的地点时，BMB 自己的行为传 2 到 5。 |
| `allowPartial` | 传 `false` 时，到不了终点的路径算作没有路径。默认情况下生物会走到它能到的最近处。 |
| `acceptPartial` | 传 `true` 时，时间用完后即使没到也返回 `true`。用于追击会移动的目标。 |
| `allowNearestGoal`、`goalSnapRadiusCells` | `allowNearestGoal = true` 时，站不了的终点会被替换成这么多格以内最近的可站立位置。 |

一个简短的例子，写在僵尸的 AI 函数里：

```lua
function ENT:RunBMBZombieAI()
    if self.HomePosition and not IsValid(self.TargetEntity)
        and self:GetPos():DistToSqr(self.HomePosition) > (6 * BMB.BS) ^ 2 then
        self:SetBMBState("wander")
        self:MoveToWorldPosition(self.HomePosition, self.WalkSpeed, { skipSourcePath = true })
        return
    end

    BaseClass.RunBMBZombieAI(self)
end
```

只要它没有目标、离 `self.HomePosition` 超过 6 格，就会往回走。每次调用只走一小段，AI 函数随后马上又被调用，所以生物会一直走到 6 格以内，然后重新交给僵尸自己的 AI。*在游戏里跑过：一只从 9 格外出发的生物，调用 4 次后回到了 6 格以内。`pathCacheTTL` 没有跑过。*

README 里的两条规则适用于所有移动代码：永远不要用 `SetPos` 或 `SetAngles` 移动生物，永远不要在协程外面调用这些会阻塞的方法。

### 战斗

| 方法 | 作用 |
|---|---|
| `IsBMBCombatTarget(target)` | 对可以被当作目标的活着的玩家，或者活着的 NPC、NextBot，返回 `true`。僵尸的 `CanBMBTarget` 返回的就是它。 |
| `TryBMBRetaliateAgainst(attacker)` | 如果 `CanBMBTarget` 允许，把攻击者设为当前目标。返回是否设置成功。 |
| `StartBMBExternalImpulse(impulse, options)` | 用一个速度 `Vector` 把生物抛出去。生物已死亡或被抓着时返回 `false`。 |
| `StartBMBHurtFlash()` | 让生物闪红，但不造成伤害。 |
| `BeginBMBDeath(damageInfo)` | 开始死亡流程。如果你替换了父类的 `OnKilled`，在你自己的版本里调用它。 |

### 名字

| 方法 | 哪一端 | 作用 |
|---|---|---|
| `SetBMBCustomName(name)` | 服务端 | 给生物起名。有名字的生物永远不会被自然刷怪系统清除。 |
| `GetBMBCustomName()` | 两端 | 名字，或 `nil`。 |
| `HasBMBCustomName()` | 两端 | 有没有名字。 |

### 客户端骨骼辅助函数

在 `ENT:UpdateBMBVisualBones()` 里使用。

| 方法 | 作用 |
|---|---|
| `SetBMBVisualBoneAngle(boneId, angle)` | 旋转一根骨骼。`boneId` 是 `nil` 时什么都不做。 |
| `SetBMBVisualBonePosition(boneId, position)` | 偏移一根骨骼。 |
| `UpdateBMBLimbSwing(speed)` | 推进行走周期。返回相位和一个 0 到 1 的幅度。 |
| `UpdateBMBLookAtHeadPose(headBoneId)` | 应用视线控制算出的转头。返回头有没有转动。 |
| `ApplyBMBBipedLocomotion(bones, phase, amount)` | 摆动 `bones.rightLeg`、`bones.leftLeg`、`bones.rightArm` 和 `bones.leftArm`。 |
| `CacheBMBZombieBones()` | 僵尸家族。返回一个表，里面是 `root`、`head`、`rightArm`、`leftArm`、`rightLeg` 和 `leftLeg` 的骨骼 id。 |

## 行为模块

`BMB.Behaviors` 下面可以复用的部件，仅服务端。一个家族的 AI 函数就是把它们组合起来的几行代码。僵尸的 AI 函数全文如下：

```lua
function ENT:RunBMBZombieAI()
    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)

    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
        coroutine.wait(0.05)
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        -- 这一轮没能靠近：继续施压，或者放弃目标
        ...
    end
end
```

| 函数 | 作用 |
|---|---|
| `SeekTarget.Find(mob, currentTarget)` | 返回现在该用的目标。`currentTarget` 仍然有效时保留它，否则搜索，每 `TargetScanInterval` 最多搜索一次。搜索时先问 `FindBMBPriorityTarget`，然后从玩家池和允许主动攻击的铁傀儡中取最近的有效候选。*1.0.0 之后*，`TargetVillagers = true` 还会加入村民和流浪商人。没有目标时返回 `nil`。 |
| `SeekTarget.IsValid(mob, target, range, acquire)` | `target` 是否活着、通过 `CanBMBTarget`、在 `range`（默认 `TargetLoseRange`）以内，并且在生物要求视线时看得见。 |
| `MeleeAttack.Try(mob, target)` | 目标在攻击距离内且冷却结束时开始一次挥击。返回有没有开始。命中在 `AttackHitDelay` 之后生效。 |
| `MeleeAttack.IsInRange(mob, target)` | 目标是否在 `AttackRange` 和 `AttackVerticalRange` 以内。 |
| `Chase.Run(mob, target)` | 朝目标移动一小段：能直冲就直冲，否则沿路径走。有进展或已在攻击距离内返回 `true`，没能靠近返回 `false`。 |
| `Wander.Run(mob)` | 在游荡距离内随机选一个到得了的点，以 `WalkSpeed` 走过去，然后停留一会儿。 |
| `Flee.Run(mob, threat)` | 以 `RunSpeed` 跑向附近的随机点，直到 `mob.FleeUntil`。给了 `threat`（一个实体或一个位置）时，只选离威胁更远的点。调用之前先设置 `mob.FleeUntil = CurTime() + seconds`。 |
| `RangedAttack.Update(mob, target)` | 骷髅远程攻击的一轮：靠近到射程内，然后横移、拉弓、射击。 |
| `FleeSun.CanStart(mob)`、`FleeSun.Run(mob)` | 骷髅在阳光下燃烧时跑去找阴凉处。 |
| `FlyWander.Run(mob)` | 飞行生物的游荡。 |
| `PassiveAnimal.Run(mob)` | 被动动物完整的行为循环。 |

还有一些模块只给单个家族用，例如 `Leap`（蜘蛛）、`Pack`（狼）、`Avoid`（猫和兔子）、`Breeding`、`Temptation` 和 `FollowParent`（动物）。用之前先在 `lua/bmb/behaviors/` 里读它们的代码。

## 全局函数

### 版本与方块大小

| 名字 | 哪一端 | 含义 |
|---|---|---|
| `BMB.Version` | 两端 | 版本字符串，这个版本是 `"1.0.0"`。 |
| `BMB.BS` | 两端 | 一格的边长（Source 单位），是最近一次调用 `BMB.GetBlockSize` 时的值。MineMod 默认是 36.5。 |
| `BMB.GetBlockSize()` | 两端 | 从 MineMod 读取方块大小，存进 `BMB.BS` 并返回。 |

要检查 BMB 有没有安装，请检查实体类而不是这个表：

```lua
if not scripted_ents.GetStored("bmb_zombie") then
    -- 没有安装 BMB
end
```

*在游戏里跑过：示例的 autorun 文件就是这么做的。*

### 生命值

| 函数 | 哪一端 | 作用 |
|---|---|---|
| `BMB.GetHealthScale()` | 两端 | 当前的 `bmb_health_scale`。 |
| `BMB.ScaleMobHealth(baseHealth)` | 两端 | `baseHealth` × 倍率，四舍五入，最小为 1。 |
| `BMB.ApplyMobHealthScale(mob, baseHealth, preserveFraction)` | 服务端 | 给生物设置新的基础生命值。传了 `preserveFraction` 时保持原来的生命百分比。如果你的生物在生成之后会改变最大生命值，就用它。 |

### 生物注册表

BMB 维护着一份所有活着的 BMB 生物的列表，自定义生物也在里面。要遍历它们，用这份列表最快。

| 函数 | 作用 |
|---|---|
| `BMB.ForEachMob(fn)` | 对每只 BMB 生物调用 `fn(mob)`。在回调里移除生物是安全的。 |
| `BMB.ForEachMobOfClass(class, fn)` | 同上，但只针对一个确切的类名。不包含子类。 |
| `BMB.GetMobCount()` | BMB 生物的数量。 |
| `BMB.GetMobCountOfClass(class)` | 一个确切类名的生物数量。 |
| `BMB.GetMobList()` | 一个新建的、包含所有生物的表。优先用 `ForEachMob`。 |
| `BMB.IsMobRegistered(ent)` | 某个实体是否在列表里。 |

这些函数两端都能用。生物在创建后的下一帧才进入列表。

```lua
local count = 0
BMB.ForEachMob(function(mob)
    if mob:GetClass() == "example_ember_zombie" and not mob.BMBDead then count = count + 1 end
end)
```

*注册表的这些函数在游戏里两端都跑过。这段代码本身没有跑过。*

### 把玩家当作目标

| 函数 | 返回什么 |
|---|---|
| `BMB.PlayerTargetBlockReason(player)` | 敌对生物可以把这名玩家当作目标时返回 `nil`。否则返回原因：`"dead"`、`"notarget"` 或 `"spectator"`。 |
| `BMB.Targeting.GetPlayerMode(player)` | `"survival"`、`"creative"`、`"spectator"`、`"dead"` 或 `"invalid"`。 |

创造模式和无敌（god）的玩家仍然会被当作目标。带 `notarget` 标志的玩家不会。

### 文本

| 函数 | 哪一端 | 作用 |
|---|---|---|
| `BMB.GetLanguage(player)` | 两端 | `"en"` 或 `"zh"`：BMB 对这名玩家使用的语言。在客户端不用传参数。 |
| `BMB.L(key, player)` | 两端 | BMB 自己的一条界面文字，按该语言返回。它只认识 BMB 的键。 |

## 自然刷怪

`BMB.NaturalSpawn` 是服务端的刷怪系统。服务器不设置 `bmb_spawn_enabled 1`，它就是关闭的。

### `BMB.NaturalSpawn.Register(className, options)`

添加一个刷怪条目。返回 `true`；类名不是非空字符串时返回 `false`。每调用一次就多一个条目，所以只调用一次。

| 选项 | 默认值 | 含义 |
|---|---|---|
| `category` | `"monster"` | `"monster"`、`"creature"` 或 `"ambient"`。各有各的规则和上限，见下文。 |
| `weight` | 1 | 在同一分类的条目中的相对概率。 |
| `packSizes` | 无 | 群体大小的列表，例如 `{ 2, 3 }`，随机选一个。不写就只刷一只。 |
| `limitConVar` | 无 | 一个 ConVar 的名字。这个类的生物达到这么多只之后，条目被跳过。`0` 表示关掉这个条目。 |
| `enabledConVar` | 无 | 一个 ConVar 的名字。它是 `0` 时条目被跳过。 |
| `maxLight` | 无 | 怪物规则。最高光照等级，0 到 15。它只能把服务器的 `bmb_spawn_max_light` 往下调。 |
| `spawnChance` | 无 | 怪物规则。小于 1 的数表示合法位置只有这个比例的机会被真正使用。 |
| `condition` | 无 | 怪物规则。`function(world, cell, position)`，在一个位置通过光照检查之后调用。返回 `true`，或者 `false` 加一个原因字符串。 |
| `groundMCIDs` | 草方块 | 动物规则。生物可以刷在哪些方块上的集合，例如 `{ ["minecraft:sand"] = true }`。 |
| `useCreatureSpawnRule` | `false` | 用于怪物条目：按动物规则选位置，但仍然属于怪物分类。 |

另外还有五个选项是给 BMB 自己的动物用的，和它的变种、年龄系统绑在一起：`initialVariant`、`chooseInitialVariant`、`sharePackVariant`、`packBabyChance` 和 `adultPackMembers`。

在游戏里跑过的有：`category`、`weight`、`packSizes`、`limitConVar`、`enabledConVar`、`maxLight` 和 `condition`。其余选项来自源码。

### 三套规则

| 分类 | 刷在哪里 | 服务器上限 |
|---|---|---|
| `monster` | 脚下和头部高度的光照等级都不超过 `bmb_spawn_max_light`（7）。然后再应用 `spawnChance` 和 `condition`。 | `bmb_spawn_max` |
| `creature` | 脚下的方块在 `groundMCIDs` 里，脚上方的那一格是空的，原始光照等级高于 8。 | `bmb_spawn_creature_max` |
| `ambient` | 蝙蝠的规则：先抛一次硬币，然后要求光照不超过一个 0 到 3 的随机数，并且不在露天处。 | `bmb_spawn_ambient_max` |

不管哪个分类，位置都要离某个玩家 20 到 40 格（`bmb_spawn_min_distance`、`bmb_spawn_max_distance`），生物的碰撞箱要放得下，而且那一格必须是生物能站的。

一群生物里，第一只按上面的规则刷出，其余的刷在它周围 5 格以内的随机位置，每只都做同样的检查。

怪物和环境生物每 `bmb_spawn_interval` 秒刷一轮，动物每 `bmb_spawn_creature_interval` 秒刷一轮。

### 其它函数

| 函数 | 作用 |
|---|---|
| `BMB.NaturalSpawn.TrySpawnForPlayer(player, options)` | 在某个玩家附近尝试刷一次。返回生物和 `"spawned"`，或者 `nil` 和失败原因。选项：`channel`（分类，默认 `"monster"`）、`ignoreEnabled`、`ignoreCap`、`entry`（指定用这个条目，而不是随机挑）。 |
| `BMB.NaturalSpawn.CountNaturalMobs(category)` | 刷怪系统在该分类下刷出的、还活着的生物数量。 |
| `BMB.NaturalSpawn.GetStatus()` | 一个表，含有 `enabled`、`monsters`、`count`、`max`、`creatureCount`、`creatureMax`、`ambientCount`、`ambientMax`、`world` 和 `daylight`。 |

刷怪系统刷出来的生物带有 `mob.BMBNaturalSpawn == true`，`mob.BMBNaturalSpawnCategory` 是它的分类。只有这样的生物才计入上限，也只有它们会被清除。

### 失败原因

由 `TrySpawnForPlayer` 返回，`bmb_spawn_now` 也会打印它们。

| 原因 | 含义 |
|---|---|
| `disabled` | `bmb_spawn_enabled` 是 `0`。 |
| `monsters_disabled` | `bmb_spawn_monsters` 是 `0`。 |
| `cap_reached` | 这个分类已达上限。 |
| `class_limit_reached` | 指定的条目已达到它的 `limitConVar`。 |
| `no_spawnable_class` | 这个分类里没有可用的条目：全都被禁用、达到上限，或者权重为 0。 |
| `outside_distance_band` | 随机选的位置比允许的近或者远。很常见，再试一次就行。 |
| `no_walkable_candidate` | 在玩家附近没找到可以行走的位置。 |
| `collision_or_standability` | 位置通过了规则，但生物放不下。 |
| `light_unknown` | 方块世界在那里没有光照数据。没有 MineMod 方块的地图上得到的就是它。 |
| `light_not_exact` | 只有估算值，而 `bmb_spawn_allow_approximate_light` 是 `0`。 |
| `light_15.00_over_7.00` | 对怪物来说太亮。两个数字是测到的光照和上限。 |
| `light_raw_7.00_not_above_8` | 对动物来说太暗。 |
| `wrong_spawn_block_minecraft:stone` | 动物脚下的方块不在 `groundMCIDs` 里。实际的方块写在名字里。 |
| `spawn_block_unknown` | 认不出脚下的方块。 |
| `no_head_clearance` | 动物脚上方那一格是实心方块。 |
| `spawn_chance` | 条目的 `spawnChance` 没掷中。 |
| `condition_failed` | 条目的 `condition` 返回了 `false` 但没给原因。给了原因的话返回的是那个原因。 |
| `coin_flip`、`sky_exposed` | 环境生物规则没通过。 |
| `invalid_player`、`unknown_channel`、`world_api_unavailable`、`light_api_unavailable`、`create_failed`、`spawn_failed` | 不是运气不好，而是缺了什么或者坏了什么。 |

### 示例：只在地下刷新

```lua
BMB.NaturalSpawn.Register("yourname_cave_zombie", {
    category = "monster",
    weight = 10,
    maxLight = 0,
    packSizes = { 1, 2 },
    condition = function(world, cell, position)
        if world.IsSkyExposedAt and world.IsSkyExposedAt(cell) ~= false then
            return false, "needs_a_roof"
        end
        return true
    end,
})
```

`IsSkyExposedAt` 只有在确知那一格上方有遮挡时才返回 `false`，所以 `~= false` 把它判断不了的情况也一并拒绝了。*只在露天环境下跑过：`condition` 用 `needs_a_roof` 拒绝了每一个位置，带 `maxLight = 0` 的条目则因为光照被拒绝。没有试过在有顶的地方刷出来。*

## 生物关系

有些 BMB 生物的行为取决于另一只生物是不是 Minecraft 的"怪物"：铁傀儡和雪傀儡攻击怪物，怪物攻击铁傀儡。`BMB.MobRelations`（服务端）负责回答这个问题。

`BMB.MobRelations.IsMinecraftEnemy(entity, context)` 按下面的顺序检查，第一个给出答案的就是结果：

1. `entity:IsBMBMinecraftEnemy(context)`，如果实体定义了它并且它返回 `true` 或 `false`；
2. 字段 `entity.BMBMinecraftEnemy`，如果它是 `true` 或 `false`；
3. 这个类有没有登记为怪物。BMB 自己的敌对生物都登记了；
4. 字段 `entity.BMBMinecraftEntityID`，对照 BMB 的 Minecraft 怪物 id 列表；
5. 游戏钩子 `BMB.IsMinecraftEnemy`，它可以返回 `true`。

所以自定义生物想成为怪物，有两个简单的办法：

```lua
ENT.BMBMinecraftEnemy = true                                             -- 写在实体文件里

BMB.MobRelations.RegisterMinecraftEnemyClass("yourname_frost_zombie")    -- 在服务端，BMB 加载之后
```

*两种办法都在游戏里跑过。*

在 1.0.0 里，成为怪物有两个效果。铁傀儡和雪傀儡会攻击这只生物。并且这只生物如果用 `SeekTarget`，除了玩家之外还会把铁傀儡选为目标。

| 函数 | 作用 |
|---|---|
| `BMB.MobRelations.RegisterMinecraftEnemyClass(className, enabled)` | 把一个类标记为怪物。第二个参数传 `false` 则取消标记。 |
| `BMB.MobRelations.IsMinecraftEnemy(entity, context)` | 上面描述的检查。 |
| `BMB.MobRelations.IsIronGolem(entity)` | 一个实体是不是铁傀儡。 |
| `BMB.MobRelations.IsAbstractVillager(entity)` | *1.0.0 之后。*返回 boolean，判断实体是否为村民或流浪商人，规则见下文。仅服务端。 |
| `BMB.MobRelations.GetHostileTargetCandidates(mob, range, candidates)` | 返回一个新的候选数组，复制 `candidates`（默认 `player.GetAll()`）并追加附近允许主动攻击的铁傀儡。*1.0.0 之后*，`mob.TargetVillagers == true` 时还追加村民和流浪商人。已开启的适配也会追加符合索敌规则的 NPC。候选去重，传入的数组不变。`range` 的单位是 Source units，默认 `mob.TargetRange` 或 900。调用方负责检查目标合法性。 |

直接写明类名的行为（比如村民躲避僵尸）不在它的管辖范围内。

### 村民目标（1.0.0 之后）

`BMB.MobRelations.IsAbstractVillager(entity)` 按 Java 的 `AbstractVillager` 分类判断：接受 `bmb_villager` 和 `bmb_wandering_trader`，包括幼年村民。外部实体的 `BMBMinecraftEntityID`（缺省时取 `MinecraftEntityID`）为 `minecraft:villager` 或 `minecraft:wandering_trader` 时也接受。无效实体和僵尸村民返回 `false`。这里只判断类别；生命值、距离、视线和 `CanBMBTarget` 由 `SeekTarget.IsValid` 分别检查。

自定义僵尸要使用共用的村民索敌，在实体文件里设置：

```lua
ENT.Base = "bmb_zombie"
ENT.TargetVillagers = true
```

更新后的 `bmb_zombie` 已把这个字段设为 `true`，所以自定义子类、尸壳和僵尸村民都会继承。`bmb_zombie_pigman` 显式覆盖为 `false`。在自己的子类上设为 `false` 可以关闭这项自然扫描；已有目标、受击反击和 debug 强制目标仍按各自规则处理。仅把生物登记为 Minecraft 怪物不会开启这个字段。

该字段由 `GetHostileTargetCandidates` 和共用的 `SeekTarget.Find` 消费。使用独立候选扫描的 AI，需要调用这个 helper 或自行实现村民目标。*已对照更新后的 Lua 源码和离线索敌回归核对；没有为本页在游戏里运行这个示例。*

### NPC 关系（1.0.0 之后）

对应适配启用时，服务端的 BMB 生物基类会处理与受支持的原版 Source NPC、VJ Base SNPC 和 DrGBase NextBot 的关系。敌对 BMB 会主动选择这些 NPC。中立 BMB 会主动选择敌对 NPC，受击时按自身 AI 反击。被动 BMB 会被敌对 NPC 主动选择。友好和中立 NPC 对 BMB 使用相同的索敌规则。

在自定义 BMB 的实体文件里，可以把 `ENT.BMBNPCTemperament` 设为 `"hostile"`、`"neutral"` 或 `"passive"`。字段未设置时，杀手兔按敌对处理，内置中立类按中立处理，其余生物根据 Minecraft 怪物分类判为敌对或被动。内置中立列表按实体类名精确匹配，自定义狼类如果要沿用狼对 NPC 的中立行为，可以显式设置这个字段。

```lua
ENT.Base = "bmb_wolf"
ENT.BMBNPCTemperament = "neutral"
```

要覆盖受支持的外部 NPC 的分类，在服务端把该实体的 `BMBNPCTemperament` 设为 `"friendly"`、`"neutral"` 或 `"hostile"`。字段未设置时，可以用 `BMB.GetNPCTemperament` 钩子提供分类。没有覆盖值时，BMB 会根据基类的阵营和行为设置分类。无法通过其他设置判断的 VJ 或 DrG 阵营按中立处理。NPC 分类会缓存，约每两秒复查一次。

```lua
hook.Add("BMB.GetNPCTemperament", "YourAddonGuardRelations", function(npc, base)
    if base == "vj" and npc:GetClass() == "npc_vj_youraddon_guard" then
        return "friendly"
    end
end)
```

| 服务端查询 | 返回值 |
|---|---|
| `BMB.NPCRelations.GetMobTemperament(mob)` | 对有效的 BMB 生物返回 `"hostile"`、`"neutral"` 或 `"passive"`。其他实体返回 `nil`。 |
| `BMB.NPCRelations.GetNPCTemperament(npc)` | 返回缓存的 `"friendly"`、`"neutral"` 或 `"hostile"`。NPC 尚未登记、类型不受支持或对应适配已关闭时返回 `nil`。 |
| `BMB.NPCRelations.CanAcquire(mob, npc)` | 判断活着的 BMB 能否按这些规则主动选择活着且适配已开启的 NPC。自定义扫描还需检查距离、视线和战斗状态。 |

自定义索敌可通过 `BMB.MobRelations.GetHostileTargetCandidates` 把 NPC 放进候选，再执行自己的目标检查。服务器开关见 [NPC 关系 ConVar 表](CONVARS.zh-CN.md#npc-关系)。跨基类的战斗规则已在游戏里验证。上面的两个示例已对照当前 Lua 源码核对。

## 燃烧

BMB 的生物有自己的一套燃烧：Minecraft 风格的时长、火焰和伤害。由 `BMB.Fire`（服务端）负责。

| 函数 | 作用 |
|---|---|
| `BMB.Fire.Ignite(mob, seconds, source)` | 点燃一只 BMB 生物，至少烧这么久。已经在烧、剩余时间更长的不会被缩短。生物在这之后处于燃烧状态时返回 `true`；生物已死亡、不是 BMB 生物或者 `FireImmune` 时返回 `false`。`source` 是你自己起的标签，会保存下来供 `GetSource` 读取。 |
| `BMB.Fire.IsBurning(mob)` | 是否在燃烧。 |
| `BMB.Fire.GetRemaining(mob)` | 还要烧多少秒。 |
| `BMB.Fire.GetSource(mob)` | 最近一次点燃时给的标签：`"sunlight"`，或者你自己的。 |
| `BMB.Fire.Extinguish(mob, reason)` | 把火扑灭，带熄灭的嘶嘶声。 |
| `BMB.Fire.Clear(mob)` | 无声地把火灭掉。 |

燃烧中的生物每 `bmb_sunlight_interval` 秒受到 `bmb_sunlight_damage` 点伤害。水会把火浇灭。

**BMB 生物和玩家要用不同的调用。** 引擎的 `Entity:Ignite()` 对玩家有效，但对 BMB 生物什么作用都没有，因为 BMB 会丢弃引擎的燃烧伤害。`BMB.Fire.Ignite` 只对 BMB 生物有效。一次能点燃这两类受害者的攻击：

```lua
function ENT:OnBMBMeleeHit(target, damageInfo)
    BaseClass.OnBMBMeleeHit(self, target, damageInfo)
    if not IsValid(target) then return end

    if target.IsBMBMob then
        BMB.Fire.Ignite(target, 3, "ember_zombie")
    elseif target:IsPlayer() and target:Alive() then
        target:Ignite(3)
    end
end
```

*两个分支都在游戏里跑过：玩家分支由示例跑过，生物分支在一只羊身上跑过。*

## 状态效果

`BMB.Status`（服务端）给生物和玩家施加有时限的效果。

| 函数 | 作用 |
|---|---|
| `BMB.Status.ApplyMobEffect(target, effect, params)` | 施加一个效果。对玩家，如果加载了 MineMod，就把效果交给 MineMod 的药水系统，这样玩家能看到图标；否则由 BMB 自己运行。平时用这个函数。返回效果有没有施加成功。 |
| `BMB.Status.Apply(target, effect, params)` | 用 BMB 自己的运行时施加效果，对玩家也是如此。 |
| `BMB.Status.Has(entity, effect)` | 实体在 BMB 的运行时里有没有这个效果。 |
| `BMB.Status.Clear(entity, effect)` | 移除一个效果。 |
| `BMB.Status.ClearAll(entity)` | 移除全部效果。 |

`target` 可以是玩家、NPC、NextBot 或 BMB 生物。`params.duration`（秒）是必填的。`params` 里的其它项会覆盖下表中效果自带的数值。

| 效果 | 作用 | 可以覆盖的数值 |
|---|---|---|
| `poison` | 每秒 2 点伤害，每秒一次。不会致死。亡灵生物免疫。 | `dps`、`interval` |
| `wither` | 每秒 1 点伤害，每 2 秒一次。可以致死。 | `dps`、`interval` |
| `slowness` | 移动速度 × 0.6。 | `mult` |
| `speed` | 移动速度 × 1.2。 | `mult` |
| `weakness` | 造成的近战伤害 − 4。 | `delta` |
| `regeneration` | 每 2.5 秒回复 1 点。 | `healPerTick`、`interval` |
| `fire_resistance` | 一个供其它代码检查的标记。 | |
| `water_breathing` | 一个供其它代码检查的标记。 | |
| `invisibility` | 一个供其它代码检查的标记。 | |

传 `source = self`，这样中毒和凋零造成的伤害会算在你的生物头上。

BMB 的洞穴蜘蛛就是这样让被它咬到的对象中毒的：

```lua
function ENT:OnBMBMeleeHit(target, damageInfo)
    BaseClass.OnBMBMeleeHit(self, target, damageInfo)

    BMB.Status.ApplyMobEffect(target, "poison", {
        duration = 7,
        interval = 1.25,
        dps = 2,
        source = self,
    })
end
```

*改写自 BMB 的 `bmb_cave_spider.lua`。在游戏里跑过：一只自定义僵尸咬了一只羊。*

## 方块世界

BMB 从不直接调用 MineMod。它通过一个适配器 `BMB.BlockWorld`（服务端）访问方块，适配器有两种实现：真实的 MineMod 世界，以及没有加载 MineMod 时使用的平地模拟世界。你的代码可以通过同一个适配器读取世界。

用 `BMB.SelectBlockWorld()` 取得适配器。它返回当前生效的那个；如果上次调用之后 MineMod 加载好了，它会切换到真实世界。

*cell*（格）是一个表 `{ x = , y = , z = }`，里面是整数的方块坐标，`z` 朝上。

| 函数 | 返回什么 |
|---|---|
| `world.WorldToBlock(position)` | 包含某个世界坐标的那一格。 |
| `world.BlockToWorld(cell)` | 一格对应的世界坐标：在真实世界里是它的中心。 |
| `world.IsSolid(cell)` | 这一格是否被挡住：被 MineMod 方块，或者被地图自身的几何体。 |
| `world.HasSupport(cell)` | 站在这一格里的生物脚下有没有东西。 |
| `world.GetBlockInfoAt(cell)` | 空气返回 `nil`。否则返回一个表，含有 `mcid`（例如 `"minecraft:grass_block"`）、`name`、`id` 和 `stateId`。 |
| `world.GetLightAt(cell)` | 一个表，含有 `level`、`blockLight` 和 `skyLight`（0 到 15，未知时为 `nil`）、`exact`（是实际采样还是估算）和 `reason`。 |
| `world.IsSkyExposedAt(cell)` | 正上方能看到天空时返回 `true`，有东西遮挡时返回 `false`，无法判断时返回 `nil` 和一个原因。 |
| `world.GetDaylightState()` | 一个表，含有 `ticks`（0 到 23999，Minecraft 的一天中的时刻）、`sunUp`、`sunStrength`（夜晚为 0，正午为 1）、`skyLevel`、`enabled` 和 `paused`。 |
| `world.GetLiquidAtPos(position)` | `nil`，或者一个描述该点所在液体的表。它的 `kind` 是 `"water"` 或 `"lava"`。 |
| `world.IsWaterAt(cell)` | 这一格里是不是水。 |
| `world.GetRandomWalkablePoint(origin, radius, mob)` | `origin` 附近一个生物能站的随机位置。找不到时返回 `origin` 本身。 |

`BMB.Pathfinder`（服务端）另外提供两项会考虑生物体型的检查：

| 函数 | 返回什么 |
|---|---|
| `BMB.Pathfinder.IsStandablePosition(position, { mob = mob })` | 生物能否站在那里，以及对应的格。 |
| `BMB.Pathfinder.FindNearestStandable(position, { mob = mob, searchRadiusCells = 4 })` | 生物能站的最近位置，或 `nil`。 |

```lua
local world = BMB.SelectBlockWorld()
local cell = world.WorldToBlock(self:GetPos())
local below = world.GetBlockInfoAt({ x = cell.x, y = cell.y, z = cell.z - 1 })
local onSand = below ~= nil and below.mcid == "minecraft:sand"
```

*上面两张表里的适配器函数都在游戏里对着真实的 MineMod 世界跑过，只有 `GetLiquidAtPos` 和 `IsWaterAt` 没有在液体里试过。这段代码本身没有跑过。*

适配器还有修改方块的函数 `world.SetBlockAt` 和 `world.RemoveBlockAt`。BMB 的生物用它们做羊吃草之类的事。这里不展开说明；用之前先读 BMB 是怎么调用它们的。

## 掉落物与经验

BMB 的生物死亡时，BMB 会为它掷 Minecraft 的掉落表，并通过 MineMod 掉出物品和经验。**自定义类完全没有这些。** 掉落表是按类名在一份生成出来的、只包含 BMB 自己的类的列表里查的。不在列表里的类会被报告为 `unmapped_mob`，什么都不掷。继承 `bmb_zombie` 也改变不了这一点，因为查表用的是生物自己的类名。

*1.0.0 之后。*BMB 的内置死亡流程在生物死亡时读取服务器的奖励模式。设置适用于手动生成和自然刷新的 BMB 生物，包括装备和手持物。物品寿命在掉落实体生成时读取。经验仍按玩家击杀归属判定。`BMBDroppedEntityLoot` 和 `BMBDroppedEntityExperience` 在对应奖励启用时触发。两个设置见 [生物死亡奖励](CONVARS.zh-CN.md#生物死亡奖励)。

自定义死亡回调直接调用生成函数时，由回调决定发放哪些奖励。自定义生物可以自行读取这两个 ConVar，以遵循同一套服务器设置。

你可以自己掉东西。`OnBMBDeathCleanup` 就是 BMB 掉落自己战利品的时刻：尸体即将在烟雾中消失。

```lua
function ENT:OnKilled(damageInfo)
    BaseClass.OnKilled(self, damageInfo)

    -- 趁致命一击的信息还在时掷表（抢夺附魔、是否由玩家击杀）。
    if BMB.Loot and BMB.Loot.BuildContext and BMB.Loot.EvaluateTable then
        local context = BMB.Loot.BuildContext(self, damageInfo)
        local ok, stacks = pcall(BMB.Loot.EvaluateTable, "minecraft:entities/zombie", context)
        self.EmberLoot = { context = context, stacks = ok and stacks or {} }
    end
end

function ENT:OnBMBDeathCleanup(corpse)
    local loot = self.EmberLoot
    if not loot or not BMB.Loot.SpawnStacks then return end

    BMB.Loot.SpawnStacks(self, loot.stacks, loot.context, self:WorldSpaceCenter())
end
```

*在加载了 MineMod 的游戏里跑过：杀了六只生物，凡是掷出了物品的，物品都掉了出来。*

| 函数 | 作用 |
|---|---|
| `BMB.Loot.BuildContext(mob, damageInfo)` | 收集掉落规则需要的信息：攻击者、最近 5 秒内有没有玩家造成过伤害、所用的武器。 |
| `BMB.Loot.EvaluateTable(tableId, context)` | 掷一张 BMB 自带的掉落表，名字形如 `"minecraft:entities/zombie"`。返回一个物品堆的列表。 |
| `BMB.Loot.SpawnStacks(mob, stacks, context, position[, lifetimeSeconds])` | 把物品堆生成为掉落物实体并返回生成数量。*1.0.0 之后*可传入以游戏秒计的可选寿命。省略时用 MineMod 的默认值。此函数需要 MineMod 的物品栏 API。 |

一个物品堆是形如 `{ item = "minecraft:rotten_flesh", count = 2 }` 的表。你可以不掷表，自己构造这个列表；游戏测试里也掉落过一份手写的列表。

这三个函数是掉落系统的内部接口，是本页最有可能变动的部分。

## 调试工具的指令

BMB Debug 工具和 `bmb_debug_move` 命令通过在生物上设置字段来指挥它。行为循环里的 `RunBMBDebugMove` 负责执行指令，所以保留标准循环的生物不需要为此写任何代码。工具本身的说明见 [ConVar 参考](CONVARS.zh-CN.md#bmb-debug-工具)。

| 方法 | 作用 |
|---|---|
| `HasBMBDebugMove()` | 有指令在执行时返回一个真值。 |
| `ClearBMBDebugMove(reason, detail)` | 丢掉正在执行的指令。当你的生物有某个行为必须从指令手里接管时调用它，蜘蛛爬墙就是这么做的。在 1.0.0 里它不接受参数。*1.0.0 之后*两个参数都是可选的：`reason` 会被记为这条指令的结果，不传的话结果是 `cancelled`。 |

*1.0.0 之后*，指令结束时会把结果留在生物身上，BMB 还会触发游戏钩子 `BMBDebugMoveFinished`，参数是生物、结果和细节。

| 生物上的字段 | 内容 |
|---|---|
| `BMBDebugMoveResult` | 上一条指令为什么结束：`arrived`、`no_progress`、`expired`、`stopped`、`climb`、`cancelled`、`done`、`unsafe`、`blocked` 或 `stuck`。每个值的含义见 ConVar 参考。下达新指令后变回 `nil`。 |
| `BMBDebugMoveResultDetail` | 结果是 `no_progress` 时：生物最后的移动模式；没找到路径时是 `no_path`。其它结果下，它是传给 `ClearBMBDebugMove` 的那个值，通常是 `nil`。 |
| `BMBDebugMoveResultAt` | 指令结束时的 `CurTime()`。 |
| `BMBDebugMoveLastTarget` | 已结束的那条指令的目标，是一个 `Vector`。`bmb_debug_move` 行走的话是 `nil`。 |
| `BMBDebugMoveOwner` | 下达指令的玩家。 |
| `BMBDebugMoveSerial` | 这只生物收到过的指令的计数。BMB 用它区分新指令和前一条指令。 |

下面这些字段用来调整右键指令。和其它字段一样写在你的类上。

| 字段 | 默认值 | 含义 |
|---|---|---|
| `DebugPathCommandTimeout` | 120 | 指令在多少秒后到期。目标非常远时会更长。 |
| `DebugPathProgressGrace` | 8.0 | 每次有进展之后，指令至少还能持续这么久。 |
| `DebugPathNoProgressTimeout` | 3.5 | 没有进展多久之后生物放弃。 |
| `DebugPathNoProgressMinAttempts` | 3 | *1.0.0 之后。*放弃之前还需要连续这么多次尝试都没有进展。 |
| `DebugPathNoProgressHardScale` | 4 | *1.0.0 之后。*没有进展的时间达到 `DebugPathNoProgressTimeout` × 这个数时，不管尝试了几次都放弃。 |
| `DebugPathDetourTimeout` | 45 | *1.0.0 之后。*沿着路径走、但没有更靠近目标的情况，最多在多长时间内仍算作进展。 |
| `DebugPathCacheTTL` | 2.5 | *1.0.0 之后。*每次尝试使用的 `pathCacheTTL`。生物自己的 `PathCacheTTL` 更大时用更大的那个。1.0.0 用的是生物平时的路径有效期。 |
| `DebugPathRepathDelay` | 0.25 | 下一次尝试之前的停顿。*1.0.0 之后*只在失败或没有进展的尝试之后才停顿。 |
| `DebugPathSegmentMinTimeout` | 3.0 | 一次尝试最短的允许时间。 |
| `DebugPathTimeoutBase`、`DebugPathTimeoutScale`、`DebugPathTimeoutMax` | 4.0、3.0、90 | 一次尝试的允许时间：基础值，加上倍率 × 按生物的速度走完路径所需的时间，不超过上限。 |
| `DebugPathFlightSegmentTime` | 2.5 | *1.0.0 之后。*飞行生物：一次尝试的时长。 |
| `DebugPathFlightHandoff` | 0.3 | *1.0.0 之后。*飞行生物：一次尝试结束后，它的飞行指令还继续生效多少秒，这样生物不会在下一次尝试接手之前停下来。 |
| `DebugPathRecenterTime` | 1.0 | *1.0.0 之后。*把挂在方块角上的生物挪回它那一格中间所允许的时间。 |
| `DebugPathRecenterTolerance` | 1.5 | *1.0.0 之后。*离中间多近算到位，以 Source 单位计。 |
| `DebugPathRecenterMinSpeed` | 20 | *1.0.0 之后。*挪回去时使用的最低速度。 |

## BMB 触发的游戏钩子

BMB 用 `hook.Run` 触发这些钩子。用 `hook.Add` 监听。全部在服务端。

### 通用

| 钩子 | 参数 | 用途 |
|---|---|---|
| `OnNPCKilled` | `mob, attacker, inflictor` | Garry's Mod 的标准钩子。BMB 的生物（包括自定义生物）死亡时，BMB 会触发它。 |
| `BMB.IsMinecraftEnemy` | `entity, context` | 返回 `true` 让一个实体算作怪物。它是最后才被询问的，见[生物关系](#生物关系)。 |
| `BMB.GetNPCTemperament` | `npc, base` | *1.0.0 之后。*返回 `"friendly"`、`"neutral"` 或 `"hostile"` 覆盖分类。返回 `nil` 时走正常分类流程。`base` 为 `"native"`、`"vj"` 或 `"drg"`。 |
| `BMB.ResolveMinecraftDifficultyId` | `mob` | 返回 0 到 3，为这只生物覆盖 `bmb_minecraft_difficulty`。 |
| `MC.ModifyEntityIgnitionDuration` | `mob, seconds, context` | 返回一个数字，改变调用 `BMB.Fire.Ignite` 时生物燃烧的时长。 |
| `MC.IgniteEntity` | `entity, seconds, context` | BMB 的火球即将点燃一个实体时触发。返回 `nil` 以外的任何值表示由你接管；`false` 表示这个实体没有被点燃。 |
| `PlayerShouldTakeDamage` | `target, owner` | Garry's Mod 的标准钩子。驯服的宠物替主人攻击玩家之前会询问它；返回 `false` 会阻止这次攻击。 |
| `BMBAnimalBred` | `loveCause, firstParent, secondParent, child` | 两只动物完成了繁殖。`loveCause` 是喂食的玩家（如果知道的话）。 |
| `BMBShouldDropBreedingExperience` | `firstParent, secondParent, child, loveCause` | 返回 `false` 则繁殖不掉落经验。 |
| `BMBShouldDropExperience` | `mob, context` | 返回 `false` 则垂死的生物不掉落经验。仅限 BMB 自己的类。 |
| `BMBDroppedEntityLoot` | `mob, stacks, spawnedCount, lastDamagePlayer` | 一只生物的掉落物已经掉出。仅限 BMB 自己的类。 |
| `BMBDroppedEntityExperience` | `mob, amount, orbs, lastDamagePlayer, context` | 一只生物的经验已经掉出。仅限 BMB 自己的类。 |
| `BMBDebugMoveFinished` | `mob, reason, detail` | *1.0.0 之后。*调试工具的一条指令结束了。`reason` 和 `detail` 的含义见[调试工具的指令](#调试工具的指令)。 |

### 针对单个生物

这些钩子报告某一种 BMB 生物做了什么，或者让别的 addon 替它回答一个问题。除非列表里另有说明，第一个参数都是那只生物。

| 生物 | 事件（没有返回值） |
|---|---|
| 悦灵 | `BMB.AllayItemGiven (allay, player, stack, infinite)`、`BMB.AllayDropInternalInventory (allay, player)`、`BMB.AllaySwingMainHand (allay, player, serial)`、`BMB.AllayDuplicated (allay, child, player)` |
| 鸡 | `BMB.ChickenFlap (chicken)` |
| 铜傀儡 | `BMB.CopperGolemOxidationChanged (golem, previous, level, reason)`、`BMB.CopperGolemBecameStatue (golem, cell, stateId, spec)`、`BMB.CopperGolemAntennaChanged (golem, item, reason)`、`BMB.CopperGolemSurfaceEvent (golem, kind, serial)`、`BMB.CopperGolemInteractionStopped (golem, previous, reason)` |
| 溺尸 | `BMBDrownedThrewTrident (drowned, target, projectile)` |
| 末影人 | `BMBEndermanBlockPickedUp (enderman, cell, info, defaultState)`、`BMBEndermanBlockPlaced (enderman, cell, stateId, spec, mcid)`、`BMBEndermanCarriedBlockDrop (enderman, stateId, spec, mcid)` |
| 哞菇 | `BMB.MooshroomStewCollected (player, mooshroom, result)` |
| 猪灵、掠夺者 | `BMBPiglinFiredCrossbow (piglin, target, arrow)`、`BMBPillagerFiredCrossbow (pillager, target, arrow)` |
| 雪傀儡 | `BMBSnowGolemPlacedSnow (golem, cell, stateId)` |
| 村民、流浪商人 | `BMB.MerchantTradeCommitted (merchant, player, offerIndex, offer)`、`BMB.MerchantRestocked (merchant)`、`BMB.MerchantUnavailable (merchant, reason)`、`BMB.VillagerTradeReputation (villager, player)`、`BMB.ReputationEvent (villager, eventType, actor)` |
| 监守者和其它监听振动的生物 | `BMB.VibrationReceived (listener, signal)` |
| 女巫 | `BMBWitchStartedDrinking (witch, potionId)`、`BMBWitchFinishedDrinking (witch, potionId, definition)`、`BMBWitchThrewPotion (witch, target, projectile, potionId)` |
| 驯服的宠物 | `BMB.PetPersistenceChanged (mob, data, revision)` |

| 生物 | 询问（返回值会被使用） |
|---|---|
| 任何生物 | `BMB.IsMobLeashed (mob)`、`BMB.IsMobPassenger (mob)`、`BMB.IsMobVehicle (mob)` |
| 犰狳 | `BMB.IsPlayerSprinting (player)` |
| 猫、狐狸、羊驼、狼 | `BMB_SelectCatVariant (cat, options)`、`BMB_SelectFoxVariant (fox, options)`、`BMB_SelectLlamaVariant (llama, options)`、`BMB_SelectWolfVariant (wolf, options)` |
| 铜傀儡 | `BMB.CopperGolemWaxChanged (golem, waxed, reason)` |
| 溺尸 | `BMB.IsEntityInMinecraftWater (target, drowned)` |
| 羊驼 | `BMB.IsLlamaPassenger (llama)`、`BMB.IsLlamaVehicle (llama)`、`BMB.GetLlamaPassengerCount (llama, playersOnly)`、`BMB.ResolveLlamaLeashHolder (llama)`、`BMB.ResolveLlamaCaravanAnchor (llama)` |
| 雪傀儡 | `BMB_SnowGolemMelts (golem, sample)` |
| 行商羊驼 | `BMB.ResolveTraderLlamaOwner (llama)`、`BMB.ResolveTraderLlamaDefenseEvent (llama, owner)`、`BMB.RunTraderLlamaOwnerFollow (llama, owner)`、`BMB.CanTraderLlamaDespawn (llama, owner)`、`BMB.GetTraderLlamaOwnerDespawnDelay (llama, owner)` |
| 村民、流浪商人 | `BMB.OpenMerchant (player, merchant)`、`BMB.GetMerchantSpecialPrice (merchant, player, offer)`、`BMB.GetVillagerReputation (villager, player)` |
| 监守者 | `BMB.WardenDamageBypassesInvulnerability (warden, damageInfo)` |
| 女巫 | `BMBTargetVisibilityPercent (target, witch)`、`BMBWitchHasActiveRaid (witch)` |

询问类的钩子该返回什么、BMB 拿返回值做什么，每个钩子都不一样。回答之前先读 BMB 源码里调用它的地方。

## 联网变量

BMB 用 `SetNW*` 在每只生物上发布这些值。在客户端用 `ent:GetNWString("BMBState")` 这样的调用读取。

| 名字 | 类型 | 含义 |
|---|---|---|
| `BMBState` | string | 当前的状态名，由 `SetBMBState` 设置。 |
| `BMBStateStartedAt` | float | 状态最近一次变化时的 `CurTime()`。 |
| `BMBMoveMode` | string | 当前的移动标签。 |
| `BMBHealth` | int | 当前生命值。 |
| `BMBDead` | bool | 生物已经死亡，正等着被移除。 |
| `BMBDesiredSpeed` | float | 生物当前被要求达到的移动速度。 |
| `BMBActivitySpeed` | float | 动画应该表现出的速度：走还是跑。 |
| `BMBHurtFlashUntil` | float | 闪红持续到的 `CurTime()`。 |
| `BMBInvulnerableUntil` | float | 受击后无敌窗口的结束时间。 |
| `BMBKnockbackUntil` | float | 击退的结束时间。 |
| `BMBAttackStartedAt` | float | 最近一次近战挥击或射击时的 `CurTime()`。 |
| `BMBOnFire` | bool | 正在燃烧。 |
| `BMBFireUntil` | float | 火焰结束时的 `CurTime()`。 |
| `BMBInSunlight` | bool | 正站在会点燃它的阳光下。只对白天会燃烧的生物保持更新。 |

`BMBDistToGoal`、`BMBPathNode`、`BMBPathAdvance` 和各个 `BMBHop...` 值是给调试 HUD 用的。只有当某个玩家打开了 `bmb_debug_hud` 时服务端才会写它们，所以不要把它们用在别的地方。

*1.0.0 之后*，调试工具为了自己的显示另外发布三个值：`BMBDebugMoveTargetPos`（vector），生物最近一条右键指令的目标；`BMBDebugMoveResult`（string），指令执行期间为空，结束后是它的结果；`BMBDebugMoveResultAt`（float），指令结束时的 `CurTime()`。

生物有名字的话，名字在 `ent:GetNW2String("BMBCustomName")` 里；`ent:GetBMBCustomName()` 会替你读出来。
