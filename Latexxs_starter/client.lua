if not exports.ox_lib then
    print("Erreur: 'ox_lib' n'est pas disponible.")
    return
end

local BlacklistedPlates = {
    "FUCK", "FUCKER", "FUCKING", "SHIT", "SHITTER", "SHITHEAD", "ASSHOLE", "ASS", "BITCH", "BITCHES",
    "SLUT", "WHOREF", "WHORE", "CUNT", "PRICK", "DICK", "DICKHEAD", "COCK", "PISS", "PISSER", "PUSSY",
    "MOTHERFUCKER", "MOTHERFUCKING", "MOTHERFUKKER", "NIGGA", "NIGGER", "FAG", "FAGGOT", "FAGS", "DYKE",
    "SPIC", "CHINK", "KIKE", "QUEER", "TRANNY", "TERROR",
    "MERDE", "PUTE", "ENCULE", "CON", "CONNARD", "CONNASSE", "SALOP", "SALOPE", "SALOPARD",
    "ENFOIRE", "ENFOIRE", "TARÉ", "TARE", "FERME TA" , "FOUTRE", "VA TE FAIRE", "VA TE FAIRE FOUTRE",
    "NIQUE", "NIQUE TA", "SALAUD", "SALAUD", "CROUD", "GUEULE",
    "BASTARD", "WH0RE", "PR1CK", "B1TCH", "SL7T"
}


local function isPlateBlacklisted(plate)
    if not plate then return false end
    local up = plate:upper()
    for _, bad in ipairs(BlacklistedPlates) do
        if up:find(bad, 1, true) then
            return true
        end
    end
    return false
end

CreateThread(function()
    RequestModel(Config.Ped.model)
    while not HasModelLoaded(Config.Ped.model) do Wait(0) end

    local ped = CreatePed(0, Config.Ped.model,
        Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z - 1.0,
        Config.Ped.coords.w, false, false)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label    = 'Parler à Marvin',
            icon     = 'fa-solid fa-gift',
            onSelect = openMainMenu
        }
    })
end)

function openMainMenu()
    local options = {
        {
            title       = '🎁 Pack de Démarrage',
            description = 'Recevez votre pack de démarrage',
            icon        = 'gift',
            onSelect    = function()
                if exports.ox_lib:progressBar({
                    duration     = 5000,
                    label        = 'Récupération du pack...',
                    useWhileDead = false,
                    canCancel    = true,
                    disable      = { move=true, combat=true, sprint=true },
                    anim         = { scenario = "WORLD_HUMAN_CLIPBOARD" }
                }) then
                    TriggerServerEvent('starter:claimPack')
                end
            end
        },
        {
            title       = '🚗 Louer une voiture',
            description = 'Louez un véhicule',
            icon        = 'car',
            onSelect    = openLocationMenu
        }
    }

    exports.ox_lib:registerContext({
        id      = 'main_menu_starter',
        title   = 'Bienvenue en ville',
        options = options
    })
    exports.ox_lib:showContext('main_menu_starter')
end


function openLocationMenu()
    local options = {
        {
            title       = Config.VehicleSpawn.model .. ' - $' .. Config.VehicleSpawn.price,
            description = 'Choisissez un mode de paiement et une plaque',
            icon        = 'car-side',
            onSelect    = function()
                local input = exports.ox_lib:inputDialog('Location de véhicule', {
                    { 
                        type    = 'select', 
                        label   = 'Méthode de paiement', 
                        options = {
                            { label = 'Cash',  value = 'money' },
                            { label = 'Banque',value = 'bank' }
                        }
                    },
                    { 
                        type    = 'input',  
                        label   = 'Plaque perso (max 8 chars)', 
                        default = '' 
                    }
                })
                if not input or not input[1] then return end

                local rawPlate = tostring(input[2] or "")
                local plate    = rawPlate:upper():gsub("[^A-Z0-9]", ""):sub(1,8)
                if plate == "" then plate = nil end

                local spawn = Config.VehicleSpawn.spawnCoords
                local radius = 3.0

                local vehNearby = GetClosestVehicle(spawn.x, spawn.y, spawn.z, radius, 0, 70)
                if DoesEntityExist(vehNearby) then
                    exports.ox_lib:notify({ type="error", description="Zone de spawn occupée par un autre véhicule." })
                    return
                end

                for _, pid in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(pid)
                    if ped ~= PlayerPedId() then
                        local pCoords = GetEntityCoords(ped)
                        if #(pCoords - vector3(spawn.x, spawn.y, spawn.z)) < radius then
                            exports.ox_lib:notify({ type="error", description="Zone de spawn occupée par un joueur." })
                            return
                        end
                    end
                end

                if exports.ox_lib:progressBar({
                    duration     = 5000,
                    label        = 'Traitement de la location...',
                    useWhileDead = false,
                    canCancel    = true,
                    disable      = { move=true, combat=true, sprint=true },
                    anim         = { scenario = "WORLD_HUMAN_CLIPBOARD" }
                }) then
                    
                    TriggerServerEvent('starter:rentVehicle', input[1], plate)
                end
            end
        }
    }

    exports.ox_lib:registerContext({
        id      = 'menu_location',
        title   = 'Location de véhicule',
        options = options
    })
    exports.ox_lib:showContext('menu_location')
end

RegisterNetEvent('starter:spawnVehicle')
AddEventHandler('starter:spawnVehicle', function(plate)
    local spawn = Config.VehicleSpawn.spawnCoords

    RequestModel(Config.VehicleSpawn.model)
    while not HasModelLoaded(Config.VehicleSpawn.model) do Wait(0) end


    local veh = CreateVehicle(
        Config.VehicleSpawn.model,
        spawn.x, spawn.y, spawn.z, spawn.w,
        true, 
        false  
    )

    local netId = VehToNet(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    NetworkRequestControlOfEntity(veh)
    while not NetworkHasControlOfEntity(veh) do
        Wait(0)
    end

    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleNumberPlateText(veh, plate or "LOCATION")
    Wait(500)
    SetVehicleFuelLevel(veh, 100.0)

end)
