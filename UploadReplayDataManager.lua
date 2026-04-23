local UploadReplayDataManager = {}

UploadReplayDataManager.maxReplayNum = 300

ReplayUploadReason = {
	kUnknow = 0 ,
	kUserExtendFlag = 11 ,
	kDpUserTag = 12 ,
	kScreenShot = 13 ,
	weekly_buy_dazhao = 14 ,
}

local logDataFilePath = "ulrdLog"
local logDataFileKey = "datas"

local function getCurrUid()
	return UserManager:getInstance():getUID() or "12345"
end

local function getCurrUdid()
	return MetaInfo:getInstance():getUdid() or "hasNoUdid"
end

function UploadReplayDataManager:init()

	if not self.logData then
		self.logData = self:getLogData()
	end

	self.uploadingCountFlag = 0

	local needReuploading = false

	local newList = {}
	for k,v in ipairs(self.logData.logList) do
		if self.logData.logMap[v] ~= "watingForUploading" then 
			self.uploadingCountFlag = self.uploadingCountFlag + 1
			self.logData.logMap[v] = "reUploading"
			needReuploading = true
			-- printx( 1 , "reUploading ---------- " , v )
		end
	end

	if needReuploading then

		local replayData = ReplayDataManager:readCheckReplayData()
		local datalist = {}

		if replayData and replayData.datas and #replayData.datas > 0 then
			for k,v in ipairs(replayData.datas) do
				local dataKey = tostring(v.idStr) .. "_" .. tostring( #v.replaySteps )
				if self.logData.logMap[dataKey] == "reUploading" then
					self.logData.logMap[dataKey] = "uploading_" .. tostring(self.uploadingCountFlag)
					table.insert( datalist , v )
				end
			end
		end

		local newList = {}
		for k,v in ipairs(self.logData.logList) do
			if self.logData.logMap[v] == "reUploading" then --原始replay数据已经被删除了，不可能被回传了，删掉
				self.logData.logMap[v] = nil
			else
				table.insert( newList , v )
			end
		end
		self.logData.logList = newList

		LocalBox:setData( logDataFileKey , self.logData , logDataFilePath )

		local currFlag = self.uploadingCountFlag
		local function uploadCallback()
			self:onDeduplicationUploadCallback( currFlag )
		end

		if #datalist > 0 then
			self:uploadReplay( datalist , 2 , ReplayUploadReason.kDpUserTag , uploadCallback )
		end
	end
end

--targetType:上传目标，1上传BI，2上传opLog回传系统，3两者都传
function UploadReplayDataManager:uploadReplay( replayDatas , targetType , reason , callback )
	-- printx( 1 , "UploadReplayDataManager:uploadReplay  ++++++++++  " , targetType , reason)
	local needCallbackCount = 0
	local currCallbackCount = 0

	local function onCallback()
		
		currCallbackCount = currCallbackCount + 1
		
		if currCallbackCount >= needCallbackCount then
			if callback then callback() end
		end
	end

	local datalist = {}
	for k,v in ipairs( replayDatas ) do
		local tableStr = table.serialize( v )
		table.insert( datalist , HeMathUtils:base64Encode(tableStr, string.len(tableStr)) )
	end


	local function sendToOplogServer()
		SyncManager.getInstance():addAfterSyncHttp( 
				"uploadReplay" , 
				{datas = datalist , reason = tostring(reason)} , 
				onCallback , 
				{allowMergers = false} 
			)
		SyncManager:getInstance():syncLite()
	end

	local function sendToBI()

		for k2,v2 in ipairs( replayDatas ) do
			DcUtil:uploadReplayData( "ReplayUpload_New" , 
				datalist[k] ,
				v2.info , v2.ver , v2.level , v2.passed , v2.score , v2.currTime , #v2.replaySteps , {reason = reason} )
		end

		onCallback()
	end


	if targetType == 1 then
		needCallbackCount = 1
		sendToBI()
	elseif targetType == 2 then
		needCallbackCount = 1
		sendToOplogServer()
	elseif targetType == 3 then
		needCallbackCount = 2
		sendToOplogServer()
		sendToBI()
	end
end

--上传本地全部录像数据（最多300条）
--targetType:上传目标，1上传BI，2上传opLog回传系统，3两者都传
function UploadReplayDataManager:uploadAllLocalReplay( targetType , reason )
	if targetType == 0 then return end
	local replaydatas = self:createUploadReplayData( 0 , false )

	if replaydatas then
		self:uploadReplay( replaydatas , targetType , reason )
		return true
	end
	return false
end

--上传本地全部录像中包含指定关卡id的数据（最多300条）
--targetType:上传目标，1上传BI，2上传opLog回传系统，3两者都传
function UploadReplayDataManager:uploadReplayByLevelId( levelId , targetType , reason )
	if targetType == 0 then return end
	local replaydatas = self:createUploadReplayData( levelId , false )

	if replaydatas then
		self:uploadReplay( replaydatas , targetType , reason )
		return true
	end
	return false
end

--去重上传，只上传新增数据
--targetType:上传目标，1上传BI，2上传opLog回传系统，3两者都传
function UploadReplayDataManager:uploadReplayByDeduplication( targetType , reason )

	-- printx( 1 , "uploadReplayByDeduplication !!!!!!!" , targetType , reason , debug.traceback() )

	self.uploadingCountFlag = self.uploadingCountFlag + 1

	if not self.logData then
		self.logData = self:getLogData()
	end
	-- printx( 1 , "uploadReplayByDeduplication self.logData" , table.tostring(self.logData) )

	local replayData = ReplayDataManager:readCheckReplayData()
	local datalist = {}

	if replayData and replayData.datas and #replayData.datas > 0 then
		for k,v in ipairs(replayData.datas) do

			local dataKey = tostring(v.idStr) .. "_" .. tostring( #v.replaySteps )
			if self.logData.logMap[dataKey] == "watingForUploading" then
				-- printx( 1 , "uploadReplayByDeduplication ---------- " , dataKey )
				table.insert( datalist , v )
				self.logData.logMap[dataKey] = "uploading_" .. tostring( self.uploadingCountFlag )
			end
		end
	end

	local currFlag = self.uploadingCountFlag
	local function uploadCallback()
		self:onDeduplicationUploadCallback( currFlag )
	end

	-- printx( 1 , "UploadReplayDataManager:uploadReplayByDeduplication  targetType , reason :" , targetType , reason)
	if #datalist > 0 then
		self:uploadReplay( datalist , targetType , reason , uploadCallback )
		return true
	else
		return false
	end
end

function UploadReplayDataManager:onDeduplicationUploadCallback( currFlag )
	local newList = {}
	for k,v in ipairs(self.logData.logList) do
		if self.logData.logMap[v] == "uploading_" .. tostring(currFlag) then 
			self.logData.logMap[v] = nil
			-- printx( 1 , "onDeduplicationUploadCallback  remove ---------- " , v )
		else
			table.insert( newList , v )--确保只删除上一次发出请求的数据
		end
	end
	self.logData.logList = newList

	LocalBox:setData( logDataFileKey , self.logData , logDataFilePath )
end

function UploadReplayDataManager:addLogDataFlag( dataKey )
	
	if not self.logData then
		self.logData = self:getLogData()
	end

	self.logData.logMap[dataKey] = "watingForUploading"
	table.insert( self.logData.logList , dataKey )
	-- printx( 1 , "addLogDataFlag  add ---------- " , dataKey )

	while #self.logData.logList > self.maxReplayNum do
		local deleteValue = table.remove( self.logData.logList , 1 )
		self.logData.logMap[deleteValue] = nil
	end

	LocalBox:setData( logDataFileKey , self.logData , logDataFilePath )
end

function UploadReplayDataManager:getLogData()
	local logData = LocalBox:getData( logDataFileKey , logDataFilePath )
	if not logData then
		logData = {}
		logData.logMap = {}
		logData.logList = {}
		-- printx( 1 , "UploadReplayDataManager:getLogData !!!!!!!!! create new !!!!!!!!!" , debug.traceback() )
	end
	return logData
end

function UploadReplayDataManager:decodeUserExtendFlag( userExtendFlag )
	userExtendFlag = userExtendFlag or 0
	userExtendFlag = tonumber(userExtendFlag)

	local cNum = 1000000000
	if userExtendFlag >= cNum then

		local targetType = math.floor( userExtendFlag / cNum )
		local levelId = math.floor( ( userExtendFlag - (cNum * targetType) ) / 100 )

		return targetType , levelId
	else
		return userExtendFlag , 0
	end
end

function UploadReplayDataManager:createUploadReplayData( levelId , deduplication )

	if not levelId then levelId = 0 end

	local datalist = {}
	local replayData = nil
	local uploadResult = 0

	local function doCreateData()

		replayData = ReplayDataManager:readCheckReplayData()

		if not replayData then
			datalist = nil
			return nil
		end

		if tostring(replayData.udid) ~= tostring(getCurrUdid()) then
			datalist = nil
			return nil
		end


		if replayData and replayData.datas and #replayData.datas > 0 then
			for k,v in ipairs(replayData.datas) do

				local passlogic = false
				if levelId and levelId > 0 then
					if v.level ~= levelId then
						passlogic = true
					end
				end

				if not passlogic then
					-- local tableStr = table.serialize( v )
					-- table.insert( datalist , HeMathUtils:base64Encode(tableStr, string.len(tableStr)) )
					table.insert( datalist , v )
				end
			end
		end
	end
	

	pcall(doCreateData)

	return datalist
end


function UploadReplayDataManager:checkUploadByDpTags()

	-- printx( 1 , "checkUploadByDpTags -------- " , debug.traceback() )
	
	local will_lose_tag = UserTagManager:getDpTagValue( DpTagId.active_will_lose_tag_for_upload_replay )
	local tagValueMap = DpTagValue[DpTagId.active_will_lose_tag_for_upload_replay]

	-- printx( 1 , "will_lose_tag :" , will_lose_tag )

	if will_lose_tag and will_lose_tag == tagValueMap.kWillLose then
		-- printx( 1 , "checkUploadByDpTags -->  uploadReplayByDeduplication  ReplayUploadReason.kDpUserTag =" , ReplayUploadReason.kDpUserTag )
		self:uploadReplayByDeduplication( 2 , ReplayUploadReason.kDpUserTag )
	end
end



return UploadReplayDataManager