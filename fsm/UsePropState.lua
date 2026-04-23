require "zoo.gamePlay.fsm.GameState"

UsePropState = class(GameState)

function UsePropState:create(context)
	local v = UsePropState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	return v
end

function UsePropState:onEnter()
	self:setNextState(nil)
	GamePlayContext:getInstance():updateAIPropUsedIndex()
	
	printx( -1 , ">>>>>>>>>>>>>>>>>use prop state enter")
end

function UsePropState:onExit()
	self:setNextState(nil)
	printx( -1 , "<<<<<<<<<<<<<<<<<use prop state exit")
end

function UsePropState:setNextState(nxtSt)
	self.nextState = nxtSt
end

function UsePropState:update(dt)
	self:runPropActionList(self.mainLogic)
end

function UsePropState:checkTransition()
	return self.nextState
end

function UsePropState:runPropActionList(mainLogic)

	local maxIndex = table.maxn(mainLogic.propActionList)
	for i = 1 , maxIndex do
		local atc = mainLogic.propActionList[i]
		if atc then
			self:runGamePropsActionLogic(mainLogic, atc , i)
			self:runPropsActionView(mainLogic.boardView, atc)
		end
	end

	--[[
	for k, v in pairs(mainLogic.propActionList) do
		self:runGamePropsActionLogic(mainLogic, v, k)
		self:runPropsActionView(mainLogic.boardView, v)
	end
	]]
end

function UsePropState:runGamePropsActionLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then 		---running阶段，自动扣时间，到时间了，进入Death阶段
		if theAction.actionDuring < 0 then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		else
			theAction.actionDuring = theAction.actionDuring - 1
			if theAction.actionType == GameItemActionType.kItemRefresh_Item_Flying then
				self:runningGameItemRefresh_Item_Flying(mainLogic, theAction, actid)
			end
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		if theAction.actionType == GamePropsActionType.kHammer then
			self:runGamePropsHammerAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kSwap then
			self:runningGamePropSwapAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kLineBrush then
			self:runGamePropsLineBrushAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kBack then
			self:runGamePropsBackAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kOctopusForbid then
			self:runGamePropsOctopusForbidAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kRandomBird then
			self:runGamePropsRandomBirdAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kBroom then
			self:runGamePropsBroomAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kMegaPropSkill then 	--GamePropsActionType.kMegaPropSkill居然从未定义过，可怕可怕
			self:runGamePropsMegaPropSkillAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kHedgehogCrazy then
			self:runGamePropsHedgehogCrazyAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kWukongJump then
			self:runGamePropsWukongJumpAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kNationDay2017Cast then
			self:runGamePropskNationDay2017CastAction(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kMoleWeeklyRaceSPProp then
			self:runGamePropsMoleWeeklySPPropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kJamSpeardHammer then
			self:runGamePropsJamSpeardHummerPropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kLineEffectProp then
			self:runGamePropsLineEffectPropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill1 then
			self:runSpringFestival2019Skill1PropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill2 then
			self:runSpringFestival2019Skill2PropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill3 then
			self:runSpringFestival2019Skill3PropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill4 then
			self:runSpringFestival2019Skill4PropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kGetTempProp then
			self:runGetTempPropPropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kThrowBird then
			self:runThrowBirdPropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kThrow_LINE_WRAP then
			self:runThrowLineWrapPropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill2 then
			self:runRailroadSkill2PropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill3 then
			self:runRailroadSkill3PropLogic(mainLogic, theAction, actid)
        elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill4 then
			self:runRailroadSkill4PropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kWeeklyRace2020SPProp then
			self:runGamePropsWeeklyRace2020SPPropLogic(mainLogic, theAction, actid)
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForStart then
		if theAction.actionType == GamePropsActionType.kThrowBird then
			self:runThrowBirdPropLogic(mainLogic, theAction, actid)
		elseif theAction.actionType == GamePropsActionType.kThrow_LINE_WRAP then
			self:runThrowLineWrapPropLogic(mainLogic, theAction, actid)
		end
	end
end

function UsePropState:runGamePropskNationDay2017CastAction( mainLogic, theAction, actid )
	if theAction.addInfo == "over" then
		NationDay2017CastLogic:runCastAction(mainLogic, 1)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsHedgehogCrazyAction( mainLogic, theAction, actid )
	-- body
	if theAction.addInfo == "over" then
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsWukongJumpAction( mainLogic, theAction, actid )
	if theAction.addInfo == "over" then
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsMegaPropSkillAction(mainLogic, theAction, actid)
	if theAction.addInfo == 'over' then
		BombItemLogic:springFestivalBombScreen(mainLogic)
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsBroomAction(mainLogic, theAction, actid)
	if theAction.addInfo == 'over' then

		-- local r1, r2 = theAction.rows.r1, theAction.rows.r2
		local interval = 0.13

		local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
		local action = GameBoardActionDataSet:createAs(
                        GameActionTargetType.kGameItemAction,
                        GameItemActionType.kItem_WitchBomb,
                        nil,
                        nil,
                        GamePlayConfig_MaxAction_time
                    )
		action.rows = theAction.rows
		action.interval = interval
		action.startDelay = theAction.bombDelayTime
		action.col = colAmount
	    mainLogic:addDestroyAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsRandomBirdAction(mainLogic, theAction, actid)
	--printx( 1 , "UsePropState:runGamePropsRandomBirdAction  " ,actid ,  theAction.addInfo , theAction.jsq)

	if theAction.addInfo == "watingForAnime" then
		theAction.jsq = theAction.jsq + 1

		if theAction.jsq > 30 then
			theAction.addInfo = 'over'
		end
	elseif theAction.addInfo == 'over' then
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		assert(item.ItemType == GameItemType.kAnimal)
		item._encrypt.ItemColorType = AnimalTypeConfig.kRandom
		item.ItemSpecialType = AnimalTypeConfig.kColor
		item.isNeedUpdate = true
		self:setNextState(self.context.waitingState)
		mainLogic.propActionList[actid] = nil
	end
end

function UsePropState:runGamePropsOctopusForbidAction(mainLogic, theAction, actid)
	printx( 1 , "   UsePropState:runGamePropsOctopusForbidAction   theAction.addInfo = " , theAction.addInfo)
	if theAction.addInfo == 'over' then	

		local octopuses = {}
		local venoms = {}
		for r = 1, #mainLogic.gameItemMap do 
			for c = 1, #mainLogic.gameItemMap[r] do 
				local item = mainLogic.gameItemMap[r][c]
				local board = mainLogic.boardmap[r][c]
				if item 
					and not item:hasActiveSuperCuteBall()
					and board.colorFilterBLevel == 0 
					and item.blockerCoverLevel == 0
					and (not WaterBucketLogic:hasBucket(item))
					and not board.isReverseSide then
					if item.ItemType == GameItemType.kPoisonBottle then
						table.insert(octopuses, item)
					elseif item.ItemType == GameItemType.kVenom then
						table.insert(venoms, item)
					end
				end
			end
		end

		for k, item in pairs(octopuses) do 
			item.forbiddenLevel = 3
			local r, c = item.y, item.x
			local action = GameBoardActionDataSet:createAs(
			                   GameActionTargetType.kGameItemAction,
			                   GameItemActionType.kOctopus_Change_Forbidden_Level,
			                   IntCoord:create(c, r),
			                   nil,
			                   GamePlayConfig_MaxAction_time)
			action.level = item.forbiddenLevel
			action.completeCallback = callback
	        self.mainLogic:addGameAction(action)
		end
		
		for k, item in pairs(venoms) do 
			local r, c = item.y, item.x
			SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c) 
		end

		mainLogic.propActionList[actid] = nil
		self:setNextState(self.context.fallingMatchState)
		mainLogic:setNeedCheckFalling()

	end
