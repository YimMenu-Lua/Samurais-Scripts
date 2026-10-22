local Geometry = {}
function Geometry.distance(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2) end

function Geometry.normalize(value)
    local length = math.sqrt(value.x ^ 2 + value.y ^ 2 + value.z ^ 2)
    if length == 0 then return Vector3.new() end
    return Vector3.new(value.x / length, value.y / length, value.z / length)
end

function Geometry.direction(rotation)
    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
    local horizontal = math.abs(math.cos(pitch))
    return Vector3.new(-math.sin(yaw) * horizontal, math.cos(yaw) * horizontal, math.sin(pitch))
end

function Geometry.lerp(a, b, fraction)
    return Vector3.new(a.x + (b.x - a.x) * fraction, a.y + (b.y - a.y) * fraction, a.z + (b.z - a.z) * fraction)
end

return Geometry
