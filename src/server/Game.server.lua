local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PathfindingService = game:GetService("PathfindingService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Map = require(script.Parent:WaitForChild("Map"))
local storeReady, Store = pcall(function()
    return DataStoreService:GetDataStore("MonsterEggHeist_v1")
end)
if not storeReady then
    warn("DataStore unavailable in this place; progress will remain in this test session")
    Store = nil
end
local rng = Random.new()
local world = Instance.new("Folder", workspace)
world.Name = "MonsterEggHeist"
local remotes = Instance.new("Folder", ReplicatedStorage)
remotes.Name = "HeistRemotes"
local dropRemote = Instance.new("RemoteEvent", remotes)
dropRemote.Name = "Drop"
local noticeRemote = Instance.new("RemoteEvent", remotes)
noticeRemote.Name = "Notice"
local states = {}
local bases = {}
local eggs = {}
local spawnPoints = {}

local function part(name, size, position, color, parent, shape)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position, p.Color = name, size, position, color
    p.Anchored, p.Material = true, Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.Parent = parent or world
    return p
end

local function label(parent, title, offset, maxDistance)
    local gui = Instance.new("BillboardGui", parent)
    gui.Size, gui.StudsOffset, gui.AlwaysOnTop = UDim2.fromOffset(180, 45), offset or Vector3.new(0, 4, 0), true
    gui.MaxDistance = maxDistance or 50
    local text = Instance.new("TextLabel", gui)
    text.Size, text.BackgroundTransparency, text.TextScaled = UDim2.fromScale(1, 1), 1, true
    text.TextColor3, text.TextStrokeTransparency, text.Font, text.Text = Color3.new(1, 1, 1), 0.2, Enum.Font.GothamBold, title
    return text
end

local function prompt(parent, action, distance, callback)
    local p = Instance.new("ProximityPrompt", parent)
    p.ActionText, p.ObjectText, p.MaxActivationDistance, p.RequiresLineOfSight = action, parent.Name, distance or 10, false
    p.Triggered:Connect(callback)
    return p
end

local function notify(player, message)
    if player and player.Parent == Players then noticeRemote:FireClient(player, message) end
end

local function sync(player)
    local s = states[player]
    if not s then return end
    player:SetAttribute("Coins", s.coins)
    player:SetAttribute("Carrying", s.carry and s.carry.rarity or "")
    player:SetAttribute("IncubationEnds", s.incubation and s.incubation.ends or 0)
    player:SetAttribute("Incubating", s.incubation and s.incubation.rarity or "")
    player:SetAttribute("ShieldEnds", s.shieldEnds)
    player:SetAttribute("IncomeLevel", s.incomeLevel)
    local list = {}
    for _, c in ipairs(s.creatures) do table.insert(list, c.name .. " (" .. c.rarity .. ")") end
    player:SetAttribute("Creatures", table.concat(list, ", "))
end

local function randomRarity(bias)
    local weights = {}
    local total = 0
    for i, r in ipairs(Config.Rarities) do
        local w = r.weight * (bias ^ (i - 1))
        weights[i] = w
        total += w
    end
    local roll = rng:NextNumber(0, total)
    for i, r in ipairs(Config.Rarities) do
        roll -= weights[i]
        if roll <= 0 then return r end
    end
    return Config.Rarities[1]
end

local function makeEgg(position, rarity, spawnIndex)
    local egg = part("Ovo " .. rarity.name, Vector3.new(2, 2.5, 2), position, rarity.color, world, Enum.PartType.Ball)
    egg.Material = Enum.Material.Neon
    local light = Instance.new("PointLight", egg)
    light.Color, light.Range, light.Brightness = rarity.color, 12, 1
    label(egg, rarity.name, nil, 24)
    local entry = {part = egg, rarity = rarity.name, spawnIndex = spawnIndex, claimed = false}
    eggs[egg] = entry
    prompt(egg, "Pegar ovo", 10, function(player)
        local s = states[player]
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not s or not root or s.carry or entry.claimed or (root.Position - egg.Position).Magnitude > 13 then return end
        entry.claimed = true
        eggs[egg] = nil
        if spawnIndex then spawnPoints[spawnIndex].occupied = false end
        s.carry = {rarity = entry.rarity}
        egg:Destroy()
        sync(player)
        notify(player, "Ovo " .. entry.rarity .. " coletado! Corra até sua base.")
    end)
    if not spawnIndex then
        task.delay(60, function()
            if eggs[egg] then eggs[egg] = nil egg:Destroy() end
        end)
    end
end

local function dropEgg(player, lost)
    local s = states[player]
    if not s or not s.carry then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local rarity = Config.GetRarity(s.carry.rarity)
    s.carry = nil
    sync(player)
    if root and rarity then makeEgg(root.Position + Vector3.new(0, 2, -4), rarity) end
    notify(player, lost and "Um guardião derrubou seu ovo!" or "Ovo solto.")
end

dropRemote.OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s then return end
    local now = os.clock()
    if now - (s.lastDrop or 0) < 1 then return end
    s.lastDrop = now
    dropEgg(player, false)
end)

