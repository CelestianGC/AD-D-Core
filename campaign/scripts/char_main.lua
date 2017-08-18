--
--
-- Functions for the character sheet.
--
--

function onInit()
    local nodeChar = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),      "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),   "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"),"onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),   "onUpdate", detailsPercentUpdate);

    DB.addHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

    DB.addHandler(DB.getPath(nodeChar, "abilities.strength.total"),    "onUpdate", updateStrength);
    DB.addHandler(DB.getPath(nodeChar, "abilities.strength.percenttotal"),    "onUpdate", updateStrength);
    DB.addHandler(DB.getPath(nodeChar, "abilities.constitution.total"),"onUpdate", updateConstitution);
    DB.addHandler(DB.getPath(nodeChar, "abilities.intelligence.total"),"onUpdate", updateIntelligence);
    DB.addHandler(DB.getPath(nodeChar, "abilities.wisdom.total"),       "onUpdate", updateWisdom);
    DB.addHandler(DB.getPath(nodeChar, "abilities.dexterity.total"),    "onUpdate", updateDexterity);
    DB.addHandler(DB.getPath(nodeChar, "abilities.charisma.total"),     "onUpdate", updateCharisma);
    
    detailsPercentUpdate();
    detailsUpdate();
    AbilityScoreADND.updateForEffects(nodeChar);
end

function onClose()
    local nodeChar = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),       "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),    "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"), "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),    "onUpdate", detailsPercentUpdate);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.strength.total"),    "onUpdate", updateStrength);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.strength.percenttotal"),    "onUpdate", updateStrength);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.constitution.total"),"onUpdate", updateConstitution);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.intelligence.total"),"onUpdate", updateIntelligence);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.wisdom.total"),       "onUpdate", updateWisdom);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.dexterity.total"),    "onUpdate", updateDexterity);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.charisma.total"),     "onUpdate", updateCharisma);
end


--
--
--
function detailsUpdate()
    local nodeChar = getDatabaseNode();
    AbilityScoreADND.detailsUpdate(nodeChar);
end

function detailsPercentUpdate()
    local nodeChar = getDatabaseNode();
    AbilityScoreADND.detailsPercentUpdate(nodeChar);
end

-- allow drag/drop of class/race/backgrounds onto main sheet
function onDrop(x, y, draginfo)
    if draginfo.isType("shortcut") then
        local sClass, sRecord = draginfo.getShortcutData();

        if StringManager.contains({"reference_class", "reference_race", "reference_subrace", "reference_background"}, sClass) then
            CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
            if StringManager.contains({"reference_class"}, sClass) then
                Interface.openWindow("charsheet_classes", getDatabaseNode());
            end
            return true;
        end
    end
end

function onHealthChanged()
    local sColor = ActorManager2.getWoundColor("pc", getDatabaseNode());
    wounds.setColor(sColor);
end

---
--- Update ability score total
---
---
function updateStrength(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateStrength(nodeChar);
    -- update encumbrance if we changed strength
    CharManager.updateEncumbrance(nodeChar);
end
function updateDexterity(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateDexterity(nodeChar);
end
function updateConstitution(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateConstitution(nodeChar);
end
function updateCharisma(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateCharisma(nodeChar);
end
function updateWisdom(node)
    local nodeChar = node.getChild("....");
    dbAbility = AbilityScoreADND.updateWisdom(nodeChar);
    if (wisdom_immunity and wisdom_immunity_label 
        and wisdom_spellbonus and wisdom_spellbonus_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        wisdom_immunity.setTooltipText(dbAbility.sImmunity_TT);
        wisdom_immunity_label.setTooltipText(dbAbility.sImmunity_TT);

        wisdom_spellbonus.setTooltipText(dbAbility.sBonus_TT);
        wisdom_spellbonus_label.setTooltipText(dbAbility.sBonus_TT);
    end
    
end
function updateIntelligence(node)
    local nodeChar = node.getChild("....");
    dbAbility = AbilityScoreADND.updateIntelligence(nodeChar);
    if (intelligence_illusion and intelligence_illusion_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        intelligence_illusion.setTooltipText(dbAbility.sImmunity_TT);
        intelligence_illusion_label.setTooltipText(dbAbility.sImmunity_TT);
    end
end
