DestroyItemLogic = class()

local destroyItemActionMap 


function DestroyItemLogic:update(mainLogic)
	local count1 = DestroyItemLogic:destroyDecision(mainLogic)
	local count2 = DestroyItemLogic:destroyExecutor(mainLogic)
	-- 检测blocker状态变化
	mainLogic:updateFallingAndBlockStatus()
	--printx( 1 , "   DestroyItemLogic:update  " , count1 , count2)
	return count1 > 0 or count2 > 0
end

function DestroyItemLogic:destroyDecision(mainLogic)
	local count = 0
	local output = "destroy item: "
	local flag = false
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if (item.ItemStatus == GameItemStatusType.kIsSpecialCover 
				or item.ItemStatus == GameItemStatusType.kIsMatch)
				and item.ItemType ~= GameItemType.kDrip
				then

				count = count + 1
				output = output .. string.format("(%d, %d) ", r, c)
				flag = true
				
				local specialType = mainLogic.gameItemMap[r][c].ItemSpecialType
				if AnimalTypeConfig.isSpecialTypeValid(specialType) then

					local keyname = ""

					if item.ItemStatus == GameItemStatusType.kIsMatch then
						if specialType == AnimalTypeConfig.kLine or specialType == AnimalTypeConfig.kColumn then
							keyname = "line_match_swap"
						elseif specialType == AnimalTypeConfig.kWrap then
							keyname = "wrap_match_swap"
						end
					elseif item.ItemStatus == GameItemStatusType.kIsSpecialCover then
						if specialType == AnimalTypeConfig.kLine or specialType == AnimalTypeConfig.kColumn then
							keyname = "line_cover"
						elseif specialType == AnimalTypeConfig.kWrap then
							keyname = "wrap_cover"
						elseif specialType == AnimalTypeConfig.kColor then
							keyname = "bird_cover"
						end
					end
					GamePlayContext:getInstance():updatePlayInfo( keyname , 1 )
					
					BombItemLogic:BombItem(mainLogic, r, c, 1, 0)

				end

				if item.ItemType == GameItemType.kAnimal and specialType == 0 then
					GamePlayContext:getInstance():updatePlayInfo( "animal_destroy_count" , 1 )
				end

				if item.ItemType == GameItemType.kBlocker199 then
					item.bombRes = nil
					item:AddItemStatus( GameItemStatusType.kNone , true )
					if SpecialCoverLogic:canBeEffectBySpecialAt(mainLogic, r, c) then
						SpecialCoverLogic:effectBlockerAt(mainLogic, r, c, 1, nil, false, false)
					end
				elseif specialType ~= AnimalTypeConfig.kColor then
					item:AddItemStatus(GameItemStatusType.kDestroy)
					mainLogic:tryDoOrderList(r, c, GameItemOrderType.kAnimal, item._encrypt.ItemColorType)
					local deletedAction = GameBoardActionDataSet:createAs(
						GameActionTargetType.kGameItemAction,
						GameItemActionType.kItemDeletedByMatch,
						IntCoord:create(r,c),
						nil,
						GamePlayConfig_GameItemAnimalDeleteAction_CD)

					if item.ItemType == GameItemType.kAnimal then
						local colorIndex = AnimalTypeConfig.convertColorTypeToIndex( item._encrypt.ItemColorType )
						GamePlayContext:getInstance():updateCMap( "gdCMap" , colorIndex )
						Notify:dispatch( "AnimalDestroy" , { r = r , c = c , colorIndex = colorIndex , specialType = specialType } )
					elseif item.ItemType == GameItemType.kBalloon then 
						deletedAction.addInfo = "balloon"
						ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Balloon, ObstacleFootprintAction.k_Eliminate, 1)
					elseif item.ItemType == GameItemType.kCrystal then 
						ObstacleFootprintManager:addCrystalBallEliminateRecord(item)
					elseif item.ItemType == GameItemType.kCuckooWindupKey then 
						deletedAction.addInfo = "cuckooWindupKey"
					elseif item.ItemType == GameItemType.kTravelEnergyBag then 
						deletedAction.addInfo = "travelEnergyBag"
					elseif item.ItemType == GameItemType.kDrip then 
						deletedAction.addInfo = "drip"
					end
					-- if item.ItemSpecialType == AnimalTypeConfig.kWrap then
					-- 	deletedAction.addInfo = "wrap"
					-- end
					mainLogic:addDestroyAction(deletedAction)

					if item:canChargeCrystalStone() then
						GameExtandPlayLogic:chargeCrystalStone(mainLogic, r, c, item._encrypt.ItemColorType)
						GameExtandPlayLogic:doAllBlocker211Collect(mainLogic, r, c, item._encrypt.ItemColorType, false, 1)--寄居蟹充能
					end	
				end
			end
		end
	end
	if flag then
		-- if _G.isLocalDevelopMode then printx(0, output) end
	end
	return count
end

function DestroyItemLogic:destroyExecutor(mainLogic)
	local count = 0

	local maxIndex = table.maxn(mainLogic.destroyActionList)
	for i = 1 , maxIndex do
		local atc = mainLogic.destroyActionList[i]
		if atc then
			count = count + 1
			--printx( 1 , "   DestroyItemLogic:destroyExecutor  " , atc.actionType)
			DestroyItemLogic:runLogicAction(mainLogic, atc, i)
			DestroyItemLogic:runViewAction(mainLogic.boardView, atc)
		end
	end
	--[[
	for k,v in pairs(mainLogic.destroyActionList) do
		count = count + 1
		DestroyItemLogic:runLogicAction(mainLogic, v, k)
		DestroyItemLogic:runViewAction(mainLogic.boardView, v)
	end
	]]
	return count
end

function DestroyItemLogic:runLogicAction(mainLogic, theAction, actid)
	-- if _G.isLocalDevelopMode then printx(0, 'run DestroyItemLogic:runLogicAction') end
	if theAction.actionStatus == GameActionStatus.kRunning then 		---running阶段，自动扣时间，到时间了，进入Death阶段
		if theAction.actionDuring < 0 then 
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		else
			theAction.actionDuring = theAction.actionDuring - 1
			DestroyItemLogic:runningGameItemAction(mainLogic, theAction, actid)
		end
	end

	


	if theAction.actionType == GameItemActionType.kItem_Travel_Hero_Walk then
		DestroyItemLogic:runGameItemActionHeroWalkLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Hero_Attack then
		DestroyItemLogic:runGameItemActionHeroAttackLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Open_Event_Box then
		DestroyItemLogic:runGameItemActionTravelEventOpenBoxLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag then
		DestroyItemLogic:runGameItemActionTravelEventEnergyBagLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Route then
		DestroyItemLogic:runGameItemActionTravelEventBombRouteLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Heart then
		DestroyItemLogic:runGameItemActionTravelEventBombHeartLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Absorb_Energy_Bag then
		DestroyItemLogic:runGameItemActionTravelEnergyBagDemolishLogic(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Add_Step_Skill then
		DestroyItemLogic:runGameItemActionTravelAddStepSkillLogic(mainLogic, theAction, actid)

    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill1 then
		DestroyItemLogic:runningGameItemActionSprintFestival2019Skill1Logic(mainLogic, theAction, actid)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill2 then
		DestroyItemLogic:runningGameItemActionSprintFestival2019Skill2Logic(mainLogic, theAction, actid)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill3 then
		DestroyItemLogic:runningGameItemActionSprintFestival2019Skill3Logic(mainLogic, theAction, actid)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill4 then
		DestroyItemLogic:runningGameItemActionSprintFestival2019Skill4Logic(mainLogic, theAction, actid)

	else 
		-- with(destroyItemActionMap[theAction.actionType], function ( ... )
		-- 	it(DestroyItemLogic, mainLogic, theAction, actid, actByView)
		-- end)

		if destroyItemActionMap[theAction.actionType] then
			destroyItemActionMap[theAction.actionType](DestroyItemLogic, mainLogic, theAction, actid, actByView)
		end

	end
end

function DestroyItemLogic:runningGameItemActionBlocker207Dec(mainLogic, theAction, actid, actByView)

	if theAction.addInfo == "checkChargeList" then

		local groupKey = theAction.groupKey or -1

		theAction.chargeList = {}

		for r = 1, #mainLogic.gameItemMap do
			for c = 1, #mainLogic.gameItemMap do 
				local item = mainLogic.gameItemMap[r][c]
				if item then 

					if item.lockLevel == groupKey and item.lockHead then
						table.insert( theAction.chargeList , {r = r , c = c} )
					end

				end
			end
		end

		theAction.addInfo = "flyEff"

	elseif theAction.addInfo == "over" then
		mainLogic.destroyActionList[actid] = nil
	end

end

function DestroyItemLogic:runningGameItemActionBlocker206Dec(mainLogic, theAction, actid, actByView)
	
	if theAction.addInfo == "checkNeedUnlockBlocker" then

		local unlockGroupKey = theAction.unlockGroupKey or -1
		local nextGroupKey = theAction.nextGroupKey or -1

		theAction.unlockGroup = {}
		theAction.nextGroup = {}

		for r = 1, #mainLogic.gameItemMap do
			for c = 1, #mainLogic.gameItemMap do 
				local item = mainLogic.gameItemMap[r][c]
				if item then 

					if item.lockLevel == unlockGroupKey then
						table.insert( theAction.unlockGroup , {r = r , c = c} )
					elseif item.lockLevel == nextGroupKey then
						table.insert( theAction.nextGroup , {r = r , c = c} )
						item.lockBoxActive = true
					end

				end
			end
		end

		theAction.addInfo = "playUnlock"

	elseif theAction.addInfo == "doUnlock" then

		if theAction.unlockGroup and #theAction.unlockGroup then
			for i = 1 , #theAction.unlockGroup do
				local pos = theAction.unlockGroup[i]

				local item = mainLogic.gameItemMap[pos.r][pos.c]

				item.lockLevel = 0
				mainLogic:checkItemBlock(pos.r, pos.c)
				mainLogic:addNeedCheckMatchPoint(pos.r, pos.c)
				mainLogic.gameMode:checkDropDownCollect(pos.r, pos.c)
				ColorFilterLogic:handleFilter(pos.r, pos.c)
				
				Blocker206Logic:cancelEffectByLock(mainLogic)
				mainLogic:setNeedCheckFalling()
			end
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Blocker206, ObstacleFootprintAction.k_Unlocked, #theAction.unlockGroup)
		end

		mainLogic.destroyActionList[actid] = nil
	end

end

function DestroyItemLogic:runningGameItemActionColorFilterBDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		local newLevel = theAction.newLevel

		if newLevel <= 0 then
			local r1 = theAction.ItemPos1.x
			local c1 = theAction.ItemPos1.y
			
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r1, c1, Blocker195CollectType.kColorFilter)
			SquidLogic:checkSquidCollectItem(mainLogic, r1, c1, TileConst.kColorFilter)

			local itemData = mainLogic.gameItemMap[r1][c1]
			itemData:setColorFilterBLock(false)

			local boardData = mainLogic.boardmap[r1][c1]
			boardData.colorFilterState = ColorFilterState.kStateA
			boardData.isNeedUpdate = true
			boardData.colorFilterBLevel = 0
			
			mainLogic:checkItemBlock(r1, c1)
			ColorFilterLogic:handleFilter(r1, c1) 
			mainLogic:addNeedCheckMatchPoint(r1, c1)
			mainLogic.gameMode:checkDropDownCollect(r1, c1)
			mainLogic:setNeedCheckFalling()
			mainLogic:tryBombSuperTotemsByForce()
		end 

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionBlocker195Dec(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r1, c1 = theAction.ItemPos1.x,theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r1][c1]

		GameExtandPlayLogic:decreaseLotus(mainLogic, r1, c1 , 1)
		SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, r1, c1)
		SpecialCoverLogic:SpecialCoverLightUpAtBlocker(mainLogic, r1, c1, 1, item:isBlocker195Available())
		
		item:cleanAnimalLikeData()
		mainLogic:setNeedCheckFalling()
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Blocker195, ObstacleFootprintAction.k_Attack, 1)

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionPlayEliminateMusic(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kRunning then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionBlockerCoverDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then

		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;

		if theAction.newLevel <= 0 then
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r1, c1, Blocker195CollectType.kBlockerCover)
			SquidLogic:checkSquidCollectItem(mainLogic, r1, c1, TileConst.kBlockerCover)
			mainLogic:checkItemBlock( r1 , c1 )
			mainLogic:addNeedCheckMatchPoint(r1, c1)
			mainLogic.gameMode:checkDropDownCollect(r1, c1)
			mainLogic:setNeedCheckFalling()
			mainLogic:tryBombSuperTotemsByForce()
		end

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionBlockerCoverMaterialDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionTangChicken(mainLogic, theAction, actid, actByView)		
	if theAction.actionStatus == GameActionStatus.kRunning then
		if not theAction.hasCollectedNum then
			theAction.actTick = theAction.actTick or 0
			theAction.actTick = theAction.actTick + 1
			if theAction.actTick >= GamePlayConfig_TangChicken_Destroy1_Time then
				theAction.hasCollectedNum = true
				if mainLogic.gameMode:is(SpringHorizontalEndlessMode) then
					mainLogic.gameMode:collectChicken(theAction.tangChickenNum)
				end
			end
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r,c = theAction.ItemPos1.x,theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		item:cleanAnimalLikeData()
		item.isUsed = false

		local boardData = mainLogic.boardmap[r][c]
		boardData.isUsed = false

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionMissileHitSingle(mainLogic, theAction, actid, actByView)

	if (theAction.addInfo == "over") then
		local function bombItem(r, c)
			local item = mainLogic.gameItemMap[r][c]
			local boardData = mainLogic.boardmap[r][c]

            local SpecialID = mainLogic:addSrcSpecialCoverToList( ccp(theAction.ItemPos1.y,theAction.ItemPos1.x) )
           	
			BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1, nil, nil, ObstacleFootprintType.k_Missile)
			SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, nil, nil, nil, nil, ObstacleFootprintType.k_Missile, SpecialID) 
			-- SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c) 
			SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
			GameExtandPlayLogic:doABlocker211Collect(mainLogic, theAction.ItemPos1.y, theAction.ItemPos1.x, r, c, 0, true, 3)
		end

		bombItem(theAction.ItemPos2.y,theAction.ItemPos2.x)

		if (theAction.completeCallback ) then
			theAction.completeCallback()
			mainLogic:setNeedCheckFalling()
		end
		mainLogic.destroyActionList[actid] = nil 
	end

end

function DestroyItemLogic:runningGameItemActionMissileFire(mainLogic, theAction, actid, actByView)

	if theAction.actionStatus == GameActionStatus.kRunning then
		-- 随机选择若干位置发射
		-- 等爆炸动画播放完成之后，发射导弹
		if (theAction.counter == 15) then
			theAction.allMissileChildActionComplete = false
			theAction.totalAttackPosition = 0
			local missileHitCount = 0
			local missileChildHitCallback = function()
				missileHitCount = missileHitCount + 1
				if (missileHitCount >= theAction.totalAttackPosition) then
					theAction.allMissileChildActionComplete = true
				end
			end

			-- 全部将要发射的冰封导弹
			for i,missile in ipairs(theAction.missiles) do
				-- 每一个冰封导弹，分裂成mainLogic.missileSplit个小弹头
				-- 按照优先级随机 mainLogic.missileSplit 个位置
				local targetPositions = GameExtandPlayLogic:findMissileTarget(mainLogic,missile, mainLogic.missileSplit)
				-- if _G.isLocalDevelopMode then printx(0, #targetPositions,"targetPositions",table.tostring(targetPositions)) end
				theAction.totalAttackPosition = theAction.totalAttackPosition + #targetPositions
				
				if (#targetPositions > 0) then
					for _,toPosition in ipairs(targetPositions) do

						local actionDeleteByMissile = GameBoardActionDataSet:createAs(
							GameActionTargetType.kGameItemAction,
							GameItemActionType.kMissileHitSingle, 
							IntCoord:create(missile.x, missile.y),	-- from positoin
							toPosition,	-- toPosition
							GamePlayConfig_MaxAction_time
							)
						actionDeleteByMissile.completeCallback = missileChildHitCallback
						-- actionDeleteByMissile.delayIndex = i * 12
						mainLogic:addDestroyAction(actionDeleteByMissile)
						mainLogic:setNeedCheckFalling()
					end
				else
					missileChildHitCallback()
				end

			end
		end

		if (theAction.addInfo == "fired" and theAction.allMissileChildActionComplete ) then
			if (theAction.completeCallback ) then
				theAction.completeCallback()
				mainLogic.destroyActionList[actid] = nil 
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionMissileFireView(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.counter = 0

		for i,itemView in ipairs(theAction.missileViews) do
			if itemView and itemView:getGameItemSprite() then
				itemView:getGameItemSprite():fire()
			end
		end

	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if (theAction.counter == 45) then
			theAction.addInfo = "fired"
		end
	end

	theAction.counter = theAction.counter + 1
end

function DestroyItemLogic:runGameItemActionMissileHitSingleView(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		-- 发射导弹动画
		theAction.counter = 0

		local fromPos = theAction.ItemPos1
		local toPos = theAction.ItemPos2

		local missilePos = IntCoord:clone(fromPos)
		local itemView = boardView.baseMap[toPos.y][toPos.x]
		if itemView then 
			itemView:playMissileFlyAnimation(missilePos,function()  
				if _G.isLocalDevelopMode then printx(0, "playMissileFlyAnimation callback",toPos.y,toPos.x) end
				-- 在指定位置上播放爆炸动画
				if itemView then 
					itemView:playMissleBombAnimation()
				end
			end)
		end



	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if (theAction.counter == 30) then
			theAction.addInfo = "over"
		end
		theAction.counter = theAction.counter + 1
	end
end

function DestroyItemLogic:runningGameItemActionOlympicIceDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "start" then
		theAction.addInfo = ""
		if mainLogic.PlayUIDelegate then
			local olympicTopNode = mainLogic.PlayUIDelegate.olympicTopNode
			if olympicTopNode then
				local r1 = theAction.ItemPos1.x
				local c1 = theAction.ItemPos1.y
				local item = mainLogic.boardView.baseMap[r1][c1]
				local fromPos = mainLogic.boardView:convertToWorldSpace(item:getBasePosition(c1, r1))
				local colId = c1 + mainLogic.passedCol

				local hasLight = GameExtandPlayLogic:checkHasLightsInCol(mainLogic, c1)
				olympicTopNode:playFlyToHoleEffect(colId, fromPos, not hasLight)
			end
		end
	elseif theAction.addInfo == "over" then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionOlympicIceDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"

		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;
		local item = boardView.baseMap[r1][c1];
		local function onAnimCompleted()
			theAction.addInfo = "over"
		end
		local iceLevel = theAction.addInt
		item:playOlympicIceDecEffect(iceLevel, onAnimCompleted)
	end
end

function DestroyItemLogic:runningGameItemActionOlympicBlockDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "start" then
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		if theAction.addInt > 1 then
			item.isNeedUpdate = true
		else
			item.isNeedUpdate = true
			-- if mainLogic.gameMode:is(OlympicHorizontalEndlessMode) then
			-- 	mainLogic.gameMode:updateWaitSteps(mainLogic.gameMode.olympicWaitSteps + 3)
			-- end
		end
		theAction.addInfo = "wait"
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionOlympicBlockDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.addInfo = "start"
		theAction.actionStatus = GameActionStatus.kRunning
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		local function onAnimCompleted()
			-- theAction.addInfo = "over"
		end
		itemView:playOlympicBlockerDecEffect(theAction.addInt, onAnimCompleted)
	end
end

function DestroyItemLogic:runningGameItemActionOlympicLockDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "start" then
		theAction.hasMatched = true
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		item.isNeedUpdate = true
		theAction.addInfo = "wait"
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		if theAction.addInt <= 1 then
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
			mainLogic:checkItemBlock(r, c)
			mainLogic:addNeedCheckMatchPoint(r, c)
			mainLogic:setNeedCheckFalling(r, c)
			FallingItemLogic:preUpdateHelpMap(mainLogic)
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionOlympicLockDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playOlympicLockDecEffect(theAction.addInt)

		GamePlayMusicPlayer:playEffect(GameMusicType.kSnowBreak)
	end
end

function DestroyItemLogic:runGameItemActionMaydayBossDie(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning 
		theAction.actionTick = 0

		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local fromItem = boardView.baseMap[r][c]
		local addMoveItems = theAction.addMoveItemPos
		local questionItems = theAction.questionItemPos
		local dripPos = theAction.dripPos
		if not dripPos then dripPos = {} end

		local function dropCallback()
			-- if not theAction.completeCount then theAction.completeCount = 0 end
			-- theAction.completeCount = theAction.completeCount + 1
			-- if theAction.completeCount >= #addMoveItems + #questionItems + #dripPos then
			-- 	theAction.addInfo = 'dropped'
			-- end
		end
		if #addMoveItems == 0 and #questionItems == 0 and #dripPos == 0 then
			dropCallback()
		else
			for k, v in pairs(addMoveItems) do 
				local item = boardView.baseMap[v.r][v.c]
				item:playMaydayBossChangeToAddMove(boardView, fromItem, dropCallback)
			end
			for k, v in pairs(questionItems) do 
				local item = boardView.baseMap[v.r][v.c]
				item:playMaydayBossChangeToAddMove(boardView, fromItem, dropCallback)
			end

			for k, v in pairs(dripPos) do 
				local item = boardView.baseMap[v.r][v.c]
				item:playMaydayBossChangeToAddMove(boardView, fromItem, dropCallback)
			end
		end
		setTimeOut(function () GamePlayMusicPlayer:playEffect(GameMusicType.kWeeklyBossDie) end, 0.60)		
		theAction.addInfo = "dropAction"
		theAction.actionTick = 0
	elseif theAction.addInfo == 'dropped' then
		theAction.addInfo = "dieAction"
		theAction.actionTick = 0
		local function dieCallback()
			-- theAction.addInfo = 'over'
		end
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:playMaydayBossDie(self, dieCallback)
	end
end

function DestroyItemLogic:runnningGameItemActionBossDie(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kRunning  then
		theAction.actionTick = theAction.actionTick + 1

		local function cleanItem(r, c)
			local item = mainLogic.gameItemMap[r][c]
			local board = mainLogic.boardmap[r][c]
			item:cleanAnimalLikeData()
			item.isDead = false
			item.isBlock = false
			item.isNeedUpdate = true
			mainLogic:checkItemBlock(r, c)
		end
		local function isNormal(item)
	        if item.ItemType == GameItemType.kAnimal
	        and item.ItemSpecialType ~= AnimalTypeConfig.kColor
	        and item:isAvailable()
	        and not item:hasLock() 
	        and not item:hasFurball()
	        then
	            return true
	        end
	        return false
	    end

		if theAction.addInfo == "dropAction" and theAction.actionTick == 30 then
			theAction.addInfo = 'dropped'
			local addMoveItems = theAction.addMoveItemPos
			local questionItems = theAction.questionItemPos
			local dripPos = theAction.dripPos
			if not dripPos then dripPos = {} end
			for k, v in pairs(addMoveItems) do
				local item = mainLogic.gameItemMap[v.r][v.c]
				if isNormal(item) then
					item.ItemType = GameItemType.kAddMove
					item:initAddMoveConfig(mainLogic.addMoveBase)
					item.isNeedUpdate = true
				end
			end
			for k, v in pairs(questionItems) do
				local item = mainLogic.gameItemMap[v.r][v.c]
				if isNormal(item) then
					assert(item._encrypt.ItemColorType, "ItemColorType should not be nil")
					item.ItemType = GameItemType.kQuestionMark
					item.isProductByBossDie = true
					mainLogic:onProduceQuestionMark(v.r, v.c)
					-- item:initAddMoveConfig(mainLogic.addMoveBase)
					item.isNeedUpdate = true
				end
			end
			for k, v in pairs(dripPos) do
				local item = mainLogic.gameItemMap[v.r][v.c]
				if isNormal(item) then
					item.ItemType = GameItemType.kDrip
					item._encrypt.ItemColorType = AnimalTypeConfig.kDrip
					item:AddItemStatus( GameItemStatusType.kNone , true )
					item.dripState = DripState.kNormal
					item.isNeedUpdate = true
					mainLogic:addNeedCheckMatchPoint(v.r , v.c)
				end
			end
		elseif theAction.addInfo == "dieAction" and theAction.actionTick == 75 then
			theAction.addInfo = 'over'
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
			GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
			cleanItem(r, c)
			cleanItem(r + 1, c)
			cleanItem(r, c+1)
			cleanItem(r+ 1, c+1)
			mainLogic:setNeedCheckFalling()
			FallingItemLogic:preUpdateHelpMap(mainLogic)
		elseif theAction.addInfo == 'over' then
			if theAction.completeCallback then
				theAction.completeCallback()
			end
			mainLogic.destroyActionList[actid] = nil
    	end
	end
end

function DestroyItemLogic:runGameItemActionWeeklyBossDie(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning 
		theAction.actionTick = 0
		theAction.addInfo = "dieAction"
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:playWeeklyBoosDie(self)
	end
end

function DestroyItemLogic:runnningGameItemActionWeeklyBossDie(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kRunning  then
		theAction.actionTick = theAction.actionTick + 1
		local function cleanItem(r, c)
			local item = mainLogic.gameItemMap[r][c]
			local board = mainLogic.boardmap[r][c]
			item:cleanAnimalLikeData()
			item.isDead = false
			item.isBlock = false
			item.isNeedUpdate = true
			mainLogic:checkItemBlock(r, c)
		end

		if theAction.addInfo == "dieAction" and theAction.actionTick == 40 then
			theAction.addInfo = 'over'
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
			GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
			cleanItem(r, c)
			cleanItem(r + 1, c)
			cleanItem(r, c+1)
			cleanItem(r+ 1, c+1)
			mainLogic:setNeedCheckFalling()
			FallingItemLogic:preUpdateHelpMap(mainLogic)
		elseif theAction.addInfo == 'over' then
			if theAction.completeCallback then
				theAction.completeCallback()
			end
			mainLogic.destroyActionList[actid] = nil
    	end
	end
end


function DestroyItemLogic:runGameItemActionInactiveSuperCute(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.actionTick = 1

		local function callback()
			-- theAction.addInfo = "over"
		end
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kSuperCute)
		SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kSuperCute)
		item:playSuperCuteInactive(callback)
	end
end


function DestroyItemLogic:runningGameItemActionInactiveSuperCute(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		-- tick
		theAction.actionTick = theAction.actionTick + 1
		if theAction.actionTick == GamePlayConfig_SuperCute_InactiveTick then
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y

			local board = mainLogic.boardmap[r][c]
			local item = mainLogic.gameItemMap[r][c]

			board.superCuteState = GameItemSuperCuteBallState.kInactive
			board.superCuteInHit = false
			item.beEffectBySuperCute = false

			mainLogic:checkItemBlock(r, c)
			mainLogic:addNeedCheckMatchPoint(r, c)
			mainLogic.gameMode:checkDropDownCollect(r, c)
			mainLogic:setNeedCheckFalling()

			if item:isActiveTotems() then
				mainLogic:addNewSuperTotemPos(IntCoord:create(r, c))
				mainLogic:tryBombSuperTotems()
			end

			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_SuperCute, ObstacleFootprintAction.k_BackOff, 1)

			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runingGameItemTotemsBombByMatch(mainLogic, theAction, actid)
	mainLogic:tryBombSuperTotems()
	mainLogic.destroyActionList[actid] = nil
end
function DestroyItemLogic:runningGameItemActionDecreaseLotus(mainLogic, theAction, actid)
	--printx( 1 , "   DestroyItemLogic:runningGameItemActionDecreaseLotus   " , actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r1][c1]
		local board = mainLogic.boardmap[r1][c1]

		if theAction.addInfo == "start" then
			
			--theAction.originLotusLevel
			if board.lotusLevel <= 0 then
				theAction.addInfo = "over"
			else
				theAction.addInfo = "playAnimation"
				theAction.viewJSQ = 0
				theAction.viewJSQTarget = 0
				theAction.currLotusLevel = board.lotusLevel

				local addScore = 0
				if board.lotusLevel == 3 then
					theAction.viewJSQTarget = 17
					addScore = GamePlayConfigScore.LotusLevel3
				elseif board.lotusLevel == 2 then
					theAction.viewJSQTarget = 13
					addScore = GamePlayConfigScore.LotusLevel2
				elseif board.lotusLevel == 1 then
					theAction.viewJSQTarget = 10
					addScore = GamePlayConfigScore.LotusLevel1
				end

				board.lotusLevel = board.lotusLevel - 1
				if board.lotusLevel < 0 then board.lotusLevel = 0 end
				item.lotusLevel = board.lotusLevel

				mainLogic.lotusEliminationNum = mainLogic.lotusEliminationNum + 1

				----[[
				mainLogic:addScoreToTotal(r1, c1, addScore)
				--]]
			end
			

		elseif theAction.addInfo == "playing" then

			if theAction.viewJSQ == 0 then
				
				if board.lotusLevel == 0 and theAction.currLotusLevel == 1 then
					board.isBlock = false

					mainLogic.currLotusNum = mainLogic.currLotusNum - 1
					mainLogic.destroyLotusNum = mainLogic.destroyLotusNum + 1

					local pos = mainLogic:getGameItemPosInView(r1, c1)
					if mainLogic.PlayUIDelegate.targetType == kLevelTargetType.order_lotus then --内有assert，会报错
						mainLogic.PlayUIDelegate:setTargetNumber(0, 0, mainLogic.currLotusNum, pos)
					end
					ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Lotus, ObstacleFootprintAction.k_Eliminate, 1)
				end
				board.isNeedUpdate = true
				if item and item.ItemType == GameItemType.kPacman then
					--- 吃豆人造成消除时不马上更新视图，等吃豆人吃完再统一更新
				else
					item.isNeedUpdate = true
				end
				mainLogic:checkItemBlock(r1, c1)

			end

			theAction.viewJSQ = theAction.viewJSQ + 1
			if theAction.viewJSQ >= theAction.viewJSQTarget then
				theAction.addInfo = "over"
			end
		elseif theAction.addInfo == "over" then

			if board.lotusLevel >= 0 and board.lotusLevel <= 2 then

				mainLogic:addNeedCheckMatchPoint(r1, c1)
				mainLogic:setNeedCheckFalling()
			end
			mainLogic.destroyActionList[actid] = nil
		end
	end
	
end

function DestroyItemLogic:runningGameItemActionCrystalStoneDestroy(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local gameItem = mainLogic.gameItemMap[r1][c1]

		if not theAction.hasBreakedLightUp then
			local condition = false
			if gameItem.ItemType == GameItemType.kCrystalStone and gameItem:isCrystalStoneActive() then
				condition = true
			end
			SpecialCoverLogic:SpecialCoverLightUpAtBlocker(mainLogic, r1, c1, 5, condition)
			theAction.hasBreakedLightUp = true
		end

		if theAction.actionDuring == 0 or 
			(theAction.isSpecial and theAction.actionDuring == GamePlayConfig_SpecialBomb_CrystalStone_Destory_Time2) then
			if gameItem.ItemType == GameItemType.kCrystalStone then	 -----动物
				gameItem:cleanAnimalLikeData()
				mainLogic:setNeedCheckFalling()
				if mainLogic.boardmap[r1][c1] and mainLogic.boardmap[r1][c1].lotusLevel and mainLogic.boardmap[r1][c1].lotusLevel > 0 then
					GameExtandPlayLogic:decreaseLotus( mainLogic, r1, c1 , 1)
				end

				if theAction.isSpecial then -- 消除一层冰
					SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r1, c1, 1, false)
				end

				ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_CrystalStone, ObstacleFootprintAction.k_Attack, 1)
			end

			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runGameItemMagicStoneActive(mainLogic, theAction, actid, actByView)
	local r,c  = theAction.ItemPos1.x, theAction.ItemPos1.y
	local stoneActiveAction = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItem_Magic_Stone_Active,
			IntCoord:create(r, c),
			nil,
			GamePlayConfig_MaxAction_time)

	stoneActiveAction.magicStoneLevel = theAction.magicStoneLevel
	stoneActiveAction.targetPos = theAction.targetPos

	mainLogic:addDestructionPlanAction(stoneActiveAction)

	ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_MagicStone, ObstacleFootprintAction.k_Hit, 1)

	mainLogic.destroyActionList[actid] = nil
end

function DestroyItemLogic:runGameItemQuestionMarkProtect(mainLogic, theAction, actid, actByView)
	-- body
	local gameItemMap = mainLogic.gameItemMap
	local leftItem = 0
	for r = 1, #gameItemMap do 
		for c = 1, #gameItemMap[r] do 
			local item = gameItemMap[r][c]
			if item.questionMarkProduct > 0 then

				item.questionMarkProduct = item.questionMarkProduct - 1
				if item.questionMarkProduct == 1 then
					mainLogic:addNeedCheckMatchPoint(r, c)
				end

				if item.questionMarkProduct > 0 then
					leftItem = leftItem + 1
				end
			end
		end
	end
	
	if leftItem == 0 then
		mainLogic.hasQuestionMarkProduct = nil
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionIceDec(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionHoneyDec(mainLogic, theAction, actid, actByView)
	-- body
	if not theAction.hasMatch then
		theAction.hasMatch = true
		local r,c  = theAction.ItemPos1.x, theAction.ItemPos1.y
		mainLogic.gameItemMap[r][c].isNeedUpdate = true
		mainLogic.gameItemMap[r][c].digBlockCanbeDelete = true
		mainLogic:checkItemBlock(r, c)
		mainLogic:addNeedCheckMatchPoint(r, c)
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionWitchBomb(mainLogic, theAction, actid, actByView)

	if theAction.addInfo == 'over' then

		local interval = theAction.interval
		local intervalFrames = math.floor(interval * 60)
		theAction.frameCount = theAction.frameCount - 1
		if theAction.frameCount <= 0 and theAction.col > 0 then
			-- if _G.isLocalDevelopMode then printx(0, 'theAction.col', theAction.col) end

			local col = theAction.col
			local rowList = theAction.rows
			for i = 1, #rowList do
				local row = rowList[i]

				local item
				if mainLogic.gameItemMap[row] then
					item = mainLogic.gameItemMap[row][col]
				end
				if item and item.isEmpty == false then
					SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, row, col, 1, true)  --可以作用银币
					BombItemLogic:tryCoverByBomb(mainLogic, row, col, true, 1)
					SpecialCoverLogic:SpecialCoverAtPos(mainLogic, row, col, 3, nil, actid)
				end

				SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, row, col)
				if i == 1 then
					SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, row - 1, col, {ChainDirConfig.kDown})
				elseif i == #rowList then
					SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, row + 1, col, {ChainDirConfig.kUp})
				end
			end

			theAction.col = theAction.col - 1
			theAction.frameCount = intervalFrames
		end
		if theAction.col <= 0 then
			-- if _G.isLocalDevelopMode then printx(0, 'action over') end
			mainLogic:resetSpecialEffectList(actid)  --- 特效生命周期中对同一个障碍(boss)的作用只有一次的保护标志位重置
			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runningGameItemActionHoneyBottleIncrease(mainLogic, theAction, actid, actByView)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
        local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
        local itemData = mainLogic.gameItemMap[r][c]
        itemData.isNeedUpdate = true

		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_HoneyBottle, ObstacleFootprintAction.k_Hit, theAction.addInt)
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionMagicLampCharging(mainLogic, theAction, actid, actByView)
	local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
	local item = mainLogic.gameItemMap[r][c]

	-- bonus time不充能
	-- 灰色的不能充能
	if not item or item.ItemType ~= GameItemType.kMagicLamp
	or mainLogic.isBonusTime
	or item.lampLevel == 0 then
		mainLogic.destroyActionList[actid] = nil
		return
	end

	local oldLampLevel = item.lampLevel
	local count = theAction.count
	if item.lampLevel + count >= 5 then
		item.lampLevel = 5
	else
		item.lampLevel = item.lampLevel + count
	end
	ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_MagicLamp, ObstacleFootprintAction.k_Hit, item.lampLevel - oldLampLevel)

	local itemV = mainLogic.boardView.baseMap[r][c]
	itemV:setMagicLampLevel(item.lampLevel)

	-- 加上匹配检查点， 防止出现不三消的情况
	mainLogic:checkItemBlock(r,c)
	mainLogic:setNeedCheckFalling()
	mainLogic:addNeedCheckMatchPoint(r, c)
	mainLogic.destroyActionList[actid] = nil
end

function DestroyItemLogic:runningGameItemActionMonsterJump( mainLogic, theAction, actid, actByView )
	-- body
	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local gameItemMap = mainLogic.gameItemMap
		local itemList = {gameItemMap[r][c], gameItemMap[r][c+1], gameItemMap[r+1][c], gameItemMap[r+1][c+1]}
		for k, v in pairs(itemList) do 
			v:cleanAnimalLikeData()
			mainLogic:checkItemBlock(v.y,v.x)
		end
		mainLogic.destroyActionList[actid] = nil
		FallingItemLogic:preUpdateHelpMap(mainLogic)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_BigMonster, ObstacleFootprintAction.k_Eliminate, 1)

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
	end

