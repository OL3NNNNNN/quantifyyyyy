-- [[ QUANTIFY PRO HUB - APEX V28.0 AUTO-INVENTORY POPPER & CHUTE BUILDER ]] --
-- Source: https://raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy/refs/heads/main/Quantify.lua

local RAW_URL = "https://raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy/refs/heads/main/Quantify.lua"
if getgenv then getgenv().QuantifySourceUrl = RAW_URL end

-- Auto-Execute Persistence across Teleports
if typeof(queue_on_teleport) == "function" then
    queue_on_teleport(string.format([[
        task.wait(1.2)
        loadstring(game:HttpGet(%q))()
    ]], RAW_URL))
elseif syn and typeof(syn.queue_on_teleport) == "function" then
    syn.queue_on_teleport(string.format([[
        task.wait(1.2)
        loadstring(game:HttpGet(%q))()
    ]], RAW_URL))
end

-- Singleton UI Manager
if getgenv and getgenv().QuantifyHubLoaded then
    if getgenv().QuantifyHubUI and typeof(getgenv().QuantifyHubUI.Destroy) == "function" then
        getgenv().QuantifyHubUI:Destroy()
    end
end
if getgenv then getgenv().QuantifyHubLoaded = true end

-- [[ SERVICES ]] --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function getSafeGuiParent()
    if typeof(gethui) == "function" then
        return gethui()
    elseif pcall(function() return CoreGui.Name end) then
        return CoreGui
    end
    return playerGui
end

local guiParent = getSafeGuiParent()
local CONFIG_FILE = "QuantifyProConfig.json"

-- [[ CONFIG STATE & PERSISTENCE ]] --
local Config = {
    AutoFarm = true,
    AutoCollectEggs = false,
    AutoVoteDifficulty = true,
    SelectedDifficulty = "Insane",
    AutoPickBestCard = true,
    AutoRetry = true,
    AutoClaimQuests = true,
    
    -- Auto-Builder Feature (Chute Stacking Mode)
    AutoBuildStack = true,
    
    -- Movement & Utilities
    SpeedBoost = false,
    SpeedValue = 45,
    InfiniteJump = false,
    NoClip = false,
    FullBright = false,
    ShapeESP = false,
    AutoProximity = true,
    
    AutoOpenBoxMode = "None",
    BoxStopThreshold = 500,
}

local function saveConfigToFile()
    if typeof(writefile) == "function" then
        pcall(function()
            local json = HttpService:JSONEncode(Config)
            writefile(CONFIG_FILE, json)
        end)
    end
end

local function loadConfigFromFile()
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        if isfile(CONFIG_FILE) then
            local success, content = pcall(function() return readfile(CONFIG_FILE) end)
            if success and content and content:len() > 2 then
                local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                if decodeSuccess and typeof(decoded) == "table" then
                    for k, v in pairs(decoded) do
                        Config[k] = v
                    end
                end
            end
        end
    end
end

loadConfigFromFile()

local Stats = {
    RetriesHandled = 0,
    CardsVoted = 0,
    EggsCollected = 0,
    LastVotedCard = "None",
    BoxesOpened = 0,
}

-- Character & Physics State
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local activeTargetPosition = nil
local placedUpgradersRegistry = {}
local fixedStackBasePosition = nil
local currentStackHeight = 3.5

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    activeTargetPosition = nil
    placedUpgradersRegistry = {}
    fixedStackBasePosition = nil
    currentStackHeight = 3.5
    
    if Config.SpeedBoost and humanoid then
        humanoid.WalkSpeed = Config.SpeedValue
    end
end)

-- Safe Remote Helper
local cachedRemotes = {}
local function getRemote(name)
    if cachedRemotes[name] then return cachedRemotes[name] end
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        local r = remotesFolder:FindFirstChild(name)
        if r then
            cachedRemotes[name] = r
            return r
        end
    end
    return nil
end

-- Button Trigger Helper
local function triggerButton(btn)
    if not btn then return end
    if typeof(firesignal) == "function" then
        firesignal(btn.Activated)
        firesignal(btn.MouseButton1Click)
        firesignal(btn.MouseButton1Down)
        firesignal(btn.MouseButton1Up)
    elseif typeof(getconnections) == "function" then
        for _, conn in pairs(getconnections(btn.Activated)) do conn:Fire() end
        for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
    end
end

-- Live Qubit Reader
local cachedQubits = 0
local function getLiveQubitNumber()
    local attr = player:GetAttribute("Qubits") or player:GetAttribute("Currency") or player:GetAttribute("Money")
    if attr and tonumber(attr) then 
        cachedQubits = tonumber(attr)
        return cachedQubits 
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local qubitObj = leaderstats:FindFirstChild("Qubits") or leaderstats:FindFirstChild("Qubit") or leaderstats:FindFirstChild("Cash")
        if qubitObj and tonumber(qubitObj.Value) then 
            cachedQubits = tonumber(qubitObj.Value)
            return cachedQubits 
        end
    end

    return cachedQubits
end

