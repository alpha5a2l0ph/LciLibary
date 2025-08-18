local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local cclosure = syn and syn.newcclosure or newcclosure or nil

local function isInjected()
    local blacklistedLibraries = {
        "synapse", "kernel", "vape", "scriptware", "sentinel", "protosmash", "fluxus", "hydra", "krnl", "delta"
    }
    for _, lib in pairs(blacklistedLibraries) do
        if string.match(tostring(debug.getinfo(1).source), lib) then
            return true
        end
    end
    return false
end

if isInjected() then
    return
end

local function protectRemoteEvents(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local oldFire = obj.FireServer
        obj.FireServer = cclosure(function(self, ...)
            local args = {...}
            for _, v in pairs(args) do
                if type(v) == "string" then
                    local blockedKeywords = {"kick", "shutdown", "teleport", "destroy"}
                    for _, f in ipairs(blockedKeywords) do
                        if string.find(v, f) then
                            return
                        end
                    end
                end
            end
            return oldFire(self, ...)
        end)
    end
    for _, c in ipairs(obj:GetChildren()) do
        protectRemoteEvents(c)
    end
end

local function dynamicExecution(func)
    local success, result = pcall(func)
    if not success then
        warn("Dynamic code execution failed: " .. result)
    end
end

local function executeProtectedCode()
    dynamicExecution(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)

        local oldNamecall
        local blockedMethods = {
            kick = true, Kick = true, Teleport = true, TeleportToPlaceInstance = true,
            Destroy = true, shutdown = true, Shutdown = true, SetCore = true,
            SetUserId = true, ChangeParent = true, ReplicateToClients = true
        }

        oldNamecall = hookmetamethod(game, "__namecall", cclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if not checkcaller() then
                if blockedMethods[method] and self == plr then
                    return
                end
            end
            return oldNamecall(self, ...)
        end))

        local oldIndex = mt.__index
        local oldNewIndex = mt.__newindex

        mt.__index = function(self, key)
            if self == plr then
                local blockedKeys = {
                    Kick = true, kick = true, Destroy = true, Shutdown = true, SetCore = true,
                    SetUserId = true, ChangeParent = true
                }
                if blockedKeys[key] then return function() end end
            end
            return oldIndex(self, key)
        end

        mt.__newindex = function(self, key, value)
            if self == plr then
                local blockedKeys = {
                    Kick = true, kick = true, Destroy = true, Shutdown = true, SetCore = true,
                    SetUserId = true, ChangeParent = true
                }
                if blockedKeys[key] then return end
            end
            return oldNewIndex(self, key, value)
        end

        setreadonly(mt, true)

        protectRemoteEvents(game)
    end)
end

spawn(function()
    while true do
        task.wait(1)
        dynamicExecution(executeProtectedCode)
    end
end)

spawn(function()
    while true do
        pcall(function()
            setreadonly(getrawmetatable(game), false)
        end)
        task.wait(5)
    end
end)
