# BMB ConVar and console command reference

[中文版](CONVARS.zh-CN.md) · [Back to the README](../README.md) · [API reference](API.md)

Every ConVar and console command that [Minecraft in GMod | Mobs](https://steamcommunity.com/sharedfiles/filedetails/?id=3774268246) (BMB) creates, grouped by what you would use it for.

This page was compiled from the Lua source of **BMB 1.0.0** (the Workshop build published on 2026-11-20). Names, defaults, ranges and flags were checked against that source by script. The descriptions say what the code does; the individual settings were not each tried in game.

The debug tool was reworked on 2026-11-25, after that build. What changed is marked *after 1.0.0* in [Debugging](#debugging) and was checked against BMB's source of that day. It is not in the 1.0.0 Workshop build.

## How to read the tables

- **Default** is the value in the source. A range in brackets, such as `32 [0–256]`, is enforced by the engine.
- **Saved** means the ConVar is archived: the value survives a restart. A ConVar that is not saved goes back to its default when the server or game restarts.
- **Server** ConVars exist on the server only. Set them from the server console, or as the host in single player or on a listen server. **Client** ConVars are each player's own setting.
- Distances written in *cells* or *blocks* are Minecraft blocks. One block is `BMB.BS` Source units (36.5 with MineMod's default).

Most of the server settings below also appear in the spawn menu under **Utilities > BlockMob Base**, in six panels: *BMB Mob Spawning*, *BMB Mob Limits*, *BMB Mob Attributes*, *BMB Fall Damage*, *BMB Climbing* and *BMB Fire*. The panels write the server ConVars directly, so they are for the host. On a dedicated server, set the ConVars from the server console or `server.cfg` (dedicated servers were not tested for this page).

## Contents

- [Mob attributes](#mob-attributes)
- [NPC relations](#npc-relations)
- [Mob death rewards](#mob-death-rewards)
- [Natural spawning](#natural-spawning)
- [Fire and sunlight](#fire-and-sunlight)
- [Fall damage](#fall-damage)
- [Climbing](#climbing)
- [Mobs changing blocks](#mobs-changing-blocks)
- [Settings for single mobs](#settings-for-single-mobs)
- [Block world and pathfinding](#block-world-and-pathfinding)
- [Movement and physics](#movement-and-physics)
- [Debugging](#debugging)
- [Client display](#client-display)
- [Client model tuning](#client-model-tuning)
- [Performance switches](#performance-switches)
- [Internal markers](#internal-markers)
- [Using ConVars from your own mob](#using-convars-from-your-own-mob)

## Mob attributes

Server, saved.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_health_scale` | `1` [0.01–100] | Multiplies every BMB mob's maximum health, custom mobs included. Living mobs keep their health percentage when it changes. Announced in chat when changed. |
| `bmb_minecraft_difficulty` | `2` | Minecraft difficulty used by the rules that have no Garry's Mod equivalent: `0` peaceful, `1` easy, `2` normal, `3` hard. Read by the breeze, drowned, parrot, piglin and pillager. Another addon can override it per mob with the `BMB.ResolveMinecraftDifficultyId` hook. |

Health in BMB is Minecraft health × 3.5, then × `bmb_health_scale`. A mob's `StartHealth` field is the value before `bmb_health_scale`.

## NPC relations

*After 1.0.0.* Server, saved. Set each integration independently with `1` to enable or `0` to disable it.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_native_npc_relations` | `1` | Enables the relation rules and natural acquisition between BMB and supported stock Source NPCs. |
| `bmb_vj_npc_relations` | `1` | Enables the integration between BMB and VJ Base SNPCs. |
| `bmb_drg_npc_relations` | `1` | Enables the integration between BMB and DrGBase NextBots. |

Disabling an integration stops BMB from adding that NPC type to new scans and restores the NPCs' own relationship rules. Existing retaliation follows the mob's own AI. See the [API reference](API.md#mob-relations) for the classification fields and queries.

## Mob death rewards

*After 1.0.0.* Server, saved. Both controls are in **Utilities > BlockMob Base > BMB Mob Spawning**, below the natural despawn settings.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_mob_death_rewards` | `3` [0–3] | `0` stops all built-in death rewards, `1` drops items only, `2` drops experience only, and `3` drops both. |
| `bmb_mob_drop_lifetime` | `300` [1–3600] | Lifetime of newly created BMB death item entities in game seconds. The Minecraft item mode counts 20 ticks per game second. On a merge, MineMod uses the resulting stack's lifetime and the younger stack's age. |

This setting applies to built-in death rewards. Breeding experience, eggs and ordinary MineMod drops have their own rules. See [Drops and experience](API.md#drops-and-experience) for custom mobs and loot hooks.

## Natural spawning

All server, saved. The spawner is **off by default**.

### Switches and caps

| ConVar | Default | What it does |
|---|---|---|
| `bmb_spawn_enabled` | `0` | Master switch for natural spawning. |
| `bmb_spawn_monsters` | `1` | Spawn hostile mobs (the `monster` category). Animals and bats do not depend on it. |
| `bmb_spawn_bats` | `1` | Spawn bats. |
| `bmb_spawn_slimes` | `1` | Spawn slimes in slime chunks. |
| `bmb_spawn_max` | `32` [0–256] | Most naturally spawned monsters alive at once. |
| `bmb_spawn_creature_max` | `10` [0–64] | Most naturally spawned animals alive at once. |
| `bmb_spawn_ambient_max` | `8` [0–64] | Most naturally spawned ambient mobs (bats) alive at once. |
| `bmb_spawn_slime_seed` | `0` | Seed for the slime chunk layout. The same seed always gives the same chunks. |

The caps count only mobs the spawner created. Mobs placed from the spawn menu do not use up the cap.

### Timing and placement

| ConVar | Default | What it does |
|---|---|---|
| `bmb_spawn_interval` | `5` [0.5–60] | Seconds between monster and bat spawn cycles. |
| `bmb_spawn_creature_interval` | `20` [1–300] | Seconds between animal spawn cycles. |
| `bmb_spawn_per_cycle` | `1` [1–8] | Monsters spawned per cycle. A pack counts as one. |
| `bmb_spawn_attempts` | `12` [1–64] | Candidate positions tried in one spawn attempt. |
| `bmb_spawn_min_distance` | `20` [1–64] | Nearest a mob may spawn to a player, in cells. |
| `bmb_spawn_max_distance` | `40` [2–128] | Farthest a mob may spawn from a player, in cells. |
| `bmb_spawn_max_light` | `7` [0–15] | Highest light level monsters may spawn in. |
| `bmb_spawn_allow_approximate_light` | `1` | When the block world cannot give an exact light level, accept its sky-exposure estimate. With `0`, a position with no exact light value is rejected. |
| `bmb_spawn_debug` | `0` | Print every spawn decision to the server console. |

### Despawning

| ConVar | Default | What it does |
|---|---|---|
| `bmb_spawn_despawn` | `1` | Remove naturally spawned mobs that are far from every player. Runs even when `bmb_spawn_enabled` is `0`. |
| `bmb_spawn_despawn_distance` | `64` [16–512] | Monsters and bats farther than this many cells from every player are removed at once. |
| `bmb_spawn_despawn_soft` | `32` [4–256] | Beyond this many cells, a monster or bat that has stayed out there for 30 seconds has a 1 in 12 chance each second to be removed. |
| `bmb_spawn_despawn_creature_distance` | `72` [16–512] | Animals farther than this many cells from every player are removed. Animals have no random band. |

Some mobs are never despawned: one held by the physics gun, frozen by the debug tool, or under a debug move order or forced target; and one that must persist, which means it has a name, is tamed, or is an enderman carrying a block.

### Per-class limits

Each limit caps how many mobs of that class may exist in the world before the spawner stops adding more. Unlike the caps above, these count every living mob of the class, hand-spawned ones included. `0` turns natural spawning of that class off. All have the range 0–64.

| ConVar | Default | | ConVar | Default |
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

`bmb_spawn_limit_witch` exists, but the witch has no natural spawn entry in this build, so it has no effect. With `bmb_spawn_limit_bat` and `bmb_spawn_limit_parrot` at `0`, bats and parrots do not spawn naturally until you raise them.

### Commands

| Command | Who | What it does |
|---|---|---|
| `bmb_spawn_now [monster\|creature\|ambient]` | Admin | Makes one spawn attempt near a random living player and prints the result, for example `[BMB spawn] forced monster spawn failed: outside_distance_band`. It ignores `bmb_spawn_enabled` and `bmb_spawn_monsters` but still obeys the caps and limits. The category defaults to `monster`. |
| `bmb_spawn_status` | Admin | Prints whether spawning is on, the three counts against their caps, which block world is active, the time of day and the sun strength. |

The failure reasons `bmb_spawn_now` can print are listed in the [API reference](API.md#failure-reasons).

## Fire and sunlight

All server, saved. BMB draws and times its own Minecraft-style fire; it does not use the engine's `Ignite`.

### Burning

| ConVar | Default | What it does |
|---|---|---|
| `bmb_sunlight_damage` | `3` [0–20] | Damage a burning mob takes on each burn tick. Despite the name it applies to every fire source. |
| `bmb_sunlight_interval` | `1` [0.1–10] | Seconds between burn ticks. Also every fire source. |
| `bmb_fire_check_interval` | `0.25` [0.05–2] | How often fire state and the contact sources below are updated. |
| `bmb_fire_debug` | `0` | Log fire state, source and contact damage. |

### Sunlight

| ConVar | Default | What it does |
|---|---|---|
| `bmb_sunlight_burn` | `1` | Mobs marked `BurnsInDaylight` catch fire under an open sky during the day. |
| `bmb_sunlight_random_tick` | `1` | Use Minecraft's random per-tick chance to ignite. With `0` an exposed mob ignites at the next check. |
| `bmb_sunlight_min_strength` | `0.5` [0–1] | How strong the sun must be (0 is night, 1 is noon) before it ignites anything. |
| `bmb_sunlight_check_interval` | `0.25` [0.1–2] | Seconds between sunlight exposure checks. |

### Lava and fire blocks

| ConVar | Default | What it does |
|---|---|---|
| `bmb_fire_lava` | `1` | Lava sets mobs on fire and hurts them. |
| `bmb_fire_lava_damage` | `14` [0–100] | Damage per lava contact tick. |
| `bmb_fire_lava_interval` | `0.5` [0.1–10] | Seconds between lava contact ticks. |
| `bmb_fire_lava_seconds` | `15` [0–60] | Seconds of fire a mob gets from touching lava. |
| `bmb_fire_blocks` | `1` | Standing in a fire or soul fire block sets mobs on fire and hurts them. |
| `bmb_fire_block_damage` | `3` [0–100] | Damage per fire block contact tick. |
| `bmb_fire_block_interval` | `0.5` [0.1–10] | Seconds between fire block contact ticks. |
| `bmb_fire_block_seconds` | `8` [0–60] | Seconds of fire a mob gets from standing in a fire block. |

A mob with `ENT.FireImmune = true` ignores all of this section.

## Fall damage

All server, saved.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_fall_damage` | `1` | Mobs take Minecraft-style fall damage. |
| `bmb_fall_damage_safe_distance` | `3` [0–64] | Cells a mob may fall without being hurt. |
| `bmb_fall_damage_multiplier` | `3.5` [0–20] | Damage per cell fallen beyond the safe distance. 3.5 matches BMB's scaled health; `1` gives Minecraft's raw numbers. |
| `bmb_fall_damage_block_modifiers` | `1` | Apply Minecraft's landing rules: hay and honey blocks ×0.2, beds ×0.5, slime blocks ×0, and no damage when the mob lands in water, powder snow or a cobweb. |
| `bmb_fall_damage_sound` | `1` | Play the fall sound when a mob is hurt by a fall. |
| `bmb_fall_damage_debug` | `0` | Print the distance, landing block and damage of every fall. |

A mob can override the first two per class with `ENT.FallSafeDistanceCells` and `ENT.FallDamageMultiplier`, or opt out with `ENT.FallDamageImmune = true`.

## Climbing

Server. This is the ladder climbing every mob has. The spider's wall climbing is separate, see [Spider wall climbing](#spider-wall-climbing).

| ConVar | Default | Saved | What it does |
|---|---|---|---|
| `bmb_climb` | `1` | yes | Mobs climb climbable blocks the way Minecraft mobs do, by walking into them. |
| `bmb_climb_vines` | `0` | yes | Count vines as climbable. Off because MineMod players cannot climb them yet. |
| `bmb_climb_scaffolding` | `0` | yes | Count scaffolding as climbable. Off for the same reason. |
| `bmb_climb_debug` | `0` | no | Print climbing decisions. |

## Mobs changing blocks

Server, saved. These are BMB's version of Minecraft's `mobGriefing` rule, one switch per mob. `0` stops that mob from changing MineMod blocks.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_creeper_griefing` | `1` | Creeper explosions destroy blocks. |
| `bmb_enderman_griefing` | `1` | Endermen pick up and place blocks. |
| `bmb_fireball_griefing` | `1` | Ghast and blaze fireballs destroy blocks and start fires. |
| `bmb_ravager_griefing` | `1` | Ravagers break the leaves they run into. |
| `bmb_snow_golem_griefing` | `1` | Snow golems leave a snow layer where they walk. |
| `bmb_evoker_griefing` | `1` | Evokers recolour blue sheep. |

## Settings for single mobs

Server, saved, unless a table says otherwise.

### Creeper

| ConVar | Default | What it does |
|---|---|---|
| `bmb_creeper_fuse_time` | `1.5` | Fuse length in seconds. |
| `bmb_creeper_swell_start_cells` | `3` | The creeper starts swelling when its target is closer than this many cells. |
| `bmb_creeper_swell_continue_cells` | `7` | A lit creeper calms down when its target is farther than this many cells. |
| `bmb_creeper_damage_scale` | `2.3` | Multiplier on explosion damage to entities. |
| `bmb_creeper_explosion_knockback` | `500` | How hard the explosion throws players. |
| `bmb_creeper_block_damage_scale` | `1.0` | Multiplier on explosion damage to blocks. |
| `bmb_creeper_step_volume` | `0.35` | Footstep volume. `0` is silent. |

### Slime

| ConVar | Default | What it does |
|---|---|---|
| `bmb_slime_split_count` | `2` | Smaller slimes spawned when a slime larger than size 1 dies. |
| `bmb_slime_hop_dist_scale` | `1` | Multiplier on how far a hop travels. |
| `bmb_slime_hop_height_scale` | `1` | Multiplier on hop height. |
| `bmb_slime_hop_interval_scale` | `1` | Multiplier on the pause between hops. |
| `bmb_slime_contact_damage_scale` | `1` | Multiplier on contact damage. |
| `bmb_slime_min_size_damage` | `0` | Contact damage of the smallest slime. |

### Enderman

| ConVar | Default | What it does |
|---|---|---|
| `bmb_enderman_teleport_ambient_interval` | `9` | Average seconds between the teleports of a calm enderman. |
| `bmb_enderman_teleport_cooldown` | `0.6` | Shortest time between two teleports. |
| `bmb_enderman_teleport_range` | `12` | How far a calm enderman may teleport, in blocks. |
| `bmb_enderman_teleport_reach_range` | `6` | How close to its target an angry enderman teleports, in blocks. |
| `bmb_enderman_teleport_flee_range` | `12` | How far it teleports to dodge a projectile, in blocks. |
| `bmb_enderman_stare_range` | `64` | How far away a player's stare is noticed, in blocks. |
| `bmb_enderman_stare_dot_bias` | `0.025` | How precisely the player must look at its head. Smaller is stricter. |
| `bmb_enderman_block_take_chance` | `10` | It picks up a block with a 1 in N chance per check. |
| `bmb_enderman_block_place_chance` | `1000` | It puts its block down with a 1 in N chance per check. |
| `bmb_enderman_block_goal_interval` | `0.10` | Seconds between those checks. |
| `bmb_enderman_block_debug` | `0` | Log pick-up and placement decisions. |

### Wolf

| ConVar | Default | What it does |
|---|---|---|
| `bmb_wolf_retaliate_players` | `1` | Wild wolves attack players who hurt them. |
| `bmb_wolf_variant_lock` | *(empty)* | Force one coat for every new wolf, by name or zero-based index. Empty picks at random by weight. |
| `bmb_wolf_variant_weight_<variant>` | `1` | Spawn weight of one coat. `<variant>` is `pale`, `spotted`, `snowy`, `black`, `ashen`, `rusty`, `woods`, `chestnut` or `striped`. |

### Goat and vex

| ConVar | Default | Saved | What it does |
|---|---|---|---|
| `bmb_goat_ram_knockback_scale` | `1` [0–10] | yes | Multiplier on how far a ram throws its target. At `1` an adult throws about 5 blocks. |
| `bmb_debug_goat_ram` | `0` | no | Print every ram attempt and why it ended. |
| `bmb_vex_phase_blocks` | `1` | yes | Vexes fly through blocks as in Minecraft. With `0` they collide like other mobs. |

### Spider wall climbing

Server, saved. These tune the wall climbing of `bmb_spider` and `bmb_cave_spider`. Speeds and distances are in Source units unless they say cells.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_spider_climb_spike` | `1` | Spiders climb walls. |
| `bmb_spider_climb_speed` | `105` | Climbing speed. |
| `bmb_spider_climb_probe_distance` | `42` | How far ahead it looks for a wall. |
| `bmb_spider_climb_wall_clearance` | `30` | Distance kept from the wall while climbing. |
| `bmb_spider_climb_mantle_forward` | `46` | Forward distance of the step onto the top. |
| `bmb_spider_climb_mantle_up` | `44` | How far up it searches for the top. |
| `bmb_spider_climb_mantle_down` | `90` | How far down it searches for the top. |
| `bmb_spider_climb_mantle_start_below` | `3` | How close below the ledge it must be before it steps over. |
| `bmb_spider_climb_mantle_speed` | `72` | Speed of the step onto the top. |
| `bmb_spider_climb_timeout` | `7` | Longest climb, in seconds. |
| `bmb_spider_climb_blocked_hold_time` | `3` | Seconds it clings to a blocked ledge before giving up. |
| `bmb_spider_climb_descend_speed` | `88` | Speed coming back down after giving up. |
| `bmb_spider_climb_descend_timeout` | `6` | Longest descent, in seconds. |
| `bmb_spider_climb_giveup_cooldown` | `4` | Seconds before it tries a wall again after giving up. |
| `bmb_spider_climb_cancel_cooldown` | `1.6` | Seconds before it climbs again after a chase cancelled the climb. |
| `bmb_spider_climb_chase_active` | `1` | While chasing, head for a wall below a target that is higher up. |
| `bmb_spider_climb_chase_min_target_up` | `18` | The target must be at least this much higher before a chase starts a climb. |
| `bmb_spider_climb_chase_wall_dot` | `0.1` | How directly the wall must lie between spider and target. |
| `bmb_spider_climb_chase_cancel_grace` | `0.45` | Seconds a climb may run before a moving target can cancel it. |
| `bmb_spider_climb_chase_approach_distance` | `260` | How far ahead a chasing spider looks for a wall to climb. |
| `bmb_spider_climb_chase_approach_timeout` | `0.45` | Longest single run toward such a wall, in seconds. |
| `bmb_spider_climb_chase_start_distance` | `84` | Within this distance of the wall the climb starts at once. |
| `bmb_spider_climb_max_cells` | `6` | Tallest wall, in cells, the pathfinder treats as climbable. |
| `bmb_spider_climb_edge_cost` | `2.5` | Path cost of each cell climbed. Higher makes spiders prefer walking round. |
| `bmb_spider_climb_horizontal_cells` | `2` | How many cells from the wall a climb may start in the pathfinder. |
| `bmb_spider_prefer_climb_over_hop` | `0` | Prefer climbing over a one-block hop where both would work. |
| `bmb_debug_spider_climb` | `0` | Print climbing diagnostics. |

## Block world and pathfinding

Server. BMB reads blocks through an adapter that has two back ends: the real MineMod world, and a flat mock world used for development.

| ConVar | Default | Saved | What it does |
|---|---|---|---|
| `bmb_use_real_world` | `1` | yes | Use the MineMod world when MineMod is loaded. BMB falls back to the mock world when it is not. |
| `bmb_use_source_path` | `0` | yes | Experimental: follow the map's navmesh instead of BMB's block pathfinder. |
| `bmb_path_admission` | `2` | no | How many path searches may start in one server tick. Extra mobs wait a tick. `0` is unlimited. |
| `bmb_block_cache_ttl` | `0.25` [0–5] | yes | Seconds a block shape lookup is cached. `0` turns the cache off. |
| `bmb_block_cache_sweep` | `30` [0–300] | yes | Seconds between full clears of that cache. `0` never clears. |
| `bmb_block_cache_max` | `120000` [1000–500000] | yes | Entries kept before the cache is dropped and rebuilt. |

### Source map geometry

MineMod blocks are not the only obstacles: the map's own walls and static props are too. These settings control how the pathfinder sees them.

| ConVar | Default | Saved | What it does |
|---|---|---|---|
| `bmb_source_geometry` | `1` | yes | The pathfinder sees the map's static geometry. With `0` it sees only MineMod blocks. |
| `bmb_source_geometry_props` | `1` | yes | Count static props as obstacles and floors. With `0`, only world brushes count. |
| `bmb_source_geometry_inset` | `0.6` [0.2–1] | yes | Width of clear space, in cells, a cell needs to count as walkable. |
| `bmb_source_geometry_support_grace` | `6` [0–18] | yes | How far below the bottom of a cell, in units, a floor may be and still count as that cell's floor. |
| `bmb_source_geometry_step_allowance` | `28` [0–36] | yes | Obstacles lower than this many units are not walls; mobs step onto them. |
| `bmb_source_geometry_cache_max` | `120000` [1000–2000000] | yes | Entries kept in the geometry cache. |
| `bmb_source_geometry_debug` | `0` | no | Draw the probe results for admins: red is an obstacle, green is a floor. |
| `bmb_source_geometry_debug_radius` | `5` [1–15] | no | Horizontal radius of that drawing, in cells. |
| `bmb_source_geometry_debug_height` | `3` [1–15] | no | Vertical radius of that drawing, in cells. |

### Chase tuning

Server, saved unless noted. These adjust how a chasing mob switches between running straight at its target and following a computed path.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_chase_step_up` | `1` | A mob running straight at its target jumps a one-block step in its way. With `0` only path following climbs steps. |
| `bmb_chase_direct_resuppress_time` | `0.6` | After a straight run fails, seconds to stay on the path before trying a straight run again. |
| `bmb_chase_cliff_memory_cooldown` | `3.0` | Seconds before a straight line that ended at a drop may be tried again. |
| `bmb_chase_cliff_memory_duration` | `25.0` | Longest time such a failure is remembered. |
| `bmb_chase_cliff_memory_move_cells` | `6.0` | Cells the mob must move before it retries that line. |
| `bmb_chase_cliff_memory_target_cells` | `2.0` | Cells the target must move before the mob retries that line. |
| `bmb_chase_wall_memory_cooldown` | `0.8` | Seconds before a straight line that ended at a wall may be tried again. |
| `bmb_chase_wall_memory_duration` | `3.0` | Longest time such a failure is remembered. |
| `bmb_chase_repath_cliff_giveup_time` | `4.0` | Seconds blocked by a drop before the mob drops its target. |
| `bmb_chase_hightarget_unreachable_duration` | `3.0` | Seconds to remember that a nearby target higher up had no complete path. |
| `bmb_chase_distance_ttl` | `1` | *Not saved.* Mobs far from their target recompute their path less often. `0` uses the same interval for all. |

### Commands

| Command | Who | What it does |
|---|---|---|
| `bmb_world [mock\|real]` | Admin | Switches the back end, or with no argument prints which one is active. |
| `bmb_block_probe [bx by bz]` | Admin | Prints what BMB sees in a block: aim at the block, or pass cell coordinates. Use it to find out why a mob will not walk somewhere. |
| `bmb_source_geometry_flush` | Admin | Drops the map geometry cache. |
| `bmb_mock_show [radius\|all] [seconds]` | Anyone | Draws the mock world's blocks around you. |
| `bmb_mock_reset` | Anyone | Rebuilds the mock world around you. |

## Movement and physics

Server. Leave these alone unless you are chasing a specific movement bug.

| ConVar | Default | Saved | What it does |
|---|---|---|---|
| `bmb_safety_ceiling_clearance` | `2` | yes | Headroom, in units, kept below a mob's head when it probes ahead for walls. |
| `bmb_ground_unsink` | `1` | yes | Lift a mob that has sunk below the floor back onto it. |
| `bmb_ground_unsink_eps` | `2` | yes | How many units a foot must be below the floor before that happens. |
| `bmb_knockback_air_step` | `1` | yes | Which hits put a mob into the airborne launch handling: `0` none, `1` real launches only, `2` every upward knock. |
| `bmb_landing_step_clamp` | `1` | yes | Stop a landing mob from dipping into the floor. `0` is the old behaviour. |
| `bmb_mob_separation` | `1` | no | Mobs push each other apart softly. `0` turns the whole layer off. |
| `bmb_mob_separation_nudge` | `0` | no | Also teleport overlapping mobs apart. Breaks client smoothing. |
| `bmb_loco_engine_avoid` | `0` | no | Turn the engine's own NextBot obstacle avoidance back on. Affects newly spawned mobs. |
| `bmb_flight_smooth` | `1` | yes | Update flying mobs more often while they fly fast. |
| `bmb_flight_smooth_update` | `0.03` | yes | Update interval used for that, in seconds. |
| `bmb_flight_smooth_speed` | `150` | yes | Flight speed, in units per second, above which a mob asks for it. |
| `bmb_flight_tick_move` | `1` | yes | Move flying mobs every server tick. |
| `bmb_lifecycle_drive_per_tick` | `0` | no | Issue the movement of breeding, tempting and following animals every tick. |
| `bmb_lifecycle_drive_steer` | `1` | no | Those animals turn to face their goal before they walk. |

### Props hitting mobs

Server, saved. A prop that hits a mob hurts it according to its momentum.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_physics_impact_min_speed` | `90` | A prop slower than this is ignored. |
| `bmb_physics_impact_min_momentum` | `18000` | Momentum below this does no damage. |
| `bmb_physics_impact_momentum_scale` | `0.00026` | Damage per unit of momentum above that threshold. |
| `bmb_physics_impact_max_damage` | `30` | Most damage from one impact. |

## Debugging

### The two you will use most

| ConVar | Default | Where | What it does |
|---|---|---|---|
| `bmb_debug_hud` | `0` | Client, saved | Draws two lines above every BMB mob: class, health, state and move mode; then speed, wanted speed, distance to goal and path node. A third line appears for a moment after each block hop. |
| `bmb_freeze` | `0` | Server, not saved | Freezes every BMB mob in place. Their AI stops; they still take damage. |

The server sends the extra numbers the HUD needs only while some player has `bmb_debug_hud` on.

### Log switches

Server. Each prints to the server console. Saved unless noted, so remember to turn them off.

| ConVar | What it logs |
|---|---|
| `bmb_debug_chase` | Chase decisions: path found, partial or missing, and which safety check stopped a move. |
| `bmb_debug_melee_knockback` | Every melee attempt, hit and knockback. |
| `bmb_debug_ranged` | Every arrow shot with its ballistics. |
| `bmb_debug_flight` | Flight path results. |
| `bmb_debug_flight_vel` | Wanted and actual velocity of flying mobs. |
| `bmb_debug_hop_log` | Every block hop: launch, peak and result. |
| `bmb_debug_ground_unsink` | Every time a mob is lifted back onto the floor. |
| `bmb_debug_liquid` | Liquid contact and buoyancy of mobs in water. |
| `bmb_debug_knockback_launch` | *Not saved.* Start and end of every airborne launch. |
| `bmb_debug_spider_climb` | Spider wall climbing. |
| `bmb_flee_sun_debug` | Why a burning skeleton does or does not run for shade. |
| `bmb_fireball_debug` | Fireball spawns, deflections and impacts. |
| `bmb_entity_interact_debug` | Each step of using an item on a mob. |
| `bmb_allay_interact_debug` | Giving items to an allay and taking them back. |
| `bmb_tempt_recompute_debug` | *Not saved.* Destination updates of animals following food. |

Three commands flip a log switch for you. Each takes `0` or `1` and defaults to `1`. Admin only.

| Command | Sets |
|---|---|
| `bmb_chase_debug` | `bmb_debug_chase` |
| `bmb_melee_knockback_debug` | `bmb_debug_melee_knockback` |
| `bmb_ranged_debug` | `bmb_debug_ranged` |

More log switches are listed with the feature they belong to: `bmb_spawn_debug`, `bmb_fire_debug`, `bmb_fall_damage_debug`, `bmb_climb_debug`, `bmb_enderman_block_debug`, `bmb_debug_goat_ram`, `bmb_source_geometry_debug` and `bmb_held_item_debug`.

One more server ConVar, not saved, controls the HUD's data feed:

| ConVar | Default | What it does |
|---|---|---|
| `bmb_debug_nw` | `-1` | `-1` sends the HUD's extra numbers only while a player has the HUD on. `1` always sends them, `0` never does. |

### Debug commands

Admin only. Each acts on the BMB mob you are aiming at, or failing that the nearest one within 768 units. *After 1.0.0* the mob selected with the BMB Debug tool comes before the nearest one.

| Command | What it does |
|---|---|
| `bmb_debug_info` | Prints class, health, state, move mode, speeds, distance to goal and position. |
| `bmb_debug_health [value]` | Sets its health, then prints the same line. 1.0.0 uses the number as given; 0 or less leaves a mob with no health that has not died. *After 1.0.0* the value is kept between 1 and 100000. |
| `bmb_debug_speed [walk] [run] [accel] [decel]` | Sets its speeds and prints them. Values you leave out are not changed. |
| `bmb_debug_move [seconds] [speed]` | Makes it walk in a straight line. Defaults: 5 seconds at its run speed. In 1.0.0 it walks the way the mob is facing: a bug keeps the direction you look in from being used. *After 1.0.0* it walks the way you are looking. |
| `bmb_debug_stop` | Cancels a debug move or forced flee. |
| `bmb_debug_flee [seconds]` | Makes it panic. Only works on mobs with a panic behaviour (passive animals). |

### The BMB Debug tool

The tool gun has a **BMB Debug** tool under the *BlockMob Base* category. Left click selects a mob. Right click on the ground sends the selected mob there. Reload cancels its order. The tool's panel has the buttons for everything else.

The panel's sliders are client ConVars, saved:

| ConVar | Default | What it sets |
|---|---|---|
| `bmb_debug_move_speed` | `120` | Speed of right-click move orders. |
| `bmb_debug_flee_duration` | `5` | Seconds of the forced flee. |
| `bmb_debug_edit_health` | `20` | Health to apply. |
| `bmb_debug_edit_walk` | `70` | Walk speed to apply. |
| `bmb_debug_edit_run` | `145` | Run speed to apply. |
| `bmb_debug_edit_accel` | `240` | Acceleration to apply. |
| `bmb_debug_edit_decel` | `260` | Deceleration to apply. |
| `bmb_debug_action_damage` | `7` | *After 1.0.0.* Damage of the `hurt` action. |
| `bmb_debug_action_fire_seconds` | `8` | *After 1.0.0.* Seconds of fire of the `ignite` action. |

The panel's buttons run these commands on the selected mob. Admin only.

| Command | What it does |
|---|---|
| `bmb_tool_stop` | Cancels its order. |
| `bmb_tool_force_flee` | Makes it panic for `bmb_debug_flee_duration` seconds. |
| `bmb_tool_toggle_ignore_players` | Toggles whether it ignores players. |
| `bmb_tool_toggle_freeze` | Freezes or unfreezes just this mob. |
| `bmb_tool_force_aggro` | Makes it attack you. |
| `bmb_tool_force_aggro_pick` | Makes it attack the next mob you left click. Run it again to cancel. |
| `bmb_tool_apply_health` | Applies `bmb_debug_edit_health`. |
| `bmb_tool_apply_speed` | Applies the four speed sliders. |
| `bmb_tool_action <name>` | *After 1.0.0.* Makes it do one thing, such as take a hit or catch fire. The names are listed below. |

#### Changes after 1.0.0

The debug tool was reworked on 2026-11-25. This subsection, and every entry above marked *after 1.0.0*, describes BMB's source since that day. None of it is in the 1.0.0 Workshop build. If your console does not know `bmb_tool_action`, your BMB does not have these changes.

**Move orders.** In 1.0.0 a mob sent somewhere with right click could give up on the way. An order now works like this:

- It counts as arrived only on the level of the target. Walking under or over the target no longer ends it. Flying mobs are judged by horizontal distance alone, as before.
- It gives up after 3.5 seconds without progress, and only once three attempts in a row have brought none. After 14 seconds without progress it gives up whatever the attempts.
- Progress means getting nearer to the target than the mob has been during this order. Following its path at least one block further also counts, for up to 45 seconds without getting nearer, so that a detour is not taken for being stuck.
- Right click again, even on the same spot, and the order starts afresh.
- It runs out no sooner than 120 seconds after the click and no sooner than 8 seconds after its last progress. This part is as in 1.0.0.

**Messages.** The player who gave an order is told in chat when it ends short of the target: the mob gave up (with the distance left and its last move mode), the order ran out of time, or a spider started to climb a wall, which drops the order. A `bmb_debug_move` walk that stops early says why as well. Right click also says at once when:

- no block the mob can stand on is within 4 blocks of the point you clicked. The mob then tries the point itself and will probably stop short;
- the mob is frozen. It starts when it is unfrozen, if the order has not run out by then;
- the mob is a pet that was told to sit. Tell it to stand first.

**On screen.** While you hold the BMB Debug tool or the physics gun, the target block of the selected mob is outlined in green, with a line to it from the mob, for as long as the order is alive. The outline is where the order really points, after the tool moved it to a block the mob can stand on. For 10 seconds after an order ends, the *Selected* line at the bottom of the screen shows `move:` and one of these results:

| Result | Meaning |
|---|---|
| `arrived` | It reached the target. |
| `no_progress` | It gave up. |
| `expired` | The order ran out of time. |
| `stopped` | You cancelled it with Reload, `bmb_tool_stop` or `bmb_debug_stop`. |
| `climb` | A spider started to climb a wall. |
| `cancelled` | Another command took the mob over: a forced flee, a forced attack or a sit order. |
| `done` | A `bmb_debug_move` walk lasted its full time. |
| `unsafe`, `blocked`, `stuck` | A `bmb_debug_move` walk stopped early: the way ahead was not safe, the mob made no headway, or the engine reported it stuck. |

A walking mob that hangs on the corner of a block is first put back on the middle of its block. Its move mode reads `debug_recenter` meanwhile.

**Actions.** `bmb_tool_action <name>` makes the selected mob do one thing. An unknown name prints the list. The panel has a button for each name, below *Apply movement tuning*.

| Name | What it does |
|---|---|
| `hurt` | Hits it for `bmb_debug_action_damage`, as a normal hit dealt by you, so it reacts as it would to any hit. Says so if the hit was ignored: the mob was hit less than half a second before, or is immune. |
| `kill` | Kills it through the same damage pipeline. A mob that ignores the hit survives; try again half a second later. |
| `ignite` | Sets it on fire for `bmb_debug_action_fire_seconds`. Mobs immune to fire refuse. |
| `extinguish` | Puts the fire out. |
| `tame` | Tames it with you as the owner. Only mobs that can be tamed: wolf, cat and parrot. |
| `sit` | Tells a tamed pet to sit, or to stand if it is sitting. Sitting drops its move order. |

The command accepts 1 to 100000 for the damage and 1 to 120 for the seconds. The panel's two sliders stop at 200 and 60.

### Other commands

| Command | Who | What it does |
|---|---|---|
| `bmb_spawn_sleeping_cat` | Admin | Spawns a frozen cat lying down where you aim. For screenshots. |
| `bmb_spawn_sleeping_fox` | Admin | Spawns a frozen sleeping fox. |
| `bmb_spawn_sitting_camel` | Admin | Spawns a frozen sitting camel. |
| `bmb_villager_reputation` | Anyone | Prints what nearby villagers think of you. |
| `bmb_fire_status` | Client | Prints the state of the fire materials and of burning mobs. |
| `bmb_mc_light_debug` | Client | Prints the values used to light mobs. |

## Client display

Client, saved unless noted.

| ConVar | Default | What it does |
|---|---|---|
| `bmb_language` | `auto` | Language of BMB's menus and messages: `auto` follows the game language, or `en`, or `zh`. |
| `bmb_fire_max_distance` | `2000` | Fire on mobs farther away than this many units is not drawn. `0` always draws it. |
| `bmb_fire_force` | `0` | *Not saved.* Draw fire on every mob, for testing. |
| `bmb_cl_bone_far_distance` | `1500` | Mobs farther away than this many units update their bones about 15 times a second instead of every frame. `0` always updates every frame. |
| `bmb_depth_pass_model_only` | `1` | In depth passes (ambient occlusion, flashlight shadows) draw only the bare model. `0` is the old behaviour. |
| `bmb_mc_light_unit_exposure` | `1` | Draw block-lit mobs at fixed exposure, like MineMod's terrain. |
| `bmb_mc_light_gain` | `1` | Brightness multiplier for block-lit mobs when the setting above is on. |
| `bmb_mc_effect_light_pbr` | `1` | With MineMod's PBR pack, light BMB's particles the way mobs are lit. |
| `bmb_mc_effect_unit_exposure` | `1` | Draw block-lit particles at fixed exposure too. |

## Client model tuning

Client, saved. These position the things mobs hold, and adjust a few procedural animations. BMB's own values are baked in as the defaults; the ConVars exist so the author can tune a model in game. They affect only what you see on your own screen.

### Held items

Every profile has seven ConVars: `<prefix>_pos_x`, `<prefix>_pos_y`, `<prefix>_pos_z`, `<prefix>_ang_p`, `<prefix>_ang_y`, `<prefix>_ang_r` and `<prefix>_scale`. Some also have left-handed variants named `<prefix>_lefthand_<field>`.

| Prefix | Item |
|---|---|
| `bmb_pigman_sword`, `bmb_pigman_spear`, `bmb_pigman_spear_chase` | Zombified piglin's sword and spear |
| `bmb_piglin_sword`, `bmb_piglin_spear`, `bmb_piglin_spear_chase`, `bmb_piglin_crossbow` | Piglin's weapons |
| `bmb_piglin_brute_axe` | Piglin brute's axe |
| `bmb_drowned_trident`, `bmb_drowned_fishing_rod`, `bmb_drowned_shell` | Drowned's items |
| `bmb_pillager_crossbow` | Pillager's crossbow |
| `bmb_vindicator_axe` | Vindicator's axe |
| `bmb_wither_sword` | Wither skeleton's sword |
| `bmb_allay_item`, `bmb_allay_block` | What an allay carries |
| `bmb_panda_item` | What a panda holds |

| Command | What it does |
|---|---|
| `bmb_held_item_dump [profile]` | Prints the current values of a profile. Look at the mob, or pass a profile name. |
| `bmb_held_item_reset [profile]` | Puts a profile back to its defaults. |
| `bmb_held_item_debug` | A ConVar, default `0`, not saved. Prints why a held item is not drawn. |

### Other attachments and poses

| ConVars | Default | What they tune |
|---|---|---|
| `bmb_bow_off_x`, `bmb_bow_off_y`, `bmb_bow_off_z`, `bmb_bow_ang_p`, `bmb_bow_ang_y`, `bmb_bow_ang_r` | `0` | Extra offset and rotation of the skeleton's bow. |
| `bmb_bow_scale` | `1` | Scale of the skeleton's bow. |
| `bmb_enderman_block_forward_cells`, `bmb_enderman_block_lateral_cells`, `bmb_enderman_block_vertical_cells` | `0` | Offset of the block an enderman carries, in cells. |
| `bmb_enderman_block_scale` | `0.5` | Size of that block, in cells. |
| `bmb_enderman_scary_head_x`, `_y`, `_z` | `0`, `11.4`, `0` | Head offset of the screaming enderman face. |
| `bmb_enderman_scary_hat_x`, `_y`, `_z` | `0`, `-11.4`, `0` | Hat layer offset of that face. |
| `bmb_enderman_creepy_jitter_scale` | `0.012` | How much an angry enderman shakes, in blocks. |
| `bmb_enderman_creepy_angle_jitter` | `0.2` | How much its outline twitches, in degrees. |
| `bmb_snow_golem_pumpkin_x`, `_y`, `_z`, `_pitch`, `_yaw`, `_roll`, `_scale` | `0`, `5.5`, `0`, `-90`, `0`, `-90`, `0.625` | Position of the snow golem's pumpkin. |
| `bmb_vex_sword_x`, `_y`, `_z`, `_pitch`, `_yaw`, `_roll`, `_scale` | tuned values | Position of the vex's sword. |
| `bmb_wolf_body_offset_*`, `bmb_wolf_upper_body_offset_*`, `bmb_wolf_tail_offset_*` | `0` | Offsets for three wolf bones. Each has `rot_x`, `rot_y`, `rot_z`, `pos_x`, `pos_y` and `pos_z`. |
| `bmb_rabbit_head_*`, `bmb_rabbit_ears_*`, `bmb_rabbit_frontlegs_*`, `bmb_rabbit_backlegs_*`, `bmb_rabbit_tail_*` | tuned values | Offsets for five rabbit bone groups. Each has `pos_x`, `pos_y`, `pos_z`, `pitch`, `yaw` and `roll`. |

| Command | What it does |
|---|---|
| `bmb_enderman_block_dump`, `bmb_enderman_block_reset` | Print or reset the carried block settings. |
| `bmb_snow_golem_attachment_dump`, `bmb_snow_golem_attachment_reset` | Print or reset the pumpkin settings. |
| `bmb_vex_sword_dump`, `bmb_vex_sword_reset` | Print or reset the vex sword settings. |

### Spider legs

| ConVar | Default | What it does |
|---|---|---|
| `bmb_spider_leg_animation` | `1` | Animate spider legs. |
| `bmb_spider_leg_swing_max` | `15` | How far the legs swing forward and back. |
| `bmb_spider_leg_lift_max` | `10` | How far the legs lift. |
| `bmb_spider_leg_frequency` | `1` | Multiplier on walking rhythm. |
| `bmb_spider_leg_phase_a` | `0` | Phase of leg group A, in radians. |
| `bmb_spider_leg_phase_b` | `3.1416` | Phase of leg group B, in radians. |
| `bmb_spider_leg_phase_step` | `0.7854` | Phase step from the front legs to the back, in radians. |
| `bmb_spider_leg_lift_phase` | `0` | Offset of the lift within the stride. |
| `bmb_spider_leg_swing_axis` | `0` | Axis of the swing: `0` pitch, `1` yaw, `2` roll. |
| `bmb_spider_leg_lift_axis` | `2` | Axis of the lift, same numbering. |
| `bmb_spider_leg_solo` | `0` | Animate only one leg, `1` to `8`. `0` animates all. |
| `bmb_spider_leg_axis_test` | `0` | Hold one leg at a fixed angle about one axis: `1` pitch, `2` yaw, `3` roll. |
| `bmb_spider_leg_axis_test_leg` | `8` | Which leg that test uses. |
| `bmb_spider_leg_axis_test_angle` | `35` | The test angle. |
| `bmb_spider_leg_debug_tuning` | `0` | *Not saved.* Use the experimental tuning instead of the released pose. |
| `bmb_spider_leg<N>_group` | per leg | Gait group of leg N (`0` to `7`): `0` is A, `1` is B. |
| `bmb_spider_leg<N>_swing_offset` | `0` | Fixed swing angle added to leg N. |
| `bmb_spider_leg<N>_lift_offset` | per leg | Fixed lift angle added to leg N. |
| `bmb_spider_leg<N>_phase_offset` | `0` | Phase added to leg N, in radians. |

## Performance switches

These exist so the author can compare a code path with and without an optimisation. None is saved unless noted. Leave them at their defaults.

| ConVar | Default | Where | What it switches |
|---|---|---|---|
| `bmb_safety_memo` | `1` | Server | Reuse the result of the forward safety check for a few ticks. |
| `bmb_carrot_reuse` | `1` | Server | Reuse the path look-ahead visibility result. |
| `bmb_surface_profile_fast` | `1` | Server | Fast path for full-cube blocks in the block adapter. |
| `bmb_surface_walk_context` | `1` | Server | Reuse block profiles inside one pathfinder step. |
| `bmb_p1` | `1` | Server | Master switch of the Think maintenance optimisations. |
| `bmb_p1_<name>` | `1` | Server | One part of them. `<name>` is `context`, `lookat`, `separation`, `climb`, `climb_window`, `liquid`, `unsink`, `maintenance`, `ambient`, `lookat_decision`, `liquid_gate`, `unsink_gate`, `climb_gate`, `activity` or `context_args`. |
| `bmb_p1_entity_table` | `0` | Server | An experiment that is off because it measured slower. |
| `bmb_p2` | `0` | Server | Master switch of the allocation optimisations. Off: it lowered memory churn but raised average cost. |
| `bmb_p2_trace`, `bmb_p2_xyz`, `bmb_p2_profiles`, `bmb_p2_flight` | `1` | Server | Parts of them. They do nothing while `bmb_p2` is `0`. |
| `bmb_p2_closures`, `bmb_p2_slice` | `0` | Server | Parts that measured slower. |
| `bmb_cl_anim_pose_reuse` | `1` | Client, saved | Reuse animation pose tables instead of making new ones every frame. |

### Performance counters

| Name | Kind | Default | Where | What it does |
|---|---|---|---|---|
| `bmb_perf` | ConVar | `0` | Server, saved | Print a summary of BMB's server counters every `bmb_perf_interval` seconds. |
| `bmb_perf_interval` | ConVar | `5` [1–60] | Server, saved | Seconds between those summaries. |
| `bmb_perf_deep` | ConVar | `0` | Server | Also time each part of the mob Think. Costs performance itself; use it only while measuring. |
| `bmb_perf_report` | Command | | Admin | Print the server counters now. |
| `bmb_perf_reset` | Command | | Admin | Reset the server counters. |
| `bmb_cl_perf` | ConVar | `0` | Client, saved | Client counters: `0` off, `1` on, `2` also counts bone writes. |
| `bmb_cl_perf_interval` | ConVar | `5` | Client, saved | Seconds between client summaries. |
| `bmb_cl_perf_report` | Command | | Client | Print the client counters now. |
| `bmb_cl_perf_reset` | Command | | Client | Reset the client counters. |

## Internal markers

BMB records one-time migrations of old default values in ConVars of its own. Do not set them; changing one makes BMB overwrite a setting again.

- Server: `bmb_spawn_limits_v2_migrated`, `bmb_spawn_limits_v3_migrated`, `bmb_spawn_distance_v2_migrated`, `bmb_spawn_default_off_migrated`, `bmb_sunlight_fire_v2_migrated`, `bmb_sunlight_fire_v3_migrated`, `bmb_sunlight_fire_v4_migrated`, `bmb_sunlight_fire_v5_migrated`, `bmb_fire_block_damage_v2_migrated`.
- Client: `bmb_language_auto_migrated`, `bmb_held_item_defaults_version`, `bmb_pigman_spear_split_migrated`, `bmb_pigman_spear_chase_pitch_migrated`, `bmb_panda_item_grip_20261110`, `bmb_snow_golem_pumpkin_defaults_version`, `bmb_vex_sword_defaults_version`.

## Using ConVars from your own mob

**Read BMB's settings** with `GetConVar`. Check for `nil`, because the ConVar does not exist when BMB is missing or on the wrong side:

```lua
local difficulty = GetConVar("bmb_minecraft_difficulty")
local hard = difficulty and difficulty:GetInt() >= 3
```

**Give your mob its own natural spawn limit and switch.** `BMB.NaturalSpawn.Register` takes the *names* of two ConVars that you create yourself:

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

The spawner reads both by name every time it picks a class. A limit of `0` stops your mob from spawning naturally. If a ConVar with that name does not exist, the option is ignored. This snippet was written from BMB's source and was not run in game.

**Name your own ConVars with your own prefix**, not `bmb_`. A future BMB ConVar with the same name would clash with yours.

**The settings that already cover your mob.** A custom mob that inherits from a BMB class is a BMB mob, so these apply to it without any work: `bmb_health_scale`, `bmb_freeze`, `bmb_debug_hud`, the debug commands and tool, fall damage, fire and sunlight, climbing, and the movement and pathfinding settings. The per-mob settings (`bmb_creeper_*`, `bmb_slime_*` and so on) apply only if you inherit from that mob.
