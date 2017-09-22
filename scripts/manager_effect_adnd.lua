
--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem)
--Debug.console("manager_effect_adnd.lua","updateItemEffects1","nodeItem",nodeItem);
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar2",nodeChar);
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeItem, "name", "");
    local sLabel = DB.getValue(nodeItem, "effect", "");
    local sLabelCombat = DB.getValue(nodeItem, "effect_combat", "");
    if (sLabelCombat ~= "") then
        sLabel = sLabel .. ";" .. sLabelCombat;
    end
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
        nodeChar = CharManager.getCTNodeByNodeChar(nodeChar);
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar3",nodeChar);
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local sItemSource = nodeItem.getPath();
    local nIdentified = DB.getValue(nodeItem, "isidentified", 0);
    local sCharacterName = DB.getValue(nodeChar, "name", "");
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sName",sName);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sLabel",sLabel);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sItemSource",sItemSource);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
    --Debug.console("manager_effect.lua","updateItemEffects","nActive",nActive);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
    --Debug.console("manager_effect.lua","updateItemEffects","sEffSource",sEffSource);
                if (sEffSource == sItemSource) then
                    bFound = true;
    --Debug.console("manager_effect.lua","updateItemEffects","bFound!!!",bFound);
                    if (not bEquipped) then
                        -- BUILD MESSAGE
                        local msg = {font = "msgfont", icon = "roll_effect"};
                        msg.text = "Effect ['" .. sLabel .. "'] ";
                        msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
                        -- HANDLE APPLIED BY SETTING
                        if sEffSource and sEffSource ~= "" then
                            msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
                        end
                        -- SEND MESSAGE
                        if nIdentified > 0 then
                            if EffectManager.isGMEffect(nodeChar, nodeEffect) then
                                if sUser == "" then
                                    msg.secret = true;
                                    Comm.addChatMessage(msg);
                                elseif sUser ~= "" then
                                    Comm.addChatMessage(msg);
                                    Comm.deliverChatMessage(msg, sUser);
                                end
                            else
                                Comm.deliverChatMessage(msg);
                            end
                        end
                    
    --Debug.console("manager_effect_adnd.lua","updateItemEffects","!!!bEquipped",bEquipped);
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
    --Debug.console("manager_effect_adnd.lua","updateItemEffects","pre bEquipped",bEquipped);
        if (not bFound and bEquipped) then
    --Debug.console("manager_effect_adnd.lua","updateItemEffects","bFound and bEquipped",bEquipped);
            local rEffect = {};
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.nDuration = 0;
            rEffect.sUnits = "day";
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nIdentified;
            rEffect.sApply = "";        
    --Debug.console("manager_effect_adnd.lua","updateItemEffects","rEffect",rEffect);
            EffectManager.addEffect(sUser, "", nodeChar, rEffect, true);
        end
        
    end
end