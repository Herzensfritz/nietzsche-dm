document.addEventListener('DOMContentLoaded', function () {
   
    const viewer = document.querySelector('pb-facsimile');
    
    pbEvents.subscribe('pb-zoom', 'transcription', (ev) =>{
        console.log(ev)
    }
        
    );
    
   pbEvents.subscribe('pb-refresh',null, (ev) => {
       console.log(viewer)
       pbEvents.emit('pb-facsimile-status', 'transcription', viewer)
        
       
    }); 
    pbEvents.subscribe('pb-panel',null, (ev) => {
        console.log(ev)   ;
       
    }); 
   if (viewer) {
       pbEvents.subscribe('pb-load-facsimile','transcription', (ev) => {
            console.log(ev)   ;
            viewer.style.visibility = 'hidden';
        });
       
        
                
        pbEvents.subscribe('pb-facsimile-status', 'transcription', (ev) => {
                    if (ev.detail.status !== 'fail') {
                        
                        viewer.style.visibility = 'visible';
                         console.log('success: ', viewer);
                        
                    } else {
                       
                        viewer.style.visibility = 'hidden';
                        console.log('fail: ' +viewer);
                    }
                }); 
      
   }
});
