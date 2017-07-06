-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onDataChanged()
	updateDisplay();
	updateViews();
end

function updateDisplay()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
    local nodeAction = getDatabaseNode();
	local nLevel = DB.getValue(nodeAction, "...level", 0);
    local sSpellType = DB.getValue(nodeAction, "...type", ""):lower();
    local bCanMemorize = (nLevel>0 and (PowerManager.isArcaneSpellType(sSpellType) or PowerManager.isDivineSpellType(sSpellType)));
    
	if sType == "cast" then
        castinitiative.setVisible(true);
         if (bCanMemorize) then
             button_memorize.setVisible(true);
             memorizedcount.setVisible(true);
         else
             button_memorize.setVisible(false);
             memorizedcount.setVisible(false);
         end
    else
        castinitiative.setVisible(false);
        button_memorize.setVisible(false);
        memorizedcount.setVisible(false);
	end
end

function updateViews()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		onCastChanged();
	end
end

function onCastChanged()
	local nodeAction = getDatabaseNode();
	if not nodeAction then
		return;
	end
	--button.setTooltipText(sTooltip);
end

function getFilter()
    local bShow = true;
  	local sType = DB.getValue(getDatabaseNode(), "type", "");
    local nodeAction = getDatabaseNode();
	local nLevel = DB.getValue(nodeAction, "...level", 0);
    local sSpellType = DB.getValue(nodeAction, "...type", ""):lower();
    local bCanMemorize = (nLevel>0 and (PowerManager.isArcaneSpellType(sSpellType) or PowerManager.isDivineSpellType(sSpellType)));
   
    return bCanMemorize
end
