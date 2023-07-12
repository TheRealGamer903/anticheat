-- Variables
local BASE_DAMAGE = 5 -- Base damage for a fall of 10 studs
local DAMAGE_INCREMENT = 5 -- Damage increment per additional 10 studs of fall distance
local VELOCITY_DAMAGE_MULTIPLIER = 0.2 -- Multiplier for calculating damage based on velocity
local MAX_FALL_SPEED = 100 -- Maximum fall speed that results in fatal damage

-- Function to calculate fall damage
local function calculateFallDamage(height, velocity)
    local fallDistance = math.max(0, height - 10)
    local distanceDamage = math.floor(fallDistance / 10) * DAMAGE_INCREMENT
    local velocityDamage = 0
    
    if velocity > MAX_FALL_SPEED then
        velocityDamage = math.floor((velocity - MAX_FALL_SPEED) * VELOCITY_DAMAGE_MULTIPLIER)
    end
    
    return BASE_DAMAGE + distanceDamage + velocityDamage
end

-- Function to apply fall damage to a player
local function applyFallDamage(player, height, velocity)
    local damage = calculateFallDamage(height, velocity)
    if damage > 0 then
        -- Apply damage to the player
        -- You can replace this with your own code to handle damage, such as reducing health or using a custom damage system
        player.Health = player.Health - damage
    end
end

-- Function to handle when a player hits the ground
local function onPlayerHitGround(character, hitPart)
    local player = game.Players:GetPlayerFromCharacter(character)
    if player then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local fallHeight = humanoid.JumpPower - hitPart.Position.Y
            local fallVelocity = humanoid.RootPart.Velocity.Y
            applyFallDamage(player, fallHeight, fallVelocity)
        end
    end
end

-- Connect the hit ground event
game:GetService("Workspace").FallParts.ChildAdded:Connect(onPlayerHitGround)
