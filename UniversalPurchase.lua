local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local localPlayer = Players.LocalPlayer

local localRobuxAmount = 414
local itemRobuxCost = 100
local productImage = "http://www.roblox.com/thumbs/asset.ashx?assetid=140329623504091&x=100&y=100&format=png"
local productName = "Gems x100"
local realPromptWatcherEnabled = true
local lastCapturedPromptRoot = nil
local lastCapturedAt = 0
local watcherScanUntil = 0
local watcherScanQueued = false
local watcherCandidates = {}
local foundationOverlayDebug = false
local foundationDebugLastMessageAt = {}
local pendingPurchaseRoot = nil
local pendingPurchaseStartedAt = 0
local activeReplacementRoot = nil
local activeReplacementSignature = ""
local activeReplacementAt = 0

if _G.CartiHubFoundationOverlayWatcherState then
    _G.CartiHubFoundationOverlayWatcherState.Enabled = false

    for _, connection in ipairs(_G.CartiHubFoundationOverlayWatcherState.Connections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local foundationWatcherState = {
    Enabled = true,
    Connections = {},
}

_G.CartiHubFoundationOverlayWatcherState = foundationWatcherState

local function foundationDebug(key, message)
    if not foundationOverlayDebug then
        return
    end

    local now = os.clock()
    if foundationDebugLastMessageAt[key] and now - foundationDebugLastMessageAt[key] < 0.35 then
        return
    end

    foundationDebugLastMessageAt[key] = now
    print("[FoundationOverlay Debug] " .. tostring(message))
end

-- File-level layout references for live configging
local currentGui = nil
local currentBackdrop = nil
local currentSheetContainer = nil
local currentSheetScale = nil
local currentSheetFrame = nil
local currentSheet = nil
local currentActions = nil

local currentSuccessCard = nil
local currentSuccessStroke = nil
local currentSuccessTitle = nil
local currentSuccessCloseBtn = nil
local currentSuccessCloseIcon = nil
local currentSuccessCheckmark = nil
local currentSuccessMsg = nil
local currentSuccessOKBtn = nil
local currentSuccessOKLabel = nil

local clearSuppressedRealPurchaseOverlays
local clearFoundationOverlaySafeArea
local clearFoundationOverlaySafeAreaBurst
local releaseInputLockBurst
local suppressedRealOverlayStates = {}
local suppressRealOverlaySequence = 0
local safeAreaClearSequence = 0
local lastReplicaShownAt = 0

-- ==========================================
-- RUNTIME CONFIG (adjusted via the config GUI)
-- ==========================================
local RuntimeConfig = {
    StretchX = 1.0,  -- horizontal scale multiplier for the prompt card
    StretchY = 1.0,  -- vertical scale multiplier for the prompt card
    BotUILength = 1.0, -- length multiplier for the bottom section (actions area)

    -- Success Card Configs:
    SuccessCardHeight = 0.85, -- Height multiplier relative to baseH
    SuccessCardY = 0.50,       -- Y scale position of the success card (0.5 for center)
    SuccessCheckmarkSize = 65, -- Size of the checkmark icon
    SuccessCheckmarkX = 0,     -- X offset of the checkmark icon
    SuccessCheckmarkY = 58.00, -- Y position of the checkmark
    SuccessTextSize = 20,      -- Text size of the success message
    SuccessTextX = 3.60,       -- X offset of the success message
    SuccessTextY = 129.60,     -- Y position of the success message
    SuccessOKButtonWidth = -35.74, -- OK Button offset width
    SuccessOKButtonHeight = 39.05, -- OK Button height
    SuccessOKButtonY = 175,    -- Y position of the OK button (relative to card top)
    SuccessOKTextSize = 15,    -- OK Button Text size
    SuccessOKTextBold = 1,     -- 1 = bold, 0 = semibold (OK text a little more bold)
    SuccessTitleTextSize = 24.97, -- Success Title Text size
    SuccessTitleX = 14,        -- Success Title X position
    SuccessTitleY = 3.00,      -- Success Title Y position
    SuccessCloseButtonSize = 35.48, -- Success Close button size
    SuccessCloseButtonX = -45.82, -- Success Close button X position
    SuccessCloseButtonY = 7.00,   -- Success Close button Y position
    SuccessCloseIconSize = 25.90, -- Success Close icon size
}

local function safeParent()
    local ok = pcall(function()
        return CoreGui.Name
    end)

    if ok then
        return CoreGui
    end

    return localPlayer:WaitForChild("PlayerGui")
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function makeText(parent, name, text, size, position, textSize, color, font)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(27, 42, 53)
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.RichText = true
    label.Parent = parent
    return label
end

local function getFont(name, fallback)
    local ok, font = pcall(function()
        return Enum.Font[name]
    end)

    if ok and font then
        return font
    end

    return fallback
end

-- ==========================================
-- MAIN PROMPT (1:1 replica from 1to1.lua + working buy button)
-- ==========================================
local function showFoundationOverlayPromptReplica()
    local parent = safeParent()
    local old = parent:FindFirstChild("CartiHubFoundationOverlayReplica")
    if old then
        old:Destroy()
    end

    lastReplicaShownAt = os.clock()

    local sX = RuntimeConfig.StretchX
    local sY = RuntimeConfig.StretchY
    local botLen = RuntimeConfig.BotUILength

    -- Base dimensions from 1to1.lua, scaled by config
    local baseW = math.floor(456 * sX)
    local baseH = math.floor(273 * sY)

    local gui = Instance.new("ScreenGui")
    gui.Name = "CartiHubFoundationOverlayReplica"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2147483647
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local sheetColor = Color3.fromRGB(27, 29, 35)
    local panelColor = Color3.fromRGB(27, 29, 35)
    local textColor = Color3.fromRGB(235, 237, 241)
    local subTextColor = Color3.fromRGB(205, 207, 214)
    local borderColor = Color3.fromRGB(72, 75, 84)
    local titleFont = getFont("BuilderSansBold", Enum.Font.GothamBold)
    local boldFont = getFont("BuilderSansBold", Enum.Font.GothamBold)
    local mediumFont = getFont("BuilderSansMedium", Enum.Font.GothamSemibold)
    local regularFont = getFont("BuilderSans", Enum.Font.Gotham)

    local safeArea = Instance.new("Frame")
    safeArea.Name = "SafeAreaFrame"
    safeArea.Size = UDim2.fromScale(1, 1)
    safeArea.BackgroundTransparency = 1
    safeArea.BorderSizePixel = 0
    safeArea.Parent = gui

    local overlayPortal = Instance.new("Frame")
    overlayPortal.Name = "OverlayPortal"
    overlayPortal.Size = UDim2.fromScale(1, 1)
    overlayPortal.BackgroundTransparency = 1
    overlayPortal.BorderSizePixel = 0
    overlayPortal.ZIndex = 200
    overlayPortal.Parent = safeArea

    local backdrop = Instance.new("ImageButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(2, 2)
    backdrop.Position = UDim2.fromScale(-0.5, -0.5)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Image = ""
    backdrop.AutoButtonColor = false
    backdrop.ZIndex = 1
    backdrop.Parent = overlayPortal

    local sheetContainer = Instance.new("Frame")
    sheetContainer.Name = "SheetContainer"
    sheetContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    sheetContainer.Size = UDim2.fromOffset(baseW, baseH)
    local sheetFinalPosition = UDim2.new(0.5, 0, 0.5, -8)
    sheetContainer.Position = UDim2.new(0.5, 0, 0.5, 6)
    sheetContainer.BackgroundTransparency = 1
    sheetContainer.BorderSizePixel = 0
    sheetContainer.ZIndex = 2
    sheetContainer.Parent = overlayPortal

    local sheetScale = Instance.new("UIScale")
    sheetScale.Scale = 0.985
    sheetScale.Parent = sheetContainer

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(baseW, baseH)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = sheetContainer

    local sheet = Instance.new("ImageButton")
    sheet.Name = "Sheet"
    sheet.Size = UDim2.fromOffset(baseW, baseH)
    sheet.Position = UDim2.fromOffset(0, 0)
    sheet.BackgroundColor3 = sheetColor
    sheet.BackgroundTransparency = 0
    sheet.BorderSizePixel = 0
    sheet.Image = ""
    sheet.AutoButtonColor = false
    sheet.ClipsDescendants = true
    sheet.ZIndex = 2
    sheet.Parent = frame
    makeCorner(sheet, 13)

    local sheetStroke = Instance.new("UIStroke")
    sheetStroke.Color = Color3.fromRGB(255, 255, 255)
    sheetStroke.Transparency = 0.88
    sheetStroke.Thickness = 1
    sheetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    sheetStroke.Parent = sheet

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.fromScale(1, 1)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Parent = sheet

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 47)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = content

    local closeButton = Instance.new("ImageButton")
    closeButton.Name = "CloseAffordance"
    closeButton.Size = UDim2.fromOffset(40, 40)
    closeButton.Position = UDim2.new(1, -52, 0, 8)
    closeButton.BackgroundTransparency = 1
    closeButton.BorderSizePixel = 0
    closeButton.Image = ""
    closeButton.Parent = header

    local closeLineA = Instance.new("Frame")
    closeLineA.Name = "IconLineA"
    closeLineA.AnchorPoint = Vector2.new(0.5, 0.5)
    closeLineA.Size = UDim2.fromOffset(18, 2)
    closeLineA.Position = UDim2.fromOffset(20, 20)
    closeLineA.BackgroundColor3 = textColor
    closeLineA.BorderSizePixel = 0
    closeLineA.Rotation = 45
    closeLineA.Parent = closeButton
    makeCorner(closeLineA, 1)

    local closeLineB = closeLineA:Clone()
    closeLineB.Name = "IconLineB"
    closeLineB.Rotation = -45
    closeLineB.Parent = closeButton

    local titleArea = Instance.new("Frame")
    titleArea.Name = "SubContent"
    titleArea.Size = UDim2.new(1, -96, 0, 28)
    titleArea.Position = UDim2.fromOffset(20, 16)
    titleArea.BackgroundTransparency = 1
    titleArea.BorderSizePixel = 0
    titleArea.Parent = header

    local title = makeText(titleArea, "RobuxAmount", "Buy item", UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(0, 0), 23, Color3.fromRGB(236, 238, 242), titleFont)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local headerPrice = Instance.new("Frame")
    headerPrice.Name = "RobuxPrice"
    headerPrice.AnchorPoint = Vector2.new(1, 0)
    headerPrice.Size = UDim2.fromOffset(72, 28)
    headerPrice.Position = UDim2.new(1, -32, 0, 21)
    headerPrice.BackgroundTransparency = 1
    headerPrice.BorderSizePixel = 0
    headerPrice.Parent = header

    local headerRobuxIcon = makeText(headerPrice, "Icon", '<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json" weight="400">robux</font>', UDim2.fromOffset(21, 21), UDim2.fromOffset(0, 3), 20, textColor, regularFont)
    headerRobuxIcon.TextXAlignment = Enum.TextXAlignment.Center
    local headerRobuxAmount = makeText(headerPrice, "Amount", tostring(localRobuxAmount), UDim2.new(1, -25, 1, 0), UDim2.fromOffset(25, 0), 16, textColor, boldFont)
    headerRobuxAmount.TextXAlignment = Enum.TextXAlignment.Left

    local productContent = Instance.new("Frame")
    productContent.Name = "Content"
    productContent.Size = UDim2.new(1, 0, 0, 78)
    productContent.Position = UDim2.fromOffset(0, 54)
    productContent.BackgroundTransparency = 1
    productContent.BorderSizePixel = 0
    productContent.Parent = content

    local details = Instance.new("Frame")
    details.Name = "Details"
    details.Size = UDim2.new(1, -40, 0, 70)
    details.Position = UDim2.fromOffset(20, 2)
    details.BackgroundTransparency = 1
    details.BorderSizePixel = 0
    details.Parent = productContent

    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.fromOffset(72, 72)
    itemIcon.Position = UDim2.fromOffset(0, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.BorderSizePixel = 0
    itemIcon.Image = productImage
    itemIcon.Parent = details

    local itemTextFrame = Instance.new("Frame")
    itemTextFrame.Name = "ItemDetailsFrame"
    itemTextFrame.Size = UDim2.new(1, -92, 0, 48)
    itemTextFrame.Position = UDim2.fromOffset(80, 16)
    itemTextFrame.BackgroundTransparency = 1
    itemTextFrame.BorderSizePixel = 0
    itemTextFrame.Parent = details

    local itemName = makeText(itemTextFrame, "ItemName", productName, UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 0), 15, Color3.fromRGB(238, 240, 244), boldFont)
    itemName.TextXAlignment = Enum.TextXAlignment.Left

    local itemCost = Instance.new("Frame")
    itemCost.Name = "ItemCost"
    itemCost.Size = UDim2.fromOffset(84, 22)
    itemCost.Position = UDim2.fromOffset(0, 25)
    itemCost.BackgroundTransparency = 1
    itemCost.BorderSizePixel = 0
    itemCost.Parent = itemTextFrame

    local itemRobuxIcon = makeText(itemCost, "Icon", '<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json" weight="400">robux</font>', UDim2.fromOffset(18, 18), UDim2.fromOffset(0, 2), 17, Color3.fromRGB(238, 240, 244), regularFont)
    itemRobuxIcon.TextXAlignment = Enum.TextXAlignment.Center
    local itemRobuxAmount = makeText(itemCost, "Amount", tostring(itemRobuxCost), UDim2.new(1, -22, 1, 0), UDim2.fromOffset(22, 0), 14, Color3.fromRGB(238, 240, 244), boldFont)
    itemRobuxAmount.TextXAlignment = Enum.TextXAlignment.Left

    -- Actions area: scaled by BotUILength
    local actionsBaseH = math.floor(131 * botLen)
    local actionsBaseY = math.floor(137 * sY)

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    actions.Size = UDim2.new(1, 0, 0, actionsBaseH)
    actions.Position = UDim2.fromOffset(0, actionsBaseY)
    actions.BackgroundTransparency = 1
    actions.BorderSizePixel = 0
    actions.Parent = content

    local buyButton = Instance.new("ImageButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(1, -40, 0, 40)
    buyButton.Position = UDim2.fromOffset(20, 20)
    buyButton.BackgroundColor3 = Color3.fromRGB(45, 86, 230)
    buyButton.BackgroundTransparency = 0
    buyButton.BorderSizePixel = 0
    buyButton.Image = ""
    buyButton.AutoButtonColor = false
    buyButton.Active = false
    buyButton.ClipsDescendants = true
    buyButton.Parent = actions
    makeCorner(buyButton, 7)

    local buyFill = Instance.new("Frame")
    buyFill.Name = "AnimatedFill"
    buyFill.Size = UDim2.fromScale(0, 1)
    buyFill.Position = UDim2.fromOffset(0, 0)
    buyFill.BackgroundColor3 = Color3.fromRGB(51, 97, 255)
    buyFill.BackgroundTransparency = 0
    buyFill.BorderSizePixel = 0
    buyFill.ZIndex = buyButton.ZIndex + 1
    buyFill.Parent = buyButton
    makeCorner(buyFill, 7)

    local buyText = makeText(buyButton, "Text", "Buy", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 16, Color3.fromRGB(246, 247, 250), mediumFont)
    buyText.ZIndex = buyFill.ZIndex + 1

    local banner = Instance.new("ImageButton")
    banner.Name = "BlackbirdUpsellBanner"
    banner.Size = UDim2.new(1, -40, 0, 44)
    banner.Position = UDim2.fromOffset(20, 72)
    banner.BackgroundColor3 = panelColor
    banner.BackgroundTransparency = 0
    banner.BorderSizePixel = 0
    banner.Image = ""
    banner.AutoButtonColor = false
    banner.Parent = actions
    makeCorner(banner, 9)

    local bannerStroke = Instance.new("UIStroke")
    bannerStroke.Color = borderColor
    bannerStroke.Transparency = 0.08
    bannerStroke.Thickness = 1
    bannerStroke.Parent = banner

    makeText(banner, "BlackbirdIcon", '<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json" weight="400">roblox-plus</font>', UDim2.fromOffset(22, 22), UDim2.fromOffset(13, 12), 20, textColor, regularFont)
    local bannerText = makeText(banner, "BannerText", "Get 10% off with Roblox Plus", UDim2.new(1, -128, 0, 22), UDim2.fromOffset(42, 12), 13, Color3.fromRGB(218, 220, 226), regularFont)
    bannerText.TextXAlignment = Enum.TextXAlignment.Left

    local badge = Instance.new("Frame")
    badge.Name = "NewBadge"
    badge.AnchorPoint = Vector2.new(1, 0.5)
    badge.Size = UDim2.fromOffset(44, 26)
    badge.Position = UDim2.new(1, -12, 0.5, 0)
    badge.BackgroundColor3 = Color3.fromRGB(247, 247, 248)
    badge.BackgroundTransparency = 0
    badge.BorderSizePixel = 0
    badge.Parent = banner
    makeCorner(badge, 13)
    makeText(badge, "Text", "New", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 13, Color3.fromRGB(32, 34, 39), boldFont)

    -- ==========================================
    -- SUCCESS CARD (ported 1:1 from reference)
    -- ==========================================
    local ANIM_OFFSET = 0.04
    local BuyDarkColor = Color3.fromRGB(0x26, 0x3d, 0x8f)
    local BuyLightColor = Color3.fromRGB(0x33, 0x5f, 0xff)
    local CloseIconId = "rbxassetid://6031094678"
    local SuccessIconId = "rbxassetid://135084016839600"
    local SuccessMessageColor = Color3.fromRGB(200, 200, 200)

    currentGui = gui
    currentBackdrop = backdrop
    currentSheetContainer = sheetContainer
    currentSheetScale = sheetScale
    currentSheetFrame = frame
    currentSheet = sheet
    currentActions = actions

    local function showSuccessCard()
        -- Success card: flat Frame parented to gui directly (like reference's screenGui)
        local card2 = Instance.new("Frame")
        local succH = math.floor(baseH * RuntimeConfig.SuccessCardHeight)
        card2.Size = UDim2.fromOffset(baseW, succH)
        card2.AnchorPoint = Vector2.new(0.5, 0.5)
        card2.Position = UDim2.new(0.5, 0, RuntimeConfig.SuccessCardY + ANIM_OFFSET, 0)
        card2.BackgroundColor3 = sheetColor
        card2.BackgroundTransparency = 1
        card2.BorderSizePixel = 0
        card2.ZIndex = 11
        card2.Parent = overlayPortal
        makeCorner(card2, 13)

        local card2Stroke = Instance.new("UIStroke")
        card2Stroke.Color = Color3.fromRGB(255, 255, 255)
        card2Stroke.Transparency = 0.88
        card2Stroke.Thickness = 1
        card2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        card2Stroke.Parent = card2

        -- Animate in: slide up + fade in (0.28s Quint Out)
        TweenService:Create(backdrop, TweenInfo.new(0.28, Enum.EasingStyle.Linear), {
            BackgroundTransparency = 0.45,
        }):Play()
        TweenService:Create(card2, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, RuntimeConfig.SuccessCardY, 0),
            BackgroundTransparency = 0,
        }):Play()

        -- Header: "Purchase completed" title
        local successTitle = Instance.new("TextLabel")
        successTitle.Size = UDim2.new(1, -20, 0, 47)
        successTitle.Position = UDim2.fromOffset(RuntimeConfig.SuccessTitleX, RuntimeConfig.SuccessTitleY)
        successTitle.BackgroundTransparency = 1
        successTitle.Text = "Purchase completed"
        successTitle.TextColor3 = textColor
        successTitle.TextSize = RuntimeConfig.SuccessTitleTextSize
        successTitle.Font = titleFont
        successTitle.TextXAlignment = Enum.TextXAlignment.Left
        successTitle.TextYAlignment = Enum.TextYAlignment.Center
        successTitle.ZIndex = 12
        successTitle.Parent = card2

        -- Close button with image icon
        local closeBtn2 = Instance.new("ImageButton")
        local btnSz = RuntimeConfig.SuccessCloseButtonSize
        closeBtn2.Size = UDim2.fromOffset(btnSz, btnSz)
        closeBtn2.Position = UDim2.new(1, RuntimeConfig.SuccessCloseButtonX, 0, RuntimeConfig.SuccessCloseButtonY)
        closeBtn2.BackgroundTransparency = 1
        closeBtn2.Image = ""
        closeBtn2.ZIndex = 12
        closeBtn2.Parent = card2

        local closeIcon2 = Instance.new("ImageLabel")
        local iconSz = RuntimeConfig.SuccessCloseIconSize
        closeIcon2.Size = UDim2.fromOffset(iconSz, iconSz)
        closeIcon2.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIcon2.Position = UDim2.new(0.5, 0, 0.5, 0)
        closeIcon2.BackgroundTransparency = 1
        closeIcon2.Image = CloseIconId
        closeIcon2.ImageColor3 = subTextColor
        closeIcon2.ScaleType = Enum.ScaleType.Fit
        closeIcon2.ZIndex = 13
        closeIcon2.Parent = closeBtn2

        -- Checkmark image
        local successIconPx = RuntimeConfig.SuccessCheckmarkSize
        local successIconX = RuntimeConfig.SuccessCheckmarkX
        local successIconY = RuntimeConfig.SuccessCheckmarkY
        local checkImg = Instance.new("ImageLabel")
        checkImg.Size = UDim2.fromOffset(successIconPx, successIconPx)
        checkImg.AnchorPoint = Vector2.new(0.5, 0)
        checkImg.Position = UDim2.new(0.5, successIconX, 0, successIconY)
        checkImg.BackgroundTransparency = 1
        checkImg.Image = SuccessIconId
        checkImg.ScaleType = Enum.ScaleType.Fit
        checkImg.ZIndex = 12
        checkImg.Parent = card2

        -- Success message
        local successMsgX = RuntimeConfig.SuccessTextX
        local successMsgY = RuntimeConfig.SuccessTextY
        local successMsg = Instance.new("TextLabel")
        successMsg.Size = UDim2.new(1, -20, 0, 28)
        successMsg.Position = UDim2.new(0.5, successMsgX, 0, successMsgY)
        successMsg.AnchorPoint = Vector2.new(0.5, 0)
        successMsg.BackgroundTransparency = 1
        successMsg.Text = "You have successfully bought " .. tostring(productName) .. "."
        successMsg.TextColor3 = SuccessMessageColor
        successMsg.TextSize = RuntimeConfig.SuccessTextSize
        successMsg.Font = mediumFont
        successMsg.TextWrapped = true
        successMsg.TextScaled = false
        successMsg.TextXAlignment = Enum.TextXAlignment.Center
        successMsg.TextYAlignment = Enum.TextYAlignment.Top
        successMsg.ZIndex = 12
        successMsg.Parent = card2

        -- OK button: starts dark, tweens to bright
        local okBtnW = RuntimeConfig.SuccessOKButtonWidth
        local okBtnH = RuntimeConfig.SuccessOKButtonHeight
        local okBtnY = RuntimeConfig.SuccessOKButtonY
        local okBtn = Instance.new("TextButton")
        okBtn.Size = UDim2.new(1, okBtnW, 0, okBtnH)
        okBtn.Position = UDim2.new(0, math.floor(-okBtnW / 2), 0, okBtnY)
        okBtn.BackgroundColor3 = BuyDarkColor
        okBtn.BorderSizePixel = 0
        okBtn.Text = ""
        okBtn.ZIndex = 12
        okBtn.ClipsDescendants = true
        okBtn.AutoButtonColor = false
        okBtn.Parent = card2
        makeCorner(okBtn, 7)

        local okLabel = Instance.new("TextLabel")
        okLabel.Size = UDim2.fromScale(1, 1)
        okLabel.BackgroundTransparency = 1
        okLabel.Text = "OK"
        okLabel.TextColor3 = textColor
        okLabel.TextSize = RuntimeConfig.SuccessOKTextSize
        okLabel.Font = RuntimeConfig.SuccessOKTextBold > 0.5 and getFont("BuilderSansBold", Enum.Font.GothamBold) or getFont("BuilderSansMedium", Enum.Font.GothamSemibold)
        okLabel.ZIndex = 13
        okLabel.Parent = okBtn

        currentSuccessCard = card2
        currentSuccessStroke = card2Stroke
        currentSuccessTitle = successTitle
        currentSuccessCloseBtn = closeBtn2
        currentSuccessCloseIcon = closeIcon2
        currentSuccessCheckmark = checkImg
        currentSuccessMsg = successMsg
        currentSuccessOKBtn = okBtn
        currentSuccessOKLabel = okLabel

        -- After 0.1s, tween OK button from dark to bright
        task.delay(0.1, function()
            if not gui.Parent then return end
            TweenService:Create(okBtn, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = BuyLightColor,
            }):Play()
        end)

        -- Close success: card slides down + fades, overlay fades, then destroy
        local function closeSuccess()
            if clearFoundationOverlaySafeAreaBurst then
                clearFoundationOverlaySafeAreaBurst(0.2)
            end

            if clearSuppressedRealPurchaseOverlays then
                clearSuppressedRealPurchaseOverlays()
            end

            local closeTween = TweenService:Create(card2, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, RuntimeConfig.SuccessCardY + ANIM_OFFSET, 0),
                BackgroundTransparency = 1,
            })
            TweenService:Create(backdrop, TweenInfo.new(0.22, Enum.EasingStyle.Linear), {
                BackgroundTransparency = 1,
            }):Play()
            closeTween:Play()
            closeTween.Completed:Connect(function()
                pcall(function() gui:Destroy() end)
                currentSuccessCard = nil
                currentSuccessStroke = nil
                currentSuccessTitle = nil
                currentSuccessCloseBtn = nil
                currentSuccessCloseIcon = nil
                currentSuccessCheckmark = nil
                currentSuccessMsg = nil
                currentSuccessOKBtn = nil
                currentSuccessOKLabel = nil
            end)

            task.delay(0.35, function()
                if gui.Parent then
                    pcall(function()
                        gui:Destroy()
                    end)
                end
            end)
        end

        okBtn.MouseButton1Click:Connect(closeSuccess)
        closeBtn2.MouseButton1Click:Connect(closeSuccess)
    end

    -- ==========================================
    -- CLOSE / BUY HANDLERS
    -- ==========================================
    local function close()
        if clearSuppressedRealPurchaseOverlays then
            clearSuppressedRealPurchaseOverlays()
        end

        if gui.Parent then
            gui:Destroy()
        end

        task.delay(0.15, function()
            if clearSuppressedRealPurchaseOverlays then
                clearSuppressedRealPurchaseOverlays()
            end
        end)

        currentGui = nil
        currentBackdrop = nil
        currentSheetContainer = nil
        currentSheetScale = nil
        currentSheetFrame = nil
        currentSheet = nil
        currentActions = nil
    end

    closeButton.MouseButton1Click:Connect(close)
    backdrop.MouseButton1Click:Connect(close)

    -- Buy button click: exact flow from reference (lines 1063-1092)
    buyButton.MouseButton1Click:Connect(function()
        if not buyButton.Active then return end
        buyButton.Active = false

        localRobuxAmount = math.max(0, localRobuxAmount - itemRobuxCost)
        headerRobuxAmount.Text = tostring(localRobuxAmount)

        -- Reset fill bar (reference line 1067)
        buyFill.Size = UDim2.new(0, 0, 1, 0)

        -- Wait 0.37s before animating out (reference line 1074)
        task.wait(0.37)

        -- Animate buy card out: slide down + fade (reference lines 1076-1080)
        local exitTween = TweenService:Create(sheetContainer, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.5 + 0.02, 0),
        })
        local exitScaleTween = TweenService:Create(sheetScale, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Scale = 0.985,
        })
        -- Fade all sheet children by making sheet transparent
        local exitSheetTween = TweenService:Create(sheet, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })

        exitTween:Play()
        exitScaleTween:Play()
        exitSheetTween:Play()

        exitTween.Completed:Connect(function()
            -- Destroy the buy card container
            pcall(function() sheetContainer:Destroy() end)
            currentSheetContainer = nil
            currentSheetFrame = nil
            currentSheet = nil
            currentActions = nil

            if clearFoundationOverlaySafeAreaBurst then
                clearFoundationOverlaySafeAreaBurst(0.3)
            end

            if releaseInputLockBurst then
                releaseInputLockBurst(1)
            end

            -- Show success card (reference line 1090)
            showSuccessCard()
        end)
    end)

    -- ==========================================
    -- OPEN ANIMATIONS
    -- ==========================================
    TweenService:Create(backdrop, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.25,
    }):Play()

    TweenService:Create(sheetContainer, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = sheetFinalPosition,
    }):Play()

    TweenService:Create(sheetScale, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1,
    }):Play()

    -- Fill bar animation (3 seconds), then enable buy button
    task.delay(0.3, function()
        if buyFill.Parent then
            TweenService:Create(buyFill, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.fromScale(1, 1),
            }):Play()
        end
    end)

    task.delay(3.3, function()
        if buyButton.Parent then
            buyButton.Active = true
            buyButton.AutoButtonColor = false
        end
    end)
