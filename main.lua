--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
    (UI Version - Bản Chống Tràn UI + Fix Diệt Quái Enemys)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Settings = {
    ThemeColor = Color3.fromRGB(138, 43, 226),
    ConfigFile = "InstantKill_SaveState.json"
}

-- ==================== HỆ THỐNG LƯU/TẢI TRẠNG THÁI ====================
local function SaveState(state)
    if writefile then
        local data = { InstantKillActive = state }
        writefile(Settings.ConfigFile, HttpService:JSONEncode(data))
    end
end

local function LoadState()
    if isfile and isfile(Settings.ConfigFile) and readfile then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(Settings.ConfigFile))
        end)
        if success and type(data) == "table" then
            return data.InstantKillActive or false
        end
    end
    return false
end

local SavedToggleState = LoadState()

-- ==================== TỰ ĐỘNG MỞ LẠI KHI TELEPORT ====================
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    local TeleportCode = [[
        task.wait(2)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/haurtabum-sys/my-studies-project/refs/heads/main/main.lua"))()
    ]]
    queue_on_teleport(TeleportCode)
end

-- ==================== CHỨC NĂNG INSTANT KILL (NHẮM VÀO ENEMYS) ====================
local function StartInstantKill(state)
    _G.InstantKill = state
    SaveState(state)

    if state then
        task.spawn(function()
            local player = Players.LocalPlayer
            while _G.InstantKill do
                -- 1. Diệt người chơi khác
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local hum = otherPlayer.Character:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            hum.Health = 0
                        end
                    end
                end

                -- 2. Diệt quái trong thư mục Enemys (Tìm Humanoid ở mọi lớp bên trong)
                local folder = game:GetService("Workspace"):FindFirstChild("Enemys")
                if folder then
                    for _, obj in pairs(folder:GetDescendants()) do
                        if obj:IsA("Humanoid") and obj.Health > 0 then
                            obj.Health = 0
                        end
                    end
                end
                task.wait(0.1) -- Tốc độ diệt ổn định
            end
        end)
    end
end

-- ==================== THƯ VIỆN UI ====================
local FluxLib = { Theme = { Primary = Settings.ThemeColor, Secondary = Color3.fromRGB(30, 30, 30), Background = Color3.fromRGB(20, 20, 20), Text = Color3.fromRGB(255, 255, 255) }, Tabs = {}, Gui = nil }

function FluxLib:CreateWindow(title)
    -- CHỐNG TRÀN UI: Xóa mọi UI cũ có cùng tên trước khi tạo mới
    for _, old in pairs(PlayerGui:GetChildren()) do
        if old.Name == "FluxHubLite" then
            old:Destroy()
        end
    end

    local screenGui = Instance.new("ScreenGui", PlayerGui)
    screenGui.Name = "FluxHubLite"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 400, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
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
        SaveState(false)
    end)
    
    local contentContainer = Instance.new("Frame", mainFrame)
    contentContainer.Size = UDim2.new(1, -20, 1, -50)
    contentContainer.Position = UDim2.new(0, 10, 0, 45)
    contentContainer.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout", contentContainer)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    
    self.Gui = {ScreenGui = screenGui, ContentContainer = contentContainer}
    return self
end

function FluxLib:CreateToggle(name, default, callback)
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

-- ==================== KHỞI TẠO UI ====================
local function CreateUI()
    local Window = FluxLib:CreateWindow("🔥 Instant Kill Hub")
    
    FluxLib:CreateToggle("Bật Instant Kill (Anti-Stack UI)", SavedToggleState, function(v) 
        StartInstantKill(v) 
    end)
end

-- Đảm bảo chỉ chạy 1 UI duy nhất
CreateUI()
