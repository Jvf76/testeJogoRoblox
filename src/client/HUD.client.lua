local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("HeistRemotes")
local drop = remotes:WaitForChild("Drop")
local notice = remotes:WaitForChild("Notice")

local gui = Instance.new("ScreenGui")
gui.Name = "HeistHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function panel(name, size, position, anchor)
    local frame = Instance.new("Frame", gui)
    frame.Name, frame.Size, frame.Position, frame.AnchorPoint = name, size, position, anchor
    frame.BackgroundColor3 = Color3.fromRGB(25, 32, 49)
    frame.BackgroundTransparency = .12
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(94, 130, 164)
    stroke.Transparency = .45
    return frame
end

local function textLabel(parent, name, size, pos, content, textSize)
    local t = Instance.new("TextLabel", parent)
    t.Name, t.Size, t.Position, t.Text = name, size, pos, content
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(245, 248, 255)
    t.Font, t.TextSize = Enum.Font.GothamBold, textSize or 18
    t.TextXAlignment, t.TextWrapped = Enum.TextXAlignment.Left, true
    return t
end

local stats = panel("Status", UDim2.fromOffset(275, 122), UDim2.fromOffset(16, 16), Vector2.zero)
local coins = textLabel(stats, "Moedas", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 10), "🪙 0 moedas", 21)
local carrying = textLabel(stats, "Ovo", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 45), "Ovo: nenhum", 17)
local incubation = textLabel(stats, "Incubação", UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 78), "Incubadora livre", 16)

local inventory = panel("Inventário", UDim2.fromOffset(275, 160), UDim2.new(1, -16, 0, 16), Vector2.new(1, 0))
textLabel(inventory, "Título", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), "CRIATURAS", 18)
local creatures = textLabel(inventory, "Lista", UDim2.new(1, -24, 1, -48), UDim2.fromOffset(12, 40), "Nenhuma criatura", 14)
creatures.TextYAlignment = Enum.TextYAlignment.Top

local dropButton = Instance.new("TextButton", gui)
dropButton.Name = "Soltar"
dropButton.Size = UDim2.fromOffset(138, 52)
dropButton.Position = UDim2.new(1, -16, 1, -20)
dropButton.AnchorPoint = Vector2.new(1, 1)
dropButton.BackgroundColor3 = Color3.fromRGB(224, 104, 87)
dropButton.TextColor3 = Color3.new(1, 1, 1)
dropButton.TextSize, dropButton.Font, dropButton.Text = 19, Enum.Font.GothamBold, "Soltar (G)"
Instance.new("UICorner", dropButton).CornerRadius = UDim.new(0, 12)
dropButton.Activated:Connect(function() drop:FireServer() end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.G then drop:FireServer() end
end)

local toast = panel("Aviso", UDim2.new(.8, 0, 0, 65), UDim2.new(.5, 0, .18, 0), Vector2.new(.5, 0))
toast.SizeConstraint = Enum.SizeConstraint.RelativeYY
toast.Size = UDim2.fromOffset(440, 65)
local toastText = textLabel(toast, "Texto", UDim2.new(1, -24, 1, -12), UDim2.fromOffset(12, 6), "", 18)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false
local toastCounter = 0
notice.OnClientEvent:Connect(function(message)
    toastCounter += 1
    local current = toastCounter
    toastText.Text = tostring(message)
    toast.Visible = true
    task.delay(4, function() if current == toastCounter then toast.Visible = false end end)
end)

local function refresh()
    coins.Text = "🪙 " .. tostring(player:GetAttribute("Coins") or 0) .. " moedas"
    local egg = player:GetAttribute("Carrying") or ""
    carrying.Text = egg ~= "" and ("Ovo: " .. egg) or "Ovo: nenhum"
    dropButton.Visible = egg ~= ""
    local list = player:GetAttribute("Creatures") or ""
    creatures.Text = list ~= "" and list or "Nenhuma criatura"
end
for _, attr in ipairs({"Coins", "Carrying", "Creatures", "IncubationEnds", "Incubating"}) do
    player:GetAttributeChangedSignal(attr):Connect(refresh)
end
refresh()
task.spawn(function()
    while gui.Parent do
        local ends = player:GetAttribute("IncubationEnds") or 0
        local rarity = player:GetAttribute("Incubating") or ""
        local left = math.max(0, ends - os.time())
        incubation.Text = rarity ~= "" and ("Incubando " .. rarity .. ": " .. left .. "s") or "Incubadora livre"
        task.wait(1)
    end
end)
