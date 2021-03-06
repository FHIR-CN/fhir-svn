<?xml version="1.0" encoding="UTF-8"?>
<!--
  - FHIR Document bundle to HTML Conversion
  -
  - Initially developed by Rick Geimer, Lantana Consulting Ltd. & Lloyd McKenzie, Gevity
  -
  - This transform provides an instantiation of the rendering process for FHIR documents as defined in the FHIR specification.
  - Systems are not required to make use of this transform.  It is provided for example purposes only.  If you choose to use it
  - within your system, you must accept all risk in doing so.
  - 
  - (c) 2014 Health Level Seven, Inc. and Lantana Consulting Group
  - 
  - Licensed under the Apache License, Version 2.0 (the "License");
  - you may not use this file except in compliance with the License.
  - You may obtain a copy of the License at
  -
  -    http://www.apache.org/licenses/LICENSE-2.0
  -
  - Unless required by applicable law or agreed to in writing, software
  - distributed under the License is distributed on an "AS IS" BASIS,
  - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  - See the License for the specific language governing permissions and
  - limitations under the License.
  -->
  
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fhir="http://hl7.org/fhir" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0" exclude-result-prefixes="xhtml">
  <xsl:output indent="yes" encoding="ISO-8859-1"/>
  <!-- Fixed values are defined as parameters so they can be overridden to expose content in other languages, etc. -->
  <xsl:param name="untitled_doc" select="'Untitled Document'"/>
  <xsl:param name="no_human_display" select="'No human-readable content available'"/>
  <xsl:param name="subject_heading" select="'Subject details'"/>
  <xsl:param name="untitled_section" select="'Untitled Section'"/>
  
  <xsl:template match="/">
    <!-- Check that we're actually dealing with a document, and if so, start processing with the Composition resource -->
    <xsl:if test="not(fhir:Bundle)">
      <xsl:message terminate="yes">Source document must be a bundle</xsl:message>
    </xsl:if>
    <xsl:if test="not(fhir:Bundle/fhir:entry[1]/fhir:resource/fhir:Composition)">
      <xsl:message terminate="yes">Bundle must start with a Composition resource</xsl:message>
    </xsl:if>
    <xsl:if test="not(fhir:Bundle/fhir:type/@value='document')">
      <xsl:message>Warning: Bundle type does not indicate it is a document.</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="fhir:Bundle/fhir:entry[1]/fhir:resource/fhir:Composition"/>
  </xsl:template>
  
  <xsl:template match="fhir:Composition">
    <!-- Generate HTML for document 'header' elements, then process sections
         Rules as documented in http://hl7.org/fhir/documents.html#presentation -->
    <xsl:variable name="title">
      <!-- Determine the title for the document, using a placeholder if there isn't one -->
      <xsl:choose>
        <xsl:when test="normalize-space(fhir:title/@value)!=''">
          <xsl:value-of select="fhir:title/@value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$untitled_doc"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <html>
      <head>
        <title>
          <xsl:value-of select="$title"/>
        </title>
      </head>
      <body>
        <h1>
          <xsl:value-of select="$title"/>
        </h1>
        <xsl:apply-templates select="fhir:text/xhtml:div">
          <xsl:with-param name="nesting-depth" select="2"/>
        </xsl:apply-templates>
        <h2>
          <xsl:value-of select="$subject_heading"/>
        </h2>
        <xsl:apply-templates mode="reference" select="fhir:subject"/>
        <xsl:apply-templates select="fhir:section"/>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template mode="reference" match="fhir:*">
    <!-- 
      - Resolve a reference to another resource:
      -  - If possible, look up the referenced resource
      -  - Otherwise expose the 'display' if it's present
      -  - In the worst case, display a place-holder
      -->
    <xsl:param name="nesting-depth" select="2">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:choose>
      <xsl:when test="fhir:reference">
        <xsl:apply-templates select="fhir:reference">
          <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="normalize-space(fhir:display/@value)!=''">
        <p>
          <xsl:value-of select="fhir:display/@value"/>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:value-of select="$no_human_display"/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="fhir:reference">
    <!-- Resolves a reference to another resource as either a local 'contained' resource
       - or as another resource within the bundle -->
    <xsl:param name="nesting-depth">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:choose>
      <xsl:when test="starts-with(@value,'#')">
        <!-- It's a local reference, so look for a 'contained' resource -->
        <xsl:variable name="local-id" select="substring-after(@value,'#')"/>
        <xsl:apply-templates select="ancestor::fhir:Bundle/fhir:entry/fhir:resource/fhir:*/fhir:contained[fhir:*/fhir:id/@value=$local-id]">
          <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="referenceURI">
          <!-- Determine the full URL of the reference -->
          <xsl:choose>
            <xsl:when test="contains(@value, ':')">
              <!-- id is a full URL, so ignore any 'base' -->
              <xsl:value-of select="@value"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="expandBase"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="matchedResource">
          <!-- Go through every resource and see if any of them is a match -->
          <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/*/fhir:id">
            <xsl:variable name="resourceURI">
              <xsl:call-template name="expandBase">
                <xsl:with-param name="type" select="local-name(ancestor::fhir:resource/*)"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$resourceURI = $referenceURI">Y</xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="normalize-space($matchedResource)=''">
            <!-- We've got a reference to a resource that's not in the bundle, which isn't legal inside a document.  
              - We *could* use document(@value) to try to retrieve the remote resource, but seeing as the
              - document's obviously non-conformant, we'll raise an error instead. -->
            <xsl:message terminate="yes">
              <xsl:value-of select="concat('Error: The document composition includes a reference to a resource not contained inside the document bundle: ', @value)"/>
            </xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/*/fhir:id">
              <!-- Go through every resource again, find the one that's a match and render its narrative -->
              <!-- Yes, this is inefficient, but given the lack of functions and ability to store elements as variables in pure XSLT 1, not a lot of choice. -->
              <xsl:variable name="resourceURI">
                <xsl:call-template name="expandBase">
                  <xsl:with-param name="type" select="local-name(ancestor::fhir:resource/*)"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:if test="$resourceURI = $referenceURI">
                <xsl:apply-templates select="parent::*/parent::*">
                  <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
                </xsl:apply-templates>
              </xsl:if>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="expandBase">
    <!-- Determines the proper URL of a reference or resource reference based on the declared base for the element or resource -->
    <xsl:param name="type">
      <!-- The name of the resource - only passed in if expanding a resource id - for a reference, should already be part of the @value if needed -->
    </xsl:param>
    <xsl:choose>
      <xsl:when test="ancestor::fhir:entry/fhir:base">
        <xsl:call-template name="createURI">
          <xsl:with-param name="base" select="ancestor::fhir:entry/fhir:base/@value"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:with-param name="id" select="@value"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="/fhir:Bundle/fhir:base">
        <xsl:call-template name="createURI">
          <xsl:with-param name="base" select="/fhir:Bundle/fhir:base/@value"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:with-param name="id" select="@value"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="createURI">
          <xsl:with-param name="base" select="''"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:with-param name="id" select="@value"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="createURI">
    <!-- Creates a full resource URI from base, type and id, figuring out when and if to add intervening '/' characters -->
    <xsl:param name="base"/>
    <xsl:param name="type"/>
    <xsl:param name="id"/>
    <xsl:choose>
      <xsl:when test="starts-with($base, 'urn') or (substring($base, string-length($base) - 1, 1)= '/' and $type ='')">
        <xsl:value-of select="concat($base, $id)"/>
      </xsl:when>
      <xsl:when test="substring($base, string-length($base) - 1, 1)= '/'">
        <xsl:value-of select="concat($base, $type, '/', $id)"/>
      </xsl:when>
      <xsl:when test="$type=''">
        <xsl:value-of select="concat($base, '/', $id)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($base, '/', $type, '/', $id)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="fhir:section">
    <!-- Handles the display of sections (and descendant sections), including their titles -->
    <xsl:param name="nesting-depth" select="2">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:variable name="heading-tag">
      <xsl:call-template name="get-heading-tag">
        <xsl:with-param name="level" select="$nesting-depth"/>
      </xsl:call-template>
    </xsl:variable>
    <div>
      <xsl:element name="{$heading-tag}">
        <xsl:choose>
          <xsl:when test="fhir:title/@value">
            <xsl:value-of select="fhir:title/@value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$untitled_section"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
      <xsl:apply-templates mode="reference" select="fhir:content">
        <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="fhir:section">
        <xsl:with-param name="nesting-depth" select="$nesting-depth + 1"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>
  
  <xsl:template match="fhir:resource|fhir:contained">
    <!-- Render the narrative content for a resource if there is one, otherwise display a place-holder -->
    <xsl:param name="nesting-depth">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:choose>
      <xsl:when test="normalize-space(fhir:*/fhir:text/xhtml:div)!=''">
        <xsl:apply-templates select="fhir:*/fhir:text/xhtml:div">
          <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:value-of select="$no_human_display"/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="xhtml:h1 | xhtml:h2 | xhtml:h3 | xhtml:h4 | xhtml:h5 | xhtml:h6">
    <!-- Translate heading tags to the appropriate level based on their nesting location within the document -->
    <xsl:param name="nesting-depth">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:variable name="current-heading-level" select="substring-after(local-name(), 'h')">
      <!-- What level is the current tag? -->
    </xsl:variable>
    <xsl:variable name="heading-tag">
      <!-- New tag combines the nesting level with the tag level -->
      <xsl:call-template name="get-heading-tag">
        <xsl:with-param name="level" select="$current-heading-level + $nesting-depth"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:element name="{$heading-tag}">
      <xsl:copy-of select="@*|node()"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="xhtml:*">
    <!-- Fall-through for xhtml passes the nesting parameter and removes uneeded namespaces -->
    <xsl:param name="nesting-depth">
      <!-- Identifies how deep in the rendering hierarchy a rendered resource is - for use in converting heading levels -->
    </xsl:param>
    <xsl:element name="{local-name(.)}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()">
        <xsl:with-param name="nesting-depth" select="$nesting-depth"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@*|text()">
    <!-- Fall-through template copies text and attributes -->
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <!-- Named templates -->
  <xsl:template name="get-heading-tag">
    <!-- Returns the appropriate heading tag for a specified nesting level.  E.g h1 for 1, h2 for 2, etc.  Anything over h6 becomes <p> -->
    <xsl:param name="level">
      <!-- Indicates the nesting level for the tag -->
    </xsl:param>
    <xsl:choose>
      <xsl:when test="$level &gt; 6">
        <xsl:message>Warning: Headings exceed 6 levels deep.  Remaining headings converted to simple paragraphs</xsl:message>
        <xsl:text>p</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('h', $level)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
