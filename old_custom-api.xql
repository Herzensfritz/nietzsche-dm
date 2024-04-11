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


declare function api:documentingGenesis($request as map(*)) {
    let $back := doc($config:data-root || "/GM_Anhang_140224.xml")
    let $log := console:log('yep')
    
    return map:entry(( 
        for $date in $back//tei:div2[tei:p/tei:seg/@change]/tei:head/tei:date/@when/string(.)
            return
                let $change := $back//tei:div2[tei:head/tei:date/@when = $date]//tei:head
                return map:entry($date, map {
                    "count": count($change),
                    "info": $change
                })
    ))
};

declare function local:FromTo($startDate as xs:date, $endDate as xs:date, $allDates) {
    if (functx:next-day($startDate) ne $endDate) then (
        local:FromTo(functx:next-day($startDate), $endDate, ($allDates, $startDate))    
    ) else ( 
        ($allDates, $endDate)    
    )
};
declare function local:updateDates($content, $dates, $date)  {
    let $newDates := if (map:contains($dates, $date)) then (
        let $oldEntry := map:get($dates, $date)
        return map:put($dates, $date, map {
                "count": $oldEntry["count"] + 1,
                "info": array:insert-before($oldEntry["info"], 1, $content)
            })
    ) else (
       map:put($dates, $date, map {
                "count": 1,
                "info": [ $content ]
            }) 
    )     
    return $newDates
};

declare function local:getTimeSpan($change as element(), $dates)  {
    let $startDateString := if($change//tei:date/@notBefore) then ($change//tei:date/@notBefore/string(.)) else (($change//tei:date/@from/string(.)))
    let $endDateString := if($change//tei:date/@notAfter) then ($change//tei:date/@notAfter/string(.)) else (($change//tei:date/@to/string(.)))
    let $startDate := functx:date(year-from-date($startDateString), month-from-date($startDateString), day-from-date($startDateString))
    let $endDate := functx:date(year-from-date($endDateString), month-from-date($endDateString), day-from-date($endDateString))
    return local:FromTo($startDate, $endDate, $dates)
};
declare function local:getAllDates($allDates, $dates as xs:date*)  {
      let $newDates := map:keys($allDates[1])
      return if (count(subsequence($allDates, 2)) eq 0) then (
            distinct-values(($dates, $newDates))   
        ) else (
            local:getAllDates(subsequence($allDates, 2), ($dates, $newDates))  
        )
              
    };
              
             
declare function local:getExistingDates($allDates, $date) as xs:string* {
    for $item in map:find($allDates, $date)
                        where exists($item)
                        return $item
   
};
declare function local:getChanges4Ids($doc as node(), $ids as xs:string*, $change as element()*) as element()* {
    let $changes := for $id in $ids
                            return $doc//tei:change[@xml:id = $id]
    return ($changes, $change)
};
declare function api:timeline($request as map(*)) {
    let $doc := doc($config:data-root || "/Druckmanuskript_D_20.xml")
    let $dates := ()
    let $allDatesMap := for $span in $doc//tei:profileDesc/tei:creation/tei:listChange/tei:change[descendant::tei:date[(@notAfter and @notBefore) or (@from and @to)]]
                        return map:merge(( for $date in local:getTimeSpan($span, $dates)
                                                return map:entry($date, string($span/@xml:id))
                        ))
  
    let $allDates := local:getAllDates($allDatesMap, $doc//tei:profileDesc/tei:creation/tei:listChange/tei:change//tei:date/@when/xs:date(.)) 
    let $log := console:log($allDates)
    return map:merge(( 
        for $date in $allDates
            let $existingDates := local:getExistingDates($allDatesMap, $date)
            let $change := $doc//tei:profileDesc/tei:creation/tei:listChange/tei:change[descendant::tei:date[@when = $date]]
            return
                if (count($existingDates) gt 0) then (
                   map:entry($date, map {
                       "count": if ($change) then (count($existingDates) + 1) else (count($existingDates)),
                       "info": local:getChanges4Ids($doc, $existingDates, $change)
                       })
                ) else (
                    map:entry($date, map {
                        "count": count($change),
                        "info": local:getChanges4Ids($doc, $existingDates, $change) 
                    })  
                )
    )) 
};