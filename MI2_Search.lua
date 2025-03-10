--
-- MI2_Search.lua
--
-- MobInfo module to control the Mob database search feature.
-- Search option settings and actual search algorithm are located in here.
--

--
-- start up defaults for search options settings
MI2_SearchOptions = {}
MI2_SearchOptions.MinLevel = 1
MI2_SearchOptions.MaxLevel = 85
MI2_SearchOptions.Normal = true
MI2_SearchOptions.Elite = 0
MI2_SearchOptions.Boss = 0
MI2_SearchOptions.MinLoots = 0
MI2_SearchOptions.MaxLoots = 9999
MI2_SearchOptions.MobName = ""
MI2_SearchOptions.ItemName = ""
MI2_SearchOptions.CompactResult = 1
MI2_SearchOptions.ListMode = "Mobs"
MI2_SearchOptions.SortMode = "profit"

local MI2_SearchResultList = {}
MI2_ItemsIdxList = {}
MI2_SearchMode = 0
MI2_SearchCount = 0
MI2_NumMobsFound = 0


-----------------------------------------------------------------------------
-- MI2_SearchForItems()
--
-- Search for all items matching the item name entered in the search dialog.
-- Display the list of items in the result list control (if requested).
--
local function MI2_SearchForItems( itemName, enterItemsIntoList )
	MI2_ItemsIdxList = {}
	MI2_NumMobsFound = 0
	if enterItemsIntoList then
		MI2_SearchResultList = {}
	end
	
	if itemName ~= "" or enterItemsIntoList then
		local itemFound, itemText, itemColor
		itemName = string.lower(itemName)
		MI2_ItemsIdxList[0] = 1
		for idx in pairs(MI2_ItemNameTable) do
			itemFound = true
			itemText, itemColor = MI2_GetLootItem( idx )
			--local itemText = MI2_ItemNameTable[idx]
			if itemName ~= "*" then
				itemFound = string.find( string.lower(itemText), itemName ) ~= nil
			end
			if itemFound then
				if enterItemsIntoList then
					MI2_NumMobsFound = MI2_NumMobsFound + 1
					MI2_SearchResultList[MI2_NumMobsFound] = { idx = itemText, val = "", col = itemColor }
				else
					MI2_ItemsIdxList[idx] = 1
				end
			end
		end
	end
	
	MI2_DisplaySearchResult( "Items" )
end -- MI2_SearchForItems()


-----------------------------------------------------------------------------
-- MI2_UpdateSearchResultList()
--
-- Update contents of search result list according to current search options
-- settings. This includes starting a new search run, sorting the result and
-- displaying the result in the scrollable result list.
--
local function MI2_UpdateSearchResultList( updateItems )
	if updateItems then
		local enterItemsIntoList = MI2_SearchOptions.ListMode == "Items"
		MI2_SearchForItems( MI2_SearchOptions.ItemName, enterItemsIntoList )
	end
	if MI2_SearchOptions.ListMode == "Mobs" then
		-- (re)start search for entire mob database
		MI2_SearchCount = 0
		MI2_SearchMode = 1
		for mobIndex, mobInfo in pairs(MobInfoDB) do
			mobInfo.sf = true
		end
	
		-- initialise search result list  
		MI2_SearchResultList = {}
		MI2_NumMobsFound = 0

		-- search first 500 database recors right away
		MI2_SearchForMobs( 500 )
	end

	MI2_DisplaySearchResult( MI2_SearchOptions.ListMode )
end -- MI2_UpdateSearchResultList()


