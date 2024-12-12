window.onload = function() {
    let params = new URLSearchParams(document.location.search);
    if (params.has('selectors')){
        params.delete('selectors');
        console.log('reloading .........');
        history.replaceState(null, null, document.location.pathname + "?" + params.toString() + window.location.hash);
        window.location.reload(true);
    } else if (window.location.hash != ''){
        const host = (window.location.port != '') ? window.location.hostname + ':' + window.location.port : window.location.hostname;
        const doc = (pbRegistry && pbRegistry.state.path) ? '?doc=' + pbRegistry.state.path : '';
        const url = window.location.protocol + '//' + host + '/exist/apps/nietzsche-dm/api/id/' + window.location.hash.substring(1) + doc;
        fetch(url).then((response) => {
            // Our handler throws an error if the request did not succeed.
            if (!response.ok) {
                throw new Error(`HTTP error: ${response.status}`);
            }
            return response.text();
        }).then((nodeId) => {
            console.log('reloading with node .........');
            history.replaceState(null, null, document.location.pathname + "?" + params.toString() + '&root=' + nodeId);
            window.location.reload(true);
        }).catch((error) => {
            console.error(`Could not fetch id: ${error} on URL ${url}`);
        });
        
    }
    
};