end

function UsePropState:runGamePropsHammerAction(mainLogic, theAction, actid)
	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local item = mainLogic.gameItemMap[r][c]

    local SpecialID = mainLogic:addSrcSpecialCoverToList( theAction.ItemPos1, theAction.ItemPos2 )

    if mainLogic.theGamePlayType == GameModeTypeId.JAMSPREAD_ID then
    	GameExtandPlayLogic:addJamSperadFlag(mainLogic, r, c )
    end

	GameExtandPlayLogic:specialCoverActiveCrystalStone(mainLogic, r, c, scoreScale) -- 作用于满能量的染色宝宝
	if item:candoBlocker195Collect(item.subtype) then
		local collectType = item.subtype
		local increment = math.max(math.floor(mainLogic.blocker195Nums[collectType] / 6), 1)
		GameExtandPlayLogic:doABlocker195Collect(mainLogic, item, nil, nil, r, c, collectType, increment)
	end
	GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, 0, true, 3)
	SquidLogic:checkHammerHitSquid(mainLogic, item)
	GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, r, c, 1, true)
	PacmanLogic:dealWithHammerHit(mainLogic, item)
	SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1, true)  --可以作用银币
	BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
	SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, nil,nil,nil,nil,nil,SpecialID) 
	SpecialCoverLogic:specialCoverChainsAroundPos(mainLogic, r, c)
	WaterBucketLogic:checkHammerHit(mainLogic, item)
	local str = string.format(GameMusicType.kEliminate, 1)
	GamePlayHapticsPlayer.getInstance():playEffect("useprop_hammer")
 	GamePlayMusicPlayer:playEffect(str);
	mainLogic.propActionList[actid] = nil
	self:setNextState(self.context.fallingMatchState)
	mainLogic:setNeedCheckFalling()
end

function UsePropState:runningGamePropSwapAction(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then 						----结束状态
		local r1, c1, r2, c2 = theAction.ItemPos1.x, theAction.ItemPos1.y, theAction.ItemPos2.x, theAction.ItemPos2.y
		if not SwapItemLogic:_trySwapedMatchItem(mainLogic, r1, c1, r2, c2, true) then

            mainLogic.boardView.baseMap[r1][c1].oldData = mainLogic.gameItemMap[r1][c1]:copy()
            mainLogic.boardView.baseMap[r2][c2].oldData = mainLogic.gameItemMap[r2][c2]:copy()

			local data1 = mainLogic.gameItemMap[r1][c1]
			local data2 = mainLogic.gameItemMap[r2][c2]
			local item1Clone = data1:copy()
			local item2Clone = data2:copy()
			data2:getAnimalLikeDataFrom(item1Clone)
			data1:getAnimalLikeDataFrom(item2Clone)
			if data1.ItemType == GameItemType.kMagicLamp or data2.ItemType == GameItemType.kMagicLamp 
				or data1.ItemType == GameItemType.kWukong or data2.ItemType == GameItemType.kWukong 
				or data1.ItemType == GameItemType.kBlocker199 or data2.ItemType == GameItemType.kBlocker199 
				or data1.ItemType == GameItemType.kPacman or data2.ItemType == GameItemType.kPacman 
                or data1.ItemType == GameItemType.kWanSheng or data2.ItemType == GameItemType.kWanSheng 
                or data1.ItemType == GameItemType.kNationalDayBunny or data2.ItemType == GameItemType.kNationalDayBunny 
				or data1:seizedByGhost() or data2:seizedByGhost()
				then
				mainLogic:checkItemBlock(r1, c1)
				mainLogic:checkItemBlock(r2, c2)
				FallingItemLogic:preUpdateHelpMap(mainLogic)
			end
		else
			local swapInfo = { { r = r1, c = c1 }, { r = r2, c = c2 } }
			mainLogic.swapInfo = swapInfo
		end
		
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)

		mainLogic.gameMode:checkDropDownCollect(r1, c1)
		mainLogic.gameMode:checkDropDownCollect(r2, c2)
		mainLogic.propActionList[actid] = nil
	end
end

function UsePropState:runGamePropsLineBrushAction(mainLogic, theAction, actid)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local animalType
	if theAction.ItemPos2.x ~= 0 then animalType = AnimalTypeConfig.kLine else animalType = AnimalTypeConfig.kColumn end
	mainLogic.gameItemMap[r1][c1]:changeItemType(mainLogic.gameItemMap[r1][c1]._encrypt.ItemColorType, animalType)
	mainLogic.gameItemMap[r1][c1].isNeedUpdate = true
	mainLogic.propActionList[actid] = nil

	GamePlayHapticsPlayer.getInstance():playEffect("useprop_brush")
	PropsAnimation:playLineEffect( animalType, r1, c1, mainLogic.boardView )

	self:setNextState(self.context.waitingState)
end

function UsePropState:runGamePropsBackAction(mainLogic, theAction, actid)
	mainLogic.propActionList[actid] = nil
	mainLogic.gameMode:revertUIFromBackProp(mainLogic)
	self:setNextState(self.context.waitingState)
end

