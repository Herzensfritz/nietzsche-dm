
xquery version "3.1";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-surface-web="http://www.tei-c.org/pm/models/surface/web/module" at "../transform/surface-web-module.xql";
import module namespace pm-surface-print="http://www.tei-c.org/pm/models/surface/print/module" at "../transform/surface-print-module.xql";
import module namespace pm-surface-latex="http://www.tei-c.org/pm/models/surface/latex/module" at "../transform/surface-latex-module.xql";
import module namespace pm-surface-epub="http://www.tei-c.org/pm/models/surface/epub/module" at "../transform/surface-epub-module.xql";
import module namespace pm-surface-fo="http://www.tei-c.org/pm/models/surface/fo/module" at "../transform/surface-fo-module.xql";
import module namespace pm-docx-tei="http://www.tei-c.org/pm/models/docx/tei/module" at "../transform/docx-tei-module.xql";
import module namespace pm-nietzsche-ed-web="http://www.tei-c.org/pm/models/nietzsche-ed/web/module" at "../transform/nietzsche-ed-web-module.xql";
import module namespace pm-nietzsche-ed-print="http://www.tei-c.org/pm/models/nietzsche-ed/print/module" at "../transform/nietzsche-ed-print-module.xql";
import module namespace pm-nietzsche-ed-latex="http://www.tei-c.org/pm/models/nietzsche-ed/latex/module" at "../transform/nietzsche-ed-latex-module.xql";
import module namespace pm-nietzsche-ed-epub="http://www.tei-c.org/pm/models/nietzsche-ed/epub/module" at "../transform/nietzsche-ed-epub-module.xql";
import module namespace pm-nietzsche-ed-fo="http://www.tei-c.org/pm/models/nietzsche-ed/fo/module" at "../transform/nietzsche-ed-fo-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "surface.odd" return pm-surface-web:transform($xml, $parameters)
    case "nietzsche-ed.odd" return pm-nietzsche-ed-web:transform($xml, $parameters)
    default return pm-surface-web:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:print-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "surface.odd" return pm-surface-print:transform($xml, $parameters)
case "nietzsche-ed.odd" return pm-nietzsche-ed-print:transform($xml, $parameters)
    default return pm-surface-print:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:latex-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "surface.odd" return pm-surface-latex:transform($xml, $parameters)
case "nietzsche-ed.odd" return pm-nietzsche-ed-latex:transform($xml, $parameters)
    default return pm-surface-latex:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:epub-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "surface.odd" return pm-surface-epub:transform($xml, $parameters)
case "nietzsche-ed.odd" return pm-nietzsche-ed-epub:transform($xml, $parameters)
    default return pm-surface-epub:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:fo-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "surface.odd" return pm-surface-fo:transform($xml, $parameters)
case "nietzsche-ed.odd" return pm-nietzsche-ed-fo:transform($xml, $parameters)
    default return pm-surface-fo:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:tei-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx.odd" return pm-docx-tei:transform($xml, $parameters)
    default return error(QName("http://www.tei-c.org/tei-simple/pm-config", "error"), "No default ODD found for output mode tei")
            
    
};
            
    