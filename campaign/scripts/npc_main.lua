-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
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

  DB.addHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateACandBaB);
  
  updateAbilityScores(nodeChar);
  checkNPCForSanity(getDatabaseNode());
  
  onSummaryChanged();
  updateACandBaB();
  update();
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
  DB.removeHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateACandBaB);
end

--
-- 
--
--
-- function detailsUpdate()
    -- local nodeChar = getDatabaseNode();
    -- AbilityScoreADND.detailsUpdate(nodeChar);
-- end

-- function detailsPercentUpdate()
    -- local nodeChar = getDatabaseNode();
    -- AbilityScoreADND.detailsPercentUpdate(nodeChar);
-- end
---
--- Update ability score total
---
---
function updateAbilityScores(node)
--Debug.console("npc_main.lua","updateAbilityScores","node",node);
    local nodeChar = node.getChild("....");
    -- -- onInit doesn't have the same path for node, so we check here so first time
    -- -- load works.
    if (node.getPath():match("^combattracker%.list%.id%-%d+$") or
        node.getPath():match("^npc%.id%-%d+$")) then
        nodeChar = node;
    end

--Debug.console("npc_main.lua","updateAbilityScores","nodeChar",nodeChar);

    AbilityScoreADND.detailsUpdate(nodeChar);
    AbilityScoreADND.detailsPercentUpdate(nodeChar);

    --AbilityScoreADND.updateForEffects(nodeChar);
    AbilityScoreADND.updateCharisma(nodeChar);
    AbilityScoreADND.updateConstitution(nodeChar);
    AbilityScoreADND.updateDexterity(nodeChar);
    AbilityScoreADND.updateStrength(nodeChar);
    AbilityScoreADND.updateWisdom(nodeChar);
--    CharManager.updateEncumbrance(nodeChar);
end
-- check hitdice and saves for sane values.
function checkNPCForSanity(nodeNPC)
    -- this is if someone uses a 5e npc with just "HD" and not "HITDICE" value set. 
    -- we do best guess on what the HD should be....BEST GUESS! --celestian
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    local sHDother = DB.getValue(nodeNPC, "hd", "");
    if sHitDice == "" and sHDother ~= "" then
        local sRawHD = string.gsub(sHDother,"[Dd]%d+","");
        -- remove spaces and () 
        sRawHD = string.gsub(sRawHD,"%s","");
        sRawHD = string.gsub(sRawHD,"%(","");
        sRawHD = string.gsub(sRawHD,"%)","");
        -- match \d+[+-]\d+
        local sM1, sM2 = sRawHD:match("(%d+)([%-+]%d+)");
        -- just using the first number, 5e has large +/- which scale off the charts for AD&D style
        if sM1 ~= "" then
            sHitDice = sM1;
            local nHD = tonumber(sHitDice) or 0;
            local nTHACO = 21 - nHD;
            thaco.setValue(nTHACO);
        end
        hitDice.setValue(sHitDice);
    end
    -- end kludge around npc hd/hitdice
    
    local nCount = DB.getChildCount(nodeNPC, "saves");
    local nPoison = DB.getValue(nodeNPC, "saves.poison.score",0);
    -- if set to default -20, then we build the saves from 
    -- creatures HDice
    if nPoison == -20 then
        CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
    end
end

function onSummaryChanged()
  local sSize = size.getValue();
  local sType = type.getValue();
  local sAlign = alignment.getValue();
  --
  local sAC = ac.getValue();
  local sHitDice = hitDice.getValue();
  local sSpeed = speed.getValue();
  local sTHACO = thaco.getValue();
  local sNumAtks = numberattacks.getValue();
  local sDamage = damage.getValue();
  local sSpecialD = specialDefense.getValue();
  local sSpecialA = specialAttacks.getValue();
  local sMR = magicresistance.getValue();
  local sMorale = morale.getValue();
  local sXP = xp.getValue();
  
  local aText = {};
  if sType ~= "" then
    table.insert(aText, "Type: " .. sType);
  end
  if sSize ~= "" then
    table.insert(aText, ", SZ: " .. sSize);
  end
  if sAlign ~= "" then
    table.insert(aText, "\rAL: " .. sAlign);
  end
  if sHitDice ~= "" then
    table.insert(aText, "\rHD: " .. sHitDice);
  end
  if sMorale ~= "" then
    table.insert(aText, ", Morale: " .. sMorale);
  end
  if sAC ~= "" then
    table.insert(aText, "\rAC: " .. sAC);
  end
  if sSpeed ~= "" then
    table.insert(aText, ", MV: " .. sSpeed);
  end
  if sTHACO ~= "" then
    table.insert(aText, "\rTHACO: " .. sTHACO);
  end
  if sNumAtks ~= "" then
    table.insert(aText, ", #ATK: " .. sNumAtks);
  end
  if sDamage ~= "" then
    table.insert(aText, ", DMG: " .. sDamage);
  end
  if sSpecialD ~= "" and sSpecialD:lower() ~= "nil" then
    table.insert(aText, "\rSD: " .. sSpecialD);
  end
  if sSpecialA ~= "" and sSpecialA:lower() ~= "nil" then
    table.insert(aText, "\rSA: " .. sSpecialA);
  end
  if sMR ~= "" then
    table.insert(aText, "\rMR: " .. sMR);
  end

  if sXP ~= "" then
    table.insert(aText, "\rXP: " .. sXP);
  end
  
  summary_label.setValue(table.concat(aText, " "));