function UsePropState:runningGameItemRefresh_Item_Flying(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
		-- mainLogic.propActionList[actid] = nil
		-- self.nextState = self.context.waitingState

		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local endItem = mainLogic:safeGetItemData(r1, c1)
		if endItem then
			endItem.shieldToColorFilter = false --刷新动画播完，结束屏蔽过滤器的保护锁
		end

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	elseif theAction.addInfo == "Pass" then
		theAction.addInfo = "waiting1"
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local item1 = mainLogic.gameItemMap[r1][c1]
		item1.isNeedUpdate = true
	elseif theAction.addInfo == "waiting1" then
		if theAction.actionDuring == 1 then 
			theAction.addInfo = "over"
		end
	end
end

function UsePropState:runPropsActionView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		if theAction.actionType == GamePropsActionType.kHammer then
			PropsView:playHammerAnimation(boardView, ccp(theAction.ItemPos1.x, theAction.ItemPos1.y))
			theAction.actionStatus = GameActionStatus.kRunning
		elseif theAction.actionType == GamePropsActionType.kSwap then
			self:runSwapItemAction(boardView, theAction)
			theAction.actionStatus = GameActionStatus.kRunning
		elseif theAction.actionType == GamePropsActionType.kLineBrush then
			PropsView:playLineBrushAnimation(boardView, ccp(theAction.ItemPos1.x, theAction.ItemPos1.y), theAction.ItemPos2)
			theAction.actionStatus = GameActionStatus.kRunning
		elseif theAction.actionType == GamePropsActionType.kBack then
			boardView:reInitByGameBoardLogic()
			theAction.actionStatus = GameActionStatus.kRunning
		elseif theAction.actionType == GamePropsActionType.kOctopusForbid then
			theAction.actionStatus = GameActionStatus.kRunning
			self:runGameItemActionStartOctopusForbidden(boardView, theAction)
		elseif theAction.actionType == GameItemActionType.kItemRefresh_Item_Flying then
			self:runGameItemActionPassRefreshItemFlying(boardView, theAction)
			self:runGameItemActionRefresh_Item_Flying(boardView, theAction)	
		elseif theAction.actionType == GamePropsActionType.kRandomBird then
			self:runGameItemActionRandomBird(boardView, theAction)	
		elseif theAction.actionType == GamePropsActionType.kBroom then
			self:runGameItemActionBroom(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kMegaPropSkill then
			self:runGameItemActionMegaPropSkill(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kHedgehogCrazy then
			self:runGameItemActionHedeglogCrazy(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kWukongJump then
			self:runGameItemActionWukongJump(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kNationDay2017Cast then
			self:runGameItemActionkNationDay2017Cast(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kMoleWeeklyRaceSPProp then
			self:runGamePropsMoleWeeklySPPropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kJamSpeardHammer then
			self:runGamePropsJamSpeardHummerPropView(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kLineEffectProp then
			self:runGamePropsLineEffectPropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill1 then
			self:runSpringFestival2019Skill1PropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill2 then
			self:runSpringFestival2019Skill2PropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill3 then
			self:runSpringFestival2019Skill3PropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kSpringFestival2019_Skill4 then
			self:runSpringFestival2019Skill4PropView(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kGetTempProp then
			self:runGetTempPropPropView(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kThrowBird then
			self:runThrowBirdPropView(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kThrow_LINE_WRAP then
			self:runThrowLineWrapPropView(mainLogic, theAction, actid)
		 elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill2 then
			self:runRailroadSkill2PropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill3 then
			self:runRailroadSkill3PropView(boardView, theAction)
        elseif theAction.actionType == GamePropsActionType.kRailRoad_Skill4 then
			self:runRailroadSkill4PropView(boardView, theAction)
		elseif theAction.actionType == GamePropsActionType.kWeeklyRace2020SPProp then
			self:runGamePropsWeeklyRace2020SPPropView(boardView, theAction)
		end
	else
		if theAction.actionType == GameItemActionType.kItemRefresh_Item_Flying then
			if theAction.addInfo == "over" then
				self:runGameItemActionPassRefreshItemFlyingOver(boardView, theAction)
			end
		end
	end
end

function UsePropState:runGameItemActionkNationDay2017Cast(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath 
		theAction.addInfo = 'over'
	end
end

function UsePropState:runGameItemActionHedeglogCrazy( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath 
		theAction.addInfo = 'over'
	end
end

function UsePropState:runGameItemActionWukongJump( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath 
		theAction.addInfo = 'over'
	end
end

function UsePropState:runGameItemActionMegaPropSkill(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath 
		theAction.addInfo = 'over'
	end
end

function UsePropState:runGameItemActionBroom(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local interval = 0.13
		local rowCount = #theAction.rows
		local rowIndex = math.min(2, rowCount)
		local row = theAction.rows[rowIndex]

		local bombDelayTime = PropsView:playWitchFlyingAnimation(boardView, interval, row, theAction.isNewBroom)
		theAction.bombDelayTime = bombDelayTime
		theAction.addInfo = 'over'
	end
end

function UsePropState:runGameItemActionRandomBird(boardView, theAction)	

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local function finishRandomBird()
			--theAction.addInfo = 'over'
		end
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		--setTimeOut(finishRandomBird, 0.5)

		theAction.addInfo = "watingForAnime"
		theAction.jsq = 0
	end
end

function UsePropState:runSwapItemAction(boardView, theAction)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y

	local sprite1, spriteCover1 = boardView.baseMap[r1][c1]:getGameItemSprite()
	local sprite2, spriteCover2 = boardView.baseMap[r2][c2]:getGameItemSprite()
	if sprite1 == nil or sprite2 == nil then
		if _G.isLocalDevelopMode then printx(0, "UsePropState:runSwapItemAction sprite1 == nil or sprite2 == nil, it is a error!!!") end
		return false
	end

	local position1 = UsePropState:getItemPosition(theAction.ItemPos1)
	local position2 = UsePropState:getItemPosition(theAction.ItemPos2)

	sprite1:runAction(UsePropState:createSwapActionsForTwoItem(position2, r1, r2))
	if spriteCover1 then spriteCover1:runAction(UsePropState:createSwapActionsForTwoItem(position2, r1, r2)) end
	sprite2:runAction(UsePropState:createSwapActionsForTwoItem(position1, r1, r2))
	if spriteCover2 then spriteCover2:runAction(UsePropState:createSwapActionsForTwoItem(position1, r1, r2)) end

	PropsAnimation:playForceSwapEffect(r1,c1,r2,c2,boardView)
end

function UsePropState:createSwapActionsForTwoItem(endPosition, r1, r2)
	local MoveToAction = CCMoveTo:create(UsePropState:getActionTime(GamePlayConfig_ForceSwapAction_Move_CD), endPosition)

	local scaleActionSeq = CCArray:create()
	if r1 == r2 then -- 横向
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(3), 1.05, 0.96))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(3), 1.05, 0.96))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(2), 0.95, 1.05))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(2), 1, 1))
	else -- 纵向
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(3), 0.96, 1.05))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(3), 0.95, 1.07))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(2), 1.05, 0.95))
		scaleActionSeq:addObject(CCScaleTo:create(UsePropState:getActionTime(2), 1, 1))
	end
	local scaleAction = CCSequence:create(scaleActionSeq)

	local action = CCSpawn:createWithTwoActions(MoveToAction, scaleAction)
	return action
end

function UsePropState:getItemPosition(itemPos)
	local x = (itemPos.y - 0.5 ) * GamePlayConfig_Tile_Width
	local y = (GamePlayConfig_Max_Item_Y - itemPos.x - 0.5 ) * GamePlayConfig_Tile_Height
	return ccp(x,y)
end

----CDCount多少帧
function UsePropState:getActionTime(CDCount)
	return 1.0 / GamePlayConfig_Action_FPS * CDCount
end

function UsePropState:runGameItemActionRefresh_Item_Flying(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	local r1 = theAction.ItemPos1.x;
	local c1 = theAction.ItemPos1.y;
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y

	local item1 = boardView.baseMap[r1][c1];
	local item2 = boardView.baseMap[r2][c2];

	local pos1 = item1:getBasePosition(c1,r1)
	local pos2 = item1:getBasePosition(c2,r2)

	local itemSpecial = item1.itemSprite[ItemSpriteType.kSpecial]
	if itemSpecial ~= nil and not itemSpecial.isDisposed then
		local length = math.sqrt(math.pow(pos2.y - pos1.y, 2) + math.pow(pos2.x - pos1.x, 2))
		local moveAction = HeBezierTo:create(BoardViewAction:getActionTime(GamePlayConfig_Refresh_Item_Flying_Time), pos1, true, length * 0.4)

		itemSpecial:setPosition(pos2);
		itemSpecial:runAction(CCEaseSineInOut:create(moveAction));
	end
end

function UsePropState:runGameItemActionPassRefreshItemFlying(boardView, theAction)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y

	local item1 = boardView.baseMap[r1][c1] 		----目标
	local item2 = boardView.baseMap[r2][c2]			----来源

	local data1 = boardView.gameBoardLogic.gameItemMap[r1][c1] 		----目标
	local data2 = boardView.gameBoardLogic.gameItemMap[r2][c2]		----来源

	item1:flyingSpriteIntoItem(item2)

	if item1.oldData then
		item1.isNeedUpdate = true

		item1.oldData._encrypt.ItemColorType = data1._encrypt.ItemColorType
		item1.oldData.ItemSpecialType = data1.ItemSpecialType
		if data1.ItemSpecialType == AnimalTypeConfig.kColor then
			item1.itemShowType = ItemSpriteItemShowType.kBird
		else
			item1.itemShowType = ItemSpriteItemShowType.kCharacter
		end 
	else 
	end
end

function UsePropState:runGameItemActionPassRefreshItemFlyingOver(boardView, theAction)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y

	local item1 = boardView.baseMap[r1][c1] 		----目标
	local item2 = boardView.baseMap[r2][c2]			----来源

	local data1 = boardView.gameBoardLogic.gameItemMap[r1][c1] 		----目标
	local data2 = boardView.gameBoardLogic.gameItemMap[r2][c2]		----来源

	item1:flyingSpriteIntoItemEnd()
	item1.isNeedUpdate = true
end

function UsePropState:runGameItemActionStartOctopusForbidden(boardView, theAction)

	if theAction.addInfo == '' then
		theAction.addInfo = 'started'
		local mainLogic = boardView.gameBoardLogic
		local octopuses = {}
		for r = 1, #mainLogic.gameItemMap do 
			for c = 1, #mainLogic.gameItemMap[r] do 
				local item = mainLogic.gameItemMap[r][c]
				local board = mainLogic.boardmap[r][c]
				if item and item.ItemType == GameItemType.kPoisonBottle and not item:hasActiveSuperCuteBall()
					and not board.isReverseSide
					and (not WaterBucketLogic:hasBucket(item))
					and board.colorFilterBLevel == 0 then
					table.insert(octopuses, item)
				end
			end
		end

		if #octopuses == 0 then
			theAction.addInfo = 'over'
			return
		end

		local count = 0

		local function callback()
			count = count + 1
			if count == #octopuses then
				theAction.addInfo = 'over'
			end
		end

		for k, v in pairs(octopuses) do 
			local fromPos = ccp(0, 0)
			local toPos = boardView.baseMap[v.y][v.x]:getBasePosition(v.x, v.y)
			local anim = PropsView:playOctopusForbidCastingAnimation(boardView, fromPos, toPos, callback)
		end
	end
end

------------------------------ Mole Weekly Spcial Prop -------------------------------
function UsePropState:runGamePropsMoleWeeklySPPropLogic(mainLogic, theAction, actid)
	local boardView = mainLogic.boardView

	if theAction.addInfo == "startAction" then
		if mainLogic:getMoleWeeklyBossData() and theAction.hpDamage > 0 
			and boardView.PlayUIDelegate and boardView.PlayUIDelegate.bossBeeController 
			then
			--有boss，能播锤子动画
			theAction.addInfo = "flyHammer"
		else
			theAction.addInfo = "flyWithoutHammer"
		end
	end

	-------------------------- 有boss和锤子动画 ------------------------------
	if theAction.addInfo == "flyHammer" then
		local bossData = mainLogic:getMoleWeeklyBossData()
		-- printx(11, "bossData", table.tostringByKeyOrder(bossData))
		bossData.hit = math.min(bossData.hit + theAction.hpDamage, bossData.totalBlood)

		-- function HanmerHitOver()
        --     theAction.addInfo = "flyHammerOver"
        -- end
        local bossData = boardView.gameBoardLogic:getMoleWeeklyBossData()
        boardView.PlayUIDelegate:setRainbowPercent( (bossData.totalBlood-bossData.hit) / bossData.totalBlood)
	    boardView.PlayUIDelegate:playPropSkillHammerHit( nil, bossData.totalBlood-bossData.hit, theAction.hpDamage )
	    theAction.addInfo = "hammerInTheAir"
	    theAction.jsq = 0
	end

	if theAction.addInfo == "hammerInTheAir" then
		theAction.jsq = theAction.jsq + 1
		if theAction.jsq == 130 then
			theAction.addInfo = "flyHammerOver"
		end
	end

    if theAction.addInfo == "flyHammerOver" then 
    	theAction.jsq = 0
		-- printx(11, "UsePropState:runGamePropsMoleWeeklySPPropView")
		-- printx(11, "targets:", table.tostring(theAction.targetList))

        theAction.lightFromPos = boardView.PlayUIDelegate.bossBeeController:getHummerPos()
        theAction.addInfo = "lightFlyToAnimal"
	end

	-------------------------- 没boss，没锤子动画 ------------------------------
	if theAction.addInfo == "flyWithoutHammer" then
		theAction.jsq = 0

		theAction.lightFromPos = boardView.PlayUIDelegate.propList:getSpringItemGlobalPosition()		--锤子大招图标位置
		theAction.addInfo = "lightFlyToAnimal"
	end

	--------------------------     共通     ------------------------------
	if theAction.addInfo == "lightFlyToAnimal" then
		if theAction.targetList and #theAction.targetList > 0 and theAction.lightFromPos then
			for k, v in pairs(theAction.targetList) do 
                local toPos = boardView.PlayUIDelegate:_getPositionFromGridCoord(v)
				boardView.PlayUIDelegate:playLightFlyingEffect(theAction.lightFromPos, toPos)
			end
			theAction.addInfo = "hammerLightFlyToAnimal"
		else
			theAction.addInfo = "over"
			-- theAction.addInfo = "bombAll"
		end
	end

	if theAction.addInfo == "hammerLightFlyToAnimal" then
		theAction.jsq = theAction.jsq + 1
		if theAction.jsq == 25 then
			theAction.addInfo = "replaceAnimal"
		end
	end

	if theAction.addInfo == "replaceAnimal" then
		local addStepCount = 0
		local colourCount = 0
		if theAction.targetList and #theAction.targetList > 0 then
			for k, v in pairs(theAction.targetList) do 
				local tItem = mainLogic.gameItemMap[v.r][v.c]

				if addStepCount < theAction.throwAddStepAmount then
					tItem.ItemType = GameItemType.kBalloon
					tItem.balloonFrom = mainLogic.balloonFrom
					if not tItem.balloonFrom or (tItem.balloonFrom <= 0) then tItem.balloonFrom = 10 end
					tItem.balloonConstantPlayAlert = true
					MoleWeeklyRaceLogic:setSkillFlagForGuide(mainLogic, GamePropsType.kMoleWeeklyRaceSPProp)
					addStepCount = addStepCount + 1
				elseif colourCount < theAction.throwColourAmount then
					tItem.ItemType = GameItemType.kAnimal
					tItem.ItemSpecialType = AnimalTypeConfig.kColor
					colourCount = colourCount + 1
					-- printx(11, "ItemSpecialType: colour", AnimalTypeConfig.kColor)
				else
					tItem.ItemType = GameItemType.kAnimal
					local list = {AnimalTypeConfig.kLine, AnimalTypeConfig.kColumn, AnimalTypeConfig.kWrap}
					tItem.ItemSpecialType = list[mainLogic.randFactory:rand(1, #list)]
					-- printx(11, "ItemSpecialType:", tItem.ItemSpecialType)
				end
				
				tItem.isNeedUpdate = true
			end
		end
		theAction.addInfo = "over"
		-- theAction.addInfo = "bombAll"
	end

	if theAction.addInfo == "bombAll" then
		mainLogic.gameMode:playBombAll()
		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsMoleWeeklySPPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

        theAction.addInfo = "startAction"
    end

end


--
------------------------------ JamSpeard Spcial Prop -------------------------------
function UsePropState:runGamePropsJamSpeardHummerPropLogic(mainLogic, theAction, actid)
	local boardView = mainLogic.boardView

	if theAction.addInfo == "startAction" then
		theAction.addInfo = "flyHammer"
        theAction.jsq = 0
        PropsView:playJamSpeardHammerAnimation(boardView, IntCoord:create(theAction.ItemPos1.x, theAction.ItemPos1.y))
	end

	if theAction.addInfo == "flyHammer" then
		theAction.jsq = theAction.jsq + 1

		if theAction.jsq == 25 then

            local r = theAction.ItemPos1.x
	        local c = theAction.ItemPos1.y
	        local item = mainLogic.gameItemMap[r][c]

            GameExtandPlayLogic:addJamSperadFlag(mainLogic, theAction.ItemPos1.x, theAction.ItemPos1.y )

            GameExtandPlayLogic:specialCoverActiveCrystalStone(mainLogic, r, c, scoreScale) -- 作用于满能量的染色宝宝
	        if item:candoBlocker195Collect(item.subtype) then
		        local collectType = item.subtype
		        local increment = math.max(math.floor(mainLogic.blocker195Nums[collectType] / 6), 1)
		        GameExtandPlayLogic:doABlocker195Collect(mainLogic, item, nil, nil, r, c, collectType, increment)
	        end
	        GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, 0, true, 3)
	        SquidLogic:checkHammerHitSquid(mainLogic, item)
	        GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, r, c, 1, true)
	        PacmanLogic:dealWithHammerHit(mainLogic, item)
	        SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1, true)  --可以作用银币
	        BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
	        SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3) 
	        SpecialCoverLogic:specialCoverChainsAroundPos(mainLogic, r, c)

			theAction.addInfo = "over"
		end
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsJamSpeardHummerPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

        theAction.addInfo = "startAction"
    end
