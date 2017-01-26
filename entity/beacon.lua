package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

local text = ""
local args = {}

function initialize(text_in, args_in)
    if onServer() then
        text = text_in or ""
        args = args_in or {}
    else
        Player():registerCallback("onPreRenderHud", "onRenderHud")

        sync()
    end
end

function interactionPossible(player, option)
    if option == 0 then
        if Player().index == Entity().factionIndex then return 1 end
        return false
    end
    return true
end

function initUI()

    local res = getResolution()
    local size = vec2(300, 250)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Beacon Text"%_t)

    window.caption = "Beacon Text"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local hsplit = UIHorizontalSplitter(Rect(window.size), 10, 10, 0.5)
    hsplit.bottomSize = 40

    textBox = window:createMultiLineTextBox(hsplit.top)

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    window:createButton(vsplit.left, "Save"%_t, "onSaveClick")
    window:createButton(vsplit.right, "Cancel"%_t, "onCancelClick")

    menu:registerInteraction("Close"%_t, "")
end

function onRenderHud()
    -- display nearest x
    if os.time() % 2 == 0 then
        local renderer = UIRenderer()
        renderer:renderEntityTargeter(Entity(), ColorRGB(1, 1, 1));
        renderer:display()
    end
end

function onSaveClick()
    invokeServerFunction("setText", textBox.text)
end

function onCancelClick()
    window:hide()
end

function onShowWindow()
    textBox.text = InteractionText(Entity().index).text
end

function setText(text_in, args_in)
    if callingPlayer and callingPlayer ~= Entity().factionIndex then return end

    args = args_in or {}
    text = text_in or ""
    broadcastInvokeClientFunction("sync", text, args)
end

function getText()
    return text
end

function sync(text_in, args_in)
    if onClient() then
        if text_in then
            InteractionText(Entity().index).text = text_in%_t % (args_in or {})
        else
            invokeServerFunction("sync")
        end
    else
        invokeClientFunction(Player(callingPlayer), "sync", text, args)
    end

end

function secure()
    return {text = text, args = args}
end

function restore(values)
    text = values.text or ""
    args = values.args or {}
end