local function formatNumber(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- [[ THEME & PALETTE ]] --
local Colors = {
    Background = Color3.fromRGB(11, 13, 20),
    Header = Color3.fromRGB(18, 21, 32),
    Card = Color3.fromRGB(20, 24, 38),
    CardBorder = Color3.fromRGB(34, 40, 62),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentCyan = Color3.fromRGB(56, 189, 248),
    AccentGreen = Color3.fromRGB(16, 185, 129),
    AccentGold = Color3.fromRGB(245, 158, 11),
    AccentRed = Color3.fromRGB(244, 63, 94),
    AccentPurple = Color3.fromRGB(168, 85, 247),
    TextPrimary = Color3.fromRGB(248, 250, 252),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    ToggleOff = Color3.fromRGB(38, 44, 66),
    ToggleOn = Color3.fromRGB(99, 102, 241),
}

-- [[ USER INTERFACE ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuantifyHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

if getgenv then getgenv().QuantifyHubUI = ScreenGui end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 560)
MainFrame.Position = UDim2.new(0.04, 0, 0.12, 0)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Colors.CardBorder
MainStroke.Thickness = 1.4

local GlowAccent = Instance.new("Frame", MainFrame)
GlowAccent.Size = UDim2.new(1, 0, 0, 2)
GlowAccent.Position = UDim2.new(0, 0, 0, 0)
GlowAccent.BackgroundColor3 = Colors.Accent
GlowAccent.BorderSizePixel = 0

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 48)
Header.Position = UDim2.new(0, 0, 0, 2)
Header.BackgroundColor3 = Colors.Header
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local LogoIcon = Instance.new("TextLabel", Header)
LogoIcon.Size = UDim2.new(0, 30, 0, 30)
LogoIcon.Position = UDim2.new(0, 12, 0.5, -15)
LogoIcon.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Text = "⚡"
LogoIcon.TextColor3 = Colors.AccentCyan
LogoIcon.TextSize = 15
Instance.new("UICorner", LogoIcon).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 50, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "QUANTIFY <font color='#6366F1'>PRO</font> <font color='#38BDF8'>V28</font>"
Title.RichText = true
Title.TextColor3 = Colors.TextPrimary
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -66, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 50)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "–"
MinBtn.TextColor3 = Colors.TextSecondary
MinBtn.TextSize = 14
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(38, 25, 35)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Colors.AccentRed
CloseBtn.TextSize = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Status Pill
local StatusPill = Instance.new("Frame", MainFrame)
StatusPill.Size = UDim2.new(1, -20, 0, 36)
StatusPill.Position = UDim2.new(0, 10, 0, 56)
StatusPill.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
StatusPill.BorderSizePixel = 0
Instance.new("UICorner", StatusPill).CornerRadius = UDim.new(0, 9)

local StatusStroke = Instance.new("UIStroke", StatusPill)
StatusStroke.Color = Color3.fromRGB(38, 48, 75)
StatusStroke.Thickness = 1

local QubitIcon = Instance.new("TextLabel", StatusPill)
QubitIcon.Size = UDim2.new(0, 26, 1, 0)
QubitIcon.Position = UDim2.new(0, 8, 0, 0)
QubitIcon.BackgroundTransparency = 1
QubitIcon.Font = Enum.Font.GothamBold
QubitIcon.Text = "💎"
QubitIcon.TextSize = 14

local QubitLabel = Instance.new("TextLabel", StatusPill)
QubitLabel.Size = UDim2.new(0.55, 0, 1, 0)
QubitLabel.Position = UDim2.new(0, 34, 0, 0)
QubitLabel.BackgroundTransparency = 1
QubitLabel.Font = Enum.Font.GothamBold
QubitLabel.Text = "Qubits: Syncing..."
QubitLabel.TextColor3 = Colors.AccentCyan
QubitLabel.TextSize = 12
QubitLabel.TextXAlignment = Enum.TextXAlignment.Left

local CardBadge = Instance.new("TextLabel", StatusPill)
CardBadge.Size = UDim2.new(0.42, 0, 1, 0)
CardBadge.Position = UDim2.new(0.58, 0, 0, 0)
CardBadge.BackgroundTransparency = 1
CardBadge.Font = Enum.Font.GothamMedium
CardBadge.Text = "Inventory Pop: ON"
CardBadge.TextColor3 = Colors.AccentGold
CardBadge.TextSize = 10
CardBadge.TextXAlignment = Enum.TextXAlignment.Right

-- Tab Bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 98)
TabBar.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
TabBar.BorderSizePixel = 0
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 9)

local TabList = Instance.new("UIListLayout", TabBar)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 4)

-- Scroll Area
local ScrollContent = Instance.new("ScrollingFrame", MainFrame)
ScrollContent.Size = UDim2.new(1, -20, 1, -142)
ScrollContent.Position = UDim2.new(0, 10, 0, 138)
ScrollContent.BackgroundTransparency = 1
ScrollContent.BorderSizePixel = 0
ScrollContent.ScrollBarThickness = 3
ScrollContent.ScrollBarImageColor3 = Colors.Accent
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

-- Pages
local LobbyPage = Instance.new("Frame", ScrollContent)
LobbyPage.Size = UDim2.new(1, 0, 0, 0)
LobbyPage.BackgroundTransparency = 1
LobbyPage.AutomaticSize = Enum.AutomaticSize.Y
LobbyPage.Visible = true

local LobbyLayout = Instance.new("UIListLayout", LobbyPage)
LobbyLayout.FillDirection = Enum.FillDirection.Vertical
LobbyLayout.Padding = UDim.new(0, 6)

local MainPage = Instance.new("Frame", ScrollContent)
MainPage.Size = UDim2.new(1, 0, 0, 0)
MainPage.BackgroundTransparency = 1
MainPage.AutomaticSize = Enum.AutomaticSize.Y
MainPage.Visible = false

local MainLayout = Instance.new("UIListLayout", MainPage)
MainLayout.FillDirection = Enum.FillDirection.Vertical
MainLayout.Padding = UDim.new(0, 6)

local CreditsPage = Instance.new("Frame", ScrollContent)
CreditsPage.Size = UDim2.new(1, 0, 0, 0)
CreditsPage.BackgroundTransparency = 1
CreditsPage.AutomaticSize = Enum.AutomaticSize.Y
CreditsPage.Visible = false