end

-- ==========================================
-- REAL FOUNDATION OVERLAY REPLACER
-- ==========================================
local function isOurFoundationGui(instance)
    local current = instance
    while current do
        if current.Name == "CartiHubFoundationOverlayReplica"
            or current.Name == "FoundationOverlayStandaloneTrigger"
            or current.Name == "FoundationOverlayConfigPanel" then
            return true
        end

        current = current.Parent
    end

    return false
end

local function normalizeText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function isVisibleGuiObject(instance)
    if not instance:IsA("GuiObject") or not instance.Visible then
        return false
    end

    local current = instance.Parent
    while current and current:IsA("GuiObject") do
        if not current.Visible then
            return false
        end

        current = current.Parent
    end

    return true
end

local function textLooksNumeric(text)
    text = normalizeText(text)
    return text:match("^%d+$") ~= nil
        or text:lower():match("^robux%s+[%d,]+$") ~= nil
end

local function parseRobuxAmount(text)
    text = normalizeText(text)
    local numberText = text:match("([%d,]+)")
    if not numberText then
        return nil
    end

    local cleaned = numberText:gsub(",", "")
    return tonumber(cleaned)
end

local function getGuiText(instance)
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        return normalizeText(instance.Text)
    end

    return ""
end

local function getScanRoots()
    local roots = {}

    local ok = pcall(function()
        table.insert(roots, CoreGui)
    end)

    if not ok then
        table.insert(roots, localPlayer:WaitForChild("PlayerGui"))
        return roots
    end

    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        table.insert(roots, playerGui)
    end

    return roots
