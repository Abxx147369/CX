--// ============================================
--// Boss 检测 + 强制装备 Punch + 自动挥拳 + 死亡重生 + 击杀后领奖
--// ============================================
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

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
    -- 兜底：找内部 ClickDetector
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
    -- 保持在领奖点 5 秒，期间反复尝试触发
    while os.clock() - t0 < 5 do
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
local lastRewardT = -math.huge   -- 领奖节流，防止 Boss 长时间不刷新时反复触发

while true do
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
        while myGen == gen do
            forceEquipOnce()
            task.wait(0.05)
        end
    end)

    --// 2. 传送 Boss 后方 + 抬高，面向 Boss（实时跟随）
    task.spawn(function()
        while myGen == gen and boss and boss.Parent do
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
        while myGen == gen do
            firePunch()
            task.wait(0.05)
        end
    end)

    --// 4. 等待：Boss 消失 或 角色死亡
    while boss and boss.Parent do
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
    if bossGone and not findBoss() and (os.clock() - lastRewardT > 10) then
        lastRewardT = os.clock()
        task.wait(0.5)
        doReward()
    end

    task.wait(0.3)
end