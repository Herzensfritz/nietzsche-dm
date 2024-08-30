function myScrollIntoView(target){
    target.scrollIntoView(true);  
    let scrolledY = window.scrollY;

     if(scrolledY){
        window.scroll(0, scrolledY - 128);
    }
    console.log('scrolled', target)
}

document.addEventListener('DOMContentLoaded', function () {
     const facsimile = document.querySelector('pb-facsimile');
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
            } else {
                target.classList.add('noDisplay');
            }
        });
    });
   
    pbEvents.subscribe("pb-update", "transcription", (ev) => {
                const id = document.location.hash
                console.log('my pb-update', id)
                if (id){
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
