FireworkLogic = class{}

function FireworkLogic:triggerOneFirework( mainLogic, item )
    if not mainLogic then
        mainLogic = GameBoardLogic:getCurrentLogic()
    end

    if not mainLogic or not item or not item.fireworkLevel or item.fireworkLevel == 0 then
        return
    end

    if not item.triggerBySameGroup then
        item.fireworkLevel = item.fireworkLevel - 1
    end

    if item.fireworkLevel == 0 or item.triggerBySameGroup then

        local function actionCallback()
            item.fireworkFinished = true
            -- item.isNeedUpdate = true
            --printx(15,"结束了一个action,位置为：",item.y,item.x)
            local boardData = mainLogic:safeGetBoardData(item.y,item.x)
            if boardData then
                self:endOnceAction(boardData)
            end
        end

        local levelBeforeTrigger = 0

        if item.triggerBySameGroup then
            item.triggerBySameGroup = false
            levelBeforeTrigger = item.fireworkLevel
            item.fireworkLevel = 0
        end

        if not mainLogic.fireworkBoomList then
            mainLogic.fireworkBoomList = {}
        end

        local boardData = mainLogic:safeGetBoardData(item.y, item.x)
        if boardData and boardData.pathConfigs and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] then
            local pathId = boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId
            if not table.includes(mainLogic.fireworkBoomList,pathId) then
                table.insert(mainLogic.fireworkBoomList,pathId)
            end
        end

        local fireworkTriggerAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kFirework_Trigger,
        IntCoord:create(item.x, item.y),
        nil,
        GamePlayConfig_MaxAction_time)
    
        fireworkTriggerAction.completeCallback = actionCallback
        fireworkTriggerAction.firework = item
        fireworkTriggerAction.levelBeforeTrigger = levelBeforeTrigger
      
        mainLogic:addDestroyAction(fireworkTriggerAction)

        mainLogic:tryDoOrderList(item.y, item.x, GameItemOrderType.kOthers, GameItemOrderType_Others.kFirework, 1)

        mainLogic:addScoreToTotal(item.y, item.x, GamePlayConfigScore.Firework)

        mainLogic:setNeedCheckFalling()
    else
        local function actionCallback()

        end

        if not mainLogic.fireworkBoomList or #mainLogic.fireworkBoomList == 0 then
            -- printx(15,"==========================")
            GamePlayMusicPlayer:playEffect(GameMusicType.kFireworkGrow)
        end

        local fireworkDecAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kFirework_Dec_Level,
        IntCoord:create(item.x, item.y),
        nil,
        GamePlayConfig_MaxAction_time)
    
        fireworkDecAction.completeCallback = actionCallback
        fireworkDecAction.firework = item
      
        mainLogic:addDestroyAction(fireworkDecAction)
        mainLogic:setNeedCheckFalling()
    end
end

local function getNextGrid(currR, currC)
    local mainLogic = GameBoardLogic:getCurrentLogic()
    local currGridData = mainLogic:safeGetBoardData(currR, currC)
    if mainLogic and currGridData and currGridData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] 
        and not currGridData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].isRoadEnd then

        local roadType = currGridData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].roadType

        if roadType == RouteConst.kUp then
            return true, currR - 1, currC
        elseif roadType == RouteConst.kDown then
            return true, currR + 1, currC
        elseif roadType == RouteConst.kLeft then
            return true, currR, currC - 1
        elseif roadType == RouteConst.kRight then
            return true, currR, currC + 1
        end
    end

    return false

end

function FireworkLogic:checkRoadState( pathId )
    -- printx(15,"检查鞭炮",pathId)
    local mainLogic = GameBoardLogic:getCurrentLogic()

    if not mainLogic or not pathId then
        return
    end

    local startR = -1
    local startC = -1

    for r = 1, #mainLogic.gameItemMap do
        for c = 1, #mainLogic.gameItemMap[r] do
            local boardData = mainLogic:safeGetBoardData(r, c)
            if boardData and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] 
                and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].isRoadStart 
                and pathId == boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId then
                
                local itemData = mainLogic.gameItemMap[r][c]
                if itemData.fireworkLevel == 0 and itemData.fireworkFinished then
                    --printx(15,"头部炸完了:",r,c)
                    startR = r
                    startC = c
                else
                    --printx(15,"头部还没炸",itemData.y,itemData.x,itemData.fireworkLevel)
                    return false
                end
                break
            end
        end
    end

    local haveNextGrid = false

    local currR = startR
    local currC = startC

    for i = 1, 99 do
        local itemData = mainLogic:safeGetItemData(currR,currC)
        if itemData and itemData.ItemType == GameItemType.kFirework and itemData.fireworkFinished then
            local boardData = mainLogic:safeGetBoardData(currR, currC)
            if boardData and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] 
                and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].isRoadEnd then
                --printx(15,"整个鞭炮都触发了，开始清除数据")
                return true, startR, startC
            else
                --printx(15,"已触发：",currR, currC)
            end
        else
            --printx(15,"还没有触发，位置:",currR,currC)
            return false
        end

        haveNextGrid,currR,currC = getNextGrid(currR,currC)

        if not haveNextGrid then
            -- printx(15,"到终点了")
            break
        end
    end

end

function FireworkLogic:clearFireworkData( startR, startC )
    -- printx(15,"清除鞭炮数据")
    local mainLogic = GameBoardLogic:getCurrentLogic()

    local r = startR
    local c = startC
    local haveNextGrid = true

    for i = 1, 99 do
        local itemData = mainLogic:safeGetItemData(r,c)

        if itemData and itemData.ItemType == GameItemType.kFirework and itemData.fireworkFinished then
            -- printx(15,"清除位置：",r,c)
            itemData:cleanAnimalLikeData()
            itemData.isNeedUpdate = true
            mainLogic:checkItemBlock(r, c)
        else
            -- printx(15,"状态不对或者已经是终点后面的一格了，位置:",r,c)
        end

        haveNextGrid,r,c = getNextGrid(r,c)

        -- --先取到下一格子的信息才能删除board的数据
        -- local boardData = mainLogic:safeGetBoardData(r,c)
        -- if boardData and boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] then
        --     boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] = nil
        -- end

        if not haveNextGrid then
            -- printx(15,"到终点了")
            break
        end
    end

    mainLogic:setNeedCheckFalling()
end

function FireworkLogic:handleFireworkBoomList( boardData )
    if boardData and boardData.pathConfigs then
        local pathId = boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId
        local mainLogic = GameBoardLogic:getCurrentLogic()
        --printx(15,"mainLogic.fireworkBoomList_before",table.tostring(mainLogic.fireworkBoomList))
        if mainLogic and mainLogic.fireworkBoomList then
            table.removeValue(mainLogic.fireworkBoomList, pathId)
        end
        --printx(15,"mainLogic.fireworkBoomList_after",table.tostring(mainLogic.fireworkBoomList))
    end
end

function FireworkLogic:endOnceAction(boardData)
    
    local needClearData = false
    local startR = -1
    local startC = -1

    if boardData then
        needClearData, startR, startC = self:checkRoadState(boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId)
    end

    if needClearData then
        self:handleFireworkBoomList(boardData)
        self:clearFireworkData(startR, startC)
    end

end