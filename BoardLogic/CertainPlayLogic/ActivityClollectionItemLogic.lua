ActivityClollectionItemLogic = class{}

--旁消 特效 直接消除
function ActivityClollectionItemLogic:destoryCollectionItem(mainLogic, r, c, hitBySpecial)
	local item = mainLogic.gameItemMap[r][c]

	if item and item:isVisibleAndFree() and item.activityCollectionItem_lock == false then
        local upgradeAction = GameBoardActionDataSet:createAs(
								 		GameActionTargetType.kGameItemAction,
								 		GameItemActionType.kActivityCollectionItemHide,
								 		IntCoord:create(r, c),
								 		nil,
								 		GamePlayConfig_MaxAction_time)
		-- printx(11, "updateTurretLevel:".."("..r..","..c..")")
        upgradeAction.hitBySpecial = hitBySpecial
		mainLogic:addDestroyAction(upgradeAction)
	end
end

--获取障碍生成的位置
function ActivityClollectionItemLogic:getCollectionItemCreatePos(mainLogic)
	local findPosList = {}
	local findPos2List = {}
    for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			local board = mainLogic.boardmap[r][c]

            if item:canInfectByActivityColltionItem() and board:canInfectByActivityColltionItem() then
            	table.insert(findPosList,IntCoord:create(r, c))
        	elseif item:canInfectByActivityColltionItem2() and board:canInfectByActivityColltionItem() then
            	table.insert(findPos2List,IntCoord:create(r, c))
            end
		end
	end

	if #findPosList > 0 then
		local findPos = mainLogic.actCollectRandFactory:rand(1, #findPosList)
		return { r = findPosList[findPos].x, c = findPosList[findPos].y }
	elseif #findPos2List > 0 then
		local findPos = mainLogic.actCollectRandFactory:rand(1, #findPos2List)
		return { r = findPos2List[findPos].x, c = findPos2List[findPos].y }
	end
end


function ActivityClollectionItemLogic:playItemShowAnim( ItemId, toPos )

	local vSize = CCDirector:sharedDirector():getVisibleSize()
	local centerPos = ccp(vSize.width/2,vSize.height/2)
	-- local centerNodePos = itemView:convertToNodeSpace(centerPos)
	-- local toNodePos = itemView:convertToNodeSpace(toPos)

    local sprite = Sprite:createEmpty()
	sprite:setPosition(centerPos)

	local function endCall()
		if sprite and not sprite.isDisposed then sprite:removeFromParentAndCleanup(true) end
	end

	local itemIndex = ItemId%3 + 1
	local AnimName = "ActivityCollectionItemAnim/ItemAnim"..itemIndex

	local animNode = UIHelper:createArmature3('tempFunctionRes/Thanksgiving2019/skeletion/ActivityCollectionItemAnim', 
	                    AnimName, AnimName, AnimName)
	animNode:setPosition(ccp(0,0))
	animNode:stop()
	animNode:update(0.001)
	sprite:addChild(animNode)

	-------------action
	local function itemFly()
		local actionList = CCArray:create()
		actionList:addObject( CCEaseSineOut:create(CCMoveTo:create(0.3, toPos)) )	--0.4
		actionList:addObject(CCCallFunc:create(endCall))
		sprite:runAction(CCSequence:create(actionList))
	end

	animNode:addEventListener(ArmatureEvents.COMPLETE, function()
    	animNode:removeAllEventListeners()
    	animNode:play("4",0)
    	-- itemFly()
    end)
	animNode:play("1",1)

	local function itemFlyCall()
    	itemFly()
	end
	local array = CCArray:create()
    array:addObject( CCDelayTime:create(1.2)  )
    array:addObject(CCCallFunc:create(itemFlyCall))
	sprite:runAction(CCSequence:create(array))

	local scene = Director:sharedDirector():getRunningScene()
	scene:addChild(sprite)
	-- return sprite
end

function ActivityClollectionItemLogic:playItemHideAnim( ItemId, fromPos )

	local vSize = CCDirector:sharedDirector():getVisibleSize()
	local centerPos = ccp(vSize.width/2,vSize.height/2)
	local toPos = centerPos

	-- local centerNodePos = itemView:convertToNodeSpace(centerPos)
	-- local toNodePos = itemView:convertToNodeSpace(toPos)
	-- local fromNodePos = itemView:convertToNodeSpace(fromPos)

    local sprite = Sprite:createEmpty()
	sprite:setPosition(fromPos)
	sprite:setScale(1.3)

	local function endCall()
		if sprite and not sprite.isDisposed then sprite:removeFromParentAndCleanup(true) end
	end

	local itemIndex = ItemId%3 + 1
	local AnimName = "ActivityCollectionItemAnim/ItemAnim"..itemIndex

	local animNode = UIHelper:createArmature3('tempFunctionRes/Thanksgiving2019/skeletion/ActivityCollectionItemAnim', 
	                    AnimName, AnimName, AnimName)
	animNode:setPosition(ccp(0,0))
	animNode:stop()
	animNode:update(0.001)
	sprite:addChild(animNode)
	animNode:play("4",0)

	local itemNode = UIHelper:getCon(animNode,"item")
	local itemPath = string.format("activityCollectionItem_InGame_d%04d.png",ItemId+1)
	local itemSprite = Sprite:createWithSpriteFrameName(itemPath)
    itemSprite:setPosition( ccp(0,0) )
    -- itemSprite:setScale(1.3)
    itemNode:addChild( itemSprite.refCocosObj )
    itemSprite:dispose()

	local function FlyToEndPos()
 		local actionList = CCArray:create()
		actionList:addObject( CCEaseSineOut:create(CCMoveTo:create(0.3, toPos)) )	--0.4
		actionList:addObject(CCCallFunc:create(endCall))
		sprite:runAction(CCSequence:create(actionList))
	end

	local function play3Action()
	    FlyToEndPos()
		animNode:play("3",1)
	end

	local function FlyCenterCallback()
		animNode:addEventListener(ArmatureEvents.COMPLETE, function()
	    	animNode:removeAllEventListeners()
	    	play3Action()
	    end)
		animNode:play("2",1)
	end

	local actionList = CCArray:create()
	actionList:addObject( CCEaseSineOut:create(CCMoveTo:create(0.3, centerPos)) )	--0.4
	actionList:addObject(CCCallFunc:create(FlyCenterCallback))
	sprite:runAction(CCSequence:create(actionList))

	local scene = Director:sharedDirector():getRunningScene()
	scene:addChild(sprite)
end