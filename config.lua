Config = {}

-- Item names (must match your items in qbx_core)
Config.FakePlateItem = 'fakeplate'
Config.FakePlateRemoverItem = 'fakeplate_remover'

-- Target System (set to false if you don't use target)
Config.UseTarget = true -- Set to true if using ox_target or qb-target
Config.TargetResource = 'ox_target' -- Options: 'ox_target' or 'qb-target'

-- Notification settings
Config.UseOxLib = false -- Set to true if using ox_lib for notifications

-- Time to apply/remove plate (in milliseconds)
Config.ApplyTime = 5000
Config.RemoveTime = 20000 -- Changed to 20 seconds as requested
Config.StealPlateTime = 15000 -- Time to steal a plate from NPC vehicle

-- Fake plate format (generates random plates)
Config.PlateFormat = '########' -- # = random letter or number

-- NPC Reaction Settings
Config.NPCReaction = {
    Enabled = true, -- Enable NPC reactions when stealing plates
    AttackChance = 35, -- Chance (0-100) that NPC will attack when stealing their plate
    FleeChance = 40, -- Chance (0-100) that NPC will flee instead of attack
    CallPoliceChance = 25, -- Remaining chance NPC does nothing
    
    -- Weapons NPCs can have (random selection)
    Weapons = {
        `WEAPON_PISTOL`,
        `WEAPON_COMBATPISTOL`,
        `WEAPON_KNIFE`,
        `WEAPON_BAT`,
        `WEAPON_CROWBAR`
    },
    
    -- Combat settings
    NPCAccuracy = 15, -- NPC shooting accuracy (0-100)
    NPCCombatRange = 50.0, -- Distance NPC will chase player
}

-- Police Notification Settings
Config.PoliceNotification = {
    Enabled = true, -- Enable police notifications
    ChanceOnSteal = 45, -- Chance (0-100) police are notified when stealing plate
    ChanceOnRemove = 25, -- Chance (0-100) police are notified when removing fake plate
    MinPolice = 0, -- Minimum police online for notifications
    PoliceJobs = {'police', 'sheriff', 'state'}, -- Job names that count as police
    
    -- Dispatch settings (choose your dispatch system)
    DispatchSystem = 'ps-dispatch', -- Options: 'ps-dispatch', 'cd_dispatch', 'qs-dispatch', 'core_dispatch', 'custom'
    
    -- Custom dispatch event (if DispatchSystem = 'custom')
    CustomDispatchEvent = 'your:dispatch:event',
}

-- Blip settings for police dispatch
Config.DispatchBlip = {
    Sprite = 229, -- Blip sprite
    Color = 1, -- Blip color
    Scale = 1.0, -- Blip scale
    Duration = 60000, -- How long blip stays (milliseconds)
    Message = 'Suspicious Activity',
    Code = '10-35' -- Police code
}

-- Debug mode
Config.Debug = false