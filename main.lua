#include "spawner.lua"

-- Constants
local DELETE_RAYCAST_DISTANCE = 10
local DELETE_OUTLINE_COLOR = {1, 0, 0, 0.5}

function DeleteObject()
	-- Highlight the shape that will be deleted
	if gDeleteShape ~= 0 then
		DrawShapeOutline(gDeleteShape, DELETE_OUTLINE_COLOR[1], DELETE_OUTLINE_COLOR[2], DELETE_OUTLINE_COLOR[3], DELETE_OUTLINE_COLOR[4])
	end

	-- Only allow deletion when not in a vehicle
	if GetPlayerVehicle() == 0 and InputPressed("delete") then
		local cameraTransform = GetCameraTransform()
		local cameraForward = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
		QueryRequire("physical dynamic large")
		local hit, _, _, shape = QueryRaycast(cameraTransform.pos, cameraForward, DELETE_RAYCAST_DISTANCE)
		
		-- First click: select the shape
		if hit and gDeleteShape == 0 then
			gDeleteShape = shape
			return
		end
		
		-- Second click on same shape: delete it
		if hit and gDeleteShape == shape then
			local body = GetShapeBody(shape)
			local vehicle = GetBodyVehicle(body)
			
			if vehicle ~= 0 then
				Delete(vehicle)
			else
				if body ~= GetWorldBody() then
					Delete(body)
				else
					Delete(shape)
				end
			end
		end
		
		gDeleteShape = 0
	end
end

function init()
	gDeleteShape = 0
	spawner_init()
end

function tick(dt)
	spawner_tick(dt)
	DeleteObject()
end

function update(dt)
end

function draw()
	spawner_draw()
end
