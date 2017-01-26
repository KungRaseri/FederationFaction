
require("randomext")

local PlanGenerator = {}

function findMaxBlock(plan, dimStr)

    local result
    local maximum = -math.huge
    for i = 0, plan.numBlocks - 1 do
        local block = plan:getNthBlock(i)

        local d = block.box.upper[dimStr]
        if d > maximum then
            result = block
            maximum = d
        end
    end

    return result
end

function findMinBlock(plan, dimStr)

    local result
    local minimum = math.huge
    for i = 0, plan.numBlocks - 1 do
        local block = plan:getNthBlock(i)

        local d = block.box.lower[dimStr]
        if d < minimum then
            result = block
            minimum = d
        end
    end

    return result
end

PlanGenerator.findMinBlock = findMinBlock
PlanGenerator.findMaxBlock = findMaxBlock

function PlanGenerator.selectMaterial(faction)
    local probabilities = Balancing_GetMaterialProbability(faction:getHomeSectorCoordinates())
    local material = Material(getValueFromDistribution(probabilities))

    local sector = Sector()
    if sector then
        local x, y = sector:getCoordinates()
        local distFromCenter = length(vec2(x, y))

        if material.value == 6 and distFromCenter > Balancing_GetBlockRingMin() then
            material.value = 5
        end
    end

    return material
end

function PlanGenerator.makeCarrierPlan(faction, volume, styleName, material)
    local plan = PlanGenerator.makeShipPlan(faction, volume, styleName, material)

    local tree = PlanBspTree(plan)

    -- this is a function that will find blocks on the plan which have free space to the +x or -x direction
    local checkFree = function(block, offset)
        local width = 40
        local box = block.box
        local displacement = box.size.x * 0.5 + width * 0.5 + 0.01

        if box.size.y < 1.3 or box.size.z < 1.3 then return false end

        box.position = box.position + vec3(displacement, displacement, displacement) * offset
        box.size = vec3(width, box.size.y, box.size.z)

        local blocks = {tree:getBlocksByBox(box)}

        -- if the only block contained, if any, is the block we're currently iterating, then we're good
        local free = false
        if #blocks == 0 then free = true end
        if #blocks == 1 and blocks[0] == block.index then free = true end

        return free
    end

    -- first, find all blocks that could potentially be spots for hangars
    local potentialBlocks = {}
    local numBlocks = plan.numBlocks
    for i = 0, numBlocks - 1 do
        local block = plan:getNthBlock(i)

        local potential
        local free = checkFree(block, vec3(1, 0, 0))
        if free then
            potential = {block = block, positive = true}
        end

        local free = checkFree(block, vec3(-1, 0, 0))
        if free then
            potential = potential or {block = block}
            potential.negative = true
        end

        if potential then
            table.insert(potentialBlocks, potential)
        end

    end

    local close = function(a, b, e)
        return math.abs(a - b) < e
    end

    -- find mirrored blocks
    for i = 1, #potentialBlocks do
        for j = i + 1, #potentialBlocks do
            local pa = potentialBlocks[i]
            local pb = potentialBlocks[j]

            local a = pa.block
            local b = pb.block

            local sa = a.box.size
            local sb = b.box.size

            if
                pa.positive ~= pb.positive
                and close(sa.x, sb.x, 0.01)
                and close(sa.y, sb.y, 0.01)
                and close(sa.z, sb.z, 0.01)
                and close(a.box.center.z, b.box.center.z, 0.01)
                then
                    pa.mirror = pb
                    pb.mirror = pa
            end
        end
    end

    -- sort by y * z area
    local comp = function(a, b)
        local s1 = a.block.box.size
        local s2 = b.block.box.size

        local area1 = s1.y * s1.z
        local area2 = s2.y * s2.z

        return area1 > area2
    end

    table.sort(potentialBlocks, comp)


    local equip = function(potential)
        potential.used = true

        local block = potential.block

        if potential.negative then
            local size = block.box.size
            size.x = math.max(size.x, 2)

            local pos = block.box.position - vec3((block.box.size.x + size.x) * 0.5, 0, 0)
            plan:addBlock(pos, size, block.index, -1, block.color, block.material, Matrix(), BlockType.Hangar)
        end

        if potential.positive then
            local size = block.box.size
            size.x = math.max(size.x, 2)

            local pos = block.box.position + vec3((block.box.size.x + size.x) * 0.5, 0, 0)
            plan:addBlock(pos, size, block.index, -1, block.color, block.material, Matrix(), BlockType.Hangar)
        end

    end

