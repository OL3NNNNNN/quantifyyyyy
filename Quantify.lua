-- [[ QUANTIFY ULTIMATE APEX PRO HUB - FULL NETWORK SUITE ]] --
-- Reverse-engineered for PlaceId: 73648930852061 & 106281373202161
-- Features: Multi-Batch Harvester, Instant Remote Inventory & Auto-Builder, Auto Cards/Difficulty,
-- Auto Wheel Spin, DCC Challenge Auto-Claim, Pet Auto-Evolve/Clear, Quest Automation, Full ESP & Exploits.

local RAW_URL = "https://raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy/refs/heads/main/Quantify.lua"
if getgenv then getgenv().QuantifySourceUrl = RAW_URL end

-- [[ AUTO-EXECUTE ON TELEPORT & RETRY ENGINE ]] --
local function setupAutoExecuteOnTeleport()
    local teleportQueue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queueonteleport
    if teleportQueue then
        local code = string.format("loadstring(game:HttpGet('%s'))()", RAW_URL)
        pcall(function()
            teleportQueue(code)
        end)
    end
end
setupAutoExecuteOnTeleport()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
        setupAutoExecuteOnTeleport()
    end
end)

-- Singleton Management
if getgenv and getgenv().QuantifyHubLoaded then
    if getgenv().QuantifyHubUI and typeof(getgenv().QuantifyHubUI.Destroy) == "function" then
        getgenv().QuantifyHubUI:Destroy()
    end
end
if getgenv then getgenv().QuantifyHubLoaded = true end

-- [[ ROBLOX SERVICES ]] --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

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
local CONFIG_FILE = "QuantifyApexConfig.json"

-- [[ REMOTES MAPPING & REVERSE-ENGINEERED NETWORK ]] --
local Remotes = {}
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)

local function cacheRemotes()
    if remotesFolder then
        for _, child in ipairs(remotesFolder:GetChildren()) do
            Remotes[child.Name] = child
        end
    end
end
cacheRemotes()

local function getRemote(name)
    if Remotes[name] then return Remotes[name] end
    if remotesFolder then
        local r = remotesFolder:FindFirstChild(name)
        if r then Remotes[name] = r return r end
    end
    return nil
end

local function fireRemote(name, ...)
    local remote = getRemote(name)
    if not remote then return false end
    local args = {...}
    return pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        elseif remote:IsA("BindableEvent") then
            remote:Fire(unpack(args))
        elseif remote:IsA("BindableFunction") then
            return remote:Invoke(unpack(args))
        end
    end)
end

-- [[ CONFIG STATE & PERSISTENCE ]] --
local Config = {
    -- Harvester Engine
    AutoFarm = true,
    CollectRange = 500,
    BatchHarvest = true,
    PrioritizeHighTierShapes = true,
    
    -- Network Auto-Builder
    AutoBuildStack = true,
    StackSpacing = 3.2,
    PrioritizeDroppers = true,
    AutoUpgradeExisting = true,
    DirectRemotePlacement = true,
    
    -- Match AI & Voting
    AutoVoteDifficulty = true,
    SelectedDifficulty = "Insane",
    AutoPickBestCard = true,
    AutoRetry = true,
    AutoOmniDropper = true,
    
    -- Rewards, Quests & Challenges
    AutoClaimQuests = true,
    AutoClaimDCC = true,
    AutoWheelSpin = true,
    AutoCollectEggs = true,
    AutoCrafterEject = true,
    AutoClaimDaily = true,
    
    -- Movement & Utilities
    SpeedBoost = false,
    SpeedValue = 50,
    InfiniteJump = false,
    NoClip = false,
    FullBright = false,
    ShapeESP = false,
    EggESP = false,
    AutoProximity = true,
    
    -- Box Engine
    AutoOpenBoxMode = "None",
    BoxStopThreshold = 500,
}

local uiBinders = {}

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

local function syncAllUiWithConfig()
    for key, updateFunc in pairs(uiBinders) do
        if Config[key] ~= nil and typeof(updateFunc) == "function" then
            pcall(function() updateFunc(Config[key]) end)
        end
    end
end

-- Character & Physics State
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local activeTargetPosition = nil

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    if Config.SpeedBoost and humanoid then
        humanoid.WalkSpeed = Config.SpeedValue
    end
end)

