local t = {}

local function isInLobby()
	local handler = GetOnlineHandlerInstance()
	return handler and handler.inLobby and handler.lobbyCode
end

local function shouldShowBanner()
	return ThemePrefs.Get("RequireLobbies") and not isInLobby()
end

local function makeActor()
	return Def.ActorFrame{
		ModuleCommand=function(self)
			self:visible(shouldShowBanner())
		end,
		OnlineLobbyStateMessageCommand=function(self)
			self:visible(shouldShowBanner())
		end,
		OnlineLobbyLeftMessageCommand=function(self)
			self:visible(shouldShowBanner())
		end,
		DisconnectOnlineMessageCommand=function(self)
			self:visible(shouldShowBanner())
		end,

		Def.Quad{
			InitCommand=function(self)
				self:zoomto(_screen.w, 32):xy(_screen.cx, _screen.cy - 15):diffuse(0, 0, 0, 1)
			end,
		},
		LoadFont("Common Normal")..{
			InitCommand=function(self)
				self:settext("Connect to an online lobby to play.")
				self:xy(_screen.cx, _screen.cy - 15):zoom(SL_WideScale(0.5, 0.6))
			end,
		},
	}
end

local screens = {
	"ScreenSelectMusic",
	"ScreenPlayerOptions",
	"ScreenPlayerOptions2",
	"ScreenPlayerOptions3",
	"ScreenGameplay",
	"ScreenEvaluationStage",
}

for _, screen in ipairs(screens) do
	t[screen] = makeActor()
end

return t
