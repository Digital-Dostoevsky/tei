<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:dd="https://github.com/Digital-Dostoevsky"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    version="3.0">
    
<!-- Products of this stylesheet, which will all be deposited in the _public folder
     upon running.
 
 1) tsv files of all speech in all the novels of the corpus, regardless of the values 
 of any of the component parts of `<said`. Should be called "[novel]_Master_Network_Data."
 
    The resulting tsv files should be structured with the following columns:
    Part, Chapter, Section, aloud, direct, who, whoSex, toWhom, toWhomSex, Text
    
 2) tsv edges files for all direct speech in all the novels of the corpus. Should
 be called "[novel]_edges".
 
     Direct speech means no self-talk, no empty `who` or `toWhom`, and the values of
     `aloud` and `direct` are true.
    
     The resulting tsv files should be structured by the following columns:
     Part, Chapter, Section, source, sourceSex, target, targetSex, aloud, direct.
     
     Note: "source" and "target" are functionally equivalent to `who` and `toWhom`.
     
     Note: Self-talk only means exactly one character talking to themselves, i.e.
     `<said aloud="true" direct="true" who="#abc" toWhom="#abc">`
     Speech where `who` and `toWhom` are identical, but where there is more than
     one character speaking and being spoken to, should go into the csv. 
     For example: 
     `<said aloud="true" direct="true" who="#abc #def #ghi" toWhom="#abc #def #ghi">
     This is most likely individual members of a group all talking to each other
     simultaneously, and is thus different than self-talk.
     
 3) tsv nodes files for all direct speech in all the novels of the corpus.
 Should be called "[novel]_nodes".
 
     These nodes files should be comprised of the distinct `xml:ids` of everyone
     who engages in direct speech, whether speaking (`who`) or spoken to (`toWhom`).
 
     The resulting csv files should be structured by the following columns:
     ID, LABEL.
     
     "ID" is the distinct `xml:id` of anyone who either speaks or is spoken to.
     
     "LABEL" is the actual name of the character that corresponds to a given `xml:id.`
     Names should be taken from the `back`, preferably from the English language
     text in `<persName xml:lang="en">...</persName> if there is an English equivalent
     given. If there is not, revert to whatever the Cyrillic is in
     `<persName>...</persName>
 
 4) tsv edges files for direct speech in each part of each novel in the corpus.
 Should be called "[novel]_[part]_edges." 

     Same parameters as the edges files above, just broken down into parts.
     
 5) tsv nodes files for direct speech in each part of each novel in the corpus.
 Should be called "[novel]_[part]_nodes".
 
     Same parameters as the nodes files above, just broken down into parts.

-->
     
     
    <!-- Specifies the output format as text--> 
    <xsl:output method="text" />
    
    
    <!-- Global variables -->
    <xsl:variable name="TAB" select="codepoints-to-string(9)"/>
    <xsl:variable name="NEWLINE" select="codepoints-to-string(10)"/>
    <xsl:param name="outputDir" select="'.'"/>
    <xsl:variable name="texts"
        as="document-node()+"
        select="collection('../../texts?select=*.xml;recurse=yes')"/>
    
    <xd:doc>
        <xd:desc>Utilizing maps, this process extracts all the data from all the novels that we will need 
            and stores it in a structured intermediate format which we pull from later in order to create 
            the files indicated in the comment at the top of this document.</xd:desc>
    </xd:doc>
    <xsl:template name="allData">
        <xsl:for-each select="$texts">
            <xsl:variable name="docId" select="//TEI/@xml:id" as="xs:string"/>
            <xsl:message>Processing <xsl:value-of select="$docId"/></xsl:message>
            <xsl:variable name="people" select="(//person[@xml:id], //personGrp[@xml:id])"
                as="element()+"/>

            <xsl:variable name="data" as="map(*)+">
                <xsl:for-each select="//said">
                    <xsl:variable name="part" select="string(ancestor::div1/@n)" as="xs:string"/>
                    <xsl:variable name="chapter" select="string(ancestor::div2/@n)" as="xs:string"/>
                    <xsl:variable name="section" select="string(ancestor::div3/@n)" as="xs:string"/>
                    <xsl:variable name="saidId" select="generate-id(.)" as="xs:string"/>
                    <xsl:variable name="aloud" select="
                            if (@aloud) then
                                string(@aloud)
                            else
                                'unknown'" as="xs:string"/>
                    <xsl:variable name="direct" select="
                            if (@direct) then
                                string(@direct)
                            else
                                'unknown'" as="xs:string"/>
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
                    <!-- Concern: what about a situation where everyone in a group is shouting at each other? 
                        `who="#person1 #person2 #person3" toWhom="#person1  #person2 #person3".
                        This is legitimate speech (unlike self-talk), but would it get excluded 
                        from the resulting document? Edge case, but still
                        possible.-->
                    
                    <!--Self talk is defined as a single person talking to themself; in any case
                        where there is more than one person either speaking or being spoken to,
                        then it cannot be self talk-->
                    <xsl:variable name="isSelfTalk" as="xs:boolean"
                        select="count($whoTokens) = 1 and 
                                count($toWhomTokens) = 1 and 
                                $whoTokens = $toWhomTokens"/>
                    
                    <!--Meainingful speech is aloud, direct, and not to self-->
                    <xsl:variable name="isMeaningfulSpeech"
                        select="$aloud = 'true' and 
                                $direct = 'true' and
                                $whoTokens != 'unknown' and
                                $toWhomTokens != 'unknown' and
                                not($isSelfTalk)"
                        as="xs:boolean"/>
                    
                    <!-- And then get raw string content -->
                    <xsl:variable name="spContents" as="xs:string" select="
                            descendant::text()
                            => string-join()
                            => normalize-space()
                            "/>

                    <xsl:for-each select="$whoTokens">
                        <xsl:variable name="currWhoPtr" select="." as="xs:string"/>
                        <xsl:variable name="whoSex" select="
                                if ($currWhoPtr != 'unknown')
                                then
                                    dd:getSexVal($currWhoPtr, $people)
                                else
                                    'unknown'" as="xs:string"/>
                        
                        <xsl:variable name="whoName" select="
                            if ($currWhoPtr != 'unknown')
                            then
                                dd:getName($currWhoPtr, $people)
                            else
                                'unknown'" as="xs:string"/>
                        <xsl:for-each select="$toWhomTokens">
                            <xsl:variable name="currToWhomPtr" select="." as="xs:string"/>
                            <xsl:variable name="toWhomSex" select="
                                    if ($currToWhomPtr != 'unknown')
                                    then
                                        dd:getSexVal($currToWhomPtr, $people)
                                    else
                                        'unknown'" as="xs:string"/>
                            <xsl:variable name="toWhomName" select="
                                if ($currToWhomPtr != 'unknown')
                                then
                                    dd:getName($currToWhomPtr, $people)
                                else
                                    'unknown'" as="xs:string"/>
                            
                            <xsl:map>
                                <xsl:map-entry key="'Part'" select="$part"/>
                                <xsl:map-entry key="'Chapter'" select="$chapter"/>
                                <xsl:map-entry key="'Section'" select="$section"/>
                                <xsl:map-entry key="'saidID'" select="$saidId"/>
                                <xsl:map-entry key="'aloud'" select="$aloud"/>
                                <xsl:map-entry key="'direct'" select="$direct"/>
                                <xsl:map-entry key="'isSelfTalk'" select="$isSelfTalk"/>
                                <xsl:map-entry key="'isMeaningfulSpeech'" select="$isMeaningfulSpeech"/>
                                <xsl:map-entry key="'who'" select="$currWhoPtr"/>
                                <xsl:map-entry key="'whoName'" select="$whoName"/>
                                <xsl:map-entry key="'whoSex'" select="$whoSex"/>
                                <xsl:map-entry key="'toWhom'" select="$currToWhomPtr"/>
                                <xsl:map-entry key="'toWhomName'" select="$toWhomName"/>
                                <xsl:map-entry key="'toWhomSex'" select="$toWhomSex"/>
                                <xsl:map-entry key="'text'" select="$spContents"/>
                            </xsl:map>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            
         
            
            <!--Result Document 1: All instances of `<said>`, regardless of the values of any of the attributes. 
                Useful for diagnostics, getting a sense of all speech, etc.-->
            <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_Master_Network_Data.tsv" method="text">
                <!--For each document, we have 1 map per spreadsheet row, but we want to just extract
                    the header values (which are the same as the keys), so we can just take the first map
                    and use its header values)-->
                <xsl:message select="'Creating ' || current-output-uri()"/>
                <xsl:variable name="headerValues" select="
                    'Part', 'Chapter', 'Section', 'ID', 'aloud', 'direct', 'isSelfTalk','isMeaningfulSpeech',
                    'who', 'whoName', 'whoSex', 'toWhom', 'toWhomName', 'toWhomSex', 'Text'"/>
                <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                <xsl:variable name="dataRows" as="xs:string+">
                    <xsl:for-each select="$data">
                        <xsl:variable name="dataToUse" 
                            select=".?Part, .?Chapter, .?Section, .?saidID, .?aloud, .?direct, xs:string(.?isSelfTalk),
                            xs:string(.?isMeaningfulSpeech), .?who, .?whoName, .?whoSex, .?toWhom, ?toWhomName, .?toWhomSex, .?text" as="xs:string+"/>
                        <xsl:variable name="row" select="string-join($dataToUse, $TAB)" as="xs:string"/>
                        <xsl:sequence select="$row"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>
            
            <!--The variable "gephiSubsetData" below gives us all of the instances 
                of speech that will be useful for Gephi network analysis. See
                above for how "isMeaningfulSpeech" works in detail, but in short it 
                means speech that is direct, aloud, and not to oneself.-->
            <xsl:variable name="gephiSubsetData"
                select="$data[.?isMeaningfulSpeech]" as="map(*)+"/>
            
            <!--Result Document 2: Edges files for all novels in full -->
            <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_all_edges.tsv" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                <xsl:variable name="headerValues" select="
                    'Location', 'ID',
                    'source', 'whoSex', 'target', 'toWhomSex'"/>
                <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                <xsl:variable name="dataRows" as="xs:string+">
                    <xsl:for-each select="$gephiSubsetData">
                        <xsl:variable name="dataToUse" 
                            select="string-join((.?Part, .?Chapter, .?Section),'.'), .?saidID,
                            .?who, .?whoSex, .?toWhom, .?toWhomSex" as="xs:string+"/>
                        <xsl:variable name="row" select="string-join($dataToUse, $TAB)" as="xs:string"/>
                        <xsl:sequence select="$row"/>
                        
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>
            
            <!--Result Document 3: Nodes files for all novels in full
            REMOVE HASH FROM ID WHEN PROCESSING-->
            <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_all_nodes.tsv" method="text">
                <xsl:message select="'Creating ' || current-output-uri()"/>
                <xsl:variable name="headerValues" select="
                    'Id', 'Label'"/>
                <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                <xsl:variable name="dataRows" as="xs:string+">
                    <xsl:variable name="allWhoValues" 
                        select="for $row in $gephiSubsetData return $row?who"
                        as="xs:string+"/>
                    <xsl:variable name="allToWhomValues" 
                        select="for $row in $gephiSubsetData return $row?toWhom" 
                        as="xs:string+"/>
                    <xsl:variable name="distinctIds" 
                        select="distinct-values(($allWhoValues, $allToWhomValues))"
                        as="xs:string+"/>
                    <xsl:variable name="row" 
                        select="for $id in $distinctIds return 
                        string-join(($id, dd:getName($id, $people)), $TAB)"/>
                    <xsl:sequence select="$row"/>
                </xsl:variable>
                <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
            </xsl:result-document>

            
            <!-- If a novel has more than one part, create the smaller subset documents
                below. If it does not have more than one part (for example, Dvoinik), then
                just use the edges and nodes code above.-->
            <xsl:if test="count(//div1[@type='part']) gt 1">
                <xsl:for-each-group select="$gephiSubsetData" group-by=".?Part">
                    <xsl:message select="'Part ' || current-grouping-key() || ' contains ' || count(current-group()) || ' saids'"/>
                    
                    
                    <!--Result Document 4: Edges files for each part of each novel, if the novel
                        has more than one part-->
                    <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_{current-grouping-key()}_edges.tsv" method="text">
                        <xsl:message select="'Creating ' || current-output-uri()"/>
                        <xsl:variable name="headerValues" select="
                            'Location', 'ID',
                            'source', 'whoSex', 'target', 'toWhomSex'"/>
                        <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                        <xsl:variable name="dataRows" as="xs:string+">
                            <xsl:for-each select="current-group()">
                                <xsl:variable name="dataToUse" 
                                    select="string-join((.?Part, .?Chapter, .?Section),'.'), .?saidID,
                                    .?who, .?whoSex, .?toWhom, .?toWhomSex" as="xs:string+"/>
                                <xsl:variable name="row" select="string-join($dataToUse, $TAB)" as="xs:string"/>
                                <xsl:sequence select="$row"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
                    </xsl:result-document>
                    
                    
                    <!--Result Document 5: Nodes files for each part of each novel, if the novel
                    has more than one part.-->
                    <xsl:result-document href="{$outputDir}/{$docId}/{$docId}_{current-grouping-key()}_nodes.tsv" method="text">
                        <xsl:message select="'Creating ' || current-output-uri()"/>
                        <xsl:variable name="headerValues" select="
                            'Id', 'Label'"/>
                        <xsl:variable name="headerRow" select="string-join($headerValues, $TAB)"/>
                        <xsl:variable name="dataRows" as="xs:string+">
                            <xsl:variable name="allWhoValues" 
                                select="for $row in current-group() return $row?who"
                                as="xs:string+"/>
                            <xsl:variable name="allToWhomValues" 
                                select="for $row in current-group() return $row?toWhom" 
                                as="xs:string+"/>
                            <xsl:variable name="distinctIds" 
                                select="distinct-values(($allWhoValues, $allToWhomValues))"
                                as="xs:string+"/>
                            <xsl:variable name="row" 
                                select="for $id in $distinctIds return 
                                string-join(($id, dd:getName($id, $people)), $TAB)"/>
                            <xsl:sequence select="$row"/>
                        </xsl:variable>
                        <xsl:sequence select="string-join(($headerRow, $dataRows), $NEWLINE)"/>
                    </xsl:result-document>
                </xsl:for-each-group>
            </xsl:if>
        </xsl:for-each>
 
    </xsl:template>
    
    
    
    <xd:doc>
        <xd:desc>Function to retrieve the `@sex` value from an person pointer.</xd:desc>
        <xd:param name="ptr">The ptr value (e.g. #rrr) for the person</xd:param>
        <xd:param name="people">The declared people (e.g. person OR personGrp) in this file.</xd:param>
        <xd:return>A string value as encoded in the person
            (e.g. "male", "female" or "unknown")</xd:return>
    </xd:doc>
    
    <xsl:function name="dd:getSexVal" as="xs:string">
        <xsl:param name="ptr" as="xs:string"/>
        <xsl:param name="people" as="element()+"/>
        <!--currWhoID: e.g. zlts-->
        <xsl:variable name="currId" 
            select="substring-after($ptr,'#')"
            as="xs:string"/>
        <!--Now find the person-->
        <xsl:variable name="person" 
            select="$people[@xml:id = $currId]" 
            as="element()?"/>
        <xsl:if test="empty($person)">
            <xsl:message>WARNING: Cannot find corresponding entity for <xsl:value-of select="$ptr"/></xsl:message>
        </xsl:if>
        <xsl:variable name="sex" 
            select="if ($person/@sex) then $person/@sex else 'unknown'"
            as="xs:string"/>
        <xsl:value-of select="$sex"/>
    </xsl:function>
    
    
    
    <xd:doc>
        <xd:desc>Function to retrieve the `persName` value from an person pointer.</xd:desc>
        <xd:param name="ptr">The ptr value (e.g. #rrr) for the person</xd:param>
        <xd:param name="people">The declared people (e.g. person OR personGrp) in this file.</xd:param>
        <xd:return><!--BB to fill in--></xd:return>
    </xd:doc>
    
    <xsl:function name="dd:getName" as="xs:string">
        <xsl:param name="ptr" as="xs:string"/>
        <xsl:param name="people" as="element()+"/>
        <!--currWhoID: e.g. zlts-->
        <xsl:variable name="currId" 
            select="substring-after($ptr,'#')"
            as="xs:string"/>
        <!--Now find the person-->
        <xsl:variable name="person" 
            select="$people[@xml:id = $currId]" 
            as="element()?"/>
        <xsl:if test="empty($person)">
            <xsl:message>WARNING: Cannot find corresponding entity for <xsl:value-of select="$ptr"/></xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$person/persName[@xml:lang = 'en']">
                <xsl:value-of select="string($person/persName[@xml:lang = 'en'])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="string($person/persName[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>