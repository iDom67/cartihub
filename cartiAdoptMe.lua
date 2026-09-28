local carti1 = {
    Players = game:GetService('Players'),
    ReplicatedStorage = game:GetService('ReplicatedStorage'),
    RunService = game:GetService('RunService'),
    UserInputService = game:GetService('UserInputService'),
    TweenService = game:GetService('TweenService'),
    HttpService = game:GetService('HttpService'),
    Chat = game:GetService('Chat')
}
local carti2 = carti1.Players
local carti3 = carti1.ReplicatedStorage
local carti4 = carti1.RunService
local carti5 = carti1.UserInputService
local carti6 = carti1.TweenService
local carti7 = carti1.HttpService

pcall(function()
    setthreadidentity(2)
end)

-- COMPREHENSIVE HOOKS FOR FAKE PLAYERS - MUST BE FIRST
local carti8 = {}
_G.fakePlayerIds = carti8

-- Hook SettingsHelper early with better fake player detection
task.spawn(function()
    task.wait(0.1)
    local carti9 = require(carti3:WaitForChild('Fsys')).load('SettingsHelper')
    local carti10 = carti9.get_setting_server

    carti9.get_setting_server = function(carti240, settingName, ...)
        if carti240 and carti240.UserId then
            if carti8[carti240.UserId] then return false end
            if not carti2:GetPlayerByUserId(carti240.UserId) then return false end
        end
        local carti11 = { ... }
        local carti12, carti13 = pcall(function()
            return carti10(carti240, settingName, table.unpack(carti11))
        end)
        if carti12 then return carti13 else return false end
    end
end)

-- Hook FamilyHelper early
task.spawn(function()
    task.wait(0.1)
    local carti14 = require(carti3:WaitForChild('Fsys')).load('FamilyHelper')
    local carti15 = carti14.are_friends_family
    local carti16 = carti14.is_my_friend_or_family
    local carti17 = carti14.are_family_because_friends
    local carti18 = carti14.is_my_family_because_friend

    carti14.are_friends_family = function(player1, player2)
        if player1 and player2 and (carti8[player1.UserId] or carti8[player2.UserId]) then return false end
        return carti15(player1, player2)
    end
    carti14.is_my_friend_or_family = function(carti240)
        if carti240 and carti8[carti240.UserId] then return false end
        return carti16(carti240)
    end
    carti14.are_family_because_friends = function(player1, player2)
        if player1 and player2 and (carti8[player1.UserId] or carti8[player2.UserId]) then return false end
        return carti17(player1, player2)
    end
    carti14.is_my_family_because_friend = function(carti240)
        if carti240 and carti8[carti240.UserId] then return false end
        return carti18(carti240)
    end
end)

local carti19 = require(carti3:WaitForChild('Fsys'))
local carti20 = carti19.load
local carti21 = {
    UIManager = carti20('UIManager'),
    ClientData = carti20('ClientData'),
    TableUtil = carti20('TableUtil'),
    RouterClient = carti20('RouterClient'),
    InventoryDB = carti20('InventoryDB'),
    animationManager = carti20('AnimationManager'),
    ColorThemeManager = carti20('ColorThemeManager')
}
local carti22 = carti21.UIManager
local carti23 = carti21.ClientData
local carti24 = carti21.TableUtil
local carti25 = carti21.RouterClient
local carti26 = carti21.InventoryDB
local carti27 = carti21.ColorThemeManager
local carti28 = carti21.animationManager

if carti22.wait_for_initialization then
    carti22:wait_for_initialization()
else
    task.wait(2)
end

local carti29 = {
    TradeApp = carti22.apps.TradeApp,
    BackpackApp = carti22.apps.BackpackApp,
    DialogApp = carti22.apps.DialogApp,
    HintApp = carti22.apps.HintApp,
    SettingsApp = carti22.apps.SettingsApp,
    PlayerProfileApp = carti22.apps.PlayerProfileApp,
    TradeHistoryApp = carti22.apps.TradeHistoryApp,
    TradePreviewApp = carti22.apps.TradePreviewApp
}
local carti30 = carti29.TradeApp
local carti31 = carti29.BackpackApp
local carti32 = carti29.HintApp
local carti33 = carti29.DialogApp
local carti34 = carti29.TradeHistoryApp
local carti35 = carti29.PlayerProfileApp

local carti36 = carti2.LocalPlayer.PlayerGui.TradeApp.Frame.NegotiationFrame

local function carti37(FriendValue)
    carti36.FriendHighlight.Visible = FriendValue
    carti36.FriendBorder.Visible = FriendValue
    local carti38 = carti36.Header.PartnerFrame
    carti36.Header.PartnerFrame.NameLabel.FriendLabel.Visible = FriendValue
    local carti39 = carti27.lookup(FriendValue and 'background' or 'saturated')
    carti36.Header.PartnerFrame.ProfileIcon.ImageColor3 = carti39
    carti36.Header.PartnerFrame.NameLabel.TextColor3 = carti39
    carti36.Header.PartnerFrame.Icon.Visible = FriendValue
    carti36.Header.PartnerFrame.Icon.Image = 'rbxassetid://84667805159408'
end

local carti40 = carti20('DownloadClient')
local carti41 = {}

local function carti42(carti180)
    if carti41[carti180] then return carti41[carti180]:Clone() end
    local carti12, carti43 = pcall(function()
        local carti44 = carti40.promise_download_copy('Pets', carti180)
        if carti44 then return carti44:expect() end
        return nil
    end)
    if carti12 and carti43 then
        carti41[carti180] = carti43
        return carti43:Clone()
    else
        warn('Failed to download pet model for:', carti180)
        return nil
    end
end

if not carti30 then return end

-- ==================== PET VALUE SYSTEM ====================
local carti45 = {}
for category, items in pairs(carti26) do
    if category == "pets" then
        for id, petinfo in pairs(items) do
            carti45[id] = petinfo.name
        end
    end
end

-- Fallback pet values when API fails (from winadopt.me/elvebredd)
local carti46 = {
    ["Bat Dragon"] = {name = "Bat Dragon", ["rvalue - nopotion"] = 503, ["rvalue - fly&ride"] = 491, ["nvalue - fly&ride"] = 1280, ["mvalue - fly&ride"] = 3620},
    ["Shadow Dragon"] = {name = "Shadow Dragon", ["rvalue - nopotion"] = 473, ["rvalue - fly&ride"] = 331, ["nvalue - fly&ride"] = 777, ["mvalue - fly&ride"] = 1950},
    ["Giraffe"] = {name = "Giraffe", ["rvalue - nopotion"] = 230, ["rvalue - fly&ride"] = 220, ["nvalue - fly&ride"] = 536, ["mvalue - fly&ride"] = 1870},
    ["Frost Dragon"] = {name = "Frost Dragon", ["rvalue - nopotion"] = 181, ["rvalue - fly&ride"] = 170, ["nvalue - fly&ride"] = 361, ["mvalue - fly&ride"] = 1050},
    ["Owl"] = {name = "Owl", ["rvalue - nopotion"] = 144, ["rvalue - fly&ride"] = 142, ["nvalue - fly&ride"] = 389, ["mvalue - fly&ride"] = 1430},
    ["Parrot"] = {name = "Parrot", ["rvalue - nopotion"] = 112.5, ["rvalue - fly&ride"] = 111.5, ["nvalue - fly&ride"] = 242, ["mvalue - fly&ride"] = 840},
    ["Crow"] = {name = "Crow", ["rvalue - nopotion"] = 93, ["rvalue - fly&ride"] = 92.5, ["nvalue - fly&ride"] = 233, ["mvalue - fly&ride"] = 920},
    ["Evil Unicorn"] = {name = "Evil Unicorn", ["rvalue - nopotion"] = 80.5, ["rvalue - fly&ride"] = 80, ["nvalue - fly&ride"] = 174, ["mvalue - fly&ride"] = 670},
    ["African Wild Dog"] = {name = "African Wild Dog", ["rvalue - nopotion"] = 57, ["rvalue - fly&ride"] = 58, ["nvalue - fly&ride"] = 192, ["mvalue - fly&ride"] = 720},
    ["Hedgehog"] = {name = "Hedgehog", ["rvalue - nopotion"] = 53.5, ["rvalue - fly&ride"] = 54, ["nvalue - fly&ride"] = 182, ["mvalue - fly&ride"] = 705},
    ["Balloon Unicorn"] = {name = "Balloon Unicorn", ["rvalue - nopotion"] = 51.5, ["rvalue - fly&ride"] = 53, ["nvalue - fly&ride"] = 186, ["mvalue - fly&ride"] = 730},
    ["Diamond Butterfly"] = {name = "Diamond Butterfly", ["rvalue - nopotion"] = 51, ["rvalue - fly&ride"] = 49, ["nvalue - fly&ride"] = 160, ["mvalue - fly&ride"] = 565},
    ["Blazing Lion"] = {name = "Blazing Lion", ["rvalue - nopotion"] = 46, ["rvalue - fly&ride"] = 48, ["nvalue - fly&ride"] = 175, ["mvalue - fly&ride"] = 708},
    ["Orchid Butterfly"] = {name = "Orchid Butterfly", ["rvalue - nopotion"] = 44, ["rvalue - fly&ride"] = 45, ["nvalue - fly&ride"] = 183, ["mvalue - fly&ride"] = 735},
    ["Dalmatian"] = {name = "Dalmatian", ["rvalue - nopotion"] = 43.5, ["rvalue - fly&ride"] = 44, ["nvalue - fly&ride"] = 134, ["mvalue - fly&ride"] = 490},
    ["Arctic Reindeer"] = {name = "Arctic Reindeer", ["rvalue - nopotion"] = 39, ["rvalue - fly&ride"] = 38, ["nvalue - fly&ride"] = 80, ["mvalue - fly&ride"] = 302},
    ["Giant Panda"] = {name = "Giant Panda", ["rvalue - nopotion"] = 35, ["rvalue - fly&ride"] = 35, ["nvalue - fly&ride"] = 155, ["mvalue - fly&ride"] = 650},
    ["Cryptid"] = {name = "Cryptid", ["rvalue - nopotion"] = 26.5, ["rvalue - fly&ride"] = 28, ["nvalue - fly&ride"] = 97, ["mvalue - fly&ride"] = 330},
    ["Haetae"] = {name = "Haetae", ["rvalue - nopotion"] = 25.5, ["rvalue - fly&ride"] = 26, ["nvalue - fly&ride"] = 105, ["mvalue - fly&ride"] = 430},
    ["Cow"] = {name = "Cow", ["rvalue - nopotion"] = 23, ["rvalue - fly&ride"] = 25.5, ["nvalue - fly&ride"] = 58.5, ["mvalue - fly&ride"] = 212},
    ["Pelican"] = {name = "Pelican", ["rvalue - nopotion"] = 24, ["rvalue - fly&ride"] = 25, ["nvalue - fly&ride"] = 99, ["mvalue - fly&ride"] = 410},
    ["Strawberry Shortcake Bat Dragon"] = {name = "Strawberry Shortcake Bat Dragon", ["rvalue - nopotion"] = 22, ["rvalue - fly&ride"] = 23.5, ["nvalue - fly&ride"] = 69, ["mvalue - fly&ride"] = 217},
    ["Peppermint Penguin"] = {name = "Peppermint Penguin", ["rvalue - nopotion"] = 21.25, ["rvalue - fly&ride"] = 22.75, ["nvalue - fly&ride"] = 71, ["mvalue - fly&ride"] = 240},
    ["Turtle"] = {name = "Turtle", ["rvalue - nopotion"] = 20, ["rvalue - fly&ride"] = 22.5, ["nvalue - fly&ride"] = 48.5, ["mvalue - fly&ride"] = 128.5},
    ["Chocolate Chip Bat Dragon"] = {name = "Chocolate Chip Bat Dragon", ["rvalue - nopotion"] = 20, ["rvalue - fly&ride"] = 21.5, ["nvalue - fly&ride"] = 67, ["mvalue - fly&ride"] = 214},
    ["Monkey King"] = {name = "Monkey King", ["rvalue - nopotion"] = 21, ["rvalue - fly&ride"] = 20, ["nvalue - fly&ride"] = 69, ["mvalue - fly&ride"] = 275},
    ["Flamingo"] = {name = "Flamingo", ["rvalue - nopotion"] = 17.5, ["rvalue - fly&ride"] = 18, ["nvalue - fly&ride"] = 71, ["mvalue - fly&ride"] = 280},
    ["Mini Pig"] = {name = "Mini Pig", ["rvalue - nopotion"] = 17.5, ["rvalue - fly&ride"] = 18, ["nvalue - fly&ride"] = 72, ["mvalue - fly&ride"] = 295},
    ["Hot Doggo"] = {name = "Hot Doggo", ["rvalue - nopotion"] = 16, ["rvalue - fly&ride"] = 16.5, ["nvalue - fly&ride"] = 68, ["mvalue - fly&ride"] = 286},
    ["Kangaroo"] = {name = "Kangaroo", ["rvalue - nopotion"] = 15, ["rvalue - fly&ride"] = 16.5, ["nvalue - fly&ride"] = 36, ["mvalue - fly&ride"] = 101.5},
    ["Albino Monkey"] = {name = "Albino Monkey", ["rvalue - nopotion"] = 15.25, ["rvalue - fly&ride"] = 15.5, ["nvalue - fly&ride"] = 50, ["mvalue - fly&ride"] = 204},
    ["Elephant"] = {name = "Elephant", ["rvalue - nopotion"] = 15, ["rvalue - fly&ride"] = 15.5, ["nvalue - fly&ride"] = 47.5, ["mvalue - fly&ride"] = 195},
    ["Candyfloss Chick"] = {name = "Candyfloss Chick", ["rvalue - nopotion"] = 13.5, ["rvalue - fly&ride"] = 14.5, ["nvalue - fly&ride"] = 54.5, ["mvalue - fly&ride"] = 220},
    ["Crocodile"] = {name = "Crocodile", ["rvalue - nopotion"] = 11.75, ["rvalue - fly&ride"] = 12.75, ["nvalue - fly&ride"] = 43, ["mvalue - fly&ride"] = 172},
    ["Blue Dog"] = {name = "Blue Dog", ["rvalue - nopotion"] = 12, ["rvalue - fly&ride"] = 12, ["nvalue - fly&ride"] = 42, ["mvalue - fly&ride"] = 162},
    ["Sugar Glider"] = {name = "Sugar Glider", ["rvalue - nopotion"] = 11.5, ["rvalue - fly&ride"] = 12, ["nvalue - fly&ride"] = 49, ["mvalue - fly&ride"] = 207},
    ["Caterpillar"] = {name = "Caterpillar", ["rvalue - nopotion"] = 11.5, ["rvalue - fly&ride"] = 12, ["nvalue - fly&ride"] = 50, ["mvalue - fly&ride"] = 210},
    ["Lion"] = {name = "Lion", ["rvalue - nopotion"] = 11, ["rvalue - fly&ride"] = 12, ["nvalue - fly&ride"] = 40, ["mvalue - fly&ride"] = 167},
    ["Fairy Bat Dragon"] = {name = "Fairy Bat Dragon", ["rvalue - nopotion"] = 9.5, ["rvalue - fly&ride"] = 10.75, ["nvalue - fly&ride"] = 36, ["mvalue - fly&ride"] = 140},
    ["Winged Tiger"] = {name = "Winged Tiger", ["rvalue - nopotion"] = 7, ["rvalue - fly&ride"] = 7.5, ["nvalue - fly&ride"] = 33.5, ["mvalue - fly&ride"] = 146},
    ["Goat"] = {name = "Goat", ["rvalue - nopotion"] = 6.75, ["rvalue - fly&ride"] = 7.25, ["nvalue - fly&ride"] = 30, ["mvalue - fly&ride"] = 136},
    ["Lion Cub"] = {name = "Lion Cub", ["rvalue - nopotion"] = 6.5, ["rvalue - fly&ride"] = 7, ["nvalue - fly&ride"] = 29.5, ["mvalue - fly&ride"] = 131},
    ["Sheeeeep"] = {name = "Sheeeeep", ["rvalue - nopotion"] = 5.5, ["rvalue - fly&ride"] = 6, ["nvalue - fly&ride"] = 25, ["mvalue - fly&ride"] = 113},
    ["Shark Puppy"] = {name = "Shark Puppy", ["rvalue - nopotion"] = 5.5, ["rvalue - fly&ride"] = 6, ["nvalue - fly&ride"] = 27, ["mvalue - fly&ride"] = 117},
    ["Jellyfish"] = {name = "Jellyfish", ["rvalue - nopotion"] = 5.5, ["rvalue - fly&ride"] = 6, ["nvalue - fly&ride"] = 25, ["mvalue - fly&ride"] = 113},
    ["Meerkat"] = {name = "Meerkat", ["rvalue - nopotion"] = 5.25, ["rvalue - fly&ride"] = 5.75, ["nvalue - fly&ride"] = 26, ["mvalue - fly&ride"] = 114},
    ["Nessie"] = {name = "Nessie", ["rvalue - nopotion"] = 5, ["rvalue - fly&ride"] = 5.5, ["nvalue - fly&ride"] = 24, ["mvalue - fly&ride"] = 109},
    ["Pink Cat"] = {name = "Pink Cat", ["rvalue - nopotion"] = 4.75, ["rvalue - fly&ride"] = 5.25, ["nvalue - fly&ride"] = 20, ["mvalue - fly&ride"] = 86},
    ["Hare"] = {name = "Hare", ["rvalue - nopotion"] = 4.5, ["rvalue - fly&ride"] = 5, ["nvalue - fly&ride"] = 20.5, ["mvalue - fly&ride"] = 87},
    ["Zombie Buffalo"] = {name = "Zombie Buffalo", ["rvalue - nopotion"] = 4.25, ["rvalue - fly&ride"] = 4.75, ["nvalue - fly&ride"] = 21, ["mvalue - fly&ride"] = 94},
    ["Many Mackerel"] = {name = "Many Mackerel", ["rvalue - nopotion"] = 4.25, ["rvalue - fly&ride"] = 4.75, ["nvalue - fly&ride"] = 21, ["mvalue - fly&ride"] = 94},
    ["Honey Badger"] = {name = "Honey Badger", ["rvalue - nopotion"] = 3.5, ["rvalue - fly&ride"] = 4, ["nvalue - fly&ride"] = 17.5, ["mvalue - fly&ride"] = 75},
    ["Unicorn"] = {name = "Unicorn", ["rvalue - nopotion"] = 3, ["rvalue - fly&ride"] = 4, ["nvalue - fly&ride"] = 15, ["mvalue - fly&ride"] = 44},
    ["Happy Clam"] = {name = "Happy Clam", ["rvalue - nopotion"] = 3.25, ["rvalue - fly&ride"] = 3.75, ["nvalue - fly&ride"] = 16, ["mvalue - fly&ride"] = 68},
    ["Rhino"] = {name = "Rhino", ["rvalue - nopotion"] = 1.5, ["rvalue - fly&ride"] = 2, ["nvalue - fly&ride"] = 7, ["mvalue - fly&ride"] = 35},
    ["Ram"] = {name = "Ram", ["rvalue - nopotion"] = 1.5, ["rvalue - fly&ride"] = 2, ["nvalue - fly&ride"] = 10, ["mvalue - fly&ride"] = 43},
    ["Yeti"] = {name = "Yeti", ["rvalue - nopotion"] = 0.65, ["rvalue - fly&ride"] = 1.15, ["nvalue - fly&ride"] = 5.25, ["mvalue - fly&ride"] = 26},
    ["Frostbite Bear"] = {name = "Frostbite Bear", ["rvalue - nopotion"] = 7.75, ["rvalue - fly&ride"] = 8.25, ["nvalue - fly&ride"] = 37, ["mvalue - fly&ride"] = 160},
    ["Cat"] = {name = "Cat", ["rvalue - nopotion"] = 0.02, ["rvalue - fly&ride"] = 0.42, ["nvalue - fly&ride"] = 0.5, ["mvalue - fly&ride"] = 1.5},
    ["Dog"] = {name = "Dog", ["rvalue - nopotion"] = 0.02, ["rvalue - fly&ride"] = 0.42, ["nvalue - fly&ride"] = 0.5, ["mvalue - fly&ride"] = 1.5},
    ["Lunar Tiger"] = {name = "Lunar Tiger", ["rvalue - nopotion"] = 0.05, ["rvalue - fly&ride"] = 0.55, ["nvalue - fly&ride"] = 0.75, ["mvalue - fly&ride"] = 2.5},
}

local function carti47()
    local carti12, carti48 = pcall(function()
        return request({
            Url = "https://elvebredd.com/api/pets/get-latest",
            Method = "GET",
            Headers = {
                ["Accept"] = "*/*",
                ["User-Agent"] = "Mozilla/5.0"
            }
        })
    end)
    if carti12 and carti48 and carti48.Success then
        local carti49, carti50 = pcall(function()
            return carti7:JSONDecode(carti48.Body)
        end)
        if carti49 and carti50 and carti50.pets then
            local carti51, carti52 = pcall(function()
                return carti7:JSONDecode(carti50.pets)
            end)
            if carti51 and carti52 and next(carti52) then
                return carti52
            end
        end
    end
    -- Return fallback values if API fails
    return carti46
end

local carti53 = {}
local carti54 = carti47()
for carti60, carti57 in pairs(carti54) do
    if type(carti57) == "table" and carti57.name then
        carti53[carti57.name] = carti57
    end
end

local function carti55(petKind, petProps)
    local carti56 = carti45[petKind] or petKind
    local carti57 = carti53[carti56]
    if not carti57 then return 0 end
    local carti58
    if petProps.mega_neon then
        carti58 = "mvalue"
    elseif petProps.neon then
        carti58 = "nvalue"
    else
        carti58 = "rvalue"
    end
    local carti59 = ""
    if petProps.rideable and petProps.flyable then
        carti59 = " - fly&ride"
    elseif petProps.rideable then
        carti59 = " - ride"
    elseif petProps.flyable then
        carti59 = " - fly"
    else
        carti59 = " - nopotion"
    end
    local carti60 = carti58 .. carti59
    return carti57[carti60] or carti57[carti58] or 0
end

local function carti61(rawData)
    if not rawData then return nil end
    local carti62 = {
        pages = {},
        stickers = {},
        properties = rawData.properties or {}
    }
    if rawData.pages then
        for _, page in ipairs(rawData.pages) do
            local carti63 = page.page_index
            carti62.stickers[carti63] = page.stickers
            carti62.pages[carti63] = {}
            if page.widgets then
                for _, widget in ipairs(page.widgets) do
                    carti62.pages[carti63][widget.slot] = widget.data
                end
            end
        end
    end
    return carti62
end

local function carti64(carti306)
    local carti65 = {}
    if carti306 and carti306.pages then
        for carti63, page in pairs(carti306.pages) do
            for slotIndex, slotData in pairs(page) do
                if slotData.widget_kind == "collection" and slotData.widget_data and slotData.widget_data.items then
                    for _, carti57 in ipairs(slotData.widget_data.items) do
                        local carti66 = carti57.properties or {}
                        table.insert(carti65, {
                            kind = carti57.kind,
                            properties = carti66,
                            displayName = carti45[carti57.kind] or carti57.kind,
                            value = carti55(carti57.kind, carti66),
                            isMega = carti66.mega_neon or false,
                            isNeon = carti66.neon or false,
                            isFly = carti66.flyable or false,
                            isRide = carti66.rideable or false,
                        })
                    end
                end
            end
        end
    end
    return carti65
end

local function carti67(carti232)
    if carti232 >= 1000000 then
        return string.format("%.2fM", carti232 / 1000000)
    elseif carti232 >= 1000 then
        return string.format("%.1fK", carti232 / 1000)
    elseif carti232 >= 100 then
        return string.format("%.0f", carti232)
    else
        return string.format("%.1f", carti232)
    end
end

local carti68 = carti25.get("PlayerProfileAPI/FetchProfile")
-- ==================== END PET VALUE SYSTEM ====================

local carti69 = {
    PARTNER_NAME = 'endeavor3313',
    PARTNER_USER_ID = 987654321,
    AUTO_ACCEPT_DELAY = 0.2,
    AUTO_CONFIRM_DELAY = 0.3,
    SPECTATOR_COUNT = 4,
    SPECTATOR_VARIATION_MIN = -1,  -- Minimum variation from base count
    SPECTATOR_VARIATION_MAX = 2,   -- Maximum variation from base count
    AUTO_SPECTATE_ENABLED = false,
    AUTO_SPECTATE_INTERVAL = 1.5,
    AUTO_PARTNER = true,
    NEGOTIATION_LOCK = 5,
    CONFIRMATION_LOCK_PER_ITEM = 3,
    SHOW_TRADE_REQUEST = true,  -- Set to true to show trade request dialog first
    TRADE_REQUEST_DELAY = 0,
    ADD_PET_REQUEST_DELAY = 0.5,
    SPAWN_FAKE_PLAYER_WITH_RANDOM_PET = false,
    FAKE_PLAYER_ACCEPT_TRADE_REQUEST = 2,
    CHAT_MESSAGES = {
        'Tysm ! 💗💗', 'Thank you', 'Trusted TY ❤️', 'Can i play also', 'Can i spin this pet', 'Please respin 🥺',
        'Spin again plss 😔', 'Please guys follow', 'Pls both ill cry 😢', 'My dp neon giraffe', 'My dp is bat dragon',
        'Can i get mega pet', 'Change last 2 pets', 'Add or i will decline', 'Add more pets',
        'You are under 😂', 'Do mega exotics',
    },
    AUTO_CHAT_DELAY = 2,
    VERIFIED_FRIENDS = {
        'Agusmareborn', 'Kellyvault', 'J3llynoah', 'Rainbowriley321',
        'Bobazmalibu', 'H3llSANG3LX', 'Xcallmeholly', 'Niniko_201999',
    },
    SHOW_VERIFIED_FRIEND = false,
    FRIEND_PARTNER = true,
    REMOVE_PARTNER_PETS_ON_CONFIRM = false,
}

-- Store original spectator count for reset functionality
local carti70 = carti69.SPECTATOR_COUNT

-- Function to get randomized spectator count based on original value
local function carti71()
    local carti72 = math.random(carti69.SPECTATOR_VARIATION_MIN, carti69.SPECTATOR_VARIATION_MAX)
    local carti73 = carti70 + carti72
    return math.max(0, carti73) -- Ensure it doesn't go negative
end

local carti74 = {
    active = false,
    trade = nil,
    isAddingItem = false,
    partnerActionPending = false,
    originalFunctions = {},
    controlPanelOpen = false,
    tradeCompleting = false,
    scamWarningShown = true,
    originalDialogFunction = nil,
    blockedTradeRequests = {},
    tradeHistory = {},
    addedTradeIds = {},
    pendingTradeRequest = false,
    canShowTradeRequest = true,
    tradeRequestBlocked = false,
    removePartnerPetsOnConfirm = false,
    partnerPetsBeforeConfirm = {},
    isMockTradeDialog = false, -- NEW: Flag to track mock trade dialog
}

local carti75 = {
    activeFlags = { F = false, R = false, N = false, M = false },
    validPetNames = {},
    validPetNamesClean = {},
}

local carti76 = {
    'Shadow Dragon', 'Bat Dragon', 'Frost Dragon', 'Giraffe', 'Owl',
    'Parrot', 'Crow', 'Evil Unicorn'
}

local carti77 = {
    'Shadow Dragon', 'Bat Dragon', 'Frost Dragon', 'Giraffe', 'Owl', 'Parrot', 'Crow',
    'Evil Unicorn', 'Arctic Reindeer', 'Dalmatian', 'Turtle', 'Kangaroo', 'Peppermint Penguin', 
    'Strawberry Shortcake Bat Dragon', 'Chocolate Chip Bat Dragon', 'Cow', 'Mini Pig',
}

local carti78 = {
    'aliceroblox6166', 'DIVAHOLIC', 'iiicristianxx_o', 'Darcie_epic', 'banan_bartek1234',
    's18amg', 'Chicken_nuggitx23817', 'RmSbx_x', 'siqnnaz', 'Nidaanurr7', 'Kkiraly',
    'daisydoo_billy', 'youssefsalah135', 'aurivxs', 'princeplay', 'sofysofy986353',
    'heaseung008800112277'
}

local function carti79(carti341)
    for _, carti247 in ipairs(carti76) do
        if carti341 == carti247 then return true end
    end
    return false
end

