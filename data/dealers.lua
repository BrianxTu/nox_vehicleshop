Dealers = {}

Dealers["pdm"] = {
    name = "Premium Deluxe Motorsport",
    zone = {
        coords = vector3(-42.2952, -1091.9165, 26.4224),
        radius = 75.0
    },
    blip = {
        sprite = 832,
        color = 0,
        scale = 0.8
    },
    classes = {1, 3, 5, 7},
    displays = {
        {vehicle = nil, coords = vector4(-41.4684448, -1099.702, 26.6257057, -224.97)},
        {vehicle = nil, coords = vector4(-46.262085, -1097.85071, 26.6257057, -249.97)},
        {vehicle = nil, coords = vector4(-49.87091, -1094.651, 26.6257057, -264.97)}
    },
    --job = "cardealer",
    npcs = {
        {
            ped = "ig_lamardavis",
            scenario = "WORLD_HUMAN_STAND_IMPATIENT",
            coords = vector4(-46.6338, -1090.8600, 25.4223, 149.8016)
        },
        {
            ped = "player_one",
            scenario = "WORLD_HUMAN_TOURIST_MOBILE",
            coords = vector4(-47.3739, -1090.4475, 25.4223, 181.7131)
        },
        {
            ped = "ig_siemonyetarian",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            coords = vector4(-33.2917, -1103.5317, 25.4223, 75.5216)
        }
    },

    preview = {
        spawn = vector4(-36.6536255, -1101.83728, 26.6257057, -204.97),
        camera = vector4(-40.6689, -1104.7635, 26.9224, 304.0993)
    },

    spawn = vector4(-46.9629, -1080.6667, 26.6379, 70.7844),
    testdrive = {
        spawn = vector4(-11.7879, -1085.0432, 26.5839, 72.3252),
        despawn = vector4(-13.0957, -1103.7966, 26.6721, 340.6205),
        time = 60
    }
}

--[[
    -- Vehicle Mods
]]
