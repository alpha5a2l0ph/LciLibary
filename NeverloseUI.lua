--[[
    Neverlose 风格 UI 库 (Roblox)
    模仿 CS:GO Neverlose 客户端的界面设计
    暗色主题 + 紫色强调色 + 侧边栏 Tab 布局

    用法:
        local NL = loadstring(game:HttpGet("..."))()
        local Window = NL:CreateWindow("Neverlose")
        local Tab = Window:CreateTab("Rage", "rbxassetid://图标ID")
        Tab:CreateToggle("启用自动开火", false, function(state) end)
        Tab:CreateSlider("FOV", 1, 100, 50, function(val) end)
        Tab:CreateDropdown("命中部位", {"头部","胸部","身体"}, "头部", function(val) end)
        Tab:CreateButton("重置配置", function() end)
        Tab:CreateColorPicker("方框颜色", Color3.fromRGB(157,78,221), function(c) end)
        Tab:CreateKeybind("切换菜单", Enum.KeyCode.RightShift, function(key) end)
        Tab:CreateLabel("提示文字", true)
        NL:Init()
]]

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Neverlose = {}
Neverlose.__index = Neverlose

-- 主题色板 (Neverlose 风格)
local Theme = {
    Background     = Color3.fromRGB(22, 22, 28),   -- 主背景
    Sidebar        = Color3.fromRGB(28, 28, 36),   -- 侧边栏背景
    SidebarItem    = Color3.fromRGB(36, 36, 46),   -- 侧边栏项
    SidebarHover   = Color3.fromRGB(46, 46, 58),   -- 侧边栏悬停
    Content        = Color3.fromRGB(24, 24, 32),   -- 内容区背景
    Element       = Color3.fromRGB(34, 34, 44),   -- 元素背景
    ElementHover   = Color3.fromRGB(42, 42, 54),   -- 元素悬停
    Accent         = Color3.fromRGB(157, 78, 221),  -- 紫色强调
    AccentDark     = Color3.fromRGB(110, 50, 165),  -- 深紫
    Text           = Color3.fromRGB(235, 235, 245),  -- 主文字
    TextDim        = Color3.fromRGB(140, 140, 160),  -- 次要文字
    ToggleOff      = Color3.fromRGB(60, 60, 75),   -- 开关关闭
    Border         = Color3.fromRGB(50, 50, 64),   -- 边框
    SearchBg       = Color3.fromRGB(20, 20, 26),   -- 搜索框
    Stroke         = Color3.fromRGB(60, 60, 80),
}

-- 工具:创建圆角
local function Round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- 工具:创建描边
local function Stroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- 工具:创建文字标签
local function MakeText(parent, text, size, color, font, align)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = text or ""
    label.TextColor3 = color or Theme.Text
    label.TextSize = size or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

-- 工具:创建内边距
local function Padding(parent, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or 0)
    pad.PaddingLeft = UDim.new(0, left or 0)
    pad.PaddingRight = UDim.new(0, right or 0)
    pad.Parent = parent
    return pad
end

