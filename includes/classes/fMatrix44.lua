---@diagnostic disable: param-type-mismatch, unknown-operator

local EPSILON <const> = 1e-6

--------------------------------------
-- Class: fMatrix44
--------------------------------------
---@ignore -- no docs (unfinished)
---@class fMatrix44
---@field M11 float
---@field M12 float
---@field M13 float
---@field M14 float
---@field M21 float
---@field M22 float
---@field M23 float
---@field M24 float
---@field M31 float
---@field M32 float
---@field M33 float
---@field M34 float
---@field M41 float
---@field M42 float
---@field M43 float
---@field M44 float
---@operator mul(fMatrix44|number): fMatrix44
---@operator eq(fMatrix44): boolean
---@overload fun(...): fMatrix44
fMatrix44 = {}

fMatrix44.__index = fMatrix44
fMatrix44.__type = "fMatrix44"
setmetatable(fMatrix44, {
    __call = function(cls, ...)
        return cls:new(...)
    end,
})

---@param m11? float
---@param m12? float
---@param m13? float
---@param m14? float
---@param m21? float
---@param m22? float
---@param m23? float
---@param m24? float
---@param m31? float
---@param m32? float
---@param m33? float
---@param m34? float
---@param m41? float
---@param m42? float
---@param m43? float
---@param m44? float
function fMatrix44:new(
    m11, m12, m13, m14,
    m21, m22, m23, m24,
    m31, m32, m33, m34,
    m41, m42, m43, m44
)
    local instance = setmetatable({}, fMatrix44)
    instance.M11 = m11 or 1
    instance.M12 = m12 or 0
    instance.M13 = m13 or 0
    instance.M14 = m14 or 0

    instance.M21 = m21 or 0
    instance.M22 = m22 or 1
    instance.M23 = m23 or 0
    instance.M24 = m24 or 0

    instance.M31 = m31 or 0
    instance.M32 = m32 or 0
    instance.M33 = m33 or 1
    instance.M34 = m34 or 0

    instance.M41 = m41 or 0
    instance.M42 = m42 or 0
    instance.M43 = m43 or 0
    instance.M44 = m44 or 1
    return instance
end

function fMatrix44:assert(arg)
    assert(IsInstance(arg, self), _F("Invalid argument! Expected 4x4 matrix, got %s instead", type(arg)))
end

---@return fMatrix44
function fMatrix44:zero()
    return fMatrix44:new(
        0, 0, 0, 0,

        0, 0, 0, 0,

        0, 0, 0, 0,

        0, 0, 0, 0
    )
end

---@return boolean
function fMatrix44:is_zero()
    local r1 = self:R1()
    local r2 = self:R2()
    local r3 = self:R3()
    local r4 = self:R4()

    return (
        r1:is_zero() and
        r2:is_zero() and
        r3:is_zero() and
        r4:is_zero()
    )
end

---@return string
function fMatrix44:__tostring()
    return _F([[

      C1     C2     C3     C4
R1 [ %.3f, %.3f, %.3f, %.3f ]
R2 [ %.3f, %.3f, %.3f, %.3f ]
R3 [ %.3f, %.3f, %.3f, %.3f ]
R4 [ %.3f, %.3f, %.3f, %.3f ]
]],
        self.M11, self.M12, self.M13, self.M14,

        self.M21, self.M22, self.M23, self.M24,

        self.M31, self.M32, self.M33, self.M34,

        self.M41, self.M42, self.M43, self.M44
    )
end

---@param b fMatrix44|number
---@return fMatrix44
function fMatrix44:__mul(b)
    return self:multiply(b)
end

---@param b fMatrix44
---@return boolean
function fMatrix44:__eq(b)
    self:assert(b)

    return (
        math.abs(self.M11 - b.M11) < EPSILON and
        math.abs(self.M12 - b.M12) < EPSILON and
        math.abs(self.M13 - b.M13) < EPSILON and
        math.abs(self.M14 - b.M14) < EPSILON and
        math.abs(self.M21 - b.M21) < EPSILON and
        math.abs(self.M22 - b.M22) < EPSILON and
        math.abs(self.M23 - b.M23) < EPSILON and
        math.abs(self.M24 - b.M24) < EPSILON and
        math.abs(self.M31 - b.M31) < EPSILON and
        math.abs(self.M32 - b.M32) < EPSILON and
        math.abs(self.M33 - b.M33) < EPSILON and
        math.abs(self.M34 - b.M34) < EPSILON and
        math.abs(self.M41 - b.M41) < EPSILON and
        math.abs(self.M42 - b.M42) < EPSILON and
        math.abs(self.M43 - b.M43) < EPSILON and
        math.abs(self.M44 - b.M44) < EPSILON
    )
end

-- Returns the first row of the matrix (right).
---@return vec4
function fMatrix44:R1()
    return vec4:new(self.M11, self.M12, self.M13, self.M14)
end