end

local function isRealPromptText(text)
    local lower = normalizeText(text):lower()
    return lower == "buy item"
        or lower:find("buy item", 1, true) ~= nil
        or lower:find("buy robux and item", 1, true) ~= nil
        or lower:find("roblox plus", 1, true) ~= nil
        or lower == "buy"
end

local function findPurchaseOverlayAncestor(instance)
    local current = instance

    while current do
        if not isOurFoundationGui(current) then
            local name = tostring(current.Name):lower()
            if name == "foundationoverlay"
                or name == "purchasepromptapp"
                or name == "commercepurchaseapp"
                or name == "bulkpurchaseapp"
                or name == "inexperiencetransferapp" then
                return current
            end
        end

        if current:IsA("CoreGui") or current:IsA("PlayerGui") then
            break
        end

        current = current.Parent
    end

    return nil
end

local function rootHasPurchasePromptContent(root)
    if not root then
        return false
    end

    local safeArea = root:FindFirstChild("SafeAreaFrame")
    if safeArea and #safeArea:GetChildren() > 0 then
        return true
    end

    local checked = 0
    for _, descendant in ipairs(root:GetDescendants()) do
        checked += 1
        if checked > 350 then
            break
        end

        if descendant:IsA("GuiObject") and not isVisibleGuiObject(descendant) then
            continue
        end

        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
            local text = getGuiText(descendant)
            local lower = text:lower()

            if isRealPromptText(text)
                or lower:find("robux", 1, true)
                or lower:find("purchase", 1, true)
                or textLooksNumeric(text) then
                return true
            end
        elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            local image = tostring(descendant.Image or ""):lower()
            local name = tostring(descendant.Name):lower()

            if name == "itemicon"
                or image:find("thumbs/asset", 1, true)
                or image:find("rbxthumb", 1, true)
                or image:find("assetid=", 1, true) then
                return true
            end
        end
    end

    return false
