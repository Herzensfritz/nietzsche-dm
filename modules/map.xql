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


declare function mapping:nietzsche-test($root as element(), $userParams as map(*)) {
     let $log := console:log($root) 
     return
     <div xmlns="http://www.tei-c.org/ns/1.0" type="test"/>
};
(:~
 : For the Nietzsche Druckmanuskript: find the page break  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-page($root as element(), $userParams as map(*)) {
    let $pbId := substring-after($root/@start, '#')
    return root($root)//tei:text//tei:pb[@xml:id = $pbId]
};
declare function mapping:nietzsche-dm-for-ed($root as element(), $userParams as map(*)) {
    let $next := $root/following::tei:pb[1]
    let $milestones := root($root)//tei:text//tei:milestone[preceding::tei:pb[@n = $root/@n] and following::tei:pb[@n = $next/@n]] 
    let $surfaces := for $milestone in $milestones
                        let $start := concat('#', $milestone/@n)
                        return $config:newest-dm//tei:sourceDoc/tei:surface[@start = $start] 
    let $file := util:document-name($config:newest-dm)
    return <div xmlns="http://www.tei-c.org/ns/1.0" type="corresp">
            {   for $surface in $surfaces
                    return element pb {
                        attribute n {substring-after($surface/@start, '#')},
                        attribute ed {$file},
                        attribute source { util:node-id($surface)}    
                    }
                        
            }
        </div>
};
(:~
 : For the Nietzsche Druckmanuskript: find the ed text corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-ed-for-dm($root as element(), $userParams as map(*)) {
    let $pb := substring-after($root/@start, '#')
    let $milestone := $config:newest-ed//tei:text//tei:milestone[@unit="page" and @source="#Dm" and @n=$pb ]
    let $log := console:log($milestone)
    return if (exists($milestone)) then (
        let $nextMilestone := $milestone/following::tei:milestone[@unit="page" and @source="#Dm"][1]
        let $content := if (exists($nextMilestone)) then (
            local:filterNodes(($milestone/following::node() intersect $nextMilestone/preceding::node()), util:document-name($config:newest-ed))
        ) else (
            local:filterNodes($milestone/following::node()[ancestor::tei:text and not(ancestor::*/preceding::tei:milestone = $milestone)], util:document-name($config:newest-ed))
        )
        (:  :let $log := console:log($content) :)
        let $firstLB := if ($milestone/following-sibling::*[1]/local-name() != 'lb') then (
            $milestone/preceding::tei:lb[1]    
        ) else ()
        let $omitText := if (count($firstLB/following::node() intersect $milestone/preceding::node()) gt 0) then (
            <hi xmlns="http://www.tei-c.org/ns/1.0" rend="italic" type="editor">[...]</hi>    
        ) else ()
        let $omitTextAfter := if (exists($nextMilestone) and $nextMilestone/following::tei:lb[1]/ancestor::tei:div2 = $nextMilestone/ancestor::tei:div2 
                and count($nextMilestone/following::node() intersect $nextMilestone/following::tei:lb[1]/preceding::node()) gt 0) then (
            <hi xmlns="http://www.tei-c.org/ns/1.0" rend="italic" type="editor">[...]</hi>    
        ) else ()
        let $div := <div xmlns="http://www.tei-c.org/ns/1.0">
            {   $firstLB,
                $omitText,
                $content,
                $omitTextAfter}
        </div>
        let $log := console:log($div)
        return $div
    ) else (
        <div>{concat('Kein Milestone in ', util:document-name($config:newest-ed),' für ', $pb)} </div>    
    )
};
declare function local:filterNodes($nodes, $file){
    let $filteredNodes := for $node in $nodes
                                return if(count($node/parent::* intersect $nodes) gt 0) then () else (
                                    if ($node instance of element(tei:pb) or $node instance of element(tei:div2)) then (
                                        element {node-name($node)} {
                                            $node/@* except $node/@facs,
                                            attribute ed {$file},
                                            attribute source { util:node-id($node)},
                                            $node/node()
                                        }
                                    ) else ($node)
                                )
    return $filteredNodes    
};
   
   (:~
 : For the Nietzsche Druckmanuskript: find the page information  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-page-info($root as element(), $userParams as map(*)) {
    let $pbId := substring-after($root/@start, '#')
    let $div := <div xmlns="http://www.tei-c.org/ns/1.0" type="pageInfo">{
        for $id in  root($root)//tei:text//tei:pb[@xml:id = $pbId]/tokenize(@corresp, ' ')
            let $content := root($root)//*[@xml:id = substring-after($id, '#') ]
            return if ($content) then ( 
                element {node-name($content/ancestor::*[local-name() != 'p'][1])} {
                    $content    
                }
            ) else ()
    }
    </div>
    let $log := console:log($div)
    return $div
};    
declare %private function local:getCorrContents($root as element(), $corresp as xs:string?, $userParams as map(*)){
    if($corresp and contains($corresp, '#')) then (
        let $first := substring-after(substring-before($corresp[1], ' '), '#')
        let $content := root($root)//*[@xml:id = $first ]
        return 
            element {node-name($content/ancestor::*[local-name() != 'p'][1])} {
                $content    
            },
            let $rest := substring-after($corresp, ' ')
            return if ($rest) then (
                local:getCorrContents($root, $rest, $userParams)
            ) else ()  
    ) else ()    
};

(:~
 : For the Nietzsche Druckmanuskript: find the notes  corresponding
 : to the surface shown in the diplomatic transcription.
 :)
declare function mapping:nietzsche-apps($root as element(), $userParams as map(*)) {
    if (empty(root($root)//tei:text//tei:app/tei:note[@type="editorial"]) and count(root($root)//tei:text//tei:note[@type="editorial"]) gt 0) then (
        mapping:nietzsche-notes($root, $userParams)    
    ) else (
        let $pbId := substring-after($root/@start, '#')
        let $apps := if (root($root)//tei:surface[@xml:id = $root/@xml:id]/following-sibling::tei:surface) then (
            root($root)//tei:text//tei:app[tei:note[@type="editorial"] and preceding::tei:pb[1][@xml:id = $pbId] and following::tei:pb[preceding::tei:pb[1][@xml:id = $pbId]] ]
        ) else (
            root($root)//tei:text//tei:app[tei:note[@type="editorial"] and preceding::tei:pb[@xml:id = $pbId]]    
        )
        let $pbN := root($root)//tei:text//tei:pb[@xml:id = $pbId]/@xml:id
        let $div := <div xmlns="http://www.tei-c.org/ns/1.0" type="noteDiv">
           
            { for $app in $apps
                return if ($app/@from) then ($app) else (
                   element { node-name($app) } {
                        $app/@*[local-name() != 'loc' and local-name() != 'corresp'],
                        attribute loc {
                            normalize-space(substring-after($app/@loc, $pbN))   
                        },
                        if (count(tokenize($app/@corresp)) gt 1) then (
                            local:parseLoc($root, $app/@loc, $app/@corresp)
                        ) else (
                            attribute corresp {
                                $app/@corresp    
                            }    
                        ),
                        $app/(tei:lem|tei:note)
                    }
                )
        }</div>
        let $log := console:log($div)
        return $div
    )
};
declare function local:parseLoc($root as node(), $loc as xs:string?, $corresp as xs:string*) as attribute()* {
    if ($corresp) then (
        let $correspTok := tokenize($corresp)
        let $tokLength := count($correspTok)
        return if ($tokLength gt 2) then (
            attribute corresp {
                $correspTok[1]    
            },
            attribute from {
                $correspTok[2]    
            },
            attribute to {
                $correspTok[$tokLength]
            }
        ) else (
            attribute corresp {
                $correspTok[1]    
            },
            attribute from {
                $correspTok[2]    
            }
        )    
    ) else (
        if (contains($loc, ',')) then (
            let $locTok := tokenize($loc, '-')
            return if (count($locTok) gt 1) then (
                local:createTargetAttribute($root, substring-after($locTok[1], ','),'from'), local:createTargetAttribute($root, $locTok[2],'to')
            ) else (
                local:createTargetAttribute($root, substring-after($locTok[1], ','),'from')    
            )
        ) else ()
    )
};
declare function local:createTargetAttribute($root as node(), $n as xs:string, $attrName as xs:string) {
    attribute {$attrName} {
        concat('#',root($root)//tei:text//tei:lb[@n = $n]/@xml:id)          
    }    
};
declare function mapping:nietzsche-notes($root as element(), $userParams as map(*)) {
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
            return if ($note/@target and $note/tei:term) then ($note) else (
                let $target := if ($note/@target) then ($note/@target) else (local:getLineTargets($root, $note/@xml:id, $note/text(), true()))
                let $targetEnd := if ($note/@targetEnd) then ($note/@targetEnd) else (local:getLineTargets($root, $note/@xml:id, $note/text(), false()))
                return if ($targetEnd) then (<note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" 
                            target="{$target}" targetEnd="{$targetEnd}">
                            {local:parseNoteContent($note)}
                            </note>) 
                    else (
                       <note xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$note/@xml:id}" type="{$note/@type}" 
                            target="{$target}">
                            {local:parseNoteContent($note)}
                            </note>
                     )
            )
    }{    for $rdg in $rdgs
                return $rdg
    }</div>
    return $div
};

declare function local:getLineTargets($root, $id, $text, $isFirst) {
    if (matches($text, '.*[0-9]+-[0-9]+:')) then (
        let $lineRef := substring-before($text[1], ':')    
        let $firstId := substring-before($lineRef, '-')
        let $lastId := substring-after($lineRef, '-')
        return if ($isFirst) then (concat('#',root($root)//tei:text//tei:lb[@n = $firstId]/@xml:id)) else (concat('#',root($root)//tei:text//tei:lb[@n = $lastId]/@xml:id)) 
    ) else (
        if ($isFirst) then (concat('#',root($root)//tei:text//tei:note[@xml:id = $id]/preceding::tei:lb[1]/@xml:id)) else ()      
    )    
};

declare function local:parseNoteContent($item as item()*) {
    if (contains($item/text()[1], ']')) then (
        <term xmlns="http://www.tei-c.org/ns/1.0" type="lem"> {substring-after(substring-before($item/text()[1], ']'), ':') } </term>, substring-after($item/text()[1], ']'), ($item/*|$item/text()[position() gt 1])
    ) else (
        if (matches($item/text()[1], '.*[0-9]:')) then (
            substring-after($item/text()[1], ':'), ($item/*|$item/text()[position() gt 1])    
        ) else ($item/(*|text()))    
    )    
};

declare function local:extendApp($node as node()*, $ED){

    let $seg := if (count($node/@from) > 1) then ($ED//tei:seg[@xml:id=substring-after($node[1]/@from, '#')]) else ($ED//tei:seg[@xml:id=substring-after($node/@from, '#')])
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

