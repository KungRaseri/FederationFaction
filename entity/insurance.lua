package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("stringutility")
require ("faction")

insuredValue = 0
refundedValue = 0
periodic = false

mailText = ""
mailHeader = ""
mailSender = ""

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered

function interactionPossible(playerIndex, option)
    if Entity().factionIndex == playerIndex then
        return true, ""
    end

    return false
end

function restore(values)
    insuredValue = values.insuredValue or 0
    refundedValue = values.refundedValue or 0
    periodic = values.periodic or false
    mailText = values.mailText or ""
    mailHeader = values.mailHeader or ""
    mailSender = values.mailSender or ""
end

function secure()
    return {
        insuredValue = insuredValue,
        refundedValue = refundedValue,
        periodic = periodic,
    }
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    if onServer() then

        local entity = Entity()
        entity:registerCallback("onDestroyed" , "onDestroyed")
        entity:registerCallback("onBlockAdded" , "onBuild")
        entity:registerCallback("onBlockRemoved" , "onBuild")
        entity:registerCallback("onAllBlocksChanged" , "onBuild")

    end

    if onClient() then
        invokeServerFunction("setTranslatedMailText",
                             "Loss Payment enclosed"%_t,
                             generateInsuranceMailText(),
                             "S.I.I. /* Abbreviation for Ship Insurance Intergalactical, must match with the email signature */"%_t)
    end
end

function setTranslatedMailText(header, text, sender)
    mailHeader = header
    mailText = text
    mailSender = sender
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()
    local res = getResolution();
    local size = vec2(400, 330)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Insurance Plan"%_t);

    window.caption = "Insurance '${craft}'"%_t % {craft = Entity().name}
    window.showCloseButton = 1
    window.moveable = 1

    local hsplit = UIHorizontalSplitter(Rect(vec2(), size), 10, 10, 0.5)
    hsplit.bottomSize = 40

    window:createLabel(vec2(10, 10), "Ship Value"%_t, 15)
    window:createLabel(vec2(10, 30), "Insured Value"%_t, 15)
    window:createLabel(vec2(10, 50), "Refunded Value"%_t, 15)
    window:createLabel(vec2(10, 90), "Insurance Price"%_t, 15)
    window:createLabel(vec2(10, 110), "Paid"%_t, 15)
    window:createLabel(vec2(10, 140), "Still Due"%_t, 15)

    local w = 150
    shipValueLabel = window:createLabel(vec2(w, 10), "", 15)
    insuranceValueLabel = window:createLabel(vec2(w, 30), "", 15)
    insuredPercentageLabel = window:createLabel(vec2(w, 30), "", 15)
    refundedValueLabel = window:createLabel(vec2(w, 50), "", 15)
    priceLabel = window:createLabel(vec2(w, 90), "", 15)
    paidLabel = window:createLabel(vec2(w, 110), "", 15)
    paidPercentageLabel = window:createLabel(vec2(w, 110), "", 15)
    dueLabel = window:createLabel(vec2(w, 140), "", 15)

    for _, label in pairs({shipValueLabel, insuranceValueLabel, refundedValueLabel, priceLabel, paidLabel, dueLabel}) do
        label.size = vec2(150, 20)
        label:setRightAligned()
    end

    insuredPercentageLabel.size = vec2(240, 20)
    insuredPercentageLabel:setRightAligned()

    paidPercentageLabel.size = vec2(240, 20)
    paidPercentageLabel:setRightAligned()

    periodicCheckBox = window:createCheckBox(Rect(10, 190, size.x - 10, 210), "Automatic Payments"%_t, "onPeriodicPaymentsChecked")
    periodicCheckBox.tooltip =  "Automatically pays 10% of your money every few minutes\nas long as you haven't fully paid for your insurance."%_t

    payButton = window:createButton(hsplit.bottom, "Buy Full Insurance"%_t, "onPayButtonPressed")

    shipValueLabel.tooltip = "This is your ship's value."%_t
    priceLabel.tooltip = "The price for the insurance of your ship (30% of its value)."%_t

    refundedValueLabel.tooltip = "On destruction, this much money will be refunded by your insurance."%_t
    insuranceValueLabel.tooltip = "The maximum value that your current insurance will cover."%_t
    paidPercentageLabel.tooltip = "The amount of money you have already paid."%_t

    local qFrame = window:createFrame(Rect(0, 0, 20, 20))
    local qLabel = window:createLabel(vec2(0, 0), " ?", 15)

    qFrame.position = qFrame.position + vec2(370, 220)
    qLabel.position = qFrame.position
    qLabel.size = vec2(20, 20)
    qLabel.tooltip =    "When destroyed, your ship's insurance will refund its value. The price is 30% of your ship's value.\n"%_t ..
                        "You can pay only a fraction of the insurance price, but then only the same fraction of your ship's value gets refunded.\n"%_t ..
                        "If you make your ship bigger, you will have to make further payments.\n"%_t ..
                        "If you make your ship smaller, you won't get money back that you already spent, but it stays invested and you won't have to pay twice."%_t

    commentLabel = window:createLabel(vec2(20, 240), "Your ship is not insured!"%_t, 15)
    commentLabel.centered = 1
    commentLabel.size = vec2(size.x - 40, 20)