end

local function getExactPromptItemNameLabel(root)
    local exactName = root and root:FindFirstChild("ItemName", true)
    if exactName and exactName:IsA("TextLabel") then
        local text = normalizeText(exactName.Text)
        if text ~= "" and #text > 1 and text:lower() ~= "x" then
            return exactName
        end
    end

    return nil
end

local function getExactPromptItemCostLabel(root)
    local exactCost = root and root:FindFirstChild("ItemCost", true)
    if exactCost and exactCost:IsA("TextLabel") and parseRobuxAmount(exactCost.Text) then
        return exactCost
    end

    return nil
end

local function getExactPromptItemIcon(root)
    local exactIcon = root and root:FindFirstChild("ItemIcon", true)
    if exactIcon and (exactIcon:IsA("ImageLabel") or exactIcon:IsA("ImageButton")) then
        local image = tostring(exactIcon.Image or "")
        if image ~= "" then
            return exactIcon
        end
    end

    return nil
end

local function getPurchaseRootPriority(root)
    local name = tostring(root and root.Name or "")
    if name == "FoundationOverlay" then
        return 1
    elseif name == "PurchasePromptApp" then
        return 2
    elseif name == "CommercePurchaseApp" then
        return 3
    elseif name == "BulkPurchaseApp" then
        return 4
    elseif name == "InExperienceTransferApp" then
        return 5
    end

    return 99
