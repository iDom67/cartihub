local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local areas = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Areas"))
local riftSpawnNotification = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("Notifications"):WaitForChild("RiftSpawn")
)
local messageNotification = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("Notifications"):WaitForChild("Message")
)
local smartProximityPrompt = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("SmartProximityPrompt")
)
local random = Random.new()
local ADMIN_USERNAME = "misfitsbsthree"
local ADMIN_USER_ID = 10751598093

local identityState = _G.CartiAdminAbuseIdentityState or {}
if identityState.CharacterAddedConnection then
    identityState.CharacterAddedConnection:Disconnect()
end
_G.CartiAdminAbuseIdentityState = identityState

local function applyCreatorTag(character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then
        return false
    end

    local oldTag = head:FindFirstChild("CartiCreatorTag")
    if oldTag then
        oldTag:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CartiCreatorTag"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 150
    billboard.Size = UDim2.fromOffset(245, 46)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    billboard.Parent = head

    local title = Instance.new("TextLabel")
    title.Name = "Creator"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 1)
    title.Font = Enum.Font.GothamBlack
    title.Text = "👑 CREATOR 👑"
    title.TextColor3 = Color3.fromRGB(239, 42, 54)
    title.TextSize = 25
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.TextStrokeTransparency = 0
    title.Parent = billboard

    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Thickness = 1.5
    textStroke.Parent = title
    return true
end

local function clearAvatarAppearance(character)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory")
            or child:IsA("Accoutrement")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic")
            or child:IsA("BodyColors")
            or child:IsA("CharacterMesh") then
            child:Destroy()
        end
    end
end

local function findCharacterAttachment(character, attachmentName)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Attachment") and descendant.Name == attachmentName then
            return descendant
        end
    end
    return nil
end

local function weldAvatarAccessory(accessory, character)
    local handle = accessory:FindFirstChild("Handle")
    if not (handle and handle:IsA("BasePart")) then
        return
    end

    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    local handleAttachment = handle:FindFirstChildOfClass("Attachment")
    local characterAttachment = handleAttachment and findCharacterAttachment(character, handleAttachment.Name)
    local targetPart = characterAttachment and characterAttachment.Parent or character:FindFirstChild("Head")
    if not (targetPart and targetPart:IsA("BasePart")) then
        return
    end

    local weld = handle:FindFirstChild("AccessoryWeld") or Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = handle
    weld.Part1 = targetPart
    if handleAttachment and characterAttachment then
        weld.C0 = handleAttachment.CFrame
        weld.C1 = characterAttachment.CFrame
    else
        weld.C0 = CFrame.new()
        weld.C1 = accessory.AttachmentPoint
        handle.CFrame = targetPart.CFrame * weld.C1
    end
    weld.Parent = handle
end

