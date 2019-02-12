---
---
---
---


function onInit()
  createAttackMatrix();
end

function onClose()
end

function createAttackMatrix()
  local node = getDatabaseNode();
--Debug.console("char_matrix.lua","createAttackMatrix","node",node);    
  local sACLabelName = "matrix_ac_label";
  local sRollLabelName = "matrix_roll_label";
  for i=-10,10,1 do
    --local nTHAC = DB.getValue(node,"thac" .. i, 0);
    local nTHAC = DB.getValue(node,"combat.matrix.thac" .. i, 20);

    local sMatrixACName = "matrix_ac_" .. i;
    local sMatrixACValue = i;
    local sMatrixNumberName = "thac" .. i;
    local cntNum = createControl("number_matrix", sMatrixNumberName, "combat.matrix." .. sMatrixNumberName);
    cntNum.setValue(nTHAC);

    local cntAC = createControl("label_fieldtop_matrix", sMatrixACName);
    cntAC.setReadOnly(true);
    cntAC.setValue(sMatrixACValue);
    cntAC.setAnchor("left", sMatrixNumberName,"left","absolute",0);
  end
end