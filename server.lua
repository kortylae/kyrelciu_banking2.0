ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local function sendToDiscord(title, message, color)
    local embed = {{
        ["color"] = color,
        ["title"] = title,
        ["description"] = message,
        ["footer"] = { ["text"] = os.date("%Y-%m-%d %H:%M:%S") }
    }}
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
        username = "Kyrelciu Banking",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function generateUniqueAccountNumber(callback)
    local function tryGenerate()
        local number = tostring(math.random(10000000, 99999999))
        exports.oxmysql:execute('SELECT COUNT(*) as count FROM users WHERE bank_account_number = ?', {number}, function(result)
            if result[1] and result[1].count == 0 then
                callback(number)
            else
                tryGenerate() 
            end
        end)
    end
    tryGenerate()
end

function addTransaction(identifier, type, amount, targetAccount, fromAccount, title)
    exports.oxmysql:execute(
        'INSERT INTO banking_transactions (identifier, type, amount, target_account, from_account, title, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
        {identifier, type, amount, targetAccount, fromAccount, title or ''}
    )
end

AddEventHandler('esx:playerLoaded', function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    exports.oxmysql:execute('SELECT bank_account_number FROM users WHERE identifier = ?', {xPlayer.identifier}, function(result)
        if result[1] and result[1].bank_account_number then
            xPlayer.set('bank_account_number', result[1].bank_account_number)
        else
            generateUniqueAccountNumber(function(accountNumber)
                xPlayer.set('bank_account_number', accountNumber)
                exports.oxmysql:execute('UPDATE users SET bank_account_number = ? WHERE identifier = ?', {accountNumber, xPlayer.identifier})
            end)
        end
    end)
end)

local function ensureAccount(xPlayer, cb)
    exports.oxmysql:execute('SELECT bank_account_number FROM users WHERE identifier=?', {xPlayer.identifier}, function(result)
        local accountNumber
        if result[1] and result[1].bank_account_number then
            accountNumber = result[1].bank_account_number
        else
            accountNumber = generateAccountNumber()
            exports.oxmysql:execute('UPDATE users SET bank_account_number=? WHERE identifier=?', {accountNumber, xPlayer.identifier})
        end
        cb(accountNumber)
    end)
end


ESX.RegisterServerCallback('kyrelciu_banking:getAccountData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    ensureAccount(xPlayer, function(accountNumber)
        local balance = xPlayer.getAccount('bank').money
        cb({
            name = xPlayer.getName(),
            account_number = accountNumber,
            balance = balance
        })
    end)
end)


ESX.RegisterServerCallback('kyrelciu_banking:getTransactions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    exports.oxmysql:execute(
        'SELECT * FROM bank_transactions WHERE identifier = ? ORDER BY created_at DESC LIMIT 50',
        {xPlayer.identifier},
        function(transactions)
            if transactions then
                for i=1, #transactions do
                    transactions[i].amount = math.floor(transactions[i].amount)
                end
            end
            cb(transactions or {})
        end
    )
end)


RegisterServerEvent('kyrelciu_banking:deposit')
AddEventHandler('kyrelciu_banking:deposit', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    amount = math.floor(tonumber(amount) or 0)
    local cash = xPlayer.getMoney()

    if amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, '❌ Nieprawidłowa kwota.')
        sendToDiscord("Błąd wpłaty", "Gracz "..xPlayer.getName().." próbował wpłacić niepoprawną kwotę: $"..amount, 15158332)
        return
    end

    if amount > cash then
        TriggerClientEvent('esx:showNotification', source, '❌ Nie masz tyle gotówki.')
        sendToDiscord("Błąd wpłaty", "Gracz "..xPlayer.getName().." próbował wpłacić $"..amount.." ale nie miał gotówki.", 15158332)
        return
    end

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', amount)

    addTransaction(xPlayer.identifier, "deposit", amount, "bank", "cash", "Wpłata")
    TriggerClientEvent('kyrelciu_banking:balanceUpdated', source, xPlayer.getAccount('bank').money)
    TriggerClientEvent('esx:showNotification', source, '✅ Wpłaciłeś $'..amount..' do banku.')
    sendToDiscord("💰 Wpłata", "Gracz **"..xPlayer.getName().."** wpłacił **$"..amount.."** do banku.", 3066993)
end)

