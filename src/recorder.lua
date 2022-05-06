---@class Recorder
---@field total number
---@field progress integer
---@field messages string[]
local Recorder = {}
Recorder.__index = Recorder

function Recorder:new(total)
    local this = setmetatable({}, Recorder)

    this.total = total
    this.progress = 0
    this.messages = {}

    return this
end

function Recorder:init(total)
    self.total = total
    self.progress = 0
end

function Recorder:notify(n, msg)
    self.progress = self.progress + n
    local prompt = msg ~= ""
        and string.format("current: %d/%d - %s", self.progress, self.total, msg)
        or string.format("current: %d/%d", self.progress, self.total)
    print(prompt)
end

return Recorder
