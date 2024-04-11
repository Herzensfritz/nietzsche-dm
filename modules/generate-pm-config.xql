xquery version "3.1";

module namespace g="http://www.tei-c.org/tei-simple/generate";

import module namespace pmc="http://www.tei-c.org/tei-simple/xquery/config";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

(:  let $pmuConfig := pmc:generate-pm-config(($config:odd-available, $config:odd-internal), $config:default-odd, $config:odd-root)
let $log := console:log('hello')
return
    xmldb:store($config:app-root || "/modules", "pm-config.xql", $pmuConfig, "application/xquery") :)

declare function g:createPmConfig() {
    let $pmuConfig := pmc:generate-pm-config(($config:odd-available, $config:odd-internal), $config:default-odd, $config:odd-root)
    let $log := console:log($pmuConfig)
    return
        xmldb:store($config:app-root || "/modules", "pm-config.xql", $pmuConfig, "application/xquery")
};

