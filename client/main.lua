Storage = {
    zones = {},
    blips = {},
    entities = {}
}

local function toboolean(input)
    if input:lower() == "true" then
        return true
    elseif input:lower() == "false" then
        return false
    end
    return nil
end

local function removeZones()
    for id, zone in pairs(Storage.zones) do
        zone:remove()
    end
    Storage.zones = {}
end

local function removeBlips()
    for id, blip in pairs(Storage.blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    Storage.blips = {}
end

local function removeEntities()
    for _, item in pairs(Storage.entities) do
        exports.ox_target:removeLocalEntity(item.entity)
        if DoesEntityExist(item.entity) then
            DeleteEntity(item.entity)
            SetModelAsNoLongerNeeded(item.hash)
        end
    end
    Storage.entities = {}
end

local function setup()
    for id, dealer in pairs(Dealers) do
        if not dealer.zone then --[[skip]]
        end

        local function createEntities()
            if dealer.displays then
                lib.callback(
                    "ox_vehicleshop:getDisplays",
                    false,
                    function(displays)
                        if displays then
                            for tag, display in ipairs(displays) do
                                local model = GetHashKey(display.vehicle)
                                local coords = display.coords

                                ClearAreaOfVehicles(
                                    coords.x,
                                    coords.y,
                                    coords.z,
                                    5.0,
                                    false,
                                    false,
                                    false,
                                    false,
                                    false
                                )

                                if model and coords then
                                    lib.requestModel(model)

                                    -- Spawn the vehicle
                                    local vehicle =
                                        CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    FreezeEntityPosition(vehicle, true)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleNumberPlateText(vehicle, "DEALER")

                                    exports.ox_target:addLocalEntity(
                                        vehicle,
                                        {
                                            {
                                                label = "Change Display Model",
                                                distance = 2.5,
                                                groups = dealer.job or dealer.jobs or nil,
                                                serverEvent = "ox_vehicleshop:modifyDisplays",
                                                meta = {dealer = id, display = tag}
                                            }
                                        }
                                    )

                                    -- Store reference for cleanup
                                    table.insert(
                                        Storage.entities,
                                        {type = "vehicle", entity = vehicle, hash = model}
                                    )
                                end
                            end
                        end
                    end,
                    id
                )
            end

            if dealer.npcs then
                for tag, npc in ipairs(dealer.npcs) do
                    local model = GetHashKey(npc.ped)
                    local coords = npc.coords
                    local anim = npc.scenario

                    if model and coords then
                        lib.requestModel(model)

                        -- Spawn the NPC
                        local ped = CreatePed(19, model, coords.x, coords.y, coords.z, coords.w, false, true)
                        SetEntityInvincible(ped, true)
                        FreezeEntityPosition(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)

                        if anim then
                            TaskStartScenarioInPlace(ped, anim, 0, true)
                        end

                        exports.ox_target:addLocalEntity(
                            ped,
                            {
                                {
                                    label = "View Vehicle Catelog",
                                    distance = 2.5,
                                    serverEvent = "ox_vehicleshop:openShop",
                                    meta = {dealer = id, npc = tag}
                                }
                            }
                        )

                        -- Store reference for cleanup
                        table.insert(Storage.entities, {type = "ped", entity = ped, hash = model})
                    end
                end
            end
        end

        local sphere =
            lib.zones.sphere(
            {
                coords = dealer.zone.coords,
                radius = dealer.zone.radius,
                debug = toboolean(Config.Debug) or false,
                onEnter = createEntities,
                onExit = removeEntities
            }
        )
        Storage.zones[id] = sphere

        if dealer.blip then
            local coords = dealer.zone.coords
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, dealer.blip.sprite)
            SetBlipColour(blip, dealer.blip.color)
            SetBlipScale(blip, dealer.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(dealer.name)
            EndTextCommandSetBlipName(blip)
            Storage.blips[id] = blip
        end
    end
end

local function cleanup()
    removeZones()
    removeBlips()
    removeEntities()
    RemovePreview()
end

AddEventHandler(
    "onResourceStart",
    function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
            return
        end
        setup()
    end
)

AddEventHandler(
    "onResourceStop",
    function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
            return
        end
        cleanup()
    end
)