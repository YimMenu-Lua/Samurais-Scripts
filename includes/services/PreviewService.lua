---@class PreviewService
PreviewService = {}
PreviewService.current = nil
PreviewService.currentModel = nil
PreviewService.currentPosition = nil
PreviewService.lastHovered = nil
PreviewService.hoverStartTime = 0
PreviewService.delay = 200 -- feels janky but prevents immediate spawn when hovering over an item
PreviewService.awaitSpawn = false


---@param i_ModelHash integer
---@param i_EntityType EntityType
function PreviewService:Preview(i_ModelHash, i_EntityType)
    script.run_in_fiber(function()
        if self.current then
            ENTITY.DELETE_ENTITY(self.current)
            self.current = nil
            self.currentPosition = nil
        end

        Await(Game.RequestModel, i_ModelHash)
        local i_Handle
        local v_Coords = vec3:zero()
        local f_GroundZ = 0.0
        local v_OffsetPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            Self.GetPedID(),
            1,
            5,
            0
        )

        _, f_GroundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
            v_OffsetPos.x,
            v_OffsetPos.y,
            v_OffsetPos.z,
            f_GroundZ,
            false,
            false
        )

        v_Coords = vec3:new(v_OffsetPos.x, v_OffsetPos.y, f_GroundZ + 0.5)

        if i_EntityType == 0 then
            i_Handle = Game.CreateObject(
                i_ModelHash,
                v_Coords,
                false,
                false,
                false,
                false,
                Self.GetHeading()
            )

        elseif i_EntityType == 1 then
            i_Handle = Game.CreateVehicle(
                i_ModelHash,
                v_Coords,
                Self.GetHeading(),
                false,
                false
            )

        elseif i_EntityType == 2 then
            i_Handle = Game.CreatePed(
                i_ModelHash,
                v_Coords,
                Self.GetHeading(),
                false,
                false
            )
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_Handle, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_Handle, true)
        end

        ENTITY.SET_ENTITY_ALPHA(i_Handle, 127, false)
        ENTITY.SET_ENTITY_INVINCIBLE(i_Handle, true)
        ENTITY.FREEZE_ENTITY_POSITION(i_Handle, true)
        ENTITY.SET_ENTITY_COLLISION(i_Handle, false, false)

        if Game.IsOnline() and ENTITY.DOES_ENTITY_EXIST(i_Handle) then
            Game.DesyncNetworkID(
                NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(i_Handle)
            )
        end

        self.current = i_Handle
        self.current_model = i_ModelHash
        self.currentPosition = v_Coords
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
            _, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(
                vec_Offset.x,
                vec_Offset.y,
                vec_Offset.z,
                groundZ,
                false,
                false
            )

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

---@param i_HoveredModelHash integer
---@param i_EntityType EntityType
function PreviewService:OnTick(i_HoveredModelHash, i_EntityType)
    local now = Time.millis()

    if i_HoveredModelHash ~= self.lastHovered then
        self.lastHovered    = i_HoveredModelHash
        self.hoverStartTime = now
        self.awaitSpawn     = true
    end

    if self.awaitSpawn and (now - self.hoverStartTime >= self.delay) then
        self.awaitSpawn = false
        self:Preview(i_HoveredModelHash, i_EntityType)
    end

    if self.current then
        self:Rotate()
    end
end

function PreviewService:Clear()
    script.run_in_fiber(function()
        if self.current and ENTITY.DOES_ENTITY_EXIST(self.current) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.current, true, true)
            ENTITY.DELETE_ENTITY(self.current)
        end

        self.current         = nil
        self.current_model   = nil
        self.currentPosition = nil
        self.lastHovered     = nil
        self.awaitSpawn      = false
        self.hoverStartTime  = 0
    end)
end

function PreviewService:Update()
    if self.current and not gui.is_open() then
        self:Clear()
    end
end