local function getLiveQubitNumber()
    local attr = player:GetAttribute("Qubits") or player:GetAttribute("Currency") or player:GetAttribute("Money") or player:GetAttribute("Cash")
    if attr and tonumber(attr) then return tonumber(attr) end
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local qubitObj = leaderstats:FindFirstChild("Qubits") or leaderstats:FindFirstChild("Qubit") or leaderstats:FindFirstChild("Cash")
        if qubitObj and tonumber(qubitObj.Value) then return tonumber(qubitObj.Value) end
    end
    return 0
end

local function formatNumber(num)
    if not num or type(num) ~= "number" then return "0" end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.2fK", num / 1e3)
    end
    return tostring(math.floor(num))
end

-- [[ THEME & COLOR PALETTE ]] --
local Colors = {
    Background = Color3.fromRGB(11, 13, 20),
    BackgroundSecondary = Color3.fromRGB(16, 20, 31),
    Card = Color3.fromRGB(22, 28, 44),
    CardBorder = Color3.fromRGB(38, 48, 74),
    Accent = Color3.fromRGB(114, 90, 245),
    AccentGlow = Color3.fromRGB(139, 92, 246),
    AccentCyan = Color3.fromRGB(6, 182, 212),
    AccentGold = Color3.fromRGB(245, 158, 11),
    AccentRed = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(248, 250, 252),
    TextMuted = Color3.fromRGB(148, 163, 184),
    ToggleOn = Color3.fromRGB(16, 185, 129),
    ToggleOff = Color3.fromRGB(51, 65, 85),
}

-- [[ UI INITIALIZATION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuantifyApexProUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent
if getgenv then getgenv().QuantifyHubUI = ScreenGui end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 410)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -205)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Colors.CardBorder
MainStroke.Thickness = 1.5

-- Window Drag System
local isDragging, dragStart, startPos = false, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - MainFrame.AbsolutePosition.Y < 46 then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- Title Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Colors.BackgroundSecondary
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 250, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "QUANTIFY <font color='#725AF5'>APEX PRO</font>"
Title.RichText = true
Title.TextColor3 = Colors.TextPrimary
Title.TextSize = 13.5
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Live Currency Pill
local QubitPill = Instance.new("Frame", Header)
QubitPill.Size = UDim2.new(0, 130, 0, 24)
QubitPill.Position = UDim2.new(1, -210, 0.5, -12)
QubitPill.BackgroundColor3 = Color3.fromRGB(26, 32, 50)
QubitPill.BorderSizePixel = 0
Instance.new("UICorner", QubitPill).CornerRadius = UDim.new(1, 0)
local pillStroke = Instance.new("UIStroke", QubitPill)
pillStroke.Color = Colors.AccentCyan
pillStroke.Thickness = 1

local QubitLabel = Instance.new("TextLabel", QubitPill)
QubitLabel.Size = UDim2.new(1, 0, 1, 0)
QubitLabel.BackgroundTransparency = 1
QubitLabel.Font = Enum.Font.GothamBold
QubitLabel.Text = "Qubits: 0"
QubitLabel.TextColor3 = Colors.AccentCyan
QubitLabel.TextSize = 9.5

-- Minimize & Close
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.TextMuted
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if getgenv then getgenv().QuantifyHubLoaded = false end
end)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -66, 0.5, -13)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = Colors.TextMuted
MinBtn.TextSize = 11
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and 46 or 410
    TweenService:Create(MainFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 520, 0, targetHeight)
    }):Play()
end)

-- Tab Bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 52)
TabBar.BackgroundTransparency = 1

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)

-- Scrolling Container
local ScrollContent = Instance.new("ScrollingFrame", MainFrame)
ScrollContent.Size = UDim2.new(1, -20, 1, -94)
ScrollContent.Position = UDim2.new(0, 10, 0, 90)
ScrollContent.BackgroundTransparency = 1
ScrollContent.BorderSizePixel = 0
ScrollContent.ScrollBarThickness = 3
ScrollContent.ScrollBarImageColor3 = Colors.Accent
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

-- Pages
local function createPage()
    local page = Instance.new("Frame", ScrollContent)
    page.Size = UDim2.new(1, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 6)
    return page
end

local PageFarm = createPage()
local PageBuilder = createPage()
local PageMatch = createPage()
local PageNetwork = createPage()
local PageSettings = createPage()
PageFarm.Visible = true

