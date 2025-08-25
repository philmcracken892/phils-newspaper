local RSGCore = exports['rsg-core']:GetCoreObject()
local articles = {}

-- Function to validate if a URL is a valid image URL (from posters resource)
local function IsValidImageURL(url)
    if not url or url == "" then
        return false
    end
    if not string.match(url, "^https?://") then
        return false
    end
    local imageExtensions = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"}
    local isDiscordCDN = string.match(url, "cdn%.discordapp%.com") or string.match(url, "media%.discordapp%.net")
    if isDiscordCDN then
        return true
    end
    for _, ext in ipairs(imageExtensions) do
        if string.match(string.lower(url), ext) then
            return true
        end
    end
    return false
end

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

-- ENHANCED: Submit news with image URL validation
RegisterNUICallback('submitNews', function(data, cb)
    local imageUrl = data.imageUrl
    
    -- Validate image URL if provided
    if imageUrl and imageUrl ~= "" then
        if not IsValidImageURL(imageUrl) then
            lib.notify({
                title = 'Invalid Image URL',
                description = 'Please provide a valid image URL (jpg, png, gif, etc.) or leave blank',
                type = 'error'
            })
            cb('error')
            return
        end
    end
    
    TriggerServerEvent("rsg-newspaper:submitNews", data.headline, data.content, imageUrl)
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
