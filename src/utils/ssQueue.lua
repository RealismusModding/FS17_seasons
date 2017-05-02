----------------------------------------------------------------------------------------------------
-- QUEUE CLASS
----------------------------------------------------------------------------------------------------
-- Purpose:  Performs updates of density maps on behalf of other modules.
-- Authors:  mrbear, Rahkiin
--
-- A fast implementation of queue(actually double queue) in Lua is done by the book Programming in Lua:
-- http://www.lua.org/pil/11.4.html
-- Reworked by MrBear
-- Complete rewrite by Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssQueue = {}
local ssQueue_mt = Class(ssQueue)

function ssQueue:new()
    local self = {}
    setmetatable(self, ssQueue_mt)

    self.first = 0
    self.last = -1
    self.items = {}
    self.size = 0

    return self
end

-- Add an item after the 'last' position
function ssQueue:push(value) -- right
    local last = self.last + 1

    self.last = last
    self.items[last] = value
    self.size = self.size + 1
end

-- Get an item at the 'first' position (FIFO)
function ssQueue:pop() -- left
    local first = self.first

    -- Check for empty queue
    if self:isEmpty() then
        return nil
    end

    local value = self.items[first]
    self.items[first] = nil

    self.first = first + 1
    self.size = self.size - 1

    return value
end

function ssQueue:isEmpty()
    return self.first > self.last
end

-- Iterate over all items in the order they
-- should be pushed to copy the queue.
-- This is from first to last.
function ssQueue:iteratePushOrder(func)
    local i = 1

    for p = self.first, self.last, 1 do
        item = self.items[p]

        if item ~= nil then
            func(item, i)

            i = i + 1
        end
    end
end
