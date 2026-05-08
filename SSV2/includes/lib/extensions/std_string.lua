-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- A string is considered invalid if any of these conditions are true:
-- - `nil`
-- - `empty`
-- - `white space`
---@param str? string
---@return boolean
function string.isvalid(str)
	return type(str) == "string"
		and not str:isempty()
		and not str:iswhitespace()
end

-- Generates a random string.
---@param length? number
---@param isalnum? boolean Alphanumeric
---@return string
function string.random(length, isalnum)
	local str_table = {}
	local charset   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	length          = length or math.random(1, 10)
	length          = math.min(length or math.random(1, 10), 128)

	if (isalnum) then
		charset = charset .. "0123456789"
	end

	for _ = 1, length do
		local index = math.random(1, #charset)
		table.insert(str_table, charset:sub(index, index))
	end

	return table.concat(str_table)
end

-- Returns whether a string is alphabetic.
---@param str string
---@return boolean
function string.isalpha(str)
	return str:match("^%a+$") ~= nil
end

-- Returns whether a string is numeric.
---@param str string
---@return boolean
function string.isdigit(str)
	return str:match("^%d+$") ~= nil
end

-- Returns whether a string is alpha-numeric.
---@param str string
---@return boolean
function string.isalnum(str)
	return str:match("^%w+$") ~= nil
end

---@param str string
---@return boolean
function string.iswhitespace(str)
	return str:match("^%s*$") ~= nil
end

---@param str? string
---@return boolean
function string.isnull(str)
	return str == nil
end

---@param str string
function string.isempty(str)
	return #str == 0
end

---@param str string?
---@return boolean
function string.isnullorempty(str)
	if str == nil then
		return true
	end

	return str:isempty()
end

---@param str string?
---@return boolean
function string.isnullorwhitespace(str)
	if str == nil then
		return true
	end

	return str:iswhitespace()
end

---@param str string
---@return boolean
function string.is_base64(str)
	if (not string.isvalid(str)) then
		return false
	end

	return (#str % 4 == 0) and (str:match("^[A-Za-z0-9+/]+=?=?$") ~= nil)
end

-- Returns whether a string starts with the provided prefix.
---@param str string
---@param prefix string
---@return boolean
function string.startswith(str, prefix)
	return str:sub(1, #prefix) == prefix
end

-- Returns whether a string contains the provided substring.
---@param str string
---@param sub string
---@return boolean
function string.contains(str, sub)
	return str:find(sub, 1, true) ~= nil
end

-- Returns whether a string ends with the provided suffix.
---@param str string
---@param suffix string
---@return boolean
function string.endswith(str, suffix)
	return str:sub(- #suffix) == suffix
end

-- Inserts a string into another string at the given position.
---@param str string
---@param pos integer
---@param text string
function string.insert(str, pos, text)
	pos = math.max(1, math.min(pos, #str + 1))
	return str:sub(1, pos) .. text .. str:sub(pos)
end

-- Replaces all occurrances of `old` string with `new` string.
--
-- Returns the new string and the count of all occurrances.
---@param str string
---@param old string
---@param new string
---@return string, number
function string.replace(str, old, new)
	if old == "" then
		return str, 0
	end

	return str:gsub(old:gsub("([^%w])", "%%%1"), new)
end

---@param str string
---@param pos integer
---@param new_cahr string
function string.replace_char(str, pos, new_cahr)
	pos = math.max(1, math.min(pos, #str + 1))
	local prefix = str:sub(1, pos - 1)
	local suffix = str:sub(pos + 1)

	return _F("%s%s%s", prefix, new_cahr, suffix)
end

-- Joins a table of strings using a separator.
---@param sep string
---@param tbl string[]
---@return string
function string.join(sep, tbl)
	return table.concat(tbl, sep)
end

-- Removes leading and trailing white space from a string.
---@param str string
---@return string
function string.trim(str)
	return str:match("^%s*(.-)%s*$")
end

---@param str string
---@param width integer
function string.wrap(str, width)
	local out = {}
	for i = 1, #str, width do
		table.insert(out, str:sub(i, i + width - 1))
	end
	return table.concat(out, "\n")
end

-- Splits a string by a separator and returns a table of strings.
---@param str string
---@param sep string
---@param maxsplit? integer Optional: limit the number of splits.
---@return string[]
function string.split(str, sep, maxsplit)
	local result, count = {}, 0
	local pattern = "([^" .. sep .. "]+)"

	for part in str:gmatch(pattern) do
		table.insert(result, part)
		count = count + 1

		if maxsplit and count >= maxsplit then
			local rest = str:match("^" .. (("([^" .. sep .. "]+)" .. sep):rep(count)) .. "(.+)$")
			if rest then
				table.insert(result, rest)
			end
			break
		end
	end

	return result
end

-- Same as `string.split` but starts from the right.
---@param str string
---@param sep string
---@param maxsplit? integer Optional: limit the number of splits.
---@return string[]
function string.rsplit(str, sep, maxsplit)
	local splits = {}

	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(splits, part)
	end

	local total = #splits
	if not maxsplit or maxsplit <= 0 or maxsplit >= total - 1 then
		return splits
	end

	local head = {}
	for i = 1, total - maxsplit - 1 do
		table.insert(head, splits[i])
	end

	local tail = table.concat(splits, sep, total - maxsplit, total)
	table.insert(head, tail)
	return head
end

-- Python-like `partition` implementation: Splits a string into 3 parts: before, separator, after
---@param str string
---@param sep string
---@return string, string, string
function string.partition(str, sep)
	local start_pos, end_pos = str:find(sep, 1, true)

	if not start_pos then
		return str, "", ""
	end

	return str:sub(1, start_pos - 1), sep, str:sub(end_pos + 1)
end

-- Same as `string.partition` but starts from the right.
---@param str string
---@param sep string
---@return string, string, string
function string.rpartition(str, sep)
	local start_pos, end_pos = str:reverse():find(sep:reverse(), 1, true)

	if not start_pos then
		return "", "", str
	end

	local rev_index = #str - end_pos + 1
	return str:sub(1, rev_index - 1), sep, str:sub(rev_index + #sep)
end

---@param str string
---@param len number
---@param char string
---@return string
function string.padleft(str, len, char)
	return _F("%s%s", string.rep(char or " ", math.max(0, len - #str)), str)
end

---@param str string
---@param len number
---@param char string
---@return string
function string.padright(str, len, char)
	return _F("%s%s", str, string.rep(char or " ", math.max(0, len - #str)))
end

-- Capitalizes the first letter in a string.
---@param str string
---@return string
function string.capitalize(str)
	return (str:lower():gsub("^%l", string.upper))
end

-- Capitalizes the first letter of each word in a string.
---@param str string
---@return string
function string.titlecase(str)
	return (str:gsub("%_+", " "):gsub("(%a)([%w_']*)", function(a, b)
		return a:upper() .. b:lower()
	end))
end

---@return string
function string.pascalcase(str)
	return str:lower():gsub("%_+", " "):gsub("%-+", ""):titlecase():gsub("%s+", "")
end

---@return string
function string.snakecase(str)
	return str:lower():gsub("[%s%-]", "_")
end

---@param value number|string
---@return string
function string.formatint(value)
	local s, _ = tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
	return s
end

---@param value number|string
---@param currency? string
---@return string
function string.formatmoney(value, currency)
	return _F("%s%s", currency or "$", string.formatint(value))
end

---@param str string
function string.hex2string(str)
	return (str:gsub("%x%x", function(digits)
		return string.char(tonumber(digits, 16))
	end))
end

---@param v string|number
---@return string
function string.hex(v)
	local _type = type(v)
	if (_type == "string") then
		return (string.gsub(v, ".", function(char)
			return _F("%02x", string.byte(char))
		end))
	elseif (_type == "number") then
		return _F("0x%X", v)
	end

	return ""
end
