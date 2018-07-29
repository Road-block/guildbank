guildbank = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
local D = AceLibrary("Deformat-2.0")
local T  = AceLibrary("Tablet-2.0")
local gratuity = AceLibrary("Gratuity-2.0")
local L = AceLibrary("AceLocale-2.2"):new("guildbank")

guildbank._class, guildbank._eClass = UnitClass("player")
guildbank._pName = (UnitName("player"))
guildbank._bags = {}
guildbank.Bags = {}
guildbank._bank = {}
guildbank.Bank = {}
guildbank._mail = {}
guildbank.Mail = {}

local links = {
  ["1"] = {label="Classic|cff5BC0DEDB|r",           prefix="https://classicdb.ch/?item=%s"},
  ["2"] = {label="|cffFFCF40T|rwin|cffFFCF40H|read",prefix="https://vanilla-twinhead.twinstar.cz/?item=%s"},
  ["3"] = {label="|cffFFA700DKPMinus|r",            prefix="https://www.dkpminus.com/vanilla-wow-database/?item=%s"},
}
local defaults = {
  Bags  = true,
  Bank  = true,
  Mail  = false,
  Money = false,
  Link  = "1",
}
local options = {
  type = "group",
  handler = guildbank,
  args = {
    Bags = {
      name = L["Bags"],
      desc = L["Include Bags"],
      type = "toggle",
      get  = "GetBagsOption",
      set  = "SetBagsOption",
      order = 2,
    },
    Bank = {
      name = L["Bank"],
      desc = L["Include Bank"],
      type = "toggle",
      get  = "GetBankOption",
      set  = "SetBankOption",
      order = 3,
    },
    Mail = {
      name = L["Mail"],
      desc = L["Include Mail"],
      type = "toggle",
      get  = "GetMailOption",
      set  = "SetMailOption",
      order = 4,
    },
    Money = {
      name = L["Money"],
      desc = L["Include Money"],
      type = "toggle",
      get  = "GetMoneyOption",
      set  = "SetMoneyOption",
      order = 5,
    },
    Link = {
      name = L["Link"],
      desc = L["Online Database"],
      type = "text",
      usage = "<site>",
      get  = "GetLinkOption",
      set  = "SetLinkOption",
      order = 6,
      validate = {["1"] = links["1"].label, ["2"] = links["2"].label, ["3"] = links["3"].label},
    },
    Export = {
      name = L["Export"],
      desc = L["Export items to bbcode list"],
      type = "execute",
      func = "ExportShow",
      order = 1,
    },
  }
}
local locations = {
  Bags = L["Bags"],
  Bank = L["Bank"],
  Mail = L["Mail"],
  Money = L["Money"],
}
local itemevents = {
  "BANKFRAME_OPENED",
  "MAIL_SHOW",
}
local bucketevents = {
  "MAIL_INBOX_UPDATE",
  "BAG_UPDATE",
}
guildbank.item_bind_patterns = {
  CRAFT = "("..ITEM_SPELL_TRIGGER_ONUSE..")",
  BOP1 = "("..ITEM_BIND_ON_PICKUP..")",
  BOP2 = "("..ITEM_SOULBOUND..")",
  QUEST = "("..ITEM_BIND_QUEST..")",
  BOU = "("..ITEM_BIND_ON_EQUIP..")",
  BOE = "("..ITEM_BIND_ON_USE..")"
}
guildbank.hexColorQuality = {}
for i=-1,6 do
  guildbank.hexColorQuality[ITEM_QUALITY_COLORS[i].hex] = i
end

---------
-- FuBar
---------
guildbank.hasIcon = [[Interface\GossipFrame\BankerGossipIcon]]
guildbank.title = L["GuildBank"]
guildbank.defaultMinimapPosition = 250
guildbank.defaultPosition = "RIGHT"
guildbank.cannotDetachTooltip = true
guildbank.tooltipHiddenWhenEmpty = false
guildbank.hideWithoutStandby = true
guildbank.independentProfile = true

