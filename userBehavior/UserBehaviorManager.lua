-- @Author: gang.niu
-- @Date:   2020-01-02 17:28:44
-- @Last Modified by:   gang.niu
-- @Last Modified time: 2020-02-12 11:09:03

local TickTaskMgr = require 'zoo.areaTask.TickTaskMgr'
local model = require 'zoo.gamePlay.userBehavior.UserBehaviorModel'

local localDataPath = "UBLocalData"
local sceondCount = 0
local fiveHours = 3600 * 5
local eightHours = 3600 * 8
local hadSendData = false

local isDebug = false


UserBehaviorManager = class()

local instance = nil
function UserBehaviorManager:getInstance( ... )
	if not instance then
		instance = UserBehaviorManager.new()
		instance:init()
	end
	return instance
end

function UserBehaviorManager:init( )
	-- body
	-- 初始化一次
	self.data = {}
	self.cacheData = {}
	self.tempLongestGamingTime = 0
	self.isCounting  = false
	self.inBackGround = false
	
	self:_read()
	self:createTimeCounter()
	self:resetData()

	-- self:trySendCacheData()
	self:firstLogin()

    GlobalEventDispatcher:getInstance():addEventListener(kGlobalEvents.kPassDay,function ( ... )
    	-- body
		self:resetData()
    end)

end

function UserBehaviorManager:resetData( )
	-- body
	local todayData = self:getTodayCacheData()
	local data = {}

	data.longestGamingTime = todayData.longestGamingTime or 0
	data.todayGamingTime = todayData.todayGamingTime or 0
	data.enterGameCount = todayData.enterGameCount or 0
	data.minTopLevel = self:getTodayTopLevel()

	data.timeByTag = {}
	for i,v in pairs(model.TimeTag) do 
		data.timeByTag[v] = todayData.timeByTag and todayData.timeByTag[v] or 0
	end

	self.data = data
end

-- 计时
function UserBehaviorManager:createTimeCounter(  )
	-- body
    self.tickTaskMgr = TickTaskMgr.new()
    self.tickTaskMgr:setTickTask(1, function()
		-- printx(16,"counting....")
    	if not self.inBackGround then
        	self:onTick()
        end
    end)
end

function UserBehaviorManager:onTick( ... )
	-- body
	sceondCount = sceondCount + 1
	-- 一分钟
	-- printx(16,"counting",sceondCount)
	-- RemoteDebug:uploadLogWithTag("UserBehaviorManageronTick",tostring(sceondCount))	

	-- printx(16,self:getTimeTag(),self:getTodayKey())

	if sceondCount%60 == 0 and self.isCounting then
		self:oneMinutePassed()
	end
end

----------------------------------------------------

-- 每分钟记录一下数据
function UserBehaviorManager:oneMinutePassed( )
	-- body
	self:recordLongestGameingTime()
	self:recordTodayGameingTime()
	self:recordTimeByTag()
	self:setTodayCacheData()
end

function UserBehaviorManager:recordLongestGameingTime()
	-- body
	self.tempLongestGamingTime = self.tempLongestGamingTime + 1
	if self.data.longestGamingTime < self.tempLongestGamingTime then
		self.data.longestGamingTime = self.tempLongestGamingTime
	end
end

function UserBehaviorManager:recordTodayGameingTime()
	-- body
	self.data.todayGamingTime = self.data.todayGamingTime + 1
end

function UserBehaviorManager:recordTimeByTag( tag )
	-- body
	local tag = self:getTimeTag()
	local timeByTag = self.data.timeByTag
	timeByTag[tag] = timeByTag[tag] + 1
end


function UserBehaviorManager:stop(  )
	-- body
	if self.tickTaskMgr then
		self.tickTaskMgr:stop()
		self.isCounting = false
	end
end

function UserBehaviorManager:start(  )
	-- body
	if self.isCounting then return end
	if self.tickTaskMgr then
		self.tickTaskMgr:start()
		self.isCounting = true
	end

	if not hadSendData then
		self:trySendCacheData()
		hadSendData = true
	end

	-- printx(16,"getTimeTag: ",self:getTimeTag(),"  todaykey: ",self:getTodayKey()," time :",Localhost:timeInSec())
	-- RemoteDebug:uploadLogWithTag("UserBehaviorManagerstart","getTimeTag: ",self:getTimeTag(),"  todaykey: ",self:getTodayKey()," time :",Localhost:timeInSec())	

end

-------------------------------------------------------

-- 本地数据读写

function UserBehaviorManager:_read( )
	-- body
	local uid = UserManager:getInstance().user.uid or "12345"
	local path = localDataPath..tostring(uid)..".ds"

	local cacheData = Localhost:readFromStorage(path) or {}

	self.cacheData = cacheData
end

function UserBehaviorManager:_write( ... )
	-- body
	local uid = UserManager:getInstance().user.uid or "12345"
	local path = localDataPath..tostring(uid)..".ds"

	Localhost:writeToStorage(self.cacheData,path)
end

function UserBehaviorManager:getAllCacheData()
	-- body
	return table.clone(self.cacheData)
end

function UserBehaviorManager:setTodayCacheData()
	-- body
	-- local cacheData = self:getAllCacheData()
	local key = self:getTodayKey()
	self.cacheData[key] = table.clone(self.data)

	self:_write()
