loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()

loadstring(game:HttpGet("https://raw.githubusercontent.com/alpha5a2l0ph/LciLibary/refs/heads/main/Antikick-no-antiban"))()

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    ClassName = "Universal Silent Aim",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = true,
    ShowSilentAimTarget = false,
    ShowTracer = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100,
    FixedFOV = true,
    TargetIndicatorRadius = 20,
    CrosshairLength = 30,
    CrosshairGap = 5,
    IndicatorRotationEnabled = false,
    IndicatorRotationSpeed = 1,
    IndicatorRainbowEnabled = false,
    IndicatorRainbowSpeed = 1,
    MaxDistance = 500,
    Tracer_Y_Offset = 0,
    PriorityMode = "Cross recently",
    TargetInfoStyle = "Panel",
    ShowTargetName = true,
    ShowTargetHealth = true,
    ShowTargetDistance = true,
    ShowTargetCategory = false,
    ShowDamageNotifier = false,
    HighlightEnabled = false,
    HighlightRainbowEnabled = false,
    HighlightColor = Color3.fromRGB(255, 255, 0),
    IndependentPanelPosition = "200,200",
    IndependentPanelPinned = false,
    LeakAndHitMode = false,
    Wallbang = false,
    EnableNameTargeting = false,
    TargetName1 = "",
    TargetName2 = "",
    TargetName3 = "",
    BlacklistedNames = {}
}

getgenv().SilentAimSettings = SilentAimSettings
local MainFileName = "UniversalSilentAim"

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetPlayers = Players.GetPlayers
local WorldToViewportPoint = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local currentTargetPart = nil
local currentHighlight = nil
local currentRotationAngle = 0
local currentIndicatorHue = 0
local npcList = {}
local targetMap = {}
local avatarCache = {}

local lockedTargetObject = nil

local target_indicator_circle = Drawing.new("Circle")
target_indicator_circle.Visible = false; target_indicator_circle.ZIndex = 1000; target_indicator_circle.Thickness = 2; target_indicator_circle.Filled = false
local target_indicator_lines = {}
for i = 1, 5 do local line = Drawing.new("Line"); line.Visible = false; line.ZIndex = 1000; line.Thickness = 2; table.insert(target_indicator_lines, line) end
local tracer_line = Drawing.new("Line")
tracer_line.Visible = false; tracer_line.ZIndex = 998; tracer_line.Color = Color3.fromRGB(255, 255, 0); tracer_line.Thickness = 1; tracer_line.Transparency = 1

local overhead_info_texts = {
    Name = Drawing.new("Text"),
    Health = Drawing.new("Text"),
    Distance = Drawing.new("Text"),
    Category = Drawing.new("Text")
}
for _, text in pairs(overhead_info_texts) do
    text.Visible = false; text.ZIndex = 1001; text.Font = Drawing.Fonts.Plex; text.Size = 14; text.Color = Color3.fromRGB(255, 255, 255); text.Center = true; text.Outline = true
end

local panel_info_bg = Drawing.new("Square")
panel_info_bg.Visible = false; panel_info_bg.ZIndex = 1002; panel_info_bg.Color = Color3.fromRGB(0, 0, 0); panel_info_bg.Thickness = 0; panel_info_bg.Filled = true; panel_info_bg.Transparency = 0.5
local panel_info_texts = {
    Name = Drawing.new("Text"),
    Health = Drawing.new("Text"),
    Distance = Drawing.new("Text"),
    Category = Drawing.new("Text")
}
for _, text in pairs(panel_info_texts) do
    text.Visible = false; text.ZIndex = 1003; text.Font = Drawing.Fonts.Plex; text.Size = 14; text.Color = Color3.fromRGB(255, 255, 255); text.Center = false; text.Outline = true
end

local FOVCircleGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
FOVCircleGui.Name = "FOVCircleGui"; FOVCircleGui.ResetOnSpawn = false; FOVCircleGui.IgnoreGuiInset = true; FOVCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local FOVCircleFrame = Instance.new("Frame", FOVCircleGui)
FOVCircleFrame.Name = "FOVCircleFrame"; FOVCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5); FOVCircleFrame.Position = UDim2.fromScale(0.5, 0.5); FOVCircleFrame.BackgroundTransparency = 1
local FOVStroke = Instance.new("UIStroke", FOVCircleFrame)
FOVStroke.Name = "FOVStroke"; FOVStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; FOVStroke.Thickness = 1; FOVStroke.Transparency = 0.5
local FOVCorner = Instance.new("UICorner", FOVCircleFrame)
FOVCorner.Name = "FOVCorner"; FOVCorner.CornerRadius = UDim.new(1, 0)

local IndependentPanelGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
IndependentPanelGui.Name = "IndependentPanelGui"; IndependentPanelGui.ResetOnSpawn = false; IndependentPanelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local IndependentPanelFrame = Instance.new("Frame", IndependentPanelGui)
IndependentPanelFrame.Name = "PanelFrame"; IndependentPanelFrame.Size = UDim2.fromOffset(160, 100); 
IndependentPanelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); IndependentPanelFrame.BackgroundTransparency = 0.3; IndependentPanelFrame.BorderSizePixel = 1; IndependentPanelFrame.BorderColor3 = Color3.new(1,1,1)
IndependentPanelFrame.Visible = false; IndependentPanelFrame.Active = true
local IPCorner = Instance.new("UICorner", IndependentPanelFrame); IPCorner.CornerRadius = UDim.new(0, 4)
local IPListLayout = Instance.new("UIListLayout", IndependentPanelFrame)
IPListLayout.Padding = UDim.new(0, 5); IPListLayout.SortOrder = Enum.SortOrder.LayoutOrder; IPListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; IPListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local independent_panel_texts = {}
for i, name in ipairs({"Name", "Health", "Distance", "Category"}) do
    local label = Instance.new("TextLabel", IndependentPanelFrame)
    label.Name = name; label.Size = UDim2.new(1, -10, 0, 15); label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans; label.TextSize = 14; label.TextColor3 = Color3.new(1,1,1); label.TextXAlignment = Enum.TextXAlignment.Left; label.LayoutOrder = i
    independent_panel_texts[name] = label
end
IndependentPanelFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and IndependentPanelFrame.Draggable then IndependentPanelFrame.Position = UDim2.fromOffset(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) end end)
IndependentPanelFrame.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and IndependentPanelFrame.Draggable then SilentAimSettings.IndependentPanelPosition = IndependentPanelFrame.Position.X.Offset .. "," .. IndependentPanelFrame.Position.Y.Offset end end)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean", "boolean"} },
    FindPartOnRayWithWhitelist = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean"} },
    FindPartOnRay = { ArgCountRequired = 2, Args = {"Instance", "Ray", "Instance", "boolean", "boolean"} },
    Raycast = { ArgCountRequired = 3, Args = {"Instance", "Vector3", "Vector3", "RaycastParams"} }
}

