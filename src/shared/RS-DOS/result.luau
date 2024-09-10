--[[
Name: result.luau
Description: Simple rust like Result object to better identify success/errors 

Creator: SquelchMaster
Date: 08/05/2024 
]]

local types = require(script.Parent.types)

return {
	ok = function<T, E>(value: T): types.Result<T, E>
		return {value = value, type = 'ok'}
	end,

	err = function<T, E>(err: E): types.Result<T, E>
		return {err = err, type = 'err'}
	end
}

-- return {
-- 	ok = function<T>(result: T): Types.Result<T, nil>
-- 		return {
-- 			ok = function() return result; end,
-- 			err = function() return end
-- 		}
-- 	end,
	
-- 	err = function<E>(err: E): Types.Result<nil, E>
-- 		return {
-- 			ok = function() return end,
-- 			err = function() return err; end
-- 		}
-- 	end,
-- }