----------------------------------------------------------------------------------------------------
-- QUEUE CLASS
----------------------------------------------------------------------------------------------------
-- Purpose:  Performs updates of density maps on behalf of other modules.
-- Authors:  mrbear, Rahkiin
--
-- A fast implementation of queue(actually double queue) in Lua is done by the book Programming in Lua:
-- http://www.lua.org/pil/11.4.html
-- Reworked by MrBear
--
-- Complete rewrite by Rahkiin
--
-- Reworked again by using a full doubly linked list, to be able to remove in the middle.
-- Only supports objects. https://gist.github.com/BlackBulletIV/4084042
--
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssQueue = {}
local ssQueue_mt = Class(ssQueue)

function ssQueue:new()
    local self = {}
    setmetatable(self, ssQueue_mt)

    self.size = 0

    return self
end

-- Add an item to the end of the list
function ssQueue:push(value)
    if self.last then
        value._prev = self.last
        self.last._next = value
        self.last = value
    else
        -- First node
        self.first = value
        self.last = value
    end

    self.size = self.size + 1
end

-- Remove an item from the beginning of the list
function ssQueue:pop()
    if not self.first then return end

    local value = self.first

    if value._next then
        value._next._prev = nil
        self.first = value._next
        value._next = nil
    else
        self.first = nil
        self.last = nil
    end

    self.size = self.size - 1

    return value
end

function ssQueue:remove(value, mutateIterating)
    if value._next then
        if value._prev then
            value._next._prev = value._prev
            value._prev._next = value._next
        else
            value._next._prev = nil
            self.first = value._next
        end
    elseif value._prev then
        value._prev._next = nil
        self._last = value._prev
    else
        self.first = nil
        self.last = nil
    end

    -- Normally, this should be emptied
    -- However, the only place it is currently used is inside a loop
    -- of the iteratePushOrder. One can't mutate the list you iterate
    -- over, unless this is commented out
    if mutateIterating ~= true then
        value._next = nil
        value._prev = nil
    end

    self.size = self.size - 1
end

function ssQueue:isEmpty()
    return self.first == nil
end

-- Iterate over all items in the order they
-- should be pushed to copy the queue.
-- This is from first to last.
function ssQueue:iteratePushOrder(func)
    local i = 1
    local item = self.first

    while item ~= nil do
        func(item, i)

        i = i + 1
        item = item._next
    end
end
