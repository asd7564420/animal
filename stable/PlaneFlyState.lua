PlaneFlyState = class(BaseStableState)

function PlaneFlyState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function PlaneFlyState:create(context)
	local v = PlaneFlyState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function PlaneFlyState:getNextState()
	return self.context.furballSplitStateInLoop
end

function PlaneFlyState:checkTransition()
	return self.nextState
end

function PlaneFlyState:getClassName()
	return "PlaneFlyState"
end

function PlaneFlyState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil

	self.allPlaneFinishedFlying = false
	self.allActivePlane = nil
	self.flyingRound = 0
end

function PlaneFlyState:onEnter()
	BaseStableState.onEnter(self)
	local context = self

    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.planeFly] then
    	printx(0, '!skip')
		self:changeToNextState()
        return
    end

	self.nextState = nil

	self.allPlaneFinishedFlying = false		--大家都飞走了吗？
	self.allActivePlane = nil				--所有还能继续飞行的飞机
	
	self:startChecking()
end

function PlaneFlyState:changeToNextState()
	self.nextState = self:getNextState()
end

function PlaneFlyState:checkIfAllProcedureEnded()
	if self.allPlaneFinishedFlying then
		FallingItemLogic:preUpdateHelpMap(self.mainLogic)
		self.mainLogic:setNeedCheckFalling()

		self:changeToNextState()
	end
end

--------------------------------------------------------------------------------------------
--									天气良好，可以起飞
--------------------------------------------------------------------------------------------
--------- 检测起飞
function PlaneFlyState:startChecking()
	self.allActivePlane = PlaneLogic:pickAllActivePlane(self.mainLogic)
	if #self.allActivePlane == 0 then
		self:changeToNextState()
		return
	end

	self:playTakeOffAnimation()

	-- self.flyingRound = 0
	-- self:startOneFlyingRound(true)

	-- if not self.allPlaneFinishedFlying then
	-- 	--增加大循环轮循次数
	-- 	self.context.needLoopCheck = true
	-- end
end

-- 还有个起飞动画，唉
function PlaneFlyState:playTakeOffAnimation()
	-- printx(11, "==== playTakeOffAnimation")
	local function onAnimationFinished()
		-- printx(11, "==== playPlaneTakeOff === onAnimationFinished", debug.traceback())
		self:onTakeOffAnimationEnded()
	end

	self.takeOffAnimationAmount = 0

	for _, activePlane in pairs(self.allActivePlane) do

		-- 起飞前，固定飞机防止下落
		activePlane.planeTookOff = true
		self.mainLogic:checkItemBlock(activePlane.y, activePlane.x)

		local eliminateChainDir = PlaneLogic:getDecChainDirByPlaneDir(activePlane.planeDirection)
		SpecialCoverLogic:specialCoverChainsAtPos(self.mainLogic, activePlane.y, activePlane.x, eliminateChainDir)

		local planeView = self.mainLogic.boardView:safeGetItemView(activePlane.y, activePlane.x)
		if planeView then
			self.takeOffAnimationAmount = self.takeOffAnimationAmount + 1
			planeView:playPlaneTakeOff(activePlane.planeDirection, onAnimationFinished)
		end
	end
end

function PlaneFlyState:onTakeOffAnimationEnded()
	-- printx(11, "==== onTakeOffAnimationEnded", self.takeOffAnimationAmount)
	self.takeOffAnimationAmount = self.takeOffAnimationAmount - 1

	self.context.needLoopCheck = true  --有起飞就增加大循环轮循次数

	if self.takeOffAnimationAmount == 0 then
		-- printx(11, "OKAY, start flying!!!!!!!!")

		self.flyingRound = 0
		self:startOneFlyingRound(true)

		-- if not self.allPlaneFinishedFlying then
		-- 	--增加大循环轮循次数
		-- 	printx(11, "==================== ADD needLoopCheck by Plane !!!! =======================")
		-- 	self.context.needLoopCheck = true
		-- end
	end
end

--------- 尝试向前进方向飞一格
function PlaneFlyState:startOneFlyingRound(isFirstRound)
	self.planeInFlyingAmount = 0

	local hasFlyingPlane = false
	if #self.allActivePlane > 0 then
		local index = #self.allActivePlane
		while index > 0 do
			local plane = self.allActivePlane[index]
			local hasReachedEnd, nextR, nextC = PlaneLogic:getNextTargetGrid(self.mainLogic, plane, self.flyingRound)

			if nextR and nextC and nextR > 0 and nextR < 10 and nextC > 0 and nextC < 10 then
				self:onPlaneFlyOneGrid(plane, nextR, nextC, hasReachedEnd)
				hasFlyingPlane = true
			else
				-- 没格子可飞，原地播消失动画，销毁飞机数据
				local planeView = self.mainLogic.boardView:safeGetItemView(plane.y, plane.x)
				if planeView then
					planeView:playPlaneVanish(plane.planeDirection, plane.y, plane.x)
				end
				PlaneLogic:onPlaneDestroyed(self.mainLogic, plane)
			end

			if hasReachedEnd then
				--没有格子或者被挡住了
				table.remove(self.allActivePlane, index)
			end

			index = index - 1
		end
	end

	self.flyingRound = self.flyingRound + 1

	if not hasFlyingPlane then
		self.allPlaneFinishedFlying = true
		-- if isFirstRound then
		-- 	--- 没有逻辑执行的情况下设置 setNeedCheckFalling 可能会导致进入end state后卡死的问题，
		-- 	--- 所以直接切换 state
		-- 	self:changeToNextState()
		-- else
			self:checkIfAllProcedureEnded()
		-- end
	end
end

--------- 飞一格
function PlaneFlyState:onPlaneFlyOneGrid(plane, nextR, nextC, hasReachedEnd)
	self.planeInFlyingAmount = self.planeInFlyingAmount + 1

	local function actionCallback()
        self:onOnePlaneArrivedNextGrid()
    end

	local currAction = GameBoardActionDataSet:createAs(
							 		GameActionTargetType.kGameItemAction,
							 		GameItemActionType.kItem_Plane_Fly_To_Grid,
							 		IntCoord:create(plane.x, plane.y),
							 		IntCoord:create(nextR, nextC),
							 		GamePlayConfig_MaxAction_time)
	-- printx(11, "plane fly. ".."("..nextR..","..nextC..")".." ReachEnd?", hasReachedEnd)
	currAction.targetPlane = plane
	currAction.nextR = nextR
	currAction.nextC = nextC
	currAction.hasReachedEnd = hasReachedEnd
	currAction.completeCallback = actionCallback
	
	self.mainLogic:addDestroyAction(currAction)
	self.mainLogic:setNeedCheckFalling()
end

function PlaneFlyState:onOnePlaneArrivedNextGrid()
	self.planeInFlyingAmount = self.planeInFlyingAmount - 1

	-- if plane and hasReachedEnd then
	-- 	PlaneLogic:onPlaneDestroyed(mainLogic, plane)
	-- end

	if self.planeInFlyingAmount == 0 then
		--本轮结束，开始下一轮
		self:startOneFlyingRound()
	end
end
