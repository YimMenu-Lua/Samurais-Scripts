---@class PreviewService
PreviewService = {}
PreviewService.current = nil
PreviewService.currentModel = nil
PreviewService.currentPosition = nil
PreviewService.lastHovered = nil
PreviewService.hoverStartTime = 0
PreviewService.delay = 200 -- feels janky but prevents immediate spawn when hovering over an item
PreviewService.awaitSpawn = false


---@param model integer
---@param entity_type EntityType
---@param ped_type? integer
function PreviewService:Preview(model, entity_type, ped_type)
    script.run_in_fiber(function()
        if self.current then
            ENTITY.DELETE_ENTITY(self.current)
            self.current = nil
            self.currentPosition = nil
        end

        if Game.RequestModel(model) then
            local handle
            local groundZ = 0
            local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Self.GetPedID(), 1, 5, 0)
            _, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(offset.x, offset.y, offset.z, groundZ, false, false)
            local coords = vec3:new(offset.x, offset.y, groundZ + 0.5)

            if entity_type == 0 then
                handle = OBJECT.CREATE_OBJECT(
                    model,
                    coords.x,
                    coords.y,
                    coords.z,
                    true,
                    true,
                    false
                )
            elseif entity_type == 1 then
                handle = VEHICLE.CREATE_VEHICLE(
                    model,
                    coords.x,
                    coords.y,
                    groundZ,
                    Self.GetHeading(),
                    true,
                    false,
                    false
                )
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(handle, 5.0)
            elseif entity_type == 2 then
                handle = PED.CREATE_PED(
                    ped_type or PED_TYPE._CIVMALE,
                    model,
                    coords.x,
                    coords.y,
                    coords.z,
                    Self.GetHeading(),
                    true,
                    false
                )
            end

            ENTITY.SET_ENTITY_ALPHA(handle, 127, false)
            ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
            ENTITY.FREEZE_ENTITY_POSITION(handle, true)
            ENTITY.SET_ENTITY_COLLISION(handle, false, false)

            self.current = handle
            self.current_model = model
            self.currentPosition = coords
        end
    end)
end

function PreviewService:Rotate()
    script.run_in_fiber(function ()
        if not self.current or not ENTITY.DOES_ENTITY_EXIST(self.current) then
            return
        end

        local heading = ENTITY.GET_ENTITY_HEADING(self.current)
        ENTITY.SET_ENTITY_HEADING(self.current, (heading - 0.3) % 360)

        if Self.IsMoving() then
            local groundZ = 0
            local vec_Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Self.GetPedID(), 1, 5, 0)
            _, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(vec_Offset.x, vec_Offset.y, vec_Offset.z, groundZ, false, false)
            self.currentPosition = vec3:new(vec_Offset.x, vec_Offset.y, groundZ + 0.5)
            ENTITY.SET_ENTITY_COORDS(
                self.current,
                self.currentPosition.x,
                self.currentPosition.y,
                self.currentPosition.z,
                false,
                false,
                false,
                false
            )
        end
    end)
end

function PreviewService:Clear()
    script.run_in_fiber(function()
        if self.current and ENTITY.DOES_ENTITY_EXIST(self.current) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.current, true, true)
            ENTITY.DELETE_ENTITY(self.current)
        end

        self.current = nil
        self.current_model = nil
        self.currentPosition = nil
        self.lastHovered = nil
        self.awaitSpawn = false
        self.hoverStartTime = 0
    end)
end

---@param entity_type EntityType
---@param ped_type? integer
function PreviewService:OnTick(hoveredModel, entity_type, ped_type)
    local now = os.clock() * 1000

    if hoveredModel ~= self.lastHovered then
        self.lastHovered = hoveredModel
        self.hoverStartTime = now
        self.awaitSpawn = true
    end

    if self.awaitSpawn and (now - self.hoverStartTime >= self.delay) then
        self.awaitSpawn = false
        self:Preview(hoveredModel, entity_type, ped_type)
    end

    if self.current then
        self:Rotate()
    end
end

function PreviewService:Update()
    if self.current and not gui.is_open() then
        self:Clear()
    end
end