end

function UserBehaviorManager:getTodayCacheData(  )
	-- body
	local key = self:getTodayKey()
	local cacheData = self:getAllCacheData()
	if cacheData and not table.isEmpty(cacheData) then
		return cacheData[key] or {}
	end
	return {}
end

function UserBehaviorManager:getTodayTopLevel()
	-- body
	local key = self:getTodayKey()
	local uid = UserManager:getInstance().user.uid or "12345"

	local todayTopLevel = CCUserDefault:getIntegerForKey(tostring(key)..tostring(uid), 0)
	if todayTopLevel == 0 then
		todayTopLevel = UserManager:getInstance().user:getTopLevelId()
		CCUserDefault:setIntegerForKey(key, todayTopLevel)
	end 
	return todayTopLevel
end

---------------------------------------------------

-- 回调函数
function UserBehaviorManager:onEnterBackGround(  )
	-- body
	if not self.isCounting then return end
	self:setTodayCacheData()
	self.tempLongestGamingTime = 0
	self.inBackGround = true
end

function UserBehaviorManager:onEnterForeGround(  )
	-- body
	if not self.isCounting then return end
	self.inBackGround = false
	self.data.enterGameCount = self.data.enterGameCount + 1
	-- RemoteDebug:uploadLogWithTag("enterGameCount","加一次 " ..tostring(self.data.enterGameCount) .. debug.traceback())
	
	self:setTodayCacheData()
end

function UserBehaviorManager:firstLogin( )
	-- body
	self.data.enterGameCount = self.data.enterGameCount + 1
	-- RemoteDebug:uploadLogWithTag("enterGameCount","加一次 " ..tostring(self.data.enterGameCount) .. debug.traceback())

end
----------------------------------------------------------

-- 获取计数器当前状态

function UserBehaviorManager:getState( )
	-- body
	return self.isCounting
end

-- 关于今天的标签计算
-- 早：[ 5:00 , 11:00 )
-- 中：[ 11:00 – 17:00 )
-- 晚：[ 17:00 – 23:00 )
-- 深夜：[ 23:00 – 5:00 )
function UserBehaviorManager:getTodayKey( )
	-- body
	local nowTime = Localhost:timeInSec()
	return tostring(time2day(nowTime))
end

-- function UserBehaviorManager:getLevelTag( level )
-- 	-- body
-- 	local userTopLevel = self:getTodayTopLevel()
-- 	local topLevel = NewAreaOpenMgr.getInstance():getLocalTopLevel()
-- 	userTopLevel = level or userTopLevel

-- 	if topLevel == userTopLevel then
-- 		return "full_level"
-- 	elseif topLevel - userTopLevel <= 30 then 
-- 		return "top30"
-- 	else
-- 		local tag = userTopLevel / 100
-- 		return tostring(tag * 100).."-"..tostring(tag*100 + 99)
-- 	end
-- end

function UserBehaviorManager:getTimeTag( )
	-- body
	local time = Localhost:timeInSec()
	local daySceonds = (time + eightHours) % (3600 * 24)
	local tag = model.TimeTag[1]
	local index = 1

	for i,v in ipairs(model.Clock) do 
		if daySceonds <	 v then 
			index = i
			-- printx(16,"getTimeTag",i)
			break
		end
	end

	tag = model.TimeTag[index]
	return tag
end

-- 向后端发送之前的数据
function UserBehaviorManager:trySendCacheData( ... )
	-- body
	local cacheData = self:getAllCacheData()
	local oldCacheData = table.clone(cacheData)

	local todayData = cacheData[self:getTodayKey()]
	cacheData[self:getTodayKey()] = nil

	if isDebug then 
		cacheData = table.clone(require 'zoo.gamePlay.userBehavior.testData')
	end

	local keyCounter = 0
	local theSendData = {}
	for k,v in pairs(cacheData) do 
		if v then 
			local tempData = table.clone(v)
			keyCounter = keyCounter + 1
			tempData["day"] = tonumber(k)
			table.insert(theSendData,tempData)
		end
	end

	-- printx(16,"keyCounter",keyCounter)
	-- RemoteDebug:uploadLogWithTag("UserBehaviorManagerstart",tostring(keyCounter))	
	local uid = UserManager:getInstance().user.uid or "12345"
	local todaykey = self:getTodayKey()

	local todaySend = CCUserDefault:getBoolForKey(tostring(todaykey)..tostring(uid)..tostring(localDataPath), false)

	-- printx(16,"todaySend",todaySend)
	if not todaySend then 
		--成功传给后端清理数据
		local function onSuccess()
			-- body
			self.cacheData = {}
			self:setTodayCacheData(todayData)
			CCUserDefault:setBoolForKey(tostring(todaykey)..tostring(uid)..tostring(localDataPath), true)
		end

		local function onFail( )
			-- body
			self.cacheData = oldCacheData
		end

		local function onCancel( )
			-- body
			self.cacheData = oldCacheData
		end

		-- setTimeOut(function( ... )
		HttpBase:syncPost('syncTagV2DataSource',{
			dailyDataSourceList = theSendData,
			minTodayTopLevel = UserManager:getInstance().user:getTopLevelId(),
		} , onSuccess, onFail, onCancel)
			-- body
		-- end,1)
	end
end

return UserBehaviorManager
