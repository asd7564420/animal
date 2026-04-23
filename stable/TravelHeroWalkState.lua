TravelHeroWalkState = class(BaseStableState)

function TravelHeroWalkState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function TravelHeroWalkState:create(context)
	local v = TravelHeroWalkState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function TravelHeroWalkState:check()
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.travelHeroWalk] then
        return 0
    end

    -- 因为需要等待某些被攻击的对象等到自己的state处理后续逻辑，所以暂时略过行进检测
    if self.mainLogic.skipTravelStateType and self.mainLogic.skipTravelStateType > 0 then
        return 0
    end

    self.maxAttackTimes = nil
	local heroCanStartMoving = false

    if TravelLogic:heroHasReachedEnd(self.mainLogic, nil, true) then
        self:onReachEnd(true)
	else
        if self.mainLogic.travelEnergy and self.mainLogic.travelEnergy > 0 then
            heroCanStartMoving = true
        end
	end

	if heroCanStartMoving then
        -- printx( 11, "====================== ~~~ =====================")
        -- printx( 11, "====================== ~~~ =====================")
        -- printx( 11, "====================== ~~~ =====================")
        printx( -1, "---->>>> TravelHeroWalkState enter: check")
		return self:_startCheckOneAction(true)
	else
		return 0
	end
end

function TravelHeroWalkState:_exitWalkingState()
    printx( -1, "---->>>> TravelHeroWalkState exit")
    -- printx( 11, "______________________ xxx _____________________")
    -- printx( 11, "______________________ xxx _____________________")
    -- printx( 11, "______________________ xxx _____________________")
    TravelLogic:refreshAllBlockStateAfterHeroWalk(self.mainLogic)
    FallingItemLogic:preUpdateHelpMap(self.mainLogic)
    self.mainLogic:setNeedCheckFalling()
end

-- 检测一次行动，移动或攻击
function TravelHeroWalkState:_startCheckOneAction(initCheck)
    -- printx(11, "TravelHeroWalkState, _startCheckOneAction")
    local hero = TravelLogic:getHeroOnBoard(self.mainLogic)
    if not hero then
        TravelLogic:clearTravelEnergy()
        return 0
    end

    local isWalkAction = false
    local isAttackAction = false
    local isAttackChain = false
    -- local nextRow, nextCol
    local nextItem
    if hero and hero:isVisibleAndFree() and self.mainLogic.travelEnergy and self.mainLogic.travelEnergy > 0 then 
        local interactType, nextItemData, attackTimes, blockType = TravelLogic:checkNextGridInteractType(hero)
        if not interactType 
            or interactType == TravelInteractType.kNone
            or (interactType == TravelInteractType.kAttackBlocker and attackTimes == 0) 
            then
            -- 前路无法交互，清空能量
            TravelLogic:clearTravelEnergy()
        else
            if interactType == TravelInteractType.kWalk then
                isWalkAction = true
            elseif interactType == TravelInteractType.kEventBox then
                -- 删除礼盒的数据占位，置可触发标记，创建假视图(?)
                local boardData = self.mainLogic:safeGetBoardData(nextItemData.y, nextItemData.x)
                if boardData then
                    boardData.needTriggerTravelEvent = true
                end

                -- nextItemData:cleanAnimalLikeData()
                -- nextItemData.isNeedUpdate = true
                -- nextItemData.isUsed = false
                -- mainLogic:checkItemBlock(nextItemData.y, nextItemData.x)

                if self.mainLogic.boardView.baseMap[nextItemData.y] then
                    local gridView = self.mainLogic.boardView.baseMap[nextItemData.y][nextItemData.x]
                    if gridView then
                        gridView:hideTravelEventBoxView()
                        gridView:playOpenDummyTravelEventBox()

                        local startPos = self.mainLogic:getGameItemPosInView(nextItemData.y, nextItemData.x)
                        TravelLogic:playSingleAnimationOnGrid(startPos, "travelStartBurstEffect")
                    end
                end

                isWalkAction = true

            elseif interactType == TravelInteractType.kAttackBlocker or interactType == TravelInteractType.kAttackChain then
                if not self.maxAttackTimes then
                    self.maxAttackTimes = attackTimes
                end
                isAttackAction = true
                if interactType == TravelInteractType.kAttackChain then
                    isAttackChain = true
                end
                if blockType and blockType > 0 then
                    self.mainLogic.skipTravelStateType = blockType
                end
            end
            nextItem = nextItemData
        end
    end
    -- printx(11, "=== isWalkAction, isAttackAction, attackTimes", isWalkAction, isAttackAction, attackTimes)

    if (isWalkAction or isAttackAction) and nextItem then
        if isWalkAction then
            self:_onHeroStartWalking(hero, nextItem)
        elseif isAttackAction then
            self:_onHeroStartAttacking(hero, nextItem, isAttackChain)
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

