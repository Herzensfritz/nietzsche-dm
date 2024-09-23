(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

(:~
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace http="http://expath.org/ns/http-client";

declare variable $pages:EXIDE :=
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");
        
declare function pages:timeline($node as node(), $model as map(*)) {
    let $document := doc(concat($config:data-root, '/', $model?doc))
    let $namespace := namespace-uri-from-QName(node-name(root($document)/*))
    let $xquery := "declare default element namespace '" || $namespace || "'; $document" || $node/@xpath
    let $data := util:eval($xquery)
    let $map := local:yearMaps($data//tei:change, 1)
    return if (count($map) eq 0) then ($node) else (
             <h1 id="{concat('year-', $map?year)}" class="year"> { $map?year }</h1>,<table class="months"> {
                    for $month in $map?months
                        let $monthKey := concat('myapp.months.', $month?month)
                        return <tr><td id="{concat($map?year, '-', $month?month)}" class="month"><pb-i18n key="{$monthKey}">{ $month?month }</pb-i18n></td><td>
                            { for $key in $month?keys 
                                return element { node-name($node)} {
                                        $node/@* except $node/(@xpath|@data-template),
                                        attribute xpath { concat($node/@xpath, "/change[@xml:id='", $key, "']")},
                                        attribute id { $key }
                                    }
                            }
                       </td></tr>
                }
                </table>
    )
};

declare function local:yearMaps($changes, $index){
    let $years := for $year in  (distinct-values(for $change in $changes
                                        return substring-before($change/tei:date/(@when|@notAfter|@notBefore)[1], '-')))
                            where $year != ''
                            return $year
    let $currentYearMonths := for $change in $changes
                    where $change/tei:date/starts-with((@when|@notAfter|@notBefore)[1], $years[$index])
                    return $change
    let $months := local:monthMaps($years[$index], $currentYearMonths, 1)
    let $currentYearMap := map { "year": $years[$index], "months": $months }
    return if (count($years) gt $index) then (
        $currentYearMap, local:yearMaps($changes, $index+1)       
    ) else (
        $currentYearMap
    )
};
declare function local:monthMaps($year, $changes, $index){
    let $prefix := concat($year,'-')
    let $months := for $month in (distinct-values(for $change in $changes
                                        return substring-before(substring-after($change/tei:date/(@when|@notAfter|@notBefore)[1], $prefix), '-')))
                                where $month != ''
                                return $month
    let $currentPrefix := concat($prefix, $months[$index])
    let $keys := for $change in $changes
                    where $change/tei:date/starts-with((@when|@notAfter|@notBefore)[1], $currentPrefix)
                    return $change/string(@xml:id)
    let $currentMonthMap := map {"month": $months[$index], "keys": $keys}
    return if (count($months) gt $index) then (
        $currentMonthMap, local:monthMaps($year, $changes, $index+1)       
    ) else (
        $currentMonthMap
    )
};

declare function pages:timeline-link($node as node(), $model as map(*)) {
    if ($model?template != 'timeline.html') then (
        let $file := if ($model?doc and doc(concat($config:data-root,'/', $model?doc))//tei:profileDesc/tei:creation/tei:listChange/tei:change) 
                    then ($model?doc) else (util:document-name($config:newest-dm))
        return element { node-name($node) } {
            $node/@* except $node/@data-template,
            attribute href { concat($file, '?template=timeline.html') },
            $node/node()
        }
    ) else ()

};

(:~
 : Needed for backwards compatibility with TEI Publisher 7.0
 :)
declare function pages:parse-params($node as node(), $model as map(*)) {
    lib:parse-params($node, $model, "\$\{", "\}")
};

declare function pages:parse-myparams($node as node(), $model as map(*)) {
    if ($model?doc) then (
    let $file := replace($model?doc, '_tp','')
    let $a := <a href="/exist/restxq/transform?file={$file}" target="topoTEI">topoTEI</a>
    return $a  
    ) else ($node)
    
};
declare function pages:check-toc($node as node(), $model as map(*)) {
    let $uri := concat($config:data-root,'/', $model?doc)
    return if ($model?doc and count(doc($uri)//tei:sourceDoc/tei:surface) eq 1) then (
       let $file := replace($model?doc, '_tp','')
       let $a := <a href="/exist/restxq/transform?file={$file}" target="topoTEI">topoTEI</a>
        return $a  
    ) else (
        pages:parse-params($node, $model)
    )
};

declare function pages:adapt-settings($node as node(), $model as map(*)) {
    if ($model?template) then (
        <div class="settings">
            <h3>
                <pb-i18n key="document.settings">Settings</pb-i18n>
            </h3>
          {
            if ($model?template = 'surface.html') then (
                <pb-toggle-feature emit="transcription" subscribe="transcription"  name="choice" on="on" off="off" default="on"> 
                    <pb-i18n key="myapp.choice-underline">... Korrekturen ...</pb-i18n>
                </pb-toggle-feature>,
                <pb-toggle-feature emit="transcription" subscribe="transcription"  name="del" on="on" off="off" default="on"> 
                    <pb-i18n key="myapp.deletion-popover">... Streichungen ...</pb-i18n>
                </pb-toggle-feature>
        
            ) else (
                <pb-toggle-feature emit="transcription" subscribe="transcription" name="edRef" selector=".edRefLB">
                    <pb-i18n key="myapp.edref-lb">... KGW KSA Zeilenumbruch ...</pb-i18n>
                </pb-toggle-feature>
            )
            
            }
            <pb-edit-xml src="document1">
                <paper-button alt="Edit source">
                    <iron-icon icon="icons:code"/> <pb-i18n key="menu.download.view-tei"/>
                </paper-button>
            </pb-edit-xml>
        </div>
    ) else ($node)
    
};

declare function pages:pb-document($node as node(), $model as map(*), $odd as xs:string?) {
    let $oddParam := ($node/@odd, $model?odd, $odd)[1]
    let $data := config:get-document($model?doc)
    let $config := tpu:parse-pi(root($data), $model?view, $oddParam)
    return  <pb-document path="{$model?doc}" root-path="{$config:data-root}" view="{$config?view}" odd="{replace($config?odd, '^(.*)\.odd', '$1')}"
                source-view="{$pages:EXIDE}">
                { $node/@id }
            </pb-document>
       
};

(:~
 : Generate the actual script tag to import pb-components.
 :)
declare function pages:load-components($node as node(), $model as map(*)) {
    if (not($node/preceding::script[@data-template="pages:load-components"])) then (
        <script defer="defer" src="https://cdn.jsdelivr.net/npm/@webcomponents/webcomponentsjs@2.7.0/webcomponents-loader.js"></script>,
        <script defer="defer" src="https://cdn.jsdelivr.net/npm/web-animations-js/web-animations.min.js"></script>
    ) else
        (),
    switch ($config:webcomponents)
        case "local" return
            <script type="module" src="resources/scripts/{$node/@src}"></script>
        case "dev" return
            <script type="module" 
                src="{$config:webcomponents-cdn}/src/{$node/@src}"></script>
        default return
            <script type="module"
                src="{$config:webcomponents-cdn}@{$config:webcomponents}/dist/{$node/@src}"></script>
};

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    for $data in config:get-document($doc)
    return
        if (exists($data)) then
            pages:load-xml($data, $view, $root, $doc)
        else
            ()
};

declare function pages:load-xml($data as node()*, $view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $config :=
        (: parse processing instructions and remember original context :)
        map:merge((tpu:parse-pi(root($data[1]), $view), map { "context": $data }))
    return
        map {
            "config": $config,
            "data":
                switch ($config?view)
            	    case "div" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return
                                nav:get-section-for-node($config, $node)
                        else
                            nav:get-section($config, $data)
                    case "page" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            nav:get-first-page-start($config, $data)
                    case "single" return
                        $data
                    case "surface" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return $node
                        else
                            let $node := nav:get-first-surface-start($config, $data)
                            
                            return $node
                    default return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data/tei:TEI/tei:text
        }
};

declare function pages:edit-odd-link($node as node(), $model as map(*)) {
    <pb-download url="{$model?app}/odd-editor.html" source="source"
        params="root={$config:odd-root}&amp;output-root={$config:output-root}&amp;output={$config:output}">
        {$node/@*, $node/node()}
    </pb-download>
};

(:~
 : Only used for generated app: output edit link for every registered ODD
 :)
declare function pages:edit-odd-list($node as node(), $model as map(*)) {
    for $odd in ($config:odd-available, $config:odd-internal)
    return
        <paper-item>
            <a href="{$model?app}/odd-editor.html?root={$config:odd-root}&amp;output-root={$config:output-root}&amp;output={$config:output}&amp;odd={$odd}"
                target="_blank">
                <pb-i18n key="menu.admin.edit-odd">Edit ODD</pb-i18n>: {$odd}
            </a>
        </paper-item>
};

declare function pages:process-content($xml as node()*, $root as node()*, $config as map(*)) {
    pages:process-content($xml, $root, $config, ())
};

declare function pages:process-content($xml as node()*, $root as node()*, $config as map(*), $userParams as map(*)?) {
    let $params := map:merge((
            map {
                "root": $root,
                "view": $config?view
            },
            $userParams))

	let $html := $pm-config:web-transform($xml, $params, $config?odd)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    let $body := pages:clean-footnotes($html)
    let $footnotes := 
        for $fn in $html//*[@class = "footnote"]
        return
            element { node-name($fn) } {
                $fn/@*,
                pages:clean-footnotes($fn/node())
            }
    return
        <div class="{$config:css-content-class} {$class}">
        {
            $body,
            if ($footnotes) then
                nav:output-footnotes($footnotes)
            else
                ()
            ,
            $html//paper-tooltip
        }
        </div>
};

declare function pages:clean-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(paper-tooltip) return
		        ()
            case element() return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        pages:clean-footnotes($node/node())
                    }
            default return
                $node
};

declare function pages:toc-ms-contents($node, $model as map(*), $target as xs:string?,
    $icons as xs:boolean?) {
    <ul>
        {
            for $locus in $node//tei:sourceDesc//tei:msContents//tei:locus
                where contains($node//tei:text//tei:pb/@xml:id, $locus/text())
                let $id := $locus/text()
                let $desc := $locus/following-sibling::tei:desc/text()
                let $root := $node//tei:sourceDoc/tei:surface[@start = concat('#', $id)]
                let $nodeId := util:node-id($root)
                let $xmlId := $root/@xml:id
                return <li><pb-link  node-id="{$nodeId}" emit="{$target}" subscribe="{$target}">{$locus}: {$desc}</pb-link></li>
            }
    </ul>
};

declare function pages:toc-timeline($node, $model as map(*), $target as xs:string?, $icons as xs:boolean?) {
    <ul>
        {
        for $map in local:yearMaps($node//tei:teiHeader/tei:profileDesc/tei:creation/tei:listChange/tei:change, 1)
            return 
        <li>
            <pb-collapse>
                <span slot="collapse-trigger">
                    <pb-link emit="{$target}" subscribe="{$target}" xml-id="{concat('year-', $map?year)}">{$map?year}</pb-link>
                </span>
                <span slot="collapse-content">
                    <ul>
                    {
                    for $month in $map?months
                        let $monthKey := concat('myapp.months.', $month?month)
                        return <li><pb-collapse>
                                    <span slot="collapse-trigger">
                                        <pb-link emit="{$target}" subscribe="{$target}" xml-id="{concat($map?year,'-', $month?month)}">
                                            <pb-i18n key="{$monthKey}">{ $month?month }</pb-i18n>
                                        </pb-link>
                                    </span>
                                    <span slot="collapse-content">
                                        <ul>
                                            {   for $key in $month?keys
                                                    let $date := $node//tei:change[@xml:id = $key]//tei:date/text()
                                                    return <li><pb-link emit="{$target}" subscribe="{$target}" xml-id="{$key}">{$date}</pb-link></li>
                                                
                                            }
                                        </ul>
                                    </span>
                                </pb-collapse>
                            </li>
                    }
                    </ul>
                </span>
            </pb-collapse>
        </li>
        }
    </ul>
};


declare function pages:toc-div($node, $model as map(*), $target as xs:string?,
    $icons as xs:boolean?) {
    let $view := $model?config?view
    let $divs := nav:get-subsections($model?config, $node)
   
    return
        <ul>
        {
            for $div in $divs
            let $headings := nav:get-section-heading($model?config, $div)/node()
            let $html :=
                if ($headings/*) then
                    $pm-config:web-transform($headings, map { "mode": "toc", "root": $div }, $model?config?odd)
                else
                    $headings/string()
            let $root := (
                if ($view = "page") then
                    ($div/*[1][self::tei:pb], $div/preceding::tei:pb[1])[1]
                else
                    (),
                $div
            )[1]
            let $parent := if ($view = 'page') then () else nav:is-filler($model?config, $div)
            let $hasDivs := exists(nav:get-subsections($model?config, $div))
            let $nodeId :=  if ($parent) then util:node-id($parent) else util:node-id($root)
            let $xmlId := if ($parent) then $parent/@xml:id else $root/@xml:id
            let $subsect := if ($parent) then attribute hash { util:node-id($root) } else ()
            return
                    <li>
                    {
                        if ($hasDivs) then
                            <pb-collapse>
                                {
                                    if (not($icons)) then
                                        attribute no-icons { "no-icons" }
                                    else
                                        ()
                                }
                                <span slot="collapse-trigger">
                                {
                                    if ($xmlId) then
                                        <pb-link xml-id="{$xmlId}" node-id="{$nodeId}" emit="{$target}" subscribe="{$target}">{$subsect, $html}</pb-link>
                                    else
                                        <pb-link node-id="{$nodeId}" emit="{$target}" subscribe="{$target}">{$subsect, $html}</pb-link>
                                }
                                </span>
                                <span slot="collapse-content">
                                { pages:toc-div($div, $model, $target, $icons) }
                                </span>
                            </pb-collapse>
                        else if ($xmlId) then
                            <pb-link xml-id="{$xmlId}" node-id="{$nodeId}" emit="{$target}" subscribe="{$target}">{$subsect, $html}</pb-link>
                        else
                            <pb-link node-id="{$nodeId}" emit="{$target}" subscribe="{$target}">{$subsect, $html}</pb-link>
                    }
                    </li>
        }
        </ul>
};

declare function pages:get-content($config as map(*), $div as element()) {
    nav:get-content($config, $div)
};

declare function pages:if-supported($node as node(), $model as map(*), $media as xs:string?) {
    if ($media and exists($model?media)) then
        if ($media = $model?media) then
            element { node-name($node) } {
                $node/@*,
                templates:process($node/node(), $model)
            }
        else
            ()
    else
        element { node-name($node) } {
            $node/@*,
            templates:process($node/node(), $model)
        }
};

declare function pages:pb-page($node as node(), $model as map(*)) {
    let $docPath := 
        if (matches($model?doc, "^.*/[^/]*$")) then
            replace($model?doc, "^(.*)/[^/]*$", "$1")
        else
            ""
    let $model := map:merge(
        (
            $model,
            map { 
                "app": $config:context-path,
                "collection": $docPath
            }
        )
    )
    return
        element { node-name($node) } {
            $node/@*,
            attribute app-root { $config:context-path },
            attribute template { $model?template },
            attribute endpoint { $config:context-path },
            templates:process($node/*, $model)
        }
};

declare function pages:determine-view($view as xs:string?, $node as node()) {
    typeswitch ($node)
        case element(tei:body) return
            "body"
        case element(tei:front) return
            "body"
        case element(tei:back) return
            "body"
        default return
            if ($view) then $view else $config:default-view
};

declare function pages:switch-view($node as node(), $model as map(*), $root as xs:string?, $doc as xs:string, $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $targetView := if ($view = "page") then "div" else "page"
    let $root := pages:switch-view-id($model?data, $view)
    return
        element { node-name($node) } {
            $node/@* except $node/@class,
            if (pages:has-pages($model?data)) then (
                attribute href {
                    "?root=" ||
                    (if (empty($root) or $root instance of element(tei:body) or $root instance of element(tei:front)) then () else util:node-id($root)) ||
                    "&amp;odd=" || $model?config?odd || "&amp;view=" || $targetView
                },
                if ($view = "page") then (
                    attribute aria-pressed { "true" },
                    attribute class { $node/@class || " active" }
                ) else
                    $node/@class
            ) else (
                $node/@class,
                attribute disabled { "disabled" }
            ),
            templates:process($node/node(), $model)
        }
};

declare function pages:has-pages($data as element()+) {
    exists(root($data)//tei:pb)
};

declare function pages:switch-view-id($data as element()+, $view as xs:string) {
    let $root :=
        if ($view = "div") then
            ($data/*[1][self::tei:pb], $data/preceding::tei:pb[1])[1]
        else
            ($data/ancestor::tei:div, $data/following::tei:div, $data/ancestor::tei:body, $data/ancestor::tei:front)[1]
    return
        $root
};

declare 
    %templates:wrap
function pages:languages($node as node(), $model as map(*)) {
    let $json := json-doc($config:app-root || "/resources/i18n/languages.json")
    return
        map:for-each($json, function($key, $value) {
            <paper-item value="{$key}">{$value}</paper-item>
        })
};

declare 
    %templates:wrap
function pages:version($node as node(), $model as map(*)) {
    $config:expath-descriptor/@version/string()
};

declare 
    %templates:wrap
function pages:api-version($node as node(), $model as map(*)) {
    let $json := json-doc($config:app-root || "/modules/lib/api.json")
    return
        $json?info?version
};

declare
    %templates:default("odd", "teipublisher.odd")
function pages:odd-editor($node as node(), $model as map(*), $odd as xs:string, $root as xs:string?, $output-root as xs:string?,
$output-prefix as xs:string?) {
    let $root := ($root, $config:odd-root)[1]
    return
        <pb-odd-editor output-root="{($output-root, $config:app-root || "/transform")[1]}"
            root-path="{$root}"
            output-prefix="{($output-prefix, "transform")[1]}"
            odd="{$odd}">
        {
            $node/@*,
            templates:process($node/node(), $model)
        }
        </pb-odd-editor>
};