end

function DestroyItemLogic:runningGameItemActionMaydayBossLossBlood(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemActionWeeklyBossLossBlood(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runningGameItemAction(mainLogic, theAction, actid)
	if theAction.actionType == GameItemActionType.kItemSpecial_Color_ItemDeleted 
		or theAction.actionType == GameItemActionType.kItemSpecial_ColorColor_ItemDeleted then 			----鸟和普通动物交换，引起同色动物的消除
		DestroyItemLogic:runingGameItemSpecialBombColorAction_ItemDeleted(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_CollectIngredient then
		DestroyItemLogic:runningGameItem_CollectIngredient(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_Mimosa_back then
		DestroyItemLogic:runningGameItemActionMimosaBack(mainLogic, theAction, actid)
	elseif theAction.actionType == GameItemActionType.kItem_KindMimosa_back then
		DestroyItemLogic:runningGameItemActionKindMimosaBack(mainLogic, theAction, actid)
	end
end

function DestroyItemLogic:runViewAction(boardView, theAction)
	if theAction.actionType == GameItemActionType.kItemDeletedByMatch then 			----Match消除
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemDeletedByMatchAction(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItemCoverBySpecial_Color then  		----cover消除
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionCoverBySpecial(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItemSpecial_Color_ItemDeleted 
		or theAction.actionType == GameItemActionType.kItemSpecial_ColorColor_ItemDeleted then 		----魔力鸟引起的消除
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionBombSpecialColor_ItemDeleted(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItem_CollectIngredient then
		if theAction.addInfo == "Pass" then
			DestroyItemLogic:runGameItemActionCollectIngredient(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_SnowDec then 		----产生雪块消除特效
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionSnowDec(boardView, theAction)
		else
			local r1 = theAction.ItemPos1.x
			local c1 = theAction.ItemPos1.y
			if boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowShow]~= nil
				and boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowShow]:getParent() then ----已经被正常添加了父节点，删除特殊效果
				boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowShow] = nil
			end
			if boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow]~= nil
				and boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow]:getParent() then ----已经被正常添加了父节点，删除特殊效果
				boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow] = nil
			end
			if boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow2]~= nil
				and boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow2]:getParent() then ----已经被正常添加了父节点，删除特殊效果
				boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kSnowSkinShow2] = nil
			end
		end
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_VenowDec then
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionVenomDec(boardView, theAction)
		end
	elseif theAction.actionType ==  GameItemActionType.kItem_Furball_Grey_Destroy then
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionGreyFurballDestroy(boardView, theAction)
		elseif theAction.actionStatus == GameActionStatus.kRunning then
			DestroyItemLogic:runningGameItemActionGreyFurballDestroy(boardView, theAction)	
		end
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_LockDec then 		----产生牢笼消除特效
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionLockDec(boardView, theAction)
		else
			local r1 = theAction.ItemPos1.x;
			local c1 = theAction.ItemPos1.y;
			if boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kLockShow]~= nil
				and boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kLockShow]:getParent() then ----已经被正常添加了父节点，删除特殊效果
				boardView.baseMap[r1][c1].itemSprite[ItemSpriteType.kLockShow] = nil;
			end
		end
	elseif theAction.actionType == GameItemActionType.kItem_Roost_Upgrade then
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemActionRoostUpgrade(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItem_DigGroundDec then
		DestroyItemLogic:runGameItemViewDigGroundDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_DigJewleDec then 
		DestroyItemLogic:runGameItemViewDigJewelDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_randomPropDec then 
		DestroyItemLogic:runGameItemViewRandomPropDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Bottle_Blocker_Explode then 
		DestroyItemLogic:runGameItemViewBottleBlockerDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Monster_frosting_dec then 
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemViewMonsterFrostingDec(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItem_chestSquare_part_dec then 
		DestroyItemLogic:runGameItemViewChestSquarePartDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Black_Cute_Ball_Dec then
		if theAction.actionStatus == GameActionStatus.kWaitingForStart then
			DestroyItemLogic:runGameItemViewBlackCuteBallDec(boardView, theAction)
		end
	elseif theAction.actionType == GameItemActionType.kItem_Mimosa_back then
		DestroyItemLogic:runGameItemActionMimosaBack(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_KindMimosa_back then
		DestroyItemLogic:runGameItemActionKindMimosaBack(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Mayday_Boss_Loss_Blood then
		DestroyItemLogic:runGameItemActionBossLossBlood(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Weekly_Boss_Loss_Blood then
		DestroyItemLogic:runGameItemActionWeeklyBossLossBlood(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Wukong_Charging then
		DestroyItemLogic:runGameItemViewActionWukongCharging(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Magic_Lamp_Charging then
		theAction.actionStatus = GameActionStatus.kRunning
	elseif theAction.actionType == GameItemActionType.kItem_WitchBomb then
		DestroyItemLogic:runGameItemActionWitchBomb(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Honey_Bottle_increase then 
		DestroyItemLogic:runGameItemActionHoneyBottleInc(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemDestroy_HoneyDec then
		DestroyItemLogic:runGameItemActionHoneyDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Sand_Clean then
		DestroyItemLogic:runGameItemActionSandClean(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_IceDec then
		DestroyItemLogic:runGameItemActionIceDec(boardView, theAction)	
	elseif theAction.actionType == GameItemActionType.kItem_Monster_Jump then
		DestroyItemLogic:runGameItemActionMonsterJump( boardView, theAction )
	elseif theAction.actionType == GameItemActionType.kItem_ChestSquare_Jump then
		DestroyItemLogic:runGameItemActionChestSquareJump( boardView, theAction )
	elseif theAction.actionType == GameItemActionType.kItemSpecial_CrystalStone_Destroy then
		DestroyItemLogic:runGameItemActionCrystalStoneDestroy( boardView, theAction )
	elseif theAction.actionType == GameItemActionType.kItem_Totems_Change then
		DestroyItemLogic:runGameItemTotemsChangeAction(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SuperTotems_Bomb_By_Match then
	elseif theAction.actionType == GameItemActionType.kItem_Decrease_Lotus then
		DestroyItemLogic:runGameItemDecreaseLotusAction(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SuperCute_Inactive then
		DestroyItemLogic:runGameItemActionInactiveSuperCute(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Mayday_Boss_Die then
		DestroyItemLogic:runGameItemActionMaydayBossDie(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Weekly_Boss_Die then
		DestroyItemLogic:runGameItemActionWeeklyBossDie(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_OlympicLockDec then
		DestroyItemLogic:runGameItemActionOlympicLockDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_OlympicBlockDec then
		DestroyItemLogic:runGameItemActionOlympicBlockDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_Olympic_IceDec then
		DestroyItemLogic:runGameItemActionOlympicIceDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kMissileHit then
		DestroyItemLogic:runGameItemActionMissileHitView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_BlockerCoverMaterialDec then
		DestroyItemLogic:runGameItemActionBlockerCoverMaterialDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Blocker_Cover_Dec then
		DestroyItemLogic:runGameItemActionBlockerCoverDec(boardView, theAction) 
	elseif theAction.actionType == GameItemActionType.kMissileFire then
		DestroyItemLogic:runGameItemActionMissileFireView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kDynamiteSetOff then
		DestroyItemLogic:runGameItemActionDynamiteSetOffView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kMissileHitSingle then
		DestroyItemLogic:runGameItemActionMissileHitSingleView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kDynamiteHitSingle then
		DestroyItemLogic:runGameItemActionDynamiteHitSingleView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_TangChicken_Destroy then
		DestroyItemLogic:runGameItemActionTangChickenView(boardView, theAction)			
	elseif theAction.actionType == GameItemActionType.kEliminateMusic then
		DestroyItemLogic:runGameItemActionPlayEliminateMusic(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Blocker195_Dec then
		DestroyItemLogic:runGameItemActionBlocker195Dec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_ColorFilterB_Dec then
		DestroyItemLogic:runGameItemActionColorFilterBDec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Blocker206_Dec then
		DestroyItemLogic:runGameItemActionBlocker206Dec(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Blocker207_Dec then
		DestroyItemLogic:runGameItemActionBlocker207Dec(boardView, theAction)			
	elseif theAction.actionType == GameItemActionType.kItem_Chameleon_transform then
		DestroyItemLogic:runGameItemActionChameleonTransformView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_pacman_eatTarget then
		DestroyItemLogic:runGameItemActionPacmanEatTargetView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_pacman_blow then
		DestroyItemLogic:runGameItemActionPacmanBlowView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_pacmansDen_generate then
		DestroyItemLogic:runGameItemActionPacmanGenerateView(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_Turret_upgrade then
		DestroyItemLogic:runGameItemActionTurretUpgradeView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_MoleWeekly_Magic_Tile_Blast then
		DestroyItemLogic:runGameItemActionMoleWeeklyMagicTileBlastView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_MoleWeekly_Boss_Cloud_Die then
		DestroyItemLogic:runGameItemActionMoleWeeklyBossCloudDieView(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_YellowDiamondDec then
		DestroyItemLogic:runGameItemViewYellowDiamond(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_ghost_move then
		DestroyItemLogic:runGameItemActionGhostMoveView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_ghost_collect then
		DestroyItemLogic:runGameItemActionGhostCollectView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SunFlask_Blast then
		DestroyItemLogic:runGameItemActionSunFlaskBlastView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SunFlower_Blast then
		DestroyItemLogic:runGameItemActionSunFlowerBlastView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Squid_Collect then
		DestroyItemLogic:runGameItemActionSquidCollectView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Squid_Run then
		DestroyItemLogic:runGameItemActionSquidRunView(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_WanSheng_increase then 
		DestroyItemLogic:runGameItemActionWanShengInc(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItemMatchAt_ApplyMilk then
		DestroyItemLogic:runningGameItemActionApplyMilkView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_gyroCreater_generate then
		DestroyItemLogic:runGameItemActionGyroGenerateView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_gyro_upgrade then
		DestroyItemLogic:runGameItemActionGyroUpgradeView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_gyroCreater_delete then
		DestroyItemLogic:runGameItemActionGyroRemoveView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_RailRoad_Skill2 then 
		DestroyItemLogic:runGameItemActionRailRoadSkill2View(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_RailRoad_Skill3 then 
		DestroyItemLogic:runGameItemActionRailRoadSkill3View(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_RailRoad_Skill4 then 
		DestroyItemLogic:runGameItemActionRailRoadSkill4View(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Water_Attack then 
		DestroyItemLogic:runGameItemActionAttackWaterView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WaterBucket_Charge then
		DestroyItemLogic:runGameItemActionChargeBucketView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WaterBucket_Ready then
		DestroyItemLogic:runGameItemActionReadyBucketView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WaterBucket_Attack then
		DestroyItemLogic:runGameItemActionAttackBucketView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WindTunnelSwitch_Demolish then
		DestroyItemLogic:runGameItemActionWindTunnelSwitchDemolishView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kAct8001 then
		DestroyItemLogic:runGameItemActionAct8001View(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kAct8001_Cast_Skill then
		DestroyItemLogic:runGameItemActionAct8001CastSkillView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kActivityCollectionItemHide then
		DestroyItemLogic:runGameItemActionActivityCollectionItemHideView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Hero_Walk then
		DestroyItemLogic:runGameItemActionHeroWalkView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Hero_Attack then
		DestroyItemLogic:runGameItemActionHeroAttackView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Open_Event_Box then
		DestroyItemLogic:runGameItemActionTravelEventOpenBoxView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag then
		DestroyItemLogic:runGameItemActionTravelEventEnergyBagView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Route then
		DestroyItemLogic:runGameItemActionTravelEventBombRouteView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Heart then
		DestroyItemLogic:runGameItemActionTravelEventBombHeartView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Absorb_Energy_Bag then
		DestroyItemLogic:runGameItemActionTravelEnergyBagDemolishView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Travel_Add_Step_Skill then
		DestroyItemLogic:runGameItemActionTravelAddStepSkillView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Plane_Fly_To_Grid then
		DestroyItemLogic:runGameItemActionPlaneFlyToGridView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WeeklyRace2020_Chest_Hit then
		DestroyItemLogic:runGameItemActionWeeklyRace2020ChestHitView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_WeeklyRace2020_Heart_Smash then
		DestroyItemLogic:runGameItemActionWeeklyRace2020HeartSmashView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cattery_Rolling then
		DestroyItemLogic:runGameItemActionCatteryRollingView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cattery_Split then
		DestroyItemLogic:runGameItemActionCatterySplitView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Meow_Collect then
		DestroyItemLogic:runGameItemActionMeowCollectView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cattery_Hit_Once then
		DestroyItemLogic:runGameItemActionCatteryHitOnceView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Angry_Bird_Walk then
		DestroyItemLogic:runGameItemActionAngryBirdWalkView(boardView,theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Angry_Bird_Shot then
		DestroyItemLogic:runGameItemActionAngryBirdShotView(boardView,theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SlyBunnyLane_Demolish then
		DestroyItemLogic:runGameItemActionSlyBunnyLaneDemolishView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kFly_Board then
		DestroyItemLogic:runGameItemActionFlyBoardView(boardView,theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Walk_Chick_Walk then
		DestroyItemLogic:runGameItemActionChickWalkView(boardView,theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Channel_Water_Target then
		DestroyItemLogic:runGameItemActionChannelWaterTargetView(boardView,theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cuckoo_Absorb_Energy then
		DestroyItemLogic:runGameItemActionCuckooWindupKeyDemolishView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cuckoo_Bird_Walk then
		DestroyItemLogic:runGameItemActionCuckooBirdWalkView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cuckoo_Bird_Attack then
		DestroyItemLogic:runGameItemActionCuckooBirdAttackView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kFirework_Trigger then
		DestroyItemLogic:runGameItemActionFireworkTriggerView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Shell_Gift_Break then
		DestroyItemLogic:runGameItemActionShellGiftBreakView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kFirework_Dec_Level then
		DestroyItemLogic:runGameItemActionFireworkDecLevelView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kBattery_Dec_Level then
		DestroyItemLogic:runGameItemActionBatteryDecLevelView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kBattery_Charge_For_Thunderbird then
		DestroyItemLogic:runGameItemActionBatteryChargeView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunny_Dec_Hp then
		DestroyItemLogic:runGameItemActionNDBunnyHpDecView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunny_produce then
		DestroyItemLogic:runGameItemActionNDBunnyProduceView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunny_move then
		DestroyItemLogic:runGameItemActionNDBunnyMoveView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunny_leave then
		DestroyItemLogic:runGameItemActionNDBunnyLeaveView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunnySnow_Dec then
		DestroyItemLogic:runGameItemActionNDBunnySnowHpDecView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_NDBunnyIce_Dec then
		DestroyItemLogic:runGameItemActionNDBunnyIceHpDecView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_Cattery_Ready then
		DestroyItemLogic:runGameItemActionCatteryReadyView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_PuffedRice_Add then
		DestroyItemLogic:runGameItemActionPuffedRiceHpDecView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_PuffedRice_JumpOnce then
		DestroyItemLogic:runGameItemActionPuffedRiceJumpOnceView(boardView, theAction)
	elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill1 then 
		DestroyItemLogic:runGameItemActionSprintFestival2019Skill1View(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill2 then 
		DestroyItemLogic:runGameItemActionSprintFestival2019Skill2View(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill3 then 
		DestroyItemLogic:runGameItemActionSprintFestival2019Skill3View(boardView, theAction)
    elseif theAction.actionType == GameItemActionType.kItem_SpringFestival2019_Skill4 then 
		DestroyItemLogic:runGameItemActionSprintFestival2019Skill4View(boardView, theAction)

	else
		local viewActionMap = {
			[GameItemActionType.kItem_Canevine_Open_Flower] = DestroyItemLogic.runGameItemActionOpenFlowerView,
		}
		with(viewActionMap[theAction.actionType], function ()
			it(DestroyItemLogic, boardView, theAction)
		end)
	end
end

function DestroyItemLogic:runGameItemActionBlocker207Dec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.addInfo = "checkChargeList"

	else

		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local item = boardView.baseMap[r1][c1]
		local fromItemPos = ccp(r1 , c1)

		if theAction.addInfo == "flyEff" then

			if theAction.chargeList and #theAction.chargeList > 0 then
				for i = 1 , #theAction.chargeList do
					local pos = theAction.chargeList[i]
					local item = boardView.baseMap[pos.r][pos.c];
					local itemData = boardView.gameBoardLogic.gameItemMap[pos.r][pos.c]
					itemData.needKeys = itemData.needKeys - 1
					-- printx( 1 , "DestroyItemLogic:runGameItemActionBlocker207Dec  " , pos.r , pos.c )
					item:playBlocker206ChargeAnimation(fromItemPos)
				end
			end

			theAction.addInfo = "waitingForFly"
			theAction.jsq = 0
		elseif theAction.addInfo == "waitingForFly" then
			theAction.jsq = theAction.jsq + 1
			if theAction.jsq >= 50 then
				theAction.addInfo = "over"
				theAction.jsq = 0
			end
		end

	end
end

function DestroyItemLogic:runGameItemActionBlocker206Dec(boardView, theAction)
	--printx(1 , "DestroyItemLogic:runGameItemActionBlocker206Dec   ")
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.addInfo = "waitingForFly"
		theAction.jsq = 0
	else
		if theAction.addInfo == "waitingForFly" then
			theAction.jsq = theAction.jsq + 1
			if theAction.jsq >= 70 then
				theAction.addInfo = "checkNeedUnlockBlocker"
				theAction.jsq = 0
			end
		elseif theAction.addInfo == "playUnlock" then

			printx(1 , "DestroyItemLogic:runGameItemActionBlocker206Dec   playUnlock  #theAction.nextGroup " , #theAction.nextGroup )
			if theAction.nextGroup and #theAction.nextGroup > 0 then
				for i = 1 , #theAction.nextGroup do
					local pos = theAction.nextGroup[i]
					local item = boardView.baseMap[pos.r][pos.c];
					item:playBlocker206ActiveAnimation()
				end
			end

			if theAction.unlockGroup and #theAction.unlockGroup > 0 then
				for i = 1 , #theAction.unlockGroup do
					local pos = theAction.unlockGroup[i]
					local item = boardView.baseMap[pos.r][pos.c];
					item:playBlocker206DestroyAnimation()
				end
			end

			theAction.addInfo = "waitingForUnlock"
			theAction.jsq = 0

		elseif theAction.addInfo == "waitingForUnlock" then
			theAction.jsq = theAction.jsq + 1
			if theAction.jsq >= 60 then
				theAction.addInfo = "doUnlock"
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionColorFilterBDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local oldLevel = theAction.oldLevel
		local newLevel = theAction.newLevel
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local item = boardView.baseMap[r1][c1]
		local colorIndex = theAction.addInt

		item:playColorFilterBDec(oldLevel)
		theAction.jsq = 0
		theAction.maxJsp = 25

		if newLevel <= 0 then 
			item:playColorFilterBDisappear()
		end

		theAction.addInfo = "waitingForAnimation"
	elseif theAction.addInfo == "waitingForAnimation" then 
		theAction.jsq = theAction.jsq + 1
		local newLevel = theAction.newLevel
		if newLevel <= 0 and theAction.jsq == theAction.maxJsp - 5 then 
			local r1 = theAction.ItemPos1.x
			local c1 = theAction.ItemPos1.y
			local item = boardView.baseMap[r1][c1]
			item:showFilterBHideLayers()
		end
		if theAction.jsq >= theAction.maxJsp then
			theAction.addInfo = "over"
		end
	end
end

function DestroyItemLogic:runGameItemActionBlocker195Dec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;
		local item = boardView.baseMap[r1][c1];
		item:playBlocker195DestroyAnimation()
		SpecialCoverLogic:SpecialCoverLightUpAtPos(boardView.gameBoardLogic, r1, c1, 1, true)
	end
end

function DestroyItemLogic:runGameItemActionPlayEliminateMusic(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local music = theAction.music
		if music then
			GamePlayMusicPlayer:playEffect(music)
		end
	end
end

function DestroyItemLogic:runGameItemActionBlockerCoverDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;
		local item = boardView.baseMap[r1][c1];

		local maxJsqs = {15, 60, 60}
		theAction.addInfo = "waitingForAnimation"
		theAction.jsq = 0
		theAction.maxJsq = maxJsqs[theAction.oldLevel]

		item:decreaseBlockerCover(theAction.newLevel)
	else
		if theAction.addInfo == "waitingForAnimation" then
			
			theAction.jsq = theAction.jsq + 1

			if theAction.jsq >= theAction.maxJsq then
				theAction.addInfo = "over"
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionBlockerCoverMaterialDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;
		local item = boardView.baseMap[r1][c1];

		if theAction.newLevel == -1 then
			theAction.addInfo = "over"
			item:playBlockerCoverMaterialWait()
		else
			local maxJsqs = {46, 46, 76}
			theAction.addInfo = "waitingForAnimation"
			theAction.jsq = 0
			theAction.maxJsq = maxJsqs[theAction.oldLevel]
			item:playBlockerCoverMaterialDecEffect(theAction.newLevel)
		end
	else
		if theAction.addInfo == "waitingForAnimation" then
			
			theAction.jsq = theAction.jsq + 1

			if theAction.jsq >= theAction.maxJsq then
				theAction.addInfo = "over"
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionTangChickenView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]

		local gameBoardLogic = boardView.gameBoardLogic
		local function playCollectAnim( fromPos,playEffect )
			gameBoardLogic.gameMode:playCollectEffect()
			-- gameBoardLogic.gameMode:playCollectAnim(fromPos,playEffect,nil,0.3)
		end
		local toPos = gameBoardLogic.gameMode:getCollectPosition()
		itemView:playTangChickenDisappear(playCollectAnim, toPos, theAction.tangChickenNum)	

		-- local function playMusic()
		-- 	GamePlayMusicPlayer:getInstance():playEffect(GameMusicType.kSpring2017Hit)
		-- end
		-- setTimeOut(playMusic, 0.15)
	end
end

function DestroyItemLogic:runGameItemDecreaseLotusAction(boardView, theAction)
	--printx( 1 , "  DestroyItemLogic:runGameItemDecreaseLotusAction  " , theAction.actionStatus , theAction.addInfo)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"
	elseif theAction.addInfo == "playAnimation" then
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]

		if itemView then
			itemView:playLotusAnimation( theAction.currLotusLevel , "out" )
			if theAction.currLotusLevel == 3 then
				itemView:setLotusHoldItemVisible(true)
			end
		end
		theAction.addInfo = "playing"
	end
end

function DestroyItemLogic:runGameItemTotemsChangeAction(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]

		itemView:playTotemsChangeToActive()
	end
end

function DestroyItemLogic:runingGameItemTotemsChangeAction(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]

		if item and item.ItemType == GameItemType.kTotems then
			item.totemsState = GameItemTotemsState.kActive
			
			-- mainLogic:checkItemBlock(r, c)
			-- FallingItemLogic:stopFCFallingByBlock(mainLogic, r, c)
			-- FallingItemLogic:preUpdateHelpMap(mainLogic)
			
			mainLogic:addNewSuperTotemPos(IntCoord:create(r, c))

			if theAction.isBomb then
				mainLogic:tryBombSuperTotems()
			end
		end
	elseif theAction.actionStatus == GameActionStatus.kRunning then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemViewActionWukongCharging( boardView, theAction )

	if not theAction.viewJSQ then theAction.viewJSQ = 0 end
	theAction.viewJSQ = theAction.viewJSQ + 1
	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local itemView = boardView.baseMap[r][c]

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"
		itemView:changeWukongState(TileWukongState.kOnHit)
	elseif theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.addInfo == "playAnimation" then
			
			local fromPositions = theAction.fromPosition
			if fromPositions and #fromPositions > 0 then

				for k,v in pairs(fromPositions) do
					
					local localPosition = v
					local targetPosition = ccp(0,0)
					if itemView.itemSprite[ItemSpriteType.kItemShow] then
						targetPosition = itemView.itemSprite[ItemSpriteType.kItemShow]:convertToWorldSpace(ccp(0,0))
					end
					local sprite = Sprite:createWithSpriteFrameName("wukong_charging_eff")
					sprite:setAnchorPoint(ccp(0.5, 0.5))
					sprite:setPosition(ccp(localPosition.x, localPosition.y))
					--sprite:setScale(math.random()*0.6 + 0.7)
					sprite:setOpacity(80)
					local moveTime = 0.45 + math.random() * 0.64
					local moveTo = CCMoveTo:create(moveTime, ccp(targetPosition.x, targetPosition.y - 28 ))
					local function onMoveFinished( ) sprite:removeFromParentAndCleanup(true) end
					--local moveIn = CCEaseElasticOut:create(CCMoveTo:create(0.25, ccp(x, y)))
					local array = CCArray:create()
					--array:addObject(CCSpawn:createWithTwoActions(moveIn, CCFadeIn:create(0.25)))
					array:addObject(CCEaseSineOut:create(moveTo))
					array:addObject(CCCallFunc:create(onMoveFinished))
					array:addObject(CCFadeTo:create(0.25 , 0))
					sprite:runAction(CCSequence:create(array))
					sprite:runAction(CCFadeTo:create(0.2 , 255))

					local scene = Director:sharedDirector():getRunningScene()
					scene:addChild(sprite)
				end
			end
			
			theAction.addInfo = "wait"
		end

		if theAction.viewJSQ == 50 then
			itemView:setWukongProgress( theAction.wukongProgressCurr ,  theAction.wukongProgressTotal )
		end

		if theAction.viewJSQ == 100 then
			theAction.addInfo = "onFin"
		end
		if theAction.addInfo == "onChangeState" then
			if theAction.viewState == TileWukongState.kOnActive then
				itemView:changeWukongState(TileWukongState.kOnActive)
			else
				itemView:changeWukongState(TileWukongState.kNormal)
			end

			theAction.addInfo = "over"
		end
	end
end

function DestroyItemLogic:runningGameItemActionWukongCharging(mainLogic, theAction, actid, actByView)

	if theAction.actionStatus == GameActionStatus.kRunning then

		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]

		if theAction.addInfo == "start" then
			item.wukongState = TileWukongState.kOnHit

			local newValue = item.wukongProgressCurr + baseWukongChargingValue + theAction.count
			if newValue > item.wukongProgressTotal then
				newValue = item.wukongProgressTotal
			end

			theAction.wukongProgressCurr = newValue
			theAction.wukongProgressTotal = item.wukongProgressTotal

			item.wukongProgressCurr = newValue

			theAction.addInfo = "playAnimation"

		elseif theAction.addInfo == "onFin" then
			
			--item.wukongProgressCurr = item.wukongProgressCurr + baseWukongChargingValue + theAction.count
			if item.wukongProgressCurr == item.wukongProgressTotal then
				--item.wukongProgressCurr = item.wukongProgressTotal
				theAction.viewState = TileWukongState.kOnActive
				item.wukongState = TileWukongState.kOnActive
			else
				theAction.viewState = item.wukongState
				item.wukongState = TileWukongState.kNormal
			end
			
			theAction.addInfo = "onChangeState"
		elseif theAction.addInfo == "over" then
			-- 加上匹配检查点， 防止出现不三消的情况
			mainLogic:checkItemBlock(r,c)
			mainLogic:setNeedCheckFalling()
			mainLogic:addNeedCheckMatchPoint(r, c)
			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runGameItemActionCrystalStoneDestroy( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		local function finishCallback()
			-- theAction.addInfo = "over"
		end

		local color = theAction.addInt
		local isSpecial = theAction.isSpecial
		itemView:playCrystalStoneDisappear(isSpecial, finishCallback)
	end
end


function DestroyItemLogic:runningGameItemActionChestSquareJump( mainLogic, theAction, actid, actByView )
	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local gameItemMap = mainLogic.gameItemMap
		
		GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
		
		local itemList = {gameItemMap[r][c], gameItemMap[r][c+1], gameItemMap[r+1][c], gameItemMap[r+1][c+1]}
		for k, v in pairs(itemList) do 
			v:cleanAnimalLikeData()
			mainLogic:checkItemBlock(v.y,v.x)
		end

		-- 添加大招能量
		if mainLogic.theGamePlayType == 12  and not  theAction.hitBySpringBomb then -- and not isFromSpringBomb
			mainLogic:chargeFirework(10, r, c)
		end

		mainLogic.destroyActionList[actid] = nil
		FallingItemLogic:preUpdateHelpMap(mainLogic)

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
	end

end

function DestroyItemLogic:runGameItemActionChestSquareJump( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]

		local function finishCallback( ... )
		end

		theAction.addInfo = "watingForAnimation"
		theAction.jsq = 0
		itemView:playChesteSquareJumpAnimation(finishCallback)
	else
		theAction.jsq = theAction.jsq + 1
		if theAction.addInfo == "watingForAnimation" then
			if theAction.jsq == 25 then
				theAction.addInfo = "over"
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionMonsterJump( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		local function jumpCallback( ... )
			boardView:viberate()
		end

		local function finishCallback( ... )
			--theAction.addInfo = "over"
		end
		theAction.addInfo = "watingForAnimation"
		theAction.jsq = 0
		itemView:playMonsterJumpAnimation(jumpCallback, finishCallback)
	else
		theAction.jsq = theAction.jsq + 1
		if theAction.addInfo == "watingForAnimation" then
			if theAction.jsq >= 110 then
				theAction.addInfo = "over"
			end
		end
	end
end

-----播放消除冰层的动画------
function DestroyItemLogic:runGameItemActionIceDec(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local r1 = theAction.ItemPos1.x;
		local c1 = theAction.ItemPos1.y;
		local item = boardView.baseMap[r1][c1];
		local function onAnimCompleted()
			theAction.addInfo = "over"
		end
		item:playIceDecEffect(theAction.addInt, onAnimCompleted)
		GamePlayMusicPlayer:playEffect(GameMusicType.kIceBreak)

		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Light, ObstacleFootprintAction.k_Hit, 1)
		if theAction.addInt == 1 then
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Light, ObstacleFootprintAction.k_Eliminate, 1)
		end
	end
end

function DestroyItemLogic:runGameItemActionSandClean(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]

		local function onAnimCompleted()
			theAction.addInfo = "over"
		end

		GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kSand)
		SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kSand)
		item:playSandClean(onAnimCompleted)
	end
end

function DestroyItemLogic:runningGameItemActionCleanSand(mainLogic, theAction, actid, actByView)
	if theAction.addInfo == "over" then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionHoneyDec(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kHoney)
		SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kHoney)
		local itemView = boardView.baseMap[r][c]
		itemView:playHoneyDec(theAction.origLevel)
	end
end

function DestroyItemLogic:runGameItemActionHoneyBottleInc(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playHoneyBottleDec(theAction.addInt)
	end
end

function DestroyItemLogic:runGameItemActionWitchBomb(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning		
	
		theAction.addInfo = 'started'
		theAction.frameCount = math.ceil(theAction.startDelay * 60) -- 女巫飞到第九列的等待时间
		-- if _G.isLocalDevelopMode then printx(0, 'start', theAction.frameCount) end

	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == 'started' then
			theAction.frameCount = theAction.frameCount - 1
			if theAction.frameCount <= 0 then
				theAction.frameCount = 0 -- 爆炸立即开始
				-- if _G.isLocalDevelopMode then printx(0, 'started', theAction.frameCount) end
				theAction.addInfo = "over"
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionBossLossBlood(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local function callback( ... )
			-- body
			theAction.addInfo = "over"
		end

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:updateBossBlood(theAction.addInt, true, theAction.debug_string)
		itemView:playBossHit(boardView)
		callback()
	end
end

function DestroyItemLogic:runGameItemActionWeeklyBossLossBlood(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local function callback()
			theAction.addInfo = "over"
		end

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playWeeklyBossHit(boardView, theAction.addInt)
		callback()
	end
end

function DestroyItemLogic:runGameItemDeletedByMatch(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning and not theAction.isStarted then
		theAction.isStarted = true

		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		GameExtandPlayLogic:itemDestroyHandler(mainLogic, r1, c1)
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local gameItem = mainLogic.gameItemMap[r1][c1]
		if gameItem.ItemType ~= GameItemType.kDrip
			and gameItem.ItemType ~= GameItemType.kMeow
			then
			gameItem:cleanAnimalLikeData()
		end
		mainLogic:setNeedCheckFalling()
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemSpecialCoverAction(mainLogic, theAction, actid)

	if theAction.actionStatus == GameActionStatus.kRunning and not theAction.isStarted then
		theAction.isStarted = true
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		GameExtandPlayLogic:itemDestroyHandler(mainLogic, r1, c1)
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		if theAction.addInfo == "kAnimal" then
			local r1 = theAction.ItemPos1.x
			local c1 = theAction.ItemPos1.y
			local gameItem = mainLogic.gameItemMap[r1][c1]
			if gameItem.ItemType == GameItemType.kAnimal 		-----动物
				and not gameItem:hasFurball()
				then
				gameItem:cleanAnimalLikeData()
				mainLogic:setNeedCheckFalling()
			elseif gameItem.ItemType == GameItemType.kNone 		-----意外的空情况
				then
				gameItem.isEmpty = true
				mainLogic:setNeedCheckFalling()
			end
				
			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runGameItemSpecialBombColorAction_ItemDeleted(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local r2 = theAction.ItemPos2.x
		local c2 = theAction.ItemPos2.y
		local gameItem = mainLogic.gameItemMap[r1][c1]
		local gameItem2 = mainLogic.gameItemMap[r2][c2]
		if r1 == r2 and c1 == c2 then
			if _G.isLocalDevelopMode then printx(0, "Error!!! runGameItemSpecialBombColorAction_ItemDeleted deleted self") end
		else
			if gameItem.ItemType ~= GameItemType.kMeow
				then
				GameExtandPlayLogic:doAllBlocker211Collect(mainLogic, r1, c1, gameItem._encrypt.ItemColorType, false, 1)
				GameExtandPlayLogic:itemDestroyHandler(mainLogic, r1, c1)
				gameItem:cleanAnimalLikeData()
			end
			gameItem2.isEmpty = false
		end

		mainLogic:setNeedCheckFalling()
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemSpecialBombColorColorAction_ItemDeleted(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r1 = theAction.ItemPos1.x
		local c1 = theAction.ItemPos1.y
		local r2 = theAction.ItemPos2.x
		local c2 = theAction.ItemPos2.y
		local gameItem = mainLogic.gameItemMap[r1][c1]
		local gameItem2 = mainLogic.gameItemMap[r2][c2]

		GameExtandPlayLogic:itemDestroyHandler(mainLogic, r1, c1)
		gameItem:cleanAnimalLikeData()

		mainLogic:setNeedCheckFalling()
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemSpecialSnowDec(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "update" then
			theAction.addInfo = ""
			mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y].isNeedUpdate = true
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y].isNeedUpdate = true
		mainLogic.boardmap[theAction.ItemPos1.x][theAction.ItemPos1.y].isNeedUpdate = true
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Snow, ObstacleFootprintAction.k_Hit, theAction.hitTimes)
		--雪花只有在爆完最后一层后才需要检测
		if theAction.addInt == 1 then
			mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
			mainLogic:setNeedCheckFalling()
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Snow, ObstacleFootprintAction.k_Eliminate, 1)
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemSpecialVenomDec(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
		mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y].isNeedUpdate = true
		mainLogic.boardmap[theAction.ItemPos1.x][theAction.ItemPos1.y].isNeedUpdate = true
		mainLogic:markVenomDestroyedInStep()
		mainLogic:setNeedCheckFalling()
		mainLogic.destroyActionList[actid] = nil
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Poison, ObstacleFootprintAction.k_Eliminate, 1)
	end
end

function DestroyItemLogic:runGameItemSpecialGreyFurballDestroy(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if not theAction.hasMatch then
			theAction.hasMatch = true
			local r = theAction.ItemPos1.x
			local c = theAction.ItemPos1.y
			local item = mainLogic.gameItemMap[r][c]
			mainLogic:addNeedCheckMatchPoint(r, c)
			mainLogic:setNeedCheckFalling()
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		item.furballDeleting = false
		mainLogic.destroyActionList[actid] = nil
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_GreyFurball, ObstacleFootprintAction.k_Eliminate, 1)
	end
end

function DestroyItemLogic:runGameItemSpecialLockDec(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if not theAction.hasMatch then
			theAction.hasMatch = true
			local r = theAction.ItemPos1.x
			local c = theAction.ItemPos1.y
			local item = mainLogic.gameItemMap[r][c]
			mainLogic:checkItemBlock(r,c)
			mainLogic:setNeedCheckFalling()
			mainLogic:addNeedCheckMatchPoint(r, c)
		end
	elseif theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Lock, ObstacleFootprintAction.k_Eliminate, 1)
	end
end

function DestroyItemLogic:runGameItemRoostUpgrade(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runingGameItemSpecialBombColorAction_ItemDeleted(mainLogic, theAction, actid)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y
	local color = theAction.addInt

	local item1 = mainLogic.gameItemMap[r1][c1] 		----消除动物
	local item2 = mainLogic.gameItemMap[r2][c2] 		----魔力鸟来源

	if theAction.addInfo == "" then
		theAction.addInfo = "Pass"						----引起界面动画计算
	elseif theAction.addInfo == "Pass" then
		theAction.addInfo = "doing" 					----数据运算等待中----结束运算在函数runGameItemSpecialBombColorAction_ItemDeleted中
	end
end

function DestroyItemLogic:runningGameItem_CollectIngredient(mainLogic, theAction, actid)
	if theAction.addInfo == "Pass" then
		theAction.addInfo = "waiting1"
	elseif theAction.addInfo == "waiting1" then
		if theAction.actionDuring == 0 then 
			local r1 = theAction.ItemPos1.x
			local c1 = theAction.ItemPos1.y
			local item1 = mainLogic.gameItemMap[r1][c1] 		----豆荚位置
			item1:cleanAnimalLikeData()
			mainLogic:setNeedCheckFalling()
			mainLogic.destroyActionList[actid] = nil
			mainLogic.toBeCollected = mainLogic.toBeCollected -1
		end
	end
end

function DestroyItemLogic:runGameItemDeletedByMatchAction(boardView, theAction) 		----animal被删除
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local itemView = boardView.baseMap[r1][c1]
	local itemSprite = itemView:getItemSprite(ItemSpriteType.kItem)
	theAction.actionStatus = GameActionStatus.kRunning
	
	if theAction.addInfo == "balloon" then
		boardView.baseMap[r1][c1]:playBalloonBombEffect()
	elseif theAction.addInfo == "wrap" then
		boardView.baseMap[r1][c1]:playWrapItemBombEffect()
	elseif theAction.addInfo == "cuckooWindupKey" then
		boardView.baseMap[r1][c1]:playCuckooWindupKeyVanish()
	else
		boardView.baseMap[r1][c1]:playAnimationAnimalDestroy()
	end
end

function DestroyItemLogic:runGameItemActionCoverBySpecial(boardView, theAction)
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	theAction.actionStatus = GameActionStatus.kRunning

	if theAction.addInfo == "kAnimal" then
		if theAction.specialMatchType == SpecialMatchType.kColorLine then
			boardView.baseMap[r1][c1]:playBirdSpecial_BirdDestroyEffect()
		elseif theAction.specialMatchType == SpecialMatchType.kColorWrap then
			boardView.baseMap[r1][c1]:playBirdSpecial_BirdDestroyEffect()
		elseif theAction.specialMatchType == SpecialMatchType.kColorColor then
			local r2 = theAction.ItemPos2.x
			local c2 = theAction.ItemPos2.y
			boardView.baseMap[r1][c1]:playBirdBird_BirdDestroyEffect(IntCoord:create((r1+r2)/2, (c1+c2)/2), theAction.isMasterBird)
		else
			boardView.baseMap[r1][c1]:playAnimationAnimalDestroy()
		end
	elseif theAction.addInfo == "kLock" then
	elseif theAction.addInfo == "kCrystal" then 
	elseif theAction.addInfo == "kGift" then
	elseif theAction.addInfo == "kNewGift" then
	end
end

function DestroyItemLogic:runGameItemActionBombSpecialColor_ItemDeleted(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y
	local r2 = theAction.ItemPos2.x
	local c2 = theAction.ItemPos2.y

	local position1 = DestroyItemLogic:getItemPosition(theAction.ItemPos1)
	
	local collectPos = theAction.collectPos or theAction.ItemPos2
	local position2 = DestroyItemLogic:getItemPosition(collectPos)

	local item = boardView.baseMap[r1][c1]
	item:playAnimationAnimalDestroyByBird(position1, position2)
end

function DestroyItemLogic:runGameItemActionCollectIngredient(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	local r1 = theAction.ItemPos1.x
	local c1 = theAction.ItemPos1.y

	local item1 = boardView.baseMap[r1][c1]

	item1:playCollectIngredientAction(theAction.itemShowType ,boardView, boardView.IngredientActionPos)
	ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Fudge, ObstacleFootprintAction.k_Collect, 1)
end

function DestroyItemLogic:runGameItemActionSnowDec(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	theAction.addInfo = "update"

	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local item = boardView.baseMap[r][c]
	local hasCollection = theAction.collectItemID and theAction.collectItemID > 1
	item:playSnowDecEffect(theAction.addInt,hasCollection)
	if theAction.addInt <= 1 then 
		GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kSnow)
		SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kFrosting1)
	end
	GamePlayMusicPlayer:playEffect(GameMusicType.kSnowBreak)

	if theAction.collectItemID then
		if SnowMatchFestivalLogic:isSnowMatchFestivalLevel(boardView.gameBoardLogic.level) then
			SnowMatchFestivalLogic:playSnowDropIngredientAnimation(r, c)
		end
	end
end

function DestroyItemLogic:runGameItemActionVenomDec(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning

	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local item = boardView.baseMap[r][c]
	GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kPoison)
	SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kPoison)
	item:playVenomDestroyEffect()
end

function DestroyItemLogic:runGameItemActionGreyFurballDestroy(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y

	local item = boardView.baseMap[r][c]
	GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kGreyCute)
	SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kGreyCute)
	item:playGreyFurballDestroyEffect()
end

function DestroyItemLogic:runningGameItemActionGreyFurballDestroy(boardView, theAction)
	if theAction.actionDuring == 1 then
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:cleanFurballEffectView()
	end
end

function DestroyItemLogic:runGameItemActionLockDec(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning

	local r = theAction.ItemPos1.x;
	local c = theAction.ItemPos1.y;
	local item = boardView.baseMap[r][c];
	GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kLock)
	SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kLock)
	item:playLockDecEffect();
end

function DestroyItemLogic:runGameItemActionRoostUpgrade(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning

	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y

	local item = boardView.baseMap[r][c]
	local times = theAction.addInt
	item:playRoostUpgradeAnimation(times)
end

function DestroyItemLogic:runGameItemDigGroundDecLogic( mainLogic,  theAction, actid)
	-- body
	if theAction.actionStatus == GameActionStatus.kRunning then 
		if theAction.actionDuring == GamePlayConfig_GameItemDigGroundDeleteAction_CD - 4 then
			local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
			if item then item.digBlockCanbeDelete = true end
		end
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		
		local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
		if theAction.cleanItem then
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, theAction.ItemPos1.x, theAction.ItemPos1.y, Blocker195CollectType.kDigGround)
			SquidLogic:checkSquidCollectItem(mainLogic, theAction.ItemPos1.x, theAction.ItemPos1.y, TileConst.kDigGround_1)
			item:cleanAnimalLikeData()
			mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
			mainLogic:setNeedCheckFalling()
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_DigGround, ObstacleFootprintAction.k_Eliminate, 1)
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemViewDigGroundDec( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]

		item:playDigGroundDecAnimation(boardView)
	end
end

function DestroyItemLogic:runGameItemDigJewelDecLogic( mainLogic,  theAction, actid)
	-- body
	if theAction.actionStatus == GameActionStatus.kRunning then 
		if theAction.actionDuring == GamePlayConfig_GameItemDigJewelDeleteAction_CD - 4 then
			local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
			if item then item.digBlockCanbeDelete = true end
		end
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		if theAction.cleanItem then
			GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
			item:cleanAnimalLikeData()
			mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
			mainLogic:setNeedCheckFalling()
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_DigGround, ObstacleFootprintAction.k_Eliminate, 1)
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_DigJewel, ObstacleFootprintAction.k_Collect, 1)
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemViewDigJewelDec( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:playDigJewelDecAnimation(boardView)
	end
end


function DestroyItemLogic:runGameItemViewRandomPropDec(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]

		item:playRandomPropDie(boardView)
		theAction.counter = 0
	end
end

function DestroyItemLogic:runGameItemRandomPropDecLogic( mainLogic,  theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then 
		theAction.counter = theAction.counter + 1
		-- if _G.isLocalDevelopMode then printx(0, "pppppppppppppppp",theAction.actionDuring,  GamePlayConfig_GameItemDigJewelDeleteAction_CD,mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y].digBlockCanbeDelete) end
		-- 这里的逻辑显然错了。。。
		if theAction.actionDuring == GamePlayConfig_GameItemDigJewelDeleteAction_CD - 4 then --有一个保护时间
			local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
			if item then item.digBlockCanbeDelete = true end
		end

		if theAction.counter > 30 then
			local r = theAction.ItemPos1.x
			local c = theAction.ItemPos1.y
			local item = mainLogic.gameItemMap[r][c]
			if theAction.cleanItem then
				GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
				item:cleanAnimalLikeData()
				mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
				mainLogic:setNeedCheckFalling()
			end
			mainLogic.destroyActionList[actid] = nil
		end
	end
end

function DestroyItemLogic:runGameItemBottleBlockerDecLogic( mainLogic,  theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning then 
		local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]

		local bottleRow = item.y
		local bottleCol = item.x

		if item.ItemType ~= GameItemType.kBottleBlocker then
			mainLogic.destroyActionList[actid] = nil
		end

		if theAction.addInfo == "start" then
			theAction.addInfo = ""
			if not item.bottleActionRunningCount then item.bottleActionRunningCount = 0 end
			item.bottleActionRunningCount = item.bottleActionRunningCount + 1
		end

		if theAction.oldState == BottleBlockerState.HitAndChanging then
			if theAction.actionDuring == GamePlayConfig_MaxAction_time - 60 then
				--瓶子消掉一层
				-- printx( 1 , " *********************   " , item._encrypt.ItemColorType , theAction.newColor)
				item._encrypt.ItemColorType = theAction.newColor
				--item.bottleState = BottleBlockerState.Waiting
				if item.bottleActionRunningCount then item.bottleActionRunningCount = item.bottleActionRunningCount - 1 end
				item.isNeedUpdate = true
				
				mainLogic:addNeedCheckMatchPoint(bottleRow, bottleCol)
				mainLogic:setNeedCheckFalling()
				theAction.actionStatus = GameActionStatus.kWaitingForDeath
			end
		elseif theAction.oldState == BottleBlockerState.ReleaseSpirit then
			-- if theAction.actionDuring == GamePlayConfig_MaxAction_time - 16 then
			--瓶子完全碎掉，释放十字特效
			local destroyAroundAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItem_Bottle_Destroy_Around,
					IntCoord:create(bottleRow, bottleCol),
					nil,
					GamePlayConfig_MaxAction_time)
			mainLogic:addDestructionPlanAction(destroyAroundAction)
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
			-- end
		else
			--assert(false, "unexcept bottle state:"..tostring(item.bottleState))
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		end
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemViewBottleBlockerDec( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]

		local newColor = GameExtandPlayLogic:randomBottleBlockerColor(boardView.gameBoardLogic, r, c)

		if not newColor then
			newColor = theAction.oldColor
		end

		theAction.newColor = newColor
		theAction.addInfo = "start"
		
		--boardView.gameBoardLogic.gameItemMap[r][c].bottleBlockerNewColor = theAction.newColor
		--boardView.gameBoardLogic.gameItemMap[r][c]._encrypt.ItemColorType = AnimalTypeConfig.kNone
		if theAction.newBottleLevel == 0 then
			GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kBottleBlocker)
			SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kBottleBlocker)
		end
		item:playBottleBlockerHitAnimation(boardView , theAction.newBottleLevel , theAction.newColor)
	end
end

function DestroyItemLogic:runGameItemChestSquarePartLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.counter = 0
		theAction.actionStatus = GameActionStatus.kRunning


		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y

		-- 对应的大宝箱也要颤抖一下。。。fuuu
		local tr,tc =  ChestSquareLogic:findChestSquare(mainLogic,r,c)
		theAction.tr = tr
		theAction.tc = tc
	end

	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.counter > 60 then
			mainLogic.destroyActionList[actid] = nil
		end
	end

	theAction.counter = theAction.counter + 1
end

function DestroyItemLogic:runGameItemViewChestSquarePartDec(boardView,theAction)
	if ( theAction.counter  == 1) then
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		
		item:playChestSquarePartDec()

		-- 对应的大宝箱也要颤抖一下。。。fuuu
		if theAction.tr and theAction.tc then 
			local itemBig = boardView.baseMap[theAction.tr][theAction.tc]
			itemBig:playChesteSquareHit()
		end
	end
end

function DestroyItemLogic:runGameItemViewMonsterFrostingDec(boardView, theAction)
	theAction.actionStatus = GameActionStatus.kRunning
	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local item = boardView.baseMap[r][c]
	item:playMonsterFrostingDec()

	local r_m , c_m = BigMonsterLogic:findTheMonster( boardView.gameBoardLogic, r, c )
	if r_m and c_m then
		local item_monster = boardView.baseMap[r_m][c_m]
		item_monster:playMonsterEncourageAnimation()
	end
end

function DestroyItemLogic:runGameItemMonsterFrostingLogic(mainLogic, theAction, actid)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		mainLogic.destroyActionList[actid] = nil
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_BigMonster, ObstacleFootprintAction.k_Hit, 1)
	end
end

function DestroyItemLogic:runGameItemViewBlackCuteBallDec(boardView, theAction)
	-- body
	local function animationCallback( ... )
		-- body
		-- theAction.actionStatus = GameActionStatus.kWaitingForDeath
	end
	theAction.actionStatus = GameActionStatus.kRunning
	local r = theAction.ItemPos1.x
	local c = theAction.ItemPos1.y
	local item = boardView.baseMap[r][c]
	local currentStrength = theAction.blackCuteStrength
	if currentStrength == 0 then
		GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kBlackCute)
		SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kBlackCute)
	end

	item:playBlackCuteBallDecAnimation(currentStrength, animationCallback)
end

function DestroyItemLogic:runGameItemBlackCuteBallDec(mainLogic, theAction, actid)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then 
		local currentStrength = theAction.blackCuteStrength
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		if currentStrength == 0 then 
			if item then 
				GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
				item:cleanAnimalLikeData()
				mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
				mainLogic:setNeedCheckFalling()
			end
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_BlackFurball, ObstacleFootprintAction.k_Eliminate, 1)
		else

		end
		item.lastInjuredStep = mainLogic.realCostMove
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_BlackFurball, ObstacleFootprintAction.k_Hit, 1)
		mainLogic.destroyActionList[actid] = nil
	end
end
function DestroyItemLogic:runGameItemActionMissileHitView(boardView, theAction)
	if theAction.counter == 0 then 
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		local currentStrength = theAction.missileLevel
		if currentStrength == 0 then
			GameExtandPlayLogic:doAllBlocker195Collect(boardView.gameBoardLogic, r, c, Blocker195CollectType.kMissile)
			SquidLogic:checkSquidCollectItem(boardView.gameBoardLogic, r, c, TileConst.kMissile)
		end

		-- 注释原因：如果冰封导弹处于掉落过程中，此帧格子上可能已经不是冰封导弹了，故将减层动画移至之前判断减层时立即将执行
		--          上面两个collect逻辑勉强没问题，是因为他们不关心格子上是什么，只是借用了格子的位置信息播放动画
		--          但是效果还是很奇怪的，因为此时冰封导弹并没有被销毁（冰封导弹放招的state才会被销毁）却被已经收集了
		--          其实这个kMissileHit的action没什么必要呢……
		-- item:playMissileDecAnimation(currentStrength) 

		-- if _G.isLocalDevelopMode then printx(0, r,c,currentStrength) end
	end
end

function DestroyItemLogic:runningGameItemActionMissileHit(mainLogic, theAction, actid)
	
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.counter  = 0
	else
		theAction.counter = theAction.counter + 1

		if theAction.counter  > 1 then 
			mainLogic.destroyActionList[actid] = nil
			mainLogic:setNeedCheckFalling()
		end
	end
end


function DestroyItemLogic:runGameItemActionMimosaBack(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"
		local function callback( ... )
			-- body
			--theAction.addInfo = "over"
		end

		local list = theAction.mimosaHoldGrid
		local time = 0
		for k = 1, #list do 
			local r, c = list[k].x, list[k].y
			local itemView = boardView.baseMap[r][c]
			local call_func = k==#list and callback or nil
			itemView:playMimosaEffectAnimation(theAction.itemType,theAction.direction, time * (#list - k),  call_func, false)
		end

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playMimosaBackAnimation(time)

		theAction.jsq = 0
	else

		if theAction.addInfo == "wait" then
			theAction.jsq = theAction.jsq + 1
			if theAction.jsq == 36 then
				theAction.addInfo = "over"
			end
		end
	end

end

function DestroyItemLogic:runGameItemActionKindMimosaBack(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "start"
		local function callback( ... )
			-- body
			--theAction.addInfo = "over"
		end

		local list = theAction.list
		local time = 0
		for k = 1, #list do 
			local r, c = list[k].x, list[k].y
			local itemView = boardView.baseMap[r][c]
			local call_func = k==#list and callback or nil
			itemView:playMimosaEffectAnimation(theAction.itemType,theAction.direction, time * (#list - k),  call_func, false)
		end

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playMimosaBackAnimation(time)

		theAction.jsq = 0
	else
		if theAction.addInfo == "wait" then
			theAction.jsq = theAction.jsq + 1
			if theAction.jsq == 36 then
				theAction.addInfo = "over"
			end
		end
	end
end

function DestroyItemLogic:runningGameItemActionMimosaBack(mainLogic, theAction, actid)
	-- body
	if theAction.addInfo == "start" then
		theAction.addInfo = "wait"


		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		local list = item.mimosaHoldGrid
		for k, v in pairs(list) do 
			local item_grid = mainLogic.gameItemMap[v.x][v.y]
			item_grid.beEffectByMimosa = 0
			item_grid.mimosaDirection = 0
			mainLogic:checkItemBlock(v.x, v.y)
			mainLogic:addNeedCheckMatchPoint(v.x, v.y)
		end
		FallingItemLogic:preUpdateHelpMap(mainLogic)
		item.mimosaHoldGrid = {}
		item.isBackAllMimosa = nil
	elseif theAction.addInfo == "over" then
		local mr, mc = theAction.ItemPos1.x, theAction.ItemPos1.y
		local mimosa = mainLogic.gameItemMap[mr][mc]
		if mimosa and mimosa.needRemoveEventuallyBySquid then
			if mainLogic.boardView.baseMap[mr] and mainLogic.boardView.baseMap[mr][mc] then
				local itemView = mainLogic.boardView.baseMap[mr][mc]
				itemView:squidCommonDestroyItemAnimation()
			end

			mimosa:cleanAnimalLikeData()
			mainLogic:checkItemBlock(mr, mc)
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end

		mainLogic.destroyActionList[actid] = nil
	end

end

function DestroyItemLogic:runningGameItemActionKindMimosaBack(mainLogic, theAction, actid)
	-- body
	if theAction.addInfo == "start" then
		theAction.addInfo = "wait"
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		local list = theAction.list
		for k, v in pairs(list) do 
			local item_grid = mainLogic.gameItemMap[v.x][v.y]
			item_grid.beEffectByMimosa = 0
			item_grid.mimosaDirection = 0
			mainLogic:checkItemBlock(v.x, v.y)
			mainLogic:addNeedCheckMatchPoint(v.x, v.y)
		end
		FallingItemLogic:preUpdateHelpMap(mainLogic)
	elseif theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:getItemPosition(itemPos)
	local x = (itemPos.y - 0.5 ) * GamePlayConfig_Tile_Width
	local y = (GamePlayConfig_Max_Item_Y - itemPos.x - 0.5 ) * GamePlayConfig_Tile_Height
	return ccp(x,y)
end


-----------------------------------------
--       Chameleon
-----------------------------------------
function DestroyItemLogic:runGameItemActionChameleonTransformLogic(mainLogic, theAction, actid)	--Logic
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
	local chameleon = mainLogic.gameItemMap[r][c]

	--动画炸裂进程中，更新转化物数据与视图
	if theAction.jsq == 16 then
		ChameleonLogic:initNewItemView(mainLogic, chameleon)
	end

	if theAction.addInfo == 'over' then
		chameleon = mainLogic.gameItemMap[r][c]
		ChameleonLogic:onChameleonDemolished(mainLogic, chameleon)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Chameleon, ObstacleFootprintAction.k_Eliminate, 1)

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionChameleonTransformView(boardView, theAction)	--View

	if theAction.actionStatus == GameActionStatus.kRunning then

		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y

		if theAction.jsq == 0 then
			local chameleonView = boardView.baseMap[r][c]
			chameleonView:playChameleonBlast()
		end

		theAction.jsq = theAction.jsq + 1

		if theAction.jsq == 32 then
			theAction.addInfo = "over"
		end

	end
end

------------------------------------------------------------------------------------
--       							Pacman
------------------------------------------------------------------------------------
------- EAT ---------
function DestroyItemLogic:runGameItemActionPacmanEatTargetLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPacmanEatTargetLogic   OVER")
		PacmanLogic:updatePacmanPosition(mainLogic, theAction.targetPacman, theAction.targetItem, theAction.pacmanCollection)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Pacman, ObstacleFootprintAction.k_Attack, 1)

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionPacmanEatTargetView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		-- printx(11, "runGameItemActionPacmanEatTargetView", theAction.jsq)
		if theAction.jsq == 0 then
			local function callback()
				theAction.addInfo = "over"
			end

			local fromRow, fromCol = theAction.ItemPos1.y, theAction.ItemPos1.x
			local toRow, toCol = theAction.ItemPos2.y, theAction.ItemPos2.x
			local pacmanView = boardView.baseMap[fromRow][fromCol]
			pacmanView:playPacmanMove(IntCoord:create(toRow - fromRow, toCol - fromCol), callback)
		end

		theAction.jsq = theAction.jsq + 1
	end
end

------- BLOW ---------
function DestroyItemLogic:runGameItemActionPacmanBlowLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "hitTarget" then
		theAction.addInfo = ""
		PacmanLogic:onHitTargets(mainLogic, theAction.targetPacman, theAction.targetPositions)
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPacmanBlowLogic   OVER")

		local targetPacman = theAction.targetPacman
		targetPacman:cleanAnimalLikeData()
		-- targetPacman.isUsed = false
		targetPacman.isNeedUpdate = true
		mainLogic:checkItemBlock(targetPacman.y, targetPacman.x)
		mainLogic:tryDoOrderList(targetPacman.y, targetPacman.x, GameItemOrderType.kOthers, GameItemOrderType_Others.kPacman, 1)
		local boardMinNum = mainLogic.pacmanConfig.boardMinNum or 0
		if boardMinNum > 0 then
			PacmanLogic:updateDenProgressDisplay(mainLogic)	-- 如果设置了吃豆人棋盘最小数量，那么吃豆人的消除可能会触发生产，遂尝试刷新窝进度的显示
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionPacmanBlowView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		-- printx(11, "runGameItemActionPacmanBlowView", theAction.jsq)

		local pacman = theAction.targetPacman
		local pacmanView = boardView.baseMap[pacman.y][pacman.x]

		--- 开始播放吃豆人Blast动画
		--- 播放发射光效流星
		if theAction.jsq == 0 then
			pacmanView:playPacmanBlastAnimation()

			local fromPos = pacmanView:getBasePosition(pacman.x, pacman.y)
			for _, v in pairs(theAction.targetPositions) do
				local toPos = boardView.baseMap[v.y][v.x]:getBasePosition(v.x, v.y)
				pacmanView:playPacmansBlowHitAnimation(fromPos, toPos)
			end
		end

		theAction.jsq = theAction.jsq + 1

		--- 击中目标
		local hitAnimationDelay = 30
		if theAction.jsq == hitAnimationDelay then
			theAction.addInfo = "hitTarget"
		end

		--- 整体结束
		local blowDurationDelay = 60
		if theAction.jsq == blowDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

------- GENERATE ---------
function DestroyItemLogic:runGameItemActionPacmanGenerateLogic(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		-- printx(11, "start runGameItemActionPacmanGenerate")
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPacmanGenerateLogic   OVER")

		local generateNumByBoardMin = theAction.generateNumByBoardMin
		local generateNumByStep = theAction.generateNumByStep

		for _, targetItem in ipairs(theAction.pickedTargets) do
			PacmanLogic:updateNewPacman(mainLogic, targetItem)
			if generateNumByBoardMin > 0 then
				mainLogic.pacmanGeneratedByBoardMin = mainLogic.pacmanGeneratedByBoardMin + 1
				generateNumByBoardMin = generateNumByBoardMin - 1
				-- printx(11, "add pacmanGeneratedByBoardMin to: ", mainLogic.pacmanGeneratedByBoardMin)
			else
				mainLogic.pacmanGeneratedByStep = mainLogic.pacmanGeneratedByStep + 1
				-- generateNumByStep = generateNumByStep - 1
				-- printx(11, "add pacmanGeneratedByStep to: ", mainLogic.pacmanGeneratedByStep)
			end
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionPacmanGenerateView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.jsq == 0 then
			local denRecord = {}
			local denPositions = {}
			for _, targetItem in ipairs(theAction.pickedTargets) do
				local function onGenerateJumpEnd()
					if theAction.generateCount then
						theAction.generateCount = theAction.generateCount - 1
					end

					if not theAction.generateCount or theAction.generateCount <= 0 then
						theAction.addInfo = "over"
					end
				end

				local denPos = targetItem.pacmansDenPos
				local denView = boardView.baseMap[denPos.y][denPos.x]

				local fromRow, fromCol = denPos.y, denPos.x
				local toRow, toCol = targetItem.y, targetItem.x
				denView:playPacmansDenGeneratePacman(IntCoord:create(toRow - fromRow, toCol - fromCol), 
					targetItem.pacmanColour, onGenerateJumpEnd)
				if not theAction.generateCount then
					theAction.generateCount = 0
				end
				theAction.generateCount = theAction.generateCount + 1
				
				local locationKey = denPos.x..","..denPos.y
				if not denRecord[locationKey] then
					table.insert(denPositions, denPos)
					denRecord[locationKey] = true
				end
			end

			for _, genDenPos in ipairs(denPositions) do
				--- Den play generate animation
				local genDenView = boardView.baseMap[genDenPos.y][genDenPos.x]
				genDenView:playPacmansDenGenerate()
			end
		end

		theAction.jsq = theAction.jsq + 1

		-- local realReplaceDelay = 25
		-- if theAction.jsq == realReplaceDelay then
		-- 	for _, targetItem in ipairs(theAction.pickedTargets) do
		-- 		local targetItemView = boardView.baseMap[targetItem.y][targetItem.x]
		-- 		if targetItemView then
		-- 			local sp = targetItemView:getGameItemSprite()
		-- 			if sp then 
		-- 				-- sp:setVisible(false)
		-- 				sp:runAction(CCSpawn:createWithTwoActions(
		-- 					CCEaseOut:create(CCMoveBy:create(1, ccp(0, -GamePlayConfig_Tile_Height)), 1/3) , 
		-- 					CCEaseSineOut:create(CCFadeOut:create(1) )))
		-- 			end
		-- 		end
		-- 	end
		-- end

		-- local wholeAnimationDelay = 60
		-- if theAction.jsq == wholeAnimationDelay then
		-- 	theAction.addInfo = "over"
		-- 	printx(11, "runGameItemActionPacmanEatTargetView  set addinfo over")
		-- end
	end
end

------------------ Turret 第二版 ----------------------
function DestroyItemLogic:runGameItemActionTurretUpgradeLogic(mainLogic, theAction, actid)
    local fromRow, fromCol = theAction.ItemPos1.x, theAction.ItemPos1.y

    if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
        theAction.turret = mainLogic.gameItemMap[fromRow][fromCol]
        theAction.isRunAddStartTime = false

         theAction.CanAttackStartTime = 0

        theAction.addInfo = "TouchTurret"

        theAction.needRemoveEventuallyBySquid = theAction.turret.needRemoveEventuallyBySquid
	end
        
    theAction.CanAttackStartTime = theAction.CanAttackStartTime + 1

    --延迟4帧 确定升级状态
    if theAction.CanAttackStartTime > 5 then
        --确定升级
        theAction.turret.updateType = 2
    end

    if theAction.addInfo == 'TouchTurret' then 
        --碰撞
        if theAction.turret.turretLevel == 0 then

            if theAction.turret.updateType == 0 then
                theAction.turret.updateType = 1
            end
            theAction.turret.turretLevel = 1
           
            theAction.isRunAddStartTime = true --只能第一个执行升级的action运行touch计数++
            if theAction.hitBySpecial then
                theAction.turret.turretIsSuper = true
            end

            theAction.addInfo = "PreUpgrade"

        elseif theAction.turret.turretLevel == 1 then
            --4帧内可连续碰撞改变特效形态
            if theAction.turret.updateType == 1 then
                if theAction.hitBySpecial then
                    theAction.turret.turretIsSuper = true
                end

                theAction.addInfo = "waitover"

            elseif theAction.turret.updateType == 2 then
                if not theAction.turret.turretLocked then

                    local CenterPos = TurretLogic:getTurretFireCenterPos(mainLogic, theAction.turret)
                    if CenterPos then
                         --开炮
			            theAction.fireTargetCoord, theAction.PiectPosList = TurretLogic:getTurretFireCenterCoord(mainLogic, theAction.turret)
			            ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Turret, ObstacleFootprintAction.k_Attack, 1)

                        --theAction.turret.turretLevel = 2
                        theAction.turret.turretLevel = 0 --开炮就0级了
                        theAction.turret.turretLocked = true
                    end

                    theAction.jsq = 0
                    theAction.addInfo = "FireCenter"
                else
                    theAction.addInfo = "waitover"
                end
            end
        end

    elseif theAction.addInfo == "hitTarget" then
        --击打中心
		theAction.addInfo = "waitHitover"
        theAction.jsq = 0
		TurretLogic:onHitTargets(mainLogic, theAction.turret, theAction.fireTargetCoord)

	elseif theAction.addInfo == "hitPieceTarget" then
        --碎片击打
        if #theAction.HitPieceDelayList == 0 then
            theAction.turret.turretIsSuper = false

            theAction.addInfo = "waitHitPieceover"
            theAction.jsq = 0
        else
        	local mathBoard = mainLogic.boardmap[fromRow][fromCol]
        	local TurrectHaveJamSperad = mathBoard:hasJamSperad()

            for i,v in pairs(theAction.HitPieceDelayList) do
                if v.Delay == theAction.jsq then

                	--如果自身有果酱。打出去的目标也给果酱属性
			        if TurrectHaveJamSperad then
				        GameExtandPlayLogic:addJamSperadFlag(mainLogic, v.r, v.c )
				    end

                    bAllFinish = false
                    TurretLogic:onHitPieceTargets(mainLogic, theAction.turret, theAction.fireTargetCoord, ccp(v.c,v.r) )
                    table.remove( theAction.HitPieceDelayList, i )
                end
             end
        end
    elseif theAction.addInfo == 'over' then
        local bCanOver = true
        if theAction.CanAttackStartTime < 4 then
            bCanOver = false
        end

        if bCanOver then
            if theAction.turret and theAction.turret.needRemoveEventuallyBySquid then
			    theAction.turret:cleanAnimalLikeData()
			    theAction.turret.isNeedUpdate = true
			    mainLogic:checkItemBlock(theAction.turret.y, theAction.turret.x)
		    end

            mainLogic.destroyActionList[actid] = nil
        end
    end
end

function DestroyItemLogic:runGameItemActionTurretUpgradeView(boardView, theAction)

    local fromRow, fromCol = theAction.ItemPos1.x, theAction.ItemPos1.y
    local turretView = boardView.baseMap[fromRow][fromCol]
    local ActionOverDelay = 20 --default

    local mathBoard = boardView.gameBoardLogic.boardmap[fromRow][fromCol]
	local TurrectHaveJamSperad = mathBoard:hasJamSperad()

    if theAction.actionStatus == GameActionStatus.kRunning then

        if theAction.addInfo == 'PreUpgrade' then
            turretView:playTurretPreUpgradeAnimation(theAction.turret.turretIsSuper, nil )

            theAction.addInfo = "waiPreUpgrade"
            theAction.jsq = 0
        elseif theAction.addInfo == "waiPreUpgrade" then
		    local hitAnimationDelay = 10
            if theAction.jsq == hitAnimationDelay then
		        --播放炮台变换
                local fromPos = turretView:getBasePositionWeek(fromCol, fromRow)
			    turretView:playTurretUpgradeAnimation(theAction.turret.turretIsSuper, fromPos )

                --等待结束
                theAction.addInfo = "waitover"
                theAction.jsq = 0
                ActionOverDelay = 0
            end
        elseif theAction.addInfo == 'FireCenter' then
            --可以开炮的时候
            if theAction.fireTargetCoord then
                --播放炮弹准星
				local fromPos = turretView:getBasePositionWeek(fromCol, fromRow)
				local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				local toPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                local pos = ccp(toPos.x,toPos.y)

				turretView:playTurretFireFlyAnimation(fromPos, toPos)

                theAction.addInfo = "targetBlink"
                theAction.jsq = 0
            else
                --如果炮弹位置中心没找到 说明打不到  等待结束
                theAction.addInfo = "waitover"
                theAction.jsq = 0
                ActionOverDelay = 20
			end
        elseif theAction.addInfo == "targetBlink" then
             ---准星后 击中目标
		    local hitAnimationDelay = 10
		    if theAction.jsq == hitAnimationDelay then
                if theAction.fireTargetCoord then
                	--播放炮弹准星
				    local fromPos = turretView:getBasePositionWeek(fromCol, fromRow)
			        turretView:playTurretUpgradeAnimation(theAction.turret.turretIsSuper,fromPos)
                end
			    theAction.addInfo = "fly"
		    end
        elseif theAction.addInfo == "fly" then
            ---fly后 击中目标
		    local hitAnimationDelay = 28
		    if theAction.jsq == hitAnimationDelay then
                local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				local toPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                local pos = ccp(toPos.x,toPos.y)

                --如果自身有果酱。打出去的目标也给果酱属性
		        if TurrectHaveJamSperad then
			        GameExtandPlayLogic:addJamSperadFlag(boardView.gameBoardLogic, targetY, targetX )
			    end

                turretView:playTurretMainBoomAnimation( toPos)
			    theAction.addInfo = "hitTarget"
		    end
        elseif theAction.addInfo == "waitHitover" then
            ---碎片飞
		    local hitAnimationDelay = 18
		    if theAction.jsq == hitAnimationDelay then

                local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				local fromPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                local pos = ccp(fromPos.x,fromPos.y)

                theAction.PieceAllNum =  #theAction.PiectPosList
--                local CurPieceHitNum = 0

                local DelayTime = 0
                local DelayNum = 0
                function PieceFlyEnd( PieceInedx )
                    --回调没用了
                end

                local HitPieceDelayList = {}
                for i,v in pairs(theAction.PiectPosList) do
                    local toPos =  boardView.baseMap[v.y][v.x]:getBasePositionWeek(v.x, v.y)
                    turretView:playTurretPieceFlyAnimation(ccp(fromPos.x,fromPos.y), toPos, DelayTime, i, PieceFlyEnd, theAction.turret.turretIsSuper )
                    DelayTime = DelayTime + 0.1

                    DelayNum = DelayNum + 6
                    local Info = {}
                    Info.Delay = DelayNum
                    Info.r = v.y
                    Info.c = v.x
                    table.insert( HitPieceDelayList, Info )
                end

--                if #theAction.PiectPosList == 0 then
--                    --等待结束
--                    theAction.addInfo = "waitover"
--                    theAction.jsq = 0
--                    ActionOverDelay = 20
--                else
                    theAction.HitPieceDelayList = HitPieceDelayList
                    theAction.addInfo = "hitPieceTarget"
                    theAction.jsq = 0
--                end
		    end
        elseif theAction.addInfo == "waitHitPieceover" then
            --等待碎片飞行结束
		    local hitAnimationDelay = 28
		    if theAction.jsq == hitAnimationDelay then
			    theAction.addInfo = "waitover"
                theAction.jsq = 0
                ActionOverDelay = 20
		    end
        elseif theAction.addInfo == "waitover" then
            --- 整体结束
		    if theAction.jsq == ActionOverDelay then
		    	if theAction.needRemoveEventuallyBySquid then
		    		turretView:squidCommonDestroyItemAnimation()
		    	end

			    theAction.addInfo = "over"
		    end
        end

        theAction.jsq = theAction.jsq + 1
    end


end


------------------ Turret ----------------------
function DestroyItemLogic:runGameItemActionTurretUpgradeLogic2(mainLogic, theAction, actid)
	local turretPos = theAction.turretPos
	local turret = mainLogic.gameItemMap[turretPos.x][turretPos.y]
    if not theAction.turretItemOldLevel then
        theAction.turretItemOldLevel = turret.turretLevel
    end
    theAction.turretItemLevel = turret.turretLevel
	theAction.turretIsSuper = turret.turretIsSuper

	local mathBoard = mainLogic.boardmap[turretPos.x][turretPos.y]
	local TurrectHaveJamSperad = mathBoard:hasJamSperad()

    theAction.CanAttackStartTime = theAction.CanAttackStartTime + 1

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
        theAction.addInfo = "TurretUpdate"
        theAction.needRemoveEventuallyBySquid = turret.needRemoveEventuallyBySquid

        --炮台满级可以发射
		if theAction.maxLevelReached then
			theAction.fireTargetCoord, theAction.PiectPosList = TurretLogic:getTurretFireCenterCoord(mainLogic, turret)
			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Turret, ObstacleFootprintAction.k_Attack, 1)
		end
	end

	if theAction.addInfo == "hitTarget" then
		theAction.addInfo = "waitHitover"
        theAction.jsq = 0
		TurretLogic:onHitTargets(mainLogic, turret, theAction.fireTargetCoord)
	end

	if theAction.addInfo == "hitPieceTarget" then

        if #theAction.HitPieceDelayList == 0 then
            theAction.addInfo = "waitHitPieceover"
            theAction.jsq = 0
        else
            for i,v in pairs(theAction.HitPieceDelayList) do
                if v.Delay == theAction.jsq then

                	--如果自身有果酱。打出去的目标也给果酱属性
			        if TurrectHaveJamSperad then
				        GameExtandPlayLogic:addJamSperadFlag(mainLogic, v.r, v.c )
				    end

                    bAllFinish = false
                    TurretLogic:onHitPieceTargets(mainLogic, turret, theAction.fireTargetCoord, ccp(v.c,v.r) )
                    table.remove( theAction.HitPieceDelayList, i )
                end
             end
        end
	end

	if theAction.addInfo == 'over' then

        if theAction.turretItemOldLevel ~= turret.turretLevel then
            theAction.actionStatus = GameActionStatus.kWaitingForStart
            theAction.addInfo = ""
            theAction.maxLevelReached = true
            turret.turretLevel = 1
            theAction.IsCanSetLock = true
        else
		    if theAction.maxLevelReached and theAction.fireTargetCoord then
			    turret.turretLevel = 0
			    turret.turretIsSuper = false
            elseif theAction.maxLevelReached and theAction.fireTargetCoord == nil then
--              turret.turretLevel = 0
--			    turret.turretIsSuper = false
            else
                local maxLevel = 2		--击中2次后触发
                if turret.turretLevel < maxLevel then
                    turret.turretLevel = turret.turretLevel + 1 
                end
		    end

            turret.runAction = false
            turret.upgradeAction = nil

            if theAction.IsCanSetLock then
                turret.turretLocked = true
            end

            if turret and turret.needRemoveEventuallyBySquid then
				turret:cleanAnimalLikeData()
				turret.isNeedUpdate = true
				mainLogic:checkItemBlock(turret.y, turret.x)
			end

		    -- if theAction.completeCallback then
		    -- 	theAction.completeCallback()
		    -- end
		    mainLogic.destroyActionList[actid] = nil
        end

	end
end

function DestroyItemLogic:runGameItemActionTurretUpgradeView2(boardView, theAction)
    local turretPos = theAction.turretPos
	local turretView = boardView.baseMap[turretPos.x][turretPos.y]

	local mathBoard = boardView.gameBoardLogic.boardmap[turretPos.x][turretPos.y]
	local TurrectHaveJamSperad = mathBoard:hasJamSperad()

	if theAction.actionStatus == GameActionStatus.kRunning then
		-- printx(11, "runGameItemActionTurretUpgradeView", theAction.jsq)
        local ActionOverDelay = 20 --default
        if theAction.addInfo == "TurretUpdate" then

            if theAction.turretItemLevel == 0 then
		        if theAction.jsq == 0 then
			        --播放炮台变换前置
                    function preUpgradeEnd()
                        --nouse 走帧回调了
                    end

			        turretView:playTurretPreUpgradeAnimation(theAction.turretIsSuper, preUpgradeEnd )

                    theAction.addInfo = "waiPreUpgrade"
                    theAction.jsq = 0
		        end
            else
                --可以开炮的时候
                if theAction.fireTargetCoord then
                    --播放炮弹准星
				    local fromPos = turretView:getBasePositionWeek(turretPos.y, turretPos.x)
				    local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				    local toPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                    local pos = ccp(toPos.x,toPos.y)

				    turretView:playTurretFireFlyAnimation(fromPos, toPos)

                    theAction.addInfo = "targetBlink"
                    theAction.jsq = 0
                else
                    --如果炮弹位置中心没找到 说明打不到  等待结束
                    theAction.addInfo = "waitover"
                    theAction.jsq = 0
                    ActionOverDelay = 20
			    end
            end
        end

        ---等待升级结束
        if theAction.addInfo == "waiPreUpgrade" then
		    local hitAnimationDelay = 10
            if theAction.jsq == hitAnimationDelay then
		        --播放炮台变换
                local fromPos = turretView:getBasePositionWeek(turretPos.y, turretPos.x)
			    turretView:playTurretUpgradeAnimation(theAction.turretIsSuper, fromPos )

                --等待结束
                theAction.addInfo = "waitover"
                theAction.jsq = 0
                ActionOverDelay = 0
            end
        end

		---准星后 击中目标
        if theAction.addInfo == "targetBlink" then
		    local hitAnimationDelay = 10
		    if theAction.jsq == hitAnimationDelay then
                if theAction.fireTargetCoord then
                	--播放炮弹准星
				    local fromPos = turretView:getBasePositionWeek(turretPos.y, turretPos.x)
			        turretView:playTurretUpgradeAnimation(theAction.turretIsSuper,fromPos)
                end
			    theAction.addInfo = "fly"
		    end
        end

        ---fly后 击中目标
        if theAction.addInfo == "fly" then
		    local hitAnimationDelay = 28
		    if theAction.jsq == hitAnimationDelay then
                local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				local toPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                local pos = ccp(toPos.x,toPos.y)

                --如果自身有果酱。打出去的目标也给果酱属性
		        if TurrectHaveJamSperad then
			        GameExtandPlayLogic:addJamSperadFlag(boardView.gameBoardLogic, targetY, targetX )
			    end

                turretView:playTurretMainBoomAnimation( toPos)
			    theAction.addInfo = "hitTarget"
		    end
        end

        ---碎片飞
        if theAction.addInfo == "waitHitover" then
		    local hitAnimationDelay = 18
		    if theAction.jsq == hitAnimationDelay then

                local targetX, targetY = theAction.fireTargetCoord.x, theAction.fireTargetCoord.y
				local fromPos = boardView.baseMap[targetY][targetX]:getBasePositionWeek(targetX, targetY)

                local pos = ccp(fromPos.x,fromPos.y)

                theAction.PieceAllNum =  #theAction.PiectPosList
--                local CurPieceHitNum = 0

                local DelayTime = 0
                local DelayNum = 0
                function PieceFlyEnd( PieceInedx )
                    --回调没用了
                end

                local HitPieceDelayList = {}
                for i,v in pairs(theAction.PiectPosList) do
                    local toPos =  boardView.baseMap[v.y][v.x]:getBasePositionWeek(v.x, v.y)
                    turretView:playTurretPieceFlyAnimation(ccp(fromPos.x,fromPos.y), toPos, DelayTime, i, PieceFlyEnd, theAction.turretIsSuper )
                    DelayTime = DelayTime + 0.1

                    DelayNum = DelayNum + 6
                    local Info = {}
                    Info.Delay = DelayNum
                    Info.r = v.y
                    Info.c = v.x
                    table.insert( HitPieceDelayList, Info )
                end

                if #theAction.PiectPosList == 0 then
                    --等待结束
                    theAction.addInfo = "waitover"
                    theAction.jsq = 0
                    ActionOverDelay = 20
                else
                    theAction.HitPieceDelayList = HitPieceDelayList
                    theAction.addInfo = "hitPieceTarget"
                    theAction.jsq = 0
                end
		    end
        end

        ---hitTarget后 碎片击中目标
--        if theAction.addInfo == "PieceFly" then
--		    local hitAnimationDelay = 20
--		    if theAction.jsq == hitAnimationDelay then
--			    theAction.addInfo = "hitPieceTarget"
--		    end
--        end

        ---hitPieceTarget后 延迟结束
        if theAction.addInfo == "waitHitPieceover" then
		    local hitAnimationDelay = 28
		    if theAction.jsq == hitAnimationDelay then
			    theAction.addInfo = "waitover"
                theAction.jsq = 0
                ActionOverDelay = 20
		    end
        end

		--- 整体结束
        if theAction.addInfo == "waitover" then
		    if theAction.jsq == ActionOverDelay then
		    	if theAction.needRemoveEventuallyBySquid then
		    		turretView:squidCommonDestroyItemAnimation()
		    	end

			    theAction.addInfo = "over"
		    end
        end

        theAction.jsq = theAction.jsq + 1
	end
end



---------------------------------------------------------------------------------------------------------
--										MOLE WEEKLY BOSS SKILL
---------------------------------------------------------------------------------------------------------
function DestroyItemLogic:runGameItemActionMoleWeeklyMagicTileBlastLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "hitTarget" then
		theAction.addInfo = ""

		for _, v in pairs(theAction.targetPositions) do
			-- printx(11, "MoleWeeklyMagicTileBlast    Hit: ("..v.y..","..v.x..")")
			local targetPoint = IntCoord:create(v.x, v.y)
			local rectangleAction = GameBoardActionDataSet:createAs(
										GameActionTargetType.kGameItemAction,
										GameItemActionType.kItemSpecial_rectangle,
										targetPoint,
										targetPoint,
										GamePlayConfig_MaxAction_time)
			rectangleAction.addInt2 = 1.5
			rectangleAction.eliminateChainIncludeHem = true
			mainLogic:addDestructionPlanAction(rectangleAction)
		end
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionMoleWeeklyMagicTileBlastLogic   OVER")

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionMoleWeeklyMagicTileBlastView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then

		local fromRow, fromCol = theAction.ItemPos1.x, theAction.ItemPos1.y
		local fromView = boardView.baseMap[fromRow][fromCol]

		--- 播放发射光效流星
		if theAction.jsq == 0 then
			local fromPos = fromView:getBasePosition(fromCol, fromRow)
			fromPos.x = fromPos.x + fromView.w
			fromPos.y = fromPos.y - fromView.h / 2
			for _, v in pairs(theAction.targetPositions) do
				local toPos = boardView.baseMap[v.y][v.x]:getBasePosition(v.x, v.y)
				-- fromView:playMoleWeeklyBossSkillFlyTo(fromPos, toPos)
				fromView:playMoleBossSeedHitAnimation(fromPos, toPos)	--一家人，借用一下动画效果
			end
		end

		theAction.jsq = theAction.jsq + 1

		--- 击中目标
		local hitAnimationDelay = 30
		if theAction.jsq == hitAnimationDelay then
			theAction.addInfo = "hitTarget"
		end

		--- 整体结束
		local blowDurationDelay = 60
		if theAction.jsq == blowDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

function DestroyItemLogic:runGameItemActionMoleWeeklyCloudDieLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kRunning  then
		theAction.actionTick = theAction.actionTick + 1
		local function cleanItem(r, c)
			local item = mainLogic.gameItemMap[r][c]
			local board = mainLogic.boardmap[r][c]
			item:cleanAnimalLikeData()
			item.isDead = false
			item.isBlock = false
			item.isNeedUpdate = true
			mainLogic:checkItemBlock(r, c)
		end

		if theAction.addInfo == "dieAction" and theAction.actionTick == 40 then
			theAction.addInfo = 'over'
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
			GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
			cleanItem(r, c)
			cleanItem(r + 1, c)
			cleanItem(r, c+1)
			cleanItem(r+ 1, c+1)
			mainLogic:setNeedCheckFalling()
			FallingItemLogic:preUpdateHelpMap(mainLogic)
		elseif theAction.addInfo == 'over' then
			if theAction.completeCallback then
				theAction.completeCallback()
			end
			mainLogic.destroyActionList[actid] = nil
    	end
	end
end

function DestroyItemLogic:runGameItemActionMoleWeeklyBossCloudDieView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning 
		theAction.actionTick = 0
		theAction.addInfo = "dieAction"
		local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:playMoleWeeklyBossCloudDie()
	end
end

--
function DestroyItemLogic:runGameItemYellowDiamondDecLogic( mainLogic,  theAction, actid)
	-- body
	if theAction.actionStatus == GameActionStatus.kRunning then 
		if theAction.actionDuring == GamePlayConfig_GameItemYellowDiamondDeleteAction_CD - 4 then
			local item = mainLogic.gameItemMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
			if item then item.yellowDiamondCanbeDelete = true end
		end
	end

	if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = mainLogic.gameItemMap[r][c]
		if theAction.cleanItem then
			GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
			item:cleanAnimalLikeData()
			mainLogic:checkItemBlock(theAction.ItemPos1.x, theAction.ItemPos1.y)
			mainLogic:setNeedCheckFalling()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemViewYellowDiamond( boardView, theAction )
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then 
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local item = boardView.baseMap[r][c]
		item:playYellowDiamondDecAnimation(boardView)
	end
end

-------------------------------------- GHOST MOVE ----------------------------------------
function DestroyItemLogic:runGameItemActionGhostMoveLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then

		GhostLogic:refreshGameItemDataAfterGhostMove(mainLogic)
		-- printx(11, "runGameItemActionGhostMoveLogic   OVER")
		-- ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Pacman, ObstacleFootprintAction.k_Attack, 1)

		-- theAction.addInfo = "over"
		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then
		-- 唉……由于视图不会立即更新，所以被挤下来的对象如果马上下落的话视图会错误。所以等一下。
		if theAction.refreshViewDelay == 1 then
			-- GhostLogic:refreshBlockStateAfterGhostMove(mainLogic)	--完成幽灵收集以后再刷新状态
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionGhostMoveView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then

			local inAnimationCount = 0

			local function completeCallback( ... )
				inAnimationCount = inAnimationCount - 1
				if inAnimationCount <= 0 then
					theAction.addInfo = "animationEnd"
				end
			end

			local downMoveSpeed = 0.2
			local upMoveSpeed1 = 0.3
			local upMoveSpeed2 = 0.4

			for r = 1, #boardView.gameBoardLogic.gameItemMap do
				for c = 1, #boardView.gameBoardLogic.gameItemMap[r] do
					local item = boardView.gameBoardLogic.gameItemMap[r][c]
					local itemView = boardView.baseMap[r][c]
					if item and itemView then
						if item.tempGhostPace ~= 0 then
							local moveSpeed
							if item.tempGhostPace > 0 then
								moveSpeed = downMoveSpeed
							else
								if item.tempGhostPace < -5 then
									moveSpeed = upMoveSpeed2
								else
									moveSpeed = upMoveSpeed1
								end
							end
							
							local sprite = itemView:getGameItemSprite()
							if sprite then
								local position = UsePropState:getItemPosition(IntCoord:create(item.y + item.tempGhostPace, item.x))

								local arr = CCArray:create()
								arr:addObject(CCDelayTime:create(0.15))
								arr:addObject(CCMoveTo:create(moveSpeed, position))
								arr:addObject(CCDelayTime:create(0.3))
								arr:addObject(CCCallFunc:create(completeCallback))
								local move_action = CCSequence:create(arr) 

								sprite:runAction(move_action)
								inAnimationCount = inAnimationCount + 1
							end

							if item:seizedByGhost() then
								itemView:playGhostFly(item.tempGhostPace)
							end
						else
							--没有可移动的步数
							if item.ghostPaceLength > 0 then
								GhostLogic:switchStatusBackToNormalWithoutMoving(boardView.gameBoardLogic, item)
							end
						end
						
					end
				end
			end

			if inAnimationCount == 0 then
				theAction.jsq = 1
				theAction.addInfo = "animationEnd"
			end
		end

		theAction.jsq = theAction.jsq + 1
	end
end

------ collect
function DestroyItemLogic:runGameItemActionGhostCollectLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then
		for _, formerGhost in pairs(theAction.targetList) do
			local row, col = formerGhost.y, formerGhost.x
			formerGhost.coveredByGhost = false
			formerGhost.tempGhostPace = 0
			formerGhost.ghostPaceLength = 0
			mainLogic:addScoreToTotal(row, col, 100)
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, row, col, Blocker195CollectType.kGhost)
			SquidLogic:checkSquidCollectItem(mainLogic, row, col, TileConst.kGhost)
			mainLogic:tryDoOrderList(row, col, GameItemOrderType.kOthers, GameItemOrderType_Others.kGhost, 1)

			mainLogic:checkItemBlock(row, col)
			mainLogic:addNeedCheckMatchPoint(row , col)
			mainLogic.gameMode:checkDropDownCollect(row, col)
			ColorFilterLogic:handleFilter(row, col) 	--即时检测过滤器过滤
			
			formerGhost.isNeedUpdate = true
			-- formerGhost.forceUpdate = true		--若落下类型颜色等相同，视图可能不更新。故而强制

			ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Ghost, ObstacleFootprintAction.k_Collect, 1)
		end

		-- printx(11, "runGameItemActionGhostCollectLogic   OVER")
		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionGhostCollectView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			for _, targetGhost in pairs(theAction.targetList) do
				local itemView = boardView.baseMap[targetGhost.y][targetGhost.x]
				if itemView then
					itemView:playGhostDisappear()
				end
			end
		end

		if theAction.jsq == 40 then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

-------------------------------------	Sunflower	-------------------------------------------------
function DestroyItemLogic:runGameItemActionSunFlaskBlastLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "blastEffect" then
		theAction.addInfo = ""

		local c, r = theAction.ItemPos1.x, theAction.ItemPos1.y
		local rectangleAction = GameBoardActionDataSet:createAs(
									GameActionTargetType.kGameItemAction,
									GameItemActionType.kItemSpecial_rectangle,
									IntCoord:create(c - 1, r - 1),
									IntCoord:create(c + 1, r + 1),
									GamePlayConfig_MaxAction_time)
		rectangleAction.addInt2 = 1
		-- rectangleAction.eliminateChainIncludeHem = true
		rectangleAction.footprintType = ObstacleFootprintType.k_SunFlask
		rectangleAction.SpecialID = mainLogic:addSrcSpecialCoverToList(IntCoord:create(r, c))
		mainLogic:addDestructionPlanAction(rectangleAction)

		SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, theAction.targetFlask.y, theAction.targetFlask.x)	--需要点亮路径
	end

	if theAction.addInfo == "vanish" then
		theAction.addInfo = ""

		SunflowerLogic:onSunFlaskDestroyed(mainLogic, theAction.targetFlask, theAction.canCharge)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_SunFlask, ObstacleFootprintAction.k_Attack, 1)
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionSunFlaskBlastLogic   OVER")

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionSunFlaskBlastView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		--动画外层播放了，这里重复……
		-- if theAction.jsq == 0 then
			-- local c, r = theAction.ItemPos1.x, theAction.ItemPos1.y
			-- local itemView = boardView.baseMap[r][c]
			-- itemView:playSunFlaskBeingHit()
		-- end 		

		theAction.jsq = theAction.jsq + 1

		--- 释放瓶中太阳
		local addSunDelay = 9
		if theAction.jsq == addSunDelay then
			-- theAction.addInfo = "addSun"
			if theAction.targetSunflower then 	--场上没有向日葵就不播放释放太阳
				local sunflowerView = boardView.baseMap[theAction.targetSunflower.y][theAction.targetSunflower.x]
				if sunflowerView and theAction.canCharge then
					if theAction.targetSunflower:isVisibleAndFree() then
						local flaskView = boardView.baseMap[theAction.ItemPos1.y][theAction.ItemPos1.x]
						local fromPos = flaskView:getBasePosition(theAction.ItemPos1.x, theAction.ItemPos1.y)
						local toPos = sunflowerView:getBasePosition(theAction.targetSunflower.x, theAction.targetSunflower.y)
						sunflowerView:playSunflowerAbsorbSun(fromPos, toPos)
					else
						sunflowerView:decreaseSunflowerNumViewRespectively()	--不显示在明面上的，削减数字就行
					end
				end
			end
		end

		--- 震荡波效果
		local blastAnimationDelay = 14
		if theAction.jsq == blastAnimationDelay then
			theAction.addInfo = "blastEffect"
		end

		-- 自身消失
		local vanishDelay = blastAnimationDelay + 17
		if theAction.jsq == vanishDelay then
			theAction.addInfo = "vanish"

			-- 鱿鱼用：鱿鱼击碎阳光罐时，需要暂时先屏蔽通用的试图更新逻辑....此时充能动画播放完毕，解锁
			local r, c = theAction.ItemPos1.y, theAction.ItemPos1.x
			local flaskData = boardView.gameBoardLogic.gameItemMap[r][c]
			if flaskData then
				flaskData.temporaryForbidUpdateView = nil
			end
		end

		--- 整体结束（考虑等待太阳被向日葵吃掉的动画）
		local blowDurationDelay = 60
		if theAction.jsq == blowDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

-----
function DestroyItemLogic:runGameItemActionSunFlowerBlastLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "blastEffect" then
		theAction.addInfo = ""

		local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
		local rectangleAction = GameBoardActionDataSet:createAs(
									GameActionTargetType.kGameItemAction,
									GameItemActionType.kItemSpecial_rectangle,
									IntCoord:create(0, 0),
									IntCoord:create(rowAmount, colAmount),
									GamePlayConfig_MaxAction_time)
		rectangleAction.addInt2 = 1
		-- rectangleAction.eliminateChainIncludeHem = true
		--太阳花 果酱兼容
		rectangleAction.SpecialID = mainLogic:addSrcSpecialCoverToList(IntCoord:create(theAction.targetFlower.y, theAction.targetFlower.x))
		mainLogic:addDestructionPlanAction(rectangleAction)

		SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, theAction.targetFlower.y, theAction.targetFlower.x)	--需要点亮路径

		GamePlayHapticsPlayer.getInstance():playEffect("sunflower_blast")
		GamePlayMusicPlayer:playEffect(GameMusicType.kSunflowerBlast)
	end

	-- if theAction.addInfo == "deleteSelf" then
	-- 	theAction.addInfo = ""
	-- 	SunflowerLogic:onSunFlowerDestroyed(mainLogic, theAction.targetFlower)
	-- end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionSunFlowerBlastLogic   OVER")
		SunflowerLogic:onSunFlowerDestroyed(mainLogic, theAction.targetFlower)

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionSunFlowerBlastView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			theAction.addInfo = "blastEffect"
		end

		theAction.jsq = theAction.jsq + 1

		-- if theAction.jsq == 2 then
		-- 	theAction.addInfo = "deleteSelf"
		-- end

		--- 整体结束
		local blowDurationDelay = 10
		if theAction.jsq == blowDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

------------------------------------------------------------------------------
--										Squid
------------------------------------------------------------------------------
--------- Collect
function DestroyItemLogic:runGameItemActionSquidCollectLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionSquidCollectLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionSquidCollectView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local targetSquid = theAction.targetSquid
			local newTargetAmount = theAction.newTargetAmount

			local squidView = boardView.baseMap[targetSquid.y][targetSquid.x]
			local fromPos
			if theAction.ItemPos1 then
				fromPos = squidView:getBasePosition(theAction.ItemPos1.x, theAction.ItemPos1.y)
			end
			local toPos = squidView:getBasePosition(targetSquid.x, targetSquid.y)
			squidView:playSquidTargetFly(fromPos, toPos, newTargetAmount)
		end

		theAction.jsq = theAction.jsq + 1

		--- 整体结束
		local wholeDurationDelay = 60
		if theAction.newTargetAmount >= theAction.targetSquid.squidTargetNeeded then
			wholeDurationDelay = 120	--如果充满了，会有更多动画，等待时间延长
		end
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

--------- Run
function DestroyItemLogic:runGameItemActionSquidRunLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		local targetGrids = theAction.targetGrids
		local headpos = targetGrids[1]
		local direction = theAction.targetSquid.squidDirection
		local addr,addc
		if direction == SquidDirection.kUp then
			addr,addc = 1, 0
		elseif direction == SquidDirection.kRight then
			addr,addc = 0, 1
		elseif direction == SquidDirection.kDown then
			addr,addc = -1, 0
		elseif direction == SquidDirection.kLeft then
			addr,addc = 0, 1
		end
		local firstpos = IntCoord:create(headpos.r + addr, headpos.c + addc)
		theAction.SpecialID1, theAction.SpecialID2 = mainLogic:addSrcSpecialCoverToList( firstpos, IntCoord:create(headpos.r, headpos.c) )

		local jamList = {}
		local SpecialID, JamStopNum, JamStop

		SpecialID = theAction.SpecialID2 or theAction.SpecialID1

		for i,target in ipairs(targetGrids) do
			if i > 1 then
				local curpos = IntCoord:create(target.r, target.c)
				local nextpos = targetGrids[i+1]
				if nextpos then
					nextpos = IntCoord:create(nextpos.r, nextpos.c)
				else
					nextpos = IntCoord:create(-1, -1)
				end
				local boardData = mainLogic.boardmap[target.r][target.c]
				if boardData:hasJamSperad() then
					JamStop = false
					JamStopNum = 0
				end

				SpecialID, JamStopNum, JamStop = DestructionPlanLogic:JamSperadSpecialIDCheck(
					mainLogic,
					curpos,
					nextpos,
					JamStop or false,
					JamStopNum or 0,
					SpecialID,
					SquidLogic:isJustRemoveItem(target)
				)

				jamList[i] = SpecialID
			end
		end
		theAction.jamList = jamList

		for _, targetPos in pairs(targetGrids) do
			if mainLogic.gameItemMap[targetPos.r] and mainLogic.gameItemMap[targetPos.r][targetPos.c] then
				local toLockItem = mainLogic.gameItemMap[targetPos.r][targetPos.c]
				if toLockItem then
					-- printx(11, "* add lock")
					toLockItem:addSquidLockValue()
					mainLogic:checkItemBlock(toLockItem.y, toLockItem.x)
				end
			end
		end

		mainLogic:addScoreToTotal(theAction.targetSquid.y, theAction.targetSquid.x, GamePlayConfigScore.MatchBySnow)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Squid, ObstacleFootprintAction.k_Attack, 1)
		ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Squid, ObstacleFootprintAction.k_HitTargets, theAction.gridAmount - 1) --包含自己的一个格子

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	--kItem_Squid_BombGrid
	if theAction.addInfo == "startBombItem" then
		theAction.startBomb = true
		theAction.bombedGridAmount = 0
		theAction.bombFrameGap = 1

		theAction.addInfo = ""
	end

	if theAction.startBomb then
		theAction.bombFrameGap = theAction.bombFrameGap - 1
		if theAction.bombFrameGap <= 0 then
			local targetGridItem
			local currPos = theAction.targetGrids[theAction.bombedGridAmount + 1]
			if currPos and mainLogic.gameItemMap[currPos.r] then
				targetGridItem = mainLogic.gameItemMap[currPos.r][currPos.c]
			end

			if targetGridItem then
				-- targetGridItem:reduceSquidLockValue()
				-- if not targetGridItem:hasSquidLock() then
					if theAction.bombedGridAmount < 1 then
						--章鱼头部的格子
						theAction.targetSquidHead = targetGridItem
						if (theAction.SpecialID1 and mainLogic:checkSrcSpecialCoverListIsHaveJamSperad(theAction.SpecialID1)) 
							or (theAction.SpecialID2 and mainLogic:checkSrcSpecialCoverListIsHaveJamSperad(theAction.SpecialID2)) then
							GameExtandPlayLogic:addJamSperadFlag(mainLogic, currPos.r, currPos.c, true )
						end
					else
						--其他格子
						local bombAction = GameBoardActionDataSet:createAs(
													GameActionTargetType.kGameItemAction,
													GameItemActionType.kItem_Squid_BombGrid,
													nil,
													nil,
													GamePlayConfig_MaxAction_time)

						local nextpos = theAction.targetGrids[theAction.bombedGridAmount + 2]
						if nextpos then
							nextpos = IntCoord:create(nextpos.r, nextpos.c)
						else
							nextpos = IntCoord:create(-1, -1)
						end

						bombAction.targetItem = targetGridItem
						bombAction.nextPos = nextpos
						bombAction.squidDirection = theAction.targetSquid.squidDirection
						bombAction.SpecialID = theAction.jamList[theAction.bombedGridAmount + 1]
						-- bombAction.jamList = theAction.jamList
						-- mainLogic:addDestroyAction(bombAction)
						mainLogic:addDestructionPlanAction(bombAction)
					end
				-- end
			end
			
			theAction.bombedGridAmount = theAction.bombedGridAmount + 1
			theAction.bombFrameGap = 2	--每几帧炸一个格子
		end

		if theAction.bombedGridAmount >= (theAction.gridAmount + 1) then
			theAction.startBomb = false
		end
	end

	if theAction.addInfo == "animationEnded" then
		mainLogic:tryDoOrderList(theAction.targetSquid.y, theAction.targetSquid.x, GameItemOrderType.kOthers, GameItemOrderType_Others.kSquid, 1)
		SquidLogic:removeSquidDataOfGrid(mainLogic, theAction.targetSquid)	--最后清除鱿鱼格子的数据
		theAction.targetSquidHead:cleanSquidLock()
		SquidLogic:removeSquidDataOfGrid(mainLogic, theAction.targetSquidHead)

		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionSquidCollectLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionSquidRunView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local targetSquid = theAction.targetSquid
			local gridAmount = theAction.gridAmount	--由于鱿鱼帽子的缘故，此值必 >= 1

			local squidView = boardView.baseMap[targetSquid.y][targetSquid.x]
			local startPos = squidView:getBasePosition(theAction.targetSquid.x, theAction.targetSquid.y)
			squidView:playSquidRun(gridAmount, startPos)
		end

		theAction.jsq = theAction.jsq + 1
		-- printx(11, "* * *", theAction.jsq)

		local startBombDelay = 75
		if theAction.jsq == startBombDelay then
			theAction.addInfo = "startBombItem"
		end

		--- 整体结束
		local wholeDurationDelay = 100	--注意这个值不要比 startBombDelay + gridAmount * bombFrameGap 要小，不然处理不完被炸的格子
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "animationEnded"
		end
	end
end

--万生被打
function DestroyItemLogic:runningGameItemActionWanShengIncrease(mainLogic, theAction, actid, actByView)
	-- body
    if theAction.addInfo == "NeedUpdate" then
        local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y

        local itemData = mainLogic.gameItemMap[r][c]
--        itemData.isNeedUpdate = true

        theAction.addInfo = "over"
    elseif theAction.addInfo == "over" then
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionWanShengInc(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		local itemView = boardView.baseMap[r][c]
		itemView:playWanShengDec(theAction.addInt)

        theAction.jsq = 0
        theAction.UpdateCDTime = 1

        local level1To2NeedCD = 52
        local level2To3NeedCD = 59

        local itemData = boardView.gameBoardLogic.gameItemMap[r][c]
        if itemData.wanShengLevel == 2 then
            theAction.UpdateCDTime = level1To2NeedCD
        elseif itemData.wanShengLevel == 3 then
            theAction.UpdateCDTime = level1To2NeedCD + level2To3NeedCD
        end
	end

    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.jsq == theAction.UpdateCDTime then
            theAction.addInfo = "NeedUpdate"
        end

        theAction.jsq = theAction.jsq + 1
    end
end

function DestroyItemLogic:runningGameItemActionApplyMilkLogic( mainLogic, theAction, actid )
	if theAction.addInfo == "ready" then
        theAction.addInfo = "updateView"
        theAction.jsq = 0
    elseif theAction.addInfo == "waiting" then
    	theAction.jsq = theAction.jsq + 1
        if theAction.jsq == 20 then
	        theAction.addInfo = "over"
        end
    elseif theAction.addInfo == "over" then
    	ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Biscuit, ObstacleFootprintAction.k_Charge, 1)
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runningGameItemActionApplyMilkView( boardView, theAction )
	if theAction.addInfo == "updateView" then
        local itemView = boardView.baseMap[theAction.ItemPos1.x][theAction.ItemPos1.y]
        itemView:playAppkyMilkAnim(theAction.addBiscuitData, theAction.ItemPos2.x, theAction.ItemPos2.y)
        theAction.addInfo = "waiting"
    end
end

------- GENERATE ---------
function DestroyItemLogic:runGameItemActionGyroGenerateLogic(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		-- printx(11, "start runGameItemActionPacmanGenerate")
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPacmanGenerateLogic   OVER")
		if theAction.newRule then
			for i, v in ipairs(theAction.pickedTargets) do 
				local CreaterItem = mainLogic:getGameItemAt(v.gyroCreaterPos.x, v.gyroCreaterPos.y)
				GyroLogic:updateNewGyro(mainLogic, v)
				if CreaterItem and CreaterItem.ItemType == GameItemType.kGyroCreater then
					CreaterItem.gyroGeneratedByStep = CreaterItem.gyroGeneratedByStep + 1
				end
			end
			for i, v in ipairs(theAction.spareTargets) do 
				local CreaterItem = mainLogic:getGameItemAt(v.gyroCreaterPos.x, v.gyroCreaterPos.y)
				GyroLogic:updateNewGyro(mainLogic, v)
				if CreaterItem and CreaterItem.ItemType == GameItemType.kGyroCreater then
					CreaterItem.gyroGeneratedByBoardMin = CreaterItem.gyroGeneratedByBoardMin + 1
				end
			end
		else
			local finalgenerateList = theAction.finalgenerateList

			for _, targetItem in ipairs(theAction.pickedTargets) do

				local bContinue = false
				local row = targetItem.gyroCreaterPos.x
				local col = targetItem.gyroCreaterPos.y

				local finalgenerateListIndex = 0
				for i,v in ipairs(finalgenerateList) do
					if v.gyroCreaterPos.x == row and v.gyroCreaterPos.y == col then
						finalgenerateListIndex = i
						break
					end
				end

				if finalgenerateListIndex == 0 then
					bContinue = true
					break
				end

				if not bContinue then
					local generateInfo = finalgenerateList[finalgenerateListIndex]
					local CreaterItem = mainLogic:getGameItemAt(generateInfo.gyroCreaterPos.x, generateInfo.gyroCreaterPos.y)

					GyroLogic:updateNewGyro(mainLogic, targetItem)

					--果酱兼容
					-- local mathBoard = mainLogic.boardmap[generateInfo.gyroCreaterPos.y][generateInfo.gyroCreaterPos.x]
		   --      	local TurrectHaveJamSperad = mathBoard:hasJamSperad()
		   --          if TurrectHaveJamSperad then
		   --          	GameExtandPlayLogic:addJamSperadFlag(mainLogic, targetItem.y, targetItem.x, true )
		   --          end

					if generateInfo.generateNumByBoardMin > 0 then
						if CreaterItem and CreaterItem.ItemType == GameItemType.kGyroCreater then
							CreaterItem.gyroGeneratedByBoardMin = CreaterItem.gyroGeneratedByBoardMin + 1
						end
						generateInfo.generateNumByBoardMin = generateInfo.generateNumByBoardMin - 1
						-- printx(11, "add pacmanGeneratedByBoardMin to: ", mainLogic.pacmanGeneratedByBoardMin)
					else
						if CreaterItem and CreaterItem.ItemType == GameItemType.kGyroCreater then
							CreaterItem.gyroGeneratedByStep = CreaterItem.gyroGeneratedByStep + 1
						end
						-- generateNumByStep = generateNumByStep - 1
						-- printx(11, "add pacmanGeneratedByStep to: ", mainLogic.pacmanGeneratedByStep)
					end
				end
			end
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionGyroGenerateView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.jsq == 0 then
			local finalTargets = {}
			if theAction.newRule then
				for i, v in ipairs(theAction.pickedTargets) do 
					table.insert(finalTargets, v) 
				end
				for i, v in ipairs(theAction.spareTargets) do 
					table.insert(finalTargets, v) 
				end
			else
				for i, v in ipairs(theAction.pickedTargets) do 
					table.insert(finalTargets, v) 
				end
			end
			for _, targetItem in ipairs(finalTargets) do
				local function onGenerateJumpEnd()
					if theAction.generateCount then
						theAction.generateCount = theAction.generateCount - 1
					end

					if not theAction.generateCount or theAction.generateCount <= 0 then
						theAction.addInfo = "over"
					end
				end

				local denPos = targetItem.gyroCreaterPos
				local fromRow, fromCol = denPos.x, denPos.y
				local toRow, toCol = targetItem.y, targetItem.x
				
				--播放生成器生成动画
				local denView = boardView.baseMap[fromRow][fromCol]
				denView:playGyroCreaterGenerateGyro(onGenerateJumpEnd)
				
				--播放箭头
				local gyroView = boardView.baseMap[toRow][toCol]
				local toPos = gyroView:getBasePositionWeek(toCol, toRow)

				-- gyroView:playGyroArrowAnim( targetItem.gyroDirection, toPos, toCol, toRow)
				
				if not theAction.generateCount then
					theAction.generateCount = 0
				end
				theAction.generateCount = theAction.generateCount + 1
			end
		end

		theAction.jsq = theAction.jsq + 1
	end
end


function DestroyItemLogic:runGameItemActionGyroRemoveLogic(mainLogic, theAction, actid )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		-- printx(11, "start runGameItemActionPacmanGenerate")
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		theAction.addInfo = "GyroRemove"
	end

	if theAction.addInfo == 'waitOver' then
		if theAction.jsq == 40 then
			theAction.addInfo = "over"
			theAction.jsq = 0
		end
	elseif theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPacmanGenerateLogic   OVER")

		for i,v in ipairs(theAction.finalgenerateList) do
			local row = v.gyroCreaterPos.x
			local col = v.gyroCreaterPos.y

			local CreaterItem = mainLogic:getGameItemAt(row, col)

			if CreaterItem and CreaterItem.ItemType == GameItemType.kGyroCreater then
				CreaterItem:cleanAnimalLikeData()
			    CreaterItem.isNeedUpdate = true
			    mainLogic:checkItemBlock(CreaterItem.y, CreaterItem.x)
			end
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionGyroRemoveView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.addInfo == "GyroRemove" then

			for i,v in ipairs(theAction.finalgenerateList) do
				local row = v.gyroCreaterPos.x
				local col = v.gyroCreaterPos.y

				local grroView = boardView.baseMap[row][col]
				grroView:playGyroCreaterRemove()
			end

			theAction.addInfo = "waitOver"
			theAction.jsq = 0
		end

		theAction.jsq = theAction.jsq + 1
	end
end


function DestroyItemLogic:runGameItemActionGyroUpgradeLogic(mainLogic, theAction, actid)
    local fromRow, fromCol = theAction.ItemPos1.x, theAction.ItemPos1.y

    if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
        theAction.gyro = mainLogic.gameItemMap[fromRow][fromCol]
        theAction.Director = theAction.gyro.gyroDirection

        theAction.addInfo = "TouchGyro"
	end

    if theAction.addInfo == 'TouchGyro' then
    	--升级。到2级执行消除 
    	theAction.gyro.gyroLevel = theAction.gyro.gyroLevel + 1
    	if theAction.gyro.gyroLevel == 2 then
    		local gyroDirection = theAction.Director

    		-- GyroLogic:onHitTargets(mainLogic, theAction.gyro, gyroDirection )

    		theAction.addInfo = 'GyroAttacking'
			theAction.jsq = 0
		elseif theAction.gyro.gyroLevel > 2 then 
			theAction.addInfo = 'waitover'
			theAction.jsq = 0
		else
			theAction.addInfo = 'GyroUpdate'
			theAction.jsq = 0
    	end
	elseif theAction.addInfo == 'GyroAttacking' then  
		-- if theAction.jsq == 3 then
			if theAction.gyro then

				--从父creater 列表里删除
				if theAction.gyro.gyroCreaterPos then
					local Item = mainLogic:getGameItemAt(theAction.gyro.gyroCreaterPos.x, theAction.gyro.gyroCreaterPos.y)
					if Item then
						local index = 0
						for i,v in ipairs(Item.gyroCreaterChildList) do
							if v.x == fromRow and v.y == fromCol then
								index = i
								break
							end
						end

						if index > 0 then
							table.remove( Item.gyroCreaterChildList, index)
						end
					end
				end


			    -- theAction.gyro:cleanAnimalLikeData()
			    -- theAction.gyro.isNeedUpdate = true
			    -- mainLogic:checkItemBlock(theAction.gyro.y, theAction.gyro.x)
		    end

			theAction.addInfo = 'waitDead'
			theAction.jsq = 0
		-- end
	elseif theAction.addInfo == 'waitCollect' then  
		if not theAction.moveCellNum then
			theAction.moveCellNum = TileGyro:getMoveCellNum( theAction.Director, fromCol, fromRow )
			theAction.attackNum = 0
		end

		theAction.addInfo = 'attack'
		theAction.jsq = 0
	elseif theAction.addInfo == 'attack' then  
		if theAction.jsq == 4 then
			if theAction.attackNum ~= theAction.moveCellNum then
				if theAction.attackNum == 0 then
					--打蜗牛路径一下 --还需要打哪里的话再后面跟着把
					SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, fromRow, fromCol)
				end

				theAction.attackNum = theAction.attackNum + 1
				theAction.jsq = 0

				local targetRow = fromRow --y
				local targetCol = fromCol --x
				if theAction.Director == 1 then
					targetRow = fromRow - theAction.attackNum
				elseif theAction.Director == 2 then
					targetCol = fromCol + theAction.attackNum
				elseif theAction.Director == 3 then
					targetRow = fromRow + theAction.attackNum
				elseif theAction.Director == 4 then
					targetCol = fromCol - theAction.attackNum
				end

				local startPos = IntCoord:create(targetCol, targetRow)

				-- local Item = mainLogic:getGameItemAt(targetRow, targetCol)
				-- if Item.isUsed then
				-- 	Item.gyroPathBlock = Item.gyroPathBlock + 1
				-- 	mainLogic:checkItemBlock(targetRow, targetCol)
				-- end

				local mathBoard = mainLogic.boardmap[fromRow][fromCol]
	        	local TurrectHaveJamSperad = mathBoard:hasJamSperad()
	            if TurrectHaveJamSperad then
			        GameExtandPlayLogic:addJamSperadFlag(mainLogic, targetRow, targetCol )
			    end

				local rectangleAction = GameBoardActionDataSet:createAs(
											GameActionTargetType.kGameItemAction,
											GameItemActionType.kItemSpecial_rectangle,
											startPos,
											startPos,
											GamePlayConfig_MaxAction_time)
				rectangleAction.addInt2 = 1
				rectangleAction.eliminateChainIncludeHem = true
				-- rectangleAction.footprintType = ObstacleFootprintType.k_Turret
				mainLogic:addDestructionPlanAction(rectangleAction)
			else
				theAction.addInfo = 'attackEnd'
				theAction.jsq = 0
			end
		end
	elseif theAction.addInfo == 'attackEnd' then 
		if theAction.jsq == 25 then
			for i=1, theAction.moveCellNum  do
				local targetRow = fromRow --y
				local targetCol = fromCol --x
				if theAction.Director == 1 then
					targetRow = fromRow - i
				elseif theAction.Director == 2 then
					targetCol = fromCol + i
				elseif theAction.Director == 3 then
					targetRow = fromRow + i
				elseif theAction.Director == 4 then
					targetCol = fromCol - i
				end

				-- local Item = mainLogic:getGameItemAt(targetRow, targetCol)
				-- if Item.isUsed then
				-- 	Item.gyroPathBlock = Item.gyroPathBlock - 1
				-- 	mainLogic:checkItemBlock( targetRow, targetCol )
				-- end
			end

			theAction.addInfo = 'tryDoOrderList'
			theAction.jsq = 0
		end
	elseif theAction.addInfo == 'tryDoOrderList' then  
		local targetRow = fromRow --y
		local targetCol = fromCol --x
		if theAction.Director == 1 then
			targetRow = fromRow - theAction.moveCellNum
		elseif theAction.Director == 2 then
			targetCol = fromCol + theAction.moveCellNum
		elseif theAction.Director == 3 then
			targetRow = fromRow + theAction.moveCellNum
		elseif theAction.Director == 4 then
			targetCol = fromCol - theAction.moveCellNum
		end

		mainLogic:tryDoOrderList(targetRow, targetCol, GameItemOrderType.kOthers, GameItemOrderType_Others.kGyro, 1)
		SquidLogic:checkSquidCollectItem(mainLogic, fromRow, fromCol, TileConst.kGyro)
		GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, fromRow, fromCol, Blocker195CollectType.kGyro)
		
		--更新自己
		if theAction.gyro then
			mainLogic:addScoreToTotal(theAction.gyro.y, theAction.gyro.x,  GamePlayConfigScore.Gyro )
		    theAction.gyro:cleanAnimalLikeData()
		    theAction.gyro.isNeedUpdate = true
		    mainLogic:checkItemBlock(theAction.gyro.y, theAction.gyro.x)
		end

		theAction.addInfo = 'waitover'
		theAction.jsq = 0

    elseif theAction.addInfo == 'over' then
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionGyroUpgradeView(boardView, theAction)

    local fromRow, fromCol = theAction.ItemPos1.x, theAction.ItemPos1.y
    local gyroView = boardView.baseMap[fromRow][fromCol]
    local ActionOverDelay = 20 --default

    if theAction.actionStatus == GameActionStatus.kRunning then

    	if theAction.addInfo == "waitDead" then

    		local fromPos = gyroView:getBasePositionWeek(fromCol, fromRow)

        	gyroView:playGyroRemove()
        	gyroView:playGyroMoveAnimation(theAction.Director,fromPos, fromCol, fromRow)

        	theAction.addInfo = 'waitCollect'
			theAction.jsq = 0
		elseif theAction.addInfo == "GyroUpdate" then
        	gyroView:playGyroUpdateAnim()

        	theAction.addInfo = 'waitover'
			theAction.jsq = 0
        elseif theAction.addInfo == "waitover" then
            --- 整体结束
		    if theAction.jsq == ActionOverDelay then
			    theAction.addInfo = "over"
		    end
        end

        theAction.jsq = theAction.jsq + 1
    end
end



--暑期技能2
function DestroyItemLogic:runningGameItemActionRailRoadSkill2Logic(mainLogic, theAction, actid, actByView)
    -- body
	local function overAction( ... )
		-- body
		theAction.addInfo = ""
		mainLogic.destroyActionList[actid] = nil
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic:setNeedCheckFalling()
	end

	local function bombItem(r, c)

		local startPos = IntCoord:create(c, r)
		local rectangleAction = GameBoardActionDataSet:createAs(
									GameActionTargetType.kGameItemAction,
									GameItemActionType.kItemSpecial_rectangle,
									startPos,
									startPos,
									GamePlayConfig_MaxAction_time)
		rectangleAction.addInt2 = 1
		rectangleAction.eliminateChainIncludeHem = true
		mainLogic:addDestructionPlanAction(rectangleAction)

		-- body
		-- local item = mainLogic.gameItemMap[r][c]
		-- local boardData = mainLogic.boardmap[r][c]

  --       if item.isUsed then
  --           view:playBonusTimeEffcet()
  --       end
	end

	if theAction.addInfo == "over" then

		local gameItemMap = mainLogic.gameItemMap
		if theAction.canBeInfectItemList then
			if theAction.canBeInfectItemList then
	        	for i,v in ipairs(theAction.canBeInfectItemList) do
		            if gameItemMap[v.x] and gameItemMap[v.x][v.y] then
			            local item = gameItemMap[v.x][v.y]
			            bombItem(item.y, item.x )
			        end
		        end
		    end
		end

		overAction()
	end
end

function DestroyItemLogic:runGameItemActionRailRoadSkill2View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        --view 展示
        theAction.addInfo = "waitForAnimation"
		theAction.jsq = 0
        theAction.animationDelay = 55
	end

    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "waitForAnimation" then
            if theAction.jsq == 0 then
                local worldPosList = {}

	        	if theAction.canBeInfectItemList then
		        	for i,v in ipairs(theAction.canBeInfectItemList) do
			            local r = v.x
			            local c = v.y
					    local item = boardView.baseMap[r][c]
			            local toWorldPos =  boardView:convertToWorldSpace(item:getBasePosition(c, r))

			            local toPos = IntCoord:create( toWorldPos.x,toWorldPos.y )
			            table.insert( worldPosList, toPos )
			        end
			    end

                theAction.addInfo = "playAnimation"
                theAction.jsq = 0
            end
        elseif theAction.addInfo == "playAnimation" then
            if theAction.jsq == theAction.animationDelay then
			    theAction.addInfo = "over" 
		    end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

--暑期技能3
function DestroyItemLogic:runningGameItemActionRailRoadSkill3Logic(mainLogic, theAction, actid, actByView)

	-- body
	if theAction.addInfo == "changeItem" then

		local gameItemMap = mainLogic.gameItemMap

		if theAction.canBeInfectItemList then
        	for i,v in ipairs(theAction.canBeInfectItemList) do
	            if gameItemMap[v.x] and gameItemMap[v.x][v.y] then
		            local item = gameItemMap[v.x][v.y]
		            if i%2 == 0 then
			            item:changeToLineAnimal()
			        else
			            item:changeToWrapAnimal()
			        end
		        end
	        end

	        theAction.jsq = 0
            theAction.addInfo = "waitOver"
        else
        	theAction.addInfo = "over"
	    end
    elseif theAction.addInfo == "waitOver" then
        if theAction.jsq == 20 then
            theAction.addInfo = "over"
        end
    elseif theAction.addInfo == "over" then
    	if theAction.completeCallback then 
			theAction.completeCallback()
		end
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionRailRoadSkill3View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        theAction.jsq = 0
		theAction.addInfo = "playAnim"	
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

        if theAction.addInfo == "playAnim" then

        	local worldPosList = {}

        	if theAction.canBeInfectItemList then
	        	for i,v in ipairs(theAction.canBeInfectItemList) do
		            local r = v.x
		            local c = v.y
				    local item = boardView.baseMap[r][c]
		            local toWorldPos =  boardView:convertToWorldSpace(item:getBasePosition(c, r))

		            table.insert( worldPosList, toWorldPos )
		        end
		    end

            theAction.jsq = 0
            theAction.addInfo = "waitAnimEnd"
        elseif  theAction.addInfo == "waitAnimEnd" then
            if theAction.jsq == 20 then
                theAction.addInfo = "changeItem"
            end
        end

        theAction.jsq = theAction.jsq + 1
    end
end

--暑期技能4
function DestroyItemLogic:runningGameItemActionRailRoadSkill4Logic(mainLogic, theAction, actid, actByView)
    -- body
	local function overAction( ... )
		-- body
		theAction.addInfo = ""
		mainLogic.destroyActionList[actid] = nil
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic:setNeedCheckFalling()
	end

	local function bombItem(r, c, dirs)
		-- body
		local item = mainLogic.gameItemMap[r][c]
		local boardData = mainLogic.boardmap[r][c]

        if item and item.isUsed then
		    BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
		    SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3,nil,nil,nil,nil,nil) 
		    SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c, dirs) --冰柱处理
		    SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
		    GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, item._encrypt.ItemColorType, false, 3)

            --背景高亮
            local view = mainLogic.boardView.baseMap[r][c]
            view:playBonusTimeEffcet()
        end
	end

	if theAction.addInfo == "over" then
		local r_min = theAction.ItemPos1.x
		local r_max = theAction.ItemPos2.x
		local c_min = theAction.ItemPos1.y
		local c_max = theAction.ItemPos2.y

        ---3*2格子
		for r = r_min , r_max do 
			for c = c_min, c_max do 
				local dirs = {ChainDirConfig.kUp, ChainDirConfig.kDown, ChainDirConfig.kRight, ChainDirConfig.kLeft}
				if r == r_min then 
					table.remove(dirs, ChainDirConfig.kUp)
				elseif r == r_max then 
					table.remove(dirs, ChainDirConfig.kDown)
				elseif c == c_min then 
					table.remove(dirs, ChainDirConfig.kLeft)
				elseif c == c_max then 
					table.remove(dirs, ChainDirConfig.kRight)
				end
				bombItem(r, c, dirs )
			end
		end

		overAction()
	end
end

function DestroyItemLogic:runGameItemActionRailRoadSkill4View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        local r_min = theAction.ItemPos1.x
		local r_max = theAction.ItemPos2.x
		local c_min = theAction.ItemPos1.y
		local c_max = theAction.ItemPos2.y
		
        --view 展示
        theAction.addInfo = "waitForAnimation"
		theAction.jsq = 0
        theAction.animationStartDelay = theAction.delayIndex * 5
        theAction.animationDelay = 25
	end

    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "waitForAnimation" then
            if theAction.jsq == theAction.animationStartDelay then
                local r_min = theAction.ItemPos1.x
		        local r_max = theAction.ItemPos2.x
		        local c_min = theAction.ItemPos1.y
		        local c_max = theAction.ItemPos2.y

                ---2*2格子
		        local item = boardView.baseMap[r_min][c_min]
		        local pos = item:getBasePositionWeek(c_min, r_min)
                local toWorldPos =  boardView:convertToWorldSpace(pos)

                theAction.addInfo = "playAnimation"
                theAction.jsq = 0
            end
        elseif theAction.addInfo == "playAnimation" then
            if theAction.jsq == theAction.animationDelay then
			    theAction.addInfo = "over" 
		    end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

function DestroyItemLogic:runningGameItemActionAttackWater( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath

			local pos = theAction.ItemPos1
			local itemData = mainLogic.gameItemMap[pos.x][pos.y]
			itemData.isNeedUpdate = true

		end

		if theAction.addInfo == "tryDoOrderListAndClearWater" then
        	local pos = theAction.ItemPos1
			mainLogic:tryDoOrderList(pos.x, pos.y, GameItemOrderType.kOthers, GameItemOrderType_Others.kWater)
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, pos.x, pos.y, Blocker195CollectType.kWater)
			SquidLogic:checkSquidCollectItem(mainLogic, pos.x, pos.y, TileConst.kWater)	--爆炸特效没有自己的大类型，故在SquidCollectType中获取特殊代号
			WaterBucketLogic:chargeBucket(mainLogic, pos.x, pos.y)

			local itemData = mainLogic.gameItemMap[pos.x][pos.y]
			itemData:cleanAnimalLikeData()

			theAction.addInfo = "over"

			mainLogic:addScoreToTotal(pos.x, pos.y, 100)
		end

		-- if theAction.addInfo == "waitingAnimation" then
		-- 	if theAction.jsq == 62 and theAction.addInt == 0 then
  --       		local pos = theAction.ItemPos1
		-- 		local itemData = mainLogic.gameItemMap[pos.x][pos.y]
		-- 		itemData:cleanAnimalLikeData()

		-- 	end
	 --    end

    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end


function DestroyItemLogic:runGameItemActionAttackWaterView( boardView, theAction )

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        theAction.addInfo = "playAnimation"
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

        if theAction.addInfo == "playAnimation" then
        	local pos = theAction.ItemPos1
			local itemView = boardView.baseMap[pos.x][pos.y]
			itemView:playAttackWaterAnim(theAction.addInt)
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0
	    end

	    if theAction.addInfo == "waitingAnimation" then
	    	local pos = theAction.ItemPos1
	    	local itemData

			if theAction.jsq >= 70 and theAction.addInt == 1 then

				itemData = boardView.gameBoardLogic.gameItemMap[pos.x][pos.y]
				if itemData then
					itemData.temporaryForbidUpdateView = nil
				end

				theAction.addInfo = "over"
			end

			if theAction.jsq >= 50 and theAction.addInt == 0 then

				itemData = boardView.gameBoardLogic.gameItemMap[pos.x][pos.y]
				if itemData then
					itemData.temporaryForbidUpdateView = nil
				end

				theAction.addInfo = "tryDoOrderListAndClearWater"
			end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

function DestroyItemLogic:runningGameItemActionChargeBucket( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		end

		if theAction.addInfo == "writeData" then
        	local pos = theAction.ItemPos2
			local itemData = mainLogic.gameItemMap[pos.x][pos.y]
        	local posStart = theAction.ItemPos1

			WaterBucketLogic:doChargeBucket(mainLogic, itemData, theAction.addInt)
			itemData.isNeedUpdate = true
			theAction.addInfo = "over"
		end
    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionChargeBucketView( boardView, theAction )

	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
        theAction.addInfo = "playFlyAnimation"
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

    	if theAction.addInfo == "playFlyAnimation" then
        	local posStart = theAction.ItemPos1
        	local posDest = theAction.ItemPos2
			local itemView = boardView.baseMap[posDest.x][posDest.y]
			theAction.noFlyAnim = posStart.x == posDest.x and posStart.y == posDest.y

			if theAction.noFlyAnim then
				theAction.addInfo = "playAnimation"
			else
				local flyId = tostring(theAction)
				itemView:playChargeBucketFlyWaterAnim(theAction.addInt, posStart, posDest, flyId)
				theAction.addInfo = "waitingFlyAnimation"
				theAction.jsq = 0
			end
	    end

        if theAction.addInfo == "playAnimation" then
        	local posStart = theAction.ItemPos1
        	local posDest = theAction.ItemPos2

			local itemView = boardView.baseMap[posDest.x][posDest.y]

			theAction.noFlyAnim = posStart.x == posDest.x and posStart.y == posDest.y

			itemView:playChargeBucketAnim(theAction.addInt, posStart, posDest, theAction.noFlyAnim)
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0
	    end

	    if theAction.addInfo == 'waitingFlyAnimation' then
	    	if theAction.jsq >= 2/3*60 then
				theAction.addInfo = "playAnimation"
			end
	    end

	    if theAction.addInfo == "waitingAnimation" then
			if theAction.jsq >= 1 then
				theAction.addInfo = "writeData"
			end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

function DestroyItemLogic:runningGameItemActionReadyBucket( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		end

		if theAction.addInfo == "finish-anim" then
        	local pos = theAction.ItemPos1
			local itemData = mainLogic.gameItemMap[pos.x][pos.y]
			itemData.isNeedUpdate = true
			theAction.addInfo = "over"
		end
    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionReadyBucketView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
        theAction.addInfo = "playAnimation"
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

        if theAction.addInfo == "playAnimation" then
        	local pos = theAction.ItemPos1

			local itemView = boardView.baseMap[pos.x][pos.y]
			itemView:playReadyBucketAnim()
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0
	    end

	    if theAction.addInfo == "waitingAnimation" then
			if theAction.jsq >= 20 then
				theAction.addInfo = "finish-anim"
			end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

function DestroyItemLogic:runningGameItemActionAttackBucket( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		end

		if theAction.addInfo == "writeData" then
        	local pos = theAction.ItemPos1
			local itemData = mainLogic.gameItemMap[pos.x][pos.y]

			WaterBucketLogic:cleanWaterBucket(itemData)

			mainLogic:tryDoOrderList(pos.x, pos.y, GameItemOrderType.kOthers, GameItemOrderType_Others.kWaterBucket)

			mainLogic:addScoreToTotal(pos.x, pos.y, 300)

			mainLogic:checkItemBlock(pos.x, pos.y)
			mainLogic:addNeedCheckMatchPoint(pos.x, pos.y)
			mainLogic.gameMode:checkDropDownCollect(pos.x, pos.y)
			ColorFilterLogic:handleFilter(pos.x, pos.y)

			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, pos.x, pos.y, Blocker195CollectType.kWaterBucket)
			SquidLogic:checkSquidCollectItem(mainLogic, pos.x, pos.y, TileConst.kWaterBucket)	--爆炸特效

			if itemData.ItemType == 0 then
				SnailLogic:SpecialCoverSnailRoadAtPos( mainLogic, pos.x, pos.y)
			end

			mainLogic:setNeedCheckFalling()

			itemData.isNeedUpdate = true
			theAction.addInfo = "over"
		end
    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionAttackBucketView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
        theAction.addInfo = "playAnimation"
	end
    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "playAnimation" then
        	local pos = theAction.ItemPos1

			local itemView = boardView.baseMap[pos.x][pos.y]
			itemView:playBucketDisappearAnim()
			local itemData = boardView.gameBoardLogic.gameItemMap[pos.x][pos.y]
			itemData.temporaryForbidUpdateView = true
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0
	    end
	    if theAction.addInfo == "waitingAnimation" then
			if theAction.jsq >= 19*2 then

				local pos = theAction.ItemPos1
				local itemData = boardView.gameBoardLogic.gameItemMap[pos.x][pos.y]
				if itemData then
					itemData.temporaryForbidUpdateView = nil
				end
				theAction.addInfo = "writeData"

				local itemView = boardView.baseMap[pos.x][pos.y]
				if itemView then
					itemView:cleanWaterBucket()
				end
			end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end
--------------------------- end -------------------------

-------------------------------------	WindTunnelSwitch	-------------------------------------------------
function DestroyItemLogic:runGameItemActionWindTunnelSwitchDemolishLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "vanish" then
		theAction.addInfo = ""

		-- printx(11, "111 targetSwitch:", theAction.targetSwitch)
		WindTunnelLogic:onWindTunnelSwitchDestroyed(mainLogic, theAction.targetSwitch)
		-- ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_SunFlask, ObstacleFootprintAction.k_Attack, 1)
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionWindTunnelSwitchDemolishLogic   OVER")

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionWindTunnelSwitchDemolishView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startVanishDelay = 1
		if theAction.jsq == startVanishDelay then
			local r, c = theAction.ItemPos1.y, theAction.ItemPos1.x
			local switchView = boardView.baseMap[r][c]
			if switchView and switchView.playWindTunnelSwitchVanish then
				switchView:playWindTunnelSwitchVanish()
			end

			-- if theAction.targetSwitch and theAction.targetSwitch.windTunnelSwitchTypeIsOff then
				theAction.vanishDelay = 30
			-- else
			-- 	theAction.hitDelay = 30
			-- 	theAction.vanishDelay = 60
			-- end
		end

		local hitDelay = startVanishDelay + (theAction.hitDelay or 0)
		if theAction.jsq == hitDelay then
			theAction.addInfo = "flyToHit"

			local r, c = theAction.ItemPos1.y, theAction.ItemPos1.x
			local switchView = boardView.baseMap[r][c]
			if switchView then
				if theAction.targetSwitch then
					local isOffSwitch = theAction.targetSwitch.windTunnelSwitchTypeIsOff
					local targetPoints = WindTunnelLogic:getHitPointOfAllValidArea(isOffSwitch, r, c)
					if targetPoints then
						local fromPos = switchView:getBasePosition(theAction.targetSwitch.x, theAction.targetSwitch.y)
						for _, targetPoint in pairs(targetPoints) do
							local toPos = boardView.baseMap[targetPoint.r][targetPoint.c]:getBasePosition(targetPoint.c, targetPoint.r)
							switchView:playWindTunnelSwitchHitAnimation(fromPos, toPos)
						end
					end
				end
			end
		end

		-- 自身消失
		local vanishDelay = theAction.vanishDelay or 60
		if theAction.jsq == vanishDelay then
			theAction.addInfo = "vanish"

			-- 鱿鱼用：鱿鱼消除开关时，需要暂时先屏蔽通用的试图更新逻辑....此时动画播放完毕，解锁
			local r, c = theAction.ItemPos1.y, theAction.ItemPos1.x
			local switchData = boardView.gameBoardLogic.gameItemMap[r][c]
			if switchData then
				switchData.temporaryForbidUpdateView = nil
			end
		end

		--- 整体结束
		local blowDurationDelay = vanishDelay + 1
		if theAction.jsq == blowDurationDelay then
			theAction.addInfo = "over"
		end
	end
end



-- act 8001 
function DestroyItemLogic:runGameItemActionAct8001Logic( mainLogic, theAction, actid, actByView )

	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then

			if theAction.completeCallback then
				theAction.completeCallback()
			end

			theAction.actionStatus = GameActionStatus.kWaitingForDeath
		end
		if theAction.addInfo == "do" then
        	if theAction.PosList and #(theAction.PosList) > 0 then

        		local counter = #(theAction.PosList)

        		local function _callback( ... )
        			counter = counter - 1
        			if counter <= 0 then
        				theAction.addInfo = "over"
        			end
        		end

		        for i=1, #theAction.PosList do
		            local PosInfo = theAction.PosList[i]
		            if not PosInfo then break end 


		            local action = GameBoardActionDataSet:createAs(
		                    GameActionTargetType.kGameItemAction,
		                    GameItemActionType.kAct8001_Cast_Skill,
		                    IntCoord:create(PosInfo.r_min, PosInfo.c_min),
		                    IntCoord:create(PosInfo.r_max, PosInfo.c_max),
		                    GamePlayConfig_MaxAction_time
		                )

		            action.completeCallback = _callback
		            action.startPos = theAction.startPos
			        mainLogic:addDestroyAction(action)
		        end

		        theAction.addInfo = 'waiting'
		    else
				theAction.addInfo = "over"
		    end
		end
    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionAct8001View( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
        theAction.addInfo = "playAnimation"
	end
    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "playAnimation" then
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0


			local monster = UIHelper:createArmature3('tempFunctionRes/TreasureUnderSnow/monster-anim', 
					                            'monster-anim-20191012/anim-1', 'monster-anim-20191012/anim-1', 'monster-anim-20191012/anim-1', true )

			local pos = boardView:getBoardViewTilePos(9, 5)		--棋盘大小不要写死数字，已下线活动不重构，复用时请注意修改
			monster:setPositionXY(pos.x, pos.y)

			theAction.startPos = pos

			Director:sharedDirector():run():addChild(monster:wrapWithBatchNode())

			monster:ad(ArmatureEvents.COMPLETE, function ( ... )
				if monster and (not monster.isDisposed) then
					monster:rma()
					monster:ad(ArmatureEvents.COMPLETE, function ( ... )
						-- body
						if monster and (not monster.isDisposed) then
							monster:removeFromParentAndCleanup(true)
						end
					end)
					monster:playByIndex(1, 1)
				end
			end)

			monster:playByIndex(0, 1)


	    end
	    if theAction.addInfo == "waitingAnimation" then
			if theAction.jsq >= 1.3*60 then
				theAction.addInfo = "do"
			end
	    end
        theAction.jsq = theAction.jsq + 1
    end
end



-- act 8001 
function DestroyItemLogic:runGameItemActionAct8001CastSkillLogic( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == "over" then
			if theAction.completeCallback then
				theAction.completeCallback()
			end
			theAction.actionStatus = GameActionStatus.kWaitingForDeath
			mainLogic:setNeedCheckFalling()
		end

		if theAction.addInfo == "do" then

			local function bombItem(r, c, dirs)
				-- body
				local item = mainLogic.gameItemMap[r][c]
				local boardData = mainLogic.boardmap[r][c]

		        if item and item.isUsed then
				    BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
				    SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3,nil,nil,nil,nil,nil) 
				    SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c, dirs) --冰柱处理
				    SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
				    GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, item._encrypt.ItemColorType, false, 3)
		            local view = mainLogic.boardView.baseMap[r][c]
		            view:playBonusTimeEffcet()
		        end
			end

			local r_min = theAction.ItemPos1.x
			local r_max = theAction.ItemPos2.x
			local c_min = theAction.ItemPos1.y
			local c_max = theAction.ItemPos2.y

			for r = r_min , r_max do 
				for c = c_min, c_max do 
					local dirs = {ChainDirConfig.kUp, ChainDirConfig.kDown, ChainDirConfig.kRight, ChainDirConfig.kLeft}
					if r == r_min then 
						table.remove(dirs, ChainDirConfig.kUp)
					elseif r == r_max then 
						table.remove(dirs, ChainDirConfig.kDown)
					elseif c == c_min then 
						table.remove(dirs, ChainDirConfig.kLeft)
					elseif c == c_max then 
						table.remove(dirs, ChainDirConfig.kRight)
					end
					bombItem(r, c, dirs )
				end
			end

			theAction.addInfo = "over"
		end
    end

    if theAction.actionStatus == GameActionStatus.kWaitingForDeath then
    	mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionAct8001CastSkillView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
        theAction.addInfo = "playAnimation"
	end
    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "playAnimation" then
			theAction.addInfo = "waitingAnimation"
			theAction.jsq = 0


			local snow = UIHelper:createSpriteFrame('tempFunctionRes/TreasureUnderSnow/start.json', 'snow-fly-wind-smile.start/snow0000')
			snow:setAnchorPoint(ccp(0.5, 0.5))
			snow:setPosition(ccp(theAction.startPos.x, theAction.startPos.y))



			local r_min = theAction.ItemPos1.x
			local r_max = theAction.ItemPos2.x
			local c_min = theAction.ItemPos1.y
			local c_max = theAction.ItemPos2.y

			local midr = (r_min + r_max) / 2 
			local midc = (c_min + c_max) / 2 

			local targetPos = boardView:getBoardViewTilePos(midr, midc)

			snow:runAction(UIHelper:sequence{CCMoveTo:create(38/60/2, targetPos), CCCallFunc:create(function ( ... )
				if snow and (not snow.isDisposed) then
					snow:removeFromParentAndCleanup(true)
				end
			end)})

			Director:sharedDirector():run():addChild(snow)


	    end
	    if theAction.addInfo == "waitingAnimation" then
			if theAction.jsq >= 19 then
				theAction.addInfo = "do"



				local effect = UIHelper:createArmature3('tempFunctionRes/TreasureUnderSnow/monster-anim', 
					                            'monster-anim-20191012/anim-2', 'monster-anim-20191012/anim-2', 'monster-anim-20191012/anim-2', true )


				local r_min = theAction.ItemPos1.x
				local r_max = theAction.ItemPos2.x
				local c_min = theAction.ItemPos1.y
				local c_max = theAction.ItemPos2.y
				local midr = (r_min + r_max) / 2 
				local midc = (c_min + c_max) / 2 

				if c_max - c_min < 1 then
					effect:setScaleX(0.5)
				end


				if r_max - r_min < 1 then
					effect:setScaleY(0.5)
				end


				local targetPos = boardView:getBoardViewTilePos(midr, midc)
				effect:setPositionXY(targetPos.x, targetPos.y)


				Director:sharedDirector():run():addChild(effect)

				effect:ad(ArmatureEvents.COMPLETE, function ( ... )
					-- body
					if effect and (not effect.isDisposed) then
						effect:removeFromParentAndCleanup(true)
					end
				end)
				effect:playByIndex(0, 1)


			end
	    end
        theAction.jsq = theAction.jsq + 1
    end
end

----感恩节收集物消除
function DestroyItemLogic:runGameItemActionActivityCollectionItemHideLogic( mainLogic, theAction, actid, actByView )
	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.addInfo == "itemLock" then
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
	        local item = mainLogic.gameItemMap[r][c]
	        item.activityCollectionItem_lock = true

			item:cleanAnimalLikeData()
	        mainLogic:checkItemBlock(r,c)

	        theAction.addInfo = "playItemDestoryAnim"

		elseif theAction.addInfo == "over" then
			if theAction.completeCallback then
				theAction.completeCallback()
			end
			mainLogic.destroyActionList[actid] = nil
		end	
	end
end

function DestroyItemLogic:runGameItemActionActivityCollectionItemHideView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.addInfo = "itemLock"
		theAction.jsq = 0
	end

	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.addInfo == "playItemDestoryAnim" then
			local r, c = theAction.ItemPos1.x, theAction.ItemPos1.y
			local itemView = boardView.baseMap[r][c]
			local tileItem = itemView:getItemSprite(ItemSpriteType.kItemShow)
			if itemView and tileItem and tileItem.activityCollectionItem_ItemId then
				tileItem:setVisible(false)
				local itemId = tileItem.activityCollectionItem_ItemId
				local fromPos = boardView:convertToWorldSpace(itemView:getBasePosition(c, r))
				ActivityClollectionItemLogic:playItemHideAnim(itemId, fromPos)
			end

			theAction.addInfo = "waitAnimEnd"
			theAction.jsq = 0
		elseif theAction.addInfo == "waitAnimEnd" then
			if theAction.jsq == 100 then
				theAction.addInfo = "over"
			end
		end

		theAction.jsq = theAction.jsq + 1
	end
end

-----------------------------------------------------------------------------------------
--       							 	TRAVEL MODE
-----------------------------------------------------------------------------------------
---------------------- Energy Bag -------------------------
function DestroyItemLogic:runGameItemActionTravelEnergyBagDemolishLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionTravelEnergyBagDemolishLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelEnergyBagDemolishView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startAnimationDelay = 1
		if theAction.jsq == startAnimationDelay then
			local travelHero = theAction.travelHero
			local heroView = boardView.baseMap[travelHero.y][travelHero.x]
			if heroView then
				local fromPos = theAction.fromPos
				local toPos = heroView:getBasePosition(travelHero.x, travelHero.y)
				heroView:playTravelHeroAbsorbEnergyBag(fromPos, toPos, theAction.bagColour)
			end
		end

		local wholeDurationDelay = 100
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

-------------------Angry Bird------------------------
function DestroyItemLogic:runGameItemActionAngryBirdWalkLogic(mainLogic, theAction, actid)
	-- printx(15,"runGameItemActionAngryBirdWalkLogic enter!!!!")
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		-- 为target加锁（用的鱿鱼锁，这种模式不会摆鱿鱼）
		local targets = theAction.nextItemList
		local angryBird = theAction.angryBird
		for i = 1 , #targets do
			local target = targets[i]
			-- printx(15,"target.y,target.x",target.y,target.x)
			if mainLogic.gameItemMap[target.y] and mainLogic.gameItemMap[target.y][target.x] then
				local toLockItem = mainLogic.gameItemMap[target.y][target.x]
				if toLockItem then
					if toLockItem.ItemType == GameItemType.kSling then
						break
					end
					-- printx(15, "=====================* add lock============================",toLockItem.y, toLockItem.x)
					toLockItem:addSquidLockValue()
					mainLogic:checkItemBlock(toLockItem.y, toLockItem.x)

				end
			end
		end

		

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 1
		theAction.addInfo = "init"
	end

	if theAction.addInfo == "clearBirdData" then
		AngryBirdLogic:removeAngryBirdDataOfGrid(mainLogic, theAction.angryBird)
		-- theAction.addInfo = nil
		theAction.addInfo = "waitingForWalk"
	elseif theAction.addInfo == "clearPassData" then
		theAction.currentMove = theAction.currentMove + 1
		local isdestination
		if theAction.currentMove == theAction.walkSteps then
			isdestination = true
		end

		if theAction.currentMove > 1 then
			local itemData = theAction.nextItemList[theAction.currentMove - 1]
			itemData:removeFallingLockByTravelHero()
			mainLogic:checkItemBlock(itemData.y, itemData.x)
		end

		-- printx(15,"开始消除",theAction.currentMove)
		AngryBirdLogic:onBirdBombGrid(mainLogic, theAction,theAction.currentMove,isdestination)

		theAction.jsq = 1
		theAction.addInfo = "waitingForWalk"
	elseif theAction.addInfo == "replaceEndData" then
		AngryBirdLogic:replaceEndData(mainLogic,theAction)
		theAction.addInfo = "over"
	elseif theAction.addInfo == "over" then
		-- printx(15, "runGameItemActionSquidCollectLogic   OVER")
		mainLogic.currMapbirdRouteLength = mainLogic.currMapbirdRouteLength - theAction.walkSteps
		-- printx(15,"mainLogic.currMapbirdRouteLength",mainLogic.currMapbirdRouteLength)
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionAngryBirdWalkView(boardView, theAction)
	--待优化 将logic相关内容分离出来 done
	if theAction.actionStatus == GameActionStatus.kRunning then
		

		if theAction.addInfo == "init" then
			theAction.tempBirdView = SpineAnimation:createWithFile(
	        "tempFunctionResInLevel/AngryBird/"..theAction.birdName..".json", 
	        "tempFunctionResInLevel/AngryBird/"..theAction.birdName..".atlas",
	        1);
			local function playForwardAnimation(targetItem)
				local itemView = boardView.baseMap[targetItem.y][targetItem.x]
				if itemView then
					local sprite = itemView:getGameItemSprite()
					-- printx(15,"sprite",sprite)
					if sprite then
						
					    theAction.tempBirdView:playByName("run", true)
					    boardView:addChild(theAction.tempBirdView)
					    theAction.tempBirdView:setPositionXY(sprite:getPositionX()-2,sprite:getPositionY()-30)
				
						
						local arr = CCArray:create()
						arr:addObject(CCCallFunc:create(function ( ... )
							
							if itemView.itemSprite[ItemSpriteType.kBirdRoad] and not itemView.itemSprite[ItemSpriteType.kBirdRoad].isDisposed then
								itemView.itemSprite[ItemSpriteType.kBirdRoad]:removeFromParentAndCleanup(true)
								itemView.itemSprite[ItemSpriteType.kBirdRoad] = nil
							end
							
						end))

						for i = 1 , theAction.walkSteps do
							local targetItem = theAction.nextItemList[i]
							local pos = UsePropState:getItemPosition(IntCoord:create(targetItem.y , targetItem.x))
							pos.x = pos.x - 2
							pos.y = pos.y - 30
							arr:addObject(CCDelayTime:create(0.05))
							arr:addObject(CCMoveTo:create(0.2, pos))
							arr:addObject(CCDelayTime:create(0.1))

						end

						local move_action = CCSequence:create(arr) 
						UIHelper:setFixUpdate(theAction.tempBirdView, true)
						theAction.tempBirdView:runAction(move_action)

					end
				end
			end

			local currentMove = theAction.currentMove
			local angryBird = theAction.angryBird
			playForwardAnimation(angryBird)
			theAction.addInfo = "clearBirdData"
		
		elseif theAction.addInfo == "waitingForWalk" then
			if theAction.currentMove == theAction.walkSteps  then
				local dest = theAction.nextItemList[theAction.walkSteps]
				local destRow = dest.y
				local destCol = dest.x
				if dest.ItemType == GameItemType.kNone then			
					theAction.addInfo = "replaceEndData"
				end
			else
				if theAction.jsq == 21 then
					theAction.addInfo = "clearPassData"
				end

				theAction.jsq = theAction.jsq + 1
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionAngryBirdShotLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then

		theAction.targetPos = mainLogic.PlayUIDelegate.topArea.pigBoss:getPosition()

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "clearBirdData" then
		AngryBirdLogic:removeAngryBirdDataOfGrid(mainLogic, theAction.angryBird)
		mainLogic.angryBirdNum = mainLogic.angryBirdNum - 1
		mainLogic.currMapbirdRouteLength = mainLogic.currMapbirdRouteLength - 1
		-- printx(15,"mainLogic.angryBirdNum",mainLogic.angryBirdNum)
		-- theAction.angryBird = nil
		-- theAction.addInfo = nil
		theAction.addInfo = "rebuildBirdRoad"

	elseif theAction.addInfo == "reachEnd" then

		AngryBirdLogic:handlePigBoss(mainLogic,theAction.birdType)
		
		if AngryBirdLogic:checkSlingNeedRemove(mainLogic,theAction.sling) then
			--有可能需要一个弹弓消失的动画 但是目前还没有
			theAction.addInfo = "clearSlingSprite"
		else
			theAction.sling.readyToShot = true
			theAction.addInfo = "over"
		end

	elseif theAction.addInfo == "clearSling" then
		AngryBirdLogic:removeAngryBirdDataOfGrid(mainLogic, theAction.sling)
		-- AngryBirdLogic:checkLevelTarget(mainLogic)
		theAction.addInfo = "over"

	elseif theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil

		--临时
		if mainLogic.angryBirdNum == 0 then
			-- printx(15,"mainLogic.currTravelMapIndex",mainLogic.currTravelMapIndex)
			mainLogic.currMapbirdRouteLength = 0 --防止中间算的不对带到下一关
			if mainLogic.currTravelMapIndex and mainLogic.currTravelMapIndex < 3 then
				mainLogic.nextBoardLevelID = mainLogic.level + 1
			elseif mainLogic.currTravelMapIndex and mainLogic.currTravelMapIndex == 3 then
				AngryBird2020Manager.getInstance():dcBeforeBonus(mainLogic)
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionAngryBirdShotView(boardView, theAction)

	if theAction.actionStatus == GameActionStatus.kRunning then
		

		if theAction.jsq == 0 then

			theAction.tempBirdView = SpineAnimation:createWithFile(
		        "tempFunctionResInLevel/AngryBird/"..theAction.birdName..".json", 
	        	"tempFunctionResInLevel/AngryBird/"..theAction.birdName..".atlas",
		        1);

			local function pullEndCallback( ... )
				if theAction.tempBirdView and not theAction.tempBirdView.isDisposed then
					theAction.tempBirdView:stop()
					if theAction.birdType == 2 then
						theAction.tempBirdView:playByName("skill",false)
						theAction.tempBirdView:addEventListener(SpineAnimationEvents.kSpineEvt, function(event)

							if event and event.data and event.data.eventType then
								if event.data.eventType == SpineEventTypes.SP_ANIMATION_COMPLETE then
									if theAction.tempBirdView and not theAction.tempBirdView.isDisposed then
										theAction.tempBirdView:playByName("fly", true)
									end
								end
							end
						end)
					else
						theAction.tempBirdView:playByName("fly",true)
					end
				end
			end

			local function flyEnd( ... )
				local slingItemView = boardView.baseMap[theAction.sling.y][theAction.sling.x]
				-- printx(15,"slingItemView",slingItemView)
				if slingItemView then
					slingItemView.itemSprite[ItemSpriteType.kItemShow]:setVisible(true)
				end
				if theAction.tempBirdView and not theAction.tempBirdView.isDisposed then
					theAction.tempBirdView:stop()
					theAction.tempBirdView:removeFromParentAndCleanup(true)
				end
				if theAction.tempSlingView and not theAction.tempSlingView.isDisposed then
					theAction.tempSlingView:removeFromParentAndCleanup(true)
				end

				theAction.addInfo = "reachEnd"
			end

			theAction.pullEnd = pullEndCallback
			theAction.flyEnd = flyEnd

			local itemView = boardView.baseMap[theAction.angryBird.y][theAction.angryBird.x]
			if itemView then
				local sprite = itemView:getGameItemSprite()
				-- printx(15,"sprite2222",sprite)
				if sprite then
					
				    theAction.tempBirdView:playByName("attack_ready", true)
				    boardView:addChild(theAction.tempBirdView)
				    theAction.tempBirdView:setPositionXY(sprite:getPositionX()-2,sprite:getPositionY()-30)
				    if itemView.itemSprite[ItemSpriteType.kBirdRoad] and not itemView.itemSprite[ItemSpriteType.kBirdRoad].isDisposed then
						itemView.itemSprite[ItemSpriteType.kBirdRoad]:removeFromParentAndCleanup(true)
						itemView.itemSprite[ItemSpriteType.kBirdRoad] = nil
					end
					theAction.addInfo = "clearBirdData"

					

					local slingItemView = boardView.baseMap[theAction.sling.y][theAction.sling.x]
					if slingItemView then
						slingItemView.itemSprite[ItemSpriteType.kItemShow]:setVisible(false)
						local pos = UsePropState:getItemPosition(IntCoord:create(theAction.sling.y,theAction.sling.x))
						theAction.tempSlingView = UIHelper:createUI("tempFunctionResInLevel/AngryBird/angryBird.json", "angryBird/sling")
						boardView:addChild(theAction.tempSlingView)
				    	theAction.tempSlingView:setPositionXY(pos.x-34,pos.y+33)
				    	theAction.tempSlingView:setScale(0.9)
				    	-- theAction.tempSlingView:setVisible(false)
						local shotAnim = require "zoo.localActivity.AngryBirdsRecall.AngryBirdAnimation"
						shotAnim:create(theAction.tempSlingView,theAction.tempBirdView,true,ccp(theAction.targetPos.x,theAction.targetPos.y+75),nil,theAction)
					end
				end
				    
			end

		end

		theAction.jsq = theAction.jsq + 1

		if theAction.addInfo == "rebuildBirdRoad" then
			local isSling,dirs = AngryBirdLogic:posHasSlingAndRoadDir(theAction.sling.y,theAction.sling.x)
			-- printx(15,"rebuildBirdRoad",table.tostring(dirs))
			local slingItemView = boardView.baseMap[theAction.sling.y][theAction.sling.x]
			if slingItemView then
				slingItemView.itemSprite[ItemSpriteType.kBirdRoad]:rebuild(dirs)
			end
			theAction.addInfo = nil
		end


		if theAction.addInfo == "clearSlingSprite" then
			--播弹弓的消除动画 暂时没有
			theAction.jsq = 1
			theAction.addInfo = "waitClearData"
			local itemView = boardView.baseMap[theAction.sling.y][theAction.sling.x]
			if itemView.itemSprite[ItemSpriteType.kBirdRoad] and not itemView.itemSprite[ItemSpriteType.kBirdRoad].isDisposed then
				itemView.itemSprite[ItemSpriteType.kBirdRoad]:removeFromParentAndCleanup(true)
				itemView.itemSprite[ItemSpriteType.kBirdRoad] = nil
			end
		end

		if theAction.addInfo == "waitClearData" and theAction.jsq == 16 then
			theAction.addInfo = "clearSling"
		end

	end
end

function DestroyItemLogic:runGameItemActionFlyBoardLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = "init"
	end

	if theAction.addInfo == "clearOldBoard" then

		local r = theAction.ItemPos1.x
		local c = theAction.ItemPos1.y
		BridgeCrossLogic:clearOldBoard(mainLogic,r,c)
		theAction.addInfo = "waitingForFlyOver"

	elseif theAction.addInfo == "updateData" then
		BridgeCrossLogic:createNewBoard(mainLogic,theAction.targetR,theAction.targetC)
		theAction.addInfo = "over"

	elseif theAction.addInfo == "over" then
		-- printx(15,"runGameItemActionFlyBoardLogic",theAction.completeCallback)
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionFlyBoardView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then

		if theAction.addInfo == "init" then
			
			theAction.jsq = 1
			theAction.addInfo = "clearOldBoard"

			local tempBoardSprite = TileBoard:create(temp)

			local itemView = boardView.baseMap[theAction.ItemPos1.x][theAction.ItemPos1.y]

			local tempLayer = itemView.itemSprite[ItemSpriteType.kTempFlyBoard]

			if tempLayer and not tempLayer.isDisposed then
				tempLayer:removeFromParentAndCleanup(true)
				tempLayer = nil
			end

			if itemView then

			    itemView.itemSprite[ItemSpriteType.kTempFlyBoard] = tempBoardSprite
			    local pos = UsePropState:getItemPosition(IntCoord:create(theAction.ItemPos1.x , theAction.ItemPos1.y))
			    tempBoardSprite:setPositionXY(pos.x,pos.y)
		
				local arr = CCArray:create()

				local pos = UsePropState:getItemPosition(IntCoord:create(theAction.targetR , theAction.targetC))
				arr:addObject(CCDelayTime:create(0.1))
				arr:addObject(CCMoveTo:create(0.3, pos))
				arr:addObject(CCDelayTime:create(0.1))
				arr:addObject(CCCallFunc:create(function ( ... )
					local tempLayer = itemView.itemSprite[ItemSpriteType.kTempFlyBoard]

					if tempLayer and not tempLayer.isDisposed then
						tempLayer:removeFromParentAndCleanup(true)
						tempLayer = nil
					end

				end))


				local move_action = CCSequence:create(arr) 
				UIHelper:setFixUpdate(tempBoardSprite, true)
				tempBoardSprite:runAction(move_action)

			end
		
		elseif theAction.addInfo == "waitingForFlyOver" then
	
			if theAction.jsq == 30 then
				theAction.addInfo = "updateData"
			end

			theAction.jsq = theAction.jsq + 1

		end
	end
end

---------------------- triggerFirework -------------------------
function DestroyItemLogic:runGameItemActionFireworkTriggerLogic(mainLogic, theAction, actid)
	-- printx(15,"runGameItemActionFireworkTriggerLogic")
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	local function getNextGrid( boardData, currR, currC )

		if boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] then

			local roadType = boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].roadType

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

	local function getPrevGrid( boardData, currR, currC )

		if boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)] then

			local roadType = boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].prevRoadType

			if roadType == RouteConst.kUp then
				return true, currR + 1, currC
			elseif roadType == RouteConst.kDown then
				return true, currR - 1, currC
			elseif roadType == RouteConst.kLeft then
				return true, currR, currC + 1
			elseif roadType == RouteConst.kRight then
				return true, currR, currC - 1
			end

		end

		return false
	end

	if theAction.addInfo == 'animationEnd' then
		local itemData = theAction.firework
		local boardData = mainLogic:safeGetBoardData(itemData.y, itemData.x)
		local pathId = boardData.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId
		if boardData then
			local hasNextGrid,nextR,nextC = getNextGrid(boardData, itemData.y, itemData.x)
			local hasPrevGrid,prevR,prevC = getPrevGrid(boardData, itemData.y, itemData.x)

			if hasNextGrid then
				-- printx(15,"hasNextGrid__nextR,nextC",nextR,nextC)
				local nextItem = mainLogic:safeGetItemData(nextR,nextC)
				if nextItem and nextItem.fireworkLevel and nextItem.fireworkLevel > 0 then
					local board = mainLogic:safeGetBoardData(nextR, nextC)
					if board and board.pathConfigs[tostring(TileConst.kFireworkPathFlag)] and board.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId == pathId then
						-- printx(15,"next!!!!!",nextR,nextC,pathId)
						nextItem.triggerBySameGroup = true
						-- table.insert(mainLogic.fireworksWaitingToTrigger,{nextR,nextC})
						-- nextItem.isNeedUpdate = true
					end
				end
			end

			if hasPrevGrid then
				-- printx(15,"hasPrevGrid__,prevR,prevC",prevR,prevC)
				local nextItem = mainLogic:safeGetItemData(prevR,prevC)
				if nextItem and nextItem.fireworkLevel and nextItem.fireworkLevel > 0 then
					local board = mainLogic:safeGetBoardData(prevR, prevC)
					if board and board.pathConfigs[tostring(TileConst.kFireworkPathFlag)] and board.pathConfigs[tostring(TileConst.kFireworkPathFlag)].pathId == pathId then
						nextItem.triggerBySameGroup = true
						-- printx(15,"prev!!!!!",prevR,prevR,pathId)
						-- table.insert(mainLogic.fireworksWaitingToTrigger,{nextR,nextC})
						-- nextItem.isNeedUpdate = true
					end
				end
			end 

		end

		SnailLogic:SpecialCoverSnailRoadAtPos( mainLogic, itemData.y, itemData.x )

		local bombPosList = {}
		local scoreScale = 1
		table.insert(bombPosList,{r=itemData.y,c=itemData.x+1})
		table.insert(bombPosList,{r=itemData.y,c=itemData.x-1})
		table.insert(bombPosList,{r=itemData.y+1,c=itemData.x})
		table.insert(bombPosList,{r=itemData.y-1,c=itemData.x})

		for _, v in ipairs(bombPosList) do
			local r, c = v.r, v.c
			if mainLogic:isPosValid(r, c) then
				local item = mainLogic.gameItemMap[r][c]

				SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, scoreScale)
				BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, scoreScale)
				SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, scoreScale) 
				local breakDirs = DestructionPlanLogic:calcBreakChainDirsAtPos(r, c, itemData.y, itemData.x, 1)
				SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c, breakDirs)
	            GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, 0, true, 3)
	            if boardData:hasJamSperad() then
	            	-- printx(15,"原点",itemData.y, itemData.x)
	            	GameExtandPlayLogic:addJamSperadFlag(mainLogic, r, c, true )
	            end
			end
		end

		--自己格的冰柱也要炸 参考萌豆
		SpecialCoverLogic:specialCoverChainsAroundPos(mainLogic, itemData.y, itemData.x, {ChainDirConfig.kUp, ChainDirConfig.kDown, ChainDirConfig.kRight, ChainDirConfig.kLeft})
 
		theAction.addInfo = nil


	elseif theAction.addInfo == 'over' then
		theAction.firework.isNeedUpdate = true
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionFireworkTriggerView(boardView, theAction)
	-- printx(15,"runGameItemActionFireworkTriggerView")
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local firework = theAction.firework

			local itemView = boardView.baseMap[firework.y][firework.x]

			-- printx(15,"itemView",itemView)
			if itemView then
				local sprite = itemView:getGameItemSprite()
				-- printx(15,"sprite",sprite)
			
				if sprite then
					sprite:playBoomAnimation(theAction.levelBeforeTrigger)
				end

			end


		end

		if theAction.jsq == 12 then
			theAction.addInfo = "animationEnd"
		elseif theAction.jsq == 25 then

			local firework = theAction.firework

			local itemView = boardView.baseMap[firework.y][firework.x]

			itemView:playFireworkBoomEffect()

		elseif theAction.jsq == 50 then
			theAction.addInfo = "over"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionFireworkDecLevelLogic( mainLogic, theAction, actid )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	elseif theAction.addInfo == 'over' then
		theAction.firework.isNeedUpdate = true
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionFireworkDecLevelView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local firework = theAction.firework

			local itemView = boardView.baseMap[firework.y][firework.x]

			if itemView then
				local sprite = itemView:getGameItemSprite()
			
				if sprite then
					sprite:playDecAnimation(firework)
					-- sprite:playGrowMusicEffect()
				end

			end

		end

		if theAction.jsq == 23 then
			theAction.addInfo = "over"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

---------------------- battery -------------------------

function DestroyItemLogic:runGameItemActionBatteryDecLevelLogic( mainLogic, theAction, actid )
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	elseif theAction.addInfo == 'over' then
		theAction.battery.isNeedUpdate = true

		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionBatteryDecLevelView( boardView, theAction )
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local battery = theAction.battery

			local itemView = boardView.baseMap[battery.y][battery.x]

			if itemView then
				local sprite = itemView:getGameItemSprite()
			
				if sprite then
					sprite:playDecAnimation(battery)
					-- sprite:playGrowMusicEffect()
				end

			end

		elseif theAction.jsq == 44 then
			theAction.addInfo = "over"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionBatteryChargeLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	local function conditionFilter( item )
			if not item then
				return
			end

			if item.isReverseSide 
				or item:hasActiveSuperCuteBall()
				or item.blockerCoverLevel > 0
				or item.colorFilterBLock
				or item:hasBlocker206()
				or WaterBucketLogic:hasBucket(item)
				or item:seizedByGhost()
				or item:hasSquidLock()
				or item.olympicLockLevel > 0
				then
				return false
			end
			return true 
		end

	if theAction.addInfo == 'beginCharge' then

		theAction.totemsList = {}
		theAction.lockList = {}

		

		for r = 1, #mainLogic.gameItemMap do
			for c = 1, #mainLogic.gameItemMap[r] do
				local item = mainLogic.gameItemMap[r][c]
	            if item.ItemType == GameItemType.kTotems then

	            	-- GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, r, c, nil, false)

	            	-- mainLogic:addNewSuperTotemPos(IntCoord:create(r, c))
	            	--printx(15,"激活闪电鸟")

	            	--先分类
	            	--特殊处理的：含羞草，2级荷塘，蜂蜜，牢笼
	            	if not item:isAvailable() or item:hasLock() then
	            		if item.cageLevel ~= 0 or 
	            		   item.lotusLevel == 2 or
	            		   item.honeyLevel ~= 0 or
	            		   item.beEffectByMimosa == GameItemType.kKindMimosa then

	            		   	if conditionFilter(item) then

	            				table.insert(theAction.lockList,item)

	            			end
	            		end

	            	else
	            		if item.totemsState == GameItemTotemsState.kNone then
	            			table.insert(theAction.totemsList,item)
	            		end

	            	end

	            end
			end
		end

		if #theAction.totemsList + #theAction.lockList == 0 then
			--空炸了
			theAction.addInfo = "emptyBoom"
			theAction.totalLength = 50
		else
			theAction.addInfo = "realBoom"
			-- theAction.totalLength = 12+11+17 + 5
			theAction.totalLength = 84
			for _, item in pairs(theAction.lockList) do

				-- BombItemLogic:tryCoverByBomb( mainLogic, item.y, item.x )

				SpecialCoverLogic:SpecialCoverAtPos(mainLogic, item.y, item.x) 
			end

			for _, item in pairs(theAction.totemsList) do
				-- printx(15,"item.y, item.x",item.y, item.x)
				GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, item.y, item.x, nil, false)
			end

		end

		-- theAction.addInfo = nil
	-- elseif theAction.addInfo == 'active' then

	-- 	-- for _, item in pairs(theAction.lockList) do

	-- 	-- 	-- BombItemLogic:tryCoverByBomb( mainLogic, item.y, item.x )

	-- 	-- 	SpecialCoverLogic:SpecialCoverAtPos(mainLogic, item.y, item.x) 
	-- 	-- end

	-- 	-- for _, item in pairs(theAction.totemsList) do
	-- 	-- 	printx(15,"item.y, item.x",item.y, item.x)
	-- 	-- 	GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, item.y, item.x, nil, false)
	-- 	-- end

	-- 	theAction.addInfo = nil

	elseif theAction.addInfo == 'animationEnd' then

		local item = theAction.battery

        item:cleanAnimalLikeData()
        item.isNeedUpdate = true
		mainLogic:checkItemBlock(item.y, item.x)
		mainLogic:setNeedCheckFalling()
		--local item1 = mainLogic.gameItemMap[3][5]
		--printx(15,"item1.isBlock",item1.isBlock)
		--printx(15,"item1.ItemStatus",item1.ItemStatus)
		--printx(15,"item1.itemType",item1.ItemType)

		--local item2 = mainLogic.gameItemMap[2][5]
		--printx(15,"item2.isBlock",item2.isBlock)
		--printx(15,"item2.ItemStatus",item2.ItemStatus)
		--printx(15,"item2.itemType",item2.ItemType)


		mainLogic:tryBombSuperTotemsByForce()
		-- printx(15,"==============尝试触发闪电鸟==================")
		theAction.addInfo = 'over'

	elseif theAction.addInfo == 'over' then

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionBatteryChargeView( boardView, theAction )

	local maxAnimationLength = 100

	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local battery = theAction.battery
			local itemView = boardView.baseMap[battery.y][battery.x]
			if itemView then
				local sprite = itemView:getGameItemSprite()
				if sprite then
					sprite:playBoomAnimation()
				end

			end

		elseif theAction.jsq == 33 then
			theAction.addInfo = "beginCharge"
		-- elseif theAction.jsq == 25 then
		-- 	if theAction.waitingActive then
		-- 		theAction.addInfo = "active"
		-- 		theAction.waitingActive = false
		-- 	else
		-- 		theAction.addInfo = nil
		-- 	end
		elseif theAction.jsq == maxAnimationLength or ( theAction.totalLength and theAction.jsq == theAction.totalLength ) then
			-- printx(15,"end one action—————— theAction.jsq",theAction.jsq)
			local battery = theAction.battery
			local itemView = boardView.baseMap[battery.y][battery.x]
			if itemView.itemSprite[ItemSpriteType.kBatteryShow] and not itemView.itemSprite[ItemSpriteType.kBatteryShow].isDisposed then
				itemView.itemSprite[ItemSpriteType.kBatteryShow]:removeFromParentAndCleanup(true)
				itemView.itemSprite[ItemSpriteType.kBatteryShow] = nil
			end

			theAction.addInfo = "animationEnd"
		end

		if theAction.addInfo == "emptyBoom" then
			-- printx(15,"emptyBoom!!!!!",theAction.jsq)
			local battery = theAction.battery
			local itemView = boardView.baseMap[battery.y][battery.x]
			if itemView then
				local sprite = itemView:getGameItemSprite()
				if sprite then
					sprite:playDisappearAnimation()
				end

			end
			theAction.addInfo = nil
		elseif theAction.addInfo == "realBoom" then

			local battery = theAction.battery
			local itemView = boardView.baseMap[battery.y][battery.x]
			if itemView then
				local sprite = itemView:getGameItemSprite()
				if sprite then
					sprite:playRealBoomAnimation()
				end

				for _, item in pairs(theAction.lockList) do

					itemView:playBatteryLightningEffect(item)
				end

				for _, item in pairs(theAction.totemsList) do

					itemView:playBatteryLightningEffect(item)
				end


				
			end
			-- theAction.addInfo = "active"
			-- theAction.waitingActive = true
			theAction.addInfo = nil

		end

		theAction.jsq = theAction.jsq + 1
	end