-----------------------------------------------------------------------------
-- MI2_SearchOptionsOnShow()
--
-- OnShow event handler for search options page
-- Write current search option settings into the search option controls.
-- Validate all values and update colors accordingly.
-- Allow Search only if all search options are valid.
--
function MI2_SearchOptionsOnShow()
	MI2_OptSearchMinLoots:SetMaxLetters( 4 )
	MI2_OptSearchMaxLoots:SetMaxLetters( 4 )
	MI2_OptSearchMinLoots:SetWidth( 36 )
	MI2_OptSearchMaxLoots:SetWidth( 36 )

	MI2_OptSearchMinLevel:SetText( tostring(MI2_SearchOptions.MinLevel) )
	MI2_OptSearchMaxLevel:SetText( tostring(MI2_SearchOptions.MaxLevel) )
	MI2_OptSearchMinLoots:SetText( tostring(MI2_SearchOptions.MinLoots) )
	MI2_OptSearchMaxLoots:SetText( tostring(MI2_SearchOptions.MaxLoots) )
	MI2_OptSearchMobName:SetText( MI2_SearchOptions.MobName )
	MI2_OptSearchItemName:SetText( MI2_SearchOptions.ItemName )

	if not MI2_SearchOptions.Normal or MI2_SearchOptions.Normal == 0 then
		MI2_OptSearchNormal:SetChecked( false )
	else
		MI2_OptSearchNormal:SetChecked( true )
	end
	if not MI2_SearchOptions.Elite or MI2_SearchOptions.Elite == 0 then
		MI2_OptSearchElite:SetChecked( false )
	else
		MI2_OptSearchElite:SetChecked( true )
	end
	if not MI2_SearchOptions.Boss or MI2_SearchOptions.Boss == 0 then
		MI2_OptSearchBoss:SetChecked( false )
	else
		MI2_OptSearchBoss:SetChecked( true )
	end

	MI2_UpdateSearchResultList()
end -- MI2_SearchOptionsOnShow()


-----------------------------------------------------------------------------
-- MI2_ValidateSearchOptions()
--
-- Validate all values and update colors accordingly.
-- Allow Search only if all search options are valid.
--
local function MI2_ValidateSearchOptions(self)
	if MI2_SearchOptions.MinLevel < 1 then
		MI2_SearchOptions.MinLevel = 1
		if self:GetText() == "0" then
			self:SetText( "1" )
		end
	end
	if MI2_SearchOptions.MaxLevel < 1 then
		MI2_SearchOptions.MaxLevel = 1
		if self:GetText() == "0" then
			self:SetText( "1" )
		end
	end
end -- MI2_ValidateSearchOptions()


-----------------------------------------------------------------------------
-- MI2_SearchCheckboxClicked()
--
-- OnClicked event handler for checkboxes on search options page
-- Store the checkbox state in the corresponding search options variable.
--
function MI2_SearchCheckboxClicked(self)
	local checkboxName = self:GetName()
	local optionName = string.sub( checkboxName, 14 )
	local optionValue = self:GetChecked() or 0

	MI2_SearchOptions[optionName] = optionValue
	MI2_UpdateSearchResultList()
end -- MI2_SearchCheckboxClicked()


-----------------------------------------------------------------------------
-- MI2_SearchValueChanged()
--
-- OnChar event handler for editbox controls on search options page
-- This handler is called whenever the contents of an EditBox control changes.
-- It gets the new value and stores it in the corresponding search options
-- variable
--
function MI2_SearchValueChanged(self)
	local editboxName = self:GetName()
	local optionName = string.sub( editboxName, 14 )
	local optionValue = tonumber(self:GetText()) or 0

	if MI2_SearchOptions[optionName] ~= optionValue then
		MI2_SearchOptions[optionName] = optionValue
		MI2_ValidateSearchOptions(self)
		MI2_UpdateSearchResultList()
	end
end -- MI2_SearchValueChanged()


-----------------------------------------------------------------------------
-- MI2_SearchTextChanged()
--
-- OnChar event handler for textual editbox controls on search options page
-- This handler is called whenever the contents of an EditBox control changes.
-- It gets the new value and stores it in the corresponding search options
-- variable
--
function MI2_SearchTextChanged(self)
	local editboxName = self:GetName()
	local optionName = string.sub( editboxName, 14 )

	if MI2_SearchOptions[optionName] ~= self:GetText() then
		MI2_SearchOptions[optionName] = self:GetText()
		MI2_UpdateSearchResultList( true )
	end
