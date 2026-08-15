-- [[ Quantify Pro Hub - Complete 3-Tab Suite ]] --
-- Source: https://raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy/refs/heads/main/Quantify.lua

local RAW_URL = "https://raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy/refs/heads/main/Quantify.lua"
if getgenv then getgenv().QuantifySourceUrl = RAW_URL end

-- Auto-Execute / Teleport Persistence
if typeof(queue_on_teleport) == "function" then
    queue_on_teleport(string.format([[
        task.wait(1.5)
        loadstring(game:HttpGet(%q))()
    ]], RAW_URL))
elseif syn and typeof(syn.queue_on_teleport) == "function" then
    syn.queue_on_teleport(string.format([[
        task.wait(1.5)
        loadstring(game:HttpGet(%q))()
    ]], RAW_URL))
end

-- Prevent Multi-Instance UI Duplication
if getgenv and getgenv().QuantifyHubLoaded then
    if getgenv().QuantifyHubUI and typeof(getgenv().QuantifyHubUI.Destroy) == "function" then
        getgenv().QuantifyHubUI:Destroy()
    end
end
if getgenv then getgenv().QuantifyHubLoaded = true end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

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
local PLACE_ID = 73648930852061

-- Positions
local spawnPos = Vector3.new(62.154415130615234, 25.5, 1298.9)

-- Safe Non-Blocking Remote Fetcher Helper
local function getRemote(name)
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        return remotesFolder:FindFirstChild(name)
    end
    return nil
end

-- Config State
local Config = {
    AutoFarm = true,
    AutoVoteInsane = true,
    AutoRetry = true,
    AutoClaimQuests = true,
}

local Stats = {
    RetriesHandled = 0
}

-- Character & Physics State
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local currentDestination = spawnPos

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    currentDestination = spawnPos
end)

-- Live Qubit Balance Reader
local function getLiveQubits()
    local attr = player:GetAttribute("Qubits") or player:GetAttribute("Currency") or player:GetAttribute("Money")
    if attr then return tostring(attr) end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local qubitObj = leaderstats:FindFirstChild("Qubits") or leaderstats:FindFirstChild("Qubit") or leaderstats:FindFirstChild("Cash")
        if qubitObj then return tostring(qubitObj.Value) end
    end

    local getData = getRemote("GetData")
    if getData and getData:IsA("RemoteFunction") then
        local success, data = pcall(function() return getData:InvokeServer() end)
        if success and typeof(data) == "table" and data.Qubits then
            return tostring(data.Qubits)
        end
    end

    for _, label in ipairs(playerGui:GetDescendants()) do
        if label:IsA("TextLabel") and label.Visible then
            local text = label.Text
            if text:find("Qubit") or text:match("%d+[,%d]*%s*Q") then
                return text
            end
        end
    end

    return "0"
end

-- [[ MODERN GLASSMORPHIC UI ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuantifyHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

if getgenv then getgenv().QuantifyHubUI = ScreenGui end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 430)
MainFrame.Position = UDim2.new(0.04, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(42, 47, 65)
UIStroke.Thickness = 1.2

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local AccentLine = Instance.new("Frame", Header)
AccentLine.Size = UDim2.new(1, 0, 0, 1)
AccentLine.Position = UDim2.new(0, 0, 1, -1)
AccentLine.BackgroundColor3 = Color3.fromRGB(90, 105, 240)
AccentLine.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "QUANTIFY  <font color='#5A69F0'>PRO HUB</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(240, 242, 250)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -34, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(180, 185, 205)
MinBtn.TextSize = 13
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- 3-Tab Selector Bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, -20, 0, 30)
TabBar.Position = UDim2.new(0, 10, 0, 48)
TabBar.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", TabBar)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 5)

-- Scrollable Content Area
local ScrollContent = Instance.new("ScrollingFrame", MainFrame)
ScrollContent.Size = UDim2.new(1, -20, 1, -88)
ScrollContent.Position = UDim2.new(0, 10, 0, 82)
ScrollContent.BackgroundTransparency = 1
ScrollContent.BorderSizePixel = 0
ScrollContent.ScrollBarThickness = 4
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
LobbyLayout.Padding = UDim.new(0, 5)

local MainPage = Instance.new("Frame", ScrollContent)
MainPage.Size = UDim2.new(1, 0, 0, 0)
MainPage.BackgroundTransparency = 1
MainPage.AutomaticSize = Enum.AutomaticSize.Y
MainPage.Visible = false

local MainLayout = Instance.new("UIListLayout", MainPage)
MainLayout.FillDirection = Enum.FillDirection.Vertical
MainLayout.Padding = UDim.new(0, 5)

local CreditsPage = Instance.new("Frame", ScrollContent)
CreditsPage.Size = UDim2.new(1, 0, 0, 0)
CreditsPage.BackgroundTransparency = 1
CreditsPage.AutomaticSize = Enum.AutomaticSize.Y
CreditsPage.Visible = false

local CreditsLayout = Instance.new("UIListLayout", CreditsPage)
CreditsLayout.FillDirection = Enum.FillDirection.Vertical
CreditsLayout.Padding = UDim.new(0, 6)

-- Tab Button Factory
local tabButtons = {}
local function createTab(name, index, targetPage)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.333, -4, 1, 0)
    btn.BackgroundColor3 = (index == 1) and Color3.fromRGB(90, 105, 240) or Color3.fromRGB(25, 28, 38)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(240, 242, 255)
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        LobbyPage.Visible = (targetPage == LobbyPage)
        MainPage.Visible = (targetPage == MainPage)
        CreditsPage.Visible = (targetPage == CreditsPage)

        for _, otherBtn in ipairs(tabButtons) do
            otherBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
        end
        btn.BackgroundColor3 = Color3.fromRGB(90, 105, 240)
    end)

    table.insert(tabButtons, btn)
    return btn
