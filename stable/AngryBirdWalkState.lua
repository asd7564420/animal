AngryBirdWalkState = class(BaseStableState)

function AngryBirdWalkState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function AngryBirdWalkState:create(context)
	local v = AngryBirdWalkState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function AngryBirdWalkState:check()
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.angryBirdWalk] then
        return 0
    end

    self.totalAction = self:checkBirdsCanMove()
    self.completeAction = 0
	return self.totalAction --walk or jump
end

function AngryBirdWalkState:checkBirdsCanMove( ... )
    local birds = AngryBirdLogic:getAngryBirdOnBoard(self.mainLogic)
    local birdsCanMove = 0
    if #birds > 0 then
        self.mainLogic.angryBirdNum = #birds
        for i = 1 , #birds do
            local bird = birds[i]
            local canJump,sling = self:checkSlingState(bird)
            if canJump and sling then
                birdsCanMove = birdsCanMove + 1
                self:_startJumpAction(bird,sling)
            elseif bird.birdEnergy > 0 then
                -- printx(15,"i,bird.birdEnergy",i,bird.birdEnergy)
                birdsCanMove = birdsCanMove + 1
                self:_startCheckOneAction(true,bird)
            end
        end
    end

    -- printx(15,"self.mainLogic.angryBirdNum",self.mainLogic.angryBirdNum)

    return birdsCanMove
end

function AngryBirdWalkState:_exitWalkingState()
    self.completeAction = self.completeAction + 1
    if self.completeAction == self.totalAction then
        self:realExit()
    end
end

function AngryBirdWalkState:realExit( ... )
    FallingItemLogic:preUpdateHelpMap(self.mainLogic)
    self.mainLogic:setNeedCheckFalling()
end

function AngryBirdWalkState:checkSlingState( bird )
    local canJump = false
    local row = bird.y
    local col = bird.x
    local dx = { 0, 1, 0, -1 }
    local dy = { 1, 0, -1, 0 }
    local targetSling
    local board = self.mainLogic.boardmap[row][col]
    if not board.isBirdRoadEnd or bird.birdEnergy == 0 then --不在弹弓附近或鸟没有能量
        --false
        -- printx(15,"不在弹弓附近或鸟没有能量")
    else
        -- bird.birdEnergy = 0 --在路径终点也有可能不会立即发射，但是把能量清0 防止进入走路的action
        --出尔反尔的产品：如果鸟在终点但没有能量，不会发射
        local slings = {}
        for i = 1 , 4 do
            local r = row + dx[i]
            local c = col + dy[i]
            if self.mainLogic:isPosValid(r, c) then
                local item = self.mainLogic.gameItemMap[r][c]
                if item.ItemType == GameItemType.kSling then
                    -- printx(15,"------------------find sling-----------------",r,c)
                    -- table.insert(slings,item)
                    local birdRoadType = board.birdRoadType
                    -- printx(15,"i,birdRoadType",i,birdRoadType)
                    local sling = item
                    if sling.readyToShot then
                        if (birdRoadType == 2 and i == 2) or (birdRoadType == 1 and i == 4)
                            or (birdRoadType == 4 and i == 1) or (birdRoadType == 3 and i == 3) then
                            sling.readyToShot = false
                            canJump = true
                            targetSling = sling
                            break
                        end
                    end
                end
            end
        end

        if not targetSling then
            printx(15,"有问题，在终点找不到弹弓")
        end
    end

    return canJump,targetSling

end

function AngryBirdWalkState:getBirdName( birdType )
    if birdType == 1 then
        return "hongniao"
    elseif birdType == 2 then
        return "lanniao"
    else
        return "heiniao"
    end
end

function AngryBirdWalkState:_startJumpAction( bird, sling )
    -- printx(15,"_startJumpAction")
    local function actionCallback()
        self:_exitWalkingState()
    end

    local angryBirdShotAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Angry_Bird_Shot,
        IntCoord:create(bird.x, bird.y),
        IntCoord:create(sling.x, sling.y),
        GamePlayConfig_MaxAction_time)
    
    angryBirdShotAction.angryBird = bird
    angryBirdShotAction.sling = sling
    angryBirdShotAction.completeCallback = actionCallback
    angryBirdShotAction.birdType = bird.birdType
    angryBirdShotAction.birdName = self:getBirdName(bird.birdType) 
  
    self.mainLogic:addDestroyAction(angryBirdShotAction)
    self.mainLogic:setNeedCheckFalling()
