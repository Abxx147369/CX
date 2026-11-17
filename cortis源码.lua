-- ═══════════════════════════════════════════════
-- CX UI - 绝对不报错终极版 (回归原生 + 全功能)
-- ═══════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local player = Players.LocalPlayer
player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

-- ==========================================
-- 🪟 1. 创建基础 UI (原生设置，纯黑半透明，不破坏底层)
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "<font color='#6a11cb'>cortis</font>", 
    Author = "CX特别版", 
    Folder = "QWHub",
    Size = UDim2.fromOffset(600, 300), 
    Transparent = true, 
    Theme = "Dark", 
    Background = "", 
    BackgroundImageTransparency = 1, 
    User = { Enabled = false },
})

local HomeTab = Window:Tab({ Title = "主页", Icon = "home" })
local WorkoutTab = Window:Tab({ Title = "锻炼", Icon = "dumbbell" })
local RebirthTab = Window:Tab({ Title = "重生", Icon = "refresh-cw" })
local BossTab1 = Window:Tab({ Title = "纯击杀", Icon = "skull" })
local BossTab2 = Window:Tab({ Title = "换包+Boss", Icon = "shield" })
local BossTab3 = Window:Tab({ Title = "锻炼+Boss", Icon = "zap" })
local OtherTab = Window:Tab({ Title = "其他", Icon = "menu" })

HomeTab:Paragraph({ Title = "欢迎使用 cortis", Desc = "CX公会欢迎您", Image = "smile" })

local function BurstRep(muscleEvent)
    if not muscleEvent then return end
    pcall(function() 
        local pingMs = player:GetNetworkPing() * 1000
        local rate = (pingMs <= 0 or pingMs >= 30) and 300 or 150
        for i = 1, math.floor(rate / 60) do muscleEvent:FireServer("rep") end
    end)
end

