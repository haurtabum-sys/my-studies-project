--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
    (UI Version - Bản Tối Thượng VIP: Bẻ khóa Camera bằng Hardware Keypress)
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

local Settings = {
    ThemeColor = Color3.fromRGB(138, 43, 226),
    ConfigFile = "InstantKill_SaveState.json"
}

_G.InstantKill = false
_G.AutoAttack = false
_G.AutoTeleport = false
_G.AutoSkill = false
_G.AutoTransform = false
_G.AutoShiftlock = false
_G.Noclip = false
_G.KillDistance = 1000 

-- ==================== HỆ THỐNG GIẢ LẬP BẤM PHÍM ====================
-- Hàm này dành cho Skill (Z,X,C,V,T) vì game nhận phím ảo bình thường
local function PressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- Hàm ĐẶC BIỆT dành riêng cho Shiftlock (Dùng phần cứng để ép Roblox phải nhận)
local function ToggleNativeShiftlock()
    pcall(function()
        if keypress and keyrelease then
            -- 0xA1 là mã Hex của phím Right Shift trên bàn phím vật lý
            keypress(0xA1) 
            task.wait(0.05)
            keyrelease(0xA1)
        else
            -- Backup nếu trình chạy script của bạn không hỗ trợ lệnh keypress
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
        end
    end)
end

-- ==================== HỆ THỐNG LƯU/TẢI TRẠNG THÁI ====================
local function SaveState()
    if writefile then
        local data = { 
            InstantKillActive = _G.InstantKill,
            AutoAttackActive = _G.AutoAttack,
            AutoTeleportActive = _G.AutoTeleport,
            AutoSkillActive = _G.AutoSkill,
            AutoTransformActive = _G.AutoTransform,
            AutoShiftlockActive = _G.AutoShiftlock,
            NoclipActive = _G.Noclip,
            KillDistance = _G.KillDistance
        }
        writefile(Settings.ConfigFile, HttpService:JSONEncode(data))
    end
end

local function LoadState()
    if isfile and isfile(Settings.ConfigFile) and readfile then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(Settings.ConfigFile))
        end)
        if success and type(data) == "table" then
            _G.InstantKill = data.InstantKillActive or false
            _G.AutoAttack = data.AutoAttackActive or false
            _G.AutoTeleport = data.AutoTeleportActive or false
            _G.AutoSkill = data.AutoSkillActive or false
            _G.AutoTransform = data.AutoTransformActive or false
            _G.AutoShiftlock = data.AutoShiftlockActive or false
            _G.Noclip = data.NoclipActive or false
            _G.KillDistance = tonumber(data.KillDistance) or 1000
            return
        end
    end
end

LoadState()

-- ==================== TỰ ĐỘNG MỞ LẠI KHI TELEPORT ====================
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    local TeleportCode = [[
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(3)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/haurtabum-sys/my-studies-project/refs/heads/main/main.lua"))()
    ]]
    queue_on_teleport(TeleportCode)
end

-- ==================== HÀM HỖ TRỢ CHUNG ====================
local function ForceKill(hum)
    if hum and hum.Health > 0 then
        pcall(function()
            hum.Health = 0
            hum:TakeDamage(999999999)
            local char = hum.Parent
            if char then
                char:SetAttribute("Health", 0)
            end
        end)
    end
end

local function getTargetPosition(obj)
    local parent = obj.Parent
    if parent then
        local part = parent:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
        for _, desc in pairs(parent:GetDescendants()) do
            if desc:IsA("BasePart") then
                return desc.Position
            end
        end
    end
    return nil
end

local function GetClosestTarget()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closestDist = math.huge
    local closestPos = nil

    local foldersToScan = {"Enemys", "NPCS"}
    for _, folderName in ipairs(foldersToScan) do
        local folder = game:GetService("Workspace"):FindFirstChild(folderName)
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("Humanoid") and obj.Health > 0 then
                    if not obj:IsDescendantOf(char) then
                        local tPos = getTargetPosition(obj)
                        if tPos then
                            local dist = (root.Position - tPos).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closestPos = tPos
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPos
end