RegisterServerEvent('kyrelciu_banking:withdraw')
AddEventHandler('kyrelciu_banking:withdraw', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    amount = math.floor(tonumber(amount) or 0)
    local bank = xPlayer.getAccount('bank').money

    if amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, '❌ Nieprawidłowa kwota.')
        sendToDiscord("Błąd wypłaty", "Gracz "..xPlayer.getName().." próbował wypłacić niepoprawną kwotę: $"..amount, 15158332)
        return
    end

    if amount > bank then
        TriggerClientEvent('esx:showNotification', source, '❌ Nie masz tyle środków na koncie.')
        sendToDiscord("Błąd wypłaty", "Gracz "..xPlayer.getName().." próbował wypłacić $"..amount.." ale nie miał tyle środków.", 15158332)
        return
    end

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)
    addTransaction(xPlayer.identifier, "withdraw", amount, "cash", "bank", "Wypłata")
    TriggerClientEvent('kyrelciu_banking:balanceUpdated', source, xPlayer.getAccount('bank').money)
    TriggerClientEvent('esx:showNotification', source, '✅ Wypłaciłeś $'..amount..' z banku.')
    sendToDiscord("🏧 Wypłata", "Gracz **"..xPlayer.getName().."** wypłacił **$"..amount.."** z banku.", 15158332)
end)

local function addTransaction(identifier, ttype, amount, targetAccount, fromAccount, title)
    exports.oxmysql:execute(
        'INSERT INTO banking_transactions (identifier, type, amount, target_account, from_account, title, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
        {identifier, ttype, amount, targetAccount, fromAccount, title or ''}
    )
end

RegisterServerEvent('kyrelciu_banking:transfer')
AddEventHandler('kyrelciu_banking:transfer', function(targetAccount, amount, title)
    local sourcePlayer = ESX.GetPlayerFromId(source)
    amount = math.floor(tonumber(amount) or 0)
    local senderName = sourcePlayer.getName()

    if amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, '❌ Nieprawidłowa kwota.')
        sendToDiscord("Błąd przelewu", senderName.." próbował wykonać przelew niepoprawną kwotą: $"..amount, 15158332)
        return
    end

    if sourcePlayer.getAccount('bank').money < amount then
        TriggerClientEvent('esx:showNotification', source, '❌ Nie masz tyle środków.')
        sendToDiscord("Błąd przelewu", senderName.." próbował wysłać $"..amount.." ale nie miał tyle środków.", 15158332)
        return
    end

    exports.oxmysql:execute('SELECT identifier FROM users WHERE bank_account_number = ?', {targetAccount}, function(result)
        if not result[1] then
            TriggerClientEvent('esx:showNotification', source, '❌ Nie znaleziono konta odbiorcy.')
            sendToDiscord("Błąd przelewu", senderName.." próbował wysłać $"..amount.." na nieistniejący numer konta: "..targetAccount, 15158332)
            return
        end

        local targetIdentifier = result[1].identifier
        local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
        local senderAccountNumber = sourcePlayer.get('bank_account_number')
        sourcePlayer.removeAccountMoney('bank', amount)
        if targetPlayer then
            targetPlayer.addAccountMoney('bank', amount)
            TriggerClientEvent('esx:showNotification', targetPlayer.source, '📥 Otrzymałeś przelew: $'..amount)
            TriggerClientEvent('kyrelciu_banking:balanceUpdated', targetPlayer.source, targetPlayer.getAccount('bank').money)
        else
            exports.oxmysql:execute('UPDATE users SET bank = bank + ? WHERE identifier = ?', {amount, targetIdentifier})
        end

        addTransaction(sourcePlayer.identifier, "transfer_out", amount, targetAccount, senderAccountNumber, title)
        addTransaction(targetIdentifier, "transfer_in", amount, targetAccount, senderAccountNumber, title)

        TriggerClientEvent('esx:showNotification', source, '✅ Przelew wykonany.')
        TriggerClientEvent('kyrelciu_banking:balanceUpdated', source, sourcePlayer.getAccount('bank').money)
        sendToDiscord("💸 Przelew", string.format("Gracz **%s** wysłał **$%s** do konta **%s**. Tytuł: %s", senderName, amount, targetAccount, title or "Brak tytułu"), 3447003)
    end)
end)

ESX.RegisterServerCallback('kyrelciu_banking:getTransactions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    exports.oxmysql:execute(
        'SELECT * FROM banking_transactions WHERE identifier = ? ORDER BY created_at DESC LIMIT 50',
        {xPlayer.identifier},
        function(transactions)
            cb(transactions or {})
        end
    )
end)

ESX.RegisterServerCallback('kyrelciu_banking:getBalance', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(0) return end

    local balance = xPlayer.getAccount('bank').money
    cb(balance)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        print('[kyrelciu_banking] System bankowy dziala poprawnie.')
    end
end)

