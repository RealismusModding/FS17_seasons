----------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To manage fields owned by the NPC according to seasons
-- Authors:  theSeb, baron
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssFieldJobManager = {}
g_seasons.fieldJobManager = ssFieldJobManager

function ssFieldJobManager:preLoad()
    FieldJob.init = Utils.overwrittenFunction(FieldJob.init, ssFieldJobManager.fieldJobInit)
    FieldJob.finish = Utils.overwrittenFunction(FieldJob.finish, ssFieldJobManager.fieldJobFinish)
    FieldJobManager.update = Utils.overwrittenFunction(FieldJobManager.update, ssFieldJobManager.fieldJobManagerUpdate)
end

function ssFieldJobManager:loadMap(name)
end

-- Filter what jobs are carried out by the FieldJobManager
function ssFieldJobManager:fieldJobManagerUpdate(superFunc, dt)
    if self.coverCounter == nil then self.coverCounter = 0 end; --FIXME: maybe when ssFieldJobManager initializes?

    if self.coverCounter > 500 or self.currentFieldPartitionIndex ~= nil or self:isFieldJobActive() then
        superFunc(self, dt + self.coverCounter)
        self.coverCounter = 0

        -- Check if field job was started by NPC, terminate if not appropriate for current season
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

-- Filter mission assignments to the player
function ssFieldJobManager:fieldJobInit(superFunc, ...)
    local initFieldJob = superFunc(self, ...)

    -- If superFunc has reset snow, we need to re-apply it
    if ssSnow.appliedSnowDepth > 0 then
        self:applyFieldSnow(ssSnow.appliedSnowDepth / ssSnow.LAYER_HEIGHT)
    end

    if initFieldJob then
        if not ssFieldJobManager.isFieldJobAllowed(self.jobType, false) then
            initFieldJob = false
        else
            -- Update income
            local pricePerMS = ssUtil.isWorkHours() and g_seasons.economy.aiPricePerMSWork or g_seasons.economy.aiPricePerMSOverwork

            -- Add difficulty factor
            local difficultyFactor = 0.8
            if g_currentMission.missionInfo.difficulty == 2 then
                difficultyFactor = 1.0
            elseif g_currentMission.missionInfo.difficulty == 1 then
                difficultyFactor = 1.2
            end

            -- Time left at this point is the full time
            self.reward = pricePerMS * self.timeLeft * 5 * difficultyFactor
        end
    end

    return initFieldJob
end

function ssFieldJobManager:fieldJobFinish(superFunc, ...)
    -- Set time left to 0 to disable time bonus
    self.timeLeft = 0

    local returnValue = superFunc(self, ...)

    -- If superFunc has reset snow, we need to re-apply it
    if ssSnow.appliedSnowDepth > 0 then
        self:applyFieldSnow(ssSnow.appliedSnowDepth / ssSnow.LAYER_HEIGHT)
    end

    return returnValue
end

-- fieldJob: FieldJob.TYPE_*
-- isNPC:    bool
function ssFieldJobManager.isFieldJobAllowed(fieldJob, isNPC)
    local currentGT = g_seasons.environment:transitionAtDay()
    local env = g_seasons.environment

    -- Use vanilla FieldJobManager if not using seasons growthManager
    if not g_seasons.growthManager.growthManagerEnabled then return true end

    -- Allow nothing when ground is frozen or snow-covered
    if g_seasons.weather:isGroundFrozen() or g_seasons.snow.appliedSnowDepth > 0 then return false end

    -- Always allow fertilizing missions
    if fieldJob == FieldJob.TYPE_FERTILIZING_GROWING or fieldJob == FieldJob.TYPE_FERTILIZING_HARVESTED or fieldJob == FieldJob.TYPE_FERTILIZING_SOWN then
        return true
    -- Always allow user assigned missions to cultivate
    -- NPC only cultivates in spring
    elseif fieldJob == FieldJob.TYPE_PLOUGHING or fieldJob == FieldJob.TYPE_CULTIVATING then
        if isNPC then
            return currentGT >= env.TRANSITION_EARLY_SPRING and currentGT <= env.TRANSITION_LATE_SPRING
        else
            return true
        end
    -- Never allow harvesting wet crop
    -- NPC only harvests in late autumn
    -- Always allow user assigned missions to harvest
    elseif fieldJob == FieldJob.TYPE_HARVESTING then
        if g_seasons.weather:isCropWet() then
            return false
        end

        if isNPC then
            return currentGT == env.TRANSITION_LATE_AUTUMN
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

-- Applies snow to mission field
function FieldJob:applyFieldSnow(layers)
    for _, partition in pairs(self.fieldDef.maxFieldStatusPartitions) do
        --set type
        setDensityParallelogram(g_currentMission.terrainDetailHeightId, partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ, 0, 5, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        --set height
        setDensityParallelogram(g_currentMission.terrainDetailHeightId, partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ, 5, 6, layers)
    end
end
