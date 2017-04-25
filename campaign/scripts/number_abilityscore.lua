-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super then
        super.onInit();
    end
	onValueChanged();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function onValueChanged()
    if self then
        local sTarget = string.lower(self.target[1]);
        local nChanged = getValue();
            
        local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
        local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
        if sActorType == "pc" and (nChanged >= 1) and (nChanged <= 25) then
            if (sTarget == "strength") then
                updateStrength(nodeActor,nChanged);
            elseif (sTarget == "dexterity") then
                updateDexterity(nodeActor,nChanged);
            elseif (sTarget == "wisdom") then
                updateWisdom(nodeActor,nChanged);
            elseif (sTarget == "constitution") then
                updateConstitution(nodeActor,nChanged);
            elseif (sTarget == "charisma") then
                updateCharisma(nodeActor,nChanged);
            elseif (sTarget == "intelligence") then
                updateIntelligence(nodeActor,nChanged);
            end
        end -- was PC
    end
end

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

function updateStrength(nodeActor,nChanged)

    nPercent = DB.getValue(nodeActor, "abilities.strength.percent", 0);

    -- Deal with 18 01-100 strength
    if ((nChanged == 18) and (nPercent > 0)) then
        local nPercentRank = 50;
        if (nPercent == 100) then 
            nPercentRank = 100
        elseif (nPercent >= 91 and nPercent <= 99) then
            nPercentRank = 99
        elseif (nPercent >= 76 and nPercent <= 90) then
            nPercentRank = 90
        elseif (nPercent >= 51 and nPercent <= 75) then
            nPercentRank = 75
        elseif (nPercent >= 1 and nPercent <= 50) then
            nPercentRank = 50
        end
        nChanged = nPercentRank;
    end
    
    DB.setValue(nodeActor, "abilities.strength.hitadj", "number", DataCommonADND.aStrength[nChanged][1]);
    DB.setValue(nodeActor, "abilities.strength.dmgadj", "number", DataCommonADND.aStrength[nChanged][2]);
    DB.setValue(nodeActor, "abilities.strength.weightallow", "number", DataCommonADND.aStrength[nChanged][3]);
    DB.setValue(nodeActor, "abilities.strength.maxpress", "number", DataCommonADND.aStrength[nChanged][4]);
    DB.setValue(nodeActor, "abilities.strength.opendoors", "string", DataCommonADND.aStrength[nChanged][5]);
    DB.setValue(nodeActor, "abilities.strength.bendbars", "number", DataCommonADND.aStrength[nChanged][6]);
end

function updateDexterity(nodeActor,nChanged)
    DB.setValue(nodeActor, "abilities.dexterity.reactionadj", "number", DataCommonADND.aDexterity[nChanged][1]);
    DB.setValue(nodeActor, "abilities.dexterity.hitadj", "number", DataCommonADND.aDexterity[nChanged][2]);
    DB.setValue(nodeActor, "abilities.dexterity.defenseadj", "number", DataCommonADND.aDexterity[nChanged][3]);
end

function updateWisdom(nodeActor,nChanged)
    
    DB.setValue(nodeActor, "abilities.wisdom.magicdefenseadj", "number", DataCommonADND.aWisdom[nChanged][1]);
    DB.setValue(nodeActor, "abilities.wisdom.spellbonus", "string", DataCommonADND.aWisdom[nChanged][2]);
    DB.setValue(nodeActor, "abilities.wisdom.failure", "number", DataCommonADND.aWisdom[nChanged][3]);
    DB.setValue(nodeActor, "abilities.wisdom.immunity", "string", DataCommonADND.aWisdom[nChanged][4]);


    if (window and window.wisdom_immunity and window.wisdom_immunity_label 
        and window.wisdom_spellbonus and window.wisdom_spellbonus_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        local sBonus_TT = "Bonus spells granted by high wisdom. ";
        local sImmunity_TT = "Immunity to spells granted by high wisdom. ";
        if (nChanged >= 18) then
            sBonus_TT = sBonus_TT .. DataCommonADND.aWisdom[nChanged+100][2];
            sImmunity_TT = sImmunity_TT .. DataCommonADND.aWisdom[nChanged+100][4];
            -- set the xml elements tooltip to data to large for display
        end
        window.wisdom_immunity.setTooltipText(sImmunity_TT);
        window.wisdom_immunity_label.setTooltipText(sImmunity_TT);

        window.wisdom_spellbonus.setTooltipText(sBonus_TT);
        window.wisdom_spellbonus_label.setTooltipText(sBonus_TT);
    end

end

function updateConstitution(nodeActor,nChanged)
    DB.setValue(nodeActor, "abilities.constitution.hitpointadj", "string", DataCommonADND.aConstitution[nChanged][1]);
    DB.setValue(nodeActor, "abilities.constitution.systemshock", "number", DataCommonADND.aConstitution[nChanged][2]);
    DB.setValue(nodeActor, "abilities.constitution.resurrectionsurvival", "number", DataCommonADND.aConstitution[nChanged][3]);
    DB.setValue(nodeActor, "abilities.constitution.poisonadj", "number", DataCommonADND.aConstitution[nChanged][4]);
    DB.setValue(nodeActor, "abilities.constitution.regeneration", "string", DataCommonADND.aConstitution[nChanged][5]);
end

function updateCharisma(nodeActor,nChanged)
    DB.setValue(nodeActor, "abilities.charisma.maxhench", "number", DataCommonADND.aCharisma[nChanged][1]);
    DB.setValue(nodeActor, "abilities.charisma.loyalty", "number", DataCommonADND.aCharisma[nChanged][2]);
    DB.setValue(nodeActor, "abilities.charisma.reaction", "number", DataCommonADND.aCharisma[nChanged][3]);
	
end

function updateIntelligence(nodeActor,nChanged)
    DB.setValue(nodeActor, "abilities.intelligence.languages", "number", DataCommonADND.aIntelligence[nChanged][1]);
    DB.setValue(nodeActor, "abilities.intelligence.spelllevel", "number", DataCommonADND.aIntelligence[nChanged][2]);
    DB.setValue(nodeActor, "abilities.intelligence.learn", "number", DataCommonADND.aIntelligence[nChanged][3]);
    DB.setValue(nodeActor, "abilities.intelligence.maxlevel", "string", DataCommonADND.aIntelligence[nChanged][4]);
    DB.setValue(nodeActor, "abilities.intelligence.illusion", "string", DataCommonADND.aIntelligence[nChanged][5]);

    -- set tooltip for this because it's just to big for the
    -- abilities pane
    if (window and window.intelligence_illusion and window.intelligence_illusion_label) then
        local sImmunity_TT = "Immune these level of Illusion spells. ";
        if (nChanged >= 19) then
            sImmunity_TT = sImmunity_TT .. DataCommonADND.aIntelligence[nChanged+100][5];
        end
        window.intelligence_illusion.setTooltipText(sImmunity_TT);
        window.intelligence_illusion_label.setTooltipText(sImmunity_TT);
    end
end
