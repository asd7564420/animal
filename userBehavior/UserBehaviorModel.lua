-- @Author: gang.niu
-- @Date:   2020-01-02 17:28:26
-- @Last Modified by:   gang.niu
-- @Last Modified time: 2020-01-03 10:15:11

UserBehaviorModel = {}

UserBehaviorModel.Clock = table.const{
	[1] = 5 * 3600,
	[2] = 11 * 3600,
	[3] = 17 * 3600,
	[4] = 23 * 3600,
}

UserBehaviorModel.TimeTag = table.const{
	[1] = "midnight",
	[2] = "morning",
	[3] = "noon",
	[4] = "evening",
}

return UserBehaviorModel
-- UserBehaviorModel: