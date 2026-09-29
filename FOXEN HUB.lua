--========================================================--
--                     FOXEN HUB
--========================================================--

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- WINDOW
--========================================================--

local window = Rayfield:CreateWindow({
    name = "Fexon Hub",
    subtitle = "Fexon Hub",
    sidebarLayout = true,
})

local visualTab = window:CreateTab({
    name = "Visual",
    icon = 109164844929627
})

local geneTab = window:CreateTab({
    name = "Gen",
    icon = 109164844929627
})

local parryTab = window:CreateTab({
    name = "Parry",
    icon = 109164844929627
})

local settingsTab = window:CreateTab({
    name = "Settings",
    icon = 109164844929627
})

--========================================================--
-- SETTINGS / THEME
--========================================================--

settingsTab:CreateDropdown({
    name = "Theme",
    options = {
        "default",
        "cobalt",
        "ember",
        "amethyst",
        "frost",
        "rose"
    },
    currentOption = {"default"},

    callback = function(option)
        local theme = option

        if typeof(option) == "table" then
            theme = option[1]
        end

        if not theme then
            return
        end

        pcall(function()
            window:ChangeTheme(string.lower(theme))
        end)
    end,
})

--========================================================--
-- CAMERA FOV
--========================================================--

local CameraFOV = 70

settingsTab:CreateSlider({
    name = "Camera FOV",
    range = {40, 120},
    increment = 1,
    suffix = "°",
    currentValue = CameraFOV,

    callback = function(value)
        CameraFOV = tonumber(value) or 70

        local Camera = workspace.CurrentCamera

        if Camera then
            Camera.FieldOfView = CameraFOV
        end
    end,
})

--========================================================--
-- ESP COLOR SETTINGS
--========================================================--

local PlayerESPColor = Color3.fromRGB(255, 255, 255)
local GeneratorESPColor = Color3.fromRGB(0, 255, 255)

local function GetESPColor(name)
    if name == "White" then
        return Color3.fromRGB(255, 255, 255)
    elseif name == "Red" then
        return Color3.fromRGB(255, 0, 0)
    elseif name == "Blue" then
        return Color3.fromRGB(0, 120, 255)
    elseif name == "Green" then
        return Color3.fromRGB(0, 255, 0)
    elseif name == "Yellow" then
        return Color3.fromRGB(255, 255, 0)
    elseif name == "Purple" then
        return Color3.fromRGB(180, 0, 255)
    elseif name == "Pink" then
        return Color3.fromRGB(255, 0, 170)
    elseif name == "Cyan" then
        return Color3.fromRGB(0, 255, 255)
    end

    return Color3.fromRGB(255, 255, 255)
end

local ESPColorOptions = {
    "White",
    "Red",
    "Blue",
    "Green",
    "Yellow",
    "Purple",
    "Pink",
    "Cyan"
}

--========================================================--
-- PLAYER ESP
--========================================================--

local ESPEnabled = false
local ESPConnections = {}
local ESPObjects = {}

local function removeESP(player)
    local object = ESPObjects[player]

    if object then
        pcall(function()
            object:Destroy()
        end)

        ESPObjects[player] = nil
    end

    local connection = ESPConnections[player]

    if connection then
        pcall(function()
            connection:Disconnect()
        end)

        ESPConnections[player] = nil
    end
end

local function IsKillerPlayer(player)
    local teamName = ""

    pcall(function()
        teamName = string.lower(player.Team and player.Team.Name or "")
    end)

    return string.find(teamName, "killer") ~= nil
end

local function createPlayerESP(player, character)
    if player == LocalPlayer or not character then
        return
    end

    removeESP(player)

    local highlight = Instance.new("Highlight")

    highlight.Name = "PlayerESP"
    highlight.FillTransparency = 0.5
    highlight.FillColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    if IsKillerPlayer(player) then
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    else
        highlight.OutlineColor = PlayerESPColor
    end

    highlight.Adornee = character
    highlight.Parent = character

    ESPObjects[player] = highlight
end

local function setupPlayerESP(player)
    if player == LocalPlayer then
        return
    end

    removeESP(player)

    if player.Character then
        createPlayerESP(player, player.Character)
    end

    ESPConnections[player] = player.CharacterAdded:Connect(function(character)
        if ESPEnabled then
            task.wait(0.2)
            createPlayerESP(player, character)
        end
    end)
