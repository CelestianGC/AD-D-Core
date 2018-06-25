-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  onHPChanged();
  --onHDChanged();
end

function onHPChanged()
  local nHP = math.max(hptotal.getValue(), 0);
  local nWounds = math.max(wounds.getValue(), 0);
  local nPercentWounded = 0;
  if nHP > 0 then
    nPercentWounded = nWounds / nHP;
  end
  
  local sColor = ColorManager.getHealthColor(nPercentWounded, true);
  hpbar.updateBackColor(sColor);
  
  hpbar.setMax(nHP);
  hpbar.setValue(nHP - nWounds);
  hpbar.updateText(Interface.getString("hp") .. ": " .. (nHP - nWounds) .. " / " .. nHP);
end

function onHDChanged()
  local nHD = math.max(hd.getValue(), 0);
  local nHDUsed = math.max(hdused.getValue(), 0);
  
  local nPercentUsed = 0;
  if nHD > 0 then
    nPercentUsed = nHDUsed / nHD;
  end
  
  local sColor = ColorManager.getUsageColor(nPercentUsed, true);
    hdbar.updateBackColor(sColor);
    
    hdbar.setMax(nHD);
    hdbar.setValue(nHD - nHDUsed);
    hdbar.updateText(Interface.getString("hd") .. ": " .. (nHD - nHDUsed) .. " / " .. nHD);
end
