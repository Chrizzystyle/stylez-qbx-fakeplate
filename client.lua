local QBX = exports.qbx_core
local isApplyingPlate = false
local isRemovingPlate = false
local isStealingPlate = false

-- Notification function
local function Notify(msg, type)
    if Config.UseOxLib then
        lib.notify({
            title = 'Fake Plates',
            description = msg,
            type = type or 'info'
        })
    else
        lib.notify({
            title = 'Fake Plates',
            description = msg,
            type = type or 'info'
        })
    end
end

-- Progress bar function with vehicle check
local function ProgressBarWithVehicleCheck(time, label, vehicle)
    if lib.progressBar then
        local progressActive = true
        local progressSuccess = false
        
        -- Start the progress bar
        CreateThread(function()
            progressSuccess = lib.progressBar({
                duration = time,
                label = label,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
                anim = {
                    dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                    clip = 'machinic_loop_mechandplayer'
                }
            })
            progressActive = false
        end)
        
        -- Check if vehicle is still nearby
        if vehicle then
            CreateThread(function()
                local startCoords = GetEntityCoords(vehicle)
                while progressActive do
                    Wait(500)
                    if not DoesEntityExist(vehicle) then
                        -- Vehicle despawned
                        lib.cancelProgress()
                        progressActive = false
                        progressSuccess = false
                        break
                    end
                    
                    local currentCoords = GetEntityCoords(vehicle)
                    local distance = #(startCoords - currentCoords)
                    
                    if distance > 5.0 then
                        -- Vehicle moved too far
                        lib.cancelProgress()
                        progressActive = false
                        progressSuccess = false
                        Notify('The vehicle moved away!', 'error')
                        break
                    end
                end
            end)
        end
        
        -- Wait for progress to finish
        while progressActive do
            Wait(100)
        end
        
        return progressSuccess
    else
        -- Fallback if ox_lib not available
        local promise = promise.new()
        RequestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
        while not HasAnimDictLoaded('anim@amb@clubhouse@tutorial@bkr_tut_ig3@') do
            Wait(0)
        end
        TaskPlayAnim(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, 8.0, -1, 1, 0, false, false, false)
        
        -- Check vehicle movement for fallback
        local cancelled = false
        if vehicle then
            CreateThread(function()
                local startCoords = GetEntityCoords(vehicle)
                local elapsed = 0
                while elapsed < time do
                    Wait(500)
                    elapsed = elapsed + 500
                    
                    if not DoesEntityExist(vehicle) then
                        cancelled = true
                        break
                    end
                    
                    local currentCoords = GetEntityCoords(vehicle)
                    local distance = #(startCoords - currentCoords)
                    
                    if distance > 5.0 then
                        cancelled = true
                        Notify('The vehicle moved away!', 'error')
                        break
                    end
                end
            end)
        end
        
        SetTimeout(time, function()
            ClearPedTasks(cache.ped)
            if cancelled then
                promise:resolve(false)
            else
                promise:resolve(true)
            end
        end)
        
        return Citizen.Await(promise)
    end
end

-- Get closest vehicle
local function GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = 3.0
    
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end
    
    return closestVehicle
end

-- Get driver of vehicle
local function GetVehicleDriver(vehicle)
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            return ped
        end
    end
    return nil
end

