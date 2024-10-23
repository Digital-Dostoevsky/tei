<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <!-- Defines the root element of the XSLT stylesheet -->
    
    <xsl:output method="text" />
    <!-- Specifies the output format as text. -->
    
    <xsl:template match="/">
        <!-- Defines a template that matches the root node (/) of the XML document. -->
        
        <xsl:for-each select="//said">
            <!-- Iterates over every 'said' element. -->
            
            <xsl:value-of select="ancestor::div1/@n" />
            <!-- Outputs the value of the 'n' attribute of the nearest 'div1' ancestor element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="ancestor::div2/@n" />
            <!-- Outputs the value of the 'n' attribute of the nearest 'div2' ancestor element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="ancestor::div3/@n" />
            <!-- Outputs the value of the 'n' attribute of the nearest 'div3' ancestor element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="@aloud" />
            <!-- Outputs the value of the 'aloud' attribute of the current 'said' element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="@direct" />
            <!-- Outputs the value of the 'direct' attribute of the current 'said' element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="@who" />
            <!-- Outputs the value of the 'who' attribute of the current 'said' element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:value-of select="@toWhom" />
            <!-- Outputs the value of the 'toWhom' attribute of the current 'said' element. -->
            
            <xsl:text>&#x9;</xsl:text>
            <!-- Inserts a tab character. -->
            
            <xsl:apply-templates select="node()" mode="strip" />
            <!-- Applies the 'strip' mode to remove any tags. -->
            
            <xsl:text>&#xA;</xsl:text>
            <!-- Inserts a newline. -->
            
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*" mode="strip">
        <!-- Template that matches any element in 'strip' mode. -->
        
        <xsl:apply-templates select="node()" mode="strip" />
        <!-- Recursively applies the 'strip' mode to all child nodes. -->
        
    </xsl:template>
    
    <xsl:template match="text()" mode="strip">
        <!-- Template that matches any text node in 'strip' mode. -->
        
        <xsl:value-of select="." />
        <!-- Outputs the text content of the current node. -->
        
    </xsl:template>
    
</xsl:stylesheet>