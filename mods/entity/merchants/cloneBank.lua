package.path = package.path .. ";data/scripts/lib/?.lua"

--[[

This script is a template for creating station- or ship- or any entity scripts.
The script runs on the server and on the client simultaneously.
Remember that there will be only 1 instance running on the server, but multiple instances running on the clients, one for each client.

There are various functions that get called at specific points of the game,
read the comments of the functions for further information.

If you don't use some functions that are offered here (which may be quite likely),
you can save performance by commenting them out or removing them from the script.
Calling an empty function takes up performance, while the program can detect missing functions, and will not call them.

]]--

package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("faction")
require ("randomext")
Dialog = require("dialogutility")

local balanceFactors = {}
-- if this function returns true the button for the script in the interaction window will be clickable.
-- If this function returns false, it can return an error message as well, which will explain why the interaction doesn't work.
function interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -10000)
end

-- This function will be called when the entity is saved into the database.
-- The server will not save the entire script and all its values.
-- Instead it will call this function to gather all values from the script that have to be saved.
-- if you have any important values that need saving, put them into a table and return them here and the database will save them.
-- When the entity is loaded from the database, the restore() function will be called
-- with all the values that were returned by this function before.
function secure()
    return {}
end

-- if previously there was a table returned by secure(), this function will be called when the entity is
-- restored from the database and the table returned by secure() will be given as parameter here.
-- This function is called AFTER the initialize() function.
function restore(data)
    
    -- etc.
end

-- this is just an example usage of how to restore an unknown number of values
--function restore(...)
--    local values = {...}
--
--    -- values is now an array containing all values that were given to us by the game.
--
--end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    local station = Entity()
    local x
    local y
    x, y = Sector():getCoordinates()

    -- We wouldn't want relationship threshold to have a cubic rise, so replace with linear rise 
    -- snippet from the Balancing_GetSectorRichnessFactor script function
    local coords = vec2(x, y)
    local dist = length(coords)
    local maxDist = Balancing_GetDimensions() / 2
    if dist > maxDist then dist = maxDist end

    local linFactor = 1.0 - (dist / maxDist)
    local richness = Balancing_GetSectorRichnessFactor(x,y)

    setPrice(richness)
    setRelationThreshold(linFactor)

    -- It is common use to have the first script that is added to a station and that sets a name to set the title of the station.
    -- In order for this to work, each script that gives a title has to check if there is not yet a title
    if station.title == "" then
        station.title =  "Clone Bank"
        InteractionText(station.index).text = generateStationInteractionText(station, random())
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/research.png"
        InteractionText(station.index).text = generateStationInteractionText(station, random())
    end

end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()
    local menu = ScriptUI()
    menu:registerInteraction("Create Clone"%_t, "onCreateClone")
end
--[[
-- this functions gets called when the indicator of the station is rendered on the client
-- if you want to do any rendering calls by yourself, then this is the place to do it. Just remember that this
-- may take up a lot of performance and might slow the game down, so don't overuse it.
function renderUIIndicator(px, py, size)

end

-- this function gets called every time the window is shown on the client, ie. when a player presses F to interact and then clicked the button for our script
function onShowWindow()

end

-- this function gets called every time the window is closed on the client
function onCloseWindow()

end

-- this function gets called once each frame, on client and server
function update(timeStep)

end

-- this function gets called once each frame, on client only
function updateClient(timeStep)

end

-- this function gets called once each frame, on server only
function updateServer(timeStep)

end

-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
-- if you want to do any rendering calls by yourself, then this is the place to do it. Just remember that this
-- may take up a lot of performance and might slow the game down, so don't overuse it.
function renderUI()

end--]]

function onCreateClone()
    --gets called when you click the "Create Clone" button.
    renderToggle = false --Make the UI not render so it won't obstruct the screen (if you know a better way, please do tell me!)
    local flag, msg = CheckFactionInteraction(Player().index, balanceFactors.relationThreshold)
    local dialog = {text = "error"}
    if flag then
        dialog.text = "We value your service to the Federation. As a token of gratitude, this clone is on us."
        invokeServerFunction("setCloneHome",Player().index,x,y)
    elseif Player():canPay(balanceFactors.price) then
        Player:payMoney(balanceFactors.price)
        invokeServerFunction("setCloneHome",Player().index,x,y)
        dialog.text = "Your clone is safe with us, " .. Player().name ..". Please remember, only one clone can be active at a time."
    else
        dialog.text = "We don't do charity cases. Come back when you have more credits." 
    end
    ScriptUI():showDialog(dialog)   
end

function setCloneHome(playerindex,x,y)
    local player = Player(playerindex)
    player:setHomeSectorCoordinates(x,y)
    --print("Changed player ".. playerindex .. "'s homeworld to: " .. player:getHomeSectorCoordinates() )
end

function generateStationInteractionText(entity, random)

    local text = ""

    local title = entity.translatedTitle
    local name = entity.name

    local nameStr = " of this "%_t .. title

    local greetings = {
        "Hello. "%_t,
        "Welcome. "%_t,
        "Greetings. "%_t,
        "Good day. "%_t,
    }

    local intro1 = {
        "This is "%_t,
        "You are talking to "%_t,
        "You are now talking to "%_t,
        "You are speaking to "%_t,
        "You are now speaking to "%_t,
    }

    local intro2 = {
        "the manager and operator${name_string}. "%_t % {name_string = nameStr},
        "the lead engineer${name_string}. "%_t % {name_string = nameStr},
    }

    local service = {
        "Would you like to purchase a clone? Safety first!"%_t,
        "The best cure for Xsotans is a clone in every sector?"%_t,
        "For a small price, you can shoot whoever you want with no repurcussions!"%_t,
    }

    local price_str = " The clone will only cost ${money} credits."%_t % {money = balanceFactors.price}
    local str =
        greetings[random:getInt(1, #greetings)] ..
        intro1[random:getInt(1, #intro1)] ..
        intro2[random:getInt(1, #intro2)] ..
        service[random:getInt(1, #service)] ..
        price_str

    return str
end

function setPrice(richness)
    -- Organic, grass fed and free roam credits only.
    local wholeValuePrice = math.floor(50000*richness)
    -- price increments by 5000 rounded up. If you don't do this you get some pretty funky numbers.
    local leftOver = wholeValuePrice % 5000
    local price = wholeValuePrice + (5000-leftOver)
    balanceFactors.price = price
end

function setRelationThreshold(linearFactor)
    balanceFactors.relationThreshold = 100000*linearFactor + 25000 -- minimum required relationship is 25000
end