function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    return math.random() <= Percentage / 100
end

do
    if not isfolder(MainFileName) then makefolder(MainFileName) end
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToViewportPoint(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then return false end
    for Pos, Argument in next, Args do if typeof(Argument) == RayMethod.Args[Pos] then Matches = Matches + 1 end end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function isNPC(obj)
    return obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj)
end

function getTargetCategory(character)
    if not character then return "None" end

    if Players:GetPlayerFromCharacter(character) then
        return "Player"
    end

    if SilentAimSettings.EnableNameTargeting then
        local name = character.Name:lower()
        local t1 = SilentAimSettings.TargetName1:lower()
        local t2 = SilentAimSettings.TargetName2:lower()
        local t3 = SilentAimSettings.TargetName3:lower()
        if (t1 ~= "" and string.find(name, t1, 1, true)) or
           (t2 ~= "" and string.find(name, t2, 1, true)) or
           (t3 ~= "" and string.find(name, t3, 1, true)) then
            return "Add"
        end
    end
    
    if character:FindFirstChild("Humanoid") then
         return "NPC/Bot"
    end

    return "Unknown"
end

local function updateNPCs()
    local newNpcList = {}
    local addedNpcs = {} 

    if SilentAimSettings.EnableNameTargeting then
        local targetSubstrings = {}
        if SilentAimSettings.TargetName1 and SilentAimSettings.TargetName1 ~= "" then table.insert(targetSubstrings, SilentAimSettings.TargetName1:lower()) end
        if SilentAimSettings.TargetName2 and SilentAimSettings.TargetName2 ~= "" then table.insert(targetSubstrings, SilentAimSettings.TargetName2:lower()) end
        if SilentAimSettings.TargetName3 and SilentAimSettings.TargetName3 ~= "" then table.insert(targetSubstrings, SilentAimSettings.TargetName3:lower()) end

        if #targetSubstrings > 0 then
            for _, model in ipairs(workspace:GetDescendants()) do
                if isNPC(model) then
                    for _, substring in ipairs(targetSubstrings) do
                        if string.find(model.Name:lower(), substring, 1, true) then
                            if not addedNpcs[model] then
                                table.insert(newNpcList, model)
                                addedNpcs[model] = true
                                break 
                            end
                        end
                    end
                end
            end
        end
    end

    for _, v in ipairs(workspace:GetChildren()) do
        if isNPC(v) then
            if not addedNpcs[v] then
                table.insert(newNpcList, v)
                addedNpcs[v] = true
            end
        end
    end
    
    npcList = newNpcList
end

local function isBlacklisted(name)
    local lowerName = name:lower()
    for _, blacklistedName in ipairs(SilentAimSettings.BlacklistedNames) do
        if blacklistedName:lower() == lowerName then
            return true
        end
    end
    return false
end

local function isPartVisible(part, customOrigin)
    if not part then return false end
    local localCharacter = LocalPlayer.Character
    if not localCharacter then return false end
    local origin = customOrigin or Camera.CFrame.Position
    local direction = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localCharacter, part.Parent}
    local raycastResult = workspace:Raycast(origin, direction.Unit * direction.Magnitude, raycastParams)
    return not raycastResult
end

local function getClosestPlayer()
    local LocalPlayerCharacter = LocalPlayer.Character
    if not LocalPlayerCharacter or not LocalPlayerCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localRoot = LocalPlayerCharacter.HumanoidRootPart
    
    local AimPoint = SilentAimSettings.FixedFOV and (Camera.ViewportSize / 2) or GetMouseLocation(UserInputService)
    local candidates = {}
    local useFovCheck = SilentAimSettings.PriorityMode ~= "The closest to yourself(No FOV)"

    for _, Player in ipairs(GetPlayers(Players)) do
        if Player ~= LocalPlayer and not (SilentAimSettings.TeamCheck and Player.Team == LocalPlayer.Team) and not isBlacklisted(Player.Name) then
            local Character = Player.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Character and Humanoid and Humanoid.Health > 0 then
                local partForChecks = Character:FindFirstChild(SilentAimSettings.TargetPart) or Character:FindFirstChild("HumanoidRootPart")
                if not partForChecks then continue end

                if not (SilentAimSettings.VisibleCheck and not isPartVisible(partForChecks, LocalPlayerCharacter.Head.Position)) then
                    local physicalDist = (localRoot.Position - partForChecks.Position).Magnitude
                    if physicalDist <= SilentAimSettings.MaxDistance then
                        local ScreenPosition, OnScreen = getPositionOnScreen(partForChecks.Position)
                        if OnScreen then
                            local fovDist = (AimPoint - ScreenPosition).Magnitude
                            if not useFovCheck or fovDist <= SilentAimSettings.FOVRadius then
                                table.insert(candidates, {character = Character, fov = fovDist, dist = physicalDist, health = Humanoid.Health})
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if SilentAimSettings.PriorityMode == "Lowest Health" then
            return a.health < b.health
        elseif SilentAimSettings.PriorityMode == The closest distance" or SilentAimSettings.PriorityMode == The closest to yourself(No FOV)" then
            return a.dist < b.dist
        else
            return a.fov < b.fov
        end
    end)
    return candidates[1].character
end

local function getNPCTarget()
    local LocalPlayerCharacter = LocalPlayer.Character
    if not LocalPlayerCharacter or not LocalPlayerCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localRoot = LocalPlayerCharacter.HumanoidRootPart

    local AimPoint = SilentAimSettings.FixedFOV and (Camera.ViewportSize / 2) or GetMouseLocation(UserInputService)
    local candidates = {}
    local useFovCheck = SilentAimSettings.PriorityMode ~= "The closest to yourself(No FOV)"

    for _, NPCModel in ipairs(npcList) do
        if not (SilentAimSettings.TeamCheck and NPCModel.Team and NPCModel.Team == LocalPlayer.Team) and not isBlacklisted(NPCModel.Name) then
            local Humanoid = NPCModel and NPCModel:FindFirstChildOfClass("Humanoid")
            if NPCModel and Humanoid and Humanoid.Health > 0 then
                local partForChecks = NPCModel:FindFirstChild(SilentAimSettings.TargetPart) or NPCModel.PrimaryPart or NPCModel:FindFirstChild("HumanoidRootPart")
                if not partForChecks then continue end

                if not (SilentAimSettings.VisibleCheck and not isPartVisible(partForChecks, LocalPlayerCharacter.Head.Position)) then
                    local physicalDist = (localRoot.Position - partForChecks.Position).Magnitude
                    if physicalDist <= SilentAimSettings.MaxDistance then
                        local ScreenPosition, OnScreen = getPositionOnScreen(partForChecks.Position)
                        if OnScreen then
                            local fovDist = (AimPoint - ScreenPosition).Magnitude
                            if not useFovCheck or fovDist <= SilentAimSettings.FOVRadius then
                                table.insert(candidates, {character = NPCModel, fov = fovDist, dist = physicalDist, health = Humanoid.Health})
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if SilentAimSettings.PriorityMode == "Lowest Health" then
            return a.health < b.health
        elseif SilentAimSettings.PriorityMode == "The closest distance" or SilentAimSettings.PriorityMode == "The closest to yourself(No FOV)" then
            return a.dist < b.dist
        else
            return a.fov < b.fov
        end
    end)
    return candidates[1].character
