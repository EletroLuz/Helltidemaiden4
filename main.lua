-- Import modules
local menu = require("menu")
menu.plugin_enabled:set(false)
local menu_renderer = require("graphics.menu_renderer")
local revive = require("data.revive")
local explorer = require("data.explorer")
local automindcage = require("data.automindcage")
local actors = require("data.actors")
local waypoint_loader = require("functions.waypoint_loader")
local interactive_patterns = require("enums.interactive_patterns")
local Movement = require("functions.movement")
local ChestsInteractor = require("functions.chests_interactor")
local teleport = require("data.teleport")
local GameStateChecker = require("functions.game_state_checker")
local maidenmain = require("data.maidenmain")
maidenmain.init()

-- Initialize variables
local plugin_enabled = false
local doorsEnabled = false
local loopEnabled = false
local revive_enabled = false
local profane_mindcage_enabled = false
local profane_mindcage_count = 0
local graphics_enabled = false
local was_in_helltide = false
local last_cleanup_time = 0
local cleanup_interval = 300 -- 5 minutos
local maidenmain_enabled = false

local function periodic_cleanup()
    local current_time = os.clock()
    if current_time - last_cleanup_time > cleanup_interval then
        collectgarbage("collect")
        ChestsInteractor.clearInteractedObjects()
        waypoint_loader.clear_cached_waypoints()
        last_cleanup_time = current_time
        console.print("Periodic cleanup performed")
    end
end

-- Function to update menu states
local function update_menu_states()
    local new_plugin_enabled = menu.plugin_enabled:get()
    local new_maidenmain_enabled = maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:get()

    -- Garantir que apenas um plugin esteja ativo
    if new_plugin_enabled and new_maidenmain_enabled then
        if plugin_enabled then
            new_maidenmain_enabled = false
            maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:set(false)
            console.print("Maidenmain plugin disabled due to conflict with main plugin")
        else
            new_plugin_enabled = false
            menu.plugin_enabled:set(false)
            console.print("Main plugin disabled due to conflict with Maidenmain plugin")
        end
    end

    -- Atualizar plugin principal
    if new_plugin_enabled ~= plugin_enabled then
        plugin_enabled = new_plugin_enabled
        console.print("Movement Plugin " .. (plugin_enabled and "enabled" or "disabled"))
        if plugin_enabled then
            local waypoints, _ = waypoint_loader.check_and_load_waypoints()
            Movement.set_waypoints(waypoints)
            Movement.set_moving(true)
        else
            Movement.save_last_index()
            Movement.set_moving(false)
        end
    end

    -- Atualizar Maidenmain
    if new_maidenmain_enabled ~= maidenmain_enabled then
        maidenmain_enabled = new_maidenmain_enabled
        console.print("Maidenmain Plugin " .. (maidenmain_enabled and "enabled" or "disabled"))
        if maidenmain_enabled then
            local world_instance = world.get_current_world()
            local zone_name = world_instance:get_current_zone_name()
            for _, tp in ipairs(waypoint_loader.helltide_tps) do
                if zone_name == tp.name then
                    local waypoints = waypoint_loader.load_maiden_route(tp.file)
                    Movement.set_waypoints(waypoints)
                    Movement.set_moving(true)
                    break
                end
            end
            -- Desabilitar o loop quando Maidenmain está ativo
            loopEnabled = false
            menu.loop_enabled:set(false)
        else
            Movement.save_last_index()
            Movement.set_moving(false)
        end
    end

    -- Atualizar outras configurações apenas se o plugin principal estiver ativo
    if plugin_enabled then
        doorsEnabled = menu.main_openDoors_enabled:get()
        loopEnabled = menu.loop_enabled:get()
    else
        doorsEnabled = false
        loopEnabled = false
    end

    revive_enabled = menu.revive_enabled:get()
    profane_mindcage_enabled = menu.profane_mindcage_toggle:get()
    profane_mindcage_count = menu.profane_mindcage_slider:get()

    -- Update maidenmain menu states
    maidenmain.update_menu_states()
end