--    for _, potential in pairs(potentialBlocks) do
--        if potential.positive and potential.negative then
--            plan:setBlockColor(block.index, ColorRGB(1, 1, 0))
--        elseif potential.mirror then
--            plan:setBlockColor(block.index, ColorRGB(1, 0, 1))
--        else
--            plan:setBlockColor(block.index, ColorRGB(0, 1, 1))
--        end
--    end

    local equipped = 0
    for _, potential in pairs(potentialBlocks) do
        if potential.used then goto continue end

        equip(potential)
        if potential.mirror then
            equip(potential.mirror)
        end

        equipped = equipped + 1
        if equipped > 5 then break end

        ::continue::
    end

    CorrectInefficiencies(plan, 1)

    return plan
end

function PlanGenerator.makeFreighterPlan(faction, volume, styleName, material)
    local plan = PlanGenerator.makeShipPlan(faction, volume, styleName, material)

    local box = plan:getBoundingBox()
    local volume = plan.volume

    -- take the smallest axis, double the size, make a box and cut off everything that's not inside it
    -- this makes the ship approximately a cube

    local smallest = math.min(box.size.x, math.min(box.size.y, box.size.z))

    box = Box(plan:getBlock(0).box.position, vec3(smallest * 2.0, smallest * 2.0, smallest * 2.0))

    local l = box.lower
    local u = box.upper

    -- find all blocks that are inside the box
    local inside = {}
    for i = 0, plan.numBlocks - 1 do

        local block = plan:getNthBlock(i)
        local bl = block.box.lower
        local bu = block.box.upper

        if  u.x > bl.x
            and l.x < bu.x
            and u.y > bl.y
            and l.y < bu.y
            and u.z > bl.z
            and l.z < bu.z then
            inside[block.index] = true
        end
    end

    -- remove all blocks that are outside the box, starting with the children
    local remove = true
    while remove do
        remove = false

        for i = 0, plan.numBlocks - 1 do
            local block = plan:getNthBlock(i)

            if block.numChildren == 0 and not inside[block.index] then
                plan:removeBlock(block.index)
                remove = true
                break
            end
        end
    end

    -- find the front-most block
    local front = findMaxBlock(plan, "z")

    local attachment = BlockPlan()

    local mat = front.material
    local parent = front.index
    local block = BlockType.Quarters
    local s = front.box.size
    local p = front.box.position
    local c = front.color
    local o = Matrix()

    local container = PlanGenerator.makeContainerPlan({faction.color1, faction.color2, faction.color3})

    -- get right-most block and add a thruster to it
    local containerMaxBlock = findMaxBlock(container, "z")
    local containerMinBlock = findMinBlock(container, "z")

    -- add the thruster
    container:addBlock(containerMaxBlock.box.position + vec3(0, 0, containerMaxBlock.box.size.z + 1) * 0.5, vec3(1, 1, 1), containerMaxBlock.index, -1, c, mat, o, BlockType.Thruster)

    -- rotate the container from z alignment to x alignment
    container:rotate(vec3(0, 1, 0), 1)

    local cs = container:getBoundingBox().size
    cs.x = cs.x - 1.0

    local left = container
    local right = copy(left)
    right:mirror(vec3(1, 0, 0), vec3(0, 0, 0))

    local containerPadding = getFloat(0.5, 1.0)
    s.z = cs.z + containerPadding
    p.z = p.z - containerPadding

    local structureType = getInt(1, 3)
    local containers = getInt(7, 12)

    if structureType == 1 then
        for i = 1, containers do
            p.z = p.z + s.z
            parent = attachment:addBlock(p, s, parent, -1, c, mat, o, block)

            attachment:addPlanDisplaced(parent, left, 0, p + vec3((cs.x + s.x) * 0.5, 0, 0))
            attachment:addPlanDisplaced(parent, right, 0, p - vec3((cs.x + s.x) * 0.5, 0, 0))
        end
    elseif structureType == 2 then

        local up = copy(left)
        local down = copy(left)

        up:rotate(vec3(0, 0, 1), 1)
        down:rotate(vec3(0, 0, 1), -1)

        for i = 1, containers do
            p.z = p.z + s.z
            parent = attachment:addBlock(p, s, parent, -1, c, mat, o, block)

            attachment:addPlanDisplaced(parent, left, 0, p + vec3((cs.x + s.x) * 0.5, 0, 0))
            attachment:addPlanDisplaced(parent, right, 0, p - vec3((cs.x + s.x) * 0.5, 0, 0))

            attachment:addPlanDisplaced(parent, up, 0, p + vec3(0, (cs.x + s.y) * 0.5, 0))
            attachment:addPlanDisplaced(parent, down, 0, p - vec3(0, (cs.x + s.y) * 0.5, 0))
        end
    elseif structureType == 3 then
        s.y = cs.y * 1.5 + 1

        for i = 1, containers do
            p.z = p.z + s.z

            parent = attachment:addBlock(p, s, parent, -1, c, mat, o, block)

            attachment:addPlanDisplaced(parent, left, 0, p + vec3((cs.x + s.x) * 0.5, cs.y * 0.75, 0))
            attachment:addPlanDisplaced(parent, left, 0, p + vec3((cs.x + s.x) * 0.5, -cs.y * 0.75, 0))
            attachment:addPlanDisplaced(parent, right, 0, p - vec3((cs.x + s.x) * 0.5, cs.y * 0.75, 0))
            attachment:addPlanDisplaced(parent, right, 0, p - vec3((cs.x + s.x) * 0.5, -cs.y * 0.75, 0))
        end
    end

    -- scale the attachment and plan so they match with good volume relations
    local scale = (volume * 0.8 / attachment.volume) ^ (1.0 / 3.0)
    attachment:scale(vec3(scale, scale, scale))

    local scale = (volume * 0.2 / plan.volume) ^ (1.0 / 3.0)
    plan:scale(vec3(scale, scale, scale))

    local back = findMinBlock(attachment, "z")
    local front = findMaxBlock(plan, "z")

    local displace = vec3(front.box.position.x, front.box.position.y, front.box.upper.z) - vec3(back.box.position.x, back.box.position.y, back.box.lower.z)
    plan:addPlanDisplaced(front.index, attachment, attachment:getNthIndex(0), displace)

    CorrectInefficiencies(plan, 1)

    return plan
