document.addEventListener('DOMContentLoaded', function () {
    console.log("Version: HELLO WORLD");
    let viewWidth = -1;
    
    pbEvents.subscribe('pb-update', 'transcription', (ev) =>{
        if (ev.target.id == 'view2'){
            let content = document.querySelector('.content-body');
            let textBlock = ev.detail.root.querySelector('.textBlock');
            if (content && textBlock){
                let fontSize = 16;
                let maxWidth = content.getBoundingClientRect().width;
                let firstFound = false;
                let zoneLines = Array.from(ev.detail.root.querySelectorAll('.zoneLine'))
                if (zoneLines.length > 0){
                    let lastLine = zoneLines[zoneLines.length-1];
                    let firstLine = Array.from(ev.detail.root.querySelectorAll('.line'))[1]
                    let diff = (firstLine.getBoundingClientRect().top - lastLine.getBoundingClientRect().bottom)/fontSize/2;
                    let oldPaddingTop = (textBlock.style.paddingTop) ? Number(textBlock.style.paddingTop.replace('em', '')) : 5;
                    textBlock.style.paddingTop = (oldPaddingTop - diff) + 'em'; 
                }
                
                Array.from(ev.detail.root.querySelectorAll('.line')).forEach(line =>{
                    line.classList.add('version2')
                });
            }
            
        } 
    });
   
   /* const viewer = document.querySelector('#view2');
    const zoomOut = document.querySelector('pb-zoom[direction="out"]')
    
   
   if (viewer && zoomOut) {
       pbEvents.subscribe('pb-update', 'transcription', (ev) =>{
        if (viewer.getBoundingClientRect().right > window.innerWidth){
            zoomOut.emitTo('pb-zoom', {direction: "out"})       
        } else {
            console.log(viewer.getBoundingClientRect().right)
        }
       });
       pbEvents.subscribe('pb-zoom','transcription', (ev) => {
           if (ev.target = undefined || ev.target.direction != 'in'){
            console.log(ev.target.direction);
            if (viewer.getBoundingClientRect().right > window.innerWidth){
                pbEvents.emit('pb-zoom', 'transcription', ev)
            }
           }
           
        });
       
        
                
   } */
});