end

---------------------- walkChick -------------------------
function DestroyItemLogic:runGameItemActionChickWalkLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		local walkChick = theAction.walkChick
		local exchangeItem = theAction.nextItem

		local walkChickRowShift = exchangeItem.y - walkChick.y
		local walkChickColShift = exchangeItem.x - walkChick.x

		walkChick.tempRowShiftByWalkChick = walkChickRowShift
		walkChick.tempColShiftByWalkChick = walkChickColShift
		exchangeItem.tempRowShiftByWalkChick = -walkChickRowShift
		exchangeItem.tempColShiftByWalkChick = -walkChickColShift

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then
		
		BridgeCrossLogic:refreshGameItemDataAfterChickWalk(mainLogic)

		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then

		if theAction.refreshViewDelay == 1 then
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionChickWalkView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then

			local function playExchangeAnimation(targetItem, shiftR, shiftC)
				local itemView = boardView.baseMap[targetItem.y][targetItem.x]
				if itemView then
					local sprite = itemView:getGameItemSprite()
					if sprite then
						local position = UsePropState:getItemPosition(
							IntCoord:create(targetItem.y + shiftR, targetItem.x + shiftC)
							)

						local arr = CCArray:create()
						arr:addObject(CCDelayTime:create(0.05))
						arr:addObject(CCMoveTo:create(0.2, position))
						arr:addObject(CCDelayTime:create(0.1))
						arr:addObject(CCCallFunc:create(function ( ... )
							local boardSprite = itemView.itemSprite[ItemSpriteType.kBoard]
							if boardSprite and not boardSprite.isDisposed then
								if targetItem.ItemType ~= GameItemType.kWalkChick then
									boardSprite:playChickPassAnimation()
								end
							end
						end))

						local move_action = CCSequence:create(arr) 

						sprite:runAction(move_action)

						if targetItem.ItemType == GameItemType.kWalkChick then
							itemView:playWalkChickWalk()
						end
					end
				end
			end

			local walkChick = theAction.walkChick
			local exchangeItem = theAction.nextItem
			playExchangeAnimation(walkChick, walkChick.tempRowShiftByWalkChick, walkChick.tempColShiftByWalkChick)
			playExchangeAnimation(exchangeItem, exchangeItem.tempRowShiftByWalkChick, exchangeItem.tempColShiftByWalkChick)

		end

		local exchangeAnimationDelay = 25
		if theAction.jsq == exchangeAnimationDelay then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