end

function getPolygonPoints(center, radius, sides)
    local points = {}
    local rotationOffset = SilentAimSettings.IndicatorRotationEnabled and currentRotationAngle or 0
    for i = 1, sides do
        local angle = (i - 1) * (2 * math.pi / sides) - (math.pi / 2) + rotationOffset
        table.insert(points, Vector2.new(center.X + radius * math.cos(angle), center.Y + radius * math.sin(angle)))
    end
    return points
end

function hideAllVisuals()
    target_indicator_circle.Visible = false
    for _, line in ipairs(target_indicator_lines) do line.Visible = false end
    for _, text in pairs(overhead_info_texts) do text.Visible = false end
    panel_info_bg.Visible = false
    for _, text in pairs(panel_info_texts) do text.Visible = false end
    if IndependentPanelFrame then IndependentPanelFrame.Visible = false end
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "Universal Silent Aim", Footer = "Beta Verison", Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Misc = Window:AddTab("Misc", "boxes"),
    ["UI Settings"] = Window:AddTab("UI settings", "settings"),
}

local MainGroupBox = Tabs.Main:AddLeftGroupbox("Main", "boxes")
MainGroupBox:AddToggle("EnabledToggle", { Text = "Enabled", Default = SilentAimSettings.Enabled }):AddKeyPicker("EnabledKeybind", { Default = SilentAimSettings.ToggleKey, SyncToggleState = true, Mode = "Toggle" })  
Toggles.EnabledToggle:OnChanged(function(Value) SilentAimSettings.Enabled = Value end)
MainGroupBox:AddToggle("TeamCheckToggle", { Text = "Team Check", Default = SilentAimSettings.TeamCheck }):OnChanged(function(Value) SilentAimSettings.TeamCheck = Value end)
MainGroupBox:AddToggle("VisibleCheckToggle", { Text = "Wallcheck", Default = SilentAimSettings.VisibleCheck }):OnChanged(function(Value) SilentAimSettings.VisibleCheck = Value end)
MainGroupBox:AddToggle("WallbangToggle", { Text = "Wallbang(test)", Default = SilentAimSettings.Wallbang}):OnChanged(function(Value) SilentAimSettings.Wallbang = Value end)
MainGroupBox:AddToggle("LeakAndHitToggle", { Text = "LeakAndHitMod", Default = SilentAimSettings.LeakAndHitMode}):OnChanged(function(Value) SilentAimSettings.LeakAndHitMode = Value end)
MainGroupBox:AddDropdown("TargetModeDropdown", { Text = "TargetMode", Default = "Player", Values = {"Palyer", "NPC/Bot", "All"} }):OnChanged(function(Value) SilentAimSettings.TargetMode = Value end)
MainGroupBox:AddDropdown("TargetPartDropdown", { Values = {"Head", "HumanoidRootPart", "Random"}, Default = SilentAimSettings.TargetPart, Text = "Part" }):OnChanged(function(Value) SilentAimSettings.TargetPart = Value end)
MainGroupBox:AddDropdown("MethodDropdown", { Text = "Method", Default = SilentAimSettings.SilentAimMethod, Values = { "Raycast","FindPartOnRay", "FindPartOnRayWithWhitelist", "FindPartOnRayWithIgnoreList", "ScreenPointToRay", "ViewportPointToRay", "Ray", "Mouse.Hit/Target" } }):OnChanged(function(Value) SilentAimSettings.SilentAimMethod = Value end)
MainGroupBox:AddSlider('HitChanceSlider', { Text = 'Chance', Default = SilentAimSettings.HitChance, Min = 0, Max = 100, Rounding = 1, Suffix = "%" }):OnChanged(function(Value) SilentAimSettings.HitChance = Value end)
MainGroupBox:AddSlider('MaxDistanceSlider', { Text = 'Max Distance', Default = SilentAimSettings.MaxDistance, Min = 10, Max = 2000, Rounding = 0, Suffix = "studs" }):OnChanged(function(Value) SilentAimSettings.MaxDistance = Value end)

