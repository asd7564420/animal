LastGamePlayContext = class()


local _instance = nil


function LastGamePlayContext:getInstance()
	if not _instance then
		_instance = LastGamePlayContext.new()
		_instance:init()
	end
	return _instance
end


function LastGamePlayContext:init()
	self.playId = 0
	self.levelId = 0
	self.levelInfo = {}
end


function LastGamePlayContext:reset()
	self.playId = 0
	self.levelId = 0
	self.levelInfo = {}
	self.playInfo = {}
end

function LastGamePlayContext:updateByContext( gamePlayContext )

	self:reset()
	
	self.playId = gamePlayContext.playId
	self.levelId = gamePlayContext.levelInfo.levelId
	self.levelInfo = gamePlayContext.levelInfo
	self.playInfo = gamePlayContext.playInfo
end