end

local function enableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerESP(player)
    end
end

local function disableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        setupPlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

visualTab:CreateToggle({
    name = "Esp",
    currentValue = false,

    callback = function(value)
        ESPEnabled = value

        if value then
            enableESP()
        else
            disableESP()
        end
    end,
})

visualTab:CreateDropdown({
    name = "Player ESP Color",
    options = ESPColorOptions,
    currentOption = {"White"},

    callback = function(option)
        if typeof(option) == "table" then
            option = option[1]
        end

        PlayerESPColor = GetESPColor(option)

        for player, highlight in pairs(ESPObjects) do
            if highlight then
                if IsKillerPlayer(player) then
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                else
                    highlight.OutlineColor = PlayerESPColor
                end
            end
        end
    end,
})

--========================================================--
-- GENERATOR ESP
--========================================================--

local GeneratorESPEnabled = false
local GeneratorObjects = {}

local function isGenerator(object)
    return object:IsA("Model")
        and string.find(string.lower(object.Name), "generator") ~= nil
end

local function convertPercent(value)
    if typeof(value) == "number" then
        if value <= 1 then
            value = value * 100
        end

        return math.clamp(math.floor(value + 0.5), 0, 100)
    end

    if typeof(value) == "string" then
        local number = tonumber(value:match("(%d+%.?%d*)"))

        if number then
            if number <= 1 then
                number = number * 100
            end

            return math.clamp(math.floor(number + 0.5), 0, 100)
        end
    end

    return 0
end

local function getGeneratorPercent(generator)
    local attributes = {
        "Progress",
        "progress",
        "Percentage",
        "percentage",
        "Percent",
        "percent",
        "RepairProgress",
        "repairProgress"
    }

    for _, attribute in ipairs(attributes) do
        local value = generator:GetAttribute(attribute)

        if value ~= nil then
            return convertPercent(value)
        end
    end

    for _, descendant in ipairs(generator:GetDescendants()) do
        if descendant:IsA("NumberValue")
            or descendant:IsA("IntValue") then

            local name = string.lower(descendant.Name)

            if string.find(name, "progress")
                or string.find(name, "percent")
                or string.find(name, "repair") then

                return convertPercent(descendant.Value)
            end
        end
    end

    return 0
end

local function getGeneratorPart(generator)
    if generator.PrimaryPart then
        return generator.PrimaryPart
    end

    return generator:FindFirstChildWhichIsA("BasePart", true)
end

local function removeGeneratorESP(generator)
    local data = GeneratorObjects[generator]

    if data then
        if data.highlight then
            pcall(function()
                data.highlight:Destroy()
            end)
        end

        if data.billboard then
            pcall(function()
                data.billboard:Destroy()
            end)
        end

        GeneratorObjects[generator] = nil
    end
end

local function createGeneratorESP(generator)
    if not GeneratorESPEnabled or not generator then
        return
    end

    removeGeneratorESP(generator)

    local part = getGeneratorPart(generator)

    if not part then
        return
    end

    local highlight = Instance.new("Highlight")

    highlight.Name = "GeneratorESP"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = GeneratorESPColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = generator
    highlight.Parent = generator

    local billboard = Instance.new("BillboardGui")

    billboard.Name = "GeneratorPercentage"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(45, 15)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 0
    billboard.Parent = part

    local text = Instance.new("TextLabel")

    text.Name = "Percentage"
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Text = "0%"
    text.TextScaled = false
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.Parent = billboard

    GeneratorObjects[generator] = {
        highlight = highlight,
        billboard = billboard,
        text = text
    }
end

local function scanGenerators()
    for _, object in ipairs(workspace:GetDescendants()) do
        if isGenerator(object) then
            createGeneratorESP(object)
        end
    end
end

local function disableGeneratorESP()
    for generator in pairs(GeneratorObjects) do
        removeGeneratorESP(generator)
    end
end

workspace.DescendantAdded:Connect(function(object)
    if GeneratorESPEnabled and isGenerator(object) then
        task.wait(0.1)

        if object.Parent then
            createGeneratorESP(object)
        end
    end
end)