end -- MI2_SearchTextChanged()


-----------------------------------------------------------------------------
-- MI2_CalculateRank()
--
-- Calculate ranking and corresponding actual value for a given mob.
-- Ranking depends on search mode. For search mode "profit" ranking is
-- based on the mobs total profit value plus bonus points for rare loot
-- items. For search mode "itemCount" ranking is identical to the overall
-- items count for the loot items being searched for (in this mode
-- rank and value are identical).
--
local function MI2_CalculateRank( mobData, mobLevel, sortMode )
	local rank, value = 0, 0

	if sortMode == "profit" then
		-- calculate rank based on mob level and loot items quality
		local bonusFactor = mobLevel / 20
		if mobData.loots > 0 then
			value = (mobData.copper or 0) + (mobData.itemValue or 0)
			rank = value + ((mobData.r3 or 0) * 200 * bonusFactor) + ((mobData.r4 or 0) * 1000 * bonusFactor) + ((mobData.r5 or 0) * 2000 * bonusFactor)
			rank = ceil( rank / mobData.loots )
			value = copper2text( ceil(value / mobData.loots) )
		end
	elseif sortMode == "item" and mobData.itemList then
		for idx, val in pairs(mobData.itemList) do
			--local itemFound = string.find( MI2_ItemsIdxList, idx ) ~= nil
			--if itemFound then  rank = rank + val  end
			rank = rank + val
		end
		value = rank.."  "
	end

	return rank, value
end -- MI2_CalculateRank()


-----------------------------------------------------------------------------
-- MI2_CheckMob()
--
-- Check a given Mob against the current search criteria. Return the
-- mob data if the mob matches the criteria, or return nil if the Mob
-- does not match.
--
local function MI2_CheckMob( mobInfo, mobName, mobLevel )
	local levelOk, lootsOk, typeOk, itemsOK, mobData
	local nameOk = true

	-- check name and level of Mob
	if MI2_SearchOptions.MobName ~= "" then
		nameOk = string.find(string.lower(mobName),string.lower(MI2_SearchOptions.MobName),1,true) ~= nil
	end
	if nameOk and mobName ~= "" then
		levelOk = mobLevel >= MI2_SearchOptions.MinLevel and mobLevel <= MI2_SearchOptions.MaxLevel
		levelOk = levelOk or (mobLevel == -1)
	end

	-- check mob data related search conditions	
	if levelOk then
		mobData = {}
		MI2_DecodeBasicMobData( mobInfo, mobData )
		mobData.loots = mobData.loots or 0
		lootsOk = (mobData.loots >= MI2_SearchOptions.MinLoots) and (mobData.loots <= MI2_SearchOptions.MaxLoots)
		typeOk =   (MI2_SearchOptions.Normal == true and (mobData.mobType == 1 or mobData.mobType == 0 or not mobData.mobType))
				or (MI2_SearchOptions.Elite == true and mobData.mobType == 4)
				or (MI2_SearchOptions.Boss == true and mobData.mobType == 3)
		if lootsOk and typeOk then
			MI2_DecodeItemList( mobInfo, mobData )
			if MI2_ItemsIdxList[0] then
				if mobData.itemList then
					for idx, val in pairs(mobData.itemList) do
						itemsOK = MI2_ItemsIdxList[idx] ~= nil
						if itemsOK then break end
					end
				end
				if not itemsOK then mobData = nil end
			end
		else
			mobData = nil
		end
	end

	return mobData
end -- MI2_CheckMob()


