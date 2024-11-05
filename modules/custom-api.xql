xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace api="http://teipublisher.com/api/custom";

(: Add your own module imports here :)
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace functx="http://www.functx.com";
import module namespace app="teipublisher.com/app" at "app.xql";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace vapi="http://teipublisher.com/api/view" at "lib/api/view.xql";
import module namespace dapi="http://teipublisher.com/api/documents" at "lib/api/document.xql";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";

import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

(:~
 : Keep this. This function does the actual lookup in the imported modules.
 :)
declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function api:get-link($request as map(*)){
    let $file :=$request?parameters?doc
   
    let $odd := if ($file = 'E40.xml') then ('nietzsche-dm.odd') else ('surface.odd')
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
     let $id := if ($document//tei:sourceDoc) then (
                $document//tei:sourceDoc/tei:surface[@start=concat('#', $request?parameters?id )]/@xml:id
            ) else ($request?parameters?id)
    let $element := $document//*[@xml:id = $id]
    return if ($element) then (
        map {
            "node": util:node-id($element),
            "odd" : $odd,
            "doc": $file
        }
    ) else ()
   
};

declare function api:node-id($request as map(*)){
    let $file := $request?parameters?doc
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $surface := $document//tei:sourceDoc/tei:surface[@xml:id = $request?parameters?id]
    return if ($surface) then (util:node-id($surface)) else ()
};

