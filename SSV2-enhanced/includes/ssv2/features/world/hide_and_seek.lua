local Feature = require('includes.ssv2.core.feature')
local Assets = require('includes.ssv2.core.assets')
local Geometry = require('includes.ssv2.core.geometry')
local dumpsters = { 'm23_2_prop_m32_dumpster_01a', 'prop_cs_dumpster_01a', 'prop_dumpster_01a',
    'prop_dumpster_02a', 'prop_dumpster_02b', 'prop_dumpster_3a', 'prop_dumpster_4a', 'prop_dumpster_4b', 'p_dumpster_t' }
local animations = {
    vehicle = { 'missmic3leadinout_mcs1', 'cockpit_pilot' },
    trash = { 'anim@amb@inspect@crouch@male_a@base', 'base' },
    trunk = { 'timetable@tracy@sleep@', 'base' }
}
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'hide_and_seek',
        category = 'world',
        path = 'features.world.hide_n_seek',
        assets = Assets.new(),
        next_scan = 0,
        next_input = 0,
        bin = 0,
        trunk = 0,
        hidden = false,
        controls = { { kind = 'toggle', path = 'features.world.hide_n_seek', label = 'WRLD_HNS', tooltip = 'WRLD_HNS_TT' } }
    })
    function f:ready(state)
        return state.alive and not ctx.game.swimming(state.handle) and not HUD.IS_PAUSE_MENU_ACTIVE()
            and not NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
    end

    function f:prompt(text)
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP('STRING')
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
        HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, false, -1)
    end

    function f:reset_actor(state)
        if ctx.features.self_misc then ctx.features.self_misc:cleanup() end
        TASK.CLEAR_PED_TASKS(state.handle); TASK.CLEAR_PED_SECONDARY_TASK(state.handle)
        PED.RESET_PED_MOVEMENT_CLIPSET(state.handle, 0.35)
        ctx.activity:acquire(self, 'playing')
        self.player = state.player_id
    end

    function f:cleanup()
        local ped = self.identity
        if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
            if self.hidden or self.phase then TASK.CLEAR_PED_TASKS(ped) end
            if self.attached then ENTITY.DETACH_ENTITY(ped, true, false) end
            if self.frozen then ENTITY.FREEZE_ENTITY_POSITION(ped, false) end
            if self.collision_disabled ~= nil then ENTITY.SET_ENTITY_COLLISION(ped, not self.collision_disabled, true) end
        end
        if self.door_open and self.trunk ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.trunk) then
            VEHICLE.SET_VEHICLE_DOOR_SHUT(self.trunk, 5, false)
        end
        if self.faded then CAMERA.DO_SCREEN_FADE_IN(200) end
        if self.player ~= nil then PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(self.player) end
        ctx.activity:release(self)
        self.hidden, self.phase, self.attached, self.frozen, self.faded, self.door_open = false, nil, false, false, false,
            false
        self.collision_disabled, self.context, self.target = nil, nil, 0
        self.bin, self.trunk = 0, 0
        self.assets:reset()
        self.next_input = util.time() + 1000
    end

    function f:animation(state, kind, flags, duration)
        local data = animations[kind]
        if not self.assets:animation(data[1]) then return false end
        TASK.TASK_PLAY_ANIM(state.handle, data[1], data[2], 4, -4, duration or -1, flags, 1, false, false, false)
        return true
    end

    function f:scan(state, now)
        if now < self.next_scan then return end
        self.next_scan = now + 1000
        local pos = state.ped:get_position()
        if self.bin ~= 0 and (not ENTITY.DOES_ENTITY_EXIST(self.bin)
                or Geometry.distance(pos, ENTITY.GET_ENTITY_COORDS(self.bin, false)) > 2) then
            self.bin = 0
        end
        if self.trunk ~= 0 and (not ENTITY.DOES_ENTITY_EXIST(self.trunk)
                or Geometry.distance(pos, ENTITY.GET_ENTITY_COORDS(self.trunk, false)) >= 3.5) then
            self.trunk = 0
        end
        if not state.on_foot or not ctx.game.outside(state.handle) or ctx.activity:busy() then return end
        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(state.handle)
        local search = Vector3.new(pos.x + forward.x * 1.2, pos.y + forward.y * 1.2, pos.z + forward.z * 1.2)
        if self.bin == 0 then
            for _, model in ipairs(dumpsters) do
                local bin = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(search.x, search.y, search.z, 1.5, util.joaat(model), false,
                    false, false)
                if bin ~= 0 and ENTITY.DOES_ENTITY_EXIST(bin)
                    and Geometry.distance(search, ENTITY.GET_ENTITY_COORDS(bin, false)) <= 1.3 then
                    self.bin = bin; break
                end
            end
        end
        if self.trunk == 0 then
            local vehicle = ctx.game.closest_vehicle(Vector3.new(pos.x + forward.x * 1.3, pos.y + forward.y * 1.3, pos.z),
                20, nil, false, 2)
            if vehicle == 0 or not VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(vehicle))
                or ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, 'boot') == -1 then
                return
            end
            local engine = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, 'engine')
            local wheel = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, 'wheel_lf')
            local rear = engine ~= -1 and wheel ~= -1 and
                Geometry.distance(ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(vehicle, engine),
                    ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(vehicle, wheel)) > 2 or false
            local minimum, maximum = ctx.game.model_dimensions(ENTITY.GET_ENTITY_MODEL(vehicle))
            local length = maximum.y - minimum.y
            local position, heading = ENTITY.GET_ENTITY_COORDS(vehicle, false), ENTITY.GET_ENTITY_FORWARD_VECTOR(vehicle)
            local offset = (rear and 1 or -1) * length / 1.6
            local boot = Vector3.new(position.x + heading.x * offset, position.y + heading.y * offset, position.z)
            if Geometry.distance(pos, boot) <= 1.5 then self.trunk, self.rear_engine = vehicle, rear end
        end
    end

    function f:begin(state, kind, target, now)
        if self.spotted then
            ctx.notifier:warn("Samurai's Scripts",
                "The cops have spotted you! You can't hide until they lose sight of you."); return
        end
        self:reset_actor(state)
        self.context, self.target, self.phase, self.deadline = kind, target, kind .. '_prepare', now
    end

    function f:advance(state, now)
        local ped = self.identity
        if now < self.deadline then return end
        if self.phase == 'vehicle_prepare' then
            local data = animations.vehicle
            if not self.assets:animation(data[1]) then return end
            TASK.TASK_PLAY_ANIM(ped, data[1], data[2], 6, 3, -1, 18, 1, false, false, false)
            VEHICLE.SET_VEHICLE_IS_WANTED(self.target, false)
            if state.driving then VEHICLE.SET_VEHICLE_ENGINE_ON(self.target, false, false, true) end
            self.hidden, self.phase, self.next_input = true, nil, now + 1000
        elseif self.phase == 'trash_prepare' then
            TASK.TASK_TURN_PED_TO_FACE_ENTITY(ped, self.target, 10)
            CAMERA.DO_SCREEN_FADE_OUT(500); self.faded = true
            self.phase, self.deadline = 'trash_attach', now + 1000
        elseif self.phase == 'trash_attach' then
            if not self.assets:animation(animations.trash[1]) then return end
            ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, self.target, -1, 0, 0.12, 1.13, 0, 0, 90, false, false, false, false, 20,
                true, 1)
            self.attached = true; self:animation(state, 'trash', 1)
            self.phase, self.deadline = 'trash_fade_in', now + 200
        elseif self.phase == 'trash_fade_in' then
            CAMERA.DO_SCREEN_FADE_IN(500); self.faded = false
            AUDIO.PLAY_SOUND_FRONTEND(-1, 'TRASH_BAG_LAND', 'DLC_HEIST_SERIES_A_SOUNDS', true)
            self.hidden, self.phase, self.next_input = true, nil, now + 1200
        elseif self.phase == 'trunk_prepare' then
            if not self.assets:animation('rcmnigel3_trunk') then return end
            if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY_IN_FRONT(ped, self.target) then
                TASK.TASK_TURN_PED_TO_FACE_ENTITY(ped, self.target, 0)
                self.phase = 'trunk_turn'; return
            end
            self.phase = 'trunk_turn'
        elseif self.phase == 'trunk_turn' then
            if TASK.GET_IS_TASK_ACTIVE(ped, 225) then return end
            TASK.TASK_PLAY_ANIM(ped, 'rcmnigel3_trunk', 'out_trunk_trevor', 4, -4, 1500, 2, 0, false, false, false)
            self.phase, self.deadline = 'trunk_freeze', now + 800
        elseif self.phase == 'trunk_freeze' then
            if not VEHICLE.IS_VEHICLE_STOPPED(self.target) then
                ctx.notifier:warn("Samurai's Scripts", 'Vehicle must be stopped.'); self:cleanup(); return
            end
            self.collision_disabled = ENTITY.GET_ENTITY_COLLISION_DISABLED(ped)
            ENTITY.FREEZE_ENTITY_POSITION(ped, true); self.frozen = true
            ENTITY.SET_ENTITY_COLLISION(ped, false, true)
            self.phase, self.deadline = 'trunk_open', now + 50
        elseif self.phase == 'trunk_open' then
            VEHICLE.SET_VEHICLE_DOOR_OPEN(self.target, 5, false, false); self.door_open = true
            self.phase, self.deadline = 'trunk_attach', now + 500
        elseif self.phase == 'trunk_attach' then
            if not self.assets:animation(animations.trunk[1]) then return end
            ENTITY.FREEZE_ENTITY_POSITION(ped, false); self.frozen = false
            local bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.target, 'chassis_dummy')
            local minimum, maximum = ctx.game.model_dimensions(ENTITY.GET_ENTITY_MODEL(self.target))
            local y = (self.rear_engine and 1 or -1) * (maximum.y - minimum.y) / 3
            local class = VEHICLE.GET_VEHICLE_CLASS(self.target)
            local z = class == 12 and 1.1 or class == 2 and 1.2 or 0.93
            self:animation(state, 'trunk', 2)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, self.target, bone == -1 and 0 or bone, -0.3, y, z, 180, 0, 0, false,
                false, false, false, 20, true, 1)
            self.attached = true; self.phase, self.deadline = 'trunk_close', now + 500
        elseif self.phase == 'trunk_close' then
            VEHICLE.SET_VEHICLE_DOOR_SHUT(self.target, 5, false); self.door_open = false
            ENTITY.SET_ENTITY_COLLISION(ped, not self.collision_disabled, true)
            VEHICLE.SET_VEHICLE_IS_WANTED(self.target, false)
            self.hidden, self.phase, self.next_input = true, nil, now + 1000
        elseif self.phase == 'trunk_exit_open' then
            ENTITY.DETACH_ENTITY(ped, true, false); self.attached = false
            TASK.CLEAR_PED_TASKS(ped)
            local out = self.exit_position
            ENTITY.SET_ENTITY_COORDS(ped, out.x, out.y, out.z, false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(ped, self.exit_heading)
            VEHICLE.SET_VEHICLE_DOOR_SHUT(self.target, 5, false); self.door_open = false
            self.phase, self.deadline = 'trunk_exit_finish', now + 200
        elseif self.phase == 'trunk_exit_finish' then
            if ENTITY.GET_ENTITY_SPEED(self.target) > 4 then PED.SET_PED_TO_RAGDOLL(ped, 1500, 0, 0, false, false, false) end
            self:cleanup()
        elseif self.phase == 'trash_exit_fade' then
            local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            local found, z = ctx.game.ground_z(pos)
            if not found then error('Could not find ground for dumpster exit') end
            ENTITY.DETACH_ENTITY(ped, true, false); self.attached = false
            ENTITY.SET_ENTITY_HEADING(ped, ENTITY.GET_ENTITY_HEADING(ped) + 90)
            TASK.CLEAR_PED_TASKS(ped)
            local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(ped)
            ENTITY.SET_ENTITY_COORDS(ped, pos.x + forward.x * 1.3, pos.y + forward.y * 1.3, z, false, false, false, false)
            CAMERA.DO_SCREEN_FADE_IN(500); self.faded = false
            AUDIO.PLAY_SOUND_FRONTEND(-1, 'TRASH_BAG_LAND', 'DLC_HEIST_SERIES_A_SOUNDS', true)
            self.phase = 'trash_exit_animation'
        elseif self.phase == 'trash_exit_animation' then
            if not self.assets:animation('move_m@_idles@shake_off') then return end
            TASK.TASK_PLAY_ANIM(ped, 'move_m@_idles@shake_off', 'shakeoff_1', 4, -4, 3000, 48, 0, false, false, false)
            self.phase, self.deadline = 'trash_exit_finish', now + 1000
        elseif self.phase == 'trash_exit_finish' then
            self:cleanup()
        end
    end

    function f:update(state)
        local now = util.time()
        self.spotted = PLAYER.IS_WANTED_AND_HAS_BEEN_SEEN_BY_COPS(state.player_id)
        self.wanted = PLAYER.GET_PLAYER_WANTED_LEVEL(state.player_id) > 0
        if (self.hidden or self.phase) and (not ENTITY.DOES_ENTITY_EXIST(self.target)
                or self.context == 'vehicle' and state.vehicle_handle ~= self.target) then
            self:cleanup(); return
        end
        if self.phase then
            self:advance(state, now); return
        end
        local input = now >= self.next_input and not ctx.input.blocked() and not HUD.IS_MP_TEXT_CHAT_TYPING()
        if not self.hidden then
            if state.on_foot then
                self:scan(state, now)
                local kind, target = self.bin ~= 0 and 'trash' or 'trunk', self.bin ~= 0 and self.bin or self.trunk
                if target ~= 0 then
                    self:prompt(kind == 'trash' and 'Press ~INPUT_PICKUP~ to hide in the dumpster.' or
                        'Press ~INPUT_PICKUP~ to hide in the trunk.')
                    if input and PAD.IS_CONTROL_JUST_PRESSED(0, 38) then self:begin(state, kind, target, now) end
                end
            elseif state.car and self.wanted and not self.spotted and (not state.driving or VEHICLE.IS_VEHICLE_STOPPED(state.vehicle_handle))
                and not PAD.IS_CONTROL_PRESSED(0, 71) and not PAD.IS_CONTROL_PRESSED(0, 72)
                and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(state.vehicle_handle) then
                self:prompt('Press ~INPUT_FRONTEND_ACCEPT~ to hide inside the vehicle.')
                if input and PAD.IS_CONTROL_JUST_PRESSED(0, 201) then
                    self:begin(state, 'vehicle', state.vehicle_handle,
                    now)
                end
            end
            return
        end
        if self.wanted and not self.spotted then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, math.random(-200, 200),
                math.random(-200, 200), math.random(0, 20))
            PED.SET_COP_PERCEPTION_OVERRIDES(0.1, 0.1, 0.1, 1, 1, 1, 0)
            PLAYER.SET_PLAYER_WANTED_CENTRE_POSITION(state.player_id, pos, true, false)
        end
        if self.context == 'vehicle' then
            if self.spotted then
                ctx.notifier:warn("Samurai's Scripts", 'You have been spotted by the cops!'); self:cleanup(); return
            end
            self:prompt('Press ~INPUT_FRONTEND_ACCEPT~ or ~INPUT_VEH_ACCELERATE~ or ~INPUT_VEH_BRAKE~ to stop hiding.')
            if input and (PAD.IS_CONTROL_JUST_PRESSED(0, 201) or PAD.IS_CONTROL_PRESSED(0, 71) or PAD.IS_CONTROL_PRESSED(0, 72)) then
                if state.driving then VEHICLE.SET_VEHICLE_ENGINE_ON(self.target, true, false, false) end
                self:cleanup()
            end
        else
            self:prompt('Press ~INPUT_PICKUP~ to get out.')
            if input and PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
                if self.context == 'trash' then
                    CAMERA.DO_SCREEN_FADE_OUT(500); self.faded = true
                    self.phase, self.deadline = 'trash_exit_fade', now + 1000
                else
                    local pos = ENTITY.GET_ENTITY_COORDS(state.handle, false)
                    local found, z = ctx.game.ground_z(pos)
                    if not found then error('Could not find ground for trunk exit') end
                    local out = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0,
                        self.rear_engine and 2 or -2, 0)
                    self.exit_position = Vector3.new(out.x, out.y, z)
                    self.exit_heading = ENTITY.GET_ENTITY_HEADING(self.target) - (self.rear_engine and 0 or 180)
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(self.target, 5, false, false); self.door_open = true
                    self.phase, self.deadline = 'trunk_exit_open', now + 500
                end
            end
        end
    end

    return f
end