end

------------------------------ 横竖特效小捣蛋...啊不，导弹 -------------------------------
function UsePropState:runGamePropsLineEffectPropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
		local action = GameBoardActionDataSet:createAs(
                        GameActionTargetType.kGameItemAction,
                        GameItemActionType.kItem_Line_Prop_Effect,
                        theAction.ItemPos1,
                        nil,
                        GamePlayConfig_MaxAction_time
                    )
		action.isColumn = theAction.isColumn
	    mainLogic:addDestructionPlanAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runGamePropsLineEffectPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		local isColumn = theAction.isColumn
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y

		local targetPos
		local posInLine
		if isColumn then
			targetPos = {x = 5, y = c}
			posInLine = r
		else
			targetPos = {x = r, y = 5}
			posInLine = c
		end

		-- printx(11, "playLineEffectAnimation", isColumn, table.tostring(targetPos), posInLine)
		PropsView:playLineEffectAnimation(boardView, targetPos, isColumn, posInLine)
		GamePlayMusicPlayer:playEffect(GameMusicType.kPropLineEffect)

		theAction.addInfo = "over"
	end
end


------------------------------ 春节技能1 -------------------------------
function UsePropState:runSpringFestival2019Skill1PropLogic(mainLogic, theAction, actid)

	if theAction.addInfo == "over" then
        local action = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_SpringFestival2019_Skill1,
                nil,
                nil,
                GamePlayConfig_MaxAction_time
            )
	    action.canBeInfectItemList = table.clone(theAction.canBeInfectItemList)
        action.WorldSpace = table.clone(theAction.WorldSpace)
	    mainLogic:addDestroyAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runSpringFestival2019Skill1PropView(boardView, theAction)

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
        theAction.actionStatus = GameActionStatus.kWaitingForDeath
		theAction.addInfo = "over"
	end
