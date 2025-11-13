-------------------------------------------------------------------------------
-- By by Unknown Coder
-------------------------------------------------------------------------------
local c = Core
local st = c.state
-------------------------------------------------------------------------------
local IsFlying = IsFlying
local IsSwimming = IsSwimming
local hooksecurefunc = hooksecurefunc
-------------------------------------------------------------------------------
st.moveUp = false
hooksecurefunc("JumpOrAscendStart", function() st.moveUp = true end);
hooksecurefunc("AscendStop", function() st.moveUp = false end);
st.moveDown = false
hooksecurefunc("SitStandOrDescendStart", function() st.moveDown = true end);
hooksecurefunc("DescendStop", function() st.moveDown = false end);
-------------------------------------------------------------------------------
st.turnRight = false
hooksecurefunc("TurnRightStart", function() st.turnRight = true end);
hooksecurefunc("TurnRightStop", function() st.turnRight = false end);
st.turnLeft = false
hooksecurefunc("TurnLeftStart", function() st.turnLeft = true end);
hooksecurefunc("TurnLeftStop", function() st.turnLeft = false end);
-------------------------------------------------------------------------------
st.autorun = false
hooksecurefunc("ToggleAutoRun", function() st.autorun = not st.autorun end);

st.moveForward = false
hooksecurefunc("MoveForwardStart", function() st.moveForward = true end);
hooksecurefunc("MoveForwardStop", function() st.moveForward = false end);
st.moveBackward = false
hooksecurefunc("MoveBackwardStart", function() st.moveBackward = true end);
hooksecurefunc("MoveBackwardStop", function() st.moveBackward = false end);
-------------------------------------------------------------------------------
st.strafeLeft = false
hooksecurefunc("StrafeLeftStart", function() st.strafeLeft = true end);
hooksecurefunc("StrafeLeftStop", function() st.strafeLeft = false end);
st.strafeRight = false
hooksecurefunc("StrafeRightStart", function() st.strafeRight = true end);
hooksecurefunc("StrafeRightStop", function() st.strafeRight = false end);
-------------------------------------------------------------------------------
st.jump = false
st.fly = false
st.swim = false
c.AttachBeforeUpdate(function()
    st.fly = IsFlying()
    st.swim = IsSwimming()
    st.jump = st.moveUp and not st.fly and not st.swim
    st.move = st.moveForward or st.moveBackward or st.strafeLeft or st.strafeRight
    if st.still and st.autorun then st.autorun = false end
end)


-- c.AttachTelemetry(function()
--     return c.ToStr(
--         c.TelemetryBool('jp', st.jump),
--         c.TelemetryBool('st', st.still),
--         c.TelemetryBool('mv', st.move),
--         c.TelemetryBool('fwd', st.moveForward),
--         c.TelemetryBool('bwd', st.moveBackward),
--         c.TelemetryBool('lft', st.strafeLeft),
--         c.TelemetryBool('rgt', st.strafeRight),
--         c.TelemetryBool('auto', st.autorun)
--     )
-- end)
