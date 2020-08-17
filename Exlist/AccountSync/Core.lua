local accountSync = Exlist.accountSync
local L = Exlist.L

local PREFIX = "Exlist_AS"

local MSG_TYPE = {
    ping = "PING",
    pingSuccess = "PING_SUCCESS",
    pairRequest = "PAIR_REQUEST",
    pairRequestSuccess = "PAIR_REQUEST_SUCCESS",
    pairRequestFailed = "PAIR_REQUEST_FAILED",
    logout = "LOGOUT"
}

local PROGRESS_TYPE = {
    success = "SUCCESS",
    warning = "WARNING",
    error = "ERROR",
    info = "INFO"
}

local CHAR_STATUS = {ONLINE = "Online", OFFLINE = "Offline"}

local callbacks = {}

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local AceComm = LibStub:GetLibrary("AceComm-3.0")
local configForDeflate = {level = 9}
local configForLS = {errorOnUnserializableType = false}

local function getPairedCharacters()
    return Exlist.ConfigDB.accountSync.pairedCharacters
end

local function getOnlineCharacters()
    local characters = getPairedCharacters()

    local onlineChar = {}
    for char, info in pairs(characters) do
        if (info.status == CHAR_STATUS.ONLINE) then
            table.insert(onlineChar, char)
        end
    end
    return onlineChar
end

local function mergePairedCharacters(accountChars, accountID)
    local paired = Exlist.ConfigDB.accountSync.pairedCharacters
    for _, char in ipairs(accountChars) do
        paired[char] = {status = CHAR_STATUS.OFFLINE, accountID = accountID}
    end
    Exlist.accountSync.AddOptions(true)
end

local function getFormattedRealm(realm)
    realm = realm or GetRealmName()
    return realm:gsub("[%p%c%s]", "")
end

local function gatherAccountCharacterNames()
    local accountCharacters = {}
    local realms = Exlist.GetRealmNames()
    for _, realm in ipairs(realms) do
        local characters = Exlist.GetRealmCharacters(realm)
        for _, char in ipairs(characters) do
            table.insert(accountCharacters,
                         string.format("%s-%s", char, getFormattedRealm(realm)))
        end
    end

    return accountCharacters
end

local function dataToString(data)
    local serialized = LibSerialize:SerializeEx(configForLS, data)
    local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
    return LibDeflate:EncodeForWoWAddonChannel(compressed)
end

local function stringToData(payload)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end
    local decrompressed = LibDeflate:DecompressDeflate(decoded)
    if not decrompressed then return end
    local success, data = LibSerialize:Deserialize(decrompressed)
    if not success then return end

    return data
end

local function getAccountId()
    local accInfo = C_BattleNet.GetGameAccountInfoByGUID(UnitGUID('player'))

    return accInfo.gameAccountID
end

local function printProgress(type, message)
    local color = "ffffff";
    if (type == PROGRESS_TYPE.success) then
        color = "00ff00"
    elseif (type == PROGRESS_TYPE.warning) then
        color = "fcbe03"
    elseif (type == PROGRESS_TYPE.error) then
        color = "ff0000"
    end

    print(string.format("|cff%s%s", color, message))
end

local function sendMessage(data, distribution, target, prio, callbackFn)
    if not Exlist.ConfigDB.accountSync.enabled then return end
    data.rqTime = GetTime()
    data.userKey = Exlist.ConfigDB.accountSync.userKey
    data.accountID = getAccountId()

    AceComm:SendCommMessage(PREFIX, dataToString(data), distribution, target,
                            prio, callbackFn)

    return data.rqTime
end

local function pingCharacter(characterName, callbackFn)
    local rqTime = sendMessage({
        type = MSG_TYPE.ping,
        key = Exlist.ConfigDB.accountSync.userKey
    }, "WHISPER", characterName);
    if (callbackFn) then callbacks[rqTime] = callbackFn end
end

local function showPairRequestPopup(characterName, callbackFn)
    StaticPopupDialogs["Exlist_PairingPopup"] =
        {
            text = string.format(L["%s is requesting pairing Exlist DBs."],
                                 characterName),
            button1 = "Accept",
            button3 = "Cancel",
            hasEditBox = false,
            OnAccept = function() callbackFn(true) end,
            OnCancel = function() callbackFn(false) end,
            timeout = 0,
            cancels = "Exlist_PairingPopup",
            whileDead = true,
            hideOnEscape = 1,
            preferredIndex = 4,
            showAlert = 1,
            enterClicksFirstButton = 1
        }
    StaticPopup_Show("Exlist_PairingPopup")
end

