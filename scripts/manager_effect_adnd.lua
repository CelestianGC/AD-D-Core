
--
-- "Persistant" effects (ones that adjust base/modify ability/saves/etc
--
--
-- flip through effects and setup ability score/other persistant effects
--function persistentEffectsUpdate(node,nodeChar,bItem)
    -- if not node or node == nil or not nodeChar or nodeChar == nil then
        -- return;
    -- end
    -- -- -- clear ALL persistant ability/save effects and then we rebuild them
    -- -- removeAllPersistanteffects(nodeChar,bItem);
    
    -- -- -- Check each effect
    -- for _,nodeEffect in pairs(DB.getChildren(node, "effects")) do
        -- -- Make sure effect is active
        -- local nActive = DB.getValue(nodeEffect, "isactive", 0);
        -- if (nActive ~= 0) then
            -- -- Handle start of turn special effects
            -- local sEffName = DB.getValue(nodeEffect, "label", "");
            -- local listEffectComp = EffectManager.parseEffect(sEffName);
            -- for _,rEffectComp in ipairs(listEffectComp) do
                -- local nAdjustment = rEffectComp.mod;
                -- local sAbility = DataCommon.ability_stol[rEffectComp.type:upper()] or "";
                -- local sSave = DataCommon.saves_stol[rEffectComp.type:lower()] or "";
                -- if (sAbility ~= "") then
                    -- -- if effect is a ability score modifier
                    -- persistantAbilityUpdate(nodeChar,sAbility,nAdjustment,bItem);
                -- elseif (sSave ~= "") then
                    -- -- if effect is a save modifier
                    -- persistantSaveUpdate(nodeChar,rEffectComp.type:lower(),nAdjustment,bItem);
                -- else
                    -- local sBase, sPercent, sShortAbility = string.match(rEffectComp.type:lower(), "^([b]?)([p]?)([a-z][a-z][a-z])$");
                    -- if (sShortAbility ~= "" and sShortAbility ~= nil) then
                        -- -- not standard ability or save, check special
                        -- sAbility = DataCommon.ability_stol[sShortAbility:upper()] or "";
                        -- local bPercent = (sPercent == "p");
                        -- local bBase = (sBase == "b");
                        -- if (sAbility ~= "") then
                            -- if bBase and bPercent then
                                -- -- BPSTR is percent/base strength value ".percentbasemod"
                                -- if (bItem) then
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"percentbaseitem");
                                -- else
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"percentbasemod");
                                -- end
                            -- elseif (bBase) then
                                -- -- BSTR is base strength ".basemod"
                                -- if (bItem) then
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"baseitem");
                                -- else
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"basemod");
                                -- end
                            -- elseif (bPercent) then
                                -- -- PSTR is percentil strength ".percenteffectmod"
                                -- if (bItem) then
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"percentitemmod");
                                -- else
                                    -- persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,"percenteffectmod");
                                -- end
                            -- end
                        -- end -- sAbility
                    -- end
                        -- sShortAbility = string.match(rEffectComp.type:lower(), "^b([a-z]+)$");
                        -- sSave    = DataCommon.saves_stol[sShortAbility] or "";
                    -- if (sShortAbility ~= "" and sShortAbility ~= nil) then
                        -- if (sSave ~= "") then
                            -- -- BSAVENAME base save ".basemod"
                            -- if (bItem) then
                                -- persistantSaveBaseUpdate(nodeChar,sShortAbility,nAdjustment,"baseitem");
                            -- else
                                -- persistantSaveBaseUpdate(nodeChar,sShortAbility,nAdjustment,"basemod");
                            -- end
                        -- end
                    -- end
                -- end
            -- end
        -- end -- END ACTIVE EFFECT CHECK
    -- end -- END EFFECT LOOP
--end

-- adjust abilities.*.effectmod/itemmod
function persistantAbilityUpdate(nodeChar,sAbility,nAdjustment,bItem)
    -- local sMod = ".effectmod";
    -- if (bItem) then
        -- sMod = ".itemmod";
    -- end
    -- local nCurrentAdjustment = DB.getValue(nodeChar,"abilities." .. sAbility .. sMod,0);
    -- local nTotal = nCurrentAdjustment + nAdjustment;
    -- DB.setValue(nodeChar,"abilities." .. sAbility .. sMod,"number",nTotal);
end
-- adjust abilities.*.sModifier
function persistantAbilityBaseUpdate(nodeChar,sAbility,nAdjustment,sModifier)
    -- local nCurrentAdjustment = DB.getValue(nodeChar,"abilities." .. sAbility .. "." .. sModifier,0);
    -- local nTotal = nCurrentAdjustment;
    -- -- only replace the value if the total is > than what we have already
    -- if (nTotal < nAdjustment) then
        -- nTotal = nAdjustment;
    -- end
    -- DB.setValue(nodeChar,"abilities." .. sAbility .. "." .. sModifier,"number",nTotal);
end

