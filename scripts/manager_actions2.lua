-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function encodeDesktopMods(rRoll)
	local nMod = 0;
	
	if ModifierStack.getModifierKey("PLUS1") then
		nMod = nMod + 1;
	end
	if ModifierStack.getModifierKey("PLUS2") then
		nMod = nMod + 2;
	end
	if ModifierStack.getModifierKey("PLUS3") then
		nMod = nMod + 3;
	end
	if ModifierStack.getModifierKey("PLUS4") then
		nMod = nMod + 4;
	end
	if ModifierStack.getModifierKey("PLUS5") then
		nMod = nMod + 5;
	end

	if ModifierStack.getModifierKey("MINUS1") then
		nMod = nMod - 1;
	end
	if ModifierStack.getModifierKey("MINUS2") then
		nMod = nMod - 2;
	end
	if ModifierStack.getModifierKey("MINUS3") then
		nMod = nMod - 3;
	end
	if ModifierStack.getModifierKey("MINUS4") then
		nMod = nMod - 4;
	end
	if ModifierStack.getModifierKey("MINUS5") then
		nMod = nMod - 5;
	end
	
	if nMod == 0 then
		return;
	end
	
	rRoll.nMod = rRoll.nMod + nMod;
	rRoll.sDesc = rRoll.sDesc .. string.format(" [%+d]", nMod);
end

function encodeAdvantage(rRoll, bADV, bDIS)
	local bButtonADV = ModifierStack.getModifierKey("ADV");
	local bButtonDIS = ModifierStack.getModifierKey("DIS");
	if bButtonADV then
		bADV = true;
	end
	if bButtonDIS then
		bDIS = true;
	end
	
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	if (bADV and not bDIS) or (bDIS and not bADV) then
		table.insert(rRoll.aDice, 2, "d20");
	end
end

function decodeAdvantage(rRoll)
	local bADV = string.match(rRoll.sDesc, "%[ADV%]");
	local bDIS = string.match(rRoll.sDesc, "%[DIS%]");
	if (bADV and not bDIS) or (bDIS and not bADV) then
		if #(rRoll.aDice) > 0 then
			local nDecodeDie;
			if (bADV and not bDIS) then
				nDecodeDie = math.max(rRoll.aDice[1].result, rRoll.aDice[2].result);
				rRoll.aDice[1].type = "g" .. string.sub(rRoll.aDice[1].type, 2);
			else
				nDecodeDie = math.min(rRoll.aDice[1].result, rRoll.aDice[2].result);
				rRoll.aDice[1].type = "r" .. string.sub(rRoll.aDice[1].type, 2);
			end
			rRoll.aDice[1].result = nDecodeDie;
			table.remove(rRoll.aDice, 2);
		end
	end	
end
