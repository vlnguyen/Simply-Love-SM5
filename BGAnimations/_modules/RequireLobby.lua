local function isInLobby()
	local handler = GetOnlineHandlerInstance()
	return handler and handler.inLobby and handler.lobbyCode
end

return Def.ActorFrame{
	InitCommand=function(self)
		self:visible(not isInLobby())
	end,
	OnlineLobbyStateMessageCommand=function(self)
		self:visible(not isInLobby())
	end,
	OnlineLobbyLeftMessageCommand=function(self)
		self:visible(true)
	end,
	DisconnectOnlineMessageCommand=function(self)
		self:visible(true)
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
