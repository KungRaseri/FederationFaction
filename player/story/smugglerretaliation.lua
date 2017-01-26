package.path = package.path .. ";data/scripts/lib/?.lua"

require ("goods")
require ("mission")
require ("stringutility")
Smuggler = require("story/smuggler")

missionData.title = "Enemy of my Enemy"%_t
missionData.brief = "Enemy of my Enemy"%_t

function initialize(x, y)

    initMissionCallbacks()

    if onServer() then

        if not x or not y then return end

        missionData.location = {x = x, y = y}
        missionData.justStarted = true
        missionData.stage = 0

    else
        sync()
    end

end

function onTargetLocationEntered()
    Smuggler.spawnEngineer()

end

function startCollecting(goods, engineerIndex)

    if missionData.stage == 0 then
        missionData.stage = 1
        missionData.goods = goods

        missionData.interactions = {{x = missionData.location.x, y = missionData.location.y, entity = engineerIndex, text = "I have your goods. /*smugglerretaliation*/"%_t, callback = "onDeliver"}}
    end

    sync()
    showMissionUpdated()

end

function giveSystem()
    if onClient() then
        invokeServerFunction("giveSystem")
        return
    end

    local player = Player(callingPlayer)
    local ship = player.craft

    local needs = findMissingGoods(ship)

    if #needs > 0 then return end

    for _, g in pairs(missionData.goods) do
        -- remove goods
        ship:removeCargo(g.name, g.amount)
    end

    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/smugglerblocker.lua", Rarity(RarityType.Exotic), Seed(0)))

end

function findMissingGoods(ship)
    local needs = {}
    for _, g in pairs(missionData.goods) do
        local has = ship:getCargoAmount(g.name) or 0

        if has < g.amount then
            table.insert(needs, {name = g.name, amount = g.amount - has})
        end
    end

    return needs
end

function onDeliver(entityIndex)

    local needs = findMissingGoods(Player().craft)

    local dialog = {}
    if #needs > 0 then
        local missing = enumerate(needs, function(g) return g.amount .. " " .. g.name end)

        dialog.text = string.format("I'm afraid you don't. My scanners show me that you're still missing %s."%_t, missing)
    else
        dialog.text = "Very good. I'll build the system. It'll be done in no time."%_t
        dialog.onEnd = "giveSystem"
        dialog.followUp = {text = "Here you go. With this you should be able to destroy Bottan's hyperspace drive."%_t, followUp = {
        text = "But keep in mind that this system might get destroyed when you use it. It's very possible that you have one shot and that's it."%_t}}
    end

    ScriptUI(entityIndex):showDialog(dialog)
end

function getMissionDescription()
    local description = "You've received a letter from someone claiming to be a 'friend'. He wants to talk to you about Bottan."%_t

    if missionData.stage == 1 then
        local str = "The mysterious figure turned out to be Bottan's ex chief engineer. He wants to take revenge and asked you to collect parts so he can build a ray that destroys Bottan's hyperspace drive."%_t

        description = description .. "\n\n" .. str

        if missionData.goods then
            local str = ""
            for _, g in pairs(missionData.goods) do
                str = str .. g.amount .. "x " .. goods[g.name]:good().displayName .. "\n"
            end
            description = description .. "\n\n" .. str
        end
    end

    return description
end