-- ==========================================
-- 📊 2. 数据统计面板
-- ==========================================
HomeTab:Section({ Title = "数据面板" })
HomeTab:Button({
    Title = "打开数据统计", Desc = "查看力量、重生、耐力等实时变化",
    Callback = function()
        local pGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        if pGui:FindFirstChild("PlayerStatWatcherFinal") then return end
        local CONFIG = { Stats = { { Name = "力量", Color = Color3.fromRGB(100, 200, 255), Paths = { "leaderstats/Strength" } }, { Name = "重生", Color = Color3.fromRGB(255, 200, 100), Paths = { "leaderstats/Rebirths" } }, { Name = "耐力", Color = Color3.fromRGB(120, 235, 160), Paths = { "Durability", "Quests/Weekly Quests/Full Body Workout/requirements/Durability" } } } }
        local LP = Players.LocalPlayer; local isFormatEnabled = true; local suffixesList = { {1e21, "Sx"}, {1e18, "Qi"}, {1e15, "Qa"}, {1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"} }
        local function formatNumber(num) if num == 0 then return "0" end; local isNeg = false; if num < 0 then isNeg = true; num = -num end; local res = ""; if isFormatEnabled then for _, data in ipairs(suffixesList) do if num >= data[1] then res = string.format("%.2f", num / data[1]):gsub("%.00$", ""):gsub("%.0$", "") .. data[2]; break end end; if res == "" then res = tostring(math.floor(num)) end else res = string.format("%.0f", num) end; if isNeg then res = "-" .. res end; return res end
        local function resolvePaths(paths) for _, pathStr in ipairs(paths) do local node = LP; for _, part in ipairs(string.split(pathStr, "/")) do if not node then break end; node = node:FindFirstChild(part) end; if node and node:IsA("ValueBase") then return node end end; return nil end
        local panelGui = Instance.new("ScreenGui"); panelGui.Name = "PlayerStatWatcherFinal"; panelGui.ResetOnSpawn = false; panelGui.DisplayOrder = 999; panelGui.IgnoreGuiInset = true; panelGui.Parent = pGui
        local main = Instance.new("Frame"); main.Size = UDim2.fromOffset(230, 145); main.Position = UDim2.fromOffset(10, 60); main.BackgroundColor3 = Color3.fromRGB(10, 10, 10); main.BackgroundTransparency = 0.4; main.BorderSizePixel = 0; main.Active = true; main.Draggable = true; main.ClipsDescendants = true; main.Parent = panelGui
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = main
        local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(60, 60, 85); stroke.Thickness = 1; stroke.ZIndex = 3; stroke.Parent = main
        local function addStroke(label) local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0, 0, 0); s.Thickness = 1.5; s.Transparency = 0.3; s.Parent = label end
        local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -36, 0, 18); title.Position = UDim2.fromOffset(8, 4); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = 11; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "收益统计 (极简)"; title.ZIndex = 3; title.Parent = main; addStroke(title)
        local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.fromOffset(20, 20); closeBtn.Position = UDim2.new(1, -24, 0, 2); closeBtn.BackgroundTransparency = 1; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.Text = "✖"; closeBtn.ZIndex = 3; closeBtn.Parent = main; addStroke(closeBtn)
        local line = Instance.new("Frame"); line.Size = UDim2.new(1, -16, 0, 1); line.Position = UDim2.fromOffset(8, 24); line.BackgroundColor3 = Color3.fromRGB(150, 150, 180); line.BackgroundTransparency = 0.5; line.BorderSizePixel = 0; line.ZIndex = 3; line.Parent = main
        local rowsContainer = Instance.new("Frame"); rowsContainer.Size = UDim2.new(1, -16, 1, -48); rowsContainer.Position = UDim2.fromOffset(8, 26); rowsContainer.BackgroundTransparency = 1; rowsContainer.ZIndex = 3; rowsContainer.Parent = main
        local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 4); listLayout.Parent = rowsContainer
        local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(0.5, 0, 0, 16); statusLabel.Position = UDim2.new(0, 8, 1, -20); statusLabel.BackgroundTransparency = 1; statusLabel.Font = Enum.Font.GothamBold; statusLabel.TextSize = 10; statusLabel.TextColor3 = Color3.fromRGB(220, 220, 230); statusLabel.TextXAlignment = Enum.TextXAlignment.Left; statusLabel.Text = "○ 扫描中..."; statusLabel.ZIndex = 3; statusLabel.Parent = main; addStroke(statusLabel)
        local toggleBtn = Instance.new("TextButton"); toggleBtn.Size = UDim2.new(0, 60, 0, 18); toggleBtn.Position = UDim2.new(1, -68, 1, -20); toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 45); toggleBtn.BackgroundTransparency = 0.2; toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 10; toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); toggleBtn.Text = "格式化: 开"; toggleBtn.ZIndex = 3; toggleBtn.Parent = main
        local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 4); btnCorner.Parent = toggleBtn
        local uiRows = {}
        for i, statData in ipairs(CONFIG.Stats) do
            local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundTransparency = 1; row.ZIndex = 3
            local nameLbl = Instance.new("TextLabel"); nameLbl.Size = UDim2.new(0.3, 0, 0, 14); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 10; nameLbl.TextColor3 = statData.Color; nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Text = statData.Name; nameLbl.ZIndex = 3; nameLbl.Parent = row; addStroke(nameLbl)
            local valLbl = Instance.new("TextLabel"); valLbl.Size = UDim2.new(0.7, 0, 0, 14); valLbl.Position = UDim2.new(0.3, 0, 0, 0); valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.Code; valLbl.TextSize = 11; valLbl.TextColor3 = Color3.fromRGB(255, 255, 255); valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = "--"; valLbl.TextTruncate = Enum.TextTruncate.AtEnd; valLbl.ZIndex = 3; valLbl.Parent = row; addStroke(valLbl)
            local diffLbl = Instance.new("TextLabel"); diffLbl.Size = UDim2.new(0.35, 0, 0, 14); diffLbl.Position = UDim2.new(0, 0, 0, 15); diffLbl.BackgroundTransparency = 1; diffLbl.Font = Enum.Font.Code; diffLbl.TextSize = 9; diffLbl.TextColor3 = Color3.fromRGB(150, 255, 190); diffLbl.TextXAlignment = Enum.TextXAlignment.Left; diffLbl.Text = "获:+0"; diffLbl.TextTruncate = Enum.TextTruncate.AtEnd; diffLbl.ZIndex = 3; diffLbl.Parent = row; addStroke(diffLbl)
            local rateDayLbl = Instance.new("TextLabel"); rateDayLbl.Size = UDim2.new(0.35, 0, 0, 14); rateDayLbl.Position = UDim2.new(0.35, 0, 0, 15); rateDayLbl.BackgroundTransparency = 1; rateDayLbl.Font = Enum.Font.Code; rateDayLbl.TextSize = 9; rateDayLbl.TextColor3 = Color3.fromRGB(255, 210, 130); rateDayLbl.TextXAlignment = Enum.TextXAlignment.Center; rateDayLbl.Text = "天:+0"; rateDayLbl.TextTruncate = Enum.TextTruncate.AtEnd; rateDayLbl.ZIndex = 3; rateDayLbl.Parent = row; addStroke(rateDayLbl)
            local rateWeekLbl = Instance.new("TextLabel"); rateWeekLbl.Size = UDim2.new(0.3, 0, 0, 14); rateWeekLbl.Position = UDim2.new(0.7, 0, 0, 15); rateWeekLbl.BackgroundTransparency = 1; rateWeekLbl.Font = Enum.Font.Code; rateWeekLbl.TextSize = 9; rateWeekLbl.TextColor3 = Color3.fromRGB(180, 220, 255); rateWeekLbl.TextXAlignment = Enum.TextXAlignment.Right; rateWeekLbl.Text = "周:+0"; rateWeekLbl.TextTruncate = Enum.TextTruncate.AtEnd; rateWeekLbl.ZIndex = 3; rateWeekLbl.Parent = row; addStroke(rateWeekLbl)
            row.Parent = rowsContainer
            uiRows[i] = { Val = valLbl, Diff = diffLbl, RateDay = rateDayLbl, RateWeek = rateWeekLbl, StartTime = os.clock(), TotalGain = 0, LastVal = 0, LastRateDay = 0, LastRateWeek = 0, ConnectedObj = nil, Conn = nil }
        end
        local function updateRowText(ui) if not ui or not ui.Val then return end; ui.Val.Text = formatNumber(ui.LastVal); ui.Diff.Text = "获:+" .. formatNumber(ui.TotalGain); ui.RateDay.Text = "天:+" .. formatNumber(ui.LastRateDay); ui.RateWeek.Text = "周:+" .. formatNumber(ui.LastRateWeek) end
        toggleBtn.MouseButton1Click:Connect(function() isFormatEnabled = not isFormatEnabled; toggleBtn.Text = isFormatEnabled and "格式化: 开" or "格式化: 关"; toggleBtn.BackgroundColor3 = isFormatEnabled and Color3.fromRGB(40, 60, 45) or Color3.fromRGB(60, 40, 40); for _, ui in pairs(uiRows) do if ui.ConnectedObj then updateRowText(ui) end end end)
        local isRunning = true; closeBtn.MouseButton1Click:Connect(function() isRunning = false; for _, ui in pairs(uiRows) do if ui.Conn then ui.Conn:Disconnect() end end; panelGui:Destroy() end)
        task.spawn(function()
            while isRunning do
                local activeCount = 0
                for i, statData in ipairs(CONFIG.Stats) do
                    local ui = uiRows[i]; local valueObj = resolvePaths(statData.Paths)
                    if valueObj then
                        activeCount = activeCount + 1
                        if ui.ConnectedObj ~= valueObj then
                            if ui.Conn then ui.Conn:Disconnect() end; ui.ConnectedObj = valueObj; ui.LastVal = tonumber(valueObj.Value) or 0; ui.TotalGain = 0; ui.StartTime = os.clock(); ui.LastRateDay = 0; ui.LastRateWeek = 0; updateRowText(ui)
                            ui.Conn = valueObj.Changed:Connect(function(newValue) if not isRunning then return end; local numVal = tonumber(newValue) or 0; if numVal > ui.LastVal then ui.TotalGain = ui.TotalGain + (numVal - ui.LastVal) elseif numVal < ui.LastVal then ui.TotalGain = 0; ui.StartTime = os.clock(); ui.LastRateDay = 0; ui.LastRateWeek = 0 end; ui.LastVal = numVal; updateRowText(ui) end)
                        end
                        local elapsed = os.clock() - ui.StartTime
                        if elapsed > 2 then if ui.TotalGain > 0 then local newRateDay = (ui.TotalGain / elapsed) * 86400; local newRateWeek = newRateDay * 7; if ui.LastRateDay == 0 or math.abs(newRateDay - ui.LastRateDay) > (ui.LastRateDay * 0.01) then ui.LastRateDay = newRateDay; ui.LastRateWeek = newRateWeek; updateRowText(ui) end else if ui.LastRateDay ~= 0 then ui.LastRateDay = 0; ui.LastRateWeek = 0; updateRowText(ui) end end end
                    else
                        if ui.ConnectedObj then if ui.Conn then ui.Conn:Disconnect() end; ui.ConnectedObj = nil; ui.Val.Text = "未找到"; ui.Diff.Text = ""; ui.RateDay.Text = ""; ui.RateWeek.Text = "" end
                    end
                end
                statusLabel.Text = (activeCount > 0) and string.format("● 运行中 (%d/%d)", activeCount, #CONFIG.Stats) or "○ 寻找数据源..."; statusLabel.TextColor3 = (activeCount > 0) and Color3.fromRGB(150, 255, 190) or Color3.fromRGB(255, 210, 130)
                task.wait(0.5) 
            end
        end)
    end
})

