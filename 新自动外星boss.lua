local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP     = Players.LocalPlayer
local camera = workspace.CurrentCamera

local VirtualInputManager
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)

local HEIGHT_OFFSET  = Vector3.new(0, 40, 0)
local PUNCH_INTERVAL = 0.05
local CLICK_DURATION = 5
local TP_SETTLE      = 0.15

local CLICK_OFFSET_X = 0
local CLICK_OFFSET_Y = 0

local KILL_CFRAME = CFrame.new(
	-1835.37622, 50.7084084 + 5, -10978.874,
	0.799689353,    6.68484859e-08, -0.600413978,
	-6.14595024e-08, 1,             2.94796223e-08,
	0.600413978,    1.33266056e-08,  0.799689353
)

local enabled     = false
local running     = false
local teleporting = false

local function checkBossStatus()
	local alien = workspace:FindFirstChild("Alien Boss")
	if not alien then return "gone", nil end
	local hitbox = alien:FindFirstChild("BossDamageHitbox")
	if not hitbox then return "gone", nil end
	local humanoid = alien:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return "dead", hitbox
	end
	return "alive", hitbox
end

local function getChar() return LP.Character or LP.CharacterAdded:Wait() end

local function unequipTools()
	local char = LP.Character
	if char then
		local human = char:FindFirstChildOfClass("Humanoid")
		if human then human:UnequipTools() end
	end
end

local camAnchor = Instance.new("Part")
camAnchor.Name = "AlienBossCamAnchor"
camAnchor.Anchored = true
camAnchor.CanCollide = false
camAnchor.CanQuery = false
camAnchor.CanTouch = false
camAnchor.Transparency = 1
camAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
camAnchor.Parent = workspace

local function pressScreenHold(seconds)
	if not VirtualInputManager then return end
	local endTime = os.clock() + seconds
	local screenSize = camera.ViewportSize
	local x = math.floor(screenSize.X / 2) + CLICK_OFFSET_X
	local y = math.floor(screenSize.Y / 2) + CLICK_OFFSET_Y

	pcall(function() VirtualInputManager:SendMouseMoveEvent(x, y, 0, game) end)
	task.wait(0.1)

	while os.clock() < endTime do
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
			task.wait(0.05)
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
		end)
		task.wait(0.15)
	end
end

local function forceTeleport()
	local char = LP.Character
	if not char then return end
	char:PivotTo(KILL_CFRAME)
	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < 0.5 do
			if not char.Parent then break end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = KILL_CFRAME
				hrp.AssemblyLinearVelocity  = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
			task.wait()
		end
	end)
end

local function afterKillClick()
	teleporting = true
	local ok, err = pcall(function()
		unequipTools()
		if TP_SETTLE > 0 then task.wait(TP_SETTLE) end
		pressScreenHold(CLICK_DURATION)
	end)
	if not ok then warn("[AlienBoss] 击杀后处理出错:", err) end
	task.wait(0.2)
	teleporting = false
end

local conn = nil

local function stopRuntime()
	if conn then conn:Disconnect(); conn = nil end
	local char = LP.Character
	if char then
		local human = char:FindFirstChildOfClass("Humanoid")
		if human then
			human.AutoRotate = true
			if camera.CameraSubject == camAnchor then camera.CameraSubject = human end
			human:UnequipTools()
		end
	end
	running = false
end

local function startRuntime()
	if running then return end
	running = true

	local char  = getChar()
	local hrp   = char:WaitForChild("HumanoidRootPart")
	local human = char:WaitForChild("Humanoid")

	local backpack = LP:FindFirstChild("Backpack")
	local punch    = backpack and backpack:FindFirstChild("Punch")
	if punch then human:EquipTool(punch) end

	human.AutoRotate     = false
	camera.CameraSubject = camAnchor

	local lastPunch = 0

	conn = RunService.Heartbeat:Connect(function()
		local ok, err = pcall(function()
			local status, hitbox = checkBossStatus()
			if status ~= "alive" then
				local wasKill = running and enabled
				if wasKill then forceTeleport() end
				stopRuntime()
				if wasKill then task.spawn(afterKillClick) end
				return
			end

			if not enabled then stopRuntime(); return end

			local target = hitbox.Position + HEIGHT_OFFSET
			hrp.CFrame = CFrame.new(target, target + Vector3.new(0, -1, 0))
			hrp.AssemblyLinearVelocity  = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			camAnchor.CFrame = CFrame.new(target)

			local now = os.clock()
			if now - lastPunch >= PUNCH_INTERVAL then
				lastPunch = now
				if checkBossStatus() == "alive" then
					local ev = LP:FindFirstChild("muscleEvent")
					if ev then ev:FireServer("punch", "leftHand") end
				end
			end
		end)
		if not ok then warn("[AlienBoss] 心跳回调异常:", err) end
	end)
end

task.spawn(function()
	while true do
		pcall(function()
			if enabled and not running and not teleporting and checkBossStatus() == "alive" then
				startRuntime()
			end
		end)
		task.wait(0.2)
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name           = "AlienBossUI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = LP:WaitForChild("PlayerGui")

local function makeDraggable(frame)
	frame.Active = true
	local dragging, dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, 250, 0, 135)
