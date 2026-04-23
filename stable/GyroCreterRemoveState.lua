GyroCreterRemoveState = class(BaseStableState)

function GyroCreterRemoveState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function GyroCreterRemoveState:create(context)
	local v = GyroCreterRemoveState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function GyroCreterRemoveState:getNextState()
	return self.context.NDBunnyLeaveState
end

function GyroCreterRemoveState:checkTransition()
	-- printx(11, "GyroCreterRemoveState, checkTransition")
	return self.nextState
end

function GyroCreterRemoveState:getClassName()
	return "GyroCreterRemoveState"
end

function GyroCreterRemoveState:onExit()
	-- printx(11, "GyroCreterRemoveState onExit")
	BaseStableState.onExit(self)

	self.nextState = nil
end

function GyroCreterRemoveState:onEnter()
	BaseStableState.onEnter(self)
	local context = self

    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.gyroGenerate] then
    	printx(0, '!skip')
		self.nextState = self:getNextState()
        return
    end

	self.nextState = nil
	
	self:tryCheckRemove()
end

--------------------------------------------------------------------------------------------
--										出去走走
--------------------------------------------------------------------------------------------
function GyroCreterRemoveState:tryCheckRemove()
	local finalgenerateList = GyroLogic:gyroCreaterRemoveCheck(self.mainLogic)

    if #finalgenerateList > 0 then
		self.context.needLoopCheck = true	--
    	self:deleteGyroCreater(finalgenerateList)
    else
    	self.nextState = self:getNextState()
	end
end

function GyroCreterRemoveState:deleteGyroCreater( finalgenerateList )
	local function actionCallback()
		FallingItemLogic:preUpdateHelpMap(self.mainLogic)
		-- GyroLogic:updateCreaterProgressDisplay(self.mainLogic)
    	self.nextState = self:getNextState()
		-- printx(11, "GyroCreterRemoveState, action callBack. nextState:", self.nextState)
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_gyroCreater_delete, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
    action.finalgenerateList = table.clone(finalgenerateList)
    action.completeCallback = actionCallback
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end

