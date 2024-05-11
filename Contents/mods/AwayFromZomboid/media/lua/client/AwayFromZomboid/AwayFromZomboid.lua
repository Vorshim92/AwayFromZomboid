---
--- Created by Max
--- Created on: 10/05/2024
---

-- Mod class
---@class AwayFromZomboid
AwayFromZomboid = {}

-- Mod info
AwayFromZomboid.modName = "AwayFromZomboid"
AwayFromZomboid.modVersion = "1.0.0"
AwayFromZomboid.modAuthor = "Max"
AwayFromZomboid.modDescription = "AwayFromZomboid is a mod that adds AFK detection & management systems."

-- Mod variables

--- The AFK timer in seconds.
AwayFromZomboid.AFKTimer = 0
AwayFromZomboid.previousCheckTime = nil
AwayFromZomboid.isAFK = false

-- Misc methods

--- Log a message.
---@param message string
---@return void
AwayFromZomboid.log = function(message)
    print(AwayFromZomboid.modName .. ": " .. message)
end

--- Check whether we're a client on a multiplayer server.
---@return boolean
AwayFromZomboid.isMultiplayerClient = function()
    if isServer() then
        AwayFromZomboid.log("Multiplayer client check returning false. Server detected.")
        return false
    end
    return getCore():getGameMode() == "Multiplayer" and isClient()
end

--- Get the total AFK time before a player is kicked.
---@return number
AwayFromZomboid.totalAFKKickTime = function()
    return AwayFromZomboid.getAFKTimeout() + AwayFromZomboid.getAFKKickTimeout()
end

--- Send a chat notification.
---@param message string
---@return void
AwayFromZomboid.sendChatNotification = function(message)
    processGeneralMessage(message)
end

-- Fetch sandbox vars

