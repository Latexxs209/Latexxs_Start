fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Latexxs'
description 'Starter pack item & cash have fun :)'

shared_script 'config.lua'
client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependency 'es_extended'
dependency 'ox_lib'
dependency 'ox_target'
dependency 'oxmysql'