function TravelHeroWalkState:onReachEnd(skipExitState)
    -- printx(11, "~~~~~~ TravelHeroWalkState:onReachEnd", self.mainLogic.level, self.mainLogic.PlayUIDelegate.levelId, debug.traceback())
    TravelLogic:clearTravelEnergy()

    if TravelLogic:isFinalMap(self.mainLogic) then
        self.mainLogic.travelHeroReachedEndFlag = true --谜之虽然成功了，但是判断为失败，只能试试简单粗暴了
        TravelLogic:onHeroReachFinalBuilding(self.mainLogic)
    else
        local nextLevelID = TravelLogic:getNextMapLevelID(self.mainLogic)
        -- nextLevelID = self.mainLogic.level + 1 -- for test use!!!!!!
        if nextLevelID and nextLevelID > 0 then
            self.mainLogic.nextBoardLevelID = nextLevelID
            TravelLogic:onHeroReachFinalBuilding(self.mainLogic)
        end  
    end

    if not skipExitState then
        self:_exitWalkingState()
    end
end

function TravelHeroWalkState:_onHeroStartWalking(hero, nextItem)
    local lastItemPos = ccp(hero.x, hero.y)

    local function actionCallback()
        self:_onOneActionEnded(lastItemPos)
    end

    local heroWalkAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Travel_Hero_Walk,
        IntCoord:create(hero.x, hero.y),
        IntCoord:create(nextItem.x, nextItem.y),
        GamePlayConfig_MaxAction_time)
    -- printx(11, "hero walk. hero, target:".."("..hero.y..","..hero.x..") , ("..nextItem.y..","..nextItem.x..")")
    heroWalkAction.hero = hero
    heroWalkAction.nextItem = nextItem
    heroWalkAction.completeCallback = actionCallback
    
    self.mainLogic:addDestroyAction(heroWalkAction)
    self.mainLogic:setNeedCheckFalling()
    if self.mainLogic.currMapTravelStep then
        self.mainLogic.currMapTravelStep = self.mainLogic.currMapTravelStep + 1
    end
end

function TravelHeroWalkState:_onHeroStartAttacking(hero, nextItem, isAttackChain)
    local function actionCallback()
        self:_onOneActionEnded()
    end

    local heroAttackAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Travel_Hero_Attack,
        IntCoord:create(hero.x, hero.y),
        IntCoord:create(nextItem.x, nextItem.y),
        GamePlayConfig_MaxAction_time)
    -- printx(11, "hero attack. hero, target:".."("..hero.y..","..hero.x..") , ("..nextItem.y..","..nextItem.x..")")
    heroAttackAction.hero = hero
    heroAttackAction.nextItem = nextItem
    heroAttackAction.isAttackChain = isAttackChain
    heroAttackAction.completeCallback = actionCallback
    
    self.mainLogic:addDestroyAction(heroAttackAction)
    self.mainLogic:setNeedCheckFalling()
end

function TravelHeroWalkState:_onOneActionEnded(lastItemPos)
    TravelLogic:consumeTravelEnergy()
    if self.maxAttackTimes then
        self.maxAttackTimes = self.maxAttackTimes - 1
    end
    -- printx(11, "=== _onOneActionEnded, curr Energy, maxAttackTimes:", self.mainLogic.travelEnergy, self.maxAttackTimes)
    -- printx(11, "=== _onOneActionEnded, currMapTravelRouteLength, currMapTravelStep:", self.mainLogic.currMapTravelRouteLength, self.mainLogic.currMapTravelStep)

    if self:_isOnRouteEventTile() then
        self:_triggerTravelEvent(lastItemPos)
    elseif TravelLogic:heroHasReachedEnd(self.mainLogic, nil ,true) then
        self:onReachEnd()
    else
        if self.mainLogic.travelEnergy > 0 then
            --本轮结束，开始下一轮
            if not self.maxAttackTimes then
                self:_startCheckOneAction()
            else
                if self.maxAttackTimes > 0 then
                    self:_startCheckOneAction()
                else
                    -- 前物会因攻击被销毁，退出行进，执行掉落
                    self:_exitWalkingState()
                end
            end
        else
            self:_exitWalkingState()
        end
    end
