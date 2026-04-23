-- 水到渠成
-- http://wiki.happyelements.net/pages/viewpage.action?pageId=65244253

ChannelWaterLogic = {}

local function log(...)
    -- printx(13,"ChannelWaterLogic-",...)
end

function ChannelWaterLogic.isEnable(level)
	-- do return true end
	-- do return false end

	MACRO_DEV_START()
	if _G.__debugChannerlWater then return true end
	local key = "ChannelWaterLogic._debug"
	local value = CCUserDefault:sharedUserDefault():getBoolForKey(key, false)
	if value then
		_G.__debugChannerlWater = true
		return true
	end
	MACRO_DEV_END()
	
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		if mainLogic.gameMode:is(LightUpMode) then
			return false
		end
		level = level or mainLogic.level
	end
	if not level then return false end
	return LevelType:isChannelLevel(level)
end

-- 消除冰块
function ChannelWaterLogic.afterDecIceLevelAt(mainLogic, r, c)
	-- log("ChannelWaterLogic.afterDecIceLevelAt",r, c)
	ChannelWaterLogic.justIceBreak = true
end

function ChannelWaterLogic.isNeedCheckWaterFlow()
	return ChannelWaterLogic.justIceBreak ~= false
end

-- 创建 水
function ChannelWaterLogic.buildWaterView()
	local sprite, animate = SpriteUtil:buildAnimatedSprite(1/15, "water_idle_%02d", 1, 35 , false)
	sprite:play(animate)
	-- 覆盖边缘  71/70
	sprite:setScale(1.02)
	return sprite
end

function ChannelWaterLogic.buildTargetView()
	local count = 59
	local sprite, animate = SpriteUtil:buildAnimatedSprite(1/30, "Crab_A_%04d", 0, count , false)
	sprite:play(animate)
	local spriteEye, animate = SpriteUtil:buildAnimatedSprite(1/30, "Crab_eye_%04d", 0, count , false)
	spriteEye:play(animate)
	spriteEye:setPositionXY(-1,16)
	local con = CocosObject:create()
	con.view = sprite
	con:addChild(sprite)
	con.eye = spriteEye
	con:addChild(spriteEye)
	return con
end

function ChannelWaterLogic.buildSoilView(iceLevel)
	if not iceLevel or iceLevel<=0 then return nil,ItemSpriteType.kChannelWater end
	local view = Sprite:createWithSpriteFrameName("nisha_" .. iceLevel)
	return view,ItemSpriteType.kChannelWater
end

function ChannelWaterLogic.buildSoilBreak(oldIceLevel, callback)
	-- log("ChannelWaterLogic.buildSoilBreak",oldIceLevel)
	if not oldIceLevel or oldIceLevel > 3 or oldIceLevel < 1 then 
		oldIceLevel = 1
	end
	local sprite, animate = SpriteUtil:buildAnimatedSprite(1/30, "nisha_"..oldIceLevel.."_%04d", 1, 18 , false)
	local function onFinish()
		sprite:dp(Event.new(Events.kComplete, nil, sprite))
		sprite:removeFromParentAndCleanup(true)
		if callback then callback() end
	end
	sprite:play(animate,0,1,onFinish)
	return sprite,ItemSpriteType.kChannelEffect
end

-- WaterFlow
-- 水流方向，多个方向会合成一个新方向
local DIRECTION = {
	NONE = 0,
	UP = 1,
	RIGHT = 2,
	DOWN = 4,
	LEFT = 8,
	UR = 3,
	UD = 5,
	DR = 6,
	UDR = 7,
	UL = 9,
	LR = 10,
	ULR = 11,
	DL = 12,
	UDL = 13,
	DLR = 14,
	ALL = 15,
}
-- 有些方向水比较多，不播放动画，直接填满
local DIRECTION_FILL_MAP = {}
DIRECTION_FILL_MAP[DIRECTION.ALL] = true
DIRECTION_FILL_MAP[DIRECTION.DLR] = true
DIRECTION_FILL_MAP[DIRECTION.UDL] = true
DIRECTION_FILL_MAP[DIRECTION.ULR] = true
DIRECTION_FILL_MAP[DIRECTION.UDR] = true
DIRECTION_FILL_MAP[DIRECTION.LR] = true
DIRECTION_FILL_MAP[DIRECTION.UD] = true