-- Make NPC react to plate theft
local function HandleNPCReaction(vehicle, ped)
    if not Config.NPCReaction.Enabled then return end
    
    local driver = GetVehicleDriver(vehicle)
    if not driver or not DoesEntityExist(driver) or IsPedAPlayer(driver) then return end
    
    local roll = math.random(1, 100)
    
    if roll <= Config.NPCReaction.AttackChance then
        -- NPC attacks player
        TaskLeaveVehicle(driver, vehicle, 256)
        Wait(2000)
        
        -- Give NPC a weapon
        local weaponHash = Config.NPCReaction.Weapons[math.random(1, #Config.NPCReaction.Weapons)]
        GiveWeaponToPed(driver, weaponHash, 250, false, true)
        
        -- Set combat attributes
        SetPedCombatAttributes(driver, 46, true)
        SetPedCombatAttributes(driver, 5, true)
        SetPedCombatRange(driver, 2)
        SetPedAccuracy(driver, Config.NPCReaction.NPCAccuracy)
        SetPedFleeAttributes(driver, 0, false)
        
        -- Attack player
        TaskCombatPed(driver, ped, 0, 16)
        
        Notify('The driver is attacking you!', 'error')
        
    elseif roll <= (Config.NPCReaction.AttackChance + Config.NPCReaction.FleeChance) then
        -- NPC flees
        TaskLeaveVehicle(driver, vehicle, 256)
        Wait(1000)
        TaskSmartFleePed(driver, ped, 100.0, -1, false, false)
        
        Notify('The driver fled in panic!', 'info')
    end
    
    -- Remaining chance: NPC does nothing/is too scared
end

-- Apply fake plate
RegisterNetEvent('fakeplate:client:applyPlate', function()
    if isApplyingPlate then return end
    
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords)
        
        if not veh then
            Notify('No vehicle nearby', 'error')
            return
        end
    end
    
    local plate = GetVehicleNumberPlateText(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    
    isApplyingPlate = true
    
    -- Check if already has fake plate
    lib.callback('fakeplate:server:hasActiveFakePlate', false, function(hasPlate)
        if hasPlate then
            Notify('This vehicle already has a fake plate', 'error')
            isApplyingPlate = false
            return
        end
        
        -- Animation
        TaskTurnPedToFaceEntity(ped, veh, 1000)
        Wait(1000)
        
        local success = ProgressBarWithVehicleCheck(Config.ApplyTime, 'Applying fake plate...', veh)
        
        if success then
            TriggerServerEvent('fakeplate:server:applyPlate', netId, plate)
        else
            Notify('Cancelled', 'error')
        end
        
        isApplyingPlate = false
    end, netId)
end)

-- Remove fake plate
RegisterNetEvent('fakeplate:client:removePlate', function()
    if isRemovingPlate then return end
    
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords)
        
        if not veh then
            Notify('No vehicle nearby', 'error')
            return
        end
    end
    
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local coords = GetEntityCoords(ped)
    
    isRemovingPlate = true
    
    -- Check if has fake plate
    lib.callback('fakeplate:server:hasActiveFakePlate', false, function(hasPlate)
        if not hasPlate then
            Notify('This vehicle does not have a fake plate', 'error')
            isRemovingPlate = false
            return
        end
        
        -- Animation
        TaskTurnPedToFaceEntity(ped, veh, 1000)
        Wait(1000)
        
        -- Check for police notification during progress
        TriggerServerEvent('fakeplate:server:checkPoliceNotify', coords, 'remove')
        
        local success = ProgressBarWithVehicleCheck(Config.RemoveTime, 'Removing fake plate...', veh)
        
        if success then
            TriggerServerEvent('fakeplate:server:removePlate', netId)
        else
            Notify('Cancelled', 'error')
        end
        
        isRemovingPlate = false
    end, netId)
end)

-- Steal plate from NPC vehicle
RegisterNetEvent('fakeplate:client:stealPlate', function()
    if isStealingPlate then return end
    
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords)
    
    if not veh then
        Notify('No vehicle nearby', 'error')
        return
    end
    
    -- Check if it's a player vehicle (check if driver is a player)
    local driver = GetPedInVehicleSeat(veh, -1)
    if driver ~= 0 and IsPedAPlayer(driver) then
        Notify('You cannot steal plates from player vehicles', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(veh)
    
    -- Additional check - see if plate exists in player_vehicles database
    lib.callback('fakeplate:server:isPlayerVehicle', false, function(isPlayerVeh)
        if isPlayerVeh then
            Notify('You cannot steal plates from owned vehicles', 'error')
            return
        end
        
        isStealingPlate = true
        
        -- Animation
        TaskTurnPedToFaceEntity(ped, veh, 1000)
        Wait(1000)
        
        -- Check for police notification during progress
        local playerCoords = GetEntityCoords(ped)
        TriggerServerEvent('fakeplate:server:checkPoliceNotify', playerCoords, 'steal')
        
        local success = ProgressBarWithVehicleCheck(Config.StealPlateTime, 'Stealing license plate...', veh)
        
        if success then
            -- Handle NPC reaction
            HandleNPCReaction(veh, ped)
            
            -- Give stolen plate to player
            TriggerServerEvent('fakeplate:server:stealPlate', plate)
        else
            Notify('Cancelled', 'error')
        end
        
        isStealingPlate = false
    end, plate)
end)

-- Update plate visually
RegisterNetEvent('fakeplate:client:updatePlate', function(netId, newPlate)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        SetVehicleNumberPlateText(veh, newPlate)
    end
end)

-- Open remover menu
RegisterNetEvent('fakeplate:client:openRemoverMenu', function()
    lib.registerContext({
        id = 'fakeplate_remover_menu',
        title = 'Plate Removal Tool',
        options = {
            {
                title = 'Remove Fake Plate',
                description = 'Remove a fake plate from a vehicle',
                icon = 'screwdriver-wrench',
                onSelect = function()
                    TriggerEvent('fakeplate:client:removePlate')
                end
            },
            {
                title = 'Steal License Plate',
                description = 'Steal a plate from a nearby NPC vehicle',
                icon = 'hand-holding',
                onSelect = function()
                    TriggerEvent('fakeplate:client:stealPlate')
                end
            }
        }
    })
    
    lib.showContext('fakeplate_remover_menu')
end)

-- Target System Support
if Config.UseTarget then
    CreateThread(function()
        local targetResource = Config.TargetResource
        
        if GetResourceState(targetResource) ~= 'started' then
            return
        end
        
        if targetResource == 'ox_target' then
            exports.ox_target:addGlobalVehicle({
                {
                    name = 'fakeplate_apply',
                    icon = 'fas fa-id-card',
                    label = 'Apply Fake Plate',
                    items = Config.FakePlateItem,
                    onSelect = function(data)
                        TriggerEvent('fakeplate:client:applyPlate')
                    end,
                    canInteract = function(entity, distance, coords, name, bone)
                        return distance < 2.5
                    end
                },
                {
                    name = 'fakeplate_remove',
                    icon = 'fas fa-screwdriver-wrench',
                    label = 'Remove Fake Plate',
                    items = Config.FakePlateRemoverItem,
                    onSelect = function(data)
                        TriggerEvent('fakeplate:client:removePlate')
                    end,
                    canInteract = function(entity, distance, coords, name, bone)
                        return distance < 2.5
                    end
                },
                {
                    name = 'fakeplate_steal',
                    icon = 'fas fa-hand-holding',
                    label = 'Steal License Plate',
                    items = Config.FakePlateRemoverItem,
                    onSelect = function(data)
                        TriggerEvent('fakeplate:client:stealPlate')
                    end,
                    canInteract = function(entity, distance, coords, name, bone)
                        -- Only show on NPC vehicles
                        local driver = GetPedInVehicleSeat(entity, -1)
                        if driver == 0 then return distance < 2.5 end
                        return not IsPedAPlayer(driver) and distance < 2.5
                    end
                }
            })
        elseif targetResource == 'qb-target' then
            exports['qb-target']:AddGlobalVehicle({
                options = {
                    {
                        icon = 'fas fa-id-card',
                        label = 'Apply Fake Plate',
                        item = Config.FakePlateItem,
                        action = function(entity)
                            TriggerEvent('fakeplate:client:applyPlate')
                        end,
                        canInteract = function(entity, distance)
                            return distance < 2.5
                        end
                    },
                    {
                        icon = 'fas fa-screwdriver-wrench',
                        label = 'Remove Fake Plate',
                        item = Config.FakePlateRemoverItem,
                        action = function(entity)
                            TriggerEvent('fakeplate:client:removePlate')
                        end,
                        canInteract = function(entity, distance)
                            return distance < 2.5
                        end
                    },
                    {
                        icon = 'fas fa-hand-holding',
                        label = 'Steal License Plate',
                        item = Config.FakePlateRemoverItem,
                        action = function(entity)
                            TriggerEvent('fakeplate:client:stealPlate')
                        end,
                        canInteract = function(entity, distance)
                            local driver = GetPedInVehicleSeat(entity, -1)
                            if driver == 0 then return distance < 2.5 end
                            return not IsPedAPlayer(driver) and distance < 2.5
                        end
                    }
                },
                distance = 2.5
            })
        end
    end)
end