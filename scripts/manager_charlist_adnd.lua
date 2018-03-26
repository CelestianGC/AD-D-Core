--
--
-- Register bits for the combat tracker
--
--
--

function onInit()
  --if User.isHost() then
    DB.addHandler("combattracker.list.*.initrolled", "onUpdate", onUpdate);
    CharacterListManager.addDecorator("init_rolled", addInitiativeWidget);
  --end
end

function onUpdate(nodeInit)
Debug.console("manager_charlist_adnd.lua","onUpdate","sIdentity",sIdentity);
  local nodeCT = nodeInit.getChild("..");
  local sIdentity = getIdentityFromCTNode(nodeCT);
Debug.console("manager_charlist_adnd.lua","onUpdate","sIdentity",sIdentity);
	updateWidgets(sIdentity);
end

function addInitiativeWidget(control, sIdentity)
	local widget = control.addBitmapWidget("init_rolled");
	widget.setPosition("center", -25, 9);
	widget.setVisible(true);
	widget.setName("initiativerolled");

	local textwidget = control.addTextWidget("mini_name", "");
	textwidget.setPosition("center", -25, 9);
	textwidget.setVisible(false);
	textwidget.setName("initiativerolledtext");
	
	updateWidgets(sIdentity);
end

-- update widget when init_roll value changes
function updateWidgets(sIdentity)
	local ctrlChar = CharacterListManager.getEntry(sIdentity);
	if not ctrlChar then
		return;
	end
	local widget = ctrlChar.findWidget("initiativerolled");
	local textwidget = ctrlChar.findWidget("initiativerolledtext");
	if not widget or not textwidget then
		return;
	end	
  local nodeCT = CombatManager.getCTFromNode("charsheet." .. sIdentity);
  local bRolled = (DB.getValue(nodeCT,"initrolled",0) == 1);
	if bRolled then
		widget.setVisible(false);
		textwidget.setVisible(false);
  else
		widget.setVisible(true);
		textwidget.setVisible(true);
  end
end

-- get Identity of a char node or from the CT node that is a PC
function getIdentityFromCTNode(nodeCT)
  local rActor = ActorManager.getActorFromCT(nodeCT);
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);    
  return getIdentityFromCharNode(nodeActor);
end
function getIdentityFromCharNode(nodeChar)
  return nodeChar.getName();
end