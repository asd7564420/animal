-- 前期用户体验优化2019
-- http://wiki.happyelements.net/pages/viewpage.action?pageId=39917655

BeginnerPlugin = {}

-- 要比 SwapItemLogic.PossibleSwapPriority 数值优先级更高
BeginnerPlugin.advisePriority={
	kTarget = 1.1,			--目标可消除，仅新手用户有
	kTargetNearBy = 1.2,	--附近的目标可被交换后消除，仅新手用户有
	kIce = 1.3, 			--可破冰
	kSpecialBird = 1.4, 	--鸟和特效
}
--每个格子相邻的四个格子相对位置
local itemNearByList = {
	{-1,0},
	{0,1},
	{0,-1},
	{1,0}
}
--每个格子四条边的枚举。每个边默认横向。r,c,旋转
local itemEdgeList = {
	{0,0,false},
	{0,1,true},
	{1,0,false},
	{0,0,true}
}

BeginnerPlugin.adviseNearByItem={
	{GameItemType.kSnow,  	GameItemOrderType.kSpecialTarget,  GameItemOrderType_ST.kSnowFlower},		----雪块
	{GameItemType.kCoin,  	GameItemOrderType.kSpecialTarget,  GameItemOrderType_ST.kCoin},		----银币
	{GameItemType.kVenom,  	GameItemOrderType.kSpecialTarget,  GameItemOrderType_ST.kVenom},		----毒液
}

function BeginnerPlugin.isEnabledGamePlayHand(level)
	level = level or UserManager:getInstance().user:getTopLevelId()
	local isEnabled = level>0 and level<=40
	-- print("BeginnerPlugin.isEnabledGamePlayHand",isEnabled,level)
	return isEnabled
end

function BeginnerPlugin.isEnabled()
	local topLevel = UserManager:getInstance().user:getTopLevelId()
	local isEnabled = topLevel>0 and topLevel<=100
	return isEnabled
end

local ADVISE_MOVIE_TIME = 1.5
local ADVISE_DELAY = 4
local ADVISE_MAX_STEP = 10

function BeginnerPlugin.getAdviseDelay()
	if BeginnerPlugin.isEnabled() then
		return ADVISE_DELAY
	end
	return nil
end

-- 操作提示优先级检查，新手增加: advisePriority 目标高优先级
function BeginnerPlugin.checkAdvise(mainLogic, needAll, priority, possbileMoves)
	if not BeginnerPlugin.isEnabled() then return end
	if not mainLogic.theCurMoves then return end
	if mainLogic.theCurMoves > ADVISE_MAX_STEP then return end
	-- 全要的不是 操作提示
	if needAll then return nil end

	local result = nil
	local move = possbileMoves[1]
	local r,c = move[1].r,move[1].c
	local colorForSwap = AnimalTypeConfig.convertColorTypeToIndex(mainLogic.gameItemMap[r][c]._encrypt.ItemColorType)
	local rd,cd = move.dir.r,move.dir.c
	local posAfterSwap = {r=r+rd,c=c+cd}

	if #move > 2 then
		for i,v in ipairs(mainLogic.theOrderList) do
			if v.key1 == GameItemOrderType.kAnimal and v.v1 > v.f1 then
				local targetColor = v.key2
				if colorForSwap == targetColor then
					result = BeginnerPlugin.advisePriority.kTarget
					break
				end
			end
		end

		if not result and mainLogic.theGamePlayType == GameModeTypeId.LIGHT_UP_ID then
			local boardmap = mainLogic.boardmap or {}
			for i,v in ipairs(move) do
				local item 
				if i == 1 then
					item = boardmap[posAfterSwap.r][posAfterSwap.c]
				else
					item = boardmap[v.r][v.c]
				end
				if item and item.iceLevel > 0 then
					result = BeginnerPlugin.advisePriority.kIce
				end
			end
		end
	end

	return result
end

