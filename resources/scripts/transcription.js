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
        if (!currentMap['finished']){
            setTimeout(checkCollapse(currentMap), 1000);    
        }

}
function createMap(finished){
    return  { toggleCollapse: false, collapse: [], finished: finished };
}
document.addEventListener('DOMContentLoaded', function () {
    const map = {};
    let currentNode = null;
  
    
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
               map[currentNode] = createMap((updating.length == 0));
           }
           if (target.checkVisibility() && map[currentNode]['finished']){
                checkCollapse(map[currentNode]);
           }
       }
   });
   pbEvents.subscribe("pb-navigate", "transcription", (ev) => {
        if (currentNode) {
            map[currentNode]['finished'] = (updating.length == 0);
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
   pbEvents.subscribe("check-collapse", null, (ev) => {
       if (currentNode){
           checkCollapse(map[currentNode]); 
       }
   });
   pbEvents.subscribe("pb-toggle", "transcription", (ev) => {
       const source = ev.detail._source;
       const dataType = source.dataset.type;
       if (dataType){
           pbRegistry._listeners.forEach(listener =>{
               if (listener.component['name'] && listener.component.dataset.type == dataType && listener.component !== source){
                    if (listener.component.name == source.name) {
                        listener.component.checked = source.checked;   
                    } 
                    console.log(listener.component['name'], listener.component.checked)   
               }
            });
        }
       
   });

   
});
window.onload = function() {
    let params = new URLSearchParams(document.location.search);
    if (params.has('selectors')){
        params.delete('selectors')
        console.log('reloading .........');
        history.replaceState(null, null, document.location.pathname + "?" + params.toString());
        window.location.reload(true);
    }
};