-- Main update function
on_update(function()
    update_menu_states()

    if plugin_enabled or maidenmain_enabled then
        periodic_cleanup()
        
        local game_state = GameStateChecker.check_game_state()

        if game_state == "loading_or_limbo" then
            console.print("Loading or in Limbo. Pausing operations.")
            return
        end

        if game_state == "no_player" then
            console.print("No player detected. Waiting for player.")
            return
        end

        local local_player = get_local_player()
        local world_instance = world.get_current_world()
        
        local teleport_state = teleport.get_teleport_state()

        if teleport_state ~= "idle" then
            if teleport.tp_to_next(ChestsInteractor, Movement) then
                console.print("Teleport completed. Loading new waypoints...")
                local waypoints
                if maidenmain_enabled then
                    local zone_name = world_instance:get_current_zone_name()
                    for _, tp in ipairs(waypoint_loader.helltide_tps) do
                        if zone_name == tp.name then
                            waypoints = waypoint_loader.load_maiden_route(tp.file)
                            break
                        end
                    end
                else
                    waypoints, _ = waypoint_loader.check_and_load_waypoints()
                end
                Movement.set_waypoints(waypoints)
                Movement.set_moving(true)
            end
        else
            if game_state == "helltide" then
                if not was_in_helltide then
                    console.print("Entered Helltide. Initializing Helltide operations.")
                    was_in_helltide = true
                    Movement.reset()
                    local waypoints
                    if maidenmain_enabled then
                        local zone_name = world_instance:get_current_zone_name()
                        for _, tp in ipairs(waypoint_loader.helltide_tps) do
                            if zone_name == tp.name then
                                waypoints = waypoint_loader.load_maiden_route(tp.file)
                                break
                            end
                        end
                    else
                        waypoints, _ = waypoint_loader.check_and_load_waypoints()
                    end
                    Movement.set_waypoints(waypoints)
                    Movement.set_moving(true)
                    ChestsInteractor.clearInteractedObjects()
                    ChestsInteractor.clearBlacklist()
                end
                
                if profane_mindcage_enabled then
                    automindcage.update()
                end
                ChestsInteractor.interactWithObjects(doorsEnabled, interactive_patterns)
                Movement.pulse(plugin_enabled or maidenmain_enabled, loopEnabled, teleport)
                if revive_enabled then
                    revive.check_and_revive()
                end
                actors.update()

                -- Update maidenmain apenas se estiver ativo
                if maidenmain_enabled then
                    local current_position = local_player:get_position()
                    maidenmain.update(menu, current_position, maidenmain.menu_elements.main_helltide_maiden_auto_plugin_explorer_circle_radius:get())
                end
            else
                if was_in_helltide then
                    console.print("Helltide ended. Performing cleanup.")
                    Movement.reset()
                    ChestsInteractor.clearInteractedObjects()
                    ChestsInteractor.clearBlacklist()
                    was_in_helltide = false
                    teleport.reset()
                    if maidenmain_enabled then
                        maidenmain.clearBlacklist()
                    end
                end

                console.print("Not in the Helltide zone. Attempting to teleport...")
                if teleport.tp_to_next(ChestsInteractor, Movement) then
                    console.print("Teleported successfully. Loading new waypoints...")
                    local waypoints
                    if maidenmain_enabled then
                        local zone_name = world_instance:get_current_zone_name()
                        for _, tp in ipairs(waypoint_loader.helltide_tps) do
                            if zone_name == tp.name then
                                waypoints = waypoint_loader.load_maiden_route(tp.file)
                                break
                            end
                        end
                    else
                        waypoints, _ = waypoint_loader.check_and_load_waypoints()
                    end
                    Movement.set_waypoints(waypoints)
                    Movement.set_moving(true)
                else
                    local state = teleport.get_teleport_state()
                    console.print("Teleport in progress. Current state: " .. state)
                end
            end
        end
    end
end)

-- Render menu function
on_render_menu(function()
    menu_renderer.render_menu(plugin_enabled, doorsEnabled, loopEnabled, revive_enabled, profane_mindcage_enabled, profane_mindcage_count)
    
    -- Adicionar aviso sobre exclusividade dos plugins
    graphics.draw_text(vec2:new(10, 30), "Apenas um plugin pode estar ativo por vez!", color.new(255, 255, 0, 255))
    
    -- Render maidenmain menu
    maidenmain.render_menu()
end)

-- Render function for maidenmain
on_render(function()
    if maidenmain_enabled then
        maidenmain.render()
    end
end)

console.print(">>Helltide Chests Farmer Eletroluz V1.5 with Maidenmain integration<<")