end

------------------------------ 春节技能2 -------------------------------
function UsePropState:runSpringFestival2019Skill2PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
        ---------------------分数加成

        local action = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_SpringFestival2019_Skill2,
                nil,
                nil,
                GamePlayConfig_MaxAction_time
            )
        action.WorldSpace = table.clone(theAction.WorldSpace)
	    mainLogic:addDestroyAction(action)

        SpringFestival2019Manager.getInstance():setSkill2Info()
        
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runSpringFestival2019Skill2PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end

------------------------------ 春节技能3 -------------------------------
function UsePropState:runSpringFestival2019Skill3PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then

        for i=1, 4 do
            local PosInfo = theAction.PosList[i]
            if not PosInfo then break end 

            local action = GameBoardActionDataSet:createAs(
                    GameActionTargetType.kGameItemAction,
                    GameItemActionType.kItem_SpringFestival2019_Skill3,
                    IntCoord:create(PosInfo.r_min, PosInfo.c_min),
                    IntCoord:create(PosInfo.r_max, PosInfo.c_max),
                    GamePlayConfig_MaxAction_time
                )
            action.delayIndex = PosInfo.delayIndex
            action.WorldSpace = table.clone(theAction.WorldSpace)
	        mainLogic:addDestroyAction(action)
        end

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runSpringFestival2019Skill3PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end

------------------------------ 春节技能4 -------------------------------
function UsePropState:runSpringFestival2019Skill4PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
        local action = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_SpringFestival2019_Skill4,
                nil,
                nil,
                GamePlayConfig_MaxAction_time
            )
	    action.PosList = table.clone(theAction.PosList)
        action.WorldSpace = table.clone(theAction.WorldSpace)
	    mainLogic:addDestroyAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runSpringFestival2019Skill4PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end


function UsePropState:runGetTempPropPropLogic(mainLogic, theAction, actid)
	-- print("UsePropState:runGetTempPropPropLogic()",mainLogic, theAction, actid,theAction.addInfo)

	if theAction.addInfo == "over" then
		mainLogic.propActionList[actid] = nil
	
		local vo = Director:sharedDirector():getVisibleOrigin()
		local vs = Director:sharedDirector():getVisibleSize()
		local pos = ccp(vo.x + vs.width/2, vo.y + vs.height/2)

		local propId = theAction.addInt
		local godGift = RedCross:getOrCreateInstance():getGiftMeta(propId)
		local itemId = godGift and godGift.itemId
		local num = godGift and godGift.num
		local realId = ItemType:getRealId(itemId)
		-- print("UsePropState:runGetTempPropPropLogic()gift",propId,table.tostring(godGift))

	    local levelId = mainLogic.level

		if godGift.action == "useProp" then
			-- 立即使用的道具，魔力鸟、爆炸加直线 等

			if propId == GamePropsType.kCastBird then
				-- 智能魔力鸟
				local action = GameBoardActionDataSet:createAs(
			        GameActionTargetType.kPropsAction, 
			        GamePropsActionType.kThrowBird,
			        nil, 
			        nil, 
			        GamePlayConfig_MaxAction_time)
				mainLogic:addPropAction(action)

			elseif godGift.itemId == GamePropsType.kWrap_b then
				-- 爆炸加直线
				local action = GameBoardActionDataSet:createAs(
			        GameActionTargetType.kPropsAction, 
			        GamePropsActionType.kThrow_LINE_WRAP,
			        nil, 
			        nil, 
			        GamePlayConfig_MaxAction_time)
				mainLogic:addPropAction(action)
			end
		elseif godGift.action == "addReward" then
			-- 加奖励，无限精力、风车币 等
			-- 通知后端 加数据
			SendPropAtFiveStepsHttp.new(false):load(levelId, nil,{propId})
			
			-- 前端 加数据
			local reward = {itemId = itemId,num = num}
		    local updateButton = true
		    local dcFeatureType = DcFeatureType.kAddFiveSteps
		    local dcSourceType = DcSourceType.kGift
		    RewardUtil:addRewardDataWithDC(reward,updateButton,dcFeatureType, dcSourceType)

		    local visibleOrigin = Director:sharedDirector():getVisibleOrigin()
		    local visibleSize =  Director:sharedDirector():getVisibleSize()
		    local worldCenterPos = ccp(
		        visibleOrigin.x + visibleSize.width/2,
		        visibleOrigin.y + visibleSize.height/2
		    )

		    local flyAnim = FlyItemsAnimation:create({reward})
		    flyAnim:setWorldPosition(worldCenterPos)
		    flyAnim:play()

		    -- 主逻辑 下一步状态
			mainLogic:setNeedCheckFalling()
			self:setNextState(self.context.fallingMatchState)

		elseif godGift.action == "tempProp" then
			-- 本关临时道具
			if realId == ItemType.ADD_2_STEP then
				-- 加步数，需要立即使用

				-- 通知后端
				SendPropAtFiveStepsHttp.new(false):load(levelId, {itemId})

				-- 使用
				local function failFunc( ... )
				end
				local function succFunc( ... )
					setTimeOut(function()
						-- 等正常的+5播放完毕，再播放这个+2
						mainLogic:useProps(GamePropsType.kAdd2)

						mainLogic:setNeedCheckFalling()
						self:setNextState(self.context.fallingMatchState)
					end,1.4)
				end

				local logic = UsePropsLogic:create(UsePropsType.TEMP, levelId, 0, {itemId}, nil)
				logic:setSuccessCallback(succFunc)
				logic:setFailedCallback(failFunc)
				logic:start()

			else
				-- 本关临时道具，放到关卡底部道具栏，临时小木槌、临时小火箭 等
				mainLogic.PlayUIDelegate:addTemporaryItem2(itemId, 1,pos, function ( ... )
					mainLogic:setNeedCheckFalling()
					self:setNextState(self.context.fallingMatchState)
				end)
			end
		end
	end
