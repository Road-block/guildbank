
function guildbank_onload()

	SLASH_GUILDBANK1 = "/gbank";
	SLASH_GUILDBANK2 = "/guildbank";
	SlashCmdList["GUILDBANK"] = guildbank_show;
	DEFAULT_CHAT_FRAME:AddMessage(GUILDBANK_LOADED_TEXT);
	
	

end

local function splitLink(itemlink)
	if (type(itemlink) ~= 'string') then return end
	local i,j, itemID, enchant, randomProp, uniqID, name = string.find(itemlink, "|Hitem:(%d+):(%d+):(%d+):(%d+)|h[[]([^]]+)[]]|h")
	return tonumber(itemID or 0), tonumber(randomProp or 0), tonumber(enchant or 0), tonumber(uniqID or 0), name
end

local function extractItemName(itemlink)
	local linkstart = string.find(itemlink, "|H");
	local linkend = string.find(itemlink, "|", linkstart+2);
	local stripped = string.sub(itemlink, linkstart+2, linkend-1)

	return GetItemInfo(stripped);
end

function guildbank_show()
	guildbankForm:Show();
	guildbankFormeditbox:Hide();
	guildbankFormLabel1:Hide();

end

function guildbank_updateCount(itemCounts, itemcount, itemNames, itemname)

	if (itemCounts[itemname]) then 
		--- increase count for existing item
		itemCounts[itemname] = itemCounts[itemname] + itemcount;
	else
		--- add new item
		itemCounts[itemname] = itemcount;
		table.insert(itemNames, itemname);
	end

	return itemCounts;
end


function guildbank_getInventory()

	local itemCounts = {};
	local itemNames = {[0] = {}; [1] = {}; [2] = {}; [3] = {}; [4] = {}; [5] = {}; [6] = {}};
	local itemname;
	local itemcount;
	local quality;
	local returnstring = "";
	local itemID = 0;
	local name = "";
	local _;
	
	local bag;
	returnstring = returnstring .. "\n\[b\]"..GUILDBANK_INVENTORY_TEXT.."\[/b\]\n\[list\]";
	for bag = 0, 4 do 
		if (GetBagName(bag)) then
		
			local slotcount = GetContainerNumSlots(bag);
			local slot;		
			for slot = 1, slotcount do 
				if (GetContainerItemLink(bag,slot)) then
					itemID, _, _, _, name = splitLink(GetContainerItemLink(bag,slot));
					itemname = "[url="..GUILDBANK_WEBLINK_TEXT..tostring(itemID).."]"..name.."[/url]";
					_, itemcount, _, quality = GetContainerItemInfo(bag, slot);
					
					if (quality == -1) then 
						quality = 1; 
					end	
					itemCounts = guildbank_updateCount(itemCounts, itemcount, itemNames[quality], itemname);		
				end	
			end		
		end	
	end
	
	for i = 6, 0, -1 do 
		table.sort(itemNames[i]);
		
		for index in itemNames[i] do
			local name = itemNames[i][index]
			local count = itemCounts[name];
			returnstring = returnstring .."\[*\]" .. count .. "x" .. name .. "\n";
		end
	end

	returnstring = returnstring .. "\[/list\]\n";
	return returnstring;

end

function guildbank_getEquipment()

	local items = {};
	local inventoryID;
	local itemname = "";
	local itemID = 0;
	local name = "";
	local _;
	local returnstring = "\n\[b\]"..GUILDBANK_EQUIPMENT_TEXT.."\[/b\]\n\[list\]";
	for inventoryID = 0, 19 do if (GetInventoryItemLink("player", inventoryID)) then
		itemID, _, _, _, name = splitLink(GetInventoryItemLink("player", inventoryID));
		itemname = "[url="..GUILDBANK_WEBLINK_TEXT..tostring(itemID).."]"..name.."[/url]";
		table.insert(items, itemname);
	end end
	
	for index in items do
		returnstring = returnstring .."\[*\]" .. items[index] .. "\n";
	end
	
	returnstring = returnstring .. "\[/list\]\n";
	return returnstring;

end

function guildbank_getBank()

	local itemCounts = {};
	local itemNames = {[0] = {}; [1] = {}; [2] = {}; [3] = {}; [4] = {}; [5] = {}; [6] = {}};

	local itemname;
	local itemcount;
	local quality;
	
	local itemID = 0;
	local name = "";
	local _;
	
	local bankslotID;
	local returnstring = "\n\[b\]"..GUILDBANK_BANK_TEXT.."\[/b\]\n\[list\]";
	for bankslotID = 1, 24 do 
		if (GetContainerItemLink(BANK_CONTAINER, bankslotID)) then
			itemID, _, _, _, name = splitLink(GetContainerItemLink(BANK_CONTAINER, bankslotID));
			itemname = "[url="..GUILDBANK_WEBLINK_TEXT..tostring(itemID).."]"..name.."[/url]";
			_, itemcount, _, quality = GetContainerItemInfo(BANK_CONTAINER, bankslotID);
				
			if (quality == -1) then 
				quality = 1; 
			end		
			itemCounts = guildbank_updateCount(itemCounts, itemcount, itemNames[quality], itemname);
		end 
	end
	
	local bag;
	for bag = 5, 10 do 
		if (GetBagName(bag)) then
			local slotcount = GetContainerNumSlots(bag);
			local slot;
			for slot = 1,slotcount do 
				if (GetContainerItemLink(bag,slot)) then
					itemID, _, _, _, name = splitLink(GetContainerItemLink(bag,slot));
					itemname = "[url="..GUILDBANK_WEBLINK_TEXT..tostring(itemID).."]"..name.."[/url]";
					_, itemcount, _, quality = GetContainerItemInfo(bag, slot);
					if (quality == -1) then 
						quality = 1; 
					end			
					itemCounts = guildbank_updateCount(itemCounts, itemcount, itemNames[quality], itemname);
				end	
			end
		end	
	end	
	
	for i = 6, 0, -1 do 
		table.sort(itemNames[i]);
		
		for index in itemNames[i] do
			local name = itemNames[i][index]
			local count = itemCounts[name];
			returnstring = returnstring .."\[*\]" .. count .. "x" .. name .. "\n";
		end
	end

	returnstring = returnstring .. "\[/list\]\n";
	return returnstring;

end

function guildbank_getGold()

	local g = floor(GetMoney() / 10000);
	local s = floor((GetMoney() - g * 10000) / 100);
	local c = GetMoney() - g * 10000 - s * 100;

	return "\n\[b\]"..GUILDBANK_MONEY_TEXT.."\[/b\]: " .. g .. "g " .. s .. "s " .. c .. "c\n";
	
end



function guildbank_readyToCopy(returnstring)
	guildbankFormeditbox:Show();
	guildbankFormeditbox:SetText(returnstring);
	guildbankFormeditbox:HighlightText();
	guildbankFormLabel1:Show();

end

function guildbank_gatherData()
	local equipString = "";
	local inventoryString = "";
	local bankString = "";
	local goldString = "";

	if (guildbankFormCheckGold:GetChecked()) then
		goldString = guildbank_getGold();
	end


	if (guildbankFormCheckButton2:GetChecked()) then
		equipString = guildbank_getEquipment();
	end
	
	if (guildbankFormCheckButton1:GetChecked()) then
		inventoryString = guildbank_getInventory();
	end

	if (guildbankFormCheckButton3:GetChecked()) then
		bankString = guildbank_getBank();
	end

	guildbank_readyToCopy(goldString .. equipString .. inventoryString .. bankString);

end