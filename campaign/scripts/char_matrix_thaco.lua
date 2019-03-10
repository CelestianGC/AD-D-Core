---
--- Creates controls/updates for THACO Attack Matrix window
---
---


function onInit()
  local node = getDatabaseNode();
--Debug.console("char_matrix_thaco.lua","onInit","node",node);      
  local bisPC = (ActorManager.isPC(node)); 
--Debug.console("char_matrix_thaco.lua","onInit","bisPC",bisPC);      
  local bUseMatrix = (DataCommonADND.coreVersion == "1e");
--Debug.console("char_matrix_thaco.lua","onInit","bUseMatrix1",bUseMatrix);    
  if bUseMatrix then
    DB.addHandler(DB.getPath(node, "combat.matrix.*"), "onUpdate", update);
  else
    if (bisPC) then
      DB.addHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
    else
      DB.addHandler(DB.getPath(node, "thaco"), "onUpdate", update);
    end
  end
  createTHACOMatrix();
end

function onClose()
  local node = getDatabaseNode();
  local bisPC = (ActorManager.isPC(node)); 
  local bUseMatrix = (DataCommonADND.coreVersion == "1e");
  if bUseMatrix then
    DB.removeHandler(DB.getPath(node, "combat.matrix.*"), "onUpdate", update);
  else
    if (bisPC) then
      DB.removeHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
    else
      DB.removeHandler(DB.getPath(node, "thaco"), "onUpdate", update);  
    end
  end
end

function createTHACOMatrix()
  local node = getDatabaseNode();
  local bisPC = (ActorManager.isPC(node)); 
  local bUseMatrix = (DataCommonADND.coreVersion == "1e");
--Debug.console("char_matrix_thaco.lua","createTHACOMatrix","node",node);
  local nTHACO = DB.getValue(node,"combat.thaco.score",20);
  if (not bisPC) then
    nTHACO = DB.getValue(node,"thaco",20);
  end
  -- 1e matrix
  local aMatrixRolls = {};
  if bUseMatrix and not bisPC then 
    local sHitDice = CombatManagerADND.getNPCHitDice(node);
    if DataCommonADND.aMatrix[sHitDice] then
      aMatrixRolls = DataCommonADND.aMatrix[sHitDice];
    end
  end
  --

  local sACLabelName = "matrix_ac_label";
  local sRollLabelName = "matrix_roll_label";
  local sHightlightColor = "a5a7aa";
  local sRedColor = "ddaf90";
  local bHighlight = true;
  for i=-10,10,1 do
    local nTHAC = nTHACO - i; -- to hit AC value. Current THACO for this Armor Class. so 20 - 10 for AC 10 would be 30.
    if bUseMatrix then
      nTHAC = DB.getValue(node,"combat.matrix.thac" .. i, 20);
      -- 1e matrix
      if not bisPC and #aMatrixRolls > 0 then
      -- math.abs(i-11), this table is reverse of how we display the matrix
      -- so we start at the end instead of at the front by taking I - 11 then get the absolute value of it.
       nTHAC = aMatrixRolls[math.abs(i-11)];
      end
      --
    end
    local sMatrixACName = "thaco_matrix_ac_" .. i; -- control name for the AC label
    local sMatrixACValue = i;                      -- AC control value
    local sMatrixNumberName = "thac" .. i;         -- control name for the THACO label
    local cntNum = nil;
    if bUseMatrix then
      cntNum = createControl("number_thaco_matrix", sMatrixNumberName, "combat.matrix." .. sMatrixNumberName);
    else
      cntNum = createControl("number_thaco_matrix", sMatrixNumberName);
    end
    
    --cntNum.setReadOnly(true);
    cntNum.setFrame(nil);
    cntNum.setValue(nTHAC);

    local cntAC = createControl("label_fieldtop_thaco_matrix", sMatrixACName);
    cntAC.setReadOnly(true);
    cntAC.setValue(sMatrixACValue);
    if (i == 0) then
      cntNum.setBackColor(sRedColor);
      cntAC.setBackColor(sRedColor);
    elseif bHighlight then
      cntNum.setBackColor(sHightlightColor);
      cntAC.setBackColor(sHightlightColor);
    end
    cntAC.setAnchor("left", sMatrixNumberName,"left","absolute",0);
    --cntAC.setAnchor("top", sMatrixNumberName,"bottom","absolute",1);
    
    bHighlight = not bHighlight;
  end
end

function update()
  local node = getDatabaseNode();
--Debug.console("char_matrix_thaco.lua","update","node",node);
  local bisPC = (ActorManager.isPC(node)); 
--Debug.console("char_matrix_thaco.lua","createTHACOMatrix","node",node);
  local bUseMatrix = (DataCommonADND.coreVersion ~= "2e");

  local nTHACO = DB.getValue(node,"combat.thaco.score",20);
  if (not bisPC) then
    nTHACO = DB.getValue(node,"thaco",20);
  end
  for i=-10,10,1 do -- update to changed THACO. Set the new values in previously created controls
    local nTHAC = nTHACO - i;
    if bUseMatrix then
      nTHAC = DB.getValue(node,"combat.matrix.thac" .. i, 20);
    end
    
    local sMatrixNumberName = "thac" .. i; -- control name for the THACO label
    local cnt = self[sMatrixNumberName];   -- get the control for this, stringcontrol named thac-10 .. thac10
    cnt.setValue(nTHAC); -- set new to hit AC value
  end
end
