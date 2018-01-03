--
--
--
--
--


function performExport()
    aProperties = {};
	aProperties.name = name.getValue();
	aProperties.namecompact = string.lower(string.gsub(aProperties.name, "%W", ""));
	aProperties.category = category.getValue();
	aProperties.file = file.getValue();
	aProperties.author = author.getValue();
	aProperties.thumbnail = thumbnail.getValue();
	if readonly.getValue() == 1 then
		aProperties.readonly = true;
	end
	aProperties.playervisible = (playervisible.getValue() == 1);

    
    local dStoryRaw = DB.getChildren("encounter");
Debug.console("author.lua","performExport","------>dStoryRaw",dStoryRaw);
    --local dCategoriesRaw = DB.getChildCategories(dStoryRaw,true);
--Debug.console("author.lua","performExport","------>dCategoriesRaw",dCategoriesRaw);
    local dRoot = DB.createChild("_authorRefmanual_tmp");
    local dStories = DB.createChild(dRoot,"stories");
    local dStoryCategories = DB.createChild(dStories,"category");
    
    for _,node in pairs(dStoryRaw) do
        local sCategory = UtilityManager.getNodeCategory(node);
        local dCategory = DB.getChild(dStoryCategories,sCategory);
        if (dCategory == nil) then
            dCategory = DB.createChild(dStoryCategories,sCategory);
            DB.setValue(dCategory,"name","string",sCategory);
        end
        local nodeEntry = dCategory.createChild();
        DB.copyNode(node,nodeEntry);
Debug.console("author.lua","performExport","sCategory",sCategory);
Debug.console("author.lua","performExport","dCategory",dCategory);
Debug.console("author.lua","performExport","nodeEntry",nodeEntry);
Debug.console("author.lua","performExport","node",node);
    end

    -- create root "author" node to drop entries
    local dAuthorNode = DB.createChild("_authorRefmanual");

    -- library section
    local dLibrary = DB.createChild(dAuthorNode,"library");
    local nodeLibrary = DB.createChild(dLibrary,"adnd_refmanual_library");
    DB.setValue(nodeLibrary,"categoryname","string",aProperties.category);
    DB.setValue(nodeLibrary,"name","string","Name-Ref-Manual-PlaceHolder-Text");
    local nodeLibraryEntries =  DB.createChild(nodeLibrary,"entries");
    --local nodeLibraryEntry =  DB.createChild(nodeLibraryEntries,"ref_00001");
    local nodeLibraryEntry =  DB.createChild(nodeLibraryEntries);
    DB.setValue(nodeLibraryEntry,"name","string",aProperties.name);
    local sLinkClass = "reference_manual";
    local sLinkRecord = "reference.refmanualindex";
    DB.setValue(nodeLibraryEntry,"librarylink","windowreference",sLinkClass,sLinkRecord);
    
	-- Loop through selected export record categories
	for _, cw in ipairs(list.getWindows()) do
        local bAuthorRecord = (cw.all.getValue() == 1);
        local aExportSources = cw.getSources();
        local aExportTargets = cw.getTargets();
        if (bAuthorRecord) then
            for kSource,vSource in ipairs(aExportSources) do
                local nodeSource = DB.findNode(vSource);
                if nodeSource then
                    -- create node matching node we're copying to manual
                    local dAuthorRecord = DB.createChild(dAuthorNode,vSource);  
                    -- create library link to list all these items
                    local nodeLibraryAdditional =  DB.createChild(nodeLibraryEntries);                    
                    DB.setValue(nodeLibraryAdditional,"name","string",vSource);
                    DB.setValue(nodeLibraryAdditional,"source","string",vSource);
                    DB.setValue(nodeLibraryAdditional,"recordtype","string",vSource);
                    local sClass = "reference_list";
                    local sRecord = "..";
                    DB.setValue(nodeLibraryAdditional,"librarylink","windowreference",sClass,sRecord);
					for _,nodeChild in pairs(nodeSource.getChildren()) do
                        if nodeChild.getType() == "node" then
                            local nodeAuthor = dAuthorRecord.createChild();
                            DB.copyNode(nodeChild,nodeAuthor);
                        end
                    end
                end
            end
        end
    end

    -- reference section
    local dReference = DB.createChild(dAuthorNode,"reference");
    local nodeRefIndex = DB.createChild(dReference,"refmanualindex");
    local nodeChapters = DB.createChild(nodeRefIndex,"chapters");
    --local nodeChapter = DB.createChild(nodeChapters,"chapter");
    local nodeChapter = DB.createChild(nodeChapters);
    DB.setValue(nodeChapter,"name","string",aProperties.name);
    local nodeSubChapters = DB.createChild(nodeChapter,"subchapters");
    -- flip through all categories, create sub per category and and entries within category
    for _,nodeCategory in pairs(dStoryCategories.getChildren()) do
        -- create subchapter node and set name
        --local nodeSubChapter = DB.createChild(nodeSubChapters,"sub_chapter");
        local nodeSubChapter = DB.createChild(nodeSubChapters);
        DB.setValue(nodeSubChapter,"name","string",DB.getValue(nodeCategory,"name","EMPTY-CATEGORY-NAME"));
        for _,nodeStory in pairs(nodeCategory.getChildren()) do
            -- create refpages node and current node to work on and set name/links
            local dRefPages = DB.createChild(nodeSubChapter,"refpages");
            --local nodeRefPage = DB.createChild(dRefPages,"refpage");
            local nodeRefPage = DB.createChild(dRefPages);
            DB.setValue(nodeRefPage,"name","string",DB.getValue(nodeStory,"name","EMPTY-STORY-NAME"));
            DB.setValue(nodeRefPage,"keywords","string",DB.getValue(nodeStory,"name","EMPTY-STORY-NAME"));
            local sLinkClass = "reference_manualtextwide";
            local sLinkRecord = "..";
            DB.setValue(nodeRefPage,"listlink","windowreference",sLinkClass,sLinkRecord);
            -- create block node and set text from story
            local dBlocks = DB.createChild(nodeRefPage,"blocks");
            --local nodeBlock = DB.createChild(dBlocks,"block");
            local nodeBlock = DB.createChild(dBlocks);
            DB.setValue(nodeBlock,"text","formattedtext",DB.getValue(nodeStory,"text","EMPTY-STORY-TEXT"));
        end
    end

    
    -- remove temporary category sorting nodes
    DB.deleteNode(dRoot);
    
	local sFormat = Interface.getString("author_completed");
	local sMsg = string.format(sFormat, aProperties.name,dAuthorNode.getPath());
	ChatManager.SystemMessage(sMsg);
    file.setFocus(true);
end