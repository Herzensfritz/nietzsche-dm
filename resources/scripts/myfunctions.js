var headerHeight = 128;
var CURRENT_TARGET = 'pageInfo';

document.addEventListener('DOMContentLoaded', function () {
    const appHeader = document.querySelector('app-header');
    headerHeight = (appHeader) ? appHeader.getBoundingClientRect().height : headerHeight;
    let params = new URLSearchParams(document.location.search);
    if (params.has('show')){
        CURRENT_TARGET = params.get('show');
    }
   
    
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

