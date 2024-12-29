const PSELECTOR = 'p.tei-p'



document.addEventListener('DOMContentLoaded', function () {
    pbEvents.subscribe("pb-update", 'transcription', (ev) => {
        ev.detail.root.querySelectorAll('.tei-line span span.tei-line').forEach(line =>{
            Array.from(line.childNodes).forEach(child =>{
                line.removeChild(child); 
            }); 
        });
        ev.detail.root.querySelectorAll(PSELECTOR).forEach(p =>{
            if (p.nextElementSibling && p.nextElementSibling.classList && p.nextElementSibling.classList.contains('head')) {
                const lines = p.querySelectorAll('.tei-line');
                if (lines.length > 0){
                    lines[lines.length-1].classList.add('last');
                }
            }   
        });
    });
});