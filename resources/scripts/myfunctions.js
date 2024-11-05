var headerHeight = 128;
var CURRENT_TARGET = 'pageInfo';

document.addEventListener('DOMContentLoaded', function () {
    const appHeader = document.querySelector('app-header');
    headerHeight = (appHeader) ? appHeader.getBoundingClientRect().height : headerHeight;
    let params = new URLSearchParams(document.location.search);
    if (params.has('show')){
        CURRENT_TARGET = params.get('show');
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
                    console.log(link)
                }
                
                }).catch((error) => {
                    console.error(`Could not fetch id: ${error} on URL ${url}`);
                });
        });
    });
    
    document.querySelectorAll('[data-target]').forEach((link) => {
        const target = document.querySelector(link.dataset.target);
        if (target){
            if (target.id != CURRENT_TARGET){
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