-- ==========================================
-- 🏋️‍♂️ 3. 锻炼页
-- ==========================================
WorkoutTab:Section({ Title = "锻炼功能" })
local isAutoWorkoutRunning = false
local fastWorkoutConnection = nil

WorkoutTab:Toggle({ Title = "自动锻炼", Desc = "低频率锻炼", Value = false, Callback = function(state)
    isAutoWorkoutRunning = state
    if state then task.spawn(function() while isAutoWorkoutRunning do pcall(function() player:WaitForChild("muscleEvent", 5):FireServer("rep") end); task.wait(0.005) end end) end
end })

WorkoutTab:Toggle({ Title = "快速锻炼", Desc = "根据Ping值高频发送锻炼信号", Value = false, Callback = function(state)
    if state then
        if not fastWorkoutConnection then
            fastWorkoutConnection = true
            task.spawn(function()
                while fastWorkoutConnection do
                    local ev = player:FindFirstChild("muscleEvent")
                    if ev then BurstRep(ev) end
                    task.wait(0.016)
                end
            end)
        end
    else fastWorkoutConnection = nil end
end })

-- ==========================================
-- 🔄 4. 重生页
-- ==========================================
RebirthTab:Section({ Title = "重生功能" })
local isAutoRebirthRunning = false
RebirthTab:Toggle({ Title = "自动重生", Desc = "每0.1秒自动发送重生请求", Value = false, Callback = function(state)
    isAutoRebirthRunning = state
    if state then task.spawn(function() while isAutoRebirthRunning do pcall(function() local r = ReplicatedStorage:FindFirstChild("rEvents"); local rem = r and r:FindFirstChild("rebirthRemote"); if rem then rem:InvokeServer("rebirthRequest") else isAutoRebirthRunning = false end end); task.wait(0.1) end end) end
end })

