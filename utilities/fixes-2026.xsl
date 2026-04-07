<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 27, 2026</xd:p>
            <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
            <xd:p>Stylesheet for updating and standardizing the encoding of all documents.
            This is meant to be run as a single, identity transformation (rather than 
            via a collection).</xd:p>
        </xd:desc>
        <xd:param name="schemaURI">URI for the schema</xd:param>
    </xd:doc>
    <xsl:param name="schemaURI" as="xs:string">https://raw.githubusercontent.com/Digital-Dostoevsky/dostoevschema/refs/heads/main/dostoevschema.rng</xsl:param>
    
    <xd:doc>
        <xd:desc>The identity transformation</xd:desc>
    </xd:doc>
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>Add formatting, but exclude most of the text itself</xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes" suppress-indentation="text body said"/>

    <xd:doc>
        <xd:desc>Remove the schema processing instructions</xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('xml-model')"/>
    
    <xd:doc>
        <xd:desc>Adjust the root TEI and include new validation
        instructions</xd:desc>
    </xd:doc>
    <xsl:template match="TEI" expand-text="yes">
        <!--First, the RNG schema-->
        <xsl:processing-instruction name="xml-model">href="{$schemaURI}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <!--And now point to the same schema, but use the embedded schematron-->
        <xsl:processing-instruction name="xml-model">href="{$schemaURI}" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
        <xsl:copy>
            <!--We should add an @xml:lang, if not present already-->
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Update text, but mostly move the back matter
        into a standOff.</xd:desc>
    </xd:doc>
    <xsl:template match="text">
        <xsl:copy>
            <!--We should add an @xml:lang here too-->
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
        <xsl:where-populated>
            <standOff>
                <xsl:apply-templates select="back/div[@type='editorial']/node()"/>
            </standOff>
        </xsl:where-populated>
    </xsl:template>

    <xd:doc>
        <xd:desc>Remove numbered divs</xd:desc>
    </xd:doc>
    <xsl:template match="div1 | div2 | div3 | div4 | div5 | div6">
        <div>
            <xsl:apply-templates select="@*|node()"/>
        </div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Delete the back element, since we move its content
        to standOff</xd:desc>
    </xd:doc>
    <xsl:template match="text/back"/>
    
    
    
</xsl:stylesheet>