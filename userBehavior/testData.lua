-- @Author: gang.niu
-- @Date:   2020-01-03 15:26:05
-- @Last Modified by:   gang.niu
-- @Last Modified time: 2020-02-06 15:01:00

local model = require 'zoo.gamePlay.userBehavior.UserBehaviorModel'

function makeFakeData( ... )
	-- body
	local data = {}
	local todayData = {}
	data.longestGamingTime =  10
	data.todayGamingTime =  10
	data.enterGameCount = 10

	data.timeByTag = {}
	for i,v in pairs(model.TimeTag) do 
		data.timeByTag[v] = todayData.timeByTag and todayData.timeByTag[v] or 10
	end
	data.minTopLevel = 10

	return data
end

local cacheData = {
	["18297"] = makeFakeData(),
	["18296"] = makeFakeData(),

}

return cacheData