TreasureHuntLogic = class()

function TreasureHuntLogic:treasuresAllFound(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end
	if mainLogic.treasuresAllFoundFlag then
		return true
	end
	return self:checkAllTreasuresFound(mainLogic)
end

function TreasureHuntLogic:checkAllTreasuresFound(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic or not mainLogic.boardmap then return end

	local allFound = true
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local boardData = mainLogic.boardmap[r][c]
			if boardData then
				if boardData.iceLevel and boardData.iceLevel > 0 
				 	and ((boardData.treasureRoadType and boardData.treasureRoadType > 0) or (boardData.treasureRoadPreType and boardData.treasureRoadPreType > 0)) then
				 		allFound = false
				 		break
				end
			end
		end
	end
	mainLogic.treasuresAllFoundFlag = allFound
	return allFound
end


function TreasureHuntLogic:initTreasureRouteData( mainLogic, config )
	local tileMap = config.treasureRouteRawData
	if not tileMap then return end
	if not mainLogic or not mainLogic.boardmap then return end
	for r = 1, #tileMap do 
		if tileMap[r] then
			for c = 1, #tileMap[r] do
				local tileDef = tileMap[r][c]
				if tileDef then
					TreasureHuntLogic:_initTreasureRoadByConfig(mainLogic, r, c, tileDef)
				end
			end
		end
	end
end


function TreasureHuntLogic:_initTreasureRoadByConfig(mainLogic, r, c, tileDef)
	local nextR = r
	local nextC = c
	local currDir
	if tileDef then 
		if tileDef:hasProperty(RouteConst.kUp) then
			currDir = DefaultDirConfig.kUp
			nextR = nextR - 1
		elseif tileDef:hasProperty(RouteConst.kDown) then
			currDir = DefaultDirConfig.kDown
			nextR = nextR + 1
		elseif tileDef:hasProperty(RouteConst.kLeft) then
			currDir = DefaultDirConfig.kLeft
			nextC = nextC - 1
		elseif tileDef:hasProperty(RouteConst.kRight) then
			currDir = DefaultDirConfig.kRight
			nextC = nextC + 1
		end
	end
	if currDir then
		local boardData = mainLogic:safeGetBoardData(r, c)
		if boardData then
			boardData.treasureRoadType = currDir
		end
		local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
		if nextBoardData then
			nextBoardData.treasureRoadPreType = currDir
		end
	end
end


function TreasureHuntLogic:getSpriteParams(x,y,treasureRoadType,treasureRoadPreType)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end
	local usetreasureRoadPreType = 0
	if treasureRoadPreType > 0 then
		local list = {3,4,1,2}
		usetreasureRoadPreType = list[treasureRoadPreType]
	end
	if treasureRoadType > 0 and treasureRoadPreType > 0 then --中间
		if (treasureRoadType - treasureRoadPreType) % 2 == 0 then --直线
			if treasureRoadType % 2 == 0 then
				return nil,{name = "treasure_hunt_straight",rotation = 90,scaleX = 1,scaleY = 1.01}
			else
				return nil,{name = "treasure_hunt_straight",rotation = 0,scaleX = 1,scaleY = 1.01}
			end
		else

			if math.abs(treasureRoadType - usetreasureRoadPreType) == 3 then  --左上
				return nil,{name = "treasure_hunt_corner",rotation = -90,scaleX = 1}
			elseif treasureRoadType + usetreasureRoadPreType == 3 then--右上
				return nil,{name = "treasure_hunt_corner",rotation = 0,scaleX = 1}
			elseif treasureRoadType + usetreasureRoadPreType == 5 then--右下
				return nil,{name = "treasure_hunt_corner",rotation = 90,scaleX = 1}
			elseif treasureRoadType + usetreasureRoadPreType == 7 then--左下
				return nil,{name = "treasure_hunt_corner",rotation = 180,scaleX = 1}
			end
		end
	else
		local item = mainLogic:safeGetItemData(y, x)
		if not item then return end
		if item.treasureFishType <= 0 then return end
		local nameList = {"lanyu","hongyu"}
		local fishScale = {-1,1}
		local roadRotation = {-90,0,-90,0}
		local roadScale = {-1,-1,1,1}
		if treasureRoadType > 0 then --起点
			return {name = nameList[item.treasureFishType],scaleX = fishScale[item.treasureFishType]},{name = "treasure_hunt_edge",rotation = roadRotation[treasureRoadType],scaleX = roadScale[treasureRoadType]}
		elseif treasureRoadPreType > 0 then --终点
			return {name = nameList[item.treasureFishType],scaleX = fishScale[item.treasureFishType]},{name = "treasure_hunt_edge",rotation = roadRotation[usetreasureRoadPreType],scaleX = roadScale[usetreasureRoadPreType]}
		end
	end
end


function TreasureHuntLogic:buildBonusEffect(PlayUIDelegate,onAnimationFinished)
	if _G.dev_kxxxl_bonus then
		return CommonEffect:buildBonusEffectXXL(onAnimationFinished)
	end

	local winSize = CCDirector:sharedDirector():getWinSize()
	local winOrigin = CCDirector:sharedDirector():getVisibleOrigin()

	local container = CocosObject.new(CCNode:create())
	local darkLayer = LayerColor:createWithColor(ccc3(0, 0, 0), winSize.width + ExpandDocker:getExtraWidth(), winSize.height)
	darkLayer:setOpacity(255 * 0.6)
	darkLayer:setPositionX(-ExpandDocker:getExtraWidth()/2)
	container:addChild(darkLayer)
	self:clearFish()
	self:showPanel(container,PlayUIDelegate,function ( ... )
		local anim = SpineAnimation:createWithFile("tempFunctionResInLevel/MatchFestival/TreasureHunt/bonustime.json", "tempFunctionResInLevel/MatchFestival/TreasureHunt/bonustime.atlas", 1)
		anim:playByName("1", false)

		anim:addEventListener(SpineAnimationEvents.kSpineEvt, function(event)
			if event and event.data and event.data.eventType then
				if event.data.eventType == SpineEventTypes.SP_ANIMATION_COMPLETE then
					if darkLayer and not darkLayer.isDisposed then
						darkLayer:removeFromParentAndCleanup(true)
					end
			     	if onAnimationFinished then onAnimationFinished() end
			     	setTimeOut(function ()
			     		if container and not container.isDisposed then
			     			container:removeFromParentAndCleanup(true)
			     		end
					end, 0.4)
				end
			end
		end)

		anim:setPositionXY(winOrigin.x+winSize.width/2, winOrigin.y+winSize.height/2)

		container:addChild(anim)
	end)
	
	return container

end


function TreasureHuntLogic:showPanel(container,PlayUIDelegate,onAnimationFinished)
	-- local picture = PlayUIDelegate.gameBoardView.showPanel[ItemSpriteType.kTreasureRoadMode]
	-- if picture then
	-- 	local size = picture:getGroupBounds().size
	-- 	picture:setContentSize(size)
	-- 	picture:setAnchorPointWhileStayOriginalPosition(ccp(0.5, 0.5))
	-- 	local originScale = UIHelper:convert2WorldSpace(picture,1)
	-- 	local newScale = 1
	-- 	local array = CCArray:create()
	-- 	array:addObject(CCCallFunc:create(function ()
	--         local oldParent = picture:getParent()
	--         local pos = picture:getPosition()
	--         local worldPos = oldParent:convertToWorldSpace(ccp(pos.x, pos.y))
	--         pos = container:convertToNodeSpace(ccp(worldPos.x, worldPos.y))
	--         picture:removeFromParentAndCleanup(false)
	--         container:addChild(picture)
	--         picture:setPosition(ccp(pos.x, pos.y))
	--         newScale = UIHelper:convert2WorldSpace(picture,1)
	--         picture:setScale(originScale/newScale)
 --   		end))
	-- 	array:addObject(CCDelayTime:create(0.1))
	-- 	array:addObject(CCScaleTo:create(0.66, 1.3*originScale/newScale))
	-- 	array:addObject(CCScaleTo:create(0.66, 1*originScale/newScale))
	-- 	array:addObject(CCCallFunc:create(function ( ... )
	-- 		local runFadeOut
	-- 		runFadeOut = function ( parent )
	-- 			for _,c in ipairs(parent.list) do
	-- 				runFadeOut(c)
	-- 			end
	-- 			if parent.road and parent.road.refCocosObj and parent.road.refCocosObj.setOpacity then
	-- 				parent.road:runAction(CCFadeOut:create(0.3))
	-- 			end
	-- 			if parent.fish and parent.fish.refCocosObj and parent.fish.refCocosObj.setOpacity then
	-- 				parent.fish:runAction(CCFadeOut:create(0.3))
	-- 			end
	-- 		end
	-- 		pcall(runFadeOut, picture)
	-- 	end))
	-- 	array:addObject(CCDelayTime:create(0.3))
	-- 	array:addObject(CCCallFunc:create(onAnimationFinished))

	-- 	picture:runAction(CCSequence:create(array))


	-- else
		onAnimationFinished()
	--end

end


function TreasureHuntLogic:clearFish()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		local gameItemMap = mainLogic.gameItemMap
		for r = 1, #gameItemMap do
			for c = 1, #gameItemMap[r] do
				local itemData = gameItemMap[r][c]
				if itemData and itemData.ItemType == GameItemType.kTreasureFish then
					local view = mainLogic.boardView:safeGetItemView(r, c)
					if view and view.itemSprite then
						local realView = view.itemSprite[ItemSpriteType.kTreasureRoadMode]
						if realView and realView.fish then
							realView.fish:removeFromParentAndCleanup(true)
						end
					end
					itemData:cleanAnimalLikeData()
					itemData.isNeedUpdate = true
					mainLogic:checkItemBlock(r,c)
					mainLogic:setNeedCheckFalling()
				end
			end
		end
	end
end

function TreasureHuntLogic:isTreasureHuntMode()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end
	return mainLogic.gameMode:is(TreasureHuntMode)
end

function TreasureHuntLogic:checkLevelTarget(mainLogic, board, oldLevel)
	if not mainLogic then return end
	if board.iceLevel > 0 then return end
	if oldLevel <= 0 then return end
	if (board.treasureRoadType and board.treasureRoadType > 0) or (board.treasureRoadPreType and board.treasureRoadPreType > 0) then
		if self:treasuresAllFound() then
			if mainLogic.PlayUIDelegate then
				local collectAction = GameBoardActionDataSet:createAs(
			 		GameActionTargetType.kGameItemAction,
			 		GameItemActionType.kAct_Treasure_Hunt_Collect,
			 		nil,
			 		nil,
			 		GamePlayConfig_MaxAction_time)
				mainLogic:addGlobalCoreAction(collectAction)
			end
		end
	end
end
