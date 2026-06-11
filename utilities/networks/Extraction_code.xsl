<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:dd="https://github.com/Digital-Dostoevsky"
    version="3.0">
    <!-- Defines the root element of the XSLT stylesheet -->
    
    <xsl:output method="text" />
    <!-- Specifies the output format as text. -->
    
  <!--  <xsl:variable name="TAB" select="'&#x9;'"/>
    <xsl:sequence select="
        string-join((ancestor::div1/@n, ancestor::div2/@n), $TAB)"/>-->
    
<!--   
        <said who="#personA #personB" toWhom="#personC #personD"/>
         1   1   1   true    true    #personA      #personC
         1   1   1   true    true    #personA      #personD
         1   1   1   true    true    #personB      #personC
         1   1   1   true    true    #personB      #personD
    -->
    
    <xsl:variable name="TAB" select="codepoints-to-string(9)"/>
    <xsl:variable name="NEWLINE" select="codepoints-to-string(10)"/>
    <xsl:param name="outputDir" select="'.'"/>
    <xsl:variable name="texts"
        as="document-node()+"
        select="collection('../../texts?select=*.xml;recurse=yes')"/>
    
    <!--Use collection to get all of the documents (see the Diagnostics for an example)-->
    <!--For every document, create a new result document called `fileId.tsv`
    populated with the said values-->
    <!--The goal here is to be able to run this Extraction_code and create all of the TSVs
        automatically-->
    
    <!--For running this, you will need to either do this at the command line using `saxon` 
        OR in oXygen, using the `initial-template` parameter -->
    
    <!--For running in the ANT build, look at how the diagnostics file is invoked -->
    
    <xsl:template name="go">
        <!--Here is where you will iterate over the documents, create the result document,
            and then apply templates to each document to create the TSV output-->
        
       <!-- Get the document ID from the TEI @xml:id attribute-->
        <xsl:for-each select="$texts">
            <xsl:variable name="docId"
                select="//TEI/@xml:id"
                as="xs:string"/>
            <xsl:variable name="people"
                select="(//person[@xml:id], //personGrp[@xml:id])"
                as="element()+"/>
            
            <xsl:message>Processing <xsl:value-of select="$docId"/></xsl:message>
            
            
       <!-- Create a result document named fileId.tsv for each source file-->
            <xsl:result-document href="{$outputDir}/{$docId}.tsv" method="text">
                <xsl:message>Creating <xsl:value-of select="current-output-uri()"/></xsl:message>
                
                
                <!-- Write the header row-->
                <xsl:variable name="headerValues" select="
                    'Part', 'Section', 'Chapter', 'ID', 'Aloud', 'Direct',
                    'who', 'who_sex', 'toWhom', 'toWhom_sex',  'text'"/>
                <xsl:value-of select="string-join($headerValues, $TAB) || $NEWLINE"/>
                
                
                <!-- Retrieve all variables in relation to said-->
                <xsl:for-each select="//said[@who and @toWhom]">
                    <xsl:variable name="part"
                        select="string(ancestor::div1/@n)"
                        as="xs:string"/>
                    <xsl:variable name="section"
                        select="string(ancestor::div2/@n)"
                        as="xs:string"/>
                    <xsl:variable name="chapter"
                        select="string(ancestor::div3/@n)"
                        as="xs:string"/>
                    
                    <!--Get id for the said value; this could be 
                more location based if desired-->
                    <xsl:variable name="saidId" select="generate-id(.)" as="xs:string"/>
                    <xsl:variable name="aloud"
                        select="if (@aloud) then string(@aloud) else 'unknown'"
                        as="xs:string"/>
                    <xsl:variable name="direct"
                        select="if (@direct) then string(@direct) else 'unknown'"
                        as="xs:string"/>
                    
                    
                    <!--Since @who and @toWhom can have multiple values, we need to
                split on spaces (i.e. tokenize) and then iterate for every
                combination-->
                    <xsl:variable name="whoTokens" 
                        select="tokenize(@who)" as="xs:string+"/>
                    <xsl:variable name="toWhomTokens" 
                        select="tokenize(@toWhom)" as="xs:string+"/>
                    
                    
                    <!--And then get raw string content -->
                    <xsl:variable name="spContents" as="xs:string"
                        select="descendant::text()
                        => string-join()
                        => normalize-space()
                        "/>
                    
                    <xsl:for-each select="$whoTokens">
                        <!--currWhoPtr: e.g. #zlts-->
                        <xsl:variable name="currWhoPtr" select="." as="xs:string"/>
                        <xsl:variable name="whoSex" select="dd:getSexVal($currWhoPtr, $people)" as="xs:string"/>
                        <xsl:for-each select="$toWhomTokens">
                            <xsl:variable name="currToWhomPtr" select="." as="xs:string"/>
                            <xsl:variable name="toWhomSex" select="dd:getSexVal($currToWhomPtr, $people)" as="xs:string"/>
                            <xsl:variable name="rowValues" as="xs:string+"
                                select="($part, $section, $chapter, $saidId, $aloud,
                                $direct, $currWhoPtr, $whoSex,  $currToWhomPtr, $toWhomSex,
                                $spContents)"/>
                            <xsl:value-of select="string-join($rowValues, $TAB) || $NEWLINE"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
                
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    
    <!-- Template for returning only that speech which is aloud, direct, and has different `@who` and `@toWhom` values-->
    <xsl:template name="test">
        
        <!-- Get the document ID from the TEI @xml:id attribute-->
        <xsl:for-each select="$texts">
            <xsl:variable name="docId"
                select="//TEI/@xml:id"
                as="xs:string"/>
            <xsl:variable name="people"
                select="(//person[@xml:id], //personGrp[@xml:id])"
                as="element()+"/>
            
            <xsl:message>Processing <xsl:value-of select="$docId"/></xsl:message>
            
            
            <!-- Create a result document named fileId_network.tsv for each source file-->
            <xsl:result-document href="{$outputDir}/{$docId}_network.tsv" method="text">
                <xsl:message>Creating <xsl:value-of select="current-output-uri()"/></xsl:message>
                
                
                <!-- Write the header row-->
                <xsl:variable name="headerValues" select="
                    'Part', 'Section', 'Chapter', 'ID', 'Aloud', 'Direct',
                    'who', 'who_sex', 'toWhom', 'toWhom_sex',  'text'"/>
                <xsl:value-of select="string-join($headerValues, $TAB) || $NEWLINE"/>
                
                <!-- Return only aloud and direct speech where `@who` and `@toWhom` have different values, i.e. no self-talk-->
                <xsl:for-each select="//said[@who and @toWhom
                    and @aloud = 'true'
                    and @direct = 'true'
                    and not(tokenize(@who) = tokenize(@toWhom))]">
                    <!-- Concern: what about a situation where everyone in a group is shouting at each other? `who="#person1 #person2 #person3" toWhom="#person1 #person2 #person3". This is legitimate speech (unlike self-talk), but would it get excluded from the resulting document? Edge case, but still possible.-->
                    
                    <!-- Return variables in relation to speech as defined above-->
                    <xsl:variable name="part"
                        select="string(ancestor::div1/@n)"
                        as="xs:string"/>
                    <xsl:variable name="section"
                        select="string(ancestor::div2/@n)"
                        as="xs:string"/>
                    <xsl:variable name="chapter"
                        select="string(ancestor::div3/@n)"
                        as="xs:string"/>
                    <!--Get id for the said value; this could be 
                more location based if desired-->
                    <xsl:variable name="saidId" select="generate-id(.)" as="xs:string"/>
                    <xsl:variable name="aloud"
                        select="string(@aloud)"
                        as="xs:string"/>
                    <xsl:variable name="direct"
                        select="string(@direct)"
                        as="xs:string"/>
                    
                    <!--Since @who and @toWhom can have multiple values, we need to
                split on spaces (i.e. tokenize) and then iterate for every
                combination-->
                    <xsl:variable name="whoTokens" 
                        select="tokenize(@who)" as="xs:string+"/>
                    <xsl:variable name="toWhomTokens" 
                        select="tokenize(@toWhom)" as="xs:string+"/>
                    
                    <!--And then get raw string content -->
                    <xsl:variable name="spContents" as="xs:string"
                        select="descendant::text()
                        => string-join()
                        => normalize-space()
                        "/>
                    
                    <xsl:for-each select="$whoTokens">
                        <!--currWhoPtr: e.g. #zlts-->
                        <xsl:variable name="currWhoPtr" select="." as="xs:string"/>
                        <xsl:variable name="whoSex" select="dd:getSexVal($currWhoPtr, $people)" as="xs:string"/>
                        <xsl:for-each select="$toWhomTokens">
                            <xsl:variable name="currToWhomPtr" select="." as="xs:string"/>
                            <xsl:variable name="toWhomSex" select="dd:getSexVal($currToWhomPtr, $people)" as="xs:string"/>
                            <xsl:variable name="rowValues" as="xs:string+"
                                select="($part, $section, $chapter, $saidId, $aloud,
                                $direct, $currWhoPtr, $whoSex,  $currToWhomPtr, $toWhomSex,
                                $spContents)"/>
                            <xsl:value-of select="string-join($rowValues, $TAB) || $NEWLINE"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
                
            </xsl:result-document>
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
    
    
    
   <!-- Joey's template, which I subsumed into the "go" template above
       
       <xsl:template match="/">
        <!-\- Defines a template that matches the root node (/) of the XML document. -\->
        <xsl:variable name="headerValues" select="
            'Part', 'Section', 'Chapter', 'ID', 'Aloud', 'Direct', 'who', 'toWhom', 'text'"/>
        <xsl:value-of select="string-join($headerValues, $TAB) || $NEWLINE"/>
        <xsl:for-each select="//said[@who and @toWhom]">
            <!-\-Retrieve all variables in relation to said-\->
            <xsl:variable name="part" 
                select="string(ancestor::div1/@n)"
                as="xs:string"/>
            <xsl:variable name="section" 
                select="string(ancestor::div2/@n)"
                as="xs:string"/>
            <xsl:variable name="chapter"
                select="string(ancestor::div3/@n)"
                as="xs:string"/>
            <!-\-Get id for the said value; this could be 
                more location based if desired-\->
            <xsl:variable name="saidId" select="generate-id(.)" as="xs:string"/>
            <xsl:variable name="aloud" 
                select="if (@aloud) then string(@aloud) else 'unknown'" 
                as="xs:string"/>
            <xsl:variable name="direct" 
                select="if (@direct) then string(@direct) else 'unknown'" 
                as="xs:string"/>
            
            <!-\-Since @who and @toWhom can have multiple values, we need to
                split on spaces (i.e. tokenize) and then iterate for every
                combination-\->
            <xsl:variable name="whoTokens" select="tokenize(@who)" as="xs:string+"/>
            <xsl:variable name="toWhomTokens" select="tokenize(@toWhom)" as="xs:string+"/>
           
            <!-\-And then get raw string content -\->
            <xsl:variable name="spContents" as="xs:string"
                select="descendant::text() (: Get all text :)
                => string-join() (: Then join all of it together :)
                => normalize-space() (: And trim spaces :)
                "/>
            
            <xsl:for-each select="$whoTokens">
                <xsl:variable name="currWhoPtr" select="." as="xs:string"/>
                <xsl:for-each select="$toWhomTokens">
                    <xsl:variable name="currToWhomPtr" select="." as="xs:string"/>
                    <xsl:variable name="rowValues" as="xs:string+"
                        select="($part, $section, $chapter, $saidId, $aloud, 
                                 $direct, $currWhoPtr, $currToWhomPtr,
                                 $spContents)"/>
                    <xsl:value-of select="string-join($rowValues, $TAB) || $NEWLINE"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>-->
   
    
 <!-- 
    
    <xsl:template match="*" mode="strip">
        <!-\- Template that matches any element in 'strip' mode. -\->
        
        <xsl:apply-templates select="node()" mode="strip" />
        <!-\- Recursively applies the 'strip' mode to all child nodes. -\->
        
    </xsl:template>
    
    <xsl:template match="text()" mode="strip">
        <!-\- Template that matches any text node in 'strip' mode. -\->
        
        <xsl:value-of select="." />
        <!-\- Outputs the text content of the current node. -\->
        
    </xsl:template>-->
    
    
    <!--<!-\- Iterates over every 'said' element. -\->
    
    <xsl:value-of select="ancestor::div1/@n" />
    <!-\- Outputs the value of the 'n' attribute of the nearest 'div1' ancestor element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->
    
    <xsl:value-of select="ancestor::div2/@n" />
    <!-\- Outputs the value of the 'n' attribute of the nearest 'div2' ancestor element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->
    
    <xsl:value-of select="ancestor::div3/@n" />
    <!-\- Outputs the value of the 'n' attribute of the nearest 'div3' ancestor element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->
    
    <xsl:value-of select="@aloud" />
    <!-\- Outputs the value of the 'aloud' attribute of the current 'said' element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->
    
    <xsl:value-of select="@direct" />
    <!-\- Outputs the value of the 'direct' attribute of the current 'said' element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->-->
    
<!--    <xsl:value-of select="@who" />
    <!-\- Outputs the value of the 'who' attribute of the current 'said' element. -\->
    
    <xsl:text></xsl:text>
    <!-\- Inserts a tab character. -\->
    
    <xsl:value-of select="@toWhom" />
    <!-\- Outputs the value of the 'toWhom' attribute of the current 'said' element. -\->
    
    <xsl:text>&#x9;</xsl:text>
    <!-\- Inserts a tab character. -\->
    
    
    <!-\- Applies the 'strip' mode to remove any tags. -\->
    
    <xsl:text>&#xA;</xsl:text>
    <!-\- Inserts a newline. -\->-->
    
    
</xsl:stylesheet>