local stopSwapRebirth = nil
RebirthTab:Toggle({ 
    Title = "换包重生", Desc = "通过宠物配置来进行\n第一个配置放力量宠物\n第二个配置放重生宠物", Value = false, 
    Callback = function(state)
        if state then
            task.spawn(function()
                if stopSwapRebirth then stopSwapRebirth() end
                local REBIRTH_DELAY, EQUIP_DELAY = 0.2, 0.3
                local pGui = player:FindFirstChild("PlayerGui"); local gui = pGui and pGui:FindFirstChild("gameGui")
                if not gui then return end
                local requiredText = gui:FindFirstChild("rebirthNewMenu") and gui.rebirthNewMenu:FindFirstChild("Content") and gui.rebirthNewMenu.Content:FindFirstChild("TopBG") and gui.rebirthNewMenu.Content.TopBG:FindFirstChild("StrengthRequired")
                local currentText = gui:FindFirstChild("hudNewMenu") and gui.hudNewMenu:FindFirstChild("Top") and gui.hudNewMenu.Top:FindFirstChild("InfoSlots") and gui.hudNewMenu.Top.InfoSlots:FindFirstChild("StrengthSlot") and gui.hudNewMenu.Top.InfoSlots.StrengthSlot:FindFirstChild("Amnt")
                if not requiredText or not currentText then return end
                local rEvents = ReplicatedStorage:FindFirstChild("rEvents"); local loadoutRemote = rEvents and rEvents:FindFirstChild("loadoutRemote"); local rebirthRemote = rEvents and rEvents:FindFirstChild("rebirthRemote"); local muscleEvent = player:FindFirstChild("muscleEvent")
                if not loadoutRemote or not rebirthRemote or not muscleEvent then return end
                local function parseShorthand(str) if not str or str == "" then return 0 end; local numStr, suffix = str:match("([%d%.]+)([%a]*)"); if not numStr then return 0 end; local num = tonumber(numStr) or 0; suffix = string.upper(suffix); local multipliers = { K=1e3, M=1e6, B=1e9, T=1e12, QA=1e15, QI=1e18, SX=1e21, SP=1e24, OC=1e27, NO=1e30, DC=1e33 }; return num * (multipliers[suffix] or 1) end
                local function forceEquipWeight() local char = player.Character; local backpack = player:FindFirstChild("Backpack"); if char and backpack then local weight = backpack:FindFirstChild("Weight"); if weight then local humanoid = char:FindFirstChildOfClass("Humanoid"); if humanoid then pcall(function() humanoid:EquipTool(weight) end) end end end end
                local currentMode, active = "none", true
                local function rebirthLoop() while currentMode == "rebirth" and active do pcall(function() rebirthRemote:InvokeServer("rebirthRequest") end); task.wait(REBIRTH_DELAY) end end
                local function checkStatus() 
                    if not active then return end
                    if parseShorthand(currentText.Text) >= parseShorthand(requiredText.Text) then 
                        if currentMode ~= "rebirth" then 
                            currentMode = "rebirth"
                            task.spawn(function() pcall(function() loadoutRemote:InvokeServer("Equip", { Slot = 2 }) end); task.wait(EQUIP_DELAY); rebirthLoop() end) 
                        end 
                    else 
                        if currentMode ~= "rep" then 
                            currentMode = "rep"
                            task.spawn(function() 
                                pcall(function() loadoutRemote:InvokeServer("Equip", { Slot = 1 }) end); task.wait(0.1)
                                pcall(function() loadoutRemote:InvokeServer("Equip", { Slot = 1 }) end); task.wait(EQUIP_DELAY)
                                while currentMode == "rep" and active do 
                                    forceEquipWeight()
                                    BurstRep(muscleEvent)
                                    task.wait(0.016) 
                                end 
                            end) 
                        end 
                    end 
                end
                local c1 = currentText:GetPropertyChangedSignal("Text"):Connect(checkStatus); local c2 = requiredText:GetPropertyChangedSignal("Text"):Connect(checkStatus); checkStatus()
                stopSwapRebirth = function() active = false; currentMode = "none"; if c1 then c1:Disconnect() end; if c2 then c2:Disconnect() end end
            end)
        else
            if stopSwapRebirth then stopSwapRebirth(); stopSwapRebirth = nil end
        end
    end 
})

