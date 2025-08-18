local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local cclosure = syn and syn.newcclosure or newcclosure or function(f) return f end

local function safeHookRemote(obj)
    if obj:IsA("RemoteEvent") then
        pcall(function()
            local old = obj.FireServer
            if old then
                obj.FireServer = cclosure(function(self,...)
                    for _,v in pairs({...}) do
                        if type(v) == "string" and (v:lower():find("kick") or v:lower():find("shutdown") or v:lower():find("teleport") or v:lower():find("destroy")) then return end
                    end
                    return old(self,...)
                end)
            end
        end)
    elseif obj:IsA("RemoteFunction") then
        pcall(function()
            local old = obj.InvokeServer
            if old then
                obj.InvokeServer = cclosure(function(self,...)
                    for _,v in pairs({...}) do
                        if type(v) == "string" and (v:lower():find("kick") or v:lower():find("shutdown") or v:lower():find("teleport") or v:lower():find("destroy")) then return end
                    end
                    return old(self,...)
                end)
            end
        end)
    end
    for _, c in ipairs(obj:GetChildren()) do
        safeHookRemote(c)
    end
end

local mt = getrawmetatable(game)
setreadonly(mt,false)

local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",cclosure(function(self,...)
    local method = getnamecallmethod()
    if not checkcaller() then
        local blocked = {kick=true,Kick=true,Teleport=true,TeleportToPlaceInstance=true,Destroy=true,shutdown=true,Shutdown=true}
        if blocked[method] and self==plr then return end
    end
    return oldNamecall(self,...)
end))

local oldIndex, oldNewIndex = mt.__index, mt.__newindex
mt.__index = function(self,key)
    if self==plr then
        local blocked={Kick=true,kick=true,Destroy=true,Shutdown=true}
        if blocked[key] then return function() end end
    end
    return oldIndex(self,key)
end
mt.__newindex = function(self,key,value)
    if self==plr then
        local blocked={Kick=true,kick=true,Destroy=true,Shutdown=true}
        if blocked[key] then return end
    end
    return oldNewIndex(self,key,value)
end
setreadonly(mt,true)

safeHookRemote(game)
