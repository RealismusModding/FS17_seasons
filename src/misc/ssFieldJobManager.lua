----------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To manage fields owned by the NPC according to seasons
-- Authors:  baron, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssFieldJobManager = {}

function ssFieldJobManager:preLoad()
    g_seasons.fieldJobManager = self

    ssUtil.overwrittenFunction(FieldJob, "init", ssFieldJobManager.fieldJobInit)
    ssUtil.overwrittenFunction(FieldJob, "finish", ssFieldJobManager.fieldJobFinish)
    ssUtil.appendedFunction(FieldJobManager, "update", ssFieldJobManager.fieldJobManagerUpdate)
end

function ssFieldJobManager:loadMap(name)
    -- TODO: determine crop to grow
end

-- Filter what jobs are carried out by the FieldJobManager
function ssFieldJobManager:fieldJobManagerUpdate(superFunc, dt)
    -- Check if field job was started by NPC, terminate if not appropriate for current season
    if self.fieldStatusParametersToSet ~= nil and self.currentFieldPartitionIndex == nil then
        local paramFieldNumber      = self.fieldStatusParametersToSet[1].fieldNumber
        local paramSetState         = self.fieldStatusParametersToSet[5] --FieldJobManager.FIELDSTATE_*

        local stateToJob = {[FieldJobManager.FIELDSTATE_CULTIVATED] = FieldJob.TYPE_CULTIVATING,
                            [FieldJobManager.FIELDSTATE_PLOUGHED] = FieldJob.TYPE_PLOUGHING,
                            [FieldJobManager.FIELDSTATE_HARVESTED] = FieldJob.TYPE_HARVESTING,
                            [FieldJobManager.FIELDSTATE_GROWING] = FieldJob.TYPE_SOWING}

        local fruitIndex = self.fieldStatusParametersToSet[4]

        if not g_seasons.fieldJobManager.isFieldJobAllowed(stateToJob[paramSetState], true, fruitIndex) then
            self.fieldStatusParametersToSet = nil -- This makes FieldJobManager never begin work and will check next field on next update
        end
    end
end

-- Filter mission assignments to the player
function ssFieldJobManager:fieldJobInit(superFunc, fieldDef, jobType, sprayFactor, fieldSpraySet, fieldState, growthState, fieldPloughFactor)
    local initFieldJob = superFunc(self, fieldDef, jobType, sprayFactor, fieldSpraySet, fieldState, growthState, fieldPloughFactor)
    local fruitIndex = fieldDef.missionFruitType

    -- If superFunc has reset snow, we need to re-apply it
    if ssSnow.appliedSnowDepth > 0 then
        self:applyFieldSnow(ssSnow.appliedSnowDepth / ssSnow.LAYER_HEIGHT)
    end

    if initFieldJob then
        if not ssFieldJobManager.isFieldJobAllowed(self.jobType, false, fruitIndex) then
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

function ssFieldJobManager:fruitIndexToName(fruitIndex)
    return FruitUtil.fruitIndexToDesc[fruitIndex].name
end

function ssFieldJobManager:allowNPCPlough()
    return true
end

function ssFieldJobManager:allowNPCPlant(fruitIndex)
    local fruitName = self:fruitIndexToName(fruitIndex)
    local currentGT = g_seasons.environment:transitionAtDay()

    if not g_seasons.growthGUI:canFruitBePlanted(fruitName, currentGT) then
        return false
    end

    -- Only plant if next GT cant plant
    return not g_seasons.growthGUI:canFruitBePlanted(fruitName, ssEnvironment:nextTransition())
end

function ssFieldJobManager:allowNPCHarvest(fruitIndex)
    local fruitName = self:fruitIndexToName(fruitIndex)
    local currentGT = g_seasons.environment:transitionAtDay()

    if not g_seasons.growthGUI:canFruitBeHarvested(fruitName, currentGT) then
        return false
    end

    -- Only auto-harvest if next GT it can't be
    return not g_seasons.growthGUI:canFruitBeHarvested(fruitName, ssEnvironment:nextTransition())
        or currentGT == ssEnvironment.TRANSITION_LATE_AUTUMN
end

function ssFieldJobManager:allowPlayerPlant(fruitIndex)
    local fruitName = self:fruitIndexToName(fruitIndex)
    local currentGT = g_seasons.environment:transitionAtDay()

    return g_seasons.growthGUI:canFruitBePlanted(fruitName, currentGT)
end

-- fieldJob: FieldJob.TYPE_*
-- isNPC:    bool
function ssFieldJobManager.isFieldJobAllowed(fieldJobType, isNPC, fruitIndex)
    -- Use vanilla FieldJobManager if not using seasons growthManager
    if not g_seasons.growthManager.growthManagerEnabled then return true end

    -- Allow nothing when ground is frozen or snow-covered
    if g_seasons.weather:isGroundFrozen() or g_seasons.snow.appliedSnowDepth > 0 then return false end

    -- Always allow fertilizing missions
    if fieldJobType == FieldJob.TYPE_FERTILIZING_GROWING or fieldJobType == FieldJob.TYPE_FERTILIZING_HARVESTED or fieldJobType == FieldJob.TYPE_FERTILIZING_SOWN then
        return true
    -- Always allow user assigned missions to cultivate
    -- NPC only cultivates in spring
    elseif fieldJobType == FieldJob.TYPE_PLOUGHING or fieldJobType == FieldJob.TYPE_CULTIVATING then
        if isNPC then
            return ssFieldJobManager:allowNPCPlough()
        else
            return true
        end
    -- Never allow harvesting wet crop
    -- NPC only harvests in late autumn
    -- Always allow user assigned missions to harvest
    elseif fieldJobType == FieldJob.TYPE_HARVESTING then
        if g_seasons.weather:isCropWet() then
            return false
        end

        if isNPC then
            return ssFieldJobManager:allowNPCHarvest(fruitIndex)
        else
            return true
        end
    -- Only allow seeding in spring - early summer
    -- NPC only seeds in late spring
    elseif fieldJobType == FieldJob.TYPE_SOWING then
        if isNPC then
            return ssFieldJobManager:allowNPCPlant(fruitIndex)
        else
            return ssFieldJobManager:allowPlayerPlant(fruitIndex)
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
