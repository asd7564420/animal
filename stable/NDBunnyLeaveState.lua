NDBunnyLeaveState = class(BaseStableState)

function NDBunnyLeaveState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function NDBunnyLeaveState:create(context)
	local v = NDBunnyLeaveState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function NDBunnyLeaveState:getNextState()
	return self.context.NDBunnyProduceState
end

function NDBunnyLeaveState:getClassName()
	return "NDBunnyLeaveState"
end

function NDBunnyLeaveState:checkTransition()
    return self.nextState
end

function NDBunnyLeaveState:onExit()
	BaseStableState.onExit(self)

	self.nextState = nil
end

function NDBunnyLeaveState:onEnter()
	BaseStableState.onEnter(self)
	local context = self
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.NDBunnyHandle] then
    	printx(0, '!skip')
		self:changeToNextState()
        return
    end

	self.nextState = nil
	self:_tryLeaveNDBunny()
end

function NDBunnyLeaveState:_tryLeaveNDBunny()
	local toLeaveBunny = NationalDayBunnyLogic:getAllToLeaveNDBunny(self.mainLogic)
	if #toLeaveBunny > 0 then
		self:_leaveNDBunny(toLeaveBunny)
	else
		self:changeToNextState()
    end
end

function NDBunnyLeaveState:_leaveNDBunny(toLeaveBunny)
	local function actionCallback()
		self.mainLogic.bunnyLeaveFlag = true
    	self:changeToNextState()
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_NDBunny_leave, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
    action.toLeaveBunny = toLeaveBunny
    action.completeCallback = actionCallback
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end

function NDBunnyLeaveState:changeToNextState()
	self.nextState = self:getNextState()
end