-- ==========================================
-- 💀 5. Boss 逻辑
-- ==========================================
local BOSS_HEIGHT = 60
local HOME_POS = Vector3.new(1, 44, -1251)
local global = { fighting = false, bossActive = false, currentBossKey = nil, conn = nil, thread = nil }
local workoutMode = { enabled = false, conn = nil }

local PureBossConfig = { {name="普通",key="Boss1"},{name="稀有",key="Boss2"},{name="史诗",key="Boss3"},{name="传奇",key="Boss4"},{name="神话",key="Boss5"},{name="彩虹",key="BossRainbow"} }
local ComboBossConfig = { {name="普通",key="Boss1"},{name="稀有",key="Boss2"},{name="史诗",key="Boss3"},{name="传奇",key="Boss4"},{name="神话",key="Boss5"},{name="彩虹",key="BossRainbow"} }
local WorkoutBossConfig = { {name="普通",key="Boss1"},{name="稀有",key="Boss2"},{name="史诗",key="Boss3"},{name="传奇",key="Boss4"},{name="神话",key="Boss5"},{name="彩虹",key="BossRainbow"} }

local function getBossHealth(key) local ev = workspace:FindFirstChild("Events"); local arena = ev and ev:FindFirstChild("BossArena"); local folder = arena and arena:FindFirstChild(key); if folder then local stats = folder:FindFirstChild("stats"); local hp = stats and stats:FindFirstChild("Health"); if hp then return hp.Value end end return 0 end
local function getBossPos(key) local ev = workspace:FindFirstChild("Events"); local arena = ev and ev:FindFirstChild("BossArena"); local folder = arena and arena:FindFirstChild(key); local boss = folder and folder:FindFirstChild("Boss"); if boss then if boss:IsA("Model") then return boss:GetPivot().Position elseif boss:IsA("BasePart") then return boss.Position end end return nil end

