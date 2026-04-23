JamSperadMode = class(OrderMode)

--[[
function JamSperadMode:afterFail()
--    -- printx(11, "----------- = = = * * * afterFail * * * = = = -----------")
--    if _G.isLocalDevelopMode then printx(0, 'JamSperadMode:afterFail') end

    local mainLogic = self.mainLogic
    local Instance = self
    local function addStepSucessCall(isTryAgain, propId, deltaStep)   ----确认加5步之后，修改数据
        if isTryAgain then
            SnapshotManager:stop()
            Instance:getAddSteps(deltaStep or 5)
            Instance:addStepSucess()
        else
            if Instance:reachTarget() then
                Instance.leftMoveToWin = Instance.theCurMoves
                self.mainLogic:setGamePlayStatus(GamePlayStatus.kBonus)
            else
                mainLogic:setGamePlayStatus(GamePlayStatus.kFailed)
            end
        end
    end 

    if mainLogic.PlayUIDelegate then
        mainLogic.PlayUIDelegate:addStep(mainLogic.level, mainLogic.totalScore, self:getScoreStarLevel(), self:reachTarget(), addStepSucessCall )
    end
end

function JamSperadMode:addStepSucess()
    local mainLogic = self.mainLogic
    local Instance = self

    --赠送魔力鸟
    local buffs = {}
	table.insert( buffs , GameInitBuffLogic:createBuffData(InitBuffType.RANDOM_BIRD, InitBuffCreateType.DEFAULT) )
	local resultList = {}
	GameInitBuffLogic:__checkMapAndFindCreatePosition( nil , buffs , resultList, true )

    if #resultList > 0 then

        local function completeCallback()
            mainLogic:setGamePlayStatus(GamePlayStatus.kNormal)
	        mainLogic.fsm:changeState(mainLogic.fsm.waitingState)
        end

        local visibleOrigin = Director:sharedDirector():getVisibleOrigin()
	    local visibleSize = CCDirector:sharedDirector():getVisibleSize()
	    local destYInWorldSpace = visibleOrigin.y + visibleSize.height / 2 + 100
	    local itemIndex = 0
	    local totalSelected = 1
	    local centerPosX = visibleOrigin.x + visibleSize.width / 2
	    local itemPadding = 190 - 10 * totalSelected

        local data = resultList[1]

        local itemData = {}
	    itemData.id = ItemType:getRealIdByTimePropId( ItemType.RANDOM_BIRD )
    --    itemData.destXInWorldSpace = centerPosX + (itemIndex - (totalSelected+1) / 2) * itemPadding
	    itemData.destXInWorldSpace = centerPosX
	    itemData.destYInWorldSpace = destYInWorldSpace

        local action = nil
        action =  GameBoardActionDataSet:createAs(
			    GameActionTargetType.kPropsAction,
			    GameItemActionType.kAddBuffSpecialAnimal,
			    nil,
			    nil,
			    GamePlayConfig_MaxAction_time)
	    action.pos = {r = data.r, c = data.c}
	    action.tarItemColorType = 0
	    action.tarItemSpecialType = data.tarItemSpecialType
	    action.fromGuide = false
	    action.buffType = data.buffType

	    action.data = itemData
    	action.completeCallback = completeCallback
	    mainLogic:addGlobalCoreAction(action)

        mainLogic:preGameProp(itemData.id)
    end
end
--]]