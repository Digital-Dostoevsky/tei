<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:dost="https://digitaldostoevsky.com"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/1999/xhtml"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Started on:</xd:b> Apr 29, 2026</xd:p>
            <xd:p><xd:b>Author:</xd:b> Joey Takeda and Braxton Boyer</xd:p>
            <xd:p>Diagnostics tests and checks for the Digital Dostoevsky project.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="outputDir" select="'.'"/>
    
    
    <xd:doc>
        <xd:desc>The entire XML document collection</xd:desc>
    </xd:doc>
    <xsl:variable name="texts"
        as="document-node()+" 
        select="collection('../texts?select=*.xml;recurse=yes')"/>
    
    
    <!--Broken pointers (broadly = internal links that don't work)-->
    <!--Wrong pointers (internal links that DO work but point to the wrong thing)-->
    
    <xsl:template name="go">
        <xsl:result-document href="{$outputDir}/diagnostics.html" method="xhtml">
            <xsl:message>Creating <xsl:value-of select="current-output-uri()"/></xsl:message>
            <html>
                <head>
                    <title>Digital Dostoevsky: Diagnostics</title>
                </head>
                <body>
                    <h1>Digital Dostoevsky: Diagnostics</h1>
                    <main>
                        <section>
                            <h2>Diagnostic Checks</h2>
                            <xsl:call-template name="checkBrokenPointers"/>
                        </section>
                    </main>
                    <hr/>
                    <footer>
                        <p>Last built: 
                            <xsl:value-of select="format-dateTime(current-dateTime(), '[MNn] [D01], [Y0001] @ [H01]:[m01]')"/> </p>
                    </footer>
                </body>
            </html>
            
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="checkBrokenPointers">
        <xsl:message>Checking for broken pointers...</xsl:message>
        <section>
            <h3>Broken Pointers</h3>
            <xsl:for-each select="$texts">
                <xsl:variable name="currText" select="." as="document-node()"/>
                <xsl:variable name="docId" select="//TEI/@xml:id" as="xs:string"/>
                <xsl:message select="'Processing ' || $docId"/>
                <xsl:variable name="allIds" select="//@xml:id" as="xs:string+"/>
                <xsl:variable name="allPointingAtts"
                    select="//@*[starts-with(.,'#')]" as="attribute()+"/>
                <section>
                    <h4><xsl:value-of select="$docId"/></h4>
                    <table>
                        <thead>
                            <tr>
                                <th>Error</th>
                                <th>Location</th>
                                <th>Element Name</th>
                                <th>Attribute</th>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each select="$allPointingAtts">
                                <xsl:variable name="currAtt" select="." as="attribute()"/>
                                <xsl:variable name="currParent" select="$currAtt/parent::*" as="element()"/>
                                <xsl:for-each select="tokenize($currAtt)">
                                    <xsl:variable name="currPtr" select="." as="xs:string"/>
                                    <xsl:variable name="targetId" 
                                        select="substring-after($currPtr, '#')"
                                        as="xs:string"/>
                                    <xsl:variable name="isDefined" select="$allIds[. = $targetId]" as="xs:string?"/>
                                    <xsl:if test="empty($isDefined)">
                                        <tr>
                                            <td><xsl:value-of select="$targetId"/></td>
                                            <td><xsl:value-of 
                                                    select="
                                                    $currParent/ancestor::*[matches(local-name(),'^div\d+')]/@n
                                                    => string-join('.')"/></td>
                                            <td><xsl:value-of select="$currParent/local-name()"/></td>
                                            <td><xsl:value-of select="$currAtt/local-name()"/></td>
                                        </tr>
                                    </xsl:if> 
                                </xsl:for-each>
                            </xsl:for-each>
                        </tbody>
                        
                    </table>
                </section>
            </xsl:for-each>
        </section>
        
        <!-- <xsl:message>COULD NOT FIND <xsl:value-of select="$targetId"/> (Found on element <xsl:value-of select="$currAtt/parent::*/local-name()"/> and attribute <xsl:value-of select="$currAtt/local-name()"/>)</xsl:message>-->
            
            
<!--        <xsl:variable name="allTargets" select="($allPointingAtts/tokenize(.))[starts-with(.,'#')]" as="xs:string+"/>
            <xsl:variable name="allReferencedIds" 
                select="$allTargets ! substring-after(.,'#')" as="xs:string+"/>
            <xsl:variable name="distinctPointers" select="distinct-values($allReferencedIds)"/>
            <xsl:variable name="errors" select="$distinctPointers[not(. = $allIds)]"/>
            <xsl:message select="count($errors)"/>-->
           <!-- <xsl:message><xsl:value-of select="$docId"/> HAS <xsl:value-of select="count($allPointingAtts)"/> POINTING ATTS (<xsl:value-of select="count($allTargets)"/>)</xsl:message>-->
    
            <!--For each pointer, 
                1. Remove the initial hash
                2. Check to see if it is in $allIds
                3. If it is, then do nothing
                4. If it isn't, then write out the bad pointer -->
                <!--check to see if the substring
                after the # matches an ID in the document-->
           
    </xsl:template>
    
    <xsl:template name="checkIncorrectPointers">
        
    </xsl:template>
    
<!--    
    <xsl:template name="foo">
        <xsl:message>Bar</xsl:message>
    </xsl:template>
    
    <xsl:template name="baz">
        <xsl:message>duck</xsl:message>
    </xsl:template>
    
    <xsl:function name="dost:double" as="xs:integer">
        <xsl:param name="startingNumber" as="xs:integer"/>
        <xsl:variable name="result" select="$startingNumber * 2"/>
        <xsl:sequence select="$result"/>
    </xsl:function>-->
    
</xsl:stylesheet>