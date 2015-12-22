#!/bin/bash
# 
# NAME
#
# RESTful Validator - Mass validate XML offered over http on the command line
#
# SYNOPSIS
#
# validate.sh [ options ] -S [ schema URI ]
#
# DESCRIPTION
# 
# Shellscript for validating XML collections offered over RESTful APIs on the command line.
# Utilizes jing (http://www.thaiopensource.com/relaxng/jing.html) for validation and optionally
# xqilla (http://xqilla.sourceforge.net/HomePage) for retrival of resources with XQueries.
# Retrival of resources via curl is also possible but less flexible in comparison with xqilla.
#
# PREREQUISITES
#
# You will need java for running jing and either xqilla or curl for extracting
# resources (URIs) from the collection to be validated.
#
# OPTIONS
#
# -C [ collection URI ] (optional, only for curl use)
#
# URI to a XML based collection of resources offered over http. Optional parameter that
# is only neccessary if URIs to resources should be retrieved with curl and not by an xquery. 
# The collection should specify the URIs of it's resources either in an attribute or within nodes.
# The extraction can then be done by using the -E parameter (see below). Example collection:
#
# <collection>
#    <resource href="http://uri/of/resource/1" />
#    <resource href="http://uri/of/resource/2" />
#    <resource href="http://uri/of/resource/3" />
# </collection>
#
# -S [ schema URI ] (required)
#
# URI to the XML Schema or RelaxNG Schema against which the resources of the collection should be validated.
#
# -E [ HTML attribute ] (optional, only for curl use)
#
# Name of the HTML attribute out of which the URI of a resource should be extracted. Only neccessary if
# using -C and curl for resource retrival. For the example collection above, -E should be set to "href"
#
# -B [ before string ] (optional, only for curl use)
#
# In scenarios where the HTML attribute does not contain the full URI to the resource, this parameter can be
# used to prepend a string (a URI part) to the URI value extracted by -E
#
# -A [ after string ] (optional, only for curl use)
#
# For scenarios where further parameters need to be appended to the URI value extracted by -E, this can be achieved 
# by appending a string using -A 
#
# -X [ XQuery file ] (optional, only for xqilla use)
#
# Name of a file with a XQuery that produces a set of URIs to validate. The XQuery is run with xqilla. It MUST return
# a set of URIs in plaintext. An example XQuery for doing this:
# 
# xquery version "1.0";
# let $collection := fn:doc("###MY_URI###")
# for $id in $collection//id
# return
# concat("###MY_URI###", $id, "###ARGUMENTS_ETC###")
#
# This XQuery can be run like this: validate.sh -X myquery.xq
#
# CREDITS 
# Torsten Schrade <Torsten.Schrade@adwmainz.de>
# Licence: MIT

Version=0.0.3

# test existence of java for jing
command -v java >/dev/null 2>&1 || { echo >&2 "java is required but seems not to be installed. Aborting."; exit 1; }

# get arguments
counter="0"
while getopts "C:S:E:B:A:X:" OPTIONS;
do
    case ${OPTIONS} in
        C) COLLECTION=${OPTARG}
            ((counter+=1))
            ;;
        S) SCHEMA=${OPTARG}
            ((counter+=1))
            ;;
        E) EXTRACT=${OPTARG}
            ((counter+=1))
            ;;
        B) BEFORE=${OPTARG}
            ((counter+=1))
            ;;
        A) AFTER=${OPTARG}
            ((counter+=1))
            ;;
        X) XQUERY=${OPTARG}
            ((counter+=1))
            ;;
    esac
done

# no $SCEMA, no validation
if [ -z "${SCHEMA}" ]; then
    echo "Schema (-S) must be specified for validation"
    exit 1
fi

# fetch resources
if ([ ! -z "${XQUERY}" ]); then
    # test if xqilla is available
    command -v xqilla >/dev/null 2>&1 || { echo >&2 "xqilla is required for running xqueries but seems not to be installed. Aborting."; exit 1; }

    # run xquery
    resources=`xqilla "$XQUERY"`
elif ([ ! -z "$COLLECTION" ] &&  [ ! -z "$EXTRACT" ]); then
    # test if curl is available
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but seems not to be installed. Aborting."; exit 1; }

    # @see: http://blog.viktorkelemen.com/2011/07/get-links-from-page-with-bash.html
    # @see: http://stackoverflow.com/questions/8737638/assign-curl-output-to-variable-in-bash
    resources=`curl "$COLLECTION" 2>&1 | grep -o -E "$EXTRACT"='"([^"#]+)"' | cut -d'"' -f2`
else
    echo "Problem with xqilla or curl. Aborting."
    exit 1
fi

# start validation if resources could be fetched
if [ -z "$resources" ]; then
    echo "Resources could not be retrieved from collection"
    exit 1
else
    # @see: http://stackoverflow.com/questions/10586153/bash-split-string-into-array
    ifs=', ' read -a array <<< "$resources"
    oldifs="$ifs"
    ifs='
    '
    ifs=${ifs:0:1} # this is useful to format your code with tabs
    lines=( $resources )
    ifs="$oldifs"

    for line in "${lines[@]:0}"
        do
#           echo "$line"
            validation="java -jar bin/jing.jar $SCHEMA $BEFORE$line$AFTER"
            result=`eval $validation`
            if [ -z "$result" ]; then
                echo 'VALID:' $BEFORE$line$AFTER
            else
                echo 'INVALID:' $validation
            fi
        done
    exit 0
fi