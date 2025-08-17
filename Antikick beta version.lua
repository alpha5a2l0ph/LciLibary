local Players=game:GetService("Players")
local plr=Players.LocalPlayer
local cclosure=syn and syn.newcclosure or newcclosure or nil
if not cclosure or not hookmetamethod then plr:Kick("\n\nYour exploit doesn't support hookmetamethod\n") end

local mt=getrawmetatable(game)
setreadonly(mt,false)
local oldNamecall
oldNamecall=hookmetamethod(game,"__namecall",cclosure(function(self,...)
    local method=getnamecallmethod()
    if not checkcaller() then
        local blocked={kick=true,Kick=true,Teleport=true,TeleportToPlaceInstance=true,Destroy=true,shutdown=true,Shutdown=true}
        if blocked[method] and self==plr then return end
    end
    return oldNamecall(self,...)
end))
local oldIndex=mt.__index
local oldNewIndex=mt.__newindex
mt.__index=function(self,key)
    if self==plr then
        local blockedKeys={Kick=true,kick=true,Destroy=true,Shutdown=true}
        if blockedKeys[key] then return function() end end
    end
    return oldIndex(self,key)
end
mt.__newindex=function(self,key,value)
    if self==plr then
        local blockedKeys={Kick=true,kick=true,Destroy=true,Shutdown=true}
        if blockedKeys[key] then return end
    end
    return oldNewIndex(self,key,value)
end
setreadonly(mt,true)

local function protectRemotes(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local oldFire=obj.FireServer
        obj.FireServer=function(self,...)
            local args={...}
            for _,v in pairs(args) do
                if type(v)=="string" then
                    for _,f in ipairs({"Kick","kick","Shutdown","shutdown","Teleport"}) do
                        if string.find(v,f) then return end
                    end
                end
            end
            return oldFire(self,...)
        end
    end
    for _,c in ipairs(obj:GetChildren()) do protectRemotes(c) end
end
protectRemotes(game)

spawn(function()
    while true do
        pcall(function()
            protectRemotes(game)
            if mt.__index~=oldIndex then
                mt.__index=function(self,key)
                    if self==plr then
                        local blockedKeys={Kick=true,kick=true,Destroy=true,Shutdown=true}
                        if blockedKeys[key] then return function() end end
                    end
                    return oldIndex(self,key)
                end
            end
            if mt.__newindex~=oldNewIndex then
                mt.__newindex=function(self,key,value)
                    if self==plr then
                        local blockedKeys={Kick=true,kick=true,Destroy=true,Shutdown=true}
                        if blockedKeys[key] then return end
                    end
                    return oldNewIndex(self,key,value)
                end
            end
        end)
        task.wait(0.3)
    end
end)

spawn(function()
    while true do
        pcall(function()
            hookmetamethod(game,"__namecall",cclosure(function(self,...)
                local method=getnamecallmethod()
                if not checkcaller() then
                    local blocked={kick=true,Kick=true,Teleport=true,TeleportToPlaceInstance=true,Destroy=true,shutdown=true,Shutdown=true}
                    if blocked[method] and self==plr then return end
                end
                return oldNamecall(self,...)
            end))
        end)
        task.wait(0.5)
    end
end)