local function carti80()
    return carti76[math.random(1, #carti76)]
end

local function carti81()
    for category_name, category_table in pairs(carti26) do
        if category_name == 'pets' then
            for id, item in pairs(category_table) do
                carti75.validPetNames[#carti75.validPetNames + 1] = item.name
                carti75.validPetNamesClean[#carti75.validPetNamesClean + 1] = item.name:lower():gsub('%s+', '')
            end
            break
        end
    end
end
carti81()

local function carti82(carti240)
    if not carti240 then return false end
    local carti12, carti83 = pcall(function()
        if carti30 and carti30._check_if_player_has_trade_license then
            return carti30:_check_if_player_has_trade_license(carti240)
        end
        local carti13 = carti25.get('TradeAPI/GetTradeLicenseStatus'):InvokeServer(carti240.UserId)
        return carti13 and carti13.has_license == true
    end)
    return carti12 and carti83 or true
end

local function carti84(username)
    for _, friendName in ipairs(carti69.VERIFIED_FRIENDS) do
        if friendName:lower() == username:lower() then return true end
    end
    return false
end

local function carti85()
    local carti86 = {
        '_get_local_trade_state', '_overwrite_local_trade_state', '_change_local_trade_state',
        '_get_my_offer', '_get_partner_offer', '_get_my_player', '_get_partner',
        '_get_current_trade_stage', '_on_accept_pressed', '_on_confirm_pressed',
        '_on_unaccept_pressed', '_decline_trade', '_add_item_to_my_offer',
        '_remove_item_from_my_offer', '_lock_trade_for_appropriate_time', '_get_lock_time',
        'refresh_all', '_evaluate_trade_fairness', '_show_scam_victim_warning', '_show_scam_perpetrator_warning',
    }
    for _, funcName in ipairs(carti86) do
        if carti30[funcName] then
            carti74.originalFunctions[funcName] = carti30[funcName]
        end
    end
    if carti34 then
        if carti34._get_trade_history then
            carti74.originalGetTradeHistory = carti34._get_trade_history
        end
        if carti34.report_scam then
            carti74.originalReportScam = carti34.report_scam
        end
    end
end

carti85()

local function carti87(carti240)
    local carti88 = carti240 and carti240.Name or carti69.PARTNER_NAME
    local carti89 = carti240 and carti240.DisplayName or carti69.PARTNER_NAME
    local carti90 = carti240 and carti240.UserId or carti69.PARTNER_USER_ID
    
    local carti91 = {
        Name = carti88,
        DisplayName = carti89,
        UserId = carti90,
        ClassName = 'Player',
        Character = nil,
        Team = nil,
        TeamColor = BrickColor.new('White'),
        Neutral = true,
        AccountAge = 365,
        MembershipType = Enum.MembershipType.None,
        CharacterAdded = Instance.new('BindableEvent'),
        CharacterRemoving = Instance.new('BindableEvent'),
    }
    
    return setmetatable(carti91, {
        __index = function(t, k)
            if k == 'Parent' then return carti2 end
            if k == 'IsA' then 
                return function(self, className) 
                    return className == 'Player' or className == 'Instance'
                end 
            end
            if k == 'GetAttribute' then
                return function(self, attr)
                    return nil
                end
            end
            if k == 'FindFirstChild' then
                return function(self, carti130)
                    return nil
                end
            end
            if k == 'WaitForChild' then
                return function(self, carti130, timeout)
                    return nil
                end
            end
            return rawget(t, k)
        end,
        __tostring = function() return carti88 end,
        __eq = function(a, carti390)
            if type(carti390) == 'table' then
                return rawget(a, 'UserId') == rawget(carti390, 'UserId')
            end
            return false
        end,
    })
end

local carti92 = carti87()

local function carti93(realPlayer)
    local carti94 = realPlayer and carti87(realPlayer) or carti92
    local carti83 = true
    if realPlayer then carti83 = carti82(realPlayer) end
    return {
        trade_id = 'MOCK_' .. tick(),
        sender = carti2.LocalPlayer,
        recipient = carti94,
        sender_offer = { items = {}, player_name = carti2.LocalPlayer.Name, negotiated = false, confirmed = false },
        recipient_offer = { items = {}, player_name = carti69.PARTNER_NAME, negotiated = false, confirmed = false },
        current_stage = 'negotiation',
        offer_version = 1,
        sender_has_trade_license = true,
        recipient_has_trade_license = carti83,
        busy_indicators = {},
        subscriber_count = carti69.SPECTATOR_COUNT,
    }
end

local function carti95(trade)
    return {
        trade_id = trade.trade_id,
        timestamp = os.time(),
        sender_user_id = carti2.LocalPlayer.UserId,
        sender_name = carti2.LocalPlayer.Name,
        sender_items = carti24.deep_copy(trade.sender_offer.items),
        recipient_user_id = trade.recipient.UserId,
        recipient_name = carti69.PARTNER_NAME,
        recipient_items = carti24.deep_copy(trade.recipient_offer.items),
        reported = false,
        reverted = nil,
    }
end

local function carti96(tradeRecord)
    if carti74.addedTradeIds[tradeRecord.trade_id] then return end
    carti74.addedTradeIds[tradeRecord.trade_id] = true
    table.insert(carti74.tradeHistory, tradeRecord)
end

local function carti97()
    if not carti34 then return end

    carti34._get_trade_history = function(self, useCache)
        local carti98 = carti74.originalGetTradeHistory(self, useCache)
        local carti99, carti100 = {}, {}
        if carti98 then
            for _, realTrade in ipairs(carti98) do
                if not carti100[realTrade.trade_id] then
                    table.insert(carti99, realTrade)
                    carti100[realTrade.trade_id] = true
                end
            end
        end
        for _, mockTrade in ipairs(carti74.tradeHistory) do
            if not carti100[mockTrade.trade_id] then
                table.insert(carti99, mockTrade)
                carti100[mockTrade.trade_id] = true
            end
        end
        self.cached_trade_history = carti99
        return carti99
    end

    carti34.report_scam = function(self, tradeData)
        if tradeData and string.find(tostring(tradeData.trade_id), 'MOCK_') then
            self.UIManager.set_app_visibility(self.ClassName, false)
            local carti101 = self.UIManager.apps.DialogApp:dialog({
                dialog_type = 'ReportScamDialog',
                suspect_name = carti69.PARTNER_NAME,
                placeholder_text = 'What happened? (Optional)',
                max_length = 500,
                use_utf8_length = true,
                left = 'Cancel',
                right = 'Report',
            })
            self.UIManager.set_app_visibility(self.ClassName, true)
            if carti101 == 'Report' then
                for _, record in ipairs(carti74.tradeHistory) do
                    if record.trade_id == tradeData.trade_id then
                        record.reported = true
                        break
                    end
                end
                self.UIManager.apps.DialogApp:dialog({ text = 'Report submitted for review.', button = 'Close', yields = false })
            end
            if self.instance.Frame.Visible then self:_refresh() else self:_clear_scrolling_frame() end
            return
        end
        return carti74.originalReportScam(self, tradeData)
    end
end

carti97()

local function carti102(args1)
    local carti103 = carti74.trade.busy_indicators
    local carti104 = carti30._get_partner().UserId
    carti103[tostring(carti104)] = args1
    carti30.partner_negotiation_offer_pane:display_busy(carti103[tostring(carti104)])
end

local function carti105(carti341, flags)
    if not carti74.active or not carti74.trade then return false, 'No active mock trade' end
    if carti74.trade.current_stage == 'confirmation' then return false, 'Cannot modify during confirmation' end
    if #carti74.trade.recipient_offer.items >= 18 then return end

    carti102({ ['picking'] = true })
    task.wait(carti69.ADD_PET_REQUEST_DELAY)

    for category_name, category_table in pairs(carti26) do
        if category_name == 'pets' then
            for id, item in pairs(category_table) do
                if item.name == carti341 then
                    local carti106 = {
                        category = 'pets',
                        kind = id,
                        unique = carti7:GenerateGUID(),
                        properties = { flyable = flags.F, rideable = flags.R, neon = flags.N, mega_neon = flags.M, age = 1 },
                    }
                    table.insert(carti74.trade.recipient_offer.items, carti106)
                    carti74.trade.sender_offer.negotiated = false
                    carti74.trade.recipient_offer.negotiated = false
                    if carti74.trade.current_stage == 'confirmation' then
                        carti74.trade.current_stage = 'negotiation'
                        carti74.trade.sender_offer.confirmed = false
                        carti74.trade.recipient_offer.confirmed = false
                    end
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    carti30:_overwrite_local_trade_state(carti74.trade)
                    if carti30._lock_trade_for_appropriate_time then carti30:_lock_trade_for_appropriate_time() end
                    if carti30._render_message_in_trade_chat then
                        carti30:_render_message_in_trade_chat(nil, string.format('%s added %s.', carti69.PARTNER_NAME, carti341), true)
                    end
                    carti102({ ['picking'] = false })
                    return true, 'Pet added successfully'
                end
            end
        end
    end
    return false, 'Pet not found'
end

local function carti107()
    if not carti74.active or not carti74.trade then return false, 'No active mock trade' end
    if carti74.trade.current_stage == 'confirmation' then return false, 'Cannot modify during confirmation' end
    local carti108 = carti74.trade.recipient_offer.items
    if #carti108 == 0 then return false, 'No items to remove' end

    local carti109 = table.remove(carti108)
    carti74.trade.sender_offer.negotiated = false
    carti74.trade.recipient_offer.negotiated = false
    if carti74.trade.current_stage == 'confirmation' then
        carti74.trade.current_stage = 'negotiation'
        carti74.trade.sender_offer.confirmed = false
        carti74.trade.recipient_offer.confirmed = false
    end
    carti74.trade.offer_version = carti74.trade.offer_version + 1
    carti30:_overwrite_local_trade_state(carti74.trade)
    if carti30._lock_trade_for_appropriate_time then carti30:_lock_trade_for_appropriate_time() end
    if carti30._render_message_in_trade_chat then
        local carti110 = 'item'
        if carti109.category == 'pets' then
            for _, category_table in pairs(carti26) do
                for id, item in pairs(category_table) do
                    if id == carti109.kind then carti110 = item.name break end
                end
            end
        end
        carti30:_render_message_in_trade_chat(nil, string.format('%s removed %s.', carti69.PARTNER_NAME, carti110), true)
    end
    return true, 'Pet removed successfully'
end

local function carti111()
    local carti112 = { 'FR', 'NFR' }
    local carti113 = carti112[math.random(1, #carti112)]
    local carti114 = { F = false, R = false, N = false, M = false }
    if carti113 == 'FR' then
        carti114.F, carti114.R = true, true
    elseif carti113 == 'NFR' then
        carti114.F, carti114.R, carti114.N = true, true, true
    end
    return carti114
end

local function carti115(carti114)
    local carti66 = {}
    if carti114.M then table.insert(carti66, 'Mega') end
    if carti114.N then table.insert(carti66, 'Neon') end
    if carti114.F then table.insert(carti66, 'Fly') end
    if carti114.R then table.insert(carti66, 'Ride') end
    if #carti66 > 0 then return ' (' .. table.concat(carti66, ' ') .. ')' end
    return ''
end

local function carti116(carti357)
    if not carti74.active or not carti74.trade then return false end
    if carti30 and carti30._render_message_in_trade_chat then
        carti30:_render_message_in_trade_chat(nil, string.format('%s: %s', carti69.PARTNER_NAME, carti357), true)
        return true
    end
    return false
end

local function carti117()
    if not carti74.active or not carti74.trade then return false end
    local carti108 = carti74.trade.recipient_offer.items
    if #carti108 == 0 then return false end
    carti74.partnerPetsBeforeConfirm = carti24.deep_copy(carti108)
    carti74.trade.recipient_offer.items = {}
    carti74.trade.offer_version = carti74.trade.offer_version + 1
    carti30:_overwrite_local_trade_state(carti74.trade)
    return true
end

local carti118

local function carti119()
    if not carti74.active or not carti74.trade or carti74.partnerActionPending then return end
    carti74.partnerActionPending = true

    while carti30.lock_countdown and carti30.lock_countdown.is_going and carti30.lock_countdown:is_going() do
        task.wait(0.1)
    end

    if carti74.trade.current_stage == 'negotiation' then
        task.wait(carti69.AUTO_ACCEPT_DELAY)
        if carti74.active and carti74.trade then
            carti74.trade.recipient_offer.negotiated = true
            if carti74.trade.sender_offer.negotiated then
                carti74.trade.current_stage = 'confirmation'
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
                if carti30._evaluate_trade_fairness then carti30:_evaluate_trade_fairness() end
                if carti30._lock_trade_for_appropriate_time then carti30:_lock_trade_for_appropriate_time() end
            else
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
            end
        end
    elseif carti74.trade.current_stage == 'confirmation' then
        task.wait(carti69.AUTO_CONFIRM_DELAY)
        if carti74.active and carti74.trade then
            carti74.trade.recipient_offer.confirmed = true
            carti74.trade.offer_version = carti74.trade.offer_version + 1
            carti30:_overwrite_local_trade_state(carti74.trade)
            if carti74.trade.sender_offer.confirmed and not carti74.tradeCompleting then
                carti74.tradeCompleting = true
                if carti30._set_confirmation_arrow_rotating then carti30:_set_confirmation_arrow_rotating(true) end
                task.wait(3)
                local carti120 = carti95(carti74.trade)
                carti96(carti120)
                local carti121 = {}
                for _, carti122 in ipairs(carti74.trade.sender_offer.items or {}) do
                    if carti122 and carti122.carti_hub_local_pet and carti122.unique then
                        carti121[carti122.unique] = true
                    end
                end
                pcall(function()
                    local carti123 = (getgenv and getgenv()) or _G
                    if carti123.CartiHubRemoveTransferredLocalPets then
                        carti123.CartiHubRemoveTransferredLocalPets(carti121)
                    end
                end)
                pcall(function()
                    local carti124 = (getgenv and getgenv()) or _G
                    if carti124.CartiHubAddReceivedFakeTradePets then
                        carti124.CartiHubAddReceivedFakeTradePets(carti74.trade.recipient_offer.items)
                    end
                end)
                carti74.active = false
                carti74.trade = nil
                carti74.tradeCompleting = false
                carti74.scamWarningShown = true
                carti74.canShowTradeRequest = true
                carti74.tradeRequestBlocked = false
                carti22.set_app_visibility('TradeApp', false)
                task.wait(0.1)
                carti118()
                if carti32 then carti32:hint({ text = 'The trade was successful!', length = 5, overridable = true }) end
                if carti34 and carti22.is_visible('TradeHistoryApp') then carti34:_refresh() end
            end
        end
    end
    carti74.partnerActionPending = false
end

local function carti121()
    carti30._get_local_trade_state = function(self)
        if carti74.active and carti74.trade then return carti24.deep_copy(carti74.trade) end
        return carti74.originalFunctions._get_local_trade_state(self)
    end

    carti30._overwrite_local_trade_state = function(self, newState)
        if carti74.active then
            if newState then
                carti74.trade = newState
                self.local_trade_state = newState
                if carti74.trade then carti74.trade.subscriber_count = carti69.SPECTATOR_COUNT end
                if self._on_local_trade_state_changed then self:_on_local_trade_state_changed(newState, newState) end
                if self.refresh_all then self:refresh_all() carti37(true) end
            else
                carti74.trade = nil
                carti74.active = false
                carti74.scamWarningShown = false
                carti74.canShowTradeRequest = true
                carti74.tradeRequestBlocked = false
                self.local_trade_state = nil
                carti118()
            end
        else
            return carti74.originalFunctions._overwrite_local_trade_state(self, newState)
        end
    end

    carti30._get_my_offer = function(self)
        local carti122 = self:_get_local_trade_state()
        if carti74.active and carti122 then
            if carti2.LocalPlayer == carti122.sender then return carti122.sender_offer, 'sender_offer' else return carti122.recipient_offer, 'recipient_offer' end
        end
        return carti74.originalFunctions._get_my_offer(self)
    end

    carti30._get_partner_offer = function(self)
        local carti122 = self:_get_local_trade_state()
        if carti74.active and carti122 then
            if carti2.LocalPlayer == carti122.sender then return carti122.recipient_offer, 'recipient_offer' else return carti122.sender_offer, 'sender_offer' end
        end
        return carti74.originalFunctions._get_partner_offer(self)
    end

    carti30._get_my_player = function(self)
        if carti74.active and carti74.trade then return carti2.LocalPlayer end
        return carti74.originalFunctions._get_my_player(self)
    end

    carti30._get_partner = function(self)
        if carti74.active and carti74.trade then return carti74.trade.recipient end
        return carti74.originalFunctions._get_partner(self)
    end

    carti30._get_current_trade_stage = function(self)
        if carti74.active and carti74.trade then return carti74.trade.current_stage end
        return carti74.originalFunctions._get_current_trade_stage(self)
    end

    carti30._change_local_trade_state = function(self, changes)
        if carti74.active then
            local function carti123(target, source)
                for k, carti152 in pairs(source) do
                    if type(carti152) == 'table' and target[k] and type(target[k]) == 'table' then carti123(target[k], carti152) else target[k] = carti152 end
                end
                return target
            end
            self:_overwrite_local_trade_state(carti123(self:_get_local_trade_state(), changes))
        else
            return carti74.originalFunctions._change_local_trade_state(self, changes)
        end
    end

    carti30._get_lock_time = function(self)
        if carti74.active and carti74.trade then
            if self:_get_current_trade_stage() == 'negotiation' then return carti69.NEGOTIATION_LOCK
            else return math.clamp(carti69.CONFIRMATION_LOCK_PER_ITEM * (#carti74.trade.sender_offer.items + #carti74.trade.recipient_offer.items), 5, 15) end
        end
        return carti74.originalFunctions._get_lock_time(self)
    end

    carti30._lock_trade_for_appropriate_time = function(self)
        if carti74.active then
            if self.lock_countdown then self.lock_countdown:stop() self.lock_countdown:set_duration(self:_get_lock_time()) self.lock_countdown:start() end
        else
            return carti74.originalFunctions._lock_trade_for_appropriate_time(self)
        end
    end

    carti30._add_item_to_my_offer = function(self)
        if carti74.active and carti74.trade then
            if carti74.isAddingItem then return end
            carti74.isAddingItem = true
            
            local carti124 = nil
            pcall(function()
                carti124 = carti31:pick_item({ 
                    keep_cached_scroll_positions_on_open = true, 
                    allow_callback = function() return true end 
                })
            end)
            
            if carti124 then
                local carti125 = false
                for _, item in ipairs(carti74.trade.sender_offer.items) do 
                    if item.unique == carti124.unique then 
                        carti125 = true 
                        break 
                    end 
                end
                if not carti125 then
                    table.insert(carti74.trade.sender_offer.items, carti124)
                    carti74.trade.sender_offer.negotiated = false
                    carti74.trade.recipient_offer.negotiated = false
                    if carti74.trade.current_stage == 'confirmation' then
                        carti74.trade.current_stage = 'negotiation'
                        carti74.trade.sender_offer.confirmed = false
                        carti74.trade.recipient_offer.confirmed = false
                    end
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    pcall(function() self:_overwrite_local_trade_state(carti74.trade) end)
                    pcall(function() self:_lock_trade_for_appropriate_time() end)
                    pcall(function()
                        if carti31 and carti31.set_item_unique_hidden then 
                            carti31:set_item_unique_hidden(carti124.unique, 'TradeApp') 
                        end
                    end)
                end
            end
            carti74.isAddingItem = false
        else
            return carti74.originalFunctions._add_item_to_my_offer(self)
        end
    end

    carti30._remove_item_from_my_offer = function(self, item)
        if carti74.active and carti74.trade then
            for i, carti152 in ipairs(carti74.trade.sender_offer.items) do
                if carti152.unique == item.unique then
                    table.remove(carti74.trade.sender_offer.items, i)
                    carti74.trade.sender_offer.negotiated = false
                    carti74.trade.recipient_offer.negotiated = false
                    if carti74.trade.current_stage == 'confirmation' then
                        carti74.trade.current_stage = 'negotiation'
                        carti74.trade.recipient_offer.negotiated = false
                        carti74.trade.sender_offer.confirmed = false
                        carti74.trade.recipient_offer.confirmed = false
                    end
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    self:_overwrite_local_trade_state(carti74.trade)
                    if self._lock_trade_for_appropriate_time then self:_lock_trade_for_appropriate_time() end
                    if carti31.reset_hidden_item_tag then carti31:reset_hidden_item_tag('TradeApp') end
                    break
                end
            end
        else
            return carti74.originalFunctions._remove_item_from_my_offer(self, item)
        end
    end

    carti30._on_accept_pressed = function(self)
        if carti74.active and carti74.trade then
            if carti74.trade.sender_offer.negotiated then
                carti74.trade.sender_offer.negotiated = false
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                self:_overwrite_local_trade_state(carti74.trade)
            else
                carti74.trade.sender_offer.negotiated = true
                if carti74.trade.recipient_offer.negotiated then
                    carti74.trade.current_stage = 'confirmation'
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    self:_overwrite_local_trade_state(carti74.trade)
                    if carti30._evaluate_trade_fairness then carti30:_evaluate_trade_fairness() end
                    if carti30._lock_trade_for_appropriate_time then carti30:_lock_trade_for_appropriate_time() end
                else
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    self:_overwrite_local_trade_state(carti74.trade)
                end
            end
            if carti69.AUTO_PARTNER and not carti74.trade.recipient_offer.negotiated and carti74.trade.sender_offer.negotiated then task.spawn(carti119) end
        else
            return carti74.originalFunctions._on_accept_pressed(self)
        end
    end

    carti30._on_confirm_pressed = function(self)
        if carti74.active and carti74.trade then
            if carti74.removePartnerPetsOnConfirm then carti117() end
            carti74.trade.sender_offer.confirmed = true
            carti74.trade.offer_version = carti74.trade.offer_version + 1
            self:_overwrite_local_trade_state(carti74.trade)
            if carti69.AUTO_PARTNER and not carti74.trade.recipient_offer.confirmed then task.spawn(carti119) end
        else
            return carti74.originalFunctions._on_confirm_pressed(self)
        end
    end

    carti30._on_unaccept_pressed = function(self)
        if carti74.active and carti74.trade then
            carti74.trade.sender_offer.negotiated = false
            if carti74.trade.current_stage == 'confirmation' then
                carti74.trade.current_stage = 'negotiation'
                carti74.trade.recipient_offer.negotiated = false
                carti74.trade.sender_offer.confirmed = false
                carti74.trade.recipient_offer.confirmed = false
            end
            carti74.trade.offer_version = carti74.trade.offer_version + 1
            self:_overwrite_local_trade_state(carti74.trade)
        else
            return carti74.originalFunctions._on_unaccept_pressed(self)
        end
    end

    carti30._decline_trade = function(self, silent)
        if carti74.active then
            if self.lock_countdown then self.lock_countdown:stop() end
            carti74.active = false
            carti74.trade = nil
            carti74.isAddingItem = false
            carti74.partnerActionPending = false
            carti74.tradeCompleting = false
            carti74.scamWarningShown = false
            carti74.canShowTradeRequest = true
            carti74.tradeRequestBlocked = false
            self:_overwrite_local_trade_state(nil)
            carti22.set_app_visibility('TradeApp', false)
            if carti31.reset_hidden_item_tag then carti31:reset_hidden_item_tag('TradeApp') end
            carti118()
        else
            return carti74.originalFunctions._decline_trade(self, silent)
        end
    end

    carti30._evaluate_trade_fairness = function(self)
        if carti74.active and carti74.trade and not carti74.scamWarningShown then
            local carti126 = #carti74.trade.sender_offer.items
            local carti108 = #carti74.trade.recipient_offer.items
            if carti126 > 0 and carti108 == 0 then
                carti74.scamWarningShown = true
                if carti33 then
                    carti33:dialog({ text = 'This trade seems unbalanced. Be careful - you could be getting scammed.', button = 'Next', yields = false })
                    carti33:dialog({ text = 'Any items lost to scams WILL NOT be returned. Be sure before you accept!', button = 'I understand', yields = false })
                end
            end
        else
            return carti74.originalFunctions._evaluate_trade_fairness(self)
        end
    end
end

carti121()

-- FIXED: Function to start mock trade directly without dialog issues
local function carti127()
    -- Only prevent if already in a trade
    if carti74.active then return end
    
    local carti12, carti128 = pcall(function()
        -- Reset all states first
        carti74.active = false
        carti74.trade = nil
        carti74.isAddingItem = false
        carti74.partnerActionPending = false
        carti74.tradeCompleting = false
        carti74.scamWarningShown = true
        carti74.tradeRequestBlocked = true
        carti74.blockedTradeRequests = {}
        carti74.pendingTradeRequest = false
        
        -- Create mock trade
        carti74.trade = carti93()
        
        -- Set active immediately
        carti74.active = true
        
        -- Close any existing trade UI
        pcall(function() carti22.set_app_visibility('TradeApp', false) end)
        task.wait(0.05)
        
        -- Overwrite trade state
        pcall(function() carti30:_overwrite_local_trade_state(carti74.trade) end)
        task.wait(0.05)
        
        -- Show trade UI
        pcall(function() carti22.set_app_visibility('TradeApp', true) end)
        pcall(function() carti37(true) end)
        
        -- Show intro message (public chat notice)
        pcall(function()
            if carti30._show_intro_message then
                carti30:_show_intro_message()
            end
        end)
        
        task.wait(0.05)
        pcall(function() 
            if carti30.refresh_all then 
                carti30:refresh_all() 
                carti37(true) 
            end 
        end)
    end)
    
    if not carti12 and carti32 then
        carti32:hint({ text = 'Error starting trade: ' .. tostring(carti128), length = 5, overridable = true })
    end
end

-- FIXED: showTradeRequest function with proper dialog handling
local function carti129()
    if carti74.pendingTradeRequest or carti74.active then
        return
    end
    carti74.pendingTradeRequest = true
    carti74.canShowTradeRequest = false
    task.wait(carti69.TRADE_REQUEST_DELAY)
    if not carti74.pendingTradeRequest or carti74.active then
        carti74.pendingTradeRequest = false
        carti74.canShowTradeRequest = true
        return
    end
    
    local carti130 = carti69.PARTNER_NAME
    local carti131 = { 
        ["text"] = carti130 .. " sent you a trade request", 
        ["left"] = "Decline", 
        ["right"] = "Accept", 
        ["header"] = {
            ["text"] = "Verified Friend",
            ["icon"] = "rbxassetid://84667805159408" 
        },
        ["tooltip_options"] = {
            ["force_display_post_trade_values"] = true
        },
        ["yields"] = true
    } 
    local carti132 = { 
        ["text"] = carti130 .. " sent you a trade request", 
        ["left"] = "Decline", 
        ["right"] = "Accept",
        ["yields"] = true
    } 
    
    -- Set flag so hookDialogApp doesn't interfere
    carti74.isMockTradeDialog = true
    
    local carti133
    local carti12, carti128 = pcall(function()
        -- Use original function directly to avoid hook interference
        if carti74.originalDialogFunction then
            if carti69.FRIEND_PARTNER then
                carti133 = carti74.originalDialogFunction(carti33, carti131)
            else
                carti133 = carti74.originalDialogFunction(carti33, carti132)
            end
        else
            if carti69.FRIEND_PARTNER then
                carti133 = carti33:dialog(carti131)
            else
                carti133 = carti33:dialog(carti132)
            end
        end
    end)
    
    carti74.isMockTradeDialog = false
    carti74.pendingTradeRequest = false
    
    if carti12 and carti133 and (carti133 == "Accept" or carti133 == "right") then
        carti127()
    else
        carti74.canShowTradeRequest = true
    end
end

local function carti134()
    local carti135 = carti25.get_event('TradeAPI/TradeRequestReceived')
    if carti135 then
        local carti136 = getconnections(carti135.OnClientEvent)
        for _, connection in pairs(carti136) do connection:Disable() end
        carti135.OnClientEvent:Connect(function(carti139)
            if carti74.active or carti74.tradeRequestBlocked then
                table.insert(carti74.blockedTradeRequests, { player = carti139, timestamp = tick() })
                return
            end
            for _, connection in pairs(carti136) do
                if connection.Function then connection.Function(carti139) end
            end
        end)
    end
end

-- FIXED: hookDialogApp to not interfere with mock trade dialogs
local function carti137()
    if not carti33 or not carti33.dialog then return end
    carti74.originalDialogFunction = carti33.dialog
    carti33.dialog = function(self, dialogData)
        -- Don't interfere with expired dialogs
        if dialogData and dialogData.text and string.find(dialogData.text, 'has expired!') then return 'Okay' end
        
        -- FIXED: Don't auto-decline if this is our mock trade dialog
        if carti74.isMockTradeDialog then
            return carti74.originalDialogFunction(self, dialogData)
        end
        
        -- FIXED: Also check for Verified Friend header to not auto-decline our dialogs
        if dialogData and dialogData.header and type(dialogData.header) == 'table' and dialogData.header.text == 'Verified Friend' then
            return carti74.originalDialogFunction(self, dialogData)
        end
        
        -- Auto-decline real trade requests while mock trade is active
        if dialogData and dialogData.handle == 'trade_request' then
            if carti74.pendingTradeRequest or carti74.active or carti74.tradeRequestBlocked then return 'Decline' end
        end
        
        return carti74.originalDialogFunction(self, dialogData)
    end
end

carti137()
carti134()

carti118 = function()
    if #carti74.blockedTradeRequests > 0 then
        task.wait(0.5)
        local carti138 = carti20('TradeExcluder')
        for _, request in ipairs(carti74.blockedTradeRequests) do
            local carti139 = request.player
            if carti138 and carti138.is_player_excluded(carti139) then
                carti25.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(carti139, false)
            else
                if carti33 and carti74.originalDialogFunction then
                    local carti48 = carti74.originalDialogFunction(carti33, {
                        text = string.format('%s sent you a trade request', carti139.Name),
                        left = 'Decline', right = 'Accept', handle = 'trade_request',
                    })
                    if carti48 == 'Accept' then
                        local carti140 = true
                        if carti30._confirm_player_if_suspicious then carti140 = carti30:_confirm_player_if_suspicious(carti139) end
                        if carti140 and not carti30:check_and_warn_if_trading_restricted() then carti30:show_scam_warning() end
                        carti25.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(carti139, carti140)
                    else
                        carti25.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(carti139, false)
                    end
                end
            end
        end
        carti74.blockedTradeRequests = {}
    end
end

-- Hook partner profile button to show mock partner's profile
task.spawn(function()
    task.wait(1) -- Wait for TradeApp to fully initialize
    pcall(function()
        if carti30 and carti30.partner_profile_button then
            local carti141 = carti30.partner_profile_button
            if carti141.callbacks and carti141.callbacks.mouse_button1_click then
                local carti142 = carti141.callbacks.mouse_button1_click
                carti141.callbacks.mouse_button1_click = function()
                    if carti74.active and carti74.trade and carti74.trade.recipient then
                        if carti35 and carti35.open_player_profile_for_user_id then 
                            carti35:open_player_profile_for_user_id(carti74.trade.recipient.UserId) 
                        end
                    else
                        if carti142 then carti142() end
                    end
                end
            end
        end
    end)
end)

function updatePartnerFromUsername(username)
    local carti12, carti143 = pcall(function() return carti2:GetUserIdFromNameAsync(username) end)
    if carti12 and carti143 then
        carti69.PARTNER_USER_ID = carti143
        carti69.PARTNER_NAME = username
        carti92 = carti87()
        return true
    else
        carti69.PARTNER_NAME = username
        carti92 = carti87()
        return false
    end
end

local function carti144(carti181, carti180)
    local carti145 = carti20('new:PetRigs')
    local carti146 = carti181:FindFirstChild('PetModel') or carti181
    local carti147 = carti26.pets[carti180]
    if not carti147 or not carti147.neon_parts then return end
    for neonPart, configuration in pairs(carti147.neon_parts) do
        local carti148 = carti145.get(carti146).get_geo_part(carti146, neonPart)
        if carti148 then
            carti148.Material = Enum.Material.Neon
            local carti149 = configuration.Color
            if carti149 then
                local carti150, carti151, carti152 = carti149:ToHSV()
                carti148.Color = Color3.fromHSV(carti150, math.min(carti151 * 1.3, 1), math.min(carti152 * 1.4, 1))
            else
                carti148.Color = Color3.fromRGB(170, 0, 255)
            end
        end
    end
end

local function carti153(carti181, carti180)
    local carti145 = carti20('new:PetRigs')
    local carti146 = carti181:FindFirstChild('PetModel') or carti181
    local carti147 = carti26.pets[carti180]
    if not carti147 or not carti147.neon_parts then return end
    for neonPart, configuration in pairs(carti147.neon_parts) do
        local carti148 = carti145.get(carti146).get_geo_part(carti146, neonPart)
        if carti148 then
            carti148.Material = Enum.Material.Neon
            if configuration.Color then carti148.Color = configuration.Color end
        end
    end
end

local carti154 = {
    currentTab = 'Control',
    tabFrames = {},
    tabButtons = {},
    activeTabPulseTween = nil,
    hasShownAnimation = {},
    playerListButtons = {},
    userListButtons = {},
    petListButtons = {},
    noclipEnabled = true,
    selectedPlayers = {},
    selectionMode = false,
    pulsationTweens = {},
    richestData = {},
    expandedPlayers = {},
    keybinds = {
        selectPartner = Enum.KeyCode.P,
        addRandomItem = Enum.KeyCode.R,
        startTrade = Enum.KeyCode.T,
        blockPlayer = Enum.KeyCode.B
    },
    waitingForKeybind = nil
}
local carti155 = carti154.tabFrames
local carti156 = carti154.tabButtons
local carti157 = carti154.richestData
local carti158 = carti154.expandedPlayers

local carti159 = {}
local carti160 = {}

local function carti161(carti60, action)
    local carti162 = carti23.get(carti60)
    local carti163 = table.clone(carti162)
    carti23.predict(carti60, action(carti163))
end

local carti164 = { running = false, checkInterval = 0.3, animationTracks = {} }

function carti164:Start()
    if self.running then return end
    self.running = true
    task.spawn(function()
        while self.running do
            task.wait(self.checkInterval)
            for _, carti147 in ipairs(carti160) do
                if carti147 and carti147.model and carti147.model.Parent then
                    pcall(function()
                        local carti165 = carti147.character
                        if carti165 and carti165.Parent then
                            local carti166 = carti165:FindFirstChild('Humanoid')
                            if carti166 then
                                local carti167 = carti166:FindFirstChild('Animator')
                                if carti167 then
                                    local carti168 = false
                                    for _, carti190 in ipairs(carti167:GetPlayingAnimationTracks()) do
                                        if carti190.Animation.AnimationId:find('PlayerRidingPet') or carti190.Animation.AnimationId:find('507766666') then carti168 = true break end
                                    end
                                    if not carti168 and carti147.hasRidingPet then
                                        if not carti147.ridingAnim or not carti147.ridingAnim.IsPlaying then
                                            if carti147.ridingAnim then carti147.ridingAnim:Stop() end
                                            carti147.ridingAnim = carti167:LoadAnimation(carti28.get_track('PlayerRidingPet'))
                                            carti147.ridingAnim.Looped = true
                                            carti147.ridingAnim:Play()
                                            carti166.Sit = true
                                        end
                                    end
                                end
                            end
                        end
                        if carti147.wrapper.mega_neon then carti144(carti147.model, carti147.wrapper.pet_id)
                        elseif carti147.wrapper.neon then carti153(carti147.model, carti147.wrapper.pet_id) end
                    end)
                end
            end
        end
    end)
end

function carti164:Stop()
    self.running = false
    for _, carti147 in ipairs(carti160) do
        if carti147.ridingAnim then carti147.ridingAnim:Stop() end
    end
end

function carti164:AddPet(carti147)
    table.insert(carti160, carti147)
    if not self.running then self:Start() end
end

local function carti169(fakeCharacter, carti88, partnerId)
    return setmetatable({
        Name = carti88, DisplayName = carti88, UserId = partnerId, Character = fakeCharacter,
    }, {
        __index = function(t, k)
            if k == 'Parent' then return carti2 end
            if k == 'IsA' then return function(self, className) return className == 'Player' end end
            if k == 'GetChildren' then return function() return {} end end
            return rawget(t, k)
        end,
        __tostring = function() return carti88 end
    })
end

function OpenProfile(Id)
    carti22.apps.PlayerProfileApp:open_player_profile_for_user_id(Id)
end

task.spawn(function()
    task.wait(0.1)
    local carti170 = carti20('InteractionsEngine')
    local carti171 = carti170.register
    carti170.register = function(self, interactionData)
        if interactionData and interactionData.part then
            local carti172 = interactionData.part
            while carti172 do
                if carti172:GetAttribute('IsFakePet') == true and carti172.Parent then return end
                carti172 = carti172.Parent
            end
        end
        return carti171(self, interactionData)
    end
end)

local carti173 = 'regular'

function CreateFakePlayerCharacterFromPARTNER_NAME(partner_name, partner_id, pros_fake_pet, pet_flags)
    local carti174, carti175 = 3, 0

    local function carti176()
        carti175 = carti175 + 1
        carti8[partner_id] = true
        _G.fakePlayerIds[partner_id] = true

        local carti177 = Instance.new('Folder')
        carti177.Name = 'fake_folder_' .. partner_name
        carti177.Parent = workspace

        local carti165 = carti2:CreateHumanoidModelFromUserId(partner_id)
        local carti178 = carti2.LocalPlayer.Character
        carti165:SetPrimaryPartCFrame(carti178.HumanoidRootPart.CFrame * CFrame.new(math.random(-10, 10), 0, math.random(-10, 10)))
        local carti166 = carti165:WaitForChild('Humanoid')
        carti166.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        carti166.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        carti166.HealthDisplayDistance = 0
        carti165.Parent = carti177

        if pros_fake_pet ~= nil then
            local carti179 = false
            local carti12, carti128 = pcall(function()
                local carti180 = pros_fake_pet.kind
                local carti181 = carti42(carti180)
                if not carti181 then warn('Could not get pet model for kind:', carti180) return end
                carti181 = carti181:Clone()
                carti181:SetAttribute('IsFakePet', true)
                if pet_flags then
                    if pet_flags.M then carti144(carti181, carti180)
                    elseif pet_flags.N then carti153(carti181, carti180) end
                end
                carti181.Parent = carti177
                carti181:SetPrimaryPartCFrame(carti165.HumanoidRootPart.CFrame)
                carti181:ScaleTo(2)
                for _, part in ipairs(carti181:GetDescendants()) do
                    if part:IsA('BasePart') then part:SetAttribute('IsFakePet', true) end
                end
                local carti182 = carti181:FindFirstChild('RidePosition', true)
                if carti182 then
                    local carti183 = Instance.new('Attachment')
                    carti183.Parent = carti182
                    carti183.Position = Vector3.new(0, 1.237, 0)
                    carti183.Name = 'SourceAttachment'
                    local carti184 = Instance.new('RigidConstraint')
                    carti184.Name = 'StateConnection'
                    carti184.Attachment0 = carti183
                    carti184.Attachment1 = carti165.PrimaryPart.RootAttachment
                    carti184.Parent = carti165
                end
                local carti185 = carti165.Humanoid.Animator:LoadAnimation(carti28.get_track('PlayerRidingPet'))
                carti185.Looped = true
                carti185:Play()
                carti165.Humanoid.Sit = true
                for _, descendant in pairs(carti165:GetDescendants()) do
                    if descendant:IsA('BasePart') and descendant.Massless == false then
                        descendant.Massless = true
                        descendant:SetAttribute('HaveMass', true)
                    end
                end
                local carti186 = carti169(carti165, partner_name, partner_id)
                local carti187 = {
                    char = carti181, mega_neon = pet_flags and pet_flags.M or false, neon = pet_flags and pet_flags.N or false,
                    player = carti186, entity_controller = carti186, controller = carti186, rp_name = '',
                    pet_trick_level = math.random(1, 5), pet_unique = carti7:GenerateGUID(false), pet_id = carti180,
                    location = { full_destination_id = 'housing', destination_id = 'housing', house_owner = carti186 },
                    pet_progression = { age = math.random(1, 900000), percentage = math.random(0.01, 0.99) },
                    are_colors_sealed = false, is_pet = true,
                }
                local carti188 = { char = carti181, player = carti186, store_key = 'pet_state_managers', is_sitting = false, chars_connected_to_me = {}, states = { { id = 'PetBeingRidden' } } }
                carti161('pet_char_wrappers', function(petWrappers)
                    carti187.unique = #petWrappers + 1
                    carti187.index = #petWrappers + 1
                    petWrappers[#petWrappers + 1] = carti187
                    return petWrappers
                end)
                carti161('pet_state_managers', function(petStates)
                    petStates[#petStates + 1] = carti188
                    return petStates
                end)
                table.insert(carti160, {
                    wrapper = carti187, state = carti188, model = carti181, character = carti165,
                    hasRidingPet = true, owner = carti186, ridingAnim = carti185, folder = carti177,
                })
                if not carti164.running then carti164:Start() end
                carti179 = true
                print('✓ Registered fake pet with native game systems:', carti180, pet_flags and (pet_flags.M and 'Mega Neon' or pet_flags.N and 'Neon' or 'Regular') or 'Regular')
            end)
            if not carti12 or not carti179 then
                warn('Error creating fake pet (Attempt ' .. retryCount .. '/' .. maxRetries .. '):', carti128)
                carti177:Destroy()
                for i, folder in ipairs(carti159) do if folder == carti177 then table.remove(carti159, i) break end end
                if carti175 < carti174 then
                    print('🔄 Retrying fake character creation for ' .. partner_name .. '...')
                    task.wait(0.5)
                    return carti176()
                else
                    warn('❌ Failed to create fake character after ' .. maxRetries .. ' attempts')
                    return false
                end
            end
        else
            local carti189 = Instance.new('Animation')
            carti189.AnimationId = 'http://www.roblox.com/asset/?id=507766666'
            local carti190 = carti165.Humanoid.Animator:LoadAnimation(carti189)
            carti190.Looped = true
            carti190:Play()
        end

        pcall(function() carti22.apps.PlayerNameApp:add_npc_id(carti165, partner_name) end)

        local carti191 = carti165:FindFirstChild('HumanoidRootPart')
        if carti191 then
            local carti170 = carti20('InteractionsEngine')
            local carti192 = function() end
            pcall(function()
                carti170:register({
                    text = partner_name, part = carti191,
                    on_selected = {
                        { text = 'Profile', on_selected = function() pcall(OpenProfile, partner_id) end },
                        { text = 'Trade', on_selected = function()
                            pcall(function()
                                task.spawn(function()
                                    pcall(function()
                                        if carti32 then carti32:hint({ text = 'Trade request sent to ' .. partner_name, length = 3, overridable = true }) end
                                    end)
                                end)
                                task.wait(carti69.FAKE_PLAYER_ACCEPT_TRADE_REQUEST)
                                partnerBox.Text = partner_name
                                updatePartnerFromUsername(partner_name)
                                carti127()
                            end)
                        end },
                        { text = 'Give Item...', on_selected = carti192 },
                        { text = 'Mute', on_selected = carti192 },
                    },
                })
            end)
        end

        table.insert(carti159, carti177)
        carti177:SetAttribute('IsFakePlayer', true)
        carti177:SetAttribute('PartnerName', partner_name)
        carti177:SetAttribute('PartnerId', partner_id)
        return true
    end

    return carti176()
end

function GetKindPet(carti130)
    for k, carti152 in pairs(carti26.pets) do
        if carti152['name']:lower() == carti130:lower() then return k end
    end
end

local function carti193(carti165)
    if not carti165 then return end
    for _, part in ipairs(carti165:GetDescendants()) do
        if part:IsA('BasePart') then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            pcall(function() part.CollisionGroup = 'Noclip' end)
        end
    end
    carti165.DescendantAdded:Connect(function(descendant)
        if descendant:IsA('BasePart') then
            task.wait()
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            pcall(function() descendant.CollisionGroup = 'Noclip' end)
        end
    end)
end

local function carti194()
    for _, folder in ipairs(carti159) do
        if folder and folder.Parent then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA('Model') then carti193(child) end
            end
        end
    end
end

local function carti195()
    for _, carti147 in ipairs(carti160) do
        if carti147 and carti147.model and carti147.model.Parent then carti193(carti147.model) end
    end
end

-- ORIGINAL BlockPlayer function
function BlockPlayer(Selected)
    pcall(function()
        setthreadidentity(8)
    end)
    game:GetService('StarterGui'):SetCore('PromptBlockPlayer', Selected)
    repeat
        game:GetService('RunService').Heartbeat:Wait()
    until game:GetService('CoreGui'):FindFirstChild('BlockingModalScreen')
    game:GetService('CoreGui').BlockingModalScreen.BlockingModalContainer.BlockingModalContainerWrapper.BlockingModal.BackgroundTransparency = 1
    game:GetService('CoreGui').BlockingModalScreen.BlockingModalContainer.BlockingModalContainerWrapper.BackgroundTransparency = 1
    game:GetService('CoreGui').BlockingModalScreen.BlockingModalContainer.BackgroundTransparency = 1
    game:GetService('CoreGui').BlockingModalScreen.BlockingModalContainer.BlockingModalContainerWrapper.BlockingModal.AlertModal.Position = UDim2.new(0.00800000038, -110, 0.5, 0)
    local carti196 = function(path)
        game:GetService('GuiService').SelectedObject = path
        task.wait()
        if game:GetService('GuiService').SelectedObject == path then
            game:GetService('VirtualInputManager'):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            game:GetService('VirtualInputManager'):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            task.wait()
        end
        game:GetService('GuiService').SelectedObject = nil
    end
    carti196(game:GetService('CoreGui').BlockingModalScreen.BlockingModalContainer.BlockingModalContainerWrapper.BlockingModal.AlertModal.AlertContents.Footer.Buttons['3'])
    pcall(function()
        setthreadidentity(2)
    end)
end

-- FIXED: Send trade request to real player using the correct API
local function carti197(carti240)
    if not carti240 then return end
    local carti198 = carti2:FindFirstChild(carti240.Name)
    if carti198 then
        pcall(function()
            -- Try multiple methods to send trade request
            local carti12 = false
            
            -- Method 1: Use RouterClient
            if not carti12 then
                local carti199 = pcall(function()
                    local carti200 = carti25.get('TradeAPI/SendTradeRequest')
                    if carti200 then
                        if carti200.FireServer then
                            carti200:FireServer(carti198)
                            carti12 = true
                        elseif carti200.InvokeServer then
                            carti200:InvokeServer(carti198)
                            carti12 = true
                        end
                    end
                end)
            end
            
            -- Method 2: Try direct remote
            if not carti12 then
                local carti201 = pcall(function()
                    local carti202 = carti3:FindFirstChild('Remotes') and carti3.Remotes:FindFirstChild('TradeAPI') and carti3.Remotes.TradeAPI:FindFirstChild('SendTradeRequest')
                    if carti202 then
                        carti202:FireServer(carti198)
                        carti12 = true
                    end
                end)
            end
            
            -- Method 3: Use InteractionsEngine
            if not carti12 then
                local carti203 = pcall(function()
                    local carti170 = carti20('InteractionsEngine')
                    if carti170 then
                        carti170:send_trade_request(carti198)
                        carti12 = true
                    end
                end)
            end
            
            if carti12 and carti32 then
                carti32:hint({ text = 'Trade request sent to ' .. player.Name, length = 3, overridable = true })
            elseif carti32 then
                carti32:hint({ text = 'Could not send trade request to ' .. player.Name, length = 3, overridable = true })
            end
        end)
    else
        if carti32 then
            carti32:hint({ text = 'Player ' .. player.Name .. ' not found in server', length = 3, overridable = true })
        end
    end
end

-- ==================== AUTO SPECTATE WITH RANDOM VARIATION ====================
local carti204 = nil

local function carti205()
    if carti204 then return end
    
    carti204 = task.spawn(function()
        while carti69.AUTO_SPECTATE_ENABLED do
            task.wait(carti69.AUTO_SPECTATE_INTERVAL)
            
            if carti74.active and carti74.trade then
                -- Get a new random spectator count
                local carti73 = carti71()
                carti69.SPECTATOR_COUNT = carti73
                
                -- Update the spectator box text if it exists
                if spectatorBox then
                    spectatorBox.Text = tostring(carti73)
                end
                
                -- Update the trade state
                carti74.trade.subscriber_count = carti73
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
            end
        end
        carti204 = nil
    end)
end

local function carti206()
    carti69.AUTO_SPECTATE_ENABLED = false
end

-- ==================== GUI CREATION ====================

for _, carti206 in ipairs(carti2.LocalPlayer:WaitForChild('PlayerGui'):GetChildren()) do
    if carti206.Name == 'MockTradeControl' then
        carti206:Destroy()
    end
end

local carti207 = Instance.new('ScreenGui')
carti207.Name = 'MockTradeControl'
carti207.ResetOnSpawn = false
carti207.DisplayOrder = 10
carti207.Enabled = true
carti207.Parent = carti2.LocalPlayer:WaitForChild('PlayerGui')

local carti208 = Instance.new('Frame')
carti208.Size = UDim2.new(0, 220, 0, 750)
carti208.Position = UDim2.new(0, 10, 0, 10)
carti208.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
carti208.BorderSizePixel = 0
carti208.ZIndex = 1
carti208.Active = true
carti208.Parent = carti207

local carti209 = Instance.new('UICorner')
carti209.CornerRadius = UDim.new(0, 6)
carti209.Parent = carti208

local carti210 = Instance.new('UIStroke')
carti210.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti210.Color = Color3.fromRGB(100, 100, 255)
carti210.Thickness = 1.5
carti210.Parent = carti208

local carti211 = Instance.new('TextLabel')
carti211.Size = UDim2.new(1, 0, 0, 22)
carti211.Position = UDim2.new(0, 0, 0, 2)
carti211.BackgroundTransparency = 1
carti211.Text = 't.me/cartiscripts'
carti211.Font = Enum.Font.FredokaOne
carti211.TextSize = 12
carti211.TextColor3 = Color3.fromRGB(240, 240, 255)
carti211.Parent = carti208

local carti212 = Instance.new('UIStroke')
carti212.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
carti212.Color = Color3.new(0, 0, 0)
carti212.Thickness = 0.8
carti212.Parent = carti211

local carti213 = Instance.new('Frame')
carti213.Size = UDim2.new(0.94, 0, 0, 54)
carti213.Position = UDim2.new(0.03, 0, 0, 26)
carti213.BackgroundTransparency = 1
carti213.Parent = carti208

function setActiveTab(tabName)
    if carti154.currentTab == tabName then return end
    if carti154.activeTabPulseTween then carti154.activeTabPulseTween:Cancel() carti154.activeTabPulseTween = nil end
    carti154.currentTab = tabName

    for carti130, carti162 in pairs(carti156) do
        local carti214 = carti130 == tabName
        carti6:Create(carti162.button, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = carti214 and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(40, 40, 50)
        }):Play()
        local carti215 = carti214 and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(80, 80, 80)
        carti6:Create(carti162.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Color = carti215, Thickness = carti214 and 1.2 or 0.8
        }):Play()
        if carti214 then
            carti154.activeTabPulseTween = carti6:Create(carti162.stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Color = carti215:Lerp(Color3.fromRGB(255, 255, 255), 0.25), Thickness = 1.5
            })
            carti154.activeTabPulseTween:Play()
        end
    end

    for carti130, frame in pairs(carti155) do frame.Visible = carti130 == tabName end
end

local carti216 = { 'Control', 'Players', 'Pets', 'Users', 'Sets', 'Inventory' }
local carti217 = { '🎮', '👥', '🐾', '🧑', '⚙️' }

for i, tabName in ipairs(carti216) do
    local carti218 = Instance.new('TextButton')
    carti218.Size = UDim2.new(1 / 3 - 0.02, 0, 0, 24)
    carti218.Position = UDim2.new(((i - 1) % 3) * (1 / 3), 0, 0, math.floor((i - 1) / 3) * 28)
    carti218.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(40, 40, 50)
    carti218.BackgroundTransparency = 0.2
    carti218.Text = (carti217[i] or utf8.char(0x1F4D6)) .. ' ' .. tabName
    carti218.Font = Enum.Font.FredokaOne
    carti218.TextSize = 10
    carti218.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti218.Parent = carti213

    local carti219 = Instance.new('UICorner')
    carti219.CornerRadius = UDim.new(0, 4)
    carti219.Parent = carti218

    local carti220 = Instance.new('UIStroke')
    carti220.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti220.Color = i == 1 and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(80, 80, 80)
    carti220.Thickness = i == 1 and 1.2 or 0.8
    carti220.Transparency = 0.3
    carti220.Parent = carti218

    carti156[tabName] = { button = carti218, stroke = carti220 }

    -- Make Control tab a ScrollingFrame for better visibility
    local carti221
    if tabName == 'Control' then
        carti221 = Instance.new('ScrollingFrame')
        carti221.Size = UDim2.new(0.9, 0, 0, 644)
        carti221.Position = UDim2.new(0.05, 0, 0, 82)
        carti221.BackgroundTransparency = 1
        carti221.BorderSizePixel = 0
        carti221.ScrollBarThickness = 4
        carti221.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        carti221.ScrollBarImageTransparency = 0.5
        carti221.CanvasSize = UDim2.new(0, 0, 0, 850)
        carti221.Visible = i == 1
        carti221.Parent = carti208
    else
        carti221 = Instance.new('Frame')
        carti221.Size = UDim2.new(0.9, 0, 0, 644)
        carti221.Position = UDim2.new(0.05, 0, 0, 82)
        carti221.BackgroundTransparency = 1
        carti221.Visible = i == 1
        carti221.Parent = carti208
    end

    carti155[tabName] = carti221

    carti218.MouseButton1Click:Connect(function() setActiveTab(tabName) end)
end

-- ==================== CONTROL TAB ====================
local carti222 = carti155['Control']

local carti223 = Instance.new('UIListLayout')
carti223.SortOrder = Enum.SortOrder.LayoutOrder
carti223.Padding = UDim.new(0, 4)
carti223.Parent = carti222

local carti224 = Instance.new('UIPadding')
carti224.PaddingTop = UDim.new(0, 4)
carti224.PaddingBottom = UDim.new(0, 4)
carti224.PaddingLeft = UDim.new(0, 4)
carti224.PaddingRight = UDim.new(0, 4)
carti224.Parent = carti222

function createSettingRow(labelText, defaultValue, parent)
    local carti225 = Instance.new('TextLabel')
    carti225.Size = UDim2.new(1, 0, 0, 14)
    carti225.BackgroundTransparency = 1
    carti225.Text = labelText
    carti225.Font = Enum.Font.SourceSansSemibold
    carti225.TextSize = 10
    carti225.TextColor3 = Color3.fromRGB(180, 180, 180)
    carti225.TextXAlignment = Enum.TextXAlignment.Left
    carti225.Parent = parent

    local carti226 = Instance.new('TextBox')
    carti226.Size = UDim2.new(1, 0, 0, 24)
    carti226.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    carti226.BackgroundTransparency = 0.2
    carti226.Text = tostring(defaultValue)
    carti226.Font = Enum.Font.SourceSans
    carti226.TextSize = 12
    carti226.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti226.ClearTextOnFocus = false
    carti226.TextXAlignment = Enum.TextXAlignment.Center
    carti226.Parent = parent

    local carti227 = Instance.new('UICorner')
    carti227.CornerRadius = UDim.new(0, 4)
    carti227.Parent = carti226

    local carti228 = Instance.new('UIStroke')
    carti228.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti228.Color = Color3.fromRGB(100, 100, 100)
    carti228.Thickness = 0.8
    carti228.Transparency = 0.5
    carti228.Parent = carti226

    carti226.Focused:Connect(function()
        if carti154.pulsationTweens[carti226] then carti154.pulsationTweens[carti226]:Cancel() end
        carti154.pulsationTweens[carti226] = carti6:Create(carti228, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Color = Color3.fromRGB(100, 100, 255):Lerp(Color3.fromRGB(150, 150, 255), 0.5), Thickness = 1.2, Transparency = 0.2
        })
        carti154.pulsationTweens[carti226]:Play()
    end)

    carti226.FocusLost:Connect(function()
        if carti154.pulsationTweens[carti226] then carti154.pulsationTweens[carti226]:Cancel() carti154.pulsationTweens[carti226] = nil end
        carti6:Create(carti228, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(100, 100, 100), Thickness = 0.8, Transparency = 0.5 }):Play()
    end)

    return carti226, carti228, carti225
end

partnerBox, partnerStroke = createSettingRow('Partner Username', carti69.PARTNER_NAME, carti222)
local carti229 = createSettingRow('Accept Delay (s)', carti69.AUTO_ACCEPT_DELAY, carti222)
local carti230 = createSettingRow('Confirm Delay (s)', carti69.AUTO_CONFIRM_DELAY, carti222)
spectatorBox = createSettingRow('Spectator Count', carti69.SPECTATOR_COUNT, carti222)
local carti231 = createSettingRow('Request Delay (s)', carti69.TRADE_REQUEST_DELAY, carti222)

partnerBox.FocusLost:Connect(function() updatePartnerFromUsername(partnerBox.Text) end)
carti229.FocusLost:Connect(function()
    local carti232 = tonumber(carti229.Text)
    if carti232 and carti232 >= 0 then carti69.AUTO_ACCEPT_DELAY = carti232 else carti229.Text = tostring(carti69.AUTO_ACCEPT_DELAY) end
end)
carti230.FocusLost:Connect(function()
    local carti232 = tonumber(carti230.Text)
    if carti232 and carti232 >= 0 then carti69.AUTO_CONFIRM_DELAY = carti232 else carti230.Text = tostring(carti69.AUTO_CONFIRM_DELAY) end
end)
spectatorBox.FocusLost:Connect(function()
    local carti232 = tonumber(spectatorBox.Text)
    if carti232 and carti232 >= 0 then
        carti69.SPECTATOR_COUNT = carti232
        carti70 = carti232
        if carti74.trade then
            carti74.trade.subscriber_count = carti232
            if carti30.refresh_all then carti30:refresh_all() carti37(true) end
        end
    else
        spectatorBox.Text = tostring(carti69.SPECTATOR_COUNT)
    end
end)
carti231.FocusLost:Connect(function()
    local carti232 = tonumber(carti231.Text)
    if carti232 and carti232 >= 0 then carti69.TRADE_REQUEST_DELAY = carti232 else carti231.Text = tostring(carti69.TRADE_REQUEST_DELAY) end
end)

local function carti233(text, bgColor, strokeColor, parent, onClick)
    local carti234 = Instance.new('TextButton')
    carti234.Size = UDim2.new(1, 0, 0, 26)
    carti234.BackgroundColor3 = bgColor
    carti234.BackgroundTransparency = 0.2
    carti234.Text = text
    carti234.Font = Enum.Font.FredokaOne
    carti234.TextSize = 12
    carti234.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti234.Parent = parent
    local carti227 = Instance.new('UICorner')
    carti227.CornerRadius = UDim.new(0, 4)
    carti227.Parent = carti234
    local carti228 = Instance.new('UIStroke')
    carti228.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti228.Color = strokeColor
    carti228.Thickness = 1.0
    carti228.Transparency = 0.3
    carti228.Parent = carti234
    if onClick then carti234.MouseButton1Click:Connect(onClick) end
    return carti234, carti228
end

local function carti235(parent, height)
    local carti236 = Instance.new('Frame')
    carti236.Size = UDim2.new(1, 0, 0, height or 3)
    carti236.BackgroundTransparency = 1
    carti236.Parent = parent
    return carti236
end

carti235(carti222, 4)

-- AUTO SPECTATE BUTTON WITH RANDOM VARIATION - PROMINENT PLACEMENT
local carti237 = Instance.new('TextButton')
carti237.Size = UDim2.new(1, 0, 0, 32)
carti237.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
carti237.BackgroundTransparency = 0.1
carti237.Text = '🎲 Auto Spectate: OFF'
carti237.Font = Enum.Font.FredokaOne
carti237.TextSize = 13
carti237.TextColor3 = Color3.fromRGB(255, 255, 255)
carti237.Parent = carti222
local carti238 = Instance.new('UICorner')
carti238.CornerRadius = UDim.new(0, 4)
carti238.Parent = carti237
local carti239 = Instance.new('UIStroke')
carti239.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti239.Color = Color3.fromRGB(255, 100, 100)
carti239.Thickness = 1.5
carti239.Parent = carti237

carti237.MouseButton1Click:Connect(function()
    carti69.AUTO_SPECTATE_ENABLED = not carti69.AUTO_SPECTATE_ENABLED
    
    if carti69.AUTO_SPECTATE_ENABLED then
        carti237.Text = '🎲 Auto Spectate: ON (Random)'
        carti237.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        carti239.Color = Color3.fromRGB(100, 255, 100)
        
        -- Store the current spectator count as the base
        carti70 = carti69.SPECTATOR_COUNT
        
        -- Start the auto spectate loop
        carti205()
        
        if carti32 then
            carti32:hint({ text = 'Auto Spectate ON! Range: ' .. (carti70 + carti69.SPECTATOR_VARIATION_MIN) .. '-' .. (carti70 + carti69.SPECTATOR_VARIATION_MAX), length = 3, overridable = true })
        end
    else
        carti237.Text = '🎲 Auto Spectate: OFF'
        carti237.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        carti239.Color = Color3.fromRGB(255, 100, 100)
        
        carti206()
        
        if carti32 then
            carti32:hint({ text = 'Auto Spectate OFF', length = 2, overridable = true })
        end
    end
end)

carti235(carti222)

carti233('Add Random Item', Color3.fromRGB(100, 50, 150), Color3.fromRGB(200, 100, 255), carti222, function()
    if carti74.active and carti74.trade then
        carti105(carti80(), carti111())
    end
end)

carti235(carti222)

carti233('Clear Trade', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), carti222, function()
    if carti74.active and carti74.trade then
        carti74.trade.sender_offer.items = {}
        carti74.trade.recipient_offer.items = {}
        carti74.trade.sender_offer.negotiated = false
        carti74.trade.recipient_offer.negotiated = false
        carti74.trade.current_stage = 'negotiation'
        carti74.trade.offer_version = carti74.trade.offer_version + 1
        carti30:_overwrite_local_trade_state(carti74.trade)
    end
end)

carti235(carti222)

-- FIXED: Start Trade button now uses the direct function
carti233('Start Trade', Color3.fromRGB(50, 80, 60), Color3.fromRGB(0, 255, 100), carti222, function()
    if carti74.active or carti74.pendingTradeRequest then return end
    
    if carti69.SHOW_TRADE_REQUEST then
        task.spawn(carti129)
    else
        task.spawn(carti127)
    end
end)

carti233('Block Player', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), carti222, function()
    local carti240 = carti2:FindFirstChild(partnerBox.Text)
    if carti240 then BlockPlayer(carti240) end
end)

carti235(carti222)

function makePartnerAccept()
    if carti74.active and carti74.trade then
        if carti74.trade.current_stage == 'negotiation' then
            if not carti74.trade.recipient_offer.negotiated then
                carti74.trade.recipient_offer.negotiated = true
                if carti74.trade.sender_offer.negotiated then
                    carti74.trade.current_stage = 'confirmation'
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    carti30:_overwrite_local_trade_state(carti74.trade)
                    if carti30._evaluate_trade_fairness then carti30:_evaluate_trade_fairness() end
                    if carti30._lock_trade_for_appropriate_time then carti30:_lock_trade_for_appropriate_time() end
                else
                    carti74.trade.offer_version = carti74.trade.offer_version + 1
                    carti30:_overwrite_local_trade_state(carti74.trade)
                end
            end
        elseif carti74.trade.current_stage == 'confirmation' then
            if not carti74.trade.recipient_offer.confirmed then
                carti74.trade.recipient_offer.confirmed = true
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
                if carti74.trade.sender_offer.confirmed and not carti74.tradeCompleting then
                    carti74.tradeCompleting = true
                    if carti30._set_confirmation_arrow_rotating then carti30:_set_confirmation_arrow_rotating(true) end
                    task.wait(3)
                    local carti120 = carti95(carti74.trade)
                    carti96(carti120)
                    local carti121 = {}
                    for _, carti122 in ipairs(carti74.trade.sender_offer.items or {}) do
                        if carti122 and carti122.carti_hub_local_pet and carti122.unique then
                            carti121[carti122.unique] = true
                        end
                    end
                    pcall(function()
                        local carti123 = (getgenv and getgenv()) or _G
                        if carti123.CartiHubRemoveTransferredLocalPets then
                            carti123.CartiHubRemoveTransferredLocalPets(carti121)
                        end
                    end)
                    pcall(function()
                        local carti124 = (getgenv and getgenv()) or _G
                        if carti124.CartiHubAddReceivedFakeTradePets then
                            carti124.CartiHubAddReceivedFakeTradePets(carti74.trade.recipient_offer.items)
                        end
                    end)
                    carti74.active = false
                    carti74.trade = nil
                    carti74.tradeCompleting = false
                    carti74.scamWarningShown = true
                    carti74.canShowTradeRequest = true
                    carti74.tradeRequestBlocked = false
                    carti22.set_app_visibility('TradeApp', false)
                    task.wait(0.1)
                    carti118()
                    if carti32 then carti32:hint({ text = 'The trade was successful!', length = 5, overridable = true }) end
                    if carti34 and carti22.is_visible('TradeHistoryApp') then carti34:_refresh() end
                end
            end
        end
    end
end

function makePartnerUnaccept()
    if carti74.active and carti74.trade then
        if carti74.trade.current_stage == 'negotiation' then
            if carti74.trade.recipient_offer.negotiated then
                carti74.trade.recipient_offer.negotiated = false
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
            end
        elseif carti74.trade.current_stage == 'confirmation' then
            if carti74.trade.recipient_offer.confirmed then
                carti74.trade.recipient_offer.confirmed = false
                carti74.trade.offer_version = carti74.trade.offer_version + 1
                carti30:_overwrite_local_trade_state(carti74.trade)
            end
        end
    end
end

carti233('Make Partner Accept', Color3.fromRGB(50, 150, 50), Color3.fromRGB(100, 255, 100), carti222, makePartnerAccept)

carti235(carti222)

local carti241, carti242 = carti233('Toggle Noclip: ON', Color3.fromRGB(80, 80, 180), Color3.fromRGB(100, 100, 255), carti222, function()
    carti154.noclipEnabled = not carti154.noclipEnabled
    if carti154.noclipEnabled then
        carti241.Text = 'Toggle Noclip: ON'
        carti241.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
        carti242.Color = Color3.fromRGB(100, 100, 255)
        carti194()
        carti195()
    else
        carti241.Text = 'Toggle Noclip: OFF'
        carti241.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
        carti242.Color = Color3.fromRGB(255, 100, 100)
    end
end)

carti235(carti222)

carti233('Make Partner Unaccept', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), carti222, makePartnerUnaccept)

carti235(carti222)

local carti243 = Instance.new('Frame')
carti243.Size = UDim2.new(1, 0, 0, 24)
carti243.BackgroundTransparency = 1
carti243.Parent = carti222

local carti244 = Instance.new('TextLabel')
carti244.Size = UDim2.new(0.4, 0, 1, 0)
carti244.BackgroundTransparency = 1
carti244.Text = 'Fake Player Pet:'
carti244.Font = Enum.Font.SourceSansSemibold
carti244.TextSize = 10
carti244.TextColor3 = Color3.fromRGB(180, 180, 180)
carti244.TextXAlignment = Enum.TextXAlignment.Left
carti244.Parent = carti243

local carti245 = {}
local carti112 = { { name = 'regular', label = 'Reg', pos = 0.4 }, { name = 'neon', label = 'Neon', pos = 0.6 }, { name = 'mega', label = 'Mega', pos = 0.8 } }

for _, pt in ipairs(carti112) do
    local carti234 = Instance.new('TextButton')
    carti234.Size = UDim2.new(0.18, 0, 1, 0)
    carti234.Position = UDim2.new(pt.pos, 0, 0, 0)
    carti234.Text = pt.label
    carti234.BackgroundColor3 = pt.name == 'regular' and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
    carti234.Font = Enum.Font.FredokaOne
    carti234.TextSize = 9
    carti234.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti234.Parent = carti243
    local carti227 = Instance.new('UICorner')
    carti227.CornerRadius = UDim.new(0, 4)
    carti227.Parent = carti234
    carti245[pt.name] = carti234
    carti234.MouseButton1Click:Connect(function()
        carti173 = pt.name
        for carti130, carti390 in pairs(carti245) do
            carti390.BackgroundColor3 = carti130 == pt.name and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
        end
    end)
end

carti233('Spawn fake player', Color3.fromRGB(65, 50, 150), Color3.fromRGB(74, 207, 255), carti222, function()
    local carti147, carti246 = nil, nil
    if carti69.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET then
        local carti247 = carti80()
        carti246 = { M = carti173 == 'mega', N = carti173 == 'neon', F = true, R = true }
        carti147 = { kind = GetKindPet(carti247) }
    end
    CreateFakePlayerCharacterFromPARTNER_NAME(carti69.PARTNER_NAME, carti2:GetUserIdFromNameAsync(carti69.PARTNER_NAME), carti147, carti246)
end)

carti235(carti222)

local carti248 = Instance.new('TextButton')
carti248.Size = UDim2.new(1, 0, 0, 14)
carti248.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
carti248.BackgroundTransparency = 0.2
carti248.Text = 'Spawn with random pet: false'
carti248.Font = Enum.Font.FredokaOne
carti248.TextSize = 7
carti248.TextColor3 = Color3.fromRGB(255, 255, 255)
carti248.Parent = carti222
local carti249 = Instance.new('UICorner')
carti249.CornerRadius = UDim.new(0, 3)
carti249.Parent = carti248
local carti250 = Instance.new('UIStroke')
carti250.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti250.Color = Color3.fromRGB(255, 100, 100)
carti250.Thickness = 0.8
carti250.Transparency = 0.3
carti250.Parent = carti248

carti248.MouseButton1Click:Connect(function()
    carti69.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET = not carti69.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET
    carti248.Text = 'Spawn with random pet: ' .. (carti69.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET and 'true' or 'false')
    if carti69.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET then
        carti248.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        carti250.Color = Color3.fromRGB(100, 255, 100)
    else
        carti248.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        carti250.Color = Color3.fromRGB(255, 100, 100)
    end
end)

carti235(carti222)

local carti251 = Instance.new('TextButton')
carti251.Size = UDim2.new(1, 0, 0, 14)
carti251.BackgroundColor3 = Color3.fromRGB(157, 58, 0)
carti251.BackgroundTransparency = 0.2
carti251.Text = 'Delete all fake players'
carti251.Font = Enum.Font.FredokaOne
carti251.TextSize = 7
carti251.TextColor3 = Color3.fromRGB(255, 255, 255)
carti251.Parent = carti222
local carti252 = Instance.new('UICorner')
carti252.CornerRadius = UDim.new(0, 3)
carti252.Parent = carti251

carti251.MouseButton1Click:Connect(function()
    pcall(function()
        carti164:Stop()
        for _, carti147 in ipairs(carti160) do
            if carti147 and carti147.model then
                pcall(function()
                    carti161('pet_char_wrappers', function(petWrappers)
                        for i = #petWrappers, 1, -1 do
                            if petWrappers[i].pet_unique == carti147.wrapper.pet_unique then table.remove(petWrappers, i) end
                        end
                        return petWrappers
                    end)
                end)
                pcall(function()
                    carti161('pet_state_managers', function(petStates)
                        for i = #petStates, 1, -1 do
                            if petStates[i].char == carti147.model then table.remove(petStates, i) end
                        end
                        return petStates
                    end)
                end)
            end
        end
        for _, folder in pairs(carti159) do if folder and folder.Parent then folder:Destroy() end end
        carti159 = {}
        carti160 = {}
        carti8 = {}
        _G.fakePlayerIds = {}
        print('✅ All fake players and pets deleted successfully')
    end)
end)

carti235(carti222)

local carti253, carti254 = carti233('Remove Partner Pets: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), carti222, function()
    carti74.removePartnerPetsOnConfirm = not carti74.removePartnerPetsOnConfirm
    carti69.REMOVE_PARTNER_PETS_ON_CONFIRM = carti74.removePartnerPetsOnConfirm
    if carti74.removePartnerPetsOnConfirm then
        carti253.Text = 'Remove Partner Pets: ON'
        carti253.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        carti254.Color = Color3.fromRGB(100, 255, 100)
    else
        carti253.Text = 'Remove Partner Pets: OFF'
        carti253.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        carti254.Color = Color3.fromRGB(255, 100, 100)
    end
end)

-- ==================== PLAYERS TAB ====================
local carti255 = carti155['Players']

local carti256 = Instance.new('TextBox')
carti256.Size = UDim2.new(1, 0, 0, 26)
carti256.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
carti256.BackgroundTransparency = 0.2
carti256.Text = ''
carti256.PlaceholderText = 'Search players...'
carti256.Font = Enum.Font.SourceSans
carti256.TextSize = 12
carti256.TextColor3 = Color3.fromRGB(255, 255, 255)
carti256.ClearTextOnFocus = false
carti256.TextXAlignment = Enum.TextXAlignment.Left
carti256.Parent = carti255
Instance.new('UICorner', carti256).CornerRadius = UDim.new(0, 4)

local carti257 = Instance.new('Frame')
carti257.Size = UDim2.new(1, 0, 0, 26)
carti257.Position = UDim2.new(0, 0, 0, 30)
carti257.BackgroundTransparency = 1
carti257.Parent = carti255

local carti258 = Instance.new('TextButton')
carti258.Size = UDim2.new(0.48, 0, 1, 0)
carti258.BackgroundColor3 = Color3.fromRGB(65, 65, 81)
carti258.BackgroundTransparency = 0.2
carti258.Text = 'Select Players'
carti258.Font = Enum.Font.FredokaOne
carti258.TextSize = 10
carti258.TextColor3 = Color3.fromRGB(255, 255, 255)
carti258.Parent = carti257
Instance.new('UICorner', carti258).CornerRadius = UDim.new(0, 4)
local carti259 = Instance.new('UIStroke')
carti259.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti259.Color = Color3.fromRGB(159, 159, 159)
carti259.Thickness = 1.0
carti259.Parent = carti258

local carti260 = Instance.new('TextButton')
carti260.Size = UDim2.new(0.48, 0, 1, 0)
carti260.Position = UDim2.new(0.52, 0, 0, 0)
carti260.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
carti260.BackgroundTransparency = 0.2
carti260.Text = 'Block Selected'
carti260.Font = Enum.Font.FredokaOne
carti260.TextSize = 10
carti260.TextColor3 = Color3.fromRGB(255, 255, 255)
carti260.Parent = carti257
Instance.new('UICorner', carti260).CornerRadius = UDim.new(0, 4)

local carti261 = Instance.new('ScrollingFrame')
carti261.Size = UDim2.new(1, 0, 0, 250)
carti261.Position = UDim2.new(0, 0, 0, 60)
carti261.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
carti261.BackgroundTransparency = 0.5
carti261.BorderSizePixel = 0
carti261.ScrollBarThickness = 4
carti261.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
carti261.ScrollBarImageTransparency = 0.5
carti261.Parent = carti255
Instance.new('UICorner', carti261).CornerRadius = UDim.new(0, 4)

local carti262 = Instance.new('UIListLayout')
carti262.SortOrder = Enum.SortOrder.LayoutOrder
carti262.Padding = UDim.new(0, 3)
carti262.Parent = carti261

local carti263 = Instance.new('UIPadding')
carti263.PaddingTop = UDim.new(0, 4)
carti263.PaddingBottom = UDim.new(0, 4)
carti263.PaddingLeft = UDim.new(0, 4)
carti263.PaddingRight = UDim.new(0, 4)
carti263.Parent = carti261

-- ==================== TOP 35 RICHEST SECTION WITH AUTOMATIC REFRESH ====================
local carti264 = Instance.new('TextLabel')
carti264.Size = UDim2.new(1, 0, 0, 18)
carti264.Position = UDim2.new(0, 0, 0, 315)
carti264.BackgroundTransparency = 1
carti264.Text = '💰 Top 35 Richest Players (Auto-Refresh)'
carti264.Font = Enum.Font.FredokaOne
carti264.TextSize = 11
carti264.TextColor3 = Color3.fromRGB(255, 215, 0)
carti264.TextXAlignment = Enum.TextXAlignment.Left
carti264.Parent = carti255

local carti265 = Instance.new('TextButton')
carti265.Size = UDim2.new(0.3, 0, 0, 18)
carti265.Position = UDim2.new(0.7, 0, 0, 315)
carti265.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
carti265.BackgroundTransparency = 0.2
carti265.Text = 'Auto: ON'
carti265.Font = Enum.Font.FredokaOne
carti265.TextSize = 8
carti265.TextColor3 = Color3.fromRGB(255, 255, 255)
carti265.Parent = carti255
Instance.new('UICorner', carti265).CornerRadius = UDim.new(0, 4)

local carti266 = Instance.new('TextButton')
carti266.Size = UDim2.new(0.3, 0, 0, 18)
carti266.Position = UDim2.new(0.35, 0, 0, 315)
carti266.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
carti266.BackgroundTransparency = 0.2
carti266.Text = '🔄 Manual'
carti266.Font = Enum.Font.FredokaOne
carti266.TextSize = 8
carti266.TextColor3 = Color3.fromRGB(255, 255, 255)
carti266.Parent = carti255
Instance.new('UICorner', carti266).CornerRadius = UDim.new(0, 4)

local carti267 = Instance.new('ScrollingFrame')
carti267.Size = UDim2.new(1, 0, 0, 320)
carti267.Position = UDim2.new(0, 0, 0, 337)
carti267.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
carti267.BackgroundTransparency = 0.5
carti267.BorderSizePixel = 0
carti267.ScrollBarThickness = 4
carti267.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
carti267.ScrollBarImageTransparency = 0.5
carti267.Parent = carti255
Instance.new('UICorner', carti267).CornerRadius = UDim.new(0, 4)

local carti268 = Instance.new('UIListLayout')
carti268.SortOrder = Enum.SortOrder.LayoutOrder
carti268.Padding = UDim.new(0, 3)
carti268.Parent = carti267

local carti269 = Instance.new('UIPadding')
carti269.PaddingTop = UDim.new(0, 4)
carti269.PaddingBottom = UDim.new(0, 4)
carti269.PaddingLeft = UDim.new(0, 4)
carti269.PaddingRight = UDim.new(0, 4)
carti269.Parent = carti267

local carti270 = {
    autoRefreshEnabled = true,
    playerCache = {},
    isRefreshing = false,
    lastRefreshTime = 0,
    REFRESH_COOLDOWN = 2,
    playerContainers = {}
}

local function carti271()
    local carti272 = {}
    for _, child in ipairs(carti267:GetChildren()) do
        if child:IsA('Frame') and child.Name:sub(1, 14) == 'RichestPlayer_' then
            carti272[child.Name:sub(15)] = true
        end
    end
    return carti272
end

local function carti273(playerName)
    for _, child in ipairs(carti267:GetChildren()) do
        if child:IsA('Frame') and child.Name == 'RichestPlayer_' .. playerName then
            child:Destroy()
        end
    end
    carti270.playerContainers[playerName] = nil
    carti270.playerCache[playerName] = nil
    carti158[playerName] = nil
end

local function carti274()
    task.wait(0.05)
    local carti275 = 8
    for _, child in ipairs(carti267:GetChildren()) do
        if child:IsA('Frame') then
            carti275 = carti275 + child.AbsoluteSize.Y + 3
        end
    end
    carti267.CanvasSize = UDim2.new(0, 0, 0, carti275)
end

local function carti276(carti310, index)
    local carti277 = Instance.new('Frame')
    carti277.Size = UDim2.new(1, -8, 0, 32)
    carti277.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    carti277.BackgroundTransparency = 0.1
    carti277.LayoutOrder = index
    carti277.Name = 'RichestPlayer_' .. carti310.playerName
    carti277.ClipsDescendants = true
    carti277.Parent = carti267
    Instance.new('UICorner', carti277).CornerRadius = UDim.new(0, 8)
    
    local carti278 = Instance.new('UIGradient')
    carti278.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 45, 65)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 32, 48))
    })
    carti278.Rotation = 90
    carti278.Parent = carti277
    
    local carti279 = Instance.new('UIStroke')
    carti279.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti279.Color = Color3.fromRGB(255, 200, 50)
    carti279.Thickness = 1.5
    carti279.Transparency = 0.2
    carti279.Parent = carti277

    local carti280 = {
        [1] = Color3.fromRGB(255, 215, 0),
        [2] = Color3.fromRGB(200, 200, 210),
        [3] = Color3.fromRGB(205, 140, 80),
    }

    local carti281 = Instance.new('TextLabel')
    carti281.Size = UDim2.new(0, 22, 0, 22)
    carti281.Position = UDim2.new(0, 5, 0, 5)
    carti281.BackgroundColor3 = carti280[index] or Color3.fromRGB(70, 70, 90)
    carti281.BackgroundTransparency = 0.2
    carti281.Text = tostring(index)
    carti281.Font = Enum.Font.GothamBlack
    carti281.TextSize = 11
    carti281.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti281.Parent = carti277
    Instance.new('UICorner', carti281).CornerRadius = UDim.new(0, 11)

    local carti282 = Instance.new('TextButton')
    carti282.Size = UDim2.new(0, 32, 0, 22)
    carti282.Position = UDim2.new(1, -74, 0, 5)
    carti282.BackgroundColor3 = Color3.fromRGB(50, 130, 100)
    carti282.BackgroundTransparency = 0.1
    carti282.Text = '🤝'
    carti282.Font = Enum.Font.GothamBold
    carti282.TextSize = 12
    carti282.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti282.Parent = carti277
    Instance.new('UICorner', carti282).CornerRadius = UDim.new(0, 6)

    carti282.MouseEnter:Connect(function()
        carti6:Create(carti282, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 160, 120) }):Play()
    end)
    
    carti282.MouseLeave:Connect(function()
        carti6:Create(carti282, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 130, 100) }):Play()
    end)

    carti282.MouseButton1Click:Connect(function()
        local carti198 = carti2:FindFirstChild(carti310.playerName)
        if carti198 then
            carti197(carti198)
        else
            for _, carti240 in ipairs(carti2:GetPlayers()) do
                if carti240.Name == carti310.playerName then
                    carti197(carti240)
                    return
                end
            end
            if carti32 then
                carti32:hint({ text = carti310.playerName .. ' is not in this server', length = 3, overridable = true })
            end
        end
    end)

    local carti141 = Instance.new('TextButton')
    carti141.Size = UDim2.new(0, 32, 0, 22)
    carti141.Position = UDim2.new(1, -38, 0, 5)
    carti141.BackgroundColor3 = Color3.fromRGB(100, 70, 150)
    carti141.BackgroundTransparency = 0.1
    carti141.Text = '👤'
    carti141.Font = Enum.Font.GothamBold
    carti141.TextSize = 12
    carti141.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti141.Parent = carti277
    Instance.new('UICorner', carti141).CornerRadius = UDim.new(0, 6)

    carti141.MouseEnter:Connect(function()
        carti6:Create(carti141, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(130, 90, 180) }):Play()
    end)
    
    carti141.MouseLeave:Connect(function()
        carti6:Create(carti141, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 70, 150) }):Play()
    end)

    carti141.MouseButton1Click:Connect(function()
        local carti198 = carti2:FindFirstChild(carti310.playerName)
        if carti198 then
            pcall(function()
                OpenProfile(carti198.UserId)
            end)
        else
            for _, carti240 in ipairs(carti2:GetPlayers()) do
                if carti240.Name == carti310.playerName then
                    pcall(function()
                        OpenProfile(carti240.UserId)
                    end)
                    return
                end
            end
            if carti32 then
                carti32:hint({ text = carti310.playerName .. ' is not in this server', length = 3, overridable = true })
            end
        end
    end)

    local carti283 = Instance.new('TextButton')
    carti283.Size = UDim2.new(1, -110, 0, 32)
    carti283.Position = UDim2.new(0, 30, 0, 0)
    carti283.BackgroundTransparency = 1
    carti283.Text = ''
    carti283.Parent = carti277

    local carti284 = Instance.new('TextLabel')
    carti284.Size = UDim2.new(0.55, 0, 1, 0)
    carti284.Position = UDim2.new(0, 0, 0, 0)
    carti284.BackgroundTransparency = 1
    carti284.Text = carti310.playerName
    carti284.Font = Enum.Font.GothamBold
    carti284.TextSize = 10
    carti284.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti284.TextXAlignment = Enum.TextXAlignment.Left
    carti284.TextTruncate = Enum.TextTruncate.AtEnd
    carti284.Parent = carti283

    local carti285 = Instance.new('TextLabel')
    carti285.Size = UDim2.new(0.45, 0, 1, 0)
    carti285.Position = UDim2.new(0.55, 0, 0, 0)
    carti285.BackgroundTransparency = 1
    carti285.Text = carti67(carti310.totalValue)
    carti285.Font = Enum.Font.GothamBold
    carti285.TextSize = 10
    carti285.TextColor3 = Color3.fromRGB(120, 255, 120)
    carti285.TextXAlignment = Enum.TextXAlignment.Right
    carti285.Parent = carti283

    -- Pets section inside container
    local carti286 = Instance.new('Frame')
    carti286.Size = UDim2.new(1, -8, 0, 0)
    carti286.Position = UDim2.new(0, 4, 0, 34)
    carti286.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    carti286.BackgroundTransparency = 0.3
    carti286.Visible = false
    carti286.Name = 'PetsSection'
    carti286.Parent = carti277
    Instance.new('UICorner', carti286).CornerRadius = UDim.new(0, 6)

    local carti287 = Instance.new('UIListLayout')
    carti287.SortOrder = Enum.SortOrder.LayoutOrder
    carti287.Padding = UDim.new(0, 2)
    carti287.Parent = carti286

    local carti288 = Instance.new('UIPadding')
    carti288.PaddingTop = UDim.new(0, 4)
    carti288.PaddingBottom = UDim.new(0, 4)
    carti288.PaddingLeft = UDim.new(0, 6)
    carti288.PaddingRight = UDim.new(0, 6)
    carti288.Parent = carti286

    local carti289 = false
    local carti290 = 0

    carti283.MouseButton1Click:Connect(function()
        if carti289 then
            carti289 = false
            carti290 = carti290 + 1
            carti286.Visible = false
            carti286.Size = UDim2.new(1, -8, 0, 0)
            carti277.Size = UDim2.new(1, -8, 0, 32)
        else
            carti289 = true
            carti290 = carti290 + 1
            local carti291 = carti290

            for _, child in ipairs(carti286:GetChildren()) do
                if child:IsA('TextLabel') then child:Destroy() end
            end

            local carti292 = 0
            if carti310.pets and #carti310.pets > 0 then
                local carti293 = {}
                for _, carti57 in ipairs(carti310.pets) do table.insert(carti293, carti57) end
                table.sort(carti293, function(a, carti390) return a.value > carti390.value end)

                local carti294 = math.min(#carti293, 8)
                for i = 1, carti294 do
                    local carti57 = carti293[i]
                    local carti295 = ""
                    if carti57.isMega then carti295 = "M "
                    elseif carti57.isNeon then carti295 = "N " end
                    if carti57.isFly then carti295 = carti295 .. "F" end
                    if carti57.isRide then carti295 = carti295 .. "R" end
                    if carti295 ~= "" then carti295 = "[" .. prefix:gsub("%s+$", "") .. "] " end

                    local carti296 = Instance.new('TextLabel')
                    carti296.Size = UDim2.new(1, 0, 0, 14)
                    carti296.BackgroundTransparency = 1
                    carti296.Text = carti295 .. pet.displayName .. ' - ' .. formatValue(carti57.value)
                    carti296.Font = Enum.Font.SourceSans
                    carti296.TextSize = 9
                    carti296.TextColor3 = carti57.isMega and Color3.fromRGB(170, 100, 255) or (carti57.isNeon and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(200, 200, 200))
                    carti296.TextXAlignment = Enum.TextXAlignment.Left
                    carti296.LayoutOrder = i
                    carti296.Parent = carti286
                end

                if #carti293 > 8 then
                    local carti297 = Instance.new('TextLabel')
                    carti297.Size = UDim2.new(1, 0, 0, 12)
                    carti297.BackgroundTransparency = 1
                    carti297.Text = '... and ' .. (#carti293 - 8) .. ' more pets'
                    carti297.Font = Enum.Font.SourceSansItalic
                    carti297.TextSize = 8
                    carti297.TextColor3 = Color3.fromRGB(150, 150, 150)
                    carti297.TextXAlignment = Enum.TextXAlignment.Left
                    carti297.LayoutOrder = 999
                    carti297.Parent = carti286
                end

                carti292 = (carti294 * 16) + 10
                if #carti293 > 8 then carti292 = carti292 + 14 end
            else
                local carti298 = Instance.new('TextLabel')
                carti298.Size = UDim2.new(1, 0, 0, 14)
                carti298.BackgroundTransparency = 1
                carti298.Text = 'No pets listed in profile'
                carti298.Font = Enum.Font.SourceSansItalic
                carti298.TextSize = 9
                carti298.TextColor3 = Color3.fromRGB(150, 150, 150)
                carti298.TextXAlignment = Enum.TextXAlignment.Left
                carti298.Parent = carti286
                carti292 = 22
            end

            carti286.Size = UDim2.new(1, -8, 0, carti292)
            carti286.Visible = true
            carti277.Size = UDim2.new(1, -8, 0, 36 + carti292)
            
            -- Auto-close after 10 seconds
            task.spawn(function()
                task.wait(10)
                if carti289 and carti290 == carti291 then
                    carti289 = false
                    carti286.Visible = false
                    carti286.Size = UDim2.new(1, -8, 0, 0)
                    carti277.Size = UDim2.new(1, -8, 0, 32)
                    
                    -- Update canvas size
                    task.wait(0.05)
                    local carti275 = 8
                    for _, child in ipairs(carti267:GetChildren()) do
                        if child:IsA('Frame') then
                            carti275 = carti275 + child.AbsoluteSize.Y + 3
                        end
                    end
                    carti267.CanvasSize = UDim2.new(0, 0, 0, carti275)
                end
            end)
        end

        -- Update canvas size
        task.wait(0.05)
        local carti275 = 8
        for _, child in ipairs(carti267:GetChildren()) do
            if child:IsA('Frame') then
                carti275 = carti275 + child.AbsoluteSize.Y + 3
            end
        end
        carti267.CanvasSize = UDim2.new(0, 0, 0, carti275)
    end)

    return carti277
end

local function carti299(forceRefresh)
    if carti270.isRefreshing then return end
    
    local carti300 = tick()
    if not forceRefresh and (carti300 - carti270.lastRefreshTime) < carti270.REFRESH_COOLDOWN then
        return
    end
    
    carti270.isRefreshing = true
    carti270.lastRefreshTime = carti300
    
    local carti301 = carti2.LocalPlayer
    local carti302 = {}
    for _, carti240 in ipairs(carti2:GetPlayers()) do
        if carti240 ~= carti301 then
            carti302[carti240.Name] = carti240
        end
    end
    
    local carti303 = carti271()
    
    -- Remove players who left
    for playerName in pairs(carti303) do
        if not carti302[playerName] then
            carti273(playerName)
            for i, carti162 in ipairs(carti157) do
                if carti162.playerName == playerName then
                    table.remove(carti157, i)
                    break
                end
            end
        end
    end
    
    -- If force refresh, clear everything
    if forceRefresh then
        for _, child in ipairs(carti267:GetChildren()) do
            if child:IsA('Frame') then child:Destroy() end
        end
        carti158 = {}
        carti157 = {}
        carti270.playerContainers = {}
        carti303 = {}
        
        local carti304 = Instance.new('TextLabel')
        carti304.Size = UDim2.new(1, -8, 0, 30)
        carti304.BackgroundTransparency = 1
        carti304.Text = '⏳ Scanning players...'
        carti304.Font = Enum.Font.FredokaOne
        carti304.TextSize = 11
        carti304.TextColor3 = Color3.fromRGB(200, 200, 200)
        carti304.LayoutOrder = 0
        carti304.Name = 'LoadingLabel'
        carti304.Parent = carti267
    end
    
    task.spawn(function()
        local carti305 = {}
        for playerName, carti240 in pairs(carti302) do
            if forceRefresh or not carti303[playerName] then
                table.insert(carti305, carti240)
            end
        end
        
        for _, carti240 in ipairs(carti305) do
            local carti12, carti306 = pcall(function()
                return carti68:InvokeServer(carti240.UserId)
            end)
            
            local carti307 = 0
            local carti308 = {}
            
            if carti12 and carti306 then
                local carti309 = carti61(carti306)
                carti308 = carti64(carti309)
                for _, carti57 in ipairs(carti308) do carti307 = carti307 + carti57.value end
            end
            
            local carti310 = { playerName = carti240.Name, totalValue = carti307, pets = carti308, player = carti240 }
            carti270.playerCache[carti240.Name] = { totalValue = carti307, pets = carti308, player = carti240, lastUpdated = tick() }
            table.insert(carti157, carti310)
        end
        
        local carti304 = carti267:FindFirstChild('LoadingLabel')
        if carti304 then carti304:Destroy() end
        
        table.sort(carti157, function(a, carti390) return a.totalValue > carti390.totalValue end)
        
        local carti294 = math.min(#carti157, 35)
        local carti280 = { [1] = Color3.fromRGB(255, 215, 0), [2] = Color3.fromRGB(192, 192, 192), [3] = Color3.fromRGB(205, 127, 50) }
        
        for i = 1, carti294 do
            local carti162 = carti157[i]
            local carti311 = carti267:FindFirstChild('RichestPlayer_' .. carti162.playerName)
            
            if not carti311 then
                carti276(carti162, i)
                carti270.playerContainers[carti162.playerName] = true
            else
                carti311.LayoutOrder = i
                local carti281 = carti311:FindFirstChildOfClass('TextLabel')
                if carti281 and carti281.Size == UDim2.new(0, 20, 0, 20) then
                    carti281.Text = tostring(i)
                    carti281.BackgroundColor3 = carti280[i] or Color3.fromRGB(80, 80, 100)
                end
            end
        end
        
        for i = carti294 + 1, #carti157 do
            local carti162 = carti157[i]
            local carti277 = carti267:FindFirstChild('RichestPlayer_' .. carti162.playerName)
            if carti277 then carti277:Destroy() end
        end
        
        carti274()
        
        if forceRefresh and carti32 then 
            carti32:hint({ text = 'Updated ' .. #carti157 .. ' players!', length = 2, overridable = true }) 
        end
        
        carti270.isRefreshing = false
    end)
end

local function carti312()
    if not carti270.autoRefreshEnabled then return end
    carti299(false)
end

task.spawn(function()
    while true do
        task.wait(5)
        carti312()
    end
end)

carti266.MouseButton1Click:Connect(function()
    carti299(true)
end)

carti265.MouseButton1Click:Connect(function()
    carti270.autoRefreshEnabled = not carti270.autoRefreshEnabled
    if carti270.autoRefreshEnabled then
        carti265.Text = 'Auto: ON'
        carti265.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        carti299(true)
    else
        carti265.Text = 'Auto: OFF'
        carti265.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

carti2.PlayerAdded:Connect(function(carti240)
    if carti270.autoRefreshEnabled then
        task.wait(1)
        if carti240 ~= carti2.LocalPlayer then
            task.spawn(function()
                local carti12, carti306 = pcall(function()
                    return carti68:InvokeServer(carti240.UserId)
                end)
                
                local carti307 = 0
                local carti308 = {}
                
                if carti12 and carti306 then
                    local carti309 = carti61(carti306)
                    carti308 = carti64(carti309)
                    for _, carti57 in ipairs(carti308) do carti307 = carti307 + carti57.value end
                end
                
                local carti310 = { playerName = carti240.Name, totalValue = carti307, pets = carti308, player = carti240 }
                carti270.playerCache[carti240.Name] = { totalValue = carti307, pets = carti308, player = carti240, lastUpdated = tick() }
                table.insert(carti157, carti310)
                
                table.sort(carti157, function(a, carti390) return a.totalValue > carti390.totalValue end)
                
                local carti313 = 1
                for i, carti162 in ipairs(carti157) do
                    if carti162.playerName == carti240.Name then carti313 = i break end
                end
                
                if carti313 <= 35 then
                    carti276(carti310, carti313)
                    carti270.playerContainers[carti240.Name] = true
                    
                    local carti280 = { [1] = Color3.fromRGB(255, 215, 0), [2] = Color3.fromRGB(192, 192, 192), [3] = Color3.fromRGB(205, 127, 50) }
                    for i, carti162 in ipairs(carti157) do
                        if i <= 35 then
                            local carti277 = carti267:FindFirstChild('RichestPlayer_' .. carti162.playerName)
                            if carti277 then
                                carti277.LayoutOrder = i
                                local carti281 = carti277:FindFirstChildOfClass('TextLabel')
                                if carti281 and carti281.Size == UDim2.new(0, 20, 0, 20) then
                                    carti281.Text = tostring(i)
                                    carti281.BackgroundColor3 = carti280[i] or Color3.fromRGB(80, 80, 100)
                                end
                            end
                        end
                    end
                    carti274()
                end
            end)
        end
    end
end)

carti2.PlayerRemoving:Connect(function(carti240)
    if carti270.autoRefreshEnabled then
        carti273(carti240.Name)
        
        for i, carti162 in ipairs(carti157) do
            if carti162.playerName == carti240.Name then
                table.remove(carti157, i)
                break
            end
        end
        
        local carti280 = { [1] = Color3.fromRGB(255, 215, 0), [2] = Color3.fromRGB(192, 192, 192), [3] = Color3.fromRGB(205, 127, 50) }
        for i, carti162 in ipairs(carti157) do
            if i <= 35 then
                local carti277 = carti267:FindFirstChild('RichestPlayer_' .. carti162.playerName)
                if carti277 then
                    carti277.LayoutOrder = i
                    local carti281 = carti277:FindFirstChildOfClass('TextLabel')
                    if carti281 and carti281.Size == UDim2.new(0, 20, 0, 20) then
                        carti281.Text = tostring(i)
                        carti281.BackgroundColor3 = carti280[i] or Color3.fromRGB(80, 80, 100)
                    end
                end
            end
        end
        carti274()
    end
end)

local function carti314(carti240, index, carti326)
    local carti315 = Instance.new('TextButton')
    carti315.Size = UDim2.new(1, -8, 0, 32)
    carti315.BackgroundColor3 = carti326 and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50)
    carti315.BackgroundTransparency = 0.2
    carti315.Text = ''
    carti315.LayoutOrder = index
    carti315.Parent = carti261
    Instance.new('UICorner', carti315).CornerRadius = UDim.new(0, 4)
    local carti316 = Instance.new('UIStroke')
    carti316.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti316.Color = carti326 and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80)
    carti316.Thickness = 1.0
    carti316.Parent = carti315

    local carti284 = Instance.new('TextLabel')
    carti284.Size = UDim2.new(1, -30, 1, 0)
    carti284.Position = UDim2.new(0, 4, 0, 0)
    carti284.BackgroundTransparency = 1
    carti284.Text = carti240.Name
    carti284.Font = Enum.Font.FredokaOne
    carti284.TextSize = 12
    carti284.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti284.TextXAlignment = Enum.TextXAlignment.Left
    carti284.Parent = carti315

    local carti317 = Instance.new('Frame')
    carti317.Size = UDim2.new(0, 20, 0, 20)
    carti317.Position = UDim2.new(1, -25, 0.5, -10)
    carti317.BackgroundColor3 = carti326 and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
    carti317.BackgroundTransparency = 0.2
    carti317.Visible = carti154.selectionMode
    carti317.Parent = carti315
    Instance.new('UICorner', carti317).CornerRadius = UDim.new(0, 4)
    local carti318 = Instance.new('UIStroke')
    carti318.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti318.Color = carti326 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
    carti318.Thickness = 1.0
    carti318.Parent = carti317

    local carti319 = Instance.new('TextLabel')
    carti319.Size = UDim2.new(1, 0, 1, 0)
    carti319.BackgroundTransparency = 1
    carti319.Text = '✓'
    carti319.Font = Enum.Font.FredokaOne
    carti319.TextSize = 14
    carti319.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti319.Visible = carti326
    carti319.Parent = carti317

    carti315.MouseButton1Click:Connect(function()
        if carti154.selectionMode then
            local carti320 = not carti154.selectedPlayers[carti240.Name]
            carti154.selectedPlayers[carti240.Name] = carti320
            carti317.BackgroundColor3 = carti320 and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
            carti318.Color = carti320 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
            carti319.Visible = carti320
            carti315.BackgroundColor3 = carti320 and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50)
            carti316.Color = carti320 and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80)
        else
            setActiveTab('Control')
            partnerBox.Text = carti240.Name
            updatePartnerFromUsername(carti240.Name)
        end
    end)

    return carti315, carti317
end

local function carti321()
    local carti315 = Instance.new('TextButton')
    carti315.Size = UDim2.new(1, -8, 0, 32)
    carti315.BackgroundColor3 = Color3.fromRGB(65, 65, 81)
    carti315.BackgroundTransparency = 0.2
    carti315.Text = ''
    carti315.Name = 'SelectFromTradeButton'
    carti315.LayoutOrder = -999
    carti315.Parent = carti261
    Instance.new('UICorner', carti315).CornerRadius = UDim.new(0, 4)
    local carti284 = Instance.new('TextLabel')
    carti284.Size = UDim2.new(1, -8, 1, 0)
    carti284.Position = UDim2.new(0, 4, 0, 0)
    carti284.BackgroundTransparency = 1
    carti284.Text = 'Select Partner From Trade'
    carti284.Font = Enum.Font.FredokaOne
    carti284.TextSize = 12
    carti284.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti284.TextXAlignment = Enum.TextXAlignment.Left
    carti284.Parent = carti315

    carti315.MouseButton1Click:Connect(function()
        setActiveTab('Control')
        pcall(function()
            local carti322 = carti2.LocalPlayer.PlayerGui.TradeApp.Frame.NegotiationFrame.Header.PartnerFrame.NameLabel.Text
            for _, carti240 in ipairs(carti2:GetPlayers()) do
                if carti240.Name:lower() == carti322:lower() then
                    partnerBox.Text = carti240.Name
                    updatePartnerFromUsername(carti240.Name)
                    break
                end
            end
        end)
    end)

    return carti315
end

local function carti323()
    for _, child in ipairs(carti261:GetChildren()) do
        if child:IsA('TextButton') and child.Name ~= 'SelectFromTradeButton' then child:Destroy() end
    end
    carti154.playerListButtons = {}

    local carti324 = carti256.Text:lower()
    local carti325 = {}
    for _, carti240 in ipairs(carti2:GetPlayers()) do
        if carti324 == '' or carti240.Name:lower():sub(1, #carti324) == carti324 then
            table.insert(carti325, carti240)
        end
    end
    table.sort(carti325, function(a, carti390) return a.Name:lower() < carti390.Name:lower() end)

    for i, carti240 in ipairs(carti325) do
        local carti326 = carti154.selectedPlayers[carti240.Name] == true
        local carti315 = carti314(carti240, i, carti326)
        table.insert(carti154.playerListButtons, carti315)
    end
    carti261.CanvasSize = UDim2.new(0, 0, 0, (#carti325 * 36) + 40)
end

carti256:GetPropertyChangedSignal("Text"):Connect(carti323)

carti258.MouseButton1Click:Connect(function()
    carti154.selectionMode = not carti154.selectionMode
    if carti154.selectionMode then
        carti258.Text = 'Cancel Selection'
        carti258.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        carti259.Color = Color3.fromRGB(255, 100, 100)
    else
        carti258.Text = 'Select Players'
        carti258.BackgroundColor3 = Color3.fromRGB(65, 65, 81)
        carti259.Color = Color3.fromRGB(159, 159, 159)
        carti154.selectedPlayers = {}
    end
    for _, child in ipairs(carti261:GetChildren()) do
        if child:IsA('TextButton') and child.Name ~= 'SelectFromTradeButton' then
            local carti317 = child:FindFirstChildOfClass('Frame')
            if carti317 then carti317.Visible = carti154.selectionMode end
        end
    end
end)

carti260.MouseButton1Click:Connect(function()
    if not carti154.selectionMode then return end
    local carti327 = 0
    for playerName, carti326 in pairs(carti154.selectedPlayers) do
        if carti326 then
            local carti240 = carti2:FindFirstChild(playerName)
            if carti240 then
                pcall(function() BlockPlayer(carti240) carti327 = carti327 + 1 end)
                task.wait(0.15)
            end
        end
    end
    carti154.selectionMode = false
    carti258.Text = 'Select Players'
    carti258.BackgroundColor3 = Color3.fromRGB(65, 65, 81)
    carti259.Color = Color3.fromRGB(159, 159, 159)
    carti154.selectedPlayers = {}
    carti323()
    if carti32 then carti32:hint({ text = 'Blocked ' .. count .. ' player(s)', length = 3, overridable = true }) end
end)

carti323()
carti321()

carti2.PlayerAdded:Connect(carti323)
carti2.PlayerRemoving:Connect(carti323)

-- ==================== PETS TAB ====================
local carti328 = carti155['Pets']

local carti329 = Instance.new('Frame')
carti329.Size = UDim2.new(1, 0, 0, 190)
carti329.Position = UDim2.new(0, 0, 0, 0)
carti329.BackgroundTransparency = 1
carti329.Parent = carti328

local carti330 = Instance.new('TextLabel')
carti330.Size = UDim2.new(1, 0, 0, 16)
carti330.BackgroundTransparency = 1
carti330.Text = 'Pet Name To Add'
carti330.Font = Enum.Font.SourceSansSemibold
carti330.TextSize = 11
carti330.TextColor3 = Color3.fromRGB(180, 180, 180)
carti330.TextXAlignment = Enum.TextXAlignment.Left
carti330.Parent = carti329

local carti331 = Instance.new('TextBox')
carti331.Size = UDim2.new(1, 0, 0, 26)
carti331.Position = UDim2.new(0, 0, 0, 18)
carti331.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
carti331.BackgroundTransparency = 0.2
carti331.Text = ''
carti331.PlaceholderText = 'Enter pet name...'
carti331.Font = Enum.Font.FredokaOne
carti331.TextSize = 11
carti331.TextColor3 = Color3.fromRGB(255, 255, 255)
carti331.ClearTextOnFocus = false
carti331.Parent = carti329
Instance.new('UICorner', carti331).CornerRadius = UDim.new(0, 4)
local carti332 = Instance.new('UIStroke')
carti332.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti332.Color = Color3.fromRGB(100, 100, 100)
carti332.Thickness = 0.8
carti332.Transparency = 0.5
carti332.Parent = carti331

local carti333 = Instance.new('Frame')
carti333.Size = UDim2.new(1, 0, 0, 26)
carti333.Position = UDim2.new(0, 0, 0, 49)
carti333.BackgroundTransparency = 1
carti333.Parent = carti329

local carti334 = { 'M', 'N', 'F', 'R' }
local carti335 = {
    M = Color3.fromRGB(170, 0, 255),
    N = Color3.fromRGB(0, 255, 100),
    F = Color3.fromRGB(0, 200, 255),
    R = Color3.fromRGB(255, 50, 150),
}

local carti336 = {}
for i, carti295 in ipairs(carti334) do
    local carti337 = Instance.new('TextButton')
    carti337.Size = UDim2.new(0.23, 0, 1, 0)
    carti337.Position = UDim2.new((i - 1) * 0.25 + 0.01, 0, 0, 0)
    carti337.Text = carti295
    carti337.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    carti337.BackgroundTransparency = 0.2
    carti337.Font = Enum.Font.FredokaOne
    carti337.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti337.TextSize = 13
    carti337.Parent = carti333
    Instance.new('UICorner', carti337).CornerRadius = UDim.new(0, 4)
    local carti316 = Instance.new('UIStroke')
    carti316.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti316.Color = carti335[carti295]
    carti316.Thickness = 1.0
    carti316.Transparency = 0.5
    carti316.Parent = carti337

    carti336[carti295] = { button = carti337, stroke = carti316 }

    carti337.MouseButton1Click:Connect(function()
        if carti295 == 'M' and carti75.activeFlags['N'] then return end
        if carti295 == 'N' and carti75.activeFlags['M'] then return end
        carti75.activeFlags[carti295] = not carti75.activeFlags[carti295]
        if carti75.activeFlags[carti295] then
            carti337.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            carti6:Create(carti316, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(0, 255, 0), Thickness = 1.2, Transparency = 0.2 }):Play()
        else
            carti337.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            carti6:Create(carti316, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = carti335[carti295], Thickness = 1.0, Transparency = 0.5 }):Play()
        end
    end)
end

local carti338 = Instance.new('TextLabel')
carti338.Size = UDim2.new(1, 0, 0, 14)
carti338.Position = UDim2.new(0, 0, 0, 68)
carti338.BackgroundTransparency = 1
carti338.Text = 'Add Pet Delay (s)'
carti338.Font = Enum.Font.SourceSansSemibold
carti338.TextSize = 10
carti338.TextColor3 = Color3.fromRGB(180, 180, 180)
carti338.TextXAlignment = Enum.TextXAlignment.Left
carti338.Parent = carti329

local carti339 = Instance.new('TextBox')
carti339.Size = UDim2.new(1, 0, 0, 24)
carti339.Position = UDim2.new(0, 0, 0, 82)
carti339.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
carti339.BackgroundTransparency = 0.2
carti339.Text = tostring(carti69.ADD_PET_REQUEST_DELAY)
carti339.Font = Enum.Font.SourceSans
carti339.TextSize = 12
carti339.TextColor3 = Color3.fromRGB(255, 255, 255)
carti339.ClearTextOnFocus = false
carti339.TextXAlignment = Enum.TextXAlignment.Center
carti339.Parent = carti329
Instance.new('UICorner', carti339).CornerRadius = UDim.new(0, 4)

carti339.FocusLost:Connect(function()
    local carti232 = tonumber(carti339.Text)
    if carti232 and carti232 >= 0 then carti69.ADD_PET_REQUEST_DELAY = carti232 else carti339.Text = tostring(carti69.ADD_PET_REQUEST_DELAY) end
end)

local carti340 = Instance.new('TextButton')
carti340.Size = UDim2.new(1, 0, 0, 26)
carti340.Position = UDim2.new(0, 0, 0, 114)
carti340.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
carti340.BackgroundTransparency = 0.2
carti340.Text = 'Add Pet to Trade'
carti340.Font = Enum.Font.FredokaOne
carti340.TextSize = 12
carti340.TextColor3 = Color3.fromRGB(255, 255, 255)
carti340.Parent = carti329
Instance.new('UICorner', carti340).CornerRadius = UDim.new(0, 4)

carti340.MouseButton1Click:Connect(function()
    local carti341 = carti331.Text
    if carti341 and carti341 ~= '' then carti105(carti341, carti75.activeFlags) end
end)

local carti342 = Instance.new('TextButton')
carti342.Size = UDim2.new(1, 0, 0, 26)
carti342.Position = UDim2.new(0, 0, 0, 145)
carti342.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
carti342.BackgroundTransparency = 0.2
carti342.Text = 'Remove Latest Pet'
carti342.Font = Enum.Font.FredokaOne
carti342.TextSize = 12
carti342.TextColor3 = Color3.fromRGB(255, 255, 255)
carti342.Parent = carti329
Instance.new('UICorner', carti342).CornerRadius = UDim.new(0, 4)

carti342.MouseButton1Click:Connect(carti107)

local carti343 = Instance.new('TextButton')
carti343.Size = UDim2.new(1, 0, 0, 26)
carti343.Position = UDim2.new(0, 0, 0, 176)
carti343.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
carti343.BackgroundTransparency = 0.2
carti343.Text = 'Add Random High-Value Pet'
carti343.Font = Enum.Font.FredokaOne
carti343.TextSize = 10
carti343.TextColor3 = Color3.fromRGB(255, 255, 255)
carti343.Parent = carti329
Instance.new('UICorner', carti343).CornerRadius = UDim.new(0, 4)

carti343.MouseButton1Click:Connect(function()
    carti105(carti80(), carti111())
end)

local carti344 = Instance.new('Frame')
carti344.Size = UDim2.new(1, 0, 0, 400)
carti344.Position = UDim2.new(0, 0, 0, 195)
carti344.BackgroundTransparency = 1
carti344.Parent = carti328

local carti345 = Instance.new('TextLabel')
carti345.Size = UDim2.new(1, 0, 0, 16)
carti345.BackgroundTransparency = 1
carti345.Text = 'High-Value Pets (Balloon Unicorn+)'
carti345.Font = Enum.Font.SourceSansSemibold
carti345.TextSize = 11
carti345.TextColor3 = Color3.fromRGB(180, 180, 180)
carti345.TextXAlignment = Enum.TextXAlignment.Left
carti345.Parent = carti344

local carti346 = Instance.new('ScrollingFrame')
carti346.Size = UDim2.new(1, 0, 0, 380)
carti346.Position = UDim2.new(0, 0, 0, 18)
carti346.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
carti346.BackgroundTransparency = 0.5
carti346.BorderSizePixel = 0
carti346.ScrollBarThickness = 4
carti346.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
carti346.ScrollBarImageTransparency = 0.5
carti346.Parent = carti344
Instance.new('UICorner', carti346).CornerRadius = UDim.new(0, 4)

local carti347 = Instance.new('UIListLayout')
carti347.SortOrder = Enum.SortOrder.LayoutOrder
carti347.Padding = UDim.new(0, 3)
carti347.Parent = carti346

local carti348 = Instance.new('UIPadding')
carti348.PaddingTop = UDim.new(0, 4)
carti348.PaddingBottom = UDim.new(0, 4)
carti348.PaddingLeft = UDim.new(0, 4)
carti348.PaddingRight = UDim.new(0, 4)
carti348.Parent = carti346

for i, carti341 in ipairs(carti77) do
    local carti315 = Instance.new('TextButton')
    carti315.Size = UDim2.new(1, -8, 0, 28)
    carti315.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti315.BackgroundTransparency = 0.1
    carti315.Text = carti341
    carti315.Font = Enum.Font.GothamBold
    carti315.TextSize = 10
    carti315.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti315.LayoutOrder = i
    carti315.Parent = carti346
    Instance.new('UICorner', carti315).CornerRadius = UDim.new(0, 6)
    
    local carti316 = Instance.new('UIStroke')
    carti316.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti316.Color = Color3.fromRGB(255, 200, 50)
    carti316.Thickness = 1.5
    carti316.Transparency = 0.2
    carti316.Parent = carti315

    carti315.MouseEnter:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play()
    end)
    
    carti315.MouseLeave:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play()
    end)

    carti315.MouseButton1Click:Connect(function()
        carti331.Text = carti341
        carti6:Create(carti332, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(255, 200, 50), Thickness = 1.5 }):Play()
        task.wait(0.5)
        carti6:Create(carti332, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(100, 100, 100), Thickness = 0.8 }):Play()
    end)