---------------------- Hero -------------------------
function DestroyItemLogic:runGameItemActionHeroWalkLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		local hero = theAction.hero
		local exchangeItem = theAction.nextItem

		local heroRowShift = exchangeItem.y - hero.y
		local heroColShift = exchangeItem.x - hero.x

		hero.tempRowShiftByHero = heroRowShift
		hero.tempColShiftByHero = heroColShift
		exchangeItem.tempRowShiftByHero = -heroRowShift
		exchangeItem.tempColShiftByHero = -heroColShift

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then
		TravelLogic:refreshGameItemDataAfterHeroWalk(mainLogic)

		-- theAction.addInfo = "over"
		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then
		-- 唉……由于视图不会立即更新，所以被挤下来的对象如果马上下落的话视图会错误。所以等一下。
		if theAction.refreshViewDelay == 1 then
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionHeroWalkView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			-- local inAnimationCount = 0
			-- local function completeCallback( ... )
			-- 	RemoteDebug:uploadLogWithTag("w-v-333", inAnimationCount)
			-- 	inAnimationCount = inAnimationCount - 1
			-- 	if inAnimationCount <= 0 then
			-- 		theAction.addInfo = "animationEnd"
			-- 	end
			-- end

			local function playExchangeAnimation(targetItem, shiftR, shiftC)
				local itemView = boardView.baseMap[targetItem.y][targetItem.x]
				if itemView then
					local sprite = itemView:getGameItemSprite()
					if sprite then
						local position = UsePropState:getItemPosition(
							IntCoord:create(targetItem.y + shiftR, targetItem.x + shiftC)
							)

						local arr = CCArray:create()
						arr:addObject(CCDelayTime:create(0.05))
						arr:addObject(CCMoveTo:create(0.2, position))
						arr:addObject(CCDelayTime:create(0.1))
						-- arr:addObject(CCCallFunc:create(completeCallback))
						local move_action = CCSequence:create(arr) 

						sprite:runAction(move_action)
						-- inAnimationCount = inAnimationCount + 1

						if targetItem.ItemType == GameItemType.kTravelHero then
							local walkingDirection = TravelLogic:getDirectionByShiftValue(shiftR, shiftC)
							if walkingDirection > 0 then
								targetItem.walkingDirection = walkingDirection
								itemView:playTravelHeroWalk(walkingDirection)
							end
						end
					end
				end
			end

			local hero = theAction.hero
			local exchangeItem = theAction.nextItem
			playExchangeAnimation(hero, hero.tempRowShiftByHero, hero.tempColShiftByHero)
			playExchangeAnimation(exchangeItem, exchangeItem.tempRowShiftByHero, exchangeItem.tempColShiftByHero)
		end

		--- 击中目标
		local exchangeAnimationDelay = 25
		if theAction.jsq == exchangeAnimationDelay then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionHeroAttackLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "effectTarget" then
		if theAction.isAttackChain then
			mainLogic:decChainBetween(theAction.hero.y, theAction.hero.x, theAction.nextItem.y, theAction.nextItem.x)
		else
			theAction.nextItem:addFallingLockByTravelHero()
			theAction.nextItem.updateLaterByTravelHero = true

			local targetPoint = IntCoord:create(theAction.nextItem.x, theAction.nextItem.y)
			local rectangleAction = GameBoardActionDataSet:createAs(
										GameActionTargetType.kGameItemAction,
										GameItemActionType.kItemSpecial_rectangle,
										targetPoint,
										targetPoint,
										GamePlayConfig_MaxAction_time)
			rectangleAction.addInt2 = 1
			-- rectangleAction.eliminateChainIncludeHem = true
			mainLogic:addDestructionPlanAction(rectangleAction)
			-- mainLogic:setNeedCheckFalling()
		end
		
		theAction.addInfo = ""
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionHeroAttackView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		-- 开始攻击动画
		local hitGestureDelay = 1
		if theAction.jsq == hitGestureDelay then
			local hero = theAction.hero
			if hero then
				local heroView = boardView.baseMap[hero.y][hero.x]
				if heroView then
					heroView:playTravelHeroAttack()
				end
			end
		end

		--- 击中目标
		local effectTargetDelay = 14
		if theAction.jsq == effectTargetDelay then
			theAction.addInfo = "effectTarget"
		end

		-- 整体结束，可以开始下一次的判定
		local hitDurationDelay = 30
		if theAction.jsq == hitDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

