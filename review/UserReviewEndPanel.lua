
local UIHelper = require 'zoo.panel.UIHelper'

local UserReviewEndPanel = class(BasePanel)

function UserReviewEndPanel:create(showMode)
    local panel = UserReviewEndPanel.new()
    panel:init(showMode)
    return panel
end

function UserReviewEndPanel:init(showMode)
	local ui = UIHelper:createUI('ui/user_review.json', 'user_review.ui/panel')
	UIUtils:adjustUI(ui, 0, nil, nil, 1764)
	BasePanel.init(self, ui)

    UIUtils:setTouchHandler(self.ui:getChildByPath('closeBtn'), function()
        self:onCloseBtnTapped()
    end)

	UIUtils:setTouchHandler(self.ui:getChildByPath('btn'), function()
        self:onReplayAgainBtnTapped()
    end)




    local holder = self.ui:getChildByPath('holder')
    UIHelper:loadUserHeadIcon(holder, UserManager:getInstance().profile, false)

    local nameLabel = self.ui:getChildByPath('name')
    local name = UserManager:getInstance().profile:getDisplayName()
	name = TextUtil:ensureTextWidth( tostring(name), nameLabel:getFontSize(), nameLabel:getDimensions() )
    nameLabel:setString(name)

    local invodeCodeLabel = self.ui:getChildByPath('invodeCode')
    invodeCodeLabel:setString('消消乐号：' .. UserManager:getInstance():getInviteCode())
    

    if showMode then
    	self.ui:getChildByPath('btn'):setVisible( false )
    	holder:setVisible( false )
    	nameLabel:setVisible( false )
    	invodeCodeLabel:setVisible( false )
    	self.ui:getChildByPath('closeBtn'):setVisible( false )

    	local logo = self.ui:getChildByPath('logo')
    	logo:setPositionY( logo:getPositionY() + 350 )

    	UIUtils:setTouchHandler(logo, function()
	        self:onCloseBtnTapped()
	    end)
    end
end

function UserReviewEndPanel:_close()
	self.allowBackKeyTap = false
	PopoutManager:sharedInstance():remove(self)
end

function UserReviewEndPanel:popout()
	PopoutManager:sharedInstance():add(self, true)
	self.allowBackKeyTap = true
end

function UserReviewEndPanel:onReplayAgainBtnTapped( ... )
    self:notify('replayAgain')
    self:_close()
end


function UserReviewEndPanel:onCloseBtnTapped( ... )
    self:notify('quitReplay')
    self:_close()
end

function UserReviewEndPanel:setDelegate( delegate )
	self.delegate = delegate
end

function UserReviewEndPanel:notify( message, ... )
	if self.isDisposed then return end
	if self.delegate then
		self.delegate:onMenuCommand(self, message, ...)
	end
end

function UserReviewEndPanel:setSavedPath( savedPath )
	if self.isDisposed then return end
	if not savedPath then
		return
	end

	local savedInfo = TextField:create('视频保存在' .. savedPath .. '', "Helvetica", 36, CCSizeMake(720, 0), kCCTextAlignmentCenter)
	self.ui:addChild(savedInfo)
	savedInfo:setAnchorPoint(ccp(0.5, 1))
	savedInfo:setPositionX(480)
	savedInfo:setPositionY(self.ui:getChildByPath('logo'):getPositionY() - self.ui:getChildByPath('logo'):getContentSize().height )
end


return UserReviewEndPanel
