---------------------------------------------------------------------------------------------------------
-- BANK SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  A new bank
-- Authors:  Rahkiin (Jarvixes), reallogger
--

ssBank = {}
ssBank.EQUITY_LOAN_RATIO = 0.7

ssBank.loan = 0
ssBank.settingsProperties = { "loan" }


function ssBank.preSetup()
    ssSettings.add("bank", ssBank)
end

function ssBank.setup()
    ssSettings.load("bank", ssBank)

    addModEventListener(ssBank)
end

function ssBank:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);

    -- Disable the vanilla financing
    g_currentMission.missionStats.loanMax = 0

    if g_currentMission.missionStats.loan ~= 0 then
        self:setLoan(g_currentMission.missionStats.loan)
        g_currentMission.missionStats.loan = 0
    end

    log("Cap: "..self:getCap())
end

function ssBank:deleteMap()
end

function ssBank:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssBank:keyEvent(unicode, sym, modifier, isDown)
end

function ssBank:draw()
end

function ssBank:update(dt)
end

function ssBank:updateTick(dt)
end

function ssBank:dayChanged()
end

function ssBank:setLoan(loan)
    loan = math.max(loan, 0)

    local moneyChange = loan - ssBank.loan
    ssBank.loan = loan

    ssSettings.set("bank", "loan", loan)

    if moneyChange > 0 then
        -- Add money!
    elseif moneyChange < 0 then
        -- Remove money!
    end
end

-- Calculate equity by summing all owned land. I know this is not
-- economically correct but it is the best we got for a value that moves
-- up as the game progresses
function ssBank:getEquity()
    local price = 0

    for _, field in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        if field.ownedByPlayer then
            price = price + field.fieldPriceInitial
        end
    end

    return price
end

-- Get the loan cap
function ssBank:getCap()
    return math.max(200000, ssBank.EQUITY_LOAN_RATIO * self:getEquity())
end

--[[

EconomyManager.MONEY_TYPE_LOAN_INTEREST

]]
