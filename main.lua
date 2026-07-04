--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
    (UI Version - Bản Cao Cấp: Thêm Slider Khoảng Cách + Tự Động Lưu Trạng Thái)
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

local Settings = {
    ThemeColor = Color3.fromRGB(138, 43, 226),
    ConfigFile = "InstantKill_SaveState.json"
}

-- Mặc định ban đầu nếu chưa có file lưu
_G.InstantKill = false
_G.KillDistance = 1000 -- 1000 tương đương với Toàn Map

-- ==================== HỆ THỐNG LƯU/TẢI TRẠNG THÁI (LƯU CẢ SLIDER) ====================
local function SaveState()
    if writefile then
        local data = { 
            InstantKillActive = _G.InstantKill,
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
            _G.KillDistance = data.KillDistance or 1000
            return
        end
    end
end

LoadState() -- Tải dữ liệu cũ ngay khi vừa chạy script

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

-- Hàm hỗ trợ tìm vị trí chính xác của Quái/NPC để tính khoảng cách (Chống lỗi giấu Part)
local function getTargetPosition(obj)
    local parent = obj.Parent
    if parent then
        local part = parent:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
        -- Quét sâu hơn nếu bị giấu trong folder Character phụ
        for _, desc in pairs(parent:GetDescendants()) do
            if desc:IsA("BasePart") then
                return desc.Position
            end
        end
    end
    return nil
end

-- ==================== CHỨC NĂNG INSTANT KILL (QUÉT KHOẢNG CÁCH) ====================
local function StartInstantKill(state)
    _G.InstantKill = state
    SaveState() -- Lưu lại trạng thái nút bật/tắt

    if state then
        task.spawn(function()
            local player = Players.LocalPlayer
            while _G.InstantKill do
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local playerPos = root and root.Position

                -- 1. Tiêu diệt người chơi khác
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local hum = otherPlayer.Character:FindFirstChild("Humanoid")
                        local tRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 then
                            if _G.KillDistance >= 1000 then -- Nếu chỉnh max (Toàn map)
                                hum.Health = 0
                            elseif playerPos and tRoot and (playerPos - tRoot.Position).Magnitude <= _G.KillDistance then
                                hum.Health = 0
                            end
                        end
                    end
                end

                -- 2. Tiêu diệt quái trong mục Enemys theo khoảng cách cài đặt
                local folder = game:GetService("Workspace"):FindFirstChild("Enemys")
                if folder then
                    for _, obj in pairs(folder:GetDescendants()) do
                        if obj:IsA("Humanoid") and obj.Health > 0 then
                            if _G.KillDistance >= 1000 then -- Nếu chỉnh max (Toàn map)
                                obj.Health = 0
                            else
                                local mobPos = getTargetPosition(obj)
                                if playerPos and mobPos and (playerPos - mobPos).Magnitude <= _G.KillDistance then
                                    obj.Health = 0
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

-- ==================== THƯ VIỆN UI (FLUXLIB NÂNG CẤP) ====================
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
    mainFrame.Size = UDim2.new(0, 400, 0, 280) -- Tăng chiều cao để vừa khít cả Slider
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
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
    label.Size = UDim2.new(0.7, 0, 1, 0)
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
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and self.Theme.Primary or Color3.fromRGB(50, 50, 50)
        toggle.Text = state and "ON" or "OFF"
        pcall(function() callback(state) end)
    end)
    pcall(function() callback(default) end)
    return frame
end

-- HÀM TẠO THANH KÉO (SLIDER) MỚI
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
    valueLabel.Position = UDim2.new(1, -130, 0, 4)
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
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(0, 3)

    local sliderFill = Instance.new("Frame", sliderTrack)
    sliderFill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    sliderFill.BackgroundColor3 = self.Theme.Primary
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
        -- Khởi tạo nút gạt On/Off
        FluxLib:CreateToggle("Bật / Tắt Instant Kill", _G.InstantKill, function(v) 
            StartInstantKill(v) 
        end)
        
        -- Khởi tạo thanh kéo khoảng cách (Lưu giá trị vào _G.KillDistance)
        FluxLib:CreateSlider("Khoảng cách diệt quái", 0, 1000, _G.KillDistance, function(value)
            _G.KillDistance = value
            SaveState() -- Mỗi lần kéo sẽ tự động lưu lại khoảng cách mới
        end)
        
        -- Kích hoạt lại vòng lặp nếu trạng thái cũ đang là ON
        if _G.InstantKill then
            StartInstantKill(true)
        end
    end
end

CreateUI()
