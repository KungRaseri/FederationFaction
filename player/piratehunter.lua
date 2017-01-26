if onServer() then

function initialize()
    -- start the pirate attack event
    Sector():addScriptOnce("pirateattack.lua")
    terminate()
end

end