local CreditsLayout = Instance.new("UIListLayout", CreditsPage)
CreditsLayout.FillDirection = Enum.FillDirection.Vertical
CreditsLayout.Padding = UDim.new(0, 6)

-- Tab Buttons
local tabButtons = {}
local function createTab(name, icon, index, targetPage)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.333, -3, 1, 0)
    btn.BackgroundColor3 = (index == 1) and Colors.Accent or Color3.fromRGB(15, 18, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Colors.TextPrimary
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseButton1Click:Connect(function()
        LobbyPage.Visible = (targetPage == LobbyPage)
        MainPage.Visible = (targetPage == MainPage)
        CreditsPage.Visible = (targetPage == CreditsPage)

        for _, otherBtn in ipairs(tabButtons) do
            TweenService:Create(otherBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(15, 18, 28)}):Play()
        end
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Colors.Accent}):Play()
    end)

    table.insert(tabButtons, btn)
    return btn
end

createTab("Lobby", "🏛️", 1, LobbyPage)
createTab("Match AI", "⚡", 2, MainPage)
createTab("Settings", "⚙️", 3, CreditsPage)

-- [[ COMPONENT FACTORIES ]] --
local function createSectionHeader(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(text)
    lbl.TextColor3 = Colors.TextMuted
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function createToggle(parent, title, subtitle, defaultState, callback)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, subtitle and 44 or 36)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Colors.CardBorder
    stroke.Thickness = 1

    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size = UDim2.new(1, -65, 0, subtitle and 20 or 36)
    titleLabel.Position = UDim2.new(0, 12, 0, subtitle and 4 or 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Colors.TextPrimary
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    if subtitle then
        local subLabel = Instance.new("TextLabel", card)
        subLabel.Size = UDim2.new(1, -65, 0, 16)
        subLabel.Position = UDim2.new(0, 12, 0, 24)
        subLabel.BackgroundTransparency = 1
        subLabel.Font = Enum.Font.Gotham
        subLabel.Text = subtitle
        subLabel.TextColor3 = Colors.TextMuted
        subLabel.TextSize = 9
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    local switch = Instance.new("TextButton", card)
    switch.Size = UDim2.new(0, 38, 0, 20)
    switch.Position = UDim2.new(1, -48, 0.5, -10)
    switch.BackgroundColor3 = defaultState and Colors.ToggleOn or Colors.ToggleOff
    switch.Text = ""
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = state and Colors.ToggleOn or Colors.ToggleOff

        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
        callback(state)
        saveConfigToFile()
    end)
end

local function createActionButton(parent, title, subtitle, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, subtitle and 42 or 34)
    btn.BackgroundColor3 = color or Color3.fromRGB(25, 30, 48)
    btn.Text = ""
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Colors.CardBorder
    stroke.Thickness = 1

    local titleLabel = Instance.new("TextLabel", btn)
    titleLabel.Size = UDim2.new(1, -20, 0, subtitle and 18 or 34)
    titleLabel.Position = UDim2.new(0, 10, 0, subtitle and 4 or 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Colors.TextPrimary
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    if subtitle then
        local subLabel = Instance.new("TextLabel", btn)
        subLabel.Size = UDim2.new(1, -20, 0, 16)
        subLabel.Position = UDim2.new(0, 10, 0, 22)
        subLabel.BackgroundTransparency = 1
        subLabel.Font = Enum.Font.Gotham
        subLabel.Text = subtitle
        subLabel.TextColor3 = Colors.TextMuted
        subLabel.TextSize = 9
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent}):Play()
        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or Color3.fromRGB(25, 30, 48)}):Play()
        end)
        callback()
    end)
    return btn
end

local function createInputRow(parent, labelText, defaultValue, callback)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Colors.CardBorder
    stroke.Thickness = 1

    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -95, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = labelText
    label.TextColor3 = Colors.TextPrimary
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox", card)
    input.Size = UDim2.new(0, 80, 0, 24)
    input.Position = UDim2.new(1, -90, 0.5, -12)
    input.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
    input.Font = Enum.Font.GothamBold
    input.Text = tostring(defaultValue)
    input.TextColor3 = Colors.AccentCyan
    input.TextSize = 11
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = Colors.Accent
    inputStroke.Thickness = 1

    input.FocusLost:Connect(function()
        local num = tonumber(input.Text) or defaultValue
        input.Text = tostring(num)
        callback(num)
        saveConfigToFile()
    end)
end

-- ===================================
-- TAB 1: ZERO-DELAY LOOTBOX ENGINE
-- ===================================
local function buySpecificBoxInstant(boxName)
    local currentQubits = getLiveQubitNumber()
    if currentQubits > 0 and currentQubits <= Config.BoxStopThreshold then
        Config.AutoOpenBoxMode = "None"
        return false
    end

    local boxRemote = getRemote("BuildingBox") or getRemote("BuildingBoxes")
    if boxRemote then
        task.spawn(function()
            pcall(function()
                if boxRemote:IsA("RemoteFunction") then
                    boxRemote:InvokeServer(boxName)
                else
                    boxRemote:FireServer(boxName)
                end
                Stats.BoxesOpened = Stats.BoxesOpened + 1
            end)
        end)
        return true
    end
    return false
end

-- Burst Loop
local NUM_WORKERS = 8
for i = 1, NUM_WORKERS do
    task.spawn(function()
        while true do
            if Config.AutoOpenBoxMode ~= "None" then
                local currentQubits = getLiveQubitNumber()
                if currentQubits > 0 and currentQubits <= Config.BoxStopThreshold then
                    Config.AutoOpenBoxMode = "None"
                    task.wait(0.2)
                else
                    buySpecificBoxInstant(Config.AutoOpenBoxMode)
                    RunService.RenderStepped:Wait()
                end
            else
                task.wait(0.1)
            end
        end
    end)
