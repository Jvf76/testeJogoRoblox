local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local yaw = 0
local pitch = math.rad(-12)
local holdingAlt = false

local function setCharacter(character)
    local root = character:WaitForChild("HumanoidRootPart")
    yaw = math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z)
end

if player.Character then setCharacter(player.Character) end
player.CharacterAdded:Connect(setCharacter)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        holdingAlt = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        holdingAlt = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and not holdingAlt then
        yaw -= input.Delta.X * .0035
        pitch = math.clamp(pitch - input.Delta.Y * .0035, math.rad(-70), math.rad(65))
    end
end)

RunService:BindToRenderStep("HeistCamera", Enum.RenderPriority.Camera.Value + 1, function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = holdingAlt and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = holdingAlt
    local focus = root.Position + Vector3.new(0, 3, 0)
    local direction = CFrame.fromOrientation(pitch, yaw, 0).LookVector
    local desired = focus - direction * 15
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(focus, desired - focus, params)
    if hit then desired = hit.Position + direction * .5 end
    camera.CFrame = CFrame.lookAt(desired, focus)
end)