--------------------- Route Events --------------------
function DestroyItemLogic:runGameItemActionTravelEventOpenBoxLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

		theAction.updateDataDelay = 1
		if theAction.eventActionType == GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag then
			theAction.updateDataDelay = 20
		end

		theAction.jsq = 0
	end

	if theAction.addInfo == "onTriggerSkill" then
		if theAction.eventActionType and theAction.eventActionType > 0 then
			local routeSkillAction = GameBoardActionDataSet:createAs(
	            GameActionTargetType.kGameItemAction,
	            theAction.eventActionType,
	            IntCoord:create(theAction.hero.x, theAction.hero.y),
	            nil,
	            GamePlayConfig_MaxAction_time)
	        routeSkillAction.targetGrids = theAction.targetGrids
	        routeSkillAction.middileGrid = theAction.middileGrid
	        routeSkillAction.hero = theAction.hero

	        mainLogic:addDestroyAction(routeSkillAction)
	    end
	    theAction.addInfo = ""
	end

	if theAction.addInfo == "updateData" then
		if theAction.eventBoxPos and theAction.eventBoxPos.y and theAction.eventBoxPos.x then
			local itemData = mainLogic:safeGetItemData(theAction.eventBoxPos.y, theAction.eventBoxPos.x)
			if itemData and itemData:hasFallingLockByTravelHero() then
				itemData:removeFallingLockByTravelHero()
				mainLogic:checkItemBlock(itemData.y, itemData.x)
	        end
		end
		theAction.addInfo = ""
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionTravelEventOpenBoxLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelEventOpenBoxView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		-- 展示礼盒内容
		local flyOutDelay = 1
		if theAction.jsq == flyOutDelay then
			TravelLogic:playEventBoxOpenAnimations(boardView, theAction)
		end

		-- 触发技能
		local triggerSkillDelay = 100
		if theAction.jsq == triggerSkillDelay then
			theAction.addInfo = "onTriggerSkill"
		end

		-- 礼盒飞出相关结束
		local updateDataDelay = triggerSkillDelay + theAction.updateDataDelay
		if theAction.jsq == updateDataDelay then
			theAction.addInfo = "updateData"
		end

		-- 全部结束
		local allOverDelay = updateDataDelay + 1
		if theAction.jsq == allOverDelay then
			theAction.addInfo = "over"
		end
	end
