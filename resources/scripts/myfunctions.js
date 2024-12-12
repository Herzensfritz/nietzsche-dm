

var PAGE_DICT = {
    'Erstdruck': 'facsimile',
    'Korrekturbogen': 'view1',
    'Surface': 'pageInfo'
}

document.addEventListener('DOMContentLoaded', function () {
    let current_target = 'pageInfo';
    const meta = document.querySelector('meta[name="description"]')
    if (meta && meta.content && PAGE_DICT.hasOwnProperty(meta.content)){
        current_target = PAGE_DICT[meta.content];
    }
    
    let params = new URLSearchParams(document.location.search);
    if (params.has('show')){
        current_target = params.get('show');
    }
    pbEvents.subscribe("pb-update", "pageInfo", (ev) => {
        const host = (window.location.port != '') ? window.location.hostname + ':' + window.location.port : window.location.hostname;
        ev.detail.root.querySelectorAll('[data-doc]').forEach((link) =>{
            let doc = link.dataset.doc;
            let id = link.dataset.id;
            let url = window.location.protocol + '//' + host + '/exist/apps/nietzsche-dm/api/link/' + doc + '?id=' + id;
            fetch(url).then((response) => {
                // Our handler throws an error if the request did not succeed.
                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status}`);
                }
                return response.json();
            }).then((data) => {
                if(data){
                    link.setAttribute('href', data['doc'] + '?root=' + data['node']);
                }
                
                }).catch((error) => {
                    console.error(`Could not fetch id: ${error} on URL ${url}`);
                });
        });
    });

    document.querySelectorAll('[data-target]').forEach((link) => {
        const target = document.querySelector(link.dataset.target);
        if (target){
            if (target.id != current_target){
                target.classList.add('noDisplay');
            }
            link.addEventListener('click', (ev) => {
                pbEvents.emit('toggle-event', null, ev)
            });
        } else {
            delete link.dataset.target;
            link.classList.add('noDisplay');
        }
    });
  
    pbEvents.subscribe('toggle-event', null, function(ev){
        const eventTarget = ev.detail.target;
        document.querySelectorAll('[data-target]').forEach((link) => {
            const target = document.querySelector(link.dataset.target);
            if (link === eventTarget) {
                console.log(target);
                target.classList.toggle('noDisplay');
                if (ev.detail.target.dataset.altIcon){
                    let alt = ev.detail.target.icon;
                    ev.detail.target.icon = ev.detail.target.dataset.altIcon;
                    ev.detail.target.dataset.altIcon = alt;
                }
            } else {
                target.classList.add('noDisplay');
            }
        });
    });
 
  
   
});

