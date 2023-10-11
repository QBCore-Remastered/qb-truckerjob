local JobsDone = 0
local LocationsDone = {}
local CurrentLocation = nil
local CurrentBlip = nil
local hasBox = false
local isWorking = false
local currentCount = 0
local CurrentPlate = nil
local selectedVeh = nil
local TruckVehBlip = nil
local TruckerBlip = nil
local Delivering = false
local showMarker = false
local markerLocation
local returningToStation = false

-- Functions

local function returnToStation()
    SetBlipRoute(TruckVehBlip, true)
    returningToStation = true
end

local function hasDoneLocation(locationId)
    if LocationsDone and table.type(LocationsDone) ~= "empty" then
        for _, v in pairs(LocationsDone) do
            if v == locationId then
                return true
            end
        end
    end
    return false
end

local function getNextLocation()
    local current = 1
    while hasDoneLocation(current) do
        current = math.random(#Config.Locations['stores'])
    end

    return current
end

local function isTruckerVehicle(vehicle)
    for k in pairs(Config.Vehicles) do
        if GetEntityModel(vehicle) == k then
            return true
        end
    end
    return false
end

local function RemoveTruckerBlips()
    ClearAllBlipRoutes()
    if TruckVehBlip then
        RemoveBlip(TruckVehBlip)
        TruckVehBlip = nil
    end

    if TruckerBlip then
        RemoveBlip(TruckerBlip)
        TruckerBlip = nil
    end

    if CurrentBlip then
        RemoveBlip(CurrentBlip)
        CurrentBlip = nil
    end
end

local function OpenMenuGarage()
    local truckMenu = {}
    for k in pairs(Config.Vehicles) do
        truckMenu[#truckMenu + 1] = {
            title = Config.Vehicles[k],
            event = "qbx_truckerjob:client:TakeOutVehicle",
            args = {
                vehicle = k
            }
        }
    end
    lib.registerContext({
        id = 'trucker_veh_menu',
        title = Lang:t("menu.header"),
        options = truckMenu
    })
    lib.showContext('trucker_veh_menu')
end

local function SetDelivering(active)
    if QBX.PlayerData.job.name ~= 'trucker' then return end
    Delivering = active
end

local function ShowMarker(active)
    if QBX.PlayerData.job.name ~= 'trucker' then return end
    showMarker = active
end

local function CreateZone(type, number)
    local coords
    local size
    local rotation
    local boxName
    local icon
    local debug

    for k, v in pairs(Config.Locations) do
        if k == type then
            if type == 'stores' then
                coords = v[number].coords
                size = v[number].size
                rotation = v[number].rotation
                boxName = v[number].label
                debug = v[number].debug
            else
                coords = v.coords
                size = v.size
                rotation = v.rotation
                boxName = v.label
                icon = v.icon
                debug = v.debug
            end
        end
    end
    if Config.UseTarget and type == 'main' then
        exports.ox_target:addBoxZone({
            coords = coords,
            size = size,
            rotation = rotation,
            debug = debug,
            options = {
                {
                    name = boxName,
                    event = 'qbx_truckerjob:client:PaySlip',
                    icon = icon,
                    label = boxName,
                    distance = 2,
                }
            }
        })
    else
        local boxZones = lib.zones.box({
            name = boxName,
            coords = coords,
            size = size,
            rotation = rotation,
            debug = debug,
            onEnter = function()
                if type == 'main' then
                    TriggerEvent('qbx_truckerjob:client:PaySlip')
                elseif type == 'vehicle' then
                    TriggerEvent('qbx_truckerjob:client:Vehicle')
                    markerLocation = coords
                    ShowMarker(true)
                elseif type == 'stores' then
                    markerLocation = coords
                    lib.notify({ title = 'Store Reached', description = Lang:t("mission.store_reached"), duration = 5000, type = 'inform' })
                    ShowMarker(true)
                    SetDelivering(true)
                end
            end,
            onExit = function()
                if type == 'vehicle' then
                    ShowMarker(false)
                elseif type == 'stores' then
                    ShowMarker(false)
                    SetDelivering(false)
                end
            end
        })
        if type == 'stores' then
            CurrentLocation.zoneCombo = boxZones
        end
    end
end

local function getNewLocation()
    local location = getNextLocation()
    if location ~= 0 then
        CurrentLocation = {}
        CurrentLocation.id = location
        CurrentLocation.dropcount = math.random(1, 3)
        CurrentLocation.store = Config.Locations['stores'][location].label
        CurrentLocation.x = Config.Locations['stores'][location].coords.x
        CurrentLocation.y = Config.Locations['stores'][location].coords.y
        CurrentLocation.z = Config.Locations['stores'][location].coords.z
        CreateZone('stores', location)

        CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
        SetBlipColour(CurrentBlip, 3)
        SetBlipRoute(CurrentBlip, true)
        SetBlipRouteColour(CurrentBlip, 3)
    else
        lib.notify({ title = 'Payslip Time', description = Lang:t("success.payslip_time"), duration = 5000, type = 'success' })
        if CurrentBlip ~= nil then
            RemoveBlip(CurrentBlip)
            ClearAllBlipRoutes()
            CurrentBlip = nil
        end
    end
end

local function CreateElements()
    TruckVehBlip = AddBlipForCoord(Config.Locations['vehicle'].coords.x, Config.Locations['vehicle'].coords.y, Config.Locations['vehicle'].coords.z)
    SetBlipSprite(TruckVehBlip, 326)
    SetBlipDisplay(TruckVehBlip, 4)
    SetBlipScale(TruckVehBlip, 0.6)
    SetBlipAsShortRange(TruckVehBlip, true)
    SetBlipColour(TruckVehBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.Locations['vehicle'].label)
    EndTextCommandSetBlipName(TruckVehBlip)

    TruckerBlip = AddBlipForCoord(Config.Locations['main'].coords.x, Config.Locations['main'].coords.y, Config.Locations['main'].coords.z)
    SetBlipSprite(TruckerBlip, 479)
    SetBlipDisplay(TruckerBlip, 4)
    SetBlipScale(TruckerBlip, 0.6)
    SetBlipAsShortRange(TruckerBlip, true)
    SetBlipColour(TruckerBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.Locations['main'].label)
    EndTextCommandSetBlipName(TruckerBlip)

    CreateZone('main')
    CreateZone('vehicle')
end

local function BackDoorsOpen(vehicle) -- This is hardcoded for the rumpo currently
    return GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 or GetVehicleDoorAngleRatio(vehicle, 2) > 0.0 and GetVehicleDoorAngleRatio(vehicle, 3) > 0.0
end

local function GetInTrunk()
    if IsPedInAnyVehicle(cache.ped, false) then
        return lib.notify({ title = 'Get Out Vehicle', description = Lang:t("error.get_out_vehicle"), duration = 5000, type = 'error' })
    end
    local pos = GetEntityCoords(cache.ped, true)
    local vehicle = GetVehiclePedIsIn(cache.ped, true)
    if not isTruckerVehicle(vehicle) or CurrentPlate ~= GetPlate(vehicle) then
        return lib.notify({ title = 'Vehicle Not Correct', description = Lang:t("error.vehicle_not_correct"), duration = 5000, type = 'error' })
    end
    if not BackDoorsOpen(vehicle) then
        return lib.notify({ title = 'Backdoors Not Open', description = Lang:t("error.backdoors_not_open"), duration = 5000, type = 'error' })
    end
    local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
    if #(pos - vector3(trunkpos.x, trunkpos.y, trunkpos.z)) > 1.5 then
        return lib.notify({ title = 'Too Far From Trunk', description = Lang:t("error.too_far_from_trunk"), duration = 5000, type = 'error' })
    end
    if isWorking then return end
    isWorking = true
    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            mouse = false,
            combat = true,
            move = true,
        },
        anim = {
            dict = 'anim@gangops@facility@servers@',
            clip = 'hotwire'
        },
    }) then
        isWorking = false
        StopAnimTask(cache.ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
        TriggerEvent('animations:client:EmoteCommandStart', {"box"})
        hasBox = true
    else
        isWorking = false
        StopAnimTask(cache.ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
        lib.notify({ title = 'Cancelled', description = Lang:t("error.cancelled"), duration = 5000, type = 'error' })
    end
end

local function Deliver()
    isWorking = true
    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    Wait(500)
    TriggerEvent('animations:client:EmoteCommandStart', {"bumbin"})
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            mouse = false,
            combat = true,
            move = true,
        },
    }) then
        isWorking = false
        ClearPedTasks(cache.ped)
        hasBox = false
        currentCount += 1
        if currentCount == CurrentLocation.dropcount then
            LocationsDone[#LocationsDone+1] = CurrentLocation.id
            TriggerServerEvent("qb-shops:server:RestockShopItems", CurrentLocation.store)
            Delivering = false
            showMarker = false
            if CurrentBlip ~= nil then
                RemoveBlip(CurrentBlip)
                ClearAllBlipRoutes()
                CurrentBlip = nil
            end
            CurrentLocation.zoneCombo:remove()
            CurrentLocation = nil
            currentCount = 0
            JobsDone += 1
            if JobsDone == Config.MaxDrops then
                lib.notify({ title = 'Return To Station', description = Lang:t("mission.return_to_station"), duration = 5000, type = 'inform' })
                returnToStation()
            else
                TriggerServerEvent("qbx_truckerjob:server:doneJob")
                lib.notify({ title = 'Goto Next Point', description = Lang:t("mission.goto_next_point"), duration = 5000, type = 'inform' })
                getNewLocation()

            end
        elseif currentCount ~= CurrentLocation.dropcount then
            lib.notify({ title = 'Another Box', description = Lang:t("mission.another_box"), duration = 5000, type = 'inform' })
        else
            isWorking = false
            ClearPedTasks(cache.ped)
            lib.notify({ title = 'Cancelled', description = Lang:t("error.cancelled"), duration = 5000, type = 'error' })
        end
    end
end

-- Events

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CurrentLocation = nil
    CurrentBlip = nil
    hasBox = false
    isWorking = false
    JobsDone = 0
    if QBX.PlayerData.job.name ~= 'trucker' then return end
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CurrentLocation = nil
    CurrentBlip = nil
    hasBox = false
    isWorking = false
    JobsDone = 0
    if QBX.PlayerData.job.name ~= 'trucker' then return end
    CreateElements()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveTruckerBlips()
    CurrentLocation = nil
    CurrentBlip = nil
    hasBox = false
    isWorking = false
    JobsDone = 0
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    RemoveTruckerBlips()
    if CurrentLocation and CurrentLocation.zoneCombo then
    CurrentLocation.zoneCombo:remove()
    Delivering = false
    showMarker = false
    
    if QBX.PlayerData.job.name ~= 'trucker' then return end
    CreateElements()
    end
end)