end

function PlanGenerator.makeShipPlan(faction, volume, styleName, material)
    local seed = math.random(0xffffffff)

    if not volume then
        volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());
        local deviation = Balancing_GetShipVolumeDeviation();
        volume = volume * deviation
    end

    if not material then
        material = PlanGenerator.selectMaterial(faction)
    end

    local style

    -- we must create the index here, before the 'if' so there is no asynchronous creation of random values
    -- otherwise the random values are different depending on whether there is a style yet or not
    local randomIndex = math.random(0xffffffff)

    if styleName == nil then
        -- no name for the style specified, just choose a random one.
        local styleNames = {faction:getShipStyleNames()}
        styleName = styleNames[(randomIndex % tablelength(styleNames)) + 1]

        style = faction:getShipStyle(styleName)

    else
        -- make sure the style exists, if it doesn't, create it.
        style = faction:getShipStyle(styleName)

        if style == nil then
            style = faction:createShipStyle(styleName)
        end
    end

    local plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, material)

    return plan
end

function PlanGenerator.makeStationPlan(faction, styleName, scale)
    scale = scale or 1.0

    local seed = math.random(0xffffffff)
    local volume = Balancing_GetSectorStationVolume(faction:getHomeSectorCoordinates());
    local deviation = Balancing_GetStationVolumeDeviation();
    volume = volume * deviation

    local material = PlanGenerator.selectMaterial(faction)
    local style;

    -- we must create the index here, before the 'if' so there is no asynchronous creation of random values
    -- otherwise the random values are different depending on whether there is a style yet or not
    local randomIndex = math.random(0xffffffff)

    if styleName == nil then
        -- no name for the style specified, just choose a random one.
        local styleNames = {faction:getStationStyleNames()}
        local numStyles = tablelength(styleNames)

        if numStyles == 0 then
            style = faction:createStationStyle("Style 1")
        else
            styleName = styleNames[(randomIndex % numStyles) + 1]
            style = faction:getStationStyle(styleName)
        end
    else
        -- make sure the style exists, if it doesn't, create it.
        style = faction:getStationStyle(styleName)

        if style == nil then
            style = faction:createStationStyle(styleName)
        end
    end

    plan = GeneratePlanFromStyle(style, Seed(seed), volume, 7500, 1, material)

    plan:scale(vec3(scale, scale, scale))

    return plan
end

