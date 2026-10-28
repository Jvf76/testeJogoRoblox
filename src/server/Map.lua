local Lighting = game:GetService("Lighting")

local Map = {}

Map.BaseSlots = {
    Vector3.new(-94, 0, -70), Vector3.new(94, 0, -70),
    Vector3.new(-94, 0, 0), Vector3.new(94, 0, 0),
    Vector3.new(-94, 0, 70), Vector3.new(94, 0, 70),
}

Map.GuardianHomes = {
    Vector3.new(-39, 2.5, -69),
    Vector3.new(40, 2.5, 0),
    Vector3.new(0, 2.5, 70),
}

local sectors = {
    {name = "Campo Verde", z = -70, ground = Color3.fromRGB(96, 235, 36), accent = Color3.fromRGB(131, 250, 61), bias = 1},
    {name = "Campo Verde", z = 0, ground = Color3.fromRGB(96, 235, 36), accent = Color3.fromRGB(131, 250, 61), bias = 1.5},
    {name = "Deserto Dourado", z = 70, ground = Color3.fromRGB(255, 190, 71), accent = Color3.fromRGB(255, 213, 108), bias = 2.1},
}

function Map.Build(world, part, label, spawnPoints)
    Lighting.ClockTime = 13.5
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(122, 145, 170)
    Lighting.OutdoorAmbient = Color3.fromRGB(155, 165, 180)
    local atmosphere = Instance.new("Atmosphere", Lighting)
    atmosphere.Name = "HeistAtmosphere"
    atmosphere.Density = .12
    atmosphere.Offset = .2
    atmosphere.Color = Color3.fromRGB(194, 226, 247)

    local ocean = part("Mar azul", Vector3.new(310, 1, 310), Vector3.new(0, -2.4, 0), Color3.fromRGB(10, 76, 197), world)
    ocean.Material = Enum.Material.SmoothPlastic
    local island = part("Ilha principal", Vector3.new(246, 2, 250), Vector3.new(0, -1, 0), Color3.fromRGB(63, 171, 44), world)
    island.Material = Enum.Material.Plastic
    local avenue = part("Caminho central", Vector3.new(13, .08, 220), Vector3.new(0, .56, 0), Color3.fromRGB(234, 219, 178), world)
    avenue.Material = Enum.Material.Plastic
    avenue.CanCollide = false

    for _, side in ipairs({-1, 1}) do
        local cliff = part("Parede alta", Vector3.new(4, 38, 246), Vector3.new(side * 122, 18, 0), Color3.fromRGB(189, 118, 78), world)
        cliff.Material = Enum.Material.Plastic
        for row = 0, 3 do
            for column = 0, 7 do
                if (row + column) % 2 == 0 then
                    local tile = part("Quadro da parede", Vector3.new(.08, 5, 14), Vector3.new(side * 119.9, 4 + row * 8, -104 + column * 29), Color3.fromRGB(207, 137, 91), world)
                    tile.CanCollide = false
                end
            end
        end
    end
    for _, z in ipairs({-123, 123}) do
        local cliff = part("Parede alta", Vector3.new(246, 38, 4), Vector3.new(0, 18, z), Color3.fromRGB(189, 118, 78), world)
        cliff.Material = Enum.Material.Plastic
    end

    for index, sector in ipairs(sectors) do
        local floor = part(sector.name, Vector3.new(238, .5, 80), Vector3.new(0, .25, sector.z), sector.ground, world)
        floor.Material = Enum.Material.Plastic
        floor.TopSurface = Enum.SurfaceType.Studs
        local marker = part("Portal " .. sector.name, Vector3.new(30, 1, 2), Vector3.new(0, 8, sector.z - 29), sector.accent, world)
        marker.Material = Enum.Material.Neon
        marker.CanCollide = false
        label(marker, sector.name, Vector3.new(0, 2.5, 0), 80)
        for _, side in ipairs({-1, 1}) do
            local post = part("Pilar do portal", Vector3.new(2, 8, 2), Vector3.new(side * 15, 4, sector.z - 29), sector.accent, world)
            post.Material = Enum.Material.Slate
            local route = part("Rota lateral", Vector3.new(76, .12, 6), Vector3.new(side * 50, .6, sector.z), Color3.fromRGB(224, 217, 190), world)
            route.Material = Enum.Material.Plastic
            route.CanCollide = false
        end

        for _, side in ipairs({-1, 1}) do
            local x = side * 58
            local z = sector.z + 18
            if index < 3 then
                local trunk = part("Árvore", Vector3.new(2.4, 7, 2.4), Vector3.new(x, 3.5, z), Color3.fromRGB(103, 73, 63), world)
                trunk.Material = Enum.Material.Wood
                local crown = part("Copa", Vector3.new(8, 8, 8), Vector3.new(x, 9, z), Color3.fromRGB(31, 139, 63), world, Enum.PartType.Ball)
                crown.CanCollide = false
            else
                local cactus = part("Cacto", Vector3.new(2, 7, 2), Vector3.new(x, 3.5, z), Color3.fromRGB(37, 154, 69), world)
                local arm = part("Braço do cacto", Vector3.new(5, 1.4, 1.4), Vector3.new(x + 2, 4, z), Color3.fromRGB(37, 154, 69), world)
            end
        end

        for _, x in ipairs({-42, -26, 26, 42}) do
            local zOffset = x < 0 and -12 or 12
            table.insert(spawnPoints, {
                position = Vector3.new(x, 1.7, sector.z + zOffset),
                bias = sector.bias,
            })
        end
    end

    for _, slot in ipairs(Map.BaseSlots) do
        for _, side in ipairs({-1, 1}) do
            local fence = part("Cerca da base", Vector3.new(1.2, 4, 29), Vector3.new(slot.X + side * 18, 2, slot.Z), Color3.fromRGB(137, 77, 39), world)
            fence.Material = Enum.Material.Wood
        end
        local back = part("Cerca traseira", Vector3.new(36, 4, 1.2), Vector3.new(slot.X, 2, slot.Z + 16), Color3.fromRGB(137, 77, 39), world)
        back.Material = Enum.Material.Wood
    end
end

return Map
