local ActBoardCollectItemViewManager = class()

require('zoo.panel.store.ClassUtils'):makeSingleton(ActBoardCollectItemViewManager)
require('zoo.panel.store.ClassUtils'):makeObserver(ActBoardCollectItemViewManager)

function ActBoardCollectItemViewManager:ctor( ... )
	-- body
	self.freeSpace = {
		{0, UIHelper.worldSize.width},
	}

end

function ActBoardCollectItemViewManager:onActGameBoardViewInited()
	self:reset()
end

function ActBoardCollectItemViewManager:reset( ... )

	self.freeSpace = {
		{0, UIHelper.worldSize.width},
	}

end

function ActBoardCollectItemViewManager:alloc( width )
	table.sort((self.freeSpace), function ( a, b )
		return a[1] + a[2] > b[1] + b[2] 
	end)

	local allocedSpace 

	for i = 1, #(self.freeSpace) do
		if (self.freeSpace)[i][2] >= width then
			allocedSpace = {
				(self.freeSpace)[i][1] + (self.freeSpace)[i][2] - width,
				width,
			}
			(self.freeSpace)[i][2] = (self.freeSpace)[i][2] - width
			break
		end
	end

	if allocedSpace then
		return allocedSpace
	end
end

function ActBoardCollectItemViewManager:free( allocedSpace )
	table.insert((self.freeSpace), allocedSpace)
	
	local unionSomething = true

	while unionSomething do
		unionSomething = false

		table.sort((self.freeSpace), function ( a, b )
			return a[1] < b[1] 
		end)

		for i = 1, (#(self.freeSpace)) - 1 do
			local _this = (self.freeSpace)[i]
			local _next = (self.freeSpace)[i+1]

			if _this[1] + _this[2] >= _next[1] then
				unionSomething = true

				table.remove((self.freeSpace), i+1)
				table.remove((self.freeSpace), i)
				table.insert((self.freeSpace), {
					_this[1],
					_this[2] + _next[2],
				})
				break
			end
		end

	end


end

function ActBoardCollectItemViewManager:dump( ... )
	printx(61, table.tostring((self.freeSpace)))
end

function ActBoardCollectItemViewManager:test( ... )
	local allocer = ActBoardCollectItemViewManager.new()
	local item1 =  allocer:alloc(100)
	printx(61, 'item1', table.tostring(item1))

	local item2 =  allocer:alloc(200)
	printx(61, 'item2', table.tostring(item2))

	allocer:free(item1)

	local item3 =  allocer:alloc(50)
	printx(61, 'item3', table.tostring(item3))

	allocer:dump()

	allocer:free(item2)
	allocer:free(item3)

	allocer:dump()
end

return ActBoardCollectItemViewManager