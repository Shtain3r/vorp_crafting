-- Configurable timers in seconds
local campfireDurationSeconds = 60 -- Time before the campfire changes to "no fire" (in seconds)
local noFireDurationSeconds = 30 -- Time before the "no fire" campfire disappears (in seconds)

-- Convert durations to milliseconds
local campfireDuration = campfireDurationSeconds * 1000
local noFireDuration = noFireDurationSeconds * 1000

local campfire = 0
local progressbar = exports.vorp_progressbar:initiate()

local function placeCampfire()
    if campfire ~= 0 then
        SetEntityAsMissionEntity(campfire, false, false)
        DeleteObject(campfire)
        campfire = 0
    end

    local playerPed = PlayerPedId()
    Animations.playAnimation(playerPed, "campfire")

    progressbar.start(_U('PlaceFire'), 20000, function()
        Animations.endAnimation("campfire")
        Animations.endAnimations()
        local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 2.0, -1.55))
        RequestModel(Config.PlaceableCampfire, false)
        repeat Wait(0) until HasModelLoaded(Config.PlaceableCampfire)
        local prop = CreateObject(GetHashKey(Config.PlaceableCampfire), x, y, z, true, false, false, false, false)
        repeat Wait(0) until DoesEntityExist(prop)
        SetEntityHeading(prop, GetEntityHeading(PlayerPedId()))
        PlaceObjectOnGroundProperly(prop, false)
        campfire = prop

        -- Start timer to replace campfire with "no fire" version
        Citizen.CreateThread(function()
            Wait(campfireDuration)
            if DoesEntityExist(campfire) then
                local campfireCoords = GetEntityCoords(campfire)
                local campfireHeading = GetEntityHeading(campfire)
                SetEntityAsMissionEntity(campfire, false, false)
                DeleteObject(campfire)

                -- Spawn the "no fire" campfire prop
                RequestModel("p_campfire03x_nofire", false)
                repeat Wait(0) until HasModelLoaded("p_campfire03x_nofire")
                local noFireProp = CreateObject(GetHashKey("p_campfire03x_nofire"), campfireCoords.x, campfireCoords.y, campfireCoords.z, true, false, false, false, false)
                SetEntityHeading(noFireProp, campfireHeading)
                PlaceObjectOnGroundProperly(noFireProp, false)
                campfire = noFireProp

                -- Notification for the player
                TriggerEvent("vorp:TipRight", _U('CampfireChanged'), 5000)

                -- Start timer to remove the "no fire" prop
                Citizen.CreateThread(function()
                    Wait(noFireDuration)
                    if DoesEntityExist(campfire) then
                        SetEntityAsMissionEntity(campfire, false, false)
                        DeleteObject(campfire)
                        campfire = 0
                        TriggerEvent("vorp:TipRight", _U('CampfireRemoved'), 5000)
                    end
                end)
            end
        end)
    end)
end

RegisterNetEvent('vorp:campfire')
AddEventHandler('vorp:campfire', function()
    placeCampfire()
end)

if Config.Commands.campfire == true then
    RegisterCommand("campfire", function()
        placeCampfire()
    end, false)
end

if Config.Commands.extinguish == true then
    RegisterCommand('extinguish', function()
        if campfire ~= 0 then
            SetEntityAsMissionEntity(campfire, false, false)
            TaskStartScenarioInPlaceHash(PlayerPedId(), GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), 7000, true, 0, 0, false)
            TriggerEvent("vorp:TipRight", _U('PutOutFire'), 7000)
            Wait(7000)
            ClearPedTasksImmediately(PlayerPedId())
            DeleteObject(campfire)
            campfire = 0
        end
    end, false)
end
