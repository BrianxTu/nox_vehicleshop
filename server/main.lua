Storage = {
    displays = {},
    lists = {}
}

local function setup()
    for id, dealer in pairs(Dealers) do
        Storage.lists[id] = Storage.lists[id] or {}
        local classes = dealer.classes
        local vehicles = Ox.GetVehicleData()

        for _, class in ipairs(classes) do
            Storage.lists[id][class] = Storage.lists[id][class] or {}

            for tag, data in pairs(vehicles) do
                if class == data.class and not data.weapons then
                    local newData = data
                    newData.spawn = tag
                    table.insert(Storage.lists[id][class], newData)
                end
            end
        end

        if dealer.displays then
            Storage.displays[id] = Storage.displays[id] or {}

            for _, display in ipairs(dealer.displays) do
                local coords = display.coords
                local model = display.vehicle

                if not model then
                    local validClasses = {}
                    for class in pairs(Storage.lists[id]) do
                        table.insert(validClasses, class)
                    end

                    if #validClasses > 0 then
                        local chosenClass = validClasses[math.random(1, #validClasses)]
                        local vehicleList = Storage.lists[id][chosenClass]

                        if #vehicleList > 0 then
                            local chosenVehicle = vehicleList[math.random(1, #vehicleList)]
                            model = chosenVehicle.spawn
                        end
                    end
                end

                table.insert(Storage.displays[id], {vehicle = model, coords = coords})
            end
        end
    end
end

lib.callback.register(
    "ox_vehicleshop:getDisplays",
    function(source, dealer)
        return Storage.displays[dealer] or nil
    end
)

RegisterNetEvent(
    "ox_vehicleshop:modifyDisplays",
    function(data)
        print(source, json.encode(data))
    end
)

RegisterNetEvent(
    "ox_vehicleshop:openShop",
    function(data)
        local src = source
        local dealerId = data.meta.dealer
        local npcId = data.meta.npc
        local dealer = Dealers[dealerId]

        if dealer then
            local classes = dealer.classes
            local npc = dealer.npcs[npcId]
            if npc and classes and next(classes) then
                local player = GetPlayerPed(src)
                local pCoords = GetEntityCoords(player)
                if #(vector3(npc.coords.x, npc.coords.y, npc.coords.z) - pCoords) < 2.5 then
                    if Storage.lists[dealerId] then
                        TriggerClientEvent("ox_vehicleshop:openShopMenu", src, dealerId, Storage.lists[dealerId])
                    end
                end
            end
        end
    end
)

RegisterNetEvent(
    "ox_vehicleshop:openBoss",
    function(data)
        print(source, json.encode(data))
    end
)

AddEventHandler(
    "onResourceStart",
    function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
            return
        end
        setup()
    end
)
