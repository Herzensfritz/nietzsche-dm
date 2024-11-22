
function highlightTarget(target){
    if (pbRegistry.state.template != 'meta.html'){
        target.classList.add("myhighlight");  
    }
}
document.addEventListener('DOMContentLoaded', function () {
    const root = document.querySelector(':root');
    const appHeader = document.querySelector('app-header');
    if (appHeader && root) {
        const headerHeight = appHeader.getBoundingClientRect().height; 
        root.style.setProperty('--scroll-top', headerHeight + 'px');
    }
    
    pbEvents.subscribe("pb-update", "transcription", (ev) => {
        const id = document.location.hash
        if (id){
            console.log('my pb-update', id)
            const target = ev.detail.root.querySelector(id);
            console.log(id, target);
            if (target){
                target.scrollIntoView(true);
                target.classList.add("myhighlight");
            }    
        }
        
    });
            
    pbEvents.subscribe("pb-refresh", "transcription", (ev) => {
        const id = document.location.hash.substring(1)
        if (id){  
            const target = document.getElementById(id);
            console.log(id, target);
            if (target){
                target.scrollIntoView(true);
                if (target.classList.contains('noscroll')){
                    target.classList.add("myhighlight");
                }
            }    
        } 
    });
});