function guildbank:OnTooltipUpdate()
  local bagupdate = self._lastBags and string.format("%s - %s\n",L["Bags"],self._lastBags) or ""
  local bankupdate = self._lastBank and string.format("%s - %s\n",L["Bank"],self._lastBank) or ""
  local mailupdate = self._lastMail and string.format("%s - %s\n",L["Mail"],self._lastMail) or ""
  local moneyupdate = self._lastMoney and string.format("%s - %s\n",L["Money"],self._lastMoney) or ""
  local updatestring = string.format("%s%s%s%s",bagupdate,bankupdate,mailupdate,moneyupdate)
  if updatestring ~= "" then updatestring = string.format("\n%s",updatestring) end
  local hint = string.format(L["%s\n|cffFFA500Click:|r Show Export|r\n|cffFFA500Right-Click:|r Options"],updatestring)
  T:SetHint(hint)
end

function guildbank:OnTextUpdate()
  self:SetText(L["GuildBank"])
end

function guildbank:OnClick()
  self:ExportShow()
end

function guildbank:make_escable(framename,operation)
  local found
  for i in UISpecialFrames do
    if UISpecialFrames[i]==framename then
      found = i
    end
  end
  if not found and operation=="add" then
    table.insert(UISpecialFrames,framename)
  elseif found and operation=="remove" then
    table.remove(UISpecialFrames,found)
  end
end

local guildbank_export = CreateFrame("FRAME","guildbank_exportbase",UIParent)
guildbank_export:SetWidth(460)
guildbank_export:SetHeight(31)
guildbank_export:SetPoint('TOP', UIParent, 'TOP', 0,-80)
guildbank_export:EnableMouse(1)
guildbank_export:SetMovable(1)
guildbank_export:SetBackdrop({
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 5, right = 3, top = 3, bottom = 5 }
  })
guildbank_export:Hide()
guildbank_export:SetScript("OnShow", function()
  this.container.edit:SetFocus()
  end)
guildbank:make_escable(guildbank_export, "add")
guildbank_export:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
guildbank_export:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)

guildbank_export.titleregion = guildbank_export:CreateTitleRegion(guildbank_export)
guildbank_export.titleregion:SetAllPoints(guildbank_export)

guildbank_export.title = guildbank_export:CreateFontString(nil,"ARTWORK","GameFontHighlight")
guildbank_export.title:SetJustifyH("CENTER")
guildbank_export.title:SetJustifyV("CENTER")
guildbank_export.title:SetTextColor(GREEN_FONT_COLOR.r,GREEN_FONT_COLOR.g,GREEN_FONT_COLOR.b)
guildbank_export.title:SetText(L["Ctrl+C to copy, Ctrl+V on Forum. Esc to close"])
guildbank_export.title:SetPoint("TOP",guildbank_export,"TOP",0,-8)

guildbank_export.close = CreateFrame("BUTTON","guildbank_exportclose",guildbank_export,"UIPanelCloseButton")
guildbank_export.close:SetPoint("TOPRIGHT",guildbank_export,"TOPRIGHT")

guildbank_export.container = CreateFrame("Frame", "guildbank_exportframe", guildbank_export)
guildbank_export.container:SetWidth(460)
guildbank_export.container:SetHeight(400)
guildbank_export.container:SetPoint('TOPLEFT', guildbank_export, 'BOTTOMLEFT')
guildbank_export.container:SetFrameStrata('DIALOG')
guildbank_export.container:SetBackdrop({
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
  tile = true, tileSize = 16, edgeSize = 16,
  insets = {left = 5, right = 3, top = 3, bottom = 5}
  })
guildbank_export.container:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
guildbank_export.container:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
guildbank_export.container.edit = CreateFrame("EditBox", "guildbank_exportedit", guildbank_export.container)
guildbank_export.container.edit:SetMultiLine(true)
guildbank_export.container.edit:SetAutoFocus(true)
guildbank_export.container.edit:EnableMouse(true)
guildbank_export.container.edit:SetMaxLetters(0)
guildbank_export.container.edit:SetHistoryLines(1)
guildbank_export.container.edit:SetFont('Fonts\\ARIALN.ttf', 12, 'THINOUTLINE')
guildbank_export.container.edit:SetWidth(500)
guildbank_export.container.edit:SetHeight(768)
guildbank_export.container.edit:SetScript("OnEscapePressed", function() 
    guildbank_export.container.edit:SetText("")
    guildbank_export:Hide() 
  end)