-- ==================== CÁC VÒNG LẶP CHỨC NĂNG ====================
local function StartInstantKill(state)
    _G.InstantKill = state
    SaveState()

    if state then
        task.spawn(function()
            local player = Players.LocalPlayer
            while _G.InstantKill do
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local playerPos = root and root.Position

                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local hum = otherPlayer.Character:FindFirstChild("Humanoid")
                        local tRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 then
                            if _G.KillDistance >= 1000 then
                                ForceKill(hum)
                            elseif playerPos and tRoot and (playerPos - tRoot.Position).Magnitude <= _G.KillDistance then
                                ForceKill(hum)
                            end
                        end
                    end
                end

                local foldersToScan = {"Enemys", "NPCS"}
                for _, folderName in ipairs(foldersToScan) do
                    local folder = game:GetService("Workspace"):FindFirstChild(folderName)
                    if folder then
                        for _, obj in pairs(folder:GetDescendants()) do
                            if obj:IsA("Humanoid") and obj.Health > 0 then
                                if not char or not obj:IsDescendantOf(char) then
                                    if _G.KillDistance >= 1000 then
                                        ForceKill(obj)
                                    else
                                        local mobPos = getTargetPosition(obj)
                                        if playerPos and mobPos and (playerPos - mobPos).Magnitude <= _G.KillDistance then
                                            ForceKill(obj)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.05) 
            end
        end)
    end
end

local function StartAutoAttack(state)
    _G.AutoAttack = state
    SaveState()
    
    if state then
        task.spawn(function()
            while _G.AutoAttack do
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new())
                
                local char = Players.LocalPlayer.Character
                if char then
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    if equippedTool then
                        equippedTool:Activate()
                    end
                end
                task.wait(0.05)
            end
        end)
    end
end

local function StartAutoTeleport(state)
    _G.AutoTeleport = state
    SaveState()
    
    if state then
        task.spawn(function()
            while _G.AutoTeleport do
                local char = Players.LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root then
                    local targetPos = GetClosestTarget()
                    if targetPos then
                        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0), targetPos)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

local function StartAutoSkill(state)
    _G.AutoSkill = state
    SaveState()
    
    if state then
        task.spawn(function()
            local skillKeys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
            while _G.AutoSkill do
                for _, key in ipairs(skillKeys) do
                    if not _G.AutoSkill then break end
                    PressKey(key)
                    task.wait(0.15) 
                end
                task.wait(0.1)
            end
        end)
    end
end

local function StartAutoTransform(state)
    _G.AutoTransform = state
    SaveState()
    
    if state then
        task.spawn(function()
            while _G.AutoTransform do
                PressKey(Enum.KeyCode.T)
                task.wait(1.5) 
            end
        end)
    end
end

local function StartAutoShiftlock(state)
    _G.AutoShiftlock = state
    SaveState()
    -- Gọi lệnh bấm Hardware
    ToggleNativeShiftlock()
end

local NoclipConnection
local function StartNoclip(state)
    _G.Noclip = state
    SaveState()
    
    if state then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                if _G.Noclip then
                    local char = Players.LocalPlayer.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
    end
end

-- ==================== HỆ THỐNG PHÍM TẮT (HOTKEYS) ====================
UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then return end 

    if input.KeyCode == Enum.KeyCode.J then
        if _G.ToggleShiftlockUI then
            _G.ToggleShiftlockUI(not _G.AutoShiftlock)
        else
            _G.AutoShiftlock = not _G.AutoShiftlock
            StartAutoShiftlock(_G.AutoShiftlock)
        end
    end
end)

-- ==================== THƯ VIỆN UI ====================
local FluxLib = { Theme = { Primary = Settings.ThemeColor, Secondary = Color3.fromRGB(30, 30, 30), Background = Color3.fromRGB(20, 20, 20), Text = Color3.fromRGB(255, 255, 255) }, Tabs = {}, Gui = nil }

function FluxLib:CreateWindow(title)
    if not PlayerGui then return nil end
    for _, old in pairs(PlayerGui:GetChildren()) do
        if old.Name == "FluxHubLite" then old:Destroy() end
    end

    local screenGui = Instance.new("ScreenGui", PlayerGui)
    screenGui.Name = "FluxHubLite"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 400, 0, 580)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -290)
    mainFrame.BackgroundColor3 = self.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = self.Theme.Primary
    stroke.Thickness = 2
    
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = self.Theme.Secondary
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
    
    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeButton = Instance.new("TextButton", titleBar)
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -40, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.MouseButton1Click:Connect(function() 
        screenGui:Destroy() 
        self.Gui = nil 
        _G.InstantKill = false 
        _G.AutoAttack = false
        _G.AutoTeleport = false
        _G.AutoSkill = false
        _G.AutoTransform = false
        _G.AutoShiftlock = false
        _G.Noclip = false
        _G.ToggleShiftlockUI = nil
        StartNoclip(false)
        -- Tắt an toàn
        if _G.AutoShiftlock then ToggleNativeShiftlock() end
        SaveState()
    end)
    
    local contentContainer = Instance.new("Frame", mainFrame)
    contentContainer.Size = UDim2.new(1, -20, 1, -50)
    contentContainer.Position = UDim2.new(0, 10, 0, 45)
    contentContainer.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout", contentContainer)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    
    self.Gui = {ScreenGui = screenGui, ContentContainer = contentContainer}
    return self
