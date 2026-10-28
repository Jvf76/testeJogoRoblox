local Config = {}

Config.Rarities = {
    {name = "Comum", weight = 50, color = Color3.fromRGB(152, 226, 143), hatch = 18, income = 1},
    {name = "Raro", weight = 28, color = Color3.fromRGB(92, 191, 255), hatch = 30, income = 3},
    {name = "Épico", weight = 15, color = Color3.fromRGB(184, 112, 255), hatch = 45, income = 7},
    {name = "Mítico", weight = 6, color = Color3.fromRGB(255, 123, 173), hatch = 65, income = 15},
    {name = "Lendário", weight = 1, color = Color3.fromRGB(255, 212, 77), hatch = 90, income = 35},
}

Config.Creatures = {
    Comum = {"Briselo", "Pedrinhoz", "Musgato", "Lumipim", "Bolhoro"},
    Raro = {"Faísculo", "Coralume", "Venturo", "Cristalva", "Sombrico"},
    ["Épico"] = {"Dracofolha", "Tempestral", "Abissauro", "Psiquélio"},
    ["Mítico"] = {"Aurorante", "Obsidraco", "Nebulince"},
    ["Lendário"] = {"Solárion", "Noxalume", "Maravox"},
}

Config.MaxEggs = 9
Config.MaxCreatures = 8
Config.SaveInterval = 60
Config.ShieldSeconds = 120
Config.StealCooldown = 30
Config.UpgradeCost = 100
Config.UpgradeIncomeMultiplier = 1.25

local total = 0
for _, rarity in ipairs(Config.Rarities) do
    assert(rarity.weight >= 0 and #Config.Creatures[rarity.name] > 0)
    total += rarity.weight
end
assert(total == 100, "Egg rarity weights must total 100")

function Config.GetRarity(name)
    for _, rarity in ipairs(Config.Rarities) do
        if rarity.name == name then return rarity end
    end
end

return Config
