# RESTful XML Validator

Mass validate XML offered over HTTP on the command line

### SYNOPSIS

**validate.sh \[ options \] -S \[ schema URI \]**

### DESCRIPTION

Shellscript for validating XML collections offered over RESTful APIs on the command line.
Utilizes jing [Jing](http://www.thaiopensource.com/relaxng/jing.html) for validation and optionally
[xqilla](http://xqilla.sourceforge.net/HomePage) for retrival of resources with XQueries.
Retrival of resources via curl is also possible but less flexible in comparison with xqilla.

### PREREQUISITES

You will need java for running jing and either xqilla or curl for extracting resources (URIs) 
from the collection to be validated. Download jing from [(http://www.thaiopensource.com/relaxng/jing.html](http://www.thaiopensource.com/relaxng/jing.html)
and put this script in the root folder above the bin/ directory.

### OPTIONS

**-C \[ collection URI \] (optional, only for curl use)**

URI to a XML based collection of resources offered over http. Optional parameter that
is only neccessary if URIs to resources should be retrieved with curl and not by an xquery. 
The collection should specify the URIs of it's resources either in an attribute or within nodes.
The extraction can then be done by using the -E parameter (see below). Example collection:

<pre><code>&lt;collection&gt;
    &lt;resource href="http://uri/of/resource/1" /&gt;
    &lt;resource href="http://uri/of/resource/2" /&gt;
    &lt;resource href="http://uri/of/resource/3" /&gt;
&lt;/collection&gt;
</code></pre>

**-S \[ schema URI \] (required)**

URI to the XML Schema or RelaxNG Schema against which the resources of the collection should be validated.

**-E \[ HTML attribute \] (optional, only for curl use)**

Name of the HTML attribute out of which the URI of a resource should be extracted. Only neccessary if
using -C and curl for resource retrival. For the example collection above, -E should be set to "href"

**-B \[ before string \] (optional, only for curl use)**

In scenarios where the HTML attribute does not contain the full URI to the resource, this parameter can be
used to prepend a string (a URI part) to the URI value extracted by -E

**-A \[ after string \] (optional, only for curl use)**

For scenarios where further parameters need to be appended to the URI value extracted by -E, this can be achieved 
by appending a string using -A 

**-X \[ XQuery file \] (optional, only for xqilla use)**

Name of a file with a XQuery that produces a set of URIs to validate. The XQuery is run with xqilla. It MUST return
a set of URIs in plaintext. An example XQuery for doing this:

<pre><code>xquery version "1.0";
let $collection := fn:doc("###MY_URI###")
for $id in $collection//id
return
concat("###MY_URI###", $id, "###ARGUMENTS_ETC###")
</code></pre>

This XQuery can be run like this: validate.sh -X myquery.xq

## Credits

Released under MIT license.

Author: <a href="http://www.adwmainz.de/mitarbeiter/profil/torsten-schrade.html">Torsten Schrade</a> (<a href="https://github.com/metacontext">@metacontext</a>)