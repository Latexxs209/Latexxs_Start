ESX = exports['es_extended']:getSharedObject()

RegisterServerEvent('starter:claimPack')
AddEventHandler('starter:claimPack', function()
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    MySQL.scalar('SELECT claimed FROM starter_claims WHERE identifier = ?', {xPlayer.identifier}, function(claimed)
        if claimed then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error',   description = 'Tu as déjà réclamé ton pack !' })
        else
            xPlayer.addAccountMoney('money', Config.StarterPack.money)
            for _, item in ipairs(Config.StarterPack.items) do
                xPlayer.addInventoryItem(item.name, item.count)
            end
            MySQL.insert('INSERT INTO starter_claims (identifier, claimed) VALUES (?, ?)', {xPlayer.identifier, true})
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Starter pack réclamé !' })
        end
    end)
end)

RegisterServerEvent('starter:rentVehicle')
AddEventHandler('starter:rentVehicle', function(method, plate)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local price = Config.VehicleSpawn.price

    if method == 'money' then
        if xPlayer.getMoney() >= price then
            xPlayer.removeMoney(price)
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = "Pas assez d'argent." })
            return
        end
    elseif method == 'bank' then
        if xPlayer.getAccount('bank').money >= price then
            xPlayer.removeAccountMoney('bank', price)
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = "Pas assez d'argent sur le compte." })
            return
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Méthode de paiement invalide.' })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Véhicule loué !' })
    TriggerClientEvent('starter:spawnVehicle', src, plate)
end)