-- adjust saves.*.effectmod/itemmod
function persistantSaveUpdate(nodeChar,sSave,nAdjustment,bItem)
    -- local sMod = ".effectmod";
    -- if (bItem) then
        -- sMod = ".itemmod";
    -- end
    -- local nCurrentAdjustment = DB.getValue(nodeChar,"saves." .. sSave .. sMod,0);
    -- local nTotal = nCurrentAdjustment + nAdjustment;
    -- DB.setValue(nodeChar,"saves." .. sSave .. sMod,"number",nTotal);
end
-- adjust saves.*.sModifier
function persistantSaveBaseUpdate(nodeChar,sSave,nAdjustment,sModifier)
    -- local nCurrentAdjustment = DB.getValue(nodeChar,"saves." .. sSave .. "." .. sModifier,0);
    -- local nTotal = nCurrentAdjustment;
    -- -- only replace the value if the total is > than what we have already
    -- if (nTotal < nAdjustment) then
        -- nTotal = nAdjustment;
    -- end
    -- DB.setValue(nodeChar,"saves." .. sSave .. "." .. sModifier,"number",nTotal);
end

-- removes all persistant ability/save modifiers
function removeAllPersistanteffects(nodeChar,bItem)
    -- if bItem then
        -- -- abilities
        -- for i = 1,6,1 do
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".itemmod","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".baseitem","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".percentitemmod","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".percentbaseitem","number",0);    
        -- end
        -- -- saves
        -- for i = 1,10,1 do
            -- DB.setValue(nodeChar,"saves." .. DataCommon.saves[i] .. ".itemmod","number",0);
            -- DB.setValue(nodeChar,"saves." .. DataCommon.saves[i] .. ".baseitem","number",0);
        -- end
    -- else
        -- -- abilities
        -- for i = 1,6,1 do
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".effectmod","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".basemod","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".percenteffectmod","number",0);    
            -- DB.setValue(nodeChar,"abilities." .. DataCommon.abilities[i] .. ".percentbasemod","number",0);    
        -- end
        -- -- saves
        -- for i = 1,10,1 do
            -- DB.setValue(nodeChar,"saves." .. DataCommon.saves[i] .. ".effectmod","number",0);
            -- DB.setValue(nodeChar,"saves." .. DataCommon.saves[i] .. ".basemod","number",0);
        -- end
    -- end
end

-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem,bCombat)
--Debug.console("manager_effect.lua","updateItemEffects1","nodeItem",nodeItem);
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
--Debug.console("manager_effect.lua","updateItemEffects","nodeChar2",nodeChar);
    local sUser = User.getUsername();
--    local nodeItem = DB.getChild(node, "..");
    --local nodeItem = node;
    local sName = DB.getValue(nodeItem, "name", "");
    local sLabel = DB.getValue(nodeItem, "effect", "");
    
    -- this allows us to manage the combat_effects with the same code
    local sLabelCombat = DB.getValue(nodeItem, "effect_combat", "");
    if (not bCombat and sLabelCombat ~= "") then
        updateItemEffects(nodeItem,true);
    end
    if bCombat then
        -- use the combat effect string
        sLabel = sLabelCombat;
    end
    -- end combat_effects triggers

    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
        nodeChar = CharManager.getCTNodeByNodeChar(nodeChar);
    end
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local sItemSource = nodeItem.getPath();
    local nIdentified = DB.getValue(nodeItem, "isidentified", 0);
    local sCharacterName = DB.getValue(nodeChar, "name", "");
--Debug.console("manager_effect.lua","updateItemEffects","node",node);
-- Debug.console("manager_effect.lua","updateItemEffects","nodeChar",nodeChar);
-- Debug.console("manager_effect.lua","updateItemEffects","nodeItem",nodeItem);
-- Debug.console("manager_effect.lua","updateItemEffects","bCombat",bCombat);
-- Debug.console("manager_effect.lua","updateItemEffects","sName",sName);
-- Debug.console("manager_effect.lua","updateItemEffects","sLabel",sLabel);
-- Debug.console("manager_effect.lua","updateItemEffects","nCarried",nCarried);
-- Debug.console("manager_effect.lua","updateItemEffects","bEquipped",bEquipped);
-- Debug.console("manager_effect.lua","updateItemEffects","sItemSource",sItemSource);
-- Debug.console("manager_effect.lua","updateItemEffects","nIdentified",nIdentified);
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
                    
    --Debug.console("manager_effect.lua","updateItemEffects","!!!bEquipped",bEquipped);
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
    --Debug.console("manager_effect.lua","updateItemEffects","pre bEquipped",bEquipped);
        if (not bFound and bEquipped) then
    --Debug.console("manager_effect.lua","updateItemEffects","bFound and bEquipped",bEquipped);
            local rEffect = {};
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.nDuration = 0;
            rEffect.sUnits = "day";
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nIdentified;
            rEffect.sApply = "";        
    --Debug.console("manager_effect.lua","updateItemEffects","rEffect",rEffect);
            EffectManager.addEffect(sUser, "", nodeChar, rEffect, true);
        end
        
        -- if not in combat(those are normal effects) then update 
        -- ability/save effects
        if (bFound or bEquipped) and (not bCombat) then
            --persistentEffectsUpdate(nodeChar,nodeChar,true);
        end
    end
end