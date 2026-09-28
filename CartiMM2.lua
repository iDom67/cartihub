local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local tradeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeModule"))
local inventoryModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryModule"))
local itemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))
local profileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
local sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
local itemPopupService = require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("ItemPopupService"))

-- These entries reference Decal assets in the game database. Inventory cards
-- need the underlying texture thumbnail rather than the Decal asset itself.
for _, itemContainer in ipairs({ sync.Weapons, sync.Item }) do
    if itemContainer then
        if itemContainer.IcecreamChroma then
            itemContainer.IcecreamChroma.Image = "rbxthumb://type=Asset&w=150&h=150&id=90300177211738"
        end

        if itemContainer.BeachyChroma then
            itemContainer.BeachyChroma.Image = "rbxthumb://type=Asset&w=150&h=150&id=134952503728391"
        end

        if itemContainer.SandsChroma then
            itemContainer.SandsChroma.Image = "rbxthumb://type=Asset&w=150&h=150&id=104927341820800"
        end
    end
end

local currentWeaponAmount = 1
local MAX_WEAPON_AMOUNT = 113
local BUTTON_COLOR = Color3.fromRGB(31, 11, 52)
local BUTTON_HOVER_COLOR = Color3.fromRGB(59, 25, 91)
local SakaUI

-- Block credentials are entered at runtime in the Block tab and are not stored in this file.`r`n
local function safeParent()
    local ok = pcall(function()
        return CoreGui.Name
    end)

    if ok then
        return CoreGui
    end

    return localPlayer:WaitForChild("PlayerGui")
end

local function getProfileOwnedTable(itemType)
    if itemType == "Weapons" or itemType == "Item" then
        return profileData.Weapons and profileData.Weapons.Owned
    elseif itemType == "Pets" then
        return profileData.Pets and profileData.Pets.Owned
    end

    local bucket = profileData[itemType]
    return bucket and bucket.Owned
end

-- Spawned stacks are display-only. Keep them separate from the profile table,
-- because MM2 can replace that table when a real copy of an item is received.
_G.CartiHubFakeInventoryAmounts = _G.CartiHubFakeInventoryAmounts or {}

function CartiHubGetFakeInventoryKey(itemId, itemType)
    local bucket = itemType == "Item" and "Weapons" or tostring(itemType)
    return bucket .. ":" .. tostring(itemId)
end

function CartiHubGetFakeInventoryAmount(itemId, itemType)
    return tonumber(_G.CartiHubFakeInventoryAmounts[CartiHubGetFakeInventoryKey(itemId, itemType)]) or 0
end

function CartiHubSetFakeInventoryAmount(itemId, itemType, amount)
    local key = CartiHubGetFakeInventoryKey(itemId, itemType)
    local owned = getProfileOwnedTable(itemType)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    if amount > 0 then
        _G.CartiHubFakeInventoryAmounts[key] = amount
        if owned then
            owned[itemId] = amount
        end
    else
        _G.CartiHubFakeInventoryAmounts[key] = nil
        if owned then
            owned[itemId] = nil
        end
    end

    return amount
end

function CartiHubAddFakeInventoryAmount(itemId, itemType, delta)
    return CartiHubSetFakeInventoryAmount(
        itemId,
        itemType,
        CartiHubGetFakeInventoryAmount(itemId, itemType) + (tonumber(delta) or 0)
    )
end

local function clearMainInventoryContainers()
    local gui = inventoryModule.GUI and inventoryModule.GUI.MyInventory
    if not gui or not gui.Main then
        return false
    end

    local blank = inventoryModule.CreateBlankInventoryTable()

    for itemType, categories in pairs(blank) do
        local typeFrame = gui.Main:FindFirstChild(itemType)
        local itemsContainer = typeFrame
            and typeFrame:FindFirstChild("Items")
            and typeFrame.Items:FindFirstChild("Container")

        if itemsContainer then
            for categoryName in pairs(categories) do
                local categoryFrame = itemsContainer:FindFirstChild(categoryName)

                if not categoryFrame and itemsContainer:FindFirstChild("Holiday") then
                    local holiday = itemsContainer.Holiday:FindFirstChild("Container")
                    categoryFrame = holiday and holiday:FindFirstChild(categoryName)
                end

                local container = categoryFrame and categoryFrame:FindFirstChild("Container")
                if container then
                    container:ClearAllChildren()
                end
            end
        end
    end

    return true
end

local function refreshMainInventoryNow()
    local gui = inventoryModule.GUI and inventoryModule.GUI.MyInventory
    if not gui or not gui.Main then
        return false
    end

    if not clearMainInventoryContainers() then
        return false
    end

    local ok, newInventory = pcall(function()
        return inventoryModule.GenerateInventory(gui, profileData)
    end)

    if not ok then
        warn("[Carti Hub] Main inventory refresh failed: " .. tostring(newInventory))
        return false
    end

    inventoryModule.MyInventory = newInventory

    pcall(function()
        inventoryModule.ConnectEquipButtons()
    end)

    pcall(function()
        inventoryModule.UpdateMyEquip()
    end)

    return true
end

task.spawn(function()
    while SakaUI == nil or SakaUI.Parent ~= nil do
        local corrected = false

        for key, amount in pairs(_G.CartiHubFakeInventoryAmounts) do
            local itemType, itemId = string.match(key, "^([^:]+):(.+)$")
            local owned = itemType and getProfileOwnedTable(itemType)

            if owned and tonumber(owned[itemId]) ~= tonumber(amount) then
                owned[itemId] = amount
                corrected = true
            end
        end

        if corrected then
            refreshMainInventoryNow()
        end

        task.wait(0.35)
    end
end)

-- Fill this table manually. Prefer exact database ids as keys because display names can overlap.
-- The watcher below applies the matching visual whenever your local equipped knife/gun changes.
local function createEvergreenLightPart(relativePosition, size, meshId)
    return {
        ClassName = "MeshPart",
        Path = { "LightParts" },
        RelativeCFrame = CFrame.new(relativePosition),
        Properties = {
            Name = "LightPart",
            Size = size,
            Color = Color3.new(0.97254902124405, 0.85098040103912, 0.42745098471642),
            Material = Enum.Material.Neon,
            Transparency = 0,
            Reflectance = 0,
            CastShadow = true,
            MeshId = meshId,
            TextureID = "",
        },
    }
end

local EvergreenLightPartsVisualTree = {
    { ClassName = "Model", Path = {}, Properties = { Name = "LightParts" } },
    createEvergreenLightPart(Vector3.new(0.0247802734375, 0.0009765625, -0.136474609375), Vector3.new(1.0546045303345, 2.2052347660065, 0.84564638137817), "rbxassetid://15408281396"),
    createEvergreenLightPart(Vector3.new(0.0765380859375, -0.1904296875, 0.12353515625), Vector3.new(1.0034183263779, 2.1422207355499, 1.0312020778656), "rbxassetid://15408281127"),
    createEvergreenLightPart(Vector3.new(-0.0377197265625, 1.1748046875, -0.029541015625), Vector3.new(0.11298670619726, 0.13323910534382, 0.063117004930973), "rbxassetid://15408281298"),
    createEvergreenLightPart(Vector3.new(0.0809326171875, -0.3125, 0.070068359375), Vector3.new(0.93531209230423, 1.8643255233765, 0.91616159677505), "rbxassetid://15408281195"),
    createEvergreenLightPart(Vector3.new(0.0416259765625, -0.60546875, 0.029052734375), Vector3.new(1.0206427574158, 1.132918715477, 0.87230980396271), "rbxassetid://15408281466"),
}

local WeaponVisuals = {
    ["Flowerwood Gun"] = {
        Type = "Gun",
        MeshId = "rbxassetid://16895099893",
        TextureId = "rbxassetid://16895448237",
        Scale = Vector3.new(0.05, 0.05, 0.05),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },

    ["Lightbringer"] = {
        Type = "Gun",
        MeshId = "rbxassetid://4730813852",
        TextureId = "http://www.roblox.com/asset/?id=4728487789",
        Scale = Vector3.new(0.05, 0.05, 0.05),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },

    ["Snowcannon"] = {
        Type = "Gun",
        MeshId = "rbxassetid://99836890880541",
        TextureId = "http://www.roblox.com/asset/?id=122392330922281",
        Scale = Vector3.new(0.05, 0.05, 0.05),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },

    ["Gingerscythe"] = {
        Type = "Knife",
        MeshId = "rbxassetid://15395668244",
        TextureId = "http://www.roblox.com/asset/?id=15409195246",
        Scale = Vector3.new(0.06, 0.06, 0.06),
        Offset = Vector3.new(0, 0, 0),
        Placement = "Back",
    },

    ["Luger"] = {
        Type = "Gun",
        MeshId = "rbxassetid://95356090",
        TextureId = "http://www.roblox.com/asset/?id=126534866",
        Scale = Vector3.new(1.7999999523162842, 1.7999999523162842, 1.7999999523162842),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },

    ["Darkbringer"] = {
        Type = "Gun",
        MeshId = "rbxassetid://4730813852",
        TextureId = "http://www.roblox.com/asset/?id=4728494788",
        Scale = Vector3.new(0.05, 0.05, 0.05),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },

    ["Eternalcane"] = {
        Type = "Knife",
        MeshId = "rbxassetid://3132923779",
        TextureId = "http://www.roblox.com/asset/?id=4488374804",
        Scale = Vector3.new(0.949999988079071, 0.949999988079071, 0.949999988079071),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistLeft",
    },

    ["Gingermint"] = {
        Type = "Gun",
        MeshId = "rbxassetid://11866444071",
        TextureId = "rbxassetid://11866444253",
        Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
        Offset = Vector3.new(0, 0, 0),
        Placement = "WaistRight",
    },
	["Elderwood Scythe"] = {
    Type = "Knife",
    MeshId = "rbxassetid://4217523241",
    TextureId = "http://www.roblox.com/asset/?id=4210044808",
    Scale = Vector3.new(0.07000000029802322, 0.07000000029802322, 0.07000000029802322),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
	Placement = "WaistLeft",
},
["Batwing"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=305826272",
    TextureId = "rbxassetid://2511673515",
    Scale = Vector3.new(1, 1, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
},
["Heartblade"] = {
    Type = "Knife",
    MeshId = "rbxassetid://6404140078",
    TextureId = "http://www.roblox.com/asset/?id=6413074818",
    Scale = Vector3.new(1, 1, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
	Placement = "WaistLeft",
},
["Candleflame"] = {
    Type = "Knife",
    MeshId = "rbxassetid://7791364860",
    TextureId = "rbxassetid://7791364988",
    Scale = Vector3.new(0.05999999865889549, 0.05999999865889549, 0.05999999865889549),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
	Placement = "WaistLeft",
},
["Makeshift"] = {
    Type = "Gun",
    MeshId = "rbxassetid://11158364935",
    TextureId = "http://www.roblox.com/asset/?id=11274360089",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
},
["Plasmablade"] = {
    Type = "Knife",
    MeshId = "rbxassetid://9702732853",
    TextureId = "rbxassetid://10015130416",
    Scale = Vector3.new(0.0020000000949949026, 0.0020000000949949026, 0.0020000000949949026),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
},
["Plasmabeam"] = {
    Type = "Gun",
    MeshId = "rbxassetid://9702755186",
    TextureId = "rbxassetid://10015208201",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
    AttachmentPosition = Vector3.new(0.06429433822631836, 0.05646803602576256, 0.19186615943908691),
    AttachmentOrientation = Vector3.new(-73.00315856933594, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.2923188805580139, -0.9563208818435669),
},
["Harvester"] = {
    Type = "Gun",
    Placement = "WaistRight",
    MeshId = "rbxassetid://7775027413",
    TextureId = "http://www.roblox.com/asset/?id=7775245551",
    Scale = Vector3.new(0.05999999865889549, 0.05999999865889549, 0.05999999865889549),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
    AttachmentPosition = Vector3.new(0.1299028992652893, 0.000002229222218375071, 0.07500199228525162),
    AttachmentOrientation = Vector3.new(-0.0026997302193194628, -60, 90.00231170654297),
    AttachmentAxis = Vector3.new(0.000020563602447509766, 1, -0.00005862116813659668),
    AttachmentSecondaryAxis = Vector3.new(-0.5, -0.00004048561822855845, -0.8660253882408142),
},
["Bat"] = {
    Type = "Knife",
    MeshId = "rbxassetid://11182796403",
    TextureId = "rbxassetid://11192090515",
    Scale = Vector3.new(0.07000000029802322, 0.07000000029802322, 0.07000000029802322),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    Chroma = false,
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
},
["ChromaLightbringer"] = {
    Type = "Gun",
    MeshId = "rbxassetid://4730813852",
    TextureId = "http://www.roblox.com/asset/?id=4728487789",
    Scale = Vector3.new(0.039000000804662704, 0.039000000804662704, 0.039000000804662704),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(5.4977863522831256e-15, -0.1866021752357483, 0.12320592254400253),
    AttachmentOrientation = Vector3.new(-80.00140380859375, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.17362435162067413, -0.9848120212554932),
    Chroma = true,
    ChromaTexture = "rbxassetid://4751498862",
    ChromaStaticLayer = "rbxassetid://18364488166",
},
["ChromaCandleflame"] = {
    Type = "Knife",
    MeshId = "rbxassetid://7791364860",
    TextureId = "rbxassetid://7791364988",
    Scale = Vector3.new(0.039000000804662704, 0.039000000804662704, 0.039000000804662704),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
	Placement = "WaistLeft",
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(5.4977863522831256e-15, -0.1866021752357483, 0.12320592254400253),
    AttachmentOrientation = Vector3.new(-80.00140380859375, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.17362435162067413, -0.9848120212554932),
    Chroma = true,
    ChromaTexture = "rbxassetid://4751498862",
    ChromaStaticLayer = "rbxassetid://18364488166",
},
["Vampire's Gun"] = {
    Type = "Gun",
    MeshId = "rbxassetid://126591885289479",
    TextureId = "rbxassetid://104946799389637",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Slate,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, -0.20000000298023224, 0.08990859985351562),
    AttachmentOrientation = Vector3.new(-50.001827239990234, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.6427633166313171, -0.7660649418830872),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Raygun"] = {
    Type = "Gun",
    MeshId = "rbxassetid://115447220952926",
    TextureId = "rbxassetid://127881437685243",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Slate,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, -0.20000000298023224, 0.08990859985351562),
    AttachmentOrientation = Vector3.new(-50.001827239990234, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.6427633166313171, -0.7660649418830872),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Nightblade"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=103838505",
    TextureId = "http://www.roblox.com/asset/?id=103838996",
    Scale = Vector3.new(0.699999988079071, 0.44999998807907104, 0.5),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.38823530077934265, 0.37254902720451355, 0.3843137323856354),
    Material = Enum.Material.Plastic,
    Transparency = 0,
	Placement = "WaistLeft",
    Reflectance = 0,
    VertexColor = Vector3.new(0.4000000059604645, 0.4000000059604645, 0.4000000059604645),
    AttachmentPosition = Vector3.new(0.006067206151783466, 0.15098965167999268, 0.04653354361653328),
    AttachmentOrientation = Vector3.new(4.996701717376709, -0.15615952014923096, -0.17513397336006165),
    AttachmentAxis = Vector3.new(0.999992311000824, -0.0030450436752289534, 0.002459252253174782),
    AttachmentSecondaryAxis = Vector3.new(0.00281926360912621, 0.9961950778961182, 0.08710600435733795),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Icebreaker"] = {
    Type = "Knife",
    MeshId = "rbxassetid://6124173614",
    TextureId = "rbxassetid://6124173821",
    Scale = Vector3.new(1, 1, 1),
	Placement = "WaistLeft",
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Hallow's Edge"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset?id=179155055",
    TextureId = "http://www.roblox.com/asset?id=179155105",
    Scale = Vector3.new(0.550000011920929, 0.550000011920929, 0.5550000071525574),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Eternal IV"] = {
    Type = "Knife",
    MeshId = "rbxassetid://3132923779",
    TextureId = "http://www.roblox.com/asset/?id=4999951444",
    Scale = Vector3.new(0.949999988079071, 0.949999988079071, 0.949999988079071),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Icewing"] = {
    Type = "Knife",
    Placement = "WaistLeft",
    MeshId = "rbxassetid://3183449780",
    TextureId = "rbxassetid://2279588369",
    Scale = Vector3.new(0.08500000089406967, 0.08500000089406967, 0.08500000089406967),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0.00309753674082458, -0.009521819651126862, 0.20591194927692413),
    AttachmentOrientation = Vector3.new(-19.19320297241211, 179.1589813232422, 1.235748291015625),
    AttachmentAxis = Vector3.new(-0.9997638463973999, 0.02036745660007, -0.007585207931697369),
    AttachmentSecondaryAxis = Vector3.new(0.01673959381878376, 0.9441957473754883, 0.32895931601524353),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Peppermint"] = {
    Type = "Knife",
    MeshId = "rbxassetid://6085025295",
    TextureId = "http://www.roblox.com/asset/?id=6074789360",
    Scale = Vector3.new(0.05999999865889549, 0.05999999865889549, 0.05999999865889549),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Rainbow"] = {
    Type = "Knife",
    MeshId = "rbxassetid://12921240966",
    TextureId = "rbxassetid://12921241867",
    Scale = Vector3.new(0.05999999865889549, 0.05999999865889549, 0.05999999865889549),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
	Placement = "WaistLeft",
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Spirit"] = {
    Type = "Knife",
    MeshId = "rbxassetid://112444333460928",
    TextureId = "rbxassetid://131787177447081",
    Scale = Vector3.new(0.07999999821186066, 0.07999999821186066, 0.07999999821186066),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Slate,
    Transparency = 0,
    Reflectance = 0,
	Placement = "WaistLeft",
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["SeerChroma"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset?id=156092238",
    TextureId = "rbxassetid://3184059718",
    Scale = Vector3.new(0.699999988079071, 0.9100000262260437, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0.20000000298023224,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = true,
    ChromaTexture = "rbxassetid://3184061374",
    ChromaStaticLayer = "rbxassetid://18364485783",
},
["Swirly Gun"] = {
    Type = "Gun",
    MeshId = "rbxassetid://8310911339",
    TextureId = "rbxassetid://8293539377",
    Scale = Vector3.new(0.8999999761581421, 0.8999999761581421, 0.8999999761581421),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Fang"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=117500241",
    TextureId = "http://www.roblox.com/asset/?id=117500388",
    Scale = Vector3.new(0.4000000059604645, 0.3700000047683716, 0.3700000047683716),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.38823530077934265, 0.37254902720451355, 0.3843137323856354),
    Material = Enum.Material.Concrete,
    Transparency = 0,
    Reflectance = 0,
		Placement = "WaistLeft",
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(-9.536782954455703e-07, -9.536768175166799e-07, -9.536794323139475e-07),
    AttachmentOrientation = Vector3.new(0.06901711970567703, -92.26690673828125, 1.0130547285079956),
    AttachmentAxis = Vector3.new(-0.039569735527038574, 0.017680207267403603, 0.9990603923797607),
    AttachmentSecondaryAxis = Vector3.new(-0.0005041101248934865, 0.9998430609703064, -0.01771402359008789),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Cookieblade"] = {
    Type = "Knife",
    MeshId = "rbxassetid://6123168377",
    TextureId = "rbxassetid://6123168583",
    Scale = Vector3.new(1.2999999523162842, 1.2999999523162842, 1.2999999523162842),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0.20000000298023224,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Evergreen"] = {
    Type = "Knife",
    MeshId = "rbxassetid://15408280573",
    TextureId = "rbxassetid://15408244684",
    Scale = Vector3.new(0.004603884648531675, 0.004603884648531675, 0.004603884648531675),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(1, 0, 0),
	Placement = "WaistLeft",
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Slasher"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=283709822",
    TextureId = "http://www.roblox.com/asset/?id=313894904",
    Scale = Vector3.new(0.6000000238418579, 0.6000000238418579, 0.6000000238418579),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Icepiercer"] = {
    Type = "Gun",
    Placement = "WaistRight",
    MeshId = "rbxassetid://11868991644",
    TextureId = "rbxassetid://11869075814",
    Scale = Vector3.new(0.05999999865889549, 0.05999999865889549, 0.05999999865889549),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0.1299028992652893, 0.000002229222218375071, 0.07500199228525162),
    AttachmentOrientation = Vector3.new(-0.0026997302193194628, -60, 90.00231170654297),
    AttachmentAxis = Vector3.new(0.000020563602447509766, 1, -0.00005862116813659668),
    AttachmentSecondaryAxis = Vector3.new(-0.5, -0.00004048561822855845, -0.8660253882408142),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Purple Seer"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset?id=156092238",
    TextureId = "rbxassetid://3184063317",
    Scale = Vector3.new(0.699999988079071, 0.9100000262260437, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
	Placement = "WaistLeft",
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Snowstorm"] = {
    Type = "Knife",
    MeshId = "rbxassetid://86944837615327",
    TextureId = "rbxassetid://84853425379784",
    Scale = Vector3.new(0.07000000029802322, 0.07000000029802322, 0.07000000029802322),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Slate,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Blizzard"] = {
    Type = "Gun",
    MeshId = "rbxassetid://77235373292363",
    TextureId = "rbxassetid://131115493735176",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, -0.20000000298023224, 0.08990859985351562),
    AttachmentOrientation = Vector3.new(-50.001827239990234, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.6427633166313171, -0.7660649418830872),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Iceblaster"] = {
    Type = "Gun",
    MeshId = "rbxassetid://6125828567",
    TextureId = "rbxassetid://6120563948",
    Scale = Vector3.new(1, 1, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 1, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Ice Shard"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=188539751 ",
    TextureId = "http://www.roblox.com/asset/?id=188539820 ",
    Scale = Vector3.new(1.2000000476837158, 1.2000000476837158, 1.2000000476837158),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(-0.0099992910400033, -0.13704271614551544, -0.17640718817710876),
    AttachmentOrientation = Vector3.new(-85.05686950683594, -175.63331604003906, 179.4180908203125),
    AttachmentAxis = Vector3.new(0.9978162050247192, 0.0008751153945922852, -0.06604611873626709),
    AttachmentSecondaryAxis = Vector3.new(-0.06572528928518295, -0.08616232872009277, -0.9941107630729675),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Candy"] = {
    Type = "Knife",
    MeshId = "http://www.roblox.com/asset/?id=19040337",
    TextureId = "http://www.roblox.com/asset/?id=19040326",
    Scale = Vector3.new(1.100000023841858, 1.399999976158142, 1.100000023841858),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.8039215803146362, 0.8039215803146362, 0.8039215803146362),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Waves"] = {
    Type = "Knife",
    MeshId = "rbxassetid://13916938702",
    TextureId = "rbxassetid://13916939964",
    Scale = Vector3.new(0.09000000357627869, 0.09000000357627869, 0.09000000357627869),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Logchopper"] = {
    Type = "Knife",
    MeshId = "rbxassetid://4535643726",
    TextureId = "rbxassetid://4535641077",
    Scale = Vector3.new(1, 1, 1),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.06666667014360428, 0.06666667014360428, 0.06666667014360428),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
	Placement = "WaistLeft",
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Turkey"] = {
    Type = "Knife",
    MeshId = "rbxassetid://15320557481",
    TextureId = "rbxassetid://15320558272",
    Scale = Vector3.new(0.0560000017285347, 0.0560000017285347, 0.0560000017285347),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
},
["Evergun"] = {
    Type = "Gun",
    MeshId = "rbxassetid://15408863676",
    TextureId = "rbxassetid://15408849730",
    Scale = Vector3.new(0.019999999552965164, 0.019999999552965164, 0.019999999552965164),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    SurfaceColorMap = "",
    SurfaceMetalnessMap = "",
    SurfaceNormalMap = "",
    SurfaceRoughnessMap = "",
    SurfaceAlphaMode = Enum.AlphaMode.Overlay,
    AttachmentPosition = Vector3.new(0, -0.20000000298023224, 0.08990859985351562),
    AttachmentOrientation = Vector3.new(-50.001827239990234, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.6427633166313171, -0.7660649418830872),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
    ChromaFace = Enum.NormalId.Back,
    CloneVisualChildrenFromPlayer = "caribbeansseas",
},
["Celestial"] = {
    Type = "Knife",
    MeshId = "rbxassetid://109711282082830",
    TextureId = "rbxassetid://79010754957272",
    Scale = Vector3.new(0.07, 0.07, 0.07),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    SurfaceColorMap = "rbxassetid://120904608273443",
    SurfaceMetalnessMap = "rbxassetid://95735363537147",
    SurfaceNormalMap = "",
    SurfaceRoughnessMap = "rbxassetid://115560145086368",
    SurfaceAlphaMode = Enum.AlphaMode.Overlay,
    UseSurfaceAppearance = false,
    Placement = "Back",
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
    ChromaFace = Enum.NormalId.Back,
},
["Bauble"] = {
    Type = "Gun",
    MeshId = "rbxassetid://107813118898769",
    TextureId = "rbxassetid://137012201908941",
    Scale = Vector3.new(0.05000000074505806, 0.05000000074505806, 0.05000000074505806),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    SurfaceColorMap = "",
    SurfaceMetalnessMap = "",
    SurfaceNormalMap = "",
    SurfaceRoughnessMap = "",
    SurfaceAlphaMode = Enum.AlphaMode.Overlay,
    UseSurfaceAppearance = false,
    Placement = "WaistRight",
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
    ChromaFace = Enum.NormalId.Back,
},
["Heart Wand"] = {
    Type = "Knife",
    MeshId = "rbxassetid://77738838473091",
    TextureId = "rbxassetid://76246633927299",
    Scale = Vector3.new(0.07, 0.07, 0.07),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.5607843399047852, 0.13333334028720856, 0.13333334028720856),
    Material = Enum.Material.Brick,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    SurfaceColorMap = "rbxassetid://76246633927299",
    SurfaceMetalnessMap = "",
	    Placement = "WaistLeft",
    SurfaceNormalMap = "",
    SurfaceRoughnessMap = "",
    SurfaceAlphaMode = Enum.AlphaMode.Overlay,
    AttachmentPosition = Vector3.new(0, 0, 0),
    AttachmentOrientation = Vector3.new(-0, 0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(0, 1, 0),
    Chroma = false,
    ChromaTexture = "",
    ChromaStaticLayer = "",
    ChromaFace = Enum.NormalId.Back,
},
["Sunrise"] = {
    Type = "Gun",
    MeshId = "rbxassetid://109742397574153",
    TextureId = "rbxassetid://71731808219690",
    Scale = Vector3.new(0.04584595561027527, 0.04584595561027527, 0.04584595561027527),
    Offset = Vector3.new(0, 0, 0),
    Color = Color3.new(0.6392157077789307, 0.6352941393852234, 0.6470588445663452),
    Material = Enum.Material.Plastic,
    Transparency = 0,
    Reflectance = 0,
    VertexColor = Vector3.new(1, 1, 1),
    SurfaceColorMap = "",
    SurfaceMetalnessMap = "",
    SurfaceNormalMap = "",
    SurfaceRoughnessMap = "",
    SurfaceAlphaMode = Enum.AlphaMode.Overlay,
    AttachmentPosition = Vector3.new(0, -0.20000000298023224, 0.08990859985351562),
    AttachmentOrientation = Vector3.new(-50.001827239990234, -0, 0),
    AttachmentAxis = Vector3.new(1, 0, 0),
    AttachmentSecondaryAxis = Vector3.new(-0, 0.6427633166313171, -0.7660649418830872),
    Chroma = true,
    ChromaTexture = "rbxassetid://122480499480858",
    ChromaStaticLayer = "",
    ChromaFace = Enum.NormalId.Left,
},
}

WeaponVisuals["Evergreen"].VisualTree = EvergreenLightPartsVisualTree

local function getPlacementAttachment(character, placement)
    if placement == "Back" then
        return character:FindFirstChild("UpperTorso")
            and character.UpperTorso:FindFirstChild("KnifeBack")
    elseif placement == "WaistLeft" then
        return character:FindFirstChild("LowerTorso")
            and character.LowerTorso:FindFirstChild("KnifeBelt")
    elseif placement == "WaistRight" then
        return character:FindFirstChild("LowerTorso")
            and character.LowerTorso:FindFirstChild("GunBelt")
    end

    return nil
end

local function applyWeaponPlacement(character, display, entry)
    local placement = entry and entry.Placement
    if not placement then
        return
    end

    local displayAttachment = display:FindFirstChildOfClass("Attachment")
        or display:FindFirstChild("Attachment", true)

    local constraint = display:FindFirstChildOfClass("RigidConstraint")
        or display:FindFirstChild("RigidConstraint", true)

    if not displayAttachment or not constraint then
        warn("[Carti Hub] Display attachment/constraint missing for placement")
        return
    end

    if entry.AttachmentPosition then
        displayAttachment.Position = entry.AttachmentPosition
    end

    if entry.AttachmentOrientation then
        displayAttachment.Orientation = entry.AttachmentOrientation
    end

    if entry.AttachmentAxis then
        displayAttachment.Axis = entry.AttachmentAxis
    end

    if entry.AttachmentSecondaryAxis then
        displayAttachment.SecondaryAxis = entry.AttachmentSecondaryAxis
    end

    constraint.Attachment0 = displayAttachment

    local targetAttachment = getPlacementAttachment(character, placement)
    if not targetAttachment then
        warn("[Carti Hub] Placement attachment not found:", placement)
        return
    end

    constraint.Attachment1 = targetAttachment
end

local lastAppliedWeaponVisuals = {}
local lastAppliedWeaponDisplays = {}
local activeChromaLoops = {}

local function stopChromaLoop(display)
    activeChromaLoops[display] = nil
end

local function startChromaLoop(display, chromaDecal)
    if activeChromaLoops[display] == chromaDecal then
        return
    end

    activeChromaLoops[display] = chromaDecal

    task.spawn(function()
        local colors = {
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 255, 255),
            Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(255, 0, 255),
        }

        while activeChromaLoops[display] == chromaDecal and chromaDecal.Parent do
            for _, color in ipairs(colors) do
                if activeChromaLoops[display] ~= chromaDecal or not chromaDecal.Parent then
                    return
                end

                TweenService:Create(chromaDecal, TweenInfo.new(1, Enum.EasingStyle.Linear), {
                    Color3 = color,
                }):Play()

                task.wait(1)
            end
        end
    end)
end

local function getWeaponVisualEntry(itemId)
    if not itemId then
        return nil
    end

    local directEntry = WeaponVisuals[itemId]
    if directEntry then
        return directEntry
    end

    local weaponData = sync.Weapons and sync.Weapons[itemId]
    local displayName = weaponData and (weaponData.ItemName or weaponData.Name)

    if displayName and WeaponVisuals[displayName] then
        return WeaponVisuals[displayName]
    end

    return nil
end

local function getDisplayRefNameForWeapon(itemId, entry)
    if entry and entry.Type == "Gun" then
        return "DisplayRefGun"
    elseif entry and (entry.Type == "Knife" or entry.Type == "Sword") then
        return "DisplayRefKnife"
    end

    local weaponData = sync.Weapons and sync.Weapons[itemId]
    if weaponData and weaponData.ItemType == "Gun" then
        return "DisplayRefGun"
    end

    return "DisplayRefKnife"
end

local function entryUsesSurfaceAppearance(entry)
    return entry and entry.UseSurfaceAppearance == true
end

local function getDefaultPlacementForEntry(entry)
    if entry and entry.Placement then
        return entry.Placement
    end

    if entry and entry.Type == "Gun" then
        return "WaistRight"
    end

    return "Back"
end

local function getExistingConstraintAttachment1(display)
    local constraint = display:FindFirstChildOfClass("RigidConstraint")
        or display:FindFirstChild("RigidConstraint", true)

    return constraint and constraint.Attachment1
end

