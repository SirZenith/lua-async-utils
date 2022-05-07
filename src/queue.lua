local copas = require "copas"

---@class Queue
---@field limit integer Maximum number of element in queue.
---@field _size integer Number of element currently in queue.
---@field _is_closed boolean Whether queue is closed for sending.
---@field _queue any[] Internal table for storing data.
local Queue = {}
Queue.__index = Queue

---@param limit integer
---@return Queue
function Queue:new(limit)
    limit = limit or 0
    local this = setmetatable({}, self)

    this.limit = limit
    this._size = 0
    this._is_closed = false
    this._queue = {}

    return this
end

-- Non-blockingly push an item into queue, return true if successed, return false
-- if queue is closed.
---@param item any
---@return boolean
function Queue:push(item)
    -- nil is used by Queue:pop to indicate no more element, so manually insert
    -- nil should be forbidden.
    if item == nil then return end

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

-- Non-blockingly pop item from queue, return item if successed, return nil when
-- queue is closed and no more data left in the queue.
---@return any
function Queue:pop()
    while not self:is_closed() do
        if self._size == 0 then
            copas.sleep(0)
        else
            self._size = self._size - 1
            return table.remove(self._queue, 1)
        end
    end
    return nil
end

-- Close sending side of queue, indicating no more data should be sent into this
-- queue.
function Queue:close()
    self._is_closed = true
end

-- Check if sending side of queue is closed.
---@return boolean
function Queue:is_closed()
    return self._size == 0 and self._is_closed
end

return Queue
