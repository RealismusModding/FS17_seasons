function ssVehicle:snowTracks()
    -- reallogger
    -- 19 12 2016
    -- function to determine wheel resistance in snow and snow sinkage/compaction in wheel tracks
    -- Based on Richmond, 1995, Motion resistance of wheeled vehicles in snow. US Army Corps of Engineers

    -- if changing wheel friction set it to 0.15 if ssSnowDepth > ssSnow.LAYER_HEIGHT

    local h = ssSnow.snowDepth
    local r = wheelRadius
    local w = wheelWidth

    if ssSnow.snowDepth <= ssSnow.LAYER_HEIGHT then  -- one snow layer offers no resistance
        self.snowResistance = 0
    else
        z = 0.7 * h ---Sinkage
        if ( h - z ) < ssSnow.LAYER_HEIGHT then
            newSnowDepth = 0  --finding the snowDepth in the tracks after driving.
        else
            newSnowDepth = h - z -- need to be transformed to snow layers
        end

        if z <= r then
            alpha = math.acos((r-z) / r)
            a = math.pi/2 * r * z * math.sin(alpha)
        elseif z > r and z <= 2 * r then
            alpha = math.pi/ 2 - math.acos((r-z) / r)
            a = math.pi - math.pi/2 * r * z * math.sin(alpha)
        elseif z > 2 * r then
            a = math.pi * r
        end

        self.snowResistance = 15 * (150 * a * w)^1.3 -- snowResistance in Newtons

    end

end