local function createMeshPartDisplayForSurfaceEntry(character, ref, oldDisplay, entry)
    if not entryUsesSurfaceAppearance(entry) or oldDisplay:IsA("MeshPart") then
        return oldDisplay
    end

    local oldAttachment1 = getExistingConstraintAttachment1(oldDisplay)
    local replacement = Instance.new("MeshPart")
    replacement.Name = oldDisplay.Name
    replacement.CFrame = oldDisplay.CFrame
    replacement.Anchored = false
    replacement.CanCollide = false
    replacement.Massless = true
    replacement.Color = oldDisplay.Color
    replacement.Material = oldDisplay.Material
    replacement.Transparency = oldDisplay.Transparency
    replacement.Reflectance = oldDisplay.Reflectance
    replacement.Parent = oldDisplay.Parent

    if entry.MeshId then
        pcall(function()
            replacement.MeshId = entry.MeshId
        end)
    end

    if entry.TextureId then
        pcall(function()
            replacement.TextureID = entry.TextureId
        end)
    end

    if entry.MeshPartSize then
        replacement.Size = entry.MeshPartSize
    elseif entry.Scale then
        replacement.Size = entry.Scale
    else
        replacement.Size = oldDisplay.Size
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "CustomAttachment"
    attachment.Position = entry.AttachmentPosition or Vector3.new(0, 0, 0)
    attachment.Orientation = entry.AttachmentOrientation or Vector3.new(0, 0, 0)
    attachment.Axis = entry.AttachmentAxis or Vector3.new(1, 0, 0)
    attachment.SecondaryAxis = entry.AttachmentSecondaryAxis or Vector3.new(0, 1, 0)
    attachment.Parent = replacement

    local targetAttachment = oldAttachment1 or getPlacementAttachment(character, getDefaultPlacementForEntry(entry))
    if targetAttachment then
        local constraint = Instance.new("RigidConstraint")
        constraint.Attachment0 = attachment
        constraint.Attachment1 = targetAttachment
        constraint.Parent = replacement
    else
        warn("[Carti Hub] Could not attach MeshPart surface replacement.")
    end

    ref.Value = replacement
    stopChromaLoop(oldDisplay)
    oldDisplay:Destroy()

    return replacement
end

local function createSpecialMeshDisplayForForcedEntry(character, ref, oldDisplay, entry)
    if not entry or entry.UseSurfaceAppearance ~= false or not oldDisplay:IsA("MeshPart") then
        return oldDisplay
    end

    local oldAttachment1 = getExistingConstraintAttachment1(oldDisplay)
    local replacement = Instance.new("Part")
    replacement.Name = oldDisplay.Name
    replacement.CFrame = oldDisplay.CFrame
    replacement.Size = Vector3.new(1, 1, 1)
    replacement.Anchored = false
    replacement.CanCollide = false
    replacement.Massless = true
    replacement.Color = oldDisplay.Color
    replacement.Material = oldDisplay.Material
    replacement.Transparency = oldDisplay.Transparency
    replacement.Reflectance = oldDisplay.Reflectance
    replacement.Parent = oldDisplay.Parent

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = entry.MeshId or oldDisplay.MeshId
    mesh.TextureId = entry.TextureId or oldDisplay.TextureID
    mesh.Scale = entry.Scale or Vector3.new(1, 1, 1)
    mesh.Offset = entry.Offset or Vector3.new(0, 0, 0)
    mesh.VertexColor = entry.VertexColor or Vector3.new(1, 1, 1)
    mesh.Parent = replacement

    local attachment = Instance.new("Attachment")
    attachment.Name = "CustomAttachment"
    attachment.Position = entry.AttachmentPosition or Vector3.new(0, 0, 0)
    attachment.Orientation = entry.AttachmentOrientation or Vector3.new(0, 0, 0)
    attachment.Axis = entry.AttachmentAxis or Vector3.new(1, 0, 0)
    attachment.SecondaryAxis = entry.AttachmentSecondaryAxis or Vector3.new(0, 1, 0)
    attachment.Parent = replacement

    local targetAttachment = oldAttachment1 or getPlacementAttachment(character, getDefaultPlacementForEntry(entry))
    if targetAttachment then
        local constraint = Instance.new("RigidConstraint")
        constraint.Attachment0 = attachment
        constraint.Attachment1 = targetAttachment
        constraint.Parent = replacement
    else
        warn("[Carti Hub] Could not attach forced SpecialMesh display.")
    end

    ref.Value = replacement
    stopChromaLoop(oldDisplay)
    oldDisplay:Destroy()

    return replacement
end

local function cleanupPreviousWeaponDisplay(refName, currentDisplay, character)
    local previousDisplay = lastAppliedWeaponDisplays[refName]

    if not previousDisplay or previousDisplay == currentDisplay or not previousDisplay.Parent then
        return
    end

    if character and previousDisplay:IsDescendantOf(character) then
        stopChromaLoop(previousDisplay)
        previousDisplay:Destroy()
    end

    lastAppliedWeaponDisplays[refName] = nil
    lastAppliedWeaponVisuals[refName] = nil
end

local function shouldCloneVisualChild(instance)
    return instance:IsA("Attachment")
        or instance:IsA("Light")
        or instance:IsA("ParticleEmitter")
        or instance:IsA("Beam")
        or instance:IsA("Trail")
        or instance:IsA("Fire")
        or instance:IsA("Smoke")
        or instance:IsA("Sparkles")
        or instance:IsA("Highlight")
        or instance:IsA("Decal")
        or instance:IsA("Texture")
end

local function containsCloneableVisual(instance)
    if shouldCloneVisualChild(instance) then
        return true
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if shouldCloneVisualChild(descendant) then
            return true
        end
    end

    return false
end

local function stripUnsafeCloneDescendants(instance)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript")
            or descendant:IsA("RigidConstraint")
            or descendant:IsA("Weld")
            or descendant:IsA("WeldConstraint")
            or descendant:IsA("Motor6D")
            or descendant:IsA("SpecialMesh")
            or descendant:IsA("SurfaceAppearance") then
            descendant:Destroy()
        end
    end
end

local function markClonedVisualTree(instance)
    instance:SetAttribute("CartiHubClonedVisual", true)

    for _, descendant in ipairs(instance:GetDescendants()) do
        descendant:SetAttribute("CartiHubClonedVisual", true)
    end
end

local function clearClonedVisualChildren(display)
    for _, descendant in ipairs(display:GetDescendants()) do
        if descendant:GetAttribute("CartiHubClonedVisual") then
            descendant:Destroy()
        end
    end
end

local function cloneVisualChildrenFromPlayer(display, refName, sourcePlayerName)
    if not sourcePlayerName or sourcePlayerName == "" then
        return
    end

    local sourcePlayer = Players:FindFirstChild(sourcePlayerName)
    local sourceCharacter = sourcePlayer and sourcePlayer.Character
    local sourceRef = sourceCharacter and sourceCharacter:FindFirstChild(refName)
    local sourceDisplay = sourceRef and sourceRef.Value

    if not sourceDisplay then
        warn("[Carti Hub] Visual child source display missing:", tostring(sourcePlayerName), refName)
        return
    end

    clearClonedVisualChildren(display)

    for _, sourceChild in ipairs(sourceDisplay:GetChildren()) do
        if containsCloneableVisual(sourceChild) then
            local clone = sourceChild:Clone()
            stripUnsafeCloneDescendants(clone)
            markClonedVisualTree(clone)
            clone.Parent = display
        end
    end
end

local function findVisualParent(display, path)
    local parent = display

    for _, name in ipairs(path or {}) do
        parent = parent:FindFirstChild(name)
        if not parent then
            return nil
        end
    end

    return parent
end

local function applyExportedVisualChildren(display, visualChildren)
    if type(visualChildren) ~= "table" then
        return false
    end

    clearClonedVisualChildren(display)

    for _, visualData in ipairs(visualChildren) do
        local className = visualData.ClassName
        local properties = visualData.Properties
        local parent = findVisualParent(display, visualData.Path)

        if type(className) == "string" and type(properties) == "table" and parent then
            local ok, visual = pcall(Instance.new, className)
            if ok and visual then
                for propertyName, value in pairs(properties) do
                    pcall(function()
                        visual[propertyName] = value
                    end)
                end

                markClonedVisualTree(visual)
                visual.Parent = parent
            end
        else
            warn("[Carti Hub] Could not apply exported visual child:", tostring(className))
        end
    end

    return true
end

local function applyExportedVisualTree(display, visualTree)
    if type(visualTree) ~= "table" then
        return false
    end

    clearClonedVisualChildren(display)

    for _, visualData in ipairs(visualTree) do
        local className = visualData.ClassName
        local properties = visualData.Properties
        local parent = findVisualParent(display, visualData.Path)

        if type(className) == "string" and type(properties) == "table" and parent then
            local ok, visual = pcall(Instance.new, className)
            if ok and visual then
                for propertyName, value in pairs(properties) do
                    pcall(function()
                        visual[propertyName] = value
                    end)
                end

                if visual:IsA("BasePart") then
                    visual.Anchored = false
                    visual.CanCollide = false
                    visual.Massless = true

                    if typeof(visualData.RelativeCFrame) == "CFrame" then
                        visual.CFrame = display.CFrame * visualData.RelativeCFrame
                    end
                end

                markClonedVisualTree(visual)
                visual.Parent = parent

                if visual:IsA("BasePart") then
                    local weld = Instance.new("Weld")
                    weld.Name = "CartiHubVisualWeld"
                    weld.Part0 = display
                    weld.Part1 = visual
                    weld.C0 = typeof(visualData.RelativeCFrame) == "CFrame"
                        and visualData.RelativeCFrame
                        or display.CFrame:ToObjectSpace(visual.CFrame)
                    weld.C1 = CFrame.new()
                    weld.Parent = visual
                    weld:SetAttribute("CartiHubClonedVisual", true)
                end
            end
        else
            warn("[Carti Hub] Could not apply exported visual-tree node:", tostring(className))
        end
    end

    return true
end

local function applyWeaponVisual(itemId)
    local entry = getWeaponVisualEntry(itemId)
    if not entry then
        return false
    end

    local char = localPlayer.Character
    if not char then
        return false
    end

    local refName = getDisplayRefNameForWeapon(itemId, entry)
    local ref = char:FindFirstChild(refName)
    local display = ref and ref.Value

    if not display then
        return false
    end

    cleanupPreviousWeaponDisplay(refName, display, char)

    display = createSpecialMeshDisplayForForcedEntry(char, ref, display, entry)
    display = createMeshPartDisplayForSurfaceEntry(char, ref, display, entry)
    applyWeaponPlacement(char, display, entry)

    local visualKey = refName .. ":" .. tostring(itemId) .. ":" .. tostring(entry.Placement)
    if lastAppliedWeaponVisuals[refName] == visualKey and lastAppliedWeaponDisplays[refName] == display then
        return true
    end

    if entry.Color then
        display.Color = entry.Color
    end

    if entry.Material then
        display.Material = entry.Material
    end

    if entry.Transparency ~= nil then
        display.Transparency = entry.Transparency
    end

    if entry.Reflectance ~= nil then
        display.Reflectance = entry.Reflectance
    end

    if display:IsA("MeshPart") then
        if entry.MeshId then
            display.MeshId = entry.MeshId
        end

        if entry.TextureId then
            display.TextureID = entry.TextureId
        end

        if entry.SurfaceColorMap
            or entry.SurfaceMetalnessMap
            or entry.SurfaceNormalMap
            or entry.SurfaceRoughnessMap
            or entry.SurfaceAlphaMode then

            local surfaceAppearance = display:FindFirstChildOfClass("SurfaceAppearance")
            if not surfaceAppearance then
                surfaceAppearance = Instance.new("SurfaceAppearance")
                surfaceAppearance.Name = "SurfaceAppearance"
                surfaceAppearance.Parent = display
            end

            if entry.SurfaceColorMap ~= nil then
                surfaceAppearance.ColorMap = entry.SurfaceColorMap
            end

            if entry.SurfaceMetalnessMap ~= nil then
                surfaceAppearance.MetalnessMap = entry.SurfaceMetalnessMap
            end

            if entry.SurfaceNormalMap ~= nil then
                surfaceAppearance.NormalMap = entry.SurfaceNormalMap
            end

            if entry.SurfaceRoughnessMap ~= nil then
                surfaceAppearance.RoughnessMap = entry.SurfaceRoughnessMap
            end

            if entry.SurfaceAlphaMode then
                surfaceAppearance.AlphaMode = entry.SurfaceAlphaMode
            end
        end
    else
        local mesh = display:FindFirstChildOfClass("SpecialMesh")
        if not mesh then
            return false
        end

        if entry.MeshId then
            mesh.MeshId = entry.MeshId
        end

        if entry.TextureId then
            mesh.TextureId = entry.TextureId
        end

        if entry.Scale then
            mesh.Scale = entry.Scale
        end

        if entry.VertexColor then
            mesh.VertexColor = entry.VertexColor
        end

        mesh.Offset = entry.Offset or Vector3.new(0, 0, 0)
    end

    if entry.Chroma then
        local chromaDecal = display:FindFirstChild("Chroma", true)

        if not chromaDecal then
            chromaDecal = Instance.new("Decal")
            chromaDecal.Name = "Chroma"
            chromaDecal.Parent = display
        end

        chromaDecal.Face = entry.ChromaFace or Enum.NormalId.Back

        if entry.ChromaTexture and entry.ChromaTexture ~= "" then
            chromaDecal.Texture = entry.ChromaTexture
        end

        if entry.ChromaStaticLayer and entry.ChromaStaticLayer ~= "" then
            chromaDecal:SetAttribute("StaticLayer", entry.ChromaStaticLayer)
        end

        chromaDecal.Color3 = Color3.fromRGB(255, 0, 0)
        startChromaLoop(display, chromaDecal)
    else
        stopChromaLoop(display)
    end

    if entry.VisualTree then
        applyExportedVisualTree(display, entry.VisualTree)
    elseif entry.VisualChildren then
        applyExportedVisualChildren(display, entry.VisualChildren)
    else
        cloneVisualChildrenFromPlayer(display, refName, entry.CloneVisualChildrenFromPlayer)
    end

    lastAppliedWeaponVisuals[refName] = visualKey
    lastAppliedWeaponDisplays[refName] = display
    return true
end

local function getLocalEquippedWeaponIds()
    local equipped = profileData.Weapons and profileData.Weapons.Equipped
    local ids = {}

    if type(equipped) ~= "table" then
        return ids
    end

    for _, itemId in pairs(equipped) do
        if type(itemId) == "string" then
            table.insert(ids, itemId)
        end
    end

    return ids
end

local function applyEquippedWeaponVisuals()
    for _, itemId in ipairs(getLocalEquippedWeaponIds()) do
        applyWeaponVisual(itemId)
    end
end

task.spawn(function()
    local lastSignature = ""

    while SakaUI == nil or SakaUI.Parent ~= nil do
        local equippedIds = getLocalEquippedWeaponIds()
        table.sort(equippedIds)

        local signature = table.concat(equippedIds, "|")
        if signature ~= lastSignature then
            lastSignature = signature
            lastAppliedWeaponVisuals = {}
            lastAppliedWeaponDisplays = {}
            applyEquippedWeaponVisuals()
        else
            applyEquippedWeaponVisuals()
        end

        task.wait(0.35)
    end
end)

local function findWeaponInDatabase(weaponName)
    if not weaponName or weaponName == "" then
        return nil
    end

    local searchName = tostring(weaponName):lower():gsub("[^%w]", "")

    local function search(container, itemType)
        local bestItemId, bestDisplayName, bestScore = nil, nil, -1

        for itemId, data in pairs(container or {}) do
            if type(data) == "table" then
                local displayName = data.ItemName or data.Name or itemId
                local idText = tostring(itemId):lower():gsub("[^%w]", "")
                local nameText = tostring(displayName):lower():gsub("[^%w]", "")
                local score = -1

                if idText == searchName then
                    score = 100
                elseif nameText == searchName then
                    score = 90
                elseif idText:find(searchName, 1, true) or nameText:find(searchName, 1, true) then
                    score = 10
                end

                -- Prefer the actual Godly/Ancient item when cosmetic variants share a name.
                if score >= 0 then
                    if data.Rarity == "Ancient" then
                        score += 8
                    elseif data.Rarity == "Godly" then
                        score += 6
                    elseif data.Rarity == "Unique" then
                        score -= 6
                    end

                    if idText:find("silver", 1, true)
                        or idText:find("gold", 1, true)
                        or idText:find("bronze", 1, true)
                        or idText:find("purple", 1, true) then
                        score -= 12
                    end

                    if score > bestScore then
                        bestItemId, bestDisplayName, bestScore = itemId, displayName, score
                    end
                end
            end
        end

        if bestItemId then
            return bestItemId, itemType, bestDisplayName
        end
    end

    local itemId, itemType, displayName = search(sync.Weapons, "Weapons")
    if itemId then
        return itemId, itemType, displayName
    end

    return search(sync.Item, "Item")
end

local function spawnWeapon(weaponNameOrId, amount)
    local itemId, itemType, displayName = findWeaponInDatabase(weaponNameOrId)

    if not itemId then
        warn("[Carti Hub] Weapon not found: " .. tostring(weaponNameOrId))
        return false
    end

    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    if not getProfileOwnedTable(itemType) then
        warn("[Carti Hub] Could not find owned table for type: " .. tostring(itemType))
        return false
    end

    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)

    refreshMainInventoryNow()

    for _ = 1, math.min(amount, 10) do
        pcall(function()
            itemPopupService:AddNewItem(itemId, itemType, 1)
        end)
    end

    return true
end

local function spawnWeaponById(itemId, itemType, amount)
    local itemData = sync[itemType] and sync[itemType][itemId]

    if not itemData then
        warn(("[Carti Hub] Weapon id not found: %s/%s"):format(tostring(itemType), tostring(itemId)))
        return false
    end

    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    if not getProfileOwnedTable(itemType) then
        warn("[Carti Hub] Could not find owned table for type: " .. tostring(itemType))
        return false
    end

    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)

    refreshMainInventoryNow()

    for _ = 1, math.min(amount, 10) do
        pcall(function()
            itemPopupService:AddNewItem(itemId, itemType, 1)
        end)
    end

    local displayName = itemData.ItemName or itemData.Name or itemId
    return true
end

local function spawnWeaponByIdNoPopup(itemId, itemType, amount)
    local itemData = sync[itemType] and sync[itemType][itemId]

    if not itemData then
        warn(("[Carti Hub] Weapon id not found: %s/%s"):format(tostring(itemType), tostring(itemId)))
        return false
    end

    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    if not getProfileOwnedTable(itemType) then
        warn("[Carti Hub] Could not find owned table for type: " .. tostring(itemType))
        return false
    end

    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)

    refreshMainInventoryNow()

    local displayName = itemData.ItemName or itemData.Name or itemId
    return true
end

local function normalizeItemText(value)
    return tostring(value or ""):lower():gsub("[^%w%?]", "")
end

local excludedBulkSpawnNames = {
    ["???"] = true,
    ["chroma???"] = true,
    ["bronzeraygun"] = true,
    ["goldraygun"] = true,
    ["redraygun"] = true,
    ["silverraygun"] = true,
    ["synthwave"] = true,
    ["niksscythe"] = true,
    ["gingerscythe"] = true,
    ["icecrusher"] = true,
    ["reaver"] = true,
}

local function isExcludedFromBulkSpawn(itemId, data)
    local idText = normalizeItemText(itemId)
    local nameText = normalizeItemText(data and (data.ItemName or data.Name))

    if excludedBulkSpawnNames[idText] or excludedBulkSpawnNames[nameText] then
        return true
    end

    return idText:find("exo", 1, true) ~= nil or nameText:find("exo", 1, true) ~= nil
end

local function spawnAllGodlyWeapons(amount)
    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    local spawnedCount = 0
    local seen = {}

    local function collect(container, itemType)
        for itemId, data in pairs(container or {}) do
            if type(data) == "table"
                and data.Rarity == "Godly"
                and not isExcludedFromBulkSpawn(itemId, data)
                and not seen[itemId] then
                seen[itemId] = true

                if getProfileOwnedTable(itemType) then
                    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)
                    spawnedCount += 1
                end
            end
        end
    end

    collect(sync.Weapons, "Weapons")
    collect(sync.Item, "Item")
    refreshMainInventoryNow()

    return spawnedCount
end

local function spawnAllAncientWeapons(amount)
    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    local spawnedCount = 0
    local seen = {}

    local function collect(container, itemType)
        for itemId, data in pairs(container or {}) do
            if type(data) == "table"
                and data.Rarity == "Ancient"
                and not isExcludedFromBulkSpawn(itemId, data)
                and not seen[itemId] then
                seen[itemId] = true

                if getProfileOwnedTable(itemType) then
                    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)
                    spawnedCount += 1
                end
            end
        end
    end

    collect(sync.Weapons, "Weapons")
    collect(sync.Item, "Item")
    refreshMainInventoryNow()

    return spawnedCount
end

local function isChromaWeapon(itemId, data)
    if type(data) ~= "table" then
        return false
    end

    local chromaTexture = data.ChromaTexture
    local chromaStaticLayer = data.ChromaStaticLayer
    local hasChromaTexture = chromaTexture ~= nil
        and chromaTexture ~= false
        and tostring(chromaTexture) ~= ""
    local hasChromaStaticLayer = chromaStaticLayer ~= nil
        and chromaStaticLayer ~= false
        and tostring(chromaStaticLayer) ~= ""

    if data.Chroma == true
        or data.IsChroma == true
        or hasChromaTexture
        or hasChromaStaticLayer then
        return true
    end

    local idText = tostring(itemId):lower()
    local nameText = tostring(data.ItemName or data.Name or ""):lower()

    return idText:find("chroma", 1, true) ~= nil
        or nameText:find("chroma", 1, true) ~= nil
end

local function spawnAllChromaWeapons(amount)
    amount = tonumber(amount) or 1
    amount = math.max(1, amount)

    local spawnedCount = 0
    local seen = {}

    local function collect(container, itemType)
        for itemId, data in pairs(container or {}) do
            if isChromaWeapon(itemId, data)
                and not isExcludedFromBulkSpawn(itemId, data)
                and not seen[itemId] then
                seen[itemId] = true

                if getProfileOwnedTable(itemType) then
                    CartiHubAddFakeInventoryAmount(itemId, itemType, amount)
                    spawnedCount += 1
                end
            end
        end
    end

    collect(sync.Weapons, "Weapons")
    collect(sync.Item, "Item")
    refreshMainInventoryNow()

    return spawnedCount
end

local function getRarityColor(rarity)
    local rarities = sync.Rarities or sync.Rarity
    local rarityData = rarities and rarities[rarity]

    if rarityData then
        if typeof(rarityData.Color) == "Color3" then
            return rarityData.Color
        end

        if type(rarityData.Hex) == "string" then
            local hex = rarityData.Hex:gsub("#", "")
            if #hex == 6 then
                return Color3.fromRGB(
                    tonumber(hex:sub(1, 2), 16),
                    tonumber(hex:sub(3, 4), 16),
                    tonumber(hex:sub(5, 6), 16)
                )
            end
        end
    end

    return Color3.fromRGB(83, 220, 255)
end

local function isSpawnerRarity(data)
    return data.Rarity == "Godly" or data.Rarity == "Ancient"
end

local function textHasEvoToken(text)
    text = tostring(text or ""):lower()
    return text == "evo"
        or text:find("^evo[%s_%-%./]") ~= nil
        or text:find("[%s_%-%./]evo[%s_%-%./]") ~= nil
        or text:find("[%s_%-%./]evo$") ~= nil
end

local function isEvoOrUntradeableWeapon(itemId, itemType)
    local data = sync[itemType] and sync[itemType][itemId]
    if type(data) ~= "table" then
        return false
    end

    if data.Tradeable == false
        or data.Tradable == false
        or data.NotTradeable == true
        or data.Untradeable == true
        or data.Untradable == true
        or data.IsEvo == true
        or data.Evo ~= nil
        or data.Evolution ~= nil
        or data.EvoData ~= nil
        or data.EvoBase ~= nil then
        return true
    end

    if data.EvoBaseID ~= nil
        or data.EvoIndex ~= nil
        or data.EvoLevel ~= nil
        or data.EvoLevels ~= nil
        or data.EvoXP ~= nil
        or data.EvolutionData ~= nil then
        return true
    end

    return textHasEvoToken(itemId)
        or textHasEvoToken(data.ItemName)
        or textHasEvoToken(data.Name)
end

local function canFakeTradeItem(itemId, itemType)
    return not isEvoOrUntradeableWeapon(itemId, itemType)
end

local function isOfferSpawnerWeapon(data)
    if type(data) ~= "table" then
        return false
    end

    if data.Rarity == "Unique" then
        return false
    end

    if data.Rarity ~= "Godly" and data.Rarity ~= "Ancient" then
        return false
    end

    local itemType = tostring(data.ItemType or data.Type or ""):lower()
    return itemType == "knife" or itemType == "sword" or itemType == "gun"
end

local SpawnerImageOverrides = {
    ["Chroma Icecream"] = "rbxthumb://type=Asset&w=150&h=150&id=90300177211738",
    ["Chroma Beachy"] = "rbxthumb://type=Asset&w=150&h=150&id=134952503728391",
    ["Chroma Sands"] = "rbxthumb://type=Asset&w=150&h=150&id=104927341820800",
    IcecreamChroma = "rbxthumb://type=Asset&w=150&h=150&id=90300177211738",
    BeachyChroma = "rbxthumb://type=Asset&w=150&h=150&id=134952503728391",
    SandsChroma = "rbxthumb://type=Asset&w=150&h=150&id=104927341820800",
}

task.spawn(function()
    pcall(function()
        game:GetService("ContentProvider"):PreloadAsync({
            SpawnerImageOverrides.IcecreamChroma,
            SpawnerImageOverrides.BeachyChroma,
            SpawnerImageOverrides.SandsChroma,
        })
    end)
end)

local function getSpawnerThumbnail(itemId, itemData)
    local displayName = itemData and (itemData.ItemName or itemData.Name) or itemId
    return SpawnerImageOverrides[displayName]
        or SpawnerImageOverrides[itemId]
        or (itemData and itemData.Image)
        or ""
end

local addSpecificItemToTheirOffer
local removeLastTheirOffer

local oldUi = safeParent():FindFirstChild("SakaModMenu")
if oldUi then
    oldUi:Destroy()
end

do
    local oldNebulaUi = safeParent():FindFirstChild("CartiHubNebula")
    if oldNebulaUi then
        oldNebulaUi:Destroy()
    end
end

SakaUI = Instance.new("ScreenGui")
SakaUI.Name = "SakaModMenu"
SakaUI.ResetOnSpawn = false
SakaUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SakaUI.Parent = safeParent()

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 448, 0, 540)
MainFrame.Position = UDim2.new(0.78, -224, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 4, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = SakaUI

local Gradient = Instance.new("UIGradient")
Gradient.Rotation = 25
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 17, 27)),
    ColorSequenceKeypoint.new(0.24, Color3.fromRGB(8, 61, 70)),
    ColorSequenceKeypoint.new(0.52, Color3.fromRGB(9, 37, 78)),
    ColorSequenceKeypoint.new(0.77, Color3.fromRGB(58, 15, 78)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 8, 38)),
})
Gradient.Parent = MainFrame
Gradient.Enabled = false

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
MainFrame.ClipsDescendants = true

local BorderStroke = Instance.new("UIStroke")
BorderStroke.Color = Color3.fromRGB(255, 255, 255)
BorderStroke.Thickness = 1
BorderStroke.Transparency = 0.9
BorderStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -154, 0, 34)
Title.Position = UDim2.new(0, 112, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "t.me/cartiscripts"
Title.TextColor3 = Color3.fromRGB(231, 222, 242)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 3)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 128, 207)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function()
    SakaUI:Destroy()
end)

local TopbarDivider = Instance.new("Frame")
TopbarDivider.Size = UDim2.new(1, 0, 0, 1)
TopbarDivider.Position = UDim2.new(0, 0, 0, 34)
TopbarDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopbarDivider.BackgroundTransparency = 0.94
TopbarDivider.BorderSizePixel = 0
TopbarDivider.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 100, 1, -128)
TabContainer.Position = UDim2.new(0, 8, 0, 76)
TabContainer.BackgroundColor3 = Color3.fromRGB(16, 5, 30)
TabContainer.BackgroundTransparency = 0
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIGridLayout")
TabLayout.CellSize = UDim2.new(1, -8, 0, 38)
TabLayout.CellPadding = UDim2.new(0, 0, 0, 4)
TabLayout.FillDirectionMaxCells = 1
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabContainer

local function CreateTabBtn(text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(19, 7, 33)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(177, 157, 197)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.LayoutOrder = order
    btn.Parent = TabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    return btn
end

local function CreateTabFrame()
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -128, 1, -62)
    frame.Position = UDim2.new(0, 116, 0, 50)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 3
    frame.CanvasSize = UDim2.new(0, 0, 1.45, 0)
    frame.Visible = false
    frame.Parent = MainFrame

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = frame

    return frame
end

local function CreateBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = Color3.fromRGB(20, 8, 34)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(132, 112, 151)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(242, 231, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(186, 163, 211)
    stroke.Thickness = 1
    stroke.Transparency = 0.82
    stroke.Parent = box

    return box
end

local function CreateBtn(parent, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = BUTTON_COLOR
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = BUTTON_HOVER_COLOR }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = BUTTON_COLOR }):Play()
    end)

    return btn
end

local function CreateSlider(parent, text, min, max, defaultVal, step, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. defaultVal
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(230, 200, 255)
    label.TextSize = 13
    label.Parent = container

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -10, 0, 10)
    bg.Position = UDim2.new(0, 5, 0, 28)
    bg.BackgroundColor3 = Color3.fromRGB(13, 22, 46)
    bg.Parent = container
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = BUTTON_COLOR
    fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 34, 0, 18)
    knob.Position = UDim2.new(1, -17, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(210, 245, 255)
    knob.Text = tostring(defaultVal)
    knob.TextColor3 = Color3.fromRGB(15, 25, 52)
    knob.Font = Enum.Font.GothamBold
    knob.TextSize = 10
    knob.Parent = fill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    knob.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation().X
            local startX = bg.AbsolutePosition.X
            local percent = math.clamp((mousePos - startX) / bg.AbsoluteSize.X, 0, 1)
            local rawVal = min + ((max - min) * percent)
            local val = math.floor(rawVal / step + 0.5) * step
            val = math.clamp(val, min, max)

            fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            label.Text = text .. ": " .. val
            knob.Text = tostring(val)
            callback(val)
        end
    end)
end

local SpawnerTabBtn = CreateTabBtn("Spawner", 1)
local TradeTabBtn = CreateTabBtn("Trade", 2)
UpgradingTabBtn = CreateTabBtn("Upgrading", 3)
BlockTabBtn = CreateTabBtn("Block", 4)
local SettingsTabBtn = CreateTabBtn("Settings", 5)
local KeybindsTabBtn = CreateTabBtn("Keys", 6)

local SpawnerFrame = CreateTabFrame()
local TradeFrame = CreateTabFrame()
UpgradingFrame = CreateTabFrame()
BlockFrame = CreateTabFrame()
local SettingsFrame = CreateTabFrame()
local KeybindsFrame = CreateTabFrame()
SpawnerFrame.Visible = true
SpawnerTabBtn.BackgroundColor3 = BUTTON_HOVER_COLOR