declare function api:timeline($request as map(*)){
    let $dates := $config:newest-dm//tei:profileDesc/tei:creation/tei:listChange/tei:change//tei:date/string(@when|@notAfter)
    let $years := (distinct-values(for $date in $dates
                                        return substring-before($date, '-')))
    let $array := []
    let $output := local:getYears($years, $dates, $array)
    let $log := console:log($output)
    let $data := map:merge((
        map:entry( 'test', $output )
    ))
    let $log := console:log($data)
    return $data
};
declare function local:getYears($years, $dates, $array) {
    let $year := $years[1]
    return if ($year != '') then (
        let $entry := map:entry($year, map:merge((local:getMonths($year, $dates)))) 
        return if (count($years) gt 1) then () else (array:append($array, $entry))
    ) else ()

        
};
declare function local:getMonths($year, $dates){
    for $month in distinct-values(for $date in $dates
                                                where starts-with($date, $year)
                                                let $datePart := substring-after($date, concat($year, '-'))
                                                return substring-before($datePart, '-')
                                        ) 
        return map:entry(
            $month, map { 'test': 'ok'}    
        )
};
declare function api:letters($request as map(*)){
    let $id := $request?parameters?id
    let $appendixFile := util:document-name($config:newest-annex)
    let $letters := for $letterId in distinct-values($config:newest-annex//*[@change=concat('#', $id)]/ancestor::tei:div2/@xml:id)
                        let $div2 := $config:newest-annex//*[@xml:id = $letterId]
                        return <pb-popover theme="material" placement="right">
                                <span slot="default">
                                    <a href="{ concat($appendixFile, '?template=nietzsche-timeline.html#', $div2/@xml:id) }">
                                       { $div2/tei:head/text() }
                                    </a>
                                </span>
                                <template slot="alternate">{$div2/tei:p}</template>
                        </pb-popover>
    return 
    <div class="appendix">
     { if (count($letters) gt 0) then (
        <pb-collapse class="changeInfo">
             <span class="mycollapse-trigger" slot="collapse-trigger">
                Dokumente zur Entstehungs- und Druckgeschichte
            </span>
            <span slot="collapse-content">
                <ul class="letters">{
                    for $letter in $letters
                    return <li>{ $letter} </li>
                }</ul>
            </span>
        </pb-collapse>
        ) else ()    }
    </div>
};
declare function api:change($request as map(*)){
    let $id := $request?parameters?id
    let $document := if ($request?parameters?doc) then (doc(concat($config:data-root, '/', $request?parameters?doc))) else ($config:newest-annex)
    let $source := $document//*[@xml:id=$id]
    let $changes := for $changeId in $source//*[@change]/substring-after(@change, '#')
                        return $config:newest-dm//*[@xml:id = $changeId]
    let $file := util:document-name($config:newest-dm)
    return 
    <div class="changes">
    {
        if (count($changes) gt 0) then (
             <pb-collapse class="changeInfo">
             <span class="mycollapse-trigger" slot="collapse-trigger">
                Relevante Bearbeitungsstufen
            </span>
            <span slot="collapse-content">
                <ul class="letters">{
                    for $change in $changes
                        let $path := concat($file, '?template=timeline.html#', $change/@xml:id)
                        let $key := $change/@xml:id
                    return <li><pb-highlight key="{$key}" highlight-self="highlight-self" duration="3000"><a href="{$path}">{ $change/node()}</a></pb-highlight> </li>
                }</ul>
            </span>
        </pb-collapse>
        ) else ()
    }
    </div>
};

declare function api:page4change($request as map(*)){
    let $xmlId := concat('#',$request?parameters?id)
    let $file := $request?parameters?doc
    let $document := doc(concat($config:data-root, '/',$file))
    let $pbs := $document//tei:pb[contains(@change, $xmlId)]
    return 
    <div class="pages">
    {
        if (count($pbs) gt 0) then (
            <pb-collapse class="changeInfo">
             <span class="mycollapse-trigger" slot="collapse-trigger">
                Bearbeitete Seiten
            </span>
            <span slot="collapse-content">
                <ul class="pages">{
                    for $pb in $pbs
                    let $surfaceId := util:node-id($document//tei:sourceDoc/tei:surface[@start=concat('#', $pb/@xml:id)])
                    let $n := string($pb/@xml:id)
                    let $path := concat($file, '?template=surface.html&amp;root=', $surfaceId)
                    return <li><a href="{$path}">
                        {$n}
                    </a></li>
                }</ul>
            </span>
        </pb-collapse>    
        ) else ()    
    }
    </div>
};

declare function api:handNote4change($request as map(*)){
    let $xmlId := concat('#',$request?parameters?id)
    let $file := $request?parameters?doc
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $sourceDoc := if ($request?parameters?source) then ($document//tei:sourceDoc/tei:surface[@xml:id = $request?parameters?source]) else ()
    let $pb := if ($sourceDoc) then ($document//tei:pb[@xml:id = substring-after($sourceDoc/@start, '#')]) else ()
    let $log := console:log($xmlId)
    let $log2 := console:log($document//tei:handNote[contains(@change, $xmlId)])
    let $handNote :=  
    <ul class="handNotes">
    {
       for $handNote in $document//tei:handNote[contains(@change, $xmlId)]
            where local:filterHand($handNote, $document, $sourceDoc, $pb)
            return <li><pb-toggle-feature data-type="handNote" subscribe="transcription" emit="transcription" name="{$handNote/@xml:id}" default="off" selector=".{$handNote/@xml:id}, .strikethrough-{$handNote/@xml:id}, .deleted-{$handNote/@xml:id}, .hatching-{$handNote/@xml:id}">{$handNote/text()}</pb-toggle-feature></li>
    }
    </ul>
    let $log := console:log($handNote)
    return $handNote
};

declare function local:filterHand($handNote, $document, $sourceDoc as node()?, $pb as node()?) as xs:boolean {
    if ($sourceDoc and $pb) then (
        (count($sourceDoc//*[@hand=concat('#', $handNote/@xml:id)]) gt 0) or (contains($pb/@corresp, $handNote/@xml:id))
    ) else (
        true()    
    )    
};

declare function api:get-link-for-target($request as map(*))  {
    let $targetId := $request?parameters?id
    let $content := replace($request?parameters?content, '%20', ' ')
    let $targetDoc := if ($request?parameters?refDoc) then ($request?parameters?refDoc) else ($request?parameters?doc)
    let $targetFile := concat($config:data-root, '/', $targetDoc)
    return if ($targetDoc and doc-available($targetFile)) then (
        let $targetElement := doc($targetFile)//*[@xml:id=$targetId]
        let $log := if ($targetElement) then (console:log($targetElement)) else (console:log($targetId))
        return if ($targetElement) then (
            let $parent := $targetElement/ancestor::*[local-name() = 'text' or local-name() = 'sourceDoc' or local-name() = 'teiHeader']
            return typeswitch($parent)
                case element(tei:text) return 
                    if ($targetElement instance of element(tei:pb)) then (
                        let $surface := doc($targetFile)//tei:sourceDoc/tei:surface[@start=concat('#', $targetId)]
                        return <pb-link emit="transcription" subscribe="transcription" node-id="{util:node-id($surface)}">{$content}</pb-link>
                    ) else ( 
                        <span class="noLink0">{ $content }</span>
                    )
                case element(tei:sourceDoc) return <pb-link node-id="{util:node-id($targetElement)}">{$content}</pb-link>
                case element(tei:teiHeader) return <a href="?template=meta.html#{$targetId}">{$content}</a>
                default return <pb-link emit="transcription" subscribe="transcription" xml-id="{$targetId}">{$content}</pb-link>
        ) else (
            <span class="noLink1">{ $content }</span>
        )
    ) else (
         <span class="noLink2">{ $content }</span>
    )
};

declare function api:get-meta-toc($request as map(*)){
    let $document := doc(concat($config:data-root, '/', $request?parameters?id))
    let $namespace := namespace-uri-from-QName(node-name(root($document)/*))
    let $target := $request?parameters?target
    return
    <ul>
        {
        for $entry in $config:meta-entries
            let $xquery := "declare default element namespace '" || $namespace || "'; $document//" || $entry
            let $log := console:log($xquery)
            let $xmlId := util:eval($xquery)/local-name()
            return 
        <li>
             <pb-link emit="{$target}" subscribe="{$target}" xml-id="{$xmlId}">{$xmlId}</pb-link>
        </li>
        }
    </ul> 
};