function PlanGenerator.makeBigAsteroidPlan(size, resources, material, iterations)

    iterations = iterations or 10

    local directions = {
        vec3(1, 0, 0), vec3(-1, 0, 0),
        vec3(0, 1, 0), vec3(0, -1, 0),
        vec3(0, 0, 1), vec3(0, 0, -1)
    }

    local plan = PlanGenerator.makeSmallAsteroidPlan(1.0, resources, material)

    local centers = {plan:getBlock(0)}
    local numCenters = 1

    for i = 1, iterations do

        local center = centers[getInt(1, numCenters)]
        local dir = directions[getInt(1, 6)]

        -- make a plan and attach it to the selected center in the selected direction
        local other = PlanGenerator.makeSmallAsteroidPlan(1.0, resources, material)
        local otherCenter = other:getBlock(0)

        local displacement = (center.box.size + otherCenter.box.size) * dir * 0.5
        other:displace(displacement)

        local index = plan:addPlan(center.index, other, otherCenter.index)

        table.insert(centers, plan:getBlock(index))
        numCenters = numCenters + 1

    end

    local scale = size / plan.radius
    plan:scale(vec3(scale, scale, scale))

    return plan
end

function PlanGenerator.makeSmallAsteroidPlan(size, resources, material)

    resources = resources or 0

    local plan = BlockPlan()

    local color = material.blockColor

    local ls = vec3(getFloat(0.1, 0.5), getFloat(0.1, 0.5), getFloat(0.1, 0.5))
    local us = vec3(getFloat(0.1, 0.5), getFloat(0.1, 0.5), getFloat(0.1, 0.5))
    local s = vec3(1, 1, 1) - ls - us

    local hls = ls * 0.5
    local hus = us * 0.5
    local hs = s * 0.5

    local stone
    local edge
    local corner

    if resources == 0 then
        stone = BlockType.Stone
        edge = BlockType.StoneEdge
        corner = BlockType.StoneCorner
    else
        stone = BlockType.RichStone
        edge = BlockType.RichStoneEdge
        corner = BlockType.RichStoneCorner
    end

    local ci = plan:addBlock(vec3(0, 0, 0), s, -1, -1, color, material, Matrix(), stone)

    -- top bottom
    plan:addBlock(vec3(0, hs.y + hus.y, 0), vec3(s.x, us.y, s.z), ci, -1, color, material, Matrix(), stone)
    plan:addBlock(vec3(0, -hs.y - hls.y, 0), vec3(s.x, ls.y, s.z), ci, -1, color, material, Matrix(), stone)

    -- left right
    plan:addBlock(vec3(hs.x + hus.x, 0, 0), vec3(us.x, s.y, s.z), ci, -1, color, material, Matrix(), stone)
    plan:addBlock(vec3(-hs.x - hls.x, 0, 0), vec3(ls.x, s.y, s.z), ci, -1, color, material, Matrix(), stone)

    -- front back
    plan:addBlock(vec3(0, 0, hs.z + hus.z), vec3(s.x, s.y, us.z), ci, -1, color, material, Matrix(), stone)
    plan:addBlock(vec3(0, 0, -hs.z - hls.z), vec3(s.x, s.y, ls.z), ci, -1, color, material, Matrix(), stone)


    -- top left right
    plan:addBlock(vec3(hs.x + hus.x, hs.y + hus.y, 0), vec3(us.x, us.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 1, 0)), edge)
    plan:addBlock(vec3(-hs.x - hls.x, hs.y + hus.y, 0), vec3(ls.x, us.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0)), edge)

    -- top front back
    plan:addBlock(vec3(0, hs.y + hus.y, hs.z + hus.z), vec3(s.x, us.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, -1), vec3(0, 1, 0)), edge)
    plan:addBlock(vec3(0, hs.y + hus.y, -hs.z - hls.z), vec3(s.x, us.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, 1), vec3(0, 1, 0)), edge)

    -- bottom left right
    plan:addBlock(vec3(hs.x + hus.x, -hs.y - hls.y, 0), vec3(us.x, ls.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, -1, 0)), edge)
    plan:addBlock(vec3(-hs.x - hls.x, -hs.y - hls.y, 0), vec3(ls.x, ls.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, -1, 0)), edge)

    -- bottom front back
    plan:addBlock(vec3(0, -hs.y - hls.y, hs.z + hus.z), vec3(s.x, ls.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, -1), vec3(0, -1, 0)), edge)
    plan:addBlock(vec3(0, -hs.y - hls.y, -hs.z - hls.z), vec3(s.x, ls.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, 1), vec3(0, -1, 0)), edge)

    -- middle left right
    plan:addBlock(vec3(hs.x + hus.x, 0, -hs.z - hls.z), vec3(us.x, s.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 0, -1)), edge)
    plan:addBlock(vec3(-hs.x - hls.x, 0, -hs.z - hls.z), vec3(ls.x, s.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, -1)), edge)

    -- middle front back
    plan:addBlock(vec3(hs.x + hus.x, 0, hs.z + hus.z), vec3(us.x, s.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 0, 1)), edge)
    plan:addBlock(vec3(-hs.x - hls.x, 0, hs.z + hus.z), vec3(ls.x, s.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, 1)), edge)


    -- top edges
    -- left right
    plan:addBlock(vec3(hs.x + hus.x, hs.y + hus.y, -hs.z - hls.z), vec3(us.x, us.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 1, 0)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, hs.y + hus.y, -hs.z - hls.z), vec3(ls.x, us.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, -1)), corner)

    -- front back
    plan:addBlock(vec3(hs.x + hus.x, hs.y + hus.y, hs.z + hus.z), vec3(us.x, us.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 0, 1)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, hs.y + hus.y, hs.z + hus.z), vec3(ls.x, us.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0)), corner)

    -- bottom edges
    -- left right
    plan:addBlock(vec3(hs.x + hus.x, -hs.y - hls.y, -hs.z - hls.z), vec3(us.x, ls.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, 1), vec3(0, -1, 0)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, -hs.y - hls.y, -hs.z - hls.z), vec3(ls.x, ls.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, -1, 0)), corner)

    -- front back
    plan:addBlock(vec3(hs.x + hus.x, -hs.y - hls.y, hs.z + hus.z), vec3(us.x, ls.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, -1, 0)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, -hs.y - hls.y, hs.z + hus.z), vec3(ls.x, ls.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, -1), vec3(0, -1, 0)), corner)

    plan:scale(vec3(getFloat(0.3, 1.5), getFloat(0.3, 1.5), getFloat(0.3, 1.5)))

    local r = size * 2.0 / plan.radius
    plan:scale(vec3(r, r, r))

    plan.convex = true

    return plan