end

local function getKnownPurchaseRoots()
    local roots = {}

    for _, scanRoot in ipairs(getScanRoots()) do
        for _, name in ipairs({
            "FoundationOverlay",
            "PurchasePromptApp",
            "CommercePurchaseApp",
            "BulkPurchaseApp",
            "InExperienceTransferApp",
        }) do
            for _, overlay in ipairs(scanRoot:GetChildren()) do
                if overlay.Name == name and not isOurFoundationGui(overlay) and rootHasPurchasePromptContent(overlay) then
                    table.insert(roots, overlay)
                end
            end
        end
    end

    table.sort(roots, function(a, b)
        return getPurchaseRootPriority(a) < getPurchaseRootPriority(b)
    end)

    return roots
end

local function instanceNameLooksLikePurchaseOverlay(instance)
    local name = tostring(instance.Name or ""):lower()
    return name:find("foundation", 1, true) ~= nil
        or name:find("purchase", 1, true) ~= nil
        or name:find("prompt", 1, true) ~= nil
        or name:find("overlay", 1, true) ~= nil
        or name:find("iap", 1, true) ~= nil
        or name:find("commerce", 1, true) ~= nil
end

local function promptRootScore(root)
    local score = 0

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            local text = getGuiText(descendant)
            local lower = text:lower()

            if lower == "buy item" or lower:find("buy item", 1, true) then
                score += 20
            elseif text == "Buy" then
                score += 5
            elseif lower:find("roblox plus", 1, true) then
                score += 8
            elseif textLooksNumeric(text) then
                score += 2
            end

            if (descendant:IsA("ImageLabel") or descendant:IsA("ImageButton"))
                and tostring(descendant.Image or "") ~= "" then
                score += 1
            end
        end
    end

    if instanceNameLooksLikePurchaseOverlay(root) then
        score += 10
    end

    return score
end

local function findPromptRootFromBuyItemLabel(label)
    local current = label
    local bestSizedRoot = nil

    foundationDebug("label", ("prompt text candidate: %s <%s> text=%q"):format(
        label:GetFullName(),
        label.ClassName,
        getGuiText(label)
    ))

    while current do
        if current:IsA("GuiObject") and not isOurFoundationGui(current) then
            if instanceNameLooksLikePurchaseOverlay(current) then
                foundationDebug("root", ("using named overlay root: %s <%s>"):format(current:GetFullName(), current.ClassName))
                return current
            end

            local size = current.AbsoluteSize
            if size.X >= 300 and size.X <= 900 and size.Y >= 160 and size.Y <= 650 then
                bestSizedRoot = current
            end
        end

        if current:IsA("ScreenGui") or current:IsA("CoreGui") or current:IsA("PlayerGui") then
            break
        end

        current = current.Parent
    end

    if bestSizedRoot then
        foundationDebug("root", ("using sized prompt root: %s <%s> size=%dx%d"):format(
            bestSizedRoot:GetFullName(),
            bestSizedRoot.ClassName,
            bestSizedRoot.AbsoluteSize.X,
            bestSizedRoot.AbsoluteSize.Y
        ))
    else
        foundationDebug("root_none", "prompt text matched, but no usable root was found")
    end

    return bestSizedRoot
end

local function findRealFoundationPromptRoot(candidate)
    if not candidate or isOurFoundationGui(candidate) then
        return nil
    end

    local purchaseRoot = findPurchaseOverlayAncestor(candidate)
    if purchaseRoot and rootHasPurchasePromptContent(purchaseRoot) then
        foundationDebug("root", ("using purchase overlay ancestor: %s <%s>"):format(purchaseRoot:GetFullName(), purchaseRoot.ClassName))
        return purchaseRoot
    end

    local function tryTextObject(instance)
        if not isOurFoundationGui(instance)
            and instance:IsA("GuiObject")
            and isVisibleGuiObject(instance)
            and isRealPromptText(getGuiText(instance)) then
            return findPromptRootFromBuyItemLabel(instance)
        end

        return nil
    end

    local root = tryTextObject(candidate)
    if root then
        return root
    end

    if candidate:IsA("GuiBase") then
        local checked = 0
        for _, descendant in ipairs(candidate:GetDescendants()) do
            checked += 1
            if checked > 250 then
                break
            end

            root = tryTextObject(descendant)
            if root then
                return root
            end
        end
    end

    local current = candidate.Parent
    while current and not current:IsA("ScreenGui") and not current:IsA("CoreGui") and not current:IsA("PlayerGui") do
        root = tryTextObject(current)
        if root then
            return root
        end

        current = current.Parent
    end

    return nil
end

local function findExistingRealFoundationPromptRoot()
    for _, parent in ipairs(getScanRoots()) do
        for _, descendant in ipairs(parent:GetDescendants()) do
            if not isOurFoundationGui(descendant)
                and descendant:IsA("GuiObject")
                and isVisibleGuiObject(descendant)
                and isRealPromptText(getGuiText(descendant)) then
                local root = findPromptRootFromBuyItemLabel(descendant)
                if root then
                    return root
                end
            end
        end
    end

    return nil
end

local function pickPromptProductImage(root)
    local bestImage = nil
    local bestScore = -math.huge

    for _, descendant in ipairs(root:GetDescendants()) do
        if (descendant:IsA("ImageLabel") or descendant:IsA("ImageButton"))
            and tostring(descendant.Image or "") ~= "" then
            local image = tostring(descendant.Image)
            local lowerName = descendant.Name:lower()
            local lowerImage = image:lower()
            local fullName = descendant:GetFullName():lower()
            local area = descendant.AbsoluteSize.X * descendant.AbsoluteSize.Y
            local score = 0

            if lowerName == "itemicon" then
                score += 1000
            end

            if fullName:find("productdetailscontainer", 1, true) then
                score += 600
            end

            if fullName:find("itemdetails", 1, true) then
                score += 250
            end

            if lowerImage:find("thumbs/asset", 1, true)
                or lowerImage:find("rbxthumb", 1, true)
                or lowerImage:find("assetid=", 1, true) then
                score += 300
            end

            score += math.min(area, 20000) / 100

            if lowerName:find("close", 1, true)
                or lowerName:find("shadow", 1, true)
                or lowerName:find("background", 1, true)
                or lowerImage:find("buildericons", 1, true)
                or lowerImage:find("foundationimages", 1, true)
                or lowerImage:find("spritesheets", 1, true)
                or lowerImage:find("close", 1, true) then
                score -= 10000
            end

            if score > bestScore then
                bestScore = score
                bestImage = descendant
            end
        end
    end

    if bestImage then
        foundationDebug("picked_image", ("picked product image: %s image=%s"):format(
            bestImage:GetFullName(),
            tostring(bestImage.Image)
        ))
    end

    return bestImage
end