RegisterNetEvent('qbx_truckerjob:client:SpawnVehicle', function()
    local netId, plate = lib.callback.await('qbx_truckerjob:server:spawnVehicle', false, selectedVeh)
    local veh = NetToVeh(netId)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleLivery(veh, 1)
    SetVehicleColours(veh, 122, 122)
    SetVehicleEngineOn(veh, true, true, false)
    CurrentPlate = GetPlate(veh)
    getNewLocation()
end)

RegisterNetEvent('qbx_truckerjob:client:TakeOutVehicle', function(data)
    local vehicleInfo = data.vehicle
    TriggerServerEvent('qbx_truckerjob:server:DoBail', true, vehicleInfo)
    selectedVeh = vehicleInfo
end)

RegisterNetEvent('qbx_truckerjob:client:Vehicle', function()
    if IsPedInAnyVehicle(cache.ped, false) and isTruckerVehicle(GetVehiclePedIsIn(cache.ped, false)) then
        if GetPedInVehicleSeat(GetVehiclePedIsIn(cache.ped, false), -1) == cache.ped then
            if isTruckerVehicle(GetVehiclePedIsIn(cache.ped, false)) then
                DeleteVehicle(GetVehiclePedIsIn(cache.ped, false))
                TriggerServerEvent('qbx_truckerjob:server:DoBail', false)
                if CurrentBlip ~= nil then
                    RemoveBlip(CurrentBlip)
                    ClearAllBlipRoutes()
                    CurrentBlip = nil
                end
                if returningToStation or CurrentLocation then
                    ClearAllBlipRoutes()
                    returningToStation = false
                    lib.notify({ title = 'Job Completed', description = Lang:t("mission.job_completed"), duration = 5000, type = 'success' })
                end
            else
                lib.notify({ title = 'Vehicle Not Correct', description = Lang:t("error.vehicle_not_correct"), duration = 5000, type = 'error' })
            end
        else
            lib.notify({ title = 'No Driver', description = Lang:t("error.no_driver"), duration = 5000, type = 'error' })
        end
    else
        OpenMenuGarage()
    end
end)

