-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@meta
---@diagnostic disable: duplicate-doc-field

--#region Generic Containers

---@alias GuiCallback function

---@class array<T> : { [integer]: T }
---@class dict<T> : { [string]: T }
---@class pair<K, V>: { first: K, second: V } -- Not the same as the `Pair` module. This represents a simple table, the other is a module with metamethods.
---@class set<T>: { [T]: true } -- Not the same as the `Set` module. This represents a simple table, the other is a module with metamethods.
---@class tuple<T1, T2>: { [1]: T1, [2]: T2 }

---@generic V
---@alias ValueOrFunction fun():V|V

---@generic T
---@class GenericClass<T>
---@field m_size uint16_t
GenericClass = setmetatable({}, {
	__index = { m_size = 0x40, __type = "GenericClass" },
	__newindex = function(...)
		error("Attempt to modify read-only Generic Class!")
	end,
	__metatable = false
})

---@alias Obj table|metatable|userdata|Callable|ClassMeta|CStructBase

---@class Enum
---@field public First fun(self: Enum): integer Returns the first value of the enum.
---@field public Keys fun(self: Enum): string[] Returns an array of all enum keys.
---@field public Values fun(self: Enum): integer[] Returns an array of all enum values.
---@field public NameOf fun(self: Enum, value: integer): string Returns the key name of `value`.
---@field public Has fun(self: Enum, value: integer): boolean Returns whether the enum has `value`
---@field private __sizeof fun(self: Enum): integer Used internally to get the symbolic size of the enum. If it's an enum of joaa_t -> Size = 0x4.
---@field private __enum boolean Used internally to flag this as an enum.
---@field private __data_type? string Optional: "int8_t" | "int16_t" | "int32_t" | "int64_t" | "uint8_t" | "uint16_t" | "uint32_t"| "uint64_t" | "joaat_t" | "float" | "byte" Used internally to define the data type so that SizeOf or the internal __sizeof can immediately lookup the size without invoking integer inference.

--#endregion

--#region Primitives

-- Time in seconds.
---@class seconds: number
-- Time in milliseconds.
---@class milliseconds: number
---@class int8_t: integer
---@class int16_t: integer
---@class int32_t: integer
---@class int64_t: integer
---@class uint8_t: integer
---@class uint16_t: integer
---@class uint32_t: integer
---@class uint64_t: integer
---@class joaat_t: uint32_t
---@class byte: int8_t
---@class float: number
---@class bool: boolean
---@class ID: integer
-- RAGE entity script handle
---@class handle: integer
-- RAGE JOAAT hash
---@class hash: joaat_t

---@class pointer_ref
---@field deref fun(self: pointer_ref): pointer|nullptr
---@field get_address fun(self: pointer_ref): uint64_t
---@field is_null fun(self: pointer_ref): boolean
---@field is_valid fun(self: pointer_ref): boolean

---@alias anyval<T> table|metatable|userdata|lightuserdata|function|string|number|boolean Any Lua value except nil.
---@alias optional<T> T?

-- LuaLS has these fields defined as integer|string which is annoying as fuck
---@class osdatefixed : osdate
---@field year  integer
---@field month integer
---@field day   integer
---@field hour  integer
---@field min   integer
---@field sec   integer

--#endregion

--#region Functional Types

---@alias Callback function
---@alias Predicate<P1, P2, P3, P4, P5> fun(p1: P1, p2?: P2, p3?: P3, p4?: P4, p5?: P5): boolean
---@alias Comparator<A, B> fun(a: A, b: B): boolean

---@type boolean
_G.FAKE_YIMAPI = _G.FAKE_YIMAPI or false

--#endregion
