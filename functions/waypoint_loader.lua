-- functions/waypoint_loader.lua

local waypoint_loader = {}
local cached_waypoints = {}

function waypoint_loader.load_waypoints(file)
    if cached_waypoints[file] then
        return cached_waypoints[file]
    end
    local waypoints = require("waypoints." .. file)
    cached_waypoints[file] = waypoints
    return waypoints
end

function waypoint_loader.clear_cached_waypoints()
    cached_waypoints = {}
    collectgarbage("collect")
end

-- Defina as variáveis necessárias (se não forem globais)
waypoint_loader.helltide_tps = {
    {name = "Frac_Tundra_S", id = 0xACE9B, file = "menestad"},
    {name = "Scos_Coast", id = 0x27E01, file = "marowen"},
    {name = "Kehj_Oasis", id = 0xDEAFC, file = "ironwolfs"},
    {name = "Hawe_Verge", id = 0x9346B, file = "wejinhani"},
    {name = "Step_South", id = 0x462E2, file = "jirandai"}
}

-- Função para randomizar waypoints
function waypoint_loader.randomize_waypoint(waypoint, max_offset)
    max_offset = max_offset or 1.5 -- Valor padrão de 1.5 metros
    local random_x = math.random() * max_offset * 2 - max_offset
    local random_y = math.random() * max_offset * 2 - max_offset
    
    return vec3:new(
        waypoint:x() + random_x,
        waypoint:y() + random_y,
        waypoint:z()
    )
end

-- Função auxiliar para carregar waypoints
function waypoint_loader.load_waypoints(file)
    if file == "wejinhani" then
        return require("waypoints.wejinhani")
    elseif file == "marowen" then
        return require("waypoints.marowen")
    elseif file == "menestad" then
        return require("waypoints.menestad")
    elseif file == "jirandai" then
        return require("waypoints.jirandai")
    elseif file == "ironwolfs" then
        return require("waypoints.ironwolfs")
    else
        console.print("No waypoints loaded")
        return {}
    end
end

function waypoint_loader.load_maiden_route(file)
    console.print("Carregando rota para Maiden do arquivo: " .. file)
    local route
    if file == "wejinhani" then
        route = require("waypoints.wejinhani_to_maiden")
    elseif file == "marowen" then
        route = require("waypoints.marowen_to_maiden")
    elseif file == "menestad" then
        route = require("waypoints.menestad_to_maiden")
    elseif file == "jirandai" then
        route = require("waypoints.jirandai_to_maiden")
    elseif file == "ironwolfs" then
        route = require("waypoints.ironwolfs_to_maiden")
    else
        console.print("Erro: Arquivo de rota desconhecido: " .. file)
        return {}
    end

    if type(route) ~= "table" or #route == 0 then
        console.print("Erro: A rota carregada está vazia ou não é uma tabela válida")
        return {}
    end

    console.print("Rota para Maiden carregada com sucesso. Total de waypoints: " .. #route)
    for i, waypoint in ipairs(route) do
        console.print("Waypoint " .. i .. ": x=" .. waypoint:x() .. ", y=" .. waypoint:y() .. ", z=" .. waypoint:z())
    end

    return route
end

function waypoint_loader.check_and_load_waypoints()
    local world_instance = world.get_current_world()
    if not world_instance then
        console.print("Error: Unable to get world instance")
        return nil, nil
    end

    local zone_name = world_instance:get_current_zone_name()
    if not zone_name then
        console.print("Error: Unable to get zone name")
        return nil, nil
    end

    for _, tp in ipairs(waypoint_loader.helltide_tps) do
        if zone_name == tp.name then
            local waypoints = waypoint_loader.load_waypoints(tp.file)
            console.print("Loaded waypoints: " .. tp.file)
            return waypoints, tp.id
        end
    end
    
    console.print("No matching city found for waypoints")
    return nil, nil
end

return waypoint_loader