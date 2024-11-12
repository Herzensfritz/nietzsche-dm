
function myScrollIntoView(target){
    target.scrollIntoView(true);  
    /*let scrolledY = window.scrollY;

     if(scrolledY){
        window.scroll(0, scrolledY - headerHeight);
    }*/
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
                myScrollIntoView(target);
                target.classList.add("myhighlight");
                console.log('added', target)
            }    
        }
        
    });
            
    pbEvents.subscribe("pb-refresh", "transcription", (ev) => {
        const id = document.location.hash.substring(1)
        if (id){  
            const target = document.getElementById(id);
            console.log(id, target);
            if (target){
                myScrollIntoView(target);
                if (target.classList.contains('noscroll')){
                    console.log('noscroll:',target);
                    target.classList.add("myhighlight");
                }
            }    
        } 
    });
});