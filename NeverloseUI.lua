--[[
    Neverlose 风格 UI 库 (Roblox) v3.0
    高度还原 CS:GO Neverlose 客户端界面

    特性:
      - 顶部全宽栏: Logo + 用户头像/名称 + 设置/关闭按钮
      - 窗口软阴影
      - 左侧边栏: 搜索框 + 图标 Tab + 配置按钮
      - 内容区: 页面标题 + 滚动列表
      - 水印: 右上角 neverlose | fps | ping
      - 通知系统
      - 组件: Toggle / Slider / Dropdown / Button / ColorPicker(含透明度) / Keybind / Label / Section / Divider / InputBox

    用法:
        local NL = loadstring(game:HttpGet("托管地址"))()
        local Window = NL:CreateWindow("neverlose")
        local Tab = Window:CreateTab("Rage", "rbxassetid://6031075931")
        Tab:CreateSection("主要")
        Tab:CreateToggle("启用自动开火", true, function(s) end)
        Tab:CreateSlider("命中率", 1, 100, 75, function(v) end)
        Tab:CreateColorPicker("方框颜色", Color3.fromRGB(157,78,221), function(c) end)
        NL:Init()
]]

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local Neverlose = {}
Neverlose.__index = Neverlose

--========================== 主题 (Neverlose 配色) ==========================--
local Theme = {
    Background      = Color3.fromRGB(15, 15, 18),   -- 窗口主背景 (近黑)
    BackgroundAlt    = Color3.fromRGB(20, 20, 25),   -- 次背景
    Topbar           = Color3.fromRGB(18, 18, 23),   -- 顶部栏
    Sidebar          = Color3.fromRGB(13, 13, 17),   -- 侧边栏
    SidebarItem     = Color3.fromRGB(0, 0, 0),      -- 侧边栏项(透明效果靠 hover)
    SidebarHover    = Color3.fromRGB(30, 30, 38),   -- 悬停
    SidebarActive   = Color3.fromRGB(26, 26, 33),   -- 选中
    Content          = Color3.fromRGB(17, 17, 22),   -- 内容区
    Element          = Color3.fromRGB(24, 24, 31),   -- 元素背景
    ElementHover    = Color3.fromRGB(32, 32, 41),   -- 元素悬停
    Accent           = Color3.fromRGB(139, 92, 246),  -- 紫色强调 (#8B5CF6)
    AccentBright    = Color3.fromRGB(167, 139, 250),  -- 亮紫
    AccentDark      = Color3.fromRGB(91, 33, 182),   -- 深紫
    Text             = Color3.fromRGB(228, 228, 231),  -- 主文字
    TextDim          = Color3.fromRGB(113, 113, 122),  -- 次要文字
    TextFaint       = Color3.fromRGB(82, 82, 91),   -- 更暗文字
    ToggleOff       = Color3.fromRGB(39, 39, 45),   -- 开关关闭底色
    Border           = Color3.fromRGB(39, 39, 46),   -- 边框
    BorderBright    = Color3.fromRGB(55, 55, 65),   -- 亮边框
    Stroke           = Color3.fromRGB(45, 45, 55),
    Track            = Color3.fromRGB(28, 28, 35),   -- 滑块轨道
    Success          = Color3.fromRGB(34, 197, 94),
    Danger           = Color3.fromRGB(239, 68, 68),
}

--========================== 工具函数 ==========================--
local function Round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function Gradient(parent, colorSeq, rot)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq
    g.Rotation = rot or 90
    g.Parent = parent
    return g
end

local function MakeText(parent, text, size, color, font, alignX, alignY)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Position = UDim2.new(0, 0, 0, 0)
    l.Text = text or ""
    l.TextColor3 = color or Theme.Text
    l.TextSize = size or 13
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = alignX or Enum.TextXAlignment.Left
    l.TextYAlignment = alignY or Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

-- 软阴影 (使用 ImageLabel 标准阴影贴图, 失败也不影响外观)
local function ApplyShadow(parent, size)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, (size or 30), 1, (size or 30))
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end

-- 圆形头像
local function MakeAvatar(parent, userId, size)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, size, 0, size)
    img.BackgroundColor3 = Theme.Element
    img.BorderSizePixel = 0
    img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150"
    img.Parent = parent
    Round(img, size / 2)
    return img
end

--========================== 水印 ==========================--
local Watermark = {}
function Watermark:Create()
    local wm = Instance.new("Frame")
    wm.Name = "Watermark"
    wm.Size = UDim2.new(0, 220, 0, 28)
    wm.Position = UDim2.new(1, -232, 0, 12)
    wm.BackgroundColor3 = Theme.Background
    wm.BackgroundTransparency = 0.1
    wm.BorderSizePixel = 0
    Round(wm, 6)
    Stroke(wm, Theme.Stroke, 1, 0.3)
    -- 内容
    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Padding = UDim.new(0, 8)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = wm
    Padding(wm, 0, 0, 10, 10)
    local function chip(text, color)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.AutomaticSize = Enum.AutomaticSize.X
        l.Size = UDim2.new(0, 0, 0, 16)
        l.Text = text
        l.TextColor3 = color or Theme.TextDim
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.Parent = wm
        return l
    end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.BackgroundColor3 = Theme.Accent
    dot.BorderSizePixel = 0
    dot.Parent = wm
    Round(dot, 3)
    local logo = chip("neverlose", Theme.Text)
    local sep1 = chip("·", Theme.TextFaint)
    local fps = chip("0 fps", Theme.TextDim)
    local sep2 = chip("·", Theme.TextFaint)
    local ping = chip("0 ms", Theme.TextDim)
    -- 更新 FPS / Ping
    local frames = 0
    local last = tick()
    RunService.RenderStepped:Connect(function()
        if not wm.Parent then return end
        frames = frames + 1
        local now = tick()
        if now - last >= 0.5 then
            fps.Text = string.format("%d fps", frames * 2)
            local p = Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem.DataStats
            local ms = 0
            pcall(function()
                ms = math.floor(Stats.Network.ServerStatsItem["Data I Kbps"].Value)
            end)
            ping.Text = string.format("%d ms", ms)
            frames = 0
            last = now
        end
    end)
    return wm
end

--========================== 通知系统 ==========================--
local Notifications = {}
function Notifications:Create()
    local holder = Instance.new("Frame")
    holder.Name = "Notifications"
    holder.Size = UDim2.new(0, 300, 1, 0)
    holder.Position = UDim2.new(1, -312, 0, 50)
    holder.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = holder
    local obj = { holder = holder, count = 0 }
    function obj:Push(title, desc, duration, notifType)
        local n = Instance.new("Frame")
        n.Size = UDim2.new(1, 0, 0, 0)
        n.BackgroundColor3 = Theme.Background
        n.BackgroundTransparency = 0.05
        n.BorderSizePixel = 0
        n.Parent = holder
        Round(n, 6)
        Stroke(n, Theme.Stroke, 1, 0.2)
        local accentColor = Theme.Accent
        if notifType == "success" then accentColor = Theme.Success
        elseif notifType == "danger" then accentColor = Theme.Danger end
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.BackgroundColor3 = accentColor
        bar.BorderSizePixel = 0
        bar.Parent = n
        Round(bar, 2)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(1, -20, 0, 18)
        t.Position = UDim2.new(0, 14, 0, 8)
        t.Text = title or "Notification"
        t.TextColor3 = Theme.Text
        t.TextSize = 13
        t.Font = Enum.Font.GothamMedium
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = n
        local d = Instance.new("TextLabel")
        d.BackgroundTransparency = 1
        d.Size = UDim2.new(1, -20, 0, 16)
        d.Position = UDim2.new(0, 14, 0, 28)
        d.Text = desc or ""
        d.TextColor3 = Theme.TextDim
        d.TextSize = 11
        d.Font = Enum.Font.Gotham
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = n
        local h = desc and desc ~= "" and 60 or 40
        n.Size = UDim2.new(1, 0, 0, 0)
        n.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, h),
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
        task.delay(duration or 3, function()
            if not n.Parent then return end
            TweenService:Create(n, TweenInfo.new(0.25), {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
            local tw = TweenService:Create(t, TweenInfo.new(0.25), {TextTransparency = 1})
            local dw = TweenService:Create(d, TweenInfo.new(0.25), {TextTransparency = 1})
            local bw = TweenService:Create(bar, TweenInfo.new(0.25), {BackgroundTransparency = 1})
            tw:Play(); dw:Play(); bw:Play()
            task.wait(0.3)
            n:Destroy()
        end)
    end
    return obj
end

--========================== 创建主窗口 ==========================--
function Neverlose:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeverloseUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self._gui = ScreenGui

    -- 水印
    self._watermark = Watermark:Create()
    self._watermark.Parent = ScreenGui

    -- 通知
    self._notifs = Notifications:Create()
    self._notifs.holder.Parent = ScreenGui

    -- 窗口外层 (用于阴影)
    local WindowHolder = Instance.new("Frame")
    WindowHolder.Name = "WindowHolder"
    WindowHolder.Size = UDim2.new(0, 720, 0, 460)
    WindowHolder.Position = UDim2.new(0.5, -360, 0.5, -230)
    WindowHolder.BackgroundTransparency = 1
    WindowHolder.Parent = ScreenGui

    -- 窗口主体
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(1, 0, 1, 0)
    Window.BackgroundColor3 = Theme.Background
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = WindowHolder
    Round(Window, 8)
    Stroke(Window, Theme.Stroke, 1)
    self._window = Window

    -- 阴影
    ApplyShadow(WindowHolder, 30)

    -- 拖拽
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        WindowHolder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                          startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    local function onDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = WindowHolder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end
    local function onMove(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end
    UserInput.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    -- ===== 顶部栏 (全宽) =====
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 48)
    Topbar.BackgroundColor3 = Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Window
    -- 顶部栏底部细线
    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, 0)
    TopLine.BackgroundColor3 = Theme.Border
    TopLine.BorderSizePixel = 0
    TopLine.Parent = Topbar

    -- 拖拽绑定到顶部栏
    Topbar.InputBegan:Connect(onDrag)
    Topbar.InputChanged:Connect(onMove)

    -- Logo (左)
    local LogoFrame = Instance.new("Frame")
    LogoFrame.Size = UDim2.new(0, 200, 1, 0)
    LogoFrame.BackgroundTransparency = 1
    LogoFrame.Parent = Topbar
    local LogoIcon = Instance.new("Frame")
    LogoIcon.Size = UDim2.new(0, 22, 0, 22)
    LogoIcon.Position = UDim2.new(0, 16, 0.5, -11)
    LogoIcon.BackgroundColor3 = Theme.Accent
    LogoIcon.BorderSizePixel = 0
    LogoIcon.Parent = LogoFrame
    Round(LogoIcon, 6)
    Gradient(LogoIcon, ColorSequence.new(Theme.AccentBright, Theme.AccentDark), 45)
    local LogoIconInner = Instance.new("TextLabel")
    LogoIconInner.BackgroundTransparency = 1
    LogoIconInner.Size = UDim2.new(1, 0, 1, 0)
    LogoIconInner.Text = "N"
    LogoIconInner.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoIconInner.TextSize = 13
    LogoIconInner.Font = Enum.Font.GothamBold
    LogoIconInner.Parent = LogoIcon
    local LogoText = MakeText(LogoFrame, "neverlose", 15, Theme.Text, Enum.Font.GothamBold)
    LogoText.Size = UDim2.new(1, -48, 1, 0)
    LogoText.Position = UDim2.new(0, 46, 0, 0)

    -- 右侧: 用户区 + 控制按钮
    local ProfileArea = Instance.new("Frame")
    ProfileArea.Size = UDim2.new(0, 200, 1, 0)
    ProfileArea.Position = UDim2.new(1, -200, 0, 0)
    ProfileArea.BackgroundTransparency = 1
    ProfileArea.Parent = Topbar
    -- 用户名
    local UserName = MakeText(ProfileArea, LocalPlayer.Name, 12, Theme.Text, Enum.Font.GothamMedium)
    UserName.Size = UDim2.new(0, 120, 1, 0)
    UserName.Position = UDim2.new(0, 8, 0, 0)
    UserName.TextXAlignment = Enum.TextXAlignment.Right
    -- 头像
    local Avatar = MakeAvatar(ProfileArea, LocalPlayer.UserId, 28)
    Avatar.Position = UDim2.new(1, -96, 0.5, -14)
    -- 分隔线
    local Sep = Instance.new("Frame")
    Sep.Size = UDim2.new(0, 1, 0, 20)
    Sep.Position = UDim2.new(1, -60, 0.5, -10)
    Sep.BackgroundColor3 = Theme.Border
    Sep.BorderSizePixel = 0
    Sep.Parent = ProfileArea
    -- 设置按钮
    local GearBtn = Instance.new("TextButton")
    GearBtn.Size = UDim2.new(0, 28, 0, 28)
    GearBtn.Position = UDim2.new(1, -48, 0.5, -14)
    GearBtn.BackgroundTransparency = 1
    GearBtn.Text = "⚙"
    GearBtn.TextColor3 = Theme.TextDim
    GearBtn.TextSize = 14
    GearBtn.Font = Enum.Font.Gotham
    GearBtn.AutoButtonColor = false
    GearBtn.Parent = ProfileArea
    GearBtn.MouseEnter:Connect(function() GearBtn.TextColor3 = Theme.Text end)
    GearBtn.MouseLeave:Connect(function() GearBtn.TextColor3 = Theme.TextDim end)
    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -20, 0.5, -14)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = ProfileArea
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Danger end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)
    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(WindowHolder, TweenInfo.new(0.2), {Size = UDim2.new(0, 720, 0, 0)}):Play()
        task.wait(0.2)
        ScreenGui:Destroy()
    end)

    -- ===== 侧边栏 =====
    local SidebarWidth = 200
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, SidebarWidth, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Window
    -- 侧边栏右侧细线
    local SideLine = Instance.new("Frame")
    SideLine.Size = UDim2.new(0, 1, 1, 0)
    SideLine.Position = UDim2.new(1, -1, 0, 0)
    SideLine.BackgroundColor3 = Theme.Border
    SideLine.BorderSizePixel = 0
    SideLine.Parent = Sidebar

    -- 搜索框
    local Search = Instance.new("Frame")
    Search.Size = UDim2.new(1, -24, 0, 30)
    Search.Position = UDim2.new(0, 12, 0, 12)
    Search.BackgroundColor3 = Theme.Element
    Search.BorderSizePixel = 0
    Search.Parent = Sidebar
    Round(Search, 6)
    Stroke(Search, Theme.Border, 1)
    local SearchIcon = MakeText(Search, "🔍", 11, Theme.TextFaint, Enum.Font.Gotham)
    SearchIcon.Size = UDim2.new(0, 24, 1, 0)
    SearchIcon.TextXAlignment = Enum.TextXAlignment.Center
    local SearchBox = Instance.new("TextBox")
    SearchBox.BackgroundTransparency = 1
    SearchBox.Size = UDim2.new(1, -34, 1, 0)
    SearchBox.Position = UDim2.new(0, 26, 0, 0)
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = Theme.TextFaint
    SearchBox.Text = ""
    SearchBox.TextColor3 = Theme.Text
    SearchBox.TextSize = 12
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = Search

    -- Tab 列表 (可滚动)
    local TabList = Instance.new("ScrollingFrame")
    TabList.Size = UDim2.new(1, 0, 1, -100)
    TabList.Position = UDim2.new(0, 0, 0, 52)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.Parent = Sidebar
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 2)
    TabListLayout.Parent = TabList
    Padding(TabList, 0, 8, 12, 12)

    -- 侧边栏底部: 配置按钮 + 版本
    local ConfigBtn = Instance.new("TextButton")
    ConfigBtn.Size = UDim2.new(1, -24, 0, 34)
    ConfigBtn.Position = UDim2.new(0, 12, 1, -70)
    ConfigBtn.BackgroundColor3 = Theme.Element
    ConfigBtn.BorderSizePixel = 0
    ConfigBtn.Text = ""
    ConfigBtn.AutoButtonColor = false
    ConfigBtn.Parent = Sidebar
    Round(ConfigBtn, 6)
    Stroke(ConfigBtn, Theme.Border, 1)
    local ConfigIcon = Instance.new("TextLabel")
    ConfigIcon.BackgroundTransparency = 1
    ConfigIcon.Size = UDim2.new(0, 20, 1, 0)
    ConfigIcon.Position = UDim2.new(0, 8, 0, 0)
    ConfigIcon.Text = "📄"
    ConfigIcon.TextSize = 12
    ConfigIcon.Font = Enum.Font.Gotham
    ConfigIcon.Parent = ConfigBtn
    local ConfigLabel = MakeText(ConfigBtn, "Config", 12, Theme.TextDim, Enum.Font.Gotham)
    ConfigLabel.Size = UDim2.new(1, -34, 1, 0)
    ConfigLabel.Position = UDim2.new(0, 30, 0, 0)
    local VersionLabel = MakeText(Sidebar, "v3.0  ·  roblox", 10, Theme.TextFaint, Enum.Font.Gotham)
    VersionLabel.Size = UDim2.new(1, -24, 0, 16)
    VersionLabel.Position = UDim2.new(0, 12, 1, -26)

    -- ===== 内容区 =====
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "Content"
    ContentArea.Size = UDim2.new(1, -SidebarWidth, 1, -48)
    ContentArea.Position = UDim2.new(0, SidebarWidth, 0, 48)
    ContentArea.BackgroundColor3 = Theme.Content
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = Window

    -- 内容头部 (Tab 标题 + 副标题)
    local ContentHeader = Instance.new("Frame")
    ContentHeader.Name = "Header"
    ContentHeader.Size = UDim2.new(1, 0, 0, 48)
    ContentHeader.BackgroundTransparency = 1
    ContentHeader.Parent = ContentArea
    ContentHeader.InputBegan:Connect(onDrag)
    ContentHeader.InputChanged:Connect(onMove)
    local HeaderTitle = MakeText(ContentHeader, title or "Menu", 16, Theme.Text, Enum.Font.GothamBold)
    HeaderTitle.Size = UDim2.new(1, -48, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 20, 0, 0)
    local HeaderSubtitle = MakeText(ContentHeader, "", 11, Theme.TextDim, Enum.Font.Gotham)
    HeaderSubtitle.Size = UDim2.new(1, -48, 0, 14)
    HeaderSubtitle.Position = UDim2.new(0, 20, 0, 30)
    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, -1)
    HeaderLine.BackgroundColor3 = Theme.Border
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = ContentHeader

    -- 页面容器
    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "Pages"
    PageContainer.Size = UDim2.new(1, 0, 1, -48)
    PageContainer.Position = UDim2.new(0, 0, 0, 48)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = ContentArea

    local WindowObj = {
        _tabs = {},
        _tabList = TabList,
        _pageContainer = PageContainer,
        _headerTitle = HeaderTitle,
        _headerSubtitle = HeaderSubtitle,
        _currentTab = nil,
    }

    --========================== 创建 Tab ==========================--
    function WindowObj:CreateTab(name, icon, subtitle)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 32)
        TabButton.BackgroundColor3 = Theme.SidebarItem
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabList
        Round(TabButton, 6)
        local TabIcon = Instance.new("ImageLabel")
        TabIcon.BackgroundTransparency = 1
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 10, 0.5, -8)
        TabIcon.Image = icon or ""
        TabIcon.ImageColor3 = Theme.TextDim
        TabIcon.Parent = TabButton
        local TabLabel = MakeText(TabButton, name, 13, Theme.TextDim, Enum.Font.Gotham)
        TabLabel.Size = UDim2.new(1, -38, 1, 0)
        TabLabel.Position = UDim2.new(0, 34, 0, 0)
        -- 左侧选中指示条
        local TabAccent = Instance.new("Frame")
        TabAccent.Size = UDim2.new(0, 0, 0, 16)
        TabAccent.Position = UDim2.new(0, 0, 0.5, -8)
        TabAccent.BackgroundColor3 = Theme.Accent
        TabAccent.BorderSizePixel = 0
        TabAccent.Parent = TabButton
        Round(TabAccent, 2)
        -- 选中背景
        local TabBg = Instance.new("Frame")
        TabBg.Size = UDim2.new(1, 0, 1, 0)
        TabBg.BackgroundColor3 = Theme.SidebarActive
        TabBg.BackgroundTransparency = 1
        TabBg.BorderSizePixel = 0
        TabBg.ZIndex = 0
        TabBg.Parent = TabButton
        Round(TabBg, 6)

        -- 页面
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.BorderBright
        Page.ScrollBarImageTransparency = 0.3
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = PageContainer
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.Parent = Page
        Padding(Page, 18, 18, 18, 18)

        local tab = {
            name = name,
            subtitle = subtitle or "",
            button = TabButton,
            label = TabLabel,
            icon = TabIcon,
            accent = TabAccent,
            bg = TabBg,
            page = Page,
        }
        table.insert(self._tabs, tab)

        TabButton.MouseButton1Click:Connect(function() self:_selectTab(tab) end)
        TabButton.MouseEnter:Connect(function()
            if self._currentTab ~= tab then
                TweenService:Create(TabBg, TweenInfo.new(0.12), {BackgroundTransparency = 0.7}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.12), {TextColor3 = Theme.Text}):Play()
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if self._currentTab ~= tab then
                TweenService:Create(TabBg, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.12), {TextColor3 = Theme.TextDim}):Play()
            end
        end)

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(SearchBox.Text)
            TabButton.Visible = (q == "" or string.find(string.lower(name), q)) and true or false
        end)

        return self:_buildTabApi(tab)
    end

    function WindowObj:_selectTab(tab)
        if self._currentTab == tab then return end
        if self._currentTab then
            local p = self._currentTab
            TweenService:Create(p.label, TweenInfo.new(0.15), {TextColor3 = Theme.TextDim}):Play()
            TweenService:Create(p.icon, TweenInfo.new(0.15), {ImageColor3 = Theme.TextDim}):Play()
            TweenService:Create(p.bg, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            TweenService:Create(p.accent, TweenInfo.new(0.18), {Size = UDim2.new(0, 0, 0, 16)}):Play()
            p.page.Visible = false
        end
        self._currentTab = tab
        TweenService:Create(tab.label, TweenInfo.new(0.15), {TextColor3 = Theme.Text}):Play()
        TweenService:Create(tab.icon, TweenInfo.new(0.15), {ImageColor3 = Theme.Accent}):Play()
        TweenService:Create(tab.bg, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        TweenService:Create(tab.accent, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 16)}):Play()
        tab.page.Visible = true
        self._headerTitle.Text = tab.name
        self._headerSubtitle.Text = tab.subtitle or ""
    end

    --========================== Tab 组件 API ==========================--
    function WindowObj:_buildTabApi(tab)
        local TabApi = {}
        local orderCounter = 0
        local function nextOrder() orderCounter = orderCounter + 1; return orderCounter end

        -- 创建元素行容器 (无标签)
        local function makeRow(height)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, height or 36)
            Row.BackgroundColor3 = Theme.Element
            Row.BorderSizePixel = 0
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            Round(Row, 6)
            Stroke(Row, Theme.Border, 1)
            return Row
        end

        -- 带标签的行
        local function makeLabeledRow(text, height)
            local Row = makeRow(height or 36)
            local Label = MakeText(Row, text, 13, Theme.Text, Enum.Font.Gotham)
            Label.Size = UDim2.new(0.5, 0, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            return Row, Label
        end

        -- Section 分组 (带标题的框)
        function TabApi:CreateSection(title)
            local Section = Instance.new("Frame")
            Section.Size = UDim2.new(1, 0, 0, 30)
            Section.BackgroundTransparency = 1
            Section.LayoutOrder = nextOrder()
            Section.Parent = tab.page
            local Title = MakeText(Section, string.upper(title or ""), 11, Theme.Accent, Enum.Font.GothamBold)
            Title.Size = UDim2.new(1, 0, 1, 0)
            Title.Position = UDim2.new(0, 4, 0, 0)
            -- 底部线
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 1, -6)
            Line.BackgroundColor3 = Theme.Border
            Line.BorderSizePixel = 0
            Line.Parent = Section
            return {}
        end

        -- Toggle 开关
        function TabApi:CreateToggle(text, default, callback)
            local Row, Label = makeLabeledRow(text, 36)
            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(0, 38, 0, 20)
            Toggle.Position = UDim2.new(1, -52, 0.5, -10)
            Toggle.BackgroundColor3 = Theme.ToggleOff
            Toggle.BorderSizePixel = 0
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            Toggle.Parent = Row
            Round(Toggle, 10)
            Stroke(Toggle, Theme.Border, 1)
            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 14, 0, 14)
            Knob.Position = UDim2.new(0, 3, 0.5, -7)
            Knob.BackgroundColor3 = Theme.TextDim
            Knob.BorderSizePixel = 0
            Knob.Parent = Toggle
            Round(Knob, 7)
            local state = default and true or false
            local function set(v)
                state = v and true or false
                local tw1 = TweenService:Create(Toggle, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
                })
                local tw2 = TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Theme.TextDim,
                })
                tw1:Play(); tw2:Play()
                if callback then callback(state) end
            end
            Toggle.MouseButton1Click:Connect(function() set(not state) end)
            set(state)
            return {Set = set, Get = function() return state end}
        end

        -- Slider 滑块
        function TabApi:CreateSlider(text, min, max, default, suffix, callback)
            if type(suffix) == "function" then callback = suffix; suffix = "" end
            local Row = makeRow(50)
            local Label = MakeText(Row, text, 13, Theme.Text, Enum.Font.Gotham)
            Label.Size = UDim2.new(0.6, 0, 0, 22)
            Label.Position = UDim2.new(0, 14, 0, 0)
            local ValueLabel = MakeText(Row, tostring(default) .. (suffix or ""), 12, Theme.Accent, Enum.Font.GothamMedium)
            ValueLabel.Size = UDim2.new(0.4, -28, 0, 22)
            ValueLabel.Position = UDim2.new(0.6, 0, 0, 0)
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -28, 0, 3)
            Track.Position = UDim2.new(0, 14, 0, 34)
            Track.BackgroundColor3 = Theme.Track
            Track.BorderSizePixel = 0
            Track.Parent = Row
            Round(Track, 2)
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Track
            Round(Fill, 2)
            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 10, 0, 10)
            Knob.Position = UDim2.new(1, -5, 0.5, -5)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = Fill
            Round(Knob, 5)
            Stroke(Knob, Theme.AccentDark, 1)
            local value = default
            local dragging = false
            local function update(input)
                local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                ValueLabel.Text = tostring(value) .. (suffix or "")
                if callback then callback(value) end
            end
            Track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end
            end)
            UserInput.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInput.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
            end)
            return {
                Get = function() return value end,
                Set = function(v)
                    value = math.clamp(v, min, max)
                    local rel = (value - min) / (max - min)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    ValueLabel.Text = tostring(value) .. (suffix or "")
                    if callback then callback(value) end
                end
            }
        end

        -- Dropdown 下拉菜单
        function TabApi:CreateDropdown(text, options, default, callback)
            local Row = makeLabeledRow(text, 36)
            local selected = default or (options and options[1])
            local ValueBtn = Instance.new("TextButton")
            ValueBtn.Size = UDim2.new(0, 130, 0, 24)
            ValueBtn.Position = UDim2.new(1, -144, 0.5, -12)
            ValueBtn.BackgroundColor3 = Theme.Track
            ValueBtn.BorderSizePixel = 0
            ValueBtn.Text = selected or ""
            ValueBtn.TextColor3 = Theme.Text
            ValueBtn.TextSize = 12
            ValueBtn.Font = Enum.Font.Gotham
            ValueBtn.TextXAlignment = Enum.TextXAlignment.Left
            ValueBtn.AutoButtonColor = false
            ValueBtn.Parent = Row
            Round(ValueBtn, 5)
            Stroke(ValueBtn, Theme.Border, 1)
            local Pad = Padding(ValueBtn, 0, 0, 10, 22)
            local Arrow = MakeText(ValueBtn, "▾", 9, Theme.TextDim, Enum.Font.Gotham)
            Arrow.Size = UDim2.new(0, 16, 1, 0)
            Arrow.Position = UDim2.new(1, -16, 0, 0)
            Arrow.TextXAlignment = Enum.TextXAlignment.Center

            -- 下拉列表 (放到 Page 上层避免被裁剪)
            local List = Instance.new("Frame")
            List.Size = UDim2.new(0, 130, 0, 0)
            List.Position = UDim2.new(1, -144, 0, 36)
            List.BackgroundColor3 = Theme.Element
            List.BorderSizePixel = 0
            List.Visible = false
            List.ZIndex = 10
            List.Parent = Row
            Round(List, 5)
            Stroke(List, Theme.BorderBright, 1)
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = List

            local open = false
            local function buildOptions()
                for _, c in ipairs(List:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local Item = Instance.new("TextButton")
                    Item.Size = UDim2.new(1, 0, 0, 24)
                    Item.BackgroundColor3 = Theme.Element
                    Item.BorderSizePixel = 0
                    Item.Text = "  " .. opt
                    Item.TextColor3 = opt == selected and Theme.Accent or Theme.Text
                    Item.TextSize = 12
                    Item.Font = Enum.Font.Gotham
                    Item.TextXAlignment = Enum.TextXAlignment.Left
                    Item.AutoButtonColor = false
                    Item.ZIndex = 10
                    Item.Parent = List
                    Item.MouseEnter:Connect(function()
                        TweenService:Create(Item, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ElementHover}):Play()
                    end)
                    Item.MouseLeave:Connect(function()
                        TweenService:Create(Item, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Element}):Play()
                    end)
                    Item.MouseButton1Click:Connect(function()
                        selected = opt
                        ValueBtn.Text = opt
                        if callback then callback(opt) end
                        open = false
                        List.Visible = false
                        Arrow.Text = "▾"
                        TweenService:Create(List, TweenInfo.new(0.12), {Size = UDim2.new(0, 130, 0, 0)}):Play()
                        buildOptions()
                    end)
                end
            end
            local function toggle()
                open = not open
                Arrow.Text = open and "▴" or "▾"
                List.Visible = open
                TweenService:Create(List, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = open and UDim2.new(0, 130, 0, #options * 24) or UDim2.new(0, 130, 0, 0)
                }):Play()
            end
            ValueBtn.MouseButton1Click:Connect(toggle)
            buildOptions()
            -- 点击外部关闭
            UserInput.InputBegan:Connect(function(i)
                if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = i.Position
                    local ap = List.AbsolutePosition
                    local as = List.AbsoluteSize
                    local bp = ValueBtn.AbsolutePosition
                    local bs = ValueBtn.AbsoluteSize
                    if (mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y)
                       and (mp.X < bp.X or mp.X > bp.X + bs.X or mp.Y < bp.Y or mp.Y > bp.Y + bs.Y) then
                        open = false
                        List.Visible = false
                        Arrow.Text = "▾"
                    end
                end
            end)
            return {
                Get = function() return selected end,
                Set = function(v)
                    selected = v
                    ValueBtn.Text = v
                    if callback then callback(v) end
                end
            }
        end

        -- Button 按钮
        function TabApi:CreateButton(text, callback)
            local Row = makeRow(34)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = text
            Btn.TextColor3 = Theme.Text
            Btn.TextSize = 13
            Btn.Font = Enum.Font.GothamMedium
            Btn.AutoButtonColor = false
            Btn.Parent = Row
            Btn.MouseEnter:Connect(function()
                TweenService:Create(Row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentDark}):Play()
                TweenService:Create(Btn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element}):Play()
                TweenService:Create(Btn, TweenInfo.new(0.15), {TextColor3 = Theme.Text}):Play()
            end)
            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
                -- 按下反馈
                TweenService:Create(Row, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent}):Play()
                task.wait(0.08)
                TweenService:Create(Row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Element}):Play()
            end)
            return {}
        end

        -- ColorPicker 颜色选择器 (含透明度)
        function TabApi:CreateColorPicker(text, default, callback)
            local Row, Label = makeLabeledRow(text, 36)
            local Preview = Instance.new("TextButton")
            Preview.Size = UDim2.new(0, 24, 0, 24)
            Preview.Position = UDim2.new(1, -38, 0.5, -12)
            Preview.BackgroundColor3 = default or Theme.Accent
            Preview.BorderSizePixel = 0
            Preview.Text = ""
            Preview.AutoButtonColor = false
            Preview.Parent = Row
            Round(Preview, 4)
            Stroke(Preview, Theme.Border, 1)

            -- 棋盘格背景 (透明度展示)
            local CheckerBg = Instance.new("ImageLabel")
            CheckerBg.Size = UDim2.new(1, 0, 1, 0)
            CheckerBg.BackgroundTransparency = 1
            CheckerBg.Image = "rbxassetid://5960627300"
            CheckerBg.ScaleType = Enum.ScaleType.Tile
            CheckerBg.TileSize = UDim2.new(0, 6, 0, 6)
            CheckerBg.Parent = Preview

            local Picker = Instance.new("Frame")
            Picker.Size = UDim2.new(0, 200, 0, 200)
            Picker.Position = UDim2.new(1, -200, 0, 38)
            Picker.BackgroundColor3 = Theme.Element
            Picker.BorderSizePixel = 0
            Picker.Visible = false
            Picker.ZIndex = 20
            Picker.Parent = Row
            Round(Picker, 6)
            Stroke(Picker, Theme.BorderBright, 1)

            -- 饱和度/亮度区
            local SV = Instance.new("TextButton")
            SV.Size = UDim2.new(1, -16, 0, 110)
            SV.Position = UDim2.new(0, 8, 0, 8)
            SV.BackgroundColor3 = default or Theme.Accent
            SV.BorderSizePixel = 0
            SV.Text = ""
            SV.AutoButtonColor = false
            SV.ZIndex = 20
            SV.Parent = Picker
            Round(SV, 4)
            local SW = Instance.new("Frame")
            SW.Size = UDim2.new(1, 0, 1, 0)
            SW.BackgroundColor3 = Color3.fromRGB(255,255,255)
            SW.BorderSizePixel = 0
            SW.Parent = SV
            local SB = Instance.new("Frame")
            SB.Size = UDim2.new(1, 0, 1, 0)
            SB.BackgroundColor3 = Color3.fromRGB(0,0,0)
            SB.BorderSizePixel = 0
            SB.BackgroundTransparency = 0.5
            SB.Parent = SV
            local SVKnob = Instance.new("Frame")
            SVKnob.Size = UDim2.new(0, 8, 0, 8)
            SVKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            SVKnob.BorderSizePixel = 0
            SVKnob.ZIndex = 22
            SVKnob.Parent = SV
            Round(SVKnob, 4)
            Stroke(SVKnob, Color3.fromRGB(0,0,0), 1)

            -- 色相条
            local HueBar = Instance.new("TextButton")
            HueBar.Size = UDim2.new(1, -16, 0, 12)
            HueBar.Position = UDim2.new(0, 8, 0, 126)
            HueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
            HueBar.BorderSizePixel = 0
            HueBar.Text = ""
            HueBar.AutoButtonColor = false
            HueBar.ZIndex = 20
            HueBar.Parent = Picker
            local HueGrad = Instance.new("UIGradient")
            HueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
            })
            HueGrad.Parent = HueBar
            local HueKnob = Instance.new("Frame")
            HueKnob.Size = UDim2.new(0, 4, 0, 14)
            HueKnob.Position = UDim2.new(0, -2, 0.5, -7)
            HueKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            HueKnob.BorderSizePixel = 0
            HueKnob.ZIndex = 22
            HueKnob.Parent = HueBar
            Round(HueKnob, 2)
            Stroke(HueKnob, Color3.fromRGB(0,0,0), 1)

            -- 透明度条
            local AlphaBar = Instance.new("TextButton")
            AlphaBar.Size = UDim2.new(1, -16, 0, 12)
            AlphaBar.Position = UDim2.new(0, 8, 0, 144)
            AlphaBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
            AlphaBar.BorderSizePixel = 0
            AlphaBar.Text = ""
            AlphaBar.AutoButtonColor = false
            AlphaBar.ZIndex = 20
            AlphaBar.Parent = Picker
            local AlphaChecker = Instance.new("ImageLabel")
            AlphaChecker.Size = UDim2.new(1, 0, 1, 0)
            AlphaChecker.BackgroundTransparency = 1
            AlphaChecker.Image = "rbxassetid://5960627300"
            AlphaChecker.ScaleType = Enum.ScaleType.Tile
            AlphaChecker.TileSize = UDim2.new(0, 6, 0, 6)
            AlphaChecker.Parent = AlphaBar
            local AlphaGrad = Instance.new("UIGradient")
            AlphaGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
            })
            AlphaGrad.Parent = AlphaBar
            local AlphaKnob = Instance.new("Frame")
            AlphaKnob.Size = UDim2.new(0, 4, 0, 14)
            AlphaKnob.Position = UDim2.new(1, -2, 0.5, -7)
            AlphaKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            AlphaKnob.BorderSizePixel = 0
            AlphaKnob.ZIndex = 22
            AlphaKnob.Parent = AlphaBar
            Round(AlphaKnob, 2)
            Stroke(AlphaKnob, Color3.fromRGB(0,0,0), 1)

            -- RGB 文字
            local rgbLabel = MakeText(Picker, "RGB", 10, Theme.TextDim, Enum.Font.Gotham)
            rgbLabel.Size = UDim2.new(1, -16, 0, 18)
            rgbLabel.Position = UDim2.new(0, 8, 0, 164)
            rgbLabel.ZIndex = 20

            local h, s, v, a = 0, 0, 1, 1
            local function fromRGB(c)
                local r, g, b = c.R, c.G, c.B
                local mx = math.max(r,g,b); local mn = math.min(r,g,b); local d = mx - mn
                v = mx
                s = mx == 0 and 0 or (d / mx)
                if d == 0 then h = 0
                elseif mx == r then h = ((g - b) / d) % 6
                elseif mx == g then h = (b - r) / d + 2
                else h = (r - g) / d + 4 end
                h = h / 6; if h < 0 then h = h + 1 end
            end
            fromRGB(default or Theme.Accent)

            local function hsvToRgb(hue, sat, val)
                local i = math.floor(hue * 6); local f = hue * 6 - i
                local p = val * (1 - sat); local q = val * (1 - f * sat); local t = val * (1 - (1 - f) * sat)
                i = i % 6
                local r, g, b
                if i == 0 then r,g,b = val,t,p
                elseif i == 1 then r,g,b = q,val,p
                elseif i == 2 then r,g,b = p,val,t
                elseif i == 3 then r,g,b = p,q,val
                elseif i == 4 then r,g,b = t,p,val
                else r,g,b = val,p,q end
                return Color3.fromRGB(r*255, g*255, b*255)
            end

            local function updateColor()
                local c = hsvToRgb(h, s, v)
                local cr = math.floor(c.R*255); local cg = math.floor(c.G*255); local cb = math.floor(c.B*255)
                Preview.BackgroundColor3 = c
                CheckerBg.ImageTransparency = a
                SV.BackgroundColor3 = hsvToRgb(h, 1, 1)
                AlphaGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
                    ColorSequenceKeypoint.new(1, c),
                })
                rgbLabel.Text = string.format("RGB  %d, %d, %d   A %d", cr, cg, cb, math.floor(a*255))
                if callback then callback(c, a) end
            end

            local svDrag, hueDrag, alphaDrag = false, false, false
            local function svUpdate(i)
                local rx = math.clamp((i.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                local ry = math.clamp((i.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                s = rx; v = 1 - ry
                SVKnob.Position = UDim2.new(rx, -4, ry, -4)
                updateColor()
            end
            local function hueUpdate(i)
                local r = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                h = r; HueKnob.Position = UDim2.new(r, -2, 0.5, -7); updateColor()
            end
            local function alphaUpdate(i)
                local r = math.clamp((i.Position.X - AlphaBar.AbsolutePosition.X) / AlphaBar.AbsoluteSize.X, 0, 1)
                a = r; AlphaKnob.Position = UDim2.new(r, -2, 0.5, -7); updateColor()
            end
            SV.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true; svUpdate(i) end end)
            HueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true; hueUpdate(i) end end)
            AlphaBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = true; alphaUpdate(i) end end)
            UserInput.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag=false; hueDrag=false; alphaDrag=false end end)
            UserInput.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if svDrag then svUpdate(i) end
                    if hueDrag then hueUpdate(i) end
                    if alphaDrag then alphaUpdate(i) end
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                Picker.Visible = not Picker.Visible
            end)
            UserInput.InputBegan:Connect(function(i)
                if Picker.Visible and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = i.Position
                    local ap = Picker.AbsolutePosition; local as = Picker.AbsoluteSize
                    local pp = Preview.AbsolutePosition; local ps = Preview.AbsoluteSize
                    if (mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y)
                       and (mp.X < pp.X or mp.X > pp.X + ps.X or mp.Y < pp.Y or mp.Y > pp.Y + ps.Y) then
                        Picker.Visible = false
                    end
                end
            end)
            updateColor()
            return {
                Get = function() return Preview.BackgroundColor3 end,
                Set = function(c) fromRGB(c); updateColor() end
            }
        end

        -- Keybind 按键绑定
        function TabApi:CreateKeybind(text, defaultKey, callback)
            local Row, Label = makeLabeledRow(text, 36)
            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.new(0, 90, 0, 24)
            KeyBtn.Position = UDim2.new(1, -104, 0.5, -12)
            KeyBtn.BackgroundColor3 = Theme.Track
            KeyBtn.BorderSizePixel = 0
            KeyBtn.Text = defaultKey and defaultKey.Name or "None"
            KeyBtn.TextColor3 = Theme.Text
            KeyBtn.TextSize = 12
            KeyBtn.Font = Enum.Font.Gotham
            KeyBtn.AutoButtonColor = false
            KeyBtn.Parent = Row
            Round(KeyBtn, 5)
            Stroke(KeyBtn, Theme.Border, 1)
            local listening = false
            local currentKey = defaultKey
            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "Press..."
                KeyBtn.TextColor3 = Theme.Accent
            end)
            UserInput.InputBegan:Connect(function(input)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    KeyBtn.Text = input.KeyCode.Name
                    KeyBtn.TextColor3 = Theme.Text
                    listening = false
                    if callback then callback(currentKey) end
                end
            end)
            return {
                Get = function() return currentKey end,
                Set = function(k)
                    currentKey = k
                    KeyBtn.Text = k and k.Name or "None"
                    if callback then callback(k) end
                end
            }
        end

        -- Label 文字标签
        function TabApi:CreateLabel(text, isTitle)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            local Lbl = MakeText(Row, text, isTitle and 13 or 11, isTitle and Theme.Accent or Theme.TextDim,
                                 isTitle and Enum.Font.GothamBold or Enum.Font.Gotham)
            Lbl.Size = UDim2.new(1, 0, 1, 0)
            return {Set = function(t) Lbl.Text = t end, Get = function() return Lbl.Text end}
        end

        -- 复选框
        function TabApi:CreateMultiToggle(text, default, callback)
            local Row, Label = makeLabeledRow(text, 36)
            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(0, 18, 0, 18)
            Toggle.Position = UDim2.new(1, -32, 0.5, -9)
            Toggle.BackgroundColor3 = Theme.Track
            Toggle.BorderSizePixel = 0
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            Toggle.Parent = Row
            Round(Toggle, 4)
            Stroke(Toggle, Theme.Border, 1)
            local Mark = Instance.new("TextLabel")
            Mark.BackgroundTransparency = 1
            Mark.Size = UDim2.new(1, 0, 1, 0)
            Mark.Text = "✓"
            Mark.TextColor3 = Color3.fromRGB(255,255,255)
            Mark.TextSize = 11
            Mark.Font = Enum.Font.GothamBold
            Mark.Visible = false
            Mark.Parent = Toggle
            local state = default and true or false
            local function set(v)
                state = v and true or false
                Mark.Visible = state
                TweenService:Create(Toggle, TweenInfo.new(0.12), {
                    BackgroundColor3 = state and Theme.Accent or Theme.Track
                }):Play()
                if callback then callback(state) end
            end
            Toggle.MouseButton1Click:Connect(function() set(not state) end)
            set(state)
            return {Set = set, Get = function() return state end}
        end

        -- InputBox 文本输入
        function TabApi:CreateInput(text, default, placeholder, callback)
            local Row, Label = makeLabeledRow(text, 36)
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0, 160, 0, 24)
            Box.Position = UDim2.new(1, -174, 0.5, -12)
            Box.BackgroundColor3 = Theme.Track
            Box.BorderSizePixel = 0
            Box.Text = default or ""
            Box.PlaceholderText = placeholder or ""
            Box.PlaceholderColor3 = Theme.TextFaint
            Box.TextColor3 = Theme.Text
            Box.TextSize = 12
            Box.Font = Enum.Font.Gotham
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.ClearTextOnFocus = false
            Box.Parent = Row
            Round(Box, 5)
            Stroke(Box, Theme.Border, 1)
            Padding(Box, 0, 0, 10, 10)
            Box.FocusLost:Connect(function(enter)
                if callback then callback(Box.Text) end
            end)
            return {
                Get = function() return Box.Text end,
                Set = function(t) Box.Text = t end
            }
        end

        -- 分割线
        function TabApi:CreateDivider()
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 1)
            Row.BackgroundColor3 = Theme.Border
            Row.BorderSizePixel = 0
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            return {}
        end

        return TabApi
    end

    self._windowObj = WindowObj
    return WindowObj
end

--========================== 初始化 ==========================--
function Neverlose:Init()
    local wo = self._windowObj
    if wo and #wo._tabs > 0 then
        wo:_selectTab(wo._tabs[1])
    end
    -- 菜单切换键: RightShift
    self._menuVisible = true
    UserInput.InputBegan:Connect(function(input, gpe)
        if input.KeyCode == Enum.KeyCode.RightShift then
            self._menuVisible = not self._menuVisible
            if self._window then
                self._window.Parent.Visible = self._menuVisible
            end
        end
    end)
end

-- 通知快捷方法
function Neverlose:Notify(title, desc, duration, notifType)
    if self._notifs then self._notifs:Push(title, desc, duration, notifType) end
end

-- 设置水印显隐
function Neverlose:SetWatermark(visible)
    if self._watermark then self._watermark.Visible = visible end
end

-- 获取主题
function Neverlose:GetTheme()
    return Theme
end

return Neverlose
