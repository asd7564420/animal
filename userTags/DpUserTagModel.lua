local DpUserTagModel = {}

local localDataKey = "DPTAG"
local currLocalDataMap = "DPTAG"

DpTagId = {
	test_tag = 12345 ,
	active_tag = 25 ,
	active_will_lose_tag = 129 ,
	active_will_lose_tag_for_upload_replay = 133 , 
	active_pass_abiility = 134 , 
	active_will_lose_test_a_rule = "G28" ,
	active_will_lose_test_b_rule = "G52" ,
}

DpTagValue = {
	[DpTagId.active_tag] = {
		kLowActive = "LowActive",
		kNormalActive = "NormalActive",
		kHighActive = "HighActive",
	},

	[DpTagId.active_will_lose_tag] = {
		kWillLose = "WillLose",
		kNormalActive = "NormalActive",
		kNoData = "NoData",
	},

	[DpTagId.active_will_lose_tag_for_upload_replay] = {
		kWillLose = "WillLoseForUploadReplay",
		kNoData = "NoData",
	},
	[DpTagId.active_pass_abiility] = {
		-- 低过关能力 LowPassAbility  中过关能力 NormalPassAbility  高过关能力HighPassAbility
		kLowPassAbility = "LowPassAbility",
		kNormalPassAbility = "NormalPassAbility",
		kHighPassAbility = "HighPassAbility",
	},
	[DpTagId.active_will_lose_test_a_rule] = {
		kPass = "pass",
		kFail = "fail",
		kError = "error",
		kNoData = "NoData",
	},
	[DpTagId.active_will_lose_test_b_rule] = {
		kPass = "pass",
		kFail = "fail",
		kError = "error",
		kNoData = "NoData",
	}

}

TagValueOutOfTime = "LocalTagOutOfTime"


local function getCurrUid()
	return UserManager:getInstance():getUID() or "12345"
end

local function getLocalFilePath()
	return localDataKey .. "_" .. tostring(getCurrUid()) .. ".ds"
end

function DpUserTagModel:init()
	if not self.localData then
		local localData = Localhost:readFromStorage( getLocalFilePath() )
		
		if not localData then
			localData = self:getDefaultData()
		end

		self.localData = localData
	end
end

function DpUserTagModel:updateTags( resp , source )

	if not self.localData then
		local localData = Localhost:readFromStorage( getLocalFilePath() )
		
		if not localData then
			localData = self:getDefaultData()
		end

		self.localData = localData
	end

	local dpTags = resp.dpTags

	if not dpTags then return end

	if source == UserTagDCSource.kLaunch then
		for k , v in pairs(dpTags) do
			-- printx( 1 , "TAG   " , v.tagId , type(v.tagId) ,  table.tostring(v))
			local cloneV = table.clone(v)
			cloneV.localUpdateTime = Localhost:timeInSec()
			self.localData.tagMap[ tostring(v.tagId) ] = cloneV
		end

		self:flushLocalData()
	end

end

function DpUserTagModel:getTagValue( tagId )
	tagId = tostring(tagId)
	if self.localData.tagMap[tagId] then
		local obj = self.localData.tagMap[tagId]
		local nowTime = Localhost:timeInSec()
		if nowTime and obj.localUpdateTime and nowTime - obj.localUpdateTime < 3600 * 24 * 7 then
			return obj.tagMappedValue or 0
		else
			return TagValueOutOfTime
		end
	end
	return 0
end

function DpUserTagModel:getTagOriginValue( tagId )
	tagId = tostring(tagId)
	if self.localData.tagMap[tagId] then
		return self.localData.tagMap[tagId].tagSource or 0
	end
	return 0
end

function DpUserTagModel:getDefaultData()
	local localData = {}

	localData.ver = 1

	localData.tagMap = {}

	return localData
end

function DpUserTagModel:flushLocalData()
	if self.localData then
		Localhost:writeToStorage(self.localData, getLocalFilePath() )
	end
end

return DpUserTagModel