local function setFighting(on)
    if global.fighting == on then return end; global.fighting = on
    if global.conn then global.conn:Disconnect(); global.conn = nil end; if global.thread then pcall(task.cancel, global.thread); global.thread = nil end
    if not on then return end
    global.conn = RunService.RenderStepped:Connect(function()
        if not global.fighting then return end
        local bp = getBossPos(global.currentBossKey); local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and bp then local target = bp + Vector3.new(0, BOSS_HEIGHT, 0); local flat = Vector3.new(bp.X - target.X, 0, bp.Z - target.Z); if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, -1) end; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; hrp.CFrame = CFrame.lookAt(target, target + flat.Unit) * CFrame.Angles(math.rad(-90), 0, 0) end
    end)
    global.thread = task.spawn(function()
        local ev = player:FindFirstChild("muscleEvent")
        while global.fighting do
            local bp = getBossPos(global.currentBossKey)
            if bp and ev then pcall(function() ev:FireServer("punch", "leftHand") end) end
            task.wait(0.05)
        end
    end)
end

local function clearAllModes()
    for _, c in ipairs(PureBossConfig) do c.uiEnabled = false end
    for _, c in ipairs(ComboBossConfig) do c.uiEnabled = false end
    for _, c in ipairs(WorkoutBossConfig) do c.uiEnabled = false end
    global.bossActive = false; setFighting(false)
    workoutMode.enabled = false; if workoutMode.conn then workoutMode.conn = nil end
end

