<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    
    <!-- This stylesheet extracts every instance of a specified character being 
     mentioned by name (via a `persName ref` element) outside of speech, 
     i.e. anywhere in the novel that is not inside a `said` element. This is 
     the complement of character_mentions_speech.xsl, which covers mentions within 
     speech. Together, the two tools cover every mention in the novel, without overlapping.
     
     Every individual `<persName>` mention gets its own row, even if several 
     mentions occur within the same paragraph.
     
     As with the character_mentions_speech.xsl file, you can run this code
     for any character in any novel.
     
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
     location
     
      .tsv files will be created for the full novel as a whole, and for any/all of its parts.
     
     .tsv files will be put in the `_public` folder in the subdirectory `character_mentions_not_speech`
     within the directory for their respective novels. They will be named for the character
     being mentioned. An example file (with the filepath) for a novel's first part would be:
     `tei/_public/bratia_karamazovy/character_mentions_not_speech/bratia_karamazovy_1_mentions_afk.tsv`
     
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
    <xsl:param name="targetId" select="''"/>
    <xsl:param name="novelId" select="''"/>
    
    <xd:doc>
        <xd:desc>For a single specified novel, finds every `persName` element 
            outside of speech (i.e. not inside a `said` element) that refers 
            to the character identified by $targetId, and writes location 
            data to a TSV covering the whole novel, plus one additional TSV 
            per part if the novel has more than one part. Also writes a 
            plain-text summary of total mention counts.</xd:desc>
    </xd:doc>
    <xsl:template name="characterMentionsAnywhere">
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
            
            <!--Build one map entry per individual persName mention that occurs 
                outside of speech, so we can reuse this for the all-novel file, 
                the per-part files, and the summary counts-->
            <xsl:variable name="mentionData" as="map(*)*">
                <xsl:for-each select="//persName[@ref = '#' || $targetId][not(ancestor::said)]">
                    <xsl:variable name="part" select="string(ancestor::div[@type='part']/@n)" as="xs:string"/>
                    <xsl:variable name="chapter" select="string(ancestor::div[@type='chapter']/@n)" as="xs:string"/>
                    <xsl:variable name="section" select="string(ancestor::div[@type='section']/@n)" as="xs:string"/>
                    <xsl:variable name="location" select="string-join(($part, $chapter, $section), '.')" as="xs:string"/>
                    
                    <xsl:map>
                        <xsl:map-entry key="'Part'" select="$part"/>
                        <xsl:map-entry key="'location'" select="$location"/>
                    </xsl:map>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="headerValues" select="'location'"/>
            <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
            
            <!--Whole-novel file-->
            <xsl:result-document href="{$outputDir}/{$docId}/character_mentions_not_speech/{$docId}_mentions_{$targetId}.tsv" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                <xsl:variable name="dataRows" as="xs:string*">
                    <xsl:for-each select="$mentionData">
                        <xsl:sequence select=".?location"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>
            
            <!--Per-part files, only if the novel actually has more than one part-->
            <xsl:if test="count(//div[@type='part']) gt 1">
                <xsl:for-each-group select="$mentionData" group-by=".?Part">
                    <xsl:result-document href="{$outputDir}/{$docId}/character_mentions_not_speech/{$docId}_{current-grouping-key()}_mentions_{$targetId}.tsv" method="text">
                        <xsl:message select="'Creating ' || current-output-uri()"/>
                        <xsl:variable name="dataRows" as="xs:string*">
                            <xsl:for-each select="current-group()">
                                <xsl:sequence select=".?location"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
                    </xsl:result-document>
                </xsl:for-each-group>
            </xsl:if>
            
            <!--Simple summary file: total mention counts outside speech, novel-wide and per part-->
            <xsl:result-document href="{$outputDir}/{$docId}/character_mentions_not_speech/{$docId}_mentions_{$targetId}_summary.txt" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                
                <xsl:variable name="totalMentions" select="count($mentionData)" as="xs:integer"/>
                
                <xsl:variable name="novelLine" 
                    select="$targetId || ' is mentioned ' || $totalMentions || ' times in the novel, outside instances of speech.'"
                    as="xs:string"/>
                
                <xsl:variable name="partLines" as="xs:string*">
                    <xsl:if test="count(//div[@type='part']) gt 1">
                        <xsl:for-each-group select="$mentionData" group-by=".?Part">
                            <xsl:variable name="partTotal" select="count(current-group())" as="xs:integer"/>
                            <xsl:sequence 
                                select="$targetId || ' is mentioned ' || $partTotal || ' times in part ' 
                                || current-grouping-key() || ', outside instances of speech.'"/>
                        </xsl:for-each-group>
                    </xsl:if>
                </xsl:variable>
                
                <xsl:sequence select="string-join(($novelLine, $partLines), $NEWLINE)"/>
            </xsl:result-document>
            
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>