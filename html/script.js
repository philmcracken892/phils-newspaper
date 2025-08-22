let currentPage = 0;
let isNewspaperOpen = false;
let isPageLoaded = false;

// Ensure UI is hidden on load
document.addEventListener('DOMContentLoaded', function() {
    
    const container = document.querySelector('.newspaper-container');
    const modal = document.getElementById('full-article-modal');
    
    // Force hide UI elements and background
    if (container) {
        container.style.display = 'none';
        container.classList.remove('active');
    }
    if (modal) {
        modal.style.display = 'none';
    }
    document.body.classList.remove('newspaper-active');
    
    isNewspaperOpen = false;
    
    
});

// Reinforce hidden state after full page load
window.addEventListener('load', () => {
   
    const container = document.querySelector('.newspaper-container');
    const modal = document.getElementById('full-article-modal');
    if (container) {
        container.style.display = 'none';
        container.classList.remove('active');
    }
    if (modal) {
        modal.style.display = 'none';
    }
    document.body.classList.remove('newspaper-active');
    isPageLoaded = true;
   
    
});

window.addEventListener('message', (event) => {
    // Delay processing until page is fully loaded
    if (!isPageLoaded) {
        
        return;
    }
    
    const data = event.data;
    const container = document.querySelector('.newspaper-container');
    
    if (!container) {
        
        return;
    }
    
    
    
    if (data.type === 'openNewspaper') {
        
        isNewspaperOpen = true;
        
        // Add background effects
        document.body.classList.add('newspaper-active');
        
        container.style.display = 'block';
        container.classList.add('active');
        currentPage = 0;
        updateArticles(data.articles || []);
        updatePageDisplay();
        
    } else if (data.type === 'updateArticles') {
        
        // Only update if newspaper is currently open
        if (isNewspaperOpen && data.articles && data.articles.length > 0) {
            updateArticles(data.articles);
            updatePageDisplay();
        }
        
    } else if (data.type === 'hideNewspaper') {
       
        isNewspaperOpen = false;
        
        // Remove background effects
        document.body.classList.remove('newspaper-active');
        
        container.style.display = 'none';
        container.classList.remove('active');
        // Also hide modal if open
        const modal = document.getElementById('full-article-modal');
        if (modal) {
            modal.style.display = 'none';
        }
    }
});

function updateArticles(articles) {
    const pageContainer = document.getElementById('page-container');
    if (!pageContainer) return;
    
    pageContainer.innerHTML = '';
    const safeArticles = Array.isArray(articles) ? articles : [];
    
    if (safeArticles.length === 0) {
        const div = document.createElement('div');
        div.className = 'page active';
        div.innerHTML = '<p>No news yet, partner!</p>';
        pageContainer.appendChild(div);
    } else {
        safeArticles.forEach((article, index) => {
            const div = document.createElement('div');
            div.className = 'page' + (index === 0 ? ' active' : ' hidden');
            
            // Safely escape quotes and newlines
            const safeHeadline = (article.headline || '').replace(/'/g, "\\'").replace(/"/g, '\\"').replace(/\n/g, "\\n");
            const safeContent = (article.content || '').replace(/'/g, "\\'").replace(/"/g, '\\"').replace(/\n/g, "\\n");
            
            div.innerHTML = `
                <div class="article-preview" onclick="showFullArticle('${safeHeadline}', '${safeContent}', ${article.id})">
                    <h2>${article.headline || 'No Title'}</h2>
                    <p>${(article.content || '').substring(0, 100)}...</p>
                </div>
                <button onclick="deleteArticle(${article.id})">Delete</button>
            `;
            pageContainer.appendChild(div);
        });
    }
    updateNavigationButtons(safeArticles.length);
}

function showFullArticle(headline, content, id) {
    const modal = document.getElementById('full-article-modal');
    const headlineEl = document.getElementById('full-article-headline');
    const textEl = document.getElementById('full-article-text');
    
    if (modal && headlineEl && textEl) {
        headlineEl.textContent = headline || 'No Title';
        textEl.textContent = content || 'No Content';
        modal.style.display = 'flex';
    }
}