end

-- 检测一次移动
function AngryBirdWalkState:_startCheckOneAction(initCheck,item)
    -- printx(15, "AngryBirdWalkState, _startCheckOneAction")
    -- local birds = AngryBirdLogic:getAngryBirdOnBoard(self.mainLogic)
    if not item or item.birdEnergy == 0 then
        -- TravelLogic:clearTravelEnergy()
        self:_exitWalkingState()
        return 0
    end

    local isWalkAction = false
    local isAttackAction = false
    local isAttackChain = false
    -- local nextRow, nextCol
    local walkSteps = item.birdEnergy
    local nextItemList = {}
    if item and item:isVisibleAndFree() and item.birdEnergy and item.birdEnergy > 0 then 
        isWalkAction = true
        local tempItem = item
        for i = 1 , walkSteps do
            local nextItemData = AngryBirdLogic:checkNextGridInteractType(tempItem)
            if not nextItemData or nextItemData.ItemType == GameItemType.kSling then
                break
            end
            table.insert(nextItemList,nextItemData)
            tempItem = nextItemData
        end


    end
    -- printx(11, "=== isWalkAction, isAttackAction, attackTimes", isWalkAction, isAttackAction, attackTimes)

    if isWalkAction and #nextItemList > 0 then
        if isWalkAction then
            self:_onBirdStartWalking(item, nextItemList)
        -- elseif isAttackAction then
        --     self:_onHeroStartAttacking(hero, nextItem, isAttackChain)
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

function AngryBirdWalkState:_onBirdStartWalking(item, nextItemList)
    local lastItemPos = ccp(item.x, item.y)

    local function actionCallback()
        self:_onOneActionEnded(lastItemPos)
    end

    local angryBirdWalkAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Angry_Bird_Walk,
        IntCoord:create(item.x, item.y),
        IntCoord:create(nextItemList[1].x, nextItemList[1].y),
        GamePlayConfig_MaxAction_time)
    -- printx(11, "hero walk. hero, target:".."("..hero.y..","..hero.x..") , ("..nextItem.y..","..nextItem.x..")")
    angryBirdWalkAction.angryBird = item
    angryBirdWalkAction.nextItemList = nextItemList
    angryBirdWalkAction.completeCallback = actionCallback
    angryBirdWalkAction.walkSteps = #nextItemList
    angryBirdWalkAction.currentMove = 0
    angryBirdWalkAction.birdType = item.birdType
    angryBirdWalkAction.birdName = self:getBirdName(item.birdType) 

    --direction 1,2,3,4 上右下左 对应鱿鱼对冰柱绳子的处理
    local forwardDirectionList = {}
    for i = 1, item.birdEnergy do
        local forwardDirection
        local item2 = nextItemList[i]
        local item1
        if i == 1 then
            item1 = item
        else
            item1 = nextItemList[i-1]
        end
        if item2 then

            if item1.x == item2.x and item2.y - item1.y == -1 then
                forwardDirection = 1
            elseif item1.x == item2.x and item1.y - item2.y == -1 then
                forwardDirection = 3
            elseif item1.y == item2.y and item2.x - item1.x == 1 then
                forwardDirection = 2
            elseif item1.y == item2.y and item1.x - item2.x == 1 then
                forwardDirection = 4
            else
                -- printx(15,"forwardDirection error!!!!!!!!")
            end
            -- printx(15,"forwardDirection",forwardDirection)
            table.insert(forwardDirectionList,forwardDirection)
        end
    end
    -- printx(15,"forwardDirectionList",table.tostring(forwardDirectionList))

    angryBirdWalkAction.forwardDirectionList = forwardDirectionList

    --出尔反尔的产品：这里不能简单的将能量清0，如果小鸟走到路径终点且没有消耗所有的能量，在下一次进入state要jump
    -- item.birdEnergy = 0
    item.birdEnergy = math.max(0,item.birdEnergy - #nextItemList)
    -- printx(15,"item.birdEnergy",item.birdEnergy)
    angryBirdWalkAction.birdEnergy = item.birdEnergy

    self.mainLogic:addDestroyAction(angryBirdWalkAction)
    self.mainLogic:setNeedCheckFalling()
    -- if self.mainLogic.currMapTravelStep then
    --     self.mainLogic.currMapTravelStep = self.mainLogic.currMapTravelStep + 1
    -- end
end

function AngryBirdWalkState:_onOneActionEnded(lastItemPos)
    self:_exitWalkingState()
end