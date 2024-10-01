local menu = require("menu")
local heart_insertion = require("functions/heart_insertion")
local circular_movement = require("functions/circular_movement")

-- Global variables
local maiden_positions = {
    vec3:new(-1982.549438, -1143.823364, 12.758240),
    vec3:new(-1517.776733, -20.840151, 105.299805),
    vec3:new(120.874367, -746.962341, 7.089052),
    vec3:new(-680.988770, 725.340576, 0.389648),
    vec3:new(-1070.214600, 449.095276, 16.321373),
    vec3:new(-464.924530, -327.773132, 36.178608)
}
local helltide_final_maidenpos = maiden_positions[1]
local explorer_circle_radius = 15.0
local explorer_point = nil

-- Menu configuration
local plugin_label = "HELLTIDE_MAIDEN_AUTO_PLUGIN_"
local menu_elements = {
    main_helltide_maiden_auto_plugin_enabled = checkbox:new(false, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_enabled")),
    main_helltide_maiden_auto_plugin_run_explorer = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_run_explorer")),
    main_helltide_maiden_auto_plugin_auto_revive = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_auto_revive")),
    main_helltide_maiden_auto_plugin_show_task = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_show_task")),
    main_helltide_maiden_auto_plugin_show_explorer_circle = checkbox:new(true, get_hash("main_helltide_maiden_auto_plugin_show_explorer_circle")),
    main_helltide_maiden_auto_plugin_run_explorer_close_first = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_run_explorer_close_first")),
    main_helltide_maiden_auto_plugin_explorer_threshold = slider_float:new(0.0, 20.0, 1.5, get_hash("main_helltide_maiden_auto_plugin_explorer_threshold")),
    main_helltide_maiden_auto_plugin_explorer_thresholdvar = slider_float:new(0.0, 10.0, 3.0, get_hash("main_helltide_maiden_auto_plugin_explorer_thresholdvar")),
    main_helltide_maiden_auto_plugin_explorer_circle_radius = slider_float:new(5.0, 30.0, 15.0, get_hash("main_helltide_maiden_auto_plugin_explorer_circle_radius")),
    main_helltide_maiden_auto_plugin_insert_hearts = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_insert_hearts")),
    main_helltide_maiden_auto_plugin_insert_hearts_interval_slider = slider_float:new(0.0, 600.0, 300.0, get_hash("main_helltide_maiden_auto_plugin_insert_hearts_interval_slider")),
    main_helltide_maiden_auto_plugin_insert_hearts_afterboss = checkbox:new(false, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_insert_hearts_afterboss")),
    main_helltide_maiden_auto_plugin_insert_hearts_onlywithnpcs = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_insert_hearts_onlywithnpcs")),
    main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies")),
    main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies_interval_slider = slider_float:new(2.0, 600.0, 10.0, get_hash("main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies_interval_slider")),
    main_helltide_maiden_auto_plugin_reset = checkbox:new(false, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_reset")),
    main_tree = tree_node:new(0),
}

local maidenmain = {}
maidenmain.menu_elements = menu_elements

-- Função para encontrar a posição da maiden mais próxima
local function find_nearest_maiden_position()
    local player = get_local_player()
    if not player then return end

    local player_pos = player:get_position()
    local nearest_pos = maiden_positions[1]
    local nearest_dist = player_pos:dist_to(nearest_pos)

    for i = 2, #maiden_positions do
        local dist = player_pos:dist_to(maiden_positions[i])
        if dist < nearest_dist then
            nearest_pos = maiden_positions[i]
            nearest_dist = dist
        end
    end

    return nearest_pos
end

function maidenmain.update_menu_states()
    explorer_circle_radius = menu_elements.main_helltide_maiden_auto_plugin_explorer_circle_radius:get()
end

function maidenmain.update(menu, current_position, explorer_circle_radius)
    local local_player = get_local_player()
    if not local_player then
        return
    end

    if not menu_elements.main_helltide_maiden_auto_plugin_enabled:get() then
        return
    end

    helltide_final_maidenpos = find_nearest_maiden_position()

    if menu_elements.main_helltide_maiden_auto_plugin_insert_hearts:get() then
        heart_insertion.update(menu_elements, helltide_final_maidenpos, explorer_circle_radius)
    end

    if menu_elements.main_helltide_maiden_auto_plugin_run_explorer:get() then
        explorer_point = circular_movement.update(menu_elements, helltide_final_maidenpos, explorer_circle_radius)
    end
end

function maidenmain.render_menu()
    if menu_elements.main_tree:push("Mera-Helltide Maiden Auto v1.3") then
        menu_elements.main_helltide_maiden_auto_plugin_enabled:render("Enable Plugin", "Enable or disable this plugin")
        
        menu_elements.main_helltide_maiden_auto_plugin_run_explorer:render("Run Explorer at Maiden", "Walks in circles around the helltide boss maiden within the exploration circle radius.")
        if menu_elements.main_helltide_maiden_auto_plugin_run_explorer:get() then
            menu_elements.main_helltide_maiden_auto_plugin_run_explorer_close_first:render("Explorer Runs to Enemies First", "Focuses on close and distant enemies and then tries random positions")
            menu_elements.main_helltide_maiden_auto_plugin_explorer_threshold:render("Movement Threshold", "Slows down the selection of new positions for anti-bot behavior", 2)
            menu_elements.main_helltide_maiden_auto_plugin_explorer_thresholdvar:render("Randomizer", "Adds random threshold on top of movement threshold for more randomness", 2)
            menu_elements.main_helltide_maiden_auto_plugin_explorer_circle_radius:render("Limit Exploration", "Limit exploration location", 2)
        end

        menu_elements.main_helltide_maiden_auto_plugin_auto_revive:render("Auto Revive", "Automatically revive upon death")
        menu_elements.main_helltide_maiden_auto_plugin_show_task:render("Show Task", "Show current task in the top left corner of the screen")
        
        menu_elements.main_helltide_maiden_auto_plugin_insert_hearts:render("Insert Hearts", "Will try to insert hearts after reaching the heart timer, requires available hearts")
        if menu_elements.main_helltide_maiden_auto_plugin_insert_hearts:get() then
            menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_interval_slider:render("Insert Interval", "Time interval to try inserting hearts", 2)
            menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_afterboss:render("Insert Heart After Maiden Death", "Insert heart directly after the helltide boss maiden's death")
            menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies:render("Insert Heart After No Enemies", "Insert heart after seeing no enemies for a particular time in the circle")
            if menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies:get() then
                menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_afternoenemies_interval_slider:render("No Enemies Timer", "Time in seconds after trying to insert heart when no enemy is seen", 2)
            end
            menu_elements.main_helltide_maiden_auto_plugin_insert_hearts_onlywithnpcs:render("Insert Only If Players In Range", "Insert hearts only if players are in range, can disable all other features if no player is seen at the altar")
        end

        menu_elements.main_helltide_maiden_auto_plugin_show_explorer_circle:render("Draw Explorer Circle", "Show Exploration Circle to check walking range (white) and target walking points (blue)")
        
        menu_elements.main_helltide_maiden_auto_plugin_reset:render("Reset (do not keep on)", "Temporarily enable reset mode to reset the plugin")

        menu_elements.main_tree:pop()
    end
end

function maidenmain.render()
    if not menu_elements.main_helltide_maiden_auto_plugin_enabled:get() then
        return
    end

    if menu_elements.main_helltide_maiden_auto_plugin_show_explorer_circle:get() then
        if helltide_final_maidenpos then
            local color_white = color.new(255, 255, 255, 255)
            local color_blue = color.new(0, 0, 255, 255)
            
            graphics.circle_3d(helltide_final_maidenpos, explorer_circle_radius, color_white)

            if explorer_point then
                graphics.circle_3d(explorer_point, 2, color_blue)
            end
        end
    end

    local color_red = color.new(255, 0, 0, 255)
    for _, pos in ipairs(maiden_positions) do
        graphics.circle_3d(pos, 2, color_red)
    end
end

function maidenmain.clearBlacklist()
    -- Implement blacklist clearing logic here
end

console.print("Lua Plugin - Helltide Maiden Auto - Version 1.3")

return maidenmain