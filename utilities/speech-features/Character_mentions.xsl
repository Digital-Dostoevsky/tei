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
     
     The stylesheet will create .tsv files with the following information (as column headers):
     location, who, whoName, toWhom, toWhomName, text
     
     .tsv files will be created for the full novel as a whole, and for any/all of its parts.
     
     .tsv files will be put in the `_public` folder in the subdirectory `character_mentions`
     within the directory for their respective novels. They will be named for the character
     being mentioned. An example file (with the filepath) for a novel's first part would be:
     `tei/_public/bratia_karamazovy/character_mentions/bratia_karamazovy_1_mentions_afk.tsv`
     
     The stylesheet will also produce a simple .txt file with a count of all mentions of the specified
     character within instances of `<said>` for the whole novel and for each part. It will
     also be placed in the `_public` folder along with the .tsv files.
     
     NOTE: Because of the way the `build.xml` file is structured, any time you run it as a whole
     (i.e. target `all`) it will delete any previous character mention files. This is not necessarily
     a problem, though, since it is trivial to just re-run the process again for whatever
     character you need.
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
            addressee, and raw text to a TSV covering the whole novel, plus 
            one additional TSV per part if the novel has more than one part.</xd:desc>
    </xd:doc>
    <xsl:template name="characterMentions">
        <xsl:if test="$targetId = ''">
            <xsl:message terminate="yes">ERROR: You must supply a targetId parameter, e.g. targetId=abc</xsl:message>
        </xsl:if>
        <xsl:if test="$novelId = ''">
            <xsl:message terminate="yes">ERROR: You must supply a novelId parameter, e.g. novelId=besy</xsl:message>
        </xsl:if>
        
        <xsl:variable name="novel" select="doc('../../texts/' || $novelId || '/' || $novelId || '.xml')" as="document-node()"/>
        
        <xsl:for-each select="$novel">
            <xsl:variable name="docId" select="//TEI/@xml:id" as="xs:string"/>
            <xsl:message>Processing <xsl:value-of select="$docId"/></xsl:message>
            <xsl:variable name="people" select="(//person[@xml:id], //personGrp[@xml:id])"
                as="element()+"/>
            
            <!--Build all mention rows once, as maps, so we can reuse them 
                for both the all-novel file and the per-part files-->
            <xsl:variable name="mentionData" as="map(*)*">
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
                            
                            <xsl:map>
                                <xsl:map-entry key="'Part'" select="$part"/>
                                <xsl:map-entry key="'location'" select="$location"/>
                                <xsl:map-entry key="'who'" select="$currWhoPtr"/>
                                <xsl:map-entry key="'whoName'" select="$whoName"/>
                                <xsl:map-entry key="'toWhom'" select="$currToWhomPtr"/>
                                <xsl:map-entry key="'toWhomName'" select="$toWhomName"/>
                                <xsl:map-entry key="'text'" select="$spContents"/>
                            </xsl:map>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="headerValues" select="
                'location', 'who', 'whoName', 'toWhom', 'toWhomName', 'text'"/>
            <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
            
            <!--Whole-novel file-->
            <xsl:result-document href="{$outputDir}/{$docId}/character_mentions/{$docId}_full_novel_mentions_{$targetId}.tsv" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                <xsl:variable name="dataRows" as="xs:string*">
                    <xsl:for-each select="$mentionData">
                        <xsl:variable name="dataToUse" 
                            select=".?location, .?who, .?whoName, .?toWhom, .?toWhomName, .?text" as="xs:string+"/>
                        <xsl:sequence select="string-join($dataToUse, $TAB)"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>
            
            <!--Per-part files, only if the novel actually has more than one part-->
            <xsl:if test="count(//div[@type='part']) gt 1">
                <xsl:for-each-group select="$mentionData" group-by=".?Part">
                    <xsl:result-document href="{$outputDir}/{$docId}/character_mentions/{$docId}_{current-grouping-key()}_mentions_{$targetId}.tsv" method="text">
                        <xsl:message select="'Creating ' || current-output-uri()"/>
                        <xsl:variable name="dataRows" as="xs:string*">
                            <xsl:for-each select="current-group()">
                                <xsl:variable name="dataToUse" 
                                    select=".?location, .?who, .?whoName, .?toWhom, .?toWhomName, .?text" as="xs:string+"/>
                                <xsl:sequence select="string-join($dataToUse, $TAB)"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
                    </xsl:result-document>
                </xsl:for-each-group>
            </xsl:if>
            
            <!--Simple summary file: total mention counts, novel-wide and per part-->
            <xsl:result-document href="{$outputDir}/{$docId}/character_mentions/{$docId}_mentions_{$targetId}_summary.txt" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                
                <xsl:variable name="totalMentions" 
                    select="count(//said//persName[@ref = '#' || $targetId])" 
                    as="xs:integer"/>
                
                <xsl:variable name="novelLine" 
                    select="$targetId || ' is mentioned in speech ' || $totalMentions || ' times in the novel.'"
                    as="xs:string"/>
                
                <xsl:variable name="partLines" as="xs:string*">
                    <xsl:if test="count(//div[@type='part']) gt 1">
                        <xsl:for-each-group select="//div[@type='part']" group-by="@n">
                            <xsl:variable name="partMentions" 
                                select="count(current-group()//said//persName[@ref = '#' || $targetId])"
                                as="xs:integer"/>
                            <xsl:sequence 
                                select="$targetId || ' is mentioned in speech ' || $partMentions || ' times in part ' || current-grouping-key() || '.'"/>
                        </xsl:for-each-group>
                    </xsl:if>
                </xsl:variable>
                
                <xsl:sequence select="string-join(($novelLine, $partLines), $NEWLINE)"/>
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