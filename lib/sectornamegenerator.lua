package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("utility")

local XYPrefix = { "Eternal", "Ephemeral", "Pure", "Holy", "Mystic", "Quaking",
"Insatiable", "Majestic", "Epic", "Unyielding", "Withering", "Translucent",
"Vehement", "Infinite", "Endless", "Dark", "Bright", "Deep", "Silent", "Solar",
"Modern", "Neverending", "Beautiful", "Treacherous", "Empowering", "Abandoned",
"Elusive", "Burning", "Magical", "Unforgiving", "Galactic", "Immortal",
"Mortal", "Sinister", "Stellar", "Righteous", "Cyclonic", "Sacred", "Grand",
"Everlasting", "Limitless", "Immense", "Vast", "Astral", "Shining", "Cosmic",
"Divine", "Lunar", "Exalted", "Empyreal", "Ethereal", "Etheric", "Unholy",
"Unknown", "Barren", "Bright", "Faded", "New", "Hollow", "Shallow", "Final",
"Tempting", "Transcendent", "Dying", "Valiant", "Sublime", "Desolate",
"Golden", "Illusional", "Iron", "Titanium", "Naonite", "Trinium", "Xanion",
"Ogonite", "Avorion" }

local XYSuffix = { "Agony", "Downfall", "Light", "Rise", "Ash", "Darkness",
"Blackness", "Brightness", "Chaos", "Flame", "Fire", "Oblivion", "Shadow",
"Storm", "Void", "Vortex", "Scion", "Epoch", "Fight", "Battle", "Birth",
"Rebirth", "Serenity", "Eternity", "Epiphany", "Epitaph", "Luminescence",
"Solitude", "Aurora", "Eloquence", "Pureness", "Apocalypse", "Cataclysm",
"Tempest", "Nexus", "Vortex", "Omen", "Balance", "Bulwark", "Beacon",
"Testament", "Equilibrium", "Legend", "Vengeance", "Exasperation", "Hope",
"Happiness", "Vividness", "Discipline", "Renegade", "Infinity", "Harbor",
"Death", "Fate", "Enemy", "Ally", "Throne", "Destruction", "Debauchery",
"Threat", "Heaven", "Hell", "Creation", "Night", "Paradise", "Power", "Sky",
"Summoning", "System", "War", "Difference", "Sun", "Star", "Path", "Fall",
"Blessing", "Dream", "Soul", "Phantom", "Gaze", "Wonder", "Wish", "Sacrament",
"Kingdom", "Tragedy", "Poem", "Time", "Quest", "Terror", "Treasure", "Sunset",
"Paranoia", "Will", "Honor", "Mercy", "Monument", "Era", "Aeon", "Awakening",
"Life", "Glory", "Way", "Universe", "Revenge", "Outlands", "Legacy", "Bliss",
"Victory", "Curse", "Blessing", "Call", "Dawn", "Prophecy", "Force", "Reality",
"Revelation", "Revolution", "Freedom", "Melody", "Twilight", "Beauty",
"Struggle", "Domination", "World", "Grace", "Peace", "Future", "Insanity",
"Destiny", "Nemesis", "Grave", "Damnation", "Wrath", "Pact", "Nightmare",
"Authority", "Rift", "Pride", "Envy", "Greed", "Faith", "Determination",
"Edge", "Spell", "Sorcery", "Renaissance", "Salvation", "Age", "Doom", "Unity",
"Empire", "Fear", "Conflict", "Decadence", "Confusion", "Eclipse", "Elysium",
"Atmosphere", "Ecstasy", "Enchantment", "Firmament", "Harmony", "Utopia",
"Perpetuity", "Continuum", "Space", "Tranquility", "Empathy", "Home", "Venue",
"Bastion", "Pandemonium", "Shelter", "Ether", "Nebula", "Vision", "Boon",
"Miracle", "Fortune", "Mines", "Ridge", "Defeat", "Might", "Clouds",
"Maelstrom", "Frontier", "Haven", "Refuge", "Triumph", "Reach", "Sprite",
"Dominion", "Sanctum", "Sanctuary", "Badlands", "Currents", "Deprivation",
"Vault", "Corona", "Ascendance", "Expansion", "Torrent", "Upheaval",
"Turbulence", "Turmoil", "Whirl", "Calm", "Incarnation", "Exile", "Judgement",
"Ruin", "Fury", "Renewal", "Helix", "Glimmer", "Haunting", "Despair", "Worth",
"Wealth", "Reckoning", "Law", "Truth", "Duty", "Reason", "Ruins",
"Tribulation", "Punishment", "Torment", "Souls", "Justice", "District",
"Estate", "Ascension", "Theory", "Anarchy", "Skies", "Gods", "Thunder", "Filth"
}

local XofYPrefix = { "Echoes", "Rise", "Flames", "Storm", "Vortex", "Epoch",
"Birth", "Bulwark", "Beacon", "Testament", "Legend", "Phantom", "Kingdom",
"Poem", "Sunset", "Dawn", "Force", "Fading", "Fields", "Tale", "Dream", "Edge",
"Call", "Renaissance", "Age", "Empire", "Shades", "Home", "Venue", "Bastion",
"Shelter", "Nebula", "Vision", "Temple", "Illusions", "Clouds", "Maelstrom",
"Frontier", "Haven", "Reservoir", "Sanctum", "Sanctuary", "Spires", "Badlands",
"Currents", "Vault", "Field", "Ascendance", "Expansion", "Torrent", "Whirl",
"Incarnation", "Reckoning", "Ruins", "Pillars", "Estate", "District",
"Ascension", "Fall", "Downfall", "Theory" }

