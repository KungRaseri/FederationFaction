package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("stringutility")
require ("faction")
require ("player")

local availableCrewMembers = 0;
local slider = 0;
local membersLabel = 0;
local placesLabel = 0;
local priceLabel = 0;
local costPerMember = 0;
local uiGroups = {}

local availableCrew = {}



-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local ship = player.craft
    if not ship then return false end
    if not ship:hasComponent(ComponentType.Crew) then return false end
    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -25000, 40000)
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    if onServer() then

		local probabilities = {}
		table.insert(probabilities, {profession = CrewProfessionType.None, probability = 1.0, number = math.random(20, 40)})
		table.insert(probabilities, {profession = CrewProfessionType.Engine, probability = 0.5, number = math.random(5, 15)})
		table.insert(probabilities, {profession = CrewProfessionType.Repair, probability = 0.5, number = math.random(5, 15)})
		table.insert(probabilities, {profession = CrewProfessionType.Gunner, probability = 0.5, number = math.random(5, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Miner, probability = 0.5, number = math.random(5, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Pilot, probability = 0.5, number = math.random(3, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Security, probability = 0.4, number = math.random(3, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Attacker, probability = 0.25, number = math.random(3, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Sergeant, probability = 0.4, number = math.random(4, 10)})
		table.insert(probabilities, {profession = CrewProfessionType.Lieutenant, probability = 0.3, number = math.random(4, 7)})
		table.insert(probabilities, {profession = CrewProfessionType.Commander, probability = 0.25, number = math.random(3, 5)})
		table.insert(probabilities, {profession = CrewProfessionType.General, probability = 0.15, number = math.random(1, 2)})
		table.insert(probabilities, {profession = CrewProfessionType.Captain, probability = 0.5, number = math.random(1, 2)})

		for _, crew in pairs(probabilities) do
			if math.random() < crew.probability and #availableCrew < 6 then
				table.insert(availableCrew, crew)
			end
		end
    end

end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()

    local res = getResolution()

    local size = vec2(615, 300)


    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Hire Crew"%_t);

    window.caption = "Hire Crew"%_t
    window.showCloseButton = 1
    window.moveable = 1

	local frame = Rect(vec2(0, 10), size)

	local hsplit = UIHorizontalMultiSplitter(frame, 10, 10, 6)

	local padding = 15
	local iconSize = 30
	local barSize = 185
	local sliderSize = 185
	local priceSize = 50
	local buttonSize = 80

	local iconX = 15
	local barX = iconX + iconSize + padding
	local sliderX = barX + barSize + padding
	local priceX = sliderX + sliderSize + padding
	local buttonX = priceX + priceSize + padding

	for i = 0, 6 do
		local rect = hsplit:partition(i)

		local pic = window:createPicture(Rect(iconX, rect.lower.y, iconX + iconSize, rect.upper.y), "")
		local bar = window:createNumbersBar(Rect(barX, rect.lower.y, barX + barSize, rect.upper.y))
		local slider = window:createSlider(Rect(sliderX, rect.lower.y, sliderX + sliderSize, rect.upper.y), 0, 15, 15, "", "updatePrice");
		local label = window:createLabel(vec2(priceX, rect.lower.y + 4), "", 16)
        local button = window:createButton(Rect(buttonX, rect.lower.y, buttonX + buttonSize, rect.upper.y), "Hire"%_t, "onHireButtonPressed");

		local hide = function (self)
			self.bar:hide()
			self.pic:hide()
			self.slider:hide()
			self.label:hide()
			self.button:hide()
		end

		local show = function (self)
			self.bar:show()
			self.pic:show()
			self.slider:show()
			self.label:show()
			self.button:show()
		end

		table.insert(uiGroups, {pic=pic, bar=bar, slider=slider, label=label, button=button, show=show, hide=hide})

	end

    retrieveData()
end

function updatePrice(slider)
    local num = slider.value

    local costs = costPerMember * num * GetFee(Faction(), Player())

	for i, group in pairs(uiGroups) do
		if group.slider.index == slider.index then

			group.label.caption = round(CrewProfession(availableCrew[i].profession).price * group.slider.value) .. "$"
		end
	end

    -- if costs > 0 then
        -- priceLabel.caption = "$".. createMonetaryString(round(costs, 0))
    -- else
        -- priceLabel.caption = ""
    -- end
end

function retrieveData()
    invokeServerFunction("sendDataToClient", Player().index);
end

-- called on client
function setData(available)
    availableCrew = available
	refreshUI()
end

function refreshUI()
	local ship = Player().craft

    if ship.maxCrewSize == nil or ship.crewSize == nil then
        return
    end

    local placesOnShip = ship.maxCrewSize - ship.crewSize

	for _, group in pairs(uiGroups) do
		group:hide()
	end

	for i, pair in pairs(availableCrew) do
		local profession = CrewProfession(pair.profession)
		local number = pair.number

		local group = uiGroups[i]
		group:show()

		group.pic.isIcon = 1
		group.pic.picture = profession.icon
		group.pic.tooltip = profession.name .. "\n" .. profession.description

		group.bar:clear()
		group.bar:setRange(0, 40)
		group.bar:addEntry(number, tostring(number) .. " " .. profession.plural, profession.color)
        group.bar.tooltip = profession.name .. "\n" .. profession.description

		group.slider.min = 0
        group.slider.max = number
        group.slider.segments = number

        if pair.profession == CrewProfessionType.Captain then
			group.slider.max = 1
			group.slider.segments = 1
		end
	end

end

function onHireButtonPressed(button)
    for i, group in pairs(uiGroups) do
		if group.button.index == button.index then
			local num = group.slider.value
			invokeServerFunction("hireCrew", Player().craftIndex, i, num)
		end
	end
end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()
    retrieveData()
end


function sendDataToClient(playerIndex)
    invokeClientFunction(Player(playerIndex), "setData", availableCrew)
end

function hireCrew(craftIndex, i, num)

	local pair = availableCrew[i]
	local profession = CrewProfession(pair.profession)
    local ship = Entity(craftIndex)
    local buyer = Player(ship.factionIndex)

    if ship.factionIndex ~= callingPlayer then return end

    local station = Entity()
    local stationFaction = Faction()

    local costs = profession.price * num

    local canPay, msg, args = buyer:canPay(costs)
    if not canPay then
        buyer:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    local canHire, msg, args = ship:canAddCrew(num, pair.profession, 0)
    if not canHire then
        buyer:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to hire crewmembers."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to hire crewmembers."%_T
    if not CheckPlayerDocked(buyer, station, errors) then
        return
    end

    buyer:pay(costs);

    ship:addCrew(num, CrewMan(profession, profession ~= CrewProfessionType.None, 1));

    pair.number = pair.number - num

    invokeClientFunction(buyer, "setData", availableCrew)
end
---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
---- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end
--
---- this function gets called once each frame, on client only
--function updateClient(timeStep)
--
--end
--
---- this function gets called once each frame, on server only
--function updateServer(timeStep)
--
--end
--
---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end