end

function TravelHeroWalkState:_isOnRouteEventTile()
    -- printx(11, "CHECK: _isOnRouteEventTile")
    local hero = TravelLogic:getHeroOnBoard(self.mainLogic)
    if not hero then return false end

    local boardData = self.mainLogic:safeGetBoardData(hero.y, hero.x)
    if boardData and boardData:canTriggerTravelEvent() then
        return true
    end

    return false
end

function TravelHeroWalkState:_triggerTravelEvent(lastItemPos)
    local hero = TravelLogic:getHeroOnBoard(self.mainLogic)
    local eventType = TravelLogic:getRouteEventTypeOnTrigger(self.mainLogic)
    local eventGrid = {r = hero.y, c = hero.x}
    -- printx(11, "Trigger travel event! Type:", eventType, table.tostring(eventGrid))

    local targetGrids
    local eventActionType
    local middileGrid
    if eventType == TravelRouteEventType.kAddEnergyBag then
        local throwGrids = TravelLogic:getAddEnergyBagTargetGrids(self.mainLogic)
        if throwGrids and #throwGrids > 0 then
            targetGrids = throwGrids
            eventActionType = GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag
            -- printx(11, "throw energy bag grids:", table.tostring(throwGrids))
        end
    elseif eventType == TravelRouteEventType.kBombRoute then
        local routeGrids = TravelLogic:getRouteGrids(self.mainLogic)
        if routeGrids and #routeGrids > 0 then
            targetGrids = routeGrids
            eventActionType = GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Route
            -- printx(11, "bomb route grids:", table.tostring(routeGrids))
        end
    elseif eventType == TravelRouteEventType.kBombHeart then
        local heartGrids = TravelLogic:getHeartGridsToBomb(self.mainLogic, eventGrid)
        if heartGrids and #heartGrids > 0 then
            targetGrids = heartGrids
            eventActionType = GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Heart
            middileGrid = eventGrid
            -- printx(11, "bomb HEART grids:", table.tostring(heartGrids))
        end
    end

    local activityScore = 0
    local accessoryID = 0

    local travelData = TravelLogic:getTravelData(self.mainLogic)
    -- printx(11, "_triggerTravelEvent  travelData", table.tostring(travelData))
    if travelData then
        activityScore = travelData.scoreAmount
        accessoryID = travelData.accessoryID
    end

    if activityScore and activityScore > 0 then
        local contentAmount = 1
        local routeEventAction = GameBoardActionDataSet:createAs(
            GameActionTargetType.kGameItemAction,
            GameItemActionType.kItem_Travel_Open_Event_Box,
            IntCoord:create(hero.x, hero.y),
            nil,
            GamePlayConfig_MaxAction_time)
        routeEventAction.activityScore = activityScore

        if accessoryID and accessoryID > 0 then
            routeEventAction.accessoryID = accessoryID
            contentAmount = contentAmount + 1
        end

        if targetGrids and eventActionType then
            routeEventAction.targetGrids = targetGrids
            routeEventAction.eventType = eventType
            routeEventAction.eventActionType = eventActionType
            routeEventAction.middileGrid = middileGrid

            contentAmount = contentAmount + 1
        end

        routeEventAction.contentAmount = contentAmount
        routeEventAction.hero = hero
        routeEventAction.eventBoxPos = lastItemPos
        self.mainLogic:addDestroyAction(routeEventAction)
        self.mainLogic:setNeedCheckFalling()

        local boardData = self.mainLogic:safeGetBoardData(hero.y, hero.x)
        if boardData then
            boardData.needTriggerTravelEvent = false
        end
        self.mainLogic.travelEventBoxOpened = true
    end

    self:_exitWalkingState()
end
