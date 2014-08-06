<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xpath-default-namespace="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.w3.org/1999/xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:fn="http://hl7.org/fhir/xslt-functions" exclude-result-prefixes="xs xhtml fn">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/Conformance">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <text xmlns="http://hl7.org/fhir">
        <status xmlns="http://hl7.org/fhir" value="generated"/>
        <div xmlns="http://www.w3.org/1999/xhtml">
          <xsl:for-each select="name">
            <h2>
              <xsl:value-of select="@value"/>
            </h2>
          </xsl:for-each>
          <p>
            <xsl:text>(</xsl:text>
            <xsl:choose>
              <xsl:when test="implementation">Implementation Conformance Statement</xsl:when>
              <xsl:when test="software">Software Conformance Statement</xsl:when>
              <xsl:otherwise>Requirements Definition</xsl:otherwise>
            </xsl:choose>
            <xsl:text>)</xsl:text>
          </p>
          <p>
            <xsl:variable name="content" as="xs:string+">
              <xsl:value-of select="identifier/@value"/>
              <xsl:for-each select="version">
                <xsl:value-of select="concat('Version: ', @value)"/>
              </xsl:for-each>
              <xsl:value-of select="concat('Published: ', date/@value)"/>
              <xsl:for-each select="status[@value=('draft', 'retired')]">
                <xsl:value-of select="concat('(', @value, ')')"/>
              </xsl:for-each>
              <xsl:if test="experimental/@value='true'">
                <xsl:text> - experimental</xsl:text>
              </xsl:if>
            </xsl:variable>
            <xsl:value-of select="normalize-space(string-join($content, ' '))"/>
          </p>
          <xsl:variable name="firstTelecom" as="xs:string?">
            <xsl:choose>
              <xsl:when test="telecom[use/@value='url']">
                <xsl:value-of select="telecom[use/@value='url'][1]/value/@value"/>
              </xsl:when>
              <xsl:when test="telecom[use/@value='email']">
                <xsl:value-of select="concat('mailto:', telecom[use/@value='email'][1]/value/@value)"/>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          <p>
            <xsl:text>Published by: </xsl:text>
            <b>
              <xsl:choose>
                <xsl:when test="$firstTelecom">
                  <a href="{$firstTelecom}">
                    <xsl:value-of select="publisher/@value"/>
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="publisher"/>
                </xsl:otherwise>
              </xsl:choose>
            </b>
            <xsl:variable name="telecoms" as="xs:string+">
              <xsl:for-each select="telecom[not(starts-with($firstTelecom, value/@value))]">
                <xsl:value-of select="concat(use/@value, ': ', value/@value)"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="string-join($telecoms, ' ')"/>
          </p>
          <xsl:copy-of select="fn:handleMarkdownLines(description/@value)"/>
          <xsl:for-each select="software">
            <p>
              <xsl:variable name="parts" as="xs:string+">
                <xsl:value-of select="concat('Applies to software: ', name/@value)"/>
                <xsl:for-each select="version/@value">
                  <xsl:value-of select="concat('version: ', .)"/>
                </xsl:for-each>
                <xsl:value-of select="date/@value"/>
              </xsl:variable>
              <xsl:value-of select="string-join($parts, ' ')"/>
            </p>
          </xsl:for-each>
          <xsl:for-each select="implementation">
            <p>
              <xsl:value-of select="concat('Implementation: ', url/@value)"/>
            </p>
            <xsl:copy-of select="fn:handleMarkdownLines(description/@value)"/>
          </xsl:for-each>
          <xsl:if test="fhirVersion/@value|acceptUnknown/@value|format/@value|profile/@value">
            <h2>General</h2>
            <table>
              <tbody>
                <xsl:for-each select="fhirVersion/@value">
                  <tr>
                    <th>FHIR Version:</th>
                    <td>
                      <xsl:value-of select="."/>
                    </td>
                  </tr>
                </xsl:for-each>
                <xsl:for-each select="acceptnknown/@value">
                  <tr>
                    <th>Accepts elements from future versions:</th>
                    <td>
                      <xsl:value-of select="."/>
                    </td>
                  </tr>
                </xsl:for-each>
                <xsl:if test="format/@value">
                  <tr>
                    <th>Supported formats:</th>
                    <td>
                      <xsl:value-of select="string-join(format/@value, ', ')"/>
                    </td>
                  </tr>
                </xsl:if>
                <xsl:if test="profile/@value">
                  <tr>
                    <th>Supported profiles:</th>
                    <td>
                      <xsl:for-each select="profile/@value">
                        <p>
                          <a href="{.}">
                            <xsl:value-of select="."/>
                          </a>
                        </p>
                      </xsl:for-each>
                    </td>
                  </tr>
                </xsl:if>
              </tbody>
            </table>
          </xsl:if>
          <xsl:for-each select="rest">
            <h2>
              <xsl:value-of select="concat('REST ', @mode, ' behavior')"/>
            </h2>
            <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
            <xsl:for-each select="security/description/@value">
              <p>
                <b>Security:</b>
              </p>
              <xsl:copy-of select="fn:handleMarkdownLines(.)"/>
            </xsl:for-each>
            <h3>Summary</h3>
            <table class="grid">
              <thead>
                <tr>
                  <th>Resource</th>
                  <th>Search</th>
                  <th>Read</th>
                  <th>Read Version</th>
                  <th>Instance History</th>
                  <th>Resource History</th>
                  <th>Validate</th>
                  <th>Create</th>
                  <th>Update</th>
                  <th>Delete</th>
                </tr>
              </thead>
              <tbody>
                <xsl:for-each select="resource">
                  <tr>
                    <th>
                      <xsl:value-of select="type/@value"/>
                      <xsl:for-each select="profile/@value">
                        <xsl:text> (</xsl:text>
                          <a href="{.}">Profile</a>
                        <xsl:text>)</xsl:text>
                      </xsl:for-each>
                    </th>
                    <td>
                      <xsl:for-each select="interaction[code/@value='search-type']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='read']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='vread']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                      <xsl:if test="readHistory/@value='false'">(current only)</xsl:if>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='history-instance']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='history-type']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='validate']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='create']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='update']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                      <xsl:if test="updateCreate/@value='false'">(existing only)</xsl:if>
                    </td>
                    <td>
                      <xsl:for-each select="interaction[code/@value='delete']">
                        <xsl:call-template name="doConformance"/>
                      </xsl:for-each>
                    </td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
            <xsl:if test="operation">
              <p>
                <b>Operations:</b>
                <xsl:for-each select="operation">
                  <xsl:if test="position()!=1">, </xsl:if>
                  <a title="{definition/display/@value}" href="{definition/reference/@value}">
                    <xsl:value-of select="name/@value"/>
                  </a>
                  <xsl:for-each select="extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']/valueCode/@value">
                    <xsl:value-of select="concat('(', ., ')')"/>
                  </xsl:for-each>
                </xsl:for-each>
              </p>
            </xsl:if>
            <xsl:if test="interaction">
              <h3>General interactions</h3>
              <table class="list">
                <tbody>
                  <xsl:apply-templates select="interaction"/>
                </tbody>
              </table>
            </xsl:if>
            <xsl:for-each select="resource">
              <h3>
                <a href="{lower-case(type/@value)}.html">
                  <xsl:value-of select="type/@value"/>
                </a>              
              </h3>
              <xsl:for-each select="profile/@value">
                <p>
                  <xsl:text>Profile: </xsl:text>
                  <a href="{.}">
                    <xsl:value-of select="."/>
                  </a>
                </p>
              </xsl:for-each>
              <xsl:copy-of select="fn:handleMarkdownLines(description/@value)">
                <!-- This doesn't exist yet -->
              </xsl:copy-of>
              <table class="list">
                <tbody>
                  <xsl:apply-templates select="interaction[documentation]"/>
                </tbody>
              </table>
              <b>Search</b>
              <xsl:if test="searchInclude">
                <p>
                  <xsl:text>Supported Includes: </xsl:text>
                  <xsl:value-of select="string-join(searchInclude/@value, ' ')"/>
                </p>
              </xsl:if>
              <xsl:if test="searchParam">
                <xsl:call-template name="doParams"/>
              </xsl:if>
            </xsl:for-each>
            <xsl:if test="query">
              <h3>Queries</h3>
              <xsl:for-each select="query">
                <b>
                  <a href="{definition/@value}">
                    <xsl:value-of select="name/@value"/>
                  </a>
                </b>
                <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
                <xsl:call-template name="doParams"/>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
          <xsl:for-each select="messaging">
            <h2>Messaging</h2>
            <p>
              <b>End point: </b>
              <xsl:value-of select="endpoint/@value"/>
            </p>
            <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
            <table class="grid">
              <thead>
                <tr>
                  <th>Event</th>
                  <th>Category</th>
                  <th>Mode</th>
                  <th>Protocol(s)</th>
                  <th>Focus</th>
                  <th>Request</th>
                  <th>Response</th>
                  <th>Notes</th>
                </tr>
              </thead>
              <tbody>
                <xsl:for-each select="event">
                  <tr>
                    <td>
                      <xsl:value-of select="code/@value"/>
                    </td>
                    <td>
                      <xsl:value-of select="category/@value"/>
                    </td>
                    <td>
                      <xsl:value-of select="mode/@value"/>
                    </td>
                    <td>
                      <xsl:value-of select="string-join(protocol/@value, ', ')"/>
                    </td>
                    <td>
                      <xsl:value-of select="focus/@value"/>
                    </td>
                    <td>
                      <xsl:for-each select="request/@value">
                        <a href="{.}">
                          <xsl:value-of select="."/>
                        </a>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:for-each select="response/@value">
                        <a href="{.}">
                          <xsl:value-of select="."/>
                        </a>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
                    </td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
          </xsl:for-each>
          <xsl:if test="document">
            <h2>Documents</h2>
            <xsl:for-each select="rest/documentMailbox/@value">
              <xsl:value-of select="concat('Mailbox: ', .)"/>
            </xsl:for-each>
            <table class="grid">
              <thead>
                <tr>
                  <th>Mode</th>
                  <th>Profile</th>
                  <th>Notes</th>
                </tr>
              </thead>
              <tbody>
                <xsl:for-each select="document">
                  <tr>
                    <td>
                      <xsl:value-of select="mode/@value"/>
                    </td>
                    <td>
                      <xsl:for-each select="profile/@value">
                        <a href="{.}">
                          <xsl:value-of select="."/>
                        </a>
                      </xsl:for-each>
                    </td>
                    <td>
                      <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
                    </td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
          </xsl:if>
        </div>
      </text>
      <xsl:copy-of select="node()[not(self::text)]"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template name="doParams" as="element(xhtml:table)">
    <xsl:variable name="doConformance" as="xs:boolean" select="exists(*[self::searchParam or self::parameter]/extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']/valueCode/@value)"/>
    <table class="list">
      <thead>
        <tr>
          <th>Parameter</th>
          <xsl:if test="$doConformance">
            <th>Conformance</th>
          </xsl:if>
          <th>Type</th>
          <th>Definition &amp; Chaining</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="searchParam|parameter">
          <tr>
            <th>
              <xsl:choose>
                <xsl:when test="definition/@value">
                  <a href="{definition/@value}">
                    <xsl:value-of select="name/@value"/>
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@name"/>
                </xsl:otherwise>
              </xsl:choose>
            </th>
            <xsl:if test="$doConformance">
              <td>
                <xsl:value-of select="extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']/valueCode/@value"/>
              </td>
            </xsl:if>
            <td>
              <xsl:value-of select="type/@value"/>
              <xsl:if test="target/@value">
                <xsl:value-of select="concat(' (', string-join(target/@value, ', '), ')')"/>
              </xsl:if>
            </td>
            <td>
              <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
              <xsl:if test="chain/@value">
                <xsl:value-of select="concat('Chaining: ', string-join(chain/@value, ', '))"/>
              </xsl:if>
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>
  <xsl:template match="interaction">
    <tr>
      <td>
        <a id="{ancestor::resource/type/@value}-{code/@value}"/>
        <b>
          <xsl:value-of select="code/@value"/>
          <xsl:for-each select="extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']/valueCode/@value">
            <xsl:value-of select="concat('(', ., ')')"/>
          </xsl:for-each>
        </b>
      </td>
      <td>
        <xsl:copy-of select="fn:handleMarkdownLines(documentation/@value)"/>
      </td>
    </tr>
  </xsl:template>
  <xsl:template name="doConformance" as="node()">
    <xsl:variable name="documentation" as="xs:string">
      <xsl:copy-of select="fn:handleMarkdown(documentation/@value)"/>
    </xsl:variable>
    <xsl:variable name="value" as="xs:string">
      <xsl:choose>
        <xsl:when test="extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']">
          <xsl:value-of select="extension[@url='http://hl7.org/fhir/Profile/conformance-common#expectation']/valueCode/@value"/>
        </xsl:when>
        <xsl:otherwise>Yes</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space($documentation)=''">
        <xsl:value-of select="$value"/>
      </xsl:when>
      <xsl:otherwise>
        <a title="{$documentation}" href="#{ancestor::resource/type/@value}-{code/@value}">
          <xsl:value-of select="$value"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:function name="fn:handleMarkdownLines" as="item()*">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:variable name="lines" as="element(xhtml:lines)">
      <lines>
        <xsl:for-each select="tokenize($string, '&lt;br/&gt;')">
          <xsl:choose>
            <xsl:when test="starts-with(normalize-space(.), '*')">
              <bulletLine>
                <xsl:value-of select="substring-after(., '*')"/>
              </bulletLine>
            </xsl:when>
            <xsl:when test="starts-with(normalize-space(.), '#')">
              <numberLine>
                <xsl:value-of select="substring-after(., '#')"/>
              </numberLine>
            </xsl:when>
            <!-- Could support indent, but not going to bother for now -->
            <xsl:otherwise>
              <line>
                <xsl:copy-of select="."/>
              </line>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </lines>
    </xsl:variable>
    <xsl:apply-templates mode="processLines" select="$lines/*[1]"/>
  </xsl:function>
  <xsl:template mode="processLines" match="*" as="item()*">
    <xsl:variable name="position" select="position()"/>
    <xsl:variable name="lines" as="element(xhtml:lines)+">
      <xsl:variable name="sameLines" as="element()*">
        <xsl:apply-templates mode="sameLines" select="following-sibling::*[1]">
          <xsl:with-param name="name" select="local-name(.)"/>
        </xsl:apply-templates>
      </xsl:variable>
      <lines>
        <xsl:copy-of select="."/>
      </lines>
      <xsl:apply-templates mode="processLines" select="following-sibling::*[$position + count($sameLines)+1]"/>
    </xsl:variable>
    <xsl:for-each select="$lines">
      <xsl:choose>
        <xsl:when test="xhtml:bulletLine">
          <ul>
            <xsl:for-each select="xhtml:bulletLine">
              <li>
                <xsl:copy-of select="fn:handleMarkdown(.)"/>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:when test="xhtml:numberLine">
          <ol>
            <xsl:for-each select="xhtml:numberLine">
              <li>
                <xsl:copy-of select="fn:handleMarkdown(.)"/>
              </li>
            </xsl:for-each>
          </ol>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="*">
            <p>
              <xsl:copy-of select="fn:handleMarkdown(.)"/>
            </p>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <xsl:template mode="sameLines" match="*" as="element()+">
    <xsl:param name="name" as="xs:string"/>
    <xsl:if test="local-name(.)=$name">
      <xsl:copy-of select="."/>
      <xsl:apply-templates mode="sameLines" select="following-sibling::*[1]">
        <xsl:with-param name="name" select="$name"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>
  <xsl:variable name="BOLD" select="''''''''"/>
  <xsl:variable name="ITALIC" select="''''''"/>
  <xsl:variable name="H5" select="'====='"/>
  <xsl:variable name="H4" select="'===='"/>
  <xsl:variable name="H3" select="'==='"/>
  <xsl:variable name="H2" select="'=='"/>
  <xsl:variable name="H1" select="'='"/>
  <xsl:variable name="WEIRD" select="'zQQzzQQz'"/>
  <xsl:function name="fn:handleMarkdown" as="item()*">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="not($string)"/>
      <xsl:when test="fn:splitable($string, $BOLD)">
        <xsl:copy-of select="fn:split($string, $BOLD, 'b')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $ITALIC)">
        <xsl:copy-of select="fn:split($string, $ITALIC, 'i')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $H5)">
        <xsl:copy-of select="fn:split($string, $H5, 'h7')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $H4)">
        <xsl:copy-of select="fn:split($string, $H4, 'h6')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $H3)">
        <xsl:copy-of select="fn:split($string, $H3, 'h5')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $H2)">
        <xsl:copy-of select="fn:split($string, $H2, 'h4')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, $H1)">
        <xsl:copy-of select="fn:split($string, $H1, 'h3')"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, '[[Image:', ']]')">
        <xsl:variable name="parts" select="fn:separate($string, '[[Image:', ']]')"/>
        <xsl:copy-of select="fn:handleMarkdown($parts[1])"/>
        <xsl:variable name="imageParts" as="xs:string+" select="tokenize($parts[2], '\|')"/>
        <xsl:variable name="src" as="xs:string" select="$imageParts[1]"/>
        <xsl:variable name="alt" as="xs:string?" select="$imageParts[position()&gt;1][last()]"/>
        <img alt="{$alt}" src="{$src}"/>
        <xsl:copy-of select="fn:handleMarkdown($parts[3])"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, '[[', ']]')">
        <xsl:variable name="parts" as="xs:string+" select="fn:separate($string, '[[', ']]')"/>
        <xsl:copy-of select="fn:handleMarkdown($parts[1])"/>
        <xsl:variable name="linkParts" as="xs:string+" select="tokenize($parts[2], '\|')"/>
        <xsl:variable name="linkBase" as="xs:string" select="$linkParts[1]"/>
        <xsl:variable name="linkExt" as="xs:string?" select="if (ends-with($linkBase, '.html') or contains($linkBase, '#')) then '' else '.html'"/>
        <xsl:variable name="name" as="xs:string?" select="$linkParts[2]"/>
        <a href="{lower-case($linkBase)}{$linkExt}">
          <xsl:value-of select="if ($name) then $name else $linkBase"/>
        </a>
        <xsl:copy-of select="fn:handleMarkdown($parts[3])"/>
      </xsl:when>
      <xsl:when test="fn:splitable($string, '[', ']')">
        <xsl:variable name="parts" select="fn:separate($string, '[', ']')"/>
        <xsl:copy-of select="fn:handleMarkdown($parts[1])"/>
        <xsl:variable name="linkParts" as="xs:string+" select="tokenize($parts[2], ' ')"/>
        <xsl:variable name="linkBase" as="xs:string" select="$linkParts[1]"/>
        <xsl:variable name="name" as="xs:string?" select="string-join($linkParts[position()&gt;1], ' ')"/>
        <a href="{$linkBase}">
          <xsl:value-of select="if ($name) then $name else $linkBase"/>
        </a>
        <xsl:copy-of select="fn:handleMarkdown($parts[3])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="fn:splitable" as="xs:boolean">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="split" as="xs:string"/>
    <xsl:value-of select="fn:splitable($string, $split, $split)"/>
  </xsl:function>
  <xsl:function name="fn:splitable" as="xs:boolean">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="start" as="xs:string"/>
    <xsl:param name="end" as="xs:string"/>
    <xsl:value-of select="matches($string, fn:regex($start, $end))"/>
  </xsl:function>
  <xsl:function name="fn:regex" as="xs:string">
    <xsl:param name="start" as="xs:string"/>
    <xsl:param name="end" as="xs:string"/>
    <xsl:value-of select="concat('(.*[^\\])?', replace($start, '([\[\]\\])', '\\$1'), '(.*[^\\])', replace($end, '([\[\]\\])', '\\$1'), '(.*)')"/>
  </xsl:function>
  <xsl:function name="fn:separate" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="start" as="xs:string"/>
    <xsl:param name="end" as="xs:string"/>
    <xsl:variable name="fixedString" as="xs:string" select="replace($string, fn:regex($start, $end), concat('$1', $WEIRD, '$3'))"/>
    <xsl:variable name="before" as="xs:string" select="substring-before($fixedString, $WEIRD)"/>
    <xsl:variable name="after" as="xs:string" select="substring-after($fixedString, $WEIRD)"/>
    <xsl:variable name="middle" as="xs:string" select="substring-before(substring-after($string, concat($before, $start)), concat($end, $after))"/>
    <xsl:copy-of select="$before"/>
    <xsl:copy-of select="$middle"/>
    <xsl:copy-of select="$after"/>
  </xsl:function>
  <xsl:function name="fn:split" as="item()+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="split" as="xs:string"/>
    <xsl:param name="element" as="xs:string"/>
    <xsl:variable name="parts" as="xs:string+" select="fn:separate($string, $split, $split)"/>
    <xsl:copy-of select="fn:handleMarkdown($parts[1])"/>
    <xsl:element name="{$element}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="fn:handleMarkdown($parts[2])"/>
    </xsl:element>
    <xsl:copy-of select="fn:handleMarkdown($parts[3])"/>
  </xsl:function>
</xsl:stylesheet>