end

--------------------------------
function DestroyItemLogic:runGameItemActionTravelEventEnergyBagLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "effectTarget" then
		if theAction.targetGrids then
			for _, targetGrid in pairs(theAction.targetGrids) do
				local targetItem = mainLogic:safeGetItemData(targetGrid.y, targetGrid.x)
				if targetItem then
					TravelLogic:transformAnimalToEnergyBag(targetItem)
				end
			end
		end
		theAction.addInfo = ""
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelEventEnergyBagView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local effectTargetDelay = 15
		if theAction.jsq == effectTargetDelay then
			theAction.addInfo = "effectTarget"
		end

		local wholeDurationDelay = effectTargetDelay + 1
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

-------------------------------
function DestroyItemLogic:runGameItemActionTravelEventBombRouteLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "startBombItem" then
		theAction.gridAmount = #theAction.targetGrids
		theAction.startBomb = true
		theAction.bombedGridAmount = 0
		theAction.bombFrameGap = 1

		theAction.addInfo = ""
	end

	if theAction.addInfo == "bombingFinished" then
		theAction.addInfo = "over"
	end

	if theAction.startBomb then
		theAction.addInfo = "bombing"
		theAction.bombFrameGap = theAction.bombFrameGap - 1
		if theAction.bombFrameGap <= 0 then
			local targetPoint = theAction.targetGrids[theAction.bombedGridAmount + 1]
			if targetPoint then
				theAction.bombingGrid = targetPoint --传递给view

				local rectangleAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItemSpecial_rectangle,
					targetPoint,
					targetPoint,
					GamePlayConfig_MaxAction_time)
				rectangleAction.addInt2 = 1
				rectangleAction.eliminateChainIncludeHem = true
				mainLogic:addDestructionPlanAction(rectangleAction)
				-- mainLogic:setNeedCheckFalling()
			end
			
			theAction.bombedGridAmount = theAction.bombedGridAmount + 1
			theAction.bombFrameGap = 2		--每几帧炸一个格子
		end

		if theAction.bombedGridAmount >= theAction.gridAmount then
			theAction.startBomb = false
			theAction.addInfo = "bombingFinished"
		end
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionTravelEventBombRouteLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelEventBombRouteView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startBombDelay = 1
		if theAction.jsq == startBombDelay then
			theAction.addInfo = "startBombItem"
		end

		if theAction.addInfo == "bombing" and theAction.bombingGrid then
			
			if boardView.baseMap[theAction.bombingGrid.y] then
				local gridView = boardView.baseMap[theAction.bombingGrid.y][theAction.bombingGrid.x]
				if gridView then
					gridView:playTravelRouteBombAnim()
				end
			end
			theAction.bombingGrid = nil
		end
	end