task.spawn(function()
    local wrapper = Instance.new("CanvasGroup")
    wrapper.Name = "CartiHubNebulaWrapper"
    wrapper.Size = UDim2.fromScale(1, 1)
    wrapper.BackgroundColor3 = Color3.fromRGB(13, 4, 24)
    wrapper.BorderSizePixel = 0
    wrapper.ZIndex = 1
    wrapper.Parent = MainFrame
    Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 8)

    local topbar = Instance.new("Frame")
    topbar.Name = "NebulaTopbar"
    topbar.Size = UDim2.new(1, 0, 0, 34)
    topbar.BackgroundColor3 = Color3.fromRGB(16, 5, 30)
    topbar.BorderSizePixel = 0
    topbar.ZIndex = 1
    topbar.Parent = wrapper
    Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 8)

    local topbarFill = Instance.new("Frame")
    topbarFill.Size = UDim2.new(1, 0, 0.5, 0)
    topbarFill.Position = UDim2.new(0, 0, 0.5, 0)
    topbarFill.BackgroundColor3 = Color3.fromRGB(16, 5, 30)
    topbarFill.BorderSizePixel = 0
    topbarFill.ZIndex = 1
    topbarFill.Parent = topbar

    local rail = Instance.new("Frame")
    rail.Name = "NebulaRibbon"
    rail.Size = UDim2.new(0, 108, 1, -42)
    rail.Position = UDim2.new(0, 4, 0, 38)
    rail.BackgroundColor3 = Color3.fromRGB(16, 5, 30)
    rail.BorderSizePixel = 0
    rail.ZIndex = 1
    rail.Parent = wrapper
    Instance.new("UICorner", rail).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Name = "NebulaPageCanvas"
    content.Size = UDim2.new(1, -122, 1, -46)
    content.Position = UDim2.new(0, 116, 0, 40)
    content.BackgroundColor3 = Color3.fromRGB(17, 6, 29)
    content.BorderSizePixel = 0
    content.ZIndex = 1
    content.Parent = wrapper
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 6)

    local sectionLine = Instance.new("Frame")
    sectionLine.Size = UDim2.new(1, -16, 0, 1)
    sectionLine.Position = UDim2.new(0, 8, 0, 32)
    sectionLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sectionLine.BackgroundTransparency = 0.94
    sectionLine.BorderSizePixel = 0
    sectionLine.ZIndex = 1
    sectionLine.Parent = rail

    local railTitle = Instance.new("TextLabel")
    railTitle.Size = UDim2.new(1, -16, 0, 20)
    railTitle.Position = UDim2.new(0, 8, 0, 7)
    railTitle.BackgroundTransparency = 1
    railTitle.Text = "CONTROL PANEL"
    railTitle.TextColor3 = Color3.fromRGB(121, 102, 140)
    railTitle.Font = Enum.Font.GothamBold
    railTitle.TextSize = 8
    railTitle.TextXAlignment = Enum.TextXAlignment.Left
    railTitle.ZIndex = 2
    railTitle.Parent = rail

    local pageCaption = Instance.new("TextLabel")
    pageCaption.Size = UDim2.new(1, -20, 0, 20)
    pageCaption.Position = UDim2.new(0, 126, 0, 41)
    pageCaption.BackgroundTransparency = 1
    pageCaption.Text = "MM2 CLIENT CONTROLS"
    pageCaption.TextColor3 = Color3.fromRGB(132, 112, 151)
    pageCaption.Font = Enum.Font.GothamBold
    pageCaption.TextSize = 8
    pageCaption.TextXAlignment = Enum.TextXAlignment.Left
    pageCaption.ZIndex = 2
    pageCaption.Parent = MainFrame

    local profile = Instance.new("Frame")
    profile.Name = "NebulaProfile"
    profile.Size = UDim2.new(0, 92, 0, 42)
    profile.Position = UDim2.new(0, 12, 1, -48)
    profile.BackgroundColor3 = Color3.fromRGB(22, 8, 39)
    profile.BorderSizePixel = 0
    profile.ZIndex = 2
    profile.Parent = MainFrame
    Instance.new("UICorner", profile).CornerRadius = UDim.new(0, 5)

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 24, 0, 24)
    avatar.Position = UDim2.new(0, 7, 0.5, -12)
    avatar.BackgroundColor3 = Color3.fromRGB(41, 20, 61)
    avatar.BorderSizePixel = 0
    avatar.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(localPlayer.UserId)
    avatar.ZIndex = 3
    avatar.Parent = profile
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local username = Instance.new("TextLabel")
    username.Size = UDim2.new(1, -40, 0, 16)
    username.Position = UDim2.new(0, 36, 0, 6)
    username.BackgroundTransparency = 1
    username.Text = localPlayer.Name
    username.TextColor3 = Color3.fromRGB(225, 215, 238)
    username.Font = Enum.Font.GothamBold
    username.TextSize = 8
    username.TextTruncate = Enum.TextTruncate.AtEnd
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.ZIndex = 3
    username.Parent = profile

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 13)
    status.Position = UDim2.new(0, 36, 0, 21)
    status.BackgroundTransparency = 1
    status.Text = "SESSION ACTIVE"
    status.TextColor3 = Color3.fromRGB(149, 117, 178)
    status.Font = Enum.Font.Gotham
    status.TextSize = 7
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 3
    status.Parent = profile

    for _, tab in ipairs({ SpawnerTabBtn, TradeTabBtn, UpgradingTabBtn, BlockTabBtn, SettingsTabBtn, KeybindsTabBtn }) do
        tab.Position = UDim2.new(0, 4, 0, 0)
        tab.Size = UDim2.new(1, -8, 0, 38)
        tab.TextXAlignment = Enum.TextXAlignment.Left
        tab.TextColor3 = Color3.fromRGB(182, 160, 203)
        tab.ZIndex = 3

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.Parent = tab

        local accent = Instance.new("Frame")
        accent.Name = "NebulaActiveAccent"
        accent.Size = UDim2.new(0, 2, 0, 18)
        accent.Position = UDim2.new(0, 0, 0.5, -9)
        accent.BackgroundColor3 = Color3.fromRGB(185, 118, 255)
        accent.BorderSizePixel = 0
        accent.Visible = tab == SpawnerTabBtn
        accent.ZIndex = 4
        accent.Parent = tab
    end

    for _, root in ipairs({ Title, CloseBtn, TopbarDivider, TabContainer, SpawnerFrame, TradeFrame, UpgradingFrame, BlockFrame, SettingsFrame, KeybindsFrame }) do
        if root:IsA("GuiObject") then
            root.ZIndex = math.max(root.ZIndex, 3)
        end

        for _, descendant in ipairs(root:GetDescendants()) do
            if descendant:IsA("GuiObject") then
                descendant.ZIndex = math.max(descendant.ZIndex, 3)
            end
        end
    end
end)

CartiHubBlockSessionBox = CreateBox(BlockFrame, "RBXSECURITY session")
CartiHubBlockTrackerBox = CreateBox(BlockFrame, "RBXEventTrackerV2 value")
_G.CartiHubGetBlockCredentials = function()
    return CartiHubBlockSessionBox and CartiHubBlockSessionBox.Text or "",
        CartiHubBlockTrackerBox and CartiHubBlockTrackerBox.Text or "",
        ""
end

_G.CartiHubPlayerListBlockButtonsEnabled = false
CartiHubPlayerListBlockToggleBtn = CreateBtn(BlockFrame, "PLAYERLIST BLOCK: OFF")
CartiHubPlayerListBlockToggleBtn.MouseButton1Click:Connect(function()
    local enabled = not _G.CartiHubPlayerListBlockButtonsEnabled
    _G.CartiHubPlayerListBlockButtonsEnabled = enabled
    CartiHubPlayerListBlockToggleBtn.Text = enabled and "PLAYERLIST BLOCK: ON" or "PLAYERLIST BLOCK: OFF"
    CartiHubPlayerListBlockToggleBtn.BackgroundColor3 = enabled and BUTTON_HOVER_COLOR or BUTTON_COLOR

    local setEnabled = _G.CartiHubSetPlayerListBlockButtonsEnabled
    if type(setEnabled) == "function" then
        setEnabled(enabled)
    end
end)

local SPAWNER_COLS = 5
local SPAWNER_BOX_SIZE = 78
local SPAWNER_PADDING = 5
local SPAWNER_NAME_HEIGHT = 21
local SPAWNER_RARITY_HEIGHT = 18
local SPAWNER_SLIDER_HEIGHT = 54
local spawnerWidth = (SPAWNER_BOX_SIZE + SPAWNER_PADDING) * SPAWNER_COLS + SPAWNER_PADDING + 20

local SpawnerGuiFrame = Instance.new("Frame")
SpawnerGuiFrame.Name = "WeaponSpawnerGUI"
SpawnerGuiFrame.Size = UDim2.new(0, spawnerWidth, 0, 470)
SpawnerGuiFrame.Position = UDim2.new(0.5, -(spawnerWidth / 2), 0.5, -235)
SpawnerGuiFrame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
SpawnerGuiFrame.BorderSizePixel = 0
SpawnerGuiFrame.Active = true
SpawnerGuiFrame.Draggable = true
SpawnerGuiFrame.Visible = false
SpawnerGuiFrame.Parent = SakaUI
Instance.new("UICorner", SpawnerGuiFrame).CornerRadius = UDim.new(0, 10)

local PopupStroke = Instance.new("UIStroke")
PopupStroke.Color = Color3.fromRGB(83, 220, 255)
PopupStroke.Thickness = 1
PopupStroke.Transparency = 0.15
PopupStroke.Parent = SpawnerGuiFrame

local PopupTitle = Instance.new("TextLabel")
PopupTitle.Size = UDim2.new(1, -40, 0, 35)
PopupTitle.Position = UDim2.new(0, 15, 0, 5)
PopupTitle.BackgroundTransparency = 1
PopupTitle.Text = "Weapon Spawner"
PopupTitle.TextColor3 = Color3.fromRGB(210, 245, 255)
PopupTitle.Font = Enum.Font.GothamBold
PopupTitle.TextSize = 18
PopupTitle.TextXAlignment = Enum.TextXAlignment.Left
PopupTitle.Parent = SpawnerGuiFrame

local PopupCloseBtn = Instance.new("TextButton")
PopupCloseBtn.Size = UDim2.new(0, 28, 0, 28)
PopupCloseBtn.Position = UDim2.new(1, -38, 0, 6)
PopupCloseBtn.BackgroundTransparency = 1
PopupCloseBtn.Text = "X"
PopupCloseBtn.TextColor3 = Color3.fromRGB(255, 128, 207)
PopupCloseBtn.Font = Enum.Font.GothamBold
PopupCloseBtn.TextSize = 18
PopupCloseBtn.Parent = SpawnerGuiFrame
PopupCloseBtn.MouseButton1Click:Connect(function()
    SpawnerGuiFrame.Visible = false
end)

local WeaponSearchBox = Instance.new("TextBox")
WeaponSearchBox.Size = UDim2.new(1, -16, 0, 30)
WeaponSearchBox.Position = UDim2.new(0, 8, 0, 42)
WeaponSearchBox.BackgroundColor3 = Color3.fromRGB(13, 22, 46)
WeaponSearchBox.BorderSizePixel = 0
WeaponSearchBox.PlaceholderText = "Search weapons..."
WeaponSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
WeaponSearchBox.Text = ""
WeaponSearchBox.TextColor3 = Color3.fromRGB(220, 240, 255)
WeaponSearchBox.Font = Enum.Font.Gotham
WeaponSearchBox.TextSize = 13
WeaponSearchBox.ClearTextOnFocus = false
WeaponSearchBox.Parent = SpawnerGuiFrame
Instance.new("UICorner", WeaponSearchBox).CornerRadius = UDim.new(0, 8)

local WeaponScrollFrame = Instance.new("ScrollingFrame")
WeaponScrollFrame.Size = UDim2.new(1, -10, 1, -(55 + SPAWNER_SLIDER_HEIGHT))
WeaponScrollFrame.Position = UDim2.new(0, 5, 0, 78)
WeaponScrollFrame.BackgroundTransparency = 1
WeaponScrollFrame.BorderSizePixel = 0
WeaponScrollFrame.ScrollBarThickness = 4
WeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
WeaponScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(83, 220, 255)
WeaponScrollFrame.Parent = SpawnerGuiFrame

local WeaponGrid = Instance.new("UIGridLayout")
WeaponGrid.CellSize = UDim2.new(0, SPAWNER_BOX_SIZE, 0, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
WeaponGrid.CellPadding = UDim2.new(0, SPAWNER_PADDING, 0, SPAWNER_PADDING)
WeaponGrid.FillDirectionMaxCells = SPAWNER_COLS
WeaponGrid.SortOrder = Enum.SortOrder.LayoutOrder
WeaponGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
WeaponGrid.Parent = WeaponScrollFrame

WeaponGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, WeaponGrid.AbsoluteContentSize.Y + 10)
end)

local PopupSliderFrame = Instance.new("Frame")
PopupSliderFrame.Size = UDim2.new(1, -16, 0, SPAWNER_SLIDER_HEIGHT)
PopupSliderFrame.Position = UDim2.new(0, 8, 1, -(SPAWNER_SLIDER_HEIGHT + 6))
PopupSliderFrame.BackgroundColor3 = Color3.fromRGB(12, 21, 45)
PopupSliderFrame.BorderSizePixel = 0
PopupSliderFrame.Parent = SpawnerGuiFrame
Instance.new("UICorner", PopupSliderFrame).CornerRadius = UDim.new(0, 10)

local PopupAmountLabel = Instance.new("TextLabel")
PopupAmountLabel.Size = UDim2.new(1, -16, 0, 20)
PopupAmountLabel.Position = UDim2.new(0, 8, 0, 4)
PopupAmountLabel.BackgroundTransparency = 1
PopupAmountLabel.Text = "Spawn Amount: " .. currentWeaponAmount
PopupAmountLabel.TextColor3 = Color3.fromRGB(210, 245, 255)
PopupAmountLabel.Font = Enum.Font.GothamBold
PopupAmountLabel.TextSize = 13
PopupAmountLabel.TextXAlignment = Enum.TextXAlignment.Left
PopupAmountLabel.Parent = PopupSliderFrame

local PopupSliderTrack = Instance.new("Frame")
PopupSliderTrack.Size = UDim2.new(1, -22, 0, 10)
PopupSliderTrack.Position = UDim2.new(0, 11, 0, 32)
PopupSliderTrack.BackgroundColor3 = Color3.fromRGB(30, 12, 55)
PopupSliderTrack.BorderSizePixel = 0
PopupSliderTrack.Parent = PopupSliderFrame
Instance.new("UICorner", PopupSliderTrack).CornerRadius = UDim.new(1, 0)

local PopupSliderFill = Instance.new("Frame")
PopupSliderFill.Size = UDim2.new(0, 0, 1, 0)
PopupSliderFill.BackgroundColor3 = BUTTON_COLOR
PopupSliderFill.BorderSizePixel = 0
PopupSliderFill.Parent = PopupSliderTrack
Instance.new("UICorner", PopupSliderFill).CornerRadius = UDim.new(1, 0)

local PopupSliderKnob = Instance.new("TextButton")
PopupSliderKnob.Size = UDim2.new(0, 34, 0, 18)
PopupSliderKnob.Position = UDim2.new(0, -17, 0.5, -9)
PopupSliderKnob.BackgroundColor3 = Color3.fromRGB(210, 245, 255)
PopupSliderKnob.Text = tostring(currentWeaponAmount)
PopupSliderKnob.TextColor3 = Color3.fromRGB(15, 25, 52)
PopupSliderKnob.Font = Enum.Font.GothamBold
PopupSliderKnob.TextSize = 10
PopupSliderKnob.Parent = PopupSliderFill
Instance.new("UICorner", PopupSliderKnob).CornerRadius = UDim.new(1, 0)

local popupDraggingAmount = false

local function setPopupSpawnAmountFromPercent(percent)
    local minAmount = 1
    local maxAmount = MAX_WEAPON_AMOUNT
    percent = math.clamp(percent, 0, 1)

    local value = math.floor(minAmount + ((maxAmount - minAmount) * percent) + 0.5)
    value = math.clamp(value, minAmount, maxAmount)

    currentWeaponAmount = value
    PopupAmountLabel.Text = "Spawn Amount: " .. value
    PopupSliderKnob.Text = tostring(value)
    PopupSliderFill.Size = UDim2.new((value - minAmount) / (maxAmount - minAmount), 0, 1, 0)
end

PopupSliderKnob.MouseButton1Down:Connect(function()
    popupDraggingAmount = true
end)

PopupSliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local percent = (UserInputService:GetMouseLocation().X - PopupSliderTrack.AbsolutePosition.X) / PopupSliderTrack.AbsoluteSize.X
        setPopupSpawnAmountFromPercent(percent)
        popupDraggingAmount = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        popupDraggingAmount = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if popupDraggingAmount and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percent = (UserInputService:GetMouseLocation().X - PopupSliderTrack.AbsolutePosition.X) / PopupSliderTrack.AbsoluteSize.X
        setPopupSpawnAmountFromPercent(percent)
    end
end)

local function filterSpawnerCards(scrollFrame, query)
    query = tostring(query or ""):lower()

    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("GuiObject") and child:GetAttribute("SearchText") then
            child.Visible = query == "" or string.find(child:GetAttribute("SearchText"), query, 1, true) ~= nil
        end
    end
end

WeaponSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterSpawnerCards(WeaponScrollFrame, WeaponSearchBox.Text)
end)

local OFFER_SPAWNER_COLS = 4
local offerSpawnerWidth = (SPAWNER_BOX_SIZE + SPAWNER_PADDING) * OFFER_SPAWNER_COLS + SPAWNER_PADDING + 20

local OfferSpawnerGuiFrame = Instance.new("Frame")
OfferSpawnerGuiFrame.Name = "OfferSpawnerGUI"
OfferSpawnerGuiFrame.Size = UDim2.new(0, offerSpawnerWidth, 0, 470)
OfferSpawnerGuiFrame.Position = UDim2.new(0.5, -(offerSpawnerWidth / 2), 0.5, -235)
OfferSpawnerGuiFrame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
OfferSpawnerGuiFrame.BorderSizePixel = 0
OfferSpawnerGuiFrame.Active = true
OfferSpawnerGuiFrame.Draggable = true
OfferSpawnerGuiFrame.Visible = false
OfferSpawnerGuiFrame.Parent = SakaUI
Instance.new("UICorner", OfferSpawnerGuiFrame).CornerRadius = UDim.new(0, 10)

local OfferPopupStroke = Instance.new("UIStroke")
OfferPopupStroke.Color = Color3.fromRGB(83, 220, 255)
OfferPopupStroke.Thickness = 1
OfferPopupStroke.Transparency = 0.15
OfferPopupStroke.Parent = OfferSpawnerGuiFrame

local OfferPopupTitle = Instance.new("TextLabel")
OfferPopupTitle.Size = UDim2.new(1, -40, 0, 35)
OfferPopupTitle.Position = UDim2.new(0, 15, 0, 5)
OfferPopupTitle.BackgroundTransparency = 1
OfferPopupTitle.Text = "Offer Spawner"
OfferPopupTitle.TextColor3 = Color3.fromRGB(210, 245, 255)
OfferPopupTitle.Font = Enum.Font.GothamBold
OfferPopupTitle.TextSize = 18
OfferPopupTitle.TextXAlignment = Enum.TextXAlignment.Left
OfferPopupTitle.Parent = OfferSpawnerGuiFrame

local OfferPopupCloseBtn = Instance.new("TextButton")
OfferPopupCloseBtn.Size = UDim2.new(0, 28, 0, 28)
OfferPopupCloseBtn.Position = UDim2.new(1, -38, 0, 6)
OfferPopupCloseBtn.BackgroundTransparency = 1
OfferPopupCloseBtn.Text = "X"
OfferPopupCloseBtn.TextColor3 = Color3.fromRGB(255, 128, 207)
OfferPopupCloseBtn.Font = Enum.Font.GothamBold
OfferPopupCloseBtn.TextSize = 18
OfferPopupCloseBtn.Parent = OfferSpawnerGuiFrame
OfferPopupCloseBtn.MouseButton1Click:Connect(function()
    OfferSpawnerGuiFrame.Visible = false
end)

local OfferSearchBox = Instance.new("TextBox")
OfferSearchBox.Size = UDim2.new(1, -16, 0, 30)
OfferSearchBox.Position = UDim2.new(0, 8, 0, 42)
OfferSearchBox.BackgroundColor3 = Color3.fromRGB(13, 22, 46)
OfferSearchBox.BorderSizePixel = 0
OfferSearchBox.PlaceholderText = "Search offer items..."
OfferSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
OfferSearchBox.Text = ""
OfferSearchBox.TextColor3 = Color3.fromRGB(220, 240, 255)
OfferSearchBox.Font = Enum.Font.Gotham
OfferSearchBox.TextSize = 13
OfferSearchBox.ClearTextOnFocus = false
OfferSearchBox.Parent = OfferSpawnerGuiFrame
Instance.new("UICorner", OfferSearchBox).CornerRadius = UDim.new(0, 8)

local OfferWeaponScrollFrame = Instance.new("ScrollingFrame")
OfferWeaponScrollFrame.Size = UDim2.new(1, -10, 1, -138)
OfferWeaponScrollFrame.Position = UDim2.new(0, 5, 0, 78)
OfferWeaponScrollFrame.BackgroundTransparency = 1
OfferWeaponScrollFrame.BorderSizePixel = 0
OfferWeaponScrollFrame.ScrollBarThickness = 4
OfferWeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
OfferWeaponScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(83, 220, 255)
OfferWeaponScrollFrame.Parent = OfferSpawnerGuiFrame

local OfferWeaponGrid = Instance.new("UIGridLayout")
OfferWeaponGrid.CellSize = UDim2.new(0, SPAWNER_BOX_SIZE, 0, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
OfferWeaponGrid.CellPadding = UDim2.new(0, SPAWNER_PADDING, 0, SPAWNER_PADDING)
OfferWeaponGrid.FillDirectionMaxCells = OFFER_SPAWNER_COLS
OfferWeaponGrid.SortOrder = Enum.SortOrder.LayoutOrder
OfferWeaponGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
OfferWeaponGrid.Parent = OfferWeaponScrollFrame

OfferWeaponGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    OfferWeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, OfferWeaponGrid.AbsoluteContentSize.Y + 10)
end)

local OfferDeleteLastBtn = Instance.new("TextButton")
OfferDeleteLastBtn.Size = UDim2.new(1, -16, 0, 42)
OfferDeleteLastBtn.Position = UDim2.new(0, 8, 1, -50)
OfferDeleteLastBtn.BackgroundColor3 = BUTTON_COLOR
OfferDeleteLastBtn.Text = "DELETE LAST OFFER SLOT"
OfferDeleteLastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OfferDeleteLastBtn.Font = Enum.Font.GothamBold
OfferDeleteLastBtn.TextSize = 13
OfferDeleteLastBtn.Parent = OfferSpawnerGuiFrame
Instance.new("UICorner", OfferDeleteLastBtn).CornerRadius = UDim.new(0, 8)

OfferDeleteLastBtn.MouseEnter:Connect(function()
    TweenService:Create(OfferDeleteLastBtn, TweenInfo.new(0.2), { BackgroundColor3 = BUTTON_HOVER_COLOR }):Play()
end)

OfferDeleteLastBtn.MouseLeave:Connect(function()
    TweenService:Create(OfferDeleteLastBtn, TweenInfo.new(0.2), { BackgroundColor3 = BUTTON_COLOR }):Play()
end)

OfferDeleteLastBtn.MouseButton1Click:Connect(function()
    if removeLastTheirOffer then
        removeLastTheirOffer()
    end
end)

OfferSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterSpawnerCards(OfferWeaponScrollFrame, OfferSearchBox.Text)
end)

local RealisticSpawnerGuiFrame
local populateRealisticSpawner

do
    local selectedRealisticWeapons = {}
    local didPopulateRealisticSpawner = false

    RealisticSpawnerGuiFrame = Instance.new("Frame")
    RealisticSpawnerGuiFrame.Name = "RealisticSpawnerGUI"
    RealisticSpawnerGuiFrame.Size = UDim2.new(0, spawnerWidth, 0, 500)
    RealisticSpawnerGuiFrame.Position = UDim2.new(0.5, -(spawnerWidth / 2), 0.5, -250)
    RealisticSpawnerGuiFrame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
    RealisticSpawnerGuiFrame.BorderSizePixel = 0
    RealisticSpawnerGuiFrame.Active = true
    RealisticSpawnerGuiFrame.Draggable = true
    RealisticSpawnerGuiFrame.Visible = false
    RealisticSpawnerGuiFrame.Parent = SakaUI
    Instance.new("UICorner", RealisticSpawnerGuiFrame).CornerRadius = UDim.new(0, 10)

    local realisticStroke = Instance.new("UIStroke")
    realisticStroke.Color = Color3.fromRGB(83, 220, 255)
    realisticStroke.Thickness = 1
    realisticStroke.Transparency = 0.15
    realisticStroke.Parent = RealisticSpawnerGuiFrame

    local realisticTitle = Instance.new("TextLabel")
    realisticTitle.Size = UDim2.new(1, -40, 0, 35)
    realisticTitle.Position = UDim2.new(0, 15, 0, 5)
    realisticTitle.BackgroundTransparency = 1
    realisticTitle.Text = "Realistic Spawner"
    realisticTitle.TextColor3 = Color3.fromRGB(210, 245, 255)
    realisticTitle.Font = Enum.Font.GothamBold
    realisticTitle.TextSize = 18
    realisticTitle.TextXAlignment = Enum.TextXAlignment.Left
    realisticTitle.Parent = RealisticSpawnerGuiFrame

    local realisticCloseBtn = Instance.new("TextButton")
    realisticCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    realisticCloseBtn.Position = UDim2.new(1, -38, 0, 6)
    realisticCloseBtn.BackgroundTransparency = 1
    realisticCloseBtn.Text = "X"
    realisticCloseBtn.TextColor3 = Color3.fromRGB(255, 128, 207)
    realisticCloseBtn.Font = Enum.Font.GothamBold
    realisticCloseBtn.TextSize = 18
    realisticCloseBtn.Parent = RealisticSpawnerGuiFrame
    realisticCloseBtn.MouseButton1Click:Connect(function()
        RealisticSpawnerGuiFrame.Visible = false
    end)

    local realisticSearchBox = Instance.new("TextBox")
    realisticSearchBox.Size = UDim2.new(1, -16, 0, 30)
    realisticSearchBox.Position = UDim2.new(0, 8, 0, 42)
    realisticSearchBox.BackgroundColor3 = Color3.fromRGB(13, 22, 46)
    realisticSearchBox.BorderSizePixel = 0
    realisticSearchBox.PlaceholderText = "Search weapons..."
    realisticSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
    realisticSearchBox.Text = ""
    realisticSearchBox.TextColor3 = Color3.fromRGB(220, 240, 255)
    realisticSearchBox.Font = Enum.Font.Gotham
    realisticSearchBox.TextSize = 13
    realisticSearchBox.ClearTextOnFocus = false
    realisticSearchBox.Parent = RealisticSpawnerGuiFrame
    Instance.new("UICorner", realisticSearchBox).CornerRadius = UDim.new(0, 8)

    local realisticScrollFrame = Instance.new("ScrollingFrame")
    realisticScrollFrame.Size = UDim2.new(1, -10, 1, -156)
    realisticScrollFrame.Position = UDim2.new(0, 5, 0, 78)
    realisticScrollFrame.BackgroundTransparency = 1
    realisticScrollFrame.BorderSizePixel = 0
    realisticScrollFrame.ScrollBarThickness = 4
    realisticScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    realisticScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(83, 220, 255)
    realisticScrollFrame.Parent = RealisticSpawnerGuiFrame

    local realisticGrid = Instance.new("UIGridLayout")
    realisticGrid.CellSize = UDim2.new(0, SPAWNER_BOX_SIZE, 0, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
    realisticGrid.CellPadding = UDim2.new(0, SPAWNER_PADDING, 0, SPAWNER_PADDING)
    realisticGrid.FillDirectionMaxCells = SPAWNER_COLS
    realisticGrid.SortOrder = Enum.SortOrder.LayoutOrder
    realisticGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    realisticGrid.Parent = realisticScrollFrame

    realisticGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        realisticScrollFrame.CanvasSize = UDim2.new(0, 0, 0, realisticGrid.AbsoluteContentSize.Y + 10)
    end)

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(1, -16, 0, 68)
    controlsFrame.Position = UDim2.new(0, 8, 1, -76)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(12, 21, 45)
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = RealisticSpawnerGuiFrame
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 10)

    local minBox = Instance.new("TextBox")
    minBox.Size = UDim2.new(0.5, -12, 0, 28)
    minBox.Position = UDim2.new(0, 8, 0, 7)
    minBox.BackgroundColor3 = Color3.fromRGB(15, 25, 52)
    minBox.BorderSizePixel = 0
    minBox.PlaceholderText = "Minimum"
    minBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
    minBox.Text = "1"
    minBox.TextColor3 = Color3.fromRGB(220, 240, 255)
    minBox.Font = Enum.Font.Gotham
    minBox.TextSize = 13
    minBox.ClearTextOnFocus = false
    minBox.Parent = controlsFrame
    Instance.new("UICorner", minBox).CornerRadius = UDim.new(0, 7)

    local maxBox = Instance.new("TextBox")
    maxBox.Size = UDim2.new(0.5, -12, 0, 28)
    maxBox.Position = UDim2.new(0.5, 4, 0, 7)
    maxBox.BackgroundColor3 = Color3.fromRGB(15, 25, 52)
    maxBox.BorderSizePixel = 0
    maxBox.PlaceholderText = "Maximum"
    maxBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
    maxBox.Text = "10"
    maxBox.TextColor3 = Color3.fromRGB(220, 240, 255)
    maxBox.Font = Enum.Font.Gotham
    maxBox.TextSize = 13
    maxBox.ClearTextOnFocus = false
    maxBox.Parent = controlsFrame
    Instance.new("UICorner", maxBox).CornerRadius = UDim.new(0, 7)

    local spawnSelectedBtn = Instance.new("TextButton")
    spawnSelectedBtn.Size = UDim2.new(1, -16, 0, 25)
    spawnSelectedBtn.Position = UDim2.new(0, 8, 0, 39)
    spawnSelectedBtn.BackgroundColor3 = BUTTON_COLOR
    spawnSelectedBtn.Text = "SPAWN SELECTED"
    spawnSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnSelectedBtn.Font = Enum.Font.GothamBold
    spawnSelectedBtn.TextSize = 13
    spawnSelectedBtn.Parent = controlsFrame
    Instance.new("UICorner", spawnSelectedBtn).CornerRadius = UDim.new(0, 7)

    local function getRealisticRange()
        local minAmount = math.floor(tonumber(minBox.Text) or 1)
        local maxAmount = math.floor(tonumber(maxBox.Text) or minAmount)

        minAmount = math.clamp(minAmount, 1, MAX_WEAPON_AMOUNT)
        maxAmount = math.clamp(maxAmount, 1, MAX_WEAPON_AMOUNT)

        if maxAmount < minAmount then
            minAmount, maxAmount = maxAmount, minAmount
        end

        minBox.Text = tostring(minAmount)
        maxBox.Text = tostring(maxAmount)
        return minAmount, maxAmount
    end

    local function setRealisticCardSelected(container, selected)
        container:SetAttribute("Selected", selected)
        container.BackgroundColor3 = selected and Color3.fromRGB(35, 130, 65) or Color3.fromRGB(45, 20, 75)

        if selected then
            task.defer(function()
                if container.Parent and container:GetAttribute("Selected") then
                    container.BackgroundColor3 = Color3.fromRGB(35, 130, 65)
                end
            end)
        end
    end

    local function addRealisticWeaponBox(itemId, itemType, weaponName, rarity)
        local rarityColor = getRarityColor(rarity)
        local itemData = sync[itemType] and sync[itemType][itemId]
        local key = tostring(itemType) .. ":" .. tostring(itemId)

        local container = Instance.new("TextButton")
        container.Name = tostring(itemId)
        container.Size = UDim2.fromOffset(SPAWNER_BOX_SIZE, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
        container.BackgroundColor3 = Color3.fromRGB(45, 20, 75)
        container.BorderSizePixel = 0
        container.Text = ""
        container.AutoButtonColor = false
        container:SetAttribute("SearchText", (tostring(weaponName or "") .. " " .. tostring(itemId) .. " " .. tostring(rarity or "") .. " " .. tostring(itemType)):lower())
        container:SetAttribute("Selected", false)
        container.Parent = realisticScrollFrame
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke")
        stroke.Color = rarityColor
        stroke.Thickness = 2
        stroke.Transparency = 0.05
        stroke.Parent = container

        local thumbnail = Instance.new("ImageLabel")
        thumbnail.Size = UDim2.new(1, -8, 0, 70)
        thumbnail.Position = UDim2.new(0, 4, 0, 4)
        thumbnail.BackgroundColor3 = Color3.fromRGB(25, 10, 45)
        thumbnail.BorderSizePixel = 0
        thumbnail.Image = getSpawnerThumbnail(itemId, itemData)
        thumbnail.ScaleType = Enum.ScaleType.Fit
        thumbnail.Parent = container
        Instance.new("UICorner", thumbnail).CornerRadius = UDim.new(0, 6)

        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -4, 0, SPAWNER_RARITY_HEIGHT)
        rarityLabel.Position = UDim2.new(0, 2, 0, 75)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = rarity or "Unknown"
        rarityLabel.TextColor3 = rarityColor
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 13
        rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
        rarityLabel.Parent = container

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -4, 0, SPAWNER_NAME_HEIGHT)
        nameLabel.Position = UDim2.new(0, 2, 0, 94)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = weaponName or itemId
        nameLabel.TextColor3 = Color3.fromRGB(210, 245, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextWrapped = false
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = container

        container.MouseButton1Click:Connect(function()
            if selectedRealisticWeapons[key] then
                selectedRealisticWeapons[key] = nil
                setRealisticCardSelected(container, false)
            else
                selectedRealisticWeapons[key] = {
                    itemId = itemId,
                    itemType = itemType,
                    name = weaponName or itemId,
                }
                setRealisticCardSelected(container, true)
            end
        end)

        container.MouseEnter:Connect(function()
            if not container:GetAttribute("Selected") then
                TweenService:Create(container, TweenInfo.new(0.15), {
                    BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(20, 10, 35), 0.45),
                }):Play()
            else
                container.BackgroundColor3 = Color3.fromRGB(35, 130, 65)
            end
        end)

        container.MouseLeave:Connect(function()
            if not container:GetAttribute("Selected") then
                TweenService:Create(container, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(45, 20, 75),
                }):Play()
            else
                container.BackgroundColor3 = Color3.fromRGB(35, 130, 65)
            end
        end)
    end

    populateRealisticSpawner = function()
        if didPopulateRealisticSpawner then
            return
        end

        didPopulateRealisticSpawner = true

        local weapons = {}
        local seen = {}

        local function collect(container, itemType)
            for itemId, data in pairs(container or {}) do
                if type(data) == "table" and isSpawnerRarity(data) and not seen[itemId] then
                    seen[itemId] = true

                    table.insert(weapons, {
                        itemId = itemId,
                        itemType = itemType,
                        name = data.ItemName or data.Name or itemId,
                        rarity = data.Rarity or "Unknown",
                    })
                end
            end
        end

        collect(sync.Weapons, "Weapons")
        collect(sync.Item, "Item")

        table.sort(weapons, function(a, b)
            if a.rarity == b.rarity then
                return a.name < b.name
            end

            if a.rarity == "Ancient" and b.rarity ~= "Ancient" then
                return true
            end

            return false
        end)

        for index, weapon in ipairs(weapons) do
            addRealisticWeaponBox(weapon.itemId, weapon.itemType, weapon.name, weapon.rarity)
            local child = realisticScrollFrame:FindFirstChild(tostring(weapon.itemId))
            if child then
                child.LayoutOrder = index
            end
        end

        filterSpawnerCards(realisticScrollFrame, realisticSearchBox.Text)
    end

    realisticSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterSpawnerCards(realisticScrollFrame, realisticSearchBox.Text)
    end)

    spawnSelectedBtn.MouseButton1Click:Connect(function()
        local minAmount, maxAmount = getRealisticRange()
        local spawnedCount = 0
        local selectedCount = 0

        for _, weapon in pairs(selectedRealisticWeapons) do
            selectedCount += 1
            local amount = math.random(minAmount, maxAmount)
            if spawnWeaponByIdNoPopup(weapon.itemId, weapon.itemType, amount) then
                spawnedCount += 1
            end
        end

        if selectedCount < 1 then
            spawnSelectedBtn.Text = "SELECT WEAPONS FIRST"
        else
            spawnSelectedBtn.Text = "SPAWNED " .. spawnedCount .. " TYPES"
        end

        task.delay(2, function()
            spawnSelectedBtn.Text = "SPAWN SELECTED"
        end)
    end)
