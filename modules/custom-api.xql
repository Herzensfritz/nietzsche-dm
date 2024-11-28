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
import module namespace capi="http://teipublisher.com/api/collection" at "lib/api/collection.xql";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "lib/browse.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace templates="http://exist-db.org/xquery/html-templating";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";

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
declare function api:test($request as map(*)) {
    let $json := $request?body
    let $log := console:log($json?test)
    return <html><body>OK</body></html>
};
declare
    %templates:wrap
function api:short-header($node as node(), $model as map(*)) {
        let $work := root($model("work"))/*
        let $file := util:document-name(root($model("work")))
        
        let $result := array:filter($model("mapping")?files, function ($item) { $item?name = $file})
        let $prefix := if (array:size($result) gt 0) then (array:get($result, 1)?target) else ()
        let $relPath := concat($prefix, '/index.html')
        return
            try {
                let $config := tpu:parse-pi(root($work), (), ())
                let $header :=
                    $pm-config:web-transform(nav:get-header($model?config, $work), map {
                        "header": "short",
                        "meta": $prefix,
                        "doc": $relPath
                    }, $config?odd)
                return
                    if ($header) then
                        $header
                    else
                        <a href="{$relPath}">{util:document-name($work)}</a>
            } catch * {
                <a href="{$relPath}">{util:document-name($work)}</a>,
                <p class="error">Failed to output document metadata: {$err:description}</p>
            }
};
declare function api:list($request as map(*)) {
    let $json := $request?body
    let $size := array:size($json?files)
    let $names := array:for-each($json?files, function ($item) { if ($item?type ='doc') then ($item?name) else () })
    let $params := map { "collection": () }
    let $works := capi:list-works((), (), $params)
    let $template :=  $config:app-root || "/templates/static-collection.html"
    let $lookup := function($name as xs:string, $arity as xs:int) {
        try {
            let $cfun := api:lookup($name, $arity)
            return
                if (empty($cfun)) then
                    function-lookup(xs:QName($name), $arity)
                else
                    $cfun
        } catch * {
            ()
        }
    }
    let $filtered := for $data in $works?all
                    let $file := util:document-name($data)
                    let $index := index-of($names, $file)
                    where exists($index)
                    order by $index
                    return $data
    let $model := map {
        "all": $filtered,
        "app": $config:context-path,
        "mapping": $json,
        "mode": "browse"
    }
    
    return
        templates:apply(doc($template), $lookup, $model, tpu:get-template-config($request))
};
declare function api:get-all-links($request as map(*)){
    let $file :=$request?parameters?doc
    let $json := $request?body
    let $channel := if ($request?parameters?target) then ($request?parameters?target) else ('transcription')
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $refs := for $ref in $document//tei:ref[@target]
                    return local:create-link($ref, $json?files, $channel)
    return $refs
   
};

declare function local:create-link($ref as node(), $files as array(*), $channel as xs:string) {
    let $target := tokenize($ref/@target/string())[1]
    let $targetDoc := substring-before($target, '#')
    let $targetFile := if ($targetDoc) then (concat($config:data-root, '/', $targetDoc)) else ()
    let $id := if ($targetDoc = 'E40.xml') then (concat(substring-after($target, '#'), '_id')) else (substring-after($target, '#'))
    let $currentDoc := if ($targetFile and doc-available($targetFile)) then (doc($targetFile)) else ($config:newest-dm)
    let $names := array:for-each($files, function ($item) { $item?name })
    return if ($config:newest-annex//*[@xml:id = $id]) then (
        <pb-link xml-id="{$id}" subscribe="{$channel}" emit="{$channel}">{$ref/text()}</pb-link>
    ) else (
        if ($currentDoc//*[@xml:id = $id]) then (
            if ($targetDoc and doc-available($targetFile)) then (
                local:get-static-link($ref, $id, $targetDoc, $names, $files)
            ) else (
               if($config:newest-dm//tei:pb[@xml:id = $id]) then (
                    let $docName := util:document-name($config:newest-dm)
                    return local:get-static-link($ref, $id, $docName, $names, $files)
                ) else (
                    <a data-id="{$id}" href="{concat('/meta-dm/index.html', $target)}">{$ref/text()}</a> 
                ) 
            )
        ) else ()
    )
};

declare function local:get-static-link($ref as node(), $targetId as xs:string, $doc as xs:string, $names as array(xs:string*), $files as array(*)){
    let $index := index-of($names, $doc)
    return if ($index gt 0) then (
        let $dataId := substring-after(tokenize($ref/@target/string())[1], '#')
        let $target := array:get($files, $index)?target
        let $id := if (array:get($files, $index)?prefix) then ( concat(array:get($files, $index)?prefix, $targetId)) else ($targetId)
        let $href := concat('/', $target, '/index.html?id=', $id)
        return <a data-id="{$dataId}" href="{$href}">{$ref/text()}</a>    
    ) else ()
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

declare function api:static-timeline($request as map(*)){
     let $file := $request?parameters?doc
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    return pages:static-timeline($document)
};
declare function api:static-letters($request as map(*)){
    let $file := $request?parameters?doc
    let $href := concat('/', $request?parameters?href, '/index.html')
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $letters := for $change in $document//tei:teiHeader/tei:profileDesc/tei:creation/tei:listChange/tei:change/@xml:id/string()
                        return local:letters($change, $href)
    return $letters
    
};
declare function api:letters($request as map(*)){
    let $appendixFile := util:document-name($config:newest-annex)
    let $href := concat($appendixFile, '?template=nietzsche-timeline.html')
    return local:letters($request?parameters?id, $href)   
};
declare function local:letters($id as xs:string*, $href as xs:string*){
    let $letters := for $letterId in distinct-values($config:newest-annex//*[@change=concat('#', $id)]/ancestor::tei:div2/@xml:id)
                        let $div2 := $config:newest-annex//*[@xml:id = $letterId]
                        return <pb-popover theme="material" placement="right">
                                <span slot="default">
                                    <a href="{ concat($href, '#', $div2/@xml:id) }">
                                       { $div2/tei:head/. }
                                    </a>
                                </span>
                                <template slot="alternate">{$div2/tei:p}</template>
                        </pb-popover>
    return 
    <div class="appendix" data-id="{$id}">
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
declare function api:static-change($request as map(*)){
    let $file := $request?parameters?doc
    let $href := concat('/', $request?parameters?href, '/index.html')
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $changes := for $letter in $document//tei:text/tei:back/tei:div1/tei:div2/@xml:id/string()
                        return local:change($letter, $document, $href)
    return $changes
    
};
declare function api:change($request as map(*)){
    let $id := $request?parameters?id
    let $document := if ($request?parameters?doc) then (doc(concat($config:data-root, '/', $request?parameters?doc))) else ($config:newest-annex)   
    return local:change($id, $document, ())
};
declare function local:change($id as xs:string, $document as node(), $href as xs:string*){
    let $source := $document//*[@xml:id=$id]
    let $changes := for $changeId in $source//*[@change]/substring-after(@change, '#')
                        return $config:newest-dm//*[@xml:id = $changeId]
    let $file := if ($href) then ($href) else (concat(util:document-name($config:newest-dm), '?template=timeline.html'))
    return 
    <div data-id="{$id}" class="changes" data-count="{ count($changes)}">
    {
        if (count($changes) gt 0) then (
             <pb-collapse class="changeInfo">
             <span class="mycollapse-trigger" slot="collapse-trigger">
                <pb-i18n key="myapp.menu.change">Werkgenetische Bezüge</pb-i18n>
            </span>
            <span slot="collapse-content">
                <ul class="letters">{
                    for $change in $changes
                        let $path := concat($file, '#', $change/@xml:id)
                    return <li><a href="{$path}">{ $change/tei:label/text()}</a> </li>
                }</ul>
            </span>
        </pb-collapse>
        ) else ()
    }
    </div>
};
declare function api:get-pbs($request as map(*)){
    let $file := $request?parameters?doc
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $pages :=   for $pb in $document//tei:pb
                        return map {
                            'id': concat($request?parameters?prefix, $pb/@xml:id/string()),
                            'n': $pb/@n/string()
                        }
    return $pages
    
};
declare function api:static-page4change($request as map(*)){
    let $file := $request?parameters?doc
    let $href := concat('/', $request?parameters?href, '/index.html')
    let $document := if ($file) then (doc(concat($config:data-root, '/',$file))) else ($config:newest-dm)
    let $pages :=   for $change in $document//tei:teiHeader/tei:profileDesc/tei:creation/tei:listChange/tei:change/@xml:id/string()
                        return local:page4change($change, $document, $href)
    return $pages
    
};

declare function api:page4change($request as map(*)){
    let $file := $request?parameters?doc
    let $document := doc(concat($config:data-root, '/',$file))
    return local:page4change($request?parameters?id, $document, concat($file, '?template=surface.html'))
};
declare function local:page4change($id as xs:string, $document as node(), $href as xs:string*){
    let $xmlId := concat('#',$id)
    let $pathPrefix := if(contains($href, '?')) then (concat($href, '&amp;')) else (concat($href, '?'))
    let $pbs := $document//tei:pb[contains(@change, $xmlId)]
    return 
    <div data-id="{$id}" class="pages">
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
                    let $path := concat($pathPrefix, 'root=', $surfaceId)
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
    let $handNote :=  
    <ul class="handNotes">
    {
       for $handNote in $document//tei:handNote[contains(@change, $xmlId)]
            where local:filterHand($handNote, $document, $sourceDoc, $pb)
            return <li><pb-toggle-feature data-type="handNote" subscribe="transcription" emit="transcription" name="{$handNote/@xml:id}" default="off" selector=".{$handNote/@xml:id}, .strikethrough-{$handNote/@xml:id}, .deleted-{$handNote/@xml:id}, .hatching-{$handNote/@xml:id}">{$handNote/text()}</pb-toggle-feature></li>
    }
    </ul>
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
    let $descString := 'descChapter'
    return
    <ul>
        {
        for $entry in $document//*[@xml:id and contains(@xml:id, $descString)]
            where number(replace(substring-after($entry/@xml:id/string(), $descString), '\.','')) lt 10
            let $key := concat('myapp.meta.',replace($entry/@xml:id/string(), '\.', '') )
            order by substring-after($entry/@xml:id/string(), $descString)
            return 
        <li>{
            let $subEntries := $entry//*[@xml:id and starts-with(@xml:id, $entry/@xml:id/string())]
            return if (count($subEntries) gt 0) then (
                    <pb-collapse>
                        <span slot="collapse-trigger"><pb-link emit="{$target}" subscribe="{$target}" xml-id="{$entry/@xml:id/string()}"><pb-i18n key="{$key}">...key...</pb-i18n></pb-link></span>
                        <span slot="collapse-content">  
                        {   for $subEntry in $subEntries
                                let $subKey := concat('myapp.meta.',replace($subEntry/@xml:id/string(), '\.', '') )
                                order by $subEntry/@xml:id/string()
                                return 
                            <pb-link emit="{$target}" subscribe="{$target}" xml-id="{$subEntry/@xml:id/string()}"><pb-i18n key="{$subKey}">...key...</pb-i18n></pb-link>
                            }
                        </span>
                    </pb-collapse>
                ) else 
                (<pb-link emit="{$target}" subscribe="{$target}" xml-id="{$entry/@xml:id/string()}"><pb-i18n key="{$key}">...key...</pb-i18n></pb-link>)
            }
        </li>
        }
    </ul> 
};