end

carti346.CanvasSize = UDim2.new(0,0, 0, (#carti77 * 31) + 8)

-- ==================== INVENTORY TAB ====================
carti154.inventoryTab = carti155['Inventory']
carti154.inventoryTitle = Instance.new('TextLabel')
carti154.inventoryTitle.Size = UDim2.new(1, 0, 0, 24)
carti154.inventoryTitle.Position = UDim2.new(0, 0, 0, 0)
carti154.inventoryTitle.BackgroundTransparency = 1
carti154.inventoryTitle.Text = 'Inventory'
carti154.inventoryTitle.Font = Enum.Font.FredokaOne
carti154.inventoryTitle.TextSize = 15
carti154.inventoryTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
carti154.inventoryTitle.TextXAlignment = Enum.TextXAlignment.Left
carti154.inventoryTitle.Parent = carti154.inventoryTab

carti154.inventorySpawnerButton = Instance.new('TextButton')
carti154.inventorySpawnerButton.Size = UDim2.new(1, 0, 0, 30)
carti154.inventorySpawnerButton.Position = UDim2.new(0, 0, 0, 32)
carti154.inventorySpawnerButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
carti154.inventorySpawnerButton.BackgroundTransparency = 0.15
carti154.inventorySpawnerButton.BorderSizePixel = 0
carti154.inventorySpawnerButton.Text = 'SPAWNER GUI'
carti154.inventorySpawnerButton.Font = Enum.Font.FredokaOne
carti154.inventorySpawnerButton.TextSize = 12
carti154.inventorySpawnerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventorySpawnerButton.Parent = carti154.inventoryTab
carti154.inventorySpawnerCorner = Instance.new('UICorner')
carti154.inventorySpawnerCorner.CornerRadius = UDim.new(0, 4)
carti154.inventorySpawnerCorner.Parent = carti154.inventorySpawnerButton

carti154.inventorySpawnerStroke = Instance.new('UIStroke')
carti154.inventorySpawnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
carti154.inventorySpawnerStroke.Color = Color3.fromRGB(190, 120, 255)
carti154.inventorySpawnerStroke.Thickness = 1
carti154.inventorySpawnerStroke.Transparency = 0.25
carti154.inventorySpawnerStroke.Parent = carti154.inventorySpawnerButton

carti154.inventorySpawnHighTierButton = Instance.new('TextButton')
carti154.inventorySpawnHighTierButton.Size = UDim2.new(1, 0, 0, 30)
carti154.inventorySpawnHighTierButton.Position = UDim2.new(0, 0, 0, 72)
carti154.inventorySpawnHighTierButton.BackgroundColor3 = Color3.fromRGB(125, 76, 180)
carti154.inventorySpawnHighTierButton.BackgroundTransparency = 0.15
carti154.inventorySpawnHighTierButton.BorderSizePixel = 0
carti154.inventorySpawnHighTierButton.Text = 'SPAWN ALL HIGH TIER PETS'
carti154.inventorySpawnHighTierButton.Font = Enum.Font.FredokaOne
carti154.inventorySpawnHighTierButton.TextSize = 11
carti154.inventorySpawnHighTierButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventorySpawnHighTierButton.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventorySpawnHighTierButton).CornerRadius = UDim.new(0, 4)

carti154.inventoryClearPetsButton = Instance.new('TextButton')
carti154.inventoryClearPetsButton.Size = UDim2.new(1, 0, 0, 30)
carti154.inventoryClearPetsButton.Position = UDim2.new(0, 0, 0, 108)
carti154.inventoryClearPetsButton.BackgroundColor3 = Color3.fromRGB(145, 58, 82)
carti154.inventoryClearPetsButton.BackgroundTransparency = 0.15
carti154.inventoryClearPetsButton.BorderSizePixel = 0
carti154.inventoryClearPetsButton.Text = 'CLEAR ALL PETS'
carti154.inventoryClearPetsButton.Font = Enum.Font.FredokaOne
carti154.inventoryClearPetsButton.TextSize = 11
carti154.inventoryClearPetsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventoryClearPetsButton.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventoryClearPetsButton).CornerRadius = UDim.new(0, 4)