end

local function AddWeaponBox(itemId, itemType, weaponName, rarity)
    local rarityColor = getRarityColor(rarity)
    local itemData = sync[itemType] and sync[itemType][itemId]

    local container = Instance.new("TextButton")
    container.Name = tostring(itemId)
    container.Size = UDim2.fromOffset(SPAWNER_BOX_SIZE, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
    container.BackgroundColor3 = Color3.fromRGB(45, 20, 75)
    container.BorderSizePixel = 0
    container.Text = ""
    container.AutoButtonColor = false
    container:SetAttribute("SearchText", (tostring(weaponName or "") .. " " .. tostring(itemId) .. " " .. tostring(rarity or "") .. " " .. tostring(itemType)):lower())
    container.Parent = WeaponScrollFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = rarityColor
    stroke.Thickness = 2
    stroke.Transparency = 0.05
    stroke.Parent = container

    local thumbnail = Instance.new("ImageLabel")
    thumbnail.Size = UDim2.new(1, -8, 0, 70)
    thumbnail.Position = UDim2.new(0, 4, 0, 4)
    thumbnail.BackgroundColor3 = Color3.fromRGB(25, 10, 45)
    thumbnail.BorderSizePixel = 0
    thumbnail.Image = getSpawnerThumbnail(itemId, itemData)
    thumbnail.ScaleType = Enum.ScaleType.Fit
    thumbnail.Parent = container
    Instance.new("UICorner", thumbnail).CornerRadius = UDim.new(0, 6)

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -4, 0, SPAWNER_RARITY_HEIGHT)
    rarityLabel.Position = UDim2.new(0, 2, 0, 75)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarity or "Unknown"
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextSize = 13
    rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
    rarityLabel.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -4, 0, SPAWNER_NAME_HEIGHT)
    nameLabel.Position = UDim2.new(0, 2, 0, 94)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = weaponName or itemId
    nameLabel.TextColor3 = Color3.fromRGB(210, 245, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextWrapped = false
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = container

    container.MouseButton1Click:Connect(function()
        spawnWeaponById(itemId, itemType, currentWeaponAmount)
    end)

    container.MouseEnter:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {
            BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(20, 10, 35), 0.45),
        }):Play()
    end)

    container.MouseLeave:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 20, 75),
        }):Play()
    end)
end

local function AddOfferWeaponBox(itemId, itemType, weaponName, rarity)
    local rarityColor = getRarityColor(rarity)
    local itemData = sync[itemType] and sync[itemType][itemId]

    local container = Instance.new("TextButton")
    container.Name = tostring(itemId)
    container.Size = UDim2.fromOffset(SPAWNER_BOX_SIZE, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
    container.BackgroundColor3 = Color3.fromRGB(45, 20, 75)
    container.BorderSizePixel = 0
    container.Text = ""
    container.AutoButtonColor = false
    container:SetAttribute("SearchText", (tostring(weaponName or "") .. " " .. tostring(itemId) .. " " .. tostring(rarity or "") .. " " .. tostring(itemType)):lower())
    container.Parent = OfferWeaponScrollFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = rarityColor
    stroke.Thickness = 2
    stroke.Transparency = 0.05
    stroke.Parent = container

    local thumbnail = Instance.new("ImageLabel")
    thumbnail.Size = UDim2.new(1, -8, 0, 70)
    thumbnail.Position = UDim2.new(0, 4, 0, 4)
    thumbnail.BackgroundColor3 = Color3.fromRGB(25, 10, 45)
    thumbnail.BorderSizePixel = 0
    thumbnail.Image = getSpawnerThumbnail(itemId, itemData)
    thumbnail.ScaleType = Enum.ScaleType.Fit
    thumbnail.Parent = container
    Instance.new("UICorner", thumbnail).CornerRadius = UDim.new(0, 6)

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -4, 0, SPAWNER_RARITY_HEIGHT)
    rarityLabel.Position = UDim2.new(0, 2, 0, 75)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarity or "Unknown"
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextSize = 13
    rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
    rarityLabel.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -4, 0, SPAWNER_NAME_HEIGHT)
    nameLabel.Position = UDim2.new(0, 2, 0, 94)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = weaponName or itemId
    nameLabel.TextColor3 = Color3.fromRGB(210, 245, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextWrapped = false
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = container

    container.MouseButton1Click:Connect(function()
        if addSpecificItemToTheirOffer then
            addSpecificItemToTheirOffer(itemId, itemType)
        end
    end)

    container.MouseEnter:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {
            BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(20, 10, 35), 0.45),
        }):Play()
    end)

    container.MouseLeave:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 20, 75),
        }):Play()
    end)
end

local didPopulateWeaponSpawner = false
local didPopulateOfferSpawner = false

local function populateWeaponSpawner()
    if didPopulateWeaponSpawner then
        return
    end

    didPopulateWeaponSpawner = true

    local weapons = {}
    local seen = {}

    local function collect(container, itemType)
        for itemId, data in pairs(container or {}) do
            if type(data) == "table" and isSpawnerRarity(data) and not seen[itemId] then
                seen[itemId] = true

                table.insert(weapons, {
                    itemId = itemId,
                    itemType = itemType,
                    name = data.ItemName or data.Name or itemId,
                    rarity = data.Rarity or "Unknown",
                })
            end
        end
    end

    collect(sync.Weapons, "Weapons")
    collect(sync.Item, "Item")

    table.sort(weapons, function(a, b)
        if a.rarity == b.rarity then
            return a.name < b.name
        end

        if a.rarity == "Ancient" and b.rarity ~= "Ancient" then
            return true
        end

        return false
    end)

    for index, weapon in ipairs(weapons) do
        AddWeaponBox(weapon.itemId, weapon.itemType, weapon.name, weapon.rarity)
        local child = WeaponScrollFrame:FindFirstChild(tostring(weapon.itemId))
        if child then
            child.LayoutOrder = index
        end
    end

    filterSpawnerCards(WeaponScrollFrame, WeaponSearchBox.Text)
end

local function populateOfferSpawner()
    if didPopulateOfferSpawner then
        return
    end

    didPopulateOfferSpawner = true

    local weapons = {}
    local seen = {}

    local function collect(container, itemType)
        for itemId, data in pairs(container or {}) do
            if isOfferSpawnerWeapon(data) and canFakeTradeItem(itemId, itemType) and not seen[itemId] then
                seen[itemId] = true

                table.insert(weapons, {
                    itemId = itemId,
                    itemType = itemType,
                    name = data.ItemName or data.Name or itemId,
                    rarity = data.Rarity or "Unknown",
                })
            end
        end
    end

    collect(sync.Weapons, "Weapons")
    collect(sync.Item, "Item")

    table.sort(weapons, function(a, b)
        if a.rarity == b.rarity then
            return a.name < b.name
        end

        if a.rarity == "Ancient" and b.rarity ~= "Ancient" then
            return true
        end

        return false
    end)

    for index, weapon in ipairs(weapons) do
        AddOfferWeaponBox(weapon.itemId, weapon.itemType, weapon.name, weapon.rarity)
        local child = OfferWeaponScrollFrame:FindFirstChild(tostring(weapon.itemId))
        if child then
            child.LayoutOrder = index
        end
    end

    filterSpawnerCards(OfferWeaponScrollFrame, OfferSearchBox.Text)
end

local SpecificWeaponBox = CreateBox(SpawnerFrame, "Spawn Weapon (e.g. Harvester)")
local SpawnSpecificBtn = CreateBtn(SpawnerFrame, "SPAWN WEAPON")

CreateSlider(SpawnerFrame, "Weapon Amount", 1, MAX_WEAPON_AMOUNT, 1, 1, function(val)
    currentWeaponAmount = val
end)

local SpawnGodliesBtn = CreateBtn(SpawnerFrame, "SPAWN ALL GODLIES")
local SpawnChromasBtn = CreateBtn(SpawnerFrame, "SPAWN ALL CHROMAS")
local SpawnAncientsBtn = CreateBtn(SpawnerFrame, "SPAWN ALL ANCIENTS")
local OpenSpawnerGuiBtn = CreateBtn(SpawnerFrame, "OPEN SPAWNER GUI")
local OpenRealisticSpawnerGuiBtn = CreateBtn(SpawnerFrame, "REALISTIC SPAWNER GUI")

SpawnSpecificBtn.MouseButton1Click:Connect(function()
    local weaponName = SpecificWeaponBox.Text

    if weaponName and weaponName ~= "" then
        local success = spawnWeapon(weaponName, currentWeaponAmount)
        if success then
            SpecificWeaponBox.Text = ""
            SpecificWeaponBox.PlaceholderText = "Spawned. Type another..."
            task.delay(2, function()
                SpecificWeaponBox.PlaceholderText = "Spawn Weapon (e.g. Harvester)"
            end)
        else
            SpecificWeaponBox.PlaceholderText = "Not found. Try again..."
            task.delay(2, function()
                SpecificWeaponBox.PlaceholderText = "Spawn Weapon (e.g. Harvester)"
            end)
        end
    else
        SpecificWeaponBox.PlaceholderText = "Type a weapon name first."
        task.delay(2, function()
            SpecificWeaponBox.PlaceholderText = "Spawn Weapon (e.g. Harvester)"
        end)
    end
end)

SpecificWeaponBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and SpecificWeaponBox.Text ~= "" then
        spawnWeapon(SpecificWeaponBox.Text, currentWeaponAmount)
    end
end)

SpawnGodliesBtn.MouseButton1Click:Connect(function()
    local count = spawnAllGodlyWeapons(currentWeaponAmount)
    if count > 0 then
        SpawnGodliesBtn.Text = "SPAWNED " .. count .. " GODLIES"
        task.delay(2, function()
            SpawnGodliesBtn.Text = "SPAWN ALL GODLIES"
        end)
    end
end)

SpawnChromasBtn.MouseButton1Click:Connect(function()
    local count = spawnAllChromaWeapons(currentWeaponAmount)
    if count > 0 then
        SpawnChromasBtn.Text = "SPAWNED " .. count .. " CHROMAS"
        task.delay(2, function()
            SpawnChromasBtn.Text = "SPAWN ALL CHROMAS"
        end)
    else
        SpawnChromasBtn.Text = "NO CHROMAS FOUND"
        task.delay(2, function()
            SpawnChromasBtn.Text = "SPAWN ALL CHROMAS"
        end)
    end
end)

SpawnAncientsBtn.MouseButton1Click:Connect(function()
    local count = spawnAllAncientWeapons(currentWeaponAmount)
    if count > 0 then
        SpawnAncientsBtn.Text = "SPAWNED " .. count .. " ANCIENTS"
        task.delay(2, function()
            SpawnAncientsBtn.Text = "SPAWN ALL ANCIENTS"
        end)
    else
        SpawnAncientsBtn.Text = "NO ANCIENTS FOUND"
        task.delay(2, function()
            SpawnAncientsBtn.Text = "SPAWN ALL ANCIENTS"
        end)
    end
end)

OpenSpawnerGuiBtn.MouseButton1Click:Connect(function()
    populateWeaponSpawner()
    SpawnerGuiFrame.Visible = not SpawnerGuiFrame.Visible
end)

OpenRealisticSpawnerGuiBtn.MouseButton1Click:Connect(function()
    populateRealisticSpawner()
    RealisticSpawnerGuiFrame.Visible = not RealisticSpawnerGuiFrame.Visible
end)

local StartTradeBtn = CreateBtn(TradeFrame, "START TRADE")
local OfferSpawnerBtn = CreateBtn(TradeFrame, "OFFER SPAWNER")
local AddRandomBtn = CreateBtn(TradeFrame, "ADD RANDOM THEIR GODLY")
local RemoveLastBtn = CreateBtn(TradeFrame, "REMOVE LAST THEIR ITEM")

OfferSpawnerBtn.MouseButton1Click:Connect(function()
    populateOfferSpawner()
    OfferSpawnerGuiFrame.Visible = not OfferSpawnerGuiFrame.Visible
end)

CartiHubSelectedUpgradePlayerName = nil
CartiHubUpgradePlayerDropdownBtn = CreateBtn(UpgradingFrame, "SELECT PLAYER: NONE")
CartiHubUpgradePlayerListFrame = Instance.new("ScrollingFrame")
CartiHubUpgradePlayerListFrame.Size = UDim2.new(1, 0, 0, 180)
CartiHubUpgradePlayerListFrame.BackgroundColor3 = Color3.fromRGB(12, 21, 45)
CartiHubUpgradePlayerListFrame.BorderSizePixel = 0
CartiHubUpgradePlayerListFrame.ScrollBarThickness = 4
CartiHubUpgradePlayerListFrame.ScrollBarImageColor3 = Color3.fromRGB(83, 220, 255)
CartiHubUpgradePlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
CartiHubUpgradePlayerListFrame.ClipsDescendants = true
CartiHubUpgradePlayerListFrame.Parent = UpgradingFrame
Instance.new("UICorner", CartiHubUpgradePlayerListFrame).CornerRadius = UDim.new(0, 8)

CartiHubUpgradePlayerListPadding = Instance.new("UIPadding")
CartiHubUpgradePlayerListPadding.PaddingTop = UDim.new(0, 6)
CartiHubUpgradePlayerListPadding.PaddingBottom = UDim.new(0, 6)
CartiHubUpgradePlayerListPadding.PaddingLeft = UDim.new(0, 6)
CartiHubUpgradePlayerListPadding.PaddingRight = UDim.new(0, 6)
CartiHubUpgradePlayerListPadding.Parent = CartiHubUpgradePlayerListFrame

CartiHubUpgradePlayerListLayout = Instance.new("UIListLayout")
CartiHubUpgradePlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
CartiHubUpgradePlayerListLayout.Padding = UDim.new(0, 5)
CartiHubUpgradePlayerListLayout.Parent = CartiHubUpgradePlayerListFrame

CartiHubUpgradePlayerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CartiHubUpgradePlayerListFrame.CanvasSize = UDim2.new(
        0,
        0,
        0,
        CartiHubUpgradePlayerListLayout.AbsoluteContentSize.Y + 12
    )
end)

CartiHubLaunchUpgradeTradeBtn = CreateBtn(UpgradingFrame, "LAUNCH FAKE TRADE")
CartiHubFakePersonTradeBtn = CreateBtn(UpgradingFrame, "FAKE UPGRADE FAKE PLAYER")
CartiHubPlayerValuesBtn = CreateBtn(UpgradingFrame, "PLAYERS VALUES")
CartiHubBlockValueBtn = CreateBtn(UpgradingFrame, "BLOCK VALUE")

do
local CartiHubBlockLastTradedBtn = CreateBtn(BlockFrame, "BLOCK LAST TRADED USER")
local HttpService = game:GetService("HttpService")

local CARTI_HUB_USERNAME_LOOKUP_URL = "https://users.roblox.com/v1/usernames/users"
local CARTI_HUB_BLOCK_URL = "https://apis.roblox.com/user-blocking-api/v1/users/%d/block-user"
local CARTI_HUB_BLOCKED_USERS_URL = "https://apis.roblox.com/user-blocking-api/v1/users/get-blocked-users?cursor=&count=50"
local CARTI_HUB_FRIEND_REQUESTS_URL = "https://friends.roblox.com/v1/my/friends/requests?limit=100&cursor=%s"
local CARTI_HUB_DECLINE_FRIEND_REQUEST_URL = "https://friends.roblox.com/v1/users/%d/decline-friend-request"
local CARTI_HUB_DECLINE_ALL_FRIEND_REQUESTS_URL = "https://friends.roblox.com/v1/user/friend-requests/decline-all"
local CARTI_HUB_PAL_HAIR_ASSET_ID = 63690008
local CARTI_HUB_REQUEST_BLOCK_HAIR_ASSET_IDS = {
    [63690008] = true, -- Pal Hair
    [1772336109] = true, -- Down to Earth Hair
    [80274239] = true, -- Black Ponytail
    [62724852] = true, -- Chestnut Bun
}

local function CartiHubGetLocalRequestFunction()
    return request
        or http_request
        or (syn and syn.request)
        or (fluxus and fluxus.request)
end

local function CartiHubGetRuntimeBlockCredentials()
    local provider = _G.CartiHubGetBlockCredentials
    if type(provider) ~= "function" then
        return "", "", ""
    end

    local session, tracker, csrfToken = provider()
    return tostring(session or ""), tostring(tracker or ""), tostring(csrfToken or "")
end

local function CartiHubGetResponseHeader(response, headerName)
    local headers = response and (response.Headers or response.headers)
    if type(headers) ~= "table" then
        return nil
    end

    local expected = string.lower(headerName)
    for key, value in pairs(headers) do
        if string.lower(tostring(key)) == expected then
            return value
        end
    end

    return nil
end

local function CartiHubGetResponseStatus(response)
    return tonumber(response and (response.StatusCode or response.status_code)) or 0
end

local function CartiHubGetResponseBody(response)
    return response and (response.Body or response.body) or ""
end

local function CartiHubDirectBlockRobloxUser(requestFunction, username)
    local robloSecurity, eventTracker, configuredCsrfToken = CartiHubGetRuntimeBlockCredentials()
    if robloSecurity == "" then
        return false, "SET SESSION"
    end

    if eventTracker == "" then
        return false, "BROWSER TRACKER MISSING"
    end

    local lookupResponse = requestFunction({
        Url = CARTI_HUB_USERNAME_LOOKUP_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
        },
        Body = HttpService:JSONEncode({
            usernames = { username },
            excludeBannedUsers = false,
        }),
    })

    if CartiHubGetResponseStatus(lookupResponse) < 200
        or CartiHubGetResponseStatus(lookupResponse) >= 300 then
        return false, "USER LOOKUP FAILED"
    end

    local lookupData = HttpService:JSONDecode(CartiHubGetResponseBody(lookupResponse))
    local userData = lookupData and lookupData.data and lookupData.data[1]
    local userId = userData and tonumber(userData.id)
    if not userId then
        return false, "USER NOT FOUND"
    end

    local browserTrackerId = string.match(eventTracker, "[Bb]rowserid=([%d]+)")
    if not browserTrackerId then
        return false, "BROWSER TRACKER INVALID"
    end

    local cookieHeader = ".ROBLOSECURITY=" .. robloSecurity
        .. "; RBXEventTrackerV2=" .. eventTracker
    local blockUrl = string.format(CARTI_HUB_BLOCK_URL, userId)
    local csrfToken = configuredCsrfToken ~= "" and configuredCsrfToken
        or (_G.CartiHubBlockCsrfToken or "")
    if csrfToken == "" then
        local csrfResponse = requestFunction({
            -- CSRF tokens are scoped to Roblox's API domain. Request it from the
            -- exact endpoint that will receive the authenticated block request.
            Url = blockUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Cookie"] = cookieHeader,
                ["Origin"] = "https://www.roblox.com",
                ["Referer"] = "https://www.roblox.com/",
                ["BrowserTrackerId"] = browserTrackerId,
            },
            Body = "{}",
        })

        csrfToken = CartiHubGetResponseHeader(csrfResponse, "x-csrf-token")
        _G.CartiHubBlockCsrfToken = csrfToken
    end

    if not csrfToken or csrfToken == "" then
        return false, "CSRF TOKEN MISSING"
    end

    local blockResponse = requestFunction({
        Url = blockUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Cookie"] = cookieHeader,
            ["x-csrf-token"] = csrfToken,
            ["Origin"] = "https://www.roblox.com",
            ["Referer"] = "https://www.roblox.com/",
            ["BrowserTrackerId"] = browserTrackerId,
        },
        Body = "{}",
    })

    local statusCode = CartiHubGetResponseStatus(blockResponse)
    local normalizedBlockBody = string.gsub(CartiHubGetResponseBody(blockResponse), "%s+", "")
    -- Roblox returns numeric code 1 when this request is a no-op for an already
    -- blocked account. Verify the authoritative blocked-user list in both cases.
    if (statusCode >= 200 and statusCode < 300)
        or (statusCode == 400 and normalizedBlockBody == "1") then
        local verifyResponse = requestFunction({
            Url = CARTI_HUB_BLOCKED_USERS_URL,
            Method = "GET",
            Headers = {
                ["Cookie"] = cookieHeader,
                ["Origin"] = "https://www.roblox.com",
                ["Referer"] = "https://www.roblox.com/",
                ["BrowserTrackerId"] = browserTrackerId,
            },
        })

        local verifyStatus = CartiHubGetResponseStatus(verifyResponse)
        local verifyBody = CartiHubGetResponseBody(verifyResponse)

        if verifyStatus < 200 or verifyStatus >= 300 then
            return false, "BLOCK VERIFY FAILED"
        end

        local verifyData = HttpService:JSONDecode(verifyBody)
        local blockedData = verifyData and (verifyData.data or verifyData) or {}
        local blockedUsers = blockedData.blockedUserIds or blockedData.blockedUsers or {}

        for _, blockedUser in ipairs(blockedUsers) do
            local blockedUserId = type(blockedUser) == "table"
                and tonumber(blockedUser.blockedUserId or blockedUser.id or blockedUser.userId)
                or tonumber(blockedUser)

            if blockedUserId == userId then
                return true
            end
        end

        return false, "BLOCK NOT CONFIRMED"
    end

    if statusCode == 401 then
        return false, "ROBLOSECURITY REJECTED"
    end

    if statusCode == 403 then
        _G.CartiHubBlockCsrfToken = nil
        return false, "CSRF TOKEN REJECTED"
    end

    if statusCode == 429 then
        return false, "BLOCK RATE LIMITED"
    end

    return false, "BLOCK FAILED"
end

_G.CartiHubBlockUsername = function(username, callback)
    username = tostring(username or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if username == "" then
        if callback then
            callback(false, "INVALID USER")
        end
        return false
    end

    local requestFunction = CartiHubGetLocalRequestFunction()
    if not requestFunction then
        if callback then
            callback(false, "HTTP UNAVAILABLE")
        end
        return false
    end

    local robloSecurity = CartiHubGetRuntimeBlockCredentials()
    if robloSecurity == "" then
        if callback then
            callback(false, "SET SESSION")
        end
        return false
    end

    task.spawn(function()
        local callOk, success, detail = pcall(function()
            return CartiHubDirectBlockRobloxUser(requestFunction, username)
        end)

        if not callOk then
            warn("[Carti Hub] Block request failed: " .. tostring(success))
            if callback then
                callback(false, "BLOCKER OFFLINE")
            end
            return
        end

        if callback then
            callback(success == true, success and "BLOCKED" or tostring(detail or "BLOCK FAILED"))
        end
    end)

    return true
end

local function CartiHubSetBlockLastTradedButtonText(text, duration)
    CartiHubBlockLastTradedBtn.Text = text

    if duration then
        task.delay(duration, function()
            if CartiHubBlockLastTradedBtn and CartiHubBlockLastTradedBtn.Parent then
                CartiHubBlockLastTradedBtn.Text = "BLOCK LAST TRADED USER"
            end
        end)
    end
end

CartiHubBlockLastTradedBtn.MouseButton1Click:Connect(function()
    local username = CartiHubGetLastTradedPlayerName and CartiHubGetLastTradedPlayerName()
    if not username then
        CartiHubSetBlockLastTradedButtonText("NO LAST TRADED USER", 2)
        return
    end

    local requestFunction = CartiHubGetLocalRequestFunction()
    if not requestFunction then
        CartiHubSetBlockLastTradedButtonText("EXECUTOR HTTP UNAVAILABLE", 2)
        return
    end

    local robloSecurity = CartiHubGetRuntimeBlockCredentials()
    if robloSecurity == "" then
        CartiHubSetBlockLastTradedButtonText("SET ROBLOSECURITY FIRST", 2)
        return
    end

    CartiHubBlockLastTradedBtn.Text = "BLOCKING " .. tostring(username) .. "..."

    task.spawn(function()
        local callOk, success, errorText = pcall(function()
            return CartiHubDirectBlockRobloxUser(requestFunction, username)
        end)

        if not callOk then
            CartiHubSetBlockLastTradedButtonText("BLOCKER OFFLINE", 2)
            warn("[Carti Hub] Direct Roblox block request failed: " .. tostring(success))
            return
        end

        if success then
            CartiHubSetBlockLastTradedButtonText("BLOCKED: " .. tostring(username), 2)
        else
            CartiHubSetBlockLastTradedButtonText(tostring(errorText):upper(), 2)
            warn("[Carti Hub] Roblox block failed: " .. tostring(errorText))
        end
    end)
end)

function CartiHubDeclinePalHairFriendRequests(runGeneration)
    if runGeneration and runGeneration ~= CartiHubAutoDeclinePalHairSequence then
        return true, 0
    end

    local requestFunction = CartiHubGetLocalRequestFunction()
    local robloSecurity, eventTracker, configuredCsrfToken = CartiHubGetRuntimeBlockCredentials()
    if not requestFunction or robloSecurity == "" then
        return false, "HTTP OR SESSION UNAVAILABLE"
    end

    local browserTrackerId = string.match(eventTracker, "[Bb]rowserid=([%d]+)")
    if not browserTrackerId then
        return false, "BROWSER TRACKER INVALID"
    end

    if os.clock() < (_G.CartiHubPalHairNextAllowedAt or 0) then
        return true, 0
    end

    local cookieHeader = ".ROBLOSECURITY=" .. robloSecurity
        .. "; RBXEventTrackerV2=" .. eventTracker
    local declinedCount = 0
    local csrfToken = configuredCsrfToken ~= "" and configuredCsrfToken
        or (_G.CartiHubFriendRequestCsrfToken or "")
    _G.CartiHubPalHairCheckedAt = _G.CartiHubPalHairCheckedAt or {}
    _G.CartiHubPalHairPendingUsers = _G.CartiHubPalHairPendingUsers or {}
    local cursor = ""
    local pagesChecked = 0

    while pagesChecked < 10 do
        if runGeneration and runGeneration ~= CartiHubAutoDeclinePalHairSequence then
            return true, declinedCount
        end

        local requestList = requestFunction({
            Url = string.format(CARTI_HUB_FRIEND_REQUESTS_URL, HttpService:UrlEncode(cursor)),
            Method = "GET",
            Headers = {
                ["Cookie"] = cookieHeader,
                ["Origin"] = "https://www.roblox.com",
                ["Referer"] = "https://www.roblox.com/",
                ["BrowserTrackerId"] = browserTrackerId,
            },
        })

        local requestListStatus = CartiHubGetResponseStatus(requestList)
        if requestListStatus == 429 then
            local retryAfter = tonumber(CartiHubGetResponseHeader(requestList, "retry-after")) or 15
            _G.CartiHubPalHairNextAllowedAt = os.clock() + math.max(5, retryAfter)
            warn("[Carti Hub] Friend-request API rate limited; resuming in " .. retryAfter .. " seconds.")
            return true, declinedCount
        end

        if requestListStatus < 200 or requestListStatus >= 300 then
            return false, ("REQUEST LIST FAILED (%d): %s"):format(
                requestListStatus,
                string.sub(CartiHubGetResponseBody(requestList), 1, 160)
            )
        end

        local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, CartiHubGetResponseBody(requestList))
        if not decodeOk or type(decoded) ~= "table" then
            return false, "REQUEST LIST INVALID"
        end

        for _, entry in ipairs(decoded.data or {}) do
            if runGeneration and runGeneration ~= CartiHubAutoDeclinePalHairSequence then
                return true, declinedCount
            end

            local requesterId = tonumber(entry.id or entry.userId or entry.requesterId
                or (entry.requester and entry.requester.id))

            if requesterId
                and os.clock() - (_G.CartiHubPalHairCheckedAt[requesterId] or 0) >= 300 then
                local wearingOk, wearingData = pcall(function()
                    return Players:GetCharacterAppearanceInfoAsync(requesterId)
                end)
                local hasPalHair = false

                if wearingOk and type(wearingData) == "table"
                    and type(wearingData.assets) == "table" then
                    for _, assetData in ipairs(wearingData.assets) do
                        if tonumber(assetData.id) == CARTI_HUB_PAL_HAIR_ASSET_ID then
                            hasPalHair = true
                            break
                        end
                    end
                elseif not wearingOk then
                    warn("[Carti Hub] Appearance lookup failed for user " .. requesterId .. ": " .. tostring(wearingData))
                end

                if hasPalHair then
                    local now = os.clock()
                    local pendingUsers = _G.CartiHubPalHairPendingUsers
                    pendingUsers[requesterId] = pendingUsers[requesterId] or now

                    local recentCount = 0
                    for userId, detectedAt in pairs(pendingUsers) do
                        if now - detectedAt <= 5 then
                            recentCount += 1
                        else
                            pendingUsers[userId] = nil
                        end
                    end

                    if recentCount > 5 then
                        local declineAllUrl = CARTI_HUB_DECLINE_ALL_FRIEND_REQUESTS_URL

                        if csrfToken == "" then
                            local csrfResponse = requestFunction({
                                Url = declineAllUrl,
                                Method = "POST",
                                Headers = {
                                    ["Content-Type"] = "application/json",
                                    ["Cookie"] = cookieHeader,
                                    ["Origin"] = "https://www.roblox.com",
                                    ["Referer"] = "https://www.roblox.com/",
                                    ["BrowserTrackerId"] = browserTrackerId,
                                },
                                Body = "{}",
                            })
                            csrfToken = CartiHubGetResponseHeader(csrfResponse, "x-csrf-token") or ""
                            _G.CartiHubFriendRequestCsrfToken = csrfToken
                        end

                        if csrfToken ~= "" then
                            local declineAllResponse = requestFunction({
                                Url = declineAllUrl,
                                Method = "POST",
                                Headers = {
                                    ["Content-Type"] = "application/json",
                                    ["Cookie"] = cookieHeader,
                                    ["x-csrf-token"] = csrfToken,
                                    ["Origin"] = "https://www.roblox.com",
                                    ["Referer"] = "https://www.roblox.com/",
                                    ["BrowserTrackerId"] = browserTrackerId,
                                },
                                Body = "{}",
                            })
                            local declineAllStatus = CartiHubGetResponseStatus(declineAllResponse)

                            if declineAllStatus >= 200 and declineAllStatus < 300 then
                                table.clear(pendingUsers)
                                table.clear(_G.CartiHubPalHairCheckedAt)
                                return true, recentCount
                            elseif declineAllStatus == 429 then
                                local retryAfter = tonumber(CartiHubGetResponseHeader(declineAllResponse, "retry-after")) or 15
                                _G.CartiHubPalHairNextAllowedAt = os.clock() + math.max(5, retryAfter)
                                return true, 0
                            end
                        end
                    elseif now - pendingUsers[requesterId] < 5 then
                        hasPalHair = false
                    end
                end

                if hasPalHair then
                    local declineUrl = string.format(CARTI_HUB_DECLINE_FRIEND_REQUEST_URL, requesterId)

                    if csrfToken == "" then
                        local csrfResponse = requestFunction({
                            Url = declineUrl,
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Cookie"] = cookieHeader,
                                ["Origin"] = "https://www.roblox.com",
                                ["Referer"] = "https://www.roblox.com/",
                                ["BrowserTrackerId"] = browserTrackerId,
                            },
                            Body = "{}",
                        })
                        csrfToken = CartiHubGetResponseHeader(csrfResponse, "x-csrf-token") or ""
                        _G.CartiHubFriendRequestCsrfToken = csrfToken
                    end

                    if csrfToken ~= "" then
                        local declineResponse = requestFunction({
                            Url = declineUrl,
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Cookie"] = cookieHeader,
                                ["x-csrf-token"] = csrfToken,
                                ["Origin"] = "https://www.roblox.com",
                                ["Referer"] = "https://www.roblox.com/",
                                ["BrowserTrackerId"] = browserTrackerId,
                            },
                            Body = "{}",
                        })

                        local declineStatus = CartiHubGetResponseStatus(declineResponse)
                        if declineStatus >= 200 and declineStatus < 300 then
                            declinedCount += 1
                            _G.CartiHubPalHairCheckedAt[requesterId] = os.clock()
                            _G.CartiHubPalHairPendingUsers[requesterId] = nil
                            task.wait(2)
                        elseif declineStatus == 403 then
                            csrfToken = ""
                            _G.CartiHubFriendRequestCsrfToken = nil
                        elseif declineStatus == 429 then
                            local retryAfter = tonumber(CartiHubGetResponseHeader(declineResponse, "retry-after")) or 15
                            _G.CartiHubPalHairNextAllowedAt = os.clock() + math.max(5, retryAfter)
                            warn("[Carti Hub] Friend-request API rate limited; resuming in " .. retryAfter .. " seconds.")
                            return true, declinedCount
                        else
                            warn(("[Carti Hub] Decline failed for %d: status=%d body=%s"):format(
                                requesterId,
                                declineStatus,
                                string.sub(CartiHubGetResponseBody(declineResponse), 1, 160)
                            ))
                        end
                    end
                elseif wearingOk and type(wearingData) == "table" then
                    _G.CartiHubPalHairCheckedAt[requesterId] = os.clock()
                end

                task.wait(0.15)
            end
        end

        pagesChecked += 1
        cursor = decoded.nextPageCursor or ""
        if cursor == "" then
            break
        end
    end

    return true, declinedCount