function BeginnerPlugin.showAdviseEffect(mainLogic)
	if not BeginnerPlugin.isEnabled() then return end
	BeginnerPlugin.stopAdviseEffect()

	local swap = mainLogic.targetPossibleSwap
	local itemPos = swap[1]
	local dir = swap.dir
	local timeScale = GameSpeedManager:getSpeedScaleBySwitch()
	local itemView = mainLogic.boardView.baseMap[itemPos.r][itemPos.c]
	-- 创建显示容器
	local con = CocosObject:create()
	local pos = itemView:getBasePosition(itemPos.c,itemPos.r)
	con:setPosition(ccp(pos.x, pos.y))
	itemView.itemSprite[ItemSpriteType.kBeginnerBorder] = con

	local anim = gAnimatedObject:createWithFilename('gaf/prompt_two_arrow/prompt_two_arrow.gaf')
    anim:setLooped(false)
    anim:start()
	anim:setRotation(dir.r ~= 0 and 90 or 0)
	anim:setPosition(ccp(GamePlayConfig_Tile_Width*dir.c*0.5, -GamePlayConfig_Tile_Height*dir.r*0.5))
    con:addChild(anim)

    BeginnerPlugin.lastAdviseItemView = itemView

	-- 标记下一帧刷新，以添加 con 新边缘容器
	itemView.isNeedUpdate = true
end

function BeginnerPlugin.stopAdviseEffect()
	local itemView = BeginnerPlugin.lastAdviseItemView
	if not itemView then return end
	if not BeginnerPlugin.isEnabled() then return end
	if itemView and itemView.itemSprite then 
		local con = itemView.itemSprite[ItemSpriteType.kBeginnerBorder]
		if con and not con.isDisposed then
			con:removeFromParentAndCleanup(true)
			itemView.itemSprite[ItemSpriteType.kBeginnerBorder] = nil
		end
	end
	BeginnerPlugin.lastAdviseItemView = nil
end

-- -- 操作提示动画 追加边框动画
-- function BeginnerPlugin.showAdviseEffect(mainLogic)
-- 	-- print("BeginnerPlugin.showAdviseEffect()",BeginnerPlugin.lastAdviseEffects,BeginnerPlugin.isEnabled())
-- 	if BeginnerPlugin.lastAdviseEffects then return end
-- 	if not BeginnerPlugin.isEnabled() then return end

-- 	BeginnerPlugin.stopAdviseEffect()
-- 	BeginnerPlugin.lastAdviseEffects={}
-- 	local edges={}
-- 	local swap = mainLogic.targetPossibleSwap
-- 	local timeScale = GameSpeedManager:getSpeedScaleBySwitch()
-- 	-- print("BeginnerPlugin.showAdviseEffect()swap",table.tostring(swap))
-- 	-- 遍历目标交换格子
-- 	for i, v in ipairs(swap) do
-- 		if i==1 and #swap>2 then
-- 			local dir = swap.dir
-- 			v = {r=v.r+dir.r,c=v.c+dir.c}
-- 		end
-- 		local itemView = mainLogic.boardView.baseMap[v.r][v.c]
-- 		-- 创建显示容器
-- 		local con = CocosObject:create()
-- 		con:setPosition(itemView:getBasePosition(v.c,v.r))
-- 		con.itemView = itemView
-- 		itemView.itemSprite[ItemSpriteType.kBeginnerBorder] = con
-- 		local pCallback = CCCallFunc:create(stopAction)
-- 	    local arr = CCArray:create()
-- 	    arr:addObject(CCDelayTime:create(ADVISE_MOVIE_TIME*timeScale))
-- 	    arr:addObject(CCHide:create())
-- 	    arr:addObject(CCDelayTime:create((ADVISE_DELAY-ADVISE_MOVIE_TIME)*timeScale))
-- 	    arr:addObject(CCShow:create())
-- 	    local action = CCRepeat:create(CCSequence:create(arr),3)
-- 		con:runAction(CCSequence:createWithTwoActions(action, CCCallFunc:create(BeginnerPlugin.stopAdviseEffect)))
-- 		table.insert(BeginnerPlugin.lastAdviseEffects,con)

