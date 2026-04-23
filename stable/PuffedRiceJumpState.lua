PuffedRiceJumpState = class(BaseStableState)

function PuffedRiceJumpState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function PuffedRiceJumpState:create(context)
	local v = PuffedRiceJumpState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function PuffedRiceJumpState:check()
	if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.puffedRiceJump] then
        return 0
    end

    return self:checkCanJump(true)
end

function PuffedRiceJumpState:checkCanJump(firstCheck)
    local allReadyPuffedRice = PuffedRiceLogic:getAllActivePuffedRiceInOrder(self.mainLogic)
    if #allReadyPuffedRice > 0 then
		return self:_checkOneJump(firstCheck,allReadyPuffedRice)
	else
		if firstCheck then
			return 0 
		else
			self:_exitState()
		end
	end
end


function PuffedRiceJumpState:_checkOneJump(firstCheck,allReadyPuffedRice)
	local map = PuffedRiceLogic:getPuffedRiceJumpMap(allReadyPuffedRice, self.mainLogic)
	if map then
		local function actionCallback()
			self:checkCanJump()
		end

		local action = GameBoardActionDataSet:createAs(
		        GameActionTargetType.kGameItemAction,
		        GameItemActionType.kItem_PuffedRice_JumpOnce, 
		        nil,
		        nil,
		        GamePlayConfig_MaxAction_time
		        )
		action.completeCallback = actionCallback
	    action.map = map
	    self.mainLogic:addDestroyAction(action)
		self.mainLogic:setNeedCheckFalling()

		if firstCheck then return 1 end
	else
		if firstCheck then 
			return 0 
		else
			self:_exitState()
		end
	end

end

function PuffedRiceJumpState:_exitState()
	PuffedRiceLogic:refreshAllBlockStateAfterPuffedRiceJump(self.mainLogic)
end

