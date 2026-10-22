-- Direct V2 operations corresponding to the original MiniGameHack rules.
-- Credits: sch-lda and Samurai's Scripts; see the source third-party README.
local rules = {}
local function write(script_name, key, value, offsets, kind)
    local group = rules[script_name] or {}; rules[script_name] = group
    group[#group + 1] = { key = key, kind = kind or 'int', value = value, offsets = offsets }
end
for index, value in ipairs({ 0, 0, 7, 3, 7, 1, 8, 5, 2 }) do
    write('fm_mission_controller', 'mgh_fmmc_local_' .. index, value,
        ({ [4] = { 135 }, [5] = { 24 }, [6] = { 11 }, [7] = { 2 } })[index], index == 6 and 'float' or 'int')
end
for _, group in ipairs({ { 'fm_mission_controller_2020', 'mgh_fmmc20_local_' }, { 'fm_mission_controller_v3', 'mgh_fmmc_v3_local_' } }) do
    for index, value in ipairs({ 7, 3, 6, 100, 2 }) do
        local offsets = ({ [1] = { 24 }, [2] = { 135 }, [4] = group[1] == 'fm_mission_controller_v3' and { { 4, 13 }, 3 } or { 3 } })
            [index]
        write(group[1], group[2] .. index, value, offsets, index == 4 and 'float' or 'int')
    end
    write(group[1], group[2] .. 6, nil, nil, 'copy_state')
    write(group[1], group[2] .. 7, nil, nil, 'password')
end
write('fm_mission_controller_v3', 'mgh_fmmc_v3_local_8', nil, nil, 'eight_flags')
write('fm_mission_controller_v3', 'mgh_fmmc_v3_local_9', 5)
write('fm_mission_controller_v3', 'mgh_fmmc_v3_local_10', 5)
write('fm_mission_controller_v3', 'mgh_fmmc_v3_local_11', nil, { 1 }, 'combination')
for _, pair in ipairs({ { 'fm_content_island_heist', 'mgh_fm_c_ih_' }, { 'fm_content_vehrob_prep', 'mgh_fm_c_vehrob_prep_' } }) do
    write(pair[1], pair[2] .. 1, nil, nil, 'copy_state'); write(pair[1], pair[2] .. 2, 7, { 24 })
end
write('am_mp_arc_cab_manager', 'mgh_am_mp_arc_cab_magr_1', nil, nil, 'copy_state')
write('fm_content_business_battles', 'mgh_fm_c_bb', 7, { 24 })
write('am_mp_hotwire', 'mgh_hotwire', 2)
write('word_hack', 'mgh_wordhack', 5, { 53 })
write('circuitblockhack', 'mgh_circ_block_hack', 2, { 9 })
write('fm_content_hacker_house_finale', 'mgh_fm_c_hh_finale', 5, { 1 })
write('fm_content_stash_house', 'mgh_stash_house', nil, { 22 }, 'combination')
return rules