--- Get the AFK timeout value in seconds.
---@return number
AwayFromZomboid.getAFKTimeout = function()
    local value = SandboxVars.AwayFromZomboid.AFKTimeout
    if value == nil then
        value = 300
        AwayFromZomboid.log("AFK timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK kick timeout value in seconds.
---@return number
AwayFromZomboid.getAFKKickTimeout = function()
    local value = SandboxVars.AwayFromZomboid.AFKKickTimeout
    if value == nil then
        value = 600
        AwayFromZomboid.log("AFK kick timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK Popup message when a player goes AFK.
---@return string
AwayFromZomboid.getAFKOnPopupMessage = function()
    local value = SandboxVars.AwayFromZomboid.AFKOnPopupMessage
    if value == nil then
        value = "You are now AFK."
        AwayFromZomboid.log("AFK On Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get the AFK Popup message when a player is no longer AFK.
---@return string
AwayFromZomboid.getAFKOffPopupMessage = function()
    local value = SandboxVars.AwayFromZomboid.AFKOffPopupMessage
    if value == nil then
        value = "You are no longer AFK."
        AwayFromZomboid.log("AFK Off Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get whether to enable the AFK popup system.
---@return boolean
AwayFromZomboid.getDoPopup = function()
    local value = SandboxVars.AwayFromZomboid.DoPopup
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Do Popup value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK kick system.
---@return boolean
AwayFromZomboid.getDoKick = function()
    local value = SandboxVars.AwayFromZomboid.DoKick
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Do Kick value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK zombies no attack system.
---@return boolean
AwayFromZomboid.getAFKZombiesNoAttack = function()
    local value = SandboxVars.AwayFromZomboid.AFKZombiesNoAttack
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Zombies No Attack value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable manual AFK.
---@return boolean
AwayFromZomboid.getAllowManualAFK = function()
    local value = SandboxVars.AwayFromZomboid.AllowManualAFK
    if value == nil then
        value = true
        AwayFromZomboid.log("Allow Manual AFK value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get the manual AFK delay value in seconds.
---@return number
AwayFromZomboid.getManualAFKDelay = function()
    local value = SandboxVars.AwayFromZomboid.ManualAFKDelay
    if value == nil then
        value = 60
        AwayFromZomboid.log("Manual AFK Delay value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get whether to ignore staff.
---@return boolean
AwayFromZomboid.getIgnoreStaff = function()
    local value = SandboxVars.AwayFromZomboid.DoIgnoreStaff
    if value == nil then
        value = true
        AwayFromZomboid.log("Ignore Staff value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

-- Mod core functions

--- Check whether the player has been AFK for longer than the timeout value
---@return boolean
AwayFromZomboid.isAFKTimedOut = function()
    return AwayFromZomboid.AFKTimer >= AwayFromZomboid.getAFKTimeout()
end

--- Check whether the player should be kicked.
---@return boolean
AwayFromZomboid.shouldKick = function()
    return AwayFromZomboid.AFKTimer >= AwayFromZomboid.totalAFKKickTime()
end

--- Reset the AFK timer.
AwayFromZomboid.resetAFKTimer = function()
    AwayFromZomboid.AFKTimer = 0
end

--- Increment the AFK timer.
AwayFromZomboid.incrementAFKTimer = function(delta)
    delta = delta or 1
    AwayFromZomboid.AFKTimer = AwayFromZomboid.AFKTimer + delta

    if AwayFromZomboid.isAFKTimedOut() then
        if AwayFromZomboid.isAFK == false then
            AwayFromZomboid.becomeAFK()
        end
        if AwayFromZomboid.getDoKick() then
            if AwayFromZomboid.shouldKick() then
                AwayFromZomboid.disconnectPlayer()
            end
        end
    else
        if AwayFromZomboid.isAFK == true then
            -- Failsafe in case the player is not AFK but the mod thinks they are
            AwayFromZomboid.log("Failsafe: Player is not AFK but the mod thinks they are.")
            AwayFromZomboid.becomeNotAFK()
        end
    end
end

--- Disconnect player.
AwayFromZomboid.disconnectPlayer = function()
    if AwayFromZomboid.isMultiplayerClient() then
        getCore():exitToMenu()
    end
end

--- Popup the AFK message.
---@return void
AwayFromZomboid.AFKOnPopup = function()
    HaloTextHelper.addText(getPlayer(), AwayFromZomboid.getAFKOnPopupMessage(), HaloTextHelper.getColorRed())
    local message = AwayFromZomboid.getAFKOnPopupMessage()
    if AwayFromZomboid.getDoKick() then
        message = message .. " (Kick in " .. AwayFromZomboid.getAFKKickTimeout() .. " seconds)"
    end
    AwayFromZomboid.sendChatNotification(message)
end

--- Popup the not AFK message.
---@return void
AwayFromZomboid.AFKOffPopup = function()
    HaloTextHelper.addText(getPlayer(), AwayFromZomboid.getAFKOffPopupMessage(), HaloTextHelper.getColorGreen())
    AwayFromZomboid.sendChatNotification(AwayFromZomboid.getAFKOffPopupMessage())
end

--- Handle becoming AFK.
---@return void
AwayFromZomboid.becomeAFK = function()
    AwayFromZomboid.isAFK = true

    if AwayFromZomboid.getDoPopup() then
        AwayFromZomboid.AFKOnPopup()
    end

    if AwayFromZomboid.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(true)
    end
end

--- Handle becoming not AFK.
---@return void
AwayFromZomboid.becomeNotAFK = function()
    AwayFromZomboid.isAFK = false

    if AwayFromZomboid.getDoPopup() then
        AwayFromZomboid.AFKOffPopup()
    end

    if AwayFromZomboid.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(false)
    end

    AwayFromZomboid.resetAFKTimer()
end

AwayFromZomboid.incrementAFKHook = function()
    if AwayFromZomboid.getIgnoreStaff() then
        local access_level = getAccessLevel()
        if access_level ~= nil and access_level ~= "" and access_level ~= "none" then   -- Access level for none seems atypical compared to other access levels
            AwayFromZomboid.resetAFKTimer()
            return
        end
    end

    if AwayFromZomboid.isMultiplayerClient() == false then
        AwayFromZomboid.log("Skipping check since isMultiplayerClient is " .. AwayFromZomboid.isMultiplayerClient())
        AwayFromZomboid.resetAFKTimer()
        return
    end

    local currentTime = os.time()

    if AwayFromZomboid.previousCheckTime ~= nil then
        AwayFromZomboid.incrementAFKTimer(currentTime - AwayFromZomboid.previousCheckTime)
    end

    AwayFromZomboid.previousCheckTime = currentTime
end

-- Init

--- Initialize the mod and add event hooks.
---@return void
AwayFromZomboid.init = function()
    AwayFromZomboid.resetAFKTimer()
    AwayFromZomboid.previousCheckTime = os.time()
    AwayFromZomboid.isAFK = false

    Events.OnKeyPressed.Add(AwayFromZomboid.resetAFKTimer)
    Events.OnMouseDown.Add(AwayFromZomboid.resetAFKTimer)
    Events.OnMouseUp.Add(AwayFromZomboid.resetAFKTimer)
    Events.OnCustomUIKeyPressed.Add(AwayFromZomboid.resetAFKTimer)

    Events.EveryOneMinute.Add(AwayFromZomboid.incrementAFKHook)

    AwayFromZomboid.log(AwayFromZomboid.modVersion .. " initialized.")
end

-- Init hook

Events.OnConnected.Add(AwayFromZomboid.init)