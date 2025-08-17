do
    local a=game:GetService("Players").LocalPlayer
    local b=syn and syn.newcclosure or newcclosure or nil
    if not b or not hookmetamethod then a:Kick("\n\nUnsupported exploit\n") end
    local c=getrawmetatable(game)
    setreadonly(c,false)
    local function xor(str,key)
        local res=""
        for i=1,#str do
            res=res..string.char(bit32.bxor(str:byte(i),key))
        end
        return res
    end
    local function decode(str)
        return xor(str,42)
    end
    local function namecallHook()
        local old
        old=hookmetamethod(game,"__namecall",b(function(s,...)
            local m=getnamecallmethod()
            if not checkcaller() then
                local blocked={}
                for _,v in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do blocked[v]=true end
                if blocked[m] and s==a then return end
            end
            return old(s,...)
        end))
        return old
    end
    local oldNC=namecallHook()
    local oldI=c.__index
    local oldN=c.__newindex
    c.__index=function(t,k)
        if t==a then
            local bl={}
            for _,v in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do bl[v]=true end
            if bl[k] then return function() end end
        end
        return oldI(t,k)
    end
    c.__newindex=function(t,k,v)
        if t==a then
            local bl={}
            for _,v2 in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do bl[v2]=true end
            if bl[k] then return end
        end
        return oldN(t,k,v)
    end
    setreadonly(c,true)
    local function protectRemote(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if not obj.__p then
                obj.__p=true
                local oldFire=obj.FireServer
                obj.FireServer=(function(f)
                    return function(s,...)
                        local args={...}
                        for _,v in pairs(args) do
                            if type(v)=="string" then
                                for _,bstr in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do
                                    if string.find(v,bstr) then return end
                                end
                            end
                        end
                        return f(s,...)
                    end
                end)(oldFire)
                if obj:IsA("RemoteFunction") then
                    local oldInv=obj.InvokeServer
                    obj.InvokeServer=(function(f)
                        return function(s,...)
                            local args={...}
                            for _,v in pairs(args) do
                                if type(v)=="string" then
                                    for _,bstr in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do
                                        if string.find(v,bstr) then return end
                                    end
                                end
                            end
                            return f(s,...)
                        end
                    end)(oldInv)
                end
            end
        end
        for _,c in ipairs(obj:GetChildren()) do protectRemote(c) end
    end
    spawn(function()
        while true do
            pcall(function()
                for _,s in pairs({workspace,Players,game:GetService("ReplicatedStorage"),game:GetService("StarterPlayer")}) do
                    for _,obj in pairs(s:GetDescendants()) do protectRemote(obj) end
                end
            end)
            task.wait(0.15)
        end
    end)
    spawn(function()
        while true do
            pcall(function()
                protectRemote(game)
                if c.__index~=oldI then
                    c.__index=function(t,k)
                        if t==a then
                            local bl={}
                            for _,v in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do bl[v]=true end
                            if bl[k] then return function() end end
                        end
                        return oldI(t,k)
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
    spawn(function()
        while true do
            pcall(function()
                if c.__newindex~=oldN then
                    c.__newindex=function(t,k,v)
                        if t==a then
                            local bl={}
                            for _,v2 in pairs({decode("\x19\x0f\x15\x0f"),decode("\x0f\x15\x19\x0f"),decode("\x0f\x17\x0b"),decode("\x0b\x17\x0f"),decode("\x1f\x0e\x12\x14\x0e\x1c\x0e\x12"),decode("\x1c\x12\x14\x0e\x1f\x0e\x12\x0e"),decode("\x16\x0e\x17\x17\x0f\x11\x0c"),decode("\x14\x0f\x0f\x1f\x1c\x12\x0e\x16")}) do bl[v2]=true end
                            if bl[k] then return end
                        end
                        return oldN(t,k,v)
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
    spawn(function()
        while true do
            pcall(function()
                oldNC=namecallHook()
            end)
            task.wait(0.05)
        end
    end)
    spawn(function()
        while true do
            pcall(function()
                local env=getfenv() or {}
                if env._G then env._G={} end
                if env.debug then env.debug=nil end
            end)
            task.wait(2)
        end
    end)
    spawn(function()
        while true do
            pcall(function()
                local m=a:GetMouse()
                m.Move:Fire(Vector3.new(math.random(1,1000),math.random(1,1000),math.random(1,1000)))
                local k={"W","A","S","D"}
                local r=k[math.random(1,#k)]
                game:GetService("UserInputService").InputBegan:Fire({KeyCode=Enum.KeyCode[r]})
            end)
            task.wait(math.random(2,5))
        end
    end)
end
