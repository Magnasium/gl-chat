local QBCore = exports['qb-core']:GetCoreObject()
local chatOpened = false

-- Chat açıkken kontrolleri engelleme
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if chatOpened then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- Bas-konuş (N) tuşuna izin ver
        end
    end
end)

function ToggleChat(status)
    chatOpened = status
    SetNuiFocus(status, status)
    if status then
        local suggestions = {}
        local commandList = {}

        -- QB-Core komutlarını farklı tablolardan kontrol et
        if QBCore.Commands and next(QBCore.Commands) then
            commandList = QBCore.Commands
        elseif QBCore.Shared and QBCore.Shared.Commands then
            commandList = QBCore.Shared.Commands
        end

        for cmd, info in pairs(commandList) do
            if type(info) == "table" then
                table.insert(suggestions, {name = cmd, help = info.help or "Komut"})
            end
        end

        SendNUIMessage({type = 'UPDATE_SUGGESTIONS', suggestions = suggestions})
        SendNUIMessage({type = 'ON_OPEN'})
    else
        SendNUIMessage({type = 'ON_CLOSE'})
    end
end

-- Tuş Dinleme (T ve ESC)
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 245) and not chatOpened and not IsPauseMenuActive() then
            ToggleChat(true)
        end
    end
end)

RegisterNUICallback('chatResult', function(data, cb)
    if data.message ~= "" then
        local msg = data.message
        if msg:sub(1, 1) == "/" then 
            ExecuteCommand(msg:sub(2)) 
        else 
            TriggerServerEvent('_chat:messageEntered', GetPlayerName(PlayerId()), {255, 255, 255}, msg)
        end
    end
    ToggleChat(false)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    ToggleChat(false)
    cb('ok')
end)

-- MESAJ FİLTRELEME BURADA
RegisterNetEvent('chat:addMessage', function(data)
    local messageSender = data.args and data.args[1] or ""
    local messageContent = data.args and data.args[2] or ""

    -- Filtre: Ambulancejob status check veya istemediğin kelimeler
    local filterWords = {"status check", "durum kontrol", "yara kontrol"}
    local shouldBlock = false

    for _, word in ipairs(filterWords) do
        if string.find(messageContent:lower(), word) or string.find(messageSender:lower(), word) then
            shouldBlock = true
            break
        end
    end

    if not shouldBlock then
        SendNUIMessage({type = 'ON_MESSAGE', message = data})
    end
end)