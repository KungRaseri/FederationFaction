package.path = package.path .. ";data/scripts/lib/?.lua"

local OperationExodus = require("story/operationexodus")
local SectorGenerator = require("SectorGenerator")
local SectorSpecifics = require("sectorspecifics")
local PlanGenerator = require("plangenerator")
local Placer = require("placer")
require("utility")
require("mission")
require("stringutility")

missionData.title = "Operation Exodus"%_t
missionData.brief = "Operation Exodus"%_t
missionData.additionalInfo = ""

function initialize(start)
    if onServer() then
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        if start then missionData.justStarted = true end
    else
        sync()
    end
end

function onSectorEntered(player, x, y)

    -- when arriving in one of the final sectors
    local corners = OperationExodus.getCornerPoints()
    for _, coords in pairs(corners) do
        if coords.x == x and coords.y == y then
            placeFinalWreckages()
            return
        end
    end

    if missionData.location then
        if missionData.location.x == x and missionData.location.y == y then
            print ("entered point: " .. x .. " " .. y)
            findNextPoint(x, y)
            placeWayWreckages()
            placeBeacon(missionData.location.x, missionData.location.y)
            showMissionUpdated()
            sync()
        end
    end

    -- reset on entering a rendez-vous point
    local points = OperationExodus.getRendezVousPoints()
    for _, p in pairs(points) do
        if p.x == x and p.y == y then
            print("entered rendez-vous point")
            findNextPoint(x, y)
            placeBeacon(missionData.location.x, missionData.location.y)
            showMissionUpdated()
            sync()
            break;
        end
    end

    if missionData.location then
        print ("next point: " .. missionData.location.x .. " " .. missionData.location.y)
        for _, corner in pairs(corners) do
            print ("corner: " .. corner.x .. " " .. corner.y)

        end
    else
        print ("next point: nil")
    end

end

function findNextPoint(x, y)
    local corners = OperationExodus.getCornerPoints()

    -- which corner is nearest?
    local eval = function (e)
        local a = e.x - x
        local b = e.y - y
        return a * a + b * b
    end

    local corner = findMinimum(corners, eval)
    local stepSize = 50

    -- if we can reach the next point within 50 sectors, do so
    local d = length(vec2(corner.x - x, corner.y - y))
    if d < stepSize then
        missionData.location = {x = corner.x, y = corner.y}
        return
    end

    -- find direction
    local dir = normalize(vec2(corner.x - x, corner.y - y)) * stepSize

    -- do a deterministic random number generation
    local serverSeed = Server().seed
    local hash = makeHash(x, y, corner.x, corner.y, serverSeed.value)
    local specs = SectorSpecifics()

    missionData.location = specs:findFreeSector(Random(Seed(hash)), math.floor(x + dir.x), math.floor(y + dir.y), 15, 20, serverSeed)

end

function beaconFound(x, y)
    local coord, index, useX = OperationExodus.getBeaconData(x, y)

    local text
    if useX then
        text = string.format("#%i X = %i", index, coord)
    else
        text = string.format("#%i Y = %i", index, coord)
    end

    if not string.find(missionData.additionalInfo, text, 1, true) then
        missionData.additionalInfo = missionData.additionalInfo .. text .. "\n"

        if onServer() then
            showMissionUpdated()
            sync()
        end
    end

end

function placeBeacon(x, y)
    local text = "Operation Exodus${remaining}"%_t
    local remaining = "\n\n" .. string.format("X = %i\nY = %i", x, y)
    SectorGenerator(Sector():getCoordinates()):createBeacon(nil, nil, text, {remaining = remaining})
end

function placeFinalWreckages()

    -- check if there's a communication beacon
    local beacon = Sector():getEntitiesByScript("data/scripts/entity/story/exodustalkbeacon.lua")

    -- if not, create one
    if not beacon then
        beacon = SectorGenerator(Sector():getCoordinates()):createBeacon(nil, nil, "")
        beacon:removeScript("data/scripts/entity/beacon.lua")
        beacon:addScript("story/exodustalkbeacon.lua")
    end

    local wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
    if #wreckages > 15 then return end

    local faction = OperationExodus.getFaction()
    local generator = SectorGenerator(faction:getHomeSectorCoordinates())

    for i = 1, 50 do
        generator:createWreckage(faction)
    end

    for i = 1, 3 do
        local plan = PlanGenerator.makeStationPlan(faction)

        generator:createWreckage(faction, plan, 25)
    end

    Placer.resolveIntersections()
end

function placeWayWreckages()

    if math.random() < 0.5 then return end

    local wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
    if #wreckages > 0 then return end

    local faction = OperationExodus.getFaction()
    local generator = SectorGenerator(faction:getHomeSectorCoordinates())

    for i = 1, math.random(1, 3) do
        generator:createWreckage(faction)
    end

    Placer.resolveIntersections()

end

function getMissionDescription()
    if missionData.location then
        return "After deciphering the beacons, you found another beacon leading you to a new location."%_t
    else
        local additionalText = ""
        if missionData.additionalInfo and missionData.additionalInfo ~= "" then
            additionalText = "Messages:\n"%_t .. missionData.additionalInfo
        end

        return "You found a beacon with a cryptic message for all participants of the so-called 'Operation Exodus'."%_t .. "\n\n" .. additionalText
    end
end

