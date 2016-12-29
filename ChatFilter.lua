local ChatFilter = {}

local ktDataDefault = {
  bEnabled = true,
  nMaxMessageLength = 120,
  arrWhitelist = {
    "T3",
    
    "WB",
    
    "Scorchwing",
    "SW",
    "Gargantua",
    "Garg",
    "Mechathorn",
    "Mecha",
    
    "Dreamspore",
    "DS",
    "Metal", "Maw",
    "MM",
    "King", "Honey", "Grave",
    "KHG",
    "Zoetic",
    "Zoe",
    
    "Metal", "Maw", "Prime",
    "MMP",
    "King", "Plush",
    "KP",
    "Grendelus",
    "Grend",
    "Kraggar",
    "Krag",
    
    "Matuk",
    "Kundar",
    "Frostgale",
    
    "Guardians", "Grove",
    "GotG",
    "Lightspire",
    "LS",
    
    "Veteran",
    "Adventure",
    "Dungeon",
    "Dungeons",
    "Vet",
    "Vets",
    "Fungeon",
    "Fungeons",
    
    "Genetic", "Archives",
    "GA",
    "Datascape",
    "DS",
    "Redmoon", "Terror",
    "RMT",
  },
  -- arrBlacklist = {},
}

local bDebug
local addonChatLog
local nRealmChannelId
local tWhitelist
-- local tBlacklist

function ChatFilter:Setup()
  addonChatLog = Apollo.GetAddon("ChatLog")
  self:FindRealmChannelId()
  self:SettingsUpdated()
  self.xmlDoc = XmlDoc.CreateFromFile("ChatFilter.xml")
  -- self.xmlDoc:RegisterCallback("OnDocumentReady", self)
  Apollo.RegisterSlashCommand("cfilter", "OnSlashCommand", self)
  Apollo.RegisterSlashCommand("chatfilter", "OnSlashCommand", self)
end

function ChatFilter:FindRealmChannelId()
  for idx, channelCurrent in ipairs(ChatSystemLib.GetChannels()) do
    local eChannelType = channelCurrent:GetType()
    if eChannelType == ChatSystemLib.ChatChannel_Realm then
      nRealmChannelId = channelCurrent:GetUniqueId()
      return
    end
  end
end

function ChatFilter:SettingsUpdated()
  if addonChatLog == nil then return end
  if nRealmChannelId == nil then return end
  Apollo.RemoveEventHandler("ChatMessage", self)
  if self.tData.bEnabled then
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
  end
  self:GenerateSearchLists()
end

function ChatFilter:GenerateSearchLists()
  tWhitelist = {}
  for idx, strWord in pairs(self.tData.arrWhitelist) do
    tWhitelist[strWord:lower()] = true
  end
  -- tBlacklist = {}
  -- for idx, strWord in pairs(self.tData.arrBlacklist) do
    -- tBlacklist[strWord:lower()] = true
  -- end
end

function ChatFilter:OnSlashCommand(strCmd, strParam)
  if strParam == "debug" then
    bDebug = not bDebug
    Print("Debug: "..tostring(bDebug))
    return
  end
  self:LoadMainWindow()
end

function ChatFilter:LoadMainWindow()
  if self.wndMain and self.wndMain:IsValid() then
    self.wndMain:Destroy()
  end
  self.wndMain = Apollo.LoadForm(self.xmlDoc, "Main", nil, self)
  self:CreateWordList()
end

function ChatFilter:CreateWordList()
  local wndList = self.wndMain:FindChild("List")
  wndList:DestroyChildren()
  for idx, strWord in pairs(self.tData.arrWhitelist) do
    if bDebug then strWord = "["..idx.."] "..strWord end
    local wndEntry = Apollo.LoadForm(self.xmlDoc, "ListEntry", wndList, self)
    wndEntry:FindChild("Word"):SetText(strWord)
    wndEntry:FindChild("ButtonRemove"):SetData(idx)
  end
  wndList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function ChatFilter:OnButtonCreate(wndHandler, wndControl)
  local strWord = self.wndMain:FindChild("CreateWord:EditBox"):GetText()
  table.insert(self.tData.arrWhitelist, strWord)
  self:GenerateSearchLists()
  self:CreateWordList()
end

function ChatFilter:OnButtonDefaults(wndHandler, wndControl)
  self.tData.arrWhitelist = ktDataDefault.arrWhitelist
  self:GenerateSearchLists()
  self:CreateWordList()
end

function ChatFilter:OnButtonRemove(wndHandler, wndControl)
  local nIndex = wndControl:GetData()
  self.tData.arrWhitelist[nIndex] = nil
  self:GenerateSearchLists()
  self:CreateWordList()
end

function ChatFilter:OnChatMessage(channelCurrent, tMessage)
  local nChatChannel = ChatSystemLib.ChatChannel_Nexus
  if bDebug then nChatChannel = ChatSystemLib.ChatChannel_Say end
  if channelCurrent:GetType() ~= nChatChannel then return end
  local strMessage = tostring(tMessage.arMessageSegments[1].strText)
  if strMessage:len() > self.tData.nMaxMessageLength then return end
  if self:SearchMessage(strMessage) then
    self:DisplayMessage(channelCurrent, tMessage)
  end
end

function ChatFilter:SearchMessage(strMessage)
  for strWord in strMessage:gmatch("%w+") do
    if tWhitelist[strWord:lower()] then
      return true
    end
  end
end

function ChatFilter:DisplayMessage(channelCurrent, tMessage)
  local tQueuedMessage = {
    tMessage = self:CloneTable(tMessage),
    eChannelType = channelCurrent:GetType(),
    strChannelName = channelCurrent:GetName(),
    strChannelCommand = channelCurrent:GetCommand(),
    idChannel = nRealmChannelId,
  }
  addonChatLog:HelperGenerateChatMessage(tQueuedMessage)
  addonChatLog:HelperQueueMessage(tQueuedMessage)
end

function ChatFilter:CloneTable(tData)
  local tClone = {}
  for k, v in pairs(tData) do
    if type(v) == "table" then
      tClone[k] = self:CloneTable(v)
    else
      tClone[k] = v
    end
  end
  setmetatable(tClone, getmetatable(tData))
  return tClone
end

function ChatFilter:OnSave(eLevel)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    return self.tData
  end
end

function ChatFilter:OnRestore(eLevel, tSave)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    self.tData = tSave
    self:SettingsUpdated()
  end
end

function ChatFilter:new(o)
  o = o or {
    tData = ktDataDefault,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function ChatFilter:Init()
  Apollo.RegisterAddon(self)
end

function ChatFilter:OnLoad()
  self:Setup()
end

local ChatFilterInst = ChatFilter:new()
ChatFilterInst:Init()
