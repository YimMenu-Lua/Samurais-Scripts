---@diagnostic disable

--#region json
--
-- -*- coding: utf-8 -*-
--
-- Simple JSON encoding and decoding in pure Lua.
--
-- Copyright 2010-2017 Jeffrey Friedl
-- http://regex.info/blog/
-- Latest version: http://regex.info/blog/lua/json
--
-- This code is released under a Creative Commons CC-BY "Attribution" License:
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
--
-- It can be used for any purpose so long as:
--    1) the copyright notice above is maintained
--    2) the web-page links above are maintained
--    3) the 'AUTHOR_NOTE' string below is maintained
--
local function JSON()
    local VERSION = '20211016.28' -- version history at end of file
    local AUTHOR_NOTE = "-[ JSON.lua package by Jeffrey Friedl (http://regex.info/blog/lua/json) version 20211016.28 ]-"

    --
    -- The 'AUTHOR_NOTE' variable exists so that information about the source
    -- of the package is maintained even in compiled versions. It's also
    -- included in OBJDEF below mostly to quiet warnings about unused variables.
    --
    local OBJDEF = {
        VERSION     = VERSION,
        AUTHOR_NOTE = AUTHOR_NOTE,
    }

    local default_pretty_indent  = "  "
    local default_pretty_options = { pretty = true, indent = default_pretty_indent, align_keys = false, array_newline = false }

    local isArray                = { __tostring = function() return "JSON array" end }
    isArray.__index              = isArray
    local isObject               = { __tostring = function() return "JSON object" end }
    isObject.__index             = isObject

    function OBJDEF:newArray(tbl)
        return setmetatable(tbl or {}, isArray)
    end

    function OBJDEF:newObject(tbl)
        return setmetatable(tbl or {}, isObject)
    end

    local function getnum(op)
        return type(op) == 'number' and op or op.N
    end

    local isNumber = {
        __tostring = function(T) return T.S end,
        __unm      = function(op) return getnum(op) end,

        __concat   = function(op1, op2) return tostring(op1) .. tostring(op2) end,
        __add      = function(op1, op2) return getnum(op1) + getnum(op2) end,
        __sub      = function(op1, op2) return getnum(op1) - getnum(op2) end,
        __mul      = function(op1, op2) return getnum(op1) * getnum(op2) end,
        __div      = function(op1, op2) return getnum(op1) / getnum(op2) end,
        __mod      = function(op1, op2) return getnum(op1) % getnum(op2) end,
        __pow      = function(op1, op2) return getnum(op1) ^ getnum(op2) end,
        __lt       = function(op1, op2) return getnum(op1) < getnum(op2) end,
        __eq       = function(op1, op2) return getnum(op1) == getnum(op2) end,
        __le       = function(op1, op2) return getnum(op1) <= getnum(op2) end,
    }
    isNumber.__index = isNumber

    function OBJDEF:asNumber(item)
        if getmetatable(item) == isNumber then
            -- it's already a JSON number object.
            return item
        elseif type(item) == 'table' and type(item.S) == 'string' and type(item.N) == 'number' then
            -- it's a number-object table that lost its metatable, so give it one
            return setmetatable(item, isNumber)
        else
            -- the normal situation... given a number or a string representation of a number....
            local holder = {
                S = tostring(item), -- S is the representation of the number as a string, which remains precise
                N = tonumber(item), -- N is the number as a Lua number.
            }
            return setmetatable(holder, isNumber)
        end
    end

    --
    -- Given an item that might be a normal string or number, or might be an 'isNumber' object defined above,
    -- return the string version. This shouldn't be needed often because the 'isNumber' object should autoconvert
    -- to a string in most cases, but it's here to allow it to be forced when needed.
    --
    function OBJDEF:forceString(item)
        if type(item) == 'table' and type(item.S) == 'string' then
            return item.S
        else
            return tostring(item)
        end
    end

    --
    -- Given an item that might be a normal string or number, or might be an 'isNumber' object defined above,
    -- return the numeric version.
    --
    function OBJDEF:forceNumber(item)
        if type(item) == 'table' and type(item.N) == 'number' then
            return item.N
        else
            return tonumber(item)
        end
    end

    --
    -- If the given item is a number, return it. Otherwise, return nil.
    -- This, this can be used both in a conditional and to access the number when you're not sure its form.
    --
    function OBJDEF:isNumber(item)
        if type(item) == 'number' then
            return item
        elseif type(item) == 'table' and type(item.N) == 'number' then
            return item.N
        else
            return nil
        end
    end

    function OBJDEF:isString(item)
        if type(item) == 'string' then
            return item
        elseif type(item) == 'table' and type(item.S) == 'string' then
            return item.S
        else
            return nil
        end
    end

    --
    -- Some utf8 routines to deal with the fact that Lua handles only bytes
    --
    local function top_three_bits(val)
        return math.floor(val / 0x20)
    end

    local function top_four_bits(val)
        return math.floor(val / 0x10)
    end

    local function unicode_character_bytecount_based_on_first_byte(first_byte)
        local W = string.byte(first_byte)
        if W < 0x80 then
            return 1
        elseif (W == 0xC0) or (W == 0xC1) or (W >= 0x80 and W <= 0xBF) or (W >= 0xF5) then
            -- this is an error -- W can't be the start of a utf8 character
            return 0
        elseif top_three_bits(W) == 0x06 then
            return 2
        elseif top_four_bits(W) == 0x0E then
            return 3
        else
            return 4
        end
    end



    local function unicode_codepoint_as_utf8(codepoint)
        --
        -- codepoint is a number
        --
        if codepoint <= 127 then
            return string.char(codepoint)
        elseif codepoint <= 2047 then
            --
            -- 110yyyxx 10xxxxxx         <-- useful notation from http://en.wikipedia.org/wiki/Utf8
            --
            local highpart = math.floor(codepoint / 0x40)
            local lowpart  = codepoint - (0x40 * highpart)
            return string.char(0xC0 + highpart,
                0x80 + lowpart)
        elseif codepoint <= 65535 then
            --
            -- 1110yyyy 10yyyyxx 10xxxxxx
            --
            local highpart  = math.floor(codepoint / 0x1000)
            local remainder = codepoint - 0x1000 * highpart
            local midpart   = math.floor(remainder / 0x40)
            local lowpart   = remainder - 0x40 * midpart

            highpart        = 0xE0 + highpart
            midpart         = 0x80 + midpart
            lowpart         = 0x80 + lowpart

            --
            -- Check for an invalid character (thanks Andy R. at Adobe).
            -- See table 3.7, page 93, in http://www.unicode.org/versions/Unicode5.2.0/ch03.pdf#G28070
            --
            if (highpart == 0xE0 and midpart < 0xA0) or
                (highpart == 0xED and midpart > 0x9F) or
                (highpart == 0xF0 and midpart < 0x90) or
                (highpart == 0xF4 and midpart > 0x8F)
            then
                return "?"
            else
                return string.char(highpart,
                    midpart,
                    lowpart)
            end
        else
            --
            -- 11110zzz 10zzyyyy 10yyyyxx 10xxxxxx
            --
            local highpart  = math.floor(codepoint / 0x40000)
            local remainder = codepoint - 0x40000 * highpart
            local midA      = math.floor(remainder / 0x1000)
            remainder       = remainder - 0x1000 * midA
            local midB      = math.floor(remainder / 0x40)
            local lowpart   = remainder - 0x40 * midB

            return string.char(0xF0 + highpart,
                0x80 + midA,
                0x80 + midB,
                0x80 + lowpart)
        end
    end

    function OBJDEF:onDecodeError(message, text, location, etc)
        if text then
            if location then
                message = string.format("%s at byte %d of: %s", message, location, text)
            else
                message = string.format("%s: %s", message, text)
            end
        end

        if etc ~= nil then
            message = message .. " (" .. OBJDEF:encode(etc) .. ")"
        end

        if self.assert then
            self.assert(false, message)
        else
            assert(false, message)
        end
    end

    function OBJDEF:onTrailingGarbage(json_text, location, parsed_value, etc)
        return self:onDecodeError("trailing garbage", json_text, location, etc)
    end

    OBJDEF.onDecodeOfNilError  = OBJDEF.onDecodeError
    OBJDEF.onDecodeOfHTMLError = OBJDEF.onDecodeError

    function OBJDEF:onEncodeError(message, etc)
        if etc ~= nil then
            message = message .. " (" .. OBJDEF:encode(etc) .. ")"
        end

        if self.assert then
            self.assert(false, message)
        else
            assert(false, message)
        end
    end

    local function grok_number(self, text, start, options)
        --
        -- Grab the integer part
        --
        local integer_part = text:match('^-?[1-9]%d*', start)
            or text:match("^-?0", start)

        if not integer_part then
            self:onDecodeError("expected number", text, start, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        local i = start + integer_part:len()

        --
        -- Grab an optional decimal part
        --
        local decimal_part = text:match('^%.%d+', i) or ""

        i = i + decimal_part:len()

        --
        -- Grab an optional exponential part
        --
        local exponent_part = text:match('^[eE][-+]?%d+', i) or ""

        i = i + exponent_part:len()

        local full_number_text = integer_part .. decimal_part .. exponent_part

        if options.decodeNumbersAsObjects then
            local objectify = false

            if not options.decodeIntegerObjectificationLength and not options.decodeDecimalObjectificationLength then
                -- no options, so objectify
                objectify = true
            elseif (options.decodeIntegerObjectificationLength
                    and
                    (integer_part:len() >= options.decodeIntegerObjectificationLength or exponent_part:len() > 0))

                or
                (options.decodeDecimalObjectificationLength
                    and
                    (decimal_part:len() >= options.decodeDecimalObjectificationLength or exponent_part:len() > 0))
            then
                -- have options and they are triggered, so objectify
                objectify = true
            end

            if objectify then
                return OBJDEF:asNumber(full_number_text), i
            end
            -- else, fall through to try to return as a straight-up number
        else
            -- Not always decoding numbers as objects, so perhaps encode as strings?

            --
            -- If we're told to stringify only under certain conditions, so do.
            -- We punt a bit when there's an exponent by just stringifying no matter what.
            -- I suppose we should really look to see whether the exponent is actually big enough one
            -- way or the other to trip stringification, but I'll be lazy about it until someone asks.
            --
            if (options.decodeIntegerStringificationLength
                    and
                    (integer_part:len() >= options.decodeIntegerStringificationLength or exponent_part:len() > 0))

                or

                (options.decodeDecimalStringificationLength
                    and
                    (decimal_part:len() >= options.decodeDecimalStringificationLength or exponent_part:len() > 0))
            then
                return full_number_text, i -- this returns the exact string representation seen in the original JSON
            end
        end


        local as_number = tonumber(full_number_text)

        if not as_number then
            self:onDecodeError("bad number", text, start, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        return as_number, i
    end


    local backslash_escape_conversion = {
        ['"'] = '"',
        ['/'] = "/",
        ['\\'] = "\\",
        ['b'] = "\b",
        ['f'] = "\f",
        ['n'] = "\n",
        ['r'] = "\r",
        ['t'] = "\t",
    }

    local function grok_string(self, text, start, options)
        if text:sub(start, start) ~= '"' then
            self:onDecodeError("expected string's opening quote", text, start, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        local i = start + 1 -- +1 to bypass the initial quote
        local text_len = text:len()
        local VALUE = ""
        while i <= text_len do
            local c = text:sub(i, i)
            if c == '"' then
                return VALUE, i + 1
            end
            if c ~= '\\' then
                -- should grab the next bytes as per the number of bytes for this utf8 character
                local byte_count = unicode_character_bytecount_based_on_first_byte(c)

                local next_character
                if byte_count == 0 then
                    self:onDecodeError("non-utf8 sequence", text, i, options.etc)
                elseif byte_count == 1 then
                    if options.strictParsing and string.byte(c) < 0x20 then
                        self:onDecodeError("Unescaped control character", text, i + 1, options.etc)
                        return nil, start -- in case the error method doesn't abort, return something sensible
                    end
                    next_character = c
                elseif byte_count == 2 then
                    next_character = text:match('^(.[\128-\191])', i)
                elseif byte_count == 3 then
                    next_character = text:match('^(.[\128-\191][\128-\191])', i)
                elseif byte_count == 4 then
                    next_character = text:match('^(.[\128-\191][\128-\191][\128-\191])', i)
                end

                if not next_character then
                    self:onDecodeError("incomplete utf8 sequence", text, i, options.etc)
                    return nil, i -- in case the error method doesn't abort, return something sensible
                end


                VALUE = VALUE .. next_character
                i = i + byte_count
            else
                --
                -- We have a backslash escape
                --
                i = i + 1

                local next_byte = text:match('^(.)', i)

                if next_byte == nil then
                    -- string ended after the \
                    self:onDecodeError("unfinished \\ escape", text, i, options.etc)
                    return nil, start -- in case the error method doesn't abort, return something sensible
                end

                if backslash_escape_conversion[next_byte] then
                    VALUE = VALUE .. backslash_escape_conversion[next_byte]
                    i = i + 1
                else
                    --
                    -- The only other valid use of \ that remains is in the form of \u####
                    --

                    local hex = text:match(
                        '^u([0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])',
                        i)
                    if hex then
                        i = i + 5 -- bypass what we just read

                        -- We have a Unicode codepoint. It could be standalone, or if in the proper range and
                        -- followed by another in a specific range, it'll be a two-code surrogate pair.
                        local codepoint = tonumber(hex, 16)
                        if codepoint >= 0xD800 and codepoint <= 0xDBFF then
                            -- it's a hi surrogate... see whether we have a following low
                            local lo_surrogate = text:match(
                                '^\\u([dD][cdefCDEF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
                            if lo_surrogate then
                                i = i + 6 -- bypass the low surrogate we just read
                                codepoint = 0x2400 + (codepoint - 0xD800) * 0x400 + tonumber(lo_surrogate, 16)
                            else
                                -- not a proper low, so we'll just leave the first codepoint as is and spit it out.
                            end
                        end
                        VALUE = VALUE .. unicode_codepoint_as_utf8(codepoint)
                    elseif options.strictParsing then
                        --local next_byte = text:match('^\\(.)', i) printf("NEXT[%s]", next_byte);
                        self:onDecodeError("illegal use of backslash escape", text, i, options.etc)
                        return nil, start -- in case the error method doesn't abort, return something sensible
                    else
                        local byte_count = unicode_character_bytecount_based_on_first_byte(next_byte)
                        if byte_count == 0 then
                            self:onDecodeError("non-utf8 sequence after backslash escape", text, i, options.etc)
                            return nil, start -- in case the error method doesn't abort, return something sensible
                        end

                        local next_character
                        if byte_count == 1 then
                            next_character = next_byte
                        elseif byte_count == 2 then
                            next_character = text:match('^(.[\128-\191])', i)
                        elseif byte_count == 3 then
                            next_character = text:match('^(.[\128-\191][\128-\191])', i)
                        elseif byte_count == 3 then
                            next_character = text:match('^(.[\128-\191][\128-\191][\128-\191])', i)
                        end

                        if next_character == nil then
                            -- incomplete utf8 character after escape
                            self:onDecodeError("incomplete utf8 sequence after backslash escape", text, i, options.etc)
                            return nil, start -- in case the error method doesn't abort, return something sensible
                        end

                        VALUE = VALUE .. next_character
                        i = i + byte_count
                    end
                end
            end
        end

        self:onDecodeError("unclosed string", text, start, options.etc)
        return nil, start -- in case the error method doesn't abort, return something sensible
    end

    local function skip_whitespace(text, start)
        local _, match_end = text:find("^[ \n\r\t]+", start) -- [ https://datatracker.ietf.org/doc/html/rfc7158#section-2 ]
        if match_end then
            return match_end + 1
        else
            return start
        end
    end

    local grok_one -- assigned later

    local function grok_object(self, text, start, options)
        if text:sub(start, start) ~= '{' then
            self:onDecodeError("expected '{'", text, start, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        local i = skip_whitespace(text, start + 1) -- +1 to skip the '{'

        local VALUE = self.strictTypes and self:newObject {} or {}

        if text:sub(i, i) == '}' then
            return VALUE, i + 1
        end
        local text_len = text:len()
        while i <= text_len do
            local key, new_i = grok_string(self, text, i, options)

            i = skip_whitespace(text, new_i)

            if text:sub(i, i) ~= ':' then
                self:onDecodeError("expected colon", text, i, options.etc)
                return nil, i -- in case the error method doesn't abort, return something sensible
            end

            i = skip_whitespace(text, i + 1)

            local new_val, new_i = grok_one(self, text, i, options)

            VALUE[key] = new_val

            --
            -- Expect now either '}' to end things, or a ',' to allow us to continue.
            --
            i = skip_whitespace(text, new_i)

            local c = text:sub(i, i)

            if c == '}' then
                return VALUE, i + 1
            end

            if text:sub(i, i) ~= ',' then
                self:onDecodeError("expected comma or '}'", text, i, options.etc)
                return nil, i -- in case the error method doesn't abort, return something sensible
            end

            i = skip_whitespace(text, i + 1)
        end

        self:onDecodeError("unclosed '{'", text, start, options.etc)
        return nil, start -- in case the error method doesn't abort, return something sensible
    end

    local function grok_array(self, text, start, options)
        if text:sub(start, start) ~= '[' then
            self:onDecodeError("expected '['", text, start, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        local i = skip_whitespace(text, start + 1) -- +1 to skip the '['
        local VALUE = self.strictTypes and self:newArray {} or {}
        if text:sub(i, i) == ']' then
            return VALUE, i + 1
        end

        local VALUE_INDEX = 1

        local text_len = text:len()
        while i <= text_len do
            local val, new_i = grok_one(self, text, i, options)

            -- can't table.insert(VALUE, val) here because it's a no-op if val is nil
            VALUE[VALUE_INDEX] = val
            VALUE_INDEX = VALUE_INDEX + 1

            i = skip_whitespace(text, new_i)

            --
            -- Expect now either ']' to end things, or a ',' to allow us to continue.
            --
            local c = text:sub(i, i)
            if c == ']' then
                return VALUE, i + 1
            end
            if text:sub(i, i) ~= ',' then
                self:onDecodeError("expected comma or ']'", text, i, options.etc)
                return nil, i -- in case the error method doesn't abort, return something sensible
            end
            i = skip_whitespace(text, i + 1)
        end
        self:onDecodeError("unclosed '['", text, start, options.etc)
        return nil, i -- in case the error method doesn't abort, return something sensible
    end


    grok_one = function(self, text, start, options)
        -- Skip any whitespace
        start = skip_whitespace(text, start)

        if start > text:len() then
            self:onDecodeError("unexpected end of string", text, nil, options.etc)
            return nil, start -- in case the error method doesn't abort, return something sensible
        end

        if text:find('^"', start) then
            return grok_string(self, text, start, options)
        elseif text:find('^[-0123456789 ]', start) then
            return grok_number(self, text, start, options)
        elseif text:find('^%{', start) then
            return grok_object(self, text, start, options)
        elseif text:find('^%[', start) then
            return grok_array(self, text, start, options)
        elseif text:find('^true', start) then
            return true, start + 4
        elseif text:find('^false', start) then
            return false, start + 5
        elseif text:find('^null', start) then
            return options.null, start + 4
        else
            self:onDecodeError("can't parse JSON", text, start, options.etc)
            return nil, 1 -- in case the error method doesn't abort, return something sensible
        end
    end

    function OBJDEF:decode(text, etc, options)
        --
        -- If the user didn't pass in a table of decode options, make an empty one.
        --
        if type(options) ~= 'table' then
            options = {}
        end

        --
        -- If they passed in an 'etc' argument, stuff it into the options.
        -- (If not, any 'etc' field in the options they passed in remains to be used)
        --
        if etc ~= nil then
            options.etc = etc
        end


        --
        -- apply global options
        --
        if options.decodeNumbersAsObjects == nil then
            options.decodeNumbersAsObjects = self.decodeNumbersAsObjects
        end
        if options.decodeIntegerObjectificationLength == nil then
            options.decodeIntegerObjectificationLength = self.decodeIntegerObjectificationLength
        end
        if options.decodeDecimalObjectificationLength == nil then
            options.decodeDecimalObjectificationLength = self.decodeDecimalObjectificationLength
        end
        if options.decodeIntegerStringificationLength == nil then
            options.decodeIntegerStringificationLength = self.decodeIntegerStringificationLength
        end
        if options.decodeDecimalStringificationLength == nil then
            options.decodeDecimalStringificationLength = self.decodeDecimalStringificationLength
        end
        if options.strictParsing == nil then
            options.strictParsing = self.strictParsing
        end


        if type(self) ~= 'table' or self.__index ~= OBJDEF then
            local error_message = "JSON:decode must be called in method format"
            OBJDEF:onDecodeError(error_message, nil, nil, options.etc)
            return nil, error_message -- in case the error method doesn't abort, return something sensible
        end

        if text == nil then
            local error_message = "nil passed to JSON:decode()"
            self:onDecodeOfNilError(error_message, nil, nil, options.etc)
            return nil, error_message -- in case the error method doesn't abort, return something sensible
        elseif type(text) ~= 'string' then
            local error_message = "expected string argument to JSON:decode()"
            self:onDecodeError(string.format("%s, got %s", error_message, type(text)), nil, nil, options.etc)
            return nil, error_message -- in case the error method doesn't abort, return something sensible
        end

        -- If passed an empty string....
        if text:match('^%s*$') then
            if options.strictParsing then
                local error_message = "empty string passed to JSON:decode()"
                self:onDecodeOfNilError(error_message, nil, nil, options.etc)
                return nil, error_message -- in case the error method doesn't abort, return something sensible
            else
                -- we'll consider it nothing, but not an error
                return nil
            end
        end

        if text:match('^%s*<') then
            -- Can't be JSON... we'll assume it's HTML
            local error_message = "HTML passed to JSON:decode()"
            self:onDecodeOfHTMLError(error_message, text, nil, options.etc)
            return nil, error_message -- in case the error method doesn't abort, return something sensible
        end

        --
        -- Ensure that it's not UTF-32 or UTF-16.
        -- Those are perfectly valid encodings for JSON (as per RFC 4627 section 3),
        -- but this package can't handle them.
        --
        if text:sub(1, 1):byte() == 0 or (text:len() >= 2 and text:sub(2, 2):byte() == 0) then
            local error_message = "JSON package groks only UTF-8, sorry"
            self:onDecodeError(error_message, text, nil, options.etc)
            return nil, error_message -- in case the error method doesn't abort, return something sensible
        end


        --
        -- Finally, go parse it
        --
        local success, value, next_i = pcall(grok_one, self, text, 1, options)

        if success then
            local error_message = nil
            if next_i ~= #text + 1 then
                -- something's left over after we parsed the first thing.... whitespace is allowed.
                next_i = skip_whitespace(text, next_i)

                -- if we have something left over now, it's trailing garbage
                if next_i ~= #text + 1 then
                    value, error_message = self:onTrailingGarbage(text, next_i, value, options.etc)
                end
            end
            return value, error_message
        else
            -- If JSON:onDecodeError() didn't abort out of the pcall, we'll have received
            -- the error message here as "value", so pass it along as an assert.
            local error_message = value
            if self.assert then
                self.assert(false, error_message)
            else
                assert(false, error_message)
            end
            -- ...and if we're still here (because the assert didn't throw an error),
            -- return a nil and throw the error message on as a second arg
            return nil, error_message
        end
    end

    local function backslash_replacement_function(c)
        if c == "\n" then
            return "\\n"
        elseif c == "\r" then
            return "\\r"
        elseif c == "\t" then
            return "\\t"
        elseif c == "\b" then
            return "\\b"
        elseif c == "\f" then
            return "\\f"
        elseif c == '"' then
            return '\\"'
        elseif c == '\\' then
            return '\\\\'
        elseif c == '/' then
            return '/'
        else
            return string.format("\\u%04x", c:byte())
        end
    end

    local chars_to_be_escaped_in_JSON_string
    = '['
        .. '"'                     -- class sub-pattern to match a double quote
        .. '%\\'                   -- class sub-pattern to match a backslash
        .. '/'                     -- class sub-pattern to match a forwardslash
        .. '%z'                    -- class sub-pattern to match a null
        .. '\001' .. '-' .. '\031' -- class sub-pattern to match control characters
        .. ']'


    local LINE_SEPARATOR_as_utf8      = unicode_codepoint_as_utf8(0x2028)
    local PARAGRAPH_SEPARATOR_as_utf8 = unicode_codepoint_as_utf8(0x2029)
    local function json_string_literal(value, options)
        local newval = value:gsub(chars_to_be_escaped_in_JSON_string, backslash_replacement_function)
        if options.stringsAreUtf8 then
            --
            -- This feels really ugly to just look into a string for the sequence of bytes that we know to be a particular utf8 character,
            -- but utf8 was designed purposefully to make this kind of thing possible. Still, feels dirty.
            -- I'd rather decode the byte stream into a character stream, but it's not technically needed so
            -- not technically worth it.
            --
            newval = newval:gsub(LINE_SEPARATOR_as_utf8, '\\u2028'):gsub(PARAGRAPH_SEPARATOR_as_utf8, '\\u2029')
        end
        return '"' .. newval .. '"'
    end

    local function object_or_array(self, T, etc)
        --
        -- We need to inspect all the keys... if there are any strings, we'll convert to a JSON
        -- object. If there are only numbers, it's a JSON array.
        --
        -- If we'll be converting to a JSON object, we'll want to sort the keys so that the
        -- end result is deterministic.
        --
        local string_keys = {}
        local number_keys = {}
        local number_keys_must_be_strings = false
        local maximum_number_key

        for key in pairs(T) do
            if type(key) == 'string' then
                table.insert(string_keys, key)
            elseif type(key) == 'number' then
                table.insert(number_keys, key)
                if key <= 0 or key >= math.huge then
                    number_keys_must_be_strings = true
                elseif not maximum_number_key or key > maximum_number_key then
                    maximum_number_key = key
                end
            elseif type(key) == 'boolean' then
                table.insert(string_keys, tostring(key))
            else
                self:onEncodeError("can't encode table with a key of type " .. type(key), etc)
            end
        end

        if #string_keys == 0 and not number_keys_must_be_strings then
            --
            -- An empty table, or a numeric-only array
            --
            if #number_keys > 0 then
                return nil, maximum_number_key -- an array
            elseif tostring(T) == "JSON array" then
                return nil
            elseif tostring(T) == "JSON object" then
                return {}
            else
                -- have to guess, so we'll pick array, since empty arrays are likely more common than empty objects
                return nil
            end
        end

        table.sort(string_keys)

        local map
        if #number_keys > 0 then
            --
            -- If we're here then we have either mixed string/number keys, or numbers inappropriate for a JSON array
            -- It's not ideal, but we'll turn the numbers into strings so that we can at least create a JSON object.
            --

            if self.noKeyConversion then
                self:onEncodeError("a table with both numeric and string keys could be an object or array; aborting", etc)
            end

            --
            -- Have to make a shallow copy of the source table so we can remap the numeric keys to be strings
            --
            map = {}
            for key, val in pairs(T) do
                map[key] = val
            end

            table.sort(number_keys)

            --
            -- Throw numeric keys in there as strings
            --
            for _, number_key in ipairs(number_keys) do
                local string_key = tostring(number_key)
                if map[string_key] == nil then
                    table.insert(string_keys, string_key)
                    map[string_key] = T[number_key]
                else
                    self:onEncodeError(
                        "conflict converting table with mixed-type keys into a JSON object: key " ..
                        number_key .. " exists both as a string and a number.", etc)
                end
            end
        end

        return string_keys, nil, map
    end

    --
    -- Encode
    --
    -- 'options' is nil, or a table with possible keys:
    --
    --    pretty         -- If true, return a pretty-printed version.
    --
    --    indent         -- A string (usually of spaces) used to indent each nested level.
    --
    --    align_keys     -- If true, align all the keys when formatting a table. The result is uglier than one might at first imagine.
    --                      Results are undefined if 'align_keys' is true but 'pretty' is not.
    --
    --    array_newline  -- If true, array elements are formatted each to their own line. The default is to all fall inline.
    --                      Results are undefined if 'array_newline' is true but 'pretty' is not.
    --
    --    null           -- If this exists with a string value, table elements with this value are output as JSON null.
    --
    --    stringsAreUtf8 -- If true, consider Lua strings not as a sequence of bytes, but as a sequence of UTF-8 characters.
    --                      (Currently, the only practical effect of setting this option is that Unicode LINE and PARAGRAPH
    --                       separators, if found in a string, are encoded with a JSON escape instead of as raw UTF-8.
    --                       The JSON is valid either way, but encoding this way, apparently, allows the resulting JSON
    --                       to also be valid Java.)
    --
    --
    local function encode_value(self, value, parents, etc, options, indent, for_key)
        --
        -- keys in a JSON object can never be null, so we don't even consider options.null when converting a key value
        --
        if value == nil or (not for_key and options and options.null and value == options.null) then
            return 'null'
        elseif type(value) == 'string' then
            return json_string_literal(value, options)
        elseif type(value) == 'number' then
            if value ~= value then
                --
                -- NaN (Not a Number).
                -- JSON has no NaN, so we have to fudge the best we can. This should really be a package option.
                --
                return "null"
            elseif value >= math.huge then
                --
                -- Positive infinity. JSON has no INF, so we have to fudge the best we can. This should
                -- really be a package option. Note: at least with some implementations, positive infinity
                -- is both ">= math.huge" and "<= -math.huge", which makes no sense but that's how it is.
                -- Negative infinity is properly "<= -math.huge". So, we must be sure to check the ">="
                -- case first.
                --
                return "1e+9999"
            elseif value <= -math.huge then
                --
                -- Negative infinity.
                -- JSON has no INF, so we have to fudge the best we can. This should really be a package option.
                --
                return "-1e+9999"
            else
                return tostring(value)
            end
        elseif type(value) == 'boolean' then
            return tostring(value)
        elseif type(value) ~= 'table' then
            if self.unsupportedTypeEncoder then
                local user_value, user_error = self:unsupportedTypeEncoder(value, parents, etc, options, indent, for_key)
                -- If the user's handler returns a string, use that. If it returns nil plus an error message, bail with that.
                -- If only nil returned, fall through to the default error handler.
                if type(user_value) == 'string' then
                    return user_value
                elseif user_value ~= nil then
                    self:onEncodeError("unsupportedTypeEncoder method returned a " .. type(user_value), etc)
                elseif user_error then
                    self:onEncodeError(tostring(user_error), etc)
                end
            end

            self:onEncodeError("can't convert " .. type(value) .. " to JSON", etc)
        elseif getmetatable(value) == isNumber then
            return tostring(value)
        else
            --
            -- A table to be converted to either a JSON object or array.
            --
            local T = value

            if type(options) ~= 'table' then
                options = {}
            end
            if type(indent) ~= 'string' then
                indent = ""
            end

            if parents[T] then
                self:onEncodeError("table " .. tostring(T) .. " is a child of itself", etc)
            else
                parents[T] = true
            end

            local result_value

            local object_keys, maximum_number_key, map = object_or_array(self, T, etc)
            if maximum_number_key then
                --
                -- An array...
                --
                local key_indent
                if options.array_newline then
                    key_indent = indent .. tostring(options.indent or "")
                else
                    key_indent = indent
                end

                local ITEMS = {}
                for i = 1, maximum_number_key do
                    table.insert(ITEMS, encode_value(self, T[i], parents, etc, options, key_indent))
                end

                if options.array_newline then
                    result_value = "[\n" ..
                        key_indent .. table.concat(ITEMS, ",\n" .. key_indent) .. "\n" .. indent .. "]"
                elseif options.pretty then
                    result_value = "[ " .. table.concat(ITEMS, ", ") .. " ]"
                else
                    result_value = "[" .. table.concat(ITEMS, ",") .. "]"
                end
            elseif object_keys then
                --
                -- An object
                --
                local TT = map or T

                if options.pretty then
                    local KEYS = {}
                    local max_key_length = 0
                    for _, key in ipairs(object_keys) do
                        local encoded = encode_value(self, tostring(key), parents, etc, options, indent, true)
                        if options.align_keys then
                            max_key_length = math.max(max_key_length, #encoded)
                        end
                        table.insert(KEYS, encoded)
                    end
                    local key_indent = indent .. tostring(options.indent or "")
                    local subtable_indent = key_indent ..
                        string.rep(" ", max_key_length) .. (options.align_keys and "  " or "")
                    local FORMAT = "%s%" ..
                        string.format("%d", max_key_length + 1) .. "s: %s"

                    local COMBINED_PARTS = {}
                    for i, key in ipairs(object_keys) do
                        local encoded_val = encode_value(self, TT[key], parents, etc, options, subtable_indent)
                        table.insert(COMBINED_PARTS, string.format(FORMAT, key_indent, KEYS[i], encoded_val))
                    end
                    result_value = "{\n" .. table.concat(COMBINED_PARTS, ",\n") .. "\n" .. indent .. "}"
                else
                    local PARTS = {}
                    for _, key in ipairs(object_keys) do
                        local encoded_val = encode_value(self, TT[key], parents, etc, options, indent)
                        local encoded_key = encode_value(self, tostring(key), parents, etc, options, indent, true)
                        table.insert(PARTS, string.format("%s:%s", encoded_key, encoded_val))
                    end
                    result_value = "{" .. table.concat(PARTS, ",") .. "}"
                end
            else
                --
                -- An empty array/object... we'll treat it as an array, though it should really be an option
                --
                result_value = "[]"
            end

            parents[T] = false
            return result_value
        end
    end

    local function top_level_encode(self, value, etc, options)
        local val = encode_value(self, value, {}, etc, options)
        if val == nil then
            --PRIVATE("may need to revert to the previous public verison if I can't figure out what the guy wanted")
            return val
        else
            return val
        end
    end

    function OBJDEF:encode(value, etc, options)
        if type(self) ~= 'table' or self.__index ~= OBJDEF then
            OBJDEF:onEncodeError("JSON:encode must be called in method format", etc)
        end

        --
        -- If the user didn't pass in a table of decode options, make an empty one.
        --
        if type(options) ~= 'table' then
            options = {}
        end

        return top_level_encode(self, value, etc, options)
    end

    function OBJDEF:encode_pretty(value, etc, options)
        if type(self) ~= 'table' or self.__index ~= OBJDEF then
            OBJDEF:onEncodeError("JSON:encode_pretty must be called in method format", etc)
        end

        --
        -- If the user didn't pass in a table of decode options, use the default pretty ones
        --
        if type(options) ~= 'table' then
            options = default_pretty_options
        end

        return top_level_encode(self, value, etc, options)
    end

    function OBJDEF.__tostring()
        return "JSON encode/decode package"
    end

    OBJDEF.__index = OBJDEF

    function OBJDEF:new(args)
        local new = {}

        if args then
            for key, val in pairs(args) do
                new[key] = val
            end
        end

        return setmetatable(new, OBJDEF)
    end

    return OBJDEF:new()
end
--#endregion



--#region YimConfig

local function SetIndentation(n)
    local retStr = ""
    if n > 0 then
        for _ = 1, n do
            retStr = retStr .. " "
        end
    end
    return retStr
end

--[[**¤ Universal Config System For YimMenu-Lua ¤**

  - Inspired by by [Harmless](https://github.com/harmless05)'s config system.

  - Rewritten from scratch by [SAMURAI (xesdoog)](https://github.com/xesdoog).

  - Uses [JSON.lua package by Jeffrey Friedl](http://regex.info/blog/lua/json).
]]
---@class YimConfig
YimConfig = {}
YimConfig.__index = YimConfig
YimConfig._version_ = "1.0.4"
YimConfig._credits_ = [[
      +----------------------------------------------------------------------------------------+
      |                                                                                        |
      |                   ¤ Universal Config System For YimMenu-Lua ¤                          |
      |________________________________________________________________________________________|
      |                                                                                        |
      |      - Inspired by Harmless: https://github.com/harmless05                             |
      |                                                                                        |
      |      - Rewritten from scratch by SAMURAI (xesdoog): https://github.com/xesdoog)        |
      |                                                                                        |
      |      - Uses JSON.lua package by Jeffrey Friedl: http://regex.info/blog/lua/json        |
      |                                                                                        |
      +----------------------------------------------------------------------------------------+
    ]]


---@param script_name string Used to create and interact with the `.json` file.
---@param default_config table | string | number A default value or table with default values to be saved/loaded/overwritten.
---@param pretty_json? boolean **Optional:** Pretty encoding *(defaults to true)*.
---@param indent? number **Optional:** Number of indentations if **Pretty Encoding** is enabled *(defaults to 2)*.
---@param strict_parsing? boolean **Optional:** Strict Json parsing *(defaults to false)*.
---@param encryption_key? string **Optional:** Used to encrypt/decrypt config data.
function YimConfig:New(script_name, default_config, pretty_json, indent, strict_parsing, encryption_key)
    local instance = setmetatable({}, self)
    self.default_config = default_config
    self.file_name = string.format("%s.json", script_name:lower():gsub(" ", "_"))
    self.pretty = pretty_json or true
    self.indent = SetIndentation(indent or 2)
    self.strict_parsing = strict_parsing or false
    self.json = JSON()
    self.xor_key = encryption_key or "\xA3\x4F\xD2\x9B\x7E\xC1\xE8\x36\x5D\x0A\xF7\xB4\x6C\x2D\x89\x50\x1E\x73\xC9\xAF\x3B\x92\x58\xE0\x14\x7D\xA6\xCB\x81\x3F\xD5\x67"
    self.b64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    self.is_base64 = function(data)
        return #data % 4 == 0 and data:match("^[A-Za-z0-9+/]+=?=?$") ~= nil
    end

    if not io.exists(self.file_name) then
        self:Save(self.default_config)
    end

    assert(
        instance ~= nil and
        instance.default_config ~= nil,
        "YimConfig failed to load! Persistent config will be disabled for this script."
    )
    log.info(string.format("YimConfig v%s successfully loaded\n%s", YimConfig._version_, YimConfig._credits_))
    return instance
end

---@param data any
---@param etc? any
function YimConfig:Encode(data, etc)
    return self.json:encode(data, etc, { pretty = self.pretty, indent = self.indent })
end

---@param data any
---@param etc? any
function YimConfig:Decode(data, etc)
    return self.json:decode(data, etc, { strictParsing = self.strict_parsing or false })
end

---@param data any
function YimConfig:Save(data)
    local file, _ = io.open(self.file_name, "w")
    if not file then
        log.warning(
            "[ERROR] (YimConfig): Failed to open config file! YimConfig will not be able to read/write data. Your config will not be saved."
        )
        return
    end

    file:write(self:Encode(data))
    file:flush()
    file:close()
end

---@return any
function YimConfig:Read()
    if not io.exists(self.file_name) then
        log.warning(
            "[ERROR] (YimConfig): Failed to open config file! YimConfig will not be able to read/write data. Your config will not be saved."
        )
        return self.default_config
    end

    local file, _ = io.open(self.file_name, "r")
    if not file then
        log.warning(
            "[ERROR] (YimConfig): Failed to open config file! YimConfig will not be able to read/write data. Your config will not be saved."
        )
        return self.default_config
    end

    local data = file:read("a")
    file:close()
    if not data or #data == 0 then
        log.warning(
            "[ERROR] (YimConfig): Failed to open config file! YimConfig will not be able to read/write data. Your config will not be saved."
        )
        return self.default_config
    end

    if self.is_base64(data) then
        self:Decrypt()
        decrypted_data = self:Read()
        self:Encrypt()
        return decrypted_data
    end

    return self:Decode(data)
end

---@param item_name string
function YimConfig:ReadItem(item_name)
    local data = self:Read()
    if type(data) ~= "table" then
        log.warning("[ERROR] (YimConfig): Invalid data type!")
        return
    end

    return data[item_name]
end

---@param item_name string
---@param value any
function YimConfig:SaveItem(item_name, value)
    local data = self:Read()

    if type(data) ~= "table" then
        log.warning("[ERROR] (YimConfig): Invalid data type!")
        return
    end

    data[item_name] = value
    self:Save(data)
end

function YimConfig:Reset()
    self:Save(self.default_config)
end

function YimConfig:b64_encode(input)
    local output = {}
    local n = #input

    for i = 1, n, 3 do
        local a = input:byte(i) or 0
        local b = input:byte(i + 1) or 0
        local c = input:byte(i + 2) or 0
        local triple = (a << 16) | (b << 8) | c
        output[#output + 1] = self.b64_chars:sub(((triple >> 18) & 63) + 1, ((triple >> 18) & 63) + 1)
        output[#output + 1] = self.b64_chars:sub(((triple >> 12) & 63) + 1, ((triple >> 12) & 63) + 1)
        output[#output + 1] = (i + 1 <= n) and self.b64_chars:sub(((triple >> 6) & 63) + 1, ((triple >> 6) & 63) + 1) or "="
        output[#output + 1] = (i + 2 <= n) and self.b64_chars:sub((triple & 63) + 1, (triple & 63) + 1) or "="
    end

    return table.concat(output)
end

function YimConfig:b64_decode(input)
    local b64lookup = {}

    for i = 1, #self.b64_chars do
        b64lookup[self.b64_chars:sub(i, i)] = i - 1
    end

    input = input:gsub("%s", ""):gsub("=", "")
    local output = {}

    for i = 1, #input, 4 do
        local a = b64lookup[input:sub(i, i)] or 0
        local b = b64lookup[input:sub(i + 1, i + 1)] or 0
        local c = b64lookup[input:sub(i + 2, i + 2)] or 0
        local d = b64lookup[input:sub(i + 3, i + 3)] or 0
        local triple = (a << 18) | (b << 12) | (c << 6) | d
        output[#output + 1] = string.char((triple >> 16) & 255)
        if i + 2 <= #input then
            output[#output + 1] = string.char((triple >> 8) & 255)
        end
        if i + 3 <= #input then
            output[#output + 1] = string.char(triple & 255)
        end
    end

    return table.concat(output)
end

function YimConfig:xor_(input)
    local output = {}
    local key_len = #self.xor_key
    for i = 1, #input do
        local input_byte = input:byte(i)
        local key_byte = self.xor_key:byte((i - 1) % key_len + 1)
        output[i] = string.char(input_byte ~ key_byte)
    end
    return table.concat(output)
end

function YimConfig:Encrypt()
    local file, _ = io.open(self.file_name, "r")
    if not file then
        log.warning("[ERROR] (YimConfig): Failed to encrypt data! Unable to read config file.")
        return
    end

    local data = file:read("a")
    file:close()
    if not data or #data == 0 then
        log.warning("[ERROR] (YimConfig): Failed to encrypt config! Data is unreadable.")
        return
    end

    local xord = self:xor_(data)
    local b64 = self:b64_encode(xord)
    file, _ = io.open(self.file_name, "w")
    if file then
        file:write(b64)
        file:flush()
        file:close()
    end
end

function YimConfig:Decrypt()
    local file, _ = io.open(self.file_name, "r")
    if not file then
        log.warning("[ERROR] (YimConfig): Failed to decrypt data! Unable to read config file.")
        return
    end

    local data = file:read("a")
    file:close()
    if not data or #data == 0 then
        log.warning("[ERROR] (YimConfig): Failed to decrypt config! Data is unreadable.")
        return
    end

    if not self.is_base64(data) then
        log.warning("(YimConfig:Decrypt): Data is not encrypted!")
        return
    end

    local decoded = self:b64_decode(data)
    local decrypted = self:xor_(decoded)
    self:Save(self:Decode(decrypted))
end

return YimConfig
--#endregion
