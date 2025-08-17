local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local cclosure = syn_newcclosure or newcclosure or nil
if not cclosure or not hookmetamethod then
    plr:Kick("\n\nYour exploit doesn't support hookmetamethod\n")
end

-- 敏感关键字与自定义封禁方法
local blockKeys = { "Kick", "kick", "Ban", "ban", "Shutdown", "shutdown" }
local customMethods = { "AdminKick", "ServerBan", "ForceLogout" }

-- Hook __namecall 拦截 LocalPlayer 调用敏感方法
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", cclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() then
        if self == plr then
            for _, m in pairs(blockKeys) do
                if method:lower() == m:lower() then return end
            end
            for _, m in pairs(customMethods) do
                if method:lower() == m:lower() then return end
            end
        end
    end
    return oldNamecall(self, ...)
end))

-- 元表防护
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex = mt.__index
local oldNewIndex = mt.__newindex

mt.__index = function(self, key)
    if self == plr then
        for _, k in pairs(blockKeys) do
            if key == k then return function() end end
        end
        for _, k in pairs(customMethods) do
            if key == k then return function() end end
        end
    end
    return oldIndex(self, key)
end

mt.__newindex = function(self, key, value)
    if self == plr then
        for _, k in pairs(blockKeys) do
            if key == k then return end
        end
        for _, k in pairs(customMethods) do
            if key == k then return end
        end
    end
    return oldNewIndex(self, key, value)
end

setreadonly(mt, true)

-- Remote 保护（递归参数检查）
local function checkArgs(args)
    for _, v in pairs(args) do
        if type(v) == "string" then
            for _, w in pairs(blockKeys) do
                if v:lower():find(w:lower()) then return true end
            end
            for _, w in pairs(customMethods) do
                if v:lower():find(w:lower()) then return true end
            end
        elseif type(v) == "table" then
            if checkArgs(v) then return true end
        end
    end
    return false
end

local function protectRemote(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        if not obj.__protected then
            obj.__protected = true
            local oldFire = obj.FireServer
            obj.FireServer = function(self, ...)
                local args = {...}
                if checkArgs(args) then return end
                return oldFire(self, ...)
            end
            if obj:IsA("RemoteFunction") then
                local oldInvoke = obj.InvokeServer
                obj.InvokeServer = function(self, ...)
                    local args = {...}
                    if checkArgs(args) then return end
                    return oldInvoke(self, ...)
                end
            end
        end
    end
    for _, child in ipairs(obj:GetChildren()) do
        protectRemote(child)
    end
end

-- 初始化全局保护
for _, container in pairs({game, ReplicatedStorage, ServerScriptService, Workspace}) do
    protectRemote(container)
end
