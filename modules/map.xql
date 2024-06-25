(:~
 : Implements a mechanism to replace a fragment shown by `pb-view` with another, aligned fragment, e.g. the translation
 : corresponding to a page of the transcription. The local name of a function in this module can be passed to the
 : `map` property of the `pb-view`.
 :)
module namespace mapping="http://www.tei-c.org/tei-simple/components/map";

import module namespace nav="http://www.tei-c.org/tei-simple/navigation/tei" at "navigation-tei.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

(:~
 : For the Nietzsche Druckmanuskript: find the page break  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-page($root as element(), $userParams as map(*)) {
    let $pbId := substring-after($root/@start, '#')
    return root($root)//tei:text//tei:pb[@xml:id = $pbId]
};
                                    
(:~
 : For the Nietzsche Druckmanuskript: find the notes  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-notes($root as element(), $userParams as map(*)) {
    let $pbId := substring-after($root/@start, '#')
    let $notes := if (root($root)//tei:surface[@xml:id = $root/@xml:id]/following-sibling::tei:surface) then (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[1][@xml:id = $pbId] and  following::tei:pb[preceding::tei:pb[1][@xml:id = $pbId] ]]
    ) else (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[@xml:id = $pbId]]    
    )
    let $div := <div xmlns="http://www.tei-c.org/ns/1.0" type="noteDiv">{ for $note in $notes
            let $target := local:getLineTargets($root, $note/@xml:id, $note/text(), true())
            let $targetEnd := local:getLineTargets($root, $note/@xml:id, $note/text(), false())
            return if ($targetEnd) then (<note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" 
                            target="{$target}" targetEnd="{$targetEnd}">
                            {local:parseNoteContent($note/text())}
                            </note>) 
                    else (
                       <note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" 
                            target="{$target}">
                            {local:parseNoteContent($note/text())}
                            </note>
                     )
    }</div>
    let $log := console:log($div)
    return $div
};

declare function local:getLineTargets($root, $id, $text, $isFirst) {
    if (matches($text, '.*[0-9]+-[0-9]+:')) then (
        let $lineRef := substring-before($text, ':')    
        let $firstId := substring-before($lineRef, '-')
        let $lastId := substring-after($lineRef, '-')
        return if ($isFirst) then (concat('#',root($root)//tei:text//tei:lb[@n = $firstId]/@xml:id)) else (concat('#',root($root)//tei:text//tei:lb[@n = $lastId]/@xml:id)) 
    ) else (
        if ($isFirst) then (concat('#',root($root)//tei:text//tei:note[@xml:id = $id]/preceding::tei:lb[1]/@xml:id)) else ()      
    )    
};

declare function local:parseNoteContent($text as xs:string*) {
    if (contains($text, ']')) then (
        <term xmlns="http://www.tei-c.org/ns/1.0" type="lem"> {local:parseNoteContent(substring-before($text, ']')) } </term>, substring-after($text, ']')
    ) else (
        if (matches($text, '.*[0-9]:')) then (
            substring-after($text, ':')    
        ) else ($text)    
    )    
};

declare function local:extendApp($node as node()*, $ED){

    let $seg := if (count($node/@from) > 1) then ($ED//tei:seg[@xml:id=substring-after($node[1]/@from, '#')]) else ($ED//tei:seg[@xml:id=substring-after($node/@from, '#')])
    let $log := console:log($seg)
    return if ($seg) then (
        element { node-name($node) } {
                            $node/@* except $node/@exist:id,
                            attribute exist:id { util:node-id($node) },
                            attribute n { concat($seg/preceding::tei:pb[not(@edRef)][1]/@n, ',', $seg/preceding::tei:lb[not(@edRef)][1]/@n) },
                            util:expand(($node/(*|text())), "add-exist-id=all")  
                        }     
    ) else
        $node
};

(:~
 : For the Nietzsche Druckmanuskript: find the notes  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-diffs($root as element(), $userParams as map(*)) {
    let $ED := doc($config:data-root || "/GM_Ed_incl.xml")
    let $rdgs := for $line in $root//tei:line/@start
                    return local:extendApp($ED//tei:rdg[@wit="#Dm" and @source=$line]/parent::tei:app, $ED)
    let $pbId := substring-after($root/@start, '#')
    let $notes := if (root($root)//tei:surface[@xml:id = $root/@xml:id]/following-sibling::tei:surface) then (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[1][@xml:id = $pbId] and  following::tei:pb[preceding::tei:pb[1][@xml:id = $pbId] ]]
    ) else (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[@xml:id = $pbId]]    
    )
    let $div := <div xmlns="http://www.tei-c.org/ns/1.0" type="noteDiv">{ for $note in $notes
            return <note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" target="{concat('#',root($root)//tei:text//tei:note[@xml:id = $note/@xml:id]/preceding::tei:lb[1]/@xml:id)}">{$note/text()}</note>
    }{    for $rdg in $rdgs
                return $rdg
    }</div>
    let $log := console:log($div)

    return $div
};

(:~
 : For the Van Gogh letters: find the page break in the translation corresponding
 : to the one shown in the transcription.
 :)
declare function mapping:vg-translation($root as element(), $userParams as map(*)) {
    let $id := ``[pb-trans-`{$root/@f}`-`{$root/@n}`]``
    let $node := root($root)/id($id)
    return
        $node
};

declare function mapping:cortez-translation($root as element(), $userParams as map(*)) {
    let $first := (($root/following-sibling::text()/ancestor::*[@xml:id])[last()], $root/following-sibling::*[@xml:id], ($root/ancestor::*[@xml:id])[last()])[1]
    let $last := $root/following::tei:pb[1]
    let $firstExcluded := ($last/following-sibling::*[@xml:id], $last/following::*[@xml:id])[1]

    let $mappedStart := root($root)/id(translate($first/@xml:id, "s", "t"))
    let $mappedEnd := root($root)/id(translate($firstExcluded/@xml:id, "s", "t"))
    let $context := root($root)//tei:text[@type='translation']

    return
        nav:milestone-chunk($mappedStart, $mappedEnd, $context)
};

(:~  mapping by retrieving same book number in the translation; assumes div view  ~:)
declare function mapping:barum-book($root as element(), $userParams as map(*)) {
        let $bookNumber := $root/@n
        let $node := root($root)//tei:text[@type='translation']//tei:div[@type="book"][@n=$bookNumber]

    return
        $node
};

(:~  mapping by translating id prefix, by default from prefix s to t1  ~:)
declare function mapping:prefix-translation($root as element(), $userParams as map(*)) {
    let $sourcePrefix := ($userParams?sourcePrefix, 's')[1]
    let $targetPrefix := ($userParams?targetPrefix, 't1')[1]
   
    let $id := $root/@xml:id
    
    let $node := root($root)/id(translate($id, $sourcePrefix, $targetPrefix))

    return
        $node
};

(:~  mapping trying to find a node in the same relation to the base of translation as current node to the base of transcription  ~:)
declare function mapping:offset-translation($root as element(), $userParams as map(*)) {
    
let $language := ($userParams?language, 'en')[1]

let $node-id := util:node-id($root)

let $source-root := util:node-id(root($root)//tei:text[@type='source']/tei:body)
let $translation-root := util:node-id(root($root)//tei:text[@type='translation'][@xml:lang=$language]/tei:body)

let $offset := substring-after($node-id, $source-root)

let $node := util:node-by-id(root($root), $translation-root || $offset) 

return 
    $node

};