end

createTab("1. Lobby", 1, LobbyPage)
createTab("2. Main Game", 2, MainPage)
createTab("3. Credits", 3, CreditsPage)

-- [[ UI COMPONENT HELPERS ]] --
local function createToggle(parent, text, defaultState, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = Color3.fromRGB(34, 38, 52)
    rowStroke.Thickness = 1

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Color3.fromRGB(215, 220, 235)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switch = Instance.new("TextButton", row)
    switch.Size = UDim2.new(0, 38, 0, 18)
    switch.Position = UDim2.new(1, -46, 0.5, -9)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(90, 105, 240) or Color3.fromRGB(45, 50, 68)
    switch.Text = ""
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = defaultState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        local targetPos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        local targetColor = state and Color3.fromRGB(90, 105, 240) or Color3.fromRGB(45, 50, 68)

        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
        callback(state)
    end)
end

local function createActionButton(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = color or Color3.fromRGB(36, 42, 58)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 242, 255)
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ==========================
-- TAB 1: LOBBY
-- ==========================
local function toggleHudFrame(frameName)
    local hud = playerGui:FindFirstChild("HUD")
    if hud then
        local frame = hud:FindFirstChild(frameName)
        if frame then frame.Visible = not frame.Visible end
    end
end

createActionButton(LobbyPage, "🛒 Open Building Shop", Color3.fromRGB(45, 75, 120), function() toggleHudFrame("BuildingShop") end)
createActionButton(LobbyPage, "🎁 Open Daily Rewards", Color3.fromRGB(45, 110, 85), function() toggleHudFrame("DailyRewards") end)
createActionButton(LobbyPage, "📦 Open Roll Box / Boxes", Color3.fromRGB(110, 60, 120), function() toggleHudFrame("RollBox") end)
createActionButton(LobbyPage, "🎡 Open Lucky Wheel", Color3.fromRGB(130, 85, 30), function()
    local wheel = playerGui:FindFirstChild("Wheel")
    if wheel then wheel.Enabled = not wheel.Enabled end
end)
createActionButton(LobbyPage, "🌲 Open Skill Tree", Color3.fromRGB(50, 95, 90), function()
    local tree = playerGui:FindFirstChild("SkillTree")
    if tree then tree.Enabled = not tree.Enabled end
end)
createActionButton(LobbyPage, "🚪 Auto Teleport to Match Door", Color3.fromRGB(140, 50, 50), function()
    local doors = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Doors")
    if doors and humanoidRootPart then
        local targetDoor = doors:FindFirstChildWhichIsA("BasePart") or doors:GetDescendants()[1]
        if targetDoor and targetDoor:IsA("BasePart") then
            humanoidRootPart.CFrame = targetDoor.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

-- ==========================
-- TAB 2: MAIN GAME
-- ==========================
local QubitFrame = Instance.new("Frame", MainPage)
QubitFrame.Size = UDim2.new(1, 0, 0, 32)
QubitFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
QubitFrame.BorderSizePixel = 0
Instance.new("UICorner", QubitFrame).CornerRadius = UDim.new(0, 8)

local QubitStroke = Instance.new("UIStroke", QubitFrame)
QubitStroke.Color = Color3.fromRGB(55, 85, 180)
QubitStroke.Thickness = 1

local QubitIcon = Instance.new("TextLabel", QubitFrame)
QubitIcon.Size = UDim2.new(0, 24, 1, 0)
QubitIcon.Position = UDim2.new(0, 8, 0, 0)
QubitIcon.BackgroundTransparency = 1
QubitIcon.Font = Enum.Font.GothamBold
QubitIcon.Text = "Ⓜ"
QubitIcon.TextColor3 = Color3.fromRGB(90, 190, 255)
QubitIcon.TextSize = 15

local QubitLabel = Instance.new("TextLabel", QubitFrame)
QubitLabel.Size = UDim2.new(1, -40, 1, 0)
QubitLabel.Position = UDim2.new(0, 34, 0, 0)
QubitLabel.BackgroundTransparency = 1
QubitLabel.Font = Enum.Font.GothamBold
QubitLabel.Text = "Live Qubits: Syncing..."
QubitLabel.TextColor3 = Color3.fromRGB(230, 242, 255)
QubitLabel.TextSize = 11
QubitLabel.TextXAlignment = Enum.TextXAlignment.Left

createToggle(MainPage, "Auto Collect Shapes", Config.AutoFarm, function(v) Config.AutoFarm = v end)
createToggle(MainPage, "Auto Vote Insane", Config.AutoVoteInsane, function(v) Config.AutoVoteInsane = v end)
createToggle(MainPage, "Auto Retry on Loss", Config.AutoRetry, function(v) Config.AutoRetry = v end)
createToggle(MainPage, "Auto Claim Quests", Config.AutoClaimQuests, function(v) Config.AutoClaimQuests = v end)

-- ==========================
-- TAB 3: CREDITS
-- ==========================
local function createCreditCard(title, desc)
    local card = Instance.new("Frame", CreditsPage)
    card.Size = UDim2.new(1, 0, 0, 48)
    card.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(34, 38, 52)
    cardStroke.Thickness = 1

    local h = Instance.new("TextLabel", card)
    h.Size = UDim2.new(1, -20, 0, 18)
    h.Position = UDim2.new(0, 10, 0, 6)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.Text = title
    h.TextColor3 = Color3.fromRGB(120, 140, 255)
    h.TextSize = 11
    h.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextLabel", card)
    d.Size = UDim2.new(1, -20, 0, 16)
    d.Position = UDim2.new(0, 10, 0, 24)
    d.BackgroundTransparency = 1
    d.Font = Enum.Font.Gotham
    d.Text = desc
    d.TextColor3 = Color3.fromRGB(180, 185, 200)
    d.TextSize = 10
    d.TextXAlignment = Enum.TextXAlignment.Left
end

createCreditCard("Quantify Pro Hub", "Version 2.6 Release (Universal & Lobby Support)")
createCreditCard("Author / Developer", "Created by OL3N for Quantify")
createCreditCard("GitHub Repository", "raw.githubusercontent.com/OL3NNNNNN/quantifyyyyy")
createCreditCard("Supported Environment", "Fully compatible with Medium & Standard UNC")

-- Minimize Trigger
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ScrollContent.Visible = not isMinimized
    TabBar.Visible = not isMinimized
    local newSize = isMinimized and UDim2.new(0, 330, 0, 42) or UDim2.new(0, 330, 0, 430)
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = newSize}):Play()
    MinBtn.Text = isMinimized and "+" or "-"
