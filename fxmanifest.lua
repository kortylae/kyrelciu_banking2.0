fx_version 'cerulean'
game 'gta5'

author 'kyrelciu'
description 'Kyrelciu Banking 2.0'
version '1.0.0'

dependency 'es_extended'

ui_page 'index.html'

files {
    'index.html',
    'style.css',
    'script.js'
}
shared_script 'config.lua'

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