end

function PlanGenerator.makeGatePlan(seed, color1, color2, color3)

	local r = random()
	local random = r

	if seed then random = Random(seed) end

    local bright = color1 or ColorRGB(0.5, 0.5, 0.5)
    local dark = color2 or ColorRGB(0.25, 0.25, 0.25)
	local colored = color3 or ColorHSV(random:getFloat(0, 360), random:getFloat(0.5, 0.7), random:getFloat(0.4, 0.6))
    local iron = Material()
    local orientation = Matrix()
    local block = BlockType.BlankHull
    local edge = BlockType.EdgeHull

	local slopes = random:getFloat() < 0.5 and true or false
	local lightLines = random:getFloat() < 0.35 and true or false
	local rings = false
	local rings2 = false
	local rings3 = false
	local bubbleLights = false
	local secondaryLine = random:getFloat() < 0.5 and true or false
	local secondaryArms = random:getFloat() < 0.35 and true or false

	if not lightLines then
		rings = random:getFloat() < 0.5 and true or false
		rings2 = random:getFloat() < 0.5 and true or false
	end

	if not slopes and not rings then
		rings3 = true
	end

	if not lightLines then
		bubbleLights = true
	end

	local segment = BlockPlan()

	-- make main arm
	-- create 2 possible thicknesses for the default blocks
	local t1 = random:getFloat(1.3, 1.75)
	local t2 = random:getFloat(0.75, 1.3)

	-- choose from the 2 thicknesses
	local ta =  t2
	local tb = random:getFloat() < 0.5 and t1 or t2
	local tc = random:getFloat() < 0.5 and t1 or t2

	local ca = random:getFloat() < 0.5 and bright or dark
	local cb = random:getFloat() < 0.5 and bright or dark
	local cc = random:getFloat() < 0.5 and bright or dark
	local cd = bright

	if not slopes then cd = colored end

	local root = segment:addBlock(vec3(0, 1 + 1, 0), vec3(ta, 2, ta), -1, -1, ca, iron, orientation, block)
	local a = root

	local b = segment:addBlock(vec3(0, 1 + 3, 0), vec3(tb, 2, tb), a, -1, cb, iron, orientation, block)
	local c = segment:addBlock(vec3(0, 1 + 5, 0), vec3(tc, 2, tc), b, -1, cc, iron, orientation, block)
	local d = segment:addBlock(vec3(0, 1 + 7, 0), vec3(2.5, 2.5, 2.5), c, -1, cd, iron, orientation, block)

	-- antennae front back
	-- segment:addBlock(vec3(0, 1 + 7, 2), vec3(0.2, 0.2, 2.5), last, -1, white, iron, orientation, block)
	-- segment:addBlock(vec3(0, 1 + 7, -2), vec3(0.2, 0.2, 2.5), last, -1, white, iron, orientation, block)

	-- antennae outside
	local antennae = random:getInt(2, 4)

	for i = 1, antennae do
		local p = random:getVector(-1, 1)
		local f = random:getFloat(0.25, 1.75)
		p.x = 0;

		local s = vec3(2.5, 0.05, 0.05) * f
		segment:addBlock(vec3(2 + s.x * 0.5 - 1, 1 + 7, 0) + p, s, last, -1, bright, iron, orientation, block)
	end

	if secondaryLine then
		segment:addBlock(vec3(1, 1 + 2.875, 0), vec3(0.5, 5.75, 0.5), a, -1, ca, iron, MatrixLookUp(vec3(0, 1, 0), vec3(0, 0, -1)), BlockType.Light)
	end

	if bubbleLights then
		segment:addBlock(vec3(0, 1 + 7, 1.5), vec3(0.75, 0.75, 2), d, -1, ca, iron, MatrixLookUp(vec3(0, 1, 0), vec3(0, 0, -1)), BlockType.Light)
		segment:addBlock(vec3(0, 1 + 7, -1.5), vec3(0.75, 0.75, 2), d, -1, ca, iron, MatrixLookUp(vec3(0, 1, 0), vec3(0, 0, 1)), BlockType.Light)
	end

	if rings then
		local h = 0.1

		segment:addBlock(vec3(0, 1 + 1, 0), vec3(ta, h, ta) + h, a, -1, ca, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 3, 0), vec3(tb, h, tb) + h, b, -1, cb, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 5, 0), vec3(tc, h, tc) + h, c, -1, cc, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 7, 0), vec3(2.5, h, 2.5) + h, d, -1, bright, iron, orientation, block)
	end

	if rings2 then
		local h = 0.1

		segment:addBlock(vec3(0, 1 + 1, 0), vec3(h, 2.5, ta) + h, a, -1, ca, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 3, 0), vec3(h, 2.5, tb) + h, b, -1, cb, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 5, 0), vec3(h, 2.5, tc) + h, c, -1, cc, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 7, 0), vec3(h, 2.5, 2.5) + h, d, -1, bright, iron, orientation, block)
	end

	if rings3 then
		local h = 0.5

		segment:addBlock(vec3(0, 1 + 1, 0), vec3(ta, h, ta) + h, a, -1, ca, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 3, 0), vec3(tb, h, tb) + h, b, -1, cb, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 5, 0), vec3(tc, h, tc) + h, c, -1, cc, iron, orientation, block)
	end

	if lightLines then
		local h = 0.05

		local block = BlockType.Glow
		local color = copy(colored)
		color.value = 1.0

		segment:addBlock(vec3(0, 1 + 1, 0), vec3(h, 2, ta) + h, a, -1, color, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 3, 0), vec3(h, 2, tb) + h, b, -1, color, iron, orientation, block)
		segment:addBlock(vec3(0, 1 + 5, 0), vec3(h, 2, tc) + h, c, -1, color, iron, orientation, block)

		if random:getFloat() < 0.5 then
			segment:addBlock(vec3(0, 1 + 7, 0), vec3(2.5, h, 2.5) + h, d, -1, color, iron, orientation, block)
		else
			segment:addBlock(vec3(0, 1 + 7, 0), vec3(h, 2.5, 2.5) + h, d, -1, color, iron, orientation, block)
		end
	end

	if slopes then
		-- slope segments
		local slopeWidth = random:getFloat(t1 + 0.1, 2.5) -- 2.0 to 2.5, but always smaller than the biggest last element
		local slopeColor = colored -- one of the 3
		local slopeHeight = random:getFloat(0.5, 1.5)
		local slopeDist = random:getFloat() < 0.15 and slopeHeight * 0.125 or random:getFloat(slopeHeight * 0.15, slopeHeight * 0.5)
		local slopeStart = random:getFloat(3.0, 5.0)

		local w = slopeWidth
		local hw = w * 0.5
		local h = slopeHeight
		local hh = h * 0.5
		local m1 = MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0))
		local m2 = MatrixLookUp(vec3(-1, 0, 0), vec3(0, -1, 0))

		for p = slopeStart, 7, slopeDist * 2.0 do
			segment:addBlock(vec3(-hw * 0.5, p, 0), vec3(hw, hh, w), last, -1, slopeColor, iron, m1, edge)
			segment:addBlock(vec3(hw * 0.5, p + hh, 0), vec3(hw, hh, w), last, -1, slopeColor, iron, m1, edge)

			segment:addBlock(vec3(-hw * 0.5, p - hh, 0), vec3(hw, hh, w), last, -1, slopeColor, iron, m2, edge)
			segment:addBlock(vec3(hw * 0.5, p, 0), vec3(hw, hh, w), last, -1, slopeColor, iron, m2, edge)
		end
	end

	local arm = nil
	if secondaryArms then
		arm = copy(segment)
	end

    local size = vec3(2, 2, 2)
	local plan = BlockPlan()
    local root = plan:addBlock(vec3(0, -10, 0), size, -1, -1, bright, iron, orientation, block)
    plan:addBlock(vec3(0, 10, 0), size, root, -1, bright, iron, orientation, block)

    plan:addBlock(vec3(10, 0, 0), size, root, -1, bright, iron, orientation, block)
    plan:addBlock(vec3(-10, 0, 0), size, root, -1, bright, iron, orientation, block)

	-- default
	segment:displace(vec3(10, 0, 0))
	plan:addPlan(0, segment, 0)

	-- mirrored down
	segment:mirror(vec3(0, 1, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	-- mirrored down other side
	segment:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	-- default other side
	segment:mirror(vec3(0, 1, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	-- turned
	segment:rotate(vec3(0, 0, 1), 1)
	plan:addPlan(0, segment, 0)

	segment:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	segment:mirror(vec3(0, 1, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	segment:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
	plan:addPlan(0, segment, 0)

	if secondaryArms then
		if random:getFloat() < 0.5 then
			arm:rotate(vec3(0, 0, 1), 1)
			arm:displace(vec3(-10, 0, 0))
			plan:addPlan(0, arm, 0)

			arm:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
			plan:addPlan(0, arm, 0)
		else
			arm:rotate(vec3(0, 0, 1), 1)
			arm:rotate(vec3(0, 1, 0), 1)

			arm:displace(vec3(-10, 0, 0))
			plan:addPlan(0, arm, 0)

			arm:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
			plan:addPlan(0, arm, 0)

			if random:getFloat() < 0.5 then
				arm:mirror(vec3(0, 0, 1), vec3(0, 0, 0))
				plan:addPlan(0, arm, 0)

				arm:mirror(vec3(1, 0, 0), vec3(0, 0, 0))
				plan:addPlan(0, arm, 0)
			end

		end
	end

    plan:addBlock(vec3(0, 0, 0), vec3(20, 20, 0.1), root, -1, bright, iron, orientation, BlockType.Portal)

    local scale = 6
    plan:scale(vec3(scale, scale, scale))
    return plan
end

function PlanGenerator.makeBeaconPlan(colors)
    local container = PlanGenerator.makeContainerPlan(colors)

    container:scale(vec3(0.5, 0.5, 2))


    local maxZ = findMaxBlock(container, "z")
    local minZ = findMinBlock(container, "z")

    container:addBlock(maxZ.box.position + vec3(0, 0, maxZ.box.size.z), maxZ.box.size, maxZ.index, -1, maxZ.color, maxZ.material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, 1)), BlockType.Light)
    container:addBlock(minZ.box.position - vec3(0, 0, minZ.box.size.z), minZ.box.size, minZ.index, -1, minZ.color, minZ.material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, -1)), BlockType.Light)



    return container
end

function PlanGenerator.makeContainerPlan(colors_in)
    local plan = BlockPlan()

    -- create root block
    local root = plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)


    local brightColor = getFloat(0.75, 1);
    local darkColor = getFloat(0.2, 0.6);

    local colors = colors_in
    if colors == nil then
        colors = {}
        table.insert(colors, ColorRGB(brightColor, brightColor, brightColor))
        table.insert(colors, ColorRGB(darkColor, darkColor, darkColor))
        table.insert(colors, ColorRGB(math.random(), math.random(), math.random()))
    end

    -- maybe add to front, back, top, bottom
    if math.random() < 0.2 then
        local size = math.random() * 1.5 + 0.5 -- 0.5 to 2.0

        local color = colors[math.random(1, 3)]

        plan:addBlock(vec3(0, 1 + size / 2, 0), vec3(size, size, size), root, -1, color, Material(), Matrix(), BlockType.CargoBay)
        plan:addBlock(vec3(0, -(1 + size / 2), 0), vec3(size, size, size), root, -1, color, Material(), Matrix(), BlockType.CargoBay)
    end

    if math.random() < 0.2 then
        local size = math.random() * 1.5 + 0.5 -- 0.5 to 2.0

        local color = colors[math.random(1, 3)]

        plan:addBlock(vec3(1 + size / 2, 0, 0), vec3(size, size, size), root, -1, color, Material(), Matrix(), BlockType.CargoBay)
        plan:addBlock(vec3(-(1 + size / 2), 0, 0), vec3(size, size, size), root, -1, color, Material(), Matrix(), BlockType.CargoBay)
    end



    -- now add to the sides
    local blockPairs = {}
    local added = 0
    local maxAdded = math.random() * 2.5 + 1.5 -- 1.5 to 4.0
    while added < maxAdded do
        local thickness;
        local size = math.random() * 1.0 + 1.5 -- 1.5 to 2.5

        if math.random() < 0.3 then
            thickness = math.random() * 0.2 + 0.1 -- 0.1 to 0.3
        else
            thickness = math.random() * 1.5 + 0.5 -- 0.5 to 2.0
        end

        local color = colors[math.random(1, 3)]

        local a = plan:addBlock(vec3(0, 0, added + thickness / 2), vec3(size, size, thickness), root, -1, color, Material(), Matrix(), BlockType.CargoBay)
        local b = plan:addBlock(vec3(0, 0, -(added + thickness / 2)), vec3(size, size, thickness), root, -1, color, Material(), Matrix(), BlockType.CargoBay)

        if thickness > 1.0 then
            table.insert(blockPairs, {a = a, b = b})
        end

        added = added + thickness
    end

    for i, blocks in pairs(blockPairs) do
        if math.random() < 0.3 then
            -- add x blocks
            local newWidth = math.random() * 0.3 + 0.7 -- 0.7 to 1.0
            local newThick = math.random() * 0.2 + 0.1 -- 0.1 to 0.3
            local newSize = vec3(newThick, newWidth, newWidth)

            -- block a
            local size = plan:getBlock(blocks.a).box.size

            -- +x
            local newPos = plan:getBlock(blocks.a).box.position
            newPos.x = newPos.x + (size.x / 2 + newSize.x / 2)
            plan:addBlock(newPos, newSize, blocks.a, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

            -- -x
            local newPos = plan:getBlock(blocks.a).box.position
            newPos.x = newPos.x - (size.x / 2 + newSize.x / 2)
            plan:addBlock(newPos, newSize, blocks.a, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)


            -- block b
            local size = plan:getBlock(blocks.b).box.size

            -- +x
            local newPos = plan:getBlock(blocks.b).box.position
            newPos.x = newPos.x + (size.x / 2 + newSize.x / 2)
            plan:addBlock(newPos, newSize, blocks.b, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

            -- -x
            local newPos = plan:getBlock(blocks.b).box.position
            newPos.x = newPos.x - (size.x / 2 + newSize.x / 2)
            plan:addBlock(newPos, newSize, blocks.b, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

        end

        if math.random() < 0.3 then
            -- add x blocks
            local newWidth = getFloat(0.7, 1.0) -- 0.7 to 1.0
            local newThick = getFloat(0.1, 0.5) -- 0.1 to 0.5
            local newSize = vec3(newWidth, newThick, newWidth)

            -- block a
            local size = plan:getBlock(blocks.a).box.size

            -- +y
            local newPos = plan:getBlock(blocks.a).box.position
            newPos.y = newPos.y + (size.y / 2 + newSize.y / 2)
            plan:addBlock(newPos, newSize, blocks.a, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

            -- -y
            local newPos = plan:getBlock(blocks.a).box.position
            newPos.y = newPos.y - (size.y / 2 + newSize.y / 2)
            plan:addBlock(newPos, newSize, blocks.a, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)


            -- block b
            local size = plan:getBlock(blocks.b).box.size

            -- +y
            local newPos = plan:getBlock(blocks.b).box.position
            newPos.y = newPos.y + (size.y / 2 + newSize.y / 2)
            plan:addBlock(newPos, newSize, blocks.b, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

            -- -y
            local newPos = plan:getBlock(blocks.b).box.position
            newPos.y = newPos.y - (size.y / 2 + newSize.y / 2)
            plan:addBlock(newPos, newSize, blocks.b, -1, ColorRGB(1, 1, 1), Material(), Matrix(), BlockType.CargoBay)

        end

    end

    local scale = getFloat(0.8, 1.3)
    plan:scale(vec3(scale, scale, scale))

    return plan
end


return PlanGenerator
