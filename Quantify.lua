-- [[ Quantify Pro Hub - Complete Automation & Live Qubit Tracker ]] --
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

-- Safe GUI container resolution
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

-- Default Positions & Remotes
local spawnPos = Vector3.new(62.154415130615234, 25.5, 1298.9)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DifficultyRemote = Remotes:WaitForChild("Difficulty")
local GameEndedEvent = Remotes:WaitForChild("GameEndedEvent")
local DailyQuestEvent = Remotes:FindFirstChild("DailyQuest")
local CompletedQuestEvent = Remotes:FindFirstChild("CompletedQuest")
local GetDataRemote = Remotes:FindFirstChild("GetData")
local GetGameDataRemote = Remotes:FindFirstChild("GetGameData")

local shapeFolders = {
    workspace:WaitForChild("Parts"),
    workspace:WaitForChild("Shapesother"),
    workspace:WaitForChild("ChudParts")
}

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
    -- 1. Check Player Attributes
    local attr = player:GetAttribute("Qubits") or player:GetAttribute("Currency") or player:GetAttribute("Money")
    if attr then return tostring(attr) end

    -- 2. Check Leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local qubitObj = leaderstats:FindFirstChild("Qubits") or leaderstats:FindFirstChild("Qubit") or leaderstats:FindFirstChild("Cash")
        if qubitObj then return tostring(qubitObj.Value) end
    end

    -- 3. Check GetData Remote
    if GetDataRemote and GetDataRemote:IsA("RemoteFunction") then
        local success, data = pcall(function() return GetDataRemote:InvokeServer() end)
        if success and typeof(data) == "table" and data.Qubits then
            return tostring(data.Qubits)
        end
    end

    -- 4. Check UI Elements in PlayerGui
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
MainFrame.Size = UDim2.new(0, 320, 0, 360)
MainFrame.Position = UDim2.new(0.04, 0, 0.25, 0)
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

-- Header Bar
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

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -20, 1, -54)
Content.Position = UDim2.new(0, 10, 0, 48)
Content.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Live Qubit Balance Display
local QubitFrame = Instance.new("Frame", Content)
QubitFrame.Size = UDim2.new(1, 0, 0, 34)
QubitFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
QubitFrame.BorderSizePixel = 0
QubitFrame.LayoutOrder = 0
Instance.new("UICorner", QubitFrame).CornerRadius = UDim.new(0, 8)

local QubitStroke = Instance.new("UIStroke", QubitFrame)
QubitStroke.Color = Color3.fromRGB(55, 85, 180)
QubitStroke.Thickness = 1

local QubitIcon = Instance.new("TextLabel", QubitFrame)
QubitIcon.Size = UDim2.new(0, 26, 1, 0)
QubitIcon.Position = UDim2.new(0, 8, 0, 0)
QubitIcon.BackgroundTransparency = 1
QubitIcon.Font = Enum.Font.GothamBold
QubitIcon.Text = "Ⓜ"
QubitIcon.TextColor3 = Color3.fromRGB(90, 190, 255)
QubitIcon.TextSize = 16

local QubitLabel = Instance.new("TextLabel", QubitFrame)
QubitLabel.Size = UDim2.new(1, -40, 1, 0)
QubitLabel.Position = UDim2.new(0, 36, 0, 0)
QubitLabel.BackgroundTransparency = 1
QubitLabel.Font = Enum.Font.GothamBold
QubitLabel.Text = "Live Qubits: Syncing..."
QubitLabel.TextColor3 = Color3.fromRGB(230, 242, 255)
QubitLabel.TextSize = 12
QubitLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle Switch Component Builder
local function createToggle(text, defaultState, callback, order)
    local row = Instance.new("Frame", Content)
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 1
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

createToggle("Auto Collect Shapes", Config.AutoFarm, function(v) Config.AutoFarm = v end, 1)
createToggle("Auto Vote Insane", Config.AutoVoteInsane, function(v) Config.AutoVoteInsane = v end, 2)
createToggle("Auto Retry on Loss", Config.AutoRetry, function(v) Config.AutoRetry = v end, 3)
createToggle("Auto Claim Daily Quests", Config.AutoClaimQuests, function(v) Config.AutoClaimQuests = v end, 4)

-- Stats / Status Footer
local StatsRow = Instance.new("Frame", Content)
StatsRow.Size = UDim2.new(1, 0, 0, 42)
StatsRow.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
StatsRow.BorderSizePixel = 0
StatsRow.LayoutOrder = 5
Instance.new("UICorner", StatsRow).CornerRadius = UDim.new(0, 8)

local StatusDot = Instance.new("Frame", StatsRow)
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 10, 0, 10)
StatusDot.BackgroundColor3 = Color3.fromRGB(70, 220, 140)
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel", StatsRow)
StatusText.Size = UDim2.new(1, -30, 0, 16)
StatusText.Position = UDim2.new(0, 24, 0, 5)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamMedium
StatusText.Text = "System Active | Qubit Tracking ON"
StatusText.TextColor3 = Color3.fromRGB(200, 205, 220)
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left

local StatsSubText = Instance.new("TextLabel", StatsRow)
StatsSubText.Size = UDim2.new(1, -20, 0, 14)
StatsSubText.Position = UDim2.new(0, 10, 0, 22)
StatsSubText.BackgroundTransparency = 1
StatsSubText.Font = Enum.Font.Gotham
StatsSubText.Text = "Retries Handled: 0 | Auto-Persist: ON"
StatsSubText.TextColor3 = Color3.fromRGB(130, 138, 160)
StatsSubText.TextSize = 9
StatsSubText.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Trigger
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Content.Visible = not isMinimized
    local newSize = isMinimized and UDim2.new(0, 320, 0, 42) or UDim2.new(0, 320, 0, 360)
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
        task.spawn(function()
            pcall(function()
                DifficultyRemote:InvokeServer("vote", "Insane")
            end)
        end)
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
        StatsSubText.Text = string.format("Retries Handled: %d | Auto-Persist: ON", Stats.RetriesHandled)
        
        task.spawn(function()
            pcall(function()
                GameEndedEvent:FireServer("Again")
            end)
        end)
    end
end

-- 3. Auto Claim Daily Quests
local lastQuestClaim = 0
local function autoClaimQuests()
    if not Config.AutoClaimQuests then return end
    local now = tick()
    if now - lastQuestClaim < 10 then return end
    lastQuestClaim = now

    task.spawn(function()
        if DailyQuestEvent then
            pcall(function() DailyQuestEvent:FireServer("Claim") end)
            pcall(function() DailyQuestEvent:FireServer("claim") end)
        end
        if CompletedQuestEvent then
            pcall(function() CompletedQuestEvent:FireServer("Claim") end)
        end
    end)
end

-- 4. Shape Target Finder
local function getActiveShape()
    if not Config.AutoFarm then return nil end

    for _, folder in ipairs(shapeFolders) do
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("BasePart") then
                return item
            elseif item:IsA("Model") then
                local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                if part then return part end
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

-- Update Qubit Counter every 1.5s
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