end

function UsePropState:runGetTempPropPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end

-- 扔爆炸加直线
function UsePropState:runThrowLineWrapPropLogic(mainLogic, theAction, actid)
	-- print("UsePropState:runThrowLineWrapPropLogic()",theAction.addInfo,theAction.datas)

	if theAction.addInfo == 'calc-pos' then
		GameInitBuffLogic.mainLogic = mainLogic
		local buffs = {GameInitBuffLogic:createBuffData(InitBuffType.LINE_WRAP, InitBuffCreateType.INGAME_STATE)}
		local resultList = {}
		GameInitBuffLogic:__checkMapAndFindCreatePosition( nil , buffs , resultList, true )

		theAction.datas = resultList and resultList[1]

		-- print("UsePropState:runThrowLineWrapPropLogic()-",table.tostring(theAction.datas))
		if theAction.datas then
			-- print("UsePropState:runThrowLineWrapPropLogic() theAction.datas-",theAction.datas.c,theAction.datas.r,theAction.datas.c2,theAction.datas.r2,theAction.datas.tarItemSpecialType)
		else
			print("UsePropState:runThrowLineWrapPropLogic() can not find pos!!")
		end

		theAction.addInfo = 'anim'

	elseif theAction.addInfo == "over" then
		print("UsePropState:runThrowLineWrapPropLogic()-",theAction.addInfo,theAction.datas)
		mainLogic.propActionList[actid] = nil
		if theAction.datas then
			local data = theAction.datas

			-- 参考 GameInitBuffLogic:useBuffWithResults
			local visibleOrigin = Director:sharedDirector():getVisibleOrigin()
			local visibleSize = CCDirector:sharedDirector():getVisibleSize()
			local destYInWorldSpace = visibleOrigin.y + visibleSize.height / 2 + 100
			local centerPosX = visibleOrigin.x + visibleSize.width / 2

			local itemData = {}
			itemData.id = ItemType.INITIAL_2_SPECIAL_EFFECT
			itemData.destXInWorldSpace = centerPosX
			itemData.destYInWorldSpace = destYInWorldSpace

			local action =  GameBoardActionDataSet:createAs(
				GameActionTargetType.kPropsAction,
				GameItemActionType.kAddBuffSpecialAnimal,
				nil,
				nil,
				GamePlayConfig_MaxAction_time)
			action.pos = {r = data.r, c = data.c}
			action.tarItemColorType = data.item._encrypt.ItemColorType
			action.tarItemSpecialType = data.tarItemSpecialType

			if true then
				action.pos2 = {r = data.r2, c = data.c2}
				action.tarItemColorType2 = data.item2._encrypt.ItemColorType
				action.tarItemSpecialType2 = data.tarItemSpecialType2
			end

			action.buffType = InitBuffType.LINE_WRAP
			action.data = itemData
			action.completeCallback = completeCallback

			print("UsePropState:runThrowLineWrapPropLogic()addGlobalCoreAction()",action)

			mainLogic:addGlobalCoreAction(action)

			mainLogic.justThrowLineWrap = 2
		end
		self:setNextState(self.context.waitingState)
	end
end

function UsePropState:runThrowLineWrapPropView(boardView, theAction)
	print("UsePropState:runThrowLineWrapPropView()",theAction.actionStatus,theAction.addInfo)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		if theAction.addInfo == '' or theAction.addInfo == nil then
			theAction.addInfo = 'calc-pos'

		elseif theAction.addInfo == 'anim' then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
			theAction.addInfo = "over"
		end
	end
	print("UsePropState:runThrowLineWrapPropView()-",theAction.actionStatus,theAction.addInfo)
end

