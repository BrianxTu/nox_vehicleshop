-- FX Information
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

-- Resource Information
name 'ox_vehicleshop'
author ''
version '1.0.0'
repository ''
description ''

-- Manifest
shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'data/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/menus.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependency {
    'ox_lib',
    'ox_target',
    'oxmysql'
}
