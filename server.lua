local RSGCore = exports['rsg-core']:GetCoreObject()

-- Notice Board Config (copied from your notice board system)
local NoticeConfig = {
    DatabaseName = "notices",
    MaxNoticesPerPlayer = 30,
    NoticeTitleMaxLength = 50,
    NoticeDescMaxLength = 500,
    NoticeUrlMaxLength = 255,
}

local function createNewspaperTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS newspaper_articles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            headline VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {}, function(result)
        if result then
            
        else
            
        end
    end)
end

local function loadNewspaperArticles(callback)
    MySQL.query('SELECT id, headline, content FROM newspaper_articles ORDER BY submitted_at DESC', {}, function(result)
        if result and #result > 0 then
            
            callback(result)
        else
            
            callback({})
        end
    end)
end

-- Helper function to create notice board poster
local function createNoticeBoardPoster(citizenid, headline, content, articleId)
    -- Truncate content if too long for notice board
    local truncatedContent = content
    if #content > NoticeConfig.NoticeDescMaxLength then
        truncatedContent = string.sub(content, 1, NoticeConfig.NoticeDescMaxLength - 20) .. "... (Read full story in The Glounge Times)"
    end
    
    -- Truncate headline if too long
    local truncatedHeadline = headline
    if #headline > NoticeConfig.NoticeTitleMaxLength then
        truncatedHeadline = string.sub(headline, 1, NoticeConfig.NoticeTitleMaxLength - 3) .. "..."
    end
    
    -- Add prefix to indicate it's from the newspaper (using NEWS instead of emoji to avoid collation issues)
    local posterTitle = "[NEWS] " .. truncatedHeadline
    local posterDescription = "Breaking News from The Glounge Times:\n\n" .. truncatedContent .. "\n\n[Article ID: " .. articleId .. "]"
    
    -- Insert into notice board database
    exports.oxmysql:insert('INSERT INTO ' .. NoticeConfig.DatabaseName .. ' (citizenid, title, description, url, created_at) VALUES (?, ?, ?, ?, ?)', {
        citizenid,
        posterTitle,
        posterDescription,
        nil, -- No URL for newspaper posters
        os.date('%Y-%m-%d %H:%M:%S')
    }, function(result)
        if result and result > 0 then
            print("Successfully created notice board poster for article: " .. headline)
        else
            print("Failed to create notice board poster for article: " .. headline)
        end
    end)
end

RSGCore.Functions.CreateUseableItem("newspaper", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    TriggerClientEvent("rsg-newspaper:openNewspaper", source)
end)

RegisterNetEvent("rsg-newspaper:getArticles")
AddEventHandler("rsg-newspaper:getArticles", function()
    local src = source
    loadNewspaperArticles(function(articles)
        
        TriggerClientEvent("rsg-newspaper:loadArticles", src, articles)
    end)
end)

RegisterNetEvent("rsg-newspaper:submitNews")
AddEventHandler("rsg-newspaper:submitNews", function(headline, content)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    
    if Player.PlayerData.job.name ~= "reporter" and Player.PlayerData.job.name ~= "lawyer" then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Permission Denied',
            description = 'Only reporters and lawyers can submit news articles!',
            type = 'error'
        })
        return
    end

    if headline and content and #headline > 0 and #content > 0 then
        MySQL.insert('INSERT INTO newspaper_articles (headline, content) VALUES (?, ?)', {headline, content}, function(insertId)
            if insertId then
                -- Create notice board poster after successful article creation
                createNoticeBoardPoster(Player.PlayerData.citizenid, headline, content, insertId)
                
                loadNewspaperArticles(function(articles)
                    if #articles > 0 then
                        TriggerClientEvent("rsg-newspaper:updateContent", -1, articles)
                    end
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'News Submitted',
                        description = 'Your news has been added to the Glounge Times and posted on the notice board!',
                        type = 'success'
                    })
                end)
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Error',
                    description = 'Failed to submit news article.',
                    type = 'error'
                })
            end
        end)
    end
end)

RegisterNetEvent("rsg-newspaper:deleteArticle")
AddEventHandler("rsg-newspaper:deleteArticle", function(articleId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    
    if Player.PlayerData.job.name ~= "reporter" and Player.PlayerData.job.name ~= "lawyer" then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Permission Denied',
            description = 'Only reporters can delete articles!',
            type = 'error'
        })
        return
    end

    -- First get the article details before deleting
    MySQL.query('SELECT headline FROM newspaper_articles WHERE id = ?', {articleId}, function(articleResult)
        if articleResult and #articleResult > 0 then
            local headline = articleResult[1].headline
            
            -- Delete the article
            MySQL.execute('DELETE FROM newspaper_articles WHERE id = ?', {articleId}, function(result)
                local affectedRows = type(result) == "table" and result.affectedRows or result
                if affectedRows and affectedRows > 0 then
                    -- Delete the corresponding notice board poster using the article ID in the description
                    exports.oxmysql:execute('DELETE FROM ' .. NoticeConfig.DatabaseName .. ' WHERE citizenid = ? AND description LIKE ?', {
                        Player.PlayerData.citizenid, 
                        '%[Article ID: ' .. articleId .. ']%'
                    }, function(noticeResult)
                        print("Deleted corresponding notice board poster for article: " .. headline)
                    end)
                    
                    loadNewspaperArticles(function(articles)
                        if #articles > 0 then
                            print("Broadcasting " .. #articles .. " articles after delete")
                            TriggerClientEvent("rsg-newspaper:updateContent", -1, articles)
                        end
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Article Deleted',
                            description = 'The article and its poster have been removed from the Glounge Times.',
                            type = 'success'
                        })
                    end)
                end
            end)
        end
    end)
end)

AddEventHandler('playerConnecting', function()
    local src = source
    loadNewspaperArticles(function(articles)
        if #articles > 0 then
            TriggerClientEvent("rsg-newspaper:updateContent", src, articles)
        end
        
    end)
end)

Citizen.CreateThread(function()
    createNewspaperTable()
    Wait(1000)
    loadNewspaperArticles(function(articles)
        
    end)
end)