local function copyGeneratedAvatar(userId, character)
    local generatedOk, sourceModel = pcall(function()
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    if not generatedOk or not sourceModel then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local sourceHumanoid = sourceModel:FindFirstChildOfClass("Humanoid")
    clearAvatarAppearance(character)

    if humanoid and sourceHumanoid
        and humanoid.RigType == Enum.HumanoidRigType.R15
        and sourceHumanoid.RigType == Enum.HumanoidRigType.R15 then
        local bodyParts = {
            Head = Enum.BodyPartR15.Head,
            UpperTorso = Enum.BodyPartR15.UpperTorso,
            LowerTorso = Enum.BodyPartR15.LowerTorso,
            LeftUpperArm = Enum.BodyPartR15.LeftUpperArm,
            LeftLowerArm = Enum.BodyPartR15.LeftLowerArm,
            LeftHand = Enum.BodyPartR15.LeftHand,
            RightUpperArm = Enum.BodyPartR15.RightUpperArm,
            RightLowerArm = Enum.BodyPartR15.RightLowerArm,
            RightHand = Enum.BodyPartR15.RightHand,
            LeftUpperLeg = Enum.BodyPartR15.LeftUpperLeg,
            LeftLowerLeg = Enum.BodyPartR15.LeftLowerLeg,
            LeftFoot = Enum.BodyPartR15.LeftFoot,
            RightUpperLeg = Enum.BodyPartR15.RightUpperLeg,
            RightLowerLeg = Enum.BodyPartR15.RightLowerLeg,
            RightFoot = Enum.BodyPartR15.RightFoot,
        }
        for partName, bodyPart in pairs(bodyParts) do
            local sourcePart = sourceModel:FindFirstChild(partName)
            if sourcePart and sourcePart:IsA("BasePart") then
                local replacement = sourcePart:Clone()
                replacement.Name = partName
                replacement.Anchored = false
                replacement.CanCollide = false
                pcall(function()
                    humanoid:ReplaceBodyPartR15(bodyPart, replacement)
                end)
            end
        end
    end

    for _, child in ipairs(sourceModel:GetChildren()) do
        if child:IsA("BodyColors")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic")
            or child:IsA("CharacterMesh") then
            child:Clone().Parent = character
        elseif child:IsA("Accessory") or child:IsA("Accoutrement") then
            local accessory = child:Clone()
            accessory.Parent = character
            weldAvatarAccessory(accessory, character)
        end
    end

    local sourceHead = sourceModel:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    if sourceHead and targetHead then
        for _, child in ipairs(targetHead:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child:Destroy()
            end
        end
        for _, child in ipairs(sourceHead:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child:Clone().Parent = targetHead
            end
        end
    end

    sourceModel:Destroy()
    return true
end

local function applyAdminAvatar(character)
    character = character or localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return false
    end

    local descriptionOk, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(ADMIN_USER_ID)
    end)
    if not descriptionOk or not description then
        applyCreatorTag(character)
        return false
    end

    local applied = pcall(function()
        humanoid:ApplyDescriptionReset(description)
    end)
    if not applied then
        applied = pcall(function()
            humanoid:ApplyDescription(description)
        end)
    end

    local copied = copyGeneratedAvatar(ADMIN_USER_ID, character)

    task.defer(function()
        if character == localPlayer.Character then
            applyCreatorTag(character)
        end
    end)
    return applied or copied
end

identityState.CharacterAddedConnection = localPlayer.CharacterAdded:Connect(function(character)
    task.spawn(function()
        task.wait(0.35)
        if character == localPlayer.Character then
            applyAdminAvatar(character)
        end
    end)
end)

task.spawn(applyAdminAvatar, localPlayer.Character)

if _G.CartiAdminAbuseUI then
    pcall(function()
        _G.CartiAdminAbuseUI:Destroy()
    end)
end

local COLORS = {
    panel = Color3.fromRGB(7, 6, 14),
    surface = Color3.fromRGB(29, 12, 54),
    surfaceDark = Color3.fromRGB(23, 9, 44),
    purple = Color3.fromRGB(128, 31, 221),
    purpleBright = Color3.fromRGB(168, 45, 255),
    purpleSoft = Color3.fromRGB(87, 25, 145),
    line = Color3.fromRGB(49, 27, 70),
    text = Color3.fromRGB(213, 190, 239),
    muted = Color3.fromRGB(148, 125, 170),
    white = Color3.fromRGB(239, 227, 248),
}

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, topColor, bottomColor, rotation)
    return create("UIGradient", {
        Color = ColorSequence.new(topColor, bottomColor),
        Rotation = rotation or 90,
    }, parent)
end

local function label(parent, text, position, size, textSize, color, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or COLORS.text,
        TextSize = textSize,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local function button(parent, name, text, position, size, active)
    local control = create("TextButton", {
        Name = name,
        AutoButtonColor = false,
        BackgroundColor3 = active and Color3.fromRGB(116, 27, 204) or Color3.fromRGB(36, 16, 61),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = active and COLORS.white or COLORS.text,
        TextSize = 12,
    }, parent)
    corner(control, 6)
    stroke(control, active and COLORS.purpleBright or COLORS.line, active and 0.54 or 0.7, 1)
    control:SetAttribute("CartiBaseColor", control.BackgroundColor3)
    return control
end

local function addHover(control)
    control.MouseEnter:Connect(function()
        local baseColor = control:GetAttribute("CartiBaseColor") or control.BackgroundColor3
        control.BackgroundColor3 = Color3.fromRGB(
            math.min(255, math.floor(baseColor.R * 255) + 14),
            math.min(255, math.floor(baseColor.G * 255) + 7),
            math.min(255, math.floor(baseColor.B * 255) + 18)
        )
    end)
    control.MouseLeave:Connect(function()
        control.BackgroundColor3 = control:GetAttribute("CartiBaseColor") or control.BackgroundColor3
    end)
end

local function setButtonActive(control, active)
    local baseColor = active and Color3.fromRGB(116, 27, 204) or Color3.fromRGB(36, 16, 61)
    control:SetAttribute("CartiBaseColor", baseColor)
    control.BackgroundColor3 = baseColor
    control.TextColor3 = active and COLORS.white or COLORS.text
end

local gui = create("ScreenGui", {
    Name = "CartiAdminAbuseUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

_G.CartiAdminAbuseUI = gui

local panel = create("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(220, 290),
    ClipsDescendants = true,
}, gui)
corner(panel, 11)
stroke(panel, Color3.fromRGB(38, 20, 55), 0.22, 1)
gradient(panel, Color3.fromRGB(10, 8, 18), Color3.fromRGB(5, 5, 11), 90)

local header = create("Frame", {
    Name = "Header",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 50),
    ZIndex = 3,
}, panel)

label(header, "⚡", UDim2.fromOffset(14, 3), UDim2.fromOffset(17, 20), 15, Color3.fromRGB(255, 205, 70))
local titleLabel = label(header, "ADMIN ABUSE", UDim2.fromOffset(30, 3), UDim2.fromOffset(145, 20), 13, COLORS.text)
titleLabel.Font = Enum.Font.GothamBold
local gameSubtitle = label(header, "Steal an Egg", UDim2.fromOffset(15, 24), UDim2.fromOffset(160, 20), 11, COLORS.muted)
gameSubtitle.Font = Enum.Font.GothamMedium
local watermark = label(
    header,
    "t<b><font size=\"15\">.</font></b>me/cartiscripts",
    UDim2.new(1, -125, 0, 24),
    UDim2.fromOffset(110, 20),
    8,
    COLORS.muted,
    Enum.TextXAlignment.Right
)
watermark.Font = Enum.Font.GothamMedium
watermark.Name = "Watermark"
watermark.RichText = true

local toggleHint = label(
    header,
    "F7 Toggle",
    UDim2.new(1, -91, 0, 3),
    UDim2.fromOffset(53, 18),
    8,
    COLORS.muted,
    Enum.TextXAlignment.Right
)
toggleHint.Name = "ToggleHint"
toggleHint.Font = Enum.Font.GothamMedium

local closeButton = button(header, "CartiCloseButton", "X", UDim2.new(1, -30, 0, 3), UDim2.fromOffset(24, 23), false)
closeButton.TextSize = 12
closeButton.BackgroundColor3 = Color3.fromRGB(72, 20, 101)
closeButton:SetAttribute("CartiBaseColor", closeButton.BackgroundColor3)
addHover(closeButton)

create("Frame", {
    Name = "HeaderDivider",
    BackgroundColor3 = COLORS.line,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(15, 48),
    Size = UDim2.new(1, -30, 0, 1),
}, header)

local pages = create("Frame", {
    Name = "Pages",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 50),
    Size = UDim2.new(1, 0, 1, -50),
}, panel)

local overview = create("ScrollingFrame", {
    Name = "Content",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 688),
    ElasticBehavior = Enum.ElasticBehavior.Never,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarImageColor3 = Color3.fromRGB(102, 42, 143),
    ScrollBarImageTransparency = 0.08,
    ScrollBarThickness = 2,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
}, pages)

