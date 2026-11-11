--// ============================================
--// Boss 检测 + 强制装备 Punch + 自动挥拳 + 死亡重生 + 击杀后领奖
--// + 右侧开关 UI
--// ============================================
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--// 攻击参数
local FOLLOW_DISTANCE = 10
local HEIGHT_OFFSET   = 60

--// 领奖点：原 CFrame + Y轴+20
local REWARD_CFRAME = CFrame.new(
    0.41224134, 34.0194778 + 20, -1248.67554,
    0, 0, 1,
    0, 1, 0,
    -1, 0, 0
)
local REWARD_PROMPT_PATH = "workspace.Events.BossArena.Board.Inner.Front.AdPart.bossRewardsPrompt"

--// 六个实体路径
local BOSS_PATHS = {
    "workspace.Events.BossArena.Boss1.Boss",
    "workspace.Events.BossArena.Boss2.Boss",
    "workspace.Events.BossArena.Boss3.Boss",
    "workspace.Events.BossArena.Boss4.Boss",
    "workspace.Events.BossArena.Boss5.Boss",
    "workspace.Events.BossArena.BossRainbow.Boss",
}

--// 功能总开关
local enabled = true

--// ============================================
--// UI
--// ============================================
local function createUI()
    local old = PlayerGui:FindFirstChild("BossFarmUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BossFarmUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.Parent = PlayerGui

    -- 主面板（右侧居中）
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 170, 0, 108)
    panel.Position = UDim2.new(1, -190, 0.5, -54)
    panel.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 70, 80)
    stroke.Thickness = 1
    stroke.Parent = panel

    -- 标题
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -46, 0, 26)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Boss 自动刷"
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    -- 关闭按钮（×）
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = true
    closeBtn.Parent = panel
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = closeBtn

    -- 开关按钮
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -20, 0, 40)
    toggleBtn.Position = UDim2.new(0, 10, 0, 44)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
    toggleBtn.Text = "状态：开启"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 15
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.AutoButtonColor = true
    toggleBtn.Parent = panel
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = toggleBtn

    -- 右下角重新打开的小图标
    local reopenBtn = Instance.new("TextButton")
    reopenBtn.Name = "Reopen"
    reopenBtn.Size = UDim2.new(0, 44, 0, 44)
    reopenBtn.Position = UDim2.new(1, -60, 0.5, -22)
    reopenBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    reopenBtn.BackgroundTransparency = 0.15
    reopenBtn.Text = "⚙"
    reopenBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    reopenBtn.TextSize = 22
    reopenBtn.Font = Enum.Font.GothamBold
    reopenBtn.BorderSizePixel = 0
    reopenBtn.Visible = false
    reopenBtn.Parent = gui
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 22)
    rc.Parent = reopenBtn

    local function refreshToggle()
        if enabled then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            toggleBtn.Text = "状态：开启"
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            toggleBtn.Text = "状态：关闭"
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        refreshToggle()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        reopenBtn.Visible = true
    end)

    reopenBtn.MouseButton1Click:Connect(function()
        panel.Visible = true
        reopenBtn.Visible = false
    end)

    refreshToggle()
    return gui
end

createUI()

--// ============================================
--// 工具函数
--// ============================================
local function resolvePath(path)
    local segments = {}
    for s in string.gmatch(path, "[^%.]+") do
        table.insert(segments, s)
    end
    local node = game
    for i, seg in ipairs(segments) do
        if i == 1 and seg:lower() == "workspace" then
            node = Workspace
        else
            node = node:FindFirstChild(seg)
        end
        if not node then return nil end
    end
    return node
end

local function findBoss()
    for _, path in ipairs(BOSS_PATHS) do
        local boss = resolvePath(path)
        if boss and boss.Parent then
            return boss
        end
    end
    return nil
end

local function getBossCFrame(boss)
    if boss:IsA("BasePart") then
        return boss.CFrame
    elseif boss:IsA("Model") then
        local primary = boss.PrimaryPart or boss:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.CFrame end
        local ok, cf = pcall(function() return boss:GetPivot() end)
        if ok then return cf end
    end
    return nil
end

local function getAliveChar()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if char and hum and hrp and hum.Health > 0 then
        return char, hrp, hum
    end
    return nil
end

