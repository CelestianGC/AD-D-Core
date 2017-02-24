-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if (super) then
		super.onInit();
	end
	onValueChanged();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function onValueChanged()
    --Debug.console("number_savescore.lua", "onValueChanged");
    
	-- local nMod = math.floor((getValue() - 10) / 2);
	
	-- local bonusctrl = window[self.target[1] .. "_bonus"];
	-- if bonusctrl then
		-- bonusctrl.setValue(nMod);
	-- end
	
	-- local modctrl = window[self.target[1] .. "_modtext"];
	-- if modctrl then
		-- modctrl.setValue(string.format("%+d", nMod));
	-- end

    -- initial work on saves for npcs from HD -msw
    -- if self then
        -- local sTarget = string.lower(self.target[1]);
        -- local nChanged = getValue();

        -- local rActor = ActorManager.getActor("", window.getDatabaseNode());
        -- if (rActor) then
            -- local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
            -- -- if score < 0 (npc, moved to CT) then we set scores based on HD
            -- if ((sActorType == "ct") and (nChanged <= 0)) then
               -- ActionSave.setNPCSave(rActor, sTarget);
            -- end -- was PC
        -- end -- was rActor
    -- end -- was self
    
end

function action(draginfo)
	local rActor = ActorManager.getActor("", window.getDatabaseNode());
	ActionSave.performRoll(draginfo, rActor, self.target[1]);
	return true;
end

function onDragStart(button, x, y, draginfo)
	if rollable then
		return action(draginfo);
	end
end
	
function onDoubleClick(x, y)
	if rollable then
		return action();
	end
end
