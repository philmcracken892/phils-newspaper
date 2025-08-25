local RSGCore = exports['rsg-core']:GetCoreObject()

-- Notice Board Config (copied from your notice board system)
local NoticeConfig = {
    DatabaseName = "notices",
    MaxNoticesPerPlayer = 30,
    NoticeTitleMaxLength = 50,
    NoticeDescMaxLength = 500,
    NoticeUrlMaxLength = 255,
}

-- Function to validate if a URL is a valid image URL (from posters resource)
local function IsValidImageURL(url)
    if not url or url == "" then
        return false
    end
    -- Check if it's a valid URL format
    if not string.match(url, "^https?://") then
        return false
    end
    -- Check for common image file extensions or Discord CDN
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

-- ENHANCED: Create newspaper table with image URL support
local function createNewspaperTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS newspaper_articles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            headline VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            image_url VARCHAR(500) DEFAULT NULL,
            author_citizenid VARCHAR(50) DEFAULT NULL,
            author_name VARCHAR(100) DEFAULT NULL,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {}, function(result)
        if result then
            print("[RSG-Newspaper] Database table created/verified successfully with image support")
        else
            print("[RSG-Newspaper] ERROR: Failed to create/verify database table")
        end
    end)
end

-- ENHANCED: Load articles with image URLs
local function loadNewspaperArticles(callback)
    MySQL.query('SELECT id, headline, content, image_url, author_name, submitted_at FROM newspaper_articles ORDER BY submitted_at DESC', {}, function(result)
        if result and #result > 0 then
            print("[RSG-Newspaper] Loaded " .. #result .. " articles")
            callback(result)
        else
            print("[RSG-Newspaper] No articles found")
            callback({})
        end
    end)
end

-- ENHANCED: Helper function to create notice board poster with image support
local function createNoticeBoardPoster(citizenid, headline, content, articleId, imageUrl)
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
    
    -- Include image URL in the notice board if available
    local noticeUrl = imageUrl and imageUrl ~= "" and imageUrl or nil
    
    -- Insert into notice board database
    exports.oxmysql:insert('INSERT INTO ' .. NoticeConfig.DatabaseName .. ' (citizenid, title, description, url, created_at) VALUES (?, ?, ?, ?, ?)', {
        citizenid,
        posterTitle,
        posterDescription,
        noticeUrl,
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

-- ENHANCED: Submit news with image URL support
RegisterNetEvent("rsg-newspaper:submitNews")
AddEventHandler("rsg-newspaper:submitNews", function(headline, content, imageUrl)
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

    -- Validate image URL if provided
    if imageUrl and imageUrl ~= "" then
        if not IsValidImageURL(imageUrl) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Invalid Image URL',
                description = 'Please provide a valid image URL (jpg, png, gif, etc.) or leave blank',
                type = 'error'
            })
            return
        end
    end

    if headline and content and #headline > 0 and #content > 0 then
        -- Insert with image URL support
        MySQL.insert('INSERT INTO newspaper_articles (headline, content, image_url, author_citizenid, author_name) VALUES (?, ?, ?, ?, ?)', {
            headline, 
            content, 
            imageUrl, 
            Player.PlayerData.citizenid, 
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        }, function(insertId)
            if insertId then
                -- Create notice board poster after successful article creation
                createNoticeBoardPoster(Player.PlayerData.citizenid, headline, content, insertId, imageUrl)
                
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
        print("[RSG-Newspaper] System initialized with " .. #articles .. " articles")
    end)
end)
