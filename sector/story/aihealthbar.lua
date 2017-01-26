
local ais = {}
local fakeEndboss

local maxHealth = 1;
local health = 0;
local maxShield = 1;
local shield = 0;

if onClient() then

function getUpdateInterval()
    return 0.15
end
end


function initialize()

end

function updateClient(timePassed)

    health = 0
    shield = 0

    local maxHealthSum = 0
    local maxShieldSum = 0

    local entities = {Sector():getEntitiesByType(EntityType.Ship)}
    for _, entity in pairs(entities) do
        if entity:hasScript("aibehaviour.lua") then

            health = health + entity.durability
            shield = shield + entity.shieldDurability

            maxHealthSum = maxHealthSum + entity.maxDurability
            maxShieldSum = maxShieldSum + entity.shieldMaxDurability
        end
    end

    maxHealth = math.max(maxHealth, maxHealthSum)
    maxShield = math.max(maxShield, maxShieldSum)

    if health > 0 or shield > 0 then
        registerBoss(0)
        setBossHealth(0, health, maxHealth, shield, maxShield)
    else
        unregisterBoss(0)
        invokeServerFunction("terminateServer")
    end
end

function terminateServer()
    terminate()
end