end

local function clickSidebarButton(sideName, buttonName)
    local side = playerGui:FindFirstChild("Side")
    if side then
        local section = side:FindFirstChild(sideName)
        if section then
            local holder = section:FindFirstChild(buttonName)
            if holder then
                local btn = holder:FindFirstChildWhichIsA("GuiButton")
                if btn then
                    triggerButton(btn)
                    return
                end
            end
        end
    end

    local hud = playerGui:FindFirstChild("HUD")
    if hud then
        local frame = hud:FindFirstChild(buttonName)
        if frame then frame.Visible = not frame.Visible end
    end
end

local function teleportTo(pos)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

createSectionHeader(LobbyPage, "🚀 Zero-Delay Box Openers")
createActionButton(LobbyPage, "📦 Buy 1x Classic Box (100 Q)", "Instant direct remote invocation", Color3.fromRGB(30, 45, 75), function() buySpecificBoxInstant("Classic Box") end)
createActionButton(LobbyPage, "💎 Buy 1x Rare Box (500 Q)", "Instant direct remote invocation", Color3.fromRGB(30, 65, 80), function() buySpecificBoxInstant("Rare Box") end)
createActionButton(LobbyPage, "👑 Buy 1x Diamond Box (2,500 Q)", "Instant direct remote invocation", Color3.fromRGB(75, 40, 85), function() buySpecificBoxInstant("Diamond Box") end)

createToggle(LobbyPage, "⚡ Parallel Burst: Classic", "Rapid zero-delay purchase loop", (Config.AutoOpenBoxMode == "Classic Box"), function(v) Config.AutoOpenBoxMode = v and "Classic Box" or "None" end)
createToggle(LobbyPage, "⚡ Parallel Burst: Rare", "Rapid zero-delay purchase loop", (Config.AutoOpenBoxMode == "Rare Box"), function(v) Config.AutoOpenBoxMode = v and "Rare Box" or "None" end)
createToggle(LobbyPage, "⚡ Parallel Burst: Diamond", "Rapid zero-delay purchase loop", (Config.AutoOpenBoxMode == "Diamond Box"), function(v) Config.AutoOpenBoxMode = v and "Diamond Box" or "None" end)

createInputRow(LobbyPage, "🛑 Stop Buying Balance Limit:", Config.BoxStopThreshold, function(val) Config.BoxStopThreshold = val end)

createSectionHeader(LobbyPage, "🚪 Lobby Teleports & Free Rewards")
createActionButton(LobbyPage, "🚪 Teleport to Match Queue Door", "Instantly enters Match Door 1", Color3.fromRGB(95, 35, 45), function()
    local door = workspace:FindFirstChild("Teleporters") and workspace.Teleporters:FindFirstChild("1") and workspace.Teleporters["1"]:FindFirstChild("FrontDoor")
    if door then
        teleportTo(door.Position + Vector3.new(0, 2, 0))
    else
        teleportTo(Vector3.new(204.2, 12.5, -27.8))
    end
end)

createActionButton(LobbyPage, "🎁 Claim Free Group Chest", "Teleports to Group Reward Chest", Color3.fromRGB(25, 75, 55), function()
    teleportTo(Vector3.new(191.1, 5.5, 18.4))
end)

createSectionHeader(LobbyPage, "🏛️ Lobby UI Menus")
createActionButton(LobbyPage, "🛒 Open Building Shop", "Toggle Building Shop Menu", Color3.fromRGB(28, 35, 55), function() clickSidebarButton("Left", "BuildingShop") end)
createActionButton(LobbyPage, "🎁 Open Daily Rewards", "Toggle Daily Rewards Calendar", Color3.fromRGB(28, 35, 55), function() clickSidebarButton("Right", "DailyRewards") end)
createActionButton(LobbyPage, "📜 Open Quests Menu", "Toggle Daily & Completed Quests", Color3.fromRGB(28, 35, 55), function()
    local questBtn = playerGui:FindFirstChild("Side") and playerGui.Side:FindFirstChild("Bottom") and playerGui.Side.Bottom:FindFirstChild("QuestButton") and playerGui.Side.Bottom.QuestButton:FindFirstChild("Click")
    if questBtn then triggerButton(questBtn) else clickSidebarButton("HUD", "Quests") end
end)

-- ===================================
-- TAB 2: MATCH AI, DIFFICULTY & AUTO-BUILDER
-- ===================================
createSectionHeader(MainPage, "⚡ Match Automation Core")
createToggle(MainPage, "Auto Collect Shapes", "Instantly touches and collects active shapes", Config.AutoFarm, function(v) Config.AutoFarm = v end)
createToggle(MainPage, "🏗️ Auto-Open Inventory & Vertical Stack", "Opens inventory automatically & stacks droppers above upgraders", Config.AutoBuildStack, function(v) Config.AutoBuildStack = v end)
createToggle(MainPage, "🥚 Auto Collect Event Eggs", "Background remote claim & proximity collection", Config.AutoCollectEggs, function(v) Config.AutoCollectEggs = v end)
createToggle(MainPage, "Auto Select Best Card", "Ranks Red, Gold, Emerald & Multiplier Cards", Config.AutoPickBestCard, function(v) Config.AutoPickBestCard = v end)
createToggle(MainPage, "Auto Retry On Loss", "Restarts match immediately on defeat", Config.AutoRetry, function(v) Config.AutoRetry = v end)
createToggle(MainPage, "Auto Claim Daily Quests", "Claims quest rewards in background", Config.AutoClaimQuests, function(v) Config.AutoClaimQuests = v end)