local function pickPromptProductCost(root, imageObject)
    local exactCost = getExactPromptItemCostLabel(root)
    if exactCost then
        return exactCost
    end

    local bestLabel = nil
    local bestDistance = math.huge
    local fallbackLabel = nil
    local largestAmount = 0

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("TextLabel") and textLooksNumeric(descendant.Text) then
            local text = normalizeText(descendant.Text)
            local lowerName = tostring(descendant.Name):lower()
            local lowerText = text:lower()
            local fullName = descendant:GetFullName():lower()

            if not fullName:find("modalheader", 1, true)
                and not fullName:find("rightside", 1, true)
                and not lowerText:find(" 314", 1, true)
                and not lowerName:find("rightside", 1, true)
                and not lowerName:find("modalheader", 1, true)
                and (not fallbackLabel or lowerName:find("cost", 1, true)) then
                fallbackLabel = descendant
            end

            local amount = parseRobuxAmount(text) or 0
            if amount > largestAmount
                and amount ~= localRobuxAmount
                and not fullName:find("modalheader", 1, true)
                and not fullName:find("rightside", 1, true) then
                largestAmount = amount
                fallbackLabel = descendant
            end

            if imageObject then
                local dx = descendant.AbsolutePosition.X - imageObject.AbsolutePosition.X
                local dy = descendant.AbsolutePosition.Y - imageObject.AbsolutePosition.Y

                if dx >= -10 and dy >= 0 then
                    local distance = math.abs(dx - 72) + math.abs(dy - 38)
                    if distance < bestDistance then
                        bestDistance = distance
                        bestLabel = descendant
                    end
                end
            end
        end
    end

    return bestLabel or fallbackLabel
end

local function pickPromptProductName(root, imageObject)
    local exactName = getExactPromptItemNameLabel(root)
    if exactName then
        return exactName
    end

    if imageObject then
        local siblingName = imageObject.Parent
            and imageObject.Parent:FindFirstChild("ItemDetailsFrame")
            and imageObject.Parent.ItemDetailsFrame:FindFirstChild("ItemName")
        if siblingName and siblingName:IsA("TextLabel") then
            local text = normalizeText(siblingName.Text)
            if text ~= "" and #text > 1 and text:lower() ~= "x" then
                return siblingName
            end
        end
    end

    local bestLabel = nil
    local bestScore = -math.huge

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local text = normalizeText(descendant.Text)
            local lower = text:lower()
            local lowerName = tostring(descendant.Name):lower()
            local fullName = descendant:GetFullName():lower()

            if text ~= ""
                and text ~= "Buy item"
                and text ~= "Buy Robux and item"
                and text ~= "Buy"
                and text ~= "New"
                and lower ~= "x"
                and lower ~= "close"
                and lower ~= "cancel"
                and not textLooksNumeric(text)
                and not lower:find("roblox plus", 1, true)
                and not lower:find("discount", 1, true)
                and not lowerName:find("close", 1, true)
                and not fullName:find("closeaffordance", 1, true)
                and not fullName:find("modalheader", 1, true)
                and not fullName:find("rightside", 1, true) then
                local score = 0

                if lowerName == "itemname" then
                    score += 1000
                end

                if fullName:find("productdetailscontainer", 1, true) then
                    score += 650
                end

                if fullName:find("itemdetails", 1, true) then
                    score += 350
                end

                if fullName:find("details", 1, true) then
                    score += 100
                end

                if imageObject then
                    local dx = descendant.AbsolutePosition.X - imageObject.AbsolutePosition.X
                    local dy = descendant.AbsolutePosition.Y - imageObject.AbsolutePosition.Y

                    if dx >= -20 and dx <= 260 and math.abs(dy) < 120 then
                        score += 300 - math.min(300, math.abs(dx - 80) + math.abs(dy))
                    else
                        score -= 250
                    end
                end

                if #text <= 1 then
                    score -= 1000
                end

                if score > bestScore then
                    bestScore = score
                    bestLabel = descendant
                end
            end
        end
    end

    if bestLabel then
        foundationDebug("picked_name", ("picked product name: %s text=%q"):format(
            bestLabel:GetFullName(),
            tostring(bestLabel.Text)
        ))
    end

    return bestLabel
end

local function hideRealFoundationPrompt(root)
    local hidden = {}

    local function hideOne(instance)
        if not instance or hidden[instance] or isOurFoundationGui(instance) then
            return
        end

        hidden[instance] = true

        pcall(function()
            if instance:IsA("ScreenGui") then
                instance.Enabled = false
            elseif instance:IsA("GuiObject") then
                instance.Visible = false
                instance.Active = false
            end
        end)
    end

    hideOne(root)

    local current = root
    while current and current.Parent do
        if current:IsA("GuiObject") and instanceNameLooksLikePurchaseOverlay(current) then
            hideOne(current)
        end

        if current.Parent:IsA("ScreenGui") then
            break
        end

        current = current.Parent
    end

    pcall(function()
        local parent = root.Parent
        if parent and not parent:IsA("ScreenGui") then
            for _, sibling in ipairs(parent:GetChildren()) do
                if sibling:IsA("GuiObject")
                    and sibling ~= root
                    and not isOurFoundationGui(sibling)
                    and sibling.AbsoluteSize.X >= 200
                    and sibling.AbsoluteSize.Y >= 120
                    and (instanceNameLooksLikePurchaseOverlay(sibling) or sibling.BackgroundTransparency < 1) then
                    hideOne(sibling)
                end
            end
        end
    end)
end

local function suppressRealFoundationOverlays(duration)
    suppressRealOverlaySequence += 1
    local sequence = suppressRealOverlaySequence
    local endsAt = os.clock() + (duration or 2)

    local function hideKnownRoots()
        for _, scanRoot in ipairs(getScanRoots()) do
            for _, name in ipairs({
                "FoundationOverlay",
                "PurchasePromptApp",
                "CommercePurchaseApp",
                "BulkPurchaseApp",
                "InExperienceTransferApp",
            }) do
                local overlay = scanRoot:FindFirstChild(name)
                if overlay and not isOurFoundationGui(overlay) then
                    pcall(function()
                        if overlay:IsA("ScreenGui") then
                            overlay.Enabled = true
                            suppressedRealOverlayStates[overlay] = suppressedRealOverlayStates[overlay] or {
                                Enabled = overlay.Enabled,
                                Children = {},
                            }

                            for _, child in ipairs(overlay:GetChildren()) do
                                if child:IsA("GuiObject") then
                                    suppressedRealOverlayStates[overlay].Children[child] = child.Visible
                                    child.Visible = false
                                    child.Active = false
                                end
                            end
                        elseif overlay:IsA("GuiObject") then
                            suppressedRealOverlayStates[overlay] = suppressedRealOverlayStates[overlay] or {
                                Visible = overlay.Visible,
                                Active = overlay.Active,
                            }
                            overlay.Visible = false
                            overlay.Active = false
                        end
                    end)
                end
            end
        end
    end

    hideKnownRoots()

    task.spawn(function()
        while sequence == suppressRealOverlaySequence and os.clock() < endsAt do
            hideKnownRoots()
            task.wait(0.05)
        end
    end)
end

local function releaseInputLock()
    pcall(function()
        GuiService.SelectedObject = nil
    end)

    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)

    pcall(function()
        UserInputService.MouseIconEnabled = true
    end)

    pcall(function()
        local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
        local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
        if playerModule then
            local controls = require(playerModule):GetControls()
            if controls and controls.Enable then
                controls:Enable()
            end
        end
    end)

    pcall(function()
        local camera = workspace.CurrentCamera
        if camera and camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Custom
        end
    end)

    for _, root in ipairs(getKnownPurchaseRoots()) do
        for _, descendant in ipairs(root:GetDescendants()) do
            if descendant:IsA("GuiButton") then
                descendant.Active = false
                pcall(function()
                    descendant.Modal = false
                end)
            elseif descendant:IsA("GuiObject")
                and descendant.AbsoluteSize.X > 1000
                and descendant.AbsoluteSize.Y > 600 then
                descendant.Active = false
            end
        end
    end
end

local function pulseRobloxMenuUnlock()
    if not VirtualInputManager then
        return
    end

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            task.wait(0.025)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
        end)

        task.defer(releaseInputLock)
        task.delay(0.08, releaseInputLock)
    end)