local function creatureModel(c, position, parent)
    local rarity = Config.GetRarity(c.rarity)
    local model = Instance.new("Model", parent)
    model.Name = c.name
    local body = part("Corpo", Vector3.new(3, 3, 3), position, rarity.color, model, Enum.PartType.Ball)
    model.PrimaryPart = body
    part("Olho E", Vector3.new(.35, .45, .3), position + Vector3.new(-.65, .25, -1.4), Color3.fromRGB(28, 32, 46), model, Enum.PartType.Ball)
    part("Olho D", Vector3.new(.35, .45, .3), position + Vector3.new(.65, .25, -1.4), Color3.fromRGB(28, 32, 46), model, Enum.PartType.Ball)
    for side = -1, 1, 2 do
        local horn = part("Crista", Vector3.new(.55, 1.2, .55), position + Vector3.new(side * .8, 1.65, .2), rarity.color, model)
        horn.Orientation = Vector3.new(0, 0, side * 25)
    end
    label(body, c.name .. " · " .. c.rarity, Vector3.new(0, 3, 0), 32)
    return model
end

local function redraw(player)
    local s, base = states[player], bases[player]
    if not s or not base then return end
    base.display:ClearAllChildren()
    for i, c in ipairs(s.creatures) do
        local position = base.center + Vector3.new(((i - 1) % 4 - 1.5) * 5, 3, 7 + math.floor((i - 1) / 4) * 5)
        local model = creatureModel(c, position, base.display)
        prompt(model.PrimaryPart, "Roubar", 10, function(thief)
            if thief == player then return end
            local ts = states[thief]
            if not ts or not states[player] or os.time() < s.shieldEnds or os.time() < (ts.stealReady or 0) then return end
            if #ts.creatures >= Config.MaxCreatures or ts.carry then notify(thief, "Sem espaço ou carregando ovo.") return end
            local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
            if not root or (root.Position - model.PrimaryPart.Position).Magnitude > 13 then return end
            local index
            for j, owned in ipairs(s.creatures) do if owned.id == c.id then index = j break end end
            if not index then return end
            table.insert(ts.creatures, table.remove(s.creatures, index))
            ts.stealReady = os.time() + Config.StealCooldown
            s.shieldEnds = os.time() + 20
            sync(player)
            sync(thief)
            redraw(player)
            redraw(thief)
            notify(player, thief.DisplayName .. " roubou " .. c.name .. "!")
            notify(thief, "Você roubou " .. c.name .. "!")
        end)
    end
end

