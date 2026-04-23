SnowMatchFestivalLogic = class{}

function SnowMatchFestivalLogic:isSnowMatchFestivalLevel(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > 0 then
		if LevelType:isSnowMatchFestivalLevel(levelID) then
			return true
		end
	end
	return false
end

function SnowMatchFestivalLogic:_playCertainAnimation(targetSprite, spritePrefix, animationFrame, animationTime, 
	doubleWithReverse, repeatTimes, onAnimationFinished, xPos, yPos)
	if targetSprite then
		targetSprite:stopAllActions()

	    local frames = SpriteUtil:buildFrames(spritePrefix.."_%04d", 0, animationFrame)
		local animation = SpriteUtil:buildAnimate(frames, animationTime)
		if doubleWithReverse then
			local frames2 = SpriteUtil:buildFrames(spritePrefix.."_%04d", 0, animationFrame, true)
			local animation2 = SpriteUtil:buildAnimate(frames2, animationTime)

			local sequence = CCArray:create()
			-- sequence:addObject(CCDelayTime:create(0.7))
			sequence:addObject(animation)
			sequence:addObject(animation2)
			-- sequence:addObject(CCDelayTime:create(1))
			local action = CCRepeatForever:create(CCSequence:create(sequence))

			targetSprite:runAction(action)
		else
			if not repeatTimes then repeatTimes = 1 end
			-- targetSprite:play(animation)
			targetSprite:play(animation, 0, repeatTimes, onAnimationFinished, true)
		end
	end
end

function SnowMatchFestivalLogic:playSnowDropIngredientAnimation(r, c)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	if not mainLogic:safeGetBoardData(r, c) then
		return
	end

	local itemView = mainLogic.boardView.baseMap[r][c]
	local currPrefix = "snow_mf_collect"
	local sprite = Sprite:createWithSpriteFrameName(currPrefix.."_0000")

	if itemView.itemSprite[ItemSpriteType.kTempFlyBoard] and not itemView.itemSprite[ItemSpriteType.kTempFlyBoard].isDisposed then
		itemView.itemSprite[ItemSpriteType.kTempFlyBoard]:removeFromParentAndCleanup(true)
		itemView.itemSprite[ItemSpriteType.kTempFlyBoard] = nil
	end

	itemView.itemSprite[ItemSpriteType.kTempFlyBoard] = sprite

	local pos = UsePropState:getItemPosition(IntCoord:create(r,c))
	pos.x = pos.x - 0
	pos.y = pos.y + 10
	sprite:setPositionXY(pos.x,pos.y)
	-- printx(15,"pos.x,pos.y",pos.x,pos.y)

	local function onAnimationFinished( ... )
		-- printx(15,"onAnimationFinished")
		sprite:removeFromParentAndCleanup(true)
		itemView.itemSprite[ItemSpriteType.kTempFlyBoard] = nil
	end

	self:_playCertainAnimation(sprite, currPrefix, 35, 1/30, false, 1, onAnimationFinished)
end