-- 创建主窗口
function Neverlose:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeverloseUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    -- 优先放 CoreGui, 否则放 PlayerGui
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    self._gui = ScreenGui

    -- 窗口主容器
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, 680, 0, 440)
    Window.Position = UDim2.new(0.5, -340, 0.5, -220)
    Window.BackgroundColor3 = Theme.Background
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = ScreenGui
    Round(Window, 10)
    Stroke(Window, Theme.Stroke, 1)
    self._window = Window

    -- 拖拽支持
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    Window.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Window.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- 顶部标题栏区 (在侧边栏里显示)
    -- 左侧 Logo / 标题
    local LogoFrame = Instance.new("Frame")
    LogoFrame.Name = "Logo"
    LogoFrame.Size = UDim2.new(0, 180, 0, 56)
    LogoFrame.Position = UDim2.new(0, 0, 0, 0)
    LogoFrame.BackgroundColor3 = Theme.Sidebar
    LogoFrame.BorderSizePixel = 0
    LogoFrame.Parent = Window
    local LogoText = Instance.new("TextLabel")
    LogoText.BackgroundTransparency = 1
    LogoText.Size = UDim2.new(1, -24, 1, 0)
    LogoText.Position = UDim2.new(0, 16, 0, 0)
    LogoText.Text = "neverlose"
    LogoText.TextColor3 = Theme.Text
    LogoText.TextSize = 18
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextXAlignment = Enum.TextXAlignment.Left
    LogoText.Parent = LogoFrame
    local LogoAccent = Instance.new("Frame")
    LogoAccent.Size = UDim2.new(0, 3, 0, 18)
    LogoAccent.Position = UDim2.new(0, 8, 0.5, -9)
    LogoAccent.BackgroundColor3 = Theme.Accent
    LogoAccent.BorderSizePixel = 0
    LogoAccent.Parent = LogoFrame

    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 180, 1, -56)
    Sidebar.Position = UDim2.new(0, 0, 0, 56)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Window

    -- 搜索框
    local Search = Instance.new("Frame")
    Search.Size = UDim2.new(1, -24, 0, 32)
    Search.Position = UDim2.new(0, 12, 0, 12)
    Search.BackgroundColor3 = Theme.SearchBg
    Search.BorderSizePixel = 0
    Search.Parent = Sidebar
    Round(Search, 6)
    local SearchIcon = Instance.new("TextLabel")
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Size = UDim2.new(0, 24, 1, 0)
    SearchIcon.Text = "⌕"
    SearchIcon.TextColor3 = Theme.TextDim
    SearchIcon.TextSize = 16
    SearchIcon.Font = Enum.Font.Gotham
    SearchIcon.Parent = Search
    local SearchBox = Instance.new("TextBox")
    SearchBox.BackgroundTransparency = 1
    SearchBox.Size = UDim2.new(1, -32, 1, 0)
    SearchBox.Position = UDim2.new(0, 28, 0, 0)
    SearchBox.PlaceholderText = "搜索..."
    SearchBox.PlaceholderColor3 = Theme.TextDim
    SearchBox.Text = ""
    SearchBox.TextColor3 = Theme.Text
    SearchBox.TextSize = 13
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = Search

    -- Tab 列表容器
    local TabList = Instance.new("Frame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 1, -68)
    TabList.Position = UDim2.new(0, 0, 0, 60)
    TabList.BackgroundTransparency = 1
    TabList.Parent = Sidebar
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 2)
    TabListLayout.Parent = TabList
    Padding(TabList, 0, 8, 12, 12)

    -- 底部版本信息
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Size = UDim2.new(1, -24, 0, 20)
    VersionLabel.Position = UDim2.new(0, 12, 1, -28)
    VersionLabel.Text = "v2.0 · roblox"
    VersionLabel.TextColor3 = Theme.TextDim
    VersionLabel.TextSize = 11
    VersionLabel.Font = Enum.Font.Gotham
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
    VersionLabel.Parent = Sidebar

    -- 内容区
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "Content"
    ContentArea.Size = UDim2.new(1, -180, 1, 0)
    ContentArea.Position = UDim2.new(0, 180, 0, 0)
    ContentArea.BackgroundColor3 = Theme.Content
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = Window

    -- 内容区头部 (显示当前 Tab 名)
    local ContentHeader = Instance.new("Frame")
    ContentHeader.Name = "Header"
    ContentHeader.Size = UDim2.new(1, 0, 0, 56)
    ContentHeader.BackgroundTransparency = 1
    ContentHeader.Parent = ContentArea
    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Size = UDim2.new(1, -32, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 24, 0, 0)
    HeaderTitle.Text = title or "Menu"
    HeaderTitle.TextColor3 = Theme.Text
    HeaderTitle.TextSize = 18
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Parent = ContentHeader
    local HeaderUnderline = Instance.new("Frame")
    HeaderUnderline.Size = UDim2.new(1, 0, 0, 1)
    HeaderUnderline.Position = UDim2.new(0, 0, 1, -1)
    HeaderUnderline.BackgroundColor3 = Theme.Border
    HeaderUnderline.BorderSizePixel = 0
    HeaderUnderline.Parent = ContentHeader

    -- Tab 内容容器 (滚动)
    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "Pages"
    PageContainer.Size = UDim2.new(1, 0, 1, -56)
    PageContainer.Position = UDim2.new(0, 0, 0, 56)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = ContentArea

    -- 顶部右侧关闭/最小化按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 32, 0, 32)
    CloseBtn.Position = UDim2.new(1, -40, 0, 12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.Parent = ContentHeader
    CloseBtn.MouseButton1Click:Connect(function()
        Window.Visible = false
    end)
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Text end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)

    local WindowObj = {
        _tabs = {},
        _tabButtons = {},
        _tabList = TabList,
        _pageContainer = PageContainer,
        _headerTitle = HeaderTitle,
        _currentTab = nil,
    }

    -- 创建 Tab
    function WindowObj:CreateTab(name, icon)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 34)
        TabButton.BackgroundColor3 = Theme.SidebarItem
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabList
        Round(TabButton, 6)
        local TabIcon = Instance.new("ImageLabel")
        TabIcon.BackgroundTransparency = 1
        TabIcon.Size = UDim2.new(0, 18, 0, 18)
        TabIcon.Position = UDim2.new(0, 12, 0.5, -9)
        TabIcon.Image = icon or ""
        TabIcon.ImageColor3 = Theme.TextDim
        TabIcon.Parent = TabButton
        local TabLabel = Instance.new("TextLabel")
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(1, -44, 1, 0)
        TabLabel.Position = UDim2.new(0, 38, 0, 0)
        TabLabel.Text = name
        TabLabel.TextColor3 = Theme.TextDim
        TabLabel.TextSize = 13
        TabLabel.Font = Enum.Font.Gotham
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton
        local TabAccent = Instance.new("Frame")
        TabAccent.Size = UDim2.new(0, 3, 0, 0)
        TabAccent.Position = UDim2.new(0, 0, 0.5, 0)
        TabAccent.BackgroundColor3 = Theme.Accent
        TabAccent.BorderSizePixel = 0
        TabAccent.Parent = TabButton
        Round(TabAccent, 2)

        -- 该 Tab 的页面
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Theme.Border
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = PageContainer
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.Parent = Page
        Padding(Page, 20, 20, 20, 20)

        local tab = {
            name = name,
            button = TabButton,
            label = TabLabel,
            icon = TabIcon,
            accent = TabAccent,
            page = Page,
            order = #self._tabs + 1,
        }
        table.insert(self._tabs, tab)

        -- 选中逻辑
        TabButton.MouseButton1Click:Connect(function()
            self:_selectTab(tab)
        end)
        TabButton.MouseEnter:Connect(function()
            if self._currentTab ~= tab then
                TabButton.BackgroundColor3 = Theme.SidebarHover
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if self._currentTab ~= tab then
                TabButton.BackgroundColor3 = Theme.SidebarItem
            end
        end)

        -- 搜索过滤
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(SearchBox.Text)
            if q == "" or string.find(string.lower(name), q) then
                TabButton.Visible = true
            else
                TabButton.Visible = false
            end
        end)

        return self:_buildTabApi(tab)
    end

    function WindowObj:_selectTab(tab)
        -- 取消之前选中
        if self._currentTab then
            local prev = self._currentTab
            prev.label.TextColor3 = Theme.TextDim
            prev.icon.ImageColor3 = Theme.TextDim
            prev.button.BackgroundColor3 = Theme.SidebarItem
            TweenService:Create(prev.accent, TweenInfo.new(0.18), {Size = UDim2.new(0, 3, 0, 0)}):Play()
            prev.page.Visible = false
        end
        self._currentTab = tab
        tab.label.TextColor3 = Theme.Text
        tab.icon.ImageColor3 = Theme.Accent
        tab.button.BackgroundColor3 = Theme.SidebarHover
        TweenService:Create(tab.accent, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 0, 0.5, -9)}):Play()
        tab.page.Visible = true
        self._headerTitle.Text = tab.name
    end

    -- 构建 Tab 的组件 API
    function WindowObj:_buildTabApi(tab)
        local TabApi = {}
        local orderCounter = 0
        local function nextOrder()
            orderCounter = orderCounter + 1
            return orderCounter
        end

        -- 通用:创建一行元素容器
        local function makeRow(labelText)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 38)
            Row.BackgroundColor3 = Theme.Element
            Row.BorderSizePixel = 0
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            Round(Row, 6)
            Stroke(Row, Theme.Border, 1)
            Padding(Row, 0, 0, 14, 14)

            local Label = Instance.new("TextLabel")
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(0.5, 0, 1, 0)
            Label.Text = labelText or ""
            Label.TextColor3 = Theme.Text
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Row
            return Row, Label
        end

        -- Toggle 开关
        function TabApi:CreateToggle(text, default, callback)
            local Row, Label = makeRow(text)
            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(0, 40, 0, 20)
            Toggle.Position = UDim2.new(1, -40, 0.5, -10)
            Toggle.BackgroundColor3 = Theme.ToggleOff
            Toggle.BorderSizePixel = 0
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            Toggle.Parent = Row
            Round(Toggle, 10)
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
                TweenService:Create(Toggle, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
                }):Play()
                TweenService:Create(Knob, TweenInfo.new(0.15), {
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Theme.TextDim
                }):Play()
                if callback then callback(state) end
            end
            Toggle.MouseButton1Click:Connect(function() set(not state) end)
            set(state)
            return {Set = set, Get = function() return state end}
        end

        -- Slider 滑块
        function TabApi:CreateSlider(text, min, max, default, callback)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 52)
            Row.BackgroundColor3 = Theme.Element
            Row.BorderSizePixel = 0
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            Round(Row, 6)
            Stroke(Row, Theme.Border, 1)
            Padding(Row, 0, 0, 14, 14)

            local Label = Instance.new("TextLabel")
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(0.6, 0, 0, 22)
            Label.Position = UDim2.new(0, 0, 0, 0)
            Label.Text = text
            Label.TextColor3 = Theme.Text
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextYAlignment = Enum.TextYAlignment.Center
            Label.Parent = Row

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Size = UDim2.new(0.4, 0, 0, 22)
            ValueLabel.Position = UDim2.new(0.6, 0, 0, 0)
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Theme.Accent
            ValueLabel.TextSize = 13
            ValueLabel.Font = Enum.Font.GothamMedium
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = Row

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 4)
            Track.Position = UDim2.new(0, 0, 0, 34)
            Track.BackgroundColor3 = Theme.SearchBg
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
            Knob.Size = UDim2.new(0, 12, 0, 12)
            Knob.Position = UDim2.new(1, -6, 0.5, -6)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = Fill
            Round(Knob, 6)

            local value = default
            local dragging = false
            local function update(input)
                local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                ValueLabel.Text = tostring(value)
                if callback then callback(value) end
            end
            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input)
                end
            end)
            UserInput.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInput.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
            return {
                Get = function() return value end,
                Set = function(v)
                    value = math.clamp(v, min, max)
                    local rel = (value - min) / (max - min)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    if callback then callback(value) end
                end
            }
        end

        -- Dropdown 下拉菜单
        function TabApi:CreateDropdown(text, options, default, callback)
            local Row, Label = makeRow(text)
            local selected = default or (options and options[1])
            local ValueBtn = Instance.new("TextButton")
            ValueBtn.Size = UDim2.new(0, 120, 0, 24)
            ValueBtn.Position = UDim2.new(1, -120, 0.5, -12)
            ValueBtn.BackgroundColor3 = Theme.SearchBg
            ValueBtn.BorderSizePixel = 0
            ValueBtn.Text = selected or ""
            ValueBtn.TextColor3 = Theme.Text
            ValueBtn.TextSize = 12
            ValueBtn.Font = Enum.Font.Gotham
            ValueBtn.TextXAlignment = Enum.TextXAlignment.Center
            ValueBtn.AutoButtonColor = false
            ValueBtn.Parent = Row
            Round(ValueBtn, 5)
            local Arrow = Instance.new("TextLabel")
            Arrow.BackgroundTransparency = 1
            Arrow.Size = UDim2.new(0, 16, 0, 24)
            Arrow.Position = UDim2.new(1, -16, 0, 0)
            Arrow.Text = "▾"
            Arrow.TextColor3 = Theme.TextDim
            Arrow.TextSize = 10
            Arrow.Parent = ValueBtn

            local open = false
            local List = Instance.new("Frame")
            List.Size = UDim2.new(0, 120, 0, 0)
            List.Position = UDim2.new(1, -120, 0, 26)
            List.BackgroundColor3 = Theme.Element
            List.BorderSizePixel = 0
            List.Visible = false
            List.Parent = Row
            Round(List, 5)
            Stroke(List, Theme.Border, 1)
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 0)
            ListLayout.Parent = List

            local function buildOptions()
                for _, opt in ipairs(options) do
                    local Item = Instance.new("TextButton")
                    Item.Size = UDim2.new(1, 0, 0, 24)
                    Item.BackgroundColor3 = Theme.Element
                    Item.BorderSizePixel = 0
                    Item.Text = opt
                    Item.TextColor3 = opt == selected and Theme.Accent or Theme.Text
                    Item.TextSize = 12
                    Item.Font = Enum.Font.Gotham
                    Item.AutoButtonColor = false
                    Item.Parent = List
                    Item.MouseEnter:Connect(function() Item.BackgroundColor3 = Theme.ElementHover end)
                    Item.MouseLeave:Connect(function() Item.BackgroundColor3 = Theme.Element end)
                    Item.MouseButton1Click:Connect(function()
                        selected = opt
                        ValueBtn.Text = opt
                        if callback then callback(opt) end
                        open = false
                        List.Visible = false
                        Arrow.Text = "▾"
                        buildOptions()
                    end)
                end
            end
            buildOptions()

            local function toggle()
                open = not open
                List.Visible = open
                Arrow.Text = open and "▴" or "▾"
                TweenService:Create(List, TweenInfo.new(0.12), {
                    Size = open and UDim2.new(0, 120, 0, #options * 24) or UDim2.new(0, 120, 0, 0)
                }):Play()
            end
            ValueBtn.MouseButton1Click:Connect(toggle)
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
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 38)
            Row.BackgroundColor3 = Theme.Element
            Row.BorderSizePixel = 0
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            Round(Row, 6)
            Stroke(Row, Theme.Border, 1)

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = text
            Btn.TextColor3 = Theme.Text
            Btn.TextSize = 13
            Btn.Font = Enum.Font.Gotham
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
            end)
            return {}
        end

        -- ColorPicker 颜色选择器
        function TabApi:CreateColorPicker(text, default, callback)
            local Row, Label = makeRow(text)
            local Preview = Instance.new("TextButton")
            Preview.Size = UDim2.new(0, 24, 0, 24)
            Preview.Position = UDim2.new(1, -24, 0.5, -12)
            Preview.BackgroundColor3 = default or Theme.Accent
            Preview.BorderSizePixel = 0
            Preview.Text = ""
            Preview.AutoButtonColor = false
            Preview.Parent = Row
            Round(Preview, 4)
            Stroke(Preview, Theme.Border, 1)

            local Picker = Instance.new("Frame")
            Picker.Size = UDim2.new(0, 180, 0, 170)
            Picker.Position = UDim2.new(1, -180, 0, 32)
            Picker.BackgroundColor3 = Theme.Element
            Picker.BorderSizePixel = 0
            Picker.Visible = false
            Picker.Parent = Row
            Round(Picker, 6)
            Stroke(Picker, Theme.Border, 1)

            -- 饱和度/亮度区
            local SV = Instance.new("TextButton")
            SV.Size = UDim2.new(1, -16, 0, 100)
            SV.Position = UDim2.new(0, 8, 0, 8)
            SV.BackgroundColor3 = default or Theme.Accent
            SV.BorderSizePixel = 0
            SV.Text = ""
            SV.AutoButtonColor = false
            SV.Parent = Picker
            Round(SV, 4)
            local SaturWhite = Instance.new("Frame")
            SaturWhite.Size = UDim2.new(1, 0, 1, 0)
            SaturWhite.BackgroundColor3 = Color3.fromRGB(255,255,255)
            SaturWhite.BorderSizePixel = 0
            SaturWhite.Parent = SV
            local SaturBlack = Instance.new("Frame")
            SaturBlack.Size = UDim2.new(1, 0, 1, 0)
            SaturBlack.BackgroundColor3 = Color3.fromRGB(0,0,0)
            SaturBlack.BorderSizePixel = 0
            SaturBlack.BackgroundTransparency = 0.5
            SaturBlack.Parent = SV
            local SVKnob = Instance.new("Frame")
            SVKnob.Size = UDim2.new(0, 6, 0, 6)
            SVKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            SVKnob.BorderSizePixel = 0
            SVKnob.Parent = SV
            Round(SVKnob, 3)
            Stroke(SVKnob, Color3.fromRGB(0,0,0), 1)

            -- 色相条
            local HueBar = Instance.new("TextButton")
            HueBar.Size = UDim2.new(1, -16, 0, 12)
            HueBar.Position = UDim2.new(0, 8, 0, 116)
            HueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
            HueBar.BorderSizePixel = 0
            HueBar.Text = ""
            HueBar.AutoButtonColor = false
            HueBar.Parent = Picker
            local HueGradient = Instance.new("UIGradient")
            HueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
            })
            HueGradient.Parent = HueBar
            local HueKnob = Instance.new("Frame")
            HueKnob.Size = UDim2.new(0, 4, 0, 14)
            HueKnob.Position = UDim2.new(0, -2, 0.5, -7)
            HueKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            HueKnob.BorderSizePixel = 0
            HueKnob.Parent = HueBar
            Round(HueKnob, 2)
            Stroke(HueKnob, Color3.fromRGB(0,0,0), 1)

            local rgbLabel = Instance.new("TextLabel")
            rgbLabel.BackgroundTransparency = 1
            rgbLabel.Size = UDim2.new(1, -16, 0, 20)
            rgbLabel.Position = UDim2.new(0, 8, 0, 138)
            rgbLabel.Text = "RGB"
            rgbLabel.TextColor3 = Theme.TextDim
            rgbLabel.TextSize = 11
            rgbLabel.Font = Enum.Font.Gotham
            rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
            rgbLabel.Parent = Picker

            -- HSV -> RGB
            local h, s, v = 0, 0, 1
            -- 从 default 反推近似 HSV
            local function fromRGB(c)
                local r, g, b = c.R, c.G, c.B
                local max = math.max(r,g,b)
                local min = math.min(r,g,b)
                local delta = max - min
                v = max
                s = max == 0 and 0 or (delta / max)
                if delta == 0 then h = 0
                elseif max == r then h = ((g - b) / delta) % 6
                elseif max == g then h = (b - r) / delta + 2
                else h = (r - g) / delta + 4 end
                h = h / 6
                if h < 0 then h = h + 1 end
            end
            fromRGB(default or Theme.Accent)

            local function hsvToRgb(hue, sat, val)
                local i = math.floor(hue * 6)
                local f = hue * 6 - i
                local p = val * (1 - sat)
                local q = val * (1 - f * sat)
                local t = val * (1 - (1 - f) * sat)
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
                Preview.BackgroundColor3 = c
                SV.BackgroundColor3 = hsvToRgb(h, 1, 1)
                rgbLabel.Text = string.format("RGB: %d, %d, %d", c.R*255, c.G*255, c.B*255)
                if callback then callback(c) end
            end

            local svDragging, hueDragging = false, false
            local function svUpdate(input)
                local relX = math.clamp((input.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                local relY = math.clamp((input.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                s = relX
                v = 1 - relY
                SVKnob.Position = UDim2.new(relX, -3, relY, -3)
                updateColor()
            end
            local function hueUpdate(input)
                local rel = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                h = rel
                HueKnob.Position = UDim2.new(rel, -2, 0.5, -7)
                updateColor()
            end
            SV.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true; svUpdate(i) end
            end)
            HueBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true; hueUpdate(i) end
            end)
            UserInput.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false; hueDragging = false end
            end)
            UserInput.InputChanged:Connect(function(i)
                if svDragging and i.UserInputType == Enum.UserInputType.MouseMovement then svUpdate(i) end
                if hueDragging and i.UserInputType == Enum.UserInputType.MouseMovement then hueUpdate(i) end
            end)

            Preview.MouseButton1Click:Connect(function()
                Picker.Visible = not Picker.Visible
            end)
            -- 点击外部关闭
            UserInput.InputBegan:Connect(function(i)
                if Picker.Visible and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = i.Position
                    local ap = Picker.AbsolutePosition
                    local as = Picker.AbsoluteSize
                    if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then
                        -- 检查是否点在 Preview 上
                        local pp = Preview.AbsolutePosition
                        local ps = Preview.AbsoluteSize
                        if mp.X < pp.X or mp.X > pp.X + ps.X or mp.Y < pp.Y or mp.Y > pp.Y + ps.Y then
                            Picker.Visible = false
                        end
                    end
                end
            end)

            updateColor()
            return {
                Get = function() return Preview.BackgroundColor3 end,
                Set = function(c)
                    fromRGB(c)
                    updateColor()
                end
            }
        end

        -- Keybind 按键绑定
        function TabApi:CreateKeybind(text, defaultKey, callback)
            local Row, Label = makeRow(text)
            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.new(0, 80, 0, 24)
            KeyBtn.Position = UDim2.new(1, -80, 0.5, -12)
            KeyBtn.BackgroundColor3 = Theme.SearchBg
            KeyBtn.BorderSizePixel = 0
            KeyBtn.Text = defaultKey and defaultKey.Name or "None"
            KeyBtn.TextColor3 = Theme.Text
            KeyBtn.TextSize = 12
            KeyBtn.Font = Enum.Font.Gotham
            KeyBtn.AutoButtonColor = false
            KeyBtn.Parent = Row
            Round(KeyBtn, 5)

            local listening = false
            local currentKey = defaultKey
            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "..."
                KeyBtn.TextColor3 = Theme.Accent
            end)
            UserInput.InputBegan:Connect(function(input, gpe)
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

        -- Label 文字标签 (可作标题)
        function TabApi:CreateLabel(text, isTitle)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 24)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = nextOrder()
            Row.Parent = tab.page
            local Lbl = Instance.new("TextLabel")
            Lbl.BackgroundTransparency = 1
            Lbl.Size = UDim2.new(1, 0, 1, 0)
            Lbl.Text = text
            Lbl.TextColor3 = isTitle and Theme.Accent or Theme.TextDim
            Lbl.TextSize = isTitle and 14 or 12
            Lbl.Font = isTitle and Enum.Font.GothamBold or Enum.Font.Gotham
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row
            return {Set = function(t) Lbl.Text = t end, Get = function() return Lbl.Text end}
        end

        -- 复选框组 (多选)
        function TabApi:CreateMultiToggle(text, default, callback)
            local Row, Label = makeRow(text)
            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(0, 18, 0, 18)
            Toggle.Position = UDim2.new(1, -18, 0.5, -9)
            Toggle.BackgroundColor3 = Theme.SearchBg
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
            Mark.TextSize = 12
            Mark.Font = Enum.Font.GothamBold
            Mark.Visible = false
            Mark.Parent = Toggle

            local state = default and true or false
            local function set(v)
                state = v and true or false
                Mark.Visible = state
                TweenService:Create(Toggle, TweenInfo.new(0.12), {
                    BackgroundColor3 = state and Theme.Accent or Theme.SearchBg
                }):Play()
                if callback then callback(state) end
            end
            Toggle.MouseButton1Click:Connect(function() set(not state) end)
            set(state)
            return {Set = set, Get = function() return state end}
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

-- 初始化 (默认选中第一个 Tab, 绑定菜单切换键)
function Neverlose:Init()
    local wo = self._windowObj
    if wo and #wo._tabs > 0 then
        wo:_selectTab(wo._tabs[1])
    end
    -- 默认切换键: RightShift
    UserInput.InputBegan:Connect(function(input, gpe)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if self._window then
                self._window.Visible = not self._window.Visible
            end
        end
    end)
end

-- 获取主题 (允许外部修改颜色)
function Neverlose:GetTheme()
    return Theme
end

return Neverlose
