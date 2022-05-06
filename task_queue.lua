local copas = require "copas"

local TaskQueue = {}
TaskQueue.limit = 0
TaskQueue._size = 0
TaskQueue._is_closed = false
TaskQueue._queue = {}

function TaskQueue:new(limit)
    limit = limit or 0
    self.__index = self
    local this = setmetatable({}, self)
    this.limit = limit
    this._size = 0
    this._queue = {}
    return this
end

--[[
non-blocking push a item into queue, return true if successed, return false if
queue is closed.
]]
function TaskQueue:push(item)
    while not self._is_closed do
        if self._size >= self.limit then
            copas.sleep(0)
        else
            self._size = self._size + 1
            self._queue[self._size] = item
            return true
        end
    end
    return false
end

--[[
non-blocking pop item from queue, return item if successed, return nil when queue
is closed and no more data left in the queue.
]]
function TaskQueue:pop()
    while not self:is_closed() do
        if self._size == 0 then
            copas.sleep(0.1)
        else
            self._size = self._size - 1
            return table.remove(self._queue, 1)
        end
    end
    return nil
end

function TaskQueue:close()
    self._is_closed = true
end

function TaskQueue:is_closed()
    return self._size == 0 and self._is_closed
end

return TaskQueue