end

function onShowWindow()
    invokeServerFunction("refreshUI")
end

function refreshUI(insuredValueIn, refundedValueIn, periodicIn)

    if onServer() then
        local faction = Faction()
        local player = nil
        if faction.isPlayer then
            player = Player(faction.index)
        else
            return
        end

        invokeClientFunction(player, "refreshUI", insuredValue, refundedValue, periodic)
        return
    end

    insuredValue = insuredValueIn or insuredValue
    refundedValue = refundedValueIn or refundedValue
    periodicIn = periodicIn or false

    local value = getShipValue()
    local price = math.floor(value * 0.3)

    local due = math.max(0, math.floor(-(insuredValue - value) * 0.3))
    local paid = math.floor(insuredValue * 0.3)

    local percentage = math.floor(insuredValue / value * 1000) / 10.0

    shipValueLabel.caption = createMonetaryString(value) .. " $"
    insuranceValueLabel.caption = createMonetaryString(insuredValue) .. " $"
    refundedValueLabel.caption = createMonetaryString(refundedValueIn) .. " $"
    priceLabel.caption = createMonetaryString(price) .. " $"
    paidLabel.caption = createMonetaryString(paid) .. " $"
    dueLabel.caption = createMonetaryString(due) .. " $"

    insuredPercentageLabel.caption = tostring(percentage) .. "%"
    paidPercentageLabel.caption = tostring(percentage) .. "%"

    -- calculate the color of the percentage number
    local green = vec3(0, 1, 0)
    local yellow = vec3(1, 1, 0)
    local red = vec3(1, 0, 0)

    local c = ColorRGB(1, 1, 1)
    if percentage <= 50 then
        c = lerp(percentage, 0, 50, red, yellow)
    elseif percentage > 50 then
        c = lerp(percentage, 50, 100, yellow, green)
    end

    if insuredValue > value then
        c = yellow
    end

    insuredPercentageLabel.color = ColorRGB(c.x, c.y, c.z)
    paidPercentageLabel.color = ColorRGB(c.x, c.y, c.z)
    commentLabel.color = ColorRGB(c.x, c.y, c.z)

    periodicCheckBox.checked = periodicIn



    if percentage == 0 then
        commentLabel.caption = "Your ship is not insured!"%_t
    elseif percentage > 0  then
        commentLabel.caption = string.format("Insured for %s%% of ship value!"%_t, percentage)
    end

end

function onPayButtonPressed()
    invokeServerFunction("insure")
end

function onPeriodicPaymentsChecked(checkbox, value)
    if onClient() then
        invokeServerFunction("onPeriodicPaymentsChecked", nil, value)
    end

    if onServer() then
        if Entity().factionIndex ~= callingPlayer then
            return
        end
    end

    periodic = value

end

function internalInsure()
    if callingPlayer then return end

    local value = getShipValue()

    insuredValue = value
    refundedValue = value
end

