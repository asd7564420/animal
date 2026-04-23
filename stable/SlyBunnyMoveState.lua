SlyBunnyMoveState = class(BaseStableState)

function SlyBunnyMoveState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function SlyBunnyMoveState:create(context)
	local v = SlyBunnyMoveState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function SlyBunnyMoveState:getNextState()
	return self.context.checkHedgehogCrazyState
end

function SlyBunnyMoveState:checkTransition()
	return self.nextState
end

function SlyBunnyMoveState:getClassName()
	return "SlyBunnyMoveState"
end

function SlyBunnyMoveState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil
end

function SlyBunnyMoveState:onEnter()
	BaseStableState.onEnter(self)
	local context = self

	-- 大循环后的模块真麻烦，使用道具也要走。记录触发步数，防止反复触发。
	if not self.mainLogic.lastSlyBunnyFleeingMoves 
		or self.mainLogic.realCostMoveWithoutBackProp <= self.mainLogic.lastSlyBunnyFleeingMoves then
		self:changeToNextState()
		return 
	end

	self.nextState = nil
	
	if SlyBunnyLogic:hasSlyBunnyOnBoard(self.mainLogic) then
		self.mainLogic.lastSlyBunnyFleeingMoves = self.mainLogic.realCostMoveWithoutBackProp
		self:_tryArrangeSlyBunnyMovements()
	else
		self:changeToNextState()
	end
end

function SlyBunnyMoveState:changeToNextState()
	self.nextState = self:getNextState()
end

--------------------------------------------------------------------------------------------
--									MOVE
--------------------------------------------------------------------------------------------
function SlyBunnyMoveState:_tryArrangeSlyBunnyMovements()
	local bunnyMovePlanList = SlyBunnyLogic:arrangeSlyBunnyMovements(self.mainLogic)
	if bunnyMovePlanList and #bunnyMovePlanList > 0 then
		self:_moveBunnies(bunnyMovePlanList)
	else
		self:changeToNextState()
	end
end

function SlyBunnyMoveState:_moveBunnies(bunnyMovePlanList)
	local function actionCallback()
		self:changeToNextState()
		self.context:onEnter()		--没有falling，强制调用来轮转state
		-- printx(11, "SlyBunnyMoveState, action callBack. nextState:", self.nextState)
	end

	local action = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItem_SlyBunny_Fleeing, 
			nil,
			nil,
			GamePlayConfig_MaxAction_time
			)
	action.bunnyMovePlanList = bunnyMovePlanList
	action.completeCallback = actionCallback
	self.mainLogic:addGlobalCoreAction(action)
end

