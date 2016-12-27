local ChatFilter = {}

local ktDataDefault = {
  bEnabled = true,
  nMaxMessageLength = 200,
  arrWhitelist = {
    "T3",
  },
  arrBlacklist = {},
}

local karrDefaultWhitelist = {
  "T3",
  "SW",
  "Scorchwing",
  "Mecha",
  "Garg",
  "Gargantua",
  "DS",
  "Dreamspore",
  "KHG",
  "King Honey Grave",
  "Metal Maw",
  "MM",
  "Zoe",
  "Zoetic",
  "MMP",
  "KP",
  "Grend",
  "Kraggar",
  "GA",
  "DS",
  "RMT",
  "WB",
  "Matuk",
  "Kundar",
  "Frostgale",
  "GotG",
  "Grove",
  "Dungeon",
  "Veteran",
  "Vet",
  "Vets",
  "Fungeon",
}

local addonChatLog
local nRealmChannelId
local tWhitelist
local tBlacklist

function ChatFilter:Setup()
  addonChatLog = Apollo.GetAddon("ChatLog")
  self:FindRealmChannelId()
  self:SettingsUpdated()
  --self.xmlDoc = 
  --register xml doc loaded callback?
  Apollo.RegisterSlashCommand("chatfilter", "OnSlashCommand", self)
end

function ChatFilter:FindRealmChannelId()
  for idx, channelCurrent in ipairs(ChatSystemLib.GetChannels()) do
    local eChannelType = channelCurrent:GetType()
    if eChannelType == ChatSystemLib.ChatChannel_Realm then
      nRealmChannelId = channelCurrent:GetUniqueId()
    end
  end
end

function ChatFilter:SettingsUpdated()
  if addonChatLog and self.tData.bEnabled then
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
  else
    Apollo.RemoveEventHandler("ChatMessage", self)
  end
  self:GenerateSearchLists()
end

function ChatFilter:GenerateSearchLists()
  --for idx, strWord in ipairs(self.tData.arrWhitelist)
  --TODO
  --self.tData.arrWhite/Blacklist
end

-- function ChatFilter:MakeTable()
  -- for idx, strGood in ipairs(ktWhiteList) do
    -- local strToAdd = strGood:lower()
    -- local tPath = tSearch
    -- for c in strToAdd:gmatch(".") do
      -- tPath[c] = tPath[c] or {}
      -- tPath = tPath[c]
    -- end
    -- tPath.isMatch = true
  -- end
-- end

function ChatFilter:OnSlashCommand(strCmd, strParam)
end

local function cloneTable(tData) --deep copy
  local tClone = {}
  for k, v in pairs(tData) do
    if type(v) == "table" then
      tClone[k] = cloneTable(v)
    else
      tClone[k] = v
    end
  end
  setmetatable(tClone, getmetatable(tData))
  return tClone
end

function ChatFilter:DisplayMessage(channelCurrent, tMessage)
  local tQueuedMessage = {
    tMessage = cloneTable(tMessage),
    eChannelType = channelCurrent:GetType(),
    strChannelName = channelCurrent:GetName(),
    strChannelCommand = channelCurrent:GetCommand(),
    idChannel = channelCurrent:GetUniqueId(),
    idChannel = nRealmChannelId,
  }
  addonChatLog:HelperGenerateChatMessage(tQueuedMessage)
  addonChatLog:HelperQueueMessage(tQueuedMessage)
end

function ChatFilter:SplitString(strIn, inSplitPattern)
  local outResults = {}
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( strIn, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( strIn, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( strIn, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( strIn, theStart ) )
  return outResults
end

function ChatFilter:IsInSearch(strWord)
  local tPath = tSearch
  for c in strWord:gmatch(".") do
    -- Print("checking: "..c)
    if not tPath[c] then return false end
    tPath = tPath[c]
    -- Print(c.." is good")
  end
  -- Print("result: "..tostring(tPath.isMatch))
  if tPath.isMatch then return true end
end

--ignore punctuation

function ChatFilter:SearchMessage(strMessage)
  -- for idx,strWord in ipairs(self:SplitString(strMessage, "%s+")) do
    -- if self:IsInSearch(strWord) then 
    -- self:GoodMessage(channelCurrent, tMessage)
    -- return
    -- end
  -- end
  -- return false
end

function ChatFilter:OnChatMessage(channelCurrent, tMessage)
  if channelCurrent:GetType() ~= ChatSystemLib.ChatChannel_Nexus then return end
  -- if channelCurrent:GetType() ~= ChatSystemLib.ChatChannel_Say then return end
  local strMessage = string.lower(tostring(tMessage.arMessageSegments[1].strText))
  if strMessage:len() > self.tData.nMaxMessageLength then return end
  self:SearchMessage(strMessage)
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
