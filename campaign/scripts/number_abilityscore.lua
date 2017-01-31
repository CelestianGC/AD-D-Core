-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- super.onInit();
	onValueChanged();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function onValueChanged()
    if self then
        local sTarget = string.lower(self.target[1]);
        local nChanged = getValue();
            
        print ("number_abilityscore.lua: onValueChanged :" .. sTarget);
        print ("number_abilityscore.lua: onValueChanged Value=" .. nChanged);

        local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
        local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
        if sActorType == "pc" and (nChanged >= 1) and (nChanged <= 25) then
            if (sTarget == "strength") then
                updateStrength(nodeActor,nChanged);
            elseif (sTarget == "dexterity") then
                updateDexterity(nodeActor,nChanged);
            elseif (sTarget == "wisdom") then
                updateWisdom(nodeActor,nChanged);
            elseif (sTarget == "constitution") then
                updateConstitution(nodeActor,nChanged);
            elseif (sTarget == "charisma") then
                updateCharisma(nodeActor,nChanged);
            elseif (sTarget == "intelligence") then
                updateIntelligence(nodeActor,nChanged);
            end
        end -- was PC

    end
end

function action(draginfo)
	local rActor = ActorManager.getActor("", window.getDatabaseNode());
	ActionCheck.performRoll(draginfo, rActor, self.target[1]);
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

function updateStrength(nodeActor,nChanged)
    -- aStrength[abilityScore]={hit prob, dam adj, weight allow, max press, open doors, bend bars}
    local aStrength = {};
    aStrength[1]  = {-5,-4,1,3,"1",0};
    aStrength[2]  = {-3,-2,1,5,"1",0};
    aStrength[3]  = {-3,-1,5,10,"2",0};
    aStrength[4]  = {-2,-1,10,25,"3",0};
    aStrength[5]  = {-2,-1,10,25,"3",0};
    aStrength[6]  = {-1,0,20,55,"4",0};
    aStrength[7]  = {-1,0,20,55,"4",0};
    aStrength[8]  = {0,0,35,90,"5",1};
    aStrength[9]  = {0,0,35,90,"5",1};
    aStrength[10] = {0,0,40,115,"6",2};
    aStrength[11] = {0,0,40,115,"6",2};
    aStrength[12] = {0,0,45,140,"7",4};
    aStrength[13] = {0,0,45,140,"7",4};
    aStrength[14] = {0,0,55,170,"8",7};
    aStrength[15] = {0,0,55,170,"8",7};
    aStrength[16] = {0,1,70,195,"9",10};
    aStrength[17] = {1,1,85,220,"10",13};
    aStrength[18] = {1,2,110,255,"11",16};
    aStrength[19] = {3,7,485,640,"16(8)",50};
    aStrength[20] = {3,8,535,700,"17(10)",60};
    aStrength[21] = {4,9,635,810,"17(12)",70};
    aStrength[22] = {4,10,785,970,"18(14)",80};
    aStrength[23] = {5,11,935,1130,"18(16)",90};
    aStrength[24] = {6,12,1235,1440,"19(17)",95};
    aStrength[25] = {7,14,1535,1750,"19(18)",99};

    -- Deal with 18 01-100 strength
    aStrength[50] = {1,3,135,280,"12",20};
    aStrength[75] = {2,3,160,305,"13",25};
    aStrength[90] = {2,4,185,330,"14",30};
    aStrength[99] = {2,5,235,380,"15(3)",35};
    aStrength[100] ={3,6,335,480,"16(6)",40};

    nPercent = DB.getValue(nodeActor, "abilities.strength.percent", 0);

    -- Deal with 18 01-100 strength
    if ((nChanged == 18) and (nPercent > 0)) then
        local nPercentRank = 50;
        if (nPercent == 100) then 
            nPercentRank = 100
        elseif (nPercent >= 91 and nPercent <= 99) then
            nPercentRank = 99
        elseif (nPercent >= 76 and nPercent <= 90) then
            nPercentRank = 90
        elseif (nPercent >= 51 and nPercent <= 75) then
            nPercentRank = 75
        elseif (nPercent >= 1 and nPercent <= 50) then
            nPercentRank = 50
        end
        nChanged = nPercentRank;
    end
    
    DB.setValue(nodeActor, "abilities.strength.hitadj", "number", aStrength[nChanged][1]);
    DB.setValue(nodeActor, "abilities.strength.dmgadj", "number", aStrength[nChanged][2]);
    DB.setValue(nodeActor, "abilities.strength.weightallow", "number", aStrength[nChanged][3]);
    DB.setValue(nodeActor, "abilities.strength.maxpress", "number", aStrength[nChanged][4]);
    DB.setValue(nodeActor, "abilities.strength.opendoors", "string", aStrength[nChanged][5]);
    DB.setValue(nodeActor, "abilities.strength.bendbars", "number", aStrength[nChanged][6]);
end

function updateDexterity(nodeActor,nChanged)
    local aDexterity = {};
end

function updateWisdom(nodeActor,nChanged)
    local aWisdom = {};
end

function updateConstitution(nodeActor,nChanged)
    local aConstitution = {};
end

function updateCharisma(nodeActor,nChanged)
    local aCharisma = {};
end

function updateIntelligence(nodeActor,nChanged)
    local aIntelligence = {};
end