-----------------------------------------------------------------------------
-- MI2_DisplaySearchResult()
--
-- Display the result of a search in the search results scrollable list.
-- The mobs to be displayed depend on the current list scroll position.
--
function MI2_DisplaySearchResult( resultType )
	-- update slider and get slider position
	FauxScrollFrame_Update( MI2_SearchResultSlider, MI2_NumMobsFound, 15, 14 );
	local sliderPos = FauxScrollFrame_GetOffset(MI2_SearchResultSlider)

	if resultType then
		MI2_TxtSearchCount:SetText( MI_SubWhite.."("..MI2_NumMobsFound.." "..resultType..")" )
	end

	-- update 15 search result lines with correct search result data
	local resultLine
	for i = 1, 15 do
		if 	(i + sliderPos) <= MI2_NumMobsFound then
			resultLine = _G[ "MI2_SearchResult"..i.."Index" ]
			resultLine:SetText( i + sliderPos )
			resultLine = _G[ "MI2_SearchResult"..i.."Value" ]
			resultLine:SetText( MI2_SearchResultList[i + sliderPos].val )
			resultLine = _G[ "MI2_SearchResult"..i.."Name" ]
			local mobName = MI2_SearchResultList[i + sliderPos].idx
			if MI2_SearchResultList[i + sliderPos].type then
				mobName = mobName.."+"
			elseif MI2_SearchResultList[i + sliderPos].col then
				mobName = MI2_SearchResultList[i + sliderPos].col..mobName
			end
			resultLine:SetText( mobName )
		else
			resultLine = _G[ "MI2_SearchResult"..i.."Index" ]
			resultLine:SetText( "" )
			resultLine = _G[ "MI2_SearchResult"..i.."Value" ]
			resultLine:SetText( "" )
			resultLine = _G[ "MI2_SearchResult"..i.."Name" ]
			resultLine:SetText( "" )
		end
	end
end  -- MI2_DisplaySearchResult()


-----------------------------------------------------------------------------
-- MI2_SlashAction_SortByValue()
--
-- Sort the search result list by mob profit
--
function MI2_SlashAction_SortByValue()
	MI2_SearchOptions.SortMode = "profit"
	MI2_UpdateSearchResultList()
end -- end of MI2_SlashAction_SortByValue()


-----------------------------------------------------------------------------
-- MI2_SlashAction_SortByItem()
--
-- Sort the search result list by mob item count
--
function MI2_SlashAction_SortByItem()
	MI2_SearchOptions.SortMode = "item"
	MI2_UpdateSearchResultList()
end -- end of MI2_SlashAction_SortByItem()


-----------------------------------------------------------------------------
-- MI2_SearchResult_Update()
--
-- Update contents of search results list based on current scroll bar
-- position. Update tooltip for selected mob if tooltip is visible.
--
function MI2_SearchResult_Update()
	FauxScrollFrame_Update( MI2_SearchResultSlider, MI2_NumMobsFound, 15, 14 );
	MI2_DisplaySearchResult()
end -- end of MI2_SearchResult_Update()


-----------------------------------------------------------------------------
-- MI2_ShowSearchResultTooltip()
--
-- Show mob tooltip for search result mob currently under mouse cursor.
--
function MI2_ShowSearchResultTooltip(self)
	local sliderPos = FauxScrollFrame_GetOffset(MI2_SearchResultSlider)
	local selection = tonumber(string.sub(self:GetName(), 17)) + sliderPos
	  
	if selection <= MI2_NumMobsFound then
		if MI2_SearchOptions.ListMode == "Mobs" then
			local index = MI2_SearchResultList[selection].idx
			local mobName, mobLevel = MI2_GetIndexComponents( index )
			-- create Mob data tooltip with full location info
			MI2_CreateTooltip( mobName, mobLevel, nil, true )
		elseif MI2_SearchOptions.ListMode == "Items" then
			GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
			local itemName = MI2_SearchResultList[selection].idx
			GameTooltip:SetText( MI2_SearchResultList[selection].col..itemName )
			MI2_BuildItemDataTooltip( itemName )
			GameTooltip:Show()
		end
	end
end  -- end of MI2_ShowSearchResultTooltip()


-----------------------------------------------------------------------------
-- MI2_HideSearchResultTooltip()
--
function MI2_HideSearchResultTooltip()
	MI2_HideTooltip()
end -- MI2_HideSearchResultTooltip()


