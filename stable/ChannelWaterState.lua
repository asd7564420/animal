ChannelWaterState = class(BaseStableState)

-- function ChannelWaterState:dispose()
	-- BaseStableState.dipose(self)
-- end

function ChannelWaterState:create(context)
	local v = ChannelWaterState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	-- printx(13,"ChannelWaterState:create",v,v.checkdFirstEnter)
	return v
end

function ChannelWaterState:getNextState()
	return self.context.shellGiftState
end

function ChannelWaterState:checkTransition()
	return self.nextState
end

function ChannelWaterState:getClassName()
	return "ChannelWaterState"
end

function ChannelWaterState:onExit()
	-- printx(13,"ChannelWaterState:onExit()")
	BaseStableState.onExit(self)
	self.nextState = nil
end

function ChannelWaterState:onEnter()
	-- printx(13,"ChannelWaterState:onEnter()-self.checkdFirstEnter",self.checkdFirstEnter)
	-- printx(13,"ChannelWaterState:onEnter()-self.checkdFirstEnter",self.checkdFirstEnter,debug.traceback())
	BaseStableState.onEnter(self)

	if not ChannelWaterLogic.isEnable() then
		-- skip
		self.nextState = self:getNextState()
		return
	end

	if not self.checkdFirstEnter then
		self.checkdFirstEnter = true
		ChannelWaterLogic.onStateFirstCheck()
	else
		if not ChannelWaterLogic.isNeedCheckWaterFlow() then
			-- skip
			self.nextState = self:getNextState()
			return
		end
	end
	
	self.nextState = nil
	ChannelWaterLogic.startWaterFlow(function()
		-- if false then
		-- 	FallingItemLogic:preUpdateHelpMap(self.mainLogic)
		-- end
		self.context.needLoopCheck = true
		self.mainLogic:setNeedCheckFalling()
		-- self.nextState = self.context.fallingMatchState
		self.nextState = self:getNextState()
	end)
end

function ChannelWaterState:update(dt)
	ChannelWaterLogic.tickWaterFlow()
end