end

function CartiHubBlockUsersFromFriendRequests()
    local requestFunction = CartiHubGetLocalRequestFunction()
    local robloSecurity, eventTracker = CartiHubGetRuntimeBlockCredentials()
    if not requestFunction or robloSecurity == "" then
        return false, "HTTP OR SESSION UNAVAILABLE"
    end

    local browserTrackerId = string.match(eventTracker, "[Bb]rowserid=([%d]+)")
    if not browserTrackerId then
        return false, "BROWSER TRACKER INVALID"
    end

    local cookieHeader = ".ROBLOSECURITY=" .. robloSecurity
        .. "; RBXEventTrackerV2=" .. eventTracker
    local cursor = ""
    local blockedCount = 0
    local seenUsers = {}

    for _ = 1, 10 do
        local response = requestFunction({
            Url = string.format(CARTI_HUB_FRIEND_REQUESTS_URL, HttpService:UrlEncode(cursor)),
            Method = "GET",
            Headers = {
                ["Cookie"] = cookieHeader,
                ["Origin"] = "https://www.roblox.com",
                ["Referer"] = "https://www.roblox.com/",
                ["BrowserTrackerId"] = browserTrackerId,
            },
        })

        if CartiHubGetResponseStatus(response) < 200
            or CartiHubGetResponseStatus(response) >= 300 then
            return false, "REQUEST LIST FAILED"
        end

        local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, CartiHubGetResponseBody(response))
        if not decodeOk or type(data) ~= "table" then
            return false, "REQUEST LIST INVALID"
        end

        for _, entry in ipairs(data.data or {}) do
            local userId = tonumber((entry.friendRequest and entry.friendRequest.senderId)
                or entry.id
                or entry.userId
                or entry.requesterId
                or (entry.requester and entry.requester.id))
            local username = entry.name or entry.username or (entry.requester and entry.requester.name)

            if userId and not seenUsers[userId] then
                seenUsers[userId] = true
                local appearanceOk, appearance = pcall(function()
                    return Players:GetCharacterAppearanceInfoAsync(userId)
                end)
                local matchesHair = false

                if appearanceOk and type(appearance) == "table" then
                    for _, assetData in ipairs(appearance.assets or {}) do
                        if CARTI_HUB_REQUEST_BLOCK_HAIR_ASSET_IDS[tonumber(assetData.id)] then
                            matchesHair = true
                            break
                        end
                    end
                end

                if matchesHair then
                    if not username or username == "" then
                        local resolved, resolvedName = pcall(function()
                            return Players:GetNameFromUserIdAsync(userId)
                        end)
                        username = resolved and resolvedName or nil
                    end

                    if username and username ~= "" then
                        local blocked = false
                        local errorText

                        for attempt = 1, 3 do
                            blocked, errorText = CartiHubDirectBlockRobloxUser(requestFunction, username)
                            if blocked or errorText ~= "BLOCK RATE LIMITED" then
                                break
                            end

                            warn("[Carti Hub] Block rate limited; retrying " .. tostring(username) .. " shortly.")
                            task.wait(15)
                        end

                        if blocked then
                            blockedCount += 1
                        else
                            warn("[Carti Hub] Could not block " .. tostring(username) .. ": " .. tostring(errorText))
                        end
                    else
                        warn("[Carti Hub] Could not resolve requested user id " .. tostring(userId))
                    end
                    task.wait(4)
                else
                    task.wait(0.15)
                end
            end
        end

        cursor = data.nextPageCursor or ""
        if cursor == "" then
            break
        end
    end

    return true, blockedCount
end
end

function CartiHubSetSelectedUpgradePlayer(username)
    CartiHubSelectedUpgradePlayerName = username
    CartiHubUpgradePlayerDropdownBtn.Text = username and ("SELECT PLAYER: " .. username) or "SELECT PLAYER: NONE"
end

function CartiHubRefreshUpgradePlayerDropdown()
    if not CartiHubUpgradePlayerListFrame or not CartiHubUpgradePlayerListFrame.Parent then
        return
    end

    local selectedStillHere = CartiHubSelectedUpgradePlayerName == nil

    for _, child in ipairs(CartiHubUpgradePlayerListFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            if player.Name == CartiHubSelectedUpgradePlayerName then
                selectedStillHere = true
            end

            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, 0, 0, 30)
            playerButton.BackgroundColor3 = player.Name == CartiHubSelectedUpgradePlayerName
                and BUTTON_HOVER_COLOR
                or Color3.fromRGB(15, 25, 52)
            playerButton.BorderSizePixel = 0
            playerButton.Text = player.Name
            playerButton.TextColor3 = Color3.fromRGB(220, 240, 255)
            playerButton.Font = Enum.Font.GothamBold
            playerButton.TextSize = 13
            playerButton.Parent = CartiHubUpgradePlayerListFrame
            Instance.new("UICorner", playerButton).CornerRadius = UDim.new(0, 7)

            playerButton.MouseButton1Click:Connect(function()
                CartiHubSetSelectedUpgradePlayer(player.Name)
                CartiHubRefreshUpgradePlayerDropdown()
            end)
        end
    end

    if not selectedStillHere then
        CartiHubSetSelectedUpgradePlayer(nil)
    end

    CartiHubUpgradePlayerListFrame.CanvasSize = UDim2.new(
        0,
        0,
        0,
        CartiHubUpgradePlayerListLayout.AbsoluteContentSize.Y + 12
    )
end

CartiHubUpgradePlayerDropdownBtn.MouseButton1Click:Connect(CartiHubRefreshUpgradePlayerDropdown)

CartiHubAutoSelectLastTradedEnabled = true
CartiHubAutoSelectLastTradedBtn = CreateBtn(UpgradingFrame, "AUTO SELECT LAST TRADED: ON")

function CartiHubSetAutoSelectLastTraded(enabled)
    CartiHubAutoSelectLastTradedEnabled = enabled == true
    CartiHubAutoSelectLastTradedBtn.Text = CartiHubAutoSelectLastTradedEnabled
        and "AUTO SELECT LAST TRADED: ON"
        or "AUTO SELECT LAST TRADED: OFF"
    CartiHubAutoSelectLastTradedBtn.BackgroundColor3 = CartiHubAutoSelectLastTradedEnabled
        and BUTTON_HOVER_COLOR
        or BUTTON_COLOR

    if CartiHubAutoSelectLastTradedEnabled and _G.CartiHubLastTradedPlayerName then
        CartiHubTryAutoSelectLastTraded(_G.CartiHubLastTradedPlayerName)
    end
end

function CartiHubTryAutoSelectLastTraded(username)
    if not CartiHubAutoSelectLastTradedEnabled or not username then
        return false
    end

    local player = Players:FindFirstChild(username)
    if not player or player == localPlayer then
        return false
    end

    CartiHubSetSelectedUpgradePlayer(player.Name)
    CartiHubRefreshUpgradePlayerDropdown()
    return true
end

CartiHubAutoSelectLastTradedBtn.MouseButton1Click:Connect(function()
    CartiHubSetAutoSelectLastTraded(not CartiHubAutoSelectLastTradedEnabled)
end)

CartiHubSetAutoSelectLastTraded(true)

CartiHubLaunchUpgradeTradeBtn.MouseButton1Click:Connect(function()
    if not CartiHubSelectedUpgradePlayerName then
        CartiHubLaunchUpgradeTradeBtn.Text = "SELECT A PLAYER FIRST"
        task.delay(2, function()
            CartiHubLaunchUpgradeTradeBtn.Text = "LAUNCH FAKE TRADE"
        end)
        return
    end

    if CartiHubLaunchUpgradeFakeTrade then
        CartiHubLaunchUpgradeFakeTrade(CartiHubSelectedUpgradePlayerName)
    else
        warn("[Carti Hub] Fake trade launcher is not ready yet.")
    end
end)

CartiHubFakePersonTradeBtn.MouseButton1Click:Connect(function()
    if CartiHubLaunchFakeUpgradeFakePlayer then
        CartiHubLaunchFakeUpgradeFakePlayer()
    else
        CartiHubFakePersonTradeBtn.Text = "TRADE UI NOT READY"
        task.delay(2, function()
            if CartiHubFakePersonTradeBtn.Parent then
                CartiHubFakePersonTradeBtn.Text = "FAKE UPGRADE FAKE PLAYER"
            end
        end)
    end
end)

CartiHubPlayerValuesBtn.MouseButton1Click:Connect(function()
    local openValues = _G.CartiHubOpenPlayerValuesGui
    if type(openValues) == "function" then
        openValues()
    else
        CartiHubPlayerValuesBtn.Text = "VALUES UI NOT READY"
        task.delay(2, function()
            if CartiHubPlayerValuesBtn.Parent then
                CartiHubPlayerValuesBtn.Text = "PLAYERS VALUES"
            end
        end)
    end
end)

CartiHubBlockValueBtn.MouseButton1Click:Connect(function()
    local openBlockValue = _G.CartiHubOpenBlockValueGui
    if type(openBlockValue) == "function" then
        openBlockValue()
    else
        CartiHubBlockValueBtn.Text = "BLOCK VALUE NOT READY"
        task.delay(2, function()
            if CartiHubBlockValueBtn.Parent then
                CartiHubBlockValueBtn.Text = "BLOCK VALUE"
            end
        end)
    end
end)

task.spawn(function()
    while SakaUI and SakaUI.Parent do
        CartiHubRefreshUpgradePlayerDropdown()
        task.wait(2)
    end
end)

do
local AutoTradeBtn = CreateBtn(SettingsFrame, "AUTO TRADE: OFF")

local autoTradeEnabled = false
local autoTradeSequence = 0

if _G.CartiHubAutoTradeState then
    _G.CartiHubAutoTradeState.Enabled = false
end

local autoTradeState = {
    Enabled = false,
}

_G.CartiHubAutoTradeState = autoTradeState
-- Edit this list to control which item names Auto Trade searches for.
_G.CartiHubAutoTradeSearchTerms = {
"Gingerscope",
"Blossom",
"Flora",
"Heart Wand",
"Sakura",
"Sunrise",
"Sunset",
"Sweet",
"Treat",
"Turkey",
"Watergun",
"Celestial",
"Icepiercer",
"Swirly Axe",
"Bauble",
"Blizzard",
"Constellation",
"Evergreen",
"Evergun",
"Swirly Gun",
"Traveler's Axe",
"Bat",
"Raygun",
"Traveler's Gun",
"Vampires's Gun"
}

local function isAutoTradeBusy()
    local gui = tradeModule.GUI
    if not gui then
        return true
    end

    if _G.CartiHubFakeTradeActive then
        return true
    end

    if gui.TradeGUI and gui.TradeGUI.Enabled then
        return true
    end

    return false
end

local function setAutoTradeEnabled(enabled)
    autoTradeEnabled = enabled == true
    autoTradeState.Enabled = autoTradeEnabled
    autoTradeSequence += 1

    local sequence = autoTradeSequence
    AutoTradeBtn.Text = autoTradeEnabled and "AUTO TRADE: ON" or "AUTO TRADE: OFF"
    AutoTradeBtn.BackgroundColor3 = autoTradeEnabled and BUTTON_HOVER_COLOR or BUTTON_COLOR

    if not autoTradeEnabled then
        return
    end

    task.spawn(function()
        while autoTradeEnabled
            and autoTradeState.Enabled
            and sequence == autoTradeSequence
            and SakaUI
            and SakaUI.Parent do
            if not isAutoTradeBusy() then
                local startFakeTrade = _G.CartiHubStartFakeTrade
                if type(startFakeTrade) == "function" then
                    startFakeTrade(true)
                end
            end

            task.wait(math.random(20, 40) / 10)
        end
    end)
end

AutoTradeBtn.MouseButton1Click:Connect(function()
    setAutoTradeEnabled(not autoTradeEnabled)
end)
end

local friendJoinDelaySeconds = 30
local autoFriendJoinEnabled = false
local autoFriendJoinSequence = 0

CreateSlider(SettingsFrame, "Friend Joined Delay (Sec)", 30, 300, 30, 10, function(val)
    friendJoinDelaySeconds = val
end)

local FriendJoinToggleBtn = CreateBtn(SettingsFrame, "FRIEND JOINED")
local AutoFriendJoinBtn = CreateBtn(SettingsFrame, "AUTO FRIEND JOIN: OFF")
local applyAvatarFromUserId
local AvatarChangerBtn = CreateBtn(SettingsFrame, "AVATAR CHANGER")
CreateBtn(KeybindsFrame, "Toggle UI: 6")
CreateBtn(KeybindsFrame, "Start Trade: Z")
CreateBtn(KeybindsFrame, "Friend Join: F")
CreateBtn(KeybindsFrame, "Random >200 Offer: 2")

do
local avatarPersistenceState = _G.CartiHubAvatarPersistenceState or {
    UserId = nil,
    Connection = nil,
}

if avatarPersistenceState.Connection then
    pcall(function()
        avatarPersistenceState.Connection:Disconnect()
    end)
end

_G.CartiHubAvatarPersistenceState = avatarPersistenceState

local AvatarChangerFrame = Instance.new("Frame")
AvatarChangerFrame.Name = "AvatarChangerGUI"
AvatarChangerFrame.Size = UDim2.new(0, 280, 0, 190)
AvatarChangerFrame.Position = UDim2.new(0.5, -140, 0.5, -95)
AvatarChangerFrame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
AvatarChangerFrame.BorderSizePixel = 0
AvatarChangerFrame.Active = true
AvatarChangerFrame.Draggable = true
AvatarChangerFrame.Visible = false
AvatarChangerFrame.Parent = SakaUI
Instance.new("UICorner", AvatarChangerFrame).CornerRadius = UDim.new(0, 14)

local AvatarChangerStroke = Instance.new("UIStroke")
AvatarChangerStroke.Color = Color3.fromRGB(83, 220, 255)
AvatarChangerStroke.Thickness = 2
AvatarChangerStroke.Transparency = 0.15
AvatarChangerStroke.Parent = AvatarChangerFrame

local AvatarChangerTitle = Instance.new("TextLabel")
AvatarChangerTitle.Size = UDim2.new(1, -44, 0, 36)
AvatarChangerTitle.Position = UDim2.new(0, 14, 0, 6)
AvatarChangerTitle.BackgroundTransparency = 1
AvatarChangerTitle.Text = "Avatar Changer"
AvatarChangerTitle.TextColor3 = Color3.fromRGB(210, 245, 255)
AvatarChangerTitle.Font = Enum.Font.GothamBold
AvatarChangerTitle.TextSize = 17
AvatarChangerTitle.TextXAlignment = Enum.TextXAlignment.Left
AvatarChangerTitle.Parent = AvatarChangerFrame

local AvatarChangerCloseBtn = Instance.new("TextButton")
AvatarChangerCloseBtn.Size = UDim2.new(0, 30, 0, 30)
AvatarChangerCloseBtn.Position = UDim2.new(1, -38, 0, 7)
AvatarChangerCloseBtn.BackgroundTransparency = 1
AvatarChangerCloseBtn.Text = "X"
AvatarChangerCloseBtn.TextColor3 = Color3.fromRGB(255, 128, 207)
AvatarChangerCloseBtn.Font = Enum.Font.GothamBold
AvatarChangerCloseBtn.TextSize = 18
AvatarChangerCloseBtn.Parent = AvatarChangerFrame

local AvatarUserIdBox = Instance.new("TextBox")
AvatarUserIdBox.Size = UDim2.new(1, -28, 0, 38)
AvatarUserIdBox.Position = UDim2.new(0, 14, 0, 52)
AvatarUserIdBox.BackgroundColor3 = Color3.fromRGB(15, 25, 52)
AvatarUserIdBox.PlaceholderText = "Username or User ID"
AvatarUserIdBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
AvatarUserIdBox.Text = ""
AvatarUserIdBox.TextColor3 = Color3.fromRGB(220, 240, 255)
AvatarUserIdBox.Font = Enum.Font.Gotham
AvatarUserIdBox.TextSize = 14
AvatarUserIdBox.ClearTextOnFocus = false
AvatarUserIdBox.Parent = AvatarChangerFrame
Instance.new("UICorner", AvatarUserIdBox).CornerRadius = UDim.new(0, 8)

local AvatarChangeBtn = Instance.new("TextButton")
AvatarChangeBtn.Size = UDim2.new(1, -28, 0, 38)
AvatarChangeBtn.Position = UDim2.new(0, 14, 0, 102)
AvatarChangeBtn.BackgroundColor3 = BUTTON_COLOR
AvatarChangeBtn.Text = "CHANGE AVATAR"
AvatarChangeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AvatarChangeBtn.Font = Enum.Font.GothamBold
AvatarChangeBtn.TextSize = 13
AvatarChangeBtn.Parent = AvatarChangerFrame
Instance.new("UICorner", AvatarChangeBtn).CornerRadius = UDim.new(0, 8)

local AvatarResetBtn = Instance.new("TextButton")
AvatarResetBtn.Size = UDim2.new(1, -28, 0, 34)
AvatarResetBtn.Position = UDim2.new(0, 14, 0, 146)
AvatarResetBtn.BackgroundColor3 = Color3.fromRGB(110, 70, 210)
AvatarResetBtn.Text = "RESET AVATAR"
AvatarResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AvatarResetBtn.Font = Enum.Font.GothamBold
AvatarResetBtn.TextSize = 13
AvatarResetBtn.Parent = AvatarChangerFrame
Instance.new("UICorner", AvatarResetBtn).CornerRadius = UDim.new(0, 8)

local function setAvatarButtonText(button, text)
    button.Text = text
    task.delay(2, function()
        if button == AvatarChangeBtn then
            button.Text = "CHANGE AVATAR"
        elseif button == AvatarResetBtn then
            button.Text = "RESET AVATAR"
        end
    end)
end

local function resolveAvatarUserId(input)
    input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then
        return nil, "TYPE USERNAME OR ID"
    end

    local livePlayer = Players:FindFirstChild(input)
    if livePlayer then
        return livePlayer.UserId, nil, livePlayer
    end

    local numericUserId = tonumber(input)
    if numericUserId and numericUserId >= 1 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == numericUserId then
                return numericUserId, nil, player
            end
        end

        return numericUserId
    end

    local ok, resolvedUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(input)
    end)

    if not ok or not resolvedUserId then
        return nil, "USER NOT FOUND"
    end

    return resolvedUserId
end

local function clearLocalAvatarAppearance(character)
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

    local head = character:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") and child.Name == "face" then
                child:Destroy()
            end
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

local function weldAccessoryToCharacter(accessory, character)
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        return false
    end

    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true

    local handleAttachment = handle:FindFirstChildOfClass("Attachment")
    local characterAttachment = handleAttachment and findCharacterAttachment(character, handleAttachment.Name)
    local targetPart = characterAttachment and characterAttachment.Parent

    if not handleAttachment or not characterAttachment or not targetPart or not targetPart:IsA("BasePart") then
        targetPart = character:FindFirstChild("Head")
        if not targetPart or not targetPart:IsA("BasePart") then
            return false
        end
    end

    local weld = handle:FindFirstChild("AccessoryWeld")
    if not weld then
        weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Parent = handle
    end

    weld.Part0 = handle
    weld.Part1 = targetPart

    if handleAttachment and characterAttachment then
        weld.C0 = handleAttachment.CFrame
        weld.C1 = characterAttachment.CFrame
    else
        local ok, attachmentPoint = pcall(function()
            return accessory.AttachmentPoint
        end)

        weld.C0 = CFrame.new()
        weld.C1 = ok and attachmentPoint or CFrame.new(0, 0.5, 0)
        handle.CFrame = targetPart.CFrame * weld.C1 * weld.C0:Inverse()
    end

    return true
end

local function addAvatarAccessory(character, humanoid, sourceAccessory)
    local accessory = sourceAccessory:Clone()
    accessory.Parent = character
    weldAccessoryToCharacter(accessory, character)
end

local function applyBodyDescriptionValues(humanoid, description)
    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        return
    end

    local scaleMap = {
        BodyDepthScale = { "DepthScale", "BodyDepthScale" },
        BodyHeightScale = { "HeightScale", "BodyHeightScale" },
        BodyProportionScale = { "ProportionScale", "BodyProportionScale" },
        BodyTypeScale = { "BodyTypeScale" },
        BodyWidthScale = { "WidthScale", "BodyWidthScale" },
        HeadScale = { "HeadScale" },
    }

    for humanoidScaleName, descriptionNames in pairs(scaleMap) do
        local valueObject = humanoid:FindFirstChild(humanoidScaleName)
        if valueObject and valueObject:IsA("NumberValue") then
            for _, descriptionName in ipairs(descriptionNames) do
                local ok, sourceValue = pcall(function()
                    return description[descriptionName]
                end)

                if ok and typeof(sourceValue) == "number" then
                    valueObject.Value = sourceValue
                    break
                end
            end
        end
    end
end

local function copyHeadFace(sourceModel, character)
    local sourceHead = sourceModel:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    if not sourceHead or not targetHead then
        return
    end

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

local function replaceR15BodyPartsFromModel(sourceModel, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local sourceHumanoid = sourceModel:FindFirstChildOfClass("Humanoid")

    if not humanoid
        or not sourceHumanoid
        or humanoid.RigType ~= Enum.HumanoidRigType.R15
        or sourceHumanoid.RigType ~= Enum.HumanoidRigType.R15 then
        return
    end

    local bodyPartMap = {
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

    for partName, bodyPartEnum in pairs(bodyPartMap) do
        local sourcePart = sourceModel:FindFirstChild(partName)
        if sourcePart and sourcePart:IsA("BasePart") then
            local replacement = sourcePart:Clone()
            replacement.Name = partName
            replacement.Anchored = false
            replacement.CanCollide = false
            replacement.Massless = false

            pcall(function()
                humanoid:ReplaceBodyPartR15(bodyPartEnum, replacement)
            end)
        end
    end
end

local function copyAvatarModelAppearance(sourceModel, character)
    clearLocalAvatarAppearance(character)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    replaceR15BodyPartsFromModel(sourceModel, character)

    for _, child in ipairs(sourceModel:GetDescendants()) do
        if child:IsA("BodyColors")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic") then
            child:Clone().Parent = character
        elseif child:IsA("CharacterMesh") and humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            child:Clone().Parent = character
        elseif child:IsA("Accessory") or child:IsA("Accoutrement") then
            addAvatarAccessory(character, humanoid, child)
        elseif child:IsA("BasePart") then
            local targetPart = character:FindFirstChild(child.Name)
            if targetPart
                and targetPart:IsA("BasePart")
                and not targetPart:IsA("MeshPart")
                and not child:IsA("MeshPart") then
                targetPart.Color = child.Color
                targetPart.Material = child.Material
            end
        end
    end

    copyHeadFace(sourceModel, character)

    return true
end

local function applyAvatarByGeneratedModel(userId, character)
    local ok, sourceModel = pcall(function()
        return Players:CreateHumanoidModelFromUserId(userId)
    end)

    if not ok or not sourceModel then
        return false, "MODEL FETCH FAILED"
    end

    sourceModel.Parent = nil

    local copyOk, copyErr = pcall(function()
        copyAvatarModelAppearance(sourceModel, character)
    end)

    sourceModel:Destroy()

    if not copyOk then
        warn("[Carti Hub] Avatar model copy failed: " .. tostring(copyErr))
        return false, "COPY FAILED"
    end

    return true
end

applyAvatarFromUserId = function(userIdOrName)
    local userId, resolveError = resolveAvatarUserId(userIdOrName)
    if not userId then
        return false, resolveError or "INVALID USER"
    end

    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "NO HUMANOID"
    end

    local ok, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)

    if not ok or not description then
        return false, "USER NOT FOUND"
    end

    local applyOk, applyErr = pcall(function()
        humanoid:ApplyDescriptionReset(description)
    end)

    if not applyOk then
        applyOk, applyErr = pcall(function()
            humanoid:ApplyDescription(description)
        end)
    end

    if not applyOk then
        warn("[Carti Hub] HumanoidDescription apply failed, using model copy fallback: " .. tostring(applyErr))
        applyBodyDescriptionValues(humanoid, description)
        local fallbackOk, fallbackErr = applyAvatarByGeneratedModel(userId, character)
        if fallbackOk then
            avatarPersistenceState.UserId = userId
        end
        return fallbackOk, fallbackErr
    end

    avatarPersistenceState.UserId = userId
    return true
end

avatarPersistenceState.Connection = localPlayer.CharacterAdded:Connect(function(character)
    local savedUserId = avatarPersistenceState.UserId
    if not savedUserId then
        return
    end

    task.spawn(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 5)
        if not humanoid then
            return
        end

        task.wait(0.35)
        if avatarPersistenceState.UserId == savedUserId and character == localPlayer.Character then
            local ok, errText = applyAvatarFromUserId(savedUserId)
            if not ok then
                warn("[Carti Hub] Could not restore saved avatar: " .. tostring(errText))
            end
        end
    end)
end)

AvatarChangerBtn.MouseButton1Click:Connect(function()
    AvatarChangerFrame.Visible = not AvatarChangerFrame.Visible
end)

AvatarChangerCloseBtn.MouseButton1Click:Connect(function()
    AvatarChangerFrame.Visible = false
end)

AvatarChangeBtn.MouseButton1Click:Connect(function()
    local ok, errText = applyAvatarFromUserId(AvatarUserIdBox.Text)
    setAvatarButtonText(AvatarChangeBtn, ok and "AVATAR CHANGED" or tostring(errText or "FAILED"))
end)

AvatarResetBtn.MouseButton1Click:Connect(function()
    local ok, errText = applyAvatarFromUserId(localPlayer.UserId)
    setAvatarButtonText(AvatarResetBtn, ok and "AVATAR RESET" or tostring(errText or "FAILED"))
end)

AvatarUserIdBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and AvatarUserIdBox.Text ~= "" then
        local ok, errText = applyAvatarFromUserId(AvatarUserIdBox.Text)
        setAvatarButtonText(AvatarChangeBtn, ok and "AVATAR CHANGED" or tostring(errText or "FAILED"))
    end
end)
end

local customUsers = {
    "XKylie_2010", "lakyboxsuperfann", "staglagala", "Anniev6157", "Augus0260", "carla_zion1",
    "itsme_ai1231", "itsme_llehvher", "GamergirlYT34577", "itsme_jane714", "Elle_62673",
    "urbb_jing", "Littlecupcake092389", "sampotieee", "etzorr_block", "jhanver_12906",
    "zoey685547", "baconkind68", "Amberx_xplayzz", "ethantherealsniper", "PrimPrim88009",
    "zxrcsiq", "jejemonlottto", "L0veBound", "iixemmyy", "gwapopan_j9912", "z0mbi33sr",
    "balakajan_12345", "black_totts", "ItzYoBoiJr", "harred1235", "ezz_game1234",
    "babu_5961", "lewis3417", "atm0sfer4", "kertkertgold", "They1uv_Z", "jindc4",
    "its_acegaming16", "GManU002", "x19soul", "Bluelockgod12101", "Itz_AlexandraPH",
    "BarbaFam9166", "STEVEN_AOTlol", "yea_yes21", "xXVanilla0re0Xx", "ashtine_be76",
    "Axisp0", "mine_nuwe", "Robloxiana3o2w6j0c", "eR050r", "boba_camnti", "Killer_03boy",
    "kevingnx102", "White170256", "crepecpu", "Sigma_of404", "winnerReD15", "Bos_s123456",
    "bombardio_duck", "jayabearrpurr", "mawgindonut", "ClaraZIzose", "qazwsxedcrfvtyhbj",
    "XxTWIC3xX", "adc_12367", "your_babyvincris", "killernaid2021", "dark_moon092",
    "jumar332211", "Cambo9", "MRSCHOCOLATE321", "kfiefiaiuy8e", "Pookung_M", "Ameerzelen",
    "Poolxdwwwww", "EIEIPROGG3", "darwisy_231115", "setan_4540", "xerluv", "Xarrense",
    "fl1xkr_xx", "zhenya_13008", "kinji3488", "0kayaddi", "AmirGtMl", "kdkei290",
    "fuji_XxD", "g0uu79024qtu05gq2ryg", "Angela320224", "mimpoopyui", "ukuha_tobe",
    "Ariayourpookie", "D1N0ST3R", "Eguiller2", "JSBoss1111", "DanielLikesRice2",
    "shanksthegreat26", "aydendesu", "tantoy123x6", "james1004338", "avoidsica",
}

local currentFakeTradeSenderName = "RandomPlayer"
_G.CartiHubLastTradedPlayerName = _G.CartiHubLastTradedPlayerName
_G.CartiHubPendingFakeTradeUsername = nil
_G.CartiHubActiveFakeTradeUsername = nil
_G.CartiHubFakeTradeActive = false
_G.CartiHubDebugFakeTradeAccept = false