local XofYSuffix = { "Agony", "Light", "Darkness", "Blackness", "Brightness",
"Chaos", "Fire", "Oblivion", "Shadows", "Rebirth", "Serenity", "Eternity",
"Luminescence", "Solitude", "Eloquence", "Pureness", "Balance", "Vengeance",
"Exasperation", "Hope", "Happiness", "Vividness", "Discipline", "Infinity",
"Destruction", "Debauchery", "Heaven", "Hell", "Creation", "Night", "Paradise",
"Power", "War", "Differences", "Wonders", "Silence", "Time", "Terror", "Honor",
"Mercy", "Life", "Glory", "Revenge", "Victory", "Reality", "Freedom", "Fate",
"Twilight", "Magic", "Domination", "Grace", "Peace", "Destiny", "Damnation",
"Wrath", "Nightmares", "Authority", "Pride", "Envy", "Greed", "Determination",
"Salvation", "Doom", "Unity", "Fear", "Decadence", "Confusion", "Elysium",
"Ecstasy", "Harmony", "Perpetuity", "Tranquility", "Empathy", "Pandemonium",
"Fortune", "Defeat", "Might", "Fantasy", "Ruin", "Fury", "Despair", "Renewal",
"Wealth", "Truth", "Reason", "Tribulation", "Punishment", "Torment", "Justice",
"Iron", "Titanium", "Naonite", "Trinium", "Xanion", "Ogonite", "Avorion",
"Ascension", "Thunders", "Filth" }

local XYPossibilities = #XYPrefix * #XYSuffix
local XofYPossibilities = #XofYPrefix * #XofYSuffix

local greekAlphabet = { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta",
"Eta", "Theta", "Iota", "Kappa", "Lambda", "My", "Ny", "Xi", "Omikron", "Pi",
"Rho", "Sigma", "Tau", "Ypsilon", "Phi", "Chi", "Psi", "Omega" }

local gridSize = 8

function gridDimensions(x, y)
    local lx = math.floor(x / gridSize) * gridSize
    local ly = math.floor(y / gridSize) * gridSize

    return lx, ly, lx + gridSize, ly + gridSize
end

-- translate 0-20 to gridX/Y on a square "ring", 6 wide, around the center
function ringIndexToGrid(index)
    -- top bar
    if index < 6 then
        return -3 + index, -3
    end
    index = index - 6
    -- bottom bar
    if index < 6 then
        return -3 + index, 2
    end
    index = index - 6
    -- left bar
    if index < 4 then
        return -3, -2 + index
    end
    index = index - 4
    -- right bar
    if index < 4 then
        return 2, -2 + index
    end
end

function generateSectorName(x, y, count, seed)
    local gridX = math.floor(x / gridSize)
    local gridY = math.floor(y / gridSize)

    local name = ""
    -- does the current sector have a backer name?
    local arwSector = (seed.value * 4051) % 20
    local dskoSector = (seed.value * 4703) % 20
    if dskoSector == arwSector then
        dskoSector = (dskoSector + 1) % 20
    end

    local arwX, arwY = ringIndexToGrid(arwSector)
    local dskoX, dskoY = ringIndexToGrid(dskoSector)

    if arwX == gridX and arwY == gridY then
        name = "arw's "
    elseif dskoX == gridX and dskoY == gridY then
        name = "Dsko's "
    end

    local rand = Random(seed + gridX + gridY * 9931)

    -- generate new name
    if rand:getInt(1, XYPossibilities + XofYPossibilities) <= XYPossibilities then
        name = name .. XYPrefix[rand:getInt(1, #XYPrefix)] .. " "
        name = name .. XYSuffix[rand:getInt(1, #XYSuffix)]
    else
        name = name .. XofYPrefix[rand:getInt(1, #XofYPrefix)] .. " of "
        name = name .. XofYSuffix[rand:getInt(1, #XofYSuffix)]
    end

    if count > 0 then
        local numberSuffix = rand:getInt(1, 3)
        if numberSuffix == 1 then
            name = name .. " " .. count
        elseif numberSuffix == 2 then
            name = name .. " " .. toRomanLiterals(count)
        else
            name = name .. " " .. greekAlphabet[((count - 1) % #greekAlphabet) + 1]
            if count > #greekAlphabet then
                local numberSuffixSuffix = rand:getInt(1, 2)
                if numberSuffixSuffix == 1 then
                    name = name .. " " .. (math.floor((count - 1) / #greekAlphabet) + 1)
                elseif numberSuffixSuffix == 2 then
                    name = name .. " " .. toRomanLiterals(math.floor((count - 1) / #greekAlphabet) + 1)
                end
            end
        end

    end

    return name
end


return
{
    gridDimensions = gridDimensions,
    generateSectorName = generateSectorName
}
