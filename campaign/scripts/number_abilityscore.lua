-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super then
        super.onInit();
    end
  --onValueChanged();
end

function update(bReadOnly)
  setReadOnly(bReadOnly);
end

-- function onValueChanged()
    -- if self then
        -- local sTarget = string.lower(self.target[1]);
        -- local nChanged = getValue();
            
        -- local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
        -- local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
        -- if sActorType == "pc" and (nChanged >= 1) and (nChanged <= 25) then
            -- if (sTarget == "strength") then
                -- AbilityScoreADND.updateStrength(nodeActor);
            -- elseif (sTarget == "dexterity") then
                -- AbilityScoreADND.updateDexterity(nodeActor);
            -- elseif (sTarget == "wisdom") then
                -- AbilityScoreADND.updateWisdom(nodeActor);
                -- -- update tooltips
                -- updateWisdom(nodeActor,nChanged);
            -- elseif (sTarget == "constitution") then
                -- AbilityScoreADND.updateConstitution(nodeActor);
            -- elseif (sTarget == "charisma") then
                -- AbilityScoreADND.updateCharisma(nodeActor);
            -- elseif (sTarget == "intelligence") then
                -- AbilityScoreADND.updateIntelligence(nodeActor);
                -- --update tooltips
                -- updateIntelligence(nodeActor,nChanged);
            -- end
        -- end -- was PC
    -- end
-- end

function action(draginfo)
  local rActor = ActorManager.getActor("", window.getDatabaseNode());
  
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
    local nTargetDC = DB.getValue(nodeActor, "abilities.".. self.target[1] .. ".score", 0);

  ActionCheck.performRoll(draginfo, rActor, self.target[1], nTargetDC);
  return true;
end

function onDragStart(button, x, y, draginfo)
  if rollable then
    return action(draginfo);
  end
end
  
function onDoubleClick(x, y)
  if rollable then
    return action();
  end
end


-- function updateWisdom(nodeActor,nChanged)
    -- -- local dbAbility = AbilityScoreADND.getWisdomProperties(nodeActor);
    -- -- local nScore = dbAbility.score;
    
    -- -- DB.setValue(nodeActor, "abilities.wisdom.magicdefenseadj", "number", dbAbility.magicdefenseadj);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.spellbonus", "string", dbAbility.spellbonus);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.failure", "number", dbAbility.failure);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.immunity", "string", dbAbility.immunity);

    -- -- DB.setValue(nodeActor, "abilities.wisdom.magicdefenseadj", "number", DataCommonADND.aWisdom[nChanged][1]);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.spellbonus", "string", DataCommonADND.aWisdom[nChanged][2]);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.failure", "number", DataCommonADND.aWisdom[nChanged][3]);
    -- -- DB.setValue(nodeActor, "abilities.wisdom.immunity", "string", DataCommonADND.aWisdom[nChanged][4]);
    -- -- if (window and window.wisdom_immunity and window.wisdom_immunity_label 
        -- -- and window.wisdom_spellbonus and window.wisdom_spellbonus_label) then
        -- -- -- set tooltip for this because it's just to big for the
        -- -- -- abilities pane
        -- -- window.wisdom_immunity.setTooltipText(dbAbility.sImmunity_TT);
        -- -- window.wisdom_immunity_label.setTooltipText(dbAbility.sImmunity_TT);

        -- -- window.wisdom_spellbonus.setTooltipText(dbAbility.sBonus_TT);
        -- -- window.wisdom_spellbonus_label.setTooltipText(dbAbility.sBonus_TT);
    -- -- end

    -- -- if (window and window.wisdom_immunity and window.wisdom_immunity_label 
        -- -- and window.wisdom_spellbonus and window.wisdom_spellbonus_label) then
        -- -- -- set tooltip for this because it's just to big for the
        -- -- -- abilities pane
        -- -- local sBonus_TT = "Bonus spells granted by high wisdom. ";
        -- -- local sImmunity_TT = "Immunity to spells granted by high wisdom. ";
        -- -- if (nScore >= 18) then
            -- -- sBonus_TT = sBonus_TT .. DataCommonADND.aWisdom[nScore+100][2];
            -- -- sImmunity_TT = sImmunity_TT .. DataCommonADND.aWisdom[nScore+100][4];
            -- -- -- set the xml elements tooltip to data to large for display
        -- -- end
        -- -- window.wisdom_immunity.setTooltipText(sImmunity_TT);
        -- -- window.wisdom_immunity_label.setTooltipText(sImmunity_TT);

        -- -- window.wisdom_spellbonus.setTooltipText(sBonus_TT);
        -- -- window.wisdom_spellbonus_label.setTooltipText(sBonus_TT);
    -- -- end

-- end

-- function updateIntelligence(nodeActor,nChanged)

    -- -- local dbAbility = AbilityScoreADND.getIntelligenceProperties(nodeActor);
    -- -- local nScore = dbAbility.score;

    -- -- DB.setValue(nodeActor, "abilities.intelligence.languages", "number", DataCommonADND.aIntelligence[nChanged][1]);
    -- -- DB.setValue(nodeActor, "abilities.intelligence.spelllevel", "number", DataCommonADND.aIntelligence[nChanged][2]);
    -- -- DB.setValue(nodeActor, "abilities.intelligence.learn", "number", DataCommonADND.aIntelligence[nChanged][3]);
    -- -- DB.setValue(nodeActor, "abilities.intelligence.maxlevel", "string", DataCommonADND.aIntelligence[nChanged][4]);
    -- -- DB.setValue(nodeActor, "abilities.intelligence.illusion", "string", DataCommonADND.aIntelligence[nChanged][5]);
    -- -- set tooltip for this because it's just to big for the
    -- -- abilities pane
    -- -- if (window and window.intelligence_illusion and window.intelligence_illusion_label) then
        -- -- window.intelligence_illusion.setTooltipText(dbAbility.sImmunity_TT);
        -- -- window.intelligence_illusion_label.setTooltipText(dbAbility.sImmunity_TT);
    -- -- end
    -- -- if (window and window.intelligence_illusion and window.intelligence_illusion_label) then
        -- -- local sImmunity_TT = "Immune these level of Illusion spells. ";
        -- -- if (nScore >= 19) then
            -- -- sImmunity_TT = sImmunity_TT .. DataCommonADND.aIntelligence[nScore+100][5];
        -- -- end
        -- -- window.intelligence_illusion.setTooltipText(sImmunity_TT);
        -- -- window.intelligence_illusion_label.setTooltipText(sImmunity_TT);
    -- -- end
-- end
