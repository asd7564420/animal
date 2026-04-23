WalkChickWalkState = class(BaseStableState)

function WalkChickWalkState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function WalkChickWalkState:create(context)
	local v = WalkChickWalkState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function WalkChickWalkState:check()
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.walkChickWalk] then
        return 0
    end

	local chickCanMove = false

    if BridgeCrossLogic:chickHasReachedEnd(self.mainLogic, true) then
        -- printx(15,"鸡到终点了")
        self:onReachEnd(true)
	else
        if BridgeCrossLogic:isBoardAheadWalkChick(self.mainLogic) then
            -- printx(15,"鸡前方有木板，可以移动")
            chickCanMove = true
        end
	end

	if chickCanMove then
        -- printx( 11, "====================== ~~~ =====================")
        -- printx( 11, "====================== ~~~ =====================")
        -- printx( 11, "====================== ~~~ =====================")
        -- printx( -1, "---->>>> WalkChickWalkState enter: check")
		return self:_startCheckOneAction(true)
	else
		return 0
	end
end

function WalkChickWalkState:_exitWalkingState()
    -- printx( -1, "---->>>> WalkChickWalkState exit")
    -- printx( 11, "______________________ xxx _____________________")
    -- printx( 11, "______________________ xxx _____________________")
    -- printx( 11, "______________________ xxx _____________________")
    BridgeCrossLogic:refreshAllBlockStateAfterChickWalk(self.mainLogic)
    FallingItemLogic:preUpdateHelpMap(self.mainLogic)
    self.mainLogic:setNeedCheckFalling()
end

-- 检测一次行动，移动或攻击
function WalkChickWalkState:_startCheckOneAction(initCheck)
    -- printx(11, "WalkChickWalkState, _startCheckOneAction")
    local walkChick = BridgeCrossLogic:getChickOnBoard(self.mainLogic)
    if not walkChick then
        return 0
    end

    local isWalkAction = false

    local nextItem
    if walkChick and walkChick:isVisibleAndFree() then 
        local canExchange,item = BridgeCrossLogic:_isExchangeableItemForWalkChick(self.mainLogic,walkChick)
        if canExchange and item then
            isWalkAction = true
            nextItem = item
        end
    end
    -- printx(11, "=== isWalkAction, isAttackAction, attackTimes", isWalkAction, isAttackAction, attackTimes)

    if isWalkAction and nextItem then
        if isWalkAction then
            self:_onChickStartWalking(walkChick, nextItem)
        end

        if initCheck then
            return 1
        end
    else
        if initCheck then
            return 0
        else
            self:_exitWalkingState()
        end
    end
end

function WalkChickWalkState:onReachEnd(skipExitState)
    -- printx(11, "~~~~~~ WalkChickWalkState:onReachEnd", self.mainLogic.level, self.mainLogic.PlayUIDelegate.levelId, debug.traceback())

    self.mainLogic.walkChickReachedEndFlag = true 

    BridgeCrossLogic:onWalkChickReachBridgeEnd(self.mainLogic)

    if not skipExitState then
        self:_exitWalkingState()
    end
end

function WalkChickWalkState:_onChickStartWalking(walkChick, nextItem)
    local lastItemPos = ccp(walkChick.x, walkChick.y)

    local function actionCallback()
        self:_onOneActionEnded(lastItemPos)
    end

    local chickWalkAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Walk_Chick_Walk,
        IntCoord:create(walkChick.x, walkChick.y),
        IntCoord:create(nextItem.x, nextItem.y),
        GamePlayConfig_MaxAction_time)
    -- printx(11, "hero walk. hero, target:".."("..hero.y..","..hero.x..") , ("..nextItem.y..","..nextItem.x..")")
    chickWalkAction.walkChick = walkChick
    chickWalkAction.nextItem = nextItem
    chickWalkAction.completeCallback = actionCallback
    
    self.mainLogic:addDestroyAction(chickWalkAction)
    self.mainLogic:setNeedCheckFalling()
end

function WalkChickWalkState:_onOneActionEnded(lastItemPos)
    -- printx(11, "=== _onOneActionEnded, curr Energy, maxAttackTimes:", self.mainLogic.travelEnergy, self.maxAttackTimes)
    -- printx(11, "=== _onOneActionEnded, currMapTravelRouteLength, currMapTravelStep:", self.mainLogic.currMapTravelRouteLength, self.mainLogic.currMapTravelStep)
    if BridgeCrossLogic:chickHasReachedEnd(self.mainLogic, true) then
        self:onReachEnd()
    else
        if BridgeCrossLogic:isBoardAheadWalkChick(self.mainLogic) then
            --本轮结束，开始下一轮
            self:_startCheckOneAction()
        else
            self:_exitWalkingState()
        end
    end
end