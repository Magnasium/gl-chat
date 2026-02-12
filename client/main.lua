local QBCore = exports['qb-core']:GetCoreObject()
local chatOpened = false

Citizen.CreateThread(function()
    while true do
        Wait(0)
        SetTextChatEnabled(false)
        if chatOpened then
            DisableAllControlActions(0)
        end
    end
end)

function ToggleChat(status)
    chatOpened = status
    SetNuiFocus(status, status)
    if status then
        -- HATA FIX: Komut listesini güvenli şekilde çekiyoruz
        local suggestions = {}
        local commandList = {}

        -- QB-Core versiyonuna göre farklı yerlerde olabilir, ikisini de kontrol et
        if QBCore.Commands and next(QBCore.Commands) then
            commandList = QBCore.Commands
        elseif QBCore.Shared and QBCore.Shared.Commands then
            commandList = QBCore.Shared.Commands
        end

        for cmd, info in pairs(commandList) do
            if type(info) == "table" then
                table.insert(suggestions, {name = cmd, help = info.help or ""})
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
        if IsControlJustPressed(0, 245) or IsDisabledControlJustPressed(0, 245) then
            if not chatOpened and not IsPauseMenuActive() then
                ToggleChat(true)
            end
        end
        if chatOpened and (IsControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 322)) then
            ToggleChat(false)
        end
    end
end)

-- Callbackler ve Eventler aynı kalıyor
RegisterNUICallback('chatResult', function(data, cb)
    if data.message ~= "" then
        local msg = data.message
        if msg:sub(1, 1) == "/" then ExecuteCommand(msg:sub(2)) else ExecuteCommand(msg) end
    end
    ToggleChat(false)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    ToggleChat(false)
    cb('ok')
end)

RegisterNetEvent('chat:addMessage', function(data)
    SendNUIMessage({type = 'ON_MESSAGE', message = data})
end)