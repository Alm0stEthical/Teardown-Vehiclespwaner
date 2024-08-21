#include "spawner.lua"

function DeleteObject()
	if delete_shape ~= 0 then
		DrawShapeOutline(delete_shape, 1, 0, 0, 0.5)
	end

	if GetPlayerVehicle() == 0 and InputPressed("delete") then
		local camera_tr = GetCameraTransform()
		local camera_fwd = TransformToParentVec(camera_tr, Vec(0, 0, -1))
		QueryRequire("physical dynamic large")
		local hit, _, _, shape = QueryRaycast(camera_tr.pos, camera_fwd, 10)
		if hit and delete_shape == 0 then
			delete_shape = shape
			return
		end
		if hit and delete_shape == shape then
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
		delete_shape = 0
	end
end

function init()
	delete_shape = 0
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
