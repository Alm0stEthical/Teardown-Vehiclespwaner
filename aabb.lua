function DrawPoint(point, name)
	local x, y, d = UiWorldToPixel(point)
	if d > 0 then
		UiTranslate(x, y)
		UiAlign("center middle")
		UiImage("ui/common/dot.png")
		UiTranslate(0, 20)
		UiFont("regular.ttf", 20)
		UiText(name)
	end
end

function DrawAABB(pmin, pmax)
	--local pmin = TransformToParentPoint(transf, Vec(0, 0, 0))
	--local pmax = TransformToParentPoint(transf, VecScale(size, 0.1))
	local points = {
		Vec(pmax[1], pmax[2], pmax[3]),
		Vec(pmax[1], pmax[2], pmin[3]),
		Vec(pmax[1], pmin[2], pmax[3]),
		Vec(pmax[1], pmin[2], pmin[3]),
		Vec(pmin[1], pmax[2], pmax[3]),
		Vec(pmin[1], pmax[2], pmin[3]),
		Vec(pmin[1], pmin[2], pmax[3]),
		Vec(pmin[1], pmin[2], pmin[3]),
	}
	DrawLine(points[1], points[2], 1, 1, 1)
	DrawLine(points[1], points[3], 1, 1, 1)
	DrawLine(points[1], points[5], 1, 1, 1)
	DrawLine(points[4], points[2], 1, 1, 1)
	DrawLine(points[4], points[3], 1, 1, 1)
	DrawLine(points[4], points[8], 1, 1, 1)
	DrawLine(points[6], points[2], 1, 1, 1)
	DrawLine(points[6], points[5], 1, 1, 1)
	DrawLine(points[6], points[8], 1, 1, 1)
	DrawLine(points[7], points[3], 0, 0, 1)
	DrawLine(points[7], points[5], 1)
	DrawLine(points[7], points[8], 0, 1)
end