-- Tab Factory
local tabButtons = {}
local function createTab(name, icon, targetPage, isDefault)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.2, -4, 1, 0)
    btn.BackgroundColor3 = isDefault and Colors.Accent or Color3.fromRGB(15, 18, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Colors.TextPrimary
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        PageFarm.Visible = (targetPage == PageFarm)
        PageBuilder.Visible = (targetPage == PageBuilder)
        PageMatch.Visible = (targetPage == PageMatch)
        PageNetwork.Visible = (targetPage == PageNetwork)
        PageSettings.Visible = (targetPage == PageSettings)

        for _, other in ipairs(tabButtons) do
            TweenService:Create(other, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(15, 18, 28)}):Play()
        end
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Colors.Accent}):Play()
    end)

    table.insert(tabButtons, btn)
    return btn
end

createTab("Harvester", "⚡", PageFarm, true)
createTab("Builder", "🏗️", PageBuilder, false)
createTab("Match AI", "🎯", PageMatch, false)
createTab("Network", "🌐", PageNetwork, false)
createTab("Exploits", "⚙️", PageSettings, false)

-- [[ UI COMPONENT FACTORIES ]] --
local function createSectionHeader(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(text)
    lbl.TextColor3 = Colors.AccentCyan
    lbl.TextSize = 9.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function createToggle(parent, title, subtitle, configKey, callback)
    local defaultState = Config[configKey]
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
        subLabel.TextSize = 8.5
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
    local function applyVisual(newState)
        state = newState
        local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = state and Colors.ToggleOn or Colors.ToggleOff
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
    end

    switch.MouseButton1Click:Connect(function()
        state = not state
        applyVisual(state)
        Config[configKey] = state
        callback(state)
        saveConfigToFile()
    end)

    uiBinders[configKey] = function(newVal)
        applyVisual(newVal)
        callback(newVal)
    end
end

local function createInputRow(parent, labelText, configKey, callback)
    local defaultValue = Config[configKey]
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
    input.Size = UDim2.new(0, 75, 0, 24)
    input.Position = UDim2.new(1, -85, 0.5, -12)
    input.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
    input.Font = Enum.Font.GothamBold
    input.Text = tostring(defaultValue)
    input.TextColor3 = Colors.AccentCyan
    input.TextSize = 10
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    input.FocusLost:Connect(function()
        callback(input.Text)
        Config[configKey] = tonumber(input.Text) or input.Text
        saveConfigToFile()
    end)

    uiBinders[configKey] = function(newVal)
        input.Text = tostring(newVal)
        callback(newVal)
    end
end

local function createActionButton(parent, title, subtitle, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color or Colors.Card
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = title .. (subtitle and ("  —  <font color='#94A3B8'>" .. subtitle .. "</font>") or "")
    lbl.RichText = true
    lbl.TextColor3 = Colors.TextPrimary
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = color or Colors.Card}):Play()
        callback()
    end)
end

-- =========================================================================
-- POPULATE TAB 1: HARVESTER ENGINE
-- =========================================================================
createSectionHeader(PageFarm, "Shape Sweeper Engine")
createToggle(PageFarm, "Auto Collect Shapes", "Sweeps shapes instantly", "AutoFarm", function(v) Config.AutoFarm = v end)
createToggle(PageFarm, "Multi-Batch Harvest (15 Shapes/Tick)", "Clears 15 geometries simultaneously", "BatchHarvest", function(v) Config.BatchHarvest = v end)
createToggle(PageFarm, "Prioritize Rare Shapes", "Hexagon > Circle > Square > Pentagon", "PrioritizeHighTierShapes", function(v) Config.PrioritizeHighTierShapes = v end)
createInputRow(PageFarm, "Collection Radius (Studs)", "CollectRange", function(val)
    local n = tonumber(val)
    if n and n > 0 then Config.CollectRange = n end
end)

createSectionHeader(PageFarm, "Production Accelerators")
createToggle(PageFarm, "Auto Fire OmniDropper Remote", "Dispatches OmniDropper network pulse", "AutoOmniDropper", function(v) Config.AutoOmniDropper = v end)
createToggle(PageFarm, "Auto Eject Crafter Items", "Clears finished crafted geometries", "AutoCrafterEject", function(v) Config.AutoCrafterEject = v end)