local function pickFakeTradeSenderName()
    currentFakeTradeSenderName = customUsers[math.random(1, #customUsers)] or "RandomPlayer"
    return currentFakeTradeSenderName
end

function CartiHubNormalizeTradeUsername(username)
    username = tostring(username or "")
    username = username:gsub("^%s*%(", ""):gsub("%)%s*$", "")
    username = username:gsub("^@", "")
    username = username:gsub("^%s+", ""):gsub("%s+$", "")

    if username == "" or username == "RandomPlayer" then
        return nil
    end

    return username
end

function CartiHubSetLastTradedPlayerName(username)
    username = CartiHubNormalizeTradeUsername(username)

    if username and username ~= localPlayer.Name then
        _G.CartiHubLastTradedPlayerName = username

        if CartiHubTryAutoSelectLastTraded then
            CartiHubTryAutoSelectLastTraded(username)
        end
    end

    return _G.CartiHubLastTradedPlayerName
end

function CartiHubGetPlayerNameFromTradeText(text)
    text = CartiHubNormalizeTradeUsername(text)
    if not text then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local playerName = tostring(player.Name)
            local displayName = tostring(player.DisplayName or "")

            if text == playerName
                or text == displayName
                or text:find(playerName, 1, true)
                or (displayName ~= "" and text:find(displayName, 1, true)) then
                return playerName
            end
        end
    end

    return nil
end

function CartiHubUpdateLastTradedPlayerFromGui()
    if _G.CartiHubFakeTradeActive then
        return _G.CartiHubLastTradedPlayerName
    end

    local gui = tradeModule.GUI
    local tradeGui = gui and gui.TradeGUI
    if not tradeGui or not tradeGui.Enabled then
        return _G.CartiHubLastTradedPlayerName
    end

    local theirOffer = gui.TheirOffer
    local usernameLabel = theirOffer and theirOffer:FindFirstChild("Username")
    local playerName = usernameLabel and CartiHubGetPlayerNameFromTradeText(usernameLabel.Text)

    if playerName and playerName ~= currentFakeTradeSenderName then
        return CartiHubSetLastTradedPlayerName(playerName)
    end

    return _G.CartiHubLastTradedPlayerName
end

function CartiHubGetLastTradedPlayerName()
    local detectedName = CartiHubUpdateLastTradedPlayerFromGui()
    if detectedName then
        return detectedName
    end

    if _G.CartiHubLastTradedPlayerName then
        return _G.CartiHubLastTradedPlayerName
    end

    local gui = tradeModule.GUI
    local theirOffer = gui and gui.TheirOffer
    local usernameLabel = theirOffer and theirOffer:FindFirstChild("Username")

    return usernameLabel and CartiHubSetLastTradedPlayerName(usernameLabel.Text) or nil
end

task.spawn(function()
    while SakaUI == nil or SakaUI.Parent ~= nil do
        local gui = tradeModule.GUI
        local tradeGui = gui and gui.TradeGUI
        local theirOffer = gui and gui.TheirOffer
        local usernameLabel = theirOffer and theirOffer:FindFirstChild("Username")

        if not _G.CartiHubFakeTradeActive and tradeGui and tradeGui.Enabled and usernameLabel then
            local username = CartiHubGetPlayerNameFromTradeText(usernameLabel.Text)

            if username and username ~= currentFakeTradeSenderName then
                CartiHubSetLastTradedPlayerName(username)
            end
        end

        if not _G.CartiHubFakeTradeActive and tradeGui and tradeGui.Enabled then
            CartiHubUpdateLastTradedPlayerFromGui()
        end

        task.wait(0.5)
    end
end)

local function getFakeTradeSenderName()
    return currentFakeTradeSenderName or "RandomPlayer"
end

function CartiHubApplyPendingFakeTradeUsername()
    local pendingName = _G.CartiHubPendingFakeTradeUsername or _G.CartiHubActiveFakeTradeUsername
    local gui = tradeModule.GUI
    local theirOffer = gui and gui.TheirOffer
    local usernameLabel = theirOffer and theirOffer:FindFirstChild("Username")

    if not pendingName or not usernameLabel then
        return
    end

    usernameLabel.Text = "(" .. tostring(pendingName) .. ")"
end

local function getFriendJoinThumbnail(username)
    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not ok or not userId then
        return "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150"
    end

    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
end

local function showFriendJoinSystemMessage(username)
    local message = ("Your friend %s has joined the game."):format(username)
    local textChatOk = pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channels = TextChatService:FindFirstChild("TextChannels")
        local systemChannel = channels and (
            channels:FindFirstChild("RBXSystem")
            or channels:FindFirstChild("RBXGeneral")
        )

        if systemChannel then
            systemChannel:DisplaySystemMessage(
                '<font color="rgb(255,255,255)">' .. message .. '</font>'
            )
        else
            error("No TextChatService system channel")
        end
    end)

    if textChatOk then
        return true
    end

    local StarterGui = game:GetService("StarterGui")
    for _ = 1, 20 do
        local legacyOk = pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = message,
                Color = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.SourceSans,
                TextSize = 18,
            })
        end)

        if legacyOk then
            return true
        end

        task.wait(0.25)
    end

    warn("[Carti Hub] Could not show friend join chat notification.")
    return false
end

local friendJoinToastSequence = 0

local function showFriendJoinTopToast(username)
    friendJoinToastSequence += 1
    local sequence = friendJoinToastSequence
    local parent = safeParent()

    local oldGui = parent:FindFirstChild("CartiHubFriendJoinTopToast")
    if oldGui then
        oldGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CartiHubFriendJoinTopToast"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 100000
    gui.Parent = parent

    local toastText = tostring(username) .. " joined you"

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 0)
    holder.Size = UDim2.new(0, 405, 0, 58)
    holder.Position = UDim2.new(0.5, 0, 0, -72)
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = holder

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(90, 91, 97)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = holder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(118, 119, 126)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(98, 99, 106)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 81, 88)),
    })
    gradient.Parent = frame

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 36, 0, 36)
    avatar.Position = UDim2.new(0, 12, 0.5, -18)
    avatar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    avatar.BorderSizePixel = 0
    avatar.Image = getFriendJoinThumbnail(username)
    avatar.Parent = frame
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(0, 105, 210)
    avatarStroke.Transparency = 0
    avatarStroke.Thickness = 1
    avatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    avatarStroke.Parent = avatar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -66, 1, 0)
    title.Position = UDim2.new(0, 58, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = toastText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.BuilderSansBold
    title.TextSize = 18
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = frame

    if holder.AbsoluteSize.X > 0 and holder.AbsoluteSize.X > gui.AbsoluteSize.X - 24 then
        scale.Scale = math.max(0.72, (gui.AbsoluteSize.X - 24) / holder.AbsoluteSize.X)
    end

    TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, -30),
    }):Play()

    task.delay(4.5, function()
        if sequence ~= friendJoinToastSequence or not holder.Parent then
            return
        end

        TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -72),
        }):Play()

        TweenService:Create(frame, TweenInfo.new(0.2), {
            BackgroundTransparency = 1,
        }):Play()

        task.wait(0.28)
        if gui.Parent then
            gui:Destroy()
        end
    end)
end

