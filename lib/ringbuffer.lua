local RingBuffer = {}
RingBuffer.__index = RingBuffer

local function new(max)
    return setmetatable({data = {}, max = max, index = 0}, RingBuffer)
end

function RingBuffer:insert(element)
    self.data[self.index + 1] = element
    self.index = ((self.index + 1) % self.max)
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
