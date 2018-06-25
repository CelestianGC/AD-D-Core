-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDiceLanded(draginfo)
  if window.parentcontrol.window.rollmode.isVisible() then
    if draginfo.isType("dice") then
      local aDice = draginfo.getDieList();
      window.parentcontrol.window.rollmode.subwindow.rolls.applyRoll(aDice);
    end
    return true;
  elseif window.parentcontrol.window.pointmode.isVisible() then
    return true;
  else
    return super.onDiceLanded(draginfo);
  end
end