visualTab:CreateToggle({
    name = "ESP Gene",
    currentValue = false,

    callback = function(value)
        GeneratorESPEnabled = value

        if value then
            scanGenerators()
        else
            disableGeneratorESP()
        end
    end,
})

visualTab:CreateDropdown({
    name = "Generator ESP Color",
    options = ESPColorOptions,
    currentOption = {"Cyan"},

    callback = function(option)
        if typeof(option) == "table" then
            option = option[1]
        end

        GeneratorESPColor = GetESPColor(option)

        for _, data in pairs(GeneratorObjects) do
            if data and data.highlight then
                data.highlight.OutlineColor = GeneratorESPColor
            end
        end
    end,
})

--========================================================--
-- GENERATOR UPDATE
--========================================================--

RunService.RenderStepped:Connect(function()
    if not GeneratorESPEnabled then
        return
    end

    for generator, data in pairs(GeneratorObjects) do
        if not generator or not generator.Parent then
            removeGeneratorESP(generator)
            continue
        end

        if data.text then
            local percent = getGeneratorPercent(generator)
            data.text.Text = tostring(percent) .. "%"
        end

        local part = getGeneratorPart(generator)

        if part and data.billboard then
            data.billboard.Adornee = part
        end
    end
end)

--========================================================--
-- AUTO GENERATOR
--========================================================--

local AutoGeneratorEnabled = false
local GeneratorMode = "SUCCESS"

local SUCCESS_MIN = 102
local SUCCESS_MAX = 116

local NEUTRAL_MIN = 116
local NEUTRAL_MAX = 159

local TriggerDelay = 0.035
local LastTrigger = 0
local Busy = false

local Check
local Line
local Goal
local Action

local function RefreshGeneratorReferences()
    Check = nil
    Line = nil
    Goal = nil
    Action = nil

    local SkillGui = PlayerGui:FindFirstChild("SkillCheckPromptGui")

    if SkillGui then
        Check = SkillGui:FindFirstChild("Check")

        if Check then
            Line = Check:FindFirstChild("Line")
            Goal = Check:FindFirstChild("Goal")
        end
    end

    local Survivor = PlayerGui:FindFirstChild("Survivor-mob")

    if Survivor then
        local Controls = Survivor:FindFirstChild("Controls")

        if Controls then
            Action = Controls:FindFirstChild("action")
        end
    end
end

local function TriggerGenerator()
    if not Action then
        RefreshGeneratorReferences()
    end

    if not Action then
        return false
    end

    local Now = os.clock()

    if Now - LastTrigger < TriggerDelay then
        return false
    end

    LastTrigger = Now

    pcall(function()
        if Action:IsA("GuiButton") then
            Action:Activate()
        end
    end)

    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(Action.MouseButton1Down)
        end)
    end

    return true
end

local function GetRotations()
    if not Line or not Goal then
        return nil, nil
    end

    local LineRotation = tonumber(Line.Rotation)
    local GoalRotation = tonumber(Goal.Rotation)

    if not LineRotation or not GoalRotation then
        return nil, nil
    end

    return LineRotation, GoalRotation
end

local function IsSuccess()
    local LineRotation, GoalRotation = GetRotations()

    if not LineRotation then
        return false
    end

    local Min = GoalRotation + SUCCESS_MIN
    local Max = GoalRotation + SUCCESS_MAX

    return LineRotation >= Min and LineRotation <= Max
end

local function IsNeutral()
    local LineRotation, GoalRotation = GetRotations()

    if not LineRotation then
        return false
    end

    local Min = GoalRotation + NEUTRAL_MIN
    local Max = GoalRotation + NEUTRAL_MAX

    return LineRotation > Min and LineRotation <= Max
end