guildbank_export.container.edit:SetScript("OnEditFocusGained", function()
  guildbank_export.container.edit:HighlightText()
end)
guildbank_export.container.edit:SetScript("OnCursorChanged", function() 
  guildbank_export.container.edit:HighlightText()
end)
guildbank_export.AddSelectText = function(txt)
  guildbank_export.container.edit:SetText(txt)
  guildbank_export.container.edit:HighlightText()
end
guildbank_export.container.scroll = CreateFrame("ScrollFrame", "guildbank_exportscroll", guildbank_export.container, 'UIPanelScrollFrameTemplate')
guildbank_export.container.scroll:SetPoint('TOPLEFT', guildbank_export.container, 'TOPLEFT', 8, -30)
guildbank_export.container.scroll:SetPoint('BOTTOMRIGHT', guildbank_export.container, 'BOTTOMRIGHT', -30, 8)
guildbank_export.container.scroll:SetScrollChild(guildbank_export.container.edit)

function guildbank:itemBinding(item)
  gratuity:SetHyperlink(item)
  if gratuity:Find(self.item_bind_patterns.BOP1,2,4,nil,true) then
    return "BOP"
  elseif gratuity:Find(self.item_bind_patterns.BOP2,2,4,nil,true) then
    return "BOP"
  elseif gratuity:Find(self.item_bind_patterns.QUEST,2,4,nil,true) then
    return "BOP"
  elseif gratuity:Find(self.item_bind_patterns.BOE,2,4,nil,true) then
    return "BOE"
  elseif gratuity:Find(self.item_bind_patterns.BOU,2,4,nil,true) then
    return "BOE"
  elseif gratuity:Find(self.item_bind_patterns.CRAFT,2,4,nil,true) then
    return "PATTERN"
  else
    return "NOBIND"
  end
  return
end

