-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

sortbytotals = false;

function setRows(n)
	if n < 0 then
		return;
	end

	local windows = getWindows();
	
	if #windows > n then
		-- Need to close some entries
		for i = n+1, #windows do
			windows[i].close();
		end
		return;
	end
	
	-- Otherwise, need to create some
	for i = 1, n - #windows do
		createWindow();
	end
end

function setDice(n)
	for _,w in ipairs(getWindows()) do
		w.setDice(n);
		w.updateTotal();
	end
end

function applyRoll(aDice)
	for _,w in ipairs(getWindows()) do
		if not w.isRolled() then
			w.applyRoll(aDice);
			return;
		end
	end
end

function updateTotals()
	for _,w in ipairs(getWindows()) do
		w.updateTotal();
	end
end

function updateModifiers()
	for _,w in ipairs(getWindows()) do
		w.modifier.setValue(window.modifier.getValue());
	end
end
