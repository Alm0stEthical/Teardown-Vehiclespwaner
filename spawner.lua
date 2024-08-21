#include "common.lua"

--Spawn state
spawnUi = false
spawnUiScale = 0
spawnPlacement = false
spawnEntities = nil
spawnOffset = nil
spawnRadius = 0
spawnDist = 3.0
spawnRot = 0
spawnPreviousTool = ""
spawnFile = ""

--Currently selected source and type
gSelectedSource = ""
gSelectedType = ""

--Raw list of spawnable items from all mods
gSpawnList = {} -- name, type, path, mod

--Filtered, sorted lists to display in UI
gSources = {} -- name, mod, category, enabled, visible
gTypes = {}   -- name, visible
gItems = {}   -- name, type, mod, path, visible

--Internal state
gFilterText = ""
gNeedRefresh = true
gSelectVisible = false
gFocusText = false
gScrollToVisibleItem = false
gSetShortcut = false

gHoverType = ""
gHoverId = ""

function trim(s)
    local n = string.find(s, "%S")
    return n and string.match(s, ".*%S", n) or ""
end

Vehicles = {}

DEFAULT_MENU_KEY = "X"

function spawner_init()
    SetInt("savegame.mod.tuxedium", GetInt("savegame.mod.tuxedium") + 1)

    if GetString("savegame.mod.hotkey") == "" then
        SetString("savegame.mod.hotkey", DEFAULT_MENU_KEY)
    end

    local types = {}

    -- Dynamically include any available mod rather than a hardcoded path
    local modKeys = ListKeys("mods.available")
    for i = 1, #modKeys do
        local mod = modKeys[i]
        if HasKey("mods.available." .. mod) then
            local ids = ListKeys("spawn." .. mod)
            for j = 1, #ids do
                local tmp = "spawn." .. mod .. "." .. ids[j]
                local n = GetString(tmp)
                local p = GetString(tmp .. ".path")
                local t = "Other"
                local s = string.find(n, "/", 1, true)
                if s and s > 1 then
                    t = string.sub(n, 1, s - 1)
                    n = string.sub(n, s + 1, string.len(n))
                end
                if n == "" then
                    n = "Unnamed"
                end
                t = trim(t)
                local found = false
                for k = 1, #types do
                    if string.lower(types[k]) == string.lower(t) then
                        t = types[k]
                        found = true
                        break
                    end
                end
                if not found then
                    types[#types + 1] = t
                end

                local item = {}
                item.name = n
                item.type = t
                item.path = p
                item.mod = mod
                gSpawnList[#gSpawnList + 1] = item
            end
        else
            DebugPrint("Vehicle Spawner Mod: ERROR! failed to find mod path for " .. mod)
        end
    end
end


function isSourceValid(mod)
    -- Allow any mod source regardless of its origin
    return not GetBool("savegame.spawn.disabled." .. mod)
end

function isTypeValid(type)
    --return gSelectedType == type
    return true
end

function matchName(name)
    if gFilterText == "" then
        return true
    else
        return string.find(string.lower(name), string.lower(gFilterText))
    end
end

function refresh()
    -- Sources
    gSources = {}
    for i = 1, #gSpawnList do
        local index = 0
        local mod = gSpawnList[i].mod
        for j = 1, #gSources do
            if gSources[j].mod == mod then
                index = j
                break
            end
        end
        if index == 0 then
            local source = {}
            source.name = GetString("mods.available." .. mod .. ".listname")
            source.mod = mod
            source.category = "" -- Removed category assignment based on source
            source.enabled = not GetBool("savegame.spawn.disabled." .. mod)
            source.visible = false
            gSources[#gSources + 1] = source
            index = #gSources
        end
        if gSources[index].visible == false and gSources[index].enabled then
            if matchName(gSpawnList[i].name) or matchName(gSpawnList[i].type) or matchName(gSources[index].name) then
                gSources[index].visible = true
            end
        end
    end
    table.sort(
        gSources,
        function(a, b)
            return a.name < b.name
        end
    )

    -- This happens when altering the search field
    if gSelectVisible then
        local alreadyVisible = false
        for i = 1, #gSources do
            if gSources[i].mod == gSelectedSource and gSources[i].visible then
                alreadyVisible = true
                break
            end
        end
        if not alreadyVisible then
            gSelectedSource = ""
        end
    end

    -- Types
    gTypes = {}
    for i = 1, #gSpawnList do
        if isSourceValid(gSpawnList[i].mod) then
            local name = gSpawnList[i].type
            local index = 0
            for j = 1, #gTypes do
                if gTypes[j].name == name then
                    index = j
                    break
                end
            end
            if index == 0 then
                local typ = {}
                typ.name = name
                typ.visible = false
                gTypes[#gTypes + 1] = typ
                index = #gTypes
            end
            if not gTypes[index].visible then
                if matchName(gSpawnList[i].name) or matchName(gTypes[index].name) then
                    gTypes[index].visible = true
                end
            end
        end
    end
    table.sort(
        gTypes,
        function(a, b)
            return a.name < b.name
        end
    )

    local found = false
    for i = 1, #gTypes do
        if gTypes[i].name == gSelectedType then
            found = true
            break
        end
    end
    if not found then
        if #gTypes > 0 then
            gSelectedType = gTypes[1].name
        else
            gSelectedType = ""
        end
        gNeedRefresh = true
    end

    if gSelectVisible then
        local alreadyVisible = false
        for i = 1, #gTypes do
            if gTypes[i].name == gSelectedType and gTypes[i].visible then
                alreadyVisible = true
                break
            end
        end
        -- If current selected is not visible, select first visible
        if not alreadyVisible then
            for i = 1, #gTypes do
                if gTypes[i].visible then
                    gSelectedType = gTypes[i].name
                    break
                end
            end
        end
    end

    -- Items
    gItems = {}
    for i = 1, #gSpawnList do
        if isSourceValid(gSpawnList[i].mod) and isTypeValid(gSpawnList[i].type) then
            local item = {}
            item.name = gSpawnList[i].name
            item.type = gSpawnList[i].type
            item.mod = gSpawnList[i].mod
            item.path = gSpawnList[i].path
            item.visible = matchName(gSpawnList[i].name)
            gItems[#gItems + 1] = item
        end
    end
    table.sort(
        gItems,
        function(a, b)
            return a.name < b.name
        end
    )

    for i = 1, #gItems do
        if not Vehicles[gItems[i].name] then
            Vehicles[gItems[i].name] = { categ = "", path = "" }
        end
        Vehicles[gItems[i].name].categ = gItems[i].type
        Vehicles[gItems[i].name].path = gItems[i].path
    end

    gScrollToVisibleItem = true
    gSelectVisible = false
end

function getRotation()
    local fwd = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1))
    fwd[2] = 0
    fwd = VecNormalize(fwd)
    local angle = math.atan2(-fwd[3], fwd[1]) * 180.0 / math.pi
    return QuatEuler(0, angle + spawnRot, 0)
end

function spawner_tick(dt)
    if spawnPlacement then
        SetBool("game.input.locktool", true)
        SetBool("game.disablepause", true)
        SetBool("game.disableinteract", true)

        spawnDist = clamp(spawnDist + InputValue("mousewheel"), 2, 8 + spawnRadius)

        local t = GetCameraTransform()
        t.pos = VecAdd(t.pos, TransformToParentVec(t, Vec(0, 0, -spawnDist)))
        t.rot = getRotation()

        local touching = false
        for i = 1, #spawnEntities do
            local e = spawnEntities[i]
            if spawnOffset[i] then
                local wt = TransformToParentTransform(t, spawnOffset[i])
                local q = 0.25
                if GetEntityType(e) == "body" then
                    local bt = GetBodyTransform(e)
                    local it = Transform(VecLerp(bt.pos, wt.pos, q), QuatSlerp(bt.rot, wt.rot, q))
                    SetBodyTransform(e, it)
                    SetBodyVelocity(e, Vec(0, 0, 0))
                    SetBodyAngularVelocity(e, Vec(0, 0, 0))
                end
            end
            if GetEntityType(e) == "shape" then
                local overlap = QueryAabbShapes(GetShapeBounds(e))
                for j = 1, #overlap do
                    local o = overlap[j]
                    local valid = true
                    for k = 1, #spawnEntities do
                        if o == spawnEntities[k] then
                            valid = false
                            break
                        end
                    end
                    if valid then
                        if IsShapeTouching(e, o) then
                            touching = true
                            break
                        end
                    end
                end
            end
        end
        if touching then
            for i = 1, #spawnEntities do
                local e = spawnEntities[i]
                if GetEntityType(e) == "shape" then
                    DrawShapeOutline(e, 1, 0, 0, 1)
                end
            end
        end
        if InputPressed("usetool") then
            for i = 1, #spawnEntities do
                local e = spawnEntities[i]
                if GetEntityType(e) == "shape" then
                    SetShapeCollisionFilter(e, 1, 255)
                end
            end
            spawnPlacement = false
            if InputDown("shift") then
                local oldDist = spawnDist
                local oldRot = spawnRot
                spawn(spawnFile)
                spawnDist = oldDist
                spawnRot = oldRot
            end
            SetInt("savegame.mod.tuxedium", GetInt("savegame.mod.tuxedium") + 1)
        end
        if InputDown("grab") then
            SetBool("game.player.disableinput", true)
            spawnRot = spawnRot + InputValue("camerax") * 50
        end
        if InputPressed("pause") then
            spawnAbort()
        end
        if not spawnPlacement then
            SetString("game.player.tool", spawnPreviousTool)
        end
    end

    --[[if not spawnUi and spawnEnabled() then
        if PauseMenuButton("Vehicle Spawner") then
            spawnUi = true
        end
    end]]

    if spawnUi and InputDown("ctrl") and InputPressed("f") then
        gFocusText = true
    end

    if gNeedRefresh then
        refresh()
        gNeedRefresh = false
    end
end

function spawnAbort()
    for i = 1, #spawnEntities do
        Delete(spawnEntities[i])
    end
    spawnPlacement = false
end

function spawnEnabled()
    return GetBool("game.player.interactive") -- and (GetBool("level.spawn") or GetBool("options.game.spawn"))
end

function drawList(w, h, title, items, selected, state, scrollToIndex)
    local hover = 0

    state.gYStartDrag = state.gYStartDrag or 0
    state.gIsDragging = state.gIsDragging or false

    if state.gIsDragging and InputReleased("lmb") then
        state.gIsDragging = false
    end

    UiPush()
    UiPush()
    UiColor(1, 1, 1)
    UiFont("bold.ttf", 22)
    UiTranslate(0, -UiFontHeight() - 5)
    UiText(title)
    UiPop()
    UiPush()
    UiColor(0, 0, 0, 0.2)
    UiTranslate(-3, -3)
    UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
    UiPop()
    UiTranslate(0, 2)
    UiWindow(w - 6, h - 8, true)
    UiPush()
    UiFont("regular.ttf", 21)
    local fh = UiFontHeight()
    if not state.scroll then
        state.scroll = 0
        state.scrollSmooth = 0
    end
    local visibleItems = math.floor(h / fh)
    local ma = math.max(0, #items - visibleItems)
    local scrollbarHeight = math.max(20, (visibleItems / #items) * h)
    local scrollItemHeight = ((h - scrollbarHeight) / ma)

    if UiIsMouseInRect(w, h) then
        state.scroll = state.scroll - InputValue("mousewheel")
    end
    if state.gIsDragging then
        local posx, posy = UiGetMousePos()
        local dy = 1 / scrollItemHeight * (posy - state.gYStartDrag)
        state.scroll = dy
    end

    if scrollToIndex and scrollToIndex ~= 0 then
        state.scroll = scrollToIndex - 1
    end

    state.scroll = clamp(state.scroll, 0, ma)
    state.scrollSmooth = 0.8 * state.scrollSmooth + 0.2 * state.scroll
    state.scrollSmooth = clamp(state.scrollSmooth, 0, ma)
    UiTranslate(0, -state.scrollSmooth * fh)

    for i = 1, #items do
        if UiIsMouseInRect(w - 4, 21) then
            hover = i
        end
        if i == selected then
            UiPush()
            UiColor(1, 1, 1, 0.1)
            UiTranslate(-1, -1)
            UiImageBox("ui/common/box-solid-4.png", w - 4, 22, 4, 4)
            UiPop()
            UiColor(1, 1, 0)
        else
            if hover == i then
                UiColor(0, 0, 0, 0.1)
                UiImageBox("ui/common/box-solid-4.png", w - 4, 22, 4, 4)
                if InputPressed("lmb") and i ~= selected then
                    UiSound("spawn/select.ogg")
                    selected = i
                end
            end
            UiColor(1, 1, 1)
        end
        local label = items[i]
        UiPush()
        local disabled = false
        while string.len(label) > 1 and string.sub(label, 2, 2) == ":" do
            if startsWith(label, "t:") then
                label = string.sub(label, 3, #label)
                UiTranslate(20, 0)
            end
            if startsWith(label, "d:") then
                label = string.sub(label, 3, #label)
                disabled = true
            end
            if startsWith(label, "h:") then
                label = string.sub(label, 3, #label)
                UiColor(1, 1, 1, 0.3)
            end
            if startsWith(label, "b:") then
                label = string.sub(label, 3, #label)
                UiFont("bold.ttf", 21)
            end
        end
        local w, h = UiText(label)
        if disabled then
            UiColorFilter(1, 1, 1, 0.75)
            UiTranslate(0, 12)
            UiRect(w, 1)
        end
        UiPop()
        UiTranslate(0, fh)
    end
    UiPop()
    UiPop()

    --Scrollbar
    if ma > 0 then
        UiPush()
        UiTranslate(-2, -2)
        UiPush()
        UiColor(0, 0, 0, 0.2)
        UiTranslate(w - 1, -1)
        UiImageBox("ui/common/box-solid-4.png", 12, h, 4, 4)
        UiPop()
        UiPush()
        UiColor(0.6, 0.6, 0.6, 1)
        UiTranslate(w, 0)
        UiTranslate(0, state.scrollSmooth * scrollItemHeight)
        if UiIsMouseInRect(10, scrollbarHeight) then
            if InputPressed("lmb") then
                local posx, posy = UiGetMousePos()
                state.gYStartDrag = posy
                state.gIsDragging = true
            end
            UiColor(0.8, 0.8, 0.8, 1)
        end
        UiImageBox("ui/common/box-solid-4.png", 10, scrollbarHeight, 4, 4)

        UiPop()
        UiPush()
        UiTranslate(w, 0)
        if UiIsMouseInRect(10, state.scrollSmooth * scrollItemHeight) and InputPressed("lmb") then
            state.scroll = clamp(state.scroll - visibleItems, 0, ma)
        end
        UiTranslate(0, state.scrollSmooth * scrollItemHeight + scrollbarHeight)
        if UiIsMouseInRect(10, h - (state.scrollSmooth * scrollItemHeight + scrollbarHeight)) and InputPressed("lmb") then
            state.scroll = clamp(state.scroll + visibleItems, 0, ma)
        end
        UiPop()
        UiPop()
    end

    return selected, hover
end

function getSource(mod)
    for i = 1, #gSources do
        if gSources[i].mod == mod then
            return gSources[i]
        end
    end
    return nil
end

function commaSeparatedList(list)
    local str = ""
    for i = 1, #list do
        if i > 1 then
            str = str .. ", "
        end
        str = str .. list[i]
    end
    return str
end

CATEGORIES = {
    ["Car"] = { 0.85, 0.3, 0.3 },
    ["Truck"] = { 0.24, 0.55, 0.45 },
    ["Military"] = { 0.64, 0.67, 0.6 },
    ["Heavy machinery"] = { 0.83, 0.84, 0.34 },
    ["Boat"] = { 0.16, 0.63, 0.88 },
    ["Robot"] = { 0.63, 0.5, 0.38 }
}

function ShowMenu(vehicle_name)
    if UiTextButton(vehicle_name) then
        UiSound("click.ogg")
        return Vehicles[vehicle_name].path
    end

    local path = Vehicles[vehicle_name].path
    local start = string.find(path, "/")
    local s_end = string.find(path, ".xml")
    local name = string.sub(path, start + 1, s_end - 1)
    local preview = "MOD/previews/" .. name .. ".png"
    --if HasFile(preview) then
    UiTranslate(-75, -35)
    UiImageBox(preview, 64, 48)
    UiTranslate(75, 35)
    --end
    UiTranslate(0, 35)
    return ""
end

cars_scroll_value = 0

function drawSpawnUi()
    local file = ""
    UiPush()
    UiMakeInteractive()
    UiTranslate(180, 180)
    UiColor(1, 1, 1)
    UiFont("regular.ttf", 30)
    UiTextShadow(0, 0, 0, 0.5, 1.0)
    UiButtonHoverColor(0.5, 0.5, 0.5)

    local cars_overflow = 0
    for k in pairs(Vehicles) do
        if Vehicles[k].categ == "Car" then
            cars_overflow = cars_overflow + 1
        end
    end

    for categ in pairs(CATEGORIES) do
        if categ == "Car" and cars_overflow > 20 then
            UiPush()
            local scroll_bar_width = (cars_overflow - 20 + 1) * 35 / 2
            cars_scroll_value = clamp(cars_scroll_value - InputValue("mousewheel") * 20, 0, scroll_bar_width)
            UiTranslate(210, UiHeight() / 2 - 180)
            UiAlign("center middle")
            UiColor(0, 0, 0, 0.5)
            UiImageBox("ui/common/box-solid-6.png", 13, scroll_bar_width, 6, 6)
            UiTranslate(0, -scroll_bar_width / 2)
            UiColor(1, 1, 0.5, 1)
            cars_scroll_value = UiSlider("ui/common/dot.png", "y", cars_scroll_value, 0, scroll_bar_width)
            UiPop()
            UiTranslate(0, -cars_scroll_value * 2)
        end

        local j = 0
        for k in pairs(Vehicles) do
            if Vehicles[k].categ == categ then
                file = ShowMenu(k)
                if file ~= "" then
                    UiPop()
                    return file
                end
                j = j + 1
            end
        end
        if j > 0 then
            UiTranslate(0, -35 * (j + 1))
            UiColor(unpack(CATEGORIES[categ]))
            UiText(categ)
            UiColor(1, 1, 1)
            UiTranslate(300, 35)
        end
        if categ == "Car" and cars_overflow > 20 then
            UiTranslate(0, cars_scroll_value * 2)
        end
    end
    UiPop()
    return ""
end

function spawn(file)
    UiSound("spawn/spawn.ogg")
    spawnRot = 0
    local t = GetCameraTransform()
    t.pos = VecAdd(t.pos, TransformToParentVec(t, Vec(0, 0, -7)))
    t.rot = getRotation()
    local c = t
    spawnEntities = Spawn(file, t)
    local mi = Vec(10000, 10000, 10000)
    local ma = Vec(-10000, -10000, -10000)
    for i = 1, #spawnEntities do
        local e = spawnEntities[i]
        if GetEntityType(e) == "shape" then
            local smi, sma = GetShapeBounds(e)
            for j = 1, 3 do
                mi[j] = math.min(mi[j], smi[j])
                ma[j] = math.max(ma[j], sma[j])
            end
        end
    end
    local mid = VecLerp(mi, ma, 0.5)
    spawnRadius = VecLength(VecSub(ma, mid))
    spawnDist = spawnRadius + 2.0
    c.pos = mid

    spawnOffset = {}
    for i = 1, #spawnEntities do
        local e = spawnEntities[i]
        local typ = GetEntityType(e)
        if typ == "body" then
            spawnOffset[i] = TransformToLocalTransform(c, GetBodyTransform(e))
        end
        if typ == "shape" then
            SetShapeCollisionFilter(e, 0, 0)
        end
    end
    spawnPreviousTool = GetString("game.player.tool")
    SetString("game.player.tool", "none")
    spawnPlacement = true
    spawnFile = file
    spawnUi = false
end

function spawner_draw()
    if InputPressed(GetString("savegame.mod.hotkey")) then
        if spawnPlacement then
            spawnAbort()
        end
        if spawnEnabled() and not spawnUi then
            spawnUi = true
            gFocusText = true
            gSetShortcut = false
        else
            spawnUi = false
        end
    end

    if spawnUi then
        UiMakeInteractive()
        SetBool("game.disablepause", true)
        SetBool("game.disablemap", true)
        SetBool("hud.disable", true)
        if gSetShortcut == false and InputPressed("pause") then
            spawnUi = false
        end
    end

    if spawnUi and spawnUiScale == 0 then
        SetValue("spawnUiScale", 1, "easeout", 0.25)
        UiSound("spawn/open.ogg")
    end
    if not spawnUi and spawnUiScale == 1 then
        SetValue("spawnUiScale", 0, "easein", 0.1)
        UiSound("spawn/close.ogg")
    end

    if spawnUiScale > 0 then
        local file = drawSpawnUi()
        if file ~= "" then
            spawn(file)
        end
    end

    if spawnPlacement then
        UiTranslate(UiWidth() - 250, UiHeight() - 170)
        UiColor(0, 0, 0, 0.5)
        UiImageBox("ui/common/box-solid-10.png", 200, 120, 10, 10)
        UiColor(1, 1, 1)
        UiTranslate(100, 32)
        UiPush()
        UiFont("bold.ttf", 22)
        UiAlign("right")
        UiText("LMB", true)
        UiText("RMB", true)
        UiText("Scroll", true)
        UiText(string.upper(GetString("game.input.pause")), true)
        UiPop()
        UiTranslate(0, 0)
        UiPush()
        UiFont("regular.ttf", 22)
        UiAlign("left")
        UiText("Place", true)
        UiText("Rotate", true)
        UiText("Distance", true)
        UiText("Abort", true)
        UiPop()
    end
end
