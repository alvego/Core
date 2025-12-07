-------------------------------------------------------------------------------
-- by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
-------------------------------------------------------------------------------
local GetPlayerMapPosition = GetPlayerMapPosition
local GetCurrentMapAreaID = GetCurrentMapAreaID
-------------------------------------------------------------------------------
-- Якоря (из пула)
local AnchorX = nil
local AnchorY = nil

local FALLBACK_X = 33400 / 3 * 2 -- 22266.666666666668
local FALLBACK_Y = 22200 / 3 * 2 -- 14800.0

local MIN_DISTANCE = 180
local MIN_MAP_DELTA = 0.002

local function resetAnchors()
    if AnchorX then
        c.TablePoolRelease(AnchorX)
        AnchorX = nil
    end
    if AnchorY then
        c.TablePoolRelease(AnchorY)
        AnchorY = nil
    end
end

-- Сбрасываем анкоры при смене зоны
c.Event('ZONE_CHANGED', resetAnchors)
c.Event('ZONE_CHANGED_NEW_AREA', resetAnchors)

-- Основная логика — не чаще 0.5 сек
c.AfterUpdate(function()
    if c.TimerLess('UpdateZoneScale', 0.5) then return end
    c.TimerStart('UpdateZoneScale')

    if not c.db then return end
    if not c.db.zoneScales then c.db.zoneScales = {} end

    local zoneID = GetCurrentMapAreaID()
    if zoneID == -1 then
        resetAnchors()
        return
    end

    local mx, my = GetPlayerMapPosition('player')
    if mx == 0 and my == 0 then
        resetAnchors()
        return
    end

    local wx, wy = c.UnitPosition('player')
    if not wx then return end

    local zoneCache = c.db.zoneScales[zoneID]
    if not zoneCache then
        zoneCache = {}
        c.db.zoneScales[zoneID] = zoneCache
    end

    local wasIncomplete = not (zoneCache.scaleX and zoneCache.scaleY)

    -- === Расчёт X ===
    if not zoneCache.scaleX then
        if not AnchorX or AnchorX.zoneID ~= zoneID then
            if not AnchorX then AnchorX = c.TablePoolAcquire() end
            AnchorX.wx, AnchorX.mx, AnchorX.zoneID = wx, mx, zoneID
        else
            local dWX = wx - AnchorX.wx
            local dMX = mx - AnchorX.mx
            if math.abs(dWX) >= MIN_DISTANCE and math.abs(dMX) >= MIN_MAP_DELTA then
                local calcX = dWX / dMX
                if calcX > 1000 and calcX < 200000 then
                    zoneCache.scaleX = calcX
                    c.Log('#|cFF00FFAA[MapScale] Зона ' ..
                        zoneID .. ': scaleX = ' .. string.format('%.1f', calcX) .. '|r')
                    c.TablePoolRelease(AnchorX)
                    AnchorX = nil
                end
            end
        end
    end

    -- === Расчёт Y ===
    if not zoneCache.scaleY then
        if not AnchorY or AnchorY.zoneID ~= zoneID then
            if not AnchorY then AnchorY = c.TablePoolAcquire() end
            AnchorY.wy, AnchorY.my, AnchorY.zoneID = wy, my, zoneID
        else
            local dWY = wy - AnchorY.wy
            local dMY = my - AnchorY.my
            if math.abs(dWY) >= MIN_DISTANCE and math.abs(dMY) >= MIN_MAP_DELTA then
                local calcY = math.abs(dWY / dMY)
                if calcY > 1000 and calcY < 200000 then
                    zoneCache.scaleY = calcY
                    c.Log('#|cFF00FFAA[MapScale] Зона ' ..
                        zoneID .. ': scaleY = ' .. string.format('%.1f', calcY) .. '|r')
                    c.TablePoolRelease(AnchorY)
                    AnchorY = nil
                end
            end
        end
    end

    -- Один раз — когда зона только что стала полной
    if wasIncomplete and zoneCache.scaleX and zoneCache.scaleY then
        c.Log('#|cFF00FF00[MapScale] Зона ' .. zoneID .. ': ПОЛНЫЙ масштаб рассчитан! X=' ..
            string.format('%.1f', zoneCache.scaleX) .. '  Y=' .. string.format('%.1f', zoneCache.scaleY) .. '|r')
    end
end)

-- Остальные функции без изменений
local function getZoneScale()
    if not c.db or not c.db.zoneScales then
        return FALLBACK_X, FALLBACK_Y
    end
    local zoneID = GetCurrentMapAreaID()
    local cache = zoneID ~= -1 and c.db.zoneScales[zoneID]
    return (cache and cache.scaleX or FALLBACK_X), (cache and cache.scaleY or FALLBACK_Y)
end

function c.WorldToMap(x, y)
    local pmx, pmy = GetPlayerMapPosition('player')
    if pmx == 0 then return 0, 0 end
    local px, py = c.UnitPosition('player')
    if not px then return 0, 0 end
    local scaleX, scaleY = getZoneScale()
    return pmx + (x - px) / scaleX,
        pmy + (y - py) / (-scaleY)
end

function c.MapToWorld(mapX, mapY)
    local pmx, pmy = GetPlayerMapPosition('player')
    if pmx == 0 then return nil, nil, nil end
    local px, py, pz = c.UnitPosition('player')
    if not px then return nil, nil, nil end
    local scaleX, scaleY = getZoneScale()
    return px + (mapX - pmx) * scaleX,
        py + (mapY - pmy) * (-scaleY),
        pz
end
