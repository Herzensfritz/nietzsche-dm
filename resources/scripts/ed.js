const PSELECTOR = 'p.tei-p'

function getNextSibling(item, targetIsLine){
    if (!item || !item.nextSibling) {
        return null;
    }
    if (!item.nextSibling.classList){
        if (targetIsLine) {
            getNextSibling(item.nextSibling)
        }
        return item.nextSibling;
    }
    if (targetIsLine) {
        return (item.nextSibling.classList.contains('tei-line')) ? item.nextSibling : getNextSibling(item.nextSibling);
    }
    return (!item.nextSibling.classList.contains('tei-line')) ? item.nextSibling : null;
}

function fixIncludedLB() {
  document.querySelector('pb-view#view1').shadowRoot.querySelectorAll('.tei-line span span.tei-line').forEach(line =>{
      Array.from(line.childNodes).forEach(child =>{
         line.removeChild(child); 
      });
  });  
  /* document.querySelector('pb-view#view1').shadowRoot.querySelectorAll('.tei-line span span.tei-line').forEach(line =>{
        let parentSpan = line.parentElement;  
        
        let copyOfParent = parentSpan.cloneNode(); 
        line.childNodes.forEach(child =>{
            copyOfParent.appendChild(child);    
        });
        line.appendChild(copyOfParent);
        let nextSibling = parentSpan.nextSibling;
        while (nextSibling){
            let tmpSibling = nextSibling.nextSibling;
            line.appendChild(nextSibling);
            nextSibling = tmpSibling;
        }
        let nextParentLine = parentSpan.parentElement.nextSibling;
        if (nextParentLine) {
            nextParentLine.parentElement.insertBefore(line, nextParentLine);
        } else {
            parentSpan.parentElement.parentElement.appendChild(line);
        }
        if (parentSpan.parentElement.classList.contains('last')){
            parentSpan.parentElement.classList.remove('last');
            line.classList.add('last');
        }
   });
   document.querySelector('pb-view#view1').shadowRoot.querySelectorAll('p.tei-p span.spaced span.tei-line').forEach(line =>{
        let parentSpan = line.parentElement;  
        let copyOfParent = parentSpan.cloneNode();
        line.childNodes.forEach(child =>{
            copyOfParent.appendChild(child);    
        });
        line.appendChild(copyOfParent);
        let nextSibling = getNextSibling(parentSpan, false);
        while (nextSibling){
            let tmpSibling = getNextSibling(nextSibling, false);
            line.appendChild(nextSibling);
            nextSibling = tmpSibling;
        }
        let nextParentLine = getNextSibling(parentSpan, true);
        if (nextParentLine) {
            nextParentLine.parentElement.insertBefore(line, nextParentLine);
        } else {
            parentSpan.parentElement.appendChild(line);
        }
   }); */
}

function justifyParagraphs(){
    let index = 0;
    document.querySelector('pb-view#view1').shadowRoot.querySelectorAll(PSELECTOR).forEach(p =>{
        let isFollowedByHead = (p.nextElementSibling && p.nextElementSibling.classList && p.nextElementSibling.classList.contains('head'))
        const lbs = p.querySelectorAll('br');
        let paragraphIndex = 0;
        let popover = null;
        lbs.forEach(br =>{
            let newParent = br.parentElement;
            let newSpan = document.createElement('span');
            let nextSibling = br.nextSibling;
            while (nextSibling && nextSibling.nodeName != 'BR') {
                      let tmpSibling = nextSibling.nextSibling;
                     
                        newSpan.appendChild(nextSibling);
                      
                      nextSibling = tmpSibling;
            }
            newSpan.setAttribute('id', 'insertedSpan' + index);
            newSpan.classList.add('tei-line');
            if (br.dataset.rend == 'last'){
               newSpan.classList.add('last'); 
            }
            newParent.insertBefore(newSpan, br);
            newParent.removeChild(br);
            paragraphIndex++
            if (isFollowedByHead && paragraphIndex == lbs.length){
                newSpan.classList.add('last');
            }
            index++;
            
        });
        fixIncludedLB();
        if (popover){
            p.appendChild(popover)
        }
        p.classList.toggle('justify');
    });
}

document.addEventListener('DOMContentLoaded', function () {
    pbEvents.subscribe("pb-update", 'transcription', (ev) => {
        document.querySelector('pb-view#view1').shadowRoot.querySelectorAll('.tei-line span span.tei-line').forEach(line =>{
            Array.from(line.childNodes).forEach(child =>{
                line.removeChild(child); 
        });
        document.querySelector('pb-view#view1').shadowRoot.querySelectorAll(PSELECTOR).forEach(p =>{
            if (p.nextElementSibling && p.nextElementSibling.classList && p.nextElementSibling.classList.contains('head')) {
                const lines = p.querySelectorAll('.tei-line');
                if (lines.length > 0){
                    lines[lines.length-1].classList.add('last');
                }
            }   
        });
  });   
    });
});