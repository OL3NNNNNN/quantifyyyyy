-- [[ QUANTIFY ULTIMATE APEX PRO HUB - RAYFIELD EDITION ]] --
-- Reverse-Engineered for PlaceId: 73648930852061
-- Powered by Rayfield Interface Suite (SiriusSoftwareLtd/Rayfield)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
end)

-- [[ REMOTES CACHE ]] --
local Remotes = {}
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
if remotesFolder then
    for _, child in ipairs(remotesFolder:GetChildren()) do
        Remotes[child.Name] = child
    end
end

local function getRemote(name)
    if Remotes[name] then return Remotes[name] end
    if remotesFolder then
        local r = remotesFolder:FindFirstChild(name)
        if r then Remotes[name] = r return r end
    end
    return nil
end

-- [[ CONFIGURATION STATE ]] --
local Config = {
    -- Harvester
    AutoFarm = false,
    CollectRange = 500,
    BatchHarvest = true,
    PrioritizeHighTierShapes = true,
    AutoOmniDropper = true,
    AutoCrafterEject = true,
    
    -- Auto-Builder
    AutoBuildStack = false,
    StackSpacing = 3.2,
    PrioritizeDroppers = true,
    AutoUpgradeExisting = true,
    
    -- Match AI
    AutoVoteDifficulty = true,
    SelectedDifficulty = "UNQUANTIFIABLE",
    AutoPickBestCard = true,
    AutoRetry = true,
    
    -- Network Claims
    AutoClaimQuests = true,
    AutoClaimDCC = true,
    AutoWheelSpin = true,
    AutoCollectEggs = true,
    
    -- Visuals & Physics
    SpeedBoost = false,
    SpeedValue = 50,
    InfiniteJump = false,
    NoClip = false,
    FullBright = false,
    ShapeESP = false,
    EggESP = false,
}

local activeTargetPosition = nil
local placedUpgradersRegistry = {}
local fixedStackBasePosition = nil
local currentStackHeight = 3.5

