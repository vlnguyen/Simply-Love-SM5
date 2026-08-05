local Players = GAMESTATE:GetHumanPlayers()
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local FilterAlpha = BackgroundFilterValues()

-- This pane's whole purpose is a versus-specific layout (split-screen
-- background, "other side" positioning, etc.) that the normal single-player
-- StepStatsPane doesn't support -- so which layout renders must depend only
-- on the local style/player count, never on the lobby's total player count.
-- UseLobbyStandings (below) only affects the score-text's own visibility and
-- dimming math further down, not whether this pane exists at all.
local OnlineHandler = GetOnlineHandlerInstance()
local UseLobbyStandings = OnlineHandler and OnlineHandler.inLobby and IsTournamentModeEX() and not IsSoloVersus()

local ShouldDisplayStatsForPlayer = function(player)
    local pn = ToEnumShortString(player)
    return (SL[pn].ActiveModifiers.DataVisualizations == "Step Statistics" or
            (ThemePrefs.Get("EnableTournamentMode") and ThemePrefs.Get("StepStats") == "Show"))
end

local ShouldDisplayStats = function()
    -- Only use this in Versus + Widescreen.
    if GAMESTATE:GetCurrentStyle():GetName() ~= "versus" or not IsUsingWideScreen() then
        return false
    end

    -- Ultrawide versus is already supported natively.
    if IsUltraWide then return false end

    local shouldDisplay = false
    for player in ivalues(Players) do
        if ShouldDisplayStatsForPlayer(player) then
            shouldDisplay = true
        end
    end
    return shouldDisplay
end

-- Returns a table of the background filter alpha values for each player
-- used to diffuse the step statistics bg quad accordingly
local determineFilterAlphas = function()
    local alphas = {}
    for player in ivalues(Players) do
        local pn = ToEnumShortString(player)
        alphas[player] = clamp(FilterAlpha[SL[pn].ActiveModifiers.BackgroundFilter]/100 or 0, 0.25, 0.9)
    end
    return alphas
end

if not ShouldDisplayStats() then
    return
end

local af = Def.ActorFrame{
    InitCommand=function(self)
		self:Center()
    end
}

local playerFilters = determineFilterAlphas()
if ShouldDisplayStats() then
    af[#af+1] = Def.Quad{
        InitCommand=function(self)
            self:diffuseleftedge(0,0,0, playerFilters[PLAYER_1] or 0.25)
                :diffuserightedge(0,0,0, playerFilters[PLAYER_2] or 0.25)
            self:zoomto(150, SCREEN_HEIGHT)
        end,
    }
end