function DrawObbAroundShape(shape)
	local transf = GetShapeWorldTransform(shape)
	local size = Vec(GetShapeSize(shape))
	local pmin = Vec(0, 0, 0)
	local pmax = VecScale(size, 0.1)
	local points = {
		TransformToParentPoint(transf, Vec(pmax[1], pmax[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmax[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmin[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmin[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmax[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmax[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmin[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmin[2], pmin[3])),
	}
	DrawLine(points[1], points[2], 1, 1, 1)
	DrawLine(points[1], points[3], 1, 1, 1)
	DrawLine(points[1], points[5], 1, 1, 1)
	DrawLine(points[4], points[2], 1, 1, 1)
	DrawLine(points[4], points[3], 1, 1, 1)
	DrawLine(points[4], points[8], 1, 1, 1)
	DrawLine(points[6], points[2], 0, 0, 1)
	DrawLine(points[6], points[5], 1)
	DrawLine(points[6], points[8], 0, 1)
	DrawLine(points[7], points[3], 1, 1, 1)
	DrawLine(points[7], points[5], 1, 1, 1)
	DrawLine(points[7], points[8], 1, 1, 1)
end

function GetShapeAABB(shape)
	local transf = GetShapeWorldTransform(shape)
	local size = Vec(GetShapeSize(shape))
	local aabbMin = Vec(9999, 9999, 9999)
	local aabbMax = Vec(-9999, -9999, -9999)
	local pmin = Vec(0, 0, 0)
	local pmax = VecScale(size, 0.1)
	local points = {
		TransformToParentPoint(transf, Vec(pmax[1], pmax[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmax[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmin[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmax[1], pmin[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmax[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmax[2], pmin[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmin[2], pmax[3])),
		TransformToParentPoint(transf, Vec(pmin[1], pmin[2], pmin[3])),
	}
	for i = 1, 3 do
		for j = 1, #points do
			aabbMin[i] = math.min(aabbMin[i], points[j][i])
			aabbMax[i] = math.max(aabbMax[i], points[j][i])
		end
	end
	return aabbMin, aabbMax
end

function GetBodyAABB(body)
	local aabbMin = Vec(9999, 9999, 9999)
	local aabbMax = Vec(-9999, -9999, -9999)
	local shapes = GetBodyShapes(body)
	for j = 1, #shapes do
		local shapeAABBMin, shapeAABBMax = GetShapeAABB(shapes[j])
		for i = 1, 3 do
			aabbMin[i] = math.min(aabbMin[i], shapeAABBMin[i])
			aabbMax[i] = math.max(aabbMax[i], shapeAABBMax[i])
		end
	end
	return aabbMin, aabbMax
end

function GetVehicleAABB(vehicle)
	local aabbMin = Vec(9999, 9999, 9999)
	local aabbMax = Vec(-9999, -9999, -9999)
	-- GetAllVehicleBodies() ~= GetJointedBodies()
	local bodies = GetAllVehicleBodies(GetVehicleBody(vehicle))
	for j = 1, #bodies do
		local bodyAABBMin, bodyAABBMax = GetBodyAABB(bodies[j])
		for i = 1, 3 do
			aabbMin[i] = math.min(aabbMin[i], bodyAABBMin[i])
			aabbMax[i] = math.max(aabbMax[i], bodyAABBMax[i])
		end
	end
	return aabbMin, aabbMax
end

function HighlightDebris(vehicle)
	aabbMin, aabbMax = GetVehicleAABB(vehicle)
	DrawAABB(aabbMin, aabbMax)
	QueryRejectVehicle(vehicle)
	QueryRequire("physical dynamic small")
	local bodies = QueryAabbBodies(aabbMin, aabbMax)
	if #bodies > 0 then
		DebugWatch("Bodies", #bodies)
	end
	for i = 1, #bodies do
		local b = bodies[i]
		DrawBodyHighlight(b, 1)
		DrawBodyOutline(b, 1, 0, 0, 1)
	end
end

function DrawOBB(transf, size)
	local points = {
		TransformToParentPoint(transf, Vec(size[1], size[2], size[3])),
		TransformToParentPoint(transf, Vec(size[1], size[2], 0)),
		TransformToParentPoint(transf, Vec(size[1], 0, size[3])),
		TransformToParentPoint(transf, Vec(size[1], 0, 0)),
		TransformToParentPoint(transf, Vec(0, size[2], size[3])),
		TransformToParentPoint(transf, Vec(0, size[2], 0)),
		TransformToParentPoint(transf, Vec(0, 0, size[3])),
		TransformToParentPoint(transf, Vec(0, 0, 0)),
	}
	DrawLine(points[1], points[2], 1, 1, 1)
	DrawLine(points[1], points[3], 1, 1, 1)
	DrawLine(points[1], points[5], 1, 1, 1)
	DrawLine(points[4], points[2], 1, 1, 1)
	DrawLine(points[4], points[3], 1, 1, 1)
	DrawLine(points[4], points[8], 1, 1, 1)
	DrawLine(points[6], points[2], 0, 0, 1)
	DrawLine(points[6], points[5], 1)
	DrawLine(points[6], points[8], 0, 1)
	DrawLine(points[7], points[3], 1, 1, 1)
	DrawLine(points[7], points[5], 1, 1, 1)
	DrawLine(points[7], points[8], 1, 1, 1)
end

function GetAABB(transf, size)
	local aabbMin = Vec(9999, 9999, 9999)
	local aabbMax = Vec(-9999, -9999, -9999)
	local points = {
		TransformToParentPoint(transf, Vec(size[1], size[2], size[3])),
		TransformToParentPoint(transf, Vec(size[1], size[2], 0)),
		TransformToParentPoint(transf, Vec(size[1], 0, size[3])),
		TransformToParentPoint(transf, Vec(size[1], 0, 0)),
		TransformToParentPoint(transf, Vec(0, size[2], size[3])),
		TransformToParentPoint(transf, Vec(0, size[2], 0)),
		TransformToParentPoint(transf, Vec(0, 0, size[3])),
		TransformToParentPoint(transf, Vec(0, 0, 0)),
	}
	for i = 1, 3 do
		for j = 1, #points do
			aabbMin[i] = math.min(aabbMin[i], points[j][i])
			aabbMax[i] = math.max(aabbMax[i], points[j][i])
		end
	end
	return aabbMin, aabbMax
end

function QueryObbBodiesAroundShape(shape)
	local shape_tr = GetShapeWorldTransform(shape)
	local shape_size = VecScale(Vec(GetShapeSize(shape)), 0.1)
	return QueryObbBodies(shape_tr, shape_size)
end

function QueryObbShapes(transf, size)
	local res = {}
	local trigger_xml = "<trigger type='box' size='" .. size[1] .. " " .. size[2] .. " " .. size[3] .. "'/>"
	local spawned = Spawn(trigger_xml, transf)
	local trigger = spawned[1]
	local shapes = QueryAabbShapes(GetTriggerBounds(trigger))
	for i = 1, #shapes do
		if IsBodyInTrigger(trigger, shapes[i]) then
			table.insert(res, shapes[i])
		end
	end
	Delete(trigger)
	return res
end

function QueryObbBodies(transf, size)
	local res = {}
	local trigger_xml = "<trigger type='box' size='" .. size[1] .. " " .. size[2] .. " " .. size[3] .. "'/>"
	local spawned = Spawn(trigger_xml, transf)
	local trigger = spawned[1]
	local bodies = QueryAabbBodies(GetTriggerBounds(trigger))
	for i = 1, #bodies do
		if IsBodyInTrigger(trigger, bodies[i]) then
			table.insert(res, bodies[i])
		end
	end
	Delete(trigger)
	return res
end