carti154.inventoryRenameBox = Instance.new('TextBox')
carti154.inventoryRenameBox.Size = UDim2.new(0.7, -4, 0, 30)
carti154.inventoryRenameBox.Position = UDim2.new(0, 0, 0, 148)
carti154.inventoryRenameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
carti154.inventoryRenameBox.BorderSizePixel = 0
carti154.inventoryRenameBox.ClearTextOnFocus = false
carti154.inventoryRenameBox.PlaceholderText = 'Rename equipped pet...'
carti154.inventoryRenameBox.PlaceholderColor3 = Color3.fromRGB(165, 165, 185)
carti154.inventoryRenameBox.Text = ''
carti154.inventoryRenameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventoryRenameBox.Font = Enum.Font.Gotham
carti154.inventoryRenameBox.TextSize = 11
carti154.inventoryRenameBox.TextXAlignment = Enum.TextXAlignment.Left
carti154.inventoryRenameBox.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventoryRenameBox).CornerRadius = UDim.new(0, 4)

carti154.inventoryRenameButton = Instance.new('TextButton')
carti154.inventoryRenameButton.Size = UDim2.new(0.3, 0, 0, 30)
carti154.inventoryRenameButton.Position = UDim2.new(0.7, 0, 0, 148)
carti154.inventoryRenameButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
carti154.inventoryRenameButton.BorderSizePixel = 0
carti154.inventoryRenameButton.Text = 'RENAME'
carti154.inventoryRenameButton.Font = Enum.Font.FredokaOne
carti154.inventoryRenameButton.TextSize = 10
carti154.inventoryRenameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventoryRenameButton.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventoryRenameButton).CornerRadius = UDim.new(0, 4)

