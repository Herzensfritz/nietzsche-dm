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
            return <note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" target="{concat('#',root($root)//tei:text//tei:note[@xml:id = $note/@xml:id]/preceding::tei:lb[1]/@xml:id)}">{$note/text()}</note>
    }</div>

    return $div
};

(:~
 : For the Nietzsche Druckmanuskript: find the notes  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-diffs($root as element(), $userParams as map(*)) {
    let $log := console:log($userParams)
    let $pbId := substring-after($root/@start, '#')
    let $notes := if (root($root)//tei:surface[@xml:id = $root/@xml:id]/following-sibling::tei:surface) then (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[1][@xml:id = $pbId] and  following::tei:pb[preceding::tei:pb[1][@xml:id = $pbId] ]]
    ) else (
        root($root)//tei:text//tei:note[@type="editorial" and preceding::tei:pb[@xml:id = $pbId]]    
    )
    let $div := <div xmlns="http://www.tei-c.org/ns/1.0" type="noteDiv">{ for $note in $notes
            return <note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" target="{concat('#',root($root)//tei:text//tei:note[@xml:id = $note/@xml:id]/preceding::tei:lb[1]/@xml:id)}">{$note/text()}</note>
    }</div>

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

