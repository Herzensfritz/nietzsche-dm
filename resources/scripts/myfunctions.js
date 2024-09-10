const NUM_COLLAPSE = 3;
var headerHeight = 128;
var toggleCollapse = false;
var updating = [];


function checkCollapse(currentMap){
       let height = currentMap['collapse'].reduce((total, current) => total + current.getBoundingClientRect().height, 0)
        if( currentMap['toggleCollapse'] || height > (window.innerHeight - headerHeight)) {
            currentMap['collapse'].forEach(c =>{
                c.opened = false; 
            }); 
            currentMap['toggleCollapse'] = true;
        } 
        console.log('check Collapse ', currentMap);

}

document.addEventListener('DOMContentLoaded', function () {
    const facsimile = document.querySelector('pb-facsimile');
    const appHeader = document.querySelector('app-header');
    const map = {};
    let currentNode = null;
    headerHeight = (appHeader) ? appHeader.getBoundingClientRect().height : headerHeight;
    if (facsimile) {
        pbEvents.subscribe('pb-facsimile-status', 'transcription', (ev) => {
            if (ev.detail.status !== 'fail') {
                facsimile.style.visibility = 'visible';
            } else {
                facsimile.style.visibility = 'hidden';
            }
        }); 
    }
    
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
                if(target.id == 'pageInfo' && target.checkVisibility() && currentNode){
                    checkCollapse(map[currentNode]);    
                }
            } else {
                target.classList.add('noDisplay');
            }
        });
    });
    pbEvents.subscribe("pb-start-update", "pageInfo", (ev) => {
       updating.push(ev.target);
    });
   pbEvents.subscribe("pb-update", "pageInfo", (ev) => {
       currentNode = ev.detail.data.rootNode
       const index = updating.indexOf(ev.target);
       if (index > -1){
           updating.splice(index, 1)
       }
       const target = ev.detail.root.querySelector('pb-collapse');
       if (target && currentNode){
           if (map.hasOwnProperty(currentNode)){
               if (!map[currentNode]['collapse'].includes(target)){
                    map[currentNode]['collapse'].push(target);
                    map[currentNode]['finished'] = (updating.length == 0)
               }
           } else {
               map[currentNode] = { toggleCollapse: false, collapse: [ target ], finished: (updating.length == 0) };
           }
           if (target.checkVisibility() && map[currentNode]['finished']){
                checkCollapse(map[currentNode]);
           }
       }
   });
   pbEvents.subscribe("pb-navigate", "transcription", (ev) => {
        if (currentNode) {
            map[currentNode]['finished'] = map[currentNode]['collapse'].length > 0;
        }
        currentNode = null;
   });
   pbEvents.subscribe("pb-collapse-open", "transcription", (ev) => {
        if (currentNode && map[currentNode]['toggleCollapse']) {
            map[currentNode]['collapse'].forEach(c =>{
                if (c !== ev.originalTarget){
                    c.opened = false;
                }
            });
        }
   });
   
});