-- Returns the second row of the matrix (forward).
---@return vec4
function fMatrix44:R2()
    return vec4:new(self.M21, self.M22, self.M23, self.M24)
end

-- Returns the third row of the matrix (up).
---@return vec4
function fMatrix44:R3()
    return vec4:new(self.M31, self.M32, self.M33, self.M34)
end

-- Returns the fourth row of the matrix (position).
---@return vec4
function fMatrix44:R4()
    return vec4:new(self.M41, self.M42, self.M43, self.M44)
end

-- Returns the first column of the matrix.
---@return vec4
function fMatrix44:C1()
    return vec4:new(self.M11, self.M21, self.M31, self.M41)
end

-- Returns the second column of the matrix.
---@return vec4
function fMatrix44:C2()
    return vec4:new(self.M12, self.M22, self.M32, self.M42)
end

-- Returns the third column of the matrix.
---@return vec4
function fMatrix44:C3()
    return vec4:new(self.M13, self.M23, self.M33, self.M43)
end

-- Returns the fourth column of the matrix.
---@return vec4
function fMatrix44:C4()
    return vec4:new(self.M14, self.M24, self.M34, self.M44)
end

-- Returns a copy of the matrix.
function fMatrix44:copy()
    return fMatrix44:new(
        self.M11, self.M12, self.M13, self.M14,
        self.M21, self.M22, self.M23, self.M24,
        self.M31, self.M32, self.M33, self.M34,
        self.M41, self.M42, self.M43, self.M44
    )
end

-- Returns a Vector4 transform from the matrix.
---@param v vec4
---@return vec4
function fMatrix44:transform_vec4(v)
    return vec4:new(
        self:R1():dot_product(v),
        self:R2():dot_product(v),
        self:R3():dot_product(v),
        self:R4():dot_product(v)
    )
end

-- Transposes the matrix into a new matrix: `new.row = this.column`
function fMatrix44:transpose()
    return fMatrix44:new(
        self.M11, self.M21, self.M31, self.M41,

        self.M12, self.M22, self.M32, self.M42,

        self.M13, self.M23, self.M33, self.M43,

        self.M14, self.M24, self.M34, self.M44
    )
end


---@param scale vec3
---@return fMatrix44
function fMatrix44:scale(scale)
    return fMatrix44:new(
        scale.x, 0, 0, 0,

        0, scale.y, 0, 0,

        0, 0, scale.z, 0,

        0, 0, 0, 1
    )
end

---@param axis vec3
---@param angle float rad
function fMatrix44:rotate(axis, angle)
    local result = fMatrix44:new(
        1, 0, 0, 0,

        0, 1, 0, 0,

        0, 0, 1, 0,

        0, 0, 0, 1
    )

    axis = axis:normalize()

    local x = axis.x
    local y = axis.y
    local z = axis.z

    local cos = math.cos(angle);
    local sin = math.sin(angle)
    local xx = x * x
    local yy = y * y
    local zz = z * z
    local xy = x * y
    local xz = x * z
    local yz = y * z

    result.M11 = xx + (cos * (1.0 - xx))
    result.M12 = (xy - (cos * xy)) + (sin * z)
    result.M13 = (xz - (cos * xz)) - (sin * y)

    result.M21 = (xy - (cos * xy)) - (sin * z)
    result.M22 = yy + (cos * (1.0 - yy))
    result.M23 = (yz - (cos * yz)) + (sin * x)

    result.M31 = (xz - (cos * xz)) + (sin * y)
    result.M32 = (yz - (cos * yz)) - (sin * x)
    result.M33 = zz + (cos * (1.0 - zz))

    return result
end

---@param b fMatrix44|number
---@return fMatrix44
function fMatrix44:multiply(b)
    if (type(b) == "number") then
        return fMatrix44:new(
            (self.M11 * b), (self.M12 * b), (self.M13 * b), (self.M14 * b),

            (self.M21 * b), (self.M22 * b), (self.M23 * b), (self.M24 * b),

            (self.M31 * b), (self.M32 * b), (self.M33 * b), (self.M34 * b),

            (self.M41 * b), (self.M42 * b), (self.M43 * b), (self.M44 * b)
        )
    end

    self:assert(b)

    local r1 = self:R1()
    local r2 = self:R2()
    local r3 = self:R3()
    local r4 = self:R4()

    local c1 = b:C1()
    local c2 = b:C2()
    local c3 = b:C3()
    local c4 = b:C4()

    return fMatrix44:new(
        r1:dot_product(c1), r1:dot_product(c2), r1:dot_product(c3), r1:dot_product(c4),

        r2:dot_product(c1), r2:dot_product(c2), r2:dot_product(c3), r2:dot_product(c4),

        r3:dot_product(c1), r3:dot_product(c2), r3:dot_product(c3), r3:dot_product(c4),

        r4:dot_product(c1), r4:dot_product(c2), r4:dot_product(c3), r4:dot_product(c4)
    )
end