function UsePropState:runThrowBirdPropLogic(mainLogic, theAction, actid)

	if theAction.addInfo == 'calc-pos' then

		local function getUnfinishedOrderList( ... )
			local result = {}
			for i = 1, #mainLogic.theOrderList do
				local orderData = mainLogic.theOrderList[i]
				local restNum = math.max(0, orderData.v1 - orderData.f1)
				if restNum > 0 then
					table.insert(result, {
						key1 = orderData.key1,
						key2 = orderData.key2,
						restNum = restNum,
					})
				end
			end
			return result
		end

		local function safeGet(mainLogic, r, c )
			if mainLogic.boardmap[r] and mainLogic.boardmap[r][c] then
				return mainLogic.boardmap[r][c], mainLogic.gameItemMap[r][c]
			end
		end

		local function isAnimalAndCanBeSwap( itemData, boardData, colorIndex )
			return itemData:canBeSwap() 
								and itemData.ItemType == GameItemType.kAnimal 
								and ( colorIndex == nil  or  (
									colorIndex > 0 
									and 
									AnimalTypeConfig.convertColorTypeToIndex(itemData._encrypt.ItemColorType) == colorIndex
								) 

								
								or 

								(colorIndex < 0 and (AnimalTypeConfig.convertColorTypeToIndex(itemData._encrypt.ItemColorType) ~= -colorIndex))
							) and itemData.ItemSpecialType ~= AnimalTypeConfig.kColor
		end

		local function isAnimal( itemData, boardData, colorIndex )
			return itemData.isUsed  
								and itemData.ItemType == GameItemType.kAnimal 
								and ( colorIndex == nil  or  (
									colorIndex > 0 
									and 
									AnimalTypeConfig.convertColorTypeToIndex(itemData._encrypt.ItemColorType) == colorIndex
								) 
								or 
								(colorIndex < 0 and (AnimalTypeConfig.convertColorTypeToIndex(itemData._encrypt.ItemColorType) ~= -colorIndex))
							) and itemData.ItemSpecialType ~= AnimalTypeConfig.kColor
		end

		local function tryNearAnimal(mainLogic, colorIndex, forceNoSameColor, isValidBirdPos )
			for r = 1, #mainLogic.boardmap do 
				for c = 1, #mainLogic.boardmap[r] do 
					local boardData = mainLogic.boardmap[r][c]
					local itemData = mainLogic.gameItemMap[r][c]
					if itemData and boardData then
						if isAnimalAndCanBeSwap(itemData, boardData, colorIndex) then

							for _, otherPos in ipairs({ 
								{r + 1, c},
								{r - 1, c},
								{r, c + 1},
								{r, c - 1},
							}) do
								local rr = otherPos[1]
								local cc = otherPos[2]

								local otherBoardData, otherItemData = safeGet(mainLogic, rr, cc)
								if otherBoardData and otherItemData then
									if isAnimalAndCanBeSwap(otherItemData, otherBoardData, forceNoSameColor and -colorIndex or nil) then
										local canSwap = SwapItemLogic:canBeSwaped(
											mainLogic,
											r, 
											c, 
											rr, 
											cc
											) == 1
										if canSwap then
											if not isValidBirdPos then
												return rr, cc
											else
												if isValidBirdPos(mainLogic, rr, cc) then
													return rr, cc
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		
		local function findThrowPos( ... )
			local unfinishedOrderList = getUnfinishedOrderList()
			local unfinishedAnimalOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == 1
			end)

			-- 未完成的目标里有动物
			if #unfinishedAnimalOrderList > 0 then
				table.sort(unfinishedAnimalOrderList, function ( a, b )
					if a.restNum == b.restNum then
						return a.key2 < b.key2
					else
						return a.restNum > b.restNum
					end
				end)

				for i = 1, #unfinishedAnimalOrderList do
					local rr, cc = tryNearAnimal(mainLogic, unfinishedAnimalOrderList[i].key2, true)
					if rr and cc then 
						-- printx(61, 'animal', unfinishedAnimalOrderList[i].key2)
						return rr, cc
					end

					local rr, cc = tryNearAnimal(mainLogic, unfinishedAnimalOrderList[i].key2, false)
					if rr and cc then 
						-- printx(61, 'animal', unfinishedAnimalOrderList[i].key2)
						return rr, cc
					end
				end
			end

			local checkList = {}

			if mainLogic.gameMode:is(LightUpMode) then
				local unfinishedLightUp = mainLogic.kLightUpLeftCount
				if unfinishedLightUp > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return boardData.iceLevel and boardData.iceLevel > 0
						end
						, restNum = unfinishedLightUp
					})
				end
			end

			if mainLogic.gameMode:is(SeaOrderMode) then
				local unfinishedLightUp = mainLogic.gameMode:checkAllLightCount()
				if unfinishedLightUp > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return boardData.iceLevel and boardData.iceLevel > 0
						end
						, restNum = unfinishedLightUp
					})
				end
			end


			if mainLogic.gameMode:is(LotusMode) then
				local unfinishedLotus = mainLogic.gameMode:checkAllLotusCount()
				if unfinishedLotus > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return boardData.lotusLevel and boardData.lotusLevel >= 1 and boardData.lotusLevel <= 2
						end
						, restNum = unfinishedLotus
					})
				end
			end

			local unfinishedBiscuitOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kOthers and orderData.key2 == GameItemOrderType_Others.kBiscuit
			end)
			if #unfinishedBiscuitOrderList > 0 then
				if unfinishedBiscuitOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return GameExtandPlayLogic:findBiscuitBoardDataCoveredMe(mainLogic, boardData.y, boardData.x) ~= nil
						end
						, restNum = unfinishedBiscuitOrderList[1].restNum
					})
				end
			end

			local unfinishedSandOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kOthers and orderData.key2 == GameItemOrderType_Others.kSand
			end)
			if #unfinishedSandOrderList > 0 then
				if unfinishedSandOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return boardData.sandLevel > 0
						end
						, restNum = unfinishedSandOrderList[1].restNum
					})
				end
			end


			local unfinishedHoneyOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kOthers and orderData.key2 == GameItemOrderType_Others.kHoney
			end)
			if #unfinishedHoneyOrderList > 0 then
				if unfinishedHoneyOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return itemData.honeyLevel > 0
						end
						, restNum = unfinishedHoneyOrderList[1].restNum
					})
				end
			end

			local unfinishedGreyCuteOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kSpecialTarget and orderData.key2 == GameItemOrderType_ST.kGreyCuteBall
			end)
			if #unfinishedGreyCuteOrderList > 0 then
				if unfinishedGreyCuteOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return itemData.furballType == GameItemFurballType.kGrey and itemData.furballLevel > 0
						end
						, restNum = unfinishedGreyCuteOrderList[1].restNum
					})
				end
			end

			local unfinishedBrownCuteOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kSpecialTarget and orderData.key2 == GameItemOrderType_ST.kBrownCuteBall
			end)
			if #unfinishedBrownCuteOrderList > 0 then
				if unfinishedBrownCuteOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return itemData.furballType == GameItemFurballType.kBrown and itemData.furballLevel > 0
						end
						, restNum = unfinishedBrownCuteOrderList[1].restNum
					})
				end
			end


			local unfinishedJamSperadOrderList = table.filter(unfinishedOrderList, function ( orderData )
				return orderData.key1 == GameItemOrderType.kOthers and orderData.key2 == GameItemOrderType_Others.kJamSperad
			end)
			if #unfinishedJamSperadOrderList > 0 then
				if unfinishedJamSperadOrderList[1].restNum > 0 then
					table.insert(checkList, {
						is = function ( itemData, boardData )
							return not boardData:hasJamSperad()
						end
						, restNum = unfinishedJamSperadOrderList[1].restNum
						, isValidBirdPos = function ( mainLogic, rr, cc )

							local boardData = mainLogic.boardmap[rr][cc]
							if boardData and boardData:hasJamSperad() then 
								return true
							end

							local boardData_1 = safeGet(mainLogic, rr + 1, cc)
							local boardData_2 = safeGet(mainLogic, rr - 1, cc)
							local boardData_3 = safeGet(mainLogic, rr, cc + 1)
							local boardData_4 = safeGet(mainLogic, rr, cc - 1)

							if boardData_1 and boardData_1:hasJamSperad() then return true end
							if boardData_2 and boardData_2:hasJamSperad() then return true end
							if boardData_3 and boardData_3:hasJamSperad() then return true end
							if boardData_4 and boardData_4:hasJamSperad() then return true end

						end
					})
				end
			end


			-- printx(61, 'checkList', #checkList, table.tostring(checkList))
			

			table.sort(checkList, function ( a, b )
				return a.restNum > b.restNum
			end)

			for _, checkItem in ipairs(checkList) do
				local animalCounter = {0, 0, 0, 0, 0, 0}


				local boardmap = mainLogic.boardmap
				for r = 1, #boardmap do 
					for c = 1, #boardmap[r] do 
						local boardData = boardmap[r][c]
						local itemData = mainLogic.gameItemMap[r][c]
						if itemData and boardData then
							if itemData.isUsed and boardData.isUsed and checkItem.is(itemData, boardData) then
								for colorIndex = 1, 6 do
									if isAnimal(itemData, boardData, colorIndex) then
										animalCounter[colorIndex] = animalCounter[colorIndex] + 1
									end
								end
							end
						end
					end
				end


				while table.max(animalCounter) > 0 do


					local maxNumColorIndex = 1
					for colorIndex = 2, 6 do
						if animalCounter[colorIndex] > animalCounter[maxNumColorIndex] then
							maxNumColorIndex = colorIndex 
						end
					end

					-- printx(61, 'animalCounter[maxNumColorIndex]', animalCounter[maxNumColorIndex])

					if animalCounter[maxNumColorIndex] > 0 then

						local rr, cc = tryNearAnimal(mainLogic, maxNumColorIndex, true, checkItem.isValidBirdPos)

						if rr and cc then 
							-- printx(61, 'checkItem', table.tostring(checkItem), maxNumColorIndex)
							return rr, cc
						end

						local rr, cc = tryNearAnimal(mainLogic, maxNumColorIndex, false, checkItem.isValidBirdPos)

						if rr and cc then 
							-- printx(61, 'checkItem', table.tostring(checkItem), maxNumColorIndex)
							return rr, cc
						end
					end

					animalCounter[maxNumColorIndex] = 0

				end
			end

			local randomPos = {}

			for r = 1, #mainLogic.boardmap do 
				for c = 1, #mainLogic.boardmap[r] do 
					local boardData = mainLogic.boardmap[r][c]
					local itemData = mainLogic.gameItemMap[r][c]
					if itemData and boardData then
						if isAnimalAndCanBeSwap(itemData, boardData) then

							local otherPos = {r - 1, c}
							local rr = otherPos[1]
							local cc = otherPos[2]

							local skip = false

							local otherBoardData, otherItemData = safeGet(mainLogic, rr, cc)
							if otherBoardData and otherItemData then
								if otherBoardData.isUsed and otherItemData.isUsed then
									if otherItemData:hasAnyFurball() then
										skip = true
									end
								end
							end

							if not skip then
								table.insert(randomPos, {r = r, c = c})
							end
						end
					end
				end
			end

			if #randomPos > 0 then
				local pos = randomPos[mainLogic.randFactory:rand(1, #randomPos)]
				return pos.r, pos.c
			end
		end
		local throwR, throwC = findThrowPos()
		if throwR and throwC then
			theAction.pos = IntCoord:create(throwR, throwC)
		end
		theAction.addInfo = 'anim'
	elseif theAction.addInfo == "over" then
		mainLogic.propActionList[actid] = nil
		if theAction.pos then
			local throwR = theAction.pos.x
			local throwC = theAction.pos.y
			if throwR and throwC then
				local item = mainLogic.gameItemMap[throwR][throwC]
				item._encrypt.ItemColorType = AnimalTypeConfig.kRandom
				item.ItemSpecialType = AnimalTypeConfig.kColor
				item.isNeedUpdate = true
				mainLogic.justThrowABird = 2
			end
		end
		self:setNextState(self.context.waitingState)
	end

end

function UsePropState:runThrowBirdPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		if theAction.addInfo == '' or theAction.addInfo == nil then
			theAction.addInfo = 'calc-pos'

		elseif theAction.addInfo == 'anim' then
			
			theAction.addInfo = 'anim-started'
			
			local function allPrePropFinishCallback()
				theAction.actionStatus = GameActionStatus.kWaitingForDeath
				theAction.addInfo = "over"
			end

			local pos = theAction.pos

			if pos then

				
				local function animFinishCallback()
					GamePlayHapticsPlayer.getInstance():playEffect("useprop_bird")
				end
				local function buildData(r, c)
					return {r = r, c = c, pos = boardView.gameBoardLogic:getGameItemPosInView_ForPreProp(r, c), type = AnimalTypeConfig.kColor}
				end

				local wrapData = nil
				wrapData = buildData(pos.x, pos.y)

				local vo = Director:sharedDirector():getVisibleOrigin()
				local vs = Director:sharedDirector():getVisibleSize()



				boardView.PlayUIDelegate:playCommonAddPrePropEffect(
					InitBuffType.RANDOM_BIRD, 
					{
						destXInWorldSpace = vo.x + vs.width/2,
						destYInWorldSpace = vo.y + vs.height/2,
					}, 
					nil, 
					wrapData, 
					animFinishCallback, 
					allPrePropFinishCallback
				)
			else
				allPrePropFinishCallback()
			end
		end
	end
end


------------------------------ 暑期技能2 -------------------------------
function UsePropState:runRailroadSkill2PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
        ---------------------分数加成

        local action = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_RailRoad_Skill2,
                nil,
                nil,
                GamePlayConfig_MaxAction_time
            )
        action.completeCallback = theAction.actionCompleteCall
        action.WorldSpace = table.clone(theAction.WorldSpace)
        action.canBeInfectItemList = table.clone(theAction.canBeInfectItemList)
	    mainLogic:addDestroyAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runRailroadSkill2PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end

------------------------------ 暑期技能3 -------------------------------
function UsePropState:runRailroadSkill3PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
        ---------------------分数加成

        local action = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_RailRoad_Skill3,
                nil,
                nil,
                GamePlayConfig_MaxAction_time
            )
        action.completeCallback = theAction.actionCompleteCall
        action.WorldSpace = table.clone(theAction.WorldSpace)
        action.canBeInfectItemList = table.clone(theAction.canBeInfectItemList)
	    mainLogic:addDestroyAction(action)

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runRailroadSkill3PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end

------------------------------ 暑期技能4 -------------------------------
function UsePropState:runRailroadSkill4PropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "over" then
		if theAction.PosList then
	        for i=1, #theAction.PosList do
	            local PosInfo = theAction.PosList[i]
	            if not PosInfo then break end 

	            local action = GameBoardActionDataSet:createAs(
	                    GameActionTargetType.kGameItemAction,
	                    GameItemActionType.kItem_RailRoad_Skill4,
	                    IntCoord:create(PosInfo.r_min, PosInfo.c_min),
	                    IntCoord:create(PosInfo.r_max, PosInfo.c_max),
	                    GamePlayConfig_MaxAction_time
	                )
	            action.completeCallback = theAction.actionCompleteCall
	            action.delayIndex = PosInfo.delayIndex
	            action.WorldSpace = table.clone(theAction.WorldSpace)
		        mainLogic:addDestroyAction(action)
	        end
	    end

		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
end

function UsePropState:runRailroadSkill4PropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath

		theAction.addInfo = "over"
	end
end
----------------------end----------------

------------------------------ Weekly Race 20202 Spcial Prop -------------------------------
function UsePropState:runGamePropsWeeklyRace2020SPPropLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "startAction" then
		theAction.addInfo = ""
		theAction.jsq = 0
	end

    local bombAnimationDelay = 60
	if theAction.jsq == bombAnimationDelay then
		WeeklyRace2020Logic:playSpecialPropBombAllAnimation(mainLogic)
	end

	local boardShakeDelay = bombAnimationDelay + 10
	if theAction.jsq == boardShakeDelay then
		if mainLogic.boardView then
			mainLogic.boardView:viberate()
		end
	end

	local bombLogicDelay = bombAnimationDelay + 20
	if theAction.jsq == bombLogicDelay then
		WeeklyRace2020Logic:onSpecialPropBombAllLogic(mainLogic)
	end

	if theAction.jsq == bombLogicDelay + 1 then
		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.propActionList[actid] = nil
		mainLogic:setNeedCheckFalling()
		self:setNextState(self.context.fallingMatchState)
	end
	
	theAction.jsq = theAction.jsq + 1
end

function UsePropState:runGamePropsWeeklyRace2020SPPropView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kWaitingForDeath
		theAction.jsq = 0
        theAction.addInfo = "startAction"
    end
end