function ChannelWaterLogic.onStateFirstCheck()
	-- log("ChannelWaterLogic.onStateFirstCheck")
	ChannelWaterLogic.justIceBreak = false
end

function ChannelWaterLogic.startWaterFlow(callback)
	log("ChannelWaterLogic.startWaterFlow")
    local mainLogic = GameBoardLogic:getCurrentLogic()
	local boardView = mainLogic and mainLogic.boardView
	local con = boardView and boardView.showPanel and boardView.showPanel[ItemSpriteType.kChannelWater]
	if not con then
		ChannelWaterLogic.justIceBreak = false
		local _ = callback and callback()
		return
	end
	ChannelWaterLogic._flowCallback = callback
	ChannelWaterLogic._flowCcon = con
	ChannelWaterLogic._tempWaterList = {}
	ChannelWaterLogic._tickIndex = -1
	ChannelWaterLogic._lastTickIndex = ChannelWaterLogic._tickIndex
	ChannelWaterLogic._tickCount = -1
end

-- 每帧动画的CD（帧数）
ChannelWaterLogic.TICK_CD = 2
-- 每次动画的持续时间（帧数） 帧动画
ChannelWaterLogic.TICK_DURATION = 5
-- 蔓延模式，是否允许一格未满前向旁边空格蔓延
ChannelWaterLogic.OVER_FLOW_MODE = false
ChannelWaterLogic.OVER_FLOW_MODE = true