for player in ivalues(Players) do
    if ShouldDisplayStatsForPlayer(player) and GAMESTATE:GetNumSidesJoined() > 1 then
        -- No need to reimplement the wheel here. Just use the existing actor and modify it for our use case.
        local judgments = LoadActor("../PerPlayer/StepStatistics/TapNoteJudgments.lua", {player, false})
        judgments.InitCommand = function(self)    
            local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
            local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Notes" )
    
            -- determine how many digits are needed to express the number of notes in base-10
            local digits = (math.floor(math.log10(total_tapnotes)) + 1)
            -- display a minimum 4 digits for aesthetic reasons
            digits = math.max(4, digits)

            self:zoom(0.8)
            self:y(100)
            self:x(65 * (player==PLAYER_1 and -1 or 1) + 1)

            if digits > 4 then
                -- This works okay enough for 5 and 6 digits.
                self:zoomx(self:GetZoomX() - 0.12 * (digits-4))
            end
        end

        af[#af+1] = judgments

        -- Add a score to Step Stats if it's hidden by the NPS graph, we're in
        -- Tournament Mode, or we're using lobby-wide standings (there might be
        -- a remote opponent to compare against with no local versus partner).
        if SL[ToEnumShortString(player)].ActiveModifiers.NPSGraphAtTop or ThemePrefs.Get("EnableTournamentMode") or UseLobbyStandings then
            local pn = ToEnumShortString(player)
            local IsEX = SL[pn].ActiveModifiers.ShowExScore
            local otherPlayer = OtherPlayer[player]

            -- Mirror "ScreenGameplay overlay/WhoIsCurrentlyWinning.lua": dim
            -- whichever player is currently behind.
            local myScore = 0
            local theirScore = 0
            local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
            local other_pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(otherPlayer)

            af[#af+1] = LoadFont("Wendy/_wendy monospace numbers")..{
                Text="0.00",
                InitCommand=function(self)
                    self:valign(1):horizalign(right)
                    self:zoom(0.25)
                    if player == PLAYER_1 then
                        self:xy(-7, -150)
                    else
                        self:xy(65, -150)
                    end

                    if IsEX then
                        -- If EX Score, let's diffuse it to be the same as th ITG top window.
                        -- This will make it consistent with the EX Score Pane.
                        self:diffuse(SL.JudgmentColors["ITG"][1])
                    end
                end,
                JudgmentMessageCommand=function(self, params)
                    if params.Player == player then
                        self:queuecommand("RedrawScore")
                    end

                    if not IsEX and (params.Player == player or params.Player == otherPlayer) then
                        -- calculate the percentage DP manually rather than use GetPercentDancePoints.
                        -- That function rounds to the nearest .01%, which is inaccurate on long songs.
                        if params.Player == player then
                            myScore = pss:GetActualDancePoints() / pss:GetPossibleDancePoints()
                        else
                            theirScore = other_pss:GetActualDancePoints() / other_pss:GetPossibleDancePoints()
                        end
                        self:queuecommand("RedrawWinning")
                    end
                end,
                RedrawScoreCommand=function(self)
                    if not IsEX then
                        local dance_points = pss:GetPercentDancePoints()
                        local percent = FormatPercentScore( dance_points ):sub(1,-2)
                        self:settext(percent)
                    end
                end,
                ExCountsChangedMessageCommand=function(self, params)
                    if params.Player ~= player and params.Player ~= otherPlayer then return end

                    if IsEX then
                        if params.Player == player then
                            self:settext(("%.02f"):format(params.ExScore))
                            myScore = params.ExScore
                        else
                            theirScore = params.ExScore
                        end
                        self:queuecommand("RedrawWinning")
                    end
                end,
                OnlineLobbyStateMessageCommand=function(self)
                    -- Remote players' scores update via the lobby server, not
                    -- local Judgment/ExCountsChanged messages, so re-check on
                    -- every lobby update too.
                    self:queuecommand("RedrawWinning")
                end,
                RedrawWinningCommand=function(self)
                    -- Check fresh each time (rather than the load-time
                    -- snapshot) so a mid-song disconnect gracefully falls back
                    -- to local-only comparison.
                    local handler = GetOnlineHandlerInstance()
                    local useLobbyStandingsNow = handler and handler.inLobby and IsTournamentModeEX() and not IsSoloVersus()

                    if useLobbyStandingsNow then
                        -- Pull "my score" from the lobby roster too (not local
                        -- judgment tracking), so both sides of the comparison
                        -- come from the same synced snapshot. Always EX score
                        -- in this mode.
                        local best = GetBestLobbyScore(true)
                        local myLobbyScore = GetLobbyScoreForPlayer(player, true)
                        self:diffusealpha((not best or not myLobbyScore or myLobbyScore >= best) and 1 or 0.65)
                        return
                    end

                    -- Only compare locally if both players are using the same
                    -- scoring mechanism.
                    if SL["P1"].ActiveModifiers.ShowExScore ~= SL["P2"].ActiveModifiers.ShowExScore then
                        self:diffusealpha(1)
                        return
                    end

                    if myScore >= theirScore then
                        self:diffusealpha(1)
                    else
                        self:diffusealpha(0.65)
                    end
                end,
            }
        end
    end
end

af[#af+1] = Def.Banner{
    CurrentSongChangedMessageCommand=function(self)
		self:LoadFromSong( GAMESTATE:GetCurrentSong() )
		self:setsize(418,164):zoom(0.3):addy(70)
        self:SetDecodeMovie(ThemePrefs.Get("AnimateBanners"))
    end
}

return af