local globalTab = button(overview, "GlobalTab", "🌍 Global", UDim2.fromOffset(13, 13), UDim2.fromOffset(94, 35), false)
local serverTab = button(overview, "ServerTab", "🖥️ Server", UDim2.fromOffset(112, 13), UDim2.fromOffset(95, 35), true)
local announcementScope = "Server"

local announcementInput = create("TextBox", {
    Name = "AnnouncementInput",
    BackgroundColor3 = Color3.fromRGB(32, 14, 56),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(13, 57),
    Size = UDim2.fromOffset(194, 39),
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderColor3 = Color3.fromRGB(111, 88, 132),
    PlaceholderText = "Type your message...",
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center,
}, overview)
corner(announcementInput, 6)
stroke(announcementInput, COLORS.line, 0.7, 1)

local announce = button(overview, "SendAnnouncement", "📣 Send Announcement", UDim2.fromOffset(18, 105), UDim2.fromOffset(184, 31), true)
announce.TextSize = 11

local mutationNames = {
    "Unicorn",
    "Kitsune",
    "Nightflame",
    "Archdemon",
    "Dreadscale",
    "Mecha",
    "Shattered",
}
local mutationButtons = {}
local selectedEgg = "Unicorn"
for index, name in ipairs(mutationNames) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    local mutation = button(
        overview,
        name,
        name,
        UDim2.fromOffset(13 + (column * 66), 146 + (row * 42)),
        UDim2.fromOffset(column == 2 and 62 or 61, 35),
        index == 1
    )
    mutation.TextSize = 11
    mutation.TextScaled = true
    create("UITextSizeConstraint", {
        MinTextSize = 7,
        MaxTextSize = 11,
    }, mutation)
    addHover(mutation)
    mutationButtons[name] = mutation
end

local actions = overview