-- 逐步触发器。检查是否需要创建新水，是则步进动画，否则返回成功
function ChannelWaterLogic.tickWaterFlow()
	if not ChannelWaterLogic._flowCallback then return end
	ChannelWaterLogic._tickIndex = ChannelWaterLogic._tickIndex+1
	if ChannelWaterLogic._tickIndex - ChannelWaterLogic._lastTickIndex<ChannelWaterLogic.TICK_CD then
		-- 不到cd
		return
	end
	
	ChannelWaterLogic._lastTickIndex = ChannelWaterLogic._tickIndex
	ChannelWaterLogic._tickCount = ChannelWaterLogic._tickCount+1
	local mod = ChannelWaterLogic._tickCount % ChannelWaterLogic.TICK_DURATION
	-- log("ChannelWaterLogic.tickWaterFlow",ChannelWaterLogic._tickIndex,ChannelWaterLogic._tickCount,mod)
	-- 继续播放动画
	local isLastFrame = mod == 0
	if ChannelWaterLogic._tempWaterList then
		if not isLastFrame then
			for k,v in ipairs(ChannelWaterLogic._tempWaterList) do
				v:showFrameIndex(mod)
			end
			-- 播放中，不需要继续检查新动画
			return
		end
		
		for k,v in ipairs(ChannelWaterLogic._tempWaterList) do
			ChannelWaterLogic.afterChangeWater(v.view)
			v:removeFromParentAndCleanup(true)
		end
		-- 清空旧动画，并继续检查新动画
		ChannelWaterLogic._tempWaterList = nil
	end

    local mainLogic = GameBoardLogic:getCurrentLogic()
	local boardView = mainLogic and mainLogic.boardView
	local con = boardView and boardView.showPanel and boardView.showPanel[ItemSpriteType.kChannelWater]
	local baseMap = boardView.baseMap
	
	local infoMap = {}
	local function getViewInfo(r,c)
		local view = baseMap[r] and baseMap[r][c]
		if not view or not view.oldBoard then return nil end
		if not infoMap[view] then
			infoMap[view] = {}
			infoMap[view].isChannelWater = view.isChannelWater
			infoMap[view].isSoil = view.oldBoard.iceLevel and view.oldBoard.iceLevel>0
			infoMap[view].isEmpty = not infoMap[view].isChannelWater and not infoMap[view].isSoil
			infoMap[view].flowDir = DIRECTION.NONE
		end
		return infoMap[view],view
	end
	
	local function checkDirStraight(r,c,newDir)
		local viewInfo,itemView = getViewInfo(r,c)
		if not viewInfo or not viewInfo.isEmpty then return end
		viewInfo.flowDir = bit.bor((viewInfo.flowDir or 0),newDir)
	end
	local rotationList1 = {
		DIRECTION.UP,
		DIRECTION.RIGHT,
		DIRECTION.DOWN,
		DIRECTION.LEFT
	}
	local rotationList2 = {
		DIRECTION.UR,
		DIRECTION.DR,
		DIRECTION.DL,
		DIRECTION.UL
	}
	
	ChannelWaterLogic._tempWaterList = {}
	local newWaterCount = 0
	local function createFlow(r,c)
		local viewInfo,view = getViewInfo(r,c)
		if not viewInfo then return end
		local dir = viewInfo.flowDir
		local isOverFlow = false
		if not dir or dir==0 then
			dir = viewInfo.overFlow
			isOverFlow = true
			if not dir or dir==0 then
				return
			end
		end
		newWaterCount = newWaterCount+1
		viewInfo.flowDir = nil
		local imgType = 0
		local rotation = 0
		
		if table.includes(rotationList1,dir) then
			imgType = 1
			rotation = (table.indexOf(rotationList1,dir) - 1)*90
		elseif table.includes(rotationList2,dir) then
			imgType = isOverFlow and 3 or 2
			rotation = (table.indexOf(rotationList2,dir) - 1)*90
		else
			imgType = 0
		end
		local function getUri(imgType,index,isOverFlow)
			return "water_flow_" .. imgType .. "_" .. (index+1)
		end
		log("createFlow()",r,c,imgType,dir,isOverFlow)
		if imgType==0 then
			ChannelWaterLogic.afterChangeWater(view)
		else
			local img = Sprite:createWithSpriteFrameName(getUri(imgType,0))
			img:setScale(1.02)
			img.imgType = imgType
			img.view = view
			img.isOverFlow = isOverFlow
			img:setRotation(rotation)
			img:setPositionXY(view.pos_x,view.pos_y)
			img.showFrameIndex = function(img,index)
				if img.isDisposed then return end
				img:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(getUri(img.imgType,index,img.isOverFlow)))
			end
			con:addChild(img)
			table.insert(ChannelWaterLogic._tempWaterList,img)
		end
	end

	for r = 1, #baseMap do
		for c = 1, #baseMap[r] do
			-- ItemView
			local viewInfo,itemView = getViewInfo(r,c)
			if viewInfo and viewInfo.isChannelWater then
				checkDirStraight(r-1,c,DIRECTION.UP)
				checkDirStraight(r+1,c,DIRECTION.DOWN)
				checkDirStraight(r,c-1,DIRECTION.LEFT)
				checkDirStraight(r,c+1,DIRECTION.RIGHT)
			end
		end
	end
	-- log("ChannelWaterLogic.OVER_FLOW_MODE",ChannelWaterLogic.OVER_FLOW_MODE)
	if ChannelWaterLogic.OVER_FLOW_MODE then
		local function checkDirOverFlow(r,c,newDir)
			local viewInfo,itemView = getViewInfo(r,c)
			if not viewInfo or not viewInfo.isEmpty then return end
			-- log("checkDirOverFlow()viewInfo.flowDir-0",r,c,newDir,viewInfo.flowDir == DIRECTION.ALL - newDir,viewInfo.overFlow and bit.band(viewInfo.overFlow,newDir),table.tostring(viewInfo))
			if not viewInfo.flowDir or viewInfo.flowDir==0 then
				if not viewInfo.overFlow then
					-- 无方向则为新角方向溢出
					viewInfo.overFlow = newDir
				elseif viewInfo.flowDir == DIRECTION.ALL - newDir then
					-- 对角方向则双角相对，自动填满
					viewInfo.flowDir = DIRECTION.ALL
				else
					-- 存在两个角落的溢出则认为是此边流出方向
					viewInfo.overFlow = bit.band(viewInfo.overFlow,newDir)
				end

			elseif viewInfo.flowDir == DIRECTION.ALL - newDir then
				-- 对角方向则双角相对，自动填满
				viewInfo.flowDir = DIRECTION.ALL
			end
			log("checkDirOverFlow()viewInfo.flowDir-e",r,c,viewInfo.flowDir)
		end
		-- 单纯的上下左右可能造成向两侧溢出
		for r = 1, #baseMap do
			for c = 1, #baseMap[r] do
				local viewInfo,itemView = getViewInfo(r,c)
				if viewInfo and viewInfo.flowDir then
					local dir = viewInfo.flowDir
					if table.includes(rotationList1,dir) then
						if dir == DIRECTION.UP then
							checkDirOverFlow(r,c-1,DIRECTION.UL)
							checkDirOverFlow(r,c+1,DIRECTION.UR)
						elseif dir == DIRECTION.DOWN then
							checkDirOverFlow(r,c-1,DIRECTION.DL)
							checkDirOverFlow(r,c+1,DIRECTION.DR)
						elseif dir == DIRECTION.LEFT then
							checkDirOverFlow(r-1,c,DIRECTION.UL)
							checkDirOverFlow(r+1,c,DIRECTION.DL)
						elseif dir == DIRECTION.RIGHT then
							checkDirOverFlow(r-1,c,DIRECTION.UR)
							checkDirOverFlow(r+1,c,DIRECTION.DR)
						end
					end
				end
			end
		end
	end
	for r = 1, #baseMap do
		for c = 1, #baseMap[r] do
			createFlow(r,c)
		end
	end
	-- log("ChannelWaterLogic.tickWaterFlow()endCall?",newWaterCount)
	if newWaterCount == 0 then
		log("ChannelWaterLogic.tickWaterFlow()endCall")
		local _ = ChannelWaterLogic._flowCallback and ChannelWaterLogic._flowCallback()
		ChannelWaterLogic._flowCallback = nil
		ChannelWaterLogic._flowCcon = nil

		ChannelWaterLogic.justIceBreak = false
	end
