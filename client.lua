ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    for _, loc in pairs(Config.Banks) do
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, 108)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank")
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, loc in pairs(Config.Banks) do
            local dist = #(coords - vector3(loc.x, loc.y, loc.z))
            if dist < 5.0 then
                sleep = 0
                DrawMarker(2, loc.x, loc.y, loc.z + 0.5, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 18, 255, 0, 150, false, false, false, true)
                if dist < 1.5 then
                    ESX.ShowHelpNotification("Naciśnij ~INPUT_CONTEXT~ aby otworzyć bank")
                    if IsControlJustReleased(0, 38) then
                        OpenBankUI()
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

function OpenBankUI()
    ESX.TriggerServerCallback('kyrelciu_banking:getAccountData', function(account)
        if not account then 
            ESX.ShowNotification('❌ Błąd przy ładowaniu konta') 
            return 
        end
        ESX.TriggerServerCallback('kyrelciu_banking:getTransactions', function(trans)
            SetNuiFocus(true, true)
            SendNUIMessage({type = 'open', account = account, transactions = trans})
        end)
    end)
end

RegisterNetEvent('kyrelciu_banking:balanceUpdated')
AddEventHandler('kyrelciu_banking:balanceUpdated', function(newBalance)
    SendNUIMessage({type = 'balanceUpdate', balance = newBalance})
    ESX.TriggerServerCallback('kyrelciu_banking:getTransactions', function(trans)
        SendNUIMessage({type = 'transactionsUpdate', transactions = trans})
    end)
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('kyrelciu_banking:deposit', tonumber(data.amount))
    cb({ok = true})
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('kyrelciu_banking:withdraw', tonumber(data.amount))
    cb({ok = true})
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('kyrelciu_banking:transfer', data.targetAccount, data.amount, data.title)
    cb({ok = true})
end)