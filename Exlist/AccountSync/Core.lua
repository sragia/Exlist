local accountSync = Exlist.accountSync
local L = Exlist.L

local PREFIX = "Exlist_AS"

local MSG_TYPE = {
    ping = "PING",
    pingSuccess = "PING_SUCCESS",
    pairRequest = "PAIR_REQUEST",
    pairRequestSuccess = "PAIR_REQUEST_SUCCESS",
    pairRequestFailed = "PAIR_REQUEST_FAILED"
}

local PROGRESS_TYPE = {
    success = "SUCCESS",
    warning = "WARNING",
    error = "ERROR",
    info = "INFO"
}

local callbacks = {}

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local AceComm = LibStub:GetLibrary("AceComm-3.0")
local configForDeflate = {level = 9}
local configForLS = {errorOnUnserializableType = false}

local function mergePairedCharacters(accountChars, accountID)
    local paired = Exlist.ConfigDB.accountSync.pairedCharacters
    for _, char in ipairs(accountChars) do
        if (not paired[char]) then
            paired[char] = {status = "Offline", accountID = accountID}
        end
    end
    Exlist.accountSync.AddOptions(true)
end

local function gatherAccountCharacterNames()
    local accountCharacters = {}
    local realms = Exlist.GetRealmNames()
    for _, realm in ipairs(realms) do
        local characters = Exlist.GetRealmCharacters(realm)
        for _, char in ipairs(characters) do
            table.insert(accountCharacters, string.format("%s-%s", char,
                                                          realm:gsub("[%p%c%s]",
                                                                     "")))
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
    AceComm:SendCommMessage(PREFIX, dataToString(data), distribution, target,
                            prio, callbackFn)
    return data.rqTime
end

local function pingCharacter(characterName, callbackFn)
    local rqTime = sendMessage({type = MSG_TYPE.ping}, "WHISPER", characterName);
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

local function messageReceive(prefix, message, distribution, sender)
    if not Exlist.ConfigDB.accountSync.enabled then return end
    local data = stringToData(message)
    local msgType = data.type
    ViragDevTool_AddData(data)

    Exlist.Switch(msgType, {
        [MSG_TYPE.ping] = function()
            sendMessage({type = MSG_TYPE.pingSuccess, resTime = data.rqTime},
                        distribution, sender)
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
                    Exlist.ConfigDB.accountSync.userKey = data.key
                    local accountInfo = C_BattleNet.GetGameAccountInfoByGUID(
                                            UnitGUID('player'))
                    sendMessage({
                        type = MSG_TYPE.pairRequestSuccess,
                        accountCharacters = gatherAccountCharacterNames(),
                        accountID = accountInfo and accountInfo.gameAccountID
                    }, distribution, sender)
                    mergePairedCharacters(data.accountCharacters, data.accountID)
                else
                    sendMessage({type = MSG_TYPE.pairRequestFailed},
                                distribution, sender)
                end
            end)
        end,
        [MSG_TYPE.pairRequestSuccess] = function()
            printProgress(PROGRESS_TYPE.success,
                          L["Pair request has been successful"])
            mergePairedCharacters(data.accountCharacters, data.accountID)
        end,
        [MSG_TYPE.pairRequestFailed] = function()
            printProgress(PROGRESS_TYPE.error,
                          L["Pair request has been cancelled"])
        end,
        default = function()
            -- Do Nothing for now
        end
    })
end
AceComm:RegisterComm(PREFIX, messageReceive)

function accountSync.pairAccount(characterName, key)
    local found = false
    pingCharacter(characterName, function(data)
        found = true
        printProgress(PROGRESS_TYPE.success,
                      "SUCCESS - " .. characterName .. " online")
        local accountInfo = C_BattleNet.GetGameAccountInfoByGUID(
                                UnitGUID('player'))
        sendMessage({
            type = MSG_TYPE.pairRequest,
            key = key,
            accountCharacters = gatherAccountCharacterNames(),
            accountID = accountInfo and accountInfo.gameAccountID
        }, "WHISPER", characterName)
    end);
    C_Timer.After(5, function()
        if (not found) then
            printProgress(PROGRESS_TYPE.error,
                          "Couldn't find - " .. characterName)
        end
    end)
end

function accountSync.syncData(characterName)
    local userKey = Exlist.ConfigDB.accountSync.userKey
    print('---', userKey)
end
