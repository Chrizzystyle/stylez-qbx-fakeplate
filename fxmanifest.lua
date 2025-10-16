fx_version 'cerulean'
game 'gta5'

author 'ChrizzyStyle'
description 'Fake Plates Script'
version '1.5.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql'
}

lua54 'yes'