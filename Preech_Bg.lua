--
-- parts of this are ripped from WarsongCountdown
--

Preech_Bg_DisplayOptions = {
    ['DisplayHonorPoints'] = true,
    ['DisplayHonorableKills'] = true,
    ['DisplayWsgFlagCount'] = true,
    ['DisplayAbEventCount'] = true,
};

HONOR_POINTS_ID = 392;
HONOR_POINTS_CAP = 4000;

local function HexToRGBPerc(hex)
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end

RED_VALUE, GREEN_VALUE, BLUE_VALUE = HexToRGBPerc('aaaaaa');
HIGHLIGHT_COLOR = 'ffffff';
CAPPED_COLOR = 'ff3300';

current_vals = {
    this_bg_hp = 0,
    this_bg_start_hp = 0,
    this_bg_start_rep = 0,
    this_bg_hks = 0,
    start_lifetime_hks = 0
};

Preech_Bg_WC_PointsPerStanding = {
    [1] = 36000,  -- Hated
    [2] = 3000,   -- Hostile
    [3] = 3000,   -- Unfriendly
    [4] = 3000,   -- Neutral
    [5] = 6000,   -- Friendly
    [6] = 12000,  -- Honored
    [7] = 21000,  -- Revered
    [8] = 1000,   -- Exalted
};

Preech_Bg_WC_WarsongFactionLookup = {
    ['Horde'] = 'Warsong Outriders',
    ['Alliance'] = 'Silverwing Sentinels',
}

Preech_Bg_AbFactionLookup = {
    ['Horde'] = 'The Defilers',
    ['Alliance'] = 'I Dunno',
}

-- Faction standings
S_WC_STANDING0='Unknown';
S_WC_STANDING1='Hated';
S_WC_STANDING2='Hostile';
S_WC_STANDING3='Unfriendly';
S_WC_STANDING4='Neutral';
S_WC_STANDING5='Friendly';
S_WC_STANDING6='Honoured';
S_WC_STANDING7='Revered';
S_WC_STANDING8='Exalted';

Preech_Bg_WC_WarsongFactionName = '';

function Preech_Bg_OnEvent(self, event, arg1, arg2, arg3, arg4)
    if (event=='ADDON_LOADED' and arg1=='Preech_Bg') then
        SLASH_PREECH_BG1='/preech';
        SLASH_PREECH_BG2='/pbg';
        SlashCmdList['PREECH_BG']=Preech_Bg_ParseParameters;

        Preech_Bg_WC_WarsongFactionName = Preech_Bg_WC_WarsongFactionLookup[UnitFactionGroup('player')];
        Preech_Bg_AbFactionName = Preech_Bg_AbFactionLookup[UnitFactionGroup('player')];
        Preech_Bg_OptionsPanel_ApplyOptions();
        Preech_Bg_WriteChatMessage("Preech Bg loaded (/preech)");
        Preech_Bg_Reset();
    elseif (event=='CHAT_MSG_COMBAT_HONOR_GAIN' or event=='MERCHANT_UPDATE' or event=='UPDATE_FACTION') then
        -- just update display
    elseif (event=='PLAYER_ENTERING_BATTLEGROUND') then
        Preech_Bg_Reset();
    end
    Preech_Bg_UpdateDisplay();

    if (event == 'PLAYER_ENTERING_BATTLEGROUND') then
        st_scored = false
        st_in_bg = true
        --BgTally_Update()
    elseif (event == 'UPDATE_BATTLEFIELD_STATUS') then
        if (not st_scored) then
            winner = GetBattlefieldWinner()
            if (winner ~= nil) then
                st_scored = true
                st_scores['bgs_played'] = st_scores['bgs_played'] + 1
                st_scores['this_session_bgs_played'] = st_scores['this_session_bgs_played'] + 1
                if (winner == st_playerFaction) then
                    st_scores['bgs_won'] = st_scores['bgs_won'] + 1
                    st_scores['this_session_bgs_won'] = st_scores['this_session_bgs_won'] + 1
                end
                st_in_bg = false
                --BgTally_Update()
            end
        end
    elseif (event == 'ADDON_LOADED' and arg1 == 'Preech_Bg') then
        if (st_playerName == '') then
            p = UnitName('player')
            st_playerName, x = p
            f, lf = UnitFactionGroup('player')
            if (f == 'Horde') then
                st_playerFaction = 0
            else
                st_playerFaction = 1
            end
            st_scores.this_session_bgs_played = 0
            st_scores.this_session_bgs_won = 0
        end
        --BgTally_Update()
    end
end

function Preech_Bg_ParseParameters(paramStr)
    if (paramStr=='options' or paramStr=='opts') then
        InterfaceOptionsFrame_OpenToCategory('Preech Bg');
    elseif (paramStr=='refresh') then
        Preech_Bg_UpdateDisplay();
    elseif (paramStr=='lock') then
        preech_frame:EnableMouse(false);
        preech_frame:RegisterForDrag('');
        Preech_Bg_WriteChatMessage("locked");
    elseif (paramStr=='unlock') then
        preech_frame:EnableMouse(true);
        preech_frame:RegisterForDrag('LeftButton');
        Preech_Bg_WriteChatMessage("unlocked, use left-click to move");
    else
        Preech_Bg_WriteChatMessage("options: display the options panel");
        Preech_Bg_WriteChatMessage("refresh: refresh the display");
        Preech_Bg_WriteChatMessage("lock: lock the display");
        Preech_Bg_WriteChatMessage("unlock: unlock the display");
    end