task.spawn(function()
    while task.wait(0.01) do
        if not AutoGeneratorEnabled then
            Busy = false
            continue
        end

        RefreshGeneratorReferences()

        if not Check or not Line or not Goal or not Action then
            continue
        end

        if not Check.Visible then
            Busy = false
            continue
        end

        if GeneratorMode == "INSTANT" then
            if not Busy then
                Busy = true

                local GoalRotation = tonumber(Goal.Rotation) or 0

                pcall(function()
                    Line.Rotation = GoalRotation + 109
                end)

                TriggerGenerator()

                task.delay(0.08, function()
                    Busy = false
                end)
            end

        elseif GeneratorMode == "SUCCESS" then
            if not Busy and IsSuccess() then
                Busy = true

                TriggerGenerator()

                task.delay(0.08, function()
                    Busy = false
                end)
            end

        elseif GeneratorMode == "NEUTRAL" then
            if not Busy and IsNeutral() then
                Busy = true

                TriggerGenerator()

                task.delay(0.08, function()
                    Busy = false
                end)
            end
        end
    end
end)

geneTab:CreateToggle({
    name = "Auto Generator",
    currentValue = false,

    callback = function(value)
        AutoGeneratorEnabled = value
        Busy = false

        if value then
            RefreshGeneratorReferences()
        end
    end,
})

geneTab:CreateDropdown({
    name = "Generator Mode",
    options = {
        "SUCCESS",
        "NEUTRAL",
        "INSTANT"
    },

    currentOption = {"SUCCESS"},

    callback = function(option)
        if typeof(option) == "table" then
            GeneratorMode = option[1] or "SUCCESS"
        else
            GeneratorMode = option
        end

        Busy = false
    end,
})

--========================================================--
-- AUTO PARRY
--========================================================--

local AutoParryEnabled = false
local RangeVisualEnabled = false

-- RANGE NAIK SEDIKIT
local ParryRange = 10

local LocalCharacter
local LocalRoot
local GuiMob

local KillerData = {}
local PendingKiller = {}

local AttackAnimations = {
    ["139369275981139"] = true,
    ["121216847022485"] = true,
    ["78935059863801"] = true,
    ["74968262036854"] = true,
    ["82666958311998"] = true,
    ["78432063483146"] = true,
    ["132817836308238"] = true,
    ["111920872708571"] = true,
    ["138720291317243"] = true,
    ["130593238885843"] = true,
    ["106871536134254"] = true,
    ["109402730355822"] = true,
}

local Attacking = false

--========================================================--
-- CHARACTER
--========================================================--

local function UpdateLocalCharacter()
    LocalCharacter = LocalPlayer.Character

    if LocalCharacter then
        LocalRoot = LocalCharacter:FindFirstChild("HumanoidRootPart")
    else
        LocalRoot = nil
    end
end

UpdateLocalCharacter()

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)

    LocalCharacter = character
    LocalRoot = character:WaitForChild("HumanoidRootPart", 5)
end)

--========================================================--
-- ORIGINAL GUI-MOB
--========================================================--

local function FindGuiMob()
    local SurvivorMob = PlayerGui:FindFirstChild("Survivor-mob")

    if not SurvivorMob then
        return nil
    end

    local Controls = SurvivorMob:FindFirstChild("Controls")

    if not Controls then
        return nil
    end

    local Button = Controls:FindFirstChild("Gui-mob")

    if Button and Button:IsA("ImageButton") then
        return Button
    end

    return nil
end

local function GetGuiMob()
    GuiMob = FindGuiMob()

    if GuiMob then
        return GuiMob
    end

    return nil
end

local function TriggerParry()
    if not AutoParryEnabled then
        return
    end

    local Button = GetGuiMob()

    if not Button then
        return
    end

    if not Button:IsA("ImageButton") then
        return
    end

    if typeof(firesignal) ~= "function" then
        return
    end

    pcall(function()
        firesignal(Button.MouseButton1Down)
    end)
end

--========================================================--
-- KILLER
--========================================================--

local function IsKiller(character)
    if not character then
        return false
    end

    if character == LocalCharacter then
        return false
    end

    return character:FindFirstChild("Lookscriptkiller", true) ~= nil
end

local function GetKillerRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function GetDistanceFromKiller(character)
    if not LocalRoot then
        return math.huge
    end

    local KillerRoot = GetKillerRoot(character)

    if not KillerRoot then
        return math.huge
    end

    return (LocalRoot.Position - KillerRoot.Position).Magnitude
end

--========================================================--
-- UNBIND
--========================================================--

local function UnbindKiller(character)
    local Data = KillerData[character]

    if Data then
        if Data.connection then
            pcall(function()
                Data.connection:Disconnect()
            end)
        end

        KillerData[character] = nil
    end

    local Pending = PendingKiller[character]

    if Pending then
        pcall(function()
            Pending:Disconnect()
        end)

        PendingKiller[character] = nil
    end
