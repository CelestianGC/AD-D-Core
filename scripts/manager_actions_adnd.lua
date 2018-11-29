---
--- replace parts of the CoreRPG manager_actions.lua functions?
---

-- function onInit()
  -- ActionsManager.messageResult = messageResult;
  -- Debug.console("manager_actions_adnd.lua","onInit","ActionsManager.messageResult",ActionsManager.messageResult);
-- end

-- function messageResult(bSecret, rSource, rTarget, rMessageGM, rMessagePlayer)

-- Debug.console("manager_actions_adnd.lua","messageResult","bSecret",bSecret);
-- Debug.console("manager_actions_adnd.lua","messageResult","rSource",rSource);
-- Debug.console("manager_actions_adnd.lua","messageResult","rTarget",rTarget);
-- Debug.console("manager_actions_adnd.lua","messageResult","rMessageGM",rMessageGM);
-- Debug.console("manager_actions_adnd.lua","messageResult","rMessagePlayer",rMessagePlayer);

	-- local bShowResultsToPlayer;
	-- local sOptSHRR = OptionsManager.getOption("SHRR");
-- Debug.console("manager_actions_adnd.lua","messageResult","sOptSHRR",sOptSHRR);
	-- if sOptSHRR == "off" then
		-- bShowResultsToPlayer = false;
	-- elseif sOptSHRR == "pc" then
		-- if (not rSource or ActorManager.getFaction(rSource) == "friend") and (not rTarget or ActorManager.getFaction(rTarget) == "friend") then
			-- bShowResultsToPlayer = true;
		-- else
			-- bShowResultsToPlayer = false;
		-- end
	-- else
		-- bShowResultsToPlayer = true;
	-- end
-- Debug.console("manager_actions_adnd.lua","messageResult","bShowResultsToPlayer",bShowResultsToPlayer);
	
	-- if bShowResultsToPlayer then
		-- local nodeCT = ActorManager.getCTNode(rTarget);
		-- if nodeCT and CombatManager.isCTHidden(nodeCT) then
			-- rMessageGM.secret = true;
			-- Comm.deliverChatMessage(rMessageGM, "");
		-- else
			-- rMessageGM.secret = false;
			-- Comm.deliverChatMessage(rMessageGM);
		-- end
	-- else
		-- rMessageGM.secret = true;
		-- Comm.deliverChatMessage(rMessageGM, "");

		-- if User.isHost() then
			-- local aUsers = User.getActiveUsers();
			-- if #aUsers > 0 then
				-- Comm.deliverChatMessage(rMessagePlayer, aUsers);
			-- end
		-- else
			-- Comm.addChatMessage(rMessagePlayer);
		-- end
	-- end
-- end