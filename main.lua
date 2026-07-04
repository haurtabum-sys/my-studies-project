--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
    (UI Version - Bản Tối Thượng: Thêm Force Kill Boss, Fix Slider, Quét NPCS)
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

_G.InstantKill = false
_G.KillDistance = 1000 -- 1000 = Toàn Map

-- ==================== HỆ THỐNG LƯU/TẢI TRẠNG THÁI ====================
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

-- ==================== HÀM ÉP TỬ (TRỊ BOSS LÌ LỢM) ====================
local function ForceKill(hum)
    if hum and hum.Health > 0 then
        pcall(function()
            -- Cách 1: Set máu trực tiếp
            hum.Health = 0
            -- Cách 2: Gây sát thương chuẩn phòng hờ
            hum:TakeDamage(999999999)
            
            -- Cách 3: Phá vỡ hệ thống máu riêng (nếu có)
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

-- ==================== CHỨC NĂNG INSTANT KILL ====================
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

                -- 1. Giết người chơi khác
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

                -- 2. Giết quái trong mục Enemys và cả NPCS
                local foldersToScan = {"Enemys", "NPCS"}
                for _, folderName in ipairs(foldersToScan) do
                    local folder = game:GetService("Workspace"):FindFirstChild(folderName)
                    if folder then
                        for _, obj in pairs(folder:GetDescendants()) do
                            if obj:IsA("Humanoid") and obj.Health > 0 then
                                -- Đảm bảo không tự giết nhầm NPC thân thiện nếu nó thuộc
