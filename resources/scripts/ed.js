const PSELECTOR = 'p.tei-p'

function justifyParagraphs(){
    let index = 0;
    document.querySelector('pb-view#view1').shadowRoot.querySelectorAll(PSELECTOR).forEach(p =>{
        p.querySelectorAll('br').forEach(br =>{
            let newParent = br.parentElement;
            let newSpan = document.createElement('span');
            let nextSibling = br.nextSibling;
            while (nextSibling && nextSibling.nodeName != 'BR') {
                      let tmpSibling = nextSibling.nextSibling;
                      newParent.removeChild(nextSibling);
                      newSpan.appendChild(nextSibling);
                      nextSibling = tmpSibling;
            }
            newSpan.setAttribute('id', 'insertedSpan' + index);
            newSpan.setAttribute('class', 'tei-line');
            if (br.classList.length > 0){
                newSpan.setAttribute('data-br-class', br.classList[0])
            }
            newParent.insertBefore(newSpan, br);
            newParent.removeChild(br);
            index++;
        });
        p.classList.toggle('justify');
    });
}
function unjustifyParagraphs() {
    document.querySelector('pb-view#view1').shadowRoot.querySelectorAll(PSELECTOR + '.justify').forEach(p =>{
       let children = [];
       p.querySelectorAll('span.tei-line').forEach(inserted =>{
           let br = document.createElement('br');
           br.setAttribute('class', inserted.dataset.brClass);
           inserted.parentElement.insertBefore(br, inserted);
           children.forEach(child =>{
               br.parentElement.insertBefore(child, br);
           });
           children = inserted.childNodes;
           inserted.parentElement.removeChild(inserted);
       }); 
       p.classList.toggle('justify');
    });
}

document.addEventListener('DOMContentLoaded', function () {
    pbEvents.subscribe("pb-update", 'transcription', (ev) => {
       if(pbRegistry.state.justify == 'on') {
            justifyParagraphs();
       }       
    });
     pbEvents.subscribe("pb-toggle", 'transcription', (ev) => {
        if(pbRegistry.state.justify == 'on') {
            justifyParagraphs();
       } else {
           unjustifyParagraphs();
       }
    });
});