function guildbank:money(c)
  if not c then 
    c = GetMoney() 
    guildbank._lastMoney = date("%b/%d %H:%M:%S")
  end
  local gold = floor(c / (COPPER_PER_SILVER * SILVER_PER_GOLD))
  local silver = floor((c - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
  local copper = mod(c, COPPER_PER_SILVER)
  goldstring = gold > 0 and string.format("%d[color=#FFD700]%s[/color] ",gold,GOLD) or ""
  silverstring = silver > 0 and string.format("%d[color=#C0C0C0]%s[/color] ",silver,SILVER) or ""
  copperstring = copper > 0 and string.format("%d[color=#B87333]%s[/color] ",copper,COPPER) or ""
  return gold, silver, copper, string.format("%s%s%s",goldstring,silverstring,copperstring)
end

function guildbank:itemid(item)
  local link_found, _, itemid_s = string.find(item,"^item:(%d+):.+")
  return tonumber(itemid_s)
end

function guildbank:itemBreakdown(item)
  local link_found, _, itemColor, itemString, itemName = string.find(item, "^(|c%x+)|H(.+)|h(%[.+%])")
  local itemQuality = self.hexColorQuality[itemColor] or -1
  if link_found then
    return itemName, itemString, itemColor, itemQuality
  end
end

local function sort(a,b)
  if a[4] ~= b[4] then
    return a[4] > b[4]
  elseif a[1] ~= b[1] then
    return a[1] < b[1]
  else
    return false
  end
end

local function empty(t)
  for k,v in pairs(t) do
    t[k]=nil
  end
  table.setn(t,0)
end

guildbank._itemCache = setmetatable({},{mode="v"})
function guildbank:searchCache(item, count)
  if self._itemCache[item] then
    return item, self._itemCache[item][1], self._itemCache[item][3], self._itemCache[item][2], "NOBIND", count 
  end
  for i=34424,1,-1 do
    local itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(i)
    if itemName then 
      self._itemCache[itemName] = {itemString, itemQuality, ITEM_QUALITY_COLORS[itemQuality].hex} 
    end
    if self._itemCache[item] then
      return item, self._itemCache[item][1], self._itemCache[item][3], self._itemCache[item][2], "NOBIND", count
    end
  end
end

function guildbank:itemList(location,items)
  empty(self[location])
  for k,v in pairs(items) do
    if location == "Mail" and k ~= MONEY then
      local itemName, itemString, itemColor, itemQuality, itemBind, itemCount = self:searchCache(k,v[6])
      if itemName then
        v[1], v[2], v[3], v[4], v[5], v[6] = itemName, itemString, itemColor, itemQuality, itemBind, itemCount
      end
    end
    table.insert(self[location],v)
  end
  table.sort(self[location],sort)
  return self[location]
end

function guildbank:Export(fmt)
  local timestamp = date("%b/%d %H:%M:%S")
  local linkformat = links[self.db.profile.Link].prefix
  local exportstring = "[b]" .. self._pName .. ":" .. timestamp .. "[/b]\n"
  if self.db.profile.Bags then
    exportstring = exportstring .. "[b]" .. L["Bags"] .. "[/b]\n"
    local numitems = table.getn(self.Bags)
    if numitems > 0 then
      exportstring = exportstring .. "[list]\n"
    end
    for i,iteminfo in ipairs(self.Bags) do
      local itemName, itemString, itemColor, _, _, itemCount = iteminfo[1], iteminfo[2], iteminfo[3], iteminfo[4], iteminfo[5], iteminfo[6]
      local itemID = self:itemid(itemString)
      local link = string.format(linkformat,itemID)
      local _, _, color = string.find(itemColor,"|cff(.+)")
      local item = string.format("[color=#%s]%s[/color]",color,itemName)
      exportstring = exportstring .. string.format("[*] [url=%s]%s[/url] x%d",link,item,itemCount) .. "\n"
    end
    if numitems > 0 then
      exportstring = exportstring .. "[/list]\n"
    end
  end
  if self.db.profile.Bank then
    exportstring = exportstring .. "[b]" .. L["Bank"] .. "[/b]\n"
    local numitems = table.getn(self.Bank)
    if numitems > 0 then
      exportstring = exportstring .. "[list]\n"
    end
    for i,iteminfo in ipairs(self.Bank) do
      local itemName, itemString, itemColor, _, _, itemCount = iteminfo[1], iteminfo[2], iteminfo[3], iteminfo[4], iteminfo[5], iteminfo[6]
      local itemID = self:itemid(itemString)
      local link = string.format(linkformat,itemID)
      local _, _, color = string.find(itemColor,"|cff(.+)")
      local item = string.format("[color=#%s]%s[/color]",color,itemName)
      exportstring = exportstring .. string.format("[*] [url=%s]%s[/url] x%d",link,item,itemCount) .. "\n"
    end
    if numitems > 0 then
      exportstring = exportstring .. "[/list]\n"
    end
  end
  if self.db.profile.Mail then
    exportstring = exportstring .. "[b]" .. L["Mail"] .. "[/b]\n"
    local numitems = table.getn(self.Mail)
    if numitems > 0 then
      exportstring = exportstring .. "[list]\n"
    end
    for i,iteminfo in ipairs(self.Mail) do
      local itemName, itemString, itemColor, _, _, itemCount = iteminfo[1], iteminfo[2], iteminfo[3], iteminfo[4], iteminfo[5], iteminfo[6]
      if itemName ~= MONEY then
        local itemID = self:itemid(itemString)
        local link = string.format(linkformat,itemID)
        local _, _, color = string.find(itemColor,"|cff(.+)")
        local item = string.format("[color=#%s]%s[/color]",color,itemName)
        exportstring = exportstring .. string.format("[*] [url=%s]%s[/url] x%d",link,item,itemCount) .. "\n"
      end
    end
    if numitems > 0 then
      exportstring = exportstring .. "[/list]\n"
    end
  end
  if self.db.profile.Money then
    exportstring = exportstring .. "[b]" .. L["Money"] .. "[/b]\n"
    local g,s,c, moneystring = self:money()
    local mailmoneystring = ""
    for i,iteminfo in ipairs(self.Mail) do
      local itemName, itemString, itemColor, _, _, itemCount = iteminfo[1], iteminfo[2], iteminfo[3], iteminfo[4], iteminfo[5], iteminfo[6]
      if itemName == MONEY then
        local _,_,_, mailmoneystring = self:money(itemCount)
        mailmoneystring = string.format("+ %s (%s)",mailmoneystring, L["Mail"])
        break
      end
    end
    exportstring = exportstring .. string.format("%s%s",moneystring,mailmoneystring)
  end
  return exportstring
end

function guildbank:ExportShow()
  guildbank_export.AddSelectText(self:Export())
  ShowUIPanel(guildbank_export)
end

function guildbank:RegisterItemEvents(status)
  if status then
    for _,event in ipairs(itemevents) do
      if not self:IsEventRegistered(event) then
        self:RegisterEvent(event)
      end
    end
    for _,event in ipairs(bucketevents) do
      if not self:IsBucketEventRegistered(event) then
        self:RegisterBucketEvent(event,1)
      end
    end
  else
    for _,event in ipairs(itemevents) do
      if self:IsEventRegistered(event) then
        self:UnregisterEvent(event)
      end
    end
    for _,event in ipairs(bucketevents) do
      if self:IsBucketEventRegistered(event) then
        self:UnregisterBucketEvent(event)
      end      
    end
  end
end

function guildbank:OnInitialize() -- ADDON_LOADED (1)
  self:RegisterDB("guildbankDB")
  self:RegisterDefaults("profile", defaults )
  self:RegisterChatCommand( { "/gbank", "/guildbank" }, options )
  self.OnMenuRequest = options
  if not FuBar then
    self.OnMenuRequest.args.hide.guiName = L["Hide minimap icon"]
    self.OnMenuRequest.args.hide.desc = L["Hide minimap icon"]
  end  
end

function guildbank:OnEnable() -- PLAYER_LOGIN (2)
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LEAVING_WORLD")
  self:PLAYER_ENTERING_WORLD()
end

function guildbank:PLAYER_ENTERING_WORLD()
  self:RegisterItemEvents(true)
end

function guildbank:PLAYER_LEAVING_WORLD()
  self:RegisterItemEvents(false)
end

function guildbank:BAG_UPDATE()
  if self.db.profile.Bags then
    empty(self._bags)
    for bag=0, NUM_BAG_FRAMES do
      if (GetBagName(bag)) then
        local slotcount = GetContainerNumSlots(bag)
        for slot=1,slotcount do
          local itemLink = GetContainerItemLink(bag,slot)
          if itemLink then
            local itemName, itemString, itemColor, itemQuality = self:itemBreakdown(itemLink)
            local itemBind = self:itemBinding(itemString)
            local _, itemCount = GetContainerItemInfo(bag,slot)
            if itemName and itemBind and (itemBind ~= "BOP") then
              if self._bags[itemName] then 
                self._bags[itemName][6] = self._bags[itemName][6]+itemCount
              else
                self._bags[itemName] = {itemName, itemString, itemColor, itemQuality, itemBind, itemCount}
              end
            end
          end
        end
      end
    end
    self:itemList("Bags",self._bags)
    self._lastBags = date("%b/%d %H:%M:%S")
  end
  if self.db.profile.Bank then

  end
  if self.db.profile.Mail then

  end
end

function guildbank:MAIL_INBOX_UPDATE()
  if self.db.profile.Mail then
    empty(self._mail)
  end
end

function guildbank:MAIL_SHOW()
  if self.db.profile.Mail then
    if not self:IsEventRegistered("MAIL_CLOSED") then
      self:RegisterEvent("MAIL_CLOSED")
    end
  end
end

function guildbank:MAIL_CLOSED()
  if self.db.profile.Mail then
    self:UnregisterEvent("MAIL_CLOSED")
    empty(self._mail)
    local num_msg = GetInboxNumItems()
    if num_msg > 0 then
      for msg = 1, num_msg do
        local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(msg)
        if hasItem then
          gratuity:SetInboxItem(msg)
          local itemName, itemTexture, itemCount, itemQuality = GetInboxItem(msg)
          if self._mail[itemName] then
            self._mail[itemName][6] = self._mail[itemName][6] + itemCount
          else
            self._mail[itemName] = {itemName, "", "", itemQuality, "", itemCount}
          end
        end
        if money and money > 0 then
          if self._mail[MONEY] then
            self._mail[MONEY][6] = self._mail[MONEY][6] + money
          else
            self._mail[MONEY] = {MONEY, "", "", -1, "", money}
          end
        end
      end
    end
    self:itemList("Mail",self._mail)
    self._lastMail = date("%b/%d %H:%M:%S")
  end
end

function guildbank:BANKFRAME_OPENED()
  if self.db.profile.Bank then
    if not self:IsEventRegistered("BANKFRAME_CLOSED") then
      self:RegisterEvent("BANKFRAME_CLOSED")
    end
    empty(self._bank)
    for bankslot = 1, NUM_BANKGENERIC_SLOTS do
      local itemLink = GetContainerItemLink(BANK_CONTAINER, bankslot)
      if itemLink then
        local itemName, itemString, itemColor, itemQuality = self:itemBreakdown(itemLink)
        local itemBind = self:itemBinding(itemString)
        local _, itemCount = GetContainerItemInfo(BANK_CONTAINER, bankslot)
        if itemName and itemBind and (itemBind ~= "BOP") then
          if self._bank[itemName] then 
            self._bank[itemName][6] = self._bank[itemName][6]+itemCount
          else
            self._bank[itemName] = {itemName, itemString, itemColor, itemQuality, itemBind, itemCount}
          end
        end
      end
    end
    for bankbag = NUM_BAG_FRAMES + 1, NUM_BAG_FRAMES + NUM_BANKBAGSLOTS do
      if (GetBagName(bankbag)) then
        local slotcount = GetContainerNumSlots(bankbag)
        for slot=1,slotcount do
          local itemLink = GetContainerItemLink(bankbag,slot)
          if itemLink then
            local itemName, itemString, itemColor, itemQuality = self:itemBreakdown(itemLink)
            local itemBind = self:itemBinding(itemString)
            local _, itemCount = GetContainerItemInfo(bankbag,slot)
            if itemName and itemBind and (itemBind ~= "BOP") then
              if self._bank[itemName] then 
                self._bank[itemName][6] = self._bank[itemName][6]+itemCount
              else
                self._bank[itemName] = {itemName, itemString, itemColor, itemQuality, itemBind, itemCount}
              end
            end
          end
        end
      end      
    end
    self:itemList("Bank",self._bank)
  end
end

function guildbank:BANKFRAME_CLOSED()
  if self.db.profile.Bank then
    self:UnregisterEvent("BANKFRAME_CLOSED")
    self._lastBank = date("%b/%d %H:%M:%S")
  end
end

function guildbank:OnDisable()
  self:UnregisterAllEvents()
  --self:UnhookAll()
  self:Print(L["Disabling"])
end

function guildbank:GetBagsOption()
  return self.db.profile.Bags
end
function guildbank:SetBagsOption(newValue)
  self.db.profile.Bags = newValue
end
function guildbank:GetBankOption()
  return self.db.profile.Bank
end
function guildbank:SetBankOption(newValue)
  self.db.profile.Bank = newValue
end
function guildbank:GetMailOption()
  return self.db.profile.Mail
end
function guildbank:SetMailOption(newValue)
  self.db.profile.Mail = newValue
end
function guildbank:GetMoneyOption()
  return self.db.profile.Money
end
function guildbank:SetMoneyOption(newValue)
  self.db.profile.Money = newValue
end
function guildbank:GetLinkOption()
  return self.db.profile.Link
end
function guildbank:SetLinkOption(newValue)
  self.db.profile.Link = newValue
end