end

function FluxLib:CreateToggle(name, default, callback)
    if not self.Gui then return nil end
    local frame = Instance.new("Frame", self.Gui.ContentContainer)
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = self.Theme.Secondary
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0, 50, 0, 26)
    toggle.Position = UDim2.new(1, -60, 0.5, -13)
    toggle.BackgroundColor3 = default and self.Theme.Primary or Color3.fromRGB(50, 50, 50)
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)
    
    local state = default

    local function UpdateToggle(newState)
        state = newState
        toggle.BackgroundColor3 = state and self.Theme.Primary or Color3.fromRGB(50, 50, 50)
        toggle.Text = state and "ON" or "OFF"
        pcall(function() callback(state) end)
    end

    toggle.MouseButton1Click:Connect(function()
        UpdateToggle(not state)
    end)
    pcall(function() callback(default) end)

    return { SetState = UpdateToggle }
end

function FluxLib:CreateSlider(name, min, max, default, callback)
    if not self.Gui then return nil end
    local frame = Instance.new("Frame", self.Gui.ContentContainer)
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundColor3 = self.Theme.Secondary
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
    valueLabel.Position = UDim2.new(1, -120, 0, 4) 
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = (default >= max) and "Toàn map" or tostring(math.floor(default))
    valueLabel.TextColor3 = self.Theme.Primary
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderTrack = Instance.new("TextButton", frame)
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 0, 38)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderTrack.Text = ""
    sliderTrack.AutoButtonColor = false
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(0, 3)

    local sliderFill = Instance.new("Frame", sliderTrack)
    sliderFill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    sliderFill.BackgroundColor3 = self.Theme.Primary
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

    local isDragging = false

    local function UpdateSlider(input)
        local mousePos = input.Position.X
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackWidth = sliderTrack.AbsoluteSize.X
        local percentage = math.clamp((mousePos - trackPos) / trackWidth, 0, 1)
        
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        local rawValue = min + (percentage * (max - min))
        local finalValue = math.floor(rawValue)
        
        if finalValue >= max then
            valueLabel.Text = "Toàn map"
        else
            valueLabel.Text = tostring(finalValue)
        end
        
        pcall(function() callback(finalValue) end)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    pcall(function() callback(default) end)
    return frame
end

-- ==================== KHỞI TẠO UI ====================
local function CreateUI()
    local Window = FluxLib:CreateWindow("🔥 Instant Kill Hub")
    if Window then
        FluxLib:CreateToggle("Bật / Tắt Instant Kill", _G.InstantKill, function(v) 
            StartInstantKill(v) 
        end)
        
        FluxLib:CreateToggle("Bật / Tắt Auto Attack", _G.AutoAttack, function(v) 
            StartAutoAttack(v) 
        end)
        
        FluxLib:CreateToggle("Bật / Tắt Tự Động Bay Lại Boss", _G.AutoTeleport, function(v) 
            StartAutoTeleport(v) 
        end)

        FluxLib:CreateToggle("Bật / Tắt Auto Skill (Z, X, C, V)", _G.AutoSkill, function(v) 
            StartAutoSkill(v) 
        end)

        FluxLib:CreateToggle("Bật / Tắt Auto Biến Hình (T)", _G.AutoTransform, function(v) 
            StartAutoTransform(v) 
        end)
        
        local shiftlockBtn = FluxLib:CreateToggle("Bật / Tắt Auto Shiftlock (Phím tắt: J)", _G.AutoShiftlock, function(v) 
            StartAutoShiftlock(v) 
        end)
        if shiftlockBtn then
            _G.ToggleShiftlockUI = shiftlockBtn.SetState
        end
        
        FluxLib:CreateToggle("Bật / Tắt Noclip (Xuyên Tường)", _G.Noclip, function(v) 
            StartNoclip(v) 
        end)
        
        FluxLib:CreateSlider("Khoảng cách diệt quái", 0, 1000, _G.KillDistance, function(value)
            _G.KillDistance = value
            SaveState()
        end)
        
        if _G.InstantKill then StartInstantKill(true) end
        if _G.AutoAttack then StartAutoAttack(true) end
        if _G.AutoTeleport then StartAutoTeleport(true) end
        if _G.AutoSkill then StartAutoSkill(true) end
        if _G.AutoTransform then StartAutoTransform(true) end
        if _G.Noclip then StartNoclip(true) end
    end
end

CreateUI()
