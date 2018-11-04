--
--
-- Functions for the character sheet.
--
--

function onInit()
  local nodeChar = getDatabaseNode();
  DB.addHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateAscendingValues);

  DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),      "onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),   "onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"),"onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),   "onUpdate", updateAbilityScores);

  DB.addHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", updateAbilityScores);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", updateAbilityScores);
  
  DB.addHandler(DB.getPath(nodeChar, "hp.base"),        "onUpdate", updateHealthScore);
  DB.addHandler(DB.getPath(nodeChar, "hp.basemod"),     "onUpdate", updateHealthScore);
  --this is managed, not adjusted by players
  --DB.addHandler(DB.getPath(nodeChar, "hp.hpconmod"),  "onUpdate", updateHealthScore);
  
  DB.addHandler(DB.getPath(nodeChar, "hp.adjustment"),  "onUpdate", updateHealthScore);
  DB.addHandler(DB.getPath(nodeChar, "hp.tempmod"),     "onUpdate", updateHealthScore);

  updateAbilityScores(nodeChar);
  updateAscendingValues();
end

function onClose()
  local nodeChar = getDatabaseNode();
  DB.removeHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateAscendingValues);
  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),       "onUpdate", updateAbilityScores);
  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),    "onUpdate", updateAbilityScores);
  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"), "onUpdate", updateAbilityScores);
  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),    "onUpdate", updateAbilityScores);

  DB.removeHandler(DB.getPath(nodeChar, "hp.base"),       "onUpdate", updateHealthScore);
  DB.removeHandler(DB.getPath(nodeChar, "hp.basemod"),    "onUpdate", updateHealthScore);
  DB.removeHandler(DB.getPath(nodeChar, "hp.adjustment"), "onUpdate", updateHealthScore);
  DB.removeHandler(DB.getPath(nodeChar, "hp.tempmod"),    "onUpdate", updateHealthScore);
  
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
  
  -- this makes sure if con changes hp con adjustments are managed
  updateHealthScore();
end

function updateAscendingValues()
  local node = getDatabaseNode();
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  -- setup handlers for whatever mode we're in, remove ones we're not
  if (bOptAscendingAC) then
    DB.removeHandler(DB.getPath(node, "combat.thaco.score"),    "onUpdate", updateBAB);  
    DB.addHandler(DB.getPath(node, "combat.bab.score"),    "onUpdate", updateTHACO);  
    updateTHACO(node);
  else
    DB.removeHandler(DB.getPath(node, "combat.bab.score"),    "onUpdate", updateTHACO);  

    DB.addHandler(DB.getPath(node, "combat.thaco.score"),    "onUpdate", updateBAB);  
    updateBAB(node);
  end
  
  -- now lets deal with labels, numbers/etc visibility and positions
  bab.setVisible(bOptAscendingAC);
  bab_label.setVisible(bOptAscendingAC);
  ---
  thaco.setVisible(not bOptAscendingAC);
  thaco_label.setVisible(not bOptAscendingAC);

  -- if (bOptAscendingAC) then
    -- actext.setAnchor("left","ac_ascending","right","relative",10);
    -- speed_label.setAnchor("left","bab","right","relative",10);
  -- else
    -- actext.setAnchor("left","ac","right","relative",10);
    -- speed_label.setAnchor("left","thaco","right","relative",10);
  -- end
end

function updateBAB()
  local node = getDatabaseNode();
  local nTHACO = DB.getValue(node,"combat.thaco.score",20);
  local nBAB = 0;
  if (nTHACO > 0) then
    nBAB = 20 - nTHACO;
  end
  DB.setValue(node,"combat.bab.score","number",nBAB);
end
function updateTHACO()
 local node = getDatabaseNode();
 local nBAB = DB.getValue(node,"combat.bab.score",0);
 local nTHACO = 20;
 if (nBAB > 0) then
  nTHACO = 20 - nBAB;
 end
 DB.setValue(node,"combat.thaco.score","number",nTHACO);
end

---
-- Manage hitpoint modifiers and total, HANDOFF to CharManager
-- we hand off to CharManager because we need to access the healupdate
-- when effects are updated and con changes. ct_entry.lua, updateForEffects(effect) also
---
function updateHealthScore()
  local nodeChar = getDatabaseNode();
  CharManager.updateHealthScore(nodeChar);
end