local function startWorkout()
    if workoutMode.conn then return end
    workoutMode.conn = true
    task.spawn(function() 
        while workoutMode.conn do 
            if not global.fighting then
                local ev = player:FindFirstChild("muscleEvent")
                if ev then BurstRep(ev) end
            end
            task.wait(0.016) 
        end 
    end) 
end

BossTab1:Section({ Title = "纯击杀 Boss" })
for _, c in ipairs(PureBossConfig) do
    BossTab1:Toggle({ Title = c.name, Value = false, Callback = function(s) 
        if s then clearAllModes(); global.bossActive = true; global.currentBossKey = c.key; setFighting(true) end
    end })
end

BossTab2:Section({ Title = "换包重生 + 自动Boss" })
BossTab2:Toggle({ Title = "换包重生", Value = false, Callback = function(s) if s then clearAllModes() end end })
for _, c in ipairs(ComboBossConfig) do
    BossTab2:Toggle({ Title = c.name, Value = false, Callback = function(s) 
        if s then clearAllModes(); global.bossActive = true; global.currentBossKey = c.key; setFighting(true) end
    end })
end

BossTab3:Section({ Title = "快速锻炼 + 自动Boss" })
BossTab3:Toggle({ Title = "快速锻炼", Value = false, Callback = function(s) if s then clearAllModes(); workoutMode.enabled = true; startWorkout() end end })
for _, c in ipairs(WorkoutBossConfig) do
    BossTab3:Toggle({ Title = c.name, Value = false, Callback = function(s) 
        if s then clearAllModes(); global.bossActive = true; global.currentBossKey = c.key; setFighting(true) end
    end })
end

-- ==========================================
-- 🎮 6. 其他页 (补全音乐播放)
-- ==========================================
OtherTab:Section({ Title = "其他功能" })
local isWheelRunning = false
OtherTab:Toggle({ Title = "自动转盘", Desc = "每0.5秒调用一次", Value = false, Callback = function(state)
    isWheelRunning = state
    if state then task.spawn(function() while isWheelRunning do pcall(function() local r = ReplicatedStorage:FindFirstChild("rEvents"); local rem = r and r:FindFirstChild("openFortuneWheelRemote"); local sh = ReplicatedStorage:FindFirstChild("shared"); local w = sh and sh.catalogs and sh.catalogs.fortuneWheelChances and sh.catalogs.fortuneWheelChances:FindFirstChild("Fortune Wheel"); if rem and w then rem:InvokeServer("openFortuneWheel", w) end end); task.wait(0.5) end end) end
end })

local MusicPlayer = Instance.new("Sound")
MusicPlayer.Volume = 0.5
MusicPlayer.Looped = true
MusicPlayer.Parent = SoundService
local currentMusicId = ""

OtherTab:Section({ Title = "背景音乐设置" })
OtherTab:Input({ Title = "输入音乐ID", Desc = "输入纯数字", Placeholder = "例如: 1838867926", Value = "", Callback = function(text) currentMusicId = text end })
OtherTab:Button({ Title = "加载并播放", Callback = function()
    if currentMusicId == "" then return end
    local finalId = tostring(currentMusicId)
    if tonumber(finalId) then finalId = "rbxassetid://" .. finalId end
    MusicPlayer:Stop(); MusicPlayer.SoundId = finalId; MusicPlayer:Play()
end })
OtherTab:Button({ Title = "停止播放", Callback = function() MusicPlayer:Stop() end })
OtherTab:Slider({ Title = "音乐音量", Value = { Min = 0, Max = 10, Default = 5 }, Callback = function(val) MusicPlayer.Volume = val / 10 end })

-- ==========================================
-- 7. 主循环
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if global.bossActive then
            local hp = getBossHealth(global.currentBossKey)
            if hp <= 0 then setFighting(false); global.bossActive = false end
        end
    end
end)

-- 核心：绑定 UI 关闭事件，彻底销毁声音
Window:OnClose(function()
    if MusicPlayer then
        MusicPlayer:Stop()
        MusicPlayer:Destroy()
    end
end)