carti154.renameInventoryPet = function()
    if carti154.renameNativeLocalPet and carti154.renameNativeLocalPet(carti154.inventoryRenameBox.Text) then
        carti154.inventoryRenameBox.Text = ''
        carti154.inventoryRenameBox.PlaceholderText = 'Pet renamed'
    else
        carti154.inventoryRenameBox.PlaceholderText = 'Equip a spawned pet first'
    end
    task.delay(1.5, function()
        if carti154.inventoryRenameBox.Parent then
            carti154.inventoryRenameBox.PlaceholderText = 'Rename equipped pet...'
        end
    end)
end
carti154.inventoryRenameButton.MouseButton1Click:Connect(carti154.renameInventoryPet)
carti154.inventoryRenameBox.FocusLost:Connect(function(carti415)
    if carti415 then carti154.renameInventoryPet() end
end)

carti154.organizeSpawnedPets = function(carti415)
    local carti416 = {
        common = 1,
        uncommon = 2,
        rare = 3,
        ultra_rare = 4,
        legendary = 5,
    }
    local carti417 = {}
    local carti418 = carti23.get('inventory')
    for _, carti419 in pairs(carti418 and carti418.pets or {}) do
        if carti419 and carti419.carti_hub_local_pet then
            local carti420 = carti26.pets and carti26.pets[carti419.kind]
            local carti421 = carti420 and carti415 and carti415[carti420.name]
            local carti422 = carti421 and tonumber(carti421['rvalue - nopotion'] or carti421.rvalue) or 0
            table.insert(carti417, {
                pet = carti419,
                rarity = carti416[(carti420 and carti420.rarity) or 'common'] or 0,
                value = carti422,
                name = (carti420 and carti420.name) or tostring(carti419.kind),
            })
        end
    end
    table.sort(carti417, function(carti423, carti424)
        if carti423.rarity ~= carti424.rarity then
            return carti423.rarity > carti424.rarity
        end
        if carti423.value ~= carti424.value then
            return carti423.value > carti424.value
        end
        return carti423.name < carti424.name
    end)
    local carti423 = os.time() * 1000
    carti161('inventory', function(carti424)
        for carti425, carti426 in ipairs(carti417) do
            carti426.pet.newness_order = carti423 + carti426.rarity * 100000 + (#carti417 - carti425)
        end
        return carti424
    end)
end

task.defer(function()
    carti154.organizeSpawnedPets(carti53)
end)

carti154.spawnAllHighTierPets = function()
    if carti154.inventoryHighTierSpawnBusy then
        return
    end
    carti154.inventoryHighTierSpawnBusy = true
    carti154.inventorySpawnHighTierButton.Text = 'CHECKING VALUES...'

    task.spawn(function()
        local carti415 = carti47()
        local carti416 = {}
        for _, carti417 in pairs(carti415 or {}) do
            if type(carti417) == 'table' and carti417.name then
                carti416[carti417.name] = carti417
            end
        end

        local carti417 = {}
        for carti418, carti419 in pairs(carti26.pets or {}) do
            local carti420 = carti419.name or carti45[carti418]
            local carti421 = carti420 and carti416[carti420]
            local carti422 = carti421 and tonumber(carti421['rvalue - nopotion'] or carti421.rvalue) or 0
            if carti422 > 50 then
                table.insert(carti417, { id = carti418, value = carti422 })
            end
        end
        table.sort(carti417, function(carti423, carti424)
            return carti423.value > carti424.value
        end)

        if #carti417 > 0 then
            carti161('inventory', function(carti423)
                carti423.pets = carti423.pets or {}
                for carti424, carti425 in ipairs(carti417) do
                    local carti426 = '2_' .. carti7:GenerateGUID(false)
                    carti423.pets[carti426] = {
                        unique = carti426,
                        category = 'pets',
                        carti_hub_local_pet = true,
                        id = carti425.id,
                        kind = carti425.id,
                        properties = {
                            rideable = false,
                            flyable = false,
                            neon = false,
                            mega_neon = false,
                            pet_trick_level = 0,
                            friendship_level = 0,
                            age = 1,
                        },
                        newness_order = os.time() * 1000,
                    }
                end
                return carti423
            end)
            carti154.organizeSpawnedPets(carti416)
        end

        carti154.inventoryHighTierSpawnBusy = false
        carti154.inventorySpawnHighTierButton.Text = #carti417 > 0
            and ('SPAWNED ' .. tostring(#carti417) .. ' HIGH TIER PETS')
            or 'NO HIGH TIER PETS FOUND'
        task.delay(1.6, function()
            if carti154.inventorySpawnHighTierButton.Parent then
                carti154.inventorySpawnHighTierButton.Text = 'SPAWN ALL HIGH TIER PETS'
            end
        end)
    end)
end

carti154.clearAllSpawnedPets = function()
    if carti154.clearLocalPetEquipState then
        carti154.clearLocalPetEquipState()
    end
    local carti415 = 0
    carti161('inventory', function(carti416)
        carti416.pets = carti416.pets or {}
        for carti417, carti418 in pairs(carti416.pets) do
            if carti418 and carti418.carti_hub_local_pet then
                carti416.pets[carti417] = nil
                carti415 += 1
            end
        end
        return carti416
    end)
    carti154.inventoryClearPetsButton.Text = carti415 > 0 and ('CLEARED ' .. tostring(carti415) .. ' PETS') or 'NO SPAWNED PETS'
    task.delay(1.4, function()
        if carti154.inventoryClearPetsButton.Parent then
            carti154.inventoryClearPetsButton.Text = 'CLEAR ALL PETS'
        end
    end)
end

carti154.inventorySpawnHighTierButton.MouseButton1Click:Connect(carti154.spawnAllHighTierPets)
carti154.inventoryClearPetsButton.MouseButton1Click:Connect(carti154.clearAllSpawnedPets)

carti154.inventoryToySpawnerTitle = Instance.new('TextLabel')
carti154.inventoryToySpawnerTitle.Size = UDim2.new(1, 0, 0, 20)
carti154.inventoryToySpawnerTitle.Position = UDim2.new(0, 0, 0, 188)
carti154.inventoryToySpawnerTitle.BackgroundTransparency = 1
carti154.inventoryToySpawnerTitle.Text = 'Toy Spawner'
carti154.inventoryToySpawnerTitle.Font = Enum.Font.FredokaOne
carti154.inventoryToySpawnerTitle.TextSize = 11
carti154.inventoryToySpawnerTitle.TextColor3 = Color3.fromRGB(225, 190, 255)
carti154.inventoryToySpawnerTitle.TextXAlignment = Enum.TextXAlignment.Left
carti154.inventoryToySpawnerTitle.Parent = carti154.inventoryTab

carti154.inventoryTopValueToys = {
    { id = 'candy_cannon', value = 138 },
    { id = 'flying_broomstick', value = 66 },
    { id = 'tombstone', value = 36 },
    { id = 'antler_chew_toy', value = 14 },
    { id = 'pumpkin_toy', value = 12 },
}

carti154.spawnToyById = function(carti415)
    local carti416 = carti26.toys and carti26.toys[carti415]
    if not carti416 then
        return false
    end
    local carti417 = '2_' .. carti7:GenerateGUID(false)
    carti161('inventory', function(carti418)
        carti418.toys = carti418.toys or {}
        carti418.toys[carti417] = {
            unique = carti417,
            category = 'toys',
            id = carti415,
            kind = carti415,
            properties = {},
            newness_order = os.time() * 1000,
        }
        return carti418
    end)
    return true
end

carti154.inventoryToySearchBox = Instance.new('TextBox')
carti154.inventoryToySearchBox.Size = UDim2.new(0.7, -4, 0, 26)
carti154.inventoryToySearchBox.Position = UDim2.new(0, 0, 0, 212)
carti154.inventoryToySearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
carti154.inventoryToySearchBox.BorderSizePixel = 0
carti154.inventoryToySearchBox.ClearTextOnFocus = false
carti154.inventoryToySearchBox.PlaceholderText = 'Spawn toy by name...'
carti154.inventoryToySearchBox.PlaceholderColor3 = Color3.fromRGB(165, 165, 185)
carti154.inventoryToySearchBox.Text = ''
carti154.inventoryToySearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventoryToySearchBox.Font = Enum.Font.Gotham
carti154.inventoryToySearchBox.TextSize = 10
carti154.inventoryToySearchBox.TextXAlignment = Enum.TextXAlignment.Left
carti154.inventoryToySearchBox.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventoryToySearchBox).CornerRadius = UDim.new(0, 4)

carti154.inventoryToySpawnButton = Instance.new('TextButton')
carti154.inventoryToySpawnButton.Size = UDim2.new(0.3, 0, 0, 26)
carti154.inventoryToySpawnButton.Position = UDim2.new(0.7, 0, 0, 212)
carti154.inventoryToySpawnButton.BackgroundColor3 = Color3.fromRGB(112, 62, 168)
carti154.inventoryToySpawnButton.BorderSizePixel = 0
carti154.inventoryToySpawnButton.Text = 'SPAWN'
carti154.inventoryToySpawnButton.Font = Enum.Font.FredokaOne
carti154.inventoryToySpawnButton.TextSize = 10
carti154.inventoryToySpawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carti154.inventoryToySpawnButton.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventoryToySpawnButton).CornerRadius = UDim.new(0, 4)

carti154.spawnToyByName = function()
    local carti415 = carti154.inventoryToySearchBox.Text:lower():gsub('^%s+', ''):gsub('%s+$', '')
    if carti415 == '' then
        return false
    end
    local carti416 = nil
    for carti417, carti418 in pairs(carti26.toys or {}) do
        local carti419 = tostring(carti418.name or carti417):lower()
        if carti419 == carti415 then
            carti416 = carti417
            break
        end
        if not carti416 and carti419:find(carti415, 1, true) then
            carti416 = carti417
        end
    end
    if carti416 and carti154.spawnToyById(carti416) then
        carti154.inventoryToySearchBox.Text = ''
        carti154.inventoryToySearchBox.PlaceholderText = 'Toy spawned'
        task.delay(1, function()
            if carti154.inventoryToySearchBox.Parent then
                carti154.inventoryToySearchBox.PlaceholderText = 'Spawn toy by name...'
            end
        end)
        return true
    end
    carti154.inventoryToySearchBox.PlaceholderText = 'Toy not found'
    task.delay(1, function()
        if carti154.inventoryToySearchBox.Parent then
            carti154.inventoryToySearchBox.PlaceholderText = 'Spawn toy by name...'
        end
    end)
    return false
end

carti154.inventoryToySpawnButton.MouseButton1Click:Connect(carti154.spawnToyByName)
carti154.inventoryToySearchBox.FocusLost:Connect(function(carti415)
    if carti415 then carti154.spawnToyByName() end
end)

carti154.inventoryToySpawnerButtons = {}
for carti415, carti416 in ipairs(carti154.inventoryTopValueToys) do
    local carti417 = carti26.toys and carti26.toys[carti416.id]
    if carti417 then
        local carti418 = Instance.new('TextButton')
        carti418.Size = UDim2.new(1, -27, 0, 25)
        carti418.Position = UDim2.new(0, 27, 0, 244 + (carti415 - 1) * 27)
        local carti419 = ({
            legendary = Color3.fromRGB(144, 104, 42),
            ultra_rare = Color3.fromRGB(83, 95, 164),
            rare = Color3.fromRGB(48, 105, 171),
            uncommon = Color3.fromRGB(56, 128, 79),
            common = Color3.fromRGB(82, 82, 98),
        })[carti417.rarity or 'common'] or Color3.fromRGB(67, 47, 98)
        carti418.BackgroundColor3 = carti419
        carti418.BackgroundTransparency = 0.12
        carti418.BorderSizePixel = 0
        carti418.Text = tostring(carti417.name or carti416.id)
        carti418.Font = Enum.Font.GothamBold
        carti418.TextSize = 10
        carti418.TextColor3 = Color3.fromRGB(245, 240, 255)
        carti418.TextXAlignment = Enum.TextXAlignment.Left
        carti418.Parent = carti154.inventoryTab
        Instance.new('UICorner', carti418).CornerRadius = UDim.new(0, 4)

        local carti420 = Instance.new('ImageLabel')
        carti420.Size = UDim2.new(0, 25, 0, 25)
        carti420.Position = UDim2.new(0, 0, 0, 244 + (carti415 - 1) * 27)
        carti420.BackgroundColor3 = carti419
        carti420.BackgroundTransparency = 0.12
        carti420.BorderSizePixel = 0
        carti420.Image = tostring(carti417.image or '')
        carti420.ScaleType = Enum.ScaleType.Fit
        carti420.ZIndex = carti418.ZIndex
        carti420.Parent = carti154.inventoryTab
        Instance.new('UICorner', carti420).CornerRadius = UDim.new(0, 4)

        local carti421 = Instance.new('UIPadding')
        carti421.PaddingLeft = UDim.new(0, 7)
        carti421.Parent = carti418
        local carti422 = Instance.new('UIStroke')
        carti422.Color = carti419:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
        carti422.Transparency = 0.18
        carti422.Thickness = 1
        carti422.Parent = carti418
        carti154.inventoryToySpawnerButtons[carti416.id] = carti418

        carti418.MouseButton1Click:Connect(function()
            if carti154.spawnToyById(carti416.id) then
                local carti423 = carti418.Text
                carti418.Text = 'SPAWNED ' .. tostring(carti417.name or carti416.id)
                task.delay(0.9, function()
                    if carti418.Parent then
                        carti418.Text = carti423
                    end
                end)
            end
        end)
    end
end

carti154.inventorySpawnTopToysButton = Instance.new('TextButton')
carti154.inventorySpawnTopToysButton.Name = 'SpawnTopToysButton'
carti154.inventorySpawnTopToysButton.Size = UDim2.new(1, 0, 0, 30)
carti154.inventorySpawnTopToysButton.Position = UDim2.new(0, 0, 0, 384)
carti154.inventorySpawnTopToysButton.BackgroundColor3 = Color3.fromRGB(118, 67, 180)
carti154.inventorySpawnTopToysButton.BorderSizePixel = 0
carti154.inventorySpawnTopToysButton.Text = 'SPAWN ALL HIGH LEVEL TOYS (5X EACH)'
carti154.inventorySpawnTopToysButton.TextColor3 = Color3.fromRGB(255, 245, 255)
carti154.inventorySpawnTopToysButton.Font = Enum.Font.GothamBold
carti154.inventorySpawnTopToysButton.TextSize = 10
carti154.inventorySpawnTopToysButton.Parent = carti154.inventoryTab
Instance.new('UICorner', carti154.inventorySpawnTopToysButton).CornerRadius = UDim.new(0, 5)

carti154.inventorySpawnTopToysButton.MouseButton1Click:Connect(function()
    local carti415 = 0
    for _, carti416 in ipairs(carti154.inventoryTopValueToys) do
        for _ = 1, 5 do
            if carti154.spawnToyById(carti416.id) then
                carti415 += 1
            end
        end
    end

    local carti417 = carti154.inventorySpawnTopToysButton.Text
    carti154.inventorySpawnTopToysButton.Text = 'SPAWNED ' .. tostring(carti415) .. ' TOYS'
    task.delay(1.2, function()
        if carti154.inventorySpawnTopToysButton.Parent then
            carti154.inventorySpawnTopToysButton.Text = carti417
        end
    end)
end)

carti154.openInventorySpawner = function()
    if carti154.inventorySpawnerDragConnection then
        carti154.inventorySpawnerDragConnection:Disconnect()
        carti154.inventorySpawnerDragConnection = nil
    end
    if carti154.inventorySpawnerGui and carti154.inventorySpawnerGui.Parent then
        carti154.inventorySpawnerGui:Destroy()
    end

    local carti416 = Instance.new('ScreenGui')
    carti416.Name = 'CartiHubPetSpawner'
    carti416.ResetOnSpawn = false
    carti416.DisplayOrder = 20
    carti416.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    carti416.Parent = carti2.LocalPlayer:WaitForChild('PlayerGui')
    carti154.inventorySpawnerGui = carti416

    local carti417 = Instance.new('Frame')
    carti417.Name = 'Window'
    carti417.Size = UDim2.new(0, 340, 0, 530)
    carti417.Position = UDim2.new(0.5, -170, 0.5, -265)
    carti417.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    carti417.BorderSizePixel = 0
    carti417.Active = true
    carti417.Draggable = false
    carti417.Parent = carti416
    local carti418 = Instance.new('UICorner')
    carti418.CornerRadius = UDim.new(0, 6)
    carti418.Parent = carti417
    local carti419 = Instance.new('UIStroke')
    carti419.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti419.Color = Color3.fromRGB(150, 95, 230)
    carti419.Thickness = 1.5
    carti419.Transparency = 0.15
    carti419.Parent = carti417

    local carti420 = Instance.new('TextLabel')
    carti420.Size = UDim2.new(1, -46, 0, 34)
    carti420.Position = UDim2.new(0, 12, 0, 4)
    carti420.BackgroundTransparency = 1
    carti420.Text = 'Pet Spawner'
    carti420.Font = Enum.Font.FredokaOne
    carti420.TextSize = 17
    carti420.TextColor3 = Color3.fromRGB(245, 240, 255)
    carti420.TextXAlignment = Enum.TextXAlignment.Left
    carti420.Active = true
    carti420.Parent = carti417

    local carti440 = false
    local carti441 = nil
    local carti442 = nil
    local carti443 = nil
    carti420.InputBegan:Connect(function(carti444)
        if carti444.UserInputType == Enum.UserInputType.MouseButton1 or carti444.UserInputType == Enum.UserInputType.Touch then
            carti440 = true
            carti442 = carti444.Position
            carti443 = carti417.Position
            carti444.Changed:Connect(function()
                if carti444.UserInputState == Enum.UserInputState.End then carti440 = false end
            end)
        end
    end)
    carti420.InputChanged:Connect(function(carti445)
        if carti445.UserInputType == Enum.UserInputType.MouseMovement or carti445.UserInputType == Enum.UserInputType.Touch then
            carti441 = carti445
        end
    end)
    carti154.inventorySpawnerDragConnection = carti5.InputChanged:Connect(function(carti446)
        if carti446 == carti441 and carti440 then
            local carti447 = carti446.Position - carti442
            carti417.Position = UDim2.new(carti443.X.Scale, carti443.X.Offset + carti447.X, carti443.Y.Scale, carti443.Y.Offset + carti447.Y)
        end
    end)

    local carti421 = Instance.new('TextButton')
    carti421.Size = UDim2.new(0, 30, 0, 30)
    carti421.Position = UDim2.new(1, -38, 0, 6)
    carti421.BackgroundTransparency = 1
    carti421.BorderSizePixel = 0
    carti421.Text = 'X'
    carti421.Font = Enum.Font.GothamBold
    carti421.TextSize = 16
    carti421.TextColor3 = Color3.fromRGB(220, 190, 255)
    carti421.Parent = carti417
    carti421.MouseButton1Click:Connect(function()
        if carti154.inventorySpawnerDragConnection then
            carti154.inventorySpawnerDragConnection:Disconnect()
            carti154.inventorySpawnerDragConnection = nil
        end
        carti416:Destroy()
    end)

    local carti422 = Instance.new('TextBox')
    carti422.Size = UDim2.new(1, -24, 0, 30)
    carti422.Position = UDim2.new(0, 12, 0, 42)
    carti422.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    carti422.BorderSizePixel = 0
    carti422.ClearTextOnFocus = false
    carti422.PlaceholderText = 'Search pets...'
    carti422.PlaceholderColor3 = Color3.fromRGB(165, 165, 185)
    carti422.Text = ''
    carti422.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti422.Font = Enum.Font.Gotham
    carti422.TextSize = 12
    carti422.TextXAlignment = Enum.TextXAlignment.Left
    carti422.Parent = carti417
    local carti423 = Instance.new('UICorner')
    carti423.CornerRadius = UDim.new(0, 4)
    carti423.Parent = carti422

    local carti424 = Instance.new('ScrollingFrame')
    carti424.Size = UDim2.new(1, -24, 1, -232)
    carti424.Position = UDim2.new(0, 12, 0, 80)
    carti424.BackgroundColor3 = Color3.fromRGB(23, 23, 32)
    carti424.BackgroundTransparency = 0.2
    carti424.BorderSizePixel = 0
    carti424.ScrollBarThickness = 4
    carti424.ScrollBarImageColor3 = Color3.fromRGB(150, 95, 230)
    carti424.ScrollBarImageTransparency = 0.25
    carti424.CanvasSize = UDim2.new(0, 0, 0, 0)
    carti424.Parent = carti417
    local carti425 = Instance.new('UICorner')
    carti425.CornerRadius = UDim.new(0, 4)
    carti425.Parent = carti424
    local carti426 = Instance.new('UIGridLayout')
    carti426.SortOrder = Enum.SortOrder.LayoutOrder
    carti426.CellSize = UDim2.fromOffset(73, 104)
    carti426.CellPadding = UDim2.fromOffset(4, 4)
    carti426.Parent = carti424
    local carti427 = Instance.new('UIPadding')
    carti427.PaddingTop = UDim.new(0, 4)
    carti427.PaddingBottom = UDim.new(0, 4)
    carti427.PaddingLeft = UDim.new(0, 4)
    carti427.PaddingRight = UDim.new(0, 4)
    carti427.Parent = carti424

    carti154.inventorySpawnerAmount = 1
    local carti463 = Instance.new('Frame')
    carti463.Size = UDim2.new(1, -24, 0, 30)
    carti463.Position = UDim2.new(0, 12, 1, -76)
    carti463.BackgroundTransparency = 1
    carti463.Parent = carti417
    carti154.inventorySpawnerAmountLabel = nil
    carti154.refreshInventorySpawnerAmount = function()
        if carti154.inventorySpawnerAmountLabel then
            carti154.inventorySpawnerAmountLabel.Text = tostring(carti154.inventorySpawnerAmount)
        end
    end

    for carti464, carti465 in ipairs({ -10, -1, 0, 1, 10 }) do
        local carti466 = carti465 == 0 and Instance.new('TextLabel') or Instance.new('TextButton')
        carti466.Size = UDim2.new(0.185, 0, 1, 0)
        carti466.Position = UDim2.new((carti464 - 1) * 0.20375, 0, 0, 0)
        carti466.BackgroundColor3 = carti465 == 0 and Color3.fromRGB(76, 54, 112) or Color3.fromRGB(48, 48, 62)
        carti466.BackgroundTransparency = 0
        carti466.BorderSizePixel = 0
        carti466.Text = carti465 == 0 and '1' or (carti465 > 0 and '+' .. tostring(carti465) or tostring(carti465))
        carti466.Font = Enum.Font.FredokaOne
        carti466.TextSize = carti465 == 0 and 15 or 12
        carti466.TextColor3 = Color3.fromRGB(255, 255, 255)
        carti466.Parent = carti463
        local carti467 = Instance.new('UICorner')
        carti467.CornerRadius = UDim.new(0, 4)
        carti467.Parent = carti466

        if carti465 == 0 then
            carti154.inventorySpawnerAmountLabel = carti466
        else
            carti466.MouseButton1Click:Connect(function()
                carti154.inventorySpawnerAmount = math.clamp(carti154.inventorySpawnerAmount + carti465, 1, 999)
                carti154.refreshInventorySpawnerAmount()
            end)
        end
    end

    local carti490 = {
        age_names = { 'Newborn', 'Junior', 'Pre-Teen', 'Teen', 'Post-Teen', 'Full Grown' },
        neon_age_names = { 'Reborn', 'Twinkle', 'Sparkle', 'Flare', 'Sunshine', 'Luminous' },
    }
    pcall(function()
        carti490 = require(carti3.ClientDB.PetProgressionDB)
    end)
    carti154.inventorySpawnerAgeIndex = 1
    carti154.inventorySpawnerAgeButtons = {}
    local carti491 = Instance.new('Frame')
    carti491.Size = UDim2.new(1, -24, 0, 30)
    carti491.Position = UDim2.new(0, 12, 1, -116)
    carti491.BackgroundTransparency = 1
    carti491.Parent = carti417
    carti154.refreshInventorySpawnerAge = function()
        local carti492 = (carti154.inventorySpawnerFlags.M or carti154.inventorySpawnerFlags.N)
            and carti490.neon_age_names
            or carti490.age_names
        for carti493, carti494 in ipairs(carti154.inventorySpawnerAgeButtons) do
            local carti495 = carti493 == carti154.inventorySpawnerAgeIndex
            carti494.Text = carti492[carti493] or ('Age ' .. tostring(carti493))
            carti494.BackgroundColor3 = carti495 and Color3.fromRGB(120, 72, 175) or Color3.fromRGB(48, 48, 62)
            carti494.TextColor3 = carti495 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(195, 195, 215)
        end
    end
    for carti492 = 1, 6 do
        local carti493 = Instance.new('TextButton')
        carti493.Size = UDim2.new(0.158, 0, 1, 0)
        carti493.Position = UDim2.new((carti492 - 1) * 0.168, 0, 0, 0)
        carti493.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
        carti493.BorderSizePixel = 0
        carti493.Font = Enum.Font.GothamBold
        carti493.TextSize = 8
        carti493.TextWrapped = true
        carti493.TextColor3 = Color3.fromRGB(195, 195, 215)
        carti493.Parent = carti491
        local carti494 = Instance.new('UICorner')
        carti494.CornerRadius = UDim.new(0, 4)
        carti494.Parent = carti493
        carti154.inventorySpawnerAgeButtons[carti492] = carti493
        carti493.MouseButton1Click:Connect(function()
            carti154.inventorySpawnerAgeIndex = carti492
            carti154.refreshInventorySpawnerAge()
        end)
    end

    carti154.inventorySpawnerFlags = { N = false, F = false, R = false, M = false }
    carti154.inventorySpawnerFlagButtons = {}
    local carti454 = Instance.new('Frame')
    carti454.Size = UDim2.new(1, -24, 0, 32)
    carti454.Position = UDim2.new(0, 12, 1, -40)
    carti454.BackgroundTransparency = 1
    carti454.Parent = carti417

    carti154.refreshInventorySpawnerFlags = function()
        for carti455, carti456 in pairs(carti154.inventorySpawnerFlagButtons) do
            local carti457 = carti154.inventorySpawnerFlags[carti455]
            carti456.BackgroundColor3 = carti457 and Color3.fromRGB(120, 72, 175) or Color3.fromRGB(48, 48, 62)
            carti456.TextColor3 = carti457 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(195, 195, 215)
        end
        if carti154.refreshInventorySpawnerAge then
            carti154.refreshInventorySpawnerAge()
        end
    end

    for carti458, carti459 in ipairs({ 'N', 'F', 'R', 'M' }) do
        local carti460 = Instance.new('TextButton')
        carti460.Size = UDim2.new(0.235, 0, 1, 0)
        carti460.Position = UDim2.new((carti458 - 1) * 0.255, 0, 0, 0)
        carti460.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
        carti460.BorderSizePixel = 0
        carti460.Text = carti459
        carti460.Font = Enum.Font.FredokaOne
        carti460.TextSize = 14
        carti460.TextColor3 = Color3.fromRGB(195, 195, 215)
        carti460.Parent = carti454
        local carti461 = Instance.new('UICorner')
        carti461.CornerRadius = UDim.new(0, 4)
        carti461.Parent = carti460
        local carti462 = Instance.new('UIStroke')
        carti462.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        carti462.Color = carti459 == 'N' and Color3.fromRGB(175, 95, 255)
            or carti459 == 'F' and Color3.fromRGB(70, 175, 255)
            or carti459 == 'R' and Color3.fromRGB(255, 100, 175)
            or Color3.fromRGB(255, 185, 50)
        carti462.Thickness = 1
        carti462.Transparency = 0.2
        carti462.Parent = carti460
        carti154.inventorySpawnerFlagButtons[carti459] = carti460

        carti460.MouseButton1Click:Connect(function()
            if carti459 == 'N' and carti154.inventorySpawnerFlags.M then
                carti154.inventorySpawnerFlags.M = false
            elseif carti459 == 'M' and carti154.inventorySpawnerFlags.N then
                carti154.inventorySpawnerFlags.N = false
            end
            carti154.inventorySpawnerFlags[carti459] = not carti154.inventorySpawnerFlags[carti459]
            carti154.refreshInventorySpawnerFlags()
        end)
    end
    carti154.refreshInventorySpawnerFlags()
    carti154.refreshInventorySpawnerAge()

    local carti428 = {}
    local carti429 = {
        legendary = 1,
        ultra_rare = 2,
        rare = 3,
        uncommon = 4,
        common = 5,
    }
    for carti430, carti431 in pairs(carti26.pets or {}) do
        table.insert(carti428, {
            id = carti430,
            name = tostring(carti431.name or carti430),
            image = tostring(carti431.image or ''),
            rarity = tostring(carti431.rarity or ''):lower(),
            value = carti55(carti430, {
                flyable = false,
                rideable = false,
                neon = false,
                mega_neon = false,
            }),
        })
    end
    table.sort(carti428, function(carti432, carti433)
        local carti434 = carti429[carti432.rarity] or 99
        local carti435 = carti429[carti433.rarity] or 99
        if carti432.value ~= carti433.value then return carti432.value > carti433.value end
        if carti434 == carti435 then return carti432.name:lower() < carti433.name:lower() end
        return carti434 < carti435
    end)

    for carti436, carti437 in ipairs(carti428) do
        local carti438 = Instance.new('ImageButton')
        carti438.Name = 'Pet_' .. tostring(carti437.id)
        carti438.BackgroundColor3 = Color3.fromRGB(54, 45, 76)
        carti438.BackgroundTransparency = 0.08
        carti438.BorderSizePixel = 0
        carti438.Image = ''
        carti438.AutoButtonColor = false
        carti438.LayoutOrder = carti436
        carti438:SetAttribute('PetName', carti437.name)
        carti438.Parent = carti424
        local carti439 = Instance.new('UICorner')
        carti439.CornerRadius = UDim.new(0, 5)
        carti439.Parent = carti438
        local carti448 = Instance.new('UIStroke')
        carti448.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        carti448.Color = carti437.rarity == 'legendary' and Color3.fromRGB(255, 185, 50)
            or carti437.rarity == 'ultra_rare' and Color3.fromRGB(255, 90, 110)
            or carti437.rarity == 'rare' and Color3.fromRGB(70, 165, 255)
            or carti437.rarity == 'uncommon' and Color3.fromRGB(100, 225, 125)
            or Color3.fromRGB(170, 170, 180)
        carti448.Thickness = 1
        carti448.Transparency = 0.2
        carti448.Parent = carti438

        local carti449 = Instance.new('ImageLabel')
        carti449.Size = UDim2.fromOffset(64, 64)
        carti449.Position = UDim2.new(0.5, -32, 0, 4)
        carti449.BackgroundTransparency = 1
        carti449.BorderSizePixel = 0
        carti449.Image = carti437.image
        carti449.ScaleType = Enum.ScaleType.Fit
        carti449.Parent = carti438

        local carti450 = Instance.new('TextLabel')
        carti450.Size = UDim2.new(1, -6, 0, 30)
        carti450.Position = UDim2.new(0, 3, 1, -33)
        carti450.BackgroundTransparency = 1
        carti450.Text = carti437.name
        carti450.Font = Enum.Font.GothamBold
        carti450.TextSize = 9
        carti450.TextColor3 = Color3.fromRGB(255, 255, 255)
        carti450.TextWrapped = true
        carti450.TextYAlignment = Enum.TextYAlignment.Center
        carti450.Parent = carti438

        carti438.MouseButton1Click:Connect(function()
            carti161('inventory', function(carti454)
                carti454.pets = carti454.pets or {}
                for carti455 = 1, carti154.inventorySpawnerAmount do
                    local carti456 = math.clamp(carti154.inventorySpawnerAgeIndex or 1, 1, 6)
                    if carti154.inventorySpawnerFlags.M then
                        carti154.inventorySpawnerMegaSequence = (carti154.inventorySpawnerMegaSequence or 0) + 1
                    end
                    local carti457 = '2_' .. carti7:GenerateGUID(false)
                    carti454.pets[carti457] = {
                        unique = carti457,
                        category = 'pets',
                        carti_hub_local_pet = true,
                        id = carti437.id,
                        kind = carti437.id,
                        properties = {
                            rideable = carti154.inventorySpawnerFlags.R,
                            flyable = carti154.inventorySpawnerFlags.F,
                            neon = carti154.inventorySpawnerFlags.N,
                            mega_neon = carti154.inventorySpawnerFlags.M,
                            pet_trick_level = 0,
                            friendship_level = 0,
                            xp = carti154.inventorySpawnerFlags.M
                                and (carti154.inventorySpawnerMegaSequence / 10000)
                                or 0,
                            age = carti456,
                        },
                        newness_order = carti154.inventorySpawnerFlags.M
                            and (os.time() * 1000 + carti154.inventorySpawnerMegaSequence)
                            or 0,
                    }
                end
                return carti454
            end)
        end)

        if carti436 % 50 == 0 then task.wait() end
    end

    local carti451 = function()
        carti424.CanvasSize = UDim2.new(0, 0, 0, carti426.AbsoluteContentSize.Y + 8)
    end
    carti426:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(carti451)
    carti451()
    carti422:GetPropertyChangedSignal('Text'):Connect(function()
        local carti452 = carti422.Text:lower()
        for _, carti453 in ipairs(carti424:GetChildren()) do
            if carti453:IsA('ImageButton') then
                carti453.Visible = carti452 == '' or carti453:GetAttribute('PetName'):lower():find(carti452, 1, true) ~= nil
            end
        end
        task.defer(carti451)
    end)
end

carti154.inventorySpawnerButton.MouseButton1Click:Connect(carti154.openInventorySpawner)

carti154.installLocalPetEquipFlow = function()
    carti154.clientToolManager = carti20('ClientToolManager')
    carti154.petEntityManager = carti20('PetEntityManager')
    carti154.charWrapperClient = carti20('CharWrapperClient')
    local carti453 = (getgenv and getgenv()) or _G
    local carti454 = carti453.CartiHubAdoptMeLocalPetHooks

    if carti454 and carti454.manager == carti154.clientToolManager then
        pcall(carti454.clear)
        if carti454.equip then
            carti154.clientToolManager.equip = carti454.equip
        end
        if carti454.unequip then
            carti154.clientToolManager.unequip = carti454.unequip
        end
        if carti454.backpackEquip then
            carti154.clientToolManager.backpack_equip = carti454.backpackEquip
        end
    elseif getupvalues then
        pcall(function()
            for _, carti455 in pairs(getupvalues(carti154.clientToolManager.equip)) do
                if type(carti455) == 'table'
                    and carti455.originalClientToolEquip
                    and carti455.originalClientToolUnequip then
                    if carti455.clearNativeLocalPetEntity then
                        carti455.clearNativeLocalPetEntity()
                    end
                    carti154.clientToolManager.equip = carti455.originalClientToolEquip
                    carti154.clientToolManager.unequip = carti455.originalClientToolUnequip
                    if carti455.originalClientToolBackpackEquip then
                        carti154.clientToolManager.backpack_equip = carti455.originalClientToolBackpackEquip
                    end
                    break
                end
            end
        end)
    end

    if carti454 and carti454.stopMountButton then
        pcall(function()
            carti22.apps.ExtraButtonsApp:unregister_button(carti454.stopMountButton)
        end)
    end

    carti154.originalClientToolEquip = carti154.clientToolManager.equip
    carti154.originalClientToolUnequip = carti154.clientToolManager.unequip
    carti154.originalClientToolBackpackEquip = carti154.clientToolManager.backpack_equip
    carti154.nativeLocalPetStopMountButton = carti22.apps.ExtraButtonsApp:register_button({
        priority = 4,
        text = 'Stop Ride',
        mouse_button1_click = function()
            if carti154.setNativeLocalPetRiding then
                carti154.setNativeLocalPetRiding(false)
            end
        end,
    })
    carti154.setNativeLocalPetStopMountButton = function(carti454)
        local carti455 = carti154.nativeLocalPetStopMountButton
        if not carti455 then
            return
        end
        if carti454 then
            pcall(function()
                carti455.instance.Face.TextLabel.Text = carti454 == 'PetBeingFlown' and 'Stop Fly' or 'Stop Ride'
                carti455:show()
            end)
        else
            pcall(function()
                carti455:hide()
            end)
        end
    end

    carti154.clearNativeLocalPetEntity = function()
        local carti454 = carti2.LocalPlayer.Character
        local carti455 = carti454 and carti454:FindFirstChild('HumanoidRootPart')
        if carti154.setNativeLocalPetStopMountButton then
            carti154.setNativeLocalPetStopMountButton(nil)
        end
        if carti154.nativeLocalPetRideConnection then
            pcall(function()
                carti154.nativeLocalPetRideConnection:Destroy()
            end)
            carti154.nativeLocalPetRideConnection = nil
        end
        if carti154.nativeLocalPetRideFollowConnection then
            carti154.nativeLocalPetRideFollowConnection:Disconnect()
            carti154.nativeLocalPetRideFollowConnection = nil
        end
        if carti154.nativeLocalPetRideTargetAttachment then
            pcall(function()
                carti154.nativeLocalPetRideTargetAttachment:Destroy()
            end)
            carti154.nativeLocalPetRideTargetAttachment = nil
        end
        local carti456 = carti454 and carti454:FindFirstChildOfClass('Humanoid')
        if carti456 then
            pcall(function() carti456.Sit = false end)
        end
        if carti154.nativeLocalPetRidePetHumanoid then
            pcall(function()
                carti154.nativeLocalPetRidePetHumanoid.AutoRotate = carti154.nativeLocalPetRideAutoRotate ~= false
            end)
            carti154.nativeLocalPetRidePetHumanoid = nil
            carti154.nativeLocalPetRideAutoRotate = nil
        end
        if carti154.nativeLocalPetRideAnimation then
            pcall(function()
                carti154.nativeLocalPetRideAnimation:Stop(0.1)
            end)
            carti154.nativeLocalPetRideAnimation = nil
        end
        if carti154.nativeLocalPetRideMountState then
            local carti456 = carti154.nativeLocalPetRideMountState
            if carti456.motor and carti456.motor.Parent then
                carti456.motor.Part1 = carti456.part1
                carti456.motor.C0 = carti456.c0
                carti456.motor.C1 = carti456.c1
                carti456.motor.Transform = carti456.transform
            end
            carti154.nativeLocalPetRideMountState = nil
        elseif carti154.nativeLocalPetRideWeld then
            pcall(function()
                carti154.nativeLocalPetRideWeld:Destroy()
            end)
        end
        if carti455 then
            local carti456 = carti455:FindFirstChild('CartiHubLocalPetRideMountMotor6D')
            if carti456 then carti456:Destroy() end
        end
        carti154.nativeLocalPetRideWeld = nil
        if carti154.nativeLocalPetFollowPosition then
            carti154.nativeLocalPetFollowPosition.Enabled = true
        end
        if carti154.nativeLocalPetFollowOrientation then
            carti154.nativeLocalPetFollowOrientation.Enabled = true
        end
        if carti154.nativeLocalPetMotionConnection then
            carti154.nativeLocalPetMotionConnection:Disconnect()
            carti154.nativeLocalPetMotionConnection = nil
        end
        for _, carti454 in ipairs(carti154.nativeLocalPetTracks or {}) do
            pcall(function()
                carti454:Stop(0.12)
            end)
        end
        carti154.nativeLocalPetTracks = nil
        if carti154.clearNativeLocalPetFlightWings then
            carti154.clearNativeLocalPetFlightWings()
        end
        if carti154.clearNativeLocalPetHeld then
            carti154.clearNativeLocalPetHeld()
        end
        if carti154.nativeLocalPetModel then
            if carti154.nativeLocalPetState then
                carti161('pet_state_managers', function(carti454)
                    for carti455 = #carti454, 1, -1 do
                        if carti454[carti455].char == carti154.nativeLocalPetModel then
                            table.remove(carti454, carti455)
                        end
                    end
                    return carti454
                end)
            end
            if carti154.nativeLocalPetWrapper then
                carti161('pet_char_wrappers', function(carti454)
                    for carti455 = #carti454, 1, -1 do
                        if carti454[carti455].char == carti154.nativeLocalPetModel then
                            table.remove(carti454, carti455)
                        end
                    end
                    return carti454
                end)
            end
            pcall(function()
                carti154.charWrapperClient.register_debug_wrapper(carti154.nativeLocalPetModel, nil)
            end)
            pcall(function()
                carti154.petEntityManager.remove_pet_entity_by_char(carti154.nativeLocalPetModel)
            end)
            pcall(function()
                carti154.nativeLocalPetModel:Destroy()
            end)
        end
        if carti154.nativeLocalPetFollowAttachment and carti154.nativeLocalPetFollowAttachment.Parent then
            carti154.nativeLocalPetFollowAttachment:Destroy()
        end
        carti154.nativeLocalPetModel = nil
        carti154.nativeLocalPetUnique = nil
        carti154.nativeLocalPetFollowAttachment = nil
        carti154.nativeLocalPetWrapper = nil
        carti154.nativeLocalPetState = nil
        carti154.nativeLocalPetFollowPosition = nil
        carti154.nativeLocalPetFollowOrientation = nil
        carti154.nativeLocalPetRideScale = nil
        carti154.nativeLocalPetMountStateId = nil
    end

    carti154.clearNativeLocalPetFlightWings = function()
        if carti154.nativeLocalPetFlightWingTrack then
            pcall(function()
                carti154.nativeLocalPetFlightWingTrack:Stop(0.12)
                carti154.nativeLocalPetFlightWingTrack:Destroy()
            end)
            carti154.nativeLocalPetFlightWingTrack = nil
        end
        if carti154.nativeLocalPetFlightWings then
            pcall(function()
                carti154.nativeLocalPetFlightWings:Destroy()
            end)
            carti154.nativeLocalPetFlightWings = nil
        end
    end

    carti154.attachNativeLocalPetFlightWings = function(carti454)
        carti154.clearNativeLocalPetFlightWings()

        local carti455 = carti154.nativeLocalPetModel
        local carti456 = carti154.nativeLocalPetWrapper
        local carti457 = carti456 and carti26.pets and carti26.pets[carti456.pet_id]
        if not carti455 or not carti457 or carti457.already_has_flying_wings then
            return false
        end

        local carti458 = carti455:FindFirstChild('WingsAttachment', true)
        local carti459 = carti3:FindFirstChild('Resources')
        local carti460 = carti459 and carti459:FindFirstChild('Effects')
        local carti461 = carti460 and carti460:FindFirstChild('DefaultWings')
        if not carti458 or not carti458:IsA('Attachment') or not carti461 then
            return false
        end

        local carti462 = carti461:Clone()
        carti462.Name = 'temp_wings_equipped'
        local carti463 = carti462:FindFirstChild('WingsAttachment', true)
        if not carti463 or not carti463:IsA('Attachment') then
            carti462:Destroy()
            return false
        end

        pcall(function()
            carti462:ScaleTo(carti455:GetScale())
        end)
        for _, carti464 in ipairs(carti462:GetDescendants()) do
            if carti464:IsA('BasePart') then
                carti464.Anchored = false
                carti464.CanCollide = false
                carti464.Massless = true
            end
        end

        local carti464 = Instance.new('RigidConstraint')
        carti464.Name = 'CartiHubLocalPetFlightWingConstraint'
        carti464.Attachment0 = carti458
        carti464.Attachment1 = carti463
        carti464.Parent = carti463.Parent
        carti462.Parent = carti455
        carti154.nativeLocalPetFlightWings = carti462

        local carti465 = carti462:FindFirstChildOfClass('AnimationController')
        local carti466 = carti465 and carti465:FindFirstChildOfClass('Animator')
        if carti466 then
            pcall(function()
                local carti467 = carti20('AnimationManager').get_track('PetFlyingWingFlap')
                local carti468 = carti466:LoadAnimation(carti467)
                carti468.Looped = true
                carti468:Play(0.12)
                carti154.nativeLocalPetFlightWingTrack = carti468
            end)
        end

        return true
    end

    carti154.clearNativeLocalPetHeld = function()
        if carti154.nativeLocalPetHoldMotor then
            pcall(function()
                carti154.nativeLocalPetHoldMotor:Destroy()
            end)
            carti154.nativeLocalPetHoldMotor = nil
        end
        if carti154.nativeLocalPetHoldSourceAttachment then
            pcall(function()
                carti154.nativeLocalPetHoldSourceAttachment:Destroy()
            end)
            carti154.nativeLocalPetHoldSourceAttachment = nil
        end
        if carti154.nativeLocalPetHoldTargetAttachment then
            pcall(function()
                carti154.nativeLocalPetHoldTargetAttachment:Destroy()
            end)
            carti154.nativeLocalPetHoldTargetAttachment = nil
        end
        if carti154.nativeLocalPetHoldTrack then
            pcall(function()
                carti154.nativeLocalPetHoldTrack:Stop(0.12)
                carti154.nativeLocalPetHoldTrack:Destroy()
            end)
            carti154.nativeLocalPetHoldTrack = nil
        end
        if carti154.nativeLocalPetHeldPetTrack then
            pcall(function()
                carti154.nativeLocalPetHeldPetTrack:Stop(0.12)
                carti154.nativeLocalPetHeldPetTrack:Destroy()
            end)
            carti154.nativeLocalPetHeldPetTrack = nil
        end
        if carti154.nativeLocalPetHeldHumanoid then
            pcall(function()
                carti154.nativeLocalPetHeldHumanoid.PlatformStand = false
                carti154.nativeLocalPetHeldHumanoid.AutoRotate = false
            end)
            carti154.nativeLocalPetHeldHumanoid = nil
        end
        if carti154.nativeLocalPetHeld then
            local carti454 = carti154.nativeLocalPetState
            if carti454 then
                carti454.states = {}
            end
            if carti154.nativeLocalPetFollowPosition then
                carti154.nativeLocalPetFollowPosition.Enabled = true
            end
            if carti154.nativeLocalPetFollowOrientation then
                carti154.nativeLocalPetFollowOrientation.Enabled = true
            end
        end
        carti154.nativeLocalPetHeld = nil
    end

    carti154.setNativeLocalPetHeld = function(carti454)
        if not carti454 then
            carti154.clearNativeLocalPetHeld()
            return true
        end

        if carti154.nativeLocalPetMountStateId and carti154.setNativeLocalPetRiding then
            carti154.setNativeLocalPetRiding(false)
        end
        carti154.clearNativeLocalPetHeld()

        local carti455 = carti154.nativeLocalPetModel
        local carti456 = carti2.LocalPlayer.Character
        local carti457 = carti455 and carti455:FindFirstChild('HumanoidRootPart')
        local carti458 = carti456 and (carti456:FindFirstChild('UpperTorso') or carti456:FindFirstChild('Torso'))
        if not carti455 or not carti457 or not carti458 then
            return false
        end

        local carti459 = carti154.nativeLocalPetWrapper
        local carti460 = carti459 and carti26.pets and carti26.pets[carti459.pet_id]
        local carti461 = (carti460 and carti460.hold_offset) or CFrame.new()

        if carti154.nativeLocalPetFollowPosition then
            carti154.nativeLocalPetFollowPosition.Enabled = false
        end
        if carti154.nativeLocalPetFollowOrientation then
            carti154.nativeLocalPetFollowOrientation.Enabled = false
        end
        if carti154.nativeLocalPetState then
            carti154.nativeLocalPetState.states = { { id = 'BabyBeingHeld' } }
        end

        local carti462 = carti455:FindFirstChildOfClass('Humanoid')
        if carti462 then
            carti462.AutoRotate = false
            carti462.PlatformStand = false
            carti154.nativeLocalPetHeldHumanoid = carti462
        end

        local carti463 = Instance.new('Attachment')
        carti463.Name = 'SourceAttachment'
        carti463.CFrame = CFrame.new(0, 0, -1) * carti461
        carti463.Parent = carti458
        local carti464 = Instance.new('Attachment')
        carti464.Name = 'TargetAttachment'
        carti464.Parent = carti457
        local carti465 = Instance.new('RigidConstraint')
        carti465.Name = 'StateConnection'
        carti465.Attachment0 = carti463
        carti465.Attachment1 = carti464
        carti465.Parent = carti455
        carti154.nativeLocalPetHoldSourceAttachment = carti463
        carti154.nativeLocalPetHoldTargetAttachment = carti464
        carti154.nativeLocalPetHoldMotor = carti465
        carti154.nativeLocalPetHeld = true

        local carti466 = carti456:FindFirstChildOfClass('Humanoid')
        local carti467 = carti466 and carti466:FindFirstChildOfClass('Animator')
        if carti467 then
            pcall(function()
                local carti468 = carti20('AnimationManager').get_track('HoldingBaby')
                local carti469 = carti467:LoadAnimation(carti468)
                carti469.Priority = Enum.AnimationPriority.Action
                carti469.Looped = true
                carti469:Play(0.12)
                carti154.nativeLocalPetHoldTrack = carti469
            end)
        end
        local carti470 = carti154.petEntityManager.get_pet_entity(carti455)
        if carti470 then
            carti470.move_state.is_moving = false
            carti470.speed_state.calculated_speed = 0
        end
        return true
    end

    carti154.setNativeLocalPetRiding = function(carti454, carti455)
        local carti476 = carti455
        local carti455 = carti154.nativeLocalPetModel
        local carti456 = carti154.nativeLocalPetState
        local carti457 = carti455 and carti455:FindFirstChild('HumanoidRootPart')
        local carti458 = carti2.LocalPlayer.Character
        local carti459 = carti458 and carti458:FindFirstChild('HumanoidRootPart')
        if not carti455 or not carti456 or not carti457 or not carti459 then
            return false
        end

        if not carti454 then
            carti456.states = {}
            carti154.nativeLocalPetMountStateId = nil
            carti154.setNativeLocalPetStopMountButton(nil)
            carti154.clearNativeLocalPetFlightWings()
            if carti154.nativeLocalPetRideConnection then
                carti154.nativeLocalPetRideConnection:Destroy()
                carti154.nativeLocalPetRideConnection = nil
            end
            if carti154.nativeLocalPetRideFollowConnection then
                carti154.nativeLocalPetRideFollowConnection:Disconnect()
                carti154.nativeLocalPetRideFollowConnection = nil
            end
            if carti154.nativeLocalPetRideTargetAttachment then
                carti154.nativeLocalPetRideTargetAttachment:Destroy()
                carti154.nativeLocalPetRideTargetAttachment = nil
            end
            local carti460 = carti458:FindFirstChildOfClass('Humanoid')
            if carti460 then
                pcall(function() carti460.Sit = false end)
            end
            if carti154.nativeLocalPetRidePetHumanoid then
                pcall(function()
                    carti154.nativeLocalPetRidePetHumanoid.AutoRotate = carti154.nativeLocalPetRideAutoRotate ~= false
                end)
                carti154.nativeLocalPetRidePetHumanoid = nil
                carti154.nativeLocalPetRideAutoRotate = nil
            end
            if carti154.nativeLocalPetRideAnimation then
                pcall(function()
                    carti154.nativeLocalPetRideAnimation:Stop(0.1)
                end)
                carti154.nativeLocalPetRideAnimation = nil
            end
            if carti154.nativeLocalPetRideMountState then
                local carti460 = carti154.nativeLocalPetRideMountState
                if carti460.motor and carti460.motor.Parent then
                    carti460.motor.Part1 = carti460.part1
                    carti460.motor.C0 = carti460.c0
                    carti460.motor.C1 = carti460.c1
                    carti460.motor.Transform = carti460.transform
                end
                carti154.nativeLocalPetRideMountState = nil
            elseif carti154.nativeLocalPetRideWeld then
                carti154.nativeLocalPetRideWeld:Destroy()
            end
            carti154.nativeLocalPetRideWeld = nil
            if carti154.nativeLocalPetRideScale then
                pcall(function()
                    carti455:ScaleTo(1)
                end)
                carti154.nativeLocalPetRideScale = nil
            end
            if carti154.nativeLocalPetFollowPosition then
                carti154.nativeLocalPetFollowPosition.Enabled = true
            end
            if carti154.nativeLocalPetFollowOrientation then
                carti154.nativeLocalPetFollowOrientation.Enabled = true
            end
            return true
        end

        carti154.clearNativeLocalPetHeld()

        carti456.states = { { id = carti476 or 'PetBeingRidden' } }
        carti154.nativeLocalPetMountStateId = carti476 or 'PetBeingRidden'
        carti154.setNativeLocalPetStopMountButton(carti154.nativeLocalPetMountStateId)
        local carti460 = carti455:FindFirstChildOfClass('Humanoid')
        if carti460 then
            carti154.nativeLocalPetRidePetHumanoid = carti460
            carti154.nativeLocalPetRideAutoRotate = carti460.AutoRotate
            carti460.AutoRotate = true
        end
        if carti154.nativeLocalPetFollowPosition then
            carti154.nativeLocalPetFollowPosition.Enabled = false
        end
        if carti154.nativeLocalPetFollowOrientation then
            carti154.nativeLocalPetFollowOrientation.Enabled = false
        end

        if carti154.nativeLocalPetRideWeld then
            carti154.nativeLocalPetRideWeld:Destroy()
        end

        local carti460 = carti26.pets and carti26.pets[carti154.nativeLocalPetWrapper.pet_id]
        local carti461 = (carti460 and carti460.max_ride_scale) or 2
        local carti462 = carti455:GetExtentsSize().Y
        pcall(function()
            carti455:ScaleTo(carti461)
        end)
        local carti463 = carti455:GetExtentsSize().Y
        if carti463 > carti462 then
            carti455:PivotTo(carti455:GetPivot() * CFrame.new(0, (carti463 - carti462) * 0.5, 0))
        end
        carti154.nativeLocalPetRideScale = carti461
        if carti476 == 'PetBeingFlown' then
            carti154.attachNativeLocalPetFlightWings()
        else
            carti154.clearNativeLocalPetFlightWings()
        end

        local carti464 = carti455:FindFirstChild('RidePosition', true)
        local carti465 = carti464 and carti464:FindFirstChild('SourceAttachment')
        local carti466 = CFrame.new()
        if not carti465 and carti464 and carti464:IsA('Attachment') then
            carti465 = carti464
            carti466 = CFrame.new(0, 1.09591794, 0)
        end
        if carti465 and carti465:IsA('Attachment') then
            local carti467 = Instance.new('Attachment')
            carti467.Name = 'CartiHubLocalPetRideTargetAttachment'
            carti467.Parent = carti459
            carti154.nativeLocalPetRideTargetAttachment = carti467
            carti459.CFrame = carti465.WorldCFrame * carti466
            carti154.nativeLocalPetRideFollowConnection = carti4.RenderStepped:Connect(function()
                if carti465.Parent and carti459.Parent then
                    local carti468 = carti465.WorldCFrame * carti466
                    if carti154.nativeLocalPetMountStateId == 'PetBeingFlown' then
                        local carti469 = carti457 and carti457.Parent
                            and Vector3.new(carti457.CFrame.LookVector.X, 0, carti457.CFrame.LookVector.Z)
                            or Vector3.new(carti468.LookVector.X, 0, carti468.LookVector.Z)
                        if carti469.Magnitude > 0.001 then
                            carti459.CFrame = CFrame.lookAt(carti468.Position, carti468.Position + carti469)
                        else
                            carti459.CFrame = CFrame.new(carti468.Position)
                        end
                    else
                        local carti469 = carti459.CFrame - carti459.Position
                        carti459.CFrame = CFrame.new(carti468.Position) * carti469
                    end
                end
            end)
        else
            local carti467 = math.max(1.65, carti455:GetExtentsSize().Y * 0.42)
            carti459.CFrame = carti457.CFrame * CFrame.new(0, carti467, 0)
            local carti468 = Instance.new('Motor6D')
            carti468.Name = 'CartiHubLocalPetRideMountMotor6D'
            carti468.Part0 = carti459
            carti468.Part1 = carti457
            carti468.C0 = CFrame.new(0, -carti467, 0)
            carti468.Parent = carti459
            carti154.nativeLocalPetRideWeld = carti468
        end

        local carti469 = carti458:FindFirstChildOfClass('Humanoid')
        local carti470 = carti469 and carti469:FindFirstChildOfClass('Animator')
        if carti470 then
            pcall(function()
                local carti471 = Instance.new('Animation')
                carti471.AnimationId = 'rbxassetid://3342979102'
                local carti473 = carti470:LoadAnimation(carti471)
                carti473.Priority = Enum.AnimationPriority.Action
                carti473.Looped = true
                carti473:Play(0.1, 1, 1)
                carti154.nativeLocalPetRideAnimation = carti473
            end)
        end
        if carti468 then
            carti468.Sit = false
        end
        return true
    end

    carti154.refreshNativeLocalPetPresentation = function()
        local carti454 = carti154.nativeLocalPetModel
        local carti455 = carti154.nativeLocalPetWrapper
        if not carti454 or not carti454.Parent or not carti455 then
            return false
        end

        local carti456 = carti26.pets and carti26.pets[carti455.pet_id]
        if not carti456 then
            return false
        end

        -- The native entity caches the wrapper name when it is created. Rebuild only
        -- that presentation layer so the name changes immediately without re-equipping.
        local carti457 = pcall(function()
            carti154.petEntityManager.remove_pet_entity_by_char(carti454)
            carti154.petEntityManager.create_pet_entity(carti454, carti456)
        end)
        return carti457
    end

    carti154.renameNativeLocalPet = function(carti454)
        carti454 = tostring(carti454 or ''):gsub('^%s+', ''):gsub('%s+$', '')
        if carti454 == '' or not carti154.nativeLocalPetModel or not carti154.nativeLocalPetWrapper then
            return false
        end
        local carti458 = carti154.nativeLocalPetModel
        carti458.Name = carti454
        carti154.nativeLocalPetWrapper.rp_name = carti454
        carti161('pet_char_wrappers', function(carti455)
            for _, carti456 in ipairs(carti455) do
                if carti456.char == carti458 then
                    carti456.rp_name = carti454
                end
            end
            return carti455
        end)
        carti154.refreshNativeLocalPetPresentation()
        return true
    end

    carti154.clearLocalPetEquipState = function()
        local carti454 = false
        local carti455 = carti23.get('equip_manager')
        for _, carti456 in ipairs(carti455 and carti455.pets or {}) do
            if carti456.carti_hub_local_pet then
                carti454 = true
                break
            end
        end

        if not carti454 then
            return false
        end

        carti154.clearNativeLocalPetEntity()
        carti161('equip_manager', function(carti457)
            carti457.pets = carti457.pets or {}
            for carti458 = #carti457.pets, 1, -1 do
                if carti457.pets[carti458].carti_hub_local_pet then
                    table.remove(carti457.pets, carti458)
                end
            end
            return carti457
        end)
        return carti454
    end

    carti154.spawnNativeLocalPetEntity = function(carti454)
        carti154.clearNativeLocalPetEntity()

        local carti455 = carti2.LocalPlayer.Character
        local carti456 = carti455 and carti455:FindFirstChild('HumanoidRootPart')
        if not carti456 then return end

        local carti457 = carti42(carti454.kind)
        if not carti457 then return end

        local carti458 = carti457:FindFirstChild('HumanoidRootPart')
        if not carti458 then
            carti457:Destroy()
            return
        end

        carti457.Name = (carti26.pets and carti26.pets[carti454.kind] and carti26.pets[carti454.kind].name)
            or tostring(carti454.kind)
        carti457:SetAttribute('CartiHubLocalPet', true)
        carti457.Parent = workspace
        carti457:PivotTo(carti456.CFrame * CFrame.new(3.4, -1.75, 0.75))

        local carti459 = Instance.new('Attachment')
        carti459.Name = 'CartiHubPetFollowAttachment'
        carti459.Position = Vector3.new(3.4, -1.75, 0.75)
        carti459.Parent = carti456
        local carti460 = Instance.new('Attachment')
        carti460.Name = 'CartiHubPetRootAttachment'
        carti460.Parent = carti458
        local carti461 = Instance.new('AlignPosition')
        carti461.Name = 'CartiHubPetFollowPosition'
        carti461.Attachment0 = carti460
        carti461.Attachment1 = carti459
        carti461.MaxForce = math.huge
        carti461.MaxVelocity = math.huge
        carti461.Responsiveness = 100
        carti461.RigidityEnabled = true
        carti461.Parent = carti458
        local carti462 = Instance.new('AlignOrientation')
        carti462.Name = 'CartiHubPetFollowOrientation'
        carti462.Attachment0 = carti460
        carti462.Attachment1 = carti459
        carti462.MaxTorque = math.huge
        carti462.MaxAngularVelocity = math.huge
        carti462.Responsiveness = 100
        carti462.RigidityEnabled = true
        carti462.Parent = carti458

        local carti481 = nil
        local carti482 = workspace:FindFirstChild('Pets')
        if carti482 then
            for _, carti483 in ipairs(carti482:GetChildren()) do
                local carti484 = carti154.charWrapperClient.get(carti483)
                if carti484 and carti484.is_pet then
                    carti481 = table.clone(carti484)
                    break
                end
            end
        end

        if not carti481 then
            carti481 = {
                is_pet = true,
                index = 1,
                unique = 0,
                transform_mode = 1,
                location = {},
                are_colors_sealed = false,
            }
        end

        if carti481 then
            carti481.char = carti457
            carti481.player = carti2.LocalPlayer
            carti481.controller = carti2.LocalPlayer
            carti481.entity_controller = carti2.LocalPlayer
            carti481.pet_unique = carti454.unique
            carti481.pet_id = carti454.kind
            carti481.unique = -math.floor(os.clock() * 1000000)
            carti481.index = 1
            carti481.rp_name = ''
            carti481.location = {
                full_destination_id = 'housing',
                destination_id = 'housing',
                house_owner = carti2.LocalPlayer,
            }
            carti481.neon = carti454.properties and carti454.properties.neon == true
            carti481.mega_neon = carti454.properties and carti454.properties.mega_neon == true
            carti481.pet_progression = {
                age = (carti454.properties and carti454.properties.age) or 1,
                xp = (carti454.properties and carti454.properties.xp) or 0,
                friendship_level = (carti454.properties and carti454.properties.friendship_level) or 0,
            }
            carti154.charWrapperClient.register_debug_wrapper(carti457, carti481)
        end

        local carti485, carti486 = pcall(function()
            return carti154.petEntityManager.create_pet_entity(carti457, carti26.pets and carti26.pets[carti454.kind])
        end)
        if not carti485 then
            pcall(function()
                carti154.charWrapperClient.register_debug_wrapper(carti457, nil)
            end)
            carti459:Destroy()
            carti457:Destroy()
            return
        end

        if carti454.properties and carti454.properties.neon == true then
            pcall(function()
                carti20('PetNeonHelper').apply_neon(
                    carti457.PetModel,
                    carti26.pets[carti454.kind].neon_parts
                )
            end)
        end

        carti154.nativeLocalPetModel = carti457
        carti154.nativeLocalPetUnique = carti454.unique
        carti154.nativeLocalPetFollowAttachment = carti459
        carti154.nativeLocalPetFollowPosition = carti461
        carti154.nativeLocalPetFollowOrientation = carti462
        carti154.nativeLocalPetWrapper = carti481
        if carti481 then
            carti154.nativeLocalPetState = {
                char = carti457,
                player = carti2.LocalPlayer,
                store_key = 'pet_state_managers',
                is_sitting = false,
                chars_connected_to_me = {},
                states = {},
            }
            carti161('pet_state_managers', function(carti487)
                table.insert(carti487, carti154.nativeLocalPetState)
                return carti487
            end)
            carti161('pet_char_wrappers', function(carti487)
                table.insert(carti487, carti481)
                return carti487
            end)
        end

        local carti474 = carti457:FindFirstChildOfClass('Humanoid')
        if carti474 then
            carti474.AutoRotate = false
        end
        carti154.nativeLocalPetMotionConnection = carti4.Heartbeat:Connect(function()
            if not carti457.Parent or not carti458.Parent or not carti456.Parent then return end
            local carti475 = carti154.petEntityManager.get_pet_entity(carti457)
            if not carti475 then return end
            if carti154.nativeLocalPetState
                and carti154.nativeLocalPetState.states
                and carti154.nativeLocalPetState.states[1]
                and (carti154.nativeLocalPetState.states[1].id == 'PetBeingRidden'
                    or carti154.nativeLocalPetState.states[1].id == 'PetBeingFlown') then
                return
            end
            if carti154.nativeLocalPetHeld then
                carti475.move_state.is_moving = false
                carti475.speed_state.calculated_speed = 0
                return
            end
            local carti476 = carti456.AssemblyLinearVelocity.Magnitude > 1.1
            carti475.move_state.is_moving = carti476
            carti475.speed_state.calculated_speed = carti476 and math.max(carti456.AssemblyLinearVelocity.Magnitude, 16) or 0
        end)
    end

    carti154.clientToolManager.equip = function(carti454, carti455)
        if not (carti454 and carti454.carti_hub_local_pet) then
            carti154.clearLocalPetEquipState()
            return carti154.originalClientToolEquip(carti454, carti455)
        end

        for _, carti456 in ipairs(carti154.clientToolManager.get_equipped_by_category('pets')) do
            if not carti456.carti_hub_local_pet then
                pcall(function()
                    carti154.originalClientToolUnequip(carti456, { suppress_fail_message = true })
                end)
            end
        end

        carti161('equip_manager', function(carti457)
            carti457.pets = carti457.pets or {}
            for carti458 = #carti457.pets, 1, -1 do
                if carti457.pets[carti458] then
                    table.remove(carti457.pets, carti458)
                end
            end
            table.insert(carti457.pets, 1, carti454)
            return carti457
        end)
        task.spawn(carti154.spawnNativeLocalPetEntity, carti454)
        return true
    end

    carti154.clientToolManager.unequip = function(carti454, carti455)
        if not (carti454 and carti454.carti_hub_local_pet) then
            return carti154.originalClientToolUnequip(carti454, carti455)
        end

        carti161('equip_manager', function(carti456)
            carti456.pets = carti456.pets or {}
            for carti457 = #carti456.pets, 1, -1 do
                if carti456.pets[carti457].unique == carti454.unique then
                    table.remove(carti456.pets, carti457)
                end
            end
            return carti456
        end)
        carti154.clearNativeLocalPetEntity()
        return true
    end

    carti154.clientToolManager.backpack_equip = function(carti454, carti455)
        if carti454 and carti454.category == 'pets' and not carti454.carti_hub_local_pet then
            if carti154.clearLocalPetEquipState() then
                task.wait()
            end
        end
        return carti154.originalClientToolBackpackEquip(carti454, carti455)
    end

    local carti462 = carti20('PetActions')
    carti462.cartiHubOriginalRidePet = carti462.cartiHubOriginalRidePet or carti462.ride_pet
    carti462.ride_pet = function(carti463, ...)
        if carti463
            and carti463.char == carti154.nativeLocalPetModel
            and carti463.pet_unique == carti154.nativeLocalPetUnique then
            local carti464 = carti23.get('inventory')
            local carti465 = carti464 and carti464.pets and carti464.pets[carti463.pet_unique]
            if carti465 and carti465.properties and carti465.properties.rideable then
                pcall(function()
                    carti22.apps.FocusPetApp:release_focus()
                end)
                return carti154.setNativeLocalPetRiding(true, 'PetBeingRidden')
            end
        end
        return carti462.cartiHubOriginalRidePet(carti463, ...)
    end

    carti462.cartiHubOriginalFlyPet = carti462.cartiHubOriginalFlyPet or carti462.fly_pet
    carti462.fly_pet = function(carti463, ...)
        if carti463
            and carti463.char == carti154.nativeLocalPetModel
            and carti463.pet_unique == carti154.nativeLocalPetUnique then
            local carti464 = carti23.get('inventory')
            local carti465 = carti464 and carti464.pets and carti464.pets[carti463.pet_unique]
            if carti465 and carti465.properties and carti465.properties.flyable then
                pcall(function()
                    carti22.apps.FocusPetApp:release_focus()
                end)
                return carti154.setNativeLocalPetRiding(true, 'PetBeingFlown')
            end
        end
        return carti462.cartiHubOriginalFlyPet(carti463, ...)
    end

    carti462.cartiHubOriginalPickUpPet = carti462.cartiHubOriginalPickUpPet or carti462.pick_up
    carti462.pick_up = function(carti463, ...)
        if carti463
            and carti463.char == carti154.nativeLocalPetModel
            and carti463.pet_unique == carti154.nativeLocalPetUnique then
            pcall(function()
                carti22.apps.FocusPetApp:release_focus()
            end)
            return carti154.setNativeLocalPetHeld(not carti154.nativeLocalPetHeld)
        end
        return carti462.cartiHubOriginalPickUpPet(carti463, ...)
    end

    carti453.CartiHubAdoptMeLocalPetHooks = {
        manager = carti154.clientToolManager,
        equip = carti154.originalClientToolEquip,
        unequip = carti154.originalClientToolUnequip,
        backpackEquip = carti154.originalClientToolBackpackEquip,
        clear = carti154.clearLocalPetEquipState,
        stopMountButton = carti154.nativeLocalPetStopMountButton,
    }
end

carti154.installLocalPetEquipFlow()

pcall(function()
    local carti453 = (getgenv and getgenv()) or _G
    if carti453.CartiHubRealTradePetTransferWatcher then
        carti453.CartiHubRealTradePetTransferWatcher.Enabled = false
        carti453.CartiHubRealTradePetTransferWatcher = nil
    end
end)

-- Remove a client-spawned pet after it has been transferred through a fake trade.
carti154.removeTransferredLocalPets = function(carti453)
    if type(carti453) ~= 'table' or next(carti453) == nil then
        return 0
    end

    local carti454 = carti154.nativeLocalPetUnique
    if carti454 and carti453[carti454] then
        if carti154.setNativeLocalPetRiding then
            carti154.setNativeLocalPetRiding(false)
        end
        if carti154.clearNativeLocalPetHeld then
            carti154.clearNativeLocalPetHeld()
        end
        if carti154.clearLocalPetEquipState then
            carti154.clearLocalPetEquipState()
        end
    end

    local carti455 = 0
    carti161('inventory', function(carti456)
        carti456.pets = carti456.pets or {}
        for carti457 in pairs(carti453) do
            local carti458 = carti456.pets[carti457]
            if carti458 and carti458.carti_hub_local_pet then
                carti456.pets[carti457] = nil
                carti455 += 1
            end
        end
        return carti456
    end)
    return carti455
end

carti154.addReceivedFakeTradePets = function(carti453)
    if type(carti453) ~= 'table' then
        return 0
    end

    local carti454 = 0
    carti161('inventory', function(carti455)
        carti455.pets = carti455.pets or {}
        for _, carti456 in ipairs(carti453) do
            local carti457 = carti456 and (carti456.kind or carti456.id)
            if carti456 and carti456.category == 'pets' and carti457 and carti26.pets and carti26.pets[carti457] then
                local carti458 = '2_' .. carti7:GenerateGUID(false)
                carti455.pets[carti458] = {
                    unique = carti458,
                    category = 'pets',
                    carti_hub_local_pet = true,
                    id = carti457,
                    kind = carti457,
                    properties = carti24.deep_copy(carti456.properties or {}),
                    newness_order = os.time() * 1000 + carti454,
                }
                carti454 += 1
            end
        end
        return carti455
    end)

    if carti454 > 0 and carti154.organizeSpawnedPets then
        carti154.organizeSpawnedPets(carti53)
    end
    return carti454
end

pcall(function()
    local carti459 = (getgenv and getgenv()) or _G
    carti459.CartiHubRemoveTransferredLocalPets = carti154.removeTransferredLocalPets
    carti459.CartiHubAddReceivedFakeTradePets = carti154.addReceivedFakeTradePets
end)

-- ==================== USERS TAB ====================
local carti349 = carti155['Users']

local carti350 = Instance.new('TextBox')
carti350.Size = UDim2.new(1, 0, 0, 26)
carti350.Position = UDim2.new(0, 0, 0, 0)
carti350.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
carti350.BackgroundTransparency = 0.2
carti350.Text = ''
carti350.PlaceholderText = 'Search users...'
carti350.Font = Enum.Font.SourceSans
carti350.TextSize = 12
carti350.TextColor3 = Color3.fromRGB(255, 255, 255)
carti350.ClearTextOnFocus = false
carti350.TextXAlignment = Enum.TextXAlignment.Left
carti350.Parent = carti349
Instance.new('UICorner', carti350).CornerRadius = UDim.new(0, 4)

local carti351 = Instance.new('ScrollingFrame')
carti351.Size = UDim2.new(1, 0, 0, 180)
carti351.Position = UDim2.new(0, 0, 0, 30)
carti351.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
carti351.BackgroundTransparency = 0.5
carti351.BorderSizePixel = 0
carti351.ScrollBarThickness = 4
carti351.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
carti351.ScrollBarImageTransparency = 0.5
carti351.Parent = carti349
Instance.new('UICorner', carti351).CornerRadius = UDim.new(0, 4)

local carti352 = Instance.new('UIListLayout')
carti352.SortOrder = Enum.SortOrder.LayoutOrder
carti352.Padding = UDim.new(0, 3)
carti352.Parent = carti351

local carti353 = Instance.new('UIPadding')
carti353.PaddingTop = UDim.new(0, 4)
carti353.PaddingBottom = UDim.new(0, 4)
carti353.PaddingLeft = UDim.new(0, 4)
carti353.PaddingRight = UDim.new(0, 4)
carti353.Parent = carti351

local carti354 = Instance.new('TextLabel')
carti354.Size = UDim2.new(1, 0, 0, 16)
carti354.Position = UDim2.new(0, 0, 0, 215)
carti354.BackgroundTransparency = 1
carti354.Text = 'Chat Messages'
carti354.Font = Enum.Font.SourceSansSemibold
carti354.TextSize = 11
carti354.TextColor3 = Color3.fromRGB(180, 180, 180)
carti354.TextXAlignment = Enum.TextXAlignment.Left
carti354.Parent = carti349

local carti355 = Instance.new('TextBox')
carti355.Size = UDim2.new(1, 0, 0, 26)
carti355.Position = UDim2.new(0, 0, 0, 233)
carti355.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
carti355.BackgroundTransparency = 0.2
carti355.Text = ''
carti355.PlaceholderText = 'Enter custom message...'
carti355.Font = Enum.Font.SourceSans
carti355.TextSize = 12
carti355.TextColor3 = Color3.fromRGB(255, 255, 255)
carti355.ClearTextOnFocus = false
carti355.TextXAlignment = Enum.TextXAlignment.Left
carti355.Parent = carti349
Instance.new('UICorner', carti355).CornerRadius = UDim.new(0, 4)

local carti356 = Instance.new('TextButton')
carti356.Size = UDim2.new(1, 0, 0, 26)
carti356.Position = UDim2.new(0, 0, 0, 263)
carti356.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
carti356.BackgroundTransparency = 0.2
carti356.Text = 'Send Chat Message'
carti356.Font = Enum.Font.FredokaOne
carti356.TextSize = 12
carti356.TextColor3 = Color3.fromRGB(255, 255, 255)
carti356.Parent = carti349
Instance.new('UICorner', carti356).CornerRadius = UDim.new(0, 4)

carti356.MouseButton1Click:Connect(function()
    local carti357 = carti355.Text
    if carti357 and carti357 ~= '' then
        carti116(carti357)
        carti355.Text = ''
    end
end)

local carti358 = Instance.new('TextLabel')
carti358.Size = UDim2.new(1, 0, 0, 16)
carti358.Position = UDim2.new(0, 0, 0, 295)
carti358.BackgroundTransparency = 1
carti358.Text = 'Quick Messages'
carti358.Font = Enum.Font.SourceSansSemibold
carti358.TextSize = 11
carti358.TextColor3 = Color3.fromRGB(180, 180, 180)
carti358.TextXAlignment = Enum.TextXAlignment.Left
carti358.Parent = carti349

local carti359 = Instance.new('ScrollingFrame')
carti359.Size = UDim2.new(1, 0, 0, 300)
carti359.Position = UDim2.new(0, 0, 0, 313)
carti359.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
carti359.BackgroundTransparency = 0.5
carti359.BorderSizePixel = 0
carti359.ScrollBarThickness = 4
carti359.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
carti359.ScrollBarImageTransparency = 0.5
carti359.Parent = carti349
Instance.new('UICorner', carti359).CornerRadius = UDim.new(0, 4)

local carti360 = Instance.new('UIListLayout')
carti360.SortOrder = Enum.SortOrder.LayoutOrder
carti360.Padding = UDim.new(0, 3)
carti360.Parent = carti359

local carti361 = Instance.new('UIPadding')
carti361.PaddingTop = UDim.new(0, 4)
carti361.PaddingBottom = UDim.new(0, 4)
carti361.PaddingLeft = UDim.new(0, 4)
carti361.PaddingRight = UDim.new(0, 4)
carti361.Parent = carti359

for i, carti357 in ipairs(carti69.CHAT_MESSAGES) do
    local carti315 = Instance.new('TextButton')
    carti315.Size = UDim2.new(1, -8, 0, 24)
    carti315.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti315.BackgroundTransparency = 0.1
    carti315.Text = '  ' .. carti357
    carti315.Font = Enum.Font.GothamMedium
    carti315.TextSize = 10
    carti315.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti315.TextTruncate = Enum.TextTruncate.AtEnd
    carti315.TextXAlignment = Enum.TextXAlignment.Left
    carti315.LayoutOrder = i
    carti315.Parent = carti359
    Instance.new('UICorner', carti315).CornerRadius = UDim.new(0, 5)
    
    local carti316 = Instance.new('UIStroke')
    carti316.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti316.Color = Color3.fromRGB(255, 200, 50)
    carti316.Thickness = 1.5
    carti316.Transparency = 0.2
    carti316.Parent = carti315

    carti315.MouseEnter:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play()
    end)
    
    carti315.MouseLeave:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play()
    end)

    carti315.MouseButton1Click:Connect(function()
        carti116(carti357)
    end)