end

function Preech_Bg_UpdateDisplay()
    hp = Preech_Bg_GetCurrency(HONOR_POINTS_ID);
    current_vals.this_bg_hp = hp - current_vals.this_bg_start_hp;
    msg = '';
    if (Preech_Bg_DisplayOptions.DisplayHonorPoints) then
        msg = msg .. 'HP: ' .. Preech_Bg_FormatHp(hp);
        if (current_vals.this_bg_hp > 0 and tonumber(current_vals.this_bg_hp) ~= tonumber(hp)) then
            msg = msg .. ' (+' .. Preech_Bg_CommaValue(current_vals.this_bg_hp) .. ')';
        end
        msg = msg .. ' | ';
    end
    if (Preech_Bg_DisplayOptions.DisplayHonorableKills) then
        hks, x, x = GetPVPLifetimeStats();
        msg = msg .. 'HK: ' .. Preech_Bg_Format(hks);
        current_vals.this_bg_hks = tonumber(hks) - tonumber(current_vals.start_lifetime_hks);
        if (current_vals.this_bg_hks > 0 and tonumber(current_vals.this_bg_hks) ~= tonumber(hks)) then
            msg = msg .. ' (+' .. Preech_Bg_CommaValue(current_vals.this_bg_hks) .. ')';
        end
    end
    msg = msg .. ' | Totals: ' .. BgTally_Update();
    if (Preech_Bg_DisplayOptions.DisplayAbEventCount or Preech_Bg_DisplayOptions.DisplayWsgFlagCount) then
        msg = msg .. '\n';
    end
    if (Preech_Bg_DisplayOptions.DisplayAbEventCount) then
        msg = msg .. Preech_Bg_BuildAbMessage();
    end
    if (Preech_Bg_DisplayOptions.DisplayWsgFlagCount) then
        if (Preech_Bg_DisplayOptions.DisplayAbEventCount) then
            msg = msg .. ' | ';
        end
        msg = msg .. Preech_Bg_WC_BuildFlagMessage();
    end
    Preech_Bg_MessageFrame:AddMessage(msg, RED_VALUE, GREEN_VALUE, BLUE_VALUE);
end

function Preech_Bg_WriteChatMessage(what)
    DEFAULT_CHAT_FRAME:AddMessage('|cffff9900<|cffff6600PreechBg|cffff9900>|r ' .. what, RED_VALUE, GREEN_VALUE, BLUE_VALUE);
end

function Preech_Bg_GetCurrency(id)
    x, points, x, x, x, x, x = GetCurrencyInfo(id);
    return points;
end

function Preech_Bg_Format(num)
    return '|cff' .. HIGHLIGHT_COLOR .. Preech_Bg_CommaValue(num) .. '|r';
end

function Preech_Bg_FormatHp(hp)
    rv = Preech_Bg_CommaValue(hp)
    if (hp>=HONOR_POINTS_CAP) then
        rv = '|cff' .. CAPPED_COLOR .. rv .. '|r';
    else
        rv = Preech_Bg_Format(hp)
    end
    return rv
end

