# BMB API reference for custom mobs

[中文版](API.zh-CN.md) · [Back to the README](../README.md) · [ConVar reference](CONVARS.md)

What a custom mob can set, override and call in [Minecraft in GMod | Mobs](https://steamcommunity.com/sharedfiles/filedetails/?id=3774268246) (BMB). Read the [README](../README.md) first: it builds a working mob step by step. This page is the lookup table for when you want to go further.

## Status of this page

- Unless marked *after 1.0.0*, it describes **BMB 1.0.0**, the Workshop build published on 2026-11-20. Those names were checked by script against the Lua source of that build. Later entries were checked against the updated source.
- BMB has **no stable API yet**. This page describes what the code does today; it is not a promise that it stays that way. Test your mob after every BMB update.
- Three kinds of things are listed, and they are not equally safe to depend on:

  | Kind | What it is | How likely to change |
  |---|---|---|
  | **Fields** | Numbers and flags on `ENT`, such as `ENT.StartHealth`. | Least likely. BMB's own mobs are written the same way. |
  | **Hooks** | Functions BMB calls on your mob if you define them, such as `ENT:OnBMBMeleeHit`. | Unlikely, for the same reason. |
  | **Internals** | Everything else you can reach under `BMB.` or on the entity. | May change in any update. |

- Much of this page was also run in game. On 2026-11-25 a single-player session against this build ran the code examples and made 182 checks against what this page says. 181 passed. The one that failed was about `MoveToWorldPosition`, and [Moving](#moving) now says what the game does. Each code example says whether it was run.
- What was not run was written from the source. That includes the field tables, the passive-animal hooks, most of the game hooks, and anything on a listen or dedicated server.
- A few entries are marked *after 1.0.0*. The 2026-11-25 entries describe the debug-tool rework and villager-targeting fix. These changes are in BMB's source and not in the 1.0.0 Workshop build. The entries were checked against that source and were not run in game for this page.

## Contents

- [Where BMB code runs](#where-bmb-code-runs)
- [Class tree](#class-tree)
- [Life of a mob](#life-of-a-mob)
- [Fields](#fields)
- [Hooks you can define](#hooks-you-can-define)
- [Methods you can call](#methods-you-can-call)
- [Behaviour modules](#behaviour-modules)
- [Global functions](#global-functions)
- [Natural spawning](#natural-spawning)
- [Mob relations](#mob-relations)
- [Fire](#fire)
- [Status effects](#status-effects)
- [Block world](#block-world)
- [Drops and experience](#drops-and-experience)
- [Debug tool orders](#debug-tool-orders)
- [Game hooks BMB fires](#game-hooks-bmb-fires)
- [Networked values](#networked-values)

## Where BMB code runs

BMB's `lua/autorun/bmb_autorun.lua` creates the global table `BMB`. What it holds depends on the side:

| Available on | Tables and functions |
|---|---|
| Server and client | `BMB.Version`, `BMB.BS`, `BMB.GetBlockSize`, `BMB.GetHealthScale`, `BMB.ScaleMobHealth`, the mob registry (`BMB.ForEachMob` and friends), `BMB.L`, `BMB.GetLanguage` |
| Server only | `BMB.Behaviors`, `BMB.NaturalSpawn`, `BMB.MobRelations`, `BMB.NPCRelations` (*after 1.0.0*), `BMB.Fire`, `BMB.Status`, `BMB.BlockWorld`, `BMB.Pathfinder`, `BMB.Loot`, `BMB.Targeting` |

Two timing rules follow from how Garry's Mod loads addons:

- **In your entity file**, `BMB` already exists. Entity files load after every addon's autorun files, so `BMB.BS` and `DEFINE_BASECLASS("bmb_zombie")` are safe at the top of the file.
- **In your autorun file**, `BMB` may not exist yet, because the order in which addons load is not guaranteed. Do your registration in an `InitPostEntity` hook, as the example does.

Mob logic runs on the server. The client draws the mob and animates its bones. A method on this page is server-side unless it says otherwise.

## Class tree

```
base_nextbot
└─ bmb_base_mob                everything shared: movement, damage, death, rendering
   ├─ bmb_zombie               melee monster
   │  ├─ bmb_husk
   │  ├─ bmb_drowned
   │  ├─ bmb_zombie_villager
   │  └─ bmb_zombie_pigman
   ├─ bmb_skeleton             ranged monster
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
   ├─ bmb_passive_animal       panic when hurt, wander otherwise
   │  ├─ bmb_sheep, bmb_pig, bmb_chicken, bmb_rabbit
   │  ├─ bmb_cow
   │  │  └─ bmb_mooshroom
   │  ├─ bmb_cat, bmb_ocelot, bmb_fox, bmb_goat, bmb_panda, bmb_polar_bear
   │  ├─ bmb_armadillo, bmb_sniffer, bmb_camel, bmb_camel_husk
   │  ├─ bmb_llama, bmb_trader_llama
   │  └─ bmb_villager, bmb_wandering_trader, bmb_copper_golem
   └─ directly on bmb_base_mob:
      bmb_creeper, bmb_enderman, bmb_wolf, bmb_bee, bmb_bat, bmb_witch,
      bmb_blaze, bmb_ghast, bmb_happy_ghast, bmb_phantom, bmb_vex, bmb_allay,
      bmb_parrot, bmb_breeze, bmb_evoker, bmb_vindicator, bmb_pillager,
      bmb_ravager, bmb_piglin, bmb_piglin_brute, bmb_hoglin, bmb_zoglin,
      bmb_iron_golem, bmb_snow_golem, bmb_shulker, bmb_warden, bmb_creaking
```

Only `bmb_zombie` has been used as a parent by this example. If you pick another one, read its file first. Things to look for:

- **The AI function.** Each family's `RunBehaviour` loop calls one function for its decisions, and that is the one to override. Its name differs per family: `RunBMBZombieAI` (zombie family), `RunBMBSkeletonAI` (skeleton family), `RunBMBSpiderAI`, `RunBMBCreeperAI`, `RunBMBSlimeAI`, `RunBMBWolfAI`, `RunBMBEndermanAI`, and so on. Passive animals have no such function; see [Passive animals](#passive-animals).
- **Data keyed by class name.** Some mobs look things up by their own class name (sound sets, baby models, loot). A child class with a new name misses those entries. The zombie's sound lookup falls back to `ENT.Sounds`, which is why overriding `ENT.Sounds` works there.
- **Where the code is.** The older mobs keep everything in `lua/entities/bmb_<name>.lua`. The newer ones split it across `lua/bmb/mobs/<name>/`, and the entity file only includes those parts.

## Life of a mob

### Spawning

Garry's Mod calls `ENT:Initialize()` on both sides. On the client BMB's version returns at once. On the server it calls `self:BaseInitialize()`, which:

1. sets the model from `self.Model` and the collision box from `self.CollisionMins` / `self.CollisionMaxs`;
2. sets health to `self.StartHealth` × the server's `bmb_health_scale`;
3. copies `StepHeight`, `TurnRate`, `Acceleration`, `Deceleration` and `WalkSpeed` into the NextBot locomotion;
4. picks the block world (MineMod's when it is loaded);
5. publishes the starting [networked values](#networked-values).

The zombie's `Initialize` then sets the state to `idle` and resets its targeting and sound timers. That is why your own `Initialize` must call `BaseClass.Initialize(self)` first.

After `BaseInitialize`, `self.StartHealth` holds the scaled health and `self.BMBBaseHealth` the value you wrote.

### The behaviour coroutine

`ENT:RunBehaviour()` is the standard NextBot coroutine and runs on the server. Every BMB family writes it as the same loop:

```lua
while true do
    if self.BMBDead then return
    elseif self:MaintainBMBFreeze() then coroutine.wait(0.05)      -- bmb_freeze, debug tool
    elseif self.BMBHeld then ...                                    -- physics gun
    elseif self:RunBMBKnockback() then ...                          -- just got hit
    elseif self:RunBMBDebugMove() then ...                          -- debug tool order
    elseif self:RunBMBStrandedRecovery() then ...                   -- standing somewhere illegal
    else self:RunBMBZombieAI() end                                  -- the family's AI function

    coroutine.yield()
end
```

Override the AI function, not `RunBehaviour`, so that your mob keeps handling the states above it.

Inside the AI function you are in a coroutine. Calls such as `MoveToWorldPosition` and `InterruptibleWait` block: they return only when the move or the wait is over. The function is called again right after it returns, so it should do one decision's worth of work and return.

How often the coroutine resumes is decided by the engine, not by BMB. According to BMB's own measurements it resumes every tick in single player and about ten times a second on a listen server. In the single-player test for this page, with the frame rate capped at 60, it resumed 60 times a second. Do not assume one `coroutine.yield()` is one tick.

### Think

`ENT:Think()` runs every tick on both sides and does a great deal of upkeep: on the server the look controller, liquids, fall damage, block hops, idle sounds and more; on the client the bone animation. If you override `Think`, call the parent's and return what it returns:

```lua
function ENT:Think()
    -- your per-tick code
    return BaseClass.Think(self)
end
```

*Run in game, on the server and on the client.*

### Taking damage

`ENT:OnTakeDamage(damageInfo)` on the server goes through these steps in order. Any step can end the pipeline.

1. Dead mobs and damage of 0 or less are ignored.
2. **Engine fire is ignored.** Damage of type `DMG_BURN` or `DMG_SLOWBURN` that does not come from BMB's own fire system is dropped. `Entity:Ignite()` therefore does not hurt a BMB mob; use [`BMB.Fire.Ignite`](#fire).
3. Potion immunities from MineMod are applied.
4. `self:IsBMBDamageImmune(damageInfo)` is asked, if you defined it. Returning `true` drops the damage with no other effect.
5. If the mob was hit less than `DamageInvulnerabilityTime` (0.5 s) ago, the damage is dropped. Fire and other environmental damage skip this check.
6. The damage is accepted: the invulnerability window starts, the mob flashes red for `HurtFlashTime`, and `self:OnBMBHurtSound(damageInfo)` is called.
7. Health goes down.
8. If health reached 0, `self:OnKilled(damageInfo)` is called. Otherwise the mob is knocked back, its current move is interrupted, it [retaliates](#targeting) if it can, and `self:OnBMBInjured(damageInfo, wasFleeing)` is called.

### Dying

`OnKilled` calls `self:BeginBMBDeath(damageInfo)`, which runs once per mob:

1. Status effects are cleared. The mob stops moving, becomes non-solid, and its state becomes `dead`. `self.BMBDead` is `true` from here on.
2. A lethal hit shoves the body a short way.
3. The standard `OnNPCKilled` game hook is run with the mob, the attacker and the inflictor.
4. Drops are rolled (BMB's own classes only, see [Drops and experience](#drops-and-experience)).
5. After `DeathRemoveDelay` seconds (1.0 by default) `self:OnBMBDeathCleanup(corpse)` is called, the death poof plays, the drops appear, and the entity is removed.

The body tipping over during that second is drawn on the client by the family's bone code.

## Fields

Set these as `ENT.Name = value` in your entity file. A field you leave out keeps the parent's value. The *Base* column is the value on `bmb_base_mob`; the *Zombie* column is `bmb_zombie`. Speeds are Source units per second, distances are Source units unless the name ends in `Cells`, and times are seconds.

The complete lists, with comments, are in BMB's `lua/bmb/base/sh_defaults.lua` (every mob) and at the top of `lua/entities/bmb_zombie.lua` (the zombie family).

### Identity

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `Model` | `models/kleiner.mdl` | zombie model | Model path. |
| `IsBMBMob` | `true` | | Marks the entity as a BMB mob. Do not change it. |
| `IsUndead` | not set | `true` | Undead mobs are immune to poison. Also required for `BurnsInDaylight`. |
| `BurnsInDaylight` | not set | `true` | Catches fire under an open sky by day. Only has an effect when `IsUndead` is `true`. |
| `FireImmune` | `false` | | Cannot be set on fire by sunlight, lava or fire blocks. |
| `BMBMinecraftEnemy` | not set | | `true` or `false` decides whether the mob counts as a Minecraft monster. See [Mob relations](#mob-relations). |
| `SupportsForcedFlee` | `false` | | `true` on passive animals. Tells the debug tool the mob has a panic behaviour. |

### Health and being hit

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `StartHealth` | 20 | 70 | Health before `bmb_health_scale`. BMB uses Minecraft health × 3.5. |
| `DamageInvulnerabilityTime` | 0.5 | | Time after an accepted hit during which further hits are ignored. |
| `HurtFlashTime` | 0.5 | | How long the mob flashes red. |
| `RetaliateOnDamage` | `true` | | Attack whoever hurt it. Needs `CanBMBTarget`. Passive animals set it to `false`. |
| `RetaliateSameClass` | `true` | | Also retaliate against its own class. |
| `KnockbackMinSpeed` | 150 | | Lowest knockback speed when hit. |
| `KnockbackMaxSpeed` | 320 | | Highest knockback speed when hit. |
| `KnockbackDamageSpeedScale` | 8 | | Knockback speed gained per point of damage. |
| `KnockbackDuration` | 0.12 | | How long the knockback overrides its movement. |
| `KnockbackUseJump` | `true` | | Lift the mob off the ground when knocked back. |
| `FallDamageImmune` | `false` | | Takes no fall damage. |
| `FallSafeDistanceCells` | `nil` | | Blocks it may fall unhurt. `nil` uses `bmb_fall_damage_safe_distance`. |
| `FallDamageMultiplier` | `nil` | | Fall damage multiplier. `nil` uses `bmb_fall_damage_multiplier`. |
| `CanFloatInWater` | `true` | `false` | Floats in water. Zombies and skeletons sink and walk on the bottom. |

### Movement

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `WalkSpeed` | 80 | about 71 | Wander speed. |
| `RunSpeed` | 120 | about 71 | Chase and flee speed. |
| `Acceleration` | 420 | 420 | |
| `Deceleration` | 650 | 650 | |
| `TurnRate` | 400 | | Fastest turn, in degrees per second. |
| `TurnInPlaceAngle` | 110 | 170 | If the goal is further behind than this many degrees, turn before walking. |
| `CollisionMins`, `CollisionMaxs` | ±16 wide, 48 tall | 0.6 × 1.95 blocks | Collision box. The pathfinder uses it to decide where the mob fits. |
| `StepHeight` | 28 | | Highest ledge it walks up without jumping. Deliberately above a half slab and below a full block. |
| `MaxPathDropCells` | 3 | | Longest drop, in blocks, the pathfinder will plan. |
| `MobSeparationEnabled` | `true` | | Pushed apart from other mobs it overlaps. |

### Targeting

Used by `BMB.Behaviors.SeekTarget`.

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `TargetRange` | not set (900 is used) | 35 blocks | How far away it notices a target. |
| `TargetLoseRange` | not set (`TargetRange` × 1.25) | 35 blocks | How far away it keeps a target it already has. |
| `TargetScanInterval` | not set (0.35) | 0.35 | Time between scans for a new target. |
| `TargetRequireLineOfSight` | not set | `false` | Must see the target to pick it. A target it already has is kept for a while after it loses sight of it. |
| `TargetVillagers` | not set (disabled) | `true` | *After 1.0.0.* Add villagers and wandering traders to the shared natural-target scan. See [Villager targets](#villager-targets-after-100). |
| `TargetUnseenMemoryTicks` | 60 | | How long it remembers a target it cannot see, in 1/20 s. Only with line of sight required. |
| `RetaliationUnseenMemoryTicks` | 300 | | The same for a target it is retaliating against. |

### Chasing

Used by `BMB.Behaviors.Chase`.

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `ChasePreferDirect` | not set | `true` | Run straight at a visible target when the way is clear, instead of following a computed path. |
| `ChaseDirectMaxDistanceCells` | not set | 6 | Farthest target it runs straight at. |
| `ChaseDirectProbeCells` | not set (4) | 4 | How far ahead a straight run is checked for walls and drops. |
| `ChaseSegmentTimeout` | not set | 2.0 | Longest time it follows one computed path before planning again. |
| `ChaseStepUpHopEnabled` | `true` | | Jump a one-block step met during a straight run. |

### Melee

Used by `BMB.Behaviors.MeleeAttack`.

| Field | Default if not set | Zombie | Meaning |
|---|---|---|---|
| `AttackRange` | one block | 60 | Horizontal reach. |
| `AttackVerticalRange` | `AttackRange` × 0.65 | 28 | Height difference it can hit across. |
| `AttackDamage` | 2 | 10.5 | Damage per hit. |
| `AttackDamageType` | `DMG_SLASH` | | Damage type. |
| `AttackCooldown` | 1.0 | 1.0 | Time between swings. |
| `AttackHitDelay` | 0.25 | 0 | Delay between starting a swing and the hit landing. |
| `AttackHitSlop` | 0.35 block | 16 | Extra reach allowed when the hit lands, so a target stepping back is still hit. |
| `AttackMoveSpeed` | `RunSpeed` | about 71 | Speed kept while swinging. Keep it equal to `RunSpeed`. |
| `AttackKnockback` | 0 | 150 | Horizontal knockback on the victim. |
| `AttackVerticalKnockback` | 0 | 155 | Upward knockback on the victim. |
| `AttackGroundedVerticalKnockback` | `AttackVerticalKnockback` | 190 | Upward knockback on a player standing on the ground. |

### Wandering and fleeing

Used by `BMB.Behaviors.Wander` and `BMB.Behaviors.Flee`.

| Field | Default if not set | Zombie | Passive animal | Meaning |
|---|---|---|---|---|
| `WanderDistanceMinCells` | 2 | 2 | 3 | Shortest stroll, in blocks. |
| `WanderDistanceMaxCells` | 5 | 5 | 8 | Longest stroll, in blocks. |
| `WanderPauseMin` | 6.0 | 0.5 | 6.0 | Shortest rest after a stroll. |
| `WanderPauseMax` | 14.0 | 1.8 | 14.0 | Longest rest after a stroll. |
| `FleeDurationMin` | | | 3.5 | Shortest panic after being hurt. |
| `FleeDurationMax` | | | 5.0 | Longest panic after being hurt. |
| `FleePanicRadiusCells` | 5 | | 5 | How far away it picks points to run to. |
| `FleeGiveUpFailures` | 4 | | 4 | Failed attempts in a row before it stops panicking. |

### Sounds

| Field | Zombie | Meaning |
|---|---|---|
| `Sounds` | five lists | Zombie family. A table with the lists `Say`, `Hurt`, `Death`, `Step` and `Hit`. See *Sounds* in the README for the merge catch. |
| `AmbientSoundIntervalTicks` | 80 | Quiet time after an idle sound, in 1/20 s. After it, the chance of the next one grows every tick. |
| `AmbientSoundChanceDenominator` | 1000 | Higher makes idle sounds rarer. |
| `StepSoundDistance` | 26 | Distance walked per footstep sound. |
| `StepSoundVolumeMin`, `StepSoundVolumeMax` | 0.15 | Footstep volume at low and at full speed. |

### Death

| Field | Base | Meaning |
|---|---|---|
| `DeathRemoveDelay` | 1.0 | Seconds the body stays. `false` keeps it forever. |
| `DeathPoofEffect` | `bmb_death_poof` | Effect played when the body disappears. `false` plays none. |
| `DeathKeepRed` | `true` | The body stays tinted red. |
| `DeathKnockbackEnabled` | `true` | A lethal hit shoves the body. |
| `UseRagdollOnDeath` | `false` | Turn into a ragdoll instead. |
| `UsePhysicsCorpseOnDeath` | `false` | Leave a physics prop of the model instead. |

### Looking around

| Field | Base | Zombie | Meaning |
|---|---|---|---|
| `LookAtEnabled` | `true` | | Glances at nearby players now and then. |
| `LookAtHeadBoneName` | `head` | | Bone that is turned. |
| `LookAtRangeCells` | 8 | | How near a player must be. |
| `LookAtYawLimit` | 70 | | How far the head turns sideways, in degrees. |
| `LookAtPitchLimit` | 24 | 40 | How far the head tilts, in degrees. |
| `LookAtPitchSign` | `nil` | -1 | Set to -1 or 1 if your model's head tilts the wrong way. |
| `LookAtEyeHeight` | 0 | 1.74 blocks | Height of the head above the feet. |
| `LookAroundEnabled` | `true` | | Looks around when idle. |

### Animation

BMB animates most mobs from Lua by rotating bones on the client, so the models need no walk cycle. The zombie family uses these:

| Field | Zombie | Meaning |
|---|---|---|
| `BipedLegSwingMax` | 38 | How far the legs swing, in degrees. |
| `BipedArmForwardAngle` | -80 | Arm angle when idle. |
| `ZombieChaseArmAngle` | -120 | Arm angle while chasing. |
| `AttackKeyframeDuration` | 0.3 | Length of the swing animation. |
| `LimbSwingPhaseScale` | 0.12 | How fast the legs cycle for a given speed. |
| `DeathTipDuration` | 0.55 | Time the body takes to fall over. |

A mob whose model has real animation sequences can use `ENT.AnimationSequences` instead: a table that maps `idle`, `walk`, `run`, `attack`, `hurt` and `death` to sequence names in the model. A missing entry falls back to `idle`.

## Hooks you can define

BMB calls these on your mob.

The *Zombie has one* column matters when you override a hook. Where it says **yes**, `bmb_zombie` or the base mob already defines the hook: call the parent's version through `BaseClass` unless you mean to replace it. Where it says **no**, nobody above you defines it and `BaseClass.TheHook` is `nil`, so write your own and do not call the parent.

### Every mob

| Hook | Side | Zombie has one | When BMB calls it | What it returns |
|---|---|---|---|---|
| `ENT:Initialize()` | both | yes | On spawn. | |
| `ENT:RunBehaviour()` | server | yes | Once. It is the behaviour coroutine. | |
| `ENT:Think()` | both | yes | Every tick. | Whatever the parent returns. |
| `ENT:CanBMBTarget(target)` | server | yes | Whenever a target is picked or re-checked. | `true` to allow it. A mob without this hook never retaliates. |
| `ENT:FindBMBPriorityTarget(range)` | server | no | At each target scan, before the normal scan. | A target it prefers, and optionally the range to check it against. `nil` for none. |
| `ENT:IsBMBDamageImmune(damageInfo)` | server | no | For each damage event, before the invulnerability check. | `true` to ignore the damage. |
| `ENT:OnBMBHurtSound(damageInfo)` | server | yes | When damage is accepted, before health goes down. Also for the killing hit. | |
| `ENT:OnBMBInjured(damageInfo, wasFleeing)` | server | no | After a hit the mob survived. Passive animals do define it: it is where they start to panic. | |
| `ENT:OnKilled(damageInfo)` | server | yes | On the killing hit. The base version calls `BeginBMBDeath`. | |
| `ENT:OnBMBDeathCleanup(corpse)` | server | no | Just before the body is removed. `corpse` is the physics prop, if one was made. | |
| `ENT:OnBMBStateChanged(oldState, newState)` | server | no | When `SetBMBState` changes the state. | |
| `ENT:OnBMBFreezeStarted(now)`, `ENT:OnBMBFreezeEnded(now)` | server | no | When the mob is frozen or released by `bmb_freeze` or the debug tool. | |
| `ENT:OnBMBHeldStarted(now)`, `ENT:OnBMBHeldEnded(now)` | server | no | When the physics gun picks it up or drops it. | |
| `ENT:MaybePlayIdleSound()` | server | yes | From `Think`, at most 20 times a second. | |
| `ENT:GetBMBForcedLookTarget()` | server | yes | By the look controller. | An entity the head should stay locked on, or `nil`. |
| `ENT:IsBMBWanderDestinationAllowed(destination)` | server | no | For each point `Wander` considers. | `false` to reject the point. |
| `ENT:TryBMBMoveOverride(reason, target)` | server | yes | Each tick of a move. | `true` if you moved the mob yourself this tick. |
| `ENT:ConfigureBMBPathfinderOptions(pathOptions, destination, moveOptions)` | server | no | Before each path search. | Change `pathOptions` in place. |
| `ENT:IsBMBMinecraftEnemy(context)` | server | no | When another mob asks whether this is a monster. | `true` or `false`. `nil` falls through to the other checks. |
| `ENT:RequiresBMBPersistence()` | both | yes | By the natural spawner's despawn sweep. | `true` to never despawn this mob. |
| `ENT:GetBMBDuplicatorState()`, `ENT:RestoreBMBDuplicatorState(state)` | server | no | When the duplicator or a save copies the mob. | A table of your own state to carry over. |
| `ENT:UpdateBMBVisualBones()` | client | yes | Every frame the mob's bones are updated. | |

### Melee mobs

The zombie defines both of these.

| Hook | When BMB calls it |
|---|---|
| `ENT:OnBMBMeleeHit(target, damageInfo)` | Right after a hit has dealt its damage and knockback. |
| `ENT:PlayBMBMeleeGesture(target)` | When a swing starts. The zombie uses it to start the arm animation. |

### Zombie family

The zombie defines both of these.

| Hook | When BMB calls it |
|---|---|
| `ENT:RunBMBZombieAI()` | From the behaviour loop. See *Its own state machine* in the README. |
| `ENT:GetBMBZombieSounds()` | Whenever a sound is picked. Returns the table with `Say`, `Hurt`, `Death`, `Step` and `Hit`. |

### Passive animals

`bmb_passive_animal` runs the whole behaviour loop in `BMB.Behaviors.PassiveAnimal.Run`. It has no AI function to override. It offers these hooks instead. The base class defines none of them, so do not call the parent's:

| Hook | When BMB calls it |
|---|---|
| `ENT:OnBMBPassiveInitialized()` | At the end of `Initialize`. |
| `ENT:RunBMBPassiveSpecialBehavior()` | When the animal is not panicking, breeding or following food, before it wanders. Return `true` if you did something this turn. |
| `ENT:StopBMBPassiveSpecialBehavior(reason)` | When something more urgent takes over, such as panic. |
| `ENT:PrepareBMBPassivePanic()` | Just before it starts to flee. |
| `ENT:PrepareBMBPassiveWander()` | Just before it starts to wander. |

Its sounds come from `ENT.PassiveSoundSets`, a table of sound sets by variant name, each with lists such as `Ambient`, `Hurt`, `Death` and `Step`.

### Examples

**React to a state change.** Glow while chasing:

```lua
function ENT:OnBMBStateChanged(oldState, newState)
    self:SetNWBool("EmberAngry", newState == "chase" or newState == "attack")
end
```

*Run in game.*

**Ignore one kind of damage.** A mob that explosions do not hurt:

```lua
function ENT:IsBMBDamageImmune(damageInfo)
    return damageInfo:IsDamageType(DMG_BLAST)
end
```

*Run in game.*

**Prefer one kind of prey.** Go for the nearest sheep before any player:

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

The zombie's `CanBMBTarget` accepts any living player, NPC or NextBot, so no other change is needed. *Run in game: the zombie picked a sheep and hit it.*

## Methods you can call

On your mob, as `self:Name(...)`. Server-side unless marked.

### State

| Method | What it does |
|---|---|
| `SetBMBState(state)` | Sets the state name, which the client uses to pick an animation and the debug HUD shows. Ignored once the mob is dead. Common names: `idle`, `wander`, `chase`, `attack`, `flee`, `aim`, `knockback`, `held`, `frozen`, `dead`. You may use your own names. |
| `SetBMBMoveMode(mode)` | Sets the finer movement label shown on the debug HUD. BMB's movement code sets it for you. |
| `IsBMBFleeing()` | `true` while the state is `flee`. |
| `IsBMBHeld()` | `true` while the physics gun holds the mob. |
| `IsBMBKnockbackActive()` | `true` during the short knockback after a hit. |
| `IsBMBOnGround()` | `true` when standing on something. |
| `IsBMBInDamageInvulnerability()` | `true` during the window after an accepted hit. |
| `GetBMBBlockSize()` | Size of one block in Source units. Both sides. |

Fields you can read: `self.State`, `self.BMBDead`, `self.BMBHeld`, `self.TargetEntity` (the current target of a hostile mob).

### Waiting

| Method | What it does |
|---|---|
| `InterruptibleWait(seconds)` | Stands idle for that long. Returns `true` if the time passed, or `false` at once if the move was interrupted, for example by a hit. Coroutine only. |

Use it instead of `coroutine.wait` for anything longer than a moment, so that the mob reacts when it is hurt.

### Moving

All of these must be called from the behaviour coroutine. Each blocks until the move ends.

| Method | What it does |
|---|---|
| `MoveToWorldPosition(destination, speed, options)` | Finds a path to a world position and walks along it. Returns `true` when it arrived. Returns `false` when there was no path, the move was blocked or interrupted, the mob is held or being knocked back, or the path expired before the mob arrived (see below). |
| `MoveAlongDirection(direction, speed, options)` | Walks in a direction for `options.duration` seconds (1.0 by default), stopping at walls and drops. |
| `FaceTarget(position)` | Turns toward a position at `TurnRate`. Does not block. |
| `InterruptBMBMovement()` | Makes the move in progress return `false`. Call it from outside the coroutine, for example from a damage hook. |

**One call to `MoveToWorldPosition` does not walk far.** BMB throws a path away 0.75 seconds after finding it (`BMB.Config.PathCacheTTL`), so that mobs notice blocks that were placed or broken. If the mob has not arrived by then, the call returns `false` (`true` with `acceptPartial`). It waits for a jump or a drop in progress to finish first. At the zombie's speed that is about one and a half blocks per call. Call it again on the next turn of your AI function and it finds a fresh path; BMB's own chasing works this way. To cover more ground in one call, pass `pathCacheTTL`.

Options of `MoveToWorldPosition`:

| Option | Meaning |
|---|---|
| `skipSourcePath` | Pass `true`. It skips an experimental path follower that is off by default; BMB's own behaviours always pass it. |
| `goalTolerance` | How close counts as arrived. Half a block by default. |
| `timeout` | Longest time for the move. By default it is worked out from the path length and the speed. |
| `pathCacheTTL` | Seconds after which the path expires and the call returns. By default the mob's `PathCacheTTL` field, or 0.75 if the mob has none. BMB's own behaviours pass 2 to 5 for a walk to a spot that does not move. |
| `allowPartial` | With `false`, a path that cannot reach the goal counts as no path. By default the mob walks as near as it can get. |
| `acceptPartial` | With `true`, the call returns `true` when the time runs out, even if it has not arrived. Used for chasing something that moves. |
| `allowNearestGoal`, `goalSnapRadiusCells` | With `allowNearestGoal = true`, a goal that cannot be stood on is replaced by the nearest spot that can, within that many blocks. |

A short example, inside the zombie's AI function:

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

It heads back toward `self.HomePosition` whenever it has no target and is more than 6 blocks away. Each call covers a short stretch and the AI function is called again right after, so the mob keeps walking until it is within 6 blocks. Then the zombie's own AI takes over again. *Run in game: a mob that started 9 blocks out was back within 6 blocks after 4 calls. `pathCacheTTL` was not run.*

Two rules from the README apply to all movement code: never move a mob with `SetPos` or `SetAngles`, and never call the blocking methods from outside the coroutine.

### Combat

| Method | What it does |
|---|---|
| `IsBMBCombatTarget(target)` | `true` for a living player who can be targeted, or a living NPC or NextBot. The zombie's `CanBMBTarget` returns exactly this. |
| `TryBMBRetaliateAgainst(attacker)` | Makes the attacker the current target, if `CanBMBTarget` allows it. Returns whether it did. |
| `StartBMBExternalImpulse(impulse, options)` | Throws the mob with a velocity `Vector`. Returns `false` if the mob is dead or held. |
| `StartBMBHurtFlash()` | Flashes the mob red without hurting it. |
| `BeginBMBDeath(damageInfo)` | Starts the death sequence. Call it from your own `OnKilled` if you replace the parent's. |

### Names

| Method | Side | What it does |
|---|---|---|
| `SetBMBCustomName(name)` | server | Gives the mob a name. A named mob is never despawned by the natural spawner. |
| `GetBMBCustomName()` | both | The name, or `nil`. |
| `HasBMBCustomName()` | both | Whether it has one. |

### Client bone helpers

For use inside `ENT:UpdateBMBVisualBones()`.

| Method | What it does |
|---|---|
| `SetBMBVisualBoneAngle(boneId, angle)` | Rotates a bone. Does nothing when `boneId` is `nil`. |
| `SetBMBVisualBonePosition(boneId, position)` | Offsets a bone. |
| `UpdateBMBLimbSwing(speed)` | Advances the walk cycle. Returns the phase and an amount from 0 to 1. |
| `UpdateBMBLookAtHeadPose(headBoneId)` | Applies the head turn of the look controller. Returns whether it turned the head. |
| `ApplyBMBBipedLocomotion(bones, phase, amount)` | Swings `bones.rightLeg`, `bones.leftLeg`, `bones.rightArm` and `bones.leftArm`. |
| `CacheBMBZombieBones()` | Zombie family. Returns a table with the bone ids of `root`, `head`, `rightArm`, `leftArm`, `rightLeg` and `leftLeg`. |

## Behaviour modules

The reusable pieces under `BMB.Behaviors`, server only. A family's AI function is a few lines that combine them. The zombie's, in full:

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
        -- could not get closer this turn: keep pressure on, or drop the target
        ...
    end
end
```

| Function | What it does |
|---|---|
| `SeekTarget.Find(mob, currentTarget)` | Returns the target to use now. It keeps `currentTarget` while that is still valid, and otherwise scans, at most once per `TargetScanInterval`. A scan asks `FindBMBPriorityTarget` first, then takes the nearest valid candidate from the player pool and eligible iron golems. *After 1.0.0*, `TargetVillagers = true` also adds villagers and wandering traders. Returns `nil` for no target. |
| `SeekTarget.IsValid(mob, target, range, acquire)` | Whether `target` is alive, passes `CanBMBTarget`, is within `range` (default `TargetLoseRange`), and is visible if the mob requires line of sight. |
| `MeleeAttack.Try(mob, target)` | Starts a swing if the target is in range and the cooldown is over. Returns whether it did. The hit lands after `AttackHitDelay`. |
| `MeleeAttack.IsInRange(mob, target)` | Whether the target is within `AttackRange` and `AttackVerticalRange`. |
| `Chase.Run(mob, target)` | Moves toward the target for one short stretch: straight at it when it can, along a path otherwise. Returns `true` if it made progress or is in attack range, `false` if it could not get closer. |
| `Wander.Run(mob)` | Picks a random reachable point within the wander distance, walks there at `WalkSpeed`, then rests. |
| `Flee.Run(mob, threat)` | Runs to random nearby points at `RunSpeed` until `mob.FleeUntil`. With a `threat` (an entity or a position), it only picks points farther from the threat. Set `mob.FleeUntil = CurTime() + seconds` before you call it. |
| `RangedAttack.Update(mob, target)` | One turn of the skeleton's ranged attack: approach until in range, then strafe, draw and shoot. |
| `FleeSun.CanStart(mob)`, `FleeSun.Run(mob)` | The skeleton's run for shade while burning in daylight. |
| `FlyWander.Run(mob)` | Wander for flying mobs. |
| `PassiveAnimal.Run(mob)` | The complete behaviour loop of passive animals. |

Other modules exist for single families, such as `Leap` (spiders), `Pack` (wolves), `Avoid` (cats and rabbits), `Breeding`, `Temptation` and `FollowParent` (animals). Read them in `lua/bmb/behaviors/` before using them.

## Global functions

### Version and block size

| Name | Side | Meaning |
|---|---|---|
| `BMB.Version` | both | Version string, `"1.0.0"` in this build. |
| `BMB.BS` | both | Size of one block in Source units, as of the last call to `BMB.GetBlockSize`. 36.5 with MineMod's default. |
| `BMB.GetBlockSize()` | both | Reads the block size from MineMod, stores it in `BMB.BS` and returns it. |

To check that BMB is installed, test for the class rather than the table:

```lua
if not scripted_ents.GetStored("bmb_zombie") then
    -- BMB is missing
end
```

*Run in game: this is what the example's autorun file does.*

### Health

| Function | Side | What it does |
|---|---|---|
| `BMB.GetHealthScale()` | both | The current `bmb_health_scale`. |
| `BMB.ScaleMobHealth(baseHealth)` | both | `baseHealth` × the scale, rounded, at least 1. |
| `BMB.ApplyMobHealthScale(mob, baseHealth, preserveFraction)` | server | Gives a mob a new base health. With `preserveFraction`, it keeps the same percentage of health. Use it if your mob changes its maximum health after spawning. |

### Mob registry

BMB keeps a list of every living BMB mob, custom ones included. It is the fast way to visit them.

| Function | What it does |
|---|---|
| `BMB.ForEachMob(fn)` | Calls `fn(mob)` for every BMB mob. Removing mobs inside the callback is safe. |
| `BMB.ForEachMobOfClass(class, fn)` | The same for one exact class name. Child classes are not included. |
| `BMB.GetMobCount()` | Number of BMB mobs. |
| `BMB.GetMobCountOfClass(class)` | Number of mobs of one exact class. |
| `BMB.GetMobList()` | A new table of all mobs. Prefer `ForEachMob`. |
| `BMB.IsMobRegistered(ent)` | Whether an entity is in the list. |

These work on both sides. A mob joins the list one frame after it is created.

```lua
local count = 0
BMB.ForEachMob(function(mob)
    if mob:GetClass() == "example_ember_zombie" and not mob.BMBDead then count = count + 1 end
end)
```

*The registry functions were run in game on both sides. This snippet was not.*

### Players as targets

| Function | What it returns |
|---|---|
| `BMB.PlayerTargetBlockReason(player)` | `nil` if hostile mobs may target the player. Otherwise the reason: `"dead"`, `"notarget"` or `"spectator"`. |
| `BMB.Targeting.GetPlayerMode(player)` | `"survival"`, `"creative"`, `"spectator"`, `"dead"` or `"invalid"`. |

Creative and god-mode players are still targeted. Players with the `notarget` flag are not.

### Text

| Function | Side | What it does |
|---|---|---|
| `BMB.GetLanguage(player)` | both | `"en"` or `"zh"`: the language BMB uses for that player. On the client, omit the argument. |
| `BMB.L(key, player)` | both | One of BMB's own interface strings in that language. It only knows BMB's keys. |

## Natural spawning

`BMB.NaturalSpawn` is the server-side spawner. It is off unless the server sets `bmb_spawn_enabled 1`.

### `BMB.NaturalSpawn.Register(className, options)`

Adds a spawn entry. Returns `true`, or `false` if the class name is not a non-empty string. Every call adds another entry, so call it once.

| Option | Default | Meaning |
|---|---|---|
| `category` | `"monster"` | `"monster"`, `"creature"` or `"ambient"`. Each has its own rules and cap, below. |
| `weight` | 1 | Relative odds among the entries of the same category. |
| `packSizes` | none | List of group sizes, for example `{ 2, 3 }`. One is picked at random. Without it a single mob spawns. |
| `limitConVar` | none | Name of a ConVar. The entry is skipped once that many mobs of the class exist. `0` turns the entry off. |
| `enabledConVar` | none | Name of a ConVar. The entry is skipped while it is `0`. |
| `maxLight` | none | Monster rule. Highest light level, 0 to 15. It can only lower the server's `bmb_spawn_max_light`. |
| `spawnChance` | none | Monster rule. A number below 1 makes a valid spot be used only that fraction of the time. |
| `condition` | none | Monster rule. `function(world, cell, position)` called for a spot that passed the light check. Return `true`, or `false` and a reason string. |
| `groundMCIDs` | grass block | Creature rule. Set of block ids the mob may spawn on, for example `{ ["minecraft:sand"] = true }`. |
| `useCreatureSpawnRule` | `false` | For a monster entry: use the creature rule for placement but stay in the monster category. |

Five more options exist for BMB's own animals and are tied to its variant and age systems: `initialVariant`, `chooseInitialVariant`, `sharePackVariant`, `packBabyChance` and `adultPackMembers`.

Run in game: `category`, `weight`, `packSizes`, `limitConVar`, `enabledConVar`, `maxLight` and `condition`. The other options are from the source.

### The three rules

| Category | Where it spawns | Server cap |
|---|---|---|
| `monster` | The light level at the feet and at head height is at most `bmb_spawn_max_light` (7). Then `spawnChance` and `condition` are applied. | `bmb_spawn_max` |
| `creature` | The block underfoot is in `groundMCIDs`, the block above the feet is free, and the raw light level is above 8. | `bmb_spawn_creature_max` |
| `ambient` | Bat rules: a coin flip, then light at most a random 0 to 3, and not under an open sky. | `bmb_spawn_ambient_max` |

In every category the spot is 20 to 40 blocks from a player (`bmb_spawn_min_distance`, `bmb_spawn_max_distance`), the mob's collision box must fit there, and the cell must be one the mob can stand in.

A pack spawns its first member by the rules above and the others at random spots within 5 blocks of it, each checked the same way.

Monsters and ambient mobs spawn every `bmb_spawn_interval` seconds, creatures every `bmb_spawn_creature_interval` seconds.

### Other functions

| Function | What it does |
|---|---|
| `BMB.NaturalSpawn.TrySpawnForPlayer(player, options)` | Makes one spawn attempt near a player. Returns the mob and `"spawned"`, or `nil` and a failure reason. Options: `channel` (the category, default `"monster"`), `ignoreEnabled`, `ignoreCap`, `entry` (use this entry instead of picking one). |
| `BMB.NaturalSpawn.CountNaturalMobs(category)` | Number of living mobs the spawner created in that category. |
| `BMB.NaturalSpawn.GetStatus()` | A table with `enabled`, `monsters`, `count`, `max`, `creatureCount`, `creatureMax`, `ambientCount`, `ambientMax`, `world` and `daylight`. |

A mob made by the spawner has `mob.BMBNaturalSpawn == true` and `mob.BMBNaturalSpawnCategory` set to its category. Only such mobs are counted against the caps and removed by despawning.

### Failure reasons

Returned by `TrySpawnForPlayer` and printed by `bmb_spawn_now`.

| Reason | Meaning |
|---|---|
| `disabled` | `bmb_spawn_enabled` is `0`. |
| `monsters_disabled` | `bmb_spawn_monsters` is `0`. |
| `cap_reached` | The category is at its cap. |
| `class_limit_reached` | The requested entry is at its `limitConVar`. |
| `no_spawnable_class` | No entry of the category is usable: all are disabled, at their limit, or have weight 0. |
| `outside_distance_band` | The random spot was nearer or farther than allowed. Common; try again. |
| `no_walkable_candidate` | No walkable spot was found near the player. |
| `collision_or_standability` | The spot passed the rules but the mob does not fit there. |
| `light_unknown` | The block world has no light data there. This is what you get on a map with no MineMod blocks. |
| `light_not_exact` | Only an estimate was available and `bmb_spawn_allow_approximate_light` is `0`. |
| `light_15.00_over_7.00` | Too bright for a monster. The numbers are the light found and the limit. |
| `light_raw_7.00_not_above_8` | Too dark for a creature. |
| `wrong_spawn_block_minecraft:stone` | A creature's ground block is not in `groundMCIDs`. The block found is in the name. |
| `spawn_block_unknown` | The ground block could not be identified. |
| `no_head_clearance` | A creature has a solid block above its feet. |
| `spawn_chance` | The entry's `spawnChance` roll failed. |
| `condition_failed` | The entry's `condition` returned `false` without a reason. With a reason, that reason is returned instead. |
| `coin_flip`, `sky_exposed` | Ambient rule failures. |
| `invalid_player`, `unknown_channel`, `world_api_unavailable`, `light_api_unavailable`, `create_failed`, `spawn_failed` | Something is missing or broken rather than merely unlucky. |

### Example: spawn only underground

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

`IsSkyExposedAt` returns `false` only when something is known to cover the cell, so `~= false` also rejects the cases where it could not tell. *Run in game under an open sky only: the `condition` turned every spot down with `needs_a_roof`, and an entry with `maxLight = 0` was turned down for light. A spawn under a roof was not tried.*

## Mob relations

Some BMB mobs act on whether another mob is a Minecraft "monster": iron golems and snow golems attack monsters, and monsters attack iron golems. `BMB.MobRelations` (server) answers that question.

`BMB.MobRelations.IsMinecraftEnemy(entity, context)` checks, in this order, and stops at the first one that gives an answer:

1. `entity:IsBMBMinecraftEnemy(context)`, if the entity defines it and it returns `true` or `false`;
2. the field `entity.BMBMinecraftEnemy`, if it is `true` or `false`;
3. whether the class is registered as a monster. BMB's own hostile mobs are;
4. the field `entity.BMBMinecraftEntityID`, against BMB's list of Minecraft monster ids;
5. the game hook `BMB.IsMinecraftEnemy`, which may return `true`.

So for a custom mob there are two simple ways to be a monster:

```lua
ENT.BMBMinecraftEnemy = true                                             -- in the entity file

BMB.MobRelations.RegisterMinecraftEnemyClass("yourname_frost_zombie")    -- on the server, after BMB has loaded
```

*Both were run in game.*

In 1.0.0, being a monster has two effects. Iron golems and snow golems attack the mob. And the mob, if it uses `SeekTarget`, also picks iron golems as targets, not only players.

| Function | What it does |
|---|---|
| `BMB.MobRelations.RegisterMinecraftEnemyClass(className, enabled)` | Marks a class as a monster. Pass `false` as the second argument to unmark it. |
| `BMB.MobRelations.IsMinecraftEnemy(entity, context)` | The check described above. |
| `BMB.MobRelations.IsIronGolem(entity)` | Whether an entity is an iron golem. |
| `BMB.MobRelations.IsAbstractVillager(entity)` | *After 1.0.0.* Returns a boolean identifying a villager or wandering trader, as described below. Server only. |
| `BMB.MobRelations.GetHostileTargetCandidates(mob, range, candidates)` | Returns a fresh candidate array, copying `candidates` (default `player.GetAll()`) and appending eligible nearby iron golems. *After 1.0.0*, also appends villagers and wandering traders when `mob.TargetVillagers == true`. It also appends eligible NPCs from enabled integrations. Entries are deduplicated and the supplied array is unchanged. `range` is in Source units and defaults to `mob.TargetRange` or 900. Callers apply their target-validity checks. |

Behaviours that name classes directly, such as villagers fleeing zombies, are not covered by this.

### Villager targets (after 1.0.0)

`BMB.MobRelations.IsAbstractVillager(entity)` follows Java's `AbstractVillager` category: it accepts `bmb_villager` and `bmb_wandering_trader`, including baby villagers. It also accepts external entities whose `BMBMinecraftEntityID` (or, if absent, `MinecraftEntityID`) is `minecraft:villager` or `minecraft:wandering_trader`. Invalid entities and zombie villagers return `false`. This is a category check; health, range, sight and `CanBMBTarget` are checked separately by `SeekTarget.IsValid`.

To use the shared scan in a custom zombie, set this in the entity file:

```lua
ENT.Base = "bmb_zombie"
ENT.TargetVillagers = true
```

The updated `bmb_zombie` already sets this field to `true`, so custom children, husks and zombie villagers inherit it. `bmb_zombie_pigman` overrides it to `false`. Set it to `false` on your child to disable this natural villager scan; existing targets, retaliation and debug-forced targets keep their own rules. Merely marking a mob as a Minecraft monster does not enable the field.

The field is consumed by `GetHostileTargetCandidates` and the shared `SeekTarget.Find`. An AI with its own candidate scanner must call the helper or implement its own villager goal. *Checked against the updated Lua source and offline targeting regression; this example was not run in game for this page.*

### NPC relations (after 1.0.0)

On the server, BMB's base mob handles relations with supported stock Source NPCs, VJ Base SNPCs and DrGBase NextBots when their integrations are enabled. Hostile BMB mobs can acquire any supported NPC. Neutral BMB mobs can acquire hostile NPCs and retaliate according to their own AI. Passive BMB mobs can be acquired by hostile NPCs. Friendly and neutral NPCs share the same acquisition rules with BMB.

Set `ENT.BMBNPCTemperament` to `"hostile"`, `"neutral"` or `"passive"` in a custom BMB entity file. When the field is unset, BMB treats killer rabbits as hostile and checks the built-in neutral list before the Minecraft monster classification. The remaining monsters count as hostile and other BMB mobs as passive. The built-in neutral list uses exact class names, so set the field explicitly if a custom wolf class should behave like a neutral wolf toward NPCs.

```lua
ENT.Base = "bmb_wolf"
ENT.BMBNPCTemperament = "neutral"
```

To classify a supported NPC from outside BMB, set its `BMBNPCTemperament` field to `"friendly"`, `"neutral"` or `"hostile"` on the server. Leave the field unset to use the `BMB.GetNPCTemperament` hook. With no override, BMB classifies the NPC from its base's faction and behaviour settings. Unrecognized VJ or DrG factions fall back to neutral when the other settings also give no answer. BMB caches NPC classifications and rechecks them about every two seconds.

```lua
hook.Add("BMB.GetNPCTemperament", "YourAddonGuardRelations", function(npc, base)
    if base == "vj" and npc:GetClass() == "npc_vj_youraddon_guard" then
        return "friendly"
    end
end)
```

| Server query | Return value |
|---|---|
| `BMB.NPCRelations.GetMobTemperament(mob)` | `"hostile"`, `"neutral"` or `"passive"` for a valid BMB mob. Returns `nil` for other entities. |
| `BMB.NPCRelations.GetNPCTemperament(npc)` | The cached `"friendly"`, `"neutral"` or `"hostile"` classification. Returns `nil` before registration, for unsupported NPCs or when that base's integration is disabled. |
| `BMB.NPCRelations.CanAcquire(mob, npc)` | Whether a living BMB mob can naturally acquire an active, living NPC under these rules. Custom scans must apply their range, sight and combat state checks separately. |

Custom scanners can use `BMB.MobRelations.GetHostileTargetCandidates` to include NPCs and then apply their own target checks. The server controls are in the [NPC relations ConVar table](CONVARS.md#npc-relations). The cross-base combat rules were tested in game. The two examples above were checked against the current Lua source.

## Fire

BMB has its own fire for mobs: Minecraft-style timing, flames and damage. `BMB.Fire` (server) owns it.

| Function | What it does |
|---|---|
| `BMB.Fire.Ignite(mob, seconds, source)` | Sets a BMB mob on fire for at least that long. A mob already burning longer is not shortened. Returns `true` if the mob is burning afterwards, `false` if it is dead, not a BMB mob, or `FireImmune`. `source` is a label of your choice, kept for `GetSource`. |
| `BMB.Fire.IsBurning(mob)` | Whether it is on fire. |
| `BMB.Fire.GetRemaining(mob)` | Seconds of fire left. |
| `BMB.Fire.GetSource(mob)` | The label given when it was last ignited: `"sunlight"`, or your own. |
| `BMB.Fire.Extinguish(mob, reason)` | Puts it out with the fizz sound. |
| `BMB.Fire.Clear(mob)` | Puts it out silently. |

A burning mob takes `bmb_sunlight_damage` every `bmb_sunlight_interval` seconds. Water puts the fire out.

**BMB mobs and players need different calls.** The engine's `Entity:Ignite()` works on players but does nothing to a BMB mob, because BMB drops engine burn damage. `BMB.Fire.Ignite` works on BMB mobs only. A hit that should burn either kind of victim:

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

*Both branches were run in game: the player branch by the example, the mob branch on a sheep.*

## Status effects

`BMB.Status` (server) gives mobs and players timed effects.

| Function | What it does |
|---|---|
| `BMB.Status.ApplyMobEffect(target, effect, params)` | Applies an effect. For a player it hands the effect to MineMod's potion system when that is loaded, so that the player sees the icon; otherwise BMB runs it. Use this one. Returns whether the effect was applied. |
| `BMB.Status.Apply(target, effect, params)` | Applies an effect with BMB's own runtime, players included. |
| `BMB.Status.Has(entity, effect)` | Whether the entity has the effect in BMB's runtime. |
| `BMB.Status.Clear(entity, effect)` | Removes one effect. |
| `BMB.Status.ClearAll(entity)` | Removes all of them. |

`target` may be a player, an NPC, a NextBot or a BMB mob. `params.duration`, in seconds, is required. Other entries in `params` override the effect's own values below.

| Effect | What it does | Values you can override |
|---|---|---|
| `poison` | 2 damage a second, once a second. Never kills. Undead mobs are immune. | `dps`, `interval` |
| `wither` | 1 damage a second, every 2 seconds. Can kill. | `dps`, `interval` |
| `slowness` | Movement speed × 0.6. | `mult` |
| `speed` | Movement speed × 1.2. | `mult` |
| `weakness` | Melee damage dealt − 4. | `delta` |
| `regeneration` | Heals 1 every 2.5 seconds. | `healPerTick`, `interval` |
| `fire_resistance` | A flag other code can check. | |
| `water_breathing` | A flag other code can check. | |
| `invisibility` | A flag other code can check. | |

Pass `source = self` so that poison and wither damage is credited to your mob.

This is how BMB's cave spider poisons what it bites:

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

*Adapted from BMB's `bmb_cave_spider.lua`. Run in game on a custom zombie that bit a sheep.*

## Block world

BMB never calls MineMod directly. It goes through an adapter, `BMB.BlockWorld` (server), which has two implementations: the real MineMod world, and a flat mock world used when MineMod is not loaded. Your code can read the world through the same adapter.

Get the adapter with `BMB.SelectBlockWorld()`. It returns the active one and switches to the real world if MineMod has loaded since the last call.

A *cell* is a table `{ x = , y = , z = }` of whole-number block coordinates, with `z` up.

| Function | What it returns |
|---|---|
| `world.WorldToBlock(position)` | The cell that contains a world position. |
| `world.BlockToWorld(cell)` | A world position for a cell: its centre in the real world. |
| `world.IsSolid(cell)` | Whether something blocks the cell: a MineMod block or the map's own geometry. |
| `world.HasSupport(cell)` | Whether a mob standing in the cell has something under its feet. |
| `world.GetBlockInfoAt(cell)` | `nil` for air. Otherwise a table with `mcid` (such as `"minecraft:grass_block"`), `name`, `id` and `stateId`. |
| `world.GetLightAt(cell)` | A table with `level`, `blockLight` and `skyLight` (0 to 15, or `nil` when unknown), `exact` (whether it is a real sample or an estimate) and `reason`. |
| `world.IsSkyExposedAt(cell)` | `true` if the sky is visible straight up, `false` if something covers it, `nil` and a reason if it cannot tell. |
| `world.GetDaylightState()` | A table with `ticks` (0 to 23999, Minecraft time of day), `sunUp`, `sunStrength` (0 at night to 1 at noon), `skyLevel`, `enabled` and `paused`. |
| `world.GetLiquidAtPos(position)` | `nil`, or a table describing the liquid a point is in. Its `kind` is `"water"` or `"lava"`. |
| `world.IsWaterAt(cell)` | Whether the cell holds water. |
| `world.GetRandomWalkablePoint(origin, radius, mob)` | A random position near `origin` that the mob can stand on. It returns `origin` itself when it finds none. |

`BMB.Pathfinder` (server) adds two checks that take the mob's size into account:

| Function | What it returns |
|---|---|
| `BMB.Pathfinder.IsStandablePosition(position, { mob = mob })` | Whether the mob can stand there, and the cell. |
| `BMB.Pathfinder.FindNearestStandable(position, { mob = mob, searchRadiusCells = 4 })` | The nearest position the mob can stand on, or `nil`. |

```lua
local world = BMB.SelectBlockWorld()
local cell = world.WorldToBlock(self:GetPos())
local below = world.GetBlockInfoAt({ x = cell.x, y = cell.y, z = cell.z - 1 })
local onSand = below ~= nil and below.mcid == "minecraft:sand"
```

*The adapter functions in the tables above were run in game on the real MineMod world, except `GetLiquidAtPos` and `IsWaterAt` in a liquid. This snippet was not.*

The adapter also has functions that change blocks, `world.SetBlockAt` and `world.RemoveBlockAt`. BMB's mobs use them for things such as sheep eating grass. They are not described here; read how BMB calls them before you use them.

## Drops and experience

When a BMB mob dies, BMB rolls the Minecraft loot table for it and drops the items and experience through MineMod. **A custom class gets none of this.** The table is found by class name in a generated list of BMB's own classes. A class that is not in the list is reported as `unmapped_mob`, and nothing is rolled. Inheriting from `bmb_zombie` does not change that, because the lookup uses the mob's own class name.

*After 1.0.0.* BMB's built-in death flow checks the server's reward mode when a mob dies. It applies to hand-spawned and naturally spawned BMB mobs, including equipment and held items. The item lifetime setting is read when the drop entity is created. Experience still follows the player-kill rule. `BMBDroppedEntityLoot` and `BMBDroppedEntityExperience` run only for their enabled reward types. See [Mob death rewards](CONVARS.md#mob-death-rewards) for the two settings.

Custom death callbacks that call the spawn helpers directly decide which rewards to create. A custom mob can read the ConVars itself to follow the same server settings.

You can drop things yourself. `OnBMBDeathCleanup` is the moment BMB drops its own loot: the body is about to vanish in the poof.

```lua
function ENT:OnKilled(damageInfo)
    BaseClass.OnKilled(self, damageInfo)

    -- Roll while the killing blow is still known (looting, killed by a player or not).
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

*Run in game with MineMod loaded: six mobs were killed, and every roll that gave items dropped them.*

| Function | What it does |
|---|---|
| `BMB.Loot.BuildContext(mob, damageInfo)` | Collects what the loot rules need: the attacker, whether a player dealt damage in the last 5 seconds, the weapon. |
| `BMB.Loot.EvaluateTable(tableId, context)` | Rolls one of the loot tables BMB ships, named like `"minecraft:entities/zombie"`. Returns a list of stacks. |
| `BMB.Loot.SpawnStacks(mob, stacks, context, position[, lifetimeSeconds])` | Drops the stacks as item entities and returns how many spawned. *After 1.0.0*, pass the optional lifetime in game seconds. Calls without a lifetime use MineMod's default. The function requires MineMod's inventory API. |

A stack is a table such as `{ item = "minecraft:rotten_flesh", count = 2 }`. You can build the list yourself instead of rolling a table; a list built by hand was dropped in the game test too.

These three functions are internals of the loot system and the most likely part of this page to change.

## Debug tool orders

The BMB Debug tool and the `bmb_debug_move` command steer a mob by setting fields on it. `RunBMBDebugMove` in the behaviour loop carries the order out, so a mob that keeps the standard loop needs no code for this. The tool itself is described in the [ConVar reference](CONVARS.md#the-bmb-debug-tool).

| Method | What it does |
|---|---|
| `HasBMBDebugMove()` | A true value while an order is active. |
| `ClearBMBDebugMove(reason, detail)` | Drops the active order. Call it when a behaviour of your mob has to take over from an order, as the spider's wall climb does. In 1.0.0 it takes no arguments. *After 1.0.0* both are optional: `reason` is recorded as the result of the order, and the result is `cancelled` when you leave it out. |

*After 1.0.0*, an order that ends leaves its result on the mob, and BMB runs the game hook `BMBDebugMoveFinished` with the mob, the result and the detail.

| Field on the mob | What it holds |
|---|---|
| `BMBDebugMoveResult` | Why the last order ended: `arrived`, `no_progress`, `expired`, `stopped`, `climb`, `cancelled`, `done`, `unsafe`, `blocked` or `stuck`. The ConVar reference says what each means. `nil` once a new order is given. |
| `BMBDebugMoveResultDetail` | For `no_progress`: the mob's last move mode, or `no_path` when no path was found. For the other results it is whatever was passed to `ClearBMBDebugMove`, usually `nil`. |
| `BMBDebugMoveResultAt` | `CurTime()` when the order ended. |
| `BMBDebugMoveLastTarget` | Target of the order that ended, as a `Vector`. `nil` for a `bmb_debug_move` walk. |
| `BMBDebugMoveOwner` | The player who gave the order. |
| `BMBDebugMoveSerial` | A count of the orders given to this mob. BMB uses it to tell a new order from the one before. |

These fields tune right-click orders. Set them on your class like any other field.

| Field | Default | Meaning |
|---|---|---|
| `DebugPathCommandTimeout` | 120 | Seconds after which an order runs out. A very distant target gets longer. |
| `DebugPathProgressGrace` | 8.0 | An order lasts at least this long after each progress. |
| `DebugPathNoProgressTimeout` | 3.5 | Time without progress before the mob gives up. |
| `DebugPathNoProgressMinAttempts` | 3 | *After 1.0.0.* Attempts in a row without progress that are also needed before it gives up. |
| `DebugPathNoProgressHardScale` | 4 | *After 1.0.0.* It gives up after `DebugPathNoProgressTimeout` × this, whatever the attempts. |
| `DebugPathDetourTimeout` | 45 | *After 1.0.0.* How long following the path without getting nearer to the target still counts as progress. |
| `DebugPathCacheTTL` | 2.5 | *After 1.0.0.* The `pathCacheTTL` of each attempt. A higher `PathCacheTTL` on the mob wins. 1.0.0 uses the mob's ordinary path lifetime. |
| `DebugPathRepathDelay` | 0.25 | Pause before the next attempt. *After 1.0.0* only after an attempt that failed or brought no progress. |
| `DebugPathSegmentMinTimeout` | 3.0 | Shortest time allowed for one attempt. |
| `DebugPathTimeoutBase`, `DebugPathTimeoutScale`, `DebugPathTimeoutMax` | 4.0, 3.0, 90 | Time allowed for one attempt: the base, plus the scale × the time the path takes at the mob's speed, up to the maximum. |
| `DebugPathFlightSegmentTime` | 2.5 | *After 1.0.0.* Flying mobs: length of one attempt. |
| `DebugPathFlightHandoff` | 0.3 | *After 1.0.0.* Flying mobs: seconds for which the flight command of one attempt stays in force after it ends, so that the mob does not stop before the next attempt takes over. |
| `DebugPathRecenterTime` | 1.0 | *After 1.0.0.* Time allowed to put a mob that hangs on a block corner back on the middle of its block. |
| `DebugPathRecenterTolerance` | 1.5 | *After 1.0.0.* How near the middle counts, in units. |
| `DebugPathRecenterMinSpeed` | 20 | *After 1.0.0.* Lowest speed used for that. |

## Game hooks BMB fires

BMB runs these with `hook.Run`. Listen with `hook.Add`. All are server-side.

### General

| Hook | Arguments | Use |
|---|---|---|
| `OnNPCKilled` | `mob, attacker, inflictor` | The standard Garry's Mod hook. BMB runs it when one of its mobs dies, custom mobs included. |
| `BMB.IsMinecraftEnemy` | `entity, context` | Return `true` to make an entity count as a monster. Asked last, see [Mob relations](#mob-relations). |
| `BMB.GetNPCTemperament` | `npc, base` | *After 1.0.0.* Return `"friendly"`, `"neutral"` or `"hostile"`. Leave the return value `nil` to allow normal classification. `base` is `"native"`, `"vj"` or `"drg"`. |
| `BMB.ResolveMinecraftDifficultyId` | `mob` | Return 0 to 3 to override `bmb_minecraft_difficulty` for that mob. |
| `MC.ModifyEntityIgnitionDuration` | `mob, seconds, context` | Return a number to change how long a mob burns when `BMB.Fire.Ignite` is called. |
| `MC.IgniteEntity` | `entity, seconds, context` | Run when a BMB fireball is about to set an entity on fire. Return anything but `nil` to take that over; `false` means the entity was not ignited. |
| `PlayerShouldTakeDamage` | `target, owner` | The standard Garry's Mod hook. A tamed pet asks it before it attacks a player for its owner; returning `false` stops the attack. |
| `BMBAnimalBred` | `loveCause, firstParent, secondParent, child` | Two animals have bred. `loveCause` is the player who fed them, if known. |
| `BMBShouldDropBreedingExperience` | `firstParent, secondParent, child, loveCause` | Return `false` to stop breeding from dropping experience. |
| `BMBShouldDropExperience` | `mob, context` | Return `false` to stop a dying mob from dropping experience. BMB's own classes only. |
| `BMBDroppedEntityLoot` | `mob, stacks, spawnedCount, lastDamagePlayer` | A mob's loot has dropped. BMB's own classes only. |
| `BMBDroppedEntityExperience` | `mob, amount, orbs, lastDamagePlayer, context` | A mob's experience has dropped. BMB's own classes only. |
| `BMBDebugMoveFinished` | `mob, reason, detail` | *After 1.0.0.* An order of the debug tool has ended. `reason` and `detail` are as in [Debug tool orders](#debug-tool-orders). |

### For one mob

These report what a particular BMB mob did, or let another addon answer a question for it. The first argument is the mob unless the list says otherwise.

| Mob | Events (nothing is returned) |
|---|---|
| Allay | `BMB.AllayItemGiven (allay, player, stack, infinite)`, `BMB.AllayDropInternalInventory (allay, player)`, `BMB.AllaySwingMainHand (allay, player, serial)`, `BMB.AllayDuplicated (allay, child, player)` |
| Chicken | `BMB.ChickenFlap (chicken)` |
| Copper golem | `BMB.CopperGolemOxidationChanged (golem, previous, level, reason)`, `BMB.CopperGolemBecameStatue (golem, cell, stateId, spec)`, `BMB.CopperGolemAntennaChanged (golem, item, reason)`, `BMB.CopperGolemSurfaceEvent (golem, kind, serial)`, `BMB.CopperGolemInteractionStopped (golem, previous, reason)` |
| Drowned | `BMBDrownedThrewTrident (drowned, target, projectile)` |
| Enderman | `BMBEndermanBlockPickedUp (enderman, cell, info, defaultState)`, `BMBEndermanBlockPlaced (enderman, cell, stateId, spec, mcid)`, `BMBEndermanCarriedBlockDrop (enderman, stateId, spec, mcid)` |
| Mooshroom | `BMB.MooshroomStewCollected (player, mooshroom, result)` |
| Piglin, pillager | `BMBPiglinFiredCrossbow (piglin, target, arrow)`, `BMBPillagerFiredCrossbow (pillager, target, arrow)` |
| Snow golem | `BMBSnowGolemPlacedSnow (golem, cell, stateId)` |
| Villager, wandering trader | `BMB.MerchantTradeCommitted (merchant, player, offerIndex, offer)`, `BMB.MerchantRestocked (merchant)`, `BMB.MerchantUnavailable (merchant, reason)`, `BMB.VillagerTradeReputation (villager, player)`, `BMB.ReputationEvent (villager, eventType, actor)` |
| Warden and other listeners | `BMB.VibrationReceived (listener, signal)` |
| Witch | `BMBWitchStartedDrinking (witch, potionId)`, `BMBWitchFinishedDrinking (witch, potionId, definition)`, `BMBWitchThrewPotion (witch, target, projectile, potionId)` |
| Tamed pets | `BMB.PetPersistenceChanged (mob, data, revision)` |

| Mob | Questions (the return value is used) |
|---|---|
| Any mob | `BMB.IsMobLeashed (mob)`, `BMB.IsMobPassenger (mob)`, `BMB.IsMobVehicle (mob)` |
| Armadillo | `BMB.IsPlayerSprinting (player)` |
| Cat, fox, llama, wolf | `BMB_SelectCatVariant (cat, options)`, `BMB_SelectFoxVariant (fox, options)`, `BMB_SelectLlamaVariant (llama, options)`, `BMB_SelectWolfVariant (wolf, options)` |
| Copper golem | `BMB.CopperGolemWaxChanged (golem, waxed, reason)` |
| Drowned | `BMB.IsEntityInMinecraftWater (target, drowned)` |
| Llama | `BMB.IsLlamaPassenger (llama)`, `BMB.IsLlamaVehicle (llama)`, `BMB.GetLlamaPassengerCount (llama, playersOnly)`, `BMB.ResolveLlamaLeashHolder (llama)`, `BMB.ResolveLlamaCaravanAnchor (llama)` |
| Snow golem | `BMB_SnowGolemMelts (golem, sample)` |
| Trader llama | `BMB.ResolveTraderLlamaOwner (llama)`, `BMB.ResolveTraderLlamaDefenseEvent (llama, owner)`, `BMB.RunTraderLlamaOwnerFollow (llama, owner)`, `BMB.CanTraderLlamaDespawn (llama, owner)`, `BMB.GetTraderLlamaOwnerDespawnDelay (llama, owner)` |
| Villager, wandering trader | `BMB.OpenMerchant (player, merchant)`, `BMB.GetMerchantSpecialPrice (merchant, player, offer)`, `BMB.GetVillagerReputation (villager, player)` |
| Warden | `BMB.WardenDamageBypassesInvulnerability (warden, damageInfo)` |
| Witch | `BMBTargetVisibilityPercent (target, witch)`, `BMBWitchHasActiveRaid (witch)` |

What a question hook should return, and what BMB does with it, differs per hook. Read the call in BMB's source before answering one.

## Networked values

BMB publishes these on every mob with `SetNW*`. Read them on the client with `ent:GetNWString("BMBState")` and so on.

| Name | Type | Meaning |
|---|---|---|
| `BMBState` | string | Current state name, as set by `SetBMBState`. |
| `BMBStateStartedAt` | float | `CurTime()` when the state last changed. |
| `BMBMoveMode` | string | Current movement label. |
| `BMBHealth` | int | Current health. |
| `BMBDead` | bool | The mob has died and is waiting to be removed. |
| `BMBDesiredSpeed` | float | Speed the mob is currently asked to move at. |
| `BMBActivitySpeed` | float | Speed its animation should show: walking or running. |
| `BMBHurtFlashUntil` | float | `CurTime()` until which it flashes red. |
| `BMBInvulnerableUntil` | float | End of the window after a hit. |
| `BMBKnockbackUntil` | float | End of the knockback. |
| `BMBAttackStartedAt` | float | `CurTime()` of the last melee swing or shot. |
| `BMBOnFire` | bool | On fire. |
| `BMBFireUntil` | float | `CurTime()` at which the fire ends. |
| `BMBInSunlight` | bool | Standing in burning sunlight. Only kept up to date for mobs that burn in daylight. |

`BMBDistToGoal`, `BMBPathNode`, `BMBPathAdvance` and the `BMBHop...` values feed the debug HUD. The server writes them only while a player has `bmb_debug_hud` on, so do not use them for anything else.

*After 1.0.0* the debug tool publishes three more for its own display: `BMBDebugMoveTargetPos` (vector), the target of the mob's latest right-click order; `BMBDebugMoveResult` (string), empty while an order is active and its result afterwards; and `BMBDebugMoveResultAt` (float), `CurTime()` when the order ended.

The name of a mob, when it has one, is in `ent:GetNW2String("BMBCustomName")`; `ent:GetBMBCustomName()` reads it for you.
