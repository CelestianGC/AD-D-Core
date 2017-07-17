-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Set the displays to what should be shown
	setTargetingVisible();
	setAttributesVisible();
	setActiveVisible();
	setSpacingVisible();
	setEffectsVisible();

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	onLinkChanged();
	
	-- Update the displays
	onFactionChanged();
	onHealthChanged();
    	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
    
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("sheetlabel");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
	else
		name.setFont("sheettext");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Remember node name
	local sNode = node.getNodeName();
	
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	effects.reset(false);

	-- Move to the next actor, if this CT entry is active
	if DB.getValue(node, "active", 0) == 1 then
		CombatManager.nextActor();
	end

	-- Delete the database node and close the window
	node.delete();

	-- Update list information (global subsection toggles, targeting)
	windowlist.onVisibilityToggle();
	windowlist.onEntrySectionToggle();
end

function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	else
        --- NPC links.
        linkNPCFields();
    end
end

-- check here to add "RIP" token overlay? -celestian
function onHealthChanged()
	local sColor, nPercentWounded, sStatus = ActorManager2.getWoundColor("ct", getDatabaseNode());

	wounds.setColor(sColor);
	status.setValue(sStatus);

	local sClass,_ = link.getValue();
	if sClass ~= "charsheet" then
		idelete.setVisibility((nPercentWounded >= 1));
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		tokenvis.setVisible(false);
	else
		tokenvis.setVisible(true);
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function onActiveChanged()
	setActiveVisible();
end
function linkNPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
        name.setLink(nodeChar.createChild("name", "string"), true);
        
		-- hptotal.setLink(nodeChar.createChild("hptotal", "number"));
		-- hptemp.setLink(nodeChar.createChild("hptemp", "number"));
		-- wounds.setLink(nodeChar.createChild("wounds", "number"));

        --- stats
		strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
		dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
		constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
		intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
		wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
		charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

        --- saves
		paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
		poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
		death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
        rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
		staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
		wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
        petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
		polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
        breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
		spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);

        -- combat
		init.setLink(nodeChar.createChild("init", "number"), true);
		thaco.setLink(nodeChar.createChild("thaco", "number"), true);
		ac.setLink(nodeChar.createChild("ac", "number"), true);
		speed.setLink(nodeChar.createChild("speed", "number"), true);
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);

		hptotal.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));
		deathsavesuccess.setLink(nodeChar.createChild("hp.deathsavesuccess", "number"));
		deathsavefail.setLink(nodeChar.createChild("hp.deathsavefail", "number"));

		strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
		dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
		constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
		intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
		wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
		charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

		paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
		poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
		death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
		
        rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
		staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
		wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
		
        petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
		polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
		
        breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
		spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);


		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
		thaco.setLink(nodeChar.createChild("combat.thaco.score", "number"), true);
		ac.setLink(nodeChar.createChild("defenses.ac.total", "number"), true);
		speed.setLink(nodeChar.createChild("speed.total", "number"), true);
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible()
	local v = false;
	if activatetargeting.getValue() == 1 then
		v = true;
	end

	targetingicon.setVisible(v);
	
	sub_targeting.setVisible(v);
	
	frame_targeting.setVisible(v);

	target_summary.onTargetsChanged();
end

function setAttributesVisible()
	local v = false;
	if activateattributes.getValue() == 1 then
		v = true;
	end
	
	attributesicon.setVisible(v);

	strength.setVisible(v);
	strength_label.setVisible(v);
	dexterity.setVisible(v);
	dexterity_label.setVisible(v);
	constitution.setVisible(v);
	constitution_label.setVisible(v);
	intelligence.setVisible(v);
	intelligence_label.setVisible(v);
	wisdom.setVisible(v);
	wisdom_label.setVisible(v);
	charisma.setVisible(v);
	charisma_label.setVisible(v);

--	attr_save_division_label.setVisible(v);

	paralyzation.setVisible(v);
	paralyzation_label.setVisible(v);
	poison.setVisible(v);
	poison_label.setVisible(v);
	
    death.setVisible(v);
	death_label.setVisible(v);
    
    rod.setVisible(v);
	rod_label.setVisible(v);
    staff.setVisible(v);
	staff_label.setVisible(v);
    wand.setVisible(v);
	wand_label.setVisible(v);

    petrification.setVisible(v);
	petrification_label.setVisible(v);
    
    polymorph.setVisible(v);
	polymorph_label.setVisible(v);

    breath.setVisible(v);
	breath_label.setVisible(v);

    spell.setVisible(v);
	spell_label.setVisible(v);

	--spacer_attribute.setVisible(v);
	
	frame_attributes.setVisible(v);
end

function setActiveVisible()
	local v = false;
	if activateactive.getValue() == 1 then
		v = true;
	end

	local sClass, sRecord = link.getValue();
	local bNPC = (sClass ~= "charsheet");
	
	activeicon.setVisible(v);

	-- reaction.setVisible(v);
	-- reaction_label.setVisible(v);
	
    thaco.setVisible(v);
	thacolabel.setVisible(v);
    
	init.setVisible(v);
	initlabel.setVisible(v);
	ac.setVisible(v);
	aclabel.setVisible(v);
	speed.setVisible(v);
	speedlabel.setVisible(v);
	
	spacer_action.setVisible(v);
	
	if bNPC then
        damage.setVisible(v);
        damagelabel.setVisible(v);
        
        specialdefenselabel.setVisible(v);
        specialDefense.setVisible(v);
        specialattackslabel.setVisible(v);
        specialAttacks.setVisible(v);
        
        sub_actions.setVisible(v);
	else
        damage.setVisible(false);
        damagelabel.setVisible(false);

        specialdefenselabel.setVisible(false);
        specialDefense.setVisible(false);
        specialattackslabel.setVisible(false);
        specialAttacks.setVisible(false);

        sub_actions.setVisible(false);
	end

	spacer_action2.setVisible(v);
	
	frame_active.setVisible(v);
end

function setSpacingVisible(v)
	local v = false;
	if activatespacing.getValue() == 1 then
		v = true;
	end

    local bNPC = (sClass ~= "charsheet");
    
	spacingicon.setVisible(v);
	
	space.setVisible(v);
	spacelabel.setVisible(v);
	reach.setVisible(v);
	reachlabel.setVisible(v);

	hitDice.setVisible(v);
	hitDicelabel.setVisible(v);
	
	if (bNPC) then
--        level.setVisible(v);
--        levellabel.setVisible(v);
    end
    
	morale.setVisible(v);
	moralelabel.setVisible(v);

	frame_spacing.setVisible(v);
end

function setEffectsVisible(v)
	local v = false;
	if activateeffects.getValue() == 1 then
		v = true;
	end
	
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	effects_iadd.setVisible(v);
	for _,w in pairs(effects.getWindows()) do
		w.idelete.setValue(0);
	end
	
	frame_effects.setVisible(v);

	effect_summary.onEffectsChanged();
end