function Preech_Bg_CommaValue(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted;
end

function Preech_Bg_Reset()
    current_vals.this_bg_hp = 0;
    current_vals.this_bg_start_hp = Preech_Bg_GetCurrency(HONOR_POINTS_ID);
    current_vals.this_bg_start_rep = Preech_Bg_WC_GetReputation(Preech_Bg_AbFactionName);
    current_vals.this_bg_hks = 0;
    current_vals.start_lifetime_hks, x, x = GetPVPLifetimeStats();
end

function Preech_Bg_WC_GetReputation(faction)
    for i=1, GetNumFactions() do
        local name, description, standingId, bottomValue, topValue, earnedValue = GetFactionInfo(i)
        if (name==faction) then
            return earnedValue, standingId
        end
    end
    return 0, 4;
end

function Preech_Bg_BuildAbMessage()
    local rep, standingId = Preech_Bg_WC_GetReputation(Preech_Bg_AbFactionName);
    if (standingId == 8) then
        return '';
    end
    local standingRep=rep;
    for i=4, standingId - 1 do
        standingRep=standingRep - Preech_Bg_WC_PointsPerStanding[i];
    end
    local repToExalted=-rep + 1;
    for i=7, 4, - 1 do
        repToExalted=repToExalted + Preech_Bg_WC_PointsPerStanding[i];
    end
    local repToNextStanding=Preech_Bg_WC_PointsPerStanding[standingId] - standingRep;
    local standingNameNext=getglobal('S_WC_STANDING' .. standingId + 1);
    local message;
    local eventsToNextStanding=ceil(repToNextStanding / 16);
    local eventsToExalted=ceil(repToExalted / 16);
    local pct = 100 - ceil(repToNextStanding / Preech_Bg_WC_PointsPerStanding[standingId] * 100);
    local events = (rep - current_vals.this_bg_start_rep) / 16;
    message = 'AB: ' .. Preech_Bg_Format(eventsToNextStanding);
    if (events > 0) then
        message = message .. ' (+' .. events .. ')';
    end
    message = message .. ' rep gains [' .. Preech_Bg_Format(pct) .. '%] to ' .. standingNameNext;
     -- .. Preech_Bg_Format(eventsToNextStanding) .. ' events to ' ..
     --          standingNameNext .. ' [' .. pct .. '%], ' .. Preech_Bg_Format(eventsToExalted) .. ' to Exalted';
    return message;
end

function Preech_Bg_WC_BuildFlagMessage()
    local reputation, standingId=Preech_Bg_WC_GetReputation(Preech_Bg_WC_WarsongFactionName);

    if (standingId==8) then
        return '';
    end
    local standingRep=reputation;
    for i=4, standingId - 1 do
        standingRep=standingRep - Preech_Bg_WC_PointsPerStanding[i];
    end
    local repToExalted=-reputation + 1;
    for i=7, 4, - 1 do
        repToExalted=repToExalted + Preech_Bg_WC_PointsPerStanding[i];
    end
    local repToNextStanding=Preech_Bg_WC_PointsPerStanding[standingId] - standingRep;
    local standingNameNext=getglobal('S_WC_STANDING' .. standingId + 1);
    local flagMessage;
    local flagsToNextStanding=ceil(repToNextStanding / 35);
    local flagsToExalted=ceil(repToExalted / 35);
    local pct = 100 - ceil(repToNextStanding / Preech_Bg_WC_PointsPerStanding[standingId] * 100)
    flagMessage = 'WSG: ' .. Preech_Bg_Format(flagsToNextStanding) .. ' flags [' .. Preech_Bg_Format(pct) .. '%] to ' .. standingNameNext; -- .. Preech_Bg_Format(flagsToNextStanding) ..
--                  ' flags to ' .. standingNameNext .. ' [' .. pct .. '%]'; -- .. ', ' .. Preech_Bg_Format(flagsToExalted) .. ' to Exalted';
    return flagMessage;
end

--
-- A Battleground tallier
--

st_scores = {
    ['bgs_played'] = 0,
    ['bgs_won'] = 0,
    ['this_session_bgs_played'] = 0,
    ['this_session_bgs_won'] = 0,
}

local st_scored = false
local st_in_bg = false

local st_playerName = ''
local st_playerFaction = ''

--
-- time any stuns and display statistics about them
--
function BgTally_Update()
    color = '|cffffffff'
    bgmsg = BgTally_Colorize(color, st_scores.this_session_bgs_won) ..
       ' for ' .. BgTally_Colorize(color, st_scores.this_session_bgs_played) ..
       ' this session'
    if st_scores['this_session_bgs_played'] > 0 then
        bgmsg = bgmsg .. ' (' .. BgTally_Colorize(color,
                                                string.format('%d', st_scores.this_session_bgs_won /
                                                                    st_scores.this_session_bgs_played * 100)) .. '%)'
    end
    bgmsg = bgmsg .. ' [' ..
          BgTally_Colorize(color, st_scores.bgs_won) ..
          ' for ' .. BgTally_Colorize(color, st_scores.bgs_played)
    if st_scores.bgs_played > 0 then
        bgmsg = bgmsg .. ' (' ..
              BgTally_Colorize(color, string.format('%d', st_scores.bgs_won /
                                                            st_scores.bgs_played * 100)) .. '%)'
    end
    bgmsg = bgmsg .. ' all time]'
    return bgmsg
end

function BgTally_Colorize(color, what)
    return color .. what .. '|r'
end

--- End Bg Tally ---

preech_frame=CreateFrame('MessageFrame', 'Preech_Bg_MessageFrame', UIParent);
preech_frame:SetMovable(true);
preech_frame:SetScript('OnEvent', Preech_Bg_OnEvent);
preech_frame:SetScript('OnDragStart', preech_frame.StartMoving);
preech_frame:SetScript('OnDragStop', preech_frame.StopMovingOrSizing);
preech_frame:RegisterEvent('ADDON_LOADED');
preech_frame:RegisterEvent('CHAT_MSG_COMBAT_HONOR_GAIN');
preech_frame:RegisterEvent('MERCHANT_UPDATE');
preech_frame:RegisterEvent('PLAYER_ENTERING_BATTLEGROUND');
preech_frame:RegisterEvent('UPDATE_FACTION');
preech_frame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
preech_frame:RegisterEvent('UPDATE_BATTLEFIELD_STATUS') -- when bg is won
preech_frame:SetWidth(600);
preech_frame:SetHeight(20);
preech_frame:SetFrameStrata('HIGH');
preech_frame:SetFading(false);
preech_frame:SetPoint('TOPLEFT');
preech_frame:SetFontObject(GameFontNormalSmall, 10, "OUTLINE");
font = preech_frame:GetFontObject();
font:SetJustifyH('CENTER');
preech_frame:Show();