end

function updateControl(sControl, bReadOnly, bForceHide)
  if not self[sControl] then
    return false;
  end
-- Debug.console("npc_main.lua","updateControl","self",self);  
-- Debug.console("npc_main.lua","updateControl","sControl",sControl);  
-- Debug.console("npc_main.lua","updateControl","bReadOnly",bReadOnly);  
-- Debug.console("npc_main.lua","updateControl","bForceHide",bForceHide);  
  
  return self[sControl].update(bReadOnly, bForceHide);
end

function update()
  local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
  local bID = LibraryData.getIDState("npc", nodeRecord);
  local bSection1 = false;
  if User.isHost() then
    if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
  else
    updateControl("nonid_name", bReadOnly, true);
  end
  divider.setVisible(bSection1);


  updateControl("size", bReadOnly);
  updateControl("type", bReadOnly);
  updateControl("alignment", bReadOnly);
  updateControl("ac", bReadOnly);
  updateControl("ac_ascending", bReadOnly);
  updateControl("actext", bReadOnly);
  updateControl("hp", bReadOnly, bReadOnly);
  updateControl("hd", bReadOnly, bReadOnly);
  updateControl("hitDice", bReadOnly);
  updateControl("hdtext", bReadOnly,bReadOnly);
  updateControl("thaco", bReadOnly);
  updateControl("bab", bReadOnly);
  updateControl("speed", bReadOnly);
  updateControl("numberattacks", bReadOnly);
  updateControl("damage", bReadOnly);
  updateControl("specialDefense", bReadOnly);
  updateControl("specialAttacks", bReadOnly);
  updateControl("magicresistance", bReadOnly);
  updateControl("morale", bReadOnly);
  updateControl("xp", bReadOnly);

  -- updateControl("size", bReadOnly, bReadOnly);
  -- updateControl("type", bReadOnly, bReadOnly);
  -- updateControl("alignment", bReadOnly, bReadOnly);
  -- updateControl("ac", bReadOnly, bReadOnly);
  -- updateControl("actext", bReadOnly, bReadOnly);
  -- updateControl("hp", bReadOnly, bReadOnly);
  -- updateControl("hd", bReadOnly, bReadOnly);
  -- updateControl("hitDice", bReadOnly, bReadOnly);
  -- updateControl("hdtext", bReadOnly, bReadOnly);
  -- updateControl("thaco", bReadOnly, bReadOnly);
  -- updateControl("speed", bReadOnly, bReadOnly);
  -- updateControl("numberattacks", bReadOnly, bReadOnly);
  -- updateControl("damage", bReadOnly, bReadOnly);
  -- updateControl("specialDefense", bReadOnly, bReadOnly);
  -- updateControl("specialAttacks", bReadOnly, bReadOnly);
  -- updateControl("magicresistance", bReadOnly, bReadOnly);
  -- updateControl("morale", bReadOnly, bReadOnly);
  -- updateControl("xp", bReadOnly, bReadOnly);
  --summary_label.setVisible(bReadOnly);
  
  summary_label.setVisible(false); -- dont use this anymore, just hide it all the time
  --npc_line_editmode.setVisible(not bReadOnly);
  
  updateControl("strength", bReadOnly);
  updateControl("constitution", bReadOnly);
  updateControl("dexterity", bReadOnly);
  updateControl("intelligence", bReadOnly);
  updateControl("wisdom", bReadOnly);
  updateControl("charisma", bReadOnly);

  updateControl("savingthrows", bReadOnly);
  updateControl("skills", bReadOnly);
  updateControl("damagevulnerabilities", bReadOnly);
  updateControl("damageresistances", bReadOnly);
  updateControl("damageimmunities", bReadOnly);
  updateControl("conditionimmunities", bReadOnly);
  updateControl("senses", bReadOnly);
  updateControl("languages", bReadOnly);
  updateControl("challengerating", bReadOnly);
  updateControl("effect_combat", bReadOnly);
  
  updateControl("organization", bReadOnly);
  updateControl("diet", bReadOnly);
  updateControl("frequency", bReadOnly);
  updateControl("activity", bReadOnly);
  updateControl("climate", bReadOnly);
  updateControl("numberappearing", bReadOnly);
  updateControl("intelligence_text", bReadOnly);
  updateControl("treasure", bReadOnly);

  ac.setReadOnly(bReadOnly);
  ac_ascending.setReadOnly(bReadOnly);
  actext.setReadOnly(bReadOnly);
  hp.setReadOnly(bReadOnly);
  hd.setReadOnly(bReadOnly);
  hitDice.setReadOnly(bReadOnly);
  thaco.setReadOnly(bReadOnly);
  bab.setReadOnly(bReadOnly);
  numberattacks.setReadOnly(bReadOnly);
  damage.setReadOnly(bReadOnly);
  morale.setReadOnly(bReadOnly);
  specialAttacks.setReadOnly(bReadOnly);
  specialDefense.setReadOnly(bReadOnly);
  speed.setReadOnly(bReadOnly);

  cr.setReadOnly(bReadOnly);
  xp.setReadOnly(bReadOnly);
  
  organization.setReadOnly(bReadOnly);
  diet.setReadOnly(bReadOnly);
  frequency.setReadOnly(bReadOnly);
  activity.setReadOnly(bReadOnly);
  climate.setReadOnly(bReadOnly);
  numberappearing.setReadOnly(bReadOnly);
  intelligence_text.setReadOnly(bReadOnly);
  treasure.setReadOnly(bReadOnly);

  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  -- now lets deal with labels, numbers/etc visibility and positions
  bab.setReadOnly(not bOptAscendingAC);
  bab.setVisible(bOptAscendingAC);
  bab_label.setVisible(bOptAscendingAC);
  ac_ascending.setReadOnly(not bOptAscendingAC);
  ac_ascending.setVisible(bOptAscendingAC);
  ac_ascending_label.setVisible(bOptAscendingAC);
  ---
  thaco.setReadOnly(bOptAscendingAC);
  thaco.setVisible(not bOptAscendingAC);
  thaco_label.setVisible(not bOptAscendingAC);
  ac.setReadOnly(bOptAscendingAC);
  ac.setVisible(not bOptAscendingAC);
  ac_label.setVisible(not bOptAscendingAC);

  if (bOptAscendingAC) then
    actext.setAnchor("left","ac_ascending","right","relative",10);
    speed_label.setAnchor("left","bab","right","relative",10);
  else
    actext.setAnchor("left","ac","right","relative",10);
    speed_label.setAnchor("left","thaco","right","relative",10);
  end
  
  -- if bReadOnly then
    -- if traits_iedit then
      -- traits_iedit.setValue(0);
      -- traits_iedit.setVisible(false);
    -- end
    
    -- local bShow = (traits.getWindowCount() ~= 0);
    -- header_traits.setVisible(bShow);
    -- traits.setVisible(bShow);
  -- else
    -- if traits_iedit then
      -- traits_iedit.setVisible(true);
    -- end
    -- header_traits.setVisible(true);
    -- traits.setVisible(true);
  -- end
  -- for _,w in ipairs(traits.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end

  -- if bReadOnly then
    -- if actions_iedit then
      -- actions_iedit.setValue(0);
      -- actions_iedit.setVisible(false);
    -- end
    
    -- local bShow = (actions.getWindowCount() ~= 0);
    -- header_actions.setVisible(bShow);
    -- actions.setVisible(bShow);
  -- else
    -- if actions_iedit then
      -- actions_iedit.setVisible(true);
    -- end
    -- header_actions.setVisible(true);
    -- actions.setVisible(true);
  -- end
  -- for _,w in ipairs(actions.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
  
  -- if bReadOnly then
    -- if reactions_iedit then
      -- reactions_iedit.setValue(0);
      -- reactions_iedit.setVisible(false);
    -- end
    
    -- local bShow = (reactions.getWindowCount() ~= 0);
    -- header_reactions.setVisible(bShow);
    -- reactions.setVisible(bShow);
  -- else
    -- if reactions_iedit then
      -- reactions_iedit.setVisible(true);
    -- end
    -- header_reactions.setVisible(true);
    -- reactions.setVisible(true);
  -- end
  -- for _,w in ipairs(reactions.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
  
  -- if bReadOnly then
    -- if legendaryactions_iedit then
      -- legendaryactions_iedit.setValue(0);
      -- legendaryactions_iedit.setVisible(false);
    -- end
    
    -- local bShow = (legendaryactions.getWindowCount() ~= 0);
    -- header_legendaryactions.setVisible(bShow);
    -- legendaryactions.setVisible(bShow);
  -- else
    -- if legendaryactions_iedit then
      -- legendaryactions_iedit.setVisible(true);
    -- end
    -- header_legendaryactions.setVisible(true);
    -- legendaryactions.setVisible(true);
  -- end
  -- for _,w in ipairs(legendaryactions.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
  
  -- if bReadOnly then
    -- if lairactions_iedit then
      -- lairactions_iedit.setValue(0);
      -- lairactions_iedit.setVisible(false);
    -- end
    
    -- local bShow = (lairactions.getWindowCount() ~= 0);
    -- header_lairactions.setVisible(bShow);
    -- lairactions.setVisible(bShow);
  -- else
    -- if lairactions_iedit then
      -- lairactions_iedit.setVisible(true);
    -- end
    -- header_lairactions.setVisible(true);
    -- lairactions.setVisible(true);
  -- end
  -- for _,w in ipairs(lairactions.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
  
  -- if bReadOnly then
    -- if innatespells_iedit then
      -- innatespells_iedit.setValue(0);
      -- innatespells_iedit.setVisible(false);
    -- end
    
    -- local bShow = (innatespells.getWindowCount() ~= 0);
    -- header_innatespells.setVisible(bShow);
    -- innatespells.setVisible(bShow);
  -- else
    -- if innatespells_iedit then
      -- innatespells_iedit.setVisible(true);
    -- end
    -- header_innatespells.setVisible(true);
    -- innatespells.setVisible(true);
  -- end
  -- for _,w in ipairs(innatespells.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
  
  -- if bReadOnly then
    -- if spells_iedit then
      -- spells_iedit.setValue(0);
      -- spells_iedit.setVisible(false);
    -- end
    
    -- local bShow = (spells.getWindowCount() ~= 0);
    -- header_spells.setVisible(bShow);
    -- spells.setVisible(bShow);
  -- else
    -- if spells_iedit then
      -- spells_iedit.setVisible(true);
    -- end
    -- header_spells.setVisible(true);
    -- spells.setVisible(true);
  -- end
  -- for _,w in ipairs(spells.getWindows()) do
    -- w.name.setReadOnly(bReadOnly);
    -- w.desc.setReadOnly(bReadOnly);
  -- end
end

function addTrait(sName, sDesc)
  local w = traits.createWindow();
  if w then
    w.name.setValue(sName);
    w.desc.setValue(sDesc);
  end
end

function addAction(sName, sDesc)
  local w = actions.createWindow();
  if w then
    w.name.setValue(sName);
    w.desc.setValue(sDesc);
  end
end

function addSpell(sName, sDesc, bInnate)
  local w = nil;
  if bInnate then
    w = innatespells.createWindow();
  else
    w = spells.createWindow();
  end
  if w then
    w.name.setValue(sName);
    w.desc.setValue(sDesc);
  end
end

function addSpellDrop(nodeSource, bInnate)
  local aDesc = {};
  
  local sSchool = DB.getValue(nodeSource, "school", "");
  local nLevel = DB.getValue(nodeSource, "level", 0);
  if sSchool ~= "" then
    sSchool = sSchool .. " ";
  end
  if nLevel ~= 0 then
    table.insert(aDesc, sSchool .. "L" .. nLevel);
  else
    table.insert(aDesc, sSchool .. "Cantrip");
  end
  
  local sCastTime = DB.getValue(nodeSource, "castingtime", "");
  if sCastTime ~= "" then
    table.insert(aDesc, "Casting Time: " .. sCastTime);
  end
  
  local sRange = DB.getValue(nodeSource, "range", "");
  if sRange ~= "" then
    table.insert(aDesc, "Range: " .. sRange);
  end
  
  local sDuration = DB.getValue(nodeSource, "duration", "");
  if sDuration ~= "" then
    table.insert(aDesc, "Duration: " .. sDuration);
  end

  local sDesc = DB.getText(nodeSource, "description", "");
  if sDesc ~= "" then
    table.insert(aDesc, sDesc);
  end
  
  addSpell(DB.getValue(nodeSource, "name", ""), table.concat(aDesc, "\r"), bInnate);
end

function onDrop(x, y, draginfo)
-- all of these moved to actions/skills so no longer needed for drag/drop here.

  -- if draginfo.isType("shortcut") then
    -- local sClass = draginfo.getShortcutData();
    -- local nodeSource = draginfo.getDatabaseNode();
    
    -- if sClass == "reference_spell" or sClass == "power" then
      -- addSpellDrop(nodeSource); -- we dont drag/drop spells here with AD&D Core
    -- elseif sClass == "reference_backgroundfeature" then
      -- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
    -- elseif sClass == "reference_classfeature" then
      -- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
    -- elseif sClass == "reference_feat" then
      -- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
    -- elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
      -- addTrait(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
    -- end
    -- return true;
  -- end
end

function updateACandBaB()
  local node = getDatabaseNode();
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  -- setup handlers for whatever mode we're in, remove ones we're not
  if (bOptAscendingAC) then
    -- DB.removeHandler(DB.getPath(node, "ac"),    "onUpdate", updateAscendingAC);  
    -- DB.removeHandler(DB.getPath(node, "thaco"),    "onUpdate", updateBAB);  
    
    -- DB.addHandler(DB.getPath(node, "ac_ascending"),    "onUpdate", updateAC);  
    -- DB.addHandler(DB.getPath(node, "bab"),    "onUpdate", updateTHACO);  
    updateAC(node);
    updateTHACO(node);
  else
    -- DB.removeHandler(DB.getPath(node, "ac_ascending"),    "onUpdate", updateAC);  
    -- DB.removeHandler(DB.getPath(node, "bab"),    "onUpdate", updateTHACO);  

    -- DB.addHandler(DB.getPath(node, "ac"),    "onUpdate", updateAscendingAC);  
    -- DB.addHandler(DB.getPath(node, "thaco"),    "onUpdate", updateBAB);  
    updateAscendingAC(node);
    updateBAB(node);
  end
  update();
end

function updateAscendingAC(node)
  -- check and see if this is npc.id-XXXXXX.ac, if so drop back a node
  if (not node.getPath():match("id%-%d+$"))then
    node = node.getParent();
  end
  local nAC = DB.getValue(node,"ac",10);
  local nAscendingAC = DB.getValue(node,"ac_ascending",10);
  local newAC = 20 - nAC;
  if (nAC < 10 and (newAC ~= nAscendingAC)) then
    DB.setValue(node,"ac_ascending","number",newAC);
  end
end
function updateBAB(node)
  if (not node.getPath():match("id%-%d+$"))then
    node = node.getParent();
  end
  local nTHACO = DB.getValue(node,"thaco",20);
  local nBAB = DB.getValue(node,"bab",0);
  local newBAB = 20 - nTHACO;
  if (nTHACO > 0 and (newBAB ~= nBAB) ) then
    DB.setValue(node,"bab","number",newBAB);
  end
end

function updateAC(node)
  if (not node.getPath():match("id%-%d+$"))then
    node = node.getParent();
  end
 local nAscendingAC = DB.getValue(node,"ac_ascending",10);
 local nAC = DB.getValue(node,"ac_ascending",10);
 local newAC = 20 - nAscendingAC;
 if (newAC ~= nAC) then
  DB.setValue(node,"ac","number",newAC);
 end
end
function updateTHACO(node)
  if (not node.getPath():match("id%-%d+$"))then
    node = node.getParent();
  end
 local nBAB = DB.getValue(node,"bab",0);
 local nTHACO = DB.getValue(node,"thaco",0);
 local newTHACO = 20 - nBAB;
 if (nBAB > 0 and newTHACO ~= nTHACO) then
  DB.setValue(node,"thaco","number",newTHACO);
 end
end