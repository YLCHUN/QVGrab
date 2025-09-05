(function() {
    var links = document.querySelectorAll('link[rel*="icon"]');
    var faviconUrl = '';
    
    // 优先查找apple-touch-icon
    for (var i = 0; i < links.length; i++) {
        var rel = links[i].getAttribute('rel');
        if (rel && rel.indexOf('apple-touch-icon') !== -1) {
            faviconUrl = links[i].getAttribute('href');
            break;
        }
    }
    
    // 如果没有apple-touch-icon，查找icon
    if (!faviconUrl) {
        for (var i = 0; i < links.length; i++) {
            var rel = links[i].getAttribute('rel');
            if (rel && rel.indexOf('icon') !== -1) {
                faviconUrl = links[i].getAttribute('href');
                break;
            }
        }
    }
    
    // 如果还是没有，尝试默认路径
    if (!faviconUrl) {
        faviconUrl = '/favicon.ico';
    }
    
    // 如果是相对路径，转换为绝对路径
    if (faviconUrl && faviconUrl.indexOf('http') !== 0) {
        faviconUrl = window.location.origin + (faviconUrl.indexOf('/') === 0 ? '' : '/') + faviconUrl;
    }
    
    return faviconUrl;
})();