-- [[ RAYFIELD WINDOW INITIALIZATION ]] --
local Window = Rayfield:CreateWindow({
    Name = "Quantify Apex Pro Hub | V30.0",
    LoadingTitle = "Quantify Apex Hub",
    LoadingSubtitle = "by OL3N (Rayfield Edition)",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "QuantifyHubConfig",
        FileName = "ApexSettings"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- [[ TABS ]] --
local TabFarm = Window:CreateTab("Harvester ⚡", 4483362458)
local TabBuilder = Window:CreateTab("Auto-Builder 🏗️", 4483362458)
local TabMatch = Window:CreateTab("Match AI 🎯", 4483362458)
local TabNetwork = Window:CreateTab("Rewards & Net 🎁", 4483362458)
local TabMovement = Window:CreateTab("Exploits & ESP 👁️", 4483362458)

-- =========================================================================
-- TAB 1: HARVESTER
-- =========================================================================
TabFarm:CreateSection("⚡ Shape Collector Core")

TabFarm:CreateToggle({
    Name = "Auto Collect Shapes",
    CurrentValue = Config.AutoFarm,
    Flag = "AutoFarmFlag",
    Callback = function(Value) Config.AutoFarm = Value end,
})

TabFarm:CreateToggle({
    Name = "Multi-Batch Harvest (15 Shapes/Tick)",
    CurrentValue = Config.BatchHarvest,
    Flag = "BatchHarvestFlag",
    Callback = function(Value) Config.BatchHarvest = Value end,
})

TabFarm:CreateToggle({
    Name = "Prioritize Rare Shapes (Hexagon > Circle > Square)",
    CurrentValue = Config.PrioritizeHighTierShapes,
    Flag = "PrioritizeHighTierFlag",
    Callback = function(Value) Config.PrioritizeHighTierShapes = Value end,
})

TabFarm:CreateSlider({
    Name = "Collection Radius (Studs)",
    Range = {10, 5000},
    Increment = 25,
    Suffix = " Studs",
    CurrentValue = Config.CollectRange,
    Flag = "CollectRangeFlag",
    Callback = function(Value) Config.CollectRange = Value end,
})

TabFarm:CreateSection("🔥 Production Boosters")

TabFarm:CreateToggle({
    Name = "Auto Fire OmniDropper Remote",
    CurrentValue = Config.AutoOmniDropper,
    Flag = "OmniDropperFlag",
    Callback = function(Value) Config.AutoOmniDropper = Value end,
})

TabFarm:CreateToggle({
    Name = "Auto Eject Finished Crafter Items",
    CurrentValue = Config.AutoCrafterEject,
    Flag = "CrafterEjectFlag",
    Callback = function(Value) Config.AutoCrafterEject = Value end,
})

-- =========================================================================
-- TAB 2: AUTO-BUILDER
-- =========================================================================
TabBuilder:CreateSection("🏗️ Apex Vertical Chute Stacker")

TabBuilder:CreateToggle({
    Name = "Auto-Build Vertical Stack",
    CurrentValue = Config.AutoBuildStack,
    Flag = "AutoBuildStackFlag",
    Callback = function(Value) Config.AutoBuildStack = Value end,
})

TabBuilder:CreateToggle({
    Name = "Top-Mounted Droppers (Chute Apex)",
    CurrentValue = Config.PrioritizeDroppers,
    Flag = "PrioritizeDroppersFlag",
    Callback = function(Value) Config.PrioritizeDroppers = Value end,
})

TabBuilder:CreateToggle({
    Name = "Auto-Upgrade Placed Machinery",
    CurrentValue = Config.AutoUpgradeExisting,
    Flag = "AutoUpgradeFlag",
    Callback = function(Value) Config.AutoUpgradeExisting = Value end,
})

TabBuilder:CreateSlider({
    Name = "Vertical Stack Spacing",
    Range = {1, 10},
    Increment = 0.2,
    Suffix = " Studs",
    CurrentValue = Config.StackSpacing,
    Flag = "StackSpacingFlag",
    Callback = function(Value) Config.StackSpacing = Value end,
})

TabBuilder:CreateButton({
    Name = "🔄 Recalculate Stacking Origin",
    Callback = function()
        fixedStackBasePosition = nil
        currentStackHeight = 3.5
        placedUpgradersRegistry = {}
        Rayfield:Notify({
            Title = "Stacking Origin Reset",
            Content = "Recalculating closest conveyor baseline position.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- =========================================================================
-- TAB 3: MATCH AI & DIFFICULTY
-- =========================================================================
TabMatch:CreateSection("🎯 Match AI & Card Engine")

TabMatch:CreateToggle({
    Name = "Auto Select Best Card (Emerald / Multipliers)",
    CurrentValue = Config.AutoPickBestCard,
    Flag = "AutoPickBestCardFlag",
    Callback = function(Value) Config.AutoPickBestCard = Value end,
})

TabMatch:CreateToggle({
    Name = "Auto Retry On Loss (Instant Match Restart)",
    CurrentValue = Config.AutoRetry,
    Flag = "AutoRetryFlag",
    Callback = function(Value) Config.AutoRetry = Value end,
})

TabMatch:CreateToggle({
    Name = "Auto Vote Difficulty",
    CurrentValue = Config.AutoVoteDifficulty,
    Flag = "AutoVoteDiffFlag",
    Callback = function(Value) Config.AutoVoteDifficulty = Value end,
})

TabMatch:CreateDropdown({
    Name = "Select Match Difficulty",
    Options = {"Easy", "Normal", "Hard", "Insane", "UNQUANTIFIABLE"},
    CurrentOption = Config.SelectedDifficulty,
    Flag = "DifficultyDropdownFlag",
    Callback = function(Option)
        Config.SelectedDifficulty = Option
    end,
})

-- =========================================================================
-- TAB 4: REWARDS & NETWORK
-- =========================================================================
TabNetwork:CreateSection("🎁 Automatic Network Claims")

TabNetwork:CreateToggle({
    Name = "Auto Claim Quests (Daily & Completed)",
    CurrentValue = Config.AutoClaimQuests,
    Flag = "AutoClaimQuestsFlag",
    Callback = function(Value) Config.AutoClaimQuests = Value end,
})

TabNetwork:CreateToggle({
    Name = "Auto Claim DCC Challenges",
    CurrentValue = Config.AutoClaimDCC,
    Flag = "AutoClaimDCCFlag",
    Callback = function(Value) Config.AutoClaimDCC = Value end,
})

TabNetwork:CreateToggle({
    Name = "Auto Spin Daily Wheel",
    CurrentValue = Config.AutoWheelSpin,
    Flag = "AutoWheelSpinFlag",
    Callback = function(Value) Config.AutoWheelSpin = Value end,
})

TabNetwork:CreateToggle({
    Name = "Auto Collect Event Eggs",
    CurrentValue = Config.AutoCollectEggs,
    Flag = "AutoCollectEggsFlag",
    Callback = function(Value) Config.AutoCollectEggs = Value end,
})

TabNetwork:CreateButton({
    Name = "⚡ Force Claim All Rewards Now",
    Callback = function()
        local daily = getRemote("DailyQuest")
        local comp = getRemote("CompletedQuest")
        local dcc = getRemote("DCCReward")
        local dccComp = getRemote("DCCComplete")
        local wheel = getRemote("WheelSpin")
        if daily then pcall(function() daily:FireServer("Claim") end) end
        if comp then pcall(function() comp:FireServer("Claim") end) end
        if dcc then pcall(function() dcc:FireServer() end) end
        if dccComp then pcall(function() dccComp:FireServer() end) end
        if wheel then pcall(function() wheel:FireServer() end) end
        Rayfield:Notify({
            Title = "Network Remotes Dispatched",
            Content = "Sent claim packets for Daily, Quests, DCC and Wheel.",
            Duration = 4,
            Image = 4483362458,
        })
    end,
})

-- =========================================================================
-- TAB 5: EXPLOITS & ESP
-- =========================================================================
TabMovement:CreateSection("🏃 Character Physics")

TabMovement:CreateToggle({
    Name = "Speed Multiplier",
    CurrentValue = Config.SpeedBoost,
    Flag = "SpeedBoostFlag",
    Callback = function(Value)
        Config.SpeedBoost = Value
        if humanoid then humanoid.WalkSpeed = Value and Config.SpeedValue or 16 end
    end,
})

TabMovement:CreateSlider({
    Name = "WalkSpeed Value",
    Range = {16, 200},
    Increment = 5,
    Suffix = " Studs/s",
    CurrentValue = Config.SpeedValue,
    Flag = "SpeedValFlag",
    Callback = function(Value)
        Config.SpeedValue = Value
        if Config.SpeedBoost and humanoid then humanoid.WalkSpeed = Value end
    end,
})

TabMovement:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = Config.InfiniteJump,
    Flag = "InfiniteJumpFlag",
    Callback = function(Value) Config.InfiniteJump = Value end,
})

TabMovement:CreateToggle({
    Name = "NoClip (Pass Through Walls)",
    CurrentValue = Config.NoClip,
    Flag = "NoClipFlag",
    Callback = function(Value) Config.NoClip = Value end,
})

TabMovement:CreateSection("👁️ Visuals & ESP")

TabMovement:CreateToggle({
    Name = "FullBright (Remove Darkness)",
    CurrentValue = Config.FullBright,
    Flag = "FullBrightFlag",
    Callback = function(Value)
        Config.FullBright = Value
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.GlobalShadows = true
        end
    end,
})

TabMovement:CreateToggle({
    Name = "Shape ESP (Cyan Highlight)",
    CurrentValue = Config.ShapeESP,
    Flag = "ShapeESPFlag",
    Callback = function(Value) Config.ShapeESP = Value end,
})

TabMovement:CreateToggle({
    Name = "Egg / Nest ESP (Gold Highlight)",
    CurrentValue = Config.EggESP,
    Flag = "EggESPFlag",
    Callback = function(Value) Config.EggESP = Value end,
})

-- =========================================================================
-- ENGINE CORE & AUTOMATION ROUTINES
-- =========================================================================

-- Trigger Button Helper
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

-- Live Currency Reader
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

-- Harvester Candidate Finder
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
local function findConveyorBasePosition()
    if fixedStackBasePosition then return fixedStackBasePosition end
    local map = workspace:FindFirstChild("Map") or workspace
    local candidates = {}

    for _, item in ipairs(map:GetDescendants()) do
        if item:IsA("BasePart") then
            local n = item.Name:lower()
            if n:find("conveyor") or n:find("belt") or n:find("drop") or n:find("collector") or n:find("processor") then
                table.insert(candidates, item)
            end
        end
    end

    if #candidates > 0 and humanoidRootPart then
        table.sort(candidates, function(a, b)
            return (a.Position - humanoidRootPart.Position).Magnitude < (b.Position - humanoidRootPart.Position).Magnitude
        end)
        fixedStackBasePosition = candidates[1].Position
        return fixedStackBasePosition
    end

    if humanoidRootPart then
        fixedStackBasePosition = humanoidRootPart.Position + Vector3.new(0, -2, 4)
        return fixedStackBasePosition
    end
    return Vector3.new(0, 5, 0)
end

-- Auto-Build Engine
local lastBuildAttempt = 0
local function autoBuildVerticalStack()
    if not Config.AutoBuildStack or not humanoidRootPart then return end
    local now = tick()
    if now - lastBuildAttempt < 0.35 then return end
    lastBuildAttempt = now

    local basePos = findConveyorBasePosition()
    local placeRemote = getRemote("PlaceBuilding") or getRemote("Place") or getRemote("Build") or getRemote("PlaceItem")
    local buyRemote = getRemote("BoughtItem") or getRemote("BuyBuilding") or getRemote("BuyItem") or getRemote("Buy")
    local currentQubits = getLiveQubitNumber()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local droppersList = {}
    local upgradersList = {}

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
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
            local isUpgrader = lowerItem:find("upgrader") or lowerText:find("upgrader") or lowerParent:find("upgrader") or lowerText:find("multiplier") or lowerText:find("processor")

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
        if countBuilt >= 2 then break end
        if currentQubits == 0 or chosen.Price <= currentQubits or chosen.Price == 0 then
            placedUpgradersRegistry[chosen.Name] = true
            countBuilt = countBuilt + 1
            triggerButton(chosen.Button)

            if buyRemote then
                task.spawn(function()
                    pcall(function()
                        if buyRemote:IsA("RemoteFunction") then buyRemote:InvokeServer(chosen.Name)
                        else buyRemote:FireServer(chosen.Name) end
                    end)
                end)
            end

            local stackHeightOffset = currentStackHeight
            if chosen.IsDropper then
                stackHeightOffset = currentStackHeight + 3.0
            else
                currentStackHeight = currentStackHeight + (Config.StackSpacing or 3.2)
            end

            local stackPosition = basePos + Vector3.new(0, stackHeightOffset, 0)
            local stackCFrame = CFrame.new(stackPosition)

            if placeRemote then
                task.spawn(function()
                    pcall(function()
                        if placeRemote:IsA("RemoteFunction") then
                            placeRemote:InvokeServer(chosen.Name, stackCFrame)
                            placeRemote:InvokeServer(chosen.Name, stackPosition)
                        else
                            placeRemote:FireServer(chosen.Name, stackCFrame)
                            placeRemote:FireServer(chosen.Name, stackPosition)
                        end
                    end)
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
        local omni = getRemote("OmniDropper")
        if omni then pcall(function() omni:FireServer() end) end
    end

    if Config.AutoCrafterEject then
        local eject = getRemote("EjectCrafter")
        if eject then pcall(function() eject:FireServer() end) end
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

    local cardsRemote = getRemote("Cards")
    local cardsEvent = getRemote("CardsEvent")
    local playerGui = player:FindFirstChild("PlayerGui")
    local gameHUD = playerGui and playerGui:FindFirstChild("GameHUD")
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
        if cardsRemote then
            task.spawn(function() pcall(function() cardsRemote:InvokeServer(bestCardName) end) end)
        end
        if cardsEvent then
            task.spawn(function() pcall(function() cardsEvent:FireServer(bestCardName) end) end)
        end
    end
end

-- Difficulty Voter
local lastVote = 0
local function autoVoteDifficulty()
    if not Config.AutoVoteDifficulty then return end
    local now = tick()
    if now - lastVote < 0.8 then return end
    lastVote = now

    local diffRemote = getRemote("Difficulty")
    local diffEvent = getRemote("DifficultyEvent")

    if diffRemote then
        task.spawn(function()
            pcall(function() diffRemote:InvokeServer("vote", Config.SelectedDifficulty) end)
            pcall(function() diffRemote:InvokeServer(Config.SelectedDifficulty) end)
        end)
    end
    if diffEvent then
        task.spawn(function()
            pcall(function() diffEvent:FireServer("vote", Config.SelectedDifficulty) end)
            pcall(function() diffEvent:FireServer(Config.SelectedDifficulty) end)
        end)
    end
end

-- Retry on Loss
local lastRetry = 0
local function autoRetry()
    if not Config.AutoRetry then return end
    local now = tick()
    if now - lastRetry < 1 then return end
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local isLossVisible = false
    for _, gui in ipairs(playerGui:GetDescendants()) do
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
        local endedEvent = getRemote("GameEndedEvent")
        if endedEvent then
            task.spawn(function() pcall(function() endedEvent:FireServer("Again") end) end)
        end
    end
end

-- Background Network Claims
local lastNetClaims = 0
local function autoNetworkClaims()
    local now = tick()
    if now - lastNetClaims < 6 then return end
    lastNetClaims = now

    if Config.AutoClaimQuests then
        local daily = getRemote("DailyQuest")
        local comp = getRemote("CompletedQuest")
        if daily then pcall(function() daily:FireServer("Claim") end) end
        if comp then pcall(function() comp:FireServer("Claim") end) end
    end

    if Config.AutoClaimDCC then
        local dccFunc = getRemote("DCCFunc")
        local dccRew = getRemote("DCCReward")
        local dccComp = getRemote("DCCComplete")
        if dccRew then pcall(function() dccRew:FireServer() end) end
        if dccComp then pcall(function() dccComp:FireServer() end) end
        if dccFunc then pcall(function() dccFunc:InvokeServer("Claim") end) end
    end

    if Config.AutoWheelSpin then
        local wheel = getRemote("WheelSpin")
        if wheel then pcall(function() wheel:FireServer() end) end
    end
end

-- ESP Updater
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
                        hl.FillColor = Color3.fromRGB(6, 182, 212)
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
                    hl.FillColor = Color3.fromRGB(245, 158, 11)
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

                local collectRemote = getRemote("CollectShape") or getRemote("Harvest") or getRemote("TouchShape") or getRemote("Collect")
                if collectRemote then
                    task.spawn(function()
                        pcall(function()
                            if collectRemote:IsA("RemoteFunction") then collectRemote:InvokeServer(bestShape)
                            else collectRemote:FireServer(bestShape) end
                        end)
                    end)
                end
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

-- Physics Target Lock
RunService.Heartbeat:Connect(function()
    if not Config.AutoFarm then return end
    if activeTargetPosition and humanoidRootPart and humanoid and humanoid.Health > 0 then
        humanoidRootPart.CFrame = CFrame.new(activeTargetPosition)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)

Rayfield:Notify({
    Title = "Quantify Apex Pro Loaded",
    Content = "All reverse-engineered network modules ready!",
    Duration = 5,
    Image = 4483362458,
})
