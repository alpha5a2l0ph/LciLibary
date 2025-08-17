local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 等待 LocalPlayer
local plr = Players.LocalPlayer
while not plr do
    task.wait(0.1)
    plr = Players.LocalPlayer
end

-- 检查兼容的 cclosure 接口
local cclosure = syn_newcclosure or newcclosure or protect_function or nil
if not cclosure or not hookmetamethod then
    plr:Kick("\n\n当前注入器不支持脚本防护\n")
end

-- 敏感关键字与自定义封禁方法
local blockKeys = { "Kick", "kick", "Ban", "ban", "Shutdown", "shutdown" }
local customMethods = { "AdminKick", "ServerBan", "ForceLogout", "GameKick", "PlayerBan" }

-- 判断敏感关键字
local function isSensitive(str)
    if type(str) ~= "string" then return false end
    for _, k in pairs(blockKeys) do if str:lower():find(k:lower()) then return true end end
    for _, k in pairs(customMethods) do if str:lower():find(k:lower()) then return true end end
    return false
end

-- 参数递归检查
local function checkArgs(args)
    for _, v in pairs(args) do
        if type(v) == "string" then
            if isSensitive(v) then return true end
        elseif type(v) == "table" then
            if checkArgs(v) then return true end
        end
    end
    return false
end

-- Hook __namecall
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", cclosure(function(self, ...)
    if not checkcaller() then
        local method = getnamecallmethod()
        if self == plr or isSensitive(method) then return end
    end
    return oldNamecall(self, ...)
end))

-- 元表防护
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex, oldNewIndex = mt.__index, mt.__newindex

mt.__index = function(self, key)
    if self == plr or isSensitive(key) then return function() end end
    return oldIndex(self, key)
end

mt.__newindex = function(self, key, value)
    if self == plr or isSensitive(key) then return end
    return oldNewIndex(self, key, value)
end

setreadonly(mt, true)

-- Remote 保护
local protectedRemotes = {}
local function protectRemote(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        if not protectedRemotes[obj] then
            protectedRemotes[obj] = true
            local oldFire, oldInvoke = obj.FireServer, obj.InvokeServer
            obj.FireServer = function(self, ...)
                if checkArgs({...}) then return end
                return oldFire(self, ...)
            end
            if obj:IsA("RemoteFunction") then
                obj.InvokeServer = function(self, ...)
                    if checkArgs({...}) then return end
                    return oldInvoke(self, ...)
                end
            end
        end
    end
    for _, child in ipairs(obj:GetChildren()) do protectRemote(child) end
end

-- 初始化全局保护
for _, container in pairs({game, Players, ReplicatedStorage, ServerScriptService, Workspace}) do
    task.spawn(function()
        while not container:IsDescendantOf(game) do task.wait(0.1) end
        protectRemote(container)
    end)
end

-- 移动端延迟 Remote 自动保护
RunService.Heartbeat:Connect(function()
    protectRemote(ReplicatedStorage)
    protectRemote(ServerScriptService)
    protectRemote(Workspace)
end)
