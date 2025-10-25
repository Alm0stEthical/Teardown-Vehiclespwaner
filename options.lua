-- Configuration constants
local KEYS_AMOUNT = 1
local DEFAULT_MENU_KEY = "X"

-- Initialize options menu state
function init()
	if GetString("savegame.mod.hotkey") == "" then
		SetString("savegame.mod.hotkey", DEFAULT_MENU_KEY)
	end

	await_input = {}
	for i = 1, KEYS_AMOUNT do
		table.insert(await_input, false)
	end
end

-- Draw a hotkey editor UI element
-- @param name: Display name for the hotkey
-- @param entry: Save game entry key
-- @param index: Index in the await_input array
function EditHotkey(name, entry, index)
	UiPush()
	UiText(name)
	UiTranslate(200, 0)
	if await_input[index] then
		UiColor(1, 0.5, 0.5)
		UiImageBox("ui/common/box-solid-6.png", 100, 40, 6, 6)
		local current_key = InputLastPressedKey()
		if current_key ~= "" then
			SetString(entry, current_key)
			await_input[index] = false
		end
	end
	local menu_key = GetString(entry)
	if UiTextButton(menu_key, 100, 40) then
		await_input[index] = true
	end
	UiPop()
	UiTranslate(0, 75)
end

-- Draw a toggle option UI element
-- @param name: Display name for the option
-- @param entry: Save game entry key
function ToggleOption(name, entry)
	UiPush()
	UiText(name)
	UiTranslate(200, 0)
	local enabled = GetBool(entry)
	local text = enabled and "Enabled" or "Disabled"
	if enabled then
		UiColor(0.5, 1, 0.5, 0.5)
	else
		UiColor(1, 0.5, 0.5)
	end
	UiImageBox("ui/common/box-solid-6.png", 100, 40, 6, 6)
	if UiTextButton(text, 100, 40) then
		enabled = not enabled
		SetBool(entry, enabled)
	end
	UiPop()
	UiTranslate(0, 75)
end

-- Draw the options menu UI
function draw()
	UiTranslate(UiCenter(), 250)
	UiAlign("center middle")
	UiFont("bold.ttf", 48)
	UiText("Vehicle spawner options")

	UiTranslate(-75, 120)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)

	EditHotkey("Open spawn menu key:", "savegame.mod.hotkey", 1)

	UiTranslate(75, 50)
	if UiTextButton("Close", 200, 40) then
		Menu()
	end
end
