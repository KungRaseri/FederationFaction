package.path = package.path .. ";data/scripts/lib/?.lua"
require ("goods")
require ("stringutility")

local lines = nil
local description = nil
local bulletins = {}

function initialize()

end

function interactionPossible(playerIndex, option)
    return true
end

function initUI()
    local res = getResolution()
    local size = vec2(900, 605)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "${entity} Bulletin Board"%_t % {entity = (Entity().translatedTitle or "")%_t}
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Electronic Bulletin Board"%_t);

    local hsplit = UIHorizontalSplitter(Rect(size), 10, 10, 0.6)

    local lister = UIVerticalLister(hsplit.top, 7, 10)

    local vsplit = UIArbitraryVerticalSplitter(lister:placeCenter(vec2(lister.inner.width, 30)), 10, 5, 430, 550)

    window:createLabel(vsplit:partition(0).lower, "Description"%_t, 15)
    window:createLabel(vsplit:partition(1).lower, "Difficulty"%_t, 15)
    window:createLabel(vsplit:partition(2).lower, "Reward"%_t, 15)

    lines = {}

    for i = 1, 8 do
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))
        local vsplit = UIVerticalSplitter(rect, 10, 0, 0.85)

        local avsplit = UIArbitraryVerticalSplitter(vsplit.left, 10, 7, 430, 530)

        local frame = window:createFrame(vsplit.left)

        local i = 0

        local brief = window:createLabel(avsplit:partition(i).lower, "", 14); i = i + 1
        local difficulty = window:createLabel(avsplit:partition(i).lower, "", 14); i = i + 1
        local reward = window:createLabel(avsplit:partition(i).lower, "", 14); i = i + 1
        local button = window:createButton(vsplit.right, "Accept"%_t, "onTakeButtonPressed")

        local hide = function(self)
--            self.frame:hide()
            self.brief:hide()
            self.difficulty:hide()
            self.reward:hide()
            self.button:hide()
        end

        local show = function(self)
            self.frame:show()
            self.brief:show()
            self.difficulty:show()
            self.reward:show()
            self.button:show()
        end

        local line = {frame = frame, brief = brief, difficulty = difficulty, reward = reward, button = button, hide = hide, show = show, selected = false}

        table.insert(lines, line)
    end

    window:createLine(hsplit.bottom.topLeft, hsplit.bottom.topRight)
    description = window:createTextField(hsplit.bottom, "")

    refreshUI()

    fetchData()
end

function onShowWindow()
    fetchData()
end

function onTakeButtonPressed(button)
    for i, line in pairs(lines) do
        if line.button.index == button.index then
            invokeServerFunction("acceptMission", i)
        end
    end
end

function updateUI()
    if not lines then return end

    for _, line in pairs(lines) do
        if line.frame.mouseOver then
            if line.selected then
                line.frame.backgroundColor = ColorARGB(0.5, 0.35, 0.35, 0.35)
            else
                line.frame.backgroundColor = ColorARGB(0.5, 0.15, 0.15, 0.15)
            end
        else
            if line.selected then
                line.frame.backgroundColor = ColorARGB(0.5, 0.25, 0.25, 0.25)
            else
                line.frame.backgroundColor = ColorARGB(0.5, 0, 0, 0)
            end
        end
    end

    if Mouse():mouseDown(1) then

        description.text = ""

        for i, line in pairs(lines) do
            line.selected = line.frame.mouseOver

            if line.selected and bulletins[i] then
                description.text = (bulletins[i].description or bulletins[i].brief or "")%_t % bulletins[i].formatArguments
            end
        end
    end
end

function fetchData()
    if onClient() then
        invokeServerFunction("fetchData")
        return
    end

    invokeClientFunction(Player(callingPlayer), "receiveData", bulletins)
end

function receiveData(bulletins_in)
    bulletins = bulletins_in

    refreshUI()
end

function refreshUI()
    if not lines then return end

    for _, line in pairs(lines) do
        line:hide()
    end

    description.text = ""

    for i, bulletin in pairs(bulletins) do
        local line = lines[i]
        if not line then break end

        line:show()

        line.brief.caption = bulletin.brief%_t % bulletin.formatArguments
        line.difficulty.caption = bulletin.difficulty%_t % bulletin.formatArguments
        line.reward.caption = bulletin.reward%_t % bulletin.formatArguments

        if line.selected then
            description.text = (bulletin.description or bulletin.brief or "")%_t % bulletin.formatArguments
        end
    end

    if #bulletins == 0 then
        local line = lines[1]
        line:show()
        line.brief.caption = "No bulletins available!"%_t
        line.difficulty.caption = ""
        line.reward.caption = ""
        line.button:hide()
    end

end

function postBulletin(bulletin_in)

    for _, bulletin in pairs(bulletins) do
        if bulletin.brief == bulletin_in.brief then
            return
        end
    end

    table.insert(bulletins, bulletin_in)

    if bulletin_in.checkAccept then
        bulletin_in.checkAccept = assert(loadstring(bulletin_in.checkAccept))
    end

    if bulletin_in.onAccept then
        bulletin_in.onAccept = assert(loadstring(bulletin_in.onAccept))
    end

    broadcastInvokeClientFunction("receiveData", bulletins)

end

-- key can be a string or an int
-- if it's a string it will be matched with the descriptions of the bulletins
-- if it's an int then the int is the index of the bulletin
function removeBulletin(key)
    local bulletin = bulletins[key]

    if not bulletin then
        for i, b in pairs(bulletins) do
            if b.brief == key then
                index = i
                bulletin = b
            end
        end
    else
        index = key
    end

    if not bulletin then return end

    bulletins[index] = nil

    local temp = bulletins
    bulletins = {}

    for _, bulletin in pairs(temp) do
        table.insert(bulletins, bulletin)
    end

    broadcastInvokeClientFunction("receiveData", bulletins)
end

function acceptMission(index)
    local bulletin = bulletins[index]
    if not bulletin then return end

    local player = Player(callingPlayer)

    if bulletin.checkAccept and bulletin.checkAccept(bulletin, player) == 0 then
        return
    end

    -- give the player a new mission
    player:addScript(bulletin.script, unpack(bulletin.arguments))

    if bulletin.onAccept then bulletin.onAccept(bulletin, player) end

    removeBulletin(index)

end


