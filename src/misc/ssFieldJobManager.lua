---------------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To manage fields owned by the NPC according to seasons
-- Authors:  theSeb, baron
--

ssFieldJobManager = {}
g_seasons.fieldJobManager = ssFieldJobManager

function ssFieldJobManager:preLoad()
    FieldJob.init = Utils.overwrittenFunction(FieldJob.init,ssFieldJobManager.fieldJobInit)
    FieldJobManager.update = Utils.overwrittenFunction(FieldJobManager.update, ssFieldJobManager.fieldJobManagerUpdate)
end

function ssFieldJobManager:load(savegame, key)
    self.disableMissions = ssStorage.getXMLBool(savegame, key .. ".settings.disableMissions", false)
end

function ssFieldJobManager:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.disableMissions", self.disableMissions)
end

function ssFieldJobManager:loadMap(name)
   if not (g_currentMission.fieldDefinitionBase ~= nil and g_currentMission.fieldDefinitionBase.fieldDefs ~= nil) then return end

    for _,fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        fieldDef.fieldJobUsageAllowed = not self.disableMissions and fieldDef.fieldJobUsageAllowed
    end
end

--filter what jobs are carried out by the FieldJobManager
function ssFieldJobManager:fieldJobManagerUpdate(superFunc, dt)
    if self.coverCounter == nil then self.coverCounter = 0 end; --FIXME: maybe when ssFieldJobManager initializes?
    
    if self.coverCounter > 500 or self.currentFieldPartitionIndex ~= nil or self:isFieldJobActive() then
        superFunc(self, dt + self.coverCounter)
        self.coverCounter = 0
        
        --check if field job was started by NPC, terminate if not appropriate for current season
        if self.fieldStatusParametersToSet ~= nil and self.currentFieldPartitionIndex == nil then
            local paramFieldNumber      = self.fieldStatusParametersToSet[1].fieldNumber
            -- local paramFruitType        = self.fieldStatusParametersToSet[1].missionFruitType --current growing fruit
            -- local paramFruitType         = self.fieldStatusParametersToSet[4] -- not filltype
            local paramSetState         = self.fieldStatusParametersToSet[5] --FieldJobManager.FIELDSTATE_*

            local stateToJob = {[FieldJobManager.FIELDSTATE_CULTIVATED] = FieldJob.TYPE_CULTIVATING,
                                [FieldJobManager.FIELDSTATE_PLOUGHED] = FieldJob.TYPE_PLOUGHING,
                                [FieldJobManager.FIELDSTATE_HARVESTED] = FieldJob.TYPE_HARVESTING,
                                [FieldJobManager.FIELDSTATE_GROWING] = FieldJob.TYPE_SOWING}

            if not g_seasons.fieldJobManager.isFieldJobAllowed(stateToJob[paramSetState], true) then
                self.fieldStatusParametersToSet = nil -- This makes FieldJobManager never begin work and will check next field on next update 
            end
        end    
    else -- Use cover counter to prevent the FieldJobManager to initiate a job on every update
        self.coverCounter = self.coverCounter + dt
    end
end

--filter mission assignments to the player
function ssFieldJobManager:fieldJobInit(superFunc, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    if superFunc(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7) then
        return ssFieldJobManager.isFieldJobAllowed(self.jobType, false)
    end

    return false
end

--fieldJob: FieldJob.TYPE_*
--isNPC:    bool
function ssFieldJobManager.isFieldJobAllowed(fieldJob, isNPC)
    local currentGT = g_seasons.environment:growthTransitionAtDay()
    local env = g_seasons.environment

    -- Allow nothing when ground is frozen
    if g_seasons.weather:isGroundFrozen() then
        return false
    end

    -- Always allow fertilizing missions, unless rain
    if fieldJob == FieldJob.TYPE_FERTILIZING_GROWING or fieldJob == FieldJob.TYPE_FERTILIZING_HARVESTED or fieldJob == FieldJob.TYPE_FERTILIZING_SOWN then
        return not (g_currentMission.environment.timeSinceLastRain == 0)
    -- Always allow user assigned missions to cultivate
    -- NPC only cultivates in early-mid spring
    elseif fieldJob == FieldJob.TYPE_PLOUGHING or fieldJob == FieldJob.TYPE_CULTIVATING then
        if isNPC then
            return currentGT >= env.TRANSITION_EARLY_SPRING and currentGT <= env.TRANSITION_MID_SPRING
        else
            return true
        end
    -- Never allow harvesting wet crop
    -- NPC only harvests in mid autumn - early winter
    -- Always allow user assigned missions to harvest
    elseif fieldJob == FieldJob.TYPE_HARVESTING then
        if g_seasons.weather:isCropWet() then
            return false
        end

        if isNPC then
            return currentGT >= env.TRANSITION_MID_AUTUMN and currentGT <= env.TRANSITION_EARLY_WINTER
        else
            return true
        end
    -- Only allow seeding in spring - early summer
    -- NPC only seeds in late spring
    elseif fieldJob == FieldJob.TYPE_SOWING then
        if isNPC then
            return currentGT == env.TRANSITION_LATE_SPRING
        else
            return currentGT >= env.TRANSITION_EARLY_SPRING and currentGT <= env.TRANSITION_EARLY_SUMMER
        end
    end

    -- Disallow everything unknown
    return false
end