end

carti359.CanvasSize = UDim2.new(0, 0, 0, (#carti69.CHAT_MESSAGES * 27) + 8)

local function carti362(username, index)
    local carti315 = Instance.new('TextButton')
    carti315.Size = UDim2.new(1, -8, 0, 28)
    carti315.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti315.BackgroundTransparency = 0.1
    carti315.Text = '  ' .. username
    carti315.Font = Enum.Font.GothamBold
    carti315.TextSize = 11
    carti315.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti315.TextXAlignment = Enum.TextXAlignment.Left
    carti315.LayoutOrder = index
    carti315.Parent = carti351
    Instance.new('UICorner', carti315).CornerRadius = UDim.new(0, 6)
    
    local carti316 = Instance.new('UIStroke')
    carti316.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti316.Color = Color3.fromRGB(255, 200, 50)
    carti316.Thickness = 1.5
    carti316.Transparency = 0.2
    carti316.Parent = carti315

    carti315.MouseEnter:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play()
    end)
    
    carti315.MouseLeave:Connect(function()
        carti6:Create(carti315, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play()
        carti6:Create(carti316, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play()
    end)

    carti315.MouseButton1Click:Connect(function()
        setActiveTab('Control')
        partnerBox.Text = username
        updatePartnerFromUsername(username)
    end)

    return carti315
end

local function carti363()
    for _, child in ipairs(carti351:GetChildren()) do
        if child:IsA('TextButton') then child:Destroy() end
    end
    carti154.userListButtons = {}

    local carti324 = carti350.Text:lower()
    local carti364 = {}
    for _, username in ipairs(carti78) do
        if carti324 == '' or username:lower():sub(1, #carti324) == carti324 then
            table.insert(carti364, username)
        end
    end
    table.sort(carti364, function(a, carti390) return a:lower() < carti390:lower() end)

    for i, username in ipairs(carti364) do
        local carti315 = carti362(username, i)
        table.insert(carti154.userListButtons, carti315)
    end
    carti351.CanvasSize = UDim2.new(0, 0, 0, (#carti364 * 29) + 8)
end

carti350:GetPropertyChangedSignal("Text"):Connect(carti363)
carti363()

-- ==================== RGB STATE (defined early for Sets tab access) ====================
local carti365 = { hue = 0, speed = 0.5, enabled = true }

-- ==================== SETS TAB (KEYBINDS) ====================
local carti366 = carti155['Sets']
local carti367 = { keybindButtons = {}, currentScale = 1.0 }

do
    local carti368 = Instance.new('UIListLayout')
    carti368.SortOrder = Enum.SortOrder.LayoutOrder
    carti368.Padding = UDim.new(0, 6)
    carti368.Parent = carti366
    
    local carti369 = Instance.new('UIPadding')
    carti369.PaddingTop = UDim.new(0, 8)
    carti369.PaddingLeft = UDim.new(0, 4)
    carti369.PaddingRight = UDim.new(0, 4)
    carti369.Parent = carti366
    
    local carti225 = Instance.new('TextLabel')
    carti225.Size = UDim2.new(1, 0, 0, 20)
    carti225.BackgroundTransparency = 1
    carti225.Text = '⌨️ Keybind Settings'
    carti225.Font = Enum.Font.GothamBold
    carti225.TextSize = 14
    carti225.TextColor3 = Color3.fromRGB(255, 200, 50)
    carti225.TextXAlignment = Enum.TextXAlignment.Center
    carti225.LayoutOrder = 0
    carti225.Parent = carti366
end

local function carti370(labelText, keybindKey, layoutOrder)
    local carti371 = Instance.new('Frame')
    carti371.Size = UDim2.new(1, 0, 0, 36)
    carti371.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti371.BackgroundTransparency = 0.1
    carti371.LayoutOrder = layoutOrder
    carti371.Parent = carti366
    Instance.new('UICorner', carti371).CornerRadius = UDim.new(0, 6)
    
    local carti228 = Instance.new('UIStroke')
    carti228.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti228.Color = Color3.fromRGB(255, 200, 50)
    carti228.Thickness = 1.5
    carti228.Transparency = 0.2
    carti228.Parent = carti371
    
    local carti372 = Instance.new('TextLabel')
    carti372.Size = UDim2.new(0.6, 0, 1, 0)
    carti372.Position = UDim2.new(0, 8, 0, 0)
    carti372.BackgroundTransparency = 1
    carti372.Text = labelText
    carti372.Font = Enum.Font.GothamMedium
    carti372.TextSize = 11
    carti372.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti372.TextXAlignment = Enum.TextXAlignment.Left
    carti372.Parent = carti371
    
    local carti234 = Instance.new('TextButton')
    carti234.Size = UDim2.new(0.35, -8, 0, 26)
    carti234.Position = UDim2.new(0.65, 0, 0.5, -13)
    carti234.BackgroundColor3 = Color3.fromRGB(70, 65, 95)
    carti234.BackgroundTransparency = 0.1
    carti234.Text = carti154.keybinds[keybindKey].Name
    carti234.Font = Enum.Font.GothamBold
    carti234.TextSize = 11
    carti234.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti234.Parent = carti371
    Instance.new('UICorner', carti234).CornerRadius = UDim.new(0, 4)
    Instance.new('UIStroke', carti234).Color = Color3.fromRGB(100, 100, 150)
    
    carti367.keybindButtons[keybindKey] = carti234
    
    carti234.MouseEnter:Connect(function()
        if carti154.waitingForKeybind ~= keybindKey then
            carti6:Create(carti234, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(90, 85, 120) }):Play()
        end
    end)
    carti234.MouseLeave:Connect(function()
        if carti154.waitingForKeybind ~= keybindKey then
            carti6:Create(carti234, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play()
        end
    end)
    carti234.MouseButton1Click:Connect(function()
        if carti154.waitingForKeybind then
            local carti373 = carti367.keybindButtons[carti154.waitingForKeybind]
            if carti373 then carti373.Text = carti154.keybinds[carti154.waitingForKeybind].Name; carti373.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
        end
        carti154.waitingForKeybind = keybindKey
        carti234.Text = '...'
        carti234.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
    end)
    return carti371
end

carti370('Select Partner from Trade', 'selectPartner', 1)
carti370('Add Random Item', 'addRandomItem', 2)
carti370('Start Trade', 'startTrade', 3)
carti370('Block Player', 'blockPlayer', 4)

-- RGB Speed Section (using do-end to limit scope)
do
    local carti236 = Instance.new('Frame')
    carti236.Size = UDim2.new(1, 0, 0, 10)
    carti236.BackgroundTransparency = 1
    carti236.LayoutOrder = 10
    carti236.Parent = carti366
    
    local carti225 = Instance.new('TextLabel')
    carti225.Size = UDim2.new(1, 0, 0, 18)
    carti225.BackgroundTransparency = 1
    carti225.Text = '🌈 RGB Settings'
    carti225.Font = Enum.Font.GothamBold
    carti225.TextSize = 12
    carti225.TextColor3 = Color3.fromRGB(255, 200, 50)
    carti225.TextXAlignment = Enum.TextXAlignment.Center
    carti225.LayoutOrder = 11
    carti225.Parent = carti366
    
    local carti371 = Instance.new('Frame')
    carti371.Size = UDim2.new(1, 0, 0, 36)
    carti371.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti371.BackgroundTransparency = 0.1
    carti371.LayoutOrder = 12
    carti371.Parent = carti366
    Instance.new('UICorner', carti371).CornerRadius = UDim.new(0, 6)
    
    local carti228 = Instance.new('UIStroke')
    carti228.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti228.Color = Color3.fromRGB(255, 200, 50)
    carti228.Thickness = 1.5
    carti228.Transparency = 0.2
    carti228.Parent = carti371
    
    local carti372 = Instance.new('TextLabel')
    carti372.Size = UDim2.new(0.5, 0, 1, 0)
    carti372.Position = UDim2.new(0, 8, 0, 0)
    carti372.BackgroundTransparency = 1
    carti372.Text = 'RGB Speed'
    carti372.Font = Enum.Font.GothamMedium
    carti372.TextSize = 11
    carti372.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti372.TextXAlignment = Enum.TextXAlignment.Left
    carti372.Parent = carti371
    
    local carti374 = Instance.new('TextBox')
    carti374.Size = UDim2.new(0.2, 0, 0, 24)
    carti374.Position = UDim2.new(0.5, 0, 0.5, -12)
    carti374.BackgroundColor3 = Color3.fromRGB(70, 65, 95)
    carti374.Text = '0.5'
    carti374.Font = Enum.Font.GothamBold
    carti374.TextSize = 11
    carti374.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti374.Parent = carti371
    Instance.new('UICorner', carti374).CornerRadius = UDim.new(0, 4)
    
    local carti375 = Instance.new('TextButton')
    carti375.Size = UDim2.new(0, 26, 0, 24)
    carti375.Position = UDim2.new(0.72, 0, 0.5, -12)
    carti375.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
    carti375.Text = '-'
    carti375.Font = Enum.Font.GothamBold
    carti375.TextSize = 14
    carti375.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti375.Parent = carti371
    Instance.new('UICorner', carti375).CornerRadius = UDim.new(0, 4)
    
    local carti376 = Instance.new('TextButton')
    carti376.Size = UDim2.new(0, 26, 0, 24)
    carti376.Position = UDim2.new(0.86, 0, 0.5, -12)
    carti376.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
    carti376.Text = '+'
    carti376.Font = Enum.Font.GothamBold
    carti376.TextSize = 14
    carti376.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti376.Parent = carti371
    Instance.new('UICorner', carti376).CornerRadius = UDim.new(0, 4)
    
    carti375.MouseButton1Click:Connect(function()
        local carti377 = math.max(0.1, (tonumber(carti374.Text) or 0.5) - 0.1)
        carti374.Text = string.format('%.1f', carti377)
        carti365.speed = carti377
    end)
    carti376.MouseButton1Click:Connect(function()
        local carti377 = math.min(2.0, (tonumber(carti374.Text) or 0.5) + 0.1)
        carti374.Text = string.format('%.1f', carti377)
        carti365.speed = carti377
    end)
    carti374.FocusLost:Connect(function()
        local carti378 = tonumber(carti374.Text)
        if carti378 then
            carti378 = math.clamp(carti378, 0.1, 2.0)
            carti374.Text = string.format('%.1f', carti378)
            carti365.speed = carti378
        else
            carti374.Text = '0.5'
            carti365.speed = 0.5
        end
    end)
end

-- Server Uptime Section (using do-end to limit scope)
do
    local carti236 = Instance.new('Frame')
    carti236.Size = UDim2.new(1, 0, 0, 10)
    carti236.BackgroundTransparency = 1
    carti236.LayoutOrder = 13
    carti236.Parent = carti366
    
    local carti225 = Instance.new('TextLabel')
    carti225.Size = UDim2.new(1, 0, 0, 18)
    carti225.BackgroundTransparency = 1
    carti225.Text = '🕐 Server Info'
    carti225.Font = Enum.Font.GothamBold
    carti225.TextSize = 12
    carti225.TextColor3 = Color3.fromRGB(255, 200, 50)
    carti225.TextXAlignment = Enum.TextXAlignment.Center
    carti225.LayoutOrder = 14
    carti225.Parent = carti366
    
    local carti371 = Instance.new('Frame')
    carti371.Size = UDim2.new(1, 0, 0, 36)
    carti371.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
    carti371.BackgroundTransparency = 0.1
    carti371.LayoutOrder = 15
    carti371.Parent = carti366
    Instance.new('UICorner', carti371).CornerRadius = UDim.new(0, 6)
    
    local carti228 = Instance.new('UIStroke')
    carti228.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    carti228.Color = Color3.fromRGB(255, 200, 50)
    carti228.Thickness = 1.5
    carti228.Transparency = 0.2
    carti228.Parent = carti371
    
    local carti372 = Instance.new('TextLabel')
    carti372.Size = UDim2.new(0.45, 0, 1, 0)
    carti372.Position = UDim2.new(0, 8, 0, 0)
    carti372.BackgroundTransparency = 1
    carti372.Text = 'Server Uptime'
    carti372.Font = Enum.Font.GothamMedium
    carti372.TextSize = 11
    carti372.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti372.TextXAlignment = Enum.TextXAlignment.Left
    carti372.Parent = carti371
    
    local carti285 = Instance.new('TextLabel')
    carti285.Size = UDim2.new(0.5, -8, 1, 0)
    carti285.Position = UDim2.new(0.5, 0, 0, 0)
    carti285.BackgroundTransparency = 1
    carti285.Text = '0h 0m 0s'
    carti285.Font = Enum.Font.GothamBold
    carti285.TextSize = 11
    carti285.TextColor3 = Color3.fromRGB(100, 255, 150)
    carti285.TextXAlignment = Enum.TextXAlignment.Right
    carti285.Parent = carti371
    
    task.spawn(function()
        while true do
            local carti379 = workspace.DistributedGameTime
            carti285.Text = string.format('%dh %dm %ds', math.floor(carti379/3600), math.floor((carti379%3600)/60), math.floor(carti379%60))
            task.wait(1)
        end
    end)
end

-- Mobile GUI Size Section (using do-end to limit scope)
do
    local carti236 = Instance.new('Frame')
    carti236.Size = UDim2.new(1, 0, 0, 10)
    carti236.BackgroundTransparency = 1
    carti236.LayoutOrder = 16
    carti236.Parent = carti366
    
    local carti225 = Instance.new('TextLabel')
    carti225.Size = UDim2.new(1, 0, 0, 18)
    carti225.BackgroundTransparency = 1
    carti225.Text = '📱 GUI Size (Mobile)'
    carti225.Font = Enum.Font.GothamBold
    carti225.TextSize = 12
    carti225.TextColor3 = Color3.fromRGB(255, 200, 50)
    carti225.TextXAlignment = Enum.TextXAlignment.Center
    carti225.LayoutOrder = 17
    carti225.Parent = carti366
    
    local carti371 = Instance.new('Frame')
    carti371.Size = UDim2.new(1, 0, 0, 40)
    carti371.BackgroundTransparency = 1
    carti371.LayoutOrder = 18
    carti371.Parent = carti366
    
    local carti380 = Instance.new('TextButton')
    carti380.Size = UDim2.new(0.48, 0, 1, 0)
    carti380.Position = UDim2.new(0, 0, 0, 0)
    carti380.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
    carti380.Text = '🔍 Small'
    carti380.Font = Enum.Font.GothamBold
    carti380.TextSize = 12
    carti380.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti380.Parent = carti371
    Instance.new('UICorner', carti380).CornerRadius = UDim.new(0, 6)
    local carti381 = Instance.new('UIStroke', carti380)
    carti381.Color = Color3.fromRGB(255, 200, 50)
    carti381.Thickness = 1.5
    carti381.Transparency = 0.2
    
    local carti382 = Instance.new('TextButton')
    carti382.Size = UDim2.new(0.48, 0, 1, 0)
    carti382.Position = UDim2.new(0.52, 0, 0, 0)
    carti382.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
    carti382.Text = '🔎 Big'
    carti382.Font = Enum.Font.GothamBold
    carti382.TextSize = 12
    carti382.TextColor3 = Color3.fromRGB(255, 255, 255)
    carti382.Parent = carti371
    Instance.new('UICorner', carti382).CornerRadius = UDim.new(0, 6)
    local carti383 = Instance.new('UIStroke', carti382)
    carti383.Color = Color3.fromRGB(255, 200, 50)
    carti383.Thickness = 1.5
    carti383.Transparency = 0.2
    
    -- Create UIScale for proper scaling
    local carti384 = carti208:FindFirstChild('UIScale') or Instance.new('UIScale')
    carti384.Name = 'UIScale'
    carti384.Parent = carti208
    
    carti380.MouseButton1Click:Connect(function()
        carti367.currentScale = math.max(0.7, carti367.currentScale - 0.05)
        carti384.Scale = carti367.currentScale
        if carti32 then carti32:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', carti367.currentScale * 100), length = 1, overridable = true }) end
    end)
    
    carti382.MouseButton1Click:Connect(function()
        carti367.currentScale = math.min(1.3, carti367.currentScale + 0.05)
        carti384.Scale = carti367.currentScale
        if carti32 then carti32:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', carti367.currentScale * 100), length = 1, overridable = true }) end
    end)
    
    carti380.MouseEnter:Connect(function() carti6:Create(carti380, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 80, 150) }):Play() end)
    carti380.MouseLeave:Connect(function() carti6:Create(carti380, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 60, 120) }):Play() end)
    carti382.MouseEnter:Connect(function() carti6:Create(carti382, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 150, 100) }):Play() end)
    carti382.MouseLeave:Connect(function() carti6:Create(carti382, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 120, 80) }):Play() end)