end

local FRAME_TIME = 0.03333*2

-- 格子变水后
function ChannelWaterLogic.afterChangeWater(view)
    local mainLogic = GameBoardLogic:getCurrentLogic()
	local r,c = view.y,view.x
	-- 变水 数据层
	local boardMap = mainLogic:getBoardMap()
	boardMap[r][c].isChannelWater = true
	-- 变水 显示层
	view:addChannelWater()

	-- 检查螃蟹
	if not boardMap[r][c].isChannelTarget then
		return
	end

	-- 加分
	mainLogic:addScoreToTotal(r,c, GamePlayConfigScore.ChannelTarget)

	-- 清掉格子数据，允许掉落
	local item = mainLogic.gameItemMap[r][c]
	item:afterChannelWater()

	-- 播放飞行动画

	local targetType,targetId = 5,23
	local function afterHit(isTween)
		mainLogic:tryDoOrderList(r,c,targetType,targetId,nil,nil,nil,isTween)
		boardMap[r][c].isChannelTarget = nil
	end
	
	local con = view.itemSprite[ItemSpriteType.kChannelTarget]
	view.itemSprite[ItemSpriteType.kChannelTarget] = nil
	local item = mainLogic.PlayUIDelegate.levelTargetPanel:getTargetByType(targetType,targetId)
	local isOK = con and con.view and item
	if not isOK then
		-- 默认收集
		afterHit()
		local _ = con and con:removeFromParentAndCleanup(true)
		return
	end

	-- 收集、无动画，要播放自己的飞行动画
	afterHit(false)

	con.eye:removeFromParentAndCleanup(true)
	con.eye = nil
	local frames = SpriteUtil:buildFrames("Crab_B_%04d", 1, 15)
	local animate = SpriteUtil:buildAnimate(frames, 1 / 30)
	
	con.view:stopAllActions()
	con.view:play(animate,0,1,function()
		local frames = SpriteUtil:buildFrames("Crab_C_%04d", 1, 12)
		local animate = SpriteUtil:buildAnimate(frames, 1 / 30)
		con.view:stopAllActions()
		con.view:setPositionY(con.view:getPositionY()+20)
		con.view:play(animate)

		local newParent = mainLogic.PlayUIDelegate.levelTargetLayer
		local tempNode = CocosObject:create()
		newParent:addChild(tempNode,SceneLayerShowKey.POP_OUT_LAYER)

		local function onTargetMovieEnd()
			tempNode:removeFromParentAndCleanup(true)
		end

		-- 飞行动画
		local pos = con:getParent():convertToWorldSpace(con:getPosition())
		pos = tempNode:convertToNodeSpace(pos)
		con:removeFromParentAndCleanup(false)
		con:setPositionXY(pos.x,pos.y)
		tempNode:addChild(con)
		local posTarget = item:getParent():convertToWorldSpace(item:getPosition())
		posTarget = tempNode:convertToNodeSpace(posTarget)
		posTarget.y = posTarget.y-98

		-- 螃蟹 起立
		Tween.to(con,0.01,{onComplete = function()
			-- 螃蟹 飞行
			Tween.to(con,7*FRAME_TIME,{delay = 0.3,x= posTarget.x,y = posTarget.y,scale = 1,onComplete = function()
				-- 螃蟹 放大消失
				Tween.to(con.view,0.3,{scale = 1.1,fAlpha = 0,onComplete = function()
					-- 爆炸闪光 代表获得
					local sprite, animate = SpriteUtil:buildAnimatedSprite(1/30, "StarBoom_%04d", 0, 15 , false)
					local function onFinish()
						sprite:removeFromParentAndCleanup(true)
						onTargetMovieEnd()
					end
					sprite:setScale(2)
					sprite:setPositionXY(-140,140)
					sprite:play(animate,0,1,onFinish)
					con:addChild(sprite)
				end})
			end})

			-- 泡泡掉落动画
			local sprite, animate = SpriteUtil:buildAnimatedSprite(1/30, "BubbleFall_%04d", 0, 19 , false)
			local function onFinish()
				sprite:removeFromParentAndCleanup(true)
			end
			sprite:setScale(2)
			sprite:setPositionXY(pos.x-20,pos.y+20)
			sprite:play(animate,0,1,onFinish)
			tempNode:addChild(sprite)

			-- 泡泡跟随
			local function createBubble()
				local tx,ty = pos.x+math.random(-20,20), pos.y+math.random(-10,10)
				local view = Sprite:createWithSpriteFrameName("BubbleUp_0000")
				tempNode:addChildAt(view,0)
				view:setPosition(ccp(tx,ty))
				view:setScale(math.random(0.8,10)*0.1)
				-- local tx,ty = pos.x, pos.y
				view:setVisible(false)
				Tween.to(view,9*FRAME_TIME,{visible = true,delay = 0.1+math.random(1,7)*0.1,x= posTarget.x+math.random(-20,20),y = posTarget.y+math.random(-10,-60),ease = CCEaseSineIn,onComplete = function()
					view:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("BubbleUp_0001"))
					Tween.to(view,1*FRAME_TIME,{onComplete = function()
						view:removeFromParentAndCleanup(false)
					end})
				end})
			end

			local n = math.random(15,25)
			for i = 1,n do
				createBubble()
			end
		end})
	end)
end