local function finishIncubation(player)
    local s = states[player]
    if not s or not s.incubation or os.time() < s.incubation.ends then return end
    if #s.creatures >= Config.MaxCreatures then return end
    local rarity = s.incubation.rarity
    local pool = Config.Creatures[rarity]
    if not pool then s.incubation = nil return end
    local name = pool[rng:NextInteger(1, #pool)]
    table.insert(s.creatures, {id = game:GetService("HttpService"):GenerateGUID(false), name = name, rarity = rarity})
    s.incubation = nil
    sync(player)
    redraw(player)
    notify(player, "✨ Seu ovo chocou: " .. name .. " (" .. rarity .. ")!")
end

local function save(player)
    local s = states[player]
    if not s or s.loadingFailed or not Store then return end
    local data = {coins = s.coins, creatures = s.creatures, incubation = s.incubation, incomeLevel = s.incomeLevel}
    local key = "u" .. player.UserId
    for attempt = 1, 3 do
        local ok = pcall(function() Store:UpdateAsync(key, function() return data end) end)
        if ok then return end
        task.wait(attempt * 2)
    end
    warn("Failed to save", player.UserId)
    notify(player, "Falha ao salvar. Tente permanecer no jogo por mais um minuto.")
end

local slots = Map.BaseSlots
local usedSlots = {}
local function buildBase(player, slot)
    local center = slots[slot]
    local folder = Instance.new("Folder", world)
    folder.Name = "Base " .. player.UserId
    local pad = part("Base de " .. player.DisplayName, Vector3.new(34, .5, 30), center + Vector3.new(0, .25, 0), Color3.fromRGB(79, 121, 158), folder)
    pad.Material = Enum.Material.Slate
    label(pad, "Base de " .. player.DisplayName, Vector3.new(0, 5, 0), 55)
    local trim = Color3.fromRGB(89, 216, 213)
    for _, offset in ipairs({Vector3.new(-16, .6, 0), Vector3.new(16, .6, 0)}) do
        local rail = part("Faixa da base", Vector3.new(.5, .4, 29), center + offset, trim, folder)
        rail.CanCollide = false
    end
    for _, offset in ipairs({Vector3.new(-15, .6, -14), Vector3.new(15, .6, -14)}) do
        local lamp = part("Luz da base", Vector3.new(1, 5, 1), center + offset + Vector3.new(0, 2.5, 0), trim, folder)
        lamp.Material = Enum.Material.Neon
        lamp.CanCollide = false
    end
    local stage = part("Palco de criaturas", Vector3.new(29, .25, 13), center + Vector3.new(0, .65, 8), Color3.fromRGB(51, 77, 111), folder)
    stage.Material = Enum.Material.Slate
    local incubator = part("Incubadora", Vector3.new(6, 4, 6), center + Vector3.new(-10, 2.5, -7), Color3.fromRGB(247, 190, 99), folder, Enum.PartType.Ball)
    incubator.Material = Enum.Material.Neon
    prompt(incubator, "Incubar ovo", 12, function(actor)
        if actor ~= player then return end
        local s = states[player]
        if not s or not s.carry or s.incubation then return end
        local rarity = Config.GetRarity(s.carry.rarity)
        if not rarity then return end
        s.incubation = {rarity = rarity.name, ends = os.time() + rarity.hatch}
        s.carry = nil
        sync(player)
        notify(player, "Incubação iniciada: " .. rarity.name)
    end)
    local shield = part("Escudo", Vector3.new(4, 4, 4), center + Vector3.new(0, 2.5, -7), Color3.fromRGB(78, 204, 255), folder, Enum.PartType.Ball)
    prompt(shield, "Proteger (100 moedas)", 12, function(actor)
        if actor ~= player then return end
        local s = states[player]
        if s and s.coins >= Config.UpgradeCost then
            s.coins -= Config.UpgradeCost
            s.shieldEnds = math.max(os.time(), s.shieldEnds) + Config.ShieldSeconds
            sync(player)
            notify(player, "Escudo ativado!")
        end
    end)
    local upgrade = part("Melhoria", Vector3.new(4, 4, 4), center + Vector3.new(10, 2.5, -7), Color3.fromRGB(255, 196, 75), folder, Enum.PartType.Ball)
    prompt(upgrade, "Melhorar renda (100 moedas)", 12, function(actor)
        if actor ~= player then return end
        local s = states[player]
        if s and s.coins >= Config.UpgradeCost then
            s.coins -= Config.UpgradeCost
            s.incomeLevel += 1
            sync(player)
            notify(player, "Renda melhorada para nível " .. s.incomeLevel)
        end
    end)
    local display = Instance.new("Folder", folder)
    display.Name = "Criaturas"
    bases[player] = {folder = folder, center = center, display = display, slot = slot}
    local spawn = Instance.new("SpawnLocation", folder)
    spawn.Size, spawn.Position = Vector3.new(5, 1, 5), center + Vector3.new(0, 1, 0)
    spawn.Anchored, spawn.Neutral, spawn.Transparency = true, true, 1
    return spawn
end

Map.Build(world, part, label, spawnPoints)
Players.PlayerAdded:Connect(function(player)
    local slot
    for i = 1, #slots do if not usedSlots[i] then slot = i break end end
    if not slot then player:Kick("Servidor cheio: sem bases disponíveis.") return end
    usedSlots[slot] = true
    local s = {coins = 0, creatures = {}, incomeLevel = 0, shieldEnds = os.time() + Config.ShieldSeconds}
    states[player] = s
    local ok, data
    if Store then
        for attempt = 1, 3 do
            ok, data = pcall(function() return Store:GetAsync("u" .. player.UserId) end)
            if ok then break end
            task.wait(attempt * 2)
        end
    else
        ok = true
    end
    if ok and type(data) == "table" then
        s.coins = math.max(0, tonumber(data.coins) or 0)
        s.incomeLevel = math.clamp(tonumber(data.incomeLevel) or 0, 0, 20)
        if type(data.creatures) == "table" then
            for _, c in ipairs(data.creatures) do
                if #s.creatures >= Config.MaxCreatures then break end
                if type(c) == "table" and type(c.id) == "string" and Config.GetRarity(c.rarity) and table.find(Config.Creatures[c.rarity], c.name) then
                    table.insert(s.creatures, {id = c.id, name = c.name, rarity = c.rarity})
                end
            end
        end
        if type(data.incubation) == "table" and Config.GetRarity(data.incubation.rarity) and type(data.incubation.ends) == "number" then
            s.incubation = {rarity = data.incubation.rarity, ends = data.incubation.ends}
        end
    elseif not ok then
        s.loadingFailed = true
        notify(player, "Dados indisponíveis; esta sessão não será salva para proteger seu progresso.")
    end
    local spawn = buildBase(player, slot)
    player.RespawnLocation = spawn
    player.CharacterAdded:Connect(function(character)
        task.wait(.2)
        local start = slots[slot] + Vector3.new(0, 4, 0)
        character:PivotTo(CFrame.lookAt(start, Vector3.new(0, start.Y, start.Z)))
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function() dropEgg(player, true) end)
    end)
    sync(player)
    redraw(player)
    finishIncubation(player)
end)

Players.PlayerRemoving:Connect(function(player)
    save(player)
    if bases[player] then
        usedSlots[bases[player].slot] = nil
        bases[player].folder:Destroy()
        bases[player] = nil
    end
    states[player] = nil
end)

task.spawn(function()
    while true do
        task.wait(2)
        local count = 0
        for _ in pairs(eggs) do count += 1 end
        if count < Config.MaxEggs then
            local options = {}
            for i, point in ipairs(spawnPoints) do if not point.occupied then table.insert(options, i) end end
            if #options > 0 then
                local index = options[rng:NextInteger(1, #options)]
                local point = spawnPoints[index]
                point.occupied = true
                makeEgg(point.position, randomRarity(point.bias), index)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        for player, s in pairs(states) do
            finishIncubation(player)
            local income = 0
            for _, c in ipairs(s.creatures) do
                local rarity = Config.GetRarity(c.rarity)
                if rarity then income += rarity.income end
            end
            if income > 0 then
                s.coins += math.floor(income * (Config.UpgradeIncomeMultiplier ^ s.incomeLevel))
                sync(player)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Config.SaveInterval)
        for player in pairs(states) do task.spawn(save, player) end
    end
end)

for i, home in ipairs(Map.GuardianHomes) do
    local guardian = part("Guardião " .. i, Vector3.new(5, 5, 5), home, Color3.fromRGB(51, 58, 83), world, Enum.PartType.Ball)
    guardian.Material = Enum.Material.Neon
    label(guardian, "GUARDIÃO", nil, 38)
    task.spawn(function()
        local current = home
        while guardian.Parent do
            local target, distance
            for player, s in pairs(states) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if s.carry and root then
                    local d = (root.Position - current).Magnitude
                    if d < 42 and (not distance or d < distance) then target, distance = player, d end
                end
            end
            local destination = home + Vector3.new(rng:NextInteger(-12, 12), 0, rng:NextInteger(-12, 12))
            local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then destination = targetRoot.Position end
            local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 5})
            local ok = pcall(function() path:ComputeAsync(current, destination) end)
            local waypoints = ok and path.Status == Enum.PathStatus.Success and path:GetWaypoints() or {{Position = destination}}
            for _, waypoint in ipairs(waypoints) do
                local goal = Vector3.new(waypoint.Position.X, 2.5, waypoint.Position.Z)
                local delta = goal - current
                local steps = math.max(1, math.ceil(delta.Magnitude / 2))
                for step = 1, steps do
                    current = current:Lerp(goal, 1 / (steps - step + 1))
                    guardian.Position = current
                    if target and states[target] and states[target].carry then
                        local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        if root and (root.Position - current).Magnitude < 5 then dropEgg(target, true) target = nil end
                    end
                    task.wait(.1)
                end
                if target and not states[target].carry then break end
            end
            task.wait(.3)
        end
    end)
end

game:BindToClose(function()
    for player in pairs(states) do task.spawn(save, player) end
    task.wait(7)
end)
