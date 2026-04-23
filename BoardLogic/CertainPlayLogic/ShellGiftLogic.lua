-- 消除节 贝壳宝箱
-- http://wiki.happyelements.net/pages/viewpage.action?pageId=65251215

ShellGiftLogic = {}

-- 自定义奖励的前缀
ShellGiftLogic.CUSTOM_REWARD_PREFIX = "_SGR_"

-- 礼盒生成配置
-- 在第【1，2】步闭区间中，随机给礼盒机会:[3]次新生成口内生成。此后每走完[4]步，给礼盒机会。当（已走步数+[5]）≥（总步数）时，则不再掉落礼盒。
ShellGiftLogic.CREATE_CONFIG = {5,7,10,8,8}
-- ShellGiftLogic.CREATE_CONFIG = {1,1,1,1,1}

-- local AI_DEBUG = _G.useMathFestivalGiftShellForAI

local showLog = not _G.AI_CHECK_ON and _G.isLocalDevelopMode

local function log(...)
    -- printx(13,"ShellGiftLogic-",...)
    -- printx(13,"ShellGiftLogic-",debug.traceback())
end

local REWARDS_CFG = {
    "10087:1,10082:1",
    "10087:1,10081:1",
    "10087:1,10087:1",
    "10007:1",
    "10087:1",
    "10082:1",
    "10081:1",
    "10163:1",
    "0:0",
}

-- 设置当前关可用 rewardsList 奖励表 类似 REWARDS_CFG , weightCfg 权重表，类似 {10,20}
function ShellGiftLogic.setCurrentLevelEnabled(rewardsList,weightCfg,nearChance)
    if showLog then log("setCurrentLevelEnabled()",table.tostring(rewardsList),weightCfg and table.concat(weightCfg,","),nearChance) end

    if ShellGiftLogic._QA_DEBUG then
        local mainLogic = GameBoardLogic:getCurrentLogic()
        if mainLogic and not mainLogic.shellGiftData then
            mainLogic.shellGiftData = ShellGiftLogic.initData(mainLogic)
        end
        return
    end
    if not rewardsList then
        ShellGiftLogic.clearLevelData()
        return
    end
    -- if showLog then log("setCurrentLevelEnabled") end

    ShellGiftLogic._createCfg = ShellGiftLogic.CREATE_CONFIG
    ShellGiftLogic._rewardCfg = rewardsList
    ShellGiftLogic._nearChance = nearChance
    ShellGiftLogic._weightCfg = weightCfg

    if ShellGiftLogic._weightCfg then
        ShellGiftLogic._weightCfg._weightList = nil
    end

    -- ShellGiftLogic._weightCfg = splite("20,20,20,20,50,50,50,10",",")
    -- for i,v in ipairs(ShellGiftLogic._weightCfg) do
    --     ShellGiftLogic._weightCfg[i] = tonumber(v)
    -- end

    -- 当前数据初始化
    local mainLogic = GameBoardLogic:getCurrentLogic()
    if mainLogic and not mainLogic.shellGiftData then
        mainLogic.shellGiftData = ShellGiftLogic.initData(mainLogic)
        local _ = ShellGiftLogic._debugCall and ShellGiftLogic._debugCall()
    end

    -- 回放数据
    ReplayDataManager:updateShellGiftInfo()
end

function ShellGiftLogic.isEnabled()
    if ShellGiftLogic._startByAI then return true end
    return ShellGiftLogic._createCfg
end

-- 挨打，激发礼盒，准备稳定后爆炸
function ShellGiftLogic.hitShellGift(mainLogic, r,c, item)
    local item = item or mainLogic.gameItemMap[r][c]
    if showLog then log("hitShellGift()r&c&item:",r,c,item) end
    if item.isHitShellGift then
        return
    end
    if not item:isVisibleAndFree() then
        return
    end
    item.isHitShellGift = true
    item.isNeedUpdate = true
end

function ShellGiftLogic.cleanAllShellGiftItem(emptyList,rewardList)
    if emptyList then
        for i,v in ipairs(emptyList) do
            local item = v.item
            if showLog then log("cleanAllShellGiftItem()empty",i,item,v.r,v.c,item.isBlock) end
            ShellGiftLogic.cleanShellGiftItem(v.item,true)
        end
    end
    if rewardList then
        for i,v in ipairs(rewardList) do
            local item = v.item
            if showLog then log("cleanAllShellGiftItem()",i,item,v.r,v.c,item.isBlock) end
            ShellGiftLogic.cleanShellGiftItem(item,false)
        end
    end
end

