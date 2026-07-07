--[[
  MB_Fahrzeugvermitung — Zentrale Fehlererkennung & Fehlerhistorie
]]
MBErrors = MBErrors or {}

local errorStore = { errors = {} }
local callbacks = {
    isAdmin = function() return false end,
    getPlayerName = function() return 'Unbekannt' end,
}

local function trim(v)
    return tostring(v or ''):match('^%s*(.-)%s*$') or ''
end

local function cfg()
    return Config.ErrorLog or {}
end

local function maxEntries()
    return math.max(10, math.min(500, tonumber(cfg().MaxEntries) or 100))
end

local function storageFile()
    return cfg().StorageFile or 'data/error_log.json'
end

function MBErrors.SetCallbacks(cbs)
    if type(cbs) ~= 'table' then return end
    if type(cbs.isAdmin) == 'function' then callbacks.isAdmin = cbs.isAdmin end
    if type(cbs.getPlayerName) == 'function' then callbacks.getPlayerName = cbs.getPlayerName end
end

function MBErrors.Load()
    if cfg().Enabled == false then return end

    local raw = LoadResourceFile(GetCurrentResourceName(), storageFile())
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' and type(decoded.errors) == 'table' then
            errorStore.errors = decoded.errors
            return
        end
    end

    errorStore.errors = {}
    MBErrors.Save()
end

function MBErrors.Save()
    if cfg().Enabled == false then return end
    SaveResourceFile(GetCurrentResourceName(), storageFile(), json.encode({ errors = errorStore.errors }), -1)
end

function MBErrors.GetLog()
    return errorStore.errors
end

function MBErrors.GetUnreadCount()
    local n = 0
    for _, entry in ipairs(errorStore.errors) do
        if entry and entry.seen ~= true then n = n + 1 end
    end
    return n
end

function MBErrors.MarkAllSeen()
    for _, entry in ipairs(errorStore.errors) do
        entry.seen = true
    end
    MBErrors.Save()
end

function MBErrors.Clear()
    errorStore.errors = {}
    MBErrors.Save()
end

local function broadcastToAdmins(eventName, payload)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and callbacks.isAdmin(src) then
            TriggerClientEvent(eventName, src, payload)
        end
    end
end

function MBErrors.Report(opts)
    if cfg().Enabled == false then return nil end
    opts = type(opts) == 'table' and opts or {}

    local src = tonumber(opts.src)
    local description = trim(opts.description)
    if description == '' then description = 'Unbekannter Fehler' end

    local entry = {
        id = ('err_%s_%s'):format(os.time(), math.random(1000, 9999)),
        time = os.time(),
        timeLabel = os.date('%d.%m. %H:%M'),
        description = description,
        system = trim(opts.system ~= '' and opts.system or 'MB_Fahrzeugvermitung'),
        playerId = src,
        playerName = src and callbacks.getPlayerName(src) or trim(opts.playerName),
        hint = trim(opts.hint),
        code = trim(opts.code),
        severity = opts.severity == 'warning' and 'warning' or 'error',
        seen = false,
    }

    if entry.playerName == '' then entry.playerName = nil end
    if entry.playerId and not entry.playerName then
        entry.playerName = GetPlayerName(entry.playerId) or ('ID %s'):format(entry.playerId)
    end

    table.insert(errorStore.errors, 1, entry)
    while #errorStore.errors > maxEntries() do
        table.remove(errorStore.errors)
    end

    MBErrors.Save()

    print(('[MB_Fahrzeugvermitung][%s] %s — %s%s'):format(
        entry.severity:upper(),
        entry.system,
        entry.description,
        entry.playerName and (' (' .. entry.playerName .. ')') or ''
    ))

    if src and opts.notifyPlayer ~= false then
        local playerMessage = trim(opts.playerMessage)
        if playerMessage == '' then
            playerMessage = 'Es ist ein technisches Problem aufgetreten. Das Team wurde informiert.'
        end
        TriggerClientEvent('MB_Fahrzeugvermitung:systemError', src, {
            message = playerMessage,
            code = entry.code,
        })
    end

    if opts.alertAdmins ~= false then
        broadcastToAdmins('MB_Fahrzeugvermitung:adminErrorAlert', {
            error = entry,
            unread = MBErrors.GetUnreadCount(),
        })
    end

    return entry
end