-----------------------------------------------------------------------------
-- MI2_SearchTab_OnClick()
--
-- The "OnClick" event handler for the TAB buttons on the search result list.
-- These TAB buttons switch the list content between two modes: mob list
-- and item list
--
function MI2_SearchTab_OnClick(self)
	PanelTemplates_Tab_OnClick( self, MI2_SearchResultFrame )
	local selected = MI2_SearchResultFrame.selectedTab
	if selected == 1 then
		MI2_OptSortByValue:Enable()
		MI2_OptSortByItem:Enable()
		if MI2_NumMobsFound > 0 then
			MI2_OptDeleteSearch:Enable()
		else
			MI2_OptDeleteSearch:Disable()
		end
		MI2_SearchOptions.ListMode = "Mobs"
		MI2_UpdateSearchResultList( true )
	elseif selected == 2 then
		MI2_OptSortByValue:Disable()
		MI2_OptSortByItem:Disable()
		MI2_OptDeleteSearch:Disable()
		MI2_SearchOptions.ListMode = "Items"
		MI2_UpdateSearchResultList( true )
	end
end -- MI2_SearchTab_OnClick()


-----------------------------------------------------------------------------
-- MI2_SearchForMobs()
--
-- Search through a limited number of Mobs. Think function is meant to be
-- called repeatedly (in the background) to incrementally build the overall
-- search result list.
--
function MI2_SearchForMobs( searchLimit )
	local searchCount = 0
	for mobIndex, mobInfo in pairs(MobInfoDB) do
		if mobInfo.sf then
			searchCount = searchCount + 1
			MI2_SearchCount = MI2_SearchCount + 1
			mobInfo.sf = nil 
			mobName, mobLevel = MI2_GetIndexComponents( mobIndex )
			mobData = MI2_CheckMob( mobInfo, mobName, mobLevel )
			-- if mob is identified as belonging into the search result its
			-- search result sorting position is calculated based on a ranking
			-- value which in turn is based on the search mode
			if mobData then
				rank, value = MI2_CalculateRank( mobData, mobLevel, MI2_SearchOptions.SortMode )
				MI2_NumMobsFound = MI2_NumMobsFound + 1
				-- insert mob at correct sorted position and store all info we need for printing the result list
				MI2_SearchResultList[MI2_NumMobsFound] = { idx=mobIndex, val=value, rank=rank }
				if mobData.mobType and mobData.mobType > 1 then
					MI2_SearchResultList[MI2_NumMobsFound].type = mobData.mobType
				end
			end
		end
		if searchCount > searchLimit then
			return false
		end
	end
	return true
end -- MI2_SearchForMobs()


-----------------------------------------------------------------------------
-- MI2_SearchOnUpdate()
--
-- OnUpdate is called periodically (about 45 times per second) by the WoW
-- client.
--
function MI2_SearchOnUpdate( time )
	if MI2_SearchMode == 1 then
		local finished = MI2_SearchForMobs( 400 )
		if ( finished ) then
			MI2_SearchMode = 0
			if MI2_NumMobsFound > 1 then
				table.sort( MI2_SearchResultList, function(a,b) return (a.rank > b.rank) end  )
			end
			MI2_DisplaySearchResult( MI2_SearchOptions.ListMode )
		else
			MI2_TxtSearchCount:SetText( MI_SubWhite.."(searching..."..MI2_SearchCount..")" )
		end
	end
end

-----------------------------------------------------------------------------
-- MI2_DeleteSearchResultMobs()
--
-- Delete all Mobs in the search result list from the MobInfo database.
-- This function is called when the user confirms the delete.
--
function MI2_DeleteSearchResultMobs()
	for idx, val in pairs(MI2_SearchResultList) do
		local mobIndex = val.idx
		MI2_DeleteMobData( mobIndex, true )
	end
	chattext( "search result deleted : "..MI2_NumMobsFound.." Mobs" )
	MI2_UpdateSearchResultList()
end -- MI2_DeleteSearchResultMobs()


