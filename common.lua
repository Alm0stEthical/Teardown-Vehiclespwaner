-- Clamp a value between minimum and maximum bounds
-- @param value: The value to clamp
-- @param mi: Minimum bound
-- @param ma: Maximum bound
-- @return: Clamped value
function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


-- Trim whitespace from both ends of a string
-- @param s: String to trim
-- @return: Trimmed string
function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-- Check if a string starts with a specific prefix
-- @param str: String to check
-- @param start: Prefix to look for
-- @return: true if str starts with start, false otherwise
function startsWith(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

-- Split a string by a delimiter
-- @param str: String to split
-- @param delimiter: Delimiter character
-- @return: Array of trimmed substrings
function splitString(str, delimiter)
	local result = {}
	for word in string.gmatch(str, '([^'..delimiter..']+)') do
		result[#result+1] = trim(word)
	end
	return result
end


-- Check if a string contains a specific word (case-insensitive)
-- @param str: String to search in
-- @param word: Word to search for
-- @return: true if word is found, false otherwise
function hasWord(str, word)
	local words = splitString(str, " ")
	for i=1,#words do
		if string.lower(words[i]) == string.lower(word) then
			return true
		end
	end
	return false
end

-- Smooth interpolation function (Hermite interpolation)
-- @param edge0: Lower edge of the Hermite function
-- @param edge1: Upper edge of the Hermite function
-- @param x: Value to interpolate
-- @return: Smoothly interpolated value between 0 and 1
function smoothstep(edge0, edge1, x)
	x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3 - 2 * x)
end


-- Math library clamp function with auto-swap for reversed bounds
-- @param val: Value to clamp
-- @param lower: Lower bound
-- @param upper: Upper bound
-- @return: Clamped value
function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end


-- Draw a progress bar UI element
-- @param w: Width of the progress bar
-- @param h: Height of the progress bar
-- @param t: Progress value (0.0 to 1.0)
function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end


-- Draw hint box with arrow to the left, pointing at cursor position
-- @param str: Text to display in the hint box
function drawHintArrow(str)
	UiPush()
		UiAlign("middle left")
		UiColor(1,1,1, 0.7)
		local w,h = UiImage("common/arrow-left.png")
		UiTranslate(w-1, 0)
		UiFont("bold.ttf", 22)
		 w,h = UiGetTextSize(str)
		UiImageBox("common/box-solid-6.png", w+40, h+12, 6, 6)
		UiPush()
			UiColor(0,0,0)
			UiTranslate(20, 0)
			UiText(str)
		UiPop()
	UiPop()
end

