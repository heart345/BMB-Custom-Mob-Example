-- Ember Zombie: a minimal custom mob for BlockMob Base (BMB).
--
-- This is a normal Garry's Mod scripted entity. Everything that is not written
-- in this file is inherited from BMB's zombie: pathfinding, chasing, melee,
-- knockback, sounds and animation.
--
-- To make your own mob: copy this file, rename it (the file name IS the class
-- name) and change what you need. Do not use the "bmb_" prefix for your class.

AddCSLuaFile()

-- Gives this file a local "BaseClass" table holding the zombie's functions,
-- so the overrides below can still call the original versions.
DEFINE_BASECLASS("bmb_zombie")

ENT.Base = "bmb_zombie"
ENT.Type = "nextbot"
ENT.PrintName = "Ember Zombie"
ENT.Author = "Your Name"
ENT.Category = "BMB Example Mobs"
ENT.Spawnable = true
ENT.AdminOnly = false

-- 1. Stats -------------------------------------------------------------------
-- Plain fields. Anything you leave out keeps the zombie's value; the full list
-- is at the top of BMB's lua/entities/bmb_zombie.lua.

ENT.StartHealth = 50          -- zombie: 70 (BMB health = Minecraft health x 3.5)
ENT.RunSpeed = 100            -- chase speed in units/second (zombie: about 71)
ENT.AttackMoveSpeed = 100     -- speed kept while swinging; match RunSpeed
ENT.AttackDamage = 7          -- zombie: 10.5
ENT.BurnsInDaylight = false   -- zombies normally burn in sunlight
ENT.FireImmune = true         -- lava and fire blocks cannot set it alight
ENT.BMBMinecraftEnemy = true  -- iron golems and co. treat it as a monster

-- 2. Look --------------------------------------------------------------------
-- Tint the stock zombie model instead of shipping a new one. BMB's renderer
-- respects Entity:SetColor().

local EMBER_COLOR = Color(255, 150, 70)

function ENT:Initialize()
    BaseClass.Initialize(self) -- always run the parent's setup first
    if CLIENT then return end

    self:SetColor(EMBER_COLOR)
end

-- 3. Behaviour ---------------------------------------------------------------
-- BMB calls OnBMBMeleeHit on the server right after a melee hit has landed.

function ENT:OnBMBMeleeHit(target, damageInfo)
    BaseClass.OnBMBMeleeHit(self, target, damageInfo) -- hit sound, view punch

    if IsValid(target) and target:IsPlayer() and target:Alive() then
        target:Ignite(3)
    end
end
