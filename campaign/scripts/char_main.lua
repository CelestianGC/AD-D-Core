--
--
-- Functions for the character sheet.
--
--

function onInit()
    local nodeChar = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),      "onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),   "onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"),"onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),   "onUpdate", updateAbilityScores);

    DB.addHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", updateAbilityScores);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", updateAbilityScores);
    updateAbilityScores(nodeChar);
end

function onClose()
    local nodeChar = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),       "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),    "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"), "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),    "onUpdate", updateAbilityScores);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", updateAbilityScores);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", updateAbilityScores);
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
function updateAbilityScores(node)
    local nodeChar = node.getChild("....");
    -- onInit doesn't have the same path for node, so we check here so first time
    -- load works.
    if (nodeChar == nil and node.getPath():match("^charsheet%.id%-%d+$")) then
        nodeChar = node;
    end

    AbilityScoreADND.detailsUpdate(nodeChar);
    AbilityScoreADND.detailsPercentUpdate(nodeChar);

    --AbilityScoreADND.updateForEffects(nodeChar);
    AbilityScoreADND.updateCharisma(nodeChar);
    AbilityScoreADND.updateConstitution(nodeChar);
    AbilityScoreADND.updateDexterity(nodeChar);
    AbilityScoreADND.updateStrength(nodeChar);
    CharManager.updateEncumbrance(nodeChar);
    local dbAbility = AbilityScoreADND.updateWisdom(nodeChar);
    if (wisdom_immunity and wisdom_immunity_label 
        and wisdom_spellbonus and wisdom_spellbonus_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        wisdom_immunity.setTooltipText(dbAbility.sImmunity_TT);
        wisdom_immunity_label.setTooltipText(dbAbility.sImmunity_TT);

        wisdom_spellbonus.setTooltipText(dbAbility.sBonus_TT);
        wisdom_spellbonus_label.setTooltipText(dbAbility.sBonus_TT);
    end
    dbAbility = AbilityScoreADND.updateIntelligence(nodeChar);
    if (intelligence_illusion and intelligence_illusion_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        intelligence_illusion.setTooltipText(dbAbility.sImmunity_TT);
        intelligence_illusion_label.setTooltipText(dbAbility.sImmunity_TT);
    end

end