createSectionHeader(MainPage, "🎯 Difficulty Auto-Vote Selector")
createToggle(MainPage, "Auto Vote Difficulty", "Automatically votes your chosen difficulty on match start", Config.AutoVoteDifficulty, function(v) Config.AutoVoteDifficulty = v end)

local DiffCard = Instance.new("Frame", MainPage)
DiffCard.Size = UDim2.new(1, 0, 0, 48)
DiffCard.BackgroundColor3 = Colors.Card
DiffCard.BorderSizePixel = 0
Instance.new("UICorner", DiffCard).CornerRadius = UDim.new(0, 8)
local DiffCardStroke = Instance.new("UIStroke", DiffCard)
DiffCardStroke.Color = Colors.CardBorder
DiffCardStroke.Thickness = 1

local DiffGrid = Instance.new("UIListLayout", DiffCard)
DiffGrid.FillDirection = Enum.FillDirection.Horizontal
DiffGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
DiffGrid.VerticalAlignment = Enum.VerticalAlignment.Center
DiffGrid.Padding = UDim.new(0, 4)

local difficultyButtons = {}
local difficulties = {
    {Name = "Easy", Color = Color3.fromRGB(16, 185, 129)},
    {Name = "Normal", Color = Color3.fromRGB(56, 189, 248)},
    {Name = "Hard", Color = Color3.fromRGB(245, 158, 11)},
    {Name = "Insane", Color = Color3.fromRGB(244, 63, 94)},
    {Name = "UNQUANTIFIABLE", Short = "UNQUANT", Color = Color3.fromRGB(168, 85, 247)}
}

for _, diff in ipairs(difficulties) do
    local dBtn = Instance.new("TextButton", DiffCard)
    dBtn.Size = UDim2.new(0, (diff.Name == "UNQUANTIFIABLE") and 70 or 60, 0, 32)
    dBtn.BackgroundColor3 = (Config.SelectedDifficulty == diff.Name) and diff.Color or Color3.fromRGB(14, 17, 26)
    dBtn.Font = Enum.Font.GothamBold
    dBtn.Text = diff.Short or diff.Name
    dBtn.TextColor3 = Colors.TextPrimary
    dBtn.TextSize = 9
    Instance.new("UICorner", dBtn).CornerRadius = UDim.new(0, 6)

    dBtn.MouseButton1Click:Connect(function()
        Config.SelectedDifficulty = diff.Name
        for _, btnData in ipairs(difficultyButtons) do
            TweenService:Create(btnData.Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 17, 26)}):Play()
        end
        TweenService:Create(dBtn, TweenInfo.new(0.15), {BackgroundColor3 = diff.Color}):Play()
        saveConfigToFile()
    end)

    table.insert(difficultyButtons, {Button = dBtn, Data = diff})
end

createSectionHeader(MainPage, "🏃 Movement & Physics Exploits")
createToggle(MainPage, "⚡ Speed Multiplier", "Walk at 45 studs/sec speed", Config.SpeedBoost, function(v)
    Config.SpeedBoost = v
    if humanoid then humanoid.WalkSpeed = v and Config.SpeedValue or 16 end
end)

createToggle(MainPage, "🕊️ Infinite Jump", "Jump infinitely in mid-air", Config.InfiniteJump, function(v)
    Config.InfiniteJump = v
end)

createToggle(MainPage, "👻 NoClip", "Walk through all walls and barriers", Config.NoClip, function(v)
    Config.NoClip = v
end)

createSectionHeader(MainPage, "👁️ Visuals & Environment")
createToggle(MainPage, "💡 FullBright", "Disables all map shadows & night darkness", Config.FullBright, function(v)
    Config.FullBright = v
    if v then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.GlobalShadows = true
    end
end)

createToggle(MainPage, "🎯 Shape & Egg ESP", "Outlines dropped shapes and rare eggs with glow", Config.ShapeESP, function(v)
    Config.ShapeESP = v
end)

-- ===================================
-- TAB 3: SETTINGS & CONFIG PERSISTENCE
-- ===================================
local function createCreditCard(title, desc, color)
    local card = Instance.new("Frame", CreditsPage)
    card.Size = UDim2.new(1, 0, 0, 48)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Colors.CardBorder
    stroke.Thickness = 1

    local h = Instance.new("TextLabel", card)
    h.Size = UDim2.new(1, -20, 0, 18)
    h.Position = UDim2.new(0, 10, 0, 6)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.Text = title
    h.TextColor3 = color or Colors.AccentCyan
    h.TextSize = 11
    h.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextLabel", card)
    d.Size = UDim2.new(1, -20, 0, 16)
    d.Position = UDim2.new(0, 10, 0, 24)
    d.BackgroundTransparency = 1
    d.Font = Enum.Font.Gotham
    d.Text = desc
    d.TextColor3 = Colors.TextSecondary
    d.TextSize = 10
    d.TextXAlignment = Enum.TextXAlignment.Left
end

createSectionHeader(CreditsPage, "💾 Configuration & Auto-Save")
createActionButton(CreditsPage, "💾 Save Current Configuration", "Saves all toggles, speed & difficulty settings", Color3.fromRGB(25, 65, 50), function()
    saveConfigToFile()
end)

createActionButton(CreditsPage, "🔄 Reload Configuration", "Reloads saved config from disk", Color3.fromRGB(35, 55, 95), function()
    loadConfigFromFile()
end)

