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
    print("ayyy initialize")
    -- It is common use to have the first script that is added to a station and that sets a name to set the title of the station.
    -- In order for this to work, each script that gives a title has to check if there is not yet a title
    if station.title == "" then
    	station.title =  "Clone Bank"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/research.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end

end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()
    local menu = ScriptUI()

    menu:registerInteraction("Create Clone"%_t, "onCreateClone")
end

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

end

function onCreateClone()
	--gets called when you click the "set homeworld" button.
	renderToggle = false --Make the UI not render so it won't obstruct the screen (if you know a better way, please do tell me!)
	local x, y = Sector():getCoordinates() 
	Player():getHomeSectorCoordinates() -- for later.
	local flag, msg = not CheckFactionInteraction(Player().index, 50000)

	local dialog = {text = "error"}
	if(flag) then
		dialog.text = "Sorry, but we do not know you well enough to let you base near us."
	else
		invokeServerFunction("setCloneHome",Player().index,x,y)
		print(Player().index)
		print(Player())
		dialog.text = "We'll be happy to have you around, " .. Player().name ..". Please remember, only one clone can be active at a time."	
	end

	ScriptUI():showDialog(dialog)	
end



function setCloneHome(playerindex,x,y)
	local player = Player(playerindex)
	player:setHomeSectorCoordinates(x,y)
	print(playerindex)
	--print("Changed player ".. playerindex .. "'s homeworld to: " .. player:getHomeSectorCoordinates() )
end