local RSGCore = exports['rsg-core']:GetCoreObject()
local articles = {}

RegisterNetEvent("rsg-newspaper:openNewspaper", function()
    TriggerServerEvent("rsg-newspaper:getArticles")
    SetNuiFocus(true, true)
end)

RegisterNetEvent("rsg-newspaper:updateContent", function(newArticles)
    articles = newArticles or {}
    SendNUIMessage({
        type = 'updateArticles', 
        articles = articles
    })
    lib.notify({
        title = 'Newspaper Updated',
        description = 'The Glounge Times has new content!',
        type = 'success'
    })
end)


RegisterNetEvent("rsg-newspaper:loadArticles", function(newArticles)
    articles = newArticles or {}
    SendNUIMessage({
        type = 'openNewspaper', 
        articles = articles
    })
end)

RegisterNUICallback('submitNews', function(data, cb)
    TriggerServerEvent("rsg-newspaper:submitNews", data.headline, data.content)
    cb('ok')
end)

RegisterNUICallback('deleteArticle', function(data, cb)
    TriggerServerEvent("rsg-newspaper:deleteArticle", data.id)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hideNewspaper' })
    cb('ok')
end)