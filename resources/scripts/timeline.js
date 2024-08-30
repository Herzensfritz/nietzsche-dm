document.addEventListener('DOMContentLoaded', function () {
    const id = (document.location.hash) ? document.location.hash.substring(1) : null;
    let target = null;
    const apis = [];
  
    /**
     * If pb-view is ready, add letter and page4change apis to array.
     * After loading, pb-load removes its api from array.
     * If the array is empty, we scroll the hash target element.
     **/
    pbEvents.subscribe("pb-update", "timeline", (ev) => {
        if (id) {
            if (ev.target.id == id){
                target = ev.target;  
            }
            const letterId = 'api/letters/' + ev.target.id ;
            const pageId = 'api/page4change/' + ev.target.id;
            apis.push(letterId);
            apis.push(pageId);
        }
    }); 
    
    /**
     * Scroll to hash target after all pb-loads are updated.
     **/
    pbEvents.subscribe("pb-end-update", "timeline", (ev) => {
        if (id) {
            const index = apis.indexOf(ev.originalTarget.url);
            if (index > -1){
                console.log('end update', ev.originalTarget.url);
                apis.splice(index, 1);
                if (apis.length == 0 && target){
                     myScrollIntoView(target);
                    target.classList.add('myhighlight');
                    console.log('scroll to ', target)
                }
            }
        }
    });
        
});