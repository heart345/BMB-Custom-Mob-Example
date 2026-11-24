-- Registers the Ember Zombie with the spawn menu and with BMB's natural
-- spawner. Files in lua/autorun/ run on the server and on every client.

local CLASS = "example_ember_zombie"

-- Spawn menu > NPCs tab.
list.Set("NPC", CLASS, {
    Name = "Ember Zombie",
    Class = CLASS,
    Category = "BMB Example Mobs"
})

if CLIENT then return end

-- Natural spawning (optional; delete everything below if you do not want it).
-- BMB's spawner is off by default: server owners turn it on with
-- "bmb_spawn_enabled 1".

ExampleEmberZombie = ExampleEmberZombie or {}

local function registerNaturalSpawn()
    if ExampleEmberZombie.NaturalSpawnRegistered then return end

    if not scripted_ents.GetStored("bmb_zombie") then
        ErrorNoHalt("[Ember Zombie] BlockMob Base (BMB) is missing; this mob needs it.\n")
        return
    end
    if not (BMB and BMB.NaturalSpawn and BMB.NaturalSpawn.Register) then return end

    ExampleEmberZombie.NaturalSpawnRegistered = BMB.NaturalSpawn.Register(CLASS, {
        category = "monster", -- "monster" (dark places), "creature" or "ambient"
        weight = 8,           -- relative odds; zombie 30, skeleton 25, creeper 15
    })
end

-- Addon load order is not guaranteed, so wait until every addon has loaded.
hook.Add("InitPostEntity", "ExampleEmberZombie_NaturalSpawn", registerNaturalSpawn)
