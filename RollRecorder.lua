if not RollRecorderDB then
    RollRecorderDB = {}
end


local addonName = "RollRecorder"
local frame = CreateFrame("Frame", addonName)

-- Initialize playerRolls with saved data or an empty table
local playerRolls = {}

local function leftPad(str, length)
    return string.format("%-" .. length .. "s", str)
end

-- Function to right pad a string with spaces
local function rightPad(str, length)
    return string.format("%" .. length .. "s", str)
end

-- Function to handle system messages
local function OnChatMsgSystem(_, event, msg)
    local playerNamePattern = "(%a+)%s+rolls"
    local valuePattern = "rolls%s+(%d+)"
    local rollBetweenPattern = "%((.-)%)"

    local playerName = string.match(msg, playerNamePattern)
    local rollValue = tonumber(string.match(msg, valuePattern))
    local rollBetween = string.match(msg, rollBetweenPattern)

    if event == "CHAT_MSG_SYSTEM" and msg:find("rolls") then
        if playerName and rollValue and rollBetween == '1-100' then
            -- Check if the player is already in the table
            if not playerRolls[playerName] then
                playerRolls[playerName] = { total = 0, count = 0, rolls = {"","","","",""} }
            end

            -- Record the roll
            playerRolls[playerName].total = playerRolls[playerName].total + tonumber(rollValue)
            playerRolls[playerName].count = playerRolls[playerName].count + 1

            -- Store the last 5 rolls
            table.insert(playerRolls[playerName].rolls, rollValue)
            if #playerRolls[playerName].rolls > 5 then
                table.remove(playerRolls[playerName].rolls, 1)
            end

            -- Debugging messages
            --print("Total Rolls for " .. rightPad(playerName,14) .. ": " .. rightPad(playerRolls[playerName].count,6) .. " Average for " .. playerName .. ": " .. playerRolls[playerName].total / playerRolls[playerName].count)
        end
    end
end

-- Function to handle ADDON_LOADED event
local function ADDON_LOADED_Tasks()
    --print("Hello")

    -- Load saved data for each player individually
    for playerName, data in pairs(RollRecorderDB) do
        playerRolls[playerName] = data
    end
end

-- Function to handle PLAYER_LOGOUT event
local function LogOutTasks()
    -- Save data on logout for each player individually
    for playerName, data in pairs(playerRolls) do
        RollRecorderDB[playerName] = data
    end
end

-- Function to display results
local function displayResults()
    -- Create a frame
    local myFrame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BasicFrameTemplateWithInset");
    myFrame:SetSize(300, 200);
    myFrame:SetPoint("CENTER", UIParent, "CENTER");
    myFrame:SetMovable(true);
    myFrame:EnableMouse(true);
    myFrame:RegisterForDrag("LeftButton");
    myFrame:SetScript("OnDragStart", myFrame.StartMoving);
    myFrame:SetScript("OnDragStop", myFrame.StopMovingOrSizing);

    -- Add a title
    myFrame.title = myFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    myFrame.title:SetPoint("CENTER", myFrame.TitleBg, "LEFT", 125, 0);
    myFrame.title:SetText("History       Avg         Count     Last 5 Rolls");

    -- Add content based on playerRolls data, including the last 5 rolls
    local contentText = ""
    for playerName, data in pairs(playerRolls) do
        local average =  string.format("%.3f", data.total / data.count) or 0
        contentText = contentText .. leftPad(playerName,14) ..  leftPad(average,10) .. leftPad(data.count,13) .. table.concat(data.rolls, ", ") .. "\n"
    end

    myFrame.content = myFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    myFrame.content:SetPoint("TOPLEFT", myFrame, "TOPLEFT", 10, -30);
    myFrame.content:SetText(contentText);

    -- Show the frame
    myFrame:Show();
end

-- Register events
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

-- Register slash command
SLASH_ROLLRECORDER1 = "/RollRecorder"
SlashCmdList["ROLLRECORDER"] = function()
    displayResults()
end

frame:SetScript("OnEvent", function(self, event, msg)
    if event == "CHAT_MSG_SYSTEM" then
        OnChatMsgSystem(self, event, msg)
    elseif event == "ADDON_LOADED" then
        ADDON_LOADED_Tasks()
    elseif event == "PLAYER_LOGOUT" then
        LogOutTasks()
    end
end)