end

-------------------------------
function DestroyItemLogic:runGameItemActionTravelEventBombHeartLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "startBombItem" then
		theAction.addInfo = "bombing"
		for _, targetPoint in pairs(theAction.targetGrids) do
			local rectangleAction = GameBoardActionDataSet:createAs(
				GameActionTargetType.kGameItemAction,
				GameItemActionType.kItemSpecial_rectangle,
				targetPoint,
				targetPoint,
				GamePlayConfig_MaxAction_time)
			rectangleAction.addInt2 = 1
			rectangleAction.eliminateChainIncludeHem = true
			mainLogic:addDestructionPlanAction(rectangleAction)
		end
		
		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionTravelEventBombRouteLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelEventBombHeartView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startAnimationDelay = 1
		if theAction.jsq == startAnimationDelay then
			TravelLogic:playHeartBombHugeAnimation(theAction.middileGrid)
		end

		local startBombDelay = 30
		if theAction.jsq == startBombDelay then
			theAction.addInfo = "startBombItem"
		end
	end
end

----------------------- Add Step Skill --------------------
function DestroyItemLogic:runGameItemActionTravelAddStepSkillLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "onTriggerSkill" then
		local throwGrids = TravelLogic:getAddEnergyBagTargetGrids(mainLogic, 10)
        if theAction.targetGrids then
            local routeSkillAction = GameBoardActionDataSet:createAs(
	            GameActionTargetType.kGameItemAction,
	            GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag,
	            nil,
	            nil,
	            GamePlayConfig_MaxAction_time)
	        routeSkillAction.targetGrids = theAction.targetGrids

	        mainLogic:addDestroyAction(routeSkillAction)
        end
		theAction.addInfo = ""
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionTravelAddStepSkillLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionTravelAddStepSkillView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		-- 展示内容
		local flyOutDelay = 2
		if theAction.jsq == flyOutDelay then
			TravelLogic:playTravelAddStepSkillAnimations(boardView, theAction.targetGrids)
		end

		-- 触发技能
		local triggerSkillDelay = 75
		if theAction.jsq == triggerSkillDelay then
			theAction.addInfo = "onTriggerSkill"
		end

		-- 飞出相关全部结束
		local allOverDelay = triggerSkillDelay + 1
		if theAction.jsq == allOverDelay then
			theAction.addInfo = "over"
		end
	end
end
-------------------------------------- TRAVEL MODE --END-- ----------------------------------------

function DestroyItemLogic:runningGameItemActionOpenFlower(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.addInfo = 'start_open_flower_anim'

		local root_item = mainLogic.gameItemMap[theAction.ItemPos1.y][theAction.ItemPos1.x]
		root_item.can_attack_canevine = true


	end

	if theAction.addInfo == 'wait_flower_anim' then
		theAction.jsq = theAction.jsq + 1


		if (theAction.addInt == 0 and theAction.jsq > 40) or (theAction.addInt == 1 and theAction.jsq > 80)  then
			theAction.addInfo = 'over'
		end
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionOpenFlowerView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.addInfo == 'start_open_flower_anim' then
			local itemView = boardView.baseMap[theAction.ItemPos1.y][theAction.ItemPos1.x]     
			local level = theAction.addInt
			itemView:play_canvine_open_flower_anim(level, theAction.addInt2)
			theAction.addInfo = 'wait_flower_anim'
			theAction.jsq = 0

			if level == 0 then

				local blink_pos_delta = lua_switch(theAction.addInt3) {
					[DefaultDirConfig.kLeft] = {dr = 0, dc = - (theAction.addInt2 - 1) },
					[DefaultDirConfig.kRight] = {dr = 0, dc = (theAction.addInt2 - 1) },
					[DefaultDirConfig.kUp] = {dr = - (theAction.addInt2 - 1), dc = 0},
					[DefaultDirConfig.kDown] = {dr = (theAction.addInt2 - 1), dc = 0},
				}

				local itemView2 = boardView.baseMap[theAction.ItemPos1.y + blink_pos_delta.dr][theAction.ItemPos1.x + blink_pos_delta.dc]     
				itemView2:playMixTileHighlightEffect()
			end

		end
	end
end

------------------------------------------------------------------------------------
--       							Plane
------------------------------------------------------------------------------------
function DestroyItemLogic:runGameItemActionPlaneFlyToGridLogic(mainLogic, theAction, actid)
	-- printx(11, "runGameItemActionPlaneFlyToGridLogic   START")
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "bomb" then
		local bombChain = false
		local col, row = theAction.nextC, theAction.nextR

		if theAction.targetPlane then
			-- 斜向炸格子四周冰柱
			local planeDir = theAction.targetPlane.planeDirection
			if planeDir then
				if planeDir > 0 and planeDir < 5 then
					local eliminateChainDir = PlaneLogic:getDecChainDirByPlaneDir(planeDir)
					SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, row, col, eliminateChainDir)
				elseif planeDir >= 5 then
					bombChain = true
				end
			end

			local formerR, formerC = PlaneLogic:getFormerGridPosByPlaneDir(planeDir, row, col)
			local formerBoardData = mainLogic:safeGetBoardData(formerR, formerC)
			if formerBoardData:hasJamSperad() then
				GameExtandPlayLogic:addJamSperadFlag(mainLogic, row, col)
			end
		end

		local rectangleAction = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItemSpecial_rectangle,
			IntCoord:create(col, row),
			IntCoord:create(col, row),
			GamePlayConfig_MaxAction_time)
		rectangleAction.addInt2 = 1
		rectangleAction.eliminateChainIncludeHem = bombChain
		mainLogic:addDestructionPlanAction(rectangleAction)
		theAction.addInfo = ""
	end

	if theAction.addInfo == 'over' then
		-- printx(11, "runGameItemActionPlaneFlyToGridLogic   OVER")
		if theAction.targetPlane and theAction.hasReachedEnd then
			PlaneLogic:onPlaneDestroyed(mainLogic, theAction.targetPlane)
		end

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end

	theAction.addInfo = ""
end

function DestroyItemLogic:runGameItemActionPlaneFlyToGridView(boardView, theAction)
	local function getPlaneView(plane)
		if plane then
			local planeView = boardView:safeGetItemView(plane.y, plane.x)
			return planeView
		end
		return nil
	end

	if theAction.actionStatus == GameActionStatus.kRunning then
		-- printx(11, "runGameItemActionPlaneFlyToGridView", theAction.jsq)
		if theAction.jsq == 0 then
			local plane = theAction.targetPlane
			local planeView = getPlaneView(plane)
			if planeView then
				planeView:planeFlyToGrid(plane.planeDirection, theAction.nextR, theAction.nextC, theAction.hasReachedEnd)
			end

			local gridView = boardView:safeGetItemView(theAction.nextR, theAction.nextC)
			if gridView then
				gridView:playPlaneFlyGridEffectAnim(plane.planeDirection, theAction.nextR, theAction.nextC)
			end
		end

		theAction.jsq = theAction.jsq + 1

		local bombDelay = 2
		if theAction.jsq == bombDelay then
			theAction.addInfo = "bomb"
		end

		local flyDelay = 5
		if theAction.jsq == flyDelay then
			if theAction.hasReachedEnd then
				local targetView = boardView:safeGetItemView(theAction.nextR, theAction.nextC)
				if targetView then
					targetView:playPlaneVanish(theAction.targetPlane.planeDirection, theAction.nextR, theAction.nextC)
				end
			end

			theAction.addInfo = "over"
		end

	end
end

-------------------------------------	WeeklyRace2020 Chest	-------------------------------------------------
function DestroyItemLogic:runGameItemActionWeeklyRace2020ChestHitLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "updateData" then
		theAction.addInfo = ""

		local chestItem = theAction.targetItem
		WeeklyRace2020Logic:setWeeklyRace2020ChestDecreaseLock(chestItem, false)

		local chestData = chestItem.weeklyRace2020ChestData
		if chestData then
			chestData.weeklyRace2020ChestLayerHP = math.max(0, chestData.weeklyRace2020ChestLayerHP - 1)
			if theAction.isFinalHitOfLayer then
				WeeklyRace2020Logic:onWeeklyRace2020ChestDecreaseLayer(chestItem)
			end
		end
	end

	if theAction.addInfo == "jewelChestBomb" then
		theAction.addInfo = ""

		if theAction.isFinalHitOfAll and theAction.isJewelChest then
			WeeklyRace2020Logic:playHugeHeartSmash(mainLogic)
		end
	end

	if theAction.addInfo == "finalUpdateData" then
		theAction.addInfo = ""

		local chestItem = theAction.targetItem
		if WeeklyRace2020Logic:getWeeklyRace2020ChestLayerHP(chestItem) <= 0 then
			if WeeklyRace2020Logic:getWeeklyRace2020ChestLayer(chestItem) == 1 then
				WeeklyRace2020Logic:onWeeklyRace2020ChestDestroyed(mainLogic, chestItem)
			end
		end
	end

	if theAction.addInfo == "over" then
		theAction.addInfo = ""

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionWeeklyRace2020ChestHitView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startHitAnimationDelay = 1
		if theAction.jsq == startHitAnimationDelay then
			local r, c = theAction.targetItem.y, theAction.targetItem.x
			local chestView = boardView:safeGetItemView(r, c)
			if chestView then
				chestView:playWeeklyRace2020ChestHit(WeeklyRace2020Logic:getWeeklyRace2020ChestLayerHP(theAction.targetItem), 
					WeeklyRace2020Logic:getWeeklyRace2020ChestLayer(theAction.targetItem))
				if theAction.isFinalHitOfAll and theAction.isJewelChest then
					local fromPos = chestView:getBasePosition(theAction.targetItem.x, theAction.targetItem.y)
					local heartMiddleR = 7
					local heartMiddleC = 5
					local toPos = boardView.baseMap[heartMiddleR][heartMiddleC]:getBasePosition(heartMiddleC, heartMiddleR)
					chestView:playWeeklyRace2020ChestHitAnimation(fromPos, toPos)
				end
			end
			if theAction.isFinalHitOfAll then
				WeeklyRace2020Logic:checkPlayWeeklyRace2020ChestOpenAnimation(theAction.targetItem)
			end
		end

		-- 普通特效：2  陀螺：4  飞机：6
		local hitLockDuration = 6
		if theAction.jsq == hitLockDuration then
			theAction.addInfo = "updateData"
		end

		-- 宝石宝箱开启后的心形爆炸
		local jewelChestBombDelay = 30
		if theAction.jsq == jewelChestBombDelay then
			theAction.addInfo = "jewelChestBomb"
		end

		--- 处理宝箱消失
		if theAction.jsq == theAction.updateChestDurationDelay then
			theAction.addInfo = "finalUpdateData"
		end

		--- 整体结束
		local wholeDurationDelay = theAction.updateChestDurationDelay + 1
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

function DestroyItemLogic:runGameItemActionWeeklyRace2020HeartSmashLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "startBombItem" then
		theAction.addInfo = ""
		for _, targetPoint in pairs(theAction.targetGrids) do
			local rectangleAction = GameBoardActionDataSet:createAs(
				GameActionTargetType.kGameItemAction,
				GameItemActionType.kItemSpecial_rectangle,
				targetPoint,
				targetPoint,
				GamePlayConfig_MaxAction_time)
			rectangleAction.addInt2 = 1
			rectangleAction.eliminateChainIncludeHem = true

			mainLogic:addDestructionPlanAction(rectangleAction)
			mainLogic:setNeedCheckFalling()
		end
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionWeeklyRace2020HeartSmashView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startAnimationDelay = 1
		if theAction.jsq == startAnimationDelay then
			WeeklyRace2020Logic:playHeartSmashHugeAnimation(theAction.middileGrid)
		end

		local startGridEffectDelay = 15
		if theAction.jsq == startGridEffectDelay then
			for _, targetPoint in pairs(theAction.targetGrids) do
				local boardLogic = boardView.gameBoardLogic
				local targetItem = boardLogic:safeGetItemData(targetPoint.y, targetPoint.x)
				if targetItem and targetItem.isUsed then
					local view = boardView:safeGetItemView(targetPoint.y, targetPoint.x)
					if view then
						view:playBonusTimeEffcet()
					end
				end
			end
		end

		local startBombDelay = 30
		if theAction.jsq == startBombDelay then
			theAction.addInfo = "startBombItem"
		end

		local allEndDelay = 40
		if theAction.jsq == allEndDelay then
			theAction.addInfo = "over"
		end

	end
end


------------------------------------------------------------------------------------
--       							Cattery
------------------------------------------------------------------------------------

function DestroyItemLogic:runGameItemActionCatteryRollingLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		if theAction.rollsNumber == 0 then
			CatteryLogic:specialDealForZeroRollnum(mainLogic,theAction.size,theAction.targetCattery,theAction.direction)
		end
	end

	if theAction.addInfo == "bomb" then
		CatteryLogic:destroyRolledGrid(mainLogic,theAction.posList[1].r, theAction.posList[1].c,theAction.posList[#theAction.posList].r, theAction.posList[#theAction.posList].c, theAction.direction)
		theAction.addInfo = ""
	end

	if theAction.addInfo == "roll"  then
		CatteryLogic:onCatteryMovedTo(mainLogic, theAction.nextR, theAction.nextC,theAction.targetCattery, theAction.posList, theAction.direction, theAction.size)
		for k,v in ipairs(theAction.posList) do
			local offset = {
				{1,0},
				{0,-1},
				{-1,0},
				{0,1},
			}
			local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
			local r = v.r + offset[theAction.direction][1]*(theAction.size)
			local c = v.c + offset[theAction.direction][2]*(theAction.size)
			if r >=1 and r <=rowAmount and c >= 1 and c <= colAmount and theAction.rollsNumber < theAction.size then
				CatteryLogic:onCatteryDestroyed(mainLogic,r,c)
			end
		end
		theAction.addInfo = 'over'
	end

	if theAction.addInfo == 'over' then
		theAction.addInfo = ""
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
			
	
end

function DestroyItemLogic:runGameItemActionCatteryRollingView(boardView, theAction)

	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local cattery = theAction.targetCattery
			local catteryView = boardView:safeGetItemView(cattery.y, cattery.x)

			if catteryView then
				catteryView:playCatteryRolling({r = theAction.nextR, c = theAction.nextC, size = theAction.size, direction = theAction.direction})
			end
		end

		theAction.jsq = theAction.jsq + 1
		local bombDelay = 1
		if theAction.jsq == bombDelay then
			theAction.addInfo = "bomb"
		end

		local rollDelay = 8
		if theAction.jsq == rollDelay then
			theAction.addInfo = "roll"
		end


	end
end


function DestroyItemLogic:runGameItemActionCatterySplitLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		if theAction.rollsNumber == 0 then
			CatteryLogic:specialDealForZeroRollnum(mainLogic,theAction.size,theAction.targetCattery,theAction.direction)
		end
	end

	if theAction.addInfo == 'split' then
		if theAction.targetCattery then
			if #theAction.posList > 0 then --消除撞到的障碍
				for k,v in ipairs(theAction.posList) do
					local finalRectAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItemSpecial_rectangle,
					IntCoord:create(v.c, v.r),
					IntCoord:create(v.c, v.r),
					GamePlayConfig_MaxAction_time)
					finalRectAction.addInt2 = 1
					finalRectAction.eliminateChainIncludeHem = true
					mainLogic:addDestructionPlanAction(finalRectAction)
				end	
			end
			if #theAction.chainList > 0 then --消除冰柱
				for k,v in ipairs(theAction.chainList) do
					CatteryLogic:canBeStoppedByChainAndClean(mainLogic, v.r, v.c, theAction.targetCattery, v.i, true)
				end	
			end
		end
		theAction.addInfo = 'splitOver'
	end

	local repreatRefreshDelay = 20
	if theAction.jsq == repreatRefreshDelay then
		CatteryLogic:onMeowDataRefresh(mainLogic,theAction.size,theAction.nextR, theAction.nextC)
	end


	if theAction.addInfo == 'over' then
		theAction.addInfo = ""
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
			
	
end

function DestroyItemLogic:runGameItemActionCatterySplitView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local cattery = theAction.targetCattery
			local catteryView = boardView:safeGetItemView(cattery.y, cattery.x)
			if catteryView then
				catteryView:playCatterySplit(theAction.size, theAction.direction)
			end
			theAction.addInfo = "split"
		end

		theAction.jsq = theAction.jsq + 1
		local splitDelay = 30
		if theAction.jsq == splitDelay then
			theAction.addInfo = "over"
		end
	end
end

------------------------------ 喵喵收集 -------------------------------

function DestroyItemLogic:runGameItemActionMeowCollectLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "waitAnim" then
		theAction.jsq = theAction.jsq + 1
	end
	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		local r = theAction.ItemPos1.y
		local c = theAction.ItemPos1.x

		GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r, c, Blocker195CollectType.kMeow)
		SquidLogic:checkSquidCollectItem(mainLogic, r, c, TileConst.kMeow)
		SnailLogic:SpecialCoverSnailRoadAtPos( mainLogic, r, c )
		mainLogic:tryDoOrderList(r, c, GameItemOrderType.kOthers, GameItemOrderType_Others.kMeow, 1)
		mainLogic:addScoreToTotal(r, c, 300)

		if theAction.targetMeow then
			theAction.targetMeow:cleanAnimalLikeData()
			theAction.targetMeow.isNeedUpdate = true
			mainLogic:checkItemBlock(theAction.targetMeow.y, theAction.targetMeow.x)
		end 

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
		
	end
end

function DestroyItemLogic:runGameItemActionMeowCollectView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		local view = boardView:safeGetItemView(theAction.ItemPos1.y,theAction.ItemPos1.x)
		if view then
			view:playMeowCollect()
		end
		theAction.addInfo = "waitAnim"
	end
	
	if theAction.jsq == 20 then
		theAction.addInfo = 'over'
	end
end


function DestroyItemLogic:runGameItemActionCatteryHitOnceLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.jsq == theAction.size - 1 then
		local item = mainLogic.gameItemMap[theAction.ItemPos1.y][theAction.ItemPos1.x]
		item.canAttackCattery = true
		theAction.addInfo = "over"
	end
		
	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionCatteryHitOnceView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionCatteryReadyLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == 'over' then
		theAction.addInfo = ""
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
			
	
end

function DestroyItemLogic:runGameItemActionCatteryReadyView(boardView, theAction)

	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			for k,v in pairs(theAction.allCattery) do
				local catteryView = boardView:safeGetItemView(v.y, v.x)
				if catteryView then
					catteryView:playCatteryAniByState(CatteryState.kReadyToRoll)
				end
			end
		end
		
		theAction.jsq = theAction.jsq + 1

		if theAction.jsq == 77 then
			theAction.addInfo = "over"
		end

	end
end

-------------------------------------------------------------------------------
function DestroyItemLogic:runGameItemActionDynamiteSetOffLogic(mainLogic, theAction, actid, actByView)
	if theAction.actionStatus == GameActionStatus.kRunning then
		-- 随机选择若干位置发射
		-- 等爆炸动画播放完成之后，发射
		if (theAction.counter == 15) then
			theAction.allMissileChildActionComplete = false
			theAction.totalAttackPosition = 0
			local missileHitCount = 0
			local missileChildHitCallback = function()
				missileHitCount = missileHitCount + 1
				if (missileHitCount >= theAction.totalAttackPosition) then
					theAction.allMissileChildActionComplete = true
				end
			end

			-- 全部将要发射的
			for i, crate in ipairs(theAction.crates) do
				-- 每一个分裂成mainLogic.missileSplit个小弹头
				-- 按照优先级随机 mainLogic.missileSplit 个位置
				local targetPositions = GameExtandPlayLogic:findMissileTarget(mainLogic, crate, mainLogic.missileSplit)
				-- if _G.isLocalDevelopMode then printx(0, #targetPositions,"targetPositions",table.tostring(targetPositions)) end
				theAction.totalAttackPosition = theAction.totalAttackPosition + #targetPositions
				
				if (#targetPositions > 0) then
					for _,toPosition in ipairs(targetPositions) do

						local actionDeleteByMissile = GameBoardActionDataSet:createAs(
							GameActionTargetType.kGameItemAction,
							GameItemActionType.kDynamiteHitSingle, 
							IntCoord:create(crate.x, crate.y),	-- from positoin
							toPosition,	-- toPosition
							GamePlayConfig_MaxAction_time
							)
						actionDeleteByMissile.completeCallback = missileChildHitCallback
						-- actionDeleteByMissile.delayIndex = i * 12
						mainLogic:addDestroyAction(actionDeleteByMissile)
						mainLogic:setNeedCheckFalling()
					end
				else
					missileChildHitCallback()
				end

			end
		end

		if (theAction.addInfo == "over" and theAction.allMissileChildActionComplete ) then
			if (theAction.completeCallback ) then
				theAction.completeCallback()
				mainLogic.destroyActionList[actid] = nil 
			end
		end
	end
end

function DestroyItemLogic:runGameItemActionDynamiteSetOffView(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.counter = 0

	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if (theAction.counter == 45) then
			theAction.addInfo = "over"
		end
	end

	theAction.counter = theAction.counter + 1
end

function DestroyItemLogic:runGameItemActionDynamiteHitSingleLogic(mainLogic, theAction, actid, actByView)

	if (theAction.addInfo == "over") then
		local function bombItem(r, c)
			local item = mainLogic.gameItemMap[r][c]
			local boardData = mainLogic.boardmap[r][c]

            local SpecialID = mainLogic:addSrcSpecialCoverToList( ccp(theAction.ItemPos1.y,theAction.ItemPos1.x) )
           	
			BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
			SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, nil, nil, nil, nil, nil, SpecialID) 
			-- SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c) 
			SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
			GameExtandPlayLogic:doABlocker211Collect(mainLogic, theAction.ItemPos1.y, theAction.ItemPos1.x, r, c, 0, true, 3)
		end

		bombItem(theAction.ItemPos2.y,theAction.ItemPos2.x)

		if (theAction.completeCallback ) then
			theAction.completeCallback()
			mainLogic:setNeedCheckFalling()
		end
		mainLogic.destroyActionList[actid] = nil 
	end

end

function DestroyItemLogic:runGameItemActionDynamiteHitSingleView(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		-- 发射导弹动画
		theAction.counter = 0

		local fromCoord = theAction.ItemPos1
		local toCoord = theAction.ItemPos2
		-- local missilePos = IntCoord:clone(fromPos)
		local crateView = boardView.baseMap[fromCoord.y][fromCoord.x]
		local itemView = boardView.baseMap[toCoord.y][toCoord.x]
		
		if itemView and crateView then 
			-- local fromPos = chestView:getBasePosition(theAction.targetItem.x, theAction.targetItem.y)
			-- local heartMiddleR = 7
			-- local heartMiddleC = 5
			-- local toPos = boardView.baseMap[heartMiddleR][heartMiddleC]:getBasePosition(heartMiddleC, heartMiddleR)
			-- chestView:playWeeklyRace2020ChestHitAnimation(fromPos, toPos)

			local fromPos = crateView:getBasePosition(fromCoord.x, fromCoord.y)
			local toPos = itemView:getBasePosition(toCoord.x, toCoord.y)

			itemView:playDynamiteCrateFlyAnimation(fromPos, toPos)
			-- itemView:playDynamiteCrateFlyAnimation(missilePos,function()  
			-- 	-- 在指定位置上播放爆炸动画
			-- 	if itemView then 
			-- 		itemView:playMissleBombAnimation()
			-- 	end
			-- end)
		end

	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if (theAction.counter == 30) then
			theAction.addInfo = "over"
		end
		theAction.counter = theAction.counter + 1
	end
end

-------------------------------------	Sly Bunny Lane	-------------------------------------------------
function DestroyItemLogic:runGameItemActionSlyBunnyLaneDemolishLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "vanish" then
		theAction.addInfo = ""

		-- printx(11, "111 targetBunnyLane:", theAction.targetBunnyLane)
		SlyBunnyLogic:onSlyBunnyLaneDestroyed(mainLogic, theAction.targetBunnyLane)

	elseif theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionSlyBunnyLaneDemolishLogic   OVER")

		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionSlyBunnyLaneDemolishView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startVanishDelay = 1
		if theAction.jsq == startVanishDelay then
			local r, c = theAction.ItemPos1.y, theAction.ItemPos1.x
			local laneView = boardView.baseMap[r][c]
			if laneView and laneView.playSlyBunnyLaneBeingHit then
				laneView:playSlyBunnyLaneBeingHit(0)
			end
		end

		-- 自身消失
		local vanishDelay = 35
		if theAction.jsq == vanishDelay then
			theAction.addInfo = "vanish"
		end

		--- 整体结束
		local wholeDurationDelay = vanishDelay + 1
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end


function DestroyItemLogic:runGameItemActionChannelWaterTargetLogic(boardView,theAction)

end

function DestroyItemLogic:runGameItemActionChannelWaterTargetView(boardView,theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.counter = 0

	elseif theAction.actionStatus == GameActionStatus.kRunning then
		if (theAction.counter == 45) then
			theAction.addInfo = "over"
		end
	end

	theAction.counter = theAction.counter + 1
end

----------------------------------------------------------------------------------------
--									Cuckoo Bird
----------------------------------------------------------------------------------------
function DestroyItemLogic:runGameItemActionCuckooWindupKeyDemolishLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "over" then
		-- printx(11, "runGameItemActionCuckooWindupKeyDemolishLogic   OVER")
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionCuckooWindupKeyDemolishView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		local startAnimationDelay = 1
		if theAction.jsq == startAnimationDelay then
			local cuckooBird = theAction.cuckooBird
			local cuckooView = boardView.baseMap[cuckooBird.y][cuckooBird.x]
			if cuckooView then
				local fromPos = theAction.fromPos
				local toPos = cuckooView:getBasePosition(cuckooBird.x, cuckooBird.y)
				cuckooView:playCuckooBirdAbsorbEnergy(fromPos, toPos, theAction.bagColour)
			end
		end

		local wholeDurationDelay = 100
		if theAction.jsq == wholeDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

function DestroyItemLogic:runGameItemActionCuckooBirdWalkLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		local cuckooBird = theAction.cuckooBird
		local exchangeItem = theAction.nextItem

		local birdRowShift = exchangeItem.y - cuckooBird.y
		local birdColShift = exchangeItem.x - cuckooBird.x

		-- 一家人不说两家话，借用下Hero的字段
		cuckooBird.tempRowShiftByHero = birdRowShift
		cuckooBird.tempColShiftByHero = birdColShift
		exchangeItem.tempRowShiftByHero = -birdRowShift
		exchangeItem.tempColShiftByHero = -birdColShift

		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then
		CuckooLogic:refreshGameItemDataAfterCuckooBirdWalk(mainLogic)

		-- theAction.addInfo = "over"
		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then
		-- 唉……由于视图不会立即更新，所以被挤下来的对象如果马上下落的话视图会错误。所以等一下。
		if theAction.refreshViewDelay == 1 then
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionCuckooBirdWalkView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then

			local function playExchangeAnimation(targetItem, shiftR, shiftC)
				local itemView = boardView.baseMap[targetItem.y][targetItem.x]
				if itemView then
					local sprite, coverSprite = itemView:getGameItemSprite()
					if sprite then
						local position = UsePropState:getItemPosition(
							IntCoord:create(targetItem.y + shiftR, targetItem.x + shiftC)
							)

						local arr = CCArray:create()
						arr:addObject(CCDelayTime:create(0.2))
						arr:addObject(CCCallFunc:create(function ( ... )
							GamePlayMusicPlayer:playEffect(GameMusicType.kCuckooWalk)
						end))
						arr:addObject(CCMoveTo:create(0.2, position))
						arr:addObject(CCDelayTime:create(0.1))
						local move_action = CCSequence:create(arr) 
						sprite:runAction(move_action)

						if coverSprite then 
							local arr2 = CCArray:create()
							arr2:addObject(CCDelayTime:create(0.2))
							arr2:addObject(CCMoveTo:create(0.2, position))
							arr2:addObject(CCDelayTime:create(0.1))
							local move_action2 = CCSequence:create(arr2)
							coverSprite:runAction(move_action2) 
						end

						if targetItem.ItemType == GameItemType.kCuckooBird then
							local walkingDirection = CuckooLogic:getDirectionByShiftValue(shiftR, shiftC)
							if walkingDirection > 0 then
								if walkingDirection == 4 then
									targetItem.faceBack = true
								elseif walkingDirection == 2 then
									targetItem.faceBack = false
								end
								itemView:playCuckooBirdWalk(walkingDirection, targetItem.faceBack)
							end
						end
					end
				end
			end

			local cuckooBird = theAction.cuckooBird
			local exchangeItem = theAction.nextItem
			playExchangeAnimation(cuckooBird, cuckooBird.tempRowShiftByHero, cuckooBird.tempColShiftByHero)
			playExchangeAnimation(exchangeItem, exchangeItem.tempRowShiftByHero, exchangeItem.tempColShiftByHero)
		end

		--- 击中目标
		local exchangeAnimationDelay = 25
		if theAction.jsq == exchangeAnimationDelay then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionCuckooBirdAttackLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "effectTarget" then
		if theAction.isAttackChain then
			mainLogic:decChainBetween(theAction.cuckooBird.y, theAction.cuckooBird.x, theAction.nextItem.y, theAction.nextItem.x)
		else
			-- theAction.nextItem:addFallingLockByCuckoo()
			theAction.nextItem.updateLaterByCuckooBird = true

			local targetPoint = IntCoord:create(theAction.nextItem.x, theAction.nextItem.y)
			local rectangleAction = GameBoardActionDataSet:createAs(
										GameActionTargetType.kGameItemAction,
										GameItemActionType.kItemSpecial_rectangle,
										targetPoint,
										targetPoint,
										GamePlayConfig_MaxAction_time)
			rectangleAction.addInt2 = 1
			-- rectangleAction.eliminateChainIncludeHem = true
			mainLogic:addDestructionPlanAction(rectangleAction)
			-- mainLogic:setNeedCheckFalling()
		end
		
		theAction.addInfo = ""
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionCuckooBirdAttackView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		-- 开始攻击动画
		local hitGestureDelay = 1
		if theAction.jsq == hitGestureDelay then
			local cuckooBird = theAction.cuckooBird
			if cuckooBird then
				local cuckooBirdView = boardView.baseMap[cuckooBird.y][cuckooBird.x]
				if cuckooBirdView then
					local shiftR = theAction.nextItem.y - cuckooBird.y
					local shiftC = theAction.nextItem.x - cuckooBird.x
					local attackDirection = CuckooLogic:getDirectionByShiftValue(shiftR, shiftC)
					local faceBack
					if attackDirection == 4 then
						faceBack = true
					elseif attackDirection == 2 then
						faceBack = false
					end
					cuckooBirdView:playCuckooBirdAttack(attackDirection, faceBack)
				end
			end
		end

		--- 击中目标
		local effectTargetDelay = 14
		if theAction.jsq == effectTargetDelay then
			theAction.addInfo = "effectTarget"
		end

		-- 整体结束，可以开始下一次的判定
		local hitDurationDelay = 30
		if theAction.jsq == hitDurationDelay then
			theAction.addInfo = "over"
		end
	end
end

------- shellGift
function DestroyItemLogic:runGameItemActionShellGiftBreakLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end
	
	if theAction.addInfo == 'over' then
		local _= theAction.completeCallback and theAction.completeCallback()
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionShellGiftBreakView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		theAction.jsq = theAction.jsq + 1

		-- print("DestroyItemLogic:runGameItemActionShellGiftBreakView()",theAction.jsq)
		
		if not theAction.rewards then
			-- 没奖励的贝壳，直接播放完毕
			if theAction.jsq==1 then
				local c,r = theAction.ItemPos1.x,theAction.ItemPos1.y
				local view = boardView:safeGetItemView(r,c)
				view:playShellGiftBreak(0)
			end
		else
			if theAction.jsq==1 then
				-- 播放贝壳打开
				local c,r = theAction.ItemPos1.x,theAction.ItemPos1.y
				local view = boardView:safeGetItemView(r,c)
				view:playShellGiftBreak(1)
				ShellGiftLogic.breakItemStart(boardView,r,c,theAction)
			end
			if theAction.jsq==60 then
				-- 播放贝壳关闭，奖励飞行
				local c,r = theAction.ItemPos1.x,theAction.ItemPos1.y
				local view = boardView:safeGetItemView(r,c)
				view:playShellGiftBreak(3)
				ShellGiftLogic.breakItemFlyRewards(boardView, theAction,r,c)
			end
		end
		-- 72是贝壳动画播放完成，60+（80 GlobalCoreActionLogic:runView_AddBuffSpecialAnimal）  是飞行动画完成时间
		if theAction.jsq==60+80 then
			-- 奖励飞行结束
			theAction.addInfo = 'over'
		end
	end
end
------- shellGift

--国庆兔子相关动画

function DestroyItemLogic:runGameItemActionNDBunnyMoveLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0

		for k,v in ipairs(theAction.skillList) do
			local newItem = theAction.moveMap[v.r][v.c]
			local curItem = mainLogic:safeGetItemData(newItem.originR, newItem.originC)
			local nowItem = mainLogic:safeGetBoardData(v.r, v.c)
			local nowBoard = mainLogic:safeGetBoardData(v.r, v.c)
			if curItem then
				if v.bunnyType == NationalDayBunnyLogic.BunnyType.kSnow then
					if curItem.ItemType == GameItemType.kAnimal then
						v.realRelease = true
					end
				end
			end
			if nowBoard then
				if v.bunnyType == NationalDayBunnyLogic.BunnyType.kIce then
					if nowItem and not nowItem.isUsed then return end
					if nowBoard.NDBunnyIceLevel ~= 1 then
						v.realRelease = true
					end
				end
			end
		end

	end
	if theAction.addInfo == "animationEnd" then
		NationalDayBunnyLogic:refreshGameItemDataAfterNDBunnyMove(mainLogic,theAction.moveMap)
		NationalDayBunnyLogic:releaseSkill(mainLogic,theAction.skillList)
		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then
		-- 唉……由于视图不会立即更新，所以被挤下来的对象如果马上下落的话视图会错误。所以等一下。
		if theAction.refreshViewDelay == 1 then
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyMoveView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local function playExchangeAnimation(targetItem,nowR,nowC)
				local itemView = boardView:safeGetItemView(targetItem.originR, targetItem.originC)
				if itemView then
					local sprite = itemView:getGameItemSprite()
					if sprite then
						local position = UsePropState:getItemPosition(
							IntCoord:create(nowR, nowC)
							)
						local arr = CCArray:create()
						arr:addObject(CCDelayTime:create(0.05))
						arr:addObject(CCMoveTo:create(0.4, position))
						local move_action = CCSequence:create(arr) 

						sprite:runAction(move_action)

						if targetItem.ItemType == GameItemType.kNationalDayBunny then
							if targetItem.hp > 0 then
								itemView:playNationalDayBunnyMove(targetItem.hp)
							end
						end
					end
				end
			end

			for r = 1, #theAction.moveMap do
				for c = 1, #theAction.moveMap[r] do
					local item = theAction.moveMap[r][c]
		            if item.originR ~= r or item.originC ~= c then
		            	playExchangeAnimation(item,r,c)
		            end
				end
			end		
		end

		local snowDelay = 16
		if theAction.jsq == snowDelay then
			if theAction.skillList then
				for k,v in ipairs(theAction.skillList) do
					if v.realRelease then
						if v.bunnyType == NationalDayBunnyLogic.BunnyType.kSnow then
							local itemView = boardView:safeGetItemView(v.r, v.c)
							if itemView and theAction.moveMap[v.r] and theAction.moveMap[v.r][v.c] and
								theAction.moveMap[v.r][v.c].ItemType == GameItemType.kAnimal then
								local item = theAction.moveMap[v.r][v.c]
								itemView:playNationalDayBunnySkillRelease(v.bunnyType,v.dir,v.snowLevel)
								local oriView = boardView:safeGetItemView(item.originR,item.originC)
								oriView:playNDbunnyDestroy(v.r,v.c)
							end
						end
					end
				end
			end
		end

		local iceDelay = 7
		if theAction.jsq == iceDelay then
			if theAction.skillList then
				for k,v in ipairs(theAction.skillList) do
					if v.realRelease then
						if v.bunnyType == NationalDayBunnyLogic.BunnyType.kIce then
							local itemView = boardView:safeGetItemView(v.r, v.c)
							if itemView then
								itemView:playNationalDayBunnySkillRelease(v.bunnyType,v.dir)
							end
						end
					end
				end
			end
		end

		--- 击中目标
		local exchangeAnimationDelay = 47
		if theAction.jsq == exchangeAnimationDelay then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyLeaveLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	if theAction.addInfo == "animationEnd" then
		for _, bunny in pairs(theAction.toLeaveBunny) do
			local row, col = bunny.y, bunny.x
			bunny:cleanAnimalLikeData()
			bunny.isNeedUpdate = true
			mainLogic:checkItemBlock(row, col)
			mainLogic:addNeedCheckMatchPoint(row , col)
			mainLogic.gameMode:checkDropDownCollect(row, col)	
		end
		theAction.addInfo = "over"
	end

	if theAction.addInfo == "over" then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyLeaveView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			for _, targetBunny in pairs(theAction.toLeaveBunny) do
				local itemView = boardView.baseMap[targetBunny.y][targetBunny.x]
				if itemView then
					itemView:playNationalDayBunnyShowOrLeave(targetBunny.NDBunnyHp,targetBunny.NDBunnyFullHp,targetBunny.NDBunnyType,targetBunny.NDBunnyDir,false)
					itemView:playNDBunnyDoorLight()
				end
			end
		end

		if theAction.jsq == 15 then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end


function DestroyItemLogic:runGameItemActionNDBunnyProduceView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			for _, config in ipairs(theAction.finalStepList) do
				if config and config.item then
					local gridView = boardView.baseMap[config.item.y][config.item.x]
					if gridView then
						gridView:playNationalDayBunnyShowOrLeave(config.hp,config.hp,config.typeId,config.dir,true)
						gridView:playNDBunnyDoorLight()
					end
				end
			end
			for _, config in ipairs(theAction.finalMinList) do
				if config and config.item then
					local gridView = boardView.baseMap[config.item.y][config.item.x]
					if gridView then
						gridView:playNationalDayBunnyShowOrLeave(config.hp,config.hp,config.typeId,config.dir,true)
						gridView:playNDBunnyDoorLight()
					end
				end
			end
		end
		theAction.jsq = theAction.jsq + 1

		if theAction.jsq == 42 then
			theAction.addInfo = "over"
		end
	end

end

function DestroyItemLogic:runGameItemActionNDBunnyProduceLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
	end

	local function dealConfig(config,configType)
		NationalDayBunnyLogic:replaceItemToBunny(mainLogic, config)
		if config and config.board then
			if not config.board.NDBunnyNumData then
				config.board.NDBunnyNumData = {}
			end
			local bunnyNumData = config.board.NDBunnyNumData
			if not bunnyNumData[tostring(config.key)] then
				bunnyNumData[tostring(config.key)] = {}
				bunnyNumData[tostring(config.key)].produceByStep = 0
				bunnyNumData[tostring(config.key)].produceByMin = 0
			end
			if configType == 1 then
				bunnyNumData[tostring(config.key)].produceByStep = bunnyNumData[tostring(config.key)].produceByStep + 1
			elseif configType == 2 then
				bunnyNumData[tostring(config.key)].produceByMin = bunnyNumData[tostring(config.key)].produceByMin + 1
			end
		end
	end
	if theAction.addInfo == 'over' then
		for _, config in ipairs(theAction.finalStepList) do
			dealConfig(config,1)
		end
		for _, config in ipairs(theAction.finalMinList) do
			dealConfig(config,2)
		end
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic:setNeedCheckFalling()
		mainLogic.destroyActionList[actid] = nil
	end

end

function DestroyItemLogic:runGameItemActionNDBunnyHpDecLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "waitAnim" then
		theAction.jsq = theAction.jsq + 1

		local r = theAction.ItemPos1.y
		local c = theAction.ItemPos1.x
	end
	
	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		if theAction.hp == 0 then
			local r = theAction.ItemPos1.y
			local c = theAction.ItemPos1.x
			local collectNum = 1
			if theAction.targetBunny and NationalDayBunnyLogic:getBunnySpecialSize(theAction.targetBunny.NDBunnyType) then
				collectNum = 5
			end
			mainLogic:tryDoOrderList(r, c, GameItemOrderType.kOthers, GameItemOrderType_Others.kNationalDayBunny, collectNum, nil, nil, nil, nil, theAction.targetBunny.NDBunnyType)
			mainLogic:addScoreToTotal(r, c, 100)
			if theAction.targetBunny then
				theAction.targetBunny:cleanAnimalLikeData()
				mainLogic:checkItemBlock(theAction.targetBunny.y, theAction.targetBunny.x)
			end 
		else
			if theAction.targetBunny then
				theAction.targetBunny.isNeedUpdate = true
			end 
		end

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
		
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyHpDecView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		local view = boardView:safeGetItemView(theAction.ItemPos1.y,theAction.ItemPos1.x)
		if view then
			view:playNationalDayBunnyDec(theAction.hp)
		end
		theAction.addInfo = "waitAnim"
	end
	
	if theAction.jsq == theAction.actionTime then
		theAction.addInfo = 'over'
	end
end

function DestroyItemLogic:runGameItemActionNDBunnySnowHpDecLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "waitAnim" then
		theAction.jsq = theAction.jsq + 1

		local r = theAction.ItemPos1.y
		local c = theAction.ItemPos1.x
	end

	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		if theAction.level == 0 then
			local r = theAction.ItemPos1.y
			local c = theAction.ItemPos1.x
			mainLogic:addScoreToTotal(r, c, 100)
			if theAction.targetSnow then
				theAction.targetSnow:cleanAnimalLikeData()
				mainLogic:checkItemBlock(theAction.targetSnow.y, theAction.targetSnow.x)
			end 
		else
			if theAction.targetSnow then
				theAction.targetSnow.isNeedUpdate = true
			end
		end

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
		
	end
end

function DestroyItemLogic:runGameItemActionNDBunnySnowHpDecView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		local view = boardView:safeGetItemView(theAction.ItemPos1.y,theAction.ItemPos1.x)
		if view then
			view:playBunnySnowDec(theAction.level)
		end
		theAction.addInfo = "waitAnim"
	end

	if theAction.jsq == theAction.actionTime then
		theAction.addInfo = 'over'
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyIceHpDecLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "waitAnim" then
		theAction.jsq = theAction.jsq + 1

		local r = theAction.ItemPos1.y
		local c = theAction.ItemPos1.x
	end

	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		if theAction.level == 0 then
			local r = theAction.ItemPos1.y
			local c = theAction.ItemPos1.x
			mainLogic:addScoreToTotal(r, c, 100)
			if theAction.IceBoard then
				theAction.IceBoard.isNeedUpdate = true
			end 
			if theAction.IceItem then
				theAction.IceItem.isNeedUpdate = true
			end 
		end

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
		
	end
end

function DestroyItemLogic:runGameItemActionNDBunnyIceHpDecView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		local view = boardView:safeGetItemView(theAction.ItemPos1.y,theAction.ItemPos1.x)
		if view then
			view:cleanBunnyIce()
		end
		theAction.addInfo = "waitAnim"
	end
	
	if theAction.jsq == theAction.actionTime then
		theAction.addInfo = 'over'
	end
end

--爆米花--

function DestroyItemLogic:runGameItemActionPuffedRiceHpDecLogic(mainLogic, theAction, actid)
	if theAction.addInfo == "waitAnim" then
		theAction.jsq = theAction.jsq + 1

		local r = theAction.targetpuffedRice.y
		local c = theAction.targetpuffedRice.x
	end

	if theAction.addInfo == "over" then
		theAction.addInfo = ""
		if theAction.hp == 0 then
			local r = theAction.targetpuffedRice.y
			local c = theAction.targetpuffedRice.x
			
			SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, r, c)
			mainLogic:tryDoOrderList(r, c, GameItemOrderType.kOthers, GameItemOrderType_Others.kpuffedRice, 1)
			SquidLogic:checkSquidCollectItem(mainLogic, r, c, TileConst.kpuffedRice)
			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r, c, Blocker195CollectType.kpuffedRice)
			if theAction.targetpuffedRice then
				theAction.targetpuffedRice:cleanAnimalLikeData()
			end
			mainLogic:checkItemBlock(r, c)
			mainLogic:addScoreToTotal(r, c, 100)
		else
			if theAction.targetpuffedRice then
				theAction.targetpuffedRice.isNeedUpdate = true
			end
		end

		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
		
	end
end

function DestroyItemLogic:runGameItemActionPuffedRiceHpDecView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0
		local view = boardView:safeGetItemView(theAction.targetpuffedRice.y,theAction.targetpuffedRice.x)
		if view then
			view:playPuffedRiceBeingHit(theAction.hp)
		end
		theAction.addInfo = "waitAnim"
	end

	if theAction.jsq == 1 then
		theAction.addInfo = 'over'
	end
end



function DestroyItemLogic:runGameItemActionPuffedRiceJumpOnceLogic(mainLogic, theAction, actid)
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
		theAction.jsq = 0

	end
	if theAction.addInfo == "animationEnd" then
		 PuffedRiceLogic:refreshGameItemDataAfterPuffedRiceJump(mainLogic,theAction.map)
		theAction.addInfo = "updateBlockState"
		theAction.refreshViewDelay = 0
	end

	if theAction.addInfo == 'updateBlockState' then
		-- 唉……由于视图不会立即更新，所以被挤下来的对象如果马上下落的话视图会错误。所以等一下。
		if theAction.refreshViewDelay == 1 then
			theAction.addInfo = "over"
		end
		theAction.refreshViewDelay = theAction.refreshViewDelay + 1
	end

	if theAction.addInfo == 'over' then
		if theAction.completeCallback then
			theAction.completeCallback()
		end
		mainLogic.destroyActionList[actid] = nil
	end
end

function DestroyItemLogic:runGameItemActionPuffedRiceJumpOnceView(boardView, theAction)
	if theAction.actionStatus == GameActionStatus.kRunning then
		if theAction.jsq == 0 then
			local function playExchangeAnimation(targetItem,nowR,nowC)
				local itemView = boardView:safeGetItemView(targetItem.originR, targetItem.originC)
				if itemView then
					local sprite = itemView:getGameItemSprite()
					if sprite then
						local position = UsePropState:getItemPosition(
							IntCoord:create(nowR, nowC)
							)
						local arr = CCArray:create()
						arr:addObject(CCDelayTime:create(0.2))
						arr:addObject(CCMoveTo:create(0.2, position))
						arr:addObject(CCDelayTime:create(0.1))
						local move_action = CCSequence:create(arr) 
						sprite:runAction(move_action)

						if targetItem and targetItem.ItemType == GameItemType.kpuffedRice then
							--itemView:playNationalDayBunnyMove(targetItem.puffedRiceHp)
						end
					end
				end
			end

			for r = 1, #theAction.map do
				for c = 1, #theAction.map[r] do
					local item = theAction.map[r][c]
		            if item.originR ~= r or item.originC ~= c then
		            	playExchangeAnimation(item,r,c)
		            end
				end
			end		
		end

		--- 击中目标
		local exchangeAnimationDelay = 25
		if theAction.jsq == exchangeAnimationDelay then
			theAction.addInfo = "animationEnd"
		end

		theAction.jsq = theAction.jsq + 1
	end
end

-- 19 春节 start
--春节技能1
function DestroyItemLogic:runningGameItemActionSprintFestival2019Skill1Logic(mainLogic, theAction, actid, actByView)

	-- body
    if theAction.addInfo == "initPosInfo" then
        local randomPos = mainLogic.randFactory:rand(1, #theAction.canBeInfectItemList)
        theAction.PosInfo = theAction.canBeInfectItemList[randomPos]

        theAction.addInfo = "playAnim"
    elseif theAction.addInfo == "changeItem" then
--        local randomPos = mainLogic.randFactory:rand(1, #theAction.canBeInfectItemList)
--        local PosInfo = theAction.canBeInfectItemList[randomPos]
        local PosInfo = theAction.PosInfo

        local gameItemMap = mainLogic.gameItemMap
        if gameItemMap[PosInfo.x] and gameItemMap[PosInfo.x][PosInfo.y] then
            local item = gameItemMap[PosInfo.x][PosInfo.y]
            item:changeToLineAnimal()

            theAction.jsq = 0
            theAction.addInfo = "waitOver"
        else
            theAction.addInfo = "over"
        end
    elseif theAction.addInfo == "waitOver" then
        if theAction.jsq == 20 then
            theAction.addInfo = "over"
        end
    elseif theAction.addInfo == "over" then
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionSprintFestival2019Skill1View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        theAction.jsq = 0
		theAction.addInfo = "initPosInfo"
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

        if theAction.addInfo == "playAnim" then

            local r = theAction.PosInfo.x
            local c = theAction.PosInfo.y
		    local item = boardView.baseMap[r][c]
            local toWorldPos =  boardView:convertToWorldSpace(item:getBasePosition(c, r))
            SpringFestival2019Manager.getInstance():playSpringFestivalAnim1( theAction.WorldSpace, toWorldPos )

            theAction.jsq = 0
            theAction.addInfo = "waitAnimEnd"
        elseif  theAction.addInfo == "waitAnimEnd" then
            if theAction.jsq == 20 then
                theAction.addInfo = "changeItem"
            end
        end

        theAction.jsq = theAction.jsq + 1
    end
end


--春节技能2
function DestroyItemLogic:runningGameItemActionSprintFestival2019Skill2Logic(mainLogic, theAction, actid, actByView)
	-- body
   if theAction.addInfo == "over" then
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionSprintFestival2019Skill2View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning
	end

    if theAction.actionStatus == GameActionStatus.kRunning then
        SpringFestival2019Manager.getInstance():playSpringFestivalAnim2( theAction.WorldSpace )

        theAction.addInfo = "over" 
--        theAction.jsq = theAction.jsq + 1
    end
end


--春节技能3
function DestroyItemLogic:runningGameItemActionSprintFestival2019Skill3Logic(mainLogic, theAction, actid, actByView)
    -- body
	local function overAction( ... )
		-- body
		theAction.addInfo = ""
		mainLogic.destroyActionList[actid] = nil
		if theAction.completeCallback then 
			theAction.completeCallback()
		end
		mainLogic:setNeedCheckFalling()
	end

	local function bombItem(r, c, dirs)
		-- body
		local item = mainLogic.gameItemMap[r][c]
		local boardData = mainLogic.boardmap[r][c]

        if item.isUsed then
		    BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
		    SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3,nil,nil,nil,nil,nil) 
		    SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c, dirs) --冰柱处理
		    SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
		    GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, item._encrypt.ItemColorType, false, 3)

            --背景高亮
            local view = mainLogic.boardView.baseMap[r][c]
            view:playBonusTimeEffcet()
        end
	end

	if theAction.addInfo == "over" then
		local r_min = theAction.ItemPos1.x
		local r_max = theAction.ItemPos2.x
		local c_min = theAction.ItemPos1.y
		local c_max = theAction.ItemPos2.y

        ---3*2格子
		for r = r_min , r_max do 
			for c = c_min, c_max do 
				local dirs = {ChainDirConfig.kUp, ChainDirConfig.kDown, ChainDirConfig.kRight, ChainDirConfig.kLeft}
				if r == r_min then 
					table.remove(dirs, ChainDirConfig.kUp)
				elseif r == r_max then 
					table.remove(dirs, ChainDirConfig.kDown)
				elseif c == c_min then 
					table.remove(dirs, ChainDirConfig.kLeft)
				elseif c == c_max then 
					table.remove(dirs, ChainDirConfig.kRight)
				end
				bombItem(r, c, dirs )
			end
		end

		overAction()
	end