end)

-- [[ AUTOMATION CORE ]] --

-- 1. Auto Vote Insane
local lastVote = 0
local function autoVoteInsane()
    if not Config.AutoVoteInsane then return end
    local now = tick()
    if now - lastVote >= 1.2 then
        lastVote = now
        local diffRemote = getRemote("Difficulty")
        if diffRemote then
            task.spawn(function()
                pcall(function()
                    diffRemote:InvokeServer("vote", "Insane")
                end)
            end)
        end
    end
end

-- 2. Auto Retry
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

-- 3. Auto Claim Daily Quests
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

-- 4. Shape Target Finder
local function getActiveShape()
    if not Config.AutoFarm then return nil end

    local folders = {
        workspace:FindFirstChild("Parts"),
        workspace:FindFirstChild("Shapesother"),
        workspace:FindFirstChild("ChudParts")
    }

    for _, folder in ipairs(folders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("BasePart") then
                    return item
                elseif item:IsA("Model") then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                    if part then return part end
                end
            end
        end
    end

    local map = workspace:FindFirstChild("Map")
    if map then
        for _, item in ipairs(map:GetChildren()) do
            if item:IsA("BasePart") and item.Name ~= "PartSpawn" and item.Name ~= "Terrain" then
                if (item.Position - spawnPos).Magnitude < 45 then
                    return item
                end
            end
        end
    end

    return nil
end

-- 5. Main Automation & Qubit Monitor Loop
task.spawn(function()
    while task.wait(0.05) do
        if Config.AutoFarm then
            local target = getActiveShape()
            currentDestination = target and (target.Position + Vector3.new(0, 0.5, 0)) or spawnPos
        end
        autoVoteInsane()
        autoRetry()
        autoClaimQuests()
    end
end)

-- Live Qubit Sync Loop
task.spawn(function()
    while task.wait(1.5) do
        local q = getLiveQubits()
        QubitLabel.Text = string.format("Live Qubits: %s", q)
    end
end)

-- 6. Jitter-Free Physics Lock (Heartbeat Sync)
RunService.Heartbeat:Connect(function()
    if not Config.AutoFarm or game.PlaceId ~= PLACE_ID then return end

    if humanoidRootPart and humanoid and humanoid.Health > 0 then
        if (humanoidRootPart.Position - currentDestination).Magnitude > 0.5 then
            humanoidRootPart.CFrame = CFrame.new(currentDestination)
        end
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)