RegisterNetEvent('qbx_truckerjob:client:PaySlip', function()
    if JobsDone > 0 then
        TriggerServerEvent("qbx_truckerjob:server:getPaid")
        JobsDone = 0
        if #LocationsDone == #Config.Locations['stores'] then
            LocationsDone = {}
        end
        if CurrentBlip ~= nil then
            RemoveBlip(CurrentBlip)
            ClearAllBlipRoutes()
            CurrentBlip = nil
        end
    else
        lib.notify({ title = 'No Work Done', description = Lang:t("error.no_work_done"), duration = 5000, type = 'error' })
    end
end)

-- Threads

CreateThread(function()
    local sleep
    while true do
        sleep = 1000
        if showMarker then
            DrawMarker(2, markerLocation.x, markerLocation.y, markerLocation.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, 0, true, nil, nil, false)
            sleep = 0
        end
        if Delivering then
            if IsControlJustReleased(0, 38) then
                if not hasBox then
                    GetInTrunk()
                else
                    if #(GetEntityCoords(cache.ped) - markerLocation) < 5 then
                        Deliver()
                    else
                        lib.notify({ title = 'Too Far From Delivery', description = Lang:t("error.too_far_from_delivery"), duration = 5000, type = 'error' })
                    end
                end
            end
            sleep = 0
        end
        Wait(sleep)
    end
end)