end

clearFoundationOverlaySafeArea = function()
    for _, scanRoot in ipairs(getScanRoots()) do
        for _, child in ipairs(scanRoot:GetChildren()) do
            if child.Name == "FoundationOverlay" and not isOurFoundationGui(child) then
                local safeArea = child:FindFirstChild("SafeAreaFrame")

                if safeArea then
                    pcall(function()
                        safeArea:ClearAllChildren()
                    end)
                end
            end
        end
    end
end

clearFoundationOverlaySafeAreaBurst = function(duration)
    safeAreaClearSequence += 1
    local sequence = safeAreaClearSequence
    local endsAt = os.clock() + (duration or 0.35)

    task.spawn(function()
        while sequence == safeAreaClearSequence and os.clock() < endsAt do
            clearFoundationOverlaySafeArea()
            task.wait(0.06)
        end
    end)
end

releaseInputLockBurst = function(duration)
    local endsAt = os.clock() + (duration or 2)

    task.spawn(function()
        while os.clock() < endsAt do
            releaseInputLock()
            task.wait(0.1)
        end
    end)
end

clearSuppressedRealPurchaseOverlays = function()
    suppressRealOverlaySequence += 1
    safeAreaClearSequence += 1

    local parent = safeParent()
    local replica = parent:FindFirstChild("CartiHubFoundationOverlayReplica")
    if replica then
        pcall(function()
            replica:Destroy()
        end)
    end

    for overlay, state in pairs(suppressedRealOverlayStates) do
        if overlay and overlay.Parent then
            pcall(function()
                if overlay:IsA("ScreenGui") then
                    overlay.Enabled = true
                elseif overlay:IsA("GuiObject") then
                    overlay.Active = true
                end
            end)
        end
    end

    clearFoundationOverlaySafeArea()
    if clearFoundationOverlaySafeAreaBurst then
        clearFoundationOverlaySafeAreaBurst(0.25)
    end
    releaseInputLock()
    releaseInputLockBurst(2)

    for _, root in ipairs(getKnownPurchaseRoots()) do
        pcall(function()
            if root:IsA("ScreenGui") then
                root.Enabled = true
            end

            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiButton") then
                    descendant.Active = false
                    pcall(function()
                        descendant.Modal = false
                    end)
                elseif descendant:IsA("GuiObject") and descendant.AbsoluteSize.X > 1000 and descendant.AbsoluteSize.Y > 600 then
                    descendant.Active = false
                end
            end
        end)
    end

    clearFoundationOverlaySafeArea()
    releaseInputLock()

    suppressedRealOverlayStates = {}
    pendingPurchaseRoot = nil
    pendingPurchaseStartedAt = 0
    lastCapturedPromptRoot = nil
    lastCapturedAt = 0
    activeReplacementRoot = nil
    activeReplacementSignature = ""
    activeReplacementAt = 0
    foundationDebug("cleanup", "cleared suppressed real purchase overlays")

    task.delay(0.1, releaseInputLock)
    task.delay(0.3, releaseInputLock)
    task.delay(0.6, releaseInputLock)
    task.delay(1.0, releaseInputLock)
    task.delay(1.5, releaseInputLock)
    task.defer(pulseRobloxMenuUnlock)
end

local function captureAndReplaceRealFoundationPrompt(candidate, allowFullScan)
    if not realPromptWatcherEnabled or not foundationWatcherState.Enabled then
        foundationDebug("disabled", "watcher disabled; skipping capture")
        return false
    end

    if candidate then
        foundationDebug("capture_candidate", ("checking candidate: %s <%s>"):format(candidate:GetFullName(), candidate.ClassName))
    elseif allowFullScan then
        foundationDebug("capture_fullscan", "running one-time full prompt scan")
    end

    local root = findRealFoundationPromptRoot(candidate)
    if not root and allowFullScan then
        root = findExistingRealFoundationPromptRoot()
    end

    if not root then
        foundationDebug("no_root", "no real FoundationOverlay prompt root found")
        return false
    end

    safeAreaClearSequence += 1

    for _, candidateRoot in ipairs(getKnownPurchaseRoots()) do
        if candidateRoot ~= root and rootHasPurchasePromptContent(candidateRoot) then
            local candidateName = getExactPromptItemNameLabel(candidateRoot)
            local candidateCost = getExactPromptItemCostLabel(candidateRoot)
            local candidateIcon = getExactPromptItemIcon(candidateRoot)
            local rootName = getExactPromptItemNameLabel(root)
            local rootCost = getExactPromptItemCostLabel(root)
            local rootIcon = getExactPromptItemIcon(root)

            local candidateScore = (candidateName and 2 or 0) + (candidateCost and 2 or 0) + (candidateIcon and 1 or 0)
            local rootScore = (rootName and 2 or 0) + (rootCost and 2 or 0) + (rootIcon and 1 or 0)

            if candidateScore > rootScore
                or (candidateScore == rootScore and getPurchaseRootPriority(candidateRoot) < getPurchaseRootPriority(root)) then
                root = candidateRoot
            end
        end
    end

    local imageObject = pickPromptProductImage(root)
    local costLabel = pickPromptProductCost(root, imageObject)
    local nameLabel = pickPromptProductName(root, imageObject)
    local parsedCost = costLabel and parseRobuxAmount(costLabel.Text)

    foundationDebug("capture_values", ("root=%s image=%s cost=%s name=%s"):format(
        root:GetFullName(),
        imageObject and tostring(imageObject.Image) or "nil",
        costLabel and tostring(costLabel.Text) or "nil",
        nameLabel and tostring(nameLabel.Text) or "nil"
    ))

    hideRealFoundationPrompt(root)
    suppressRealFoundationOverlays(1.5)

    if not parsedCost then
        if pendingPurchaseRoot ~= root then
            pendingPurchaseRoot = root
            pendingPurchaseStartedAt = os.clock()
        end

        foundationDebug("waiting_cost", "real prompt found, waiting for Robux cost before showing replica")

        if os.clock() - pendingPurchaseStartedAt < 2.5 then
            table.insert(watcherCandidates, root)
            watcherScanUntil = math.max(watcherScanUntil, os.clock() + 0.5)
            return false
        end

        foundationDebug("fallback_show", "Robux cost was not found; showing replica with last known/default cost")
    else
        pendingPurchaseRoot = nil
        pendingPurchaseStartedAt = 0
    end

    lastCapturedPromptRoot = root
    lastCapturedAt = os.clock()

    if imageObject and tostring(imageObject.Image or "") ~= "" then
        productImage = imageObject.Image
    end

    itemRobuxCost = parsedCost or itemRobuxCost

    if nameLabel and normalizeText(nameLabel.Text) ~= "" and #normalizeText(nameLabel.Text) > 1 then
        productName = normalizeText(nameLabel.Text)
    end

    local signature = tostring(productName) .. "|" .. tostring(itemRobuxCost) .. "|" .. tostring(productImage)
    if activeReplacementRoot == root
        and activeReplacementSignature == signature
        and os.clock() - activeReplacementAt < 8 then
        suppressRealFoundationOverlays(1)
        return true
    end

    activeReplacementRoot = root
    activeReplacementSignature = signature
    activeReplacementAt = os.clock()

    suppressRealFoundationOverlays(4)
    showFoundationOverlayPromptReplica()

    warn(("[FoundationOverlay Standalone] Replaced real prompt: %s / %s Robux"):format(
        tostring(productName),
        tostring(itemRobuxCost)
    ))

    return true
end