local function setSenderStatus(sender, status, accountID)
    local characters = Exlist.ConfigDB.accountSync.pairedCharacters
    local _, realm = strsplit("-", sender)
    if (not realm) then sender = sender .. "-" .. getFormattedRealm() end
    if (characters[sender]) then
        characters[sender].status = status
        characters[sender].accountID = accountID or characters[sender].accountID
    elseif sender and status and accountID then
        characters[sender] = {status = status, accountID = accountID}
    end
end

local function validateRequest(data)
    return data.userKey == Exlist.ConfigDB.accountSync.userKey
end

--[[
    ---------------------- MSG RECEIVE -------------------------------
]]
local function messageReceive(prefix, message, distribution, sender)
    if not Exlist.ConfigDB.accountSync.enabled then return end
    local userKey = Exlist.ConfigDB.accountSync.userKey
    local data = stringToData(message)
    local msgType = data.type
    print("Msg Received ", msgType, sender)
    Exlist.Switch(msgType, {
        [MSG_TYPE.ping] = function()
            if (validateRequest(data)) then
                sendMessage(
                    {type = MSG_TYPE.pingSuccess, resTime = data.rqTime},
                    distribution, sender)
                setSenderStatus(sender, CHAR_STATUS.ONLINE, data.accountID)
            end
        end,
        [MSG_TYPE.pingSuccess] = function()
            local cb = callbacks[data.resTime]
            if (cb) then
                cb(data)
                cb = nil
            end
        end,
        [MSG_TYPE.pairRequest] = function()
            showPairRequestPopup(sender, function(success)
                if success then
                    Exlist.ConfigDB.accountSync.userKey = data.userKey
                    sendMessage({
                        type = MSG_TYPE.pairRequestSuccess,
                        accountCharacters = gatherAccountCharacterNames(),
                        accountID = getAccountId()
                    }, distribution, sender)
                    mergePairedCharacters(data.accountCharacters, data.accountID)
                    accountSync.pingAccountCharacters(data.accountID)
                else
                    sendMessage({
                        type = MSG_TYPE.pairRequestFailed,
                        userKey = userKey
                    }, distribution, sender)
                end
            end)
        end,
        [MSG_TYPE.pairRequestSuccess] = function()
            if validateRequest(data) then
                printProgress(PROGRESS_TYPE.success,
                              L["Pair request has been successful"])
                mergePairedCharacters(data.accountCharacters, data.accountID)
                accountSync.pingAccountCharacters(data.accountID)
            end
        end,
        [MSG_TYPE.pairRequestFailed] = function()
            if (validateRequest(data)) then
                printProgress(PROGRESS_TYPE.error,
                              L["Pair request has been cancelled"])
            end
        end,
        default = function()
            -- Do Nothing for now
        end
    })
end
AceComm:RegisterComm(PREFIX, messageReceive)

function accountSync.pairAccount(characterName, userKey)
    sendMessage({
        type = MSG_TYPE.pairRequest,
        userKey = userKey,
        accountCharacters = gatherAccountCharacterNames(),
        accountID = getAccountId()
    }, "WHISPER", characterName)
end

function accountSync.syncData(characterName)
    local userKey = Exlist.ConfigDB.accountSync.userKey
    print('---', userKey)
end

-- Does account have any online characters
local accountStatus = {}

local function pingAccountCharacters(accountID)
    local characters = Exlist.ConfigDB.accountSync.pairedCharacters
    local online = false
    local i = 1
    for char, info in pairs(characters) do
        if (info.accountID == accountID) then
            local found = false
            C_Timer.After(i * 0.1, function()
                pingCharacter(char, function()
                    found = true
                    characters[char].status = CHAR_STATUS.ONLINE
                    online = true
                end)
            end)
            C_Timer.After(5, function()
                if (not found) then
                    characters[char].status = CHAR_STATUS.OFFLINE
                end
            end)
            i = i + 1
        end
    end
    C_Timer.After(10, function() accountStatus[accountID] = online end)
end

function accountSync.pingEveryone()
    local characters = getPairedCharacters()
    local pingedAccounts = {}
    local i = 1
    for _, info in pairs(characters) do
        if (not pingedAccounts[info.accountID]) then
            C_Timer.After(0.5 * i,
                          function()
                pingAccountCharacters(info.accountID)
            end)
            pingedAccounts[info.accountID] = true
            i = i + 1
        end
    end
end

local PING_INTERVAL = 60 * 60 * 5 -- Every 5 minutes

accountSync.coreInit = function()
    C_Timer.NewTicker(PING_INTERVAL, function()
        local characters = getOnlineCharacters()
        local i = 1
        for _, char in ipairs(characters) do
            local online = false
            C_Timer.After(i * 0.1, function()
                pingCharacter(char, function() online = true end)
            end)

            C_Timer.After(5, function()
                if not online then
                    setSenderStatus(char, CHAR_STATUS.OFFLINE)
                end
            end)
            i = i + 1
        end
    end)
end
