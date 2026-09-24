<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:dd="https://github.com/Digital-Dostoevsky"
    version="3.0">
    
    <!-- This stylesheet extracts every instance of a specified character being 
     mentioned by name within another character's speech (i.e. inside a `<said>` 
     element), for a single specified novel. Both the target character and the 
     novel are passed in as parameters, so this can be rerun for any 
     character/novel combination without modifying the code.
     
     To change which character and/or which novel you want data for, do the following:
     
     1. Write the xml:id of your desired character (do not include the hash) within the single
     quotation marks in `<xsl:param name ="targetId" select="''"/>`. For example: 
     `<xsl:param name="targetId" select="'afk'"/>
     
     2. Write the xml:id of your desired novel within the single quotation marks in
     `<xsl:param name="novelId" select="''"/>`. For example:
     `<xsl:param name="novelId" select="'bratia_karamazovy'"/>`
     
     Reminder that xml:ids of the novels can be found towards the very top of each
     novel's encoding, within the `<TEI>` element. Or, more easily, the xml:id is also
     just the name of the xml file (but excluding the .xml): "bratia_karamazovy.xml"
     
     The stylesheet will create a tsv with the following information (as column headers):
     location, who, whoName, toWhom, toWhomName, text
     
     The tsv will be put in the `_public` folder for its respective novel and will be named
     for the character being mentioned. An example file (with the filepath) would be:
     `tei/_public/bratia_karamazovy/bratia_karamazovy_mentions_afk.tsv`
-->
    
    <!-- Specifies the output format as text--> 
    <xsl:output method="text" />
    
    <!-- Global variables -->
    <xsl:variable name="TAB" select="codepoints-to-string(9)"/>
    <xsl:variable name="NEWLINE" select="codepoints-to-string(10)"/>
    <xsl:param name="outputDir" select="'.'"/>
    <xsl:param name="targetId" select="'afk'"/>
    <xsl:param name="novelId" select="'bratia_karamazovy'"/>
    
    <xd:doc>
        <xd:desc>For a single specified novel, finds every `said` element that 
            mentions the character identified by $targetId (via a `persName` 
            reference somewhere in its content), and writes the speaker, 
            addressee, and raw text to a tsv.</xd:desc>
    </xd:doc>
    <xsl:template name="characterMentions">
        <xsl:if test="$targetId = ''">
            <xsl:message terminate="yes">ERROR: You must supply a targetId parameter, e.g. targetId=abc</xsl:message>
        </xsl:if>
        <xsl:if test="$novelId = ''">
            <xsl:message terminate="yes">ERROR: You must supply a novelId parameter, e.g. novelId=besy</xsl:message>
        </xsl:if>
        
        <xsl:variable name="novel" select="doc('../../texts/' || $novelId || '.xml')" as="document-node()"/>
        
        <xsl:for-each select="$novel">
            <xsl:variable name="docId" select="//TEI/@xml:id" as="xs:string"/>
            <xsl:message>Processing <xsl:value-of select="$docId"/></xsl:message>
            <xsl:variable name="people" select="(//person[@xml:id], //personGrp[@xml:id])"
                as="element()+"/>
            
            <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_mentions_{$targetId}.tsv" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                
                <xsl:variable name="headerValues" select="
                    'location', 'who', 'whoName', 'toWhom', 'toWhomName', 'text'"/>
                <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                
                <xsl:variable name="dataRows" as="xs:string*">
                    <!--Only said elements that contain a persName referring to the target character-->
                    <xsl:for-each select="//said[descendant::persName[@ref = '#' || $targetId]]">
                        <xsl:variable name="part" select="string(ancestor::div[@type='part']/@n)" as="xs:string"/>
                        <xsl:variable name="chapter" select="string(ancestor::div[@type='chapter']/@n)" as="xs:string"/>
                        <xsl:variable name="section" select="string(ancestor::div[@type='section']/@n)" as="xs:string"/>
                        <xsl:variable name="location" select="string-join(($part, $chapter, $section), '.')" as="xs:string"/>
                        
                        <xsl:variable name="whoTokens" select="
                            if (@who) then
                            tokenize(@who)
                            else
                            'unknown'" as="xs:string+"/>
                        <xsl:variable name="toWhomTokens" select="
                            if (@toWhom) then
                            tokenize(@toWhom)
                            else
                            'unknown'" as="xs:string+"/>
                        
                        <!-- And then get raw string content -->
                        <xsl:variable name="spContents" as="xs:string" select="
                            descendant::text()
                            => string-join()
                            => normalize-space()
                            "/>
                        
                        <xsl:for-each select="$whoTokens">
                            <xsl:variable name="currWhoPtr" select="." as="xs:string"/>
                            <xsl:variable name="whoName" select="
                                if ($currWhoPtr != 'unknown')
                                then
                                dd:getName($currWhoPtr, $people)
                                else
                                'unknown'" as="xs:string"/>
                            <xsl:for-each select="$toWhomTokens">
                                <xsl:variable name="currToWhomPtr" select="." as="xs:string"/>
                                <xsl:variable name="toWhomName" select="
                                    if ($currToWhomPtr != 'unknown')
                                    then
                                    dd:getName($currToWhomPtr, $people)
                                    else
                                    'unknown'" as="xs:string"/>
                                
                                <xsl:variable name="rowValues" as="xs:string+"
                                    select="($location, $currWhoPtr, $whoName, 
                                    $currToWhomPtr, $toWhomName, $spContents)"/>
                                <xsl:sequence select="string-join($rowValues, $TAB)"/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Function to retrieve the `persName` value from a person pointer.</xd:desc>
        <xd:param name="ptr">The ptr value (e.g. #rrr) for the person</xd:param>
        <xd:param name="people">The declared people (e.g. person OR personGrp) in this file.</xd:param>
        <xd:return>The character's name, preferring English.</xd:return>
    </xd:doc>
    <xsl:function name="dd:getName" as="xs:string">
        <xsl:param name="ptr" as="xs:string"/>
        <xsl:param name="people" as="element()+"/>
        <xsl:variable name="currId" 
            select="substring-after($ptr,'#')"
            as="xs:string"/>
        <xsl:variable name="person" 
            select="$people[@xml:id = $currId]" 
            as="element()?"/>
        <xsl:if test="empty($person)">
            <xsl:message>WARNING: Cannot find corresponding entity for <xsl:value-of select="$ptr"/></xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="count($person/persName[@xml:lang = 'en']) gt 1">
                <xsl:value-of select="string($person/persName[@xml:lang = 'en'][2])"/>
            </xsl:when>
            <xsl:when test="count($person/persName[@xml:lang = 'en']) eq 1">
                <xsl:value-of select="string($person/persName[@xml:lang = 'en'])"/>
            </xsl:when>
            <xsl:when test="$person/persName[@xml:lang = 'fr']">
                <xsl:value-of select="string($person/persName[@xml:lang = 'fr'][1])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="string($person/persName[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>