-- 		--遍历每个目标格子的四条边
-- 		-- print("item:",v.r,v.c)
-- 		for ii,vv in ipairs(itemEdgeList) do
-- 			local r = v.r+vv[1]
-- 			local c = v.c+vv[2]
-- 			local key = r .. "_" .. c .. "_"..tostring(vv[3])
-- 			-- print("edge:",key,vv[1],vv[2],vv[3])
-- 			if not edges[key] then
-- 				edges[key] = {key = key,r=vv[1],c=vv[2],isRotate=vv[3],isHide=false,item = itemView,con = con}
-- 				table.insert(edges,edges[key])
-- 			else
-- 				edges[key].isHide = true
-- 			end
-- 		end
-- 		-- 标记下一帧刷新，以添加 con 新边缘容器
-- 		itemView.isNeedUpdate = true
-- 	end

-- 	local edgeWidth = 70
-- 	-- 绘制所有边
-- 	for i,v in ipairs(edges) do
-- 		if not v.isHide then
-- 		    local anim = gAnimatedObject:createWithFilename('gaf/lightBand/lightBand.gaf')
-- 		    anim:setLooped(true)
-- 		    anim:start()
-- 	    	anim:setRotation(v.isRotate and 90 or 0)
-- 		    anim:setPosition(ccp(edgeWidth*(v.c-0.5),edgeWidth*(-v.r+0.5) ) )
-- 		    v.con:addChild(anim)
-- 		end
-- 	end
-- end

-- -- 操作提示动画 停止
-- -- needReset 清除上一次的操作提示动画。每一次停止操作后，循环提示，但是特效动画仅显示前三轮。下一次操作后清空重新显示特效
-- function BeginnerPlugin.stopAdviseEffect(needReset)
-- 	-- print("BeginnerPlugin.stopAdviseEffect()",BeginnerPlugin.lastAdviseEffects,needReset)
-- 	if not BeginnerPlugin.lastAdviseEffects then return end
-- 	for i,con in ipairs(BeginnerPlugin.lastAdviseEffects) do
-- 		if not con.isDisposed then
-- 			con:removeFromParentAndCleanup(true)
-- 			if con.itemView and con.itemView.itemSprite then
-- 				con.itemView.itemSprite[ItemSpriteType.kBeginnerBorder] = nil
-- 			end
-- 		end
-- 	end
-- 	if needReset then
-- 		BeginnerPlugin.lastAdviseEffects = nil
-- 	end
-- end

-- 新手期优先强弹打开关卡开始面板
require "zoo.scenes.component.HomeScene.popoutQueue.HomeScenePopoutAction"

BeginnerPlugin_StartGame = class(HomeScenePopoutAction)
BeginnerPlugin_StartGame_A = class(BeginnerPlugin_StartGame)
BeginnerPlugin_StartGame_B = class(BeginnerPlugin_StartGame)

function BeginnerPlugin_StartGame:ctor()
    self:setSource(AutoPopoutSource.kInitEnter)
end

function BeginnerPlugin_StartGame_A:ctor()
	self.name = "BeginnerPlugin_StartGame_A"
	self.groupKey = "startGameA"
end

function BeginnerPlugin_StartGame_B:ctor()
	self.name = "BeginnerPlugin_StartGame_B"
	self.groupKey = "startGameB"
end

function BeginnerPlugin_StartGame:checkCanPop()
	if BeginnerPlugin.isEnabled() then
		local isOpen = MaintenanceManager:getInstance():isEnabledInGroup('beginnerExp', self.groupKey, UserManager:getInstance().uid)
		if isOpen then
			self:onCheckPopResult(true)
			return
		end
	end
	self:onCheckPopResult(false)
end

function BeginnerPlugin_StartGame:popout( next_action )
	local levelId = UserManager:getInstance().user.topLevelId
	if levelId<=0 then
		he_log_error("BeginnerPlugin_StartGame:popout()invalid levelId:"..tostring(levelId).."-uid:"..tostring(UserManager:getInstance().uid))
		local _ = next_action and next_action()
		return
	end
    HomeScene:sharedInstance().worldScene:moveNodeToCenter(levelId, function ( ... )
        if not PopoutManager:sharedInstance():haveWindowOnScreen() and not HomeScene:sharedInstance().ladyBugOnScreen then
            local startGamePanel = StartGamePanel2020Manager.getInstance():createStartGamePanel(levelId, GameLevelType.kMainLevel)
            startGamePanel:popout(false)
            startGamePanel:setOnClosePanelCallback(next_action)
        end
    end)
end