end

-- Pet Value Calculator Section
do
    local carti385 = { state = { M = false, N = false, F = false, R = false }, btns = {} }
    local carti386 = { M = {Color3.fromRGB(170,0,255), Color3.fromRGB(80,60,100)}, N = {Color3.fromRGB(255,215,0), Color3.fromRGB(80,60,100)}, F = {Color3.fromRGB(0,200,255), Color3.fromRGB(80,60,100)}, R = {Color3.fromRGB(0,255,100), Color3.fromRGB(80,60,100)} }
    
    Instance.new('Frame', carti366).Size = UDim2.new(1,0,0,10); carti366:GetChildren()[#carti366:GetChildren()].BackgroundTransparency = 1; carti366:GetChildren()[#carti366:GetChildren()].LayoutOrder = 19
    
    local carti150 = Instance.new('TextLabel', carti366)
    carti150.Size, carti150.BackgroundTransparency, carti150.Text, carti150.Font, carti150.TextSize, carti150.TextColor3, carti150.TextXAlignment, carti150.LayoutOrder = UDim2.new(1,0,0,18), 1, '💎 Pet Value Calculator', Enum.Font.GothamBold, 12, Color3.fromRGB(255,200,50), Enum.TextXAlignment.Center, 20
    
    local carti387 = Instance.new('Frame', carti366)
    carti387.Size, carti387.BackgroundColor3, carti387.BackgroundTransparency, carti387.LayoutOrder = UDim2.new(1,0,0,30), Color3.fromRGB(55,50,75), 0.1, 21
    Instance.new('UICorner', carti387).CornerRadius = UDim.new(0,6)
    local carti388 = Instance.new('UIStroke', carti387); carti388.Color, carti388.Thickness, carti388.Transparency = Color3.fromRGB(255,200,50), 1.5, 0.2
    
    carti385.input = Instance.new('TextBox', carti387)
    carti385.input.Size, carti385.input.Position, carti385.input.BackgroundTransparency, carti385.input.Text, carti385.input.PlaceholderText = UDim2.new(1,-16,1,-6), UDim2.new(0,8,0,3), 1, '', 'Enter pet name...'
    carti385.input.Font, carti385.input.TextSize, carti385.input.TextColor3, carti385.input.PlaceholderColor3, carti385.input.TextXAlignment, carti385.input.ClearTextOnFocus = Enum.Font.GothamMedium, 11, Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,160), Enum.TextXAlignment.Left, false
    
    local carti389 = Instance.new('Frame', carti366)
    carti389.Size, carti389.BackgroundTransparency, carti389.LayoutOrder = UDim2.new(1,0,0,28), 1, 22
    
    for i, p in ipairs({'M','N','F','R'}) do
        local carti390 = Instance.new('TextButton', carti389)
        carti390.Size, carti390.Position, carti390.BackgroundColor3, carti390.Text, carti390.Font, carti390.TextSize, carti390.TextColor3 = UDim2.new(0.24,-4,1,0), UDim2.new((i-1)*0.25,2,0,0), carti386[p][2], p, Enum.Font.GothamBold, 12, Color3.fromRGB(255,255,255)
        Instance.new('UICorner', carti390).CornerRadius = UDim.new(0,4)
        carti385.btns[p] = carti390
        carti390.MouseButton1Click:Connect(function()
            if p == 'M' then carti385.state.M = not carti385.state.M; if carti385.state.M then carti385.state.N = false end
            elseif p == 'N' then carti385.state.N = not carti385.state.N; if carti385.state.N then carti385.state.M = false end
            else carti385.state[p] = not carti385.state[p] end
            for k, carti152 in pairs(carti385.btns) do carti152.BackgroundColor3 = carti385.state[k] and carti386[k][1] or carti386[k][2] end
        end)
    end
    
    local carti391 = Instance.new('TextButton', carti366)
    carti391.Size, carti391.BackgroundColor3, carti391.Text, carti391.Font, carti391.TextSize, carti391.TextColor3, carti391.LayoutOrder = UDim2.new(1,0,0,32), Color3.fromRGB(80,160,80), '📊 Calculate Value', Enum.Font.GothamBold, 12, Color3.fromRGB(255,255,255), 23
    Instance.new('UICorner', carti391).CornerRadius = UDim.new(0,6)
    local carti392 = Instance.new('UIStroke', carti391); carti392.Color, carti392.Thickness, carti392.Transparency = Color3.fromRGB(255,200,50), 1.5, 0.2
    
    carti385.result = Instance.new('TextLabel', carti366)
    carti385.result.Size, carti385.result.BackgroundColor3, carti385.result.Text, carti385.result.Font, carti385.result.TextSize, carti385.result.TextColor3, carti385.result.LayoutOrder = UDim2.new(1,0,0,36), Color3.fromRGB(40,35,55), 'Value: --', Enum.Font.GothamBold, 14, Color3.fromRGB(100,255,150), 24
    Instance.new('UICorner', carti385.result).CornerRadius = UDim.new(0,6)
    local carti393 = Instance.new('UIStroke', carti385.result); carti393.Color, carti393.Thickness, carti393.Transparency = Color3.fromRGB(255,200,50), 1.5, 0.2
    
    carti391.MouseButton1Click:Connect(function()
        local carti394 = carti385.input.Text:lower():gsub('%s+', '')
        if carti394 == '' then carti385.result.Text, carti385.result.TextColor3 = 'Enter a pet name!', Color3.fromRGB(255,100,100) return end
        local carti395, carti396 = nil, nil
        for k, carti57 in pairs(carti53) do if k:lower():gsub('%s+','') == carti394 or k:lower():gsub('%s+',''):find(carti394,1,true) then carti395, fk = carti57, k break end end
        if not carti395 then carti385.result.Text, carti385.result.TextColor3 = 'Pet not found!', Color3.fromRGB(255,100,100) return end
        local carti397 = carti385.state.M and "mvalue" or (carti385.state.N and "nvalue" or "rvalue")
        local carti398 = (carti385.state.R and carti385.state.F) and " - fly&ride" or (carti385.state.R and " - ride" or (carti385.state.F and " - fly" or " - nopotion"))
        local carti152 = carti395[carti397..sf] or carti395[carti397] or 0
        local carti399 = carti152 >= 1e9 and string.format('%.2fB',carti152/1e9) or (carti152 >= 1e6 and string.format('%.2fM',carti152/1e6) or (carti152 >= 1e3 and string.format('%.2fK',carti152/1e3) or tostring(carti152)))
        local carti400 = (carti385.state.M and 'Mega ' or '')..(carti385.state.N and 'Neon ' or '')..(carti385.state.F and 'F' or '')..(carti385.state.R and 'R' or ''); if carti400 == '' then carti400 = 'Normal' end
        carti385.result.Text, carti385.result.TextColor3 = carti396..' ('..ps..'): '..fv, Color3.fromRGB(100,255,150)
    end)
    carti391.MouseEnter:Connect(function() carti6:Create(carti391, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(100,180,100)}):Play() end)
    carti391.MouseLeave:Connect(function() carti6:Create(carti391, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(80,160,80)}):Play() end)
