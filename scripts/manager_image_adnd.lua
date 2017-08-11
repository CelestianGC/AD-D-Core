---
-- this isn't useful, was going to use it to get map scale and make sure reach
-- was matching map unit scale but at the point reach is set it's not even on the
-- map so we don't have image data. -- 
--
---

-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
-- THIS IS NOT USED ANYWHERE. SAVING INCASE I COME UP WITH A USE CASE ----------
function onInit()
end


function getScaleControlValue(nodeImage)
    local node = nodeImage.getChild("..");
    local sValue = DB.getValue(node,"scale","10ft"); -- default to 10ft here but we should never see this.
    return sValue;
end
function getScaleControlisValid(nodeImage)
    return getScaleControlValue(nodeImage):find("^%d") ~= nil
end
function getScaleControlScaleValue(nodeImage)
    return getScaleControlisValid(nodeImage) and tonumber(getScaleControlValue(nodeImage):match("^(%d+)")) or 0
end
function getScaleControlScaleLabel(nodeImage)
    return StringManager.trim(getScaleControlValue(nodeImage):gsub("^%d+%s*", ""))
end

--- return the map units per hex/grid 
function getMapUnitsPerGrid(nodeNPC)
    local nUnit = GameSystem.getDistanceUnitsPerGrid();
    local sImagePath = DB.getValue(nodeNPC,"tokenrefnode","");
Debug.console("manager_image_adnd.lua","getMapUnitsPerGrid","nUnit",nUnit);
Debug.console("manager_image_adnd.lua","getMapUnitsPerGrid","nodeNPC",nodeNPC);
Debug.console("manager_image_adnd.lua","getMapUnitsPerGrid","sImagePath",sImagePath);
    if sImagePath ~= "" then
        local nodeImage = DB.findNode(sImagePath);
        if (nodeImage) then
            local nMapUnit = getScaleControlScaleValue(nodeImage);
            if (nMapUnit > 0) then
                nUnit = nMapUnit;
            end
        end
    end
    Debug.console("manager_image_adnd.lua","getMapUnitsPerGrid","nUnit2",nUnit);
    return nUnit;
end