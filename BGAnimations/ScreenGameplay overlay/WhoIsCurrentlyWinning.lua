-- If both players are joined, change the opacity of their score BitmapText actors to
-- visually indicate who is winning at a given moment during gameplay.
--
-- During a Tournament Mode (EX scoring) event while connected to an online lobby,
-- standing is instead judged against the whole lobby rather than just a local
-- opponent -- there might only be one local player racing remote opponents. (Solo
-- versus -- see IsSoloVersus() -- still falls back to the local-only behavior, since
-- the "whole lobby" there is just the two local players anyway.)
------------------------------------------------------------

local handler = GetOnlineHandlerInstance()
local UseLobbyStandings = handler and handler.inLobby and IsTournamentModeEX() and not IsSoloVersus()

-- Outside of that specific lobby scenario, there's no one to compare against
-- unless both local players are joined and using the same scoring mechanism.
if not UseLobbyStandings then
	if #GAMESTATE:GetHumanPlayers() < 2 then return end
	if SL["P1"].ActiveModifiers.ShowExScore ~= SL["P2"].ActiveModifiers.ShowExScore then return end
end

local p1_score, p2_score
local p1_dp = 0
local p2_dp = 0
local p1_pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
local p2_pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_2)
local IsEX = SL["P1"].ActiveModifiers.ShowExScore

-- allow for HideScore, which outright removes score actors
local try_diffusealpha = function(af, alpha)
	if not af or not (af.diffusealpha) then return end
	af:diffusealpha(alpha)
end

return Def.Actor{
	OnCommand=function(self)
		local underlay = SCREENMAN:GetTopScreen():GetChild("Underlay")
		p1_score = underlay:GetChild("P1Score")
		p2_score = underlay:GetChild("P2Score")
	end,
	JudgmentMessageCommand=function(self, params)
		-- Tournament Mode + EX scoring always reports via ExCountsChanged instead.
		if UseLobbyStandings then return end

		if not IsEX then
			-- calculate the percentage DP manually rather than use GetPercentDancePoints.
			-- That function rounds to the nearest .01%, which is inaccurate on long songs.
			if params.Player == PLAYER_1 then
				p1_dp = p1_pss:GetActualDancePoints() / p1_pss:GetPossibleDancePoints()
			elseif params.Player == PLAYER_2 then
				p2_dp = p2_pss:GetActualDancePoints() / p2_pss:GetPossibleDancePoints()
			end
			self:queuecommand("Winning")
		end
	end,
	ExCountsChangedMessageCommand=function(self, params)
		if UseLobbyStandings then
			-- Tournament Mode + EX scoring forces everyone's ShowExScore to true,
			-- so this is always the EX score, regardless of join status.
			if params.Player == PLAYER_1 then
				p1_dp = params.ExScore
			elseif params.Player == PLAYER_2 then
				p2_dp = params.ExScore
			end
			self:queuecommand("Winning")
			return
		end

		if IsEX then
			if params.Player == PLAYER_1 then
				p1_dp = params.ExScore
			elseif params.Player == PLAYER_2 then
				p2_dp = params.ExScore
			end
			self:queuecommand("Winning")
		end
	end,
	OnlineLobbyStateMessageCommand=function(self)
		-- Remote players' scores update via the lobby server, not local
		-- Judgment/ExCountsChanged messages, so re-check on every lobby update too.
		self:queuecommand("Winning")
	end,
	WinningCommand=function(self)
		-- Check fresh each time (rather than the load-time snapshot) so a
		-- mid-song disconnect gracefully falls back to local-only comparison.
		local handler = GetOnlineHandlerInstance()
		local useLobbyStandingsNow = handler and handler.inLobby and IsTournamentModeEX() and not IsSoloVersus()

		if useLobbyStandingsNow then
			-- Judge each local player against the whole lobby instead of just
			-- each other -- there might only be one local player here. Pull
			-- "my score" from the lobby roster too (not local judgment
			-- tracking), so both sides of the comparison come from the same
			-- synced snapshot. Always EX score in this mode.
			local best = GetBestLobbyScore(true)
			if GAMESTATE:IsSideJoined(PLAYER_1) then
				local myLobbyScore = GetLobbyScoreForPlayer(PLAYER_1, true)
				try_diffusealpha(p1_score, (not best or not myLobbyScore or myLobbyScore >= best) and 1 or 0.65)
			end
			if GAMESTATE:IsSideJoined(PLAYER_2) then
				local myLobbyScore = GetLobbyScoreForPlayer(PLAYER_2, true)
				try_diffusealpha(p2_score, (not best or not myLobbyScore or myLobbyScore >= best) and 1 or 0.65)
			end
			return
		end

		if p1_dp == p2_dp then
			try_diffusealpha(p1_score, 1)
			try_diffusealpha(p2_score, 1)
		elseif p1_dp > p2_dp then
			try_diffusealpha(p1_score, 1)
			try_diffusealpha(p2_score, 0.65)
		elseif p2_dp > p1_dp then
			try_diffusealpha(p1_score, 0.65)
			try_diffusealpha(p2_score, 1)
		end
	end,
}