local VisualsGroupBox = Tabs.Main:AddRightGroupbox("Visual")
VisualsGroupBox:AddToggle("FOVVisibleToggle", { Text = "Show Fov", Default = SilentAimSettings.FOVVisible }):AddColorPicker("FOVColorPicker", { Default = Color3.fromRGB(54, 57, 241), Title = "FOV圈颜色" })
Toggles.FOVVisibleToggle:OnChanged(function(Value) FOVCircleGui.Enabled = Value; SilentAimSettings.FOVVisible = Value end)
Options.FOVColorPicker:OnChanged(function(Value) FOVStroke.Color = Value end)
VisualsGroupBox:AddSlider("FOVRadiusSlider", { Text = "FOV radius", Min = 10, Max = 1000, Default = SilentAimSettings.FOVRadius, Rounding = 0 }):OnChanged(function(Value) FOVCircleFrame.Size = UDim2.fromOffset(Value * 2, Value * 2); SilentAimSettings.FOVRadius = Value end)
VisualsGroupBox:AddToggle("FixedFOVToggle", { Text = "Fixed Fov(Mobile)", Default = SilentAimSettings.FixedFOV }):OnChanged(function(Value) SilentAimSettings.FixedFOV = Value end)
VisualsGroupBox:AddToggle("ShowTargetToggle", { Text = "Show Target", Default = SilentAimSettings.ShowSilentAimTarget }):AddColorPicker("TargetIndicatorColorPicker", { Default = Color3.fromRGB(255,0,0), Title = "指示器颜色" })
Toggles.ShowTargetToggle:OnChanged(function(Value) SilentAimSettings.ShowSilentAimTarget = Value end)
Options.TargetIndicatorColorPicker:OnChanged(function(Value) target_indicator_circle.Color = Value; for _, line in ipairs(target_indicator_lines) do line.Color = Value end end)
VisualsGroupBox:AddDropdown("IndicatorStyleDropdown", { Text = "Indicator style", Values = {"Circle", "Triangle", "Pentagram", "十字准星"}, Default = "Circle" })
VisualsGroupBox:AddSlider("TargetIndicatorRadiusSlider", { Text = "Indicator size", Min = 5, Max = 50, Default = SilentAimSettings.TargetIndicatorRadius, Rounding = 0 }):OnChanged(function(Value) SilentAimSettings.TargetIndicatorRadius = Value end)
VisualsGroupBox:AddSlider("CrosshairLengthSlider", { Text = "Cross Extent", Min = 5, Max = 100, Default = SilentAimSettings.CrosshairLength, Rounding = 0 }):OnChanged(function(Value) SilentAimSettings.CrosshairLength = Value end)
VisualsGroupBox:AddSlider("CrosshairGapSlider", { Text = "Cross, Min = 0, Max = 50, Default = SilentAimSettings.CrosshairGap, Rounding = 0 }):OnChanged(function(Value) SilentAimSettings.CrosshairGap = Value end)
VisualsGroupBox:AddToggle("IndicatorRotationToggle", { Text = "The indicator rotates", Default = SilentAimSettings.IndicatorRotationEnabled })
Toggles.IndicatorRotationToggle:OnChanged(function(Value) SilentAimSettings.IndicatorRotationEnabled = Value end)
VisualsGroupBox:AddSlider("IndicatorRotationSpeedSlider", { Text = "SpinSpeed", Min = 0, Max = 10, Default = SilentAimSettings.IndicatorRotationSpeed, Rounding = 1, Compact = true })
Options.IndicatorRotationSpeedSlider:OnChanged(function(Value) SilentAimSettings.IndicatorRotationSpeed = Value end)
VisualsGroupBox:AddToggle("IndicatorRainbowToggle", { Text = "Rainbow", Default = SilentAimSettings.IndicatorRainbowEnabled })
Toggles.IndicatorRainbowToggle:OnChanged(function(Value) SilentAimSettings.IndicatorRainbowEnabled = Value end)
VisualsGroupBox:AddSlider("IndicatorRainbowSpeedSlider", { Text = "Colour change speed", Min = 0, Max = 10, Default = SilentAimSettings.IndicatorRainbowSpeed, Rounding = 1, Compact = true })
Options.IndicatorRainbowSpeedSlider:OnChanged(function(Value) SilentAimSettings.IndicatorRainbowSpeed = Value end)
VisualsGroupBox:AddToggle("ShowTracerToggle", { Text = "Target tracking line", Default = SilentAimSettings.ShowTracer }):AddColorPicker("TracerColorPicker", { Default = tracer_line.Color, Title = "追踪线颜色" })
Toggles.ShowTracerToggle:OnChanged(function(Value) SilentAimSettings.ShowTracer = Value end)
Options.TracerColorPicker:OnChanged(function(Value) tracer_line.Color = Value end)
VisualsGroupBox:AddSlider('TracerYOffsetSlider', { Text = 'The Y-axis offset of the tracking line', Default = SilentAimSettings.Tracer_Y_Offset, Min = -10, Max = 10, Rounding = 3, Suffix = " studs" }):OnChanged(function(Value) SilentAimSettings.Tracer_Y_Offset = Value end)

local PredictionGroupBox = Tabs.Main:AddLeftGroupbox("Pred")
PredictionGroupBox:AddToggle("PredictionToggle", { Text = "Mouse.Hit/Target Mod Pred", Default = SilentAimSettings.MouseHitPrediction }):OnChanged(function(Value) SilentAimSettings.MouseHitPrediction = Value end)
PredictionGroupBox:AddSlider("PredictionAmountSlider", { Text = "Pred Vaule", Min = 0, Max = 1, Default = SilentAimSettings.MouseHitPredictionAmount, Rounding = 3 }):OnChanged(function(Value) SilentAimSettings.MouseHitPredictionAmount = Value; PredictionAmount = Value end)

local MiscGroupBox = Tabs.Misc:AddLeftGroupbox("Misc")
MiscGroupBox:AddDropdown("PriorityModeDropdown", { Text = "Priority mode", Default = SilentAimSettings.PriorityMode, Values = {"准星最近", "距离最近", "最低血量", "最近的人(无FOV)"} }):OnChanged(function(Value) SilentAimSettings.PriorityMode = Value end)
MiscGroupBox:AddDropdown("TargetInfoStyleDropdown", { Text = "Information display style", Default = SilentAimSettings.TargetInfoStyle, Values = {"Panel", "Top", "Independent panel"} }):OnChanged(function(Value) SilentAimSettings.TargetInfoStyle = Value end)
MiscGroupBox:AddToggle("ShowTargetNameToggle", { Text = "Show Target Name", Default = SilentAimSettings.ShowTargetName }):OnChanged(function(Value) SilentAimSettings.ShowTargetName = Value end)
MiscGroupBox:AddToggle("ShowTargetHealthToggle", { Text = "Show Target Health", Default = SilentAimSettings.ShowTargetHealth }):OnChanged(function(Value) SilentAimSettings.ShowTargetHealth = Value end)
MiscGroupBox:AddToggle("ShowTargetDistanceToggle", { Text = "Show Target Distance", Default = SilentAimSettings.ShowTargetDistance }):OnChanged(function(Value) SilentAimSettings.ShowTargetDistance = Value end)
MiscGroupBox:AddToggle("ShowTargetCategoryToggle", { Text = "Show target category", Default = SilentAimSettings.ShowTargetCategory }):OnChanged(function(Value) SilentAimSettings.ShowTargetCategory = Value end)
MiscGroupBox:AddToggle("DamageNotifierToggle", { Text = "Show Hit Notify", Default = SilentAimSettings.ShowDamageNotifier }):OnChanged(function(Value) SilentAimSettings.ShowDamageNotifier = Value end)
MiscGroupBox:AddButton("Reset the position of the independent panel", function()
    SilentAimSettings.IndependentPanelPosition = "200,200"
    local pos = SilentAimSettings.IndependentPanelPosition:split(",")
    IndependentPanelFrame.Position = UDim2.fromOffset(tonumber(pos[1]), tonumber(pos[2]))
end)
MiscGroupBox:AddToggle("PinPanelToggle", {Text = "Fixed Panel", Default = SilentAimSettings.IndependentPanelPinned}):OnChanged(function(value)
    SilentAimSettings.IndependentPanelPinned = value
    IndependentPanelFrame.Draggable = not value
end)

local ManualLockGroupBox = Tabs.Misc:AddLeftGroupbox("Lock")
ManualLockGroupBox:AddDropdown("TargetSelectorDropdown", { Text = "LockTarget (None=Auto)", Default = "None", Values = {"None"} }):OnChanged(function(selectedName)
    if selectedName == "None" then
        lockedTargetObject = nil
    else
        lockedTargetObject = targetMap[selectedName]
    end
end)
ManualLockGroupBox:AddButton("Refresh the list", function()
    targetMap = {}
    local targetNames = {"None"}
    local targetMode = SilentAimSettings.TargetMode
    
    if targetMode == "NPC/Bot" or targetMode == "All" then
        updateNPCs() 
    end
    
    if targetMode == "Player" or targetMode == "All" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if not (SilentAimSettings.TeamCheck and player.Team == LocalPlayer.Team) then
                    table.insert(targetNames, player.Name)
                    targetMap[player.Name] = player
                end
            end
        end
    end
    
    if targetMode == "NPC/Bot" or targetMode == "All" then
        for _, npc in ipairs(npcList) do
            if npc and npc.Name and npc.PrimaryPart then
                table.insert(targetNames, npc.Name)
                targetMap[npc.Name] = npc
            end
        end
    end

    Options.TargetSelectorDropdown:SetValues(targetNames, "无")
    lockedTargetObject = nil
end)

local HighlightGroupBox = Tabs.Misc:AddRightGroupbox("hignlight")
HighlightGroupBox:AddToggle("HighlightToggle", { Text = "Enableb highlight", Default = SilentAimSettings.HighlightEnabled }):AddColorPicker("HighlightColorPicker", { Default = SilentAimSettings.HighlightColor, Title = "高亮颜色" })
Toggles.HighlightToggle:OnChanged(function(Value) SilentAimSettings.HighlightEnabled = Value end)
Options.HighlightColorPicker:OnChanged(function(Value) SilentAimSettings.HighlightColor = Value end)
HighlightGroupBox:AddToggle("HighlightRainbowToggle", { Text = "Rainbow", Default = SilentAimSettings.HighlightRainbowEnabled }):OnChanged(function(Value) SilentAimSettings.HighlightRainbowEnabled = Value end)

local NameTargetingGroup = Tabs.Misc:AddRightGroupbox("Name Lock")
NameTargetingGroup:AddToggle("EnableNameTargetingToggle", { Text = "Enableb Name Lock", Default = SilentAimSettings.EnableNameTargeting }):OnChanged(function(Value)
    SilentAimSettings.EnableNameTargeting = Value
end)
NameTargetingGroup:AddInput("TargetName1Input", { Text = "TargetName 1", Default = "", PlaceholderText = "Enter the name of NPC or robot or player" }):OnChanged(function(Value)
    SilentAimSettings.TargetName1 = Value
end)
NameTargetingGroup:AddInput("TargetName2Input", { Text = "TargetName 2", Default = "", PlaceholderText = "Enter the name of NPC or bot or player" }):OnChanged(function(Value)
    SilentAimSettings.TargetName2 = Value
end)
NameTargetingGroup:AddInput("TargetName3Input", { Text = "TargetName 3", Default = "", PlaceholderText = "Enter the name of NPC or robot or player" }):OnChanged(function(Value)
    SilentAimSettings.TargetName3 = Value
end)

local EntertainmentGroup = Tabs.Misc:AddRightGroupbox("Fun")
local spinThread = nil
local spinEnabled = false
local spinSpeed = math.rad(10)
local function spinCharacter()
    while spinEnabled and task.wait() do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, spinSpeed, 0)
        else
            break
        end
    end
    spinThread = nil
end
EntertainmentGroup:AddToggle("SpinToggle", { Text = "Spin", Default = false }):OnChanged(function(value)
    spinEnabled = value
    if spinEnabled and not spinThread then
        spinThread = coroutine.create(spinCharacter)
        coroutine.resume(spinThread)
    end
end)
EntertainmentGroup:AddSlider("SpinSpeedSlider", { Text = "SpinSpeed", Default = 10, Min = 1, Max = 100, Rounding = 0 }):OnChanged(function(value)
    spinSpeed = math.rad(value)
end)

local BlacklistGroup = Tabs.Misc:AddRightGroupbox("Blacklist management")

-- This hidden option will store the blacklist data for saving and loading
local blacklistDataOption = BlacklistGroup:AddInput("BlacklistData", {
    Text = "Blacklist Internal Data",
    Default = "[]" -- Default to an empty JSON array string
})
blacklistDataOption.Visible = false -- Hide this from the user interface

-- This function updates the hidden data option whenever the blacklist is changed
local function updateBlacklistData()
    local jsonString = HttpService:JSONEncode(SilentAimSettings.BlacklistedNames)
    blacklistDataOption:SetValue(jsonString)
end

BlacklistGroup:AddInput("BlacklistNameInput", { Text = "Name", PlaceholderText = "An exact name is required" })

BlacklistGroup:AddButton("Add to the blacklist", function()
    local name = Options.BlacklistNameInput.Value
    if name and name ~= "" and not isBlacklisted(name) then
        table.insert(SilentAimSettings.BlacklistedNames, name)
        Options.BlacklistDropdown:SetValues(SilentAimSettings.BlacklistedNames)
        Options.BlacklistNameInput:SetValue("")
        updateBlacklistData() -- Update the data for saving
    end
end)

BlacklistGroup:AddDropdown("BlacklistDropdown", { Text = "blacklist", Values = SilentAimSettings.BlacklistedNames or {} })

BlacklistGroup:AddButton("Remove from the blacklist", function()
    local selectedName = Options.BlacklistDropdown.Value
    if selectedName then
        for i, name in ipairs(SilentAimSettings.BlacklistedNames) do
            if name == selectedName then
                table.remove(SilentAimSettings.BlacklistedNames, i)
                break
            end
        end
        Options.BlacklistDropdown:SetValues(SilentAimSettings.BlacklistedNames)
        updateBlacklistData() -- Update the data for saving
    end
end)

-- This function runs when a config is loaded, restoring the blacklist
blacklistDataOption:OnChanged(function(jsonString)
    if not jsonString or jsonString == "" then jsonString = "[]" end
    local success, decoded = pcall(HttpService.JSONDecode, HttpService, jsonString)
    if success and type(decoded) == 'table' then
        SilentAimSettings.BlacklistedNames = decoded
        Options.BlacklistDropdown:SetValues(SilentAimSettings.BlacklistedNames)
    end
end)


FOVCircleGui.Enabled = Toggles.FOVVisibleToggle.Value
FOVStroke.Color = Options.FOVColorPicker.Value
FOVCircleFrame.Size = UDim2.fromOffset(Options.FOVRadiusSlider.Value * 2, Options.FOVRadiusSlider.Value * 2)
IndependentPanelFrame.Draggable = not SilentAimSettings.IndependentPanelPinned

task.spawn(function()
    while task.wait(2) do
        if SilentAimSettings.TargetMode == "NP/BotC" or SilentAimSettings.TargetMode == "All" then
            updateNPCs()
        end
    end
end)

local lastHealthValues = {}
local damageIndicators = {}
local DAMAGE_INDICATOR_FADE_TIME = 1

local pos = SilentAimSettings.IndependentPanelPosition:split(",")
IndependentPanelFrame.Position = UDim2.fromOffset(tonumber(pos[1]), tonumber(pos[2]))

local lastTargetCharacter = nil
local lockedRandomPart = nil

resume(create(function()
    RenderStepped:Connect(function()
        if SilentAimSettings.IndicatorRotationEnabled then currentRotationAngle = (currentRotationAngle + (SilentAimSettings.IndicatorRotationSpeed / 50)) % (math.pi * 2) end
        if SilentAimSettings.IndicatorRainbowEnabled or SilentAimSettings.HighlightRainbowEnabled then currentIndicatorHue = (currentIndicatorHue + (SilentAimSettings.IndicatorRainbowSpeed / 200)) % 1 end
        
        local isEnabled = Toggles.EnabledToggle.Value
        currentTargetPart = nil
        local currentTargetCharacter = nil

        if isEnabled then
            if lockedTargetObject then
                 if lockedTargetObject.Parent and not isBlacklisted(lockedTargetObject.Name) then
                    if lockedTargetObject:IsA("Player") then
                        currentTargetCharacter = lockedTargetObject.Character
                    elseif lockedTargetObject:IsA("Model") then
                        currentTargetCharacter = lockedTargetObject
                    end
                else
                    lockedTargetObject = nil 
                    Options.TargetSelectorDropdown:SetValue("无")
                end
            else
                local targetMode = SilentAimSettings.TargetMode
                local playerTarget, npcTarget
                if targetMode == "Player" or targetMode == "All" then playerTarget = getClosestPlayer() end
                if targetMode == "NPC/Bot" or targetMode == "All" then npcTarget = getNPCTarget() end

                if playerTarget and npcTarget then
                    local priority = SilentAimSettings.PriorityMode
                    if priority == "Lowest Health" then
                        local pHumanoid = playerTarget:FindFirstChildOfClass("Humanoid")
                        local nHumanoid = npcTarget:FindFirstChildOfClass("Humanoid")
                        currentTargetCharacter = (pHumanoid and nHumanoid and pHumanoid.Health <= nHumanoid.Health) and playerTarget or npcTarget
                    else
                        local pDist = (LocalPlayer.Character.HumanoidRootPart.Position - playerTarget.HumanoidRootPart.Position).Magnitude
                        local nDist = (LocalPlayer.Character.HumanoidRootPart.Position - npcTarget.HumanoidRootPart.Position).Magnitude
                        currentTargetCharacter = pDist < nDist and playerTarget or npcTarget
                    end
                else
                    currentTargetCharacter = playerTarget or npcTarget
                end
            end
        end

        if currentTargetCharacter ~= lastTargetCharacter then
            lockedRandomPart = nil 
        end
        lastTargetCharacter = currentTargetCharacter

        if currentTargetCharacter then
            local humanoid = currentTargetCharacter:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                if lockedTargetObject and lockedTargetObject:IsA("Model") and lockedTargetObject == currentTargetCharacter then
                    lockedTargetObject = nil
                    Options.TargetSelectorDropdown:SetValue("None")
                end
                currentTargetCharacter = nil
                currentTargetPart = nil
            else
                if SilentAimSettings.LeakAndHitMode then
                    for _, part in ipairs(currentTargetCharacter:GetDescendants()) do
                        if part:IsA("BasePart") and part.Parent == currentTargetCharacter then
                            if isPartVisible(part) then
                                currentTargetPart = part
                                break
                            end
                        end
                    end
                else
                    local targetPartName = SilentAimSettings.TargetPart
                    if targetPartName == "Random" then
                        if not lockedRandomPart or not lockedRandomPart.Parent or lockedRandomPart.Parent ~= currentTargetCharacter then
                            lockedRandomPart = currentTargetCharacter[ValidTargetParts[math.random(1, #ValidTargetParts)]]
                        end
                        currentTargetPart = lockedRandomPart
                    else
                        currentTargetPart = currentTargetCharacter:FindFirstChild(targetPartName) or currentTargetCharacter:FindFirstChild("HumanoidRootPart")
                    end
                end
            end
        end

        if isEnabled and currentTargetPart and SilentAimSettings.ShowDamageNotifier then
            local humanoid = currentTargetPart.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local currentHealth = humanoid.Health
                local lastHealth = lastHealthValues[humanoid]
                if lastHealth and currentHealth < lastHealth then
                    local damage = math.floor(lastHealth - currentHealth)
                    if damage > 0 then
                        local indicator = {}; indicator.Created = tick(); indicator.Position, _ = getPositionOnScreen(currentTargetPart.Position)
                        indicator.TextObject = Drawing.new("Text")
                        indicator.TextObject.Font = Drawing.Fonts.Monospace; indicator.TextObject.Text = string.format("-%d", damage)
                        indicator.TextObject.Color = Color3.fromRGB(255, 50, 50); indicator.TextObject.Size = 20
                        indicator.TextObject.Center = true; indicator.TextObject.Outline = true
                        table.insert(damageIndicators, indicator)
                    end
                end
                lastHealthValues[humanoid] = currentHealth
            end
        end

        for i = #damageIndicators, 1, -1 do
            local indicator = damageIndicators[i]; local age = tick() - indicator.Created
            if age > DAMAGE_INDICATOR_FADE_TIME then
                indicator.TextObject:Remove(); table.remove(damageIndicators, i)
            else
                local progress = age / DAMAGE_INDICATOR_FADE_TIME
                indicator.TextObject.Position = indicator.Position - Vector2.new(0, progress * 40)
                indicator.TextObject.Transparency = progress; indicator.TextObject.Visible = true
            end
        end

        hideAllVisuals()
        
        if currentHighlight and (not currentTargetCharacter or not SilentAimSettings.HighlightEnabled) then
            currentHighlight:Destroy()
            currentHighlight = nil
        end

        if isEnabled and currentTargetCharacter and SilentAimSettings.HighlightEnabled then
             if not currentHighlight then
                currentHighlight = Instance.new("Highlight")
                currentHighlight.Parent = currentTargetCharacter
            end
            currentHighlight.Adornee = currentTargetCharacter
            currentHighlight.Enabled = true
            currentHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            if SilentAimSettings.HighlightRainbowEnabled then
                local rainbowColor = Color3.fromHSV(currentIndicatorHue, 1, 1)
                currentHighlight.FillColor = rainbowColor
                currentHighlight.OutlineColor = rainbowColor
                currentHighlight.FillTransparency = 0.5
                currentHighlight.OutlineTransparency = 0
            else
                currentHighlight.FillColor = SilentAimSettings.HighlightColor
                currentHighlight.OutlineColor = SilentAimSettings.HighlightColor
                currentHighlight.FillTransparency = 0.5
                currentHighlight.OutlineTransparency = 0
            end
        end

        if isEnabled and currentTargetPart then
            local RootToViewportPoint, IsOnScreen = getPositionOnScreen(currentTargetPart.Position)

            if IsOnScreen and Toggles.ShowTargetToggle.Value then
                local indicatorRadius = SilentAimSettings.TargetIndicatorRadius
                local indicatorStyle = Options.IndicatorStyleDropdown.Value
                local finalIndicatorColor; local isTargetVisible = isPartVisible(currentTargetPart)
                if isTargetVisible then finalIndicatorColor = Color3.fromRGB(0, 255, 0); indicatorRadius = indicatorRadius * 0.6
                elseif SilentAimSettings.IndicatorRainbowEnabled then finalIndicatorColor = Color3.fromHSV(currentIndicatorHue, 1, 1)
                else finalIndicatorColor = Options.TargetIndicatorColorPicker.Value end
                
                if indicatorStyle == "Circle" then
                    target_indicator_circle.Visible = true; target_indicator_circle.Color = finalIndicatorColor; target_indicator_circle.Radius = indicatorRadius; target_indicator_circle.Position = RootToViewportPoint
                elseif indicatorStyle == "Triangle" then
                    local points = getPolygonPoints(RootToViewportPoint, indicatorRadius, 3)
                    for i = 1, 3 do local line = target_indicator_lines[i]; line.Visible = true; line.Color = finalIndicatorColor; line.From = points[i]; line.To = points[i % 3 + 1] end
                elseif indicatorStyle == "Pentagram" then
                    local points = getPolygonPoints(RootToViewportPoint, indicatorRadius, 5)
                    local pentagram_order = {1, 3, 5, 2, 4}
                    for i = 1, 5 do local line = target_indicator_lines[i]; line.Visible = true; line.Color = finalIndicatorColor; line.From = points[pentagram_order[i]]; line.To = points[pentagram_order[i % 5 + 1]] end
                elseif indicatorStyle == "Cross" then
                    local length = SilentAimSettings.CrosshairLength
                    local gap = SilentAimSettings.CrosshairGap
                    local center = RootToViewportPoint
                    local rotation = SilentAimSettings.IndicatorRotationEnabled and currentRotationAngle or 0
                    local cos, sin = math.cos(rotation), math.sin(rotation)

                    local function rotate(v)
                        return Vector2.new(v.X * cos - v.Y * sin, v.X * sin + v.Y * cos)
                    end

                    local points = {
                        {From = rotate(Vector2.new(0, -length)) + center, To = rotate(Vector2.new(0, -gap)) + center},
                        {From = rotate(Vector2.new(0, length)) + center, To = rotate(Vector2.new(0, gap)) + center},
                        {From = rotate(Vector2.new(-length, 0)) + center, To = rotate(Vector2.new(-gap, 0)) + center},
                        {From = rotate(Vector2.new(length, 0)) + center, To = rotate(Vector2.new(gap, 0)) + center}
                    }

                    for i = 1, 4 do
                        target_indicator_lines[i].Visible = true
                        target_indicator_lines[i].Color = finalIndicatorColor
                        target_indicator_lines[i].From = points[i].From
                        target_indicator_lines[i].To = points[i].To
                    end
                end
            end

            local showAnyInfo = Toggles.ShowTargetNameToggle.Value or Toggles.ShowTargetHealthToggle.Value or Toggles.ShowTargetDistanceToggle.Value or Toggles.ShowTargetCategoryToggle.Value  
            if showAnyInfo then
                local player = Players:GetPlayerFromCharacter(currentTargetCharacter)
                local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = currentTargetCharacter:FindFirstChildOfClass("Humanoid")
                if humanoid and localRoot then
                    local targetName = player and player.DisplayName or currentTargetCharacter.Name
                    local health = math.floor(humanoid.Health)
                    local maxHealth = humanoid.MaxHealth
                    local dist = math.floor((localRoot.Position - currentTargetPart.Position).Magnitude)
                    local category = getTargetCategory(currentTargetCharacter)
                    local infoStyle = SilentAimSettings.TargetInfoStyle
                    
                    if infoStyle == "Independent panel" then
                        IndependentPanelFrame.Visible = true
                        independent_panel_texts.Name.Visible = Toggles.ShowTargetNameToggle.Value
                        independent_panel_texts.Health.Visible = Toggles.ShowTargetHealthToggle.Value
                        independent_panel_texts.Distance.Visible = Toggles.ShowTargetDistanceToggle.Value
                        independent_panel_texts.Category.Visible = Toggles.ShowTargetCategoryToggle.Value
                        if Toggles.ShowTargetNameToggle.Value then independent_panel_texts.Name.Text = "Target: " .. targetName end
                        if Toggles.ShowTargetHealthToggle.Value then independent_panel_texts.Health.Text = string.format("Health: %d", health) end
                        if Toggles.ShowTargetDistanceToggle.Value then independent_panel_texts.Distance.Text = string.format("Distance: %dm", dist) end
                        if Toggles.ShowTargetCategoryToggle.Value then independent_panel_texts.Category.Text = "Classification: " .. category end
                    elseif infoStyle == "panel" and IsOnScreen then
                        local indicatorRadius = SilentAimSettings.TargetIndicatorRadius
                        local linesDrawn = 0; local lineHeight = 15; local infoPos = RootToViewportPoint + Vector2.new(indicatorRadius + 5, -22)
                        if Toggles.ShowTargetNameToggle.Value then local textObj = panel_info_texts.Name; textObj.Text = targetName; textObj.Position = infoPos + Vector2.new(5, 5 + (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetHealthToggle.Value then local textObj = panel_info_texts.Health; textObj.Text = string.format("Health: %d", health); textObj.Position = infoPos + Vector2.new(5, 5 + (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetDistanceToggle.Value then local textObj = panel_info_texts.Distance; textObj.Text = string.format("Distance: %dm", dist); textObj.Position = infoPos + Vector2.new(5, 5 + (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetCategoryToggle.Value then local textObj = panel_info_texts.Category; textObj.Text = "Classification: " .. category; textObj.Position = infoPos + Vector2.new(5, 5 + (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if linesDrawn > 0 then panel_info_bg.Position = infoPos; panel_info_bg.Size = Vector2.new(120, 10 + (linesDrawn * lineHeight)); panel_info_bg.Visible = true end
                    elseif infoStyle == "Top" and IsOnScreen then
                        local indicatorRadius = SilentAimSettings.TargetIndicatorRadius
                        local linesDrawn = 0; local lineHeight = 15; local base_y = RootToViewportPoint.Y - indicatorRadius - 10
                        if Toggles.ShowTargetNameToggle.Value then local textObj = overhead_info_texts.Name; textObj.Text = string.format("[%s]", targetName); textObj.Position = Vector2.new(RootToViewportPoint.X, base_y - (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetHealthToggle.Value then local textObj = overhead_info_texts.Health; textObj.Text = string.format("[%d]", health); textObj.Position = Vector2.new(RootToViewportPoint.X, base_y - (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetDistanceToggle.Value then local textObj = overhead_info_texts.Distance; textObj.Text = string.format("[%dm]", dist); textObj.Position = Vector2.new(RootToViewportPoint.X, base_y - (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                        if Toggles.ShowTargetCategoryToggle.Value then local textObj = overhead_info_texts.Category; textObj.Text = string.format("[%s]", category); textObj.Position = Vector2.new(RootToViewportPoint.X, base_y - (linesDrawn * lineHeight)); textObj.Visible = true; linesDrawn = linesDrawn + 1 end
                    end
                end
            end
        elseif isEnabled then
            local infoStyle = SilentAimSettings.TargetInfoStyle
            if infoStyle == "Independent panel" then
                IndependentPanelFrame.Visible = true
                independent_panel_texts.Name.Visible = true
                independent_panel_texts.Health.Visible = true
                independent_panel_texts.Distance.Visible = false
                independent_panel_texts.Category.Visible = false
                independent_panel_texts.Name.Text = "State: AutoLocking.."
                independent_panel_texts.Health.Text = "Target: None"
            end
        end

        if Toggles.ShowTracerToggle.Value and isEnabled and currentTargetPart then
            local targetHead = currentTargetCharacter and currentTargetCharacter:FindFirstChild("Head")
            local tracerTargetPosition = (targetHead and targetHead.Position) or currentTargetPart.Position
            local y_offset = SilentAimSettings.Tracer_Y_Offset
            local finalTracerPosition = tracerTargetPosition - Vector3.new(0, y_offset, 0)
            local targetScreenPos, IsOnScreen = getPositionOnScreen(finalTracerPosition)
            tracer_line.Visible = IsOnScreen
            if IsOnScreen then tracer_line.From = Camera.ViewportSize / 2; tracer_line.To = targetScreenPos; tracer_line.Color = Options.TracerColorPicker.Value end
        else
            tracer_line.Visible = false
        end
        
        if Toggles.FOVVisibleToggle.Value then
            if Toggles.FixedFOVToggle.Value then FOVCircleFrame.Position = UDim2.fromScale(0.5, 0.5) else local mousePos = GetMouseLocation(UserInputService); FOVCircleFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y) end
        end
    end)
end))

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    if SilentAimSettings.Enabled and not checkcaller() and CalculateChance(SilentAimSettings.HitChance) and currentTargetPart then
        local currentMethod = SilentAimSettings.SilentAimMethod
        if Method == "FindPartOnRayWithIgnoreList" and currentMethod == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                if SilentAimSettings.Wallbang then
                    return currentTargetPart, currentTargetPart.Position, currentTargetPart.CFrame.LookVector, currentTargetPart.Material
                end
                local A_Ray = Arguments[2]
                Arguments[2] = Ray.new(A_Ray.Origin, getDirection(A_Ray.Origin, currentTargetPart.Position))
                return oldNamecall(unpack(Arguments))
            end
        elseif Method == "FindPartOnRayWithWhitelist" and currentMethod == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                if SilentAimSettings.Wallbang then
                    return currentTargetPart, currentTargetPart.Position, currentTargetPart.CFrame.LookVector, currentTargetPart.Material
                end
                local A_Ray = Arguments[2]
                Arguments[2] = Ray.new(A_Ray.Origin, getDirection(A_Ray.Origin, currentTargetPart.Position))
                return oldNamecall(unpack(Arguments))
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and currentMethod:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                if SilentAimSettings.Wallbang then
                    return currentTargetPart, currentTargetPart.Position, currentTargetPart.CFrame.LookVector, currentTargetPart.Material
                end
                local A_Ray = Arguments[2]
                Arguments[2] = Ray.new(A_Ray.Origin, getDirection(A_Ray.Origin, currentTargetPart.Position))
                return oldNamecall(unpack(Arguments))
            end
        elseif Method == "Raycast" and currentMethod == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                if SilentAimSettings.Wallbang then
                    local origin = Arguments[2]
                    local direction = getDirection(origin, currentTargetPart.Position)
                    local wallbangParams = RaycastParams.new()
                    wallbangParams.FilterType = Enum.RaycastFilterType.Include
                    wallbangParams.FilterDescendantsInstances = {currentTargetPart.Parent}
                    local newArgs = {self, origin, direction, wallbangParams}
                    return oldNamecall(unpack(newArgs))
                end
                Arguments[3] = getDirection(Arguments[2], currentTargetPart.Position)
                return oldNamecall(unpack(Arguments))
            end
        elseif (Method == "ScreenPointToRay" or Method == "ViewportPointToRay") and currentMethod == Method and self == Camera then
            local origin = Camera.CFrame.Position
            local direction = (currentTargetPart.Position - origin).Unit
            return Ray.new(origin, direction)
        end
    end
    return oldNamecall(...)
end))

local oldIndex
local oldRayNew
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and SilentAimSettings.Enabled and SilentAimSettings.SilentAimMethod == "Mouse.Hit/Target" then
        if currentTargetPart then
            if Index == "Target" or Index == "target" then
                return currentTargetPart
            elseif Index == "Hit" or Index == "hit" then
                return (SilentAimSettings.MouseHitPrediction and (currentTargetPart.CFrame + (currentTargetPart.Velocity * currentTargetPart.Velocity.magnitude * SilentAimSettings.MouseHitPredictionAmount))) or currentTargetPart.CFrame
            elseif Index == "X" or Index == "x" then
                return self.X
            elseif Index == "Y" or Index == "y" then
                return self.Y
            elseif Index == "UnitRay" then
                return Ray.new(self.Origin, (self.Hit.p - self.Origin.p).Unit)
            end
        end
    end
    return oldIndex(self, Index)
end))

oldRayNew = hookfunction(Ray.new, newcclosure(function(origin, direction)
    if SilentAimSettings.Enabled and SilentAimSettings.SilentAimMethod == "Ray" and currentTargetPart and not checkcaller() and CalculateChance(SilentAimSettings.HitChance) then
        local newDirectionVector = getDirection(origin, currentTargetPart.Position)
        return oldRayNew(origin, newDirectionVector)
    end
    return oldRayNew(origin, direction)
end))

Library:OnUnload(function()
    FOVCircleGui:Destroy()
    if IndependentPanelGui then
        IndependentPanelGui:Destroy()
    end
    if currentHighlight then
        currentHighlight:Destroy()
    end
    hideAllVisuals()
    oldNamecall:UnHook()
    oldIndex:UnHook()
    oldRayNew:UnHook()
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("UniversalSilentAim/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