local function showFakeFriendJoinNotification(username)
    username = username or customUsers[math.random(1, #customUsers)] or "RobloxPlayer"
    showFriendJoinSystemMessage(username)
    showFriendJoinTopToast(username)
end

local function showRandomFakeFriendJoinNotification()
    showFakeFriendJoinNotification(customUsers[math.random(1, #customUsers)])
end

local function setAutoFriendJoinEnabled(enabled)
    autoFriendJoinEnabled = enabled
    autoFriendJoinSequence += 1
    local sequence = autoFriendJoinSequence

    AutoFriendJoinBtn.Text = enabled and "AUTO FRIEND JOIN: ON" or "AUTO FRIEND JOIN: OFF"
    AutoFriendJoinBtn.BackgroundColor3 = enabled and BUTTON_HOVER_COLOR or BUTTON_COLOR

    if not enabled then
        return
    end

    task.spawn(function()
        while autoFriendJoinEnabled and sequence == autoFriendJoinSequence and SakaUI and SakaUI.Parent do
            showRandomFakeFriendJoinNotification()

            local waitRemaining = math.max(1, tonumber(friendJoinDelaySeconds) or 30)
            while waitRemaining > 0 and autoFriendJoinEnabled and sequence == autoFriendJoinSequence do
                task.wait(math.min(1, waitRemaining))
                waitRemaining -= 1
            end
        end
    end)
end

FriendJoinToggleBtn.MouseButton1Click:Connect(function()
    showRandomFakeFriendJoinNotification()
end)

AutoFriendJoinBtn.MouseButton1Click:Connect(function()
    setAutoFriendJoinEnabled(not autoFriendJoinEnabled)
end)

local theirOffer = {}
local localOffer = {}
local localAcceptMode = "Accept"
local localConfirmStartedAt = 0
local cooldownEndsAt = 0
local cooldownSequence = 0
local otherAcceptSequence = 0
local redrawLocalTrade
local resetAcceptUi
local installOfferRemoveButtons
local refreshMainInventoryQueued = false

local function cleanupOldOverlays()
    local gui = tradeModule.GUI
    if not gui then
        return
    end

    for _, root in ipairs({ gui.TradeGUI }) do
        if root then
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant.Name == "ClientPlaceholderTradeRemove"
                    or descendant.Name == "ClientPlaceholderTradeToggle"
                    or descendant.Name == "ClientPlaceholderTradeAcceptBridge"
                    or descendant.Name == "ClientPlaceholderTradeAcceptOverlay"
                    or descendant.Name == "ClientPlaceholderTradeActionOverlay"
                    or descendant.Name == "CartiHubFakeTradeWatermark" then
                    descendant:Destroy()
                end
            end
        end
    end
end

-- All fake-trade controls are parented into the game's shared trade GUI. They
-- must be removed before the next real trade or they intercept its buttons.
function CartiHubEndFakeTradeSession()
    _G.CartiHubFakeTradeActive = false
    _G.CartiHubFakeTradeVisualSequence = (_G.CartiHubFakeTradeVisualSequence or 0) + 1
    _G.CartiHubAutoTradeOfferSequence = (_G.CartiHubAutoTradeOfferSequence or 0) + 1
    _G.CartiHubPendingFakeTradeUsername = nil
    _G.CartiHubActiveFakeTradeUsername = nil
    _G.CartiHubInstantFakeTradeReturnPending = false

    if CartiHubDisconnectFakeTradeFrameGuardSignals then
        CartiHubDisconnectFakeTradeFrameGuardSignals()
    end

    cleanupOldOverlays()
end

local function clearLeakedFakeTradeControls()
    if _G.CartiHubFakeTradeActive then
        return
    end

    local gui = tradeModule.GUI
    local tradeGui = gui and gui.TradeGUI
    if not tradeGui then
        return
    end

    local leaked = false
    for _, descendant in ipairs(tradeGui:GetDescendants()) do
        if descendant.Name == "ClientPlaceholderTradeActionOverlay"
            or descendant.Name == "ClientPlaceholderTradeToggle"
            or descendant.Name == "ClientPlaceholderTradeRemove"
            or descendant.Name == "CartiHubFakeTradeWatermark" then
            leaked = true
            break
        end
    end

    if leaked then
        CartiHubEndFakeTradeSession()
    end
end

task.spawn(function()
    while SakaUI == nil or SakaUI.Parent ~= nil do
        clearLeakedFakeTradeControls()
        task.wait(0.2)
    end
end)

local function clearOfferSlots(offerFrame)
    if not offerFrame or not offerFrame:FindFirstChild("Container") then
        return
    end

    for index = 1, 4 do
        local slot = offerFrame.Container:FindFirstChild("NewItem" .. index)
        if slot then
            itemModule.DisplayItem(slot, nil)
            slot.Visible = false
        end
    end
end

local function copyItemData(itemId, itemType, amount)
    local source = sync[itemType] and sync[itemType][itemId]
    if not source then
        return nil
    end

    local data = {}
    for key, value in pairs(source) do
        data[key] = value
    end

    data.DataType = itemType
    data.Amount = amount or 1
    return data
end

local function refreshMainInventoryItem()
    if refreshMainInventoryQueued then
        return
    end

    refreshMainInventoryQueued = true

    task.defer(function()
        refreshMainInventoryQueued = false
        refreshMainInventoryNow()
    end)
end

local function isTradeGuiOpen()
    return tradeModule.GUI
        and tradeModule.GUI.TradeGUI
        and tradeModule.GUI.TradeGUI.Enabled
end

local function applyInventoryDelta(itemId, itemType, delta)
    local owned = getProfileOwnedTable(itemType)
    if not owned then
        warn(("[IncomingTradePopup] No local owned table for %s/%s"):format(tostring(itemType), tostring(itemId)))
        return
    end

    local hasFakeStack = CartiHubGetFakeInventoryAmount(itemId, itemType) > 0
    local current = tonumber(owned[itemId]) or 0
    local nextAmount

    if hasFakeStack then
        nextAmount = CartiHubAddFakeInventoryAmount(itemId, itemType, delta)
    else
        nextAmount = current + delta
        if nextAmount > 0 then
            owned[itemId] = nextAmount
        else
            owned[itemId] = nil
        end
    end

    local tradeInventory = tradeModule.TradeInventory
    local entry = tradeInventory
        and tradeInventory.Data
        and tradeInventory.Data[itemType]
        and tradeInventory.Data[itemType].Current
        and tradeInventory.Data[itemType].Current[itemId]

    if entry then
        entry.Amount = math.max(0, (tonumber(entry.Amount) or current) + delta)

        if entry.Frame then
            if entry.Amount <= 0 then
                entry.Frame.Visible = false
            else
                local itemData = copyItemData(itemId, itemType, entry.Amount)
                if itemData then
                    itemModule.DisplayItem(entry.Frame, itemData, nil, true)
                end
                entry.Frame.Visible = true
            end
        end
    end

    if not isTradeGuiOpen() then
        task.defer(refreshMainInventoryItem)
    end
end

local function restoreLocalOfferToInventory()
    for _, offer in ipairs(localOffer) do
        applyInventoryDelta(offer.ItemID, offer.ItemType, offer.Amount or 1)
    end

    table.clear(localOffer)
end

local function addTheirOfferToInventory(offerList)
    for _, offer in ipairs(offerList or theirOffer) do
        applyInventoryDelta(offer.ItemID, offer.ItemType, offer.Amount or 1)
    end
end

_G.CartiHubSeasonalOfferTagConnections = _G.CartiHubSeasonalOfferTagConnections or {}

function CartiHubClearSeasonalOfferTagGuards(slot)
    local tags = slot and slot:FindFirstChild("Tags", true)
    if not tags then
        return
    end

    for _, tagName in ipairs({ "Halloween", "Christmas" }) do
        local tag = tags:FindFirstChild(tagName)
        local connection = tag and _G.CartiHubSeasonalOfferTagConnections[tag]
        if connection then
            connection:Disconnect()
            _G.CartiHubSeasonalOfferTagConnections[tag] = nil
        end
    end
end

function CartiHubHideSeasonalOfferTags(slot)
    local tags = slot and slot:FindFirstChild("Tags", true)
    if not tags then
        return
    end

    for _, tagName in ipairs({ "Halloween", "Christmas" }) do
        local tag = tags:FindFirstChild(tagName)
        if tag and tag:IsA("GuiObject") then
            local oldConnection = _G.CartiHubSeasonalOfferTagConnections[tag]
            if oldConnection then
                oldConnection:Disconnect()
            end

            tag.Visible = false
            _G.CartiHubSeasonalOfferTagConnections[tag] = tag:GetPropertyChangedSignal("Visible"):Connect(function()
                if tag.Parent and tag.Visible then
                    tag.Visible = false
                end
            end)
        end
    end
end

local function drawOfferSlots(offerFrame, offerList)
    clearOfferSlots(offerFrame)

    for index, offer in ipairs(offerList) do
        local slot = offerFrame
            and offerFrame:FindFirstChild("Container")
            and offerFrame.Container:FindFirstChild("NewItem" .. index)

        local itemData = copyItemData(offer.ItemID, offer.ItemType, offer.Amount)
        if slot and itemData then
            CartiHubClearSeasonalOfferTagGuards(slot)
            itemModule.DisplayItem(slot, itemData)
            if offer.HideSeasonalTags then
                CartiHubHideSeasonalOfferTags(slot)
            end
            slot.Visible = true
        end
    end
end

function CartiHubEnforceFakeTradeFrame()
    if not _G.CartiHubFakeTradeActive or not tradeModule.GUI or not tradeModule.GUI.TradeGUI then
        return
    end

    if not tradeModule.GUI.TradeGUI.Enabled then
        tradeModule.GUI.TradeGUI.Enabled = true
    end

    if tradeModule.GUI.TradeGUI:FindFirstChild("Container") then
        tradeModule.GUI.TradeGUI.Container.Visible = true
    end

    if localAcceptMode == "Waiting" or localAcceptMode == "BothAccepted" then
        return
    end

    drawOfferSlots(tradeModule.GUI.YourOffer, localOffer)
    drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)

    if tradeModule.GUI.TheirOffer and tradeModule.GUI.TheirOffer:FindFirstChild("Username") then
        tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
        CartiHubApplyPendingFakeTradeUsername()
    end

    if installOfferRemoveButtons then
        installOfferRemoveButtons()
    end

    if localAcceptMode == "Accept" then
        CartiHubWakeAcceptActionButton()
    else
        CartiHubSetAcceptContainerOverlayVisible(false)
    end

    CartiHubTraceFakeAcceptState("enforce")
end

function CartiHubQueueFakeTradeFrameRepair()
    if not _G.CartiHubFakeTradeActive then
        return
    end

    task.defer(CartiHubEnforceFakeTradeFrame)
end

function CartiHubDisconnectFakeTradeFrameGuardSignals()
    _G.CartiHubAutoTradeOfferSequence = (_G.CartiHubAutoTradeOfferSequence or 0) + 1

    for _, connection in ipairs(_G.CartiHubFakeTradeGuardConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    _G.CartiHubFakeTradeGuardConnections = {}

    if _G.CartiHubFakeTradeSearchConnection then
        pcall(function()
            _G.CartiHubFakeTradeSearchConnection:Disconnect()
        end)
        _G.CartiHubFakeTradeSearchConnection = nil
    end
end

function CartiHubConnectFakeTradeFrameGuardSignals()
    CartiHubDisconnectFakeTradeFrameGuardSignals()

    local gui = tradeModule.GUI
    local tradeGui = gui and gui.TradeGUI
    _G.CartiHubFakeTradeGuardConnections = {}

    if tradeGui then
        table.insert(_G.CartiHubFakeTradeGuardConnections, tradeGui:GetPropertyChangedSignal("Enabled"):Connect(CartiHubQueueFakeTradeFrameRepair))

        if tradeGui:FindFirstChild("Container") then
            table.insert(_G.CartiHubFakeTradeGuardConnections, tradeGui.Container:GetPropertyChangedSignal("Visible"):Connect(CartiHubQueueFakeTradeFrameRepair))
        end
    end

end

function CartiHubStartFakeTradeFrameGuard()
    _G.CartiHubFakeTradeVisualSequence = (_G.CartiHubFakeTradeVisualSequence or 0) + 1
    local sequence = _G.CartiHubFakeTradeVisualSequence
    CartiHubConnectFakeTradeFrameGuardSignals()

    task.spawn(function()
        while _G.CartiHubFakeTradeActive
            and sequence == _G.CartiHubFakeTradeVisualSequence
            and SakaUI
            and SakaUI.Parent do
            CartiHubEnforceFakeTradeFrame()
            task.wait(0.08)
        end

        if sequence == _G.CartiHubFakeTradeVisualSequence then
            CartiHubDisconnectFakeTradeFrameGuardSignals()
        end
    end)
end

local function setLocalAcceptState(mode)
    local actions = tradeModule.GUI.Actions
    local accept = actions and actions:FindFirstChild("Accept")
    if not accept then
        return
    end

    localAcceptMode = mode

    if accept:FindFirstChild("Confirm") then
        accept.Confirm.Visible = mode == "Confirm"
    end

    if accept:FindFirstChild("Cancel") then
        accept.Cancel.Visible = mode == "Waiting" or mode == "BothAccepted"
    end

    if accept:FindFirstChild("Cooldown") and mode ~= "Cooldown" then
        accept.Cooldown.Visible = false
    end

    if accept:FindFirstChild("AddItem") then
        accept.AddItem.Visible = mode == "Cooldown"
    end

    if tradeModule.GUI.YourOffer:FindFirstChild("Accepted") then
        tradeModule.GUI.YourOffer.Accepted.Visible = mode == "Waiting" or mode == "BothAccepted"
    end

    if tradeModule.GUI.TheirOffer:FindFirstChild("Accepted") then
        tradeModule.GUI.TheirOffer.Accepted.Visible = mode == "BothAccepted"
    end

    CartiHubSetAcceptContainerOverlayVisible(mode == "Accept")
end

function CartiHubHandleFakeAcceptClick()
    CartiHubTraceFakeAcceptState("accept_click")

    if localAcceptMode == "Accept" and time() >= cooldownEndsAt then
        localConfirmStartedAt = time()
        setLocalAcceptState("Confirm")
        CartiHubTraceFakeAcceptState("accept_to_confirm")
    end
end

function CartiHubSetAcceptContainerOverlayVisible(visible)
    local actions = tradeModule.GUI and tradeModule.GUI.Actions
    local accept = actions and actions:FindFirstChild("Accept")
    local overlay = accept and accept:FindFirstChild("ClientPlaceholderTradeActionOverlay")

    if overlay and overlay:IsA("GuiObject") then
        overlay.Visible = visible
    end
end

function CartiHubTraceFakeAcceptState(reason)
    return
end

function CartiHubWakeAcceptActionButton()
    local actions = tradeModule.GUI and tradeModule.GUI.Actions
    local accept = actions and actions:FindFirstChild("Accept")
    if not accept then
        return
    end

    accept.Visible = true

    if accept:FindFirstChild("Cooldown") and localAcceptMode ~= "Cooldown" then
        accept.Cooldown.Visible = false
    end

    if accept:FindFirstChild("AddItem") and localAcceptMode ~= "Cooldown" then
        accept.AddItem.Visible = false
    end

    if accept:FindFirstChild("Confirm") and localAcceptMode ~= "Confirm" then
        accept.Confirm.Visible = false
    end

    if accept:FindFirstChild("Cancel") and localAcceptMode ~= "Waiting" and localAcceptMode ~= "BothAccepted" then
        accept.Cancel.Visible = false
    end

    local actionButton = accept:FindFirstChild("ActionButton")
    if actionButton and actionButton:IsA("GuiObject") then
        actionButton.Visible = true
        actionButton.ZIndex = math.max(actionButton.ZIndex, accept.ZIndex + 1)
    end

    if actionButton and actionButton:IsA("GuiButton") then
        actionButton.Active = true
        actionButton.Selectable = true
        actionButton.AutoButtonColor = true
    end

    local containerOverlay = accept:FindFirstChild("ClientPlaceholderTradeActionOverlay")
    if not containerOverlay then
        containerOverlay = Instance.new("TextButton")
        containerOverlay.Name = "ClientPlaceholderTradeActionOverlay"
        containerOverlay.BackgroundTransparency = 1
        containerOverlay.BorderSizePixel = 0
        containerOverlay.Text = ""
        containerOverlay.Size = UDim2.fromScale(1, 1)
        containerOverlay.Position = UDim2.fromScale(0, 0)
        containerOverlay.Parent = accept
        containerOverlay.MouseButton1Click:Connect(CartiHubHandleFakeAcceptClick)
    end

    if containerOverlay:IsA("GuiObject") then
        containerOverlay.Visible = localAcceptMode == "Accept"
        containerOverlay.BackgroundTransparency = 1
        containerOverlay.ZIndex = accept.ZIndex + 200
        containerOverlay.Size = UDim2.fromScale(1, 1)
        containerOverlay.Position = UDim2.fromScale(0, 0)
    end

    if containerOverlay:IsA("GuiButton") then
        containerOverlay.Active = true
        containerOverlay.Selectable = true
        containerOverlay.AutoButtonColor = false
    end

    local overlay = actionButton and actionButton:FindFirstChild("ClientPlaceholderTradeActionOverlay")
    if actionButton and not overlay then
        overlay = Instance.new("TextButton")
        overlay.Name = "ClientPlaceholderTradeActionOverlay"
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Text = ""
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.Position = UDim2.fromScale(0, 0)
        overlay.Parent = actionButton
        overlay.MouseButton1Click:Connect(CartiHubHandleFakeAcceptClick)
    end

    if overlay and overlay:IsA("GuiObject") then
        overlay.Visible = localAcceptMode == "Accept"
        overlay.BackgroundTransparency = 1
        overlay.ZIndex = actionButton.ZIndex + 100
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.Position = UDim2.fromScale(0, 0)
    end

    if overlay and overlay:IsA("GuiButton") then
        overlay.Active = true
        overlay.Selectable = true
        overlay.AutoButtonColor = false
    end

    CartiHubTraceFakeAcceptState("wake")
end

function CartiHubForceFakeAcceptReady()
    if not _G.CartiHubFakeTradeActive then
        return
    end

    localAcceptMode = "Accept"

    local actions = tradeModule.GUI and tradeModule.GUI.Actions
    local accept = actions and actions:FindFirstChild("Accept")

    if accept then
        accept.Visible = true

        if accept:FindFirstChild("Cooldown") then
            accept.Cooldown.Visible = false
        end

        if accept:FindFirstChild("AddItem") then
            accept.AddItem.Visible = false
        end

        if accept:FindFirstChild("Confirm") then
            accept.Confirm.Visible = false
        end

        if accept:FindFirstChild("Cancel") then
            accept.Cancel.Visible = false
        end
    end

    CartiHubWakeAcceptActionButton()
    CartiHubSetAcceptContainerOverlayVisible(true)
    CartiHubTraceFakeAcceptState("force_ready")
end

function CartiHubStabilizeFakeAcceptReady(sequence)
    task.spawn(function()
        for _ = 1, 8 do
            if sequence ~= cooldownSequence or not _G.CartiHubFakeTradeActive or localAcceptMode ~= "Accept" then
                return
            end

            CartiHubForceFakeAcceptReady()
            task.wait(0.05)
        end
    end)
end

local function promptReceivedTheirOfferItems(offerList)
    for _, offer in ipairs(offerList or theirOffer) do
        local ok, err = pcall(function()
            itemPopupService:AddNewItem(offer.ItemID, offer.ItemType, offer.Amount or 1)
        end)

        if not ok then
            warn(("[IncomingTradePopup] Item popup failed for %s/%s: %s"):format(
                tostring(offer.ItemType),
                tostring(offer.ItemID),
                tostring(err)
            ))
        end
    end
end

local function scheduleOtherSideAccept()
    otherAcceptSequence += 1
    local sequence = otherAcceptSequence
    local delaySeconds = math.random(10, 30) / 10

    task.delay(delaySeconds, function()
        if sequence ~= otherAcceptSequence or localAcceptMode ~= "Waiting" then
            return
        end

        if tradeModule.GUI.TheirOffer:FindFirstChild("Accepted") then
            tradeModule.GUI.TheirOffer.Accepted.Visible = true
        end

        task.delay(1, function()
            if sequence ~= otherAcceptSequence or localAcceptMode ~= "Waiting" then
                return
            end

            local tradeGui = tradeModule.GUI.TradeGUI
            local receivedItems = {}
            local returnTradeUsername = _G.CartiHubInstantFakeTradeReturnPending
                and getFakeTradeSenderName()

            _G.CartiHubInstantFakeTradeReturnPending = false

            for _, offer in ipairs(theirOffer) do
                table.insert(receivedItems, {
                    ItemID = offer.ItemID,
                    ItemType = offer.ItemType,
                    Amount = offer.Amount or 1,
                })
            end

            tradeGui.Enabled = false
            CartiHubEndFakeTradeSession()
            addTheirOfferToInventory(receivedItems)
            refreshMainInventoryItem()
            promptReceivedTheirOfferItems(receivedItems)
            tradeModule.TradeInventory = nil
            table.clear(localOffer)
            table.clear(theirOffer)
            resetAcceptUi()
            clearOfferSlots(tradeModule.GUI.YourOffer)
            clearOfferSlots(tradeModule.GUI.TheirOffer)

            if returnTradeUsername then
                task.delay(math.random(20, 40) / 10, function()
                    if SakaUI and SakaUI.Parent and CartiHubLaunchInstantFakePersonTrade then
                        CartiHubLaunchInstantFakePersonTrade(returnTradeUsername, true)
                    end
                end)
            end
        end)
    end)
end

local function startAcceptCooldown(seconds)
    local actions = tradeModule.GUI.Actions
    local accept = actions and actions:FindFirstChild("Accept")
    local cooldown = accept and accept:FindFirstChild("Cooldown")
    local title = cooldown and cooldown:FindFirstChild("Title")

    if not cooldown then
        return
    end

    cooldownSequence += 1
    local sequence = cooldownSequence
    cooldownEndsAt = time() + seconds
    localAcceptMode = "Cooldown"

    if accept:FindFirstChild("Confirm") then
        accept.Confirm.Visible = false
    end

    if accept:FindFirstChild("Cancel") then
        accept.Cancel.Visible = false
    end

    if tradeModule.GUI.YourOffer:FindFirstChild("Accepted") then
        tradeModule.GUI.YourOffer.Accepted.Visible = false
    end

    cooldown.Visible = true
    CartiHubSetAcceptContainerOverlayVisible(false)
    CartiHubTraceFakeAcceptState("cooldown_start")

    task.spawn(function()
        while sequence == cooldownSequence do
            local remaining = math.max(0, math.ceil(cooldownEndsAt - time()))
            if title then
                title.Text = ("Please wait (%d) before accepting."):format(remaining)
            end

            if remaining <= 0 then
                break
            end

            task.wait(0.2)
        end

        if sequence == cooldownSequence then
            CartiHubTraceFakeAcceptState("cooldown_end_before_ready")
            CartiHubForceFakeAcceptReady()
            CartiHubStabilizeFakeAcceptReady(sequence)
        end
    end)
end

resetAcceptUi = function()
    cooldownSequence += 1
    otherAcceptSequence += 1
    cooldownEndsAt = 0
    setLocalAcceptState("Accept")
    CartiHubWakeAcceptActionButton()
    task.defer(CartiHubWakeAcceptActionButton)

    local actions = tradeModule.GUI.Actions
    if actions and actions:FindFirstChild("oldconfirm") then
        actions.oldconfirm.Visible = false
    end
end

installOfferRemoveButtons = function()
    local yourOffer = tradeModule.GUI.YourOffer
    if not yourOffer or not yourOffer:FindFirstChild("Container") then
        return
    end

    for index = 1, 4 do
        local slot = yourOffer.Container:FindFirstChild("NewItem" .. index)
        if slot then
            local oldOverlay = slot:FindFirstChild("ClientPlaceholderTradeRemove")
            if oldOverlay then
                oldOverlay:Destroy()
            end

            if localOffer[index] then
                local overlay = Instance.new("TextButton")
                overlay.Name = "ClientPlaceholderTradeRemove"
                overlay.BackgroundTransparency = 1
                overlay.BorderSizePixel = 0
                overlay.Text = ""
                overlay.Size = UDim2.fromScale(1, 1)
                overlay.Position = UDim2.fromScale(0, 0)
                overlay.ZIndex = slot.ZIndex + 50
                overlay.Parent = slot

                overlay.MouseButton1Click:Connect(function()
                    local removed = table.remove(localOffer, index)
                    if removed then
                        applyInventoryDelta(removed.ItemID, removed.ItemType, removed.Amount or 1)
                    end

                    if redrawLocalTrade then
                        redrawLocalTrade()
                    end
                end)
            end
        end
    end
end

redrawLocalTrade = function()
    drawOfferSlots(tradeModule.GUI.YourOffer, localOffer)
    drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
    resetAcceptUi()
    tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
    CartiHubApplyPendingFakeTradeUsername()
    installOfferRemoveButtons()
end

local function toggleLocalOffer(itemId, itemType)
    if not canFakeTradeItem(itemId, itemType) then
        warn(("[IncomingTradePopup] %s/%s is not tradeable."):format(tostring(itemType), tostring(itemId)))
        return
    end

    for _, offer in ipairs(localOffer) do
        if offer.ItemID == itemId and offer.ItemType == itemType then
            offer.Amount = (tonumber(offer.Amount) or 1) + 1
            applyInventoryDelta(itemId, itemType, -1)
            redrawLocalTrade()
            startAcceptCooldown(6)
            return
        end
    end

    if #localOffer >= 4 then
        warn("[IncomingTradePopup] Trade offer is full.")
        return
    end

    table.insert(localOffer, {
        ItemID = itemId,
        Amount = 1,
        ItemType = itemType,
    })

    applyInventoryDelta(itemId, itemType, -1)
    redrawLocalTrade()
    startAcceptCooldown(6)
end

function CartiHubGetFakeTradeSearchBox()
    local gui = tradeModule.GUI
    local tradeGui = gui and gui.TradeGUI

    return tradeGui
        and tradeGui:FindFirstChild("Container")
        and tradeGui.Container:FindFirstChild("Items")
        and tradeGui.Container.Items:FindFirstChild("Tabs")
        and tradeGui.Container.Items.Tabs:FindFirstChild("Search")
        and tradeGui.Container.Items.Tabs.Search:FindFirstChild("Container")
        and tradeGui.Container.Items.Tabs.Search.Container:FindFirstChild("SearchText")
end

function CartiHubStartAutoTradeOfferFill()
    _G.CartiHubAutoTradeOfferSequence = (_G.CartiHubAutoTradeOfferSequence or 0) + 1
    local sequence = _G.CartiHubAutoTradeOfferSequence

    task.spawn(function()
        local function isActive()
            return _G.CartiHubAutoTradeOfferSequence == sequence and _G.CartiHubFakeTradeActive == true
        end

        local function isAlreadyOffered(itemId, itemType)
            for _, offer in ipairs(localOffer) do
                if offer.ItemID == itemId and offer.ItemType == itemType then
                    return true
                end
            end

            return false
        end

        local function getCandidate()
            local inventory = tradeModule.TradeInventory
            local candidates = {}
            local searchTerms = _G.CartiHubAutoTradeSearchTerms

            if type(searchTerms) ~= "table" or #searchTerms == 0 then
                return nil
            end

            for itemType, typeData in pairs(inventory and inventory.Data or {}) do
                if itemType == "Weapons" or itemType == "Item" then
                    for itemId, entry in pairs(typeData.Current or {}) do
                        local availableAmount = math.max(0, math.floor(tonumber(entry.Amount) or 0))
                        if availableAmount > 0
                            and canFakeTradeItem(itemId, itemType)
                            and not isAlreadyOffered(itemId, itemType) then
                            local itemName = tostring(entry.Name or itemId)
                            local lowerItemName = itemName:lower()

                            for _, term in ipairs(searchTerms) do
                                term = tostring(term or "")
                                if term ~= "" and lowerItemName:find(term:lower(), 1, true) then
                                    table.insert(candidates, {
                                        ItemID = itemId,
                                        ItemType = itemType,
                                        Name = itemName,
                                        SearchTerm = term,
                                        AvailableAmount = availableAmount,
                                    })
                                end
                            end
                        end
                    end
                end
            end

            if #candidates == 0 then
                return nil
            end

            return candidates[math.random(1, #candidates)]
        end

        local function typeSearch(searchText, term)
            task.wait(math.random(100, 180) / 100)
            if not isActive() or not searchText.Parent then
                return false
            end

            searchText.Text = ""

            for index = 1, #term do
                if not isActive() or not searchText.Parent then
                    return false
                end

                searchText.Text = term:sub(1, index)
                task.wait(math.random(6, 16) / 100)
            end

            return true
        end

        while isActive() and #localOffer < 4 do
            local candidate = getCandidate()
            local searchText = CartiHubGetFakeTradeSearchBox()
            if not candidate or not searchText or not searchText:IsA("TextBox") then
                return
            end

            if not typeSearch(searchText, tostring(candidate.SearchTerm)) then
                return
            end

            local addCount = math.random(1, math.min(3, candidate.AvailableAmount))
            for _ = 1, addCount do
                if not isActive() then
                    return
                end

                toggleLocalOffer(candidate.ItemID, candidate.ItemType)
                task.wait(math.random(45, 90) / 100)
            end

            task.wait(math.random(20, 45) / 100)
            for index = #searchText.Text - 1, 0, -1 do
                if not isActive() or not searchText.Parent then
                    return
                end

                searchText.Text = searchText.Text:sub(1, index)
                task.wait(math.random(10, 20) / 100)
            end

            task.wait(math.random(25, 55) / 100)
        end

        while isActive() and localAcceptMode == "Cooldown" do
            task.wait(0.1)
        end

        if isActive() and #localOffer >= 4 and localAcceptMode == "Accept" then
            task.wait(math.random(35, 75) / 100)
        end

        if isActive() and #localOffer >= 4 and localAcceptMode == "Accept" then
            localConfirmStartedAt = time()
            setLocalAcceptState("Confirm")
            task.wait(math.random(60, 115) / 100)

            if isActive() and localAcceptMode == "Confirm" then
                setLocalAcceptState("Waiting")
                scheduleOtherSideAccept()
            end
        end
    end)
end

local function getRandomGodlyWeapon()
    local candidates = {}

    for itemId, data in pairs(sync.Weapons or {}) do
        if type(data) == "table"
            and data.Rarity == "Godly"
            and (data.ItemType == "Knife" or data.ItemType == "Gun")
            and canFakeTradeItem(itemId, "Weapons") then
            table.insert(candidates, {
                ItemID = itemId,
                Amount = 1,
                ItemType = "Weapons",
            })
        end
    end

    if #candidates < 1 then
        return nil
    end

    return candidates[math.random(1, #candidates)]
end

local function addItemToTheirOfferStack(itemId, itemType, amount, hideSeasonalTags)
    amount = tonumber(amount) or 1
    local sourceData = sync[itemType] and sync[itemType][itemId]
    local displayName = sourceData and (sourceData.ItemName or sourceData.Name) or itemId
    local rarity = sourceData and sourceData.Rarity or ""
    local stackKey = table.concat({
        tostring(itemType),
        tostring(rarity),
        normalizeItemText(displayName),
    }, ":")

    for _, offer in ipairs(theirOffer) do
        local offerData = sync[offer.ItemType] and sync[offer.ItemType][offer.ItemID]
        local offerName = offerData and (offerData.ItemName or offerData.Name) or offer.ItemID
        local offerRarity = offerData and offerData.Rarity or ""
        local offerStackKey = offer.StackKey or table.concat({
            tostring(offer.ItemType),
            tostring(offerRarity),
            normalizeItemText(offerName),
        }, ":")

        if (offer.ItemID == itemId and offer.ItemType == itemType)
            or offerStackKey == stackKey then
            offer.Amount = (tonumber(offer.Amount) or 1) + amount
            offer.HideSeasonalTags = offer.HideSeasonalTags or hideSeasonalTags == true
            offer.StackKey = stackKey
            return true
        end
    end

    if #theirOffer >= 4 then
        return false
    end

    table.insert(theirOffer, {
        ItemID = itemId,
        Amount = amount,
        ItemType = itemType,
        StackKey = stackKey,
        HideSeasonalTags = hideSeasonalTags == true,
    })

    return true
end

local function addRandomGodlyToTheirOffer()
    if not tradeModule.GUI.TradeGUI.Enabled then
        warn("[IncomingTradePopup] Open the placeholder trade before adding their random godly.")
        return
    end

    local item = getRandomGodlyWeapon()
    if not item then
        warn("[IncomingTradePopup] No godly knife/gun found in the item database.")
        return
    end

    if not addItemToTheirOfferStack(item.ItemID, item.ItemType, item.Amount or 1) then
        warn("[IncomingTradePopup] Their offer is full.")
        return
    end

    drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
    resetAcceptUi()
    tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
    CartiHubApplyPendingFakeTradeUsername()
    startAcceptCooldown(6)

end

local function getStoredWeaponValue(itemId, data)
    local displayName = data and (data.ItemName or data.Name) or itemId
    local values = isChromaWeapon(itemId, data)
        and _G.CartiHubChromaItemValues
        or _G.CartiHubNormalItemValues

    if type(values) ~= "table" then
        return 0
    end

    return tonumber(
        values[itemId]
        or values[displayName]
        or values[normalizeItemText(itemId)]
        or values[normalizeItemText(displayName)]
    ) or 0
end

local function addRandomWeaponAboveValue(minimumValue)
    if not tradeModule.GUI.TradeGUI.Enabled then
        warn("[Carti Hub] Open a fake trade before adding an offer item.")
        return false
    end

    local candidates = {}
    for _, itemType in ipairs({ "Weapons", "Item" }) do
        for itemId, data in pairs(sync[itemType] or {}) do
            if type(data) == "table"
                and (data.Rarity == "Godly" or data.Rarity == "Ancient")
                and canFakeTradeItem(itemId, itemType)
                and getStoredWeaponValue(itemId, data) > minimumValue then
                table.insert(candidates, {
                    ItemID = itemId,
                    ItemType = itemType,
                })
            end
        end
    end

    if #candidates == 0 then
        warn("[Carti Hub] No tradeable weapons above value " .. tostring(minimumValue) .. " were found.")
        return false
    end

    local item = candidates[math.random(1, #candidates)]
    addSpecificItemToTheirOffer(item.ItemID, item.ItemType, true)
    return true
end

addSpecificItemToTheirOffer = function(itemId, itemType, hideSeasonalTags)
    if not tradeModule.GUI.TradeGUI.Enabled then
        warn("[IncomingTradePopup] Open the placeholder trade before adding an offer-spawner item.")
        return
    end

    local itemData = sync[itemType] and sync[itemType][itemId]
    if not itemData then
        warn(("[IncomingTradePopup] Offer-spawner item not found: %s/%s"):format(tostring(itemType), tostring(itemId)))
        return
    end

    if not canFakeTradeItem(itemId, itemType) then
        warn(("[IncomingTradePopup] %s/%s is not tradeable."):format(tostring(itemType), tostring(itemId)))
        return
    end

    if not addItemToTheirOfferStack(itemId, itemType, 1, hideSeasonalTags) then
        warn("[IncomingTradePopup] Their offer is full.")
        return
    end

    drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
    resetAcceptUi()
    tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
    CartiHubApplyPendingFakeTradeUsername()
    startAcceptCooldown(6)

end

removeLastTheirOffer = function()
    if not tradeModule.GUI.TradeGUI.Enabled then
        warn("[IncomingTradePopup] Open the placeholder trade before removing their item.")
        return
    end

    if #theirOffer < 1 then
        warn("[IncomingTradePopup] Their offer is already empty.")
        return
    end

    local removed = table.remove(theirOffer)
    drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
    resetAcceptUi()
    tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
    CartiHubApplyPendingFakeTradeUsername()
    startAcceptCooldown(6)

end

local function addOverlayClickTarget(parent, itemId, itemType)
    if not parent or not parent:IsA("GuiObject") then
        return
    end

    local oldOverlay = parent:FindFirstChild("ClientPlaceholderTradeToggle")
    if oldOverlay then
        oldOverlay:Destroy()
    end

    local overlay = Instance.new("TextButton")
    overlay.Name = "ClientPlaceholderTradeToggle"
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.ZIndex = parent.ZIndex + 100
    overlay.Parent = parent

    overlay.MouseButton1Click:Connect(function()
        toggleLocalOffer(itemId, itemType)
    end)
end

local function addActionOverlay(parent, callback)
    if not parent or not parent:IsA("GuiObject") then
        return
    end

    local oldOverlay = parent:FindFirstChild("ClientPlaceholderTradeActionOverlay")
    if oldOverlay then
        oldOverlay:Destroy()
    end

    local overlay = Instance.new("TextButton")
    overlay.Name = "ClientPlaceholderTradeActionOverlay"
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.ZIndex = parent.ZIndex + 100
    overlay.Parent = parent
    overlay.MouseButton1Click:Connect(callback)
end

local function installTradeActionButtons()
    local actions = tradeModule.GUI.Actions
    if not actions then
        return
    end

    local accept = actions:FindFirstChild("Accept")
    local decline = actions:FindFirstChild("Decline")

    if accept then
        addActionOverlay(accept, CartiHubHandleFakeAcceptClick)
        addActionOverlay(accept:FindFirstChild("ActionButton"), CartiHubHandleFakeAcceptClick)

        local confirmButton = accept:FindFirstChild("Confirm")
            and accept.Confirm:FindFirstChild("ActionButton")
        addActionOverlay(confirmButton, function()
            if localAcceptMode == "Confirm" and time() - localConfirmStartedAt >= 0.4 then
                setLocalAcceptState("Waiting")
                scheduleOtherSideAccept()
            end
        end)

        local cancelButton = accept:FindFirstChild("Cancel")
            and accept.Cancel:FindFirstChild("ActionButton")
        addActionOverlay(cancelButton, resetAcceptUi)
    end

    if decline then
        addActionOverlay(decline:FindFirstChild("ActionButton"), function()
            tradeModule.GUI.TradeGUI.Enabled = false
            CartiHubEndFakeTradeSession()
            tradeModule.TradeInventory = nil
            restoreLocalOfferToInventory()
            table.clear(theirOffer)
            resetAcceptUi()
        end)
    end
end

local function installInventoryToggleButtons()
    local tradeInventory = tradeModule.TradeInventory
    if not tradeInventory or not tradeInventory.Data then
        return
    end

    for itemType, categories in pairs(tradeInventory.Data) do
        for _, items in pairs(categories) do
            for itemId, entry in pairs(items) do
                local frame = entry.Frame
                local actionButton = frame
                    and frame:FindFirstChild("Container")
                    and frame.Container:FindFirstChild("ActionButton")

                if actionButton and actionButton:IsA("GuiObject") then
                    addOverlayClickTarget(actionButton, itemId, itemType)
                elseif frame and frame:IsA("GuiObject") then
                    addOverlayClickTarget(frame, itemId, itemType)
                end
            end
        end
    end
end

function CartiHubInstallFakeTradeSearchFilter()
    if _G.CartiHubFakeTradeSearchConnection then
        _G.CartiHubFakeTradeSearchConnection:Disconnect()
        _G.CartiHubFakeTradeSearchConnection = nil
    end

    local gui = tradeModule.GUI
    local searchText = gui
        and gui.TradeGUI
        and gui.TradeGUI:FindFirstChild("Container")
        and gui.TradeGUI.Container:FindFirstChild("Items")
        and gui.TradeGUI.Container.Items:FindFirstChild("Tabs")
        and gui.TradeGUI.Container.Items.Tabs:FindFirstChild("Search")
        and gui.TradeGUI.Container.Items.Tabs.Search:FindFirstChild("Container")
        and gui.TradeGUI.Container.Items.Tabs.Search.Container:FindFirstChild("SearchText")

    if not searchText or not searchText:IsA("TextBox") then
        return
    end

    local function applyFilter()
        local inventory = tradeModule.TradeInventory
        if not inventory or not inventory.Data then
            return
        end

        local query = tostring(searchText.Text or ""):lower()

        for _, itemTypeData in pairs(inventory.Data) do
            for _, entry in pairs(itemTypeData.Current or {}) do
                if entry.Frame then
                    local itemName = tostring(entry.Name or ""):lower()
                    entry.Frame.Visible = query == "" or itemName:find(query, 1, true) ~= nil
                end
            end
        end
    end

    _G.CartiHubFakeTradeSearchConnection = searchText:GetPropertyChangedSignal("Text"):Connect(applyFilter)
    applyFilter()
end

local function openTradeFrameFromAccept()
    local tradeGui = tradeModule.GUI.TradeGUI
    local tradeContainer = tradeGui.Container
    local shouldAutoSearch = _G.CartiHubAutoTradeSearchPending == true
    local shouldAutoUpgradeOffer = _G.CartiHubAutoUpgradeOfferPending == true

    _G.CartiHubAutoTradeSearchPending = nil
    _G.CartiHubAutoUpgradeOfferPending = nil

    _G.CartiHubFakeTradeActive = true
    CartiHubStartFakeTradeFrameGuard()
    restoreLocalOfferToInventory()
    table.clear(theirOffer)
    resetAcceptUi()

    for _, categoryName in ipairs({ "Weapons", "Pets" }) do
        local category = tradeContainer.Items.Main:FindFirstChild(categoryName)
        if category and category:FindFirstChild("Items") and category.Items:FindFirstChild("Container") then
            for _, section in ipairs(category.Items.Container:GetChildren()) do
                local container = section:FindFirstChild("Container")
                if container then
                    container:ClearAllChildren()
                end
            end
        end
    end

    tradeModule.TradeInventory = inventoryModule.GenerateInventory(
        tradeContainer.Items,
        profileData,
        "Trading",
        tradeModule.GUI.ItemsLayout
    )

    tradeModule.ConnectOfferButtons(tradeModule.TradeInventory)
    CartiHubInstallFakeTradeSearchFilter()
    redrawLocalTrade()
    tradeModule.GUI.TheirOffer.Username.Text = "(" .. getFakeTradeSenderName() .. ")"
    CartiHubApplyPendingFakeTradeUsername()
    _G.CartiHubPendingFakeTradeUsername = nil
    tradeGui.Enabled = true
    task.defer(installInventoryToggleButtons)
    task.delay(0.5, installInventoryToggleButtons)
    installTradeActionButtons()
    CartiHubWakeAcceptActionButton()
    CartiHubEnforceFakeTradeFrame()
    task.defer(CartiHubWakeAcceptActionButton)
    task.defer(CartiHubEnforceFakeTradeFrame)

    if shouldAutoSearch then
        CartiHubStartAutoTradeOfferFill()
    end

    if shouldAutoUpgradeOffer then
        task.spawn(function()
            task.wait(math.random(50, 200) / 100)

            local count = math.random(1, 3)
            for _ = 1, count do
                if not _G.CartiHubFakeTradeActive or not tradeGui.Enabled then
                    return
                end

                addRandomWeaponAboveValue(1000)
                task.wait(math.random(50, 200) / 100)
            end
        end)
    end
end

cleanupOldOverlays()

function CartiHubLaunchInstantFakePersonTrade(username, isReturnTrade, autoSearch, autoUpgradeOffer)
    if _G.CartiHubFakeTradeActive then
        return false
    end

    username = CartiHubNormalizeTradeUsername(username) or pickFakeTradeSenderName()
    currentFakeTradeSenderName = username
    _G.CartiHubAutoTradeSearchPending = autoSearch == true
    _G.CartiHubAutoUpgradeOfferPending = autoUpgradeOffer == true
    _G.CartiHubPendingFakeTradeUsername = username
    _G.CartiHubActiveFakeTradeUsername = username
    _G.CartiHubInstantFakeTradeReturnPending = isReturnTrade ~= true

    task.defer(openTradeFrameFromAccept)
    return true
end

function CartiHubLaunchFakeUpgradeFakePlayer()
    return CartiHubLaunchInstantFakePersonTrade(nil, false, false, true)
end

function CartiHubLaunchUpgradeFakeTrade(username)
    if not username or username == "" then
        return false
    end

    return CartiHubLaunchInstantFakePersonTrade(username, true)
end

StartTradeBtn.MouseButton1Click:Connect(function()
    CartiHubLaunchInstantFakePersonTrade(nil, true)
end)
AddRandomBtn.MouseButton1Click:Connect(addRandomGodlyToTheirOffer)
RemoveLastBtn.MouseButton1Click:Connect(removeLastTheirOffer)

local function SwitchTab(activeBtn, activeFrame)
    SpawnerFrame.Visible = false
    TradeFrame.Visible = false
    UpgradingFrame.Visible = false
    BlockFrame.Visible = false
    SettingsFrame.Visible = false
    KeybindsFrame.Visible = false

    for _, tab in ipairs({ SpawnerTabBtn, TradeTabBtn, UpgradingTabBtn, BlockTabBtn, SettingsTabBtn, KeybindsTabBtn }) do
        tab.BackgroundColor3 = Color3.fromRGB(19, 7, 33)
        tab.BackgroundTransparency = 1
        tab.TextColor3 = Color3.fromRGB(182, 160, 203)

        local accent = tab:FindFirstChild("NebulaActiveAccent")
        if accent then
            accent.Visible = false
        end
    end

    activeFrame.Visible = true
    activeBtn.BackgroundColor3 = BUTTON_HOVER_COLOR
    activeBtn.BackgroundTransparency = 0.35
    activeBtn.TextColor3 = Color3.fromRGB(255, 244, 255)

    local activeAccent = activeBtn:FindFirstChild("NebulaActiveAccent")
    if activeAccent then
        activeAccent.Visible = true
    end
end

SpawnerTabBtn.MouseButton1Click:Connect(function()
    SwitchTab(SpawnerTabBtn, SpawnerFrame)
end)

TradeTabBtn.MouseButton1Click:Connect(function()
    SwitchTab(TradeTabBtn, TradeFrame)
end)

UpgradingTabBtn.MouseButton1Click:Connect(function()
    CartiHubRefreshUpgradePlayerDropdown()
    SwitchTab(UpgradingTabBtn, UpgradingFrame)
end)

BlockTabBtn.MouseButton1Click:Connect(function()
    SwitchTab(BlockTabBtn, BlockFrame)
end)

SettingsTabBtn.MouseButton1Click:Connect(function()
    SwitchTab(SettingsTabBtn, SettingsFrame)
end)

KeybindsTabBtn.MouseButton1Click:Connect(function()
    SwitchTab(KeybindsTabBtn, KeybindsFrame)
end)

if _G.ClientPlaceholderTradeKeybindConnection then
    _G.ClientPlaceholderTradeKeybindConnection:Disconnect()
end

_G.ClientPlaceholderTradeKeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.Six then
        if SakaUI and SakaUI.Parent then
            SakaUI.Enabled = not SakaUI.Enabled

            local nebulaGui = _G.CartiHubNebulaGui
            if nebulaGui and nebulaGui.Parent then
                nebulaGui.Enabled = SakaUI.Enabled
            end
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        showRandomFakeFriendJoinNotification()
        return
    end

    if input.KeyCode == Enum.KeyCode.Two then
        addRandomWeaponAboveValue(200)
        return
    end

    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Z then
        CartiHubLaunchInstantFakePersonTrade(nil, true)
    elseif input.KeyCode == Enum.KeyCode.Y then
        addRandomGodlyToTheirOffer()
    elseif input.KeyCode == Enum.KeyCode.B then
        removeLastTheirOffer()
    end
end)

_G.CartiHubSpawnWeapon = spawnWeapon
_G.CartiHubSpawnWeaponById = spawnWeaponById
_G.CartiHubSpawnWeaponByIdNoPopup = spawnWeaponByIdNoPopup
_G.CartiHubSpawnAllGodlies = spawnAllGodlyWeapons
_G.CartiHubSpawnAllChromas = spawnAllChromaWeapons
_G.CartiHubSpawnAllAncients = spawnAllAncientWeapons
_G.CartiHubStartFakeTrade = function(autoSearch)
    return CartiHubLaunchInstantFakePersonTrade(nil, true, autoSearch == true)
end
_G.CartiHubLaunchUpgradeFakeTrade = CartiHubLaunchUpgradeFakeTrade
_G.CartiHubLaunchInstantFakePersonTrade = CartiHubLaunchInstantFakePersonTrade
_G.CartiHubSetAutoSelectLastTraded = CartiHubSetAutoSelectLastTraded
_G.CartiHubAddRandomTheirGodly = addRandomGodlyToTheirOffer
_G.CartiHubAddRandomWeaponAboveValue = addRandomWeaponAboveValue
_G.CartiHubRemoveLastTheirOffer = removeLastTheirOffer
_G.CartiHubPopulateWeaponSpawner = populateWeaponSpawner
_G.CartiHubPopulateOfferSpawner = populateOfferSpawner
_G.CartiHubPopulateRealisticSpawner = populateRealisticSpawner
_G.CartiHubAddWeaponBox = AddWeaponBox
_G.CartiHubWeaponVisuals = WeaponVisuals
_G.CartiHubApplyWeaponVisual = applyWeaponVisual
_G.CartiHubApplyEquippedWeaponVisuals = applyEquippedWeaponVisuals
_G.CartiHubShowFriendJoin = showFakeFriendJoinNotification
_G.CartiHubShowRandomFriendJoin = showRandomFakeFriendJoinNotification
_G.CartiHubSetAutoFriendJoin = setAutoFriendJoinEnabled
_G.CartiHubApplyAvatarFromUserId = applyAvatarFromUserId
_G.CartiHubApplyAvatar = applyAvatarFromUserId
_G.CartiHubResetAvatar = function()
    return applyAvatarFromUserId(localPlayer.UserId)
end

-- Add values here. Keys may be an item id, display name, or normalized name.
-- Keep chroma variants in the chroma table so they never use a normal value.
task.spawn(function()
    local NORMAL_ITEM_VALUES = {
        ["Gingerscope"] = 17750,
        ["Traveler's Axe"] = 8100,
        ["TravelersAxe"] = 8100,
        ["Celestial"] = 2175,
        ["VampireAxe"] = 1225,
        ["Harvester"] = 250,
        ["Icepiercer"] = 160,
        ["Traveler's Gun"] = 5600,
        ["TravelersGun"] = 5600,
        ["Evergun"] = 3450,
        ["Constellation"] = 2700,
        ["Evergreen"] = 2500,
        ["Turkey"] = 2450,
        ["Vampire's Gun"] = 1950,
        ["VampiresGun"] = 1950,
        ["Alienbeam"] = 1850,
        ["Darkshot"] = 1650,
        ["Darksword"] = 1625,
        ["Raygun"] = 1450,
        ["Blossom"] = 1310,
        ["Sakura"] = 1300,
        ["Sunrise"] = 1125,
        ["Snowcannon"] = 850,
        ["Bauble"] = 825,
        ["Sunset"] = 625,
        ["Soul"] = 615,
        ["Spirit"] = 605,
        ["Rainbow_G"] = 420,
        ["Flora"] = 410,
        ["Rainbow_K"] = 410,
        ["Bloom"] = 400,
        ["Heart Wand"] = 340,
        ["HeartWand"] = 340,
        ["Ocean"] = 285,
        ["Waves"] = 280,
        ["Xenoknife"] = 280,
        ["Xenoshot"] = 280,
        ["Flowerwood Gun"] = 265,
        ["FlowerwoodGun"] = 265,
        ["Blizzard"] = 260,
        ["Flowerwood"] = 260,
        ["Snowstorm"] = 260,
        ["Snow Dagger"] = 255,
        ["SnowDagger"] = 255,
        ["Watergun"] = 250,
        ["Beachy"] = 160,
        ["Icecream"] = 160,
        ["Sands"] = 160,
        ["Treat"] = 155,
        ["Sweet"] = 150,
        ["Borealis"] = 145,
        ["Australis"] = 140,
        ["Bat"] = 120,
        ["Pearlshine"] = 90,
        ["Pearl"] = 85,
        ["Candy"] = 80,
        ["Heartblade"] = 65,
        ["Luger"] = 40,
        ["Red Luger"] = 37,
        ["RedLuger"] = 37,
        ["Phantom"] = 35,
        ["Spectre"] = 35,
        ["Candleflame"] = 33,
        ["Darkbringer"] = 33,
        ["Elderwood Blade"] = 33,
        ["ElderwoodBlade"] = 33,
        ["Elderwood Revolver"] = 33,
        ["ElderwoodRevolver"] = 33,
        ["Iceblaster"] = 33,
        ["Lightbringer"] = 33,
        ["Makeshift"] = 33,
        ["Sugar"] = 32,
        ["Ornament"] = 27,
        ["Green Luger"] = 23,
        ["GreenLuger"] = 23,
        ["Amerilaser"] = 22,
        ["Laser"] = 22,
        ["Hallowgun"] = 20,
        ["Nightblade"] = 20,
        ["Shark"] = 20,
        ["Icebeam"] = 18,
        ["Plasmabeam"] = 18,
        ["Swirly Gun"] = 18,
        ["SwirlyGun"] = 18,
        ["Battleaxe II"] = 17,
        ["BattleAxe II"] = 17,
        ["BattleaxeII"] = 17,
        ["Blaster"] = 17,
        ["Ginger Luger"] = 17,
        ["GingerLuger"] = 17,
        ["Pixel"] = 17,
        ["Gemstone"] = 15,
        ["Iceflake"] = 15,
        ["Old Glory"] = 15,
        ["OldGlory"] = 15,
        ["Plasmablade"] = 15,
        ["Slasher"] = 15,
        ["Vampire's Edge"] = 15,
        ["VampiresEdge"] = 15,
        ["Cookiecane"] = 13,
        ["Deathshard"] = 13,
        ["Eternalcane"] = 13,
        ["Gingerblade"] = 13,
        ["Jinglegun"] = 13,
        ["Lugercane"] = 13,
        ["Minty"] = 13,
        ["Nebula"] = 13,
        ["Virtual"] = 13,
        ["Battleaxe"] = 12,
        ["BattleAxe"] = 12,
        ["Gingermint"] = 12,
        ["Swirly Blade"] = 12,
        ["SwirlyBlade"] = 12,
        ["Chill"] = 10,
        ["Clockwork"] = 10,
        ["Fang"] = 10,
        ["Frostsaber"] = 10,
        ["Heat"] = 10,
        ["Spider"] = 10,
        ["Tides"] = 10,
        ["Bioblade"] = 8,
        ["Eternal III"] = 8,
        ["EternalIII"] = 8,
        ["Eternal IV"] = 8,
        ["EternalIV"] = 8,
        ["Hallow's Blade"] = 8,
        ["HallowsBlade"] = 8,
        ["Hallow's Edge"] = 8,
        ["HallowsEdge"] = 8,
        ["Handsaw"] = 8,
        ["Boneblade"] = 7,
        ["Eternal"] = 7,
        ["Eternal II"] = 7,
        ["EternalII"] = 7,
        ["Frostbite"] = 7,
        ["Ghostblade"] = 7,
        ["Ice Dragon"] = 7,
        ["IceDragon"] = 7,
        ["Ice Shard"] = 7,
        ["IceShard"] = 7,
        ["Prismatic"] = 7,
        ["Pumpking"] = 7,
        ["Saw"] = 7,
        ["Xmas"] = 7,
        ["Eggblade"] = 5,
        ["Flames"] = 5,
        ["Snowflake"] = 5,
        ["Winter's Edge"] = 5,
        ["WintersEdge"] = 5,
        ["Peppermint"] = 4,
        ["Cookieblade"] = 3,
        ["Blue Seer"] = 3,
        ["BlueSeer"] = 3,
        ["Purple Seer"] = 3,
        ["PurpleSeer"] = 3,
        ["Red Seer"] = 3,
        ["RedSeer"] = 3,
        ["Seer"] = 3,
        ["Orange Seer"] = 2,
        ["OrangeSeer"] = 2,
        ["Yellow Seer"] = 2,
        ["YellowSeer"] = 2,
    }

    local CHROMA_ITEM_VALUES = {
        -- Exact MM2 database ids for chromas whose display names omit "Chroma".
        ["TravelerGunChroma"] = 220000,
        ["TreeGun2023Chroma"] = 75000,
        ["TreeKnife2023Chroma"] = 50000,
        ["BaubleChroma"] = 34000,
        ["VampireGunChroma"] = 29000,
        ["ConstellationChroma"] = 27000,
        ["UFOKnifeChroma"] = 24000,
        ["SunsetGunChroma"] = 13250,
        ["RaygunChroma"] = 12000,
        ["SnowcannonChroma"] = 8500,
        ["SunsetKnifeChroma"] = 8250,
        ["BlizzardChroma"] = 8000,
        ["SnowDaggerChroma"] = 4250,
        ["SnowstormChroma"] = 4250,
        ["HeartWandChroma"] = 4250,
        ["WatergunChroma"] = 3400,
        ["TreatChroma"] = 2800,
        ["SweetChroma"] = 2300,
        ["IcecreamChroma"] = 2000,
        ["SandsChroma"] = 1800,
        ["BeachyChroma"] = 1750,
        ["BaubleKnifeChroma"] = 1800,
        ["DarkbringerChroma"] = 65,
        ["LightbringerChroma"] = 60,
        ["LugerChroma"] = 50,
        ["CandleflameChroma"] = 40,
        ["LaserChroma"] = 40,
        ["SwirlyGunChroma"] = 38,
        ["ElderwoodKnifeChroma"] = 37,
        ["DeathshardChroma"] = 35,
        ["Gingermint_KChroma"] = 32,
        ["FangChroma"] = 32,
        ["GemstoneChroma"] = 32,
        ["SharkChroma"] = 32,
        ["SlasherChroma"] = 32,
        ["HeatChroma"] = 28,
        ["SeerChroma"] = 28,
        ["GingerbladeChroma"] = 27,
        ["TidesChroma"] = 27,
        ["SawChroma"] = 23,
        ["BonebladeChroma"] = 22,
        ["Chroma Traveler's Gun"] = 220000,
        ["C. Traveler's Gun"] = 220000,
        ["ChromaTravelerGun"] = 220000,
        ["Chroma Evergun"] = 75000,
        ["ChromaEvergun"] = 75000,
        ["Chroma Evergreen"] = 50000,
        ["ChromaEvergreen"] = 50000,
        ["Chroma Bauble"] = 34000,
        ["ChromaBauble"] = 34000,
        ["Chroma Vampire's Gun"] = 29000,
        ["C. Vampire's Gun"] = 29000,
        ["ChromaVampiresGun"] = 29000,
        ["Chroma Constellation"] = 27000,
        ["C. Constellation"] = 27000,
        ["ChromaConstellation"] = 27000,
        ["Chroma Alienbeam"] = 24000,
        ["ChromaAlienbeam"] = 24000,
        ["Chroma Sunrise"] = 13250,
        ["ChromaSunrise"] = 13250,
        ["Chroma Raygun"] = 12000,
        ["ChromaRaygun"] = 12000,
        ["Chroma Snowcannon"] = 8500,
        ["ChromaSnowcannon"] = 8500,
        ["Chroma Sunset"] = 8250,
        ["ChromaSunset"] = 8250,
        ["Chroma Blizzard"] = 8000,
        ["ChromaBlizzard"] = 8000,
        ["Chroma Snow Dagger"] = 4250,
        ["ChromaSnowDagger"] = 4250,
        ["Chroma Snowstorm"] = 4250,
        ["ChromaSnowstorm"] = 4250,
        ["Chroma Heart Wand"] = 4250,
        ["ChromaHeartWand"] = 4250,
        ["Chroma Watergun"] = 3400,
        ["ChromaWatergun"] = 3400,
        ["Chroma Treat"] = 2800,
        ["ChromaTreat"] = 2800,
        ["Chroma Sweet"] = 2300,
        ["ChromaSweet"] = 2300,
        ["Chroma Icecream"] = 2000,
        ["ChromaIcecream"] = 2000,
        ["Chroma Sands"] = 1800,
        ["ChromaSands"] = 1800,
        ["Chroma Ornament"] = 1800,
        ["ChromaOrnament"] = 1800,
        ["Chroma Beachy"] = 1750,
        ["ChromaBeachy"] = 1750,
        ["Chroma Darkbringer"] = 65,
        ["ChromaDarkbringer"] = 65,
        ["Chroma Lightbringer"] = 60,
        ["ChromaLightbringer"] = 60,
        ["Chroma Luger"] = 50,
        ["ChromaLuger"] = 50,
        ["Chroma Candleflame"] = 40,
        ["ChromaCandleflame"] = 40,
        ["Chroma Laser"] = 40,
        ["ChromaLaser"] = 40,
        ["Chroma Swirly Gun"] = 38,
        ["ChromaSwirlyGun"] = 38,
        ["Chroma Elderwood Blade"] = 37,
        ["C. Elderwood Blade"] = 37,
        ["ChromaElderwoodBlade"] = 37,
        ["Chroma Deathshard"] = 35,
        ["ChromaDeathshard"] = 35,
        ["Chroma Cookiecane"] = 32,
        ["ChromaCookiecane"] = 32,
        ["Chroma Fang"] = 32,
        ["ChromaFang"] = 32,
        ["Chroma Gemstone"] = 32,
        ["ChromaGemstone"] = 32,
        ["Chroma Shark"] = 32,
        ["ChromaShark"] = 32,
        ["Chroma Slasher"] = 32,
        ["ChromaSlasher"] = 32,
        ["Chroma Heat"] = 28,
        ["ChromaHeat"] = 28,
        ["Chroma Seer"] = 28,
        ["ChromaSeer"] = 28,
        ["Chroma Gingerblade"] = 27,
        ["ChromaGingerblade"] = 27,
        ["Chroma Tides"] = 27,
        ["ChromaTides"] = 27,
        ["Chroma Saw"] = 23,
        ["ChromaSaw"] = 23,
        ["Chroma Boneblade"] = 22,
        ["ChromaBoneblade"] = 22,
    }

    local parent = safeParent()
    local oldGui = parent:FindFirstChild("CartiHubPlayerValuesGUI")
    if oldGui then
        oldGui:Destroy()
    end

    local function normalizeValueKey(value)
        return tostring(value or ""):lower():gsub("[^%w]", "")
    end

    local itemIdsByDisplayName = {}
    for _, itemType in ipairs({ "Weapons", "Item" }) do
        for itemId, data in pairs(sync[itemType] or {}) do
            if type(data) == "table" then
                local displayName = normalizeValueKey(data.ItemName or data.Name or itemId)
                itemIdsByDisplayName[displayName] = itemIdsByDisplayName[displayName] or {}
                itemIdsByDisplayName[displayName][tostring(itemId)] = true
            end
        end
    end

    local function isUniqueDisplayName(itemId, displayName)
        local ids = itemIdsByDisplayName[normalizeValueKey(displayName)]
        if not ids then
            return true
        end

        local count = 0
        for knownItemId in pairs(ids) do
            count += 1
            if knownItemId ~= tostring(itemId) then
                return false
            end
        end

        return count <= 1
    end

    local function readValue(valueTable, itemId, displayName)
        local direct = valueTable[itemId] or valueTable[normalizeValueKey(itemId)]
        if direct ~= nil then
            return tonumber(direct) or 0
        end

        if not isUniqueDisplayName(itemId, displayName) then
            return 0
        end

        return tonumber(valueTable[displayName] or valueTable[normalizeValueKey(displayName)]) or 0
    end

    local function isChromaValueItem(itemId, data)
        local chromaTexture = data and data.ChromaTexture
        local chromaStaticLayer = data and data.ChromaStaticLayer
        local hasChromaTexture = chromaTexture ~= nil
            and chromaTexture ~= false
            and tostring(chromaTexture) ~= ""
        local hasChromaStaticLayer = chromaStaticLayer ~= nil
            and chromaStaticLayer ~= false
            and tostring(chromaStaticLayer) ~= ""

        if type(data) == "table" and (
            data.Chroma == true
            or data.IsChroma == true
            or hasChromaTexture
            or hasChromaStaticLayer
        ) then
            return true
        end

        local itemText = normalizeValueKey(itemId)
        local nameText = normalizeValueKey(data and (data.ItemName or data.Name))
        return itemText:find("chroma", 1, true) ~= nil or nameText:find("chroma", 1, true) ~= nil
    end

    local function findValueItem(itemId, preferredType)
        local searchTypes = preferredType and { preferredType } or { "Weapons", "Item" }

        for _, itemType in ipairs(searchTypes) do
            local data = sync[itemType] and sync[itemType][itemId]
            if type(data) == "table" then
                local displayName = data.ItemName or data.Name or itemId
                local chroma = isChromaValueItem(itemId, data)
                local value = readValue(chroma and CHROMA_ITEM_VALUES or NORMAL_ITEM_VALUES, itemId, displayName)

                return {
                    ItemID = itemId,
                    ItemType = itemType,
                    Name = displayName,
                    Value = value,
                    Chroma = chroma,
                }
            end
        end

        return nil
    end

    local function sortAndLimit(items)
        table.sort(items, function(a, b)
            if a.Value == b.Value then
                return tostring(a.Name):lower() < tostring(b.Name):lower()
            end

            return a.Value > b.Value
        end)

        while #items > 3 do
            table.remove(items)
        end

        return items
    end

    local function getLocalPlayerValues()
        local found = {}
        local seen = {}

        local function collect(owned, itemType)
            for itemId, amount in pairs(owned or {}) do
                if (tonumber(amount) or 0) > 0 then
                    local entry = findValueItem(itemId, itemType)
                    local key = entry and (entry.ItemType .. ":" .. entry.ItemID)
                    if entry and not seen[key] then
                        seen[key] = true
                        entry.Amount = amount
                        table.insert(found, entry)
                    end
                end
            end
        end

        collect(profileData.Weapons and profileData.Weapons.Owned, "Weapons")
        collect(profileData.Item and profileData.Item.Owned, "Item")
        return sortAndLimit(found)
    end

    local function getVisiblePlayerValues(player)
        if player == localPlayer then
            return getLocalPlayerValues()
        end

        local found = {}
        local seen = {}
        local attributes = {
            "EquippedKnife",
            "EquippedGun",
            "Knife",
            "Gun",
        }

        for _, attributeName in ipairs(attributes) do
            local itemId = player:GetAttribute(attributeName)
            if type(itemId) == "string" and itemId ~= "" then
                local entry = findValueItem(itemId)
                local key = entry and (entry.ItemType .. ":" .. entry.ItemID)
                if entry and not seen[key] then
                    seen[key] = true
                    table.insert(found, entry)
                end
            end
        end

        return sortAndLimit(found)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CartiHubPlayerValuesGUI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100001
    gui.Enabled = false
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 450)
    frame.Position = UDim2.new(0.5, -150, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(83, 220, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -130, 0, 40)
    title.Position = UDim2.new(0, 14, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "Players Values"
    title.TextColor3 = Color3.fromRGB(210, 245, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 72, 0, 28)
    refreshButton.Position = UDim2.new(1, -112, 0, 10)
    refreshButton.BackgroundColor3 = BUTTON_COLOR
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "REFRESH"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 11
    refreshButton.Parent = frame
    Instance.new("UICorner", refreshButton).CornerRadius = UDim.new(0, 7)

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 28, 0, 28)
    closeButton.Position = UDim2.new(1, -36, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 128, 207)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -56)
    scroll.Position = UDim2.new(0, 8, 0, 48)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(83, 220, 255)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 7)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    local function formatValue(value)
        local text = tostring(math.floor(tonumber(value) or 0))
        local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return formatted
    end

    local function refreshValues()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        local playerRows = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local entries = getVisiblePlayerValues(player)
            table.insert(playerRows, {
                Player = player,
                Entries = entries,
                HighestValue = entries[1] and entries[1].Value or 0,
            })
        end

        table.sort(playerRows, function(a, b)
            if a.HighestValue == b.HighestValue then
                return a.Player.Name:lower() < b.Player.Name:lower()
            end
            return a.HighestValue > b.HighestValue
        end)

        for index, row in ipairs(playerRows) do
            local player = row.Player
            local entries = row.Entries
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 88)
            card.BackgroundColor3 = Color3.fromRGB(16, 27, 55)
            card.BorderSizePixel = 0
            card.LayoutOrder = index
            card.Parent = scroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -20, 0, 22)
            name.Position = UDim2.new(0, 10, 0, 5)
            name.BackgroundTransparency = 1
            name.Text = player.Name
            name.TextColor3 = Color3.fromRGB(220, 240, 255)
            name.Font = Enum.Font.GothamBold
            name.TextSize = 14
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.Parent = card

            for line = 1, 3 do
                local entry = entries[line]
                local itemLabel = Instance.new("TextLabel")
                itemLabel.Size = UDim2.new(1, -20, 0, 17)
                itemLabel.Position = UDim2.new(0, 10, 0, 26 + ((line - 1) * 18))
                itemLabel.BackgroundTransparency = 1
                itemLabel.Font = Enum.Font.Gotham
                itemLabel.TextSize = 12
                itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                itemLabel.TextTruncate = Enum.TextTruncate.AtEnd

                if entry then
                    local prefix = entry.Chroma and "[CHROMA] " or ""
                    local amount = entry.Amount and (" x" .. tostring(entry.Amount)) or ""
                    itemLabel.Text = prefix .. tostring(entry.Name) .. amount .. "  -  " .. formatValue(entry.Value)
                    itemLabel.TextColor3 = entry.Chroma
                        and Color3.fromRGB(255, 175, 255)
                        or Color3.fromRGB(240, 230, 255)
                elseif line == 1 then
                    itemLabel.Text = "No valued items found"
                    itemLabel.TextColor3 = Color3.fromRGB(190, 160, 220)
                else
                    itemLabel.Text = ""
                end

                itemLabel.Parent = card
            end
        end
    end

    closeButton.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)
    refreshButton.MouseButton1Click:Connect(refreshValues)

    local refreshQueued = false
    local function queuePlayerValuesRefresh(delaySeconds)
        if refreshQueued or not gui.Enabled then
            return
        end

        refreshQueued = true
        task.delay(delaySeconds or 0, function()
            refreshQueued = false
            if gui.Parent and gui.Enabled then
                refreshValues()
            end
        end)
    end

    Players.PlayerAdded:Connect(function()
        queuePlayerValuesRefresh(0.5)
    end)

    Players.PlayerRemoving:Connect(function()
        queuePlayerValuesRefresh()
    end)

    _G.CartiHubNormalItemValues = NORMAL_ITEM_VALUES
    _G.CartiHubChromaItemValues = CHROMA_ITEM_VALUES
    _G.CartiHubGetVisiblePlayerTopValue = function(player)
        local entries = getVisiblePlayerValues(player)
        return entries[1] and entries[1].Value or 0
    end
    _G.CartiHubOpenPlayerValuesGui = function()
        if not gui.Parent then
            return false
        end
        gui.Enabled = true
        refreshValues()
        return true
    end

    local oldBlockValueState = _G.CartiHubBlockValueState
    if oldBlockValueState then
        oldBlockValueState.Enabled = false
    end

    local blockValueState = {
        Enabled = false,
        Minimum = 0,
        Attempted = {},
    }
    _G.CartiHubBlockValueState = blockValueState

    local oldBlockValueGui = parent:FindFirstChild("CartiHubBlockValueGUI")
    if oldBlockValueGui then
        oldBlockValueGui:Destroy()
    end

    local blockValueGui = Instance.new("ScreenGui")
    blockValueGui.Name = "CartiHubBlockValueGUI"
    blockValueGui.ResetOnSpawn = false
    blockValueGui.DisplayOrder = 100002
    blockValueGui.Enabled = false
    blockValueGui.Parent = parent

    local blockValueFrame = Instance.new("Frame")
    blockValueFrame.Size = UDim2.new(0, 280, 0, 164)
    blockValueFrame.Position = UDim2.new(0.5, -140, 0.5, -82)
    blockValueFrame.BackgroundColor3 = Color3.fromRGB(9, 14, 31)
    blockValueFrame.BorderSizePixel = 0
    blockValueFrame.Active = true
    blockValueFrame.Draggable = true
    blockValueFrame.Parent = blockValueGui
    Instance.new("UICorner", blockValueFrame).CornerRadius = UDim.new(0, 12)

    local blockValueStroke = Instance.new("UIStroke")
    blockValueStroke.Color = Color3.fromRGB(83, 220, 255)
    blockValueStroke.Thickness = 2
    blockValueStroke.Transparency = 0.15
    blockValueStroke.Parent = blockValueFrame

    local blockValueTitle = Instance.new("TextLabel")
    blockValueTitle.Size = UDim2.new(1, -46, 0, 36)
    blockValueTitle.Position = UDim2.new(0, 12, 0, 4)
    blockValueTitle.BackgroundTransparency = 1
    blockValueTitle.Text = "Block Value"
    blockValueTitle.TextColor3 = Color3.fromRGB(210, 245, 255)
    blockValueTitle.Font = Enum.Font.GothamBold
    blockValueTitle.TextSize = 17
    blockValueTitle.TextXAlignment = Enum.TextXAlignment.Left
    blockValueTitle.Parent = blockValueFrame

    local blockValueClose = Instance.new("TextButton")
    blockValueClose.Size = UDim2.new(0, 28, 0, 28)
    blockValueClose.Position = UDim2.new(1, -36, 0, 8)
    blockValueClose.BackgroundTransparency = 1
    blockValueClose.Text = "X"
    blockValueClose.TextColor3 = Color3.fromRGB(255, 128, 207)
    blockValueClose.Font = Enum.Font.GothamBold
    blockValueClose.TextSize = 18
    blockValueClose.Parent = blockValueFrame

    local minimumBox = Instance.new("TextBox")
    minimumBox.Size = UDim2.new(1, -24, 0, 36)
    minimumBox.Position = UDim2.new(0, 12, 0, 45)
    minimumBox.BackgroundColor3 = Color3.fromRGB(15, 25, 52)
    minimumBox.BorderSizePixel = 0
    minimumBox.PlaceholderText = "Minimum value"
    minimumBox.PlaceholderColor3 = Color3.fromRGB(120, 151, 191)
    minimumBox.Text = ""
    minimumBox.TextColor3 = Color3.fromRGB(220, 240, 255)
    minimumBox.Font = Enum.Font.Gotham
    minimumBox.TextSize = 14
    minimumBox.ClearTextOnFocus = false
    minimumBox.Parent = blockValueFrame
    Instance.new("UICorner", minimumBox).CornerRadius = UDim.new(0, 7)

    local blockValueToggle = Instance.new("TextButton")
    blockValueToggle.Size = UDim2.new(1, -24, 0, 36)
    blockValueToggle.Position = UDim2.new(0, 12, 0, 91)
    blockValueToggle.BackgroundColor3 = BUTTON_COLOR
    blockValueToggle.BorderSizePixel = 0
    blockValueToggle.Text = "BLOCK VALUE: OFF"
    blockValueToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    blockValueToggle.Font = Enum.Font.GothamBold
    blockValueToggle.TextSize = 13
    blockValueToggle.Parent = blockValueFrame
    Instance.new("UICorner", blockValueToggle).CornerRadius = UDim.new(0, 7)

    local blockValueStatus = Instance.new("TextLabel")
    blockValueStatus.Size = UDim2.new(1, -24, 0, 18)
    blockValueStatus.Position = UDim2.new(0, 12, 0, 132)
    blockValueStatus.BackgroundTransparency = 1
    blockValueStatus.Text = ""
    blockValueStatus.TextColor3 = Color3.fromRGB(210, 175, 245)
    blockValueStatus.Font = Enum.Font.Gotham
    blockValueStatus.TextSize = 11
    blockValueStatus.TextTruncate = Enum.TextTruncate.AtEnd
    blockValueStatus.Parent = blockValueFrame

    local function setBlockValueEnabled(enabled)
        blockValueState.Enabled = enabled == true
        blockValueToggle.Text = blockValueState.Enabled and "BLOCK VALUE: ON" or "BLOCK VALUE: OFF"
        blockValueToggle.BackgroundColor3 = blockValueState.Enabled and BUTTON_HOVER_COLOR or BUTTON_COLOR
        blockValueStatus.Text = blockValueState.Enabled
            and ("Blocking below " .. formatValue(blockValueState.Minimum))
            or ""
    end

    local function setMinimumValue()
        local cleaned = tostring(minimumBox.Text or ""):gsub(",", "")
        blockValueState.Minimum = math.max(0, math.floor(tonumber(cleaned) or 0))
        minimumBox.Text = blockValueState.Minimum > 0 and formatValue(blockValueState.Minimum) or ""
        if blockValueState.Enabled then
            blockValueStatus.Text = "Blocking below " .. formatValue(blockValueState.Minimum)
        end
    end

    minimumBox.FocusLost:Connect(setMinimumValue)
    blockValueToggle.MouseButton1Click:Connect(function()
        setMinimumValue()
        setBlockValueEnabled(not blockValueState.Enabled)
    end)
    blockValueClose.MouseButton1Click:Connect(function()
        blockValueGui.Enabled = false
    end)

    _G.CartiHubOpenBlockValueGui = function()
        if not blockValueGui.Parent then
            return false
        end
        blockValueGui.Enabled = true
        return true
    end

    task.spawn(function()
        while blockValueGui.Parent and _G.CartiHubBlockValueState == blockValueState do
            if blockValueState.Enabled then
                local blockUser = _G.CartiHubBlockUsername
                if type(blockUser) ~= "function" then
                    blockValueStatus.Text = "Block function unavailable"
                else
                    for _, player in ipairs(Players:GetPlayers()) do
                        if not blockValueState.Enabled or player == localPlayer then
                            continue
                        end

                        local topValue = _G.CartiHubGetVisiblePlayerTopValue(player)
                        if topValue < blockValueState.Minimum and not blockValueState.Attempted[player.UserId] then
                            blockValueState.Attempted[player.UserId] = true
                            blockValueStatus.Text = "Blocking " .. player.Name
                            blockUser(player.Name, function(success, detail)
                                if _G.CartiHubBlockValueState ~= blockValueState then
                                    return
                                end
                                blockValueStatus.Text = success and ("Blocked " .. player.Name) or tostring(detail or "Block failed")
                            end)
                            task.wait(0.5)
                        end
                    end
                end
                task.wait(3)
            else
                task.wait(0.25)
            end
        end
    end)

end)

task.defer(function()
    pcall(refreshMainInventoryNow)
end)

-- Roblox's contact list is protected CoreGui, so these companion controls are
-- positioned directly before its name column instead of modifying its rows.
task.spawn(function()
    local parent = safeParent()
    local oldGui = parent:FindFirstChild("CartiHubPlayerListBlockButtons")
    if oldGui then
        oldGui:Destroy()
    end

    local oldState = _G.CartiHubPlayerListBlockButtonState
    if oldState and oldState.Connections then
        for _, connection in ipairs(oldState.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    local state = {
        Connections = {},
        Blocking = {},
        Blocked = {},
        Enabled = _G.CartiHubPlayerListBlockButtonsEnabled == true,
    }
    _G.CartiHubPlayerListBlockButtonState = state

    local gui = Instance.new("ScreenGui")
    gui.Name = "CartiHubPlayerListBlockButtons"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100000
    gui.Enabled = state.Enabled
    gui.Parent = parent

    local function getPlayerListOrder()
        local ordered = Players:GetPlayers()

        -- MM2's native player list orders its rows by prestige, then level.
        -- Those replicated attributes let the companion buttons follow new
        -- joins and removals without relying on a server-specific name list.
        table.sort(ordered, function(a, b)
            local aPrestige = tonumber(a:GetAttribute("Prestige")) or 0
            local bPrestige = tonumber(b:GetAttribute("Prestige")) or 0
            if aPrestige ~= bPrestige then
                return aPrestige > bPrestige
            end

            local aLevel = tonumber(a:GetAttribute("Level")) or 0
            local bLevel = tonumber(b:GetAttribute("Level")) or 0
            if aLevel ~= bLevel then
                return aLevel > bLevel
            end

            return a.Name:lower() < b.Name:lower()
        end)

        return ordered
    end

    local function refreshButtons()
        if not gui.Parent then
            return
        end

        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end

        if not state.Enabled then
            return
        end

        for index, player in ipairs(getPlayerListOrder()) do
            if player ~= localPlayer then
                local button = Instance.new("TextButton")
                button.Name = "Block_" .. tostring(player.UserId)
                button.AnchorPoint = Vector2.new(1, 0)
                button.Size = UDim2.fromOffset(70, 30)
                button.Position = UDim2.new(1, -284, 0, 22 + ((index - 1) * 42))
                button.BackgroundColor3 = state.Blocked[player.UserId]
                    and Color3.fromRGB(80, 80, 84)
                    or Color3.fromRGB(166, 48, 66)
                button.BackgroundTransparency = 0.08
                button.BorderSizePixel = 0
                button.Text = state.Blocked[player.UserId] and "DONE" or "BLOCK"
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                button.Font = Enum.Font.GothamBold
                button.TextSize = 8
                button.AutoButtonColor = not state.Blocked[player.UserId]
                button.Active = not state.Blocked[player.UserId]
                button.ZIndex = 100001
                button.Parent = gui
                Instance.new("UICorner", button).CornerRadius = UDim.new(0, 3)

                if not state.Blocked[player.UserId] then
                    button.MouseButton1Click:Connect(function()
                        if state.Blocking[player.UserId] then
                            return
                        end

                        local blockUser = _G.CartiHubBlockUsername
                        if type(blockUser) ~= "function" then
                            button.Text = "OFFLINE"
                            return
                        end

                        state.Blocking[player.UserId] = true
                        button.Text = "..."
                        button.Active = false

                        blockUser(player.Name, function(success, detail)
                            state.Blocking[player.UserId] = nil
                            if not button.Parent then
                                return
                            end

                            if success then
                                state.Blocked[player.UserId] = true
                                button.Text = "DONE"
                                button.BackgroundColor3 = Color3.fromRGB(80, 80, 84)
                            else
                                button.Text = tostring(detail or "FAILED")
                                task.delay(2, function()
                                    if button.Parent and not state.Blocked[player.UserId] then
                                        button.Text = "BLOCK"
                                        button.Active = true
                                    end
                                end)
                            end
                        end)
                    end)
                end
            end
        end
    end

    _G.CartiHubSetPlayerListBlockButtonsEnabled = function(enabled)
        state.Enabled = enabled == true
        _G.CartiHubPlayerListBlockButtonsEnabled = state.Enabled
        gui.Enabled = state.Enabled
        refreshButtons()
    end

    table.insert(state.Connections, Players.PlayerAdded:Connect(refreshButtons))
    table.insert(state.Connections, Players.PlayerRemoving:Connect(function()
        task.defer(refreshButtons)
    end))

    refreshButtons()
    while gui.Parent do
        refreshButtons()
        task.wait(0.75)
    end
end)

task.spawn(function()
    local assetId = "rbxassetid://86422603476263"
    local loadedOk, loadedObjects = pcall(function()
        return game:GetObjects(assetId)
    end)

    if not loadedOk or type(loadedObjects) ~= "table" or not loadedObjects[1] then
        warn("[Carti Hub] Nebula UI asset could not be loaded: " .. tostring(loadedObjects))
        return
    end

    local nebulaGui = loadedObjects[1]
    if not nebulaGui:IsA("ScreenGui") then
        nebulaGui = nebulaGui:FindFirstChildWhichIsA("ScreenGui", true)
    end

    if not nebulaGui then
        warn("[Carti Hub] Nebula UI asset did not contain a ScreenGui.")
        return
    end

    nebulaGui.Name = "CartiHubNebula"
    nebulaGui.ResetOnSpawn = false
    nebulaGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    nebulaGui.Parent = safeParent()
    _G.CartiHubNebulaGui = nebulaGui

    local uiFolder = nebulaGui:FindFirstChild("UI")
    local panel = uiFolder and uiFolder:FindFirstChild("Panel")
    local panelFrame = panel and panel:FindFirstChild("MainFrame")
    local panelContainer = panelFrame and panelFrame:FindFirstChild("Container")
    local ribbon = panelFrame and panelFrame:FindFirstChild("Ribbon")
    local topbar = panelFrame and panelFrame:FindFirstChild("Topbar")

    if not panelFrame or not panelContainer or not ribbon or not topbar then
        nebulaGui:Destroy()
        _G.CartiHubNebulaGui = nil
        warn("[Carti Hub] Nebula UI asset is missing the PC panel layout.")
        return
    end

    for _, surfaceName in ipairs({ "Menu", "Command Bar", "Popups" }) do
        local surface = uiFolder:FindFirstChild(surfaceName)
        if surface and surface:IsA("GuiObject") then
            surface.Visible = false
        end
    end

    local panelPopups = panel:FindFirstChild("Popups")
    if panelPopups and panelPopups:IsA("GuiObject") then
        panelPopups.Visible = false
    end

    panel.Visible = true
    panelFrame.Visible = true
    panel.Size = UDim2.new(0, 360, 0, 535)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)

    local sizeConstraint = panel:FindFirstChildOfClass("UISizeConstraint")
    if sizeConstraint then
        sizeConstraint.MinSize = Vector2.new(360, 535)
        sizeConstraint.MaxSize = Vector2.new(360, 535)
    end

    local aspectConstraint = panel:FindFirstChildOfClass("UIAspectRatioConstraint")
    if aspectConstraint then
        aspectConstraint:Destroy()
    end

    panelFrame.Active = true
    panelContainer.ClipsDescendants = true

    for _, child in ipairs(panelContainer:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    for _, ribbonSideName in ipairs({ "Left", "Right" }) do
        local ribbonSide = ribbon:FindFirstChild(ribbonSideName)
        if ribbonSide then
            for _, child in ipairs(ribbonSide:GetChildren()) do
                if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
        end
    end

    for _, topbarSideName in ipairs({ "Left", "Middle", "Right" }) do
        local topbarSide = topbar:FindFirstChild(topbarSideName)
        if topbarSide then
            for _, child in ipairs(topbarSide:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
        end
    end

    local dragHandle = Instance.new("TextButton")
    dragHandle.Name = "CartiHubDragHandle"
    dragHandle.Size = UDim2.fromScale(1, 1)
    dragHandle.BackgroundTransparency = 1
    dragHandle.BorderSizePixel = 0
    dragHandle.Text = ""
    dragHandle.AutoButtonColor = false
    dragHandle.Active = true
    dragHandle.ZIndex = 20
    dragHandle.Parent = topbar

    local dragging = false
    local dragStart
    local panelStart

    local function updatePanelDrag(input)
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            panelStart.X.Scale,
            panelStart.X.Offset + delta.X,
            panelStart.Y.Scale,
            panelStart.Y.Offset + delta.Y
        )
    end

    dragHandle.InputBegan:Connect(function(input)
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updatePanelDrag(input)
        end
    end)

    local topbarLeft = topbar:FindFirstChild("Left")
    if topbarLeft then
        local logo = Instance.new("ImageLabel")
        logo.Name = "CartiHubLogo"
        logo.Size = UDim2.new(0, 18, 0, 18)
        logo.Position = UDim2.new(0, 9, 0.5, -9)
        logo.BackgroundTransparency = 1
        logo.Image = "rbxassetid://85529926460930"
        logo.ScaleType = Enum.ScaleType.Fit
        logo.ZIndex = 22
        logo.Parent = topbarLeft
    end

    TabContainer.Parent = ribbon
    TabContainer.BackgroundTransparency = 1
    TabContainer.Size = UDim2.new(1, -18, 1, -8)
    TabContainer.Position = UDim2.new(0, 9, 0, 4)
    TabContainer.ZIndex = 20

    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.FillDirectionMaxCells = 6
    TabLayout.CellSize = UDim2.new(1 / 6, -4, 1, 0)
    TabLayout.CellPadding = UDim2.new(0, 4, 0, 0)

    for _, tab in ipairs({ SpawnerTabBtn, TradeTabBtn, UpgradingTabBtn, BlockTabBtn, SettingsTabBtn, KeybindsTabBtn }) do
        tab.Size = UDim2.new(0, 0, 0, 0)
        tab.BackgroundTransparency = 1
        tab.TextXAlignment = Enum.TextXAlignment.Center
        tab.TextColor3 = Color3.fromRGB(192, 181, 208)
        tab.TextSize = 8

        local padding = tab:FindFirstChildOfClass("UIPadding")
        if padding then
            padding:Destroy()
        end

        local accent = tab:FindFirstChild("NebulaActiveAccent")
        if accent then
            accent.Visible = false
        end
    end

    for _, page in ipairs({ SpawnerFrame, TradeFrame, UpgradingFrame, BlockFrame, SettingsFrame, KeybindsFrame }) do
        page.Parent = panelContainer
        page.Size = UDim2.new(1, -24, 1, -20)
        page.Position = UDim2.new(0, 12, 0, 10)
        page.ZIndex = 12
        page.ScrollBarThickness = 3
    end

    local middle = topbar:FindFirstChild("Middle")
    if middle then
        Title.Parent = middle
        Title.Size = UDim2.new(1, 0, 1, 0)
        Title.Position = UDim2.fromScale(0, 0)
        Title.Text = "t.me/cartiscripts"
        Title.TextSize = 11
        Title.TextXAlignment = Enum.TextXAlignment.Center
        Title.ZIndex = 22
    end

    local right = topbar:FindFirstChild("Right")
    if right then
        CloseBtn.Parent = right
        CloseBtn.Size = UDim2.new(0, 28, 1, 0)
        CloseBtn.Position = UDim2.new(1, -30, 0, 0)
        CloseBtn.TextSize = 14
        CloseBtn.ZIndex = 22
    end

    local bottom = panelFrame:FindFirstChild("Bottom")
    local bottomLeft = bottom and bottom:FindFirstChild("Left")
    if bottomLeft then
        for _, label in ipairs(bottomLeft:GetDescendants()) do
            if label:IsA("TextLabel") then
                label.Text = label.Text == "" and localPlayer.Name or label.Text
            end
        end
    end

    CloseBtn.MouseButton1Click:Connect(function()
        if nebulaGui.Parent then
            nebulaGui:Destroy()
        end
    end)

    MainFrame.Visible = false
end)