end

--========================================================--
-- ATTACK
--========================================================--

local function MarkAttack(character, track)
    local Data = KillerData[character]

    if not Data then
        return
    end

    Data.attacking = true
    Data.track = track

    Attacking = true

    -- AUTO PARRY LANGSUNG CEK SAAT ATTACK TERDETEKSI
    if AutoParryEnabled then
        local Distance = GetDistanceFromKiller(character)

        if Distance <= ParryRange then
            TriggerParry()
        end
    end

    -- CEK JARAK SETIAP 0.01 DETIK SELAMA ATTACK
    task.spawn(function()
        local StartTime = os.clock()

        while AutoParryEnabled
            and track
            and track.IsPlaying
            and character.Parent
            and KillerData[character]
            and KillerData[character].track == track
            and os.clock() - StartTime <= 0.45 do

            local Distance = GetDistanceFromKiller(character)

            if Distance <= ParryRange then
                TriggerParry()
            end

            task.wait(0.01)
        end
    end)

    task.spawn(function()
        local StoppedConnection

        StoppedConnection = track.Stopped:Connect(function()
            if KillerData[character]
                and KillerData[character].track == track then

                KillerData[character].attacking = false
                KillerData[character].track = nil
            end

            Attacking = false

            if StoppedConnection then
                StoppedConnection:Disconnect()
            end
        end)

        task.delay(1, function()
            if StoppedConnection then
                StoppedConnection:Disconnect()
            end

            if KillerData[character]
                and KillerData[character].track == track then

                KillerData[character].attacking = false
                KillerData[character].track = nil
            end

            Attacking = false
        end)
    end)
end

local function CheckAnimation(character, track)
    if not IsKiller(character) then
        return
    end

    if not track then
        return
    end

    local Animation = track.Animation

    if not Animation then
        return
    end

    local AnimationId =
        tostring(Animation.AnimationId):match("%d+")

    if not AnimationId then
        return
    end

    if not AttackAnimations[AnimationId] then
        return
    end

    MarkAttack(character, track)
end

--========================================================--
-- BIND KILLER
--========================================================--

local function BindKiller(character)
    if not character then
        return
    end

    if character == LocalCharacter then
        return
    end

    if KillerData[character] then
        return
    end

    if not IsKiller(character) then
        return
    end

    local Humanoid = character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return
    end

    local Animator = Humanoid:FindFirstChildOfClass("Animator")

    if not Animator then
        return
    end

    local Data = {
        Root = GetKillerRoot(character),
        attacking = false,
        track = nil,
        connection = nil,
    }

    KillerData[character] = Data

    Data.connection = Animator.AnimationPlayed:Connect(function(track)
        CheckAnimation(character, track)
    end)
end

--========================================================--
-- WAIT FOR KILLER MARKER
--========================================================--

local function WatchForKiller(character)
    if not character or character == LocalCharacter then
        return
    end

    if KillerData[character] then
        return
    end

    if IsKiller(character) then
        BindKiller(character)
        return
    end

    if PendingKiller[character] then
        return
    end

    PendingKiller[character] =
        character.DescendantAdded:Connect(function(instance)

            if instance.Name == "Lookscriptkiller" then
                task.defer(function()
                    if PendingKiller[character] then
                        PendingKiller[character]:Disconnect()
                        PendingKiller[character] = nil
                    end

                    BindKiller(character)
                end)
            end
        end)
end

--========================================================--
-- SCAN KILLERS
--========================================================--

local function ScanKillers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            WatchForKiller(player.Character)
        end
    end

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") then
            if object ~= LocalCharacter then
                WatchForKiller(object)
            end
        end
    end
end

--========================================================--
-- PLAYER WATCHER
--========================================================--

local PlayerConnections = {}