function ShellGiftLogic.cleanShellGiftItem(item,isEmptyReward)
    if showLog then log("cleanShellGiftItem()item,x,y",item,item and item.x,item and item.y) end
    local mainLogic = GameBoardLogic:getCurrentLogic()
    if isEmptyReward and mainLogic.isBonusTime then
        -- 因为没有奖励配置，或者有特效奖励但是bonus时候无法再扔特效，bonus 时候不销毁，保持抖动
        return
    end
    if not item then return end
    item:cleanAnimalLikeData()

    if isEmptyReward then
        -- 无奖励直接销毁，不再等贝壳打开动画
        local boardView = mainLogic.boardView
        local view = boardView:safeGetItemView(item.y,item.x)
        view:playShellGiftBreak(-1)
    end
end

-- ShellGiftState 状态机到了礼包状态，开始检查贝壳礼包
function ShellGiftLogic.stateCheckStart(boardView,callback)
    if showLog then log("stateCheckStart()") end
    ShellGiftLogic.afterUseMoves()
    local isNeedCheckFalling = false
    local mainLogic = boardView.gameBoardLogic
    local gameItemMap = mainLogic:getItemMap()
    local emptyList = {}
    local list = {}
    for r=1, #gameItemMap do
        for c = 1, #gameItemMap[r] do
            local item = gameItemMap[r][c]
            if item and item.isHitShellGift and item:isVisibleAndFree() then
                local rewards = {}
                local props = item.shellGiftInfo
                if ShellGiftLogic._QA_DEBUG then
                    -- ai 打关 测试数据
                    props =  ShellGiftLogic.getGiftRewardsDebug()
                end
                if showLog then log("stateCheckStart() props",tostring(props),type(props)) end
                if type(props) == "table" then
                    if showLog then log("stateCheckStart() props table") end
                    rewards = props
                elseif type(props) == "string" then
                    -- 找得到活动分隔符，说明有活动数据
                    local propInfo,actInfo = nil,nil
                    local array = splite(props,ShellGiftLogic.CUSTOM_REWARD_PREFIX)
                    local a,b = string.find(props,ShellGiftLogic.CUSTOM_REWARD_PREFIX)
                    if a and a==1 then
                        -- 活动分隔符有且首位，则只活动
                        propInfo,actInfo = "",array[1]
                    else
                        -- 活动分隔符没有，或者非首位，则尝试第二位寻找
                        propInfo,actInfo = array[1],array[2]
                    end
                    if showLog then log("stateCheckStart()stringArray",a,b,"propInfo&actInfo:",propInfo," - ",actInfo,table.tostring(array)) end
                    local propsArray = splite(propInfo,",")
                    print("--propsArray",table.tostring(propsArray))
                    for i,v in ipairs(propsArray) do
                        local info = splite(v,":")
                        local reward = {itemId = tonumber(info[1]),num = tonumber(info[2]),kAddBuff = true}
                        print("--propsArray-",i,reward.itemId,table.tostring(info))
                        if reward.itemId>0 then
                            rewards[i] = reward
                        end
                    end
                    if showLog then log("stateCheckStart()stringRewards",table.tostring(rewards)) end
                    if actInfo then
                        if showLog then log("stateCheckStart() props string ACT",actInfo) end
                        -- 是活动自定义的道具，派发出去看有没有活动处理
                        local actData = {info = actInfo}
                        LocalActCoreModel.getInstance():notify(ActInterface.kShellGiftBreak, actData)
                        if actData.rewards then
                            for k,v in pairs(actData.rewards) do
                                table.insert(rewards,v)
                            end
                        end
                    end
                end
                if rewards and rewards[1] then
                    table.insert(list,{rewards = rewards ,item = item, r = r , c = c})
                else
                    printx(13,"ERROR!ShellGiftLogic.beforeBreak() NO REWARDS: r:"..r.."-c:" .. c)
                    -- ShellGiftLogic.cleanShellGiftItem(item,true)
                    -- 仅记录,最后一起清除
                    table.insert(emptyList,{ item = item, r = r , c = c})
                    isNeedCheckFalling = true
                end
                -- 加分
                mainLogic:addScoreToTotal(r,c, GamePlayConfigScore.ShellGift)
            end
        end
    end

    if showLog then log("stateCheckStart()-check list",#list) end

    if #list==0 then
        ShellGiftLogic.cleanAllShellGiftItem(emptyList)
        local _ = callback and callback(isNeedCheckFalling)
        return
    end

    -- 检查一下要扔buff的是否有位置能扔，不能扔的就去掉这个奖励，不显示
    local waitAddBuffPos = {}
    local initBuffInfo = nil
    if true then
        local waitAddBuffIds = {}
        local waitAddBuffMap = {}
        for i,v in ipairs(list) do
            for ii,vv in ipairs(v.rewards) do
                if not mainLogic.isBonusTime and type(vv) == "table" and vv.kAddBuff then
                    table.insert(waitAddBuffIds,vv.itemId)
                    waitAddBuffMap[#waitAddBuffIds] = {v.rewards,ii}
                end
            end
        end

        -- if showLog then log("stateCheckStart()-check buff pos-()waitAddBuffIds:",table.tostring(waitAddBuffIds)) end

        if #waitAddBuffIds>0 then
            local targetItemPosList = nil
            targetItemPosList,initBuffInfo = GameExtandPlayLogic:checkAddBuffsOnBoard(mainLogic,waitAddBuffIds)
            -- if showLog then log("stateCheckStart()-check buff pos-targetItemPosList",table.tostring(targetItemPosList)) end
            if targetItemPosList then
                for i,_ in ipairs(waitAddBuffIds) do
                    local v = targetItemPosList[i]
                    local info = waitAddBuffMap[i]
                    local reward = info[1][info[2]]
                    if showLog then log("stateCheckStart()-check buff pos",i,"-Tpos:",v and v.r,v and v.c,"-Rpos:",info[1],info[2],reward.itemId) end
                    if v and v.r~=0 then
                        -- 有这个奖励的位置，记下来，各个奖励的爆炸位置互相不要重叠
                        reward.targetItemPos = v
                        waitAddBuffPos[v.r .. "_" .. v.c] = info
                        if v.r2 then
                            waitAddBuffPos[v.r2 .. "_" .. v.c2] = info
                        end
                    else
                        -- 没有这个奖励的位置，去掉这个奖励
                        info[1][info[2]] = nil
                        if showLog then log("stateCheckStart()-check buff pos",i,"clear.") end
                    end
                end
            end
        end
        if showLog then log("stateCheckStart()-after check buff pos-",list and #list) end
        -- if showLog then log("stateCheckStart()-after check buff pos-",table.tostring(list)) end
    end

    -- 是否检查相邻
    local isNearRewardCheck = false
    if initBuffInfo and #waitAddBuffPos > 1 then
        if showLog then log("nearChance-",ShellGiftLogic._nearChance) end
        if ShellGiftLogic._nearChance and ShellGiftLogic._nearChance>0 then
            local r = mainLogic.randFactory:rand(1,100)/100
            if showLog then log("nearChance-",r,"<=",ShellGiftLogic._nearChance) end
            if r <= ShellGiftLogic._nearChance then
                isNearRewardCheck = true
            end
        end
    end

    if isNearRewardCheck and initBuffInfo then
        -- 需要检查是否可以扔到相邻位置
        local isFind = false

        -- initBuffInfo
        --     candidateIndex_boom,            -- 可投放 buff/前置炸弹
        --     candidateIndex_magicBird,   -- 可投放 魔力鸟
        --     candidateIndex_firework,        -- 可投放 前置/buff爆竹
        --     candidateIndex_lineAndWrap,     -- 可投放 特效动物
        --     candidateIndex_addStepAnimal,   -- 可投放 加步数动物

        -- 在库中寻找是否有对应的位置
        local function checkPosInMap(map,r,c)
            for swapIndex = 0, 1 do
                local currIndexList = map[swapIndex]
                if currIndexList and #currIndexList > 0 then
                    for i,v in ipairs(currIndexList) do
                        if v.r==r and v.c==c then
                            return v
                        end
                    end
                end
            end
            return nil
        end

        -- 按buff类别分别寻找合法的库
        local function checkDirStraight(r,c,buffType)
            local item = mainLogic:safeGetItemData(r,c)
            if item then
                local result = nil
                if buffType == InitBuffType.RANDOM_BIRD then
                    result = checkPosInMap(initBuffInfo[2],r,c)
                elseif buffType == InitBuffType.BUFF_BOOM then
                    result = checkPosInMap(initBuffInfo[1],r,c)
                -- elseif buffType == InitBuffType.FIRECRACKER then
                --     result = checkPosInMap(candidateIndex_firework)
                elseif buffType == InitBuffType.ADD_STEP_ANIMAL then
                    result = checkPosInMap(initBuffInfo[5],r,c)
                elseif buffType == InitBuffType.LINE or buffType == InitBuffType.WRAP then
                    result = checkPosInMap(initBuffInfo[4],r,c)
                end
                return result
            end
        end

        local dirMap = {
            {-1,0},
            {1,0},
            {0,-1},
            {0,1}
        }

        function temp_shuffle( t )
            for i=#t,1,-1 do
                -- local index = math.random(1, i)
                local index = mainLogic.randFactory:rand(1, i)
                local value = t[index]
                t[index] = t[i]
                t[i] = value
            end
            return t
        end
        dirMap = temp_shuffle(dirMap)

        -- 按rc位置检查附近是否有可用空位
        local function checkNearPosByRC(r,c,target)
            if not r or r==0 then return end
            local key = r .. "_" .. "c"
            if waitAddBuffPos[key] then return end
            local fondData = target.targetItemPos
            -- fondData.item = pos.item
            -- fondData.r = pos.r
            -- fondData.c = pos.c
            -- fondData.tarItemSpecialType = tarItemSpecialType
            -- fondData.tarItemType = tarItemType
            -- fondData.buffType = v.buffType
            -- fondData.createType = v.createType
            -- fondData.propId = v.propId
            local result = nil
            if not result then result = checkDirStraight(r+dirMap[1][1],c+dirMap[1][2],fondData.buffType) end
            if not result then result = checkDirStraight(r+dirMap[2][1],c+dirMap[2][2],fondData.buffType) end
            if not result then result = checkDirStraight(r+dirMap[3][1],c+dirMap[3][2],fondData.buffType) end
            if not result then result = checkDirStraight(r+dirMap[4][1],c+dirMap[4][2],fondData.buffType) end
            return result
        end

        -- 已知队列，求其中一个元素，是否他有附近可用
        local function checkNearPos(target,rewards)
            local secondTarget = nil
            for ii,vv in pairs(rewards) do
                if type(vv) == "table" and vv~=target and vv.targetItemPos then
                    secondTarget = vv
                end
            end
            if not secondTarget then return end
            local pos = checkNearPosByRC(target.targetItemPos.r,target.targetItemPos.c,secondTarget)
            if not pos then
                pos = checkNearPosByRC(target.targetItemPos.r2,target.targetItemPos.c2,secondTarget)
            end
            if not pos then return false end
            secondTarget.targetItemPos.r = pos.r
            secondTarget.targetItemPos.c = pos.c
            return true
        end

        -- 遍历队列，检查每一个元素，如果找到一个就停
        for i,v in ipairs(list) do
            if #v.rewards>1 and v.rewards.isNearReward then
                for ii,vv in pairs(v.rewards) do
                    if type(vv) == "table" and vv.targetItemPos then
                        isFind = checkNearPos(vv,v.rewards)
                    end
                    if isFind then break end
                end
            end
            if isFind then break end
        end
    end

    -- 创建临时动画容器
    local newParent = mainLogic.PlayUIDelegate.propList.layer
    local conRewards = CocosObject:create()
    newParent:addChildAt(conRewards,31)

    -- 回调
    local now,total = 0,#list
    local function callbackOne()
        now = now+1
        -- if showLog then log("callbackOne()",now,total) end
        if now>=total then
            ShellGiftLogic.cleanAllShellGiftItem(emptyList,list)
            conRewards:removeFromParentAndCleanup(true)
            isNeedCheckFalling = total>0
            local _ = callback and callback(isNeedCheckFalling)
        end
    end

    for i,v in ipairs(list) do
        local theAction = GameBoardActionDataSet:createAs(
            GameActionTargetType.kGameItemAction,
            GameItemActionType.kItem_Shell_Gift_Break,
            IntCoord:create(v.c,v.r),
            nil,
            GamePlayConfig_MaxAction_time)
        -- 
        theAction.completeCallback = callbackOne
        theAction.rewards = v.rewards
        theAction.conRewards = conRewards
        mainLogic:addDestroyAction(theAction)
        -- if showLog then log("stateCheckStart()theAction:",i,theAction,theAction.actid) end
    end

    for i,v in ipairs(emptyList) do
        local theAction = GameBoardActionDataSet:createAs(
            GameActionTargetType.kGameItemAction,
            GameItemActionType.kItem_Shell_Gift_Break,
            IntCoord:create(v.c,v.r),
            nil,
            GamePlayConfig_MaxAction_time)
        mainLogic:addDestroyAction(theAction)
        -- if showLog then log("stateCheckStart()theActionEmpty:",i,theAction,theAction.actid) end
    end
    mainLogic:setNeedCheckFalling()
end

-- DestroyItemLogic:runGameItemActionShellGiftBreakView
function ShellGiftLogic.breakItemStart(boardView,r,c,theAction)
    local rewards = theAction.rewards
    local conRewards = theAction.conRewards
    if showLog then log("breakItemStart",r,c,rewards and #rewards) end
    local mainLogic = boardView.gameBoardLogic
    local pos = mainLogic:getGameItemPosInView(r, c)
    local newParent = mainLogic.PlayUIDelegate.propList.layer
    local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)

    -- 播放贝壳打开
    local view = boardView:safeGetItemView(r,c)
    view:playShellGiftBreak(1)

    local baseX = 0
    local gap = 80
    if c==1 then
        gap = gap*0.5
        baseX = gap
    elseif c == colAmount then
        gap = gap*0.5
        baseX = -gap
    end
    local n=#rewards
    local cIndex = n*0.5+0.5
    -- local conRewards = CocosObject:create()
    -- conRewards.icons = {}
    -- newParent:addChildAt(conRewards,31)

    theAction.icons = {}
    local index = -1
    for i,v in pairs(rewards) do
        if type(v) == "table" then
            index = index+1
            local tx = (index-cIndex+1)*gap + baseX + pos.x
            local ty = pos.y - 30
            local con = CocosObject:create()
            local img = Sprite:createWithSpriteFrameName("break_light")
            con:addChild(img)
            conRewards:addChildAt(con,1)

            local onNextLight = nil
    		local function runBgLight()
    			Tween.to(img,3,{rotateBy = 180,onComplete = onNextLight})
    		end
    		onNextLight = runBgLight
            onNextLight()
            
            local icon = GuiUtil.createRewardIcon(v,true)
            conRewards:addChildAt(icon,2)

            local function doMovie(target)
                target:setPosition(ccp(pos.x,pos.y))
                target:setScale(0.01)
                Tween.to(target,0.15,{delay=4*1/15,x = (tx+pos.x)*0.5,y = (ty+pos.y)*0.5+50,scale = 0.5,onComplete = function()
                    Tween.to(target,0.15,{x = tx,y = ty,scale = 1})
                end})
            end

            doMovie(con)
            doMovie(icon)

            icon.reward = v
            icon.pos = ccp(tx,ty)
            icon.light = con
            theAction.icons[i] = icon
        end
    end
    -- local function doFlyRewards()
    --     -- 播放贝壳关闭
    --     view:playShellGiftBreak(3)
    --     -- 奖励飞行
    --     ShellGiftLogic.breakItemFlyRewards(boardView,theAction,r,c)
    -- end
    -- setTimeOut(doFlyRewards,1.2)
    -- doFlyRewards()
end

function ShellGiftLogic.breakItemFlyRewards(boardView, theAction,r,c)
    if showLog then log("breakItemFlyRewards()",r,c) end
    local mainLogic = boardView.gameBoardLogic
    local waitBuffIds = {}
    local startPosList = {}
    local targetItemPosList = {}

    for i,icon in pairs(theAction.icons) do
        local reward = icon.reward
        if showLog then log("breakItemFlyRewards()icon.reward",i,reward,reward and reward.itemId,reward and reward.onDrop) end

        if reward.onDrop then
            -- 奖励有自定义掉落的处理逻辑
            reward.onDrop(reward,icon.pos,icon)
        elseif reward.kAddBuff then
            if not mainLogic.isBonusTime then
                -- 像前置buff一样扔到棋盘上 
                table.insert(waitBuffIds,reward.itemId)
                table.insert(startPosList,icon.pos)
                table.insert(targetItemPosList,reward.targetItemPos)
            end
        else
            -- 基础行为，仅添加
            -- mainLogic.PlayUIDelegate:addTemporaryItem(reward.itemId, reward.num, icon.pos)
        end

        icon.light:removeFromParentAndCleanup(true)
        icon:removeFromParentAndCleanup(true)
    end

    if showLog then log("breakItemFlyRewards()waitBuffIds:",r,c,table.tostring(waitBuffIds)) end

    if #waitBuffIds>0 then
        -- GameExtandPlayLogic:addBuffsOnBoard( mainLogic,itemIds,startPosList,targetItemPosList,callback )
        GameExtandPlayLogic:addBuffsOnBoard(mainLogic,waitBuffIds,startPosList,targetItemPosList,function( ... )
            -- local tItem = targetItemPosList and targetItemPosList[1]
            -- if showLog then log("stateCheckStartViewAndFlyRewards()all done -r:",r,"-c:",c,"buffType:",tItem and tItem.buffType) end
            -- local _ = theAction.completeCallback and theAction.completeCallback()
        end)
    else
        -- local _ = theAction.completeCallback and theAction.completeCallback()
    end
end

-------------------------------

-- ProductItemLogic:product
function ShellGiftLogic.afterProductItem(newItem,mainLogic,r,c)
    local data = mainLogic.shellGiftData
    if not data then
        return
    end
    -- if showLog then log("newItem.ItemSpecialType",newItem.ItemType,newItem.ItemSpecialType,table.tostring(newItem)) end
    -- 仅替换普通动物
    local board = mainLogic:safeGetBoardData(r, c)
    if not (newItem.ItemType == GameItemType.kAnimal and newItem.ItemSpecialType==0) or board.preAndBuffMagicBirdPassSelect then
        return
    end
    -- if showLog then log("afterProductItem()",table.tostring(data.waitList)) end
    for i,v in ipairs(data.waitList) do
        if v>0 then
            data.waitList[i] = v-1
            if data.waitList[i] == 0 then
                newItem.ItemType = GameItemType.kShellGift
                newItem.shellGiftInfo = ShellGiftLogic.getGiftRewards()
                table.remove(data.waitList,i)

                table.insert(data.history,newItem.shellGiftInfo)

                local _ = ShellGiftLogic._debugCall and ShellGiftLogic._debugCall()
                if showLog then log("afterProductItem()ok!!!\n---[[[[ ",newItem.shellGiftInfo) end
                -- break
                return true
            end
        end
    end
end

function ShellGiftLogic.afterUseMoves()
    -- 没有数据，功能是没启用
    local mainLogic = GameBoardLogic:getCurrentLogic()
    local data = mainLogic.shellGiftData
    if not data then
        return
    end
    local currentStep = mainLogic.realCostMoveWithoutBackProp
    local canCheck = not data.lastCheckStep or currentStep>data.lastCheckStep
    if not canCheck then
        return
    end
    data.lastCheckStep = currentStep
    local totalStep = mainLogic.staticLevelMoves
    -- 获得是否有新礼盒机会，且这个机会值是之后的第几次【新生成口掉落】时创建
    local chance,reason = ShellGiftLogic.getCreateChance(currentStep,totalStep,data)
    if chance and chance>0 then
        table.insert(data.waitList,chance)
        data.lastCreate = currentStep
    end

    if ShellGiftLogic._debugCall then
        local msg = ""
        if reason ==1 then
            msg = "无：未到首次机会:" .. currentStep .. "<" .. data.firstCreate
        elseif reason ==2 then
            msg = "无：步数太大，不再掉落:" .. currentStep  .. "+" ..  ShellGiftLogic._createCfg[5] .. ">=" .. totalStep
        elseif reason ==3 then
            msg = "成功，首次掉落，该机会在第N生成口:" .. chance
        elseif reason ==4 then
            msg = "成功，非首次掉落，该机会在第N生成口:" .. chance
        elseif reason ==5 then
            msg = "无：步数不符合条件"
        end
        msg = "第" .. currentStep .. "/" .. totalStep .. "步:" .. msg
        local _ = ShellGiftLogic._debugCall and ShellGiftLogic._debugCall(msg,1)
    end
    if showLog then log("afterUseMoves",chance,currentStep,totalStep,table.tostring(data)) end
end

function ShellGiftLogic.dispose(force)
    if showLog then log("dispose",force) end
    if __WIN32 and not force then
        -- win32 下，连续播放replay，会先初始化新棋盘，再销毁旧棋盘。这里跳过 board.dispose，避免一些全局数据丢失。TODO改成棋盘数据
        return
    end
    ShellGiftLogic.clearLevelData()
end

function ShellGiftLogic.initData(mainLogic)
    -- if showLog then log("initData") end
    local data = {}
    -- 待生成礼包的队列，值为之后第几次新生成口的生成。可能因为未完成生成又触发，所有有多个值
    data.waitList = {}
    -- 关卡内礼盒首次创建的步，不在开局时初始化，此时的随机值是固定的
    -- data.firstCreate = mainLogic.randFactory:rand(ShellGiftLogic._createCfg[1],ShellGiftLogic._createCfg[2])
    data.firstCreate = 0
    -- 关卡内礼盒上次创建的步
    data.lastCreate = 0
    -- 创建礼盒的累计历史，每次存 shellGiftInfo
    data.history = {}
    return data
end

function ShellGiftLogic.getCreateChance(step,total,data)
    local function getChestChance()
        return ShellGiftLogic._createCfg[3]
    end
    if step<ShellGiftLogic._createCfg[1] then
        if showLog then log("ShellGiftLogic.getCreateChance",step,total,data,data.firstCreate==0,ShellGiftLogic._createCfg[1],step == ShellGiftLogic._createCfg[1] - 1) end
        if data.firstCreate==0 and step == ShellGiftLogic._createCfg[1] - 2 then
            local mainLogic = GameBoardLogic:getCurrentLogic()
            data.firstCreate = mainLogic.randFactory:rand(ShellGiftLogic._createCfg[1],ShellGiftLogic._createCfg[2])
        end
        return nil,1
    end
    if step<data.firstCreate then
        return nil,1
    end
    if step + ShellGiftLogic._createCfg[5] >= total then
        return nil,2
    end
    if step>=data.firstCreate and data.lastCreate<=0 then
        return getChestChance(),3
    end
    if data.lastCreate>0 and step-data.lastCreate == ShellGiftLogic._createCfg[4] then
        return getChestChance(),4
    end
    return nil,5
end

-- 自定义贝壳礼包奖励的创建方案
function ShellGiftLogic.setCustomGiftRewards(createCallback)
    -- if showLog then log("setCustomGiftRewards",createCallback) end
    ShellGiftLogic.customGiftCreateCall = createCallback
end

-- 创建贝壳礼包的奖励内容，值是 string 类型，为了方便存断面，礼包破裂时再解析
function ShellGiftLogic.getGiftRewards()
    if ShellGiftLogic._startByAI then
        -- ai 打关 测试数据，没有权重表则直接随机
        if not ShellGiftLogic._weightCfg then
            return ShellGiftLogic.getGiftRewardsDebug()
        end
    end
    if showLog then log("getGiftRewards",ShellGiftLogic.customGiftCreateCall) end
    local result = nil
    if ShellGiftLogic._weightCfg then
        local data = ShellGiftLogic._weightCfg
        if not data._weightList then
            data._weightList = {}
            for k,v in ipairs(data) do
                for i=1,v do
                    table.insert(data._weightList,k)
                end
            end
            -- if showLog then log("getGiftRewards()_weightList",data._weightList) end
        end
        local mainLogic = GameBoardLogic:getCurrentLogic()
        local randId = mainLogic.randFactory:rand(1,#data._weightList)
        local rewardIndex = data._weightList[randId]
        local rewards = ShellGiftLogic._rewardCfg[rewardIndex]
        result = rewards
    end

    if ShellGiftLogic.customGiftCreateCall then
        local data = ShellGiftLogic.customGiftCreateCall()
        if data then
            result = (result or "") .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. tostring(data)
        end
    end
    -- "10087:1,10082:1_SGR_TICKET:777"
    return result
end

function ShellGiftLogic.getDebugInfo()
    -- local msg = string.format("-- 配置：在第【%d，%d】步闭区间中，随机给机会:%d次新生成口内生成。此后每走完%d步，给礼盒机会。当（已走步数+%d）≥（总步数-%d）时，则不再掉落",
    local msg = ShellGiftLogic._createCfg and string.format("-- 礼盒%d,%d步随机首次机会:第%d掉落。后每%d步有机会。步+%d≥总,则不掉",
        (table.unpack or unpack)(ShellGiftLogic._createCfg))
    local mainLogic = GameBoardLogic:getCurrentLogic()
    local data = mainLogic.shellGiftData
    if not data then
        msg = tostring(msg) .. "未初始化"
        return
    end

    msg = msg .. "\n-- 首次生成:" .. tostring(data.firstCreate) .. " - 上次生成:" .. tostring(data.lastCreate)
    msg = msg .. "-- 候选机会:" .. (#data.waitList <=0 and "无" or table.concat(data.waitList,","))
    return msg
end

function ShellGiftLogic.setDebugConfig(cfg)
    if cfg then
        ShellGiftLogic._createCfg = cfg
    else
        ShellGiftLogic._createCfg = ShellGiftLogic.CREATE_CONFIG
    end
    local _ = ShellGiftLogic._debugCall and ShellGiftLogic._debugCall()
end

function ShellGiftLogic.clearLevelData()
    if showLog then log("clearLevelData()") end

    ShellGiftLogic.customGiftCreateCall = nil

    ShellGiftLogic._createCfg = nil
    ShellGiftLogic._rewardCfg = nil
    ShellGiftLogic._weightCfg = nil
    ShellGiftLogic._startByAI = nil
    ShellGiftLogic._nearChance = nil
    ShellGiftLogic._aiCfg = nil
end

-- 以回放数据初始
function ShellGiftLogic.setDataByReplay(data)
    if showLog then log("setDataByReplay()",ShellGiftLogic,table.tostring(data)) end

    if not data then
        ShellGiftLogic.clearLevelData()
        return
    end
    ShellGiftLogic._createCfg = data.createCfg
    ShellGiftLogic._rewardCfg = data.rewardCfg
    ShellGiftLogic._startByAI = data.startByAI
    ShellGiftLogic._nearChance = data.nearChance
    if data.weightCfg then
        ShellGiftLogic._weightCfg = splite(data.weightCfg,",")
        for i,v in ipairs(ShellGiftLogic._weightCfg) do
            ShellGiftLogic._weightCfg[i] = tonumber(v)
        end
    end

    if showLog then log("setDataByReplay()",table.tostring(ShellGiftLogic._createCfg),table.tostring(ShellGiftLogic._weightCfg)) end
end

-- ai打关初始化
function ShellGiftLogic.startLevelByAI()
    if showLog then log("startLevelByAI()") end
    ShellGiftLogic.clearLevelData()
    if not _G.useMathFestivalGiftShellForAI then
        return
    end
    ShellGiftLogic._createCfg = ShellGiftLogic.CREATE_CONFIG
    ShellGiftLogic._rewardCfg = REWARDS_CFG
    ShellGiftLogic._startByAI = true
    ShellGiftLogic._weightCfg = nil
    ShellGiftLogic._nearChance = nil
    local aiCfg = _G.useMathFestivalGiftShellForAI
    -- print("aiCfg",type(aiCfg),aiCfg)

    local arr = type(aiCfg) == "string" and splite(aiCfg,"_")
    if arr and #arr>=#ShellGiftLogic._createCfg+2 then
        ShellGiftLogic._nearChance = tonumber(arr[2])/100
        local cfg = {}
        local indexStart = 3
        for i=indexStart,#arr do
            cfg[i-indexStart+1] = tonumber(arr[i])
        end
        ShellGiftLogic._weightCfg = cfg
        ShellGiftLogic._aiCfg = nil
        -- print("ShellGiftLogic.startLevelByAI()",ShellGiftLogic._nearChance,table.tostring(_G.useMathFestivalGiftShellForAI),table.tostring(ShellGiftLogic._weightCfg))
    else
        ShellGiftLogic._aiCfg = tostring(aiCfg)
        -- print("ShellGiftLogic.startLevelByAI()cfgFail:",aiCfg)
    end
end

-- 进关保存回放
function ShellGiftLogic.getDataForReplay()
    if showLog then log("getDataForReplay()") end
    local data = nil
    if _G.useMathFestivalGiftShellForAI then
        data = {}
        data.createCfg = ShellGiftLogic.CREATE_CONFIG
        data.rewardCfg = REWARDS_CFG
        data.startByAI = ShellGiftLogic._startByAI
        data.weightCfg = ShellGiftLogic._weightCfg and table.concat(ShellGiftLogic._weightCfg,",")
        data.nearChance = ShellGiftLogic._nearChance
        data.aiCfg = ShellGiftLogic._aiCfg
    elseif ShellGiftLogic.isEnabled() then
        data = {}
        data.createCfg = ShellGiftLogic.CREATE_CONFIG
        data.rewardCfg = ShellGiftLogic._rewardCfg
        data.weightCfg = ShellGiftLogic._weightCfg and table.concat(ShellGiftLogic._weightCfg,",")
        data.nearChance = ShellGiftLogic._nearChance
    end
    return data
end

MACRO_DEV_START()

-- unittest AI_CFG
-- _G.useMathFestivalGiftShellForAI = "MathFestivalGiftShell_15_0_0_0_0_10_10_10_0_100"
-- print("find?",string.find(_G.useMathFestivalGiftShellForAI,"MathFestivalGiftShell"))
-- ShellGiftLogic.startLevelByAI()
-- unittest AI_CFG END

-- 10087，--前置魔力鸟
-- 10007, --游戏前置 糖纸(爆炸+直线)
-- 10081, --游戏前置 爆炸
-- 10082, --游戏前置 直线
-- 10163, --游戏前置 加五动物
function ShellGiftLogic.getGiftRewardsDebug()
    local cfg = ShellGiftLogic._rewardCfg or REWARDS_CFG
    
    local mainLogic = GameBoardLogic:getCurrentLogic()
    local index = mainLogic.randFactory:rand(1,#cfg)
    local str = cfg[index]
    local ticketStr = "5027t:999"
    local data = str .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- local data = "10163:1"           .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- local data = "10087:1,10081:1"   .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- local data = "10087:1,10082:1"   .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- local data = "10182:1"           .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- local data = "10181:1"           .. ShellGiftLogic.CUSTOM_REWARD_PREFIX .. ticketStr
    -- ShellGiftLogic._testI = (ShellGiftLogic._testI or 0) + 1
    -- if ShellGiftLogic._testI == 1 then
    --     return "0:0_SGR_5027t:999"
    -- end
    -- if ShellGiftLogic._testI == 2 then
    --     return "10007:1_SGR_5027t:999"
    -- end
    return data
end

-- unittest  强制生成礼盒机会
-- local mainLogic = GameBoardLogic and GameBoardLogic:getCurrentLogic()
-- if mainLogic then
--     ShellGiftLogic.setCurrentLevelEnabled()
--     table.insert(mainLogic.shellGiftData.waitList,1)
--     print("----new debug shellgift",table.tostring(mainLogic.shellGiftData))
-- end
-- unittest  强制生成礼盒机会 END

-- unittest  强制掉生成临时道具的礼包  win32 调试 QA测试用
-- if __WIN32 and not _G.AI_CHECK_ON then
--     ShellGiftLogic._QA_DEBUG = true
--     ShellGiftLogic._startByAI = true
--     ShellGiftLogic._createCfg = ShellGiftLogic.CREATE_CONFIG
--     ShellGiftLogic._rewardCfg = REWARDS_CFG
--     ShellGiftLogic._weightCfg = nil
--     ShellGiftLogic._nearChance = nil

--     function ShellGiftLogic.setCurrentLevelEnabled(rewardsList,weightCfg,nearChance)
--         local mainLogic = GameBoardLogic:getCurrentLogic()
--         if mainLogic and not mainLogic.shellGiftData then
--             mainLogic.shellGiftData = ShellGiftLogic.initData(mainLogic)
--         end
--     end
--     function ShellGiftLogic.dispose()
--     end
-- end
-- unittest  强制掉生成临时道具的礼包  END

MACRO_DEV_END()