end

function DestroyItemLogic:runGameItemActionSprintFestival2019Skill3View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        local r_min = theAction.ItemPos1.x
		local r_max = theAction.ItemPos2.x
		local c_min = theAction.ItemPos1.y
		local c_max = theAction.ItemPos2.y
		
        --view 展示
        theAction.addInfo = "waitForAnimation"
		theAction.jsq = 0
        theAction.animationStartDelay = theAction.delayIndex * 5
        theAction.animationDelay = 25
	end

    if theAction.actionStatus == GameActionStatus.kRunning then
        if theAction.addInfo == "waitForAnimation" then
            if theAction.jsq == theAction.animationStartDelay then
                local r_min = theAction.ItemPos1.x
		        local r_max = theAction.ItemPos2.x
		        local c_min = theAction.ItemPos1.y
		        local c_max = theAction.ItemPos2.y

                ---2*2格子
		        local item = boardView.baseMap[r_min][c_min]
                local toWorldPos =  boardView:convertToWorldSpace(item:getBasePosition(c_min, r_min))
                SpringFestival2019Manager.getInstance():playSpringFestivalAnim3( theAction.WorldSpace, toWorldPos )

                theAction.addInfo = "playAnimation"
                theAction.jsq = 0
            end
        elseif theAction.addInfo == "playAnimation" then
            if theAction.jsq == theAction.animationDelay then
			    theAction.addInfo = "over" 
		    end
	    end

        theAction.jsq = theAction.jsq + 1
    end

    
end


--春节技能4
function DestroyItemLogic:runningGameItemActionSprintFestival2019Skill4Logic(mainLogic, theAction, actid, actByView)
	-- body
    if theAction.addInfo == "changeItem" then
        local gameItemMap = mainLogic.gameItemMap
        for i,v in ipairs(theAction.PosList) do
            if gameItemMap[v.x] and gameItemMap[v.x][v.y] then
                local item = gameItemMap[v.x][v.y]
--                item:changeToLineAnimal()

                local lineColumnRandList = {AnimalTypeConfig.kLine, AnimalTypeConfig.kColumn}
				local resultSpecialType = lineColumnRandList[mainLogic.randFactory:rand(1, 2)]
				GameExtandPlayLogic:itemDestroyHandler(mainLogic, v.x, v.y)

				item.ItemType = GameItemType.kAnimal
				item.ItemSpecialType = resultSpecialType
				item.isNeedUpdate = true
            end
        end

        theAction.jsq = 0
        theAction.addInfo = "waitboom"
    elseif theAction.addInfo == "waitboom" then
        if theAction.jsq == 20 then
            theAction.addInfo = "boom"
        end
    elseif theAction.addInfo == "boom" then

        local gameItemMap = mainLogic.gameItemMap
        for i,v in ipairs(theAction.PosList) do

            local r = v.x
            local c = v.y
            local item = gameItemMap[r][c]

            if item then
                item:AddItemStatus(GameItemStatusType.kIsSpecialCover)
            end
        end
        
        theAction.addInfo = "over"
    elseif theAction.addInfo == "over" then
        mainLogic.destroyActionList[actid] = nil
    end
end

function DestroyItemLogic:runGameItemActionSprintFestival2019Skill4View(boardView, theAction)
	-- body
	if theAction.actionStatus == GameActionStatus.kWaitingForStart then
		theAction.actionStatus = GameActionStatus.kRunning

        --view 展示
        theAction.addInfo = "waitForAnimation"
		theAction.jsq = 0
        theAction.animationDelay = 90
	end

    if theAction.actionStatus == GameActionStatus.kRunning then

         if theAction.addInfo == "waitForAnimation" then

            local toWorldPosList = {}
            for i,v in ipairs(theAction.PosList) do
                local r = v.x
                local c = v.y
                local item = boardView.baseMap[r][c]
                local toWorldPos =  boardView:convertToWorldSpace(item:getBasePosition(c, r))
                table.insert( toWorldPosList, toWorldPos )
            end

            SpringFestival2019Manager.getInstance():playSpringFestivalAnim4( theAction.WorldSpace, toWorldPosList )

		    theAction.addInfo = "playAnimation"
            theAction.jsq = 0

        elseif theAction.addInfo == "playAnimation" then
            if theAction.jsq == theAction.animationDelay then
			    theAction.addInfo = "changeItem" 
		    end
	    end

        theAction.jsq = theAction.jsq + 1
    end
end

-- 19 春节 end

----------------------------------------------------------------------------------------


----------------------------------------------------------------

destroyItemActionMap = {

	[GameItemActionType.kItemDeletedByMatch] 					= DestroyItemLogic.runGameItemDeletedByMatch,
	[GameItemActionType.kItemCoverBySpecial_Color] 				= DestroyItemLogic.runGameItemSpecialCoverAction,
	[GameItemActionType.kItemSpecial_Color_ItemDeleted] 		= DestroyItemLogic.runGameItemSpecialBombColorAction_ItemDeleted,
	[GameItemActionType.kItemSpecial_ColorColor_ItemDeleted] 	= DestroyItemLogic.runGameItemSpecialBombColorColorAction_ItemDeleted,
	[GameItemActionType.kItemMatchAt_SnowDec] 					= DestroyItemLogic.runGameItemSpecialSnowDec,
	[GameItemActionType.kItemMatchAt_VenowDec] 					= DestroyItemLogic.runGameItemSpecialVenomDec,
	[GameItemActionType.kItem_Furball_Grey_Destroy]				= DestroyItemLogic.runGameItemSpecialGreyFurballDestroy,
	[GameItemActionType.kItemMatchAt_LockDec] 					= DestroyItemLogic.runGameItemSpecialLockDec,
	[GameItemActionType.kItem_Roost_Upgrade] 					= DestroyItemLogic.runGameItemRoostUpgrade,
	[GameItemActionType.kItem_DigGroundDec] 					= DestroyItemLogic.runGameItemDigGroundDecLogic,
	[GameItemActionType.kItem_DigJewleDec] 						= DestroyItemLogic.runGameItemDigJewelDecLogic,
	[GameItemActionType.kItem_randomPropDec] 					= DestroyItemLogic.runGameItemRandomPropDecLogic,
	[GameItemActionType.kItem_Bottle_Blocker_Explode] 			= DestroyItemLogic.runGameItemBottleBlockerDecLogic,
	[GameItemActionType.kItem_Monster_frosting_dec]  			= DestroyItemLogic.runGameItemMonsterFrostingLogic,
	[GameItemActionType.kItem_chestSquare_part_dec]  			= DestroyItemLogic.runGameItemChestSquarePartLogic,
	[GameItemActionType.kItem_Black_Cute_Ball_Dec] 				= DestroyItemLogic.runGameItemBlackCuteBallDec,
	[GameItemActionType.kItem_Mayday_Boss_Loss_Blood] 			= DestroyItemLogic.runningGameItemActionMaydayBossLossBlood,
	[GameItemActionType.kItem_Weekly_Boss_Loss_Blood] 			= DestroyItemLogic.runningGameItemActionWeeklyBossLossBlood,
	[GameItemActionType.kItem_Magic_Lamp_Charging] 				= DestroyItemLogic.runningGameItemActionMagicLampCharging,
	[GameItemActionType.kItem_Wukong_Charging] 					= DestroyItemLogic.runningGameItemActionWukongCharging,
	[GameItemActionType.kItem_WitchBomb] 						= DestroyItemLogic.runningGameItemActionWitchBomb,
	[GameItemActionType.kItem_Honey_Bottle_increase] 			= DestroyItemLogic.runningGameItemActionHoneyBottleIncrease,
	[GameItemActionType.kItemDestroy_HoneyDec] 					= DestroyItemLogic.runningGameItemActionHoneyDec,
	[GameItemActionType.kItem_Sand_Clean] 						= DestroyItemLogic.runningGameItemActionCleanSand,
	[GameItemActionType.kItemMatchAt_IceDec] 					= DestroyItemLogic.runningGameItemActionIceDec,
	[GameItemActionType.kItem_QuestionMark_Protect] 			= DestroyItemLogic.runGameItemQuestionMarkProtect,
	[GameItemActionType.kItem_Magic_Stone_Active] 				= DestroyItemLogic.runGameItemMagicStoneActive,
	[GameItemActionType.kItem_Monster_Jump] 					= DestroyItemLogic.runningGameItemActionMonsterJump,
	[GameItemActionType.kItem_ChestSquare_Jump] 				= DestroyItemLogic.runningGameItemActionChestSquareJump,
	[GameItemActionType.kItemSpecial_CrystalStone_Destroy] 		= DestroyItemLogic.runningGameItemActionCrystalStoneDestroy,
	[GameItemActionType.kItem_Totems_Change] 					= DestroyItemLogic.runingGameItemTotemsChangeAction,
	[GameItemActionType.kItem_SuperTotems_Bomb_By_Match] 		= DestroyItemLogic.runingGameItemTotemsBombByMatch,
	[GameItemActionType.kItem_Decrease_Lotus] 					= DestroyItemLogic.runningGameItemActionDecreaseLotus,
	[GameItemActionType.kItem_SuperCute_Inactive] 				= DestroyItemLogic.runningGameItemActionInactiveSuperCute,
	[GameItemActionType.kItem_Mayday_Boss_Die] 					= DestroyItemLogic.runnningGameItemActionBossDie,
	[GameItemActionType.kItem_Weekly_Boss_Die] 					= DestroyItemLogic.runnningGameItemActionWeeklyBossDie,
	[GameItemActionType.kItemMatchAt_OlympicLockDec] 			= DestroyItemLogic.runningGameItemActionOlympicLockDec,
	[GameItemActionType.kItemMatchAt_OlympicBlockDec] 			= DestroyItemLogic.runningGameItemActionOlympicBlockDec,
	[GameItemActionType.kItemMatchAt_Olympic_IceDec] 			= DestroyItemLogic.runningGameItemActionOlympicIceDec,
	[GameItemActionType.kMissileHit] 							= DestroyItemLogic.runningGameItemActionMissileHit,
	[GameItemActionType.kItemMatchAt_BlockerCoverMaterialDec] 	= DestroyItemLogic.runningGameItemActionBlockerCoverMaterialDec,
	[GameItemActionType.kItem_Blocker_Cover_Dec] 				= DestroyItemLogic.runningGameItemActionBlockerCoverDec,
	[GameItemActionType.kMissileFire] 							= DestroyItemLogic.runningGameItemActionMissileFire,
	[GameItemActionType.kDynamiteSetOff] 						= DestroyItemLogic.runGameItemActionDynamiteSetOffLogic,
	[GameItemActionType.kMissileHitSingle] 						= DestroyItemLogic.runningGameItemActionMissileHitSingle,
	[GameItemActionType.kDynamiteHitSingle] 					= DestroyItemLogic.runGameItemActionDynamiteHitSingleLogic,
	[GameItemActionType.kItem_TangChicken_Destroy] 				= DestroyItemLogic.runningGameItemActionTangChicken,
	[GameItemActionType.kEliminateMusic] 						= DestroyItemLogic.runningGameItemActionPlayEliminateMusic,
	[GameItemActionType.kItem_Blocker195_Dec]			 		= DestroyItemLogic.runningGameItemActionBlocker195Dec	,
	[GameItemActionType.kItem_ColorFilterB_Dec] 				= DestroyItemLogic.runningGameItemActionColorFilterBDec,
	[GameItemActionType.kItem_Chameleon_transform] 				= DestroyItemLogic.runGameItemActionChameleonTransformLogic		,
	[GameItemActionType.kItem_Blocker206_Dec] 					= DestroyItemLogic.runningGameItemActionBlocker206Dec	,
	[GameItemActionType.kItem_Blocker207_Dec] 					= DestroyItemLogic.runningGameItemActionBlocker207Dec	,
	[GameItemActionType.kItem_pacman_eatTarget] 				= DestroyItemLogic.runGameItemActionPacmanEatTargetLogic,
	[GameItemActionType.kItem_pacman_blow] 						= DestroyItemLogic.runGameItemActionPacmanBlowLogic,
	[GameItemActionType.kItem_pacmansDen_generate] 				= DestroyItemLogic.runGameItemActionPacmanGenerateLogic,
	[GameItemActionType.kItem_Turret_upgrade] 					= DestroyItemLogic.runGameItemActionTurretUpgradeLogic,
	[GameItemActionType.kItem_MoleWeekly_Magic_Tile_Blast] 		= DestroyItemLogic.runGameItemActionMoleWeeklyMagicTileBlastLogic,
	[GameItemActionType.kItem_MoleWeekly_Boss_Cloud_Die] 		= DestroyItemLogic.runGameItemActionMoleWeeklyCloudDieLogic,
	[GameItemActionType.kItem_YellowDiamondDec] 				= DestroyItemLogic.runGameItemYellowDiamondDecLogic,
	[GameItemActionType.kItem_ghost_move] 						= DestroyItemLogic.runGameItemActionGhostMoveLogic,
	[GameItemActionType.kItem_ghost_collect] 					= DestroyItemLogic.runGameItemActionGhostCollectLogic,
	[GameItemActionType.kItem_SunFlask_Blast] 					= DestroyItemLogic.runGameItemActionSunFlaskBlastLogic,
	[GameItemActionType.kItem_SunFlower_Blast] 					= DestroyItemLogic.runGameItemActionSunFlowerBlastLogic,
	[GameItemActionType.kItem_Squid_Collect] 					= DestroyItemLogic.runGameItemActionSquidCollectLogic,
	[GameItemActionType.kItem_Squid_Run] 						= DestroyItemLogic.runGameItemActionSquidRunLogic,
	[GameItemActionType.kItem_Canevine_Open_Flower] 			= DestroyItemLogic.runningGameItemActionOpenFlower,
	[GameItemActionType.kItem_Travel_Ramdom_Event_Bomb_Route] 	= DestroyItemLogic.runGameItemActionTravelEventBombRouteLogic,
	[GameItemActionType.kItem_Travel_Ramdom_Event_Energy_Bag]	= DestroyItemLogic.runGameItemActionTravelEventEnergyBagLogic,
	[GameItemActionType.kItem_Travel_Hero_Attack]				= DestroyItemLogic.runGameItemActionHeroAttackLogic,
	[GameItemActionType.kItem_Travel_Hero_Walk]					= DestroyItemLogic.runGameItemActionHeroWalkLogic,
	[GameItemActionType.kActivityCollectionItemHide]			= DestroyItemLogic.runGameItemActionActivityCollectionItemHideLogic,
	[GameItemActionType.kAct8001_Cast_Skill]					= DestroyItemLogic.runGameItemActionAct8001CastSkillLogic,
	[GameItemActionType.kAct8001]								= DestroyItemLogic.runGameItemActionAct8001Logic,
	[GameItemActionType.kItem_WindTunnelSwitch_Demolish]		= DestroyItemLogic.runGameItemActionWindTunnelSwitchDemolishLogic,
	[GameItemActionType.kItem_WaterBucket_Attack]				= DestroyItemLogic.runningGameItemActionAttackBucket,
	[GameItemActionType.kItem_WaterBucket_Ready]				= DestroyItemLogic.runningGameItemActionReadyBucket,
	[GameItemActionType.kItem_WaterBucket_Charge]				= DestroyItemLogic.runningGameItemActionChargeBucket,
	[GameItemActionType.kItem_Water_Attack]						= DestroyItemLogic.runningGameItemActionAttackWater,
	[GameItemActionType.kItem_RailRoad_Skill4]					= DestroyItemLogic.runningGameItemActionRailRoadSkill4Logic,
	[GameItemActionType.kItem_RailRoad_Skill3]					= DestroyItemLogic.runningGameItemActionRailRoadSkill3Logic,
	[GameItemActionType.kItem_RailRoad_Skill2]					= DestroyItemLogic.runningGameItemActionRailRoadSkill2Logic,
	[GameItemActionType.kItem_gyroCreater_delete]				= DestroyItemLogic.runGameItemActionGyroRemoveLogic,
	[GameItemActionType.kItem_gyro_upgrade]						= DestroyItemLogic.runGameItemActionGyroUpgradeLogic,
	[GameItemActionType.kItem_gyroCreater_generate]				= DestroyItemLogic.runGameItemActionGyroGenerateLogic,
	[GameItemActionType.kItemMatchAt_ApplyMilk]					= DestroyItemLogic.runningGameItemActionApplyMilkLogic,
	[GameItemActionType.kItem_WanSheng_increase]				= DestroyItemLogic.runningGameItemActionWanShengIncrease,
	[GameItemActionType.kItem_Plane_Fly_To_Grid] 				= DestroyItemLogic.runGameItemActionPlaneFlyToGridLogic,
	[GameItemActionType.kItem_WeeklyRace2020_Chest_Hit] 		= DestroyItemLogic.runGameItemActionWeeklyRace2020ChestHitLogic,
	[GameItemActionType.kItem_WeeklyRace2020_Heart_Smash] 		= DestroyItemLogic.runGameItemActionWeeklyRace2020HeartSmashLogic,
	[GameItemActionType.kItem_Cattery_Rolling] 		            = DestroyItemLogic.runGameItemActionCatteryRollingLogic,
	[GameItemActionType.kItem_Cattery_Split] 		            = DestroyItemLogic.runGameItemActionCatterySplitLogic,
	[GameItemActionType.kItem_Meow_Collect] 		            = DestroyItemLogic.runGameItemActionMeowCollectLogic,
	[GameItemActionType.kItem_Cattery_Hit_Once] 		        = DestroyItemLogic.runGameItemActionCatteryHitOnceLogic,
	[GameItemActionType.kItem_Angry_Bird_Walk]					= DestroyItemLogic.runGameItemActionAngryBirdWalkLogic,
	[GameItemActionType.kItem_Angry_Bird_Shot]					= DestroyItemLogic.runGameItemActionAngryBirdShotLogic,
	[GameItemActionType.kItem_SlyBunnyLane_Demolish]			= DestroyItemLogic.runGameItemActionSlyBunnyLaneDemolishLogic,
	[GameItemActionType.kFly_Board]								= DestroyItemLogic.runGameItemActionFlyBoardLogic,
	[GameItemActionType.kItem_Walk_Chick_Walk]					= DestroyItemLogic.runGameItemActionChickWalkLogic,
	[GameItemActionType.kItem_Channel_Water_Target]				= DestroyItemLogic.runGameItemActionChannelWaterTargetLogic,
	[GameItemActionType.kItem_Cuckoo_Absorb_Energy]				= DestroyItemLogic.runGameItemActionCuckooWindupKeyDemolishLogic,
	[GameItemActionType.kItem_Cuckoo_Bird_Walk]					= DestroyItemLogic.runGameItemActionCuckooBirdWalkLogic,
	[GameItemActionType.kItem_Cuckoo_Bird_Attack]				= DestroyItemLogic.runGameItemActionCuckooBirdAttackLogic,
	[GameItemActionType.kFirework_Trigger]						= DestroyItemLogic.runGameItemActionFireworkTriggerLogic,
	[GameItemActionType.kItem_Shell_Gift_Break]					= DestroyItemLogic.runGameItemActionShellGiftBreakLogic,
	[GameItemActionType.kFirework_Dec_Level]					= DestroyItemLogic.runGameItemActionFireworkDecLevelLogic,
	[GameItemActionType.kBattery_Dec_Level]						= DestroyItemLogic.runGameItemActionBatteryDecLevelLogic,
	[GameItemActionType.kBattery_Charge_For_Thunderbird]		= DestroyItemLogic.runGameItemActionBatteryChargeLogic,
	[GameItemActionType.kItem_NDBunny_move]		                = DestroyItemLogic.runGameItemActionNDBunnyMoveLogic,
	[GameItemActionType.kItem_NDBunny_leave]		            = DestroyItemLogic.runGameItemActionNDBunnyLeaveLogic,
	[GameItemActionType.kItem_NDBunny_produce]		            = DestroyItemLogic.runGameItemActionNDBunnyProduceLogic,
	[GameItemActionType.kItem_NDBunny_Dec_Hp]		            = DestroyItemLogic.runGameItemActionNDBunnyHpDecLogic,
	[GameItemActionType.kItem_NDBunnySnow_Dec]		            = DestroyItemLogic.runGameItemActionNDBunnySnowHpDecLogic,
	[GameItemActionType.kItem_NDBunnyIce_Dec]		            = DestroyItemLogic.runGameItemActionNDBunnyIceHpDecLogic,
	[GameItemActionType.kItem_Cattery_Ready] 		            = DestroyItemLogic.runGameItemActionCatteryReadyLogic,
	[GameItemActionType.kItem_PuffedRice_Add] 		            = DestroyItemLogic.runGameItemActionPuffedRiceHpDecLogic,
	[GameItemActionType.kItem_PuffedRice_JumpOnce]		        = DestroyItemLogic.runGameItemActionPuffedRiceJumpOnceLogic,
}