function insure()

    local value = getShipValue()

    -- don't do anything if the insured value is bigger than the actual ship value
    if insuredValue > value then return end

    local due = math.max(0, math.floor(-(insuredValue - value) * 0.3))

    local faction = Faction()
    local player = nil
    if faction.isPlayer then
        player = Player(faction.index)
    else
        return
    end

    if player.index ~= callingPlayer then return end

    local canPay, msg, args = player:canPay(due)
    if not canPay then
        sendError(msg, unpack(args))
        return
    end

    player:pay(due)
    insuredValue = value
    refundedValue = value

    refreshUI()
end

function insurePartial()

    local value = getShipValue()

    -- don't do anything if the insured value is bigger than the actual ship value
    if insuredValue > value then return end

    local due = math.max(0, math.floor(-(insuredValue - value) * 0.3))
    if due == 0 then
        -- if nothing is due, adjust the insuredValue to the actual ship value, to reach the exact 100%
        if insuredValue < value then
            insuredValue = value
            refundedValue = value

            refreshUI()
        end
        return
    end

    local faction = Faction()
    local player = nil
    if faction.isPlayer then
        player = Player(faction.index)
    else
        return
    end

    local toPay = math.floor(player.money * 0.1)

    toPay = math.min(due, toPay)

    player:pay(toPay)

    insuredValue = math.floor(insuredValue + toPay / 0.3)
    refundedValue = insuredValue

    if toPay > 0 then
        sendInfo("You paid %i$ for %s's insurance."%_t, toPay, Entity().name)
    end

    refreshUI()
end

-- determines the exact value of the ship counting both credit- and resourcevalues
function getShipValue()
    local entity = Entity()

    local resourceValues = {entity:getUndamagedPlanResourceValue()};
    local sum = entity:getUndamagedPlanMoneyValue();

    for i, v in pairs(resourceValues) do
        sum = sum + Material(i - 1).costFactor * v * 10;
    end
    return math.floor(sum);
end

-- called whenever the blockplan is changed by building
function onBuild(objectIndex, blockIndex)

    -- the maximum payment players get back is the worth of the ship or what they've already paid for
    -- this means that when blocks are removed, the returned value sinks, and players can't refund this money
    refundedValue = math.min(getShipValue(), insuredValue)
end

-- if ship is destroyed this function is called
function onDestroyed (index, lastDamageInflictor)

    local faction = Faction()
    if not faction then return end
    if not faction.isPlayer then return end

    local player = Player(faction.index)

    local ship = Entity(index)

    -- don't pay if the player destroyed his ship by himself
    local damagers = {ship:getDamageContributorPlayers()}
    if #damagers == 1 and damagers[1] == player.index then
        sendInfo("Insurance Fraud detected. You won't receive any payments for %s."%_t, ship.name)
        return
    end

    local mail = Mail()
    mail.header = mailHeader
    mail.text = mailText
    mail.sender = mailSender
    mail.money = refundedValue

    player:addMail(mail)
end

-- following are mail texts sent to the player
function generateInsuranceMailText ()
    local entity = Entity()
    local player = Faction()

    local insurance_loss_payment = [[Dear ${player},

We received notice of the destruction of your craft '${craft}'. Very unfortunate!
As you are insured at our company you shall receive enclosed the sum insured with us as a loss payment.
The contract for your craft '${craft}' is now fulfilled. We hope we can be of future service to you.

Best wishes,
Ship Insurance Intergalactical
]]%_t

    return insurance_loss_payment % {player = player.name, craft = entity.name}
end

function sendError(msg, ...)
    local faction = Faction()
    if faction and faction.isPlayer then
        Player():sendChatMessage("S.I.I."%_t, 1, msg, ...)
    end
end

function sendInfo(msg, ...)
    local faction = Faction()
    if faction and faction.isPlayer then
        Player():sendChatMessage("S.I.I."%_t, 3, msg, ...)
    end
end

function setServerText()

end

-- this functions gets called when the indicator of the station is rendered on the client
--function renderUIIndicator(px, py, size)
--
--end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
-- function onShowWindow()
--
-- end

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

function getUpdateInterval()
    local minutes = 5
    return minutes * 60
end

-- this function gets called once each frame, on server only
function updateServer(timeStep)
    if periodic and insuredValue < getShipValue() then
        insurePartial()
    end
end

---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end
