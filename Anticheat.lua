local allowedGuis = {
    -- List the names of the authorized GUIs here
    "MainMenu",
    "Settings",
    "AdminGUI", -- Add the name of the admin GUI
    -- Add more authorized GUI names as needed
}

local allowedScripts = {
    -- List the names of the authorized scripts here
    "Script1",
    "Script2",
    -- Add more authorized script names as needed
}

local allowedAdminUsers = {
    "Player1", -- Add the usernames of players allowed to use the admin GUI
    "Player2",
    -- Add more usernames as needed
}

local excludedPlayers = {
    "AdminPlayer1", -- Add the usernames of players to be excluded from the GUI check
    "AdminPlayer2",
    "YoutuberPlayer1",
    -- Add more usernames as needed
}

local maxWalkSpeed = 20 -- Maximum allowed walk speed (modify as needed)
local maxFallSpeed = 100 -- Maximum allowed fall speed (modify as needed)
local maxVehicleSpeed = 100 -- Maximum allowed vehicle speed (modify as needed)
local maxOtherSpeed = 100 -- Maximum allowed speed for other properties (modify as needed)
local freezeTime = 10 -- Time in seconds to freeze the player

local positionCheckInterval = 1 -- Time interval for checking player position (in seconds)
local maxPositionChangeThreshold = 200 -- Maximum allowed position change threshold (in studs)
local maxPositionChangeTime = 5 -- Maximum allowed time for position change (in seconds)

local function freezePlayer(player)
    -- Implement the freezing mechanism here
    -- For example, you can disable movement controls or set the player's WalkSpeed to 0
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
    end
end

local function checkSpeed(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.WalkSpeed > maxWalkSpeed then
        freezePlayer(player)
        return
    end

    -- Check fall speed
    if humanoid.FloorMaterial == Enum.Material.Air then
        local velocityY = humanoid:GetVelocity().Y
        if velocityY < -maxFallSpeed then
            freezePlayer(player)
            return
        end
    end

    -- Check other speed properties like vehicle speed, fly speed, etc. here
    -- Implement the appropriate checks and actions based on your game's logic
    -- For example, you can check vehicle speed or fly speed properties and freeze the player accordingly
end

local function isGuiAllowed(guiName, playerRank, playerName)
    if table.find(excludedPlayers, playerName) then
        return true
    end

    for _, allowedGui in ipairs(allowedGuis) do
        if guiName == allowedGui then
            return true
        end
    end
    if guiName == "AdminGUI" and (playerRank and playerRank >= 3) and table.find(allowedAdminUsers, playerName) then
        return true
    end
    return false
end

local function isScriptAllowed(scriptName)
    for _, allowedScript in ipairs(allowedScripts) do
        if scriptName == allowedScript then
            return true
        end
    end
    return false
end

local function checkScriptIntegrity(player)
    local character = player.Character
    if not character then return end

    for _, script in ipairs(character:GetDescendants()) do
        if script:IsA("LocalScript") or script:IsA("ModuleScript") then
            if not isScriptAllowed(script.Name) then
                -- Perform actions for unauthorized scripts, such as freezing the player
                freezePlayer(player)
                break
            end
        end
    end
end

local function isPositionModified(player, previousPosition, currentPosition, previousTime, currentTime)
    local positionChangeMagnitude = (previousPosition - currentPosition).Magnitude
    local positionChangeTime = currentTime - previousTime

    return positionChangeMagnitude > maxPositionChangeThreshold and positionChangeTime < maxPositionChangeTime
end

local function checkMeshing(player)
    local character = player.Character
    if not character then return end

    -- Check if the player's character is under the ground
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoidFloorPart = character:FindFirstChild("HumanoidFloorPart")
    if humanoidRootPart and humanoidFloorPart then
        local distance = (humanoidRootPart.Position - humanoidFloorPart.Position).Y
        if distance < -3 then
            -- Teleport the player above or back to their previous position
            local previousPosition = humanoidRootPart:GetAttribute("PreviousPosition")
            if previousPosition then
                humanoidRootPart.CFrame = CFrame.new(previousPosition)
            end

            -- Freeze the player
            freezePlayer(player)
        else
            -- Store the current position as the previous position for future reference
            humanoidRootPart:SetAttribute("PreviousPosition", humanoidRootPart.Position)
        end
    end
end

game.Players.PlayerAdded:Connect(function(player)
    local previousPosition = player.Character and player.Character.HumanoidRootPart.Position
    local previousTime = tick()

    player.PlayerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            local guiName = child.Name
            local playerRank = 0 -- Modify this to retrieve the player's rank or rank ID
            local playerName = player.Name
            if not isGuiAllowed(guiName, playerRank, playerName) then
                -- Perform actions for unauthorized GUIs or when player is not allowed to open admin GUI
                if guiName == "AdminGUI" then
                    player:Kick("You are not authorized to use the admin GUI!")
                else
                    player:Kick("Unauthorized GUI detected!")
                end
            end
        end
    end)

    player.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                checkSpeed(player)
            end
        end)
    end)

    game:GetService("RunService").Heartbeat:Connect(function()
        local character = player.Character
        if not character then return end

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        local currentPosition = humanoidRootPart.Position
        local currentTime = tick()

        if isPositionModified(player, previousPosition, currentPosition, previousTime, currentTime) then
            -- Perform actions for modified position, such as freezing the player
            freezePlayer(player)

            -- Return player to previous position
            humanoidRootPart.CFrame = CFrame.new(previousPosition)

            -- Update previous position and time
            previousPosition = humanoidRootPart.Position
            previousTime = tick()

            -- Delay before reactivating player movement
            wait(freezeTime)

            -- Update previous position and time again
            previousPosition = humanoidRootPart.Position
            previousTime = tick()
        else
            previousPosition = currentPosition
            previousTime =currentTime
        end
    end)

    -- Anti-meshing check
    game:GetService("RunService").Heartbeat:Connect(function()
        checkMeshing(player)
    end)

    -- Script integrity check
    game:GetService("RunService").Heartbeat:Connect(function()
        checkScriptIntegrity(player)
    end)
end)