-- =========================================================================
-- POPULATE TAB 2: APEX VERTICAL AUTO-BUILDER
-- =========================================================================
createSectionHeader(PageBuilder, "Apex Chute Stacker")
createToggle(PageBuilder, "Auto-Build Vertical Stack", "Deploys droppers & upgraders", "AutoBuildStack", function(v) Config.AutoBuildStack = v end)
createToggle(PageBuilder, "Top-Mounted Droppers (Apex)", "Mounts droppers at top of chute", "PrioritizeDroppers", function(v) Config.PrioritizeDroppers = v end)
createToggle(PageBuilder, "Auto-Upgrade Existing Buildings", "Triggers prompt upgrades", "AutoUpgradeExisting", function(v) Config.AutoUpgradeExisting = v end)
createInputRow(PageBuilder, "Vertical Stack Spacing", "StackSpacing", function(val)
    local n = tonumber(val)
    if n and n > 0 then Config.StackSpacing = n end
end)
createActionButton(PageBuilder, "Reset Stacking Origin", "Recalculates conveyor drop baseline", Color3.fromRGB(30, 41, 59), function()
    placedUpgradersRegistry = {}
    currentStackHeight = 3.5
end)

-- =========================================================================
-- POPULATE TAB 3: MATCH AI & DIFFICULTY
-- =========================================================================
createSectionHeader(PageMatch, "Match Voting & Card Selector")
createToggle(PageMatch, "Auto Vote Difficulty", "Votes chosen difficulty on match start", "AutoVoteDifficulty", function(v) Config.AutoVoteDifficulty = v end)
createInputRow(PageMatch, "Target Difficulty", "SelectedDifficulty", function(val)
    if val and val:len() > 1 then Config.SelectedDifficulty = val end
end)
createToggle(PageMatch, "Auto Select Best Card", "Emerald > Multipliers > Rare > Gold", "AutoPickBestCard", function(v) Config.AutoPickBestCard = v end)
createToggle(PageMatch, "Auto Retry on Loss", "Immediately sends GameEndedEvent retry", "AutoRetry", function(v) Config.AutoRetry = v end)

-- =========================================================================
-- POPULATE TAB 4: NETWORK REWARDS
-- =========================================================================
createSectionHeader(PageNetwork, "Daily & Challenge Automation")
createToggle(PageNetwork, "Auto Claim Daily Quests", "Hooks DailyQuest & CompletedQuest", "AutoClaimQuests", function(v) Config.AutoClaimQuests = v end)
createToggle(PageNetwork, "Auto Claim DCC Challenges", "Hooks DCCReward & DCCComplete", "AutoClaimDCC", function(v) Config.AutoClaimDCC = v end)
createToggle(PageNetwork, "Auto Daily Wheel Spin", "Fires WheelSpin remote", "AutoWheelSpin", function(v) Config.AutoWheelSpin = v end)
createToggle(PageNetwork, "Auto Collect Event Eggs", "Sweeps Nest models", "AutoCollectEggs", function(v) Config.AutoCollectEggs = v end)
createActionButton(PageNetwork, "⚡ Force Claim All Network Rewards", "Triggers all claim remotes now", Color3.fromRGB(30, 41, 59), function()
    fireRemote("DailyQuest", "Claim")
    fireRemote("ClaimDaily")
    fireRemote("CompletedQuest", "Claim")
    fireRemote("DCCReward")
    fireRemote("DCCComplete")
    fireRemote("WheelSpin")
    fireRemote("GroupChestOpen")
end)

-- =========================================================================
-- POPULATE TAB 5: EXPLOITS & ESP
-- =========================================================================
createSectionHeader(PageSettings, "Character Physics & Visuals")
createToggle(PageSettings, "Speed Multiplier", "Modifies WalkSpeed", "SpeedBoost", function(v)
    Config.SpeedBoost = v
    if humanoid then humanoid.WalkSpeed = v and Config.SpeedValue or 16 end
end)
createInputRow(PageSettings, "WalkSpeed Value", "SpeedValue", function(val)
    local n = tonumber(val)
    if n and n > 0 then
        Config.SpeedValue = n
        if Config.SpeedBoost and humanoid then humanoid.WalkSpeed = n end
    end
end)
createToggle(PageSettings, "Infinite Jump", "Jump mid-air continuously", "InfiniteJump", function(v) Config.InfiniteJump = v end)
createToggle(PageSettings, "NoClip", "Pass through barriers", "NoClip", function(v) Config.NoClip = v end)
createToggle(PageSettings, "FullBright", "Maximum visibility lighting", "FullBright", function(v)
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
createToggle(PageSettings, "Shape ESP (Cyan)", "Highlights active geometries", "ShapeESP", function(v) Config.ShapeESP = v end)
createToggle(PageSettings, "Egg ESP (Gold)", "Highlights event nests", "EggESP", function(v) Config.EggESP = v end)

-- Initial Sync of UI with Loaded Config
syncAllUiWithConfig()

-- =========================================================================
-- ENGINE CORE ROUTINES
-- =========================================================================

local function triggerButton(btn)
    if not btn then return end
    if typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Click) end)
    elseif typeof(getconnections) == "function" then
        pcall(function()
            for _, conn in pairs(getconnections(btn.Activated)) do conn:Fire() end
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
        end)
    end