local function startRealFoundationPromptWatcher()
    local function scheduleCapture(candidate)
        watcherScanUntil = math.max(watcherScanUntil, os.clock() + 3)

        if candidate and not isOurFoundationGui(candidate) then
            table.insert(watcherCandidates, candidate)
            if #watcherCandidates > 40 then
                table.remove(watcherCandidates, 1)
            end
        end

        if watcherScanQueued then
            return
        end

        watcherScanQueued = true

        task.spawn(function()
            local nextScanAt = 0

            while realPromptWatcherEnabled and foundationWatcherState.Enabled and os.clock() < watcherScanUntil do
                local now = os.clock()
                if now >= nextScanAt then
                    local candidates = watcherCandidates
                    watcherCandidates = {}

                    for _, currentCandidate in ipairs(candidates) do
                        if captureAndReplaceRealFoundationPrompt(currentCandidate, false) then
                            watcherCandidates = {}
                            watcherScanUntil = 0
                            break
                        end
                    end

                    nextScanAt = now + 0.04
                end

                task.wait(0.05)
            end

            watcherScanQueued = false
        end)
    end

    for _, parent in ipairs(getScanRoots()) do
        local connection = parent.DescendantAdded:Connect(function(descendant)
            local purchaseRoot = findPurchaseOverlayAncestor(descendant)
            if (purchaseRoot and rootHasPurchasePromptContent(purchaseRoot))
                or instanceNameLooksLikePurchaseOverlay(descendant)
                or isRealPromptText(getGuiText(descendant)) then
                if captureAndReplaceRealFoundationPrompt(descendant, false) then
                    return
                end

                scheduleCapture(descendant)
            end
        end)

        table.insert(foundationWatcherState.Connections, connection)
    end

    task.defer(function()
        captureAndReplaceRealFoundationPrompt(nil, true)
        for _, root in ipairs(getKnownPurchaseRoots()) do
            if captureAndReplaceRealFoundationPrompt(root, false) then
                break
            end
        end
    end)

    task.spawn(function()
        while realPromptWatcherEnabled and foundationWatcherState.Enabled do
            if not safeParent():FindFirstChild("CartiHubFoundationOverlayReplica") then
                for _, root in ipairs(getKnownPurchaseRoots()) do
                    captureAndReplaceRealFoundationPrompt(root, false)
                end
            end

            task.wait(0.35)
        end
    end)
end

-- ==========================================
-- CONFIG PANEL
-- ==========================================
local parent = safeParent()
local oldConfig = parent:FindFirstChild("FoundationOverlayConfigPanel")
if oldConfig then
    oldConfig:Destroy()
end

local oldTrigger = parent:FindFirstChild("FoundationOverlayStandaloneTrigger")
if oldTrigger then
    oldTrigger:Destroy()
end

local configGui = Instance.new("ScreenGui")
configGui.Name = "FoundationOverlayConfigPanel"
configGui.ResetOnSpawn = false
configGui.DisplayOrder = 2147483646
configGui.Parent = parent

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 132)
panel.Position = UDim2.new(0, 20, 0.5, -66)
panel.BackgroundColor3 = Color3.fromRGB(34, 18, 52)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = configGui
makeCorner(panel, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(220, 120, 255)
panelStroke.Thickness = 1
panelStroke.Transparency = 0.15
panelStroke.Parent = panel

local panelTitle = Instance.new("TextLabel")
panelTitle.Name = "Title"
panelTitle.Size = UDim2.new(1, -18, 0, 24)
panelTitle.Position = UDim2.fromOffset(9, 8)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "Enter how much robux u want"
panelTitle.TextColor3 = Color3.fromRGB(255, 245, 255)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 14
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.Parent = panel

local robuxBox = Instance.new("TextBox")
robuxBox.Name = "RobuxBox"
robuxBox.Size = UDim2.new(1, -18, 0, 36)
robuxBox.Position = UDim2.fromOffset(9, 40)
robuxBox.BackgroundColor3 = Color3.fromRGB(52, 28, 78)
robuxBox.BorderSizePixel = 0
robuxBox.ClearTextOnFocus = false
robuxBox.PlaceholderText = "Enter Robux amount"
robuxBox.Text = tostring(localRobuxAmount)
robuxBox.TextColor3 = Color3.fromRGB(255, 245, 255)
robuxBox.PlaceholderColor3 = Color3.fromRGB(195, 170, 220)
robuxBox.Font = Enum.Font.Gotham
robuxBox.TextSize = 14
robuxBox.Parent = panel
makeCorner(robuxBox, 8)

local applyButton = Instance.new("TextButton")
applyButton.Name = "ApplyButton"
applyButton.Size = UDim2.new(1, -18, 0, 34)
applyButton.Position = UDim2.fromOffset(9, 88)
applyButton.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
applyButton.BorderSizePixel = 0
applyButton.Text = "APPLY CHANGES"
applyButton.TextColor3 = Color3.fromRGB(255, 245, 255)
applyButton.Font = Enum.Font.GothamBold
applyButton.TextSize = 13
applyButton.Parent = panel
makeCorner(applyButton, 8)

local function applyLocalRobuxAmount()
    local amount = math.max(0, math.floor(tonumber(robuxBox.Text) or localRobuxAmount))
    localRobuxAmount = amount
    robuxBox.Text = tostring(amount)
    applyButton.Text = "APPLIED"

    task.delay(1.2, function()
        if applyButton.Parent then
            applyButton.Text = "APPLY CHANGES"
        end
    end)
end

applyButton.MouseButton1Click:Connect(applyLocalRobuxAmount)
robuxBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        applyLocalRobuxAmount()
    end
end)

startRealFoundationPromptWatcher()

_G.CartiHubShowFoundationOverlayPrompt = showFoundationOverlayPromptReplica
_G.CartiHubReplaceRealFoundationOverlay = function()
    for _, root in ipairs(getKnownPurchaseRoots()) do
        if captureAndReplaceRealFoundationPrompt(root, false) then
            return true
        end
    end

    return captureAndReplaceRealFoundationPrompt(nil, true)
end
_G.CartiHubSetFoundationOverlayWatcher = function(enabled)
    realPromptWatcherEnabled = enabled == true
    foundationWatcherState.Enabled = realPromptWatcherEnabled
end

_G.CartiHubSetFoundationDebug = function(enabled)
    foundationOverlayDebug = enabled == true
end

_G.CartiHubClearFoundationPurchaseOverlays = function()
    if clearSuppressedRealPurchaseOverlays then
        clearSuppressedRealPurchaseOverlays()
    end
end

_G.CartiHubReleaseFoundationInputLock = releaseInputLock
_G.CartiHubReleaseFoundationInputLockBurst = releaseInputLockBurst
_G.CartiHubClearFoundationSafeArea = clearFoundationOverlaySafeArea
_G.CartiHubClearFoundationSafeAreaBurst = clearFoundationOverlaySafeAreaBurst
_G.CartiHubPulseRobloxMenuUnlock = pulseRobloxMenuUnlock

_G.CartiHubEnablePlayerControls = function()
    pcall(function()
        local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
        local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
        if playerModule then
            local controls = require(playerModule):GetControls()
            if controls and controls.Enable then
                controls:Enable()
            end
        end
    end)
end

_G.CartiHubDebugFoundationOverlayScan = function()
    local results = {}

    for _, root in ipairs(getScanRoots()) do
        for _, descendant in ipairs(root:GetDescendants()) do
            if not isOurFoundationGui(descendant) and descendant:IsA("GuiObject") then
                local text = getGuiText(descendant)
                local lowerText = text:lower()
                local lowerName = tostring(descendant.Name):lower()

                if lowerText:find("buy", 1, true)
                    or lowerText:find("robux", 1, true)
                    or lowerText:find("plus", 1, true)
                    or lowerName:find("foundation", 1, true)
                    or lowerName:find("purchase", 1, true)
                    or lowerName:find("prompt", 1, true)
                    or lowerName:find("overlay", 1, true) then
                    table.insert(results, ("%s <%s> visible=%s text=%q"):format(
                        descendant:GetFullName(),
                        descendant.ClassName,
                        tostring(descendant.Visible),
                        text
                    ))

                    if #results >= 80 then
                        break
                    end
                end
            end
        end
    end

    warn("[FoundationOverlay DebugScan]\n" .. table.concat(results, "\n"))
    return results
end
_G.CartiHubSetFoundationRobux = function(amount)
    localRobuxAmount = math.max(0, tonumber(amount) or localRobuxAmount)
end
_G.CartiHubGetFoundationRobux = function()
    return localRobuxAmount
end
_G.CartiHubSetFoundationProduct = function(name, cost, image)
    if name and tostring(name) ~= "" then
        productName = tostring(name)
    end

    if tonumber(cost) then
        itemRobuxCost = tonumber(cost)
    end

    if image and tostring(image) ~= "" then
        productImage = tostring(image)
    end
end

print("[FoundationOverlay Standalone] Loaded.")