local function inputRow(name, caption, value, y)
    local row = create("Frame", {
        Name = name,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(13, y),
        Size = UDim2.fromOffset(194, 34),
    }, actions)
    corner(row, 4)
    gradient(row, Color3.fromRGB(34, 15, 62), Color3.fromRGB(23, 9, 44), 0)
    label(row, caption, UDim2.fromOffset(8, 0), UDim2.fromOffset(66, 34), 11, COLORS.text)

    local input = create("TextBox", {
        Name = "Input",
        BackgroundColor3 = Color3.fromRGB(26, 10, 51),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(74, 3),
        Size = UDim2.fromOffset(116, 28),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = COLORS.muted,
        Text = value,
        TextColor3 = COLORS.text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, row)
    corner(input, 4)
    return input
end

local quantityInput = inputRow("QuantityRow", "Quantity:", "1", 278)
local playerInput = inputRow("PlayerRow", "Player:", "", 316)

local spawnEggs = button(actions, "SpawnEggs", "🥚 Spawn Eggs", UDim2.fromOffset(13, 362), UDim2.fromOffset(194, 39), false)
local spawnToPlayer = button(actions, "SpawnEggsToPlayer", "🥚 Spawn Eggs to Player", UDim2.fromOffset(13, 409), UDim2.fromOffset(194, 39), false)
local spawnEggsInServer = button(actions, "SpawnEggsInServer", "🥚 Spawn Eggs in Server", UDim2.fromOffset(13, 456), UDim2.fromOffset(194, 39), false)
local startRift = button(actions, "StartRift", "🌌 Start Rift", UDim2.fromOffset(13, 503), UDim2.fromOffset(194, 39), false)
local giveAdmin = button(actions, "GiveAdmin", "👑 Give Admin", UDim2.fromOffset(13, 550), UDim2.fromOffset(194, 39), false)
local botNameInput = inputRow("BotNameRow", "Bot Name:", "", 597)
botNameInput.PlaceholderText = "Roblox username"
local createBotButton = button(actions, "CreateBot", "🤖 Create Bot", UDim2.fromOffset(13, 639), UDim2.fromOffset(194, 39), false)
for _, actionButton in ipairs({ spawnEggs, spawnToPlayer, startRift, giveAdmin, spawnEggsInServer, createBotButton }) do
    actionButton.TextSize = 11
    actionButton.TextColor3 = Color3.fromRGB(220, 199, 239)
    actionButton.BackgroundColor3 = Color3.fromRGB(39, 18, 65)
    actionButton:SetAttribute("CartiBaseColor", actionButton.BackgroundColor3)
    actionButton.TextXAlignment = Enum.TextXAlignment.Left
    create("UIPadding", { PaddingLeft = UDim.new(0, 9) }, actionButton)
    addHover(actionButton)
end

local function getRandomBiomeId()
    local biomeIds = {}
    for areaId in pairs(areas.Directory) do
        table.insert(biomeIds, areaId)
    end

    table.sort(biomeIds, function(left, right)
        return tostring(left) < tostring(right)
    end)

    if #biomeIds == 0 then
        return nil
    end

    return biomeIds[random:NextInteger(1, #biomeIds)]
end

local function showRandomRiftNotification()
    local biomeId = getRandomBiomeId()
    if biomeId == nil then
        return nil
    end

    riftSpawnNotification.Top({
        AreaId = biomeId,
        Time = 6,
    })

    return biomeId
end

local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$")
end

local function showAnnouncement(message)
    message = trim(message)
    if message == "" then
        return false
    end

    local thumbnail = ""
    pcall(function()
        thumbnail = Players:GetUserThumbnailAsync(
            ADMIN_USER_ID,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
    end)

    messageNotification.Top({
        ShowShadow = true,
        Message = ": " .. message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        Image = thumbnail ~= "" and thumbnail or nil,
        SingleLine = true,
    })

    return true
end

local VERIFIED_BADGE = utf8.char(0xE000)

local function escapeRichText(value)
    local escaped = tostring(value or "")
    escaped = string.gsub(escaped, "&", "&amp;")
    escaped = string.gsub(escaped, "<", "&lt;")
    escaped = string.gsub(escaped, ">", "&gt;")
    escaped = string.gsub(escaped, '"', "&quot;")
    escaped = string.gsub(escaped, "'", "&apos;")
    return escaped
end

local function composeEggName(quantity)
    local suffix = quantity == 1 and " Egg" or " Eggs"
    return "Divine " .. selectedEgg .. suffix
end

local function showEggSpawnNotification(quantity, targetPlayer)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local sender = escapeRichText(ADMIN_USERNAME)
    local eggName = escapeRichText(composeEggName(quantity))
    local firstLine = string.format(
        '<font color="#20BFFF">%s %s</font> <font color="#FFFFFF">spawned</font> <font color="#FFD51B">%d %s</font>',
        sender,
        VERIFIED_BADGE,
        quantity,
        eggName
    )

    local message
    local singleLine
    if targetPlayer ~= nil then
        targetPlayer = trim(targetPlayer)
        if targetPlayer == "" then
            return false
        end

        message = string.format(
            "%s\n<font color=\"#FFFFFF\">in</font> <font color=\"#FF3B3B\">%s's server!</font>",
            firstLine,
            escapeRichText(targetPlayer)
        )
        singleLine = false
    else
        message = firstLine .. '<font color="#FFD51B">!</font>'
        singleLine = true
    end

    messageNotification.Top({
        ShowShadow = true,
        Message = message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        Size = not singleLine and UDim2.fromScale(1.5, 0.6) or nil,
        WrapText = not singleLine,
        SingleLine = singleLine,
    })

    return true
end

local function showSpawnEggs(quantity)
    return showEggSpawnNotification(quantity, nil)
end

local function showSpawnEggsToPlayer(playerName, quantity)
    return showEggSpawnNotification(quantity, playerName)
end

local function showGiveAdminNotification(playerName)
    playerName = trim(playerName)
    if playerName == "" then
        return false
    end

    local sender = escapeRichText(ADMIN_USERNAME)
    local message = string.format(
        '<font color="#20BFFF">%s %s</font> <font color="#FFFFFF">gave admin to</font> <font color="#FF3B3B">%s!</font>',
        sender,
        VERIFIED_BADGE,
        escapeRichText(playerName)
    )

    messageNotification.Top({
        ShowShadow = true,
        Message = message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        SingleLine = true,
    })

    return true
end

local EGG_MODEL_NAMES = {
    Unicorn = "Unicorn",
    Kitsune = "Kitsune",
    Nightflame = "Godzilla",
    Archdemon = "Archdemon Dragon",
    Dreadscale = "Monster Egg",
    Mecha = "Mecha Egg",
    Shattered = "Crystal Egg",
}

local function attachDivineRarityVfx(model)
    local hitbox = model:FindFirstChild("Hitbox")
    local particles = ReplicatedStorage:FindFirstChild("Assets")
    particles = particles and particles:FindFirstChild("Particles")
    local rarityVfx = particles and particles:FindFirstChild("EggRarityVFX")
    local source = rarityVfx and rarityVfx:FindFirstChild("RarityNumber9+")
    if not (hitbox and hitbox:IsA("BasePart") and source) then
        return false
    end

    local vfxModel = Instance.new("Model")
    for _, child in ipairs(source:GetChildren()) do
        child:Clone().Parent = vfxModel
    end
    local sourceHitboxY = math.max(source:GetAttribute("HitboxSizeY") or 5, 1)
    vfxModel:ScaleTo(hitbox.Size.Y / sourceHitboxY)
    for _, child in ipairs(vfxModel:GetChildren()) do
        child.Parent = hitbox
    end
    vfxModel:Destroy()

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ParticleEmitter")
            or descendant:IsA("Beam")
            or descendant:IsA("Trail")
            or descendant:IsA("Light") then
            descendant.Enabled = true
        end
    end
    return true
end

local function getLocalEggFolder()
    local folder = workspace:FindFirstChild("CartiLocalSpawnedEggs")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CartiLocalSpawnedEggs"
        folder.Parent = workspace
    end
    return folder
end

local function addNativeEggPrompt(model)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CarryAreaEgg"
    prompt.ActionText = "Steal"
    prompt.ObjectText = "Egg"
    prompt.HoldDuration = 1.2
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.ClickablePrompt = true
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

    smartProximityPrompt.AttachToModel(prompt, model, {
        PartName = "CartiEggSmartPromptPart",
        SurfaceOffset = 0.75,
        TrackDistance = 8,
        MaxActivationDistance = 8,
    })
    return prompt
end

local function getNativeNestTemplate()
    local objects = workspace:FindFirstChild("__OBJECTS")
    local areasFolder = objects and objects:FindFirstChild("Areas")
    local guardAreas = areasFolder and areasFolder:FindFirstChild("GuardAreas")
    if not guardAreas then
        return nil
    end

    for _, descendant in ipairs(guardAreas:GetDescendants()) do
        if descendant:IsA("Model") and descendant.Name == "NestModel" then
            return descendant
        end
    end

    return nil
end

local function makePassThrough(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
        end
    end
end

local function groundModelAt(model, targetPosition, raycastFilter)
    local templateRotation = model:GetPivot().Rotation
    model:PivotTo(CFrame.new(targetPosition) * templateRotation)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = raycastFilter
    raycastParams.IgnoreWater = false
    raycastParams.RespectCanCollide = true

    local hit = workspace:Raycast(
        targetPosition + Vector3.new(0, 24, 0),
        Vector3.new(0, -100, 0),
        raycastParams
    )
    local groundY = hit and hit.Position.Y or targetPosition.Y - 3
    local boundingCFrame, boundingSize = model:GetBoundingBox()
    local verticalOffset = groundY + (boundingSize.Y / 2) - boundingCFrame.Position.Y
    model:PivotTo(model:GetPivot() + Vector3.new(0, verticalOffset, 0))
    return groundY
end

local function spawnNativeEggModels(quantity)
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    local modelName = EGG_MODEL_NAMES[selectedEgg]
    local eggTemplates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Eggs")
    local template = modelName and eggTemplates:FindFirstChild(modelName)
    if not (template and template:IsA("Model")) then
        return false
    end

    quantity = math.clamp(math.floor(tonumber(quantity) or 1), 1, 20)
    local folder = getLocalEggFolder()
    local nestTemplate = getNativeNestTemplate()
    local columns = math.min(quantity, 5)
    local spacing = 28

    for index = 1, quantity do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        local horizontalOffset = (column - ((columns - 1) / 2)) * spacing
        local forwardOffset = 16 + (row * spacing)
        local targetPosition = rootPart.Position
            + (rootPart.CFrame.LookVector * forwardOffset)
            + (rootPart.CFrame.RightVector * horizontalOffset)

        local clone = template:Clone()
        clone.Name = "Divine " .. selectedEgg .. " Egg"
        attachDivineRarityVfx(clone)
        clone:ScaleTo(clone:GetScale() * 4)
        clone.Parent = folder
        makePassThrough(clone)

        local nest
        if nestTemplate then
            nest = nestTemplate:Clone()
            nest.Name = clone.Name .. " Nest"
            nest.Parent = folder

            local _, eggSize = clone:GetBoundingBox()
            local _, originalNestSize = nest:GetBoundingBox()
            local originalDiameter = math.max(originalNestSize.X, originalNestSize.Z)
            if originalDiameter > 0 then
                local desiredDiameter = math.max(eggSize.X, eggSize.Z) * 1.2
                nest:ScaleTo(nest:GetScale() * (desiredDiameter / originalDiameter))
            end
            makePassThrough(nest)
            local groundY = groundModelAt(nest, targetPosition, { character, folder })

            local eggSpotBottom = nest:FindFirstChild("EggSpotBottom", true)
            if eggSpotBottom and eggSpotBottom:IsA("BasePart") then
                local fullSink = groundY - eggSpotBottom.Position.Y
                nest:PivotTo(nest:GetPivot() + Vector3.new(0, fullSink * 0.5, 0))
            end
            local _, scaledNestSize = nest:GetBoundingBox()
            local nestCFrame = nest:GetBoundingBox()
            local seatPosition = eggSpotBottom and eggSpotBottom.Position
                or Vector3.new(targetPosition.X, nestCFrame.Position.Y + (scaledNestSize.Y / 2), targetPosition.Z)

            clone:PivotTo(CFrame.new(seatPosition) * clone:GetPivot().Rotation)
            local eggCFrame, seatedEggSize = clone:GetBoundingBox()
            local eggBottom = eggCFrame.Position.Y - (seatedEggSize.Y / 2)
            clone:PivotTo(clone:GetPivot() + Vector3.new(0, seatPosition.Y - eggBottom, 0))
        else
            groundModelAt(clone, targetPosition, { character, folder })
        end

        addNativeEggPrompt(clone)
    end

    return true, quantity
end

local function getBotFolder()
    local folder = workspace:FindFirstChild("CartiLocalBots")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CartiLocalBots"
        folder.Parent = workspace
    end
    return folder
end

local function spawnedEggChoices()
    local folder = workspace:FindFirstChild("CartiLocalSpawnedEggs")
    local choices = {}
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model")
                and child.Name:match(" Egg$")
                and not child:GetAttribute("CartiBotCarried") then
                table.insert(choices, child)
            end
        end
    end
    return choices, folder
end

local function floorYAt(position, exclude)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclude or {}
    params.IgnoreWater = false
    params.RespectCanCollide = true
    local hit = workspace:Raycast(
        position + Vector3.new(0, 40, 0),
        Vector3.new(0, -140, 0),
        params
    )
    return hit and hit.Position.Y or position.Y
end

local function placeBotOnFloor(bot, position, lookAtPosition, exclude)
    local rotation = CFrame.new()
    local flatLook = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
    if (flatLook - position).Magnitude > 0.1 then
        rotation = CFrame.lookAt(position, flatLook).Rotation
    end
    bot:PivotTo(CFrame.new(position) * rotation)
    local boundsCFrame, boundsSize = bot:GetBoundingBox()
    local groundY = floorYAt(position, exclude)
    local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
    bot:PivotTo(bot:GetPivot() + Vector3.new(0, groundY - bottomY, 0))
end

local function nativeCharacterAnimationId(folderName, animationName, fallback)
    local character = localPlayer.Character
    local animate = character and character:FindFirstChild("Animate")
    local folder = animate and animate:FindFirstChild(folderName)
    local animation = folder and folder:FindFirstChild(animationName)
    return animation and animation:IsA("Animation") and animation.AnimationId or fallback
end

local function loadBotTrack(humanoid, animationId, priority, looped)
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
    animator.Parent = humanoid
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if not ok or not track then
        return nil
    end
    track.Priority = priority
    track.Looped = looped
    return track
end

local function moveBotTo(bot, destination, timeout)
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    local root = bot:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return false
    end

    local started = os.clock()
    local lastCommand = 0
    while bot.Parent and humanoid.Health > 0 and os.clock() - started < timeout do
        local flatDistance = (
            Vector3.new(root.Position.X, 0, root.Position.Z)
            - Vector3.new(destination.X, 0, destination.Z)
        ).Magnitude
        if flatDistance <= 4 then
            humanoid:MoveTo(root.Position)
            return true
        end
        if os.clock() - lastCommand >= 1.5 then
            humanoid:MoveTo(destination)
            lastCommand = os.clock()
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

local function removeEggPromptNear(egg)
    local eggCFrame, eggSize = egg:GetBoundingBox()
    local radius = math.max(eggSize.X, eggSize.Y, eggSize.Z)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("BasePart")
            and child.Name == "CartiEggSmartPromptPart"
            and (child.Position - eggCFrame.Position).Magnitude <= radius then
            child:Destroy()
        end
    end
end

local function carryEggWithBot(bot, egg, eggFolder)
    local root = bot:FindFirstChild("HumanoidRootPart")
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return nil
    end

    egg:SetAttribute("CartiBotCarried", true)
    removeEggPromptNear(egg)
    local nest = eggFolder and eggFolder:FindFirstChild(egg.Name .. " Nest")
    if nest then
        nest:Destroy()
    end

    for _, descendant in ipairs(egg:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.Massless = true
        end
    end

    local eggBoundsCFrame, eggBoundsSize = egg:GetBoundingBox()
    local pivotToBottom = egg:GetPivot().Position.Y
        - (eggBoundsCFrame.Position.Y - (eggBoundsSize.Y / 2))
    local rootGroundOffset = humanoid.HipHeight + (root.Size.Y / 2)
    local carryHeight = pivotToBottom - rootGroundOffset + 0.75
    local carryForward = math.max(2.5, math.max(eggBoundsSize.X, eggBoundsSize.Z) * 0.3)

    local connection = RunService.Heartbeat:Connect(function()
        if bot.Parent and egg.Parent and root.Parent then
            egg:PivotTo(root.CFrame * CFrame.new(0, carryHeight, -carryForward))
        end
    end)
    return connection
end

local function createEggStealingBot(username)
    username = trim(username)
    if username == "" then
        return false, "Enter a Roblox username"
    end

    local eggChoices, eggFolder = spawnedEggChoices()
    if #eggChoices == 0 then
        return false, "Spawn an egg in the server first"
    end
    local targetEgg = eggChoices[random:NextInteger(1, #eggChoices)]

    local userId
    local resolved = pcall(function()
        userId = Players:GetUserIdFromNameAsync(username)
    end)
    if not resolved or not userId then
        return false, "Roblox user not found"
    end

    local created, bot = pcall(function()
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    if not created or not bot then
        return false, "Could not create bot avatar"
    end

    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    local root = bot:FindFirstChild("HumanoidRootPart")
    local separationLine = workspace:FindFirstChild("__OBJECTS")
        and workspace.__OBJECTS:FindFirstChild("Areas")
        and workspace.__OBJECTS.Areas:FindFirstChild("SeparationLine")
    if not humanoid or not root or not (separationLine and separationLine:IsA("BasePart")) then
        bot:Destroy()
        return false, "Bot rig or safe-zone line is unavailable"
    end

    bot.Name = username .. " Bot"
    humanoid.DisplayName = username
    humanoid.NameDisplayDistance = 120
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.WalkSpeed = 340
    bot.PrimaryPart = root
    bot.Parent = getBotFolder()
    local eggCFrame, eggSize = targetEgg:GetBoundingBox()
    local lineRight = separationLine.CFrame.RightVector
    local lineForward = separationLine.CFrame.LookVector
    local lateral = math.clamp(
        lineRight:Dot(eggCFrame.Position - separationLine.Position),
        -(separationLine.Size.X / 2) + 6,
        (separationLine.Size.X / 2) - 6
    )
    local spawnPosition = separationLine.Position + (lineRight * lateral) - (lineForward * 5)
    placeBotOnFloor(bot, spawnPosition, eggCFrame.Position, { bot, eggFolder })

    local approachDirection = Vector3.new(
        -targetEgg:GetPivot().LookVector.X,
        0,
        -targetEgg:GetPivot().LookVector.Z
    )
    approachDirection = approachDirection.Magnitude > 0.1 and approachDirection.Unit or lineForward
    local approachRadius = (math.max(eggSize.X, eggSize.Z) / 2) + 3
    local approachPosition = eggCFrame.Position + (approachDirection * approachRadius)
    approachPosition = Vector3.new(
        approachPosition.X,
        floorYAt(approachPosition, { bot, eggFolder }),
        approachPosition.Z
    )

    local runId = humanoid.RigType == Enum.HumanoidRigType.R6
        and "rbxassetid://180426354"
        or nativeCharacterAnimationId("run", "RunAnim", "rbxassetid://913376220")
    local runTrack = loadBotTrack(humanoid, runId, Enum.AnimationPriority.Movement, true)
    if runTrack then
        runTrack:Play(0.15)
        runTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
    end

    task.spawn(function()
        local reachedEgg = moveBotTo(bot, approachPosition, 45)
        if not reachedEgg or not bot.Parent or not targetEgg.Parent then
            bot:Destroy()
            return
        end

        if runTrack then
            runTrack:Stop(0.15)
        end
        humanoid:MoveTo(root.Position)
        bot:PivotTo(bot:GetPivot() + Vector3.new(
            approachPosition.X - root.Position.X,
            0,
            approachPosition.Z - root.Position.Z
        ))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local faceEgg = Vector3.new(eggCFrame.Position.X, root.Position.Y, eggCFrame.Position.Z)
        if (faceEgg - root.Position).Magnitude > 0.1 then
            root.CFrame = CFrame.lookAt(root.Position, faceEgg)
        end
        task.wait(2)

        local stealId = humanoid.RigType == Enum.HumanoidRigType.R6
            and "rbxassetid://182393478"
            or nativeCharacterAnimationId("toolnone", "ToolNoneAnim", "rbxassetid://507768375")
        local stealTrack = loadBotTrack(humanoid, stealId, Enum.AnimationPriority.Action, true)
        if stealTrack then
            stealTrack:Play(0.1)
        end
        local carryConnection = carryEggWithBot(bot, targetEgg, eggFolder)

        local exitLateral = math.clamp(
            lineRight:Dot(root.Position - separationLine.Position),
            -(separationLine.Size.X / 2) + 6,
            (separationLine.Size.X / 2) - 6
        )
        local exitPosition = separationLine.Position + (lineRight * exitLateral) - (lineForward * 24)
        exitPosition = Vector3.new(
            exitPosition.X,
            floorYAt(exitPosition, { bot, eggFolder }),
            exitPosition.Z
        )
        if runTrack then
            runTrack:Play(0.1)
            runTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
        end
        moveBotTo(bot, exitPosition, 30)

        if carryConnection then
            carryConnection:Disconnect()
        end
        if targetEgg.Parent then
            targetEgg:Destroy()
        end
        bot:Destroy()
    end)

    return true, bot
end

local callbacks = {
    SendAnnouncement = showAnnouncement,
    SpawnEggs = showSpawnEggs,
    SpawnEggsToPlayer = showSpawnEggsToPlayer,
    StartRift = showRandomRiftNotification,
    GiveAdmin = showGiveAdminNotification,
    SpawnEggsInServer = spawnNativeEggModels,
    CreateBot = createEggStealingBot,
}

local integrityFailed = false
local integrityConnection
local api = {}

function api.SetCallbacks(newCallbacks)
    if integrityFailed then
        return false
    end
    for name, callback in pairs(newCallbacks or {}) do
        if callbacks[name] ~= nil and type(callback) == "function" then
            callbacks[name] = callback
        end
    end
    return true
end

function api.ShowOverview()
    overview.Visible = true
    overview.CanvasPosition = Vector2.zero
end

function api.ShowActions()
    overview.Visible = true
    overview.CanvasPosition = Vector2.new(0, 266)
end

function api.SetPlayerName(name)
    playerInput.Text = tostring(name or "")
end

function api.SetQuantity(amount)
    quantityInput.Text = tostring(math.max(1, math.floor(tonumber(amount) or 1)))
end

function api.SetSelectedEgg(name)
    if not mutationButtons[name] then
        return false
    end

    selectedEgg = name
    for eggName, eggButton in pairs(mutationButtons) do
        setButtonActive(eggButton, eggName == selectedEgg)
    end
    return true
end

function api.GetSelectedEgg()
    return selectedEgg
end

function api.SetAnnouncementMessage(message)
    announcementInput.Text = tostring(message or "")
end

function api.SendAnnouncement(message)
    if message ~= nil then
        announcementInput.Text = tostring(message)
    end
    return callbacks.SendAnnouncement(announcementInput.Text)
end

function api.StartRift()
    return callbacks.StartRift()
end

function api.ShowSpawnEggs(quantity)
    return callbacks.SpawnEggs(quantity or quantityInput.Text)
end

function api.ShowSpawnEggsToPlayer(playerName, quantity)
    return callbacks.SpawnEggsToPlayer(playerName or playerInput.Text, quantity or quantityInput.Text)
end


function api.GiveAdmin(playerName)
    if playerName ~= nil then
        playerInput.Text = tostring(playerName)
    end
    return callbacks.GiveAdmin(playerInput.Text)
end

function api.SpawnEggsInServer(quantity)
    return callbacks.SpawnEggsInServer(quantity or quantityInput.Text)
end

function api.CreateBot(username)
    if username ~= nil then
        botNameInput.Text = tostring(username)
    end
    return callbacks.CreateBot(botNameInput.Text)
end

function api.Destroy()
    integrityFailed = true
    if integrityConnection then
        integrityConnection:Disconnect()
        integrityConnection = nil
    end
    if _G.CartiAdminAbuse == api then
        _G.CartiAdminAbuse = nil
    end
    if gui.Parent then
        gui:Destroy()
    end
end

_G.CartiAdminAbuse = api

integrityConnection = RunService.Heartbeat:Connect(function()
    local intact = watermark.Parent == header
        and watermark:IsDescendantOf(gui)
        and watermark.Name == "Watermark"
        and watermark.Text == "t<b><font size=\"15\">.</font></b>me/cartiscripts"
        and watermark.RichText
        and watermark.TextSize == 8
        and watermark.Font == Enum.Font.GothamMedium
        and watermark.TextXAlignment == Enum.TextXAlignment.Right
        and watermark.Visible
        and watermark.TextTransparency == 0

    if intact then
        return
    end

    integrityFailed = true
    for name in pairs(callbacks) do
        callbacks[name] = function()
            return false
        end
    end
    if _G.CartiAdminAbuse == api then
        _G.CartiAdminAbuse = nil
    end
    integrityConnection:Disconnect()
    integrityConnection = nil
    if gui.Parent then
        gui:Destroy()
    end
end)

globalTab.MouseButton1Click:Connect(function()
    announcementScope = "Global"
    setButtonActive(globalTab, true)
    setButtonActive(serverTab, false)
end)

serverTab.MouseButton1Click:Connect(function()
    announcementScope = "Server"
    setButtonActive(serverTab, true)
    setButtonActive(globalTab, false)
end)

for _, name in ipairs(mutationNames) do
    overview[name].MouseButton1Click:Connect(function()
        api.SetSelectedEgg(name)
    end)
end

announce.MouseButton1Click:Connect(function()
    callbacks.SendAnnouncement(announcementInput.Text)
end)

announcementInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        callbacks.SendAnnouncement(announcementInput.Text)
    end
end)

spawnEggs.MouseButton1Click:Connect(function()
    callbacks.SpawnEggs(math.max(1, tonumber(quantityInput.Text) or 1))
end)

spawnToPlayer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsToPlayer(playerInput.Text, math.max(1, tonumber(quantityInput.Text) or 1))
end)

startRift.MouseButton1Click:Connect(function()
    callbacks.StartRift()
end)

giveAdmin.MouseButton1Click:Connect(function()
    callbacks.GiveAdmin(playerInput.Text)
end)

spawnEggsInServer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsInServer(quantityInput.Text)
end)

createBotButton.MouseButton1Click:Connect(function()
    callbacks.CreateBot(botNameInput.Text)
end)

botNameInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        callbacks.CreateBot(botNameInput.Text)
    end
end)

closeButton.MouseButton1Click:Connect(api.Destroy)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F7 and gui.Parent then
        gui.Enabled = not gui.Enabled
    end
end)

local dragging = false
local dragStart
local panelStart

header.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    dragging = true
    dragStart = input.Position
    panelStart = panel.Position

    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    panel.Position = UDim2.new(
        panelStart.X.Scale,
        panelStart.X.Offset + delta.X,
        panelStart.Y.Scale,
        panelStart.Y.Offset + delta.Y
    )
end)

return api