local respawnRequested = false
local function tryRespawn()
    if respawnRequested then return end
    respawnRequested = true
    pcall(function() LocalPlayer:LoadCharacter() end)
    task.delay(3, function() respawnRequested = false end)
end

local function forceEquipOnce()
    local char, _, hum = getAliveChar()
    if not char then return end
    if char:FindFirstChild("Punch") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local punch = backpack and backpack:FindFirstChild("Punch")
    if punch then
        pcall(function() hum:EquipTool(punch) end)
    end
end

local function firePunch()
    local ev = LocalPlayer:FindFirstChild("muscleEvent")
    if ev then
        pcall(function() ev:FireServer("punch", "rightHand") end)
    end
end

--// ---------------- 领奖相关 ----------------
local function claimRewardOnce()
    local prompt = resolvePath(REWARD_PROMPT_PATH)
    if not prompt then return false end
    if prompt:IsA("ProximityPrompt") then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration or 0.5, 0.3))
            prompt:InputHoldEnd()
        end)
        return true
    elseif prompt:IsA("ClickDetector") then
        if fireclickdetector then
            pcall(function() fireclickdetector(prompt) end)
            return true
        end
    end
    local cd = prompt:FindFirstChildWhichIsA("ClickDetector", true)
    if cd and fireclickdetector then
        pcall(function() fireclickdetector(cd) end)
        return true
    end
    return false
end

local function doReward()
    local _, hrp, hum = getAliveChar()
    if not hrp then return end
    hum.AutoRotate = true
    local t0 = os.clock()
    while os.clock() - t0 < 5 do
        if not enabled then break end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        local hm = c and c:FindFirstChildOfClass("Humanoid")
        if h and hm and hm.Health > 0 then
            h.CFrame = REWARD_CFRAME
            h.AssemblyLinearVelocity = Vector3.zero
        end
        claimRewardOnce()
        task.wait(0.4)
    end
end

--// ============================================
--// 主循环
--// ============================================
local gen = 0
local lastRewardT = -math.huge
local wasEnabled = true

while true do
    --// 关闭状态处理：让所有子协程失效并恢复角色
    if not enabled then
        if wasEnabled then
            gen += 1
            wasEnabled = false
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Parent then h.AutoRotate = true end
        end
        task.wait(0.2)
        continue
    end
    wasEnabled = true

    local boss = findBoss()
    if not boss then
        task.wait(0.5)
        continue
    end

    local char, hrp, hum = getAliveChar()
    if not char then
        tryRespawn()
        task.wait(0.5)
        continue
    end

    gen += 1
    local myGen = gen
    hum.AutoRotate = false

    --// 1. 持续强制装备 Punch
    task.spawn(function()
        while myGen == gen and enabled do
            forceEquipOnce()
            task.wait(0.05)
        end
    end)

    --// 2. 传送 Boss 后方 + 抬高，面向 Boss（实时跟随）
    task.spawn(function()
        while myGen == gen and enabled and boss and boss.Parent do
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h then
                local cf = getBossCFrame(boss)
                if cf then
                    local bossPos  = cf.Position
                    local standPos = bossPos
                                   - cf.LookVector * FOLLOW_DISTANCE
                                   + Vector3.new(0, HEIGHT_OFFSET, 0)
                    h.CFrame = CFrame.lookAt(standPos, bossPos, Vector3.new(0, 1, 0))
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)

    --// 3. 快速挥拳
    task.spawn(function()
        while myGen == gen and enabled do
            firePunch()
            task.wait(0.05)
        end
    end)

    --// 4. 等待：Boss 消失 / 角色死亡 / 开关关闭
    while boss and boss.Parent do
        if not enabled then break end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not h or h.Health <= 0 then
            break
        end
        task.wait(0.1)
    end

    local bossGone = not (boss and boss.Parent)

    --// 5. 本轮结束，让协程失效
    gen += 1
    local curChar = LocalPlayer.Character
    local curHum  = curChar and curChar:FindFirstChildOfClass("Humanoid")
    if curHum and curHum.Parent then
        curHum.AutoRotate = true
    end

    --// 6. Boss 被击杀（非角色死亡）且六个 Boss 都不存在 → 传送领奖
    if enabled and bossGone and not findBoss() and (os.clock() - lastRewardT > 10) then
        lastRewardT = os.clock()
        task.wait(0.5)
        doReward()
    end

    task.wait(0.3)
end