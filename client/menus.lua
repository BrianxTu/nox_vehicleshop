Storage.menuData = {}
Storage.preview = nil

local classNames = {
    [0] = "Compact Vehicles",
    [1] = "Sedans",
    [2] = "SUVs",
    [3] = "Coupes",
    [4] = "Muscle Vehicles",
    [5] = "Sports Classics",
    [6] = "Sport Vehicles",
    [7] = "Super Vehicles",
    [8] = "Motorcycles",
    [9] = "Off-road Vehicles",
    [10] = "Industrial Vehicles",
    [11] = "Utility Vehicles",
    [12] = "Vans",
    [13] = "Cycles",
    [14] = "Boats",
    [15] = "Helicopters",
    [16] = "Planes",
    [17] = "Service Vehicles",
    [18] = "Emergency Vehicles",
    [19] = "Military Vehicles",
    [20] = "Commercial Vehicles",
    [21] = "Trains",
    [22] = "Open Wheel Vehicles"
}

local function restoreCamera()
    if Storage.camera then
        DestroyCam(Storage.camera, false)
        RenderScriptCams(false, false, 1000, true, false)
        Storage.camera = nil
    end
end

local function connectCamera()
    local dealerId = Storage.menuData.dealer
    if not dealerId or not Dealers[dealerId] or not Dealers[dealerId].preview then
        return
    end

    local spawnCoords = Dealers[dealerId].preview.spawn
    local cameraCoords = Dealers[dealerId].preview.camera
    if not cameraCoords then
        return
    end

    Storage.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(Storage.camera, cameraCoords.x, cameraCoords.y, cameraCoords.z)
    PointCamAtCoord(Storage.camera, spawnCoords.x, spawnCoords.y, spawnCoords.z)

    SetCamActive(Storage.camera, true)
    RenderScriptCams(true, true, 1000, true, false)
end

function RemovePreview()
    if Storage.preview and DoesEntityExist(Storage.preview) then
        DeleteEntity(Storage.preview)
    end
    Storage.preview = nil
    restoreCamera()
end

local function createPreview(vehicle)
    local dealerId = Storage.menuData.dealer
    if not dealerId or not Dealers[dealerId] or not Dealers[dealerId].preview then
        return
    end

    local spawnCoords = Dealers[dealerId].preview.spawn
    if not spawnCoords then
        return
    end

    RemovePreview()

    lib.requestModel(vehicle)

    ClearAreaOfVehicles(spawnCoords.x, spawnCoords.y, spawnCoords.z, 5.0, false, false, false, false, false)

    Storage.preview = CreateVehicle(vehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, false, false)

    SetVehicleDoorsLocked(Storage.preview, 2)
    FreezeEntityPosition(Storage.preview, true)
    SetEntityInvincible(Storage.preview, true)
    SetVehicleNumberPlateText(Storage.preview, "DEALER")

    connectCamera()
end

local function startTestDrive()
    local dealerId = Storage.menuData.dealer
    if not dealerId or not Dealers[dealerId] or not Dealers[dealerId].testdrive then return end

    local testDriveData = Dealers[dealerId].testdrive
    local testDriveCoords = testDriveData.spawn
    local returnZoneCoords = testDriveData.despawn
    local testDriveTime = testDriveData.time or 60

    if not testDriveCoords then return end

    -- Ensure the vehicle is currently previewed
    if not Storage.preview or not DoesEntityExist(Storage.preview) then return end

    restoreCamera()

    -- Save player's last position before test drive
    local playerPed = PlayerPedId()
    local lastPosition = GetEntityCoords(playerPed)
    local lastHeading = GetEntityHeading(playerPed)

    -- Convert the preview vehicle to a networked entity
    local netId = VehToNet(Storage.preview)
    SetNetworkIdExistsOnAllMachines(netId, true)
    NetworkSetNetworkIdDynamic(netId, false)
    SetEntityAsMissionEntity(Storage.preview, true, true)

    -- Move the vehicle to the test drive location
    SetEntityCoords(Storage.preview, testDriveCoords.x, testDriveCoords.y, testDriveCoords.z, false, false, false, true)
    SetEntityHeading(Storage.preview, testDriveCoords.w)

    -- Unlock and unfreeze the vehicle for driving
    SetVehicleDoorsLocked(Storage.preview, 0)
    FreezeEntityPosition(Storage.preview, false)
    SetEntityInvincible(Storage.preview, false)

    -- Put the player inside the vehicle
    TaskWarpPedIntoVehicle(playerPed, Storage.preview, -1)

    -- Notify the player
    lib.notify({ title = "Test Drive Started", description = "You have " .. testDriveTime .. " seconds. Return to the zone!", type = "info" })

    -- Create a zone for returning the vehicle
    local returnZone = lib.zones.sphere({
        coords = returnZoneCoords,
        radius = 5.0,
        debug = true,
        inside = function(self)
            -- If player returns within time, restore the vehicle
            lib.notify({ title = "Test Drive Completed", description = "Vehicle returned successfully.", type = "success" })
            
            DoScreenFadeOut(100)
            Citizen.Wait(200)

            local previewCoords = Dealers[dealerId].preview.spawn
            SetEntityCoords(Storage.preview, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false, true)
            SetEntityHeading(Storage.preview, previewCoords.w)
            FreezeEntityPosition(Storage.preview, true)
            SetVehicleDoorsLocked(Storage.preview, 2)
            SetEntityInvincible(Storage.preview, true)

            -- Restore player to their last position
            SetEntityCoords(playerPed, lastPosition.x, lastPosition.y, lastPosition.z -1, false, false, false, true)
            SetEntityHeading(playerPed, lastHeading)

            -- Load dealership interior
            local interior = GetInteriorAtCoords(lastPosition.x, lastPosition.y, lastPosition.z)
            if interior ~= 0 then
                LoadInterior(interior)
                RefreshInterior(interior)
            end
            Citizen.Wait(200)
            DoScreenFadeIn(100)

            -- Restore camera to preview
            connectCamera()
            lib.showContext("vehicle_details")

            -- Remove zone
            self:remove()
        end
    })

    -- Schedule event trigger if they fail to return
    Citizen.SetTimeout(testDriveTime * 1000, function()
        if returnZone then
            returnZone:remove() -- Remove zone if time expires
        end

        -- If vehicle wasn't returned, trigger an event
        if DoesEntityExist(Storage.preview) then
            TriggerServerEvent("ox_mdt:event", GetVehicleNumberPlateText(Storage.preview))
            lib.notify({ 
                title = "Test Drive Failed!",
                description = "You failed to return the test drive vehicle in time. **Law enforcement has been notified!**",
                type = "error"
            })
        end
    end)
end


local function openVehicleDetails(vehicleData)
    if not vehicleData or not Storage.menuData.dealer then
        lib.showContext("vehicle_list")
        RemovePreview()
        return
    end

    createPreview(vehicleData.spawn)

    lib.registerContext(
        {
            id = "vehicle_details",
            title = vehicleData.name,
            menu = "vehicle_list",
            onBack = function()
                RemovePreview()
            end,
            onExit = function()
                RemovePreview()
            end,
            options = {
                {
                    title = "Details",
                    description = "Hover to view detailed vehicle statistics.",
                    icon = "circle-info",
                    iconColor = "blue",
                    metadata = {
                        {label = "Make", value = vehicleData.make ~= "" and vehicleData.make or "Unknown"},
                        {label = "Class", value = classNames[vehicleData.class]},
                        {label = "Type", value = vehicleData.type},
                        {label = "Price", value = "$" .. tostring(vehicleData.price)},
                        {
                            label = "Speed",
                            value = tostring(vehicleData.speed),
                            progress = vehicleData.speed / 100 * 100,
                            colorScheme = "blue"
                        },
                        {
                            label = "Acceleration",
                            value = tostring(vehicleData.acceleration),
                            progress = vehicleData.acceleration * 100,
                            colorScheme = "green"
                        },
                        {
                            label = "Braking",
                            value = tostring(vehicleData.braking),
                            progress = vehicleData.braking * 100,
                            colorScheme = "red"
                        },
                        {
                            label = "Handling",
                            value = tostring(vehicleData.handling),
                            progress = vehicleData.handling * 100,
                            colorScheme = "yellow"
                        },
                        {
                            label = "Traction",
                            value = tostring(vehicleData.traction),
                            progress = vehicleData.traction * 100,
                            colorScheme = "purple"
                        },
                        {label = "Seats", value = tostring(vehicleData.seats)},
                        {label = "Doors", value = tostring(vehicleData.doors)}
                    },
                    readOnly = true
                },
                {
                    title = "Test Drive",
                    description = "Take this vehicle for a test drive.",
                    icon = "road",
                    iconColor = "green",
                    onSelect = function()
                        startTestDrive()
                    end
                },
                {
                    title = "Purchase",
                    description = "Buy this vehicle.",
                    icon = "shopping-cart",
                    iconColor = "gold",
                    onSelect = function()
                        print("Purchase Selected - Placeholder")
                        RemovePreview()
                    end
                }
            }
        }
    )

    lib.showContext("vehicle_details")
end

local function openVehicleListMenu(class, startIndex)
    if not Storage.menuData or not Storage.menuData[class] then
        return
    end
    local vehicles = Storage.menuData[class]

    startIndex = startIndex or 1
    local vehiclesPerPage = 9
    local endIndex = math.min(startIndex + vehiclesPerPage - 1, #vehicles)

    local options = {}

    for i = startIndex, endIndex do
        local vehicleData = vehicles[i]
        if vehicleData and vehicleData.spawn then
            table.insert(
                options,
                {
                    title = vehicleData.name,
                    arrow = true,
                    icon = "fa-car-side",
                    onSelect = function()
                        openVehicleDetails(vehicleData)
                    end
                }
            )
        end
    end

    if startIndex > 1 then
        table.insert(
            options,
            1,
            {
                title = "Back",
                icon = "fa-arrow-left",
                onSelect = function()
                    openVehicleListMenu(class, math.max(1, startIndex - vehiclesPerPage))
                end
            }
        )
    end

    if endIndex < #vehicles then
        table.insert(
            options,
            {
                title = "Next",
                icon = "fa-arrow-right",
                onSelect = function()
                    openVehicleListMenu(class, startIndex + vehiclesPerPage)
                end
            }
        )
    end

    lib.registerContext(
        {
            id = "vehicle_list",
            title = classNames[class],
            menu = "vehicle_class_menu",
            options = options
        }
    )

    lib.showContext("vehicle_list")
end

local function openVehicleClassMenu()
    if not Storage.menuData then
        return
    end

    local options = {}

    for class, _ in pairs(Storage.menuData) do
        if class == "dealer" then
            goto continue
        end

        local className = classNames[class] or "Unknown Class"

        table.insert(
            options,
            {
                title = "View " .. className,
                arrow = true,
                onSelect = function()
                    openVehicleListMenu(class)
                end
            }
        )

        ::continue::
    end

    lib.registerContext(
        {
            id = "vehicle_class_menu",
            title = "Vehicle Classes",
            options = options
        }
    )

    lib.showContext("vehicle_class_menu")
end

RegisterNetEvent(
    "ox_vehicleshop:openShopMenu",
    function(dealer, data)
        Storage.menuData = data
        Storage.menuData.dealer = dealer
        openVehicleClassMenu()
    end
)
