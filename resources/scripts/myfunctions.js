var headerHeight = 128;

document.addEventListener('DOMContentLoaded', function () {
    const appHeader = document.querySelector('app-header');
    headerHeight = (appHeader) ? appHeader.getBoundingClientRect().height : headerHeight;
   
    
    document.querySelectorAll('[data-target]').forEach((link) => {
        const target = document.querySelector(link.dataset.target);
        if (target){
            target.classList.add('noDisplay');
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
                if(target.id == 'pageInfo' && target.checkVisibility()){
                   pbEvents.emit('check-collapse', null, target);
                }
            } else {
                target.classList.add('noDisplay');
            }
        });
    });
 
  
   
});