function updatePageDisplay() {
    const pages = document.querySelectorAll('.page');
    pages.forEach((page, index) => {
        if (index === currentPage) {
            page.classList.remove('hidden');
            page.classList.add('active');
        } else {
            page.classList.remove('active');
            page.classList.add('hidden');
        }
    });
    updateNavigationButtons(pages.length);
}

function updateNavigationButtons(totalPages) {
    const prevBtn = document.getElementById('prev-page');
    const nextBtn = document.getElementById('next-page');
    const pageNumber = document.getElementById('page-number');
    
    if (prevBtn) prevBtn.disabled = currentPage === 0;
    if (nextBtn) nextBtn.disabled = currentPage === totalPages - 1 || totalPages === 0;
    if (pageNumber) pageNumber.textContent = totalPages > 0 ? `Page ${currentPage + 1} of ${totalPages}` : 'No Pages';
}

function deleteArticle(id) {
    if (typeof GetParentResourceName === 'function') {
        fetch(`https://${GetParentResourceName()}/deleteArticle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ id })
        }).catch(err => console.error('Delete article error:', err));
    }
}

function closeNewspaper() {
    if (typeof GetParentResourceName === 'function') {
        fetch(`https://${GetParentResourceName()}/closeUI`, { 
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        }).catch(err => console.error('Close UI error:', err));
    }
    
    // Remove background effects
    document.body.classList.remove('newspaper-active');
    
    // Manually close UI
    const container = document.querySelector('.newspaper-container');
    const modal = document.getElementById('full-article-modal');
    
    if (container) {
        container.style.display = 'none';
        container.classList.remove('active');
    }
    if (modal) {
        modal.style.display = 'none';
    }
    
    isNewspaperOpen = false;
    
}

// Event listeners with null checks
document.addEventListener('DOMContentLoaded', function() {
    // Previous page button
    const prevBtn = document.getElementById('prev-page');
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            if (currentPage > 0) {
                currentPage--;
                updatePageDisplay();
            }
        });
    }

    // Next page button
    const nextBtn = document.getElementById('next-page');
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            const totalPages = document.querySelectorAll('.page').length;
            if (currentPage < totalPages - 1) {
                currentPage++;
                updatePageDisplay();
            }
        });
    }

    // Submit button
    const submitBtn = document.getElementById('submit-btn');
    if (submitBtn) {
        submitBtn.addEventListener('click', () => {
            const form = document.getElementById('submit-form');
            if (form) {
                form.style.display = form.style.display === 'none' ? 'block' : 'none';
            }
        });
    }

    // Submit news button
    const submitNewsBtn = document.getElementById('submit-news');
    if (submitNewsBtn) {
        submitNewsBtn.addEventListener('click', () => {
            const headline = document.getElementById('headline')?.value;
            const content = document.getElementById('content')?.value;
            
            if (headline && content && typeof GetParentResourceName === 'function') {
                fetch(`https://${GetParentResourceName()}/submitNews`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ headline, content })
                }).catch(err => console.error('Submit news error:', err));
                
                // Clear form and hide it
                const form = document.getElementById('submit-form');
                const headlineInput = document.getElementById('headline');
                const contentInput = document.getElementById('content');
                
                if (form) form.style.display = 'none';
                if (headlineInput) headlineInput.value = '';
                if (contentInput) contentInput.value = '';
            }
        });
    }

    // Cancel submit button
    const cancelBtn = document.getElementById('cancel-submit');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', () => {
            const form = document.getElementById('submit-form');
            if (form) {
                form.style.display = 'none';
            }
        });
    }

    // Close full article button
    const closeBtn = document.getElementById('close-full-article');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            const modal = document.getElementById('full-article-modal');
            if (modal) {
                modal.style.display = 'none';
            }
        });
    }

    // Escape key handler
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && isNewspaperOpen) {
            closeNewspaper();
        }
    });
});