createSectionHeader(CreditsPage, "⭐ Release & Repository Info")
createCreditCard("Quantify Pro Hub (Apex V28.0)", "Complete Auto-Inventory & Vertical Chute Suite", Colors.Accent)
createCreditCard("Developer", "Created by OL3N for Quantify", Colors.AccentGold)
createCreditCard("GitHub Script URL", "raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy", Colors.AccentCyan)
createCreditCard("Universal Compatibility", "Works on Medium, Macsploit & UNC Executors", Colors.AccentGreen)

createActionButton(CreditsPage, "📋 Copy GitHub Raw URL", "Copies raw loadstring link to clipboard", Color3.fromRGB(35, 55, 95), function()
    if typeof(setclipboard) == "function" then
        setclipboard(RAW_URL)
    end
end)

-- Minimize Trigger
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ScrollContent.Visible = not isMinimized
    TabBar.Visible = not isMinimized
    StatusPill.Visible = not isMinimized
    local newSize = isMinimized and UDim2.new(0, 360, 0, 50) or UDim2.new(0, 360, 0, 560)
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = newSize}):Play()
    MinBtn.Text = isMinimized and "+" or "–"
end)

-- [[ AUTOMATION CORE ENGINE ]] --

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- NoClip Stepper
RunService.Stepped:Connect(function()
    if Config.NoClip and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Auto Fast Proximity Prompt Trigger
task.spawn(function()
    while task.wait(0.25) do
        if Config.AutoProximity and character and humanoidRootPart then
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local part = prompt.Parent
                    if part and part:IsA("BasePart") then
                        if (part.Position - humanoidRootPart.Position).Magnitude <= prompt.MaxActivationDistance + 2 then
                            if typeof(fireproximityprompt) == "function" then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Helper: Locate Main Conveyor Base Position
local function findConveyorBasePosition()
    if fixedStackBasePosition then return fixedStackBasePosition end

    local map = workspace:FindFirstChild("Map")
    if map then
        for _, item in ipairs(map:GetDescendants()) do
            if item:IsA("BasePart") and (item.Name:lower():find("conveyor") or item.Name:lower():find("belt") or item.Name:lower():find("drop")) then
                fixedStackBasePosition = item.Position
                return fixedStackBasePosition
            end
        end
    end

    if humanoidRootPart then
        fixedStackBasePosition = humanoidRootPart.Position + Vector3.new(3, 0, 0)
        return fixedStackBasePosition
    end

    return Vector3.new(0, 5, 0)
end

-- Helper: Ensure Inventory UI Is Open
local function ensureInventoryIsOpen()
    -- Check if Inventory / Shop Frame is already open
    local invOpen = false
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("Frame") or gui:IsA("ScrollingFrame")) and gui.Visible then
            local n = gui.Name:lower()
            if n:find("inventory") or n:find("buildingshop") or n:find("shop") or n:find("dropper") then
                invOpen = true
                break
            end
        end
    end

    if not invOpen then
        -- Method 1: Press 'C' keybind via VirtualInputManager
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
        end

        -- Method 2: Click [C] Inventory button on HUD
        for _, btn in ipairs(playerGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local t = btn:IsA("TextButton") and btn.Text:lower() or ""
                local n = btn.Name:lower()
                if t:find("inventory") or n:find("inventory") or t:find("[c]") then
                    triggerButton(btn)
                end
            end
        end
    end
end

-- [[ PERFECT VERTICAL CONVEYOR STACK BUILDER ]] --
local lastBuildAttempt = 0

local function autoBuildVerticalStack()
    if not Config.AutoBuildStack or not humanoidRootPart then return end
    local now = tick()
    if now - lastBuildAttempt < 1.2 then return end
    lastBuildAttempt = now

    -- Auto-open inventory pop-up
    ensureInventoryIsOpen()

    local basePos = findConveyorBasePosition()
    local placeRemote = getRemote("PlaceBuilding") or getRemote("Place") or getRemote("Build") or getRemote("PlaceItem")
    local buyRemote = getRemote("BuyBuilding") or getRemote("BuyItem") or getRemote("Buy")
    local candidates = {}

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local itemName = gui.Name
            local pName = gui.Parent and gui.Parent.Name or ""
            local fullText = ""
            
            for _, lbl in ipairs(gui:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Visible then
                    fullText = fullText .. " " .. lbl.Text
                end
            end

            local isDropper = itemName:lower():find("dropper") or fullText:lower():find("dropper") or pName:lower():find("dropper")
            local isUpgrader = itemName:lower():find("upgrader") or fullText:lower():find("upgrader") or pName:lower():find("upgrader")

            if (isDropper or isUpgrader) and not placedUpgradersRegistry[itemName] then
                local price = 999999
                local cleanPrice = fullText:gsub(",", ""):match("%$(%d+)") or fullText:gsub(",", ""):match("(%d+)%s*Q") or fullText:gsub(",", ""):match("(%d+)")
                if cleanPrice and tonumber(cleanPrice) then
                    price = tonumber(cleanPrice)
                end

                table.insert(candidates, {
                    Button = gui,
                    Name = itemName,
                    Price = price,
                    IsDropper = isDropper
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Price < b.Price
    end)

    if #candidates > 0 then
        local chosen = candidates[1]
        placedUpgradersRegistry[chosen.Name] = true
        
        triggerButton(chosen.Button)

        if buyRemote then
            task.spawn(function()
                pcall(function()
                    if buyRemote:IsA("RemoteFunction") then
                        buyRemote:InvokeServer(chosen.Name)
                    else
                        buyRemote:FireServer(chosen.Name)
                    end
                end)
            end)
        end

        local stackCFrame = CFrame.new(basePos + Vector3.new(0, currentStackHeight, 0))
        currentStackHeight = currentStackHeight + 2.5

        if placeRemote then
            task.spawn(function()
                pcall(function()
                    if placeRemote:IsA("RemoteFunction") then
                        placeRemote:InvokeServer(chosen.Name, stackCFrame)
                    else
                        placeRemote:FireServer(chosen.Name, stackCFrame)
                    end
                end)
            end)
        end
    end
end

-- [[ BACKGROUND PROXIMITY EGG GRABBER ]] --
task.spawn(function()
    while task.wait(0.8) do
        if Config.AutoCollectEggs and humanoidRootPart then
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, item in ipairs(map:GetChildren()) do
                    if item.Name == "Nest" and item:IsA("Model") then
                        for _, desc in ipairs(item:GetDescendants()) do
                            if desc:IsA("BasePart") and desc.Transparency < 0.95 then
                                if typeof(firetouchinterest) == "function" then
                                    firetouchinterest(humanoidRootPart, desc, 0)
                                    firetouchinterest(humanoidRootPart, desc, 1)
                                end
                            elseif desc:IsA("ProximityPrompt") and desc.Enabled then
                                if typeof(fireproximityprompt) == "function" then
                                    fireproximityprompt(desc)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Claim Hatching Slots
task.spawn(function()
    while task.wait(1.0) do
        if Config.AutoCollectEggs then
            local hatchSlots = playerGui:FindFirstChild("HatchingSlots")
            if hatchSlots and hatchSlots.Enabled then
                for _, btn in ipairs(hatchSlots:GetDescendants()) do
                    if btn:IsA("GuiButton") and btn.Visible then
                        local n = string.lower(btn.Name)
                        if n:find("claim") or n:find("collect") or n:find("button") then
                            triggerButton(btn)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ ADVANCED COLOR & MULTIPLIER CARD EVALUATOR ]] --
local function rateCard(cardObj)
    local cardName = string.lower(cardObj.Name)
    local fullText = ""
    local displayName = cardObj.Name
    local score = 10

    for _, elem in ipairs(cardObj:GetDescendants()) do
        if elem:IsA("GuiObject") and elem.Visible then
            local c = elem.BackgroundColor3
            local stroke = elem:FindFirstChildWhichIsA("UIStroke")
            if stroke then c = stroke.Color end
            
            if (c.R > 0.7 and c.G < 0.3 and c.B < 0.3) or (c.R > 0.8 and c.G < 0.4) then
                score = score + 1000
            elseif (c.R > 0.75 and c.G > 0.6 and c.B < 0.3) then
                score = score + 850
            elseif (c.G > 0.7 and c.R < 0.4 and c.B < 0.5) then
                score = score + 750
            elseif (c.R > 0.5 and c.B > 0.6 and c.G < 0.4) then
                score = score + 700
            end
        end

        if elem:IsA("TextLabel") and elem.Visible then
            fullText = fullText .. " " .. string.lower(elem.Text)
            if displayName == cardObj.Name and elem.Text:len() > 1 then
                displayName = elem.Text
            end
        end
    end

    if fullText:find("emerald") or cardName:find("emerald") then score = score + 950 end
    if fullText:find("ruby") or cardName:find("ruby") then score = score + 950 end
    if fullText:find("sapphire") or cardName:find("sapphire") then score = score + 900 end
    if fullText:find("amethyst") or cardName:find("amethyst") then score = score + 880 end
    if fullText:find("diamond") or cardName:find("diamond") then score = score + 850 end
    if fullText:find("prismatic") or fullText:find("rainbow") then score = score + 850 end

    if fullText:find("time sacrifice") or cardName:find("timesacrifice") then score = score + 650 end
    if fullText:find("stack overflow") or cardName:find("stackoverflow") then score = score + 600 end
    if fullText:find("worthy hand") or cardName:find("worthyhand") then score = score + 550 end
    if fullText:find("midas") or cardName:find("midas") then score = score + 530 end
    if fullText:find("moss") or cardName:find("moss") then score = score + 500 end
    if fullText:find("golden") or cardName:find("golden") or fullText:find("gold") then score = score + 480 end
    if fullText:find("heavy") or cardName:find("heavy") then score = score + 450 end
    if fullText:find("shiny") or cardName:find("shiny") then score = score + 430 end
    if fullText:find("singularity") or fullText:find("void") or fullText:find("quantum") then score = score + 420 end

    local mult = fullText:match("x(%d+%.?%d*)") or fullText:match("(%d+%.?%d*)x")
    if mult and tonumber(mult) then
        score = score + (tonumber(mult) * 120)
    end
    local pct = fullText:match("%+(%d+)%%")
    if pct and tonumber(pct) then
        score = score + (tonumber(pct) * 2)
    end

    if fullText:find("overclock") or fullText:find("turbo") then score = score + 250 end
    if fullText:find("speedy") or fullText:find("conveyor") then score = score + 220 end
    if fullText:find("rush hour") or fullText:find("faster") then score = score + 200 end

    if fullText:find("hexagon") or cardName:find("hexagon") then score = score + 120 end
    if fullText:find("circle") or cardName:find("circle") then score = score + 100 end
    if fullText:find("square") or cardName:find("square") then score = score + 80 end
    if fullText:find("pentagon") or cardName:find("pentagon") then score = score + 60 end

    return score, displayName
end

local lastCardPick = 0
local function autoPickBestCard()
    if not Config.AutoPickBestCard then return end
    local now = tick()
    if now - lastCardPick < 0.8 then return end

    local gameHUD = playerGui:FindFirstChild("GameHUD")
    local cardsFrame = gameHUD and gameHUD:FindFirstChild("Cards")
    if not cardsFrame or not cardsFrame.Visible then return end

    local bestBtn = nil
    local highestScore = -1
    local bestCardName = ""

    local holders = cardsFrame:FindFirstChild("Back") and cardsFrame.Back:FindFirstChild("Holders")
    if holders then
        for _, holder in ipairs(holders:GetChildren()) do
            for _, cardHolder in ipairs(holder:GetChildren()) do
                local card = cardHolder:FindFirstChild("Card") or cardHolder
                if card then
                    local clickBtn = card:FindFirstChild("Click") or card:FindFirstChildWhichIsA("GuiButton") or card:FindFirstChildWhichIsA("ImageButton")
                    if clickBtn and clickBtn.Visible then
                        local score, name = rateCard(cardHolder)
                        if score > highestScore then
                            highestScore = score
                            bestBtn = clickBtn
                            bestCardName = name
                        end
                    end
                end
            end
        end
    end

    if bestBtn and highestScore > 0 then
        lastCardPick = now
        Stats.CardsVoted = Stats.CardsVoted + 1
        Stats.LastVotedCard = bestCardName
        CardBadge.Text = "Card: " .. string.sub(bestCardName, 1, 12)
        triggerButton(bestBtn)
    end
end

-- 2. Dual-Layer Auto-Vote Difficulty (Remote + GUI Auto-Click)
local lastVote = 0
local function autoVoteDifficulty()
    if not Config.AutoVoteDifficulty then return end
    local now = tick()
    if now - lastVote < 0.8 then return end
    lastVote = now

    local diffRemote = getRemote("Difficulty")
    if diffRemote then
        task.spawn(function()
            pcall(function() diffRemote:InvokeServer("vote", Config.SelectedDifficulty) end)
            pcall(function() diffRemote:InvokeServer(Config.SelectedDifficulty) end)
            pcall(function() diffRemote:FireServer("vote", Config.SelectedDifficulty) end)
            pcall(function() diffRemote:FireServer(Config.SelectedDifficulty) end)
        end)
    end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local n = string.lower(gui.Name)
            local t = gui:IsA("TextButton") and string.lower(gui.Text) or ""
            local targetName = string.lower(Config.SelectedDifficulty)

            if n == targetName or t == targetName or n:find(targetName) or t:find(targetName) then
                triggerButton(gui)
            end
        end
    end
end

-- 3. Auto Retry on Loss
local lastRetry = 0
local function autoRetry()
    if not Config.AutoRetry then return end
    local now = tick()
    if now - lastRetry < 1 then return end

    local isLossVisible = false
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
            local t = string.lower(gui.Text)
            if t:find("you lose") or t:find("retry") then
                isLossVisible = true
                break
            end
        end
    end

    if isLossVisible then
        lastRetry = now
        Stats.RetriesHandled = Stats.RetriesHandled + 1
        placedUpgradersRegistry = {}
        fixedStackBasePosition = nil
        currentStackHeight = 3.5
        local endedEvent = getRemote("GameEndedEvent")
        if endedEvent then
            task.spawn(function()
                pcall(function()
                    endedEvent:FireServer("Again")
                end)
            end)
        end
    end
end

-- 4. Auto Claim Quests
local lastQuestClaim = 0
local function autoClaimQuests()
    if not Config.AutoClaimQuests then return end
    local now = tick()
    if now - lastQuestClaim < 10 then return end
    lastQuestClaim = now

    local dailyEvent = getRemote("DailyQuest")
    local completedEvent = getRemote("CompletedQuest")

    task.spawn(function()
        if dailyEvent then
            pcall(function() dailyEvent:FireServer("Claim") end)
            pcall(function() dailyEvent:FireServer("claim") end)
        end
        if completedEvent then
            pcall(function() completedEvent:FireServer("Claim") end)
        end
    end)
end

-- 5. Shape Collector Target Finder (Universal Harvester)
local function getActiveShape()
    if not Config.AutoFarm then return nil end

    local primaryFolders = {
        workspace:FindFirstChild("Parts"),
        workspace:FindFirstChild("Shapesother"),
        workspace:FindFirstChild("ChudParts"),
        workspace:FindFirstChild("Shapes")
    }

    for _, folder in ipairs(primaryFolders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("BasePart") and item.Transparency < 0.95 then
                    return item
                elseif item:IsA("Model") and not item.Name:find("Nest") and not item.Name:find("Building") then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                    if part and part.Transparency < 0.95 then return part end
                end
            end
        end
    end

    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("BasePart") and item.Transparency < 0.95 and not item.Anchored and item.Name ~= "Terrain" then
            return item
        end
    end

    return nil
end

-- 6. Main Automation Loop
task.spawn(function()
    while task.wait(0.03) do
        local newTarget = nil
        
        if Config.AutoFarm then
            local shape = getActiveShape()
            if shape then
                newTarget = shape.Position + Vector3.new(0, 0.4, 0)
                
                if humanoidRootPart and typeof(firetouchinterest) == "function" then
                    firetouchinterest(humanoidRootPart, shape, 0)
                    firetouchinterest(humanoidRootPart, shape, 1)
                end
            end
        end

        activeTargetPosition = newTarget
        
        autoVoteDifficulty()
        autoPickBestCard()
        autoRetry()
        autoClaimQuests()
        autoBuildVerticalStack()
    end
end)

-- 7. Live Qubit Monitor Loop
task.spawn(function()
    while task.wait(1.5) do
        local q = getLiveQubitNumber()
        QubitLabel.Text = string.format("Qubits: %s", formatNumber(q))
    end
end)

-- 8. Target-Only Physics Lock
RunService.Heartbeat:Connect(function()
    if not Config.AutoFarm then return end

    if activeTargetPosition and humanoidRootPart and humanoid and humanoid.Health > 0 then
        humanoidRootPart.CFrame = CFrame.new(activeTargetPosition)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)
