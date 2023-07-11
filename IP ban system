-- Configuration
local ADMIN_IDS = {123456, 789012} -- Replace with the IDs of authorized administrators/moderators

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local banDataStore = DataStoreService:GetDataStore("BanDataStore")

-- Ban Command
local function banPlayer(targetPlayer, adminPlayer)
    local targetIpAddress = targetPlayer.IPAddress
    local targetName = targetPlayer.Name

    -- Store the banned IP address in the database
    local success, error = pcall(function()
        banDataStore:SetAsync(targetIpAddress, true)
    end)
    if success then
        print("Player " .. targetName .. " with IP " .. targetIpAddress .. " has been banned.")
        targetPlayer:Kick("You have been banned from this game.")
    else
        warn("Failed to ban player: " .. error)
    end
end

local function onPlayerChatted(player, message)
    if not table.find(ADMIN_IDS, player.UserId) then
        return
    end

    local command, targetName = message:match("^/ban%s+(%w+)%s*(%w*)$")
    if command == "ban" then
        local targetPlayer = nil

        if targetName ~= "" then
            targetPlayer = Players:FindFirstChild(targetName)
        else
            targetPlayer = player:GetMouse().Target
            if targetPlayer and targetPlayer:IsA("BasePart") then
                targetPlayer = Players:GetPlayerFromCharacter(targetPlayer.Parent)
            end
        end

        if targetPlayer then
            banPlayer(targetPlayer, player)
        else
            player:Kick("Player not found.")
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    -- Retrieve player's IP address
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = "https://api.ipify.org?format=json",
            Method = "GET"
        })
    end)

    if success and result.StatusCode == 200 then
        local data = HttpService:JSONDecode(result.Body)
        player.IPAddress = data.ip
    else
        player:Kick("Failed to retrieve IP address. Please rejoin the game.")
        return
    end

    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)

    -- Check if the player's IP address is banned
    local isBanned = banDataStore:GetAsync(player.IPAddress)
    if isBanned then
        player:Kick("You are banned from this game.")
    end
end)
