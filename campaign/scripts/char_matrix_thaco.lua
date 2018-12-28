---
--- Creates controls/updates for THACO Attack Matrix window
---
---


function onInit()
  local node = getDatabaseNode();
  local bisPC = (ActorManager.isPC(node)); 
  if (bisPC) then
    DB.addHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
  else
    DB.addHandler(DB.getPath(node, "thaco"), "onUpdate", update);
  end
  createTHACOMatrix();
end

function onClose()
  local node = getDatabaseNode();
  local bisPC = (ActorManager.isPC(node)); 
  if (bisPC) then
    DB.removeHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
  else
    DB.removeHandler(DB.getPath(node, "thaco"), "onUpdate", update);  
  end
end

function createTHACOMatrix()
  local node = getDatabaseNode();
  local bisPC = (ActorManager.isPC(node)); 
--Debug.console("char_matrix_thaco.lua","createTHACOMatrix","node",node);
  local nTHACO = DB.getValue(node,"combat.thaco.score",20);
  if (not bisPC) then
    nTHACO = DB.getValue(node,"thaco",20);
  end
  local sACLabelName = "matrix_ac_label";
  local sRollLabelName = "matrix_roll_label";
  local sHightlightColor = "a5a7aa";
  local sRedColor = "ddaf90";
  local bHighlight = true;
  for i=-10,10,1 do
    local nTHAC = nTHACO - i; -- to hit AC value. Current THACO for this Armor Class. so 20 - 10 for AC 10 would be 30.
    local sMatrixACName = "thaco_matrix_ac_" .. i; -- control name for the AC label
    local sMatrixACValue = i;                      -- AC control value
    local sMatrixNumberName = "thac" .. i;         -- control name for the THACO label
    local cntNum = createControl("number_thaco_matrix", sMatrixNumberName);
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
  local nTHACO = DB.getValue(node,"combat.thaco.score",20);
  if (not bisPC) then
    nTHACO = DB.getValue(node,"thaco",20);
  end
  for i=-10,10,1 do -- update to changed THACO, just set the new values in previosly created controls
    local nTHAC = nTHACO - i;
    local sMatrixNumberName = "thac" .. i; -- control name for the THACO label
    local cnt = self[sMatrixNumberName];   -- get the control for this, stringcontrol named thac-10 .. thac10
    cnt.setValue(nTHAC); -- set new to hit AC value
  end
end