end

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

-- Harvester Target Discovery
local function getActiveShapesList()
    if not Config.AutoFarm or not humanoidRootPart then return {} end
    local maxRange = Config.CollectRange or 500
    local hrpPos = humanoidRootPart.Position
    local candidates = {}

    local function scoreShape(part)
        local n = part.Name:lower()
        local s = 10
        if n:find("hexagon") or n:find("hex") then s = 100
        elseif n:find("circle") or n:find("sphere") then s = 80
        elseif n:find("square") or n:find("cube") then s = 60
        elseif n:find("pentagon") then s = 50
        elseif n:find("triangle") then s = 40 end
        return s
    end

    local function checkCandidate(part)
        if part and part:IsA("BasePart") and part.Transparency < 0.95 then
            local dist = (part.Position - hrpPos).Magnitude
            if dist <= maxRange then
                table.insert(candidates, {
                    Part = part,
                    Distance = dist,
                    Score = Config.PrioritizeHighTierShapes and scoreShape(part) or 10
                })
            end
        end
    end

    local primaryFolders = {
        workspace:FindFirstChild("Parts"),
        workspace:FindFirstChild("Shapesother"),
        workspace:FindFirstChild("ChudParts"),
        workspace:FindFirstChild("Shapes")
    }

    for _, folder in ipairs(primaryFolders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("BasePart") then checkCandidate(item)
                elseif item:IsA("Model") and not item.Name:find("Nest") and not item.Name:find("Building") then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                    checkCandidate(part)
                end
            end
        end
    end

    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("BasePart") and not item.Anchored and item.Name ~= "Terrain" then
            checkCandidate(item)
        end
    end

    table.sort(candidates, function(a, b)
        if a.Score ~= b.Score then return a.Score > b.Score end
        return a.Distance < b.Distance
    end)
    return candidates
end

-- Conveyor Baseline Finder
local fixedStackBasePosition = nil
local function findConveyorBasePosition()
    if fixedStackBasePosition then return fixedStackBasePosition end
    local map = workspace:FindFirstChild("Map") or workspace
    local candidates = {}

    for _, item in ipairs(map:GetDescendants()) do
        if item:IsA("BasePart") then
            local n = item.Name:lower()
            local pName = item.Parent and item.Parent.Name:lower() or ""
            if n:find("conveyor") or n:find("belt") or n:find("touch") or n:find("collector") or n:find("sell") or pName:find("conveyor") or pName:find("seller") then
                table.insert(candidates, item)
            end
        end
    end

    if #candidates > 0 and humanoidRootPart then
        table.sort(candidates, function(a, b)
            return (a.Position - humanoidRootPart.Position).Magnitude < (b.Position - humanoidRootPart.Position).Magnitude
        end)
        fixedStackBasePosition = candidates[1].Position + Vector3.new(0, 1.5, 0)
        return fixedStackBasePosition
    end

    if humanoidRootPart then
        fixedStackBasePosition = humanoidRootPart.Position + Vector3.new(0, -1, 3)
        return fixedStackBasePosition
    end
    return Vector3.new(0, 5, 0)
end

-- High-Throughput Auto-Builder Engine
local placedUpgradersRegistry = {}
local currentStackHeight = 3.5
local lastBuildAttempt = 0

local function autoBuildVerticalStack()
    if not Config.AutoBuildStack or not humanoidRootPart then return end
    local now = tick()
    if now - lastBuildAttempt < 0.25 then return end
    lastBuildAttempt = now

    local basePos = findConveyorBasePosition()
    local currentQubits = getLiveQubitNumber()

    -- 1. Auto-Upgrade Existing Buildings
    if Config.AutoUpgradeExisting then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local pName = desc.Parent and desc.Parent.Name:lower() or ""
                local ppName = desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name:lower() or ""
                if pName:find("upgrad") or pName:find("dropper") or ppName:find("upgrad") or ppName:find("dropper") then
                    pcall(function()
                        desc.HoldDuration = 0
                        if typeof(fireproximityprompt) == "function" then
                            fireproximityprompt(desc, 0)
                        end
                    end)
                end
            end
        end
    end

    -- 2. Inventory Machinery Deployment
    local buildingInv = getRemote("BuildingInventory")
    if buildingInv then
        task.spawn(function()
            local success, inv = pcall(function() return buildingInv:InvokeServer() end)
            if success and typeof(inv) == "table" then
                for itemName, count in pairs(inv) do
                    local qty = tonumber(count) or 1
                    if qty > 0 and not placedUpgradersRegistry["INV_" .. itemName] then
                        placedUpgradersRegistry["INV_" .. itemName] = true
                        
                        local isDropper = itemName:lower():find("dropper") or itemName:lower():find("spawn")
                        local stackHeightOffset = isDropper and (currentStackHeight + 3.0) or currentStackHeight
                        if not isDropper then currentStackHeight = currentStackHeight + (Config.StackSpacing or 3.2) end
                        
                        local stackPos = basePos + Vector3.new(0, stackHeightOffset, 0)
                        local stackCF = CFrame.new(stackPos)
                        
                        fireRemote("PlaceBuilding", itemName, stackCF)
                        fireRemote("PlaceBuilding", itemName, stackPos)
                        fireRemote("BuildingPurchase", itemName, stackCF)
                    end
                end
            end
        end)
    end

    -- 3. Shop Machinery Scanner & Deployer
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        local droppersList = {}
        local upgradersList = {}

        for _, gui in ipairs(pGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                local itemName = gui.Name
                local pName = gui.Parent and gui.Parent.Name or ""
                local fullText = ""
                for _, lbl in ipairs(gui:GetDescendants()) do
                    if lbl:IsA("TextLabel") then fullText = fullText .. " " .. lbl.Text end
                end

                local lowerItem = itemName:lower()
                local lowerText = fullText:lower()
                local lowerParent = pName:lower()

                local isDropper = lowerItem:find("dropper") or lowerText:find("dropper") or lowerParent:find("dropper") or lowerText:find("spawner") or lowerItem:find("spawn")
                local isUpgrader = lowerItem:find("upgrader") or lowerText:find("upgrader") or lowerParent:find("upgrader") or lowerText:find("multiplier") or lowerText:find("processor") or lowerText:find("pad") or lowerText:find("filter")

                if (isDropper or isUpgrader) and not placedUpgradersRegistry[itemName] then
                    local price = 0
                    local cleanPrice = fullText:gsub(",", ""):match("%$(%d+)") or fullText:gsub(",", ""):match("(%d+)%s*Q") or fullText:gsub(",", ""):match("(%d+)")
                    if cleanPrice and tonumber(cleanPrice) then price = tonumber(cleanPrice) end

                    local candidateObj = {
                        Button = gui,
                        Name = itemName,
                        Price = price,
                        IsDropper = isDropper
                    }
                    if isDropper then table.insert(droppersList, candidateObj)
                    else table.insert(upgradersList, candidateObj) end
                end
            end
        end

        local sortFunc = function(a, b) return a.Price < b.Price end
        table.sort(droppersList, sortFunc)
        table.sort(upgradersList, sortFunc)

        local targetQueue = {}
        if Config.PrioritizeDroppers and #droppersList > 0 then
            for _, d in ipairs(droppersList) do table.insert(targetQueue, d) end
            for _, u in ipairs(upgradersList) do table.insert(targetQueue, u) end
        else
            for _, u in ipairs(upgradersList) do table.insert(targetQueue, u) end
            for _, d in ipairs(droppersList) do table.insert(targetQueue, d) end
        end

        local countBuilt = 0
        for _, chosen in ipairs(targetQueue) do
            if countBuilt >= 3 then break end
            if currentQubits == 0 or chosen.Price <= currentQubits or chosen.Price == 0 then
                placedUpgradersRegistry[chosen.Name] = true
                countBuilt = countBuilt + 1
                triggerButton(chosen.Button)

                local stackHeightOffset = currentStackHeight
                if chosen.IsDropper then
                    stackHeightOffset = currentStackHeight + 3.2
                else
                    currentStackHeight = currentStackHeight + (Config.StackSpacing or 3.2)
                end

                local stackPos = basePos + Vector3.new(0, stackHeightOffset, 0)
                local stackCF = CFrame.new(stackPos)

                task.spawn(function()
                    fireRemote("BuildingPurchase", chosen.Name, stackCF)
                    fireRemote("BuildingPurchase", chosen.Name, stackPos)
                    fireRemote("BoughtItem", chosen.Name)
                    fireRemote("PlaceBuilding", chosen.Name, stackCF)
                end)
            end
        end
    end
end

-- OmniDropper & Crafter Pulse
local lastOmniFire = 0
local function autoOmniAndCrafter()
    local now = tick()
    if now - lastOmniFire < 0.5 then return end
    lastOmniFire = now

    if Config.AutoOmniDropper then
        fireRemote("OmniDropper")
    end

    if Config.AutoCrafterEject then
        fireRemote("EjectCrafter")
    end
end

-- Card Evaluator & Selector
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
            if (c.R > 0.7 and c.G < 0.3 and c.B < 0.3) or (c.R > 0.8 and c.G < 0.4) then score = score + 1000
            elseif (c.R > 0.75 and c.G > 0.6 and c.B < 0.3) then score = score + 850
            elseif (c.G > 0.7 and c.R < 0.4 and c.B < 0.5) then score = score + 750
            elseif (c.R > 0.5 and c.B > 0.6 and c.G < 0.4) then score = score + 700 end
        end

        if elem:IsA("TextLabel") and elem.Visible then
            fullText = fullText .. " " .. string.lower(elem.Text)
            if displayName == cardObj.Name and elem.Text:len() > 1 then displayName = elem.Text end
        end
    end

    if fullText:find("emerald") or cardName:find("emerald") then score = score + 950 end
    if fullText:find("ruby") or cardName:find("ruby") then score = score + 950 end
    if fullText:find("sapphire") or cardName:find("sapphire") then score = score + 900 end
    if fullText:find("diamond") or cardName:find("diamond") then score = score + 850 end
    if fullText:find("time sacrifice") or cardName:find("timesacrifice") then score = score + 650 end

    local mult = fullText:match("x(%d+%.?%d*)") or fullText:match("(%d+%.?%d*)x")
    if mult and tonumber(mult) then score = score + (tonumber(mult) * 120) end
    return score, displayName
end

local lastCardPick = 0
local function autoPickBestCard()
    if not Config.AutoPickBestCard then return end
    local now = tick()
    if now - lastCardPick < 0.6 then return end

    local pGui = player:FindFirstChild("PlayerGui")
    local gameHUD = pGui and pGui:FindFirstChild("GameHUD")
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
        triggerButton(bestBtn)
        task.spawn(function()
            fireRemote("Cards", bestCardName)
            fireRemote("CardsEvent", bestCardName)
        end)
    end
end

-- Difficulty Voter (Remotes + GUI)
local lastVote = 0
local function autoVoteDifficulty()
    if not Config.AutoVoteDifficulty then return end
    local now = tick()
    if now - lastVote < 0.8 then return end
    lastVote = now

    local targetDifficulty = Config.SelectedDifficulty or "Insane"
    
    task.spawn(function()
        fireRemote("Difficulty", "vote", targetDifficulty)
        fireRemote("Difficulty", targetDifficulty)
        fireRemote("DifficultyEvent", "vote", targetDifficulty)
        fireRemote("DifficultyEvent", targetDifficulty)
    end)

    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                local fullText = ""
                for _, lbl in ipairs(gui:GetDescendants()) do
                    if lbl:IsA("TextLabel") then fullText = fullText .. " " .. lbl.Text end
                end
                if gui:IsA("TextButton") then fullText = fullText .. " " .. gui.Text end

                local lowerName = gui.Name:lower()
                local lowerText = fullText:lower()
                local targetLower = targetDifficulty:lower()

                if lowerName:find(targetLower) or lowerText:find(targetLower) then
                    triggerButton(gui)
                end
            end
        end
    end
end

-- Retry on Loss
local lastRetry = 0
local function autoRetry()
    if not Config.AutoRetry then return end
    local now = tick()
    if now - lastRetry < 1 then return end
    local pGui = player:FindFirstChild("PlayerGui")
    if not pGui then return end

    local isLossVisible = false
    for _, gui in ipairs(pGui:GetDescendants()) do
        if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
            local t = string.lower(gui.Text)
            if t:find("you lose") or t:find("retry") or t:find("game over") then
                isLossVisible = true
                break
            end
        end
    end

    if isLossVisible then
        lastRetry = now
        placedUpgradersRegistry = {}
        fixedStackBasePosition = nil
        currentStackHeight = 3.5
        task.spawn(function()
            setupAutoExecuteOnTeleport()
            fireRemote("GameEndedEvent", "Again")
        end)
    end
end

-- Background Network Claims
local lastNetClaims = 0
local function autoNetworkClaims()
    local now = tick()
    if now - lastNetClaims < 6 then return end
    lastNetClaims = now

    if Config.AutoClaimQuests then
        task.spawn(function()
            fireRemote("DailyQuest", "Claim")
            fireRemote("ClaimDaily")
            fireRemote("CompletedQuest", "Claim")
            fireRemote("QuestFunc", "Claim")
        end)
    end

    if Config.AutoClaimDCC then
        task.spawn(function()
            fireRemote("DCCReward")
            fireRemote("DCCComplete")
            fireRemote("DCCFunc", "Claim")
        end)
    end

    if Config.AutoWheelSpin then
        fireRemote("WheelSpin")
    end
end

-- Full ESP Visual Highlight System
local espHighlights = {}
local function updateESP()
    if not Config.ShapeESP and not Config.EggESP then
        for part, hl in pairs(espHighlights) do
            if hl and hl.Parent then hl:Destroy() end
            espHighlights[part] = nil
        end
        return
    end

    if Config.ShapeESP then
        local primaryFolders = {
            workspace:FindFirstChild("Parts"),
            workspace:FindFirstChild("Shapesother"),
            workspace:FindFirstChild("ChudParts"),
            workspace:FindFirstChild("Shapes")
        }
        for _, folder in ipairs(primaryFolders) do
            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    local target = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
                    if target and target.Transparency < 0.95 and not espHighlights[target] then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ApexShapeESP"
                        hl.FillColor = Colors.AccentCyan
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Adornee = target
                        hl.Parent = target
                        espHighlights[target] = hl
                    end
                end
            end
        end
    end

    if Config.EggESP then
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, item in ipairs(map:GetChildren()) do
                if item.Name == "Nest" and item:IsA("Model") and not espHighlights[item] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ApexEggESP"
                    hl.FillColor = Colors.AccentGold
                    hl.OutlineColor = Color3.fromRGB(255, 215, 0)
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0
                    hl.Adornee = item
                    hl.Parent = item
                    espHighlights[item] = hl
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(1.5) do pcall(updateESP) end
end)

-- =========================================================================
-- MASTER CONCURRENT LOOP
-- =========================================================================
task.spawn(function()
    while task.wait(0.02) do
        local newTarget = nil
        
        if Config.AutoFarm and humanoidRootPart then
            local shapes = getActiveShapesList()
            if #shapes > 0 then
                local bestShape = shapes[1].Part
                newTarget = bestShape.Position + Vector3.new(0, 0.4, 0)

                local batchLimit = Config.BatchHarvest and math.min(#shapes, 15) or 1
                for i = 1, batchLimit do
                    local sPart = shapes[i].Part
                    if sPart and sPart.Parent and typeof(firetouchinterest) == "function" then
                        firetouchinterest(humanoidRootPart, sPart, 0)
                        firetouchinterest(humanoidRootPart, sPart, 1)
                    end
                end

                task.spawn(function()
                    fireRemote("CollectShape", bestShape)
                    fireRemote("Harvest", bestShape)
                    fireRemote("TouchShape", bestShape)
                    fireRemote("Collect", bestShape)
                end)
            end
        end

        activeTargetPosition = newTarget
        
        autoVoteDifficulty()
        autoPickBestCard()
        autoRetry()
        autoBuildVerticalStack()
        autoOmniAndCrafter()
        autoNetworkClaims()
    end
end)

-- Live Currency Monitor Loop
task.spawn(function()
    while task.wait(1.2) do
        local q = getLiveQubitNumber()
        QubitLabel.Text = string.format("Qubits: %s", formatNumber(q))
    end
end)

-- Physics Lock Engine
RunService.Heartbeat:Connect(function()
    if not Config.AutoFarm then return end
    if activeTargetPosition and humanoidRootPart and humanoid and humanoid.Health > 0 then
        humanoidRootPart.CFrame = CFrame.new(activeTargetPosition)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)

print("🚀 QUANTIFY ULTIMATE APEX PRO HUB LOADED SUCCESSFULLY!")