local function SetupPlayer(player)
    if player == LocalPlayer then
        return
    end

    if PlayerConnections[player] then
        pcall(function()
            PlayerConnections[player]:Disconnect()
        end)
    end

    PlayerConnections[player] =
        player.CharacterAdded:Connect(function(character)

            task.wait(0.2)

            WatchForKiller(character)

            task.delay(1, function()
                WatchForKiller(character)
            end)

            task.delay(2, function()
                WatchForKiller(character)
            end)
        end)

    if player.Character then
        WatchForKiller(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    SetupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        UnbindKiller(player.Character)
    end

    if PlayerConnections[player] then
        pcall(function()
            PlayerConnections[player]:Disconnect()
        end)

        PlayerConnections[player] = nil
    end
end)

--========================================================--
-- WORKSPACE WATCHER
--========================================================--

workspace.DescendantAdded:Connect(function(instance)

    if instance:IsA("Model") then
        task.defer(function()
            WatchForKiller(instance)
        end)
    end

    if instance.Name == "Lookscriptkiller" then
        local Character = instance:FindFirstAncestorOfClass("Model")

        if Character then
            task.defer(function()
                BindKiller(Character)
            end)
        end
    end
end)

workspace.DescendantRemoving:Connect(function(instance)
    if KillerData[instance] then
        UnbindKiller(instance)
    end
end)

--========================================================--
-- RANGE VISUAL
--========================================================--

local RangeRing = Instance.new("CylinderHandleAdornment")

RangeRing.Name = "ParryRange"
RangeRing.Height = 0.15
RangeRing.Radius = ParryRange
RangeRing.Transparency = 1
RangeRing.AlwaysOnTop = true

-- UNGU
RangeRing.Color3 = Color3.fromRGB(170, 0, 255)

RangeRing.CFrame =
    CFrame.new(0, -2.8, 0) *
    CFrame.Angles(math.rad(90), 0, 0)

RangeRing.Parent = workspace

local function UpdateRangeVisual()
    if not AutoParryEnabled or not RangeVisualEnabled then
        RangeRing.Transparency = 1
        return
    end

    if not LocalRoot or not LocalRoot.Parent then
        RangeRing.Transparency = 1
        return
    end

    RangeRing.Adornee = LocalRoot
    RangeRing.Radius = ParryRange
    RangeRing.Transparency = 0.35

    -- RING SELALU UNGU
    RangeRing.Color3 = Color3.fromRGB(170, 0, 255)
end

--========================================================--
-- RAYFIELD CONTROLS
--========================================================--

parryTab:CreateToggle({
    name = "Auto Parry",
    currentValue = false,

    callback = function(value)
        AutoParryEnabled = value

        if value then
            UpdateLocalCharacter()
            GetGuiMob()
            ScanKillers()

            task.spawn(function()
                for i = 1, 20 do
                    if not AutoParryEnabled then
                        break
                    end

                    ScanKillers()
                    task.wait(0.1)
                end
            end)
        else
            RangeRing.Transparency = 0.80
            Attacking = false

            for _, data in pairs(KillerData) do
                if data then
                    data.attacking = false
                    data.track = nil
                end
            end
        end
    end,
})

parryTab:CreateSlider({
    name = "Parry Range",
    range = {1, 32},
    increment = 1,
    suffix = " studs",
    currentValue = ParryRange,

    callback = function(value)
        ParryRange =
            math.clamp(tonumber(value) or 10, 1, 32)

        RangeRing.Radius = ParryRange
    end,
})

parryTab:CreateToggle({
    name = "Range Visual",
    currentValue = false,

    callback = function(value)
        RangeVisualEnabled = value

        if not value or not AutoParryEnabled then
            RangeRing.Transparency = 1
        end
    end,
})

--========================================================--
-- UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    UpdateLocalCharacter()

    if AutoParryEnabled then
        GetGuiMob()
    end

    for character, data in pairs(KillerData) do
        if character and character.Parent then
            data.Root = GetKillerRoot(character)
        else
            UnbindKiller(character)
        end
    end

    UpdateRangeVisual()
end)

--========================================================--
-- RESPAWN
--========================================================--

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    LocalCharacter = character
    LocalRoot = character:WaitForChild("HumanoidRootPart", 5)

    if LocalRoot then
        RangeRing.Adornee = LocalRoot

        RangeRing.CFrame =
            CFrame.new(0, -2.8, 0) *
            CFrame.Angles(math.rad(90), 0, 0)
    end

    if AutoParryEnabled then
        GetGuiMob()
        ScanKillers()
    end
end)