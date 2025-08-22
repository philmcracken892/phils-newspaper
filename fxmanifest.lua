fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'RSG-Core Newspaper Script with ox_lib'
author 'Phil Mcracken'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
    
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua',
	'@oxmysql/lib/MySQL.lua'
}

dependencies {
    'rsg-core',
    'ox_lib'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
	'html/images/old-newspaper.png'
}


lua54 'yes'