end

-- Keybind input handler
carti5.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if carti154.waitingForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        local carti60 = input.KeyCode
        if carti60 == Enum.KeyCode.Escape then
            local carti315 = carti367.keybindButtons[carti154.waitingForKeybind]
            if carti315 then carti315.Text = carti154.keybinds[carti154.waitingForKeybind].Name; carti315.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
            carti154.waitingForKeybind = nil
            return
        end
        carti154.keybinds[carti154.waitingForKeybind] = carti60
        local carti315 = carti367.keybindButtons[carti154.waitingForKeybind]
        if carti315 then carti315.Text = carti60.Name; carti315.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
        carti154.waitingForKeybind = nil
        if carti32 then carti32:hint({ text = 'Keybind set to ' .. key.Name, length = 2, overridable = true }) end
        return
    end
    
    -- Handle keybind actions
    if input.UserInputType == Enum.UserInputType.Keyboard and not carti154.waitingForKeybind then
        local carti60 = input.KeyCode
        
        -- Select Partner from Trade
        if carti60 == carti154.keybinds.selectPartner then
            pcall(function()
                local carti94 = nil
                if carti74.active and carti74.trade then
                    carti94 = carti74.trade.recipient
                else
                    carti94 = carti30:_get_partner()
                end
                if carti94 and carti94.Name then
                    partnerBox.Text = carti94.Name
                    updatePartnerFromUsername(carti94.Name)
                    if carti32 then
                        carti32:hint({ text = 'Partner set to ' .. partner.Name, length = 2, overridable = true })
                    end
                end
            end)
        end
        
        -- Add Random Item
        if carti60 == carti154.keybinds.addRandomItem then
            if carti74.active then
                carti105(carti80(), carti111())
            end
        end
        
        -- Start Trade
        if carti60 == carti154.keybinds.startTrade then
            if not carti74.active then
                task.spawn(carti127)
            end
        end
        
        -- Block Player
        if carti60 == carti154.keybinds.blockPlayer then
            local carti240 = carti2:FindFirstChild(partnerBox.Text)
            if carti240 then
                BlockPlayer(carti240)
            end
        end
    end
end)

-- ==================== FIXED DRAGGING SYSTEM ====================
local carti401 = false
local carti402, carti403, carti404

carti208.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        carti401 = true
        carti403 = input.Position
        carti404 = carti208.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                carti401 = false
            end
        end)
    end
end)

carti208.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        carti402 = input
    end
end)

carti5.InputChanged:Connect(function(input)
    if input == carti402 and carti401 then
        local carti405 = input.Position - carti403
        carti208.Position = UDim2.new(carti404.X.Scale, carti404.X.Offset + carti405.X, carti404.Y.Scale, carti404.Y.Offset + carti405.Y)
    end
end)

-- ==================== KEYBOARD SHORTCUTS ====================
carti5.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        carti208.Visible = not carti208.Visible
    end
end)

-- ==================== NOCLIP MAINTENANCE ====================
task.spawn(function()
    while true do
        task.wait(1)
        if carti154.noclipEnabled then
            carti194()
            carti195()
        end
    end
end)

-- ==================== INITIAL SETUP ====================
if carti154.activeTabPulseTween == nil then
    local carti162 = carti156['Control']
    if carti162 then
        carti154.activeTabPulseTween = carti6:Create(carti162.stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Color = Color3.fromRGB(100, 100, 255):Lerp(Color3.fromRGB(255, 255, 255), 0.25), Thickness = 1.5
        })
        carti154.activeTabPulseTween:Play()
    end
end

task.wait(3)
carti299(true)

-- ==================== AUTO PARTNER EMOJI ====================
_G.EmojiSystem = {
    running = false,
    reactions = carti20('SharedConstants').trade_spectate_reactions
}

_G.EmojiSystem.display = function(index)
    if not _G.EmojiSystem.reactions[index] then return end
    if not carti74.active or not carti74.trade then return end
    
    pcall(function()
        local carti406 = carti2.LocalPlayer.PlayerGui.TradeApp.Frame
        
        local carti407 = Instance.new('ImageLabel')
        carti407.Image = _G.EmojiSystem.reactions[index]
        carti407.BackgroundTransparency = 1
        carti407.ImageTransparency = 1
        carti407.Size = UDim2.fromOffset(40, 40)
        carti407.Position = UDim2.new(0.92 + math.random(-3, 3) / 100, 0, 0.95, 0)
        carti407.AnchorPoint = Vector2.new(0.5, 1)
        carti407.ZIndex = 100
        carti407.Parent = carti406
        
        carti6:Create(carti407, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            ImageTransparency = 0, Size = UDim2.fromOffset(45, 45)
        }):Play()
        
        local carti408, carti409, carti410 = tick(), math.random(18, 28) / 10, 0.18
        local carti411
        carti411 = carti4.Heartbeat:Connect(function(dt)
            local carti412 = tick() - carti408
            if carti412 >= carti409 or not carti407.Parent then carti411:Disconnect() if carti407.Parent then carti407:Destroy() end return end
            local carti413 = carti407.Position.Y.Scale - carti410 * dt
            local carti414 = math.sin(carti412 * 4) * dt * 0.0
            carti407.Position = UDim2.new(math.clamp(carti407.Position.X.Scale + carti414, 0.85, 0.98), 0, carti413, 0)
            if carti412 >= carti409 * 0.5 then carti407.ImageTransparency = (carti412 - carti409 * 0.5) / (carti409 * 0.5) end
        end)
    end)
end

carti235(carti222)

carti233('🎭 Auto Partner Emoji: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), carti222, function()
    _G.EmojiSystem.running = not _G.EmojiSystem.running
    local carti234
    for _, carti152 in pairs(carti222:GetChildren()) do
        if carti152:IsA('TextButton') and carti152.Text:find('Emoji') then carti234 = carti152 break end
    end
    
    if _G.EmojiSystem.running then
        carti234.Text = '🎭 Auto Partner Emoji: ON'
        carti234.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        task.spawn(function()
            while _G.EmojiSystem.running do
                task.wait(math.random(8, 20) / 10)
                if _G.EmojiSystem.running and carti74.active and carti74.trade then
                    _G.EmojiSystem.display(math.random(1, #_G.EmojiSystem.reactions))
                end
            end
        end)
    else
        carti234.Text = '🎭 Auto Partner Emoji: OFF'
        carti234.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

-- ==================== RGB CYCLING EFFECT ====================
task.spawn(function()
    while true do
        task.wait(0.03)
        if carti365.enabled and carti210 then
            carti365.hue = (carti365.hue + carti365.speed) % 360
            local carti415 = Color3.fromHSV(carti365.hue / 360, 0.7, 1)
            carti210.Color = carti415
        end
    end
end)