panel.Position               = UDim2.new(0, 20, 0.5, -67)
panel.BackgroundColor3       = Color3.fromRGB(25, 25, 30)
panel.BackgroundTransparency = 0.3 
panel.BorderSizePixel        = 0
panel.ClipsDescendants       = true 
panel.ZIndex                 = 1
panel.Parent                 = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(80, 80, 90)
panelStroke.Thickness = 1
panelStroke.Parent    = panel

local bgImage = Instance.new("ImageLabel")
bgImage.Size                   = UDim2.new(1, 0, 1, 0)
bgImage.Position               = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image                  = "https://raw.githubusercontent.com/Abxx147369/CX/refs/heads/main/Image_1791731543974_443.jpg"
bgImage.ScaleType              = Enum.ScaleType.Crop
bgImage.ImageTransparency      = 0.4 
bgImage.ZIndex                 = 0
bgImage.Parent                 = panel

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 8)
bgCorner.Parent = bgImage

local contentFrame = Instance.new("Frame")
contentFrame.Size                   = UDim2.new(1, 0, 1, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex                 = 2
contentFrame.Parent                 = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop    = UDim.new(0, 15)
padding.PaddingBottom = UDim.new(0, 15)
padding.PaddingLeft   = UDim.new(0, 15)
padding.PaddingRight  = UDim.new(0, 40) 
padding.Parent        = contentFrame

local layout = Instance.new("UIListLayout")
layout.Padding   = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent    = contentFrame

local title = Instance.new("TextLabel")
title.LayoutOrder = 1
title.Size        = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text        = "Alien Boss 助手"
title.TextColor3  = Color3.fromRGB(230, 230, 230)
title.Font        = Enum.Font.GothamBold
title.TextSize    = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex      = 3
title.Parent      = contentFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.LayoutOrder = 2
statusLabel.Size        = UDim2.new(1, 0, 0, 16)
statusLabel.BackgroundTransparency = 1
statusLabel.Text        = "状态：已关闭"
statusLabel.TextColor3  = Color3.fromRGB(180, 180, 180)
statusLabel.Font        = Enum.Font.Gotham
statusLabel.TextSize    = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex      = 3
statusLabel.Parent      = contentFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.LayoutOrder = 3
toggleBtn.Size        = UDim2.new(1, 0, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Text        = "开启"
toggleBtn.TextColor3  = Color3.new(1, 1, 1)
toggleBtn.Font        = Enum.Font.GothamBold
toggleBtn.TextSize    = 14
toggleBtn.ZIndex      = 3
toggleBtn.Parent      = contentFrame
local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 6); tCorner.Parent = toggleBtn

local xBtn = Instance.new("TextButton")
xBtn.Size                   = UDim2.new(0, 24, 0, 24)
xBtn.Position               = UDim2.new(1, -32, 0, 10)
xBtn.BackgroundColor3       = Color3.fromRGB(200, 60, 60)
xBtn.BackgroundTransparency = 0.8
xBtn.BorderSizePixel        = 0
xBtn.Text                   = "X"
xBtn.TextColor3             = Color3.fromRGB(200, 200, 200)
xBtn.Font                   = Enum.Font.GothamBold
xBtn.TextSize               = 13
xBtn.ZIndex                 = 5
xBtn.Parent                 = panel

local xBtnCorner = Instance.new("UICorner")
xBtnCorner.CornerRadius = UDim.new(0, 6)
xBtnCorner.Parent = xBtn

xBtn.MouseEnter:Connect(function()
	xBtn.BackgroundTransparency = 0.2
	xBtn.TextColor3 = Color3.new(1, 1, 1)
end)
xBtn.MouseLeave:Connect(function()
	xBtn.BackgroundTransparency = 0.8
	xBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

local reopenBtn = Instance.new("TextButton")
reopenBtn.Size        = UDim2.new(0, 40, 0, 40)
reopenBtn.Position    = UDim2.new(0, 20, 0.5, -20)
reopenBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
reopenBtn.BorderSizePixel  = 0
reopenBtn.Text        = "☰"
reopenBtn.TextColor3  = Color3.new(1, 1, 1)
reopenBtn.Font        = Enum.Font.GothamBold
reopenBtn.TextSize    = 20
reopenBtn.Visible     = false
reopenBtn.Parent      = gui
local rCorner = Instance.new("UICorner"); rCorner.CornerRadius = UDim.new(0, 8); rCorner.Parent = reopenBtn

makeDraggable(panel)
makeDraggable(reopenBtn)

local function updateUI()
	if teleporting then
		statusLabel.Text           = "状态：传送/开箱中..."
		statusLabel.TextColor3     = Color3.fromRGB(120, 180, 255)
		toggleBtn.Text             = "停止"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
	elseif enabled then
		toggleBtn.Text             = "停止"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
		statusLabel.Text           = running and "状态：攻击中" or "状态：等待 Boss..."
		statusLabel.TextColor3     = Color3.fromRGB(100, 220, 130)
	else
		toggleBtn.Text             = "开启"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
		statusLabel.Text           = "状态：已关闭"
		statusLabel.TextColor3     = Color3.fromRGB(180, 180, 180)
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	if not enabled then stopRuntime() end
	updateUI()
end)

xBtn.MouseButton1Click:Connect(function()
	panel.Visible     = false
	reopenBtn.Visible = true
end)

reopenBtn.MouseButton1Click:Connect(function()
	panel.Visible     = true
	reopenBtn.Visible = false
end)

task.spawn(function()
	while true do
		pcall(updateUI)
		task.wait(0.2)
	end
end)