-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- The target value is a series of consecutive window lists or sub windows
local bVisibility = nil;
local nLevel = 1;
local aTargetPath = {};
local cTarget = nil;

function onInit()
	for sWord in string.gmatch(target[1], "([%w_]+)") do
		table.insert(aTargetPath, sWord);
	end
	if expand then
		bVisibility = true;
	elseif collapse then
		bVisibility = false;
	end
	if ctarget and ctarget[1] then
		cTarget = ctarget[1];
	end
	if togglelevel then
		nLevel = tonumber(togglelevel[1]) or 0;
		if nLevel < 1 then
			nLevel = 1;
		end
	end
end

function onButtonPress()
	applyTo(window[aTargetPath[1]], 1);
end

function applyTo(vTarget, nIndex)

	if nIndex > nLevel then
		vTarget.setVisible(bVisibility);
	end
	
	nIndex = nIndex + 1;
	if nIndex > #aTargetPath then
		return;
	end

	local sTargetType = type(vTarget);
	
	if sTargetType == "windowlist" then
		for _,wChild in pairs(vTarget.getWindows()) do
			applyTo(wChild[aTargetPath[nIndex]], nIndex);
			if cTarget and wChild[cTarget] then
				applyTo(wChild[cTarget], nIndex);
			end
		end
	elseif sTargetType == "subwindow" then
		applyTo(vTarget.subwindow[aTargetPath[nIndex]], nIndex);
	end
end
