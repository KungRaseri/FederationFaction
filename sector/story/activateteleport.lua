
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("randomext")
Balancing = require ("galaxy")
PlanGenerator = require("plangenerator")
SectorSpecifics = require("sectorspecifics")


local activationDistance = 150

function initialize()

end

if onServer() then
function getUpdateInterval()
    return 1
end
end

if onClient() then
function getUpdateInterval()
    return 0
end
end



function getTeleporters()
    if teleporters then return teleporters end

    teleporters = {}
    local entities = {Sector():getEntitiesByComponent(ComponentType.Scripts)}

    for _, entity in pairs(entities) do
        local teleporter = entity:getValue("teleporter")
        if teleporter then
            teleporters[teleporter] = entity
        end
    end

    return teleporters
end

function updateServer()

    -- if there's a wormhole, don't activate
    -- this is to prevent double activation
    local wormholes = {Sector():getEntitiesByComponent(ComponentType.EntityTransferrer)}
    if #wormholes > 0 then return end

    -- get all entities that can have upgrades
    local entities = {Sector():getEntitiesByComponent(ComponentType.ShipSystem)}

    -- filter out all entities that don't have a teleporter key upgrade
    for i, entity in pairs(entities) do
        if entity:hasScript("teleporterkey") == false then
            entities[i] = nil
        end
    end

    local teleporters = getTeleporters()
    local teleportersOccupied = 0

    -- check if positioning is correct
    for i, teleporter in pairs(teleporters) do
        local occupied

        for _, entity in pairs(entities) do
            if teleporter.index ~= entity.index then
                local scriptName = string.format("teleporterkey%i.lua", i)

                if entity:hasScript(scriptName) then
                    local d = teleporter:getNearestDistance(entity)
                    if d <= activationDistance then
                        occupied = true
                        break
                    end
                end
            end
        end

        if occupied then
            teleportersOccupied = teleportersOccupied + 1
        end
    end

    if teleportersOccupied == 8 then
        -- if yes, activate the wormhole
        local x, y = Sector():getCoordinates()
        local own = vec2(x, y)
        local d = length(own)

        local distanceInside = 5;

        -- find a free destination inside the ring
        local destination = nil
        while not destination do
            local d = own / d * (Balancing.BlockRingMin - distanceInside)

            local specs = SectorSpecifics()
            local target = specs:findFreeSector(random(), math.floor(d.x), math.floor(d.y), 1, distanceInside - 1, Server().seed)

            if target then
                destination = target
            else
                distanceInside = distanceInside + 1
            end
        end

        local desc = WormholeDescriptor()
        desc:addComponent(ComponentType.DeletionTimer)

        desc.cpwormhole.color = ColorRGB(1, 0, 0)
        desc.cpwormhole:setTargetCoordinates(destination.x, destination.y)
        desc.cpwormhole.visualSize = 100
        desc.cpwormhole.passageSize = 150
        desc.cpwormhole.oneWay = false

        local wormHole = Sector():createEntity(desc)

        DeletionTimer(wormHole.index).timeLeft = 20 * 60 -- open for 20 minutes
    end
end

local topLevelBlocks
local glowPositions = {}
local timeCount = 0
local lasers = {}

function updateClient(timeStep)

    timeCount = timeCount + timeStep
    while timeCount > 1.0 do
        updateClientLowFq()
        timeCount = timeCount - 1.0
    end

    for _, position in pairs(glowPositions) do
        Sector():createGlow(position, random():getFloat(14, 18), ColorRGB(1.0, 0.2, 0.2))
    end
end


function updateClientLowFq()
    glowPositions = {}

    -- get all entities that can have upgrades
    local entities = {Sector():getEntitiesByComponent(ComponentType.ShipSystem)}

    -- filter out all entities that don't have a teleporter key upgrade
    for i, entity in pairs(entities) do
        if entity:hasScript("teleporterkey") == false then
            entities[i] = nil
        end
    end

    local teleporters = getTeleporters()

    if not topLevelBlocks then
        topLevelBlocks = {}

        for _, teleporter in pairs(teleporters) do
            local plan = Plan(teleporter.index)
            local block = PlanGenerator.findMinBlock(plan, "y")
            topLevelBlocks[teleporter.index] = block.box.center
        end
    end

    local teleportersOccupied = 0
    -- check if positioning is correct
    for i, teleporter in pairs(teleporters) do
        local occupied

        for _, entity in pairs(entities) do
            if teleporter.index ~= entity.index then
                local scriptName = string.format("teleporterkey%i.lua", i)

                if entity:hasScript(scriptName) then
                    local d = teleporter:getNearestDistance(entity)
                    if d <= activationDistance then
                        occupied = true
                        break
                    end
                end
            end
        end

        if occupied then
            teleportersOccupied = teleportersOccupied + 1

            local position = topLevelBlocks[teleporter.index]
            position = teleporter.position:transformCoord(position)

            table.insert(glowPositions, position)
        end
    end

    if teleportersOccupied == 8 then
        local wormholes = {Sector():getEntitiesByComponent(ComponentType.EntityTransferrer)}
        if #wormholes > 0 then return end

        if #lasers == 0 then
            for index, position in pairs(topLevelBlocks) do
                local teleporter = Entity(index)
                local pos = teleporter.position:transformCoord(position)

                local laser = Sector():createLaser(pos, vec3(), ColorRGB(1, 0, 0), 15)
                laser.collision = false
                laser.maxAliveTime = 15

                table.insert(lasers, laser)
            end
        end
    else
        if #lasers > 0 then
            for _, laser in pairs(lasers) do
                if valid(laser) then
                    laser.maxAliveTime = 0.01
                end
            end
            lasers = {}
        end
    end

end



