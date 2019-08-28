require "spec_helper"

RSpec.describe IsoDoc::NIST do

  it "processes default metadata" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title language="en" format="plain" type="main">Main Title</title>
  <title language="en" format="plain" type="short-title">Short Main Title</title>
  <title language="en" format="plain" type="subtitle">Subtitle</title>
  <title language="en" format="plain" type="short-subtitle">Short Subtitle</title>
  <title language="en" format="plain" type="document-class">Information Security</title>
  <docidentifier type="NIST">1000(wd) (January 2007)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <date type="confirmed">
  <on>2005-01-01</on>
  </date>
  <date type="superseded">
  <on>2005-01-01</on>
  </date>
  <date type="abandoned">
  <on>2005-01-01</on>
  </date>
  <date type="issued">
  <on>2004-01-01</on>
  </date>
  <date type="obsoleted">
  <on>1000-01-01</on>
  </date>
  <edition>Revision 2</edition>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
<note type="additional-note" id="_eb262240-a5ce-4b3e-ae7d-f04153ace1db">Additional Note</note>
<note type="withdrawal-note" id="_eb262240-a5ce-4b3e-ae7d-f04153ace1dc">Withdrawal Note</note>
<note type="withdrawal-annoncement-link" id="_eb262240-a5ce-4b3e-ae7d-f04153ace1dd">Withdrawal Link</note>
  <contributor>
    <role type="author"/>
    <organization>
      <name>Acme</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>Acme</name>
      <subdivision>Ministry of Silly Walks</subdivision>
    </organization>
  </contributor>
  <contributor>
    <role type="editor"/>
    <person>
    <name>
    <forename>Barney</forename>
      <surname>Rubble</surname>
      </name>
      <affiliation>
      <organization><name>Bedrock Inc.</name>
      <address>
      <formattedAddress>Bedrock</formattedAddress>
      </address>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="author"/>
    <person>
    <name>
      <completename>Fred Flintstone</completename>
      </name>
    </person>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>draft-wip</stage>
    <substage>withdrawn</substage>
    <iteration>3</iteration>
  </status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>Acme</name>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <technical-committee type="A">TC</committee>
  </editorialgroup>
  <uri type="uri">http://www.example.com</uri>
  <uri type="doi">http://www.example2.com</uri>
  <uri type="email">email@example.com</uri>
  <relation type="obsoletes">
  <bibitem>
    <docidentifier>NIST SP 800</docidentifier>
  </bibitem>
</relation>
<relation type="obsoletes">
  <bibitem>
    <docidentifier>NIST SP 800-53A Rev. 1</docidentifier>
  </bibitem>
</relation>
<relation type="obsoletedBy">
  <bibitem>
    <title type="main">Superseding Title</title>
    <title type="subtitle">Superseding Subtitle</title>
    <uri type="doi">http://doi.org/1</uri>
    <uri type="uri">http://example.org/1</uri>
    <docidentifier type="NIST">NIST FIPS 1000 Volume 5, Revision 3</docidentifier>
    <docidentifier type="nist-long">NIST Federal Information Processing Standards 1000 Volume 5, Revision 3</docidentifier>
    <contributor>
      <role type="author"/>
      <person>
        <name>
          <completename>Fred Nerk</completename>
        </name>
      </person>
    </contributor>
    <contributor>
      <role type="author"/>
      <person>
        <name>
          <completename>Joe Bloggs</completename>
        </name>
      </person>
    </contributor>
    <date type="circulated"><on>2030-01-01</on></date>
    <date type="issued"><on>2031-01-01</on></date>
    <date type="updated"><on>2032-01-01</on></date>
    <status>
      <stage>draft-public</stage>
      <iteration>final</iteration>
    </status>
  </bibitem>
</relation>
<relation type="obsoletedBy">
  <bibitem>
    <docidentifier>NIST SP 800-53A Rev. 1</docidentifier>
  </bibitem>
</relation>
<relation type="supersedes">
  <bibitem>
    <docidentifier>NIST SP 800-53A Rev. 1</docidentifier>
  </bibitem>
</relation>
<relation type="supersededBy">
  <bibitem>
    <docidentifier>NIST SP 800-53A Rev. 1</docidentifier>
  </bibitem>
</relation>
  <series type="main"><title>NIST Federal Information Processing Standards</title>
  <abbreviation>NIST FIPS</abbreviation></series>
           <keyword>A</keyword>
         <keyword>B</keyword>
  <ext>
  <doctype>standard</doctype>
         <commentperiod>
         <from>2001-01-01</from>
         <to>2001-01-02</to>
         <extended>2001-01-03</extended>
         </commentperiod>
         </ext>
</bibdata>
<sections>
<errata>
  <row>
    <date>2012-01-01</date>
    <type>Major</type>
    <change>
      <em>Repaginate</em>
    </change>
    <pages>12-13</pages>
  </row>
  <row>
    <date>2012-01-02</date>
    <type>Minor</type>
    <change>Revert</change>
    <pages>9-12</pages>
  </row>
</errata>
</sections>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:abandoneddate=>"2005-01-01", :abandoneddate_MMMddyyyy=>"January 01, 2005", :abandoneddate_mmddyyyy=>"01-01-2005", :abandoneddate_monthyear=>"January 2005", :accesseddate=>"XXX", :additional_note=>"Additional Note", :authors=>["Barney Rubble", "Fred Flintstone"], :authors_affiliations=>{"Bedrock Inc., Bedrock"=>["Barney Rubble"], ""=>["Fred Flintstone"]}, :circulateddate=>"XXX", :comment_extended=>"2001-01-03", :comment_from=>"2001-01-01", :comment_to=>"2001-01-02", :confirmeddate=>"2005-01-01", :confirmeddate_MMMddyyyy=>"January 01, 2005", :confirmeddate_mmddyyyy=>"01-01-2005", :confirmeddate_monthyear=>"January 2005", :copieddate=>"XXX", :createddate=>"XXX", :docclasstitle=>"Information Security", :docidentifier=>"1000(wd) (January 2007)", :docidentifier_long=>"1000(wd) Long", :docidentifier_long_undated=>"1000(wd) Long", :docidentifier_undated=>"1000(wd)", :docnumber=>"1000", :docsubtitle=>"Subtitle", :docsubtitle_short=>"Short Subtitle", :doctitle=>"Main Title", :doctitle_short=>"Short Main Title", :doctype=>"Standard", :docyear=>"2001", :doi=>"http://www.example2.com", :draft=>"3.4", :draft_prefix=>"DRAFT (3WD) ", :draftinfo=>" draft 3.4", :edition=>"Revision 2", :email=>"email@example.com", :errata=>true, :implementeddate=>"XXX", :issueddate=>"2004-01-01", :issueddate_MMMddyyyy=>"January 01, 2004", :issueddate_mmddyyyy=>"01-01-2004", :issueddate_monthyear=>"January 2004", :iteration=>"3", :iteration_code=>"3WD", :iteration_ordinal=>"third", :keywords=>["A", "B"], :most_recent_date_MMMddyyyy=>"January 01, 2000", :most_recent_date_mmddyyyy=>"01-01-2000", :most_recent_date_monthyear=>"January 2000", :nist_subdiv=>"Ministry of Silly Walks", :obsoletedby=>["NIST FIPS 1000 Volume 5, Revision 3", "NIST SP 800-53A Rev. 1"], :obsoleteddate=>"1000-01-01", :obsoleteddate_MMMddyyyy=>"January 01, 1000", :obsoleteddate_mmddyyyy=>"01-01-1000", :obsoleteddate_monthyear=>"January 1000", :obsoletes=>["NIST SP 800", "NIST SP 800-53A Rev. 1"], :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_MMMddyyyy=>"January 01, 2000", :revdate_monthyear=>"January 2000", :revision=>"2", :series=>"NIST Federal Information Processing Standards", :status=>"Work-in-Progress Draft", :substage=>"withdrawn", :supersededby=>["NIST SP 800-53A Rev. 1"], :supersededdate=>"2005-01-01", :supersededdate_MMMddyyyy=>"January 01, 2005", :supersededdate_mmddyyyy=>"01-01-2005", :supersededdate_monthyear=>"January 2005", :supersedes=>["NIST SP 800-53A Rev. 1"], :superseding_authors=>["Fred Nerk", "Joe Bloggs"], :superseding_circulated_date=>"2030-01-01", :superseding_circulated_date_monthyear=>"January 2030", :superseding_docidentifier=>"NIST FIPS 1000 Volume 5, Revision 3", :superseding_docidentifier_long=>"NIST Federal Information Processing Standards 1000 Volume 5, Revision 3", :superseding_doi=>"http://doi.org/1", :superseding_issued_date=>"2031-01-01", :superseding_issued_date_monthyear=>"January 2031", :superseding_iteration_code=>"FPD", :superseding_iteration_ordinal=>"Final", :superseding_status=>"Public Draft", :superseding_subtitle=>"Superseding Subtitle", :superseding_title=>"Superseding Title", :superseding_updated_date=>"2032-01-01", :superseding_updated_date_MMMddyyyy=>"January 01, 2032", :superseding_updated_date_monthyear=>"January 2032", :superseding_uri=>"http://example.org/1", :transmitteddate=>"XXX", :unchangeddate=>"XXX", :unpublished=>true, :updateddate=>"XXX", :url=>"http://www.example.com", :withdrawal_note=>"Withdrawal Note"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

  it "processes initial public draft; gives default values for short titles; withdrawal pending; default superseding title" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title type="main" language="en" format="plain">Main Title</title>
  <title type="subtitle" language="en" format="plain">Subtitle</title>
  <docidentifier type="NIST">1000(wd)</docidentifier>
  <docnumber>1000</docnumber>
  <date type="obsoleted">
  <on>3000-01-01</on>
  </date>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <contributor>
    <role type="author"/>
    <person>
      <name><completename>Fred Nurk</completename></name>
    </person>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>draft-public</stage>
    <substage>active</substage>
    <iteration>1</iteration>
  </status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>Acme</name>
      </organization>
    </owner>
  </copyright>
  <relation type="obsoletedBy">
  <bibitem>
    <docidentifier>NIST SP 800-53A Rev. 1</docidentifier>
  </bibitem>
</relation>
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>["Fred Nurk"], :authors_affiliations=>{""=>["Fred Nurk"]}, :circulateddate=>"XXX", :confirmeddate=>"XXX", :copieddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>nil, :docidentifier_long_undated=>nil, :docidentifier_undated=>"1000(wd)", :docnumber=>"1000", :docsubtitle=>"Subtitle", :docsubtitle_short=>"Subtitle", :doctitle=>"Main Title", :doctitle_short=>"Main Title", :docyear=>"2001", :draft=>"3.4", :draft_prefix=>"DRAFT (IPD) ", :draftinfo=>" draft 3.4", :edition=>nil, :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"1", :iteration_code=>"IPD", :iteration_ordinal=>"Initial", :keywords=>[], :most_recent_date_MMMddyyyy=>"January 01, 2000", :most_recent_date_mmddyyyy=>"01-01-2000", :most_recent_date_monthyear=>"January 2000", :obsoletedby=>["NIST SP 800-53A Rev. 1"], :obsoleteddate=>"3000-01-01", :obsoleteddate_MMMddyyyy=>"January 01, 3000", :obsoleteddate_mmddyyyy=>"01-01-3000", :obsoleteddate_monthyear=>"January 3000", :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_MMMddyyyy=>"January 01, 2000", :revdate_monthyear=>"January 2000", :status=>"Public Draft", :substage=>"active", :superseding_authors=>["Fred Nurk"], :superseding_status=>"Final", :superseding_subtitle=>"Subtitle", :superseding_title=>"Main Title", :transmitteddate=>"XXX", :unchangeddate=>"XXX", :unpublished=>true, :updateddate=>"XXX", :withdrawal_pending=>true}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

    it "processes second public draft" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title type="main" language="en" format="plain">Main Title</title>
  <docidentifier type="NIST">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>draft-public</stage>
    <substage>active</substage>
    <iteration>2</iteration>
  </status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>Acme</name>
      </organization>
    </owner>
  </copyright>
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :circulateddate=>"XXX", :confirmeddate=>"XXX", :copieddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"1000(wd) Long", :docidentifier_long_undated=>"1000(wd) Long", :docidentifier_undated=>"1000(wd)", :docnumber=>"1000", :doctitle=>"Main Title", :doctitle_short=>"Main Title", :docyear=>"2001", :draft=>"3.4", :draft_prefix=>"DRAFT (2PD) ", :draftinfo=>" draft 3.4", :edition=>nil, :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"2", :iteration_code=>"2PD", :iteration_ordinal=>"second", :keywords=>[], :most_recent_date_MMMddyyyy=>"January 01, 2000", :most_recent_date_mmddyyyy=>"01-01-2000", :most_recent_date_monthyear=>"January 2000", :obsoleteddate=>"XXX", :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_MMMddyyyy=>"January 01, 2000", :revdate_monthyear=>"January 2000", :status=>"Public Draft", :substage=>"active", :transmitteddate=>"XXX", :unchangeddate=>"XXX", :unpublished=>true, :updateddate=>"XXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

  it "processes final public draft" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title type="main" language="en" format="plain">Main Title</title>
  <docidentifier type="NIST">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>draft-public</stage>
    <substage>active</substage>
    <iteration>final</iteration>
  </status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>Acme</name>
      </organization>
    </owner>
  </copyright>
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :circulateddate=>"XXX", :confirmeddate=>"XXX", :copieddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"1000(wd) Long", :docidentifier_long_undated=>"1000(wd) Long", :docidentifier_undated=>"1000(wd)", :docnumber=>"1000", :doctitle=>"Main Title", :doctitle_short=>"Main Title", :docyear=>"2001", :draft=>"3.4", :draft_prefix=>"DRAFT (FPD) ", :draftinfo=>" draft 3.4", :edition=>nil, :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"final", :iteration_code=>"FPD", :iteration_ordinal=>"Final", :keywords=>[], :most_recent_date_MMMddyyyy=>"January 01, 2000", :most_recent_date_mmddyyyy=>"01-01-2000", :most_recent_date_monthyear=>"January 2000", :obsoleteddate=>"XXX", :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_MMMddyyyy=>"January 01, 2000", :revdate_monthyear=>"January 2000", :status=>"Public Draft", :substage=>"active", :transmitteddate=>"XXX", :unchangeddate=>"XXX", :unpublished=>true, :updateddate=>"XXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

  it "processes published" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title type="main" language="en" format="plain">Main Title</title>
  <docidentifier type="NIST">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>final</stage>
  </status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>Acme</name>
      </organization>
    </owner>
  </copyright>
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :circulateddate=>"XXX", :confirmeddate=>"XXX", :copieddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"1000(wd) Long", :docidentifier_long_undated=>"1000(wd) Long", :docidentifier_undated=>"1000(wd)", :docnumber=>"1000", :doctitle=>"Main Title", :doctitle_short=>"Main Title", :docyear=>"2001", :draft=>"3.4", :draftinfo=>" draft 3.4", :edition=>nil, :implementeddate=>"XXX", :issueddate=>"XXX", :keywords=>[], :obsoleteddate=>"XXX", :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_MMMddyyyy=>"January 01, 2000", :revdate_monthyear=>"January 2000", :status=>"Final", :transmitteddate=>"XXX", :unchangeddate=>"XXX", :unpublished=>false, :updateddate=>"XXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end



  it "processes pre" do
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<preface><foreword>
<pre>ABC</pre>
</foreword></preface>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    #{HTML_HDR}
             <div>
               <h1 class="ForewordTitle"/>
               <pre>ABC</pre>
             </div>
           </div>
         </body>
    OUTPUT

    expect(
      IsoDoc::NIST::HtmlConvert.new({}).
      convert("test", input, true).
      gsub(%r{^.*<body}m, "<body").
      gsub(%r{</body>.*}m, "</body>")
    ).to be_equivalent_to output
  end

  it "processes keyword" do
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<preface><foreword>
<keyword>ABC</keyword>
</foreword></preface>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    #{HTML_HDR}
             <div>
               <h1 class="ForewordTitle"/>
               <span class="keyword">ABC</span>
             </div>
           </div>
         </body>
    OUTPUT

    expect(
      IsoDoc::NIST::HtmlConvert.new({}).
      convert("test", input, true).
      gsub(%r{^.*<body}m, "<body").
      gsub(%r{</body>.*}m, "</body>")
    ).to be_equivalent_to output
  end

  it "processes pseudocode" do
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<preface><foreword>
<figure id="1" type="pseudocode">
<name>First figure</name>
<ol>
<li>A B C
<ol><li>D</li>
<li>E</li>
</ol>
</li>
</ol>
</figure>
</foreword></preface>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    #{HTML_HDR}
             <div>
               <h1 class="ForewordTitle"/>
               <div id="1" class="pseudocode">
       <ol type="a">
       <li>A B C
       <ol type="1"><li>D</li>
       <li>E</li>
       </ol>
       </li>
       </ol>
       <p class="FigureTitle" style="text-align:center;">Figure 1&#160;&#8212; First figure</p>
       </div>
       </div>
           </div>
         </body>
    OUTPUT

    expect(
      IsoDoc::NIST::HtmlConvert.new({}).
      convert("test", input, true).
      gsub(%r{^.*<body}m, "<body").
      gsub(%r{</body>.*}m, "</body>")
    ).to be_equivalent_to output
  end

  it "processes nistvariable tag" do 
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<preface><foreword>
<sourcecode id="_">&lt;xccdf:check system="<nistvariable>http://oval.mitre.org/XMLSchema/oval-definitions-5</nistvariable>"&gt;</sourcecode>
</foreword></preface>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    #{HTML_HDR}
             <div>
               <h1 class="ForewordTitle"/>
               <pre id="_" class="prettyprint ">&lt;xccdf:check system="<span class="nistvariable">http://oval.mitre.org/XMLSchema/oval-definitions-5</span>"&gt;</pre>
       </div>
           </div>
         </body>
    OUTPUT

    expect(
      IsoDoc::NIST::HtmlConvert.new({}).
      convert("test", input, true).
      gsub(%r{^.*<body}m, "<body").
      gsub(%r{</body>.*}m, "</body>")
    ).to be_equivalent_to output
  end

  it "processes boilerplate" do
      IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", false)
    <nist-standard xmlns="https://open.ribose.com/standards/example">
    <boilerplate>
    <legal-statement>
    <clause id="authority1">
       <title>Authority</title>

       <p id="_">This publication has been developed by NIST in accordance with its statutory responsibilities under the Federal Information Security Modernization Act (FISMA) of 2014, 44 U.S.C. § 3551 <em>et seq.</em>, Public Law (P.L.) 113-283. NIST is responsible for develoo
ping information security standards and guidelines, including minimum requirements for federal information systems, but such standards and guidelines shall not apply to national security systems without the express approval of appropriate federal officials exercising policy authority over such systems. This guideline is consistent with the requirements of the Office of Management and Budget (OMB) Circular A-130.</p>

       <p id="_">Nothing in this publication should be taken to contradict the standards and guidelines made mandatory and binding on federal agencies by the Secretary of Commerce under statutory authority. Nor should these guidelines be interpreted as altering or superseding the existing authorities of the Secretary of Commerce, Director of the OMB, or any other federal official. This publication may be used by nongovernmental organizations on a voluntary basis and is not subject to copyright in the United States. Attribution would, however, be appreciated by NIST.</p>
       </clause>

       <clause id="authority2">
       <p align="center" id="_">National Institute of Standards and Technology ABC <br/>
       Natl. Inst. Stand. Technol. ABC, () <br/>
       CODEN: NSPUE2</p>


       <p align="center" id="_">This publication is available free of charge from: <br/>
         <link target="http://www.example.com"/></p>

       </clause>

       <clause id="authority3">
       <p id="_">Any mention of commercial products or reference to commercial organizations is for information only; it does not imply recommendation or endorsement by the United States Government, nor does it imply that the products mentioned are necessarily the best available for the purpose.</p>

       <p id="_">There may be references in this publication to other publications currently under development by NIST in accordance with its assigned statutory responsibilities. The information in this publication, including concepts and methodologies, may be used by Federal agencies even before the completion of such companion publications. Thus, until each publication is completed, current requirements, guidelines, and procedures, where they exist, remain operative. For planning and transition purposes, Federal agencies may wish to closely follow the development of these new publications by NIST.</p>

       <p id="_">Organizations are encouraged to review all draft publications during public comment periods and provide feedback to NIST. Many NIST cybersecurity publications, other than the ones noted above, are available at <link target="https://csrc.nist.gov/publications"/>
       </p></clause>
       </legal-statement>

       <feedback-statement>
       <clause id="authority4">

       <p align="center" id="_">[2010-01-03: Comment period extended]</p>



       <p align="center" id="_"><strong>Public comment period: <em>2010-01-01</em> through <em>2010-01-02</em></strong></p>

       </clause>

       <clause id="authority5">
       <title>Comments on this publication may be submitted to:</title>

       <p align="center" id="_">National Institute of Standards and Technology <br/>
       Attn: Computer Security Division, Information Technology Laboratory <br/>
       100 Bureau Drive (Mail Stop 8930) Gaithersburg, MD 20899-8930 <br/>
       Email: <link target="mailto:email@example.com"/></p>

       <p align="center" id="_">All comments are subject to release under the Freedom of Information Act (FOIA).</p>
       </clause>
       </feedback-statement>
       </boilerplate>
       <preface/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
             <div class="authority">

              <div id="authority1" class="authority1">
              <h2 class="IntroTitle">Authority</h2>
              <p id="_">This publication has been developed by NIST in accordance with its statutory responsibilities under the Federal Information Security Modernization Act (FISMA) of 2014, 44 U.S.C. &#167; 3551 <i>et seq.</i>, Public Law (P.L.) 113-283. NIST is responsible for develoo
       ping information security standards and guidelines, including minimum requirements for federal information systems, but such standards and guidelines shall not apply to national security systems without the express approval of appropriate federal officials exercising policy authority over such systems. This guideline is consistent with the requirements of the Office of Management and Budget (OMB) Circular A-130.</p>

              <p id="_">Nothing in this publication should be taken to contradict the standards and guidelines made mandatory and binding on federal agencies by the Secretary of Commerce under statutory authority. Nor should these guidelines be interpreted as altering or superseding the existing authorities of the Secretary of Commerce, Director of the OMB, or any other federal official. This publication may be used by nongovernmental organizations on a voluntary basis and is not subject to copyright in the United States. Attribution would, however, be appreciated by NIST.</p>
              </div>

              <div id="authority2" class="authority2"><h2 class="IntroTitle"/>
              <p id="_" style="text-align:center;">National Institute of Standards and Technology ABC <br/>
              Natl. Inst. Stand. Technol. ABC, () <br/>
              CODEN: NSPUE2</p>


              <p id="_" style="text-align:center;">This publication is available free of charge from: <br/>
                <a href="http://www.example.com">http://www.example.com</a></p>

              </div>

              <div id="authority3" class="authority3"><h2 class="IntroTitle"/>
              <p id="_">Any mention of commercial products or reference to commercial organizations is for information only; it does not imply recommendation or endorsement by the United States Government, nor does it imply that the products mentioned are necessarily the best available for the purpose.</p>

              <p id="_">There may be references in this publication to other publications currently under development by NIST in accordance with its assigned statutory responsibilities. The information in this publication, including concepts and methodologies, may be used by Federal agencies even before the completion of such companion publications. Thus, until each publication is completed, current requirements, guidelines, and procedures, where they exist, remain operative. For planning and transition purposes, Federal agencies may wish to closely follow the development of these new publications by NIST.</p>

              <p id="_">Organizations are encouraged to review all draft publications during public comment periods and provide feedback to NIST. Many NIST cybersecurity publications, other than the ones noted above, are available at <a href="https://csrc.nist.gov/publications">https://csrc.nist.gov/publications</a>
              </p></div>

              <div id="authority4" class="authority4"><h2 class="IntroTitle"/>

              <p id="_" style="text-align:center;">[2010-01-03: Comment period extended]</p>



              <p id="_" style="text-align:center;"><b>Public comment period: <i>2010-01-01</i> through <i>2010-01-02</i></b></p>

              </div>

              <div id="authority5" class="authority5">
              <h2 class="IntroTitle">Comments on this publication may be submitted to:</h2>

              <p id="_" style="text-align:center;">National Institute of Standards and Technology <br/>
              Attn: Computer Security Division, Information Technology Laboratory <br/>
              100 Bureau Drive (Mail Stop 8930) Gaithersburg, MD 20899-8930 <br/>
              Email: <a href="mailto:email@example.com">email@example.com</a></p>

              <p id="_" style="text-align:center;">All comments are subject to release under the Freedom of Information Act (FOIA).</p>
              </div>
              </div>
    OUTPUT

      expect(File.exist?("test.html")).to be true
  html = File.read("test.html", encoding: "utf-8").sub(/^.*<div class="authority">/m, '<div class="authority">').sub(/<nav>.*$/m, "")

    expect(html).to be_equivalent_to output
  end


it "processes errata tag" do
  input = <<~"INPUT"
    <nist-standard xmlns="https://open.ribose.com/standards/example">
<preface><foreword>
    <errata>
  <row>
    <date>2012-01-01</date>
    <type>Major</type>
    <change>
      <em>Repaginate</em>
    </change>
    <pages>12-13</pages>
  </row>
  <row>
    <date>2012-01-02</date>
    <type>Minor</type>
    <change>Revert</change>
    <pages>9-12</pages>
  </row>
</errata>
</foreword></preface>
</nist-standard>
  INPUT
  output = <<~"OUTPUT"
  #{HTML_HDR}
             <div>
               <h1 class="ForewordTitle"/>
               <a name="errata_XYZZY"/>
               <table class="MsoISOTable" style="border-width:1px;border-spacing:0;">
                 <thead>
                   <tr>
                     <th>Date</th>
                     <th>Type</th>
                     <th>Change</th>
                     <th>Pages</th>
                   </tr>
                 </thead>
                 <tbody>
                   <tr>
                     <td>2012-01-01</td>
                     <td>Major</td>
                     <td><i>Repaginate</i></td>
                     <td>12-13</td>
                   </tr>
                   <tr>
                     <td>2012-01-02</td>
                     <td>Minor</td>
                     <td>Revert</td>
                     <td>9-12</td>
                   </tr>
                 </tbody>
               </table>
             </div>
           </div>
         </body>
  OUTPUT

  expect(
    IsoDoc::NIST::HtmlConvert.new({}).
    convert("test", input, true).
    gsub(%r{^.*<body}m, "<body").
    gsub(%r{</body>.*}m, "</body>")
  ).to be_equivalent_to output
end

it "processes glossaries" do
  FileUtils.rm_f "test.html"

  IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", false)
    <nist-standard xmlns="https://open.ribose.com/standards/example">
    <annex id="_32d7b4db-f3fb-4a11-a418-74f365b96d4b" obligation="normative">
  <title>Glossary</title>
    <terms id="_normal_terms_2" obligation="normative">
  <title>Normal Terms 2</title>
  <term id="_normal_terms"><preferred>Normal Terms</preferred><definition><p id="_4883de72-6054-4227-a111-b8966759b0f6">Definition</p></definition>
<termexample id="_f22bc30c-a5a6-45ae-8bea-0792d7109470">
  <p id="_16555fc3-3570-4b16-8fff-ac95941b62b1">Example</p>
</termexample></term>
  <term id="other_terms"><preferred>Other Terms</preferred><definition><p id="_4883de72-6054-4227-a111-b8966759b0f7">Definition</p></definition>
<termnote id="_f22bc30c-a5a6-45ae-8bea-0792d7109471">
  <p id="_16555fc3-3570-4b16-8fff-ac95941b62b2">Example</p>
</termnote></term>
</terms>
</annex>
</nist-standard>
  INPUT

  output = <<~"OUTPUT"
         <main class="main-section"><button onclick="topFunction()" id="myBtn" title="Go to top">Top</button>
             <br />
             <div id="_32d7b4db-f3fb-4a11-a418-74f365b96d4b" class="Section3">
               <h1 class="Annex"><b>Appendix A</b> &#x2014; <b>Glossary</b></h1>
               <div id="_normal_terms_2"><h1>A. Normal Terms 2</h1>
         <dl class="terms_dl"><dt>Normal Terms</dt><dd><p id="_4883de72-6054-4227-a111-b8966759b0f6">Definition</p>
       <div id="_f22bc30c-a5a6-45ae-8bea-0792d7109470" class="example"><p class="example-title">EXAMPLE</p>
         <p id="_16555fc3-3570-4b16-8fff-ac95941b62b1">Example</p>
       </div></dd></dl><dl class="terms_dl"><dt>Other Terms</dt><dd><p id="_4883de72-6054-4227-a111-b8966759b0f7">Definition</p>
       <div class="Note"><p>Note 1 to entry: Example</p></div></dd></dl>
       </div>
             </div>
           </main>
  OUTPUT

  expect(File.exist?("test.html")).to be true
  html = File.read("test.html", encoding: "utf-8").sub(/^.*<main /m, "<main ").sub(/<\/main>.*$/m, "</main>")
  expect(html).to be_equivalent_to output

end

it "processes appendix bibliographies" do
  FileUtils.rm_f "test.html"
  IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", false)
    <nist-standard xmlns="http://riboseinc.com/isoxml">
   <sections/>

         <annex id="A" obligation="normative">
         <title>First Appendix</title>
         <example id="B">
         <p id="C">Example</p>
       </example>
       </annex><annex id="D" obligation="normative">
         <title>Bibliography</title>
         <references id="E" obligation="informative"/>
       </annex><annex id="F" obligation="normative">
         <title>Second Appendix</title>
         <example id="G">
         <p id="H">Example</p>
       </example>
       </annex>
       </nist-standard>
  INPUT
  output = <<~"OUTPUT"
        <main class="main-section"><button onclick="topFunction()" id="myBtn" title="Go to top">Top</button>
      <br />
      <div id="A" class="Section3">
        <h1 class="Annex"><b>Appendix A</b> &#x2014; <b>First Appendix</b></h1>
        <div id="B" class="example"><p class="example-title">EXAMPLE</p>
      <p id="C">Example</p>
    </div>
      </div>
      <br />
      <div id="D" class="Section3">
        <h1 class="Annex"><b>Appendix B</b> &#x2014; <b>References</b></h1>
        <div>
        </div>
      </div>
      <br />
      <div id="F" class="Section3">
        <h1 class="Annex"><b>Appendix C</b> &#x2014; <b>Second Appendix</b></h1>
        <div id="G" class="example"><p class="example-title">EXAMPLE</p>
      <p id="H">Example</p>
    </div>
      </div>
    </main>
  OUTPUT

  expect(File.exist?("test.html")).to be true
  html = File.read("test.html", encoding: "utf-8").sub(/^.*<main /m, "<main ").sub(/<\/main>.*$/m, "</main>")
  expect(html).to be_equivalent_to output


end


it "processes section names" do
  input = <<~"INPUT"
    <nist-standard xmlns="http://riboseinc.com/isoxml">
      <preface>
      <abstract id="S1" obligation="informative">
         <title>Abstract</title>
         <p id="AA">This is an Abstract</p>
      </abstract>
      <foreword id="S2" obligation="informative">
         <title>Foreword</title>
         <p id="A">This is a preamble</p>
       </foreword>
        <introduction id="B" obligation="informative"><title>Introduction</title><clause id="C" inline-header="false" obligation="informative">
         <title>Introduction Subsection</title>
       </clause>
       </introduction>
      <clause id="S3" obligation="informative"><title>Acknowlegdements</title>
         <p id="AB">These are acknowledgements</p>
       </clause>
      <clause id="S4" obligation="informative"><title>Audience</title>
         <p id="AD">This are audience</p>
       </clause>
      <clause id="S5" obligation="informative"><title>Conformance Testing</title>
         <p id="AC">This is conformance testing</p>
       </clause>
      <executivesummary id="S6" obligation="informative"><title>Executive Summary</title>
         <p id="AC">This is an executive summary</p>
       </executivesummary>
        </preface><sections>
       <clause id="D" obligation="normative">
         <title>Scope</title>
         <p id="E">Text</p>
       </clause>

       <clause id="M" inline-header="false" obligation="normative"><title>Clause 4</title><clause id="N" inline-header="false" obligation="normative">
         <title>Introduction</title>
       </clause>
       <clause id="O" inline-header="false" obligation="normative">
         <title>Clause 4.2</title>
       </clause></clause>

       </sections><annex id="P" inline-header="false" obligation="normative">
         <title>Annex</title>
         <clause id="Q" inline-header="false" obligation="normative">
         <title>Annex A.1</title>
         <clause id="Q1" inline-header="false" obligation="normative">
         <title>Annex A.1a</title>
         </clause>
       </clause>
       </annex><bibliography><references id="R" obligation="informative">
         <title>Normative References</title>
       </references><clause id="S" obligation="informative">
         <title>Bibliography</title>
         <references id="T" obligation="informative">
         <title>Bibliography Subsection</title>
       </references>
       </clause>
       </bibliography>
       </nist-standard>
  INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
             <div id="S2">
               <h1 class="ForewordTitle">Foreword</h1>
               <p id="A">This is a preamble</p>
             </div>
             <div id="S1">
               <h1 class="AbstractTitle">Abstract</h1>
               <p id="AA">This is an Abstract</p>
             </div>
             <div id="B">
               <h1 class="IntroTitle">Introduction</h1>
               <div id="C"><h2>Introduction Subsection</h2>

          </div>
             </div>
             <div id="S3">
               <h1 class="IntroTitle">Acknowlegdements</h1>
               <p id="AB">These are acknowledgements</p>
             </div>
             <div id="S4">
               <h1 class="IntroTitle">Audience</h1>
               <p id="AD">This are audience</p>
             </div>
             <div id="S5">
               <h1 class="IntroTitle">Conformance Testing</h1>
               <p id="AC">This is conformance testing</p>
             </div>
             <div id="S6">
               <h1 class="NormalTitle">Executive Summary</h1>
               <p id="AC">This is an executive summary</p>
             </div>
             <div id="D">
               <h1>1.&#160; Scope</h1>
               <p id="E">Text</p>
             </div>
             <div id="M">
               <h1>2.&#160; Clause 4</h1>
               <div id="N"><h2>2.1. Introduction</h2>

          </div>
          <div id="O"><h2>2.2. Clause 4.2</h2>

          </div>
             </div>
             <br/>
             <div>
               <h1 class="Section3">Normative References</h1>
             </div>
             <div>
               <h1 class="Section3">Bibliography</h1>
               <div>
                 <h2 class="Section3">Bibliography Subsection</h2>
               </div>
             </div>
             <br/>
             <div id="P" class="Section3">
               <h1 class="Annex"><b>Appendix A</b> &#8212; <b>Annex</b></h1>
               <div id="Q"><h2>A.1. Annex A.1</h2>

            <div id="Q1"><h3>A.1.1. Annex A.1a</h3>

            </div>
          </div>
             </div>
           </div>
         </body>
  OUTPUT

  expect(
    IsoDoc::NIST::HtmlConvert.new({}).convert("test", input, true).
    gsub(%r{^.*<body}m, "<body").
    gsub(%r{</body>.*}m, "</body>")
  ).to be_equivalent_to output
end

it "skips Note to Reviewers if not draft" do
  input = <<~"INPUT"
    <nist-standard xmlns="http://riboseinc.com/isoxml">
    <bibdata type="standard">
  <status format="plain">published</status>
  </bibdata>
      <preface>
      <abstract obligation="informative">
         <title>Abstract</title>
         <p id="AA">This is an Abstract</p>
      </abstract>
      <reviewernote obligation="informative"><title>Note for Reviewers</title>
      <p>Hello reviewer</p>
      </reviewernote>
      </preface>
      </nist-standard>
  INPUT

  output = <<~"OUTPUT"
        <body lang="EN-US" link="blue" vlink="#954F72" xml:lang="EN-US" class="container">
    <div class="title-section">
      <p>&#160;</p>
    </div>
    <br/>
    <div class="prefatory-section">
      <p>&#160;</p>
    </div>
    <br/>
    <div class="main-section">
      <div>
        <h1 class="AbstractTitle">Abstract</h1>
        <p id="AA">This is an Abstract</p>
      </div>
    </div>
  </body>
  OUTPUT

  expect(
    IsoDoc::NIST::HtmlConvert.new({}).convert("test", input, true).
    gsub(%r{^.*<body}m, "<body").
    gsub(%r{</body>.*}m, "</body>")
  ).to be_equivalent_to output
end

it "renders Note to Reviewers if draft" do
  input = <<~"INPUT"
    <nist-standard xmlns="http://riboseinc.com/isoxml">
    <bibdata type="standard">
  <status><stage>public-draft</stage></status>
  </bibdata>
      <preface>
      <abstract obligation="informative">
         <title>Abstract</title>
         <p id="AA">This is an Abstract</p>
      </abstract>
      <reviewernote obligation="informative"><title>Note for Reviewers</title>
      <p>Hello reviewer</p>
      </reviewernote>
      </preface>
      </nist-standard>
  INPUT

  output = <<~"OUTPUT"
            <body lang="EN-US" link="blue" vlink="#954F72" xml:lang="EN-US" class="container">
    <div class="title-section">
      <p>&#160;</p>
    </div>
    <br/>
    <div class="prefatory-section">
      <p>&#160;</p>
    </div>
    <br/>
    <div class="main-section">
      <div>
        <h1 class="AbstractTitle">Abstract</h1>
        <p id="AA">This is an Abstract</p>
      </div>
      <div>
  <h1 class="IntroTitle">Note for Reviewers</h1>
  <p>Hello reviewer</p>
</div>
    </div>
  </body>
  OUTPUT

  expect(
    IsoDoc::NIST::HtmlConvert.new({}).convert("test", input, true).
    gsub(%r{^.*<body}m, "<body").
    gsub(%r{</body>.*}m, "</body>")
  ).to be_equivalent_to output
end

it "cross-references recommendations" do
  expect(IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", true).gsub(%r{^.*<body}m, "<body").gsub(%r{</body>.*}m, "</body>")).to be_equivalent_to <<~"OUTPUT"
        <nist-standard xmlns="http://riboseinc.com/isoxml">
        <preface>
    <foreword id="fwd">
    <p>
    <xref target="N1"/>
    <xref target="N2"/>
    <xref target="N"/>
    <xref target="note1"/>
    <xref target="note2"/>
    <xref target="AN"/>
    <xref target="Anote1"/>
    <xref target="Anote2"/>
    </p>
    </foreword>
        <introduction id="intro">
        <recommendation id="N1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
  <clause id="xyz"><title>Preparatory</title>
        <recommendation id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <recommendation id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <recommendation id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
    <recommendation id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <recommendation id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
    </clause>
    <clause id="annex1b">
        <recommendation id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
    <recommendation id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </recommendation>
    </clause>
    </annex>
    </nist-standard>
INPUT
  #{HTML_HDR}
    <div id="fwd">
    <h1 class="ForewordTitle"/>
    <p>
    <a href="#N1">Introduction, Recommendation 1</a>
    <a href="#N2">Preparatory, Recommendation 2</a>
    <a href="#N">Section 1, Recommendation 3</a>
    <a href="#note1">Section 3.1, Recommendation 4</a>
    <a href="#note2">Section 3.1, Recommendation 5</a>
    <a href="#AN">Appendix A.1, Recommendation A-1</a>
    <a href="#Anote1">Appendix A.2, Recommendation A-2</a>
    <a href="#Anote2">Appendix A.2, Recommendation A-3</a>
    </p>
    </div>
    <div id="intro">
    <h1 class="IntroTitle"/>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation 1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="recommend"><p class="AdmonitionTitle">Recommendation 2:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="recommend"><p class="AdmonitionTitle">Recommendation 3:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <p>
                 <a href="#N">Recommendation 3</a>
    </p>
    </div>
    <div id="widgets">
    <h1>3.&#160; Empty Clause</h1>
      </div>
    <div id="widgets">
    <h1>3.&#160; Widgets</h1>
      <div id="widgets1"><h2>3.1. </h2>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation 4:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation 5:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Recommendation 4</a> <a href="#note2">Recommendation 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation A-1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation A-2:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="recommend"><p class="AdmonitionTitle">Recommendation A-3:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    </div>
    </div>
    </body>
    </html>
  OUTPUT
end

it "injects JS into blank html" do
  system "rm -f test.html"
  input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
  INPUT

  output = <<~"OUTPUT"
  #{BLANK_HDR}
  #{AUTHORITY}
  <preface/>
<sections/>
</nist-standard>
  OUTPUT

  expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  html = File.read("test.html", encoding: "utf-8")
  expect(html).to match(%r{jquery\.min\.js})
  expect(html).to match(%r{Baskerville})
end

it "cross-references requirements" do
  expect(IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", true).gsub(%r{^.*<body}m, "<body").gsub(%r{</body>.*}m, "</body>")).to be_equivalent_to <<~"OUTPUT"
        <nist-standard xmlns="http://riboseinc.com/isoxml">
        <preface>
    <foreword id="fwd">
    <p>
    <xref target="N1"/>
    <xref target="N2"/>
    <xref target="N"/>
    <xref target="note1"/>
    <xref target="note2"/>
    <xref target="AN"/>
    <xref target="Anote1"/>
    <xref target="Anote2"/>
    </p>
    </foreword>
        <introduction id="intro">
        <requirement id="N1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
  <clause id="xyz"><title>Preparatory</title>
        <requirement id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <requirement id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <requirement id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
    <requirement id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <requirement id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
    </clause>
    <clause id="annex1b">
        <requirement id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
    <requirement id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </requirement>
    </clause>
    </annex>
    </nist-standard>
INPUT
  #{HTML_HDR}
    <div id="fwd">
    <h1 class="ForewordTitle"/>
    <p>
    <a href="#N1">Introduction, Requirement 1</a>
    <a href="#N2">Preparatory, Requirement 2</a>
    <a href="#N">Section 1, Requirement 3</a>
    <a href="#note1">Section 3.1, Requirement 4</a>
    <a href="#note2">Section 3.1, Requirement 5</a>
    <a href="#AN">Appendix A.1, Requirement A-1</a>
    <a href="#Anote1">Appendix A.2, Requirement A-2</a>
    <a href="#Anote2">Appendix A.2, Requirement A-3</a>
    </p>
    </div>
    <div id="intro">
    <h1 class="IntroTitle"/>
    <div class="require"><p class="AdmonitionTitle">Requirement 1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="require"><p class="AdmonitionTitle">Requirement 2:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="require"><p class="AdmonitionTitle">Requirement 3:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <p>
                 <a href="#N">Requirement 3</a>
    </p>
    </div>
    <div id="widgets">
    <h1>3.&#160; Empty Clause</h1>
      </div>
    <div id="widgets">
    <h1>3.&#160; Widgets</h1>
      <div id="widgets1"><h2>3.1. </h2>
    <div class="require"><p class="AdmonitionTitle">Requirement 4:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="require"><p class="AdmonitionTitle">Requirement 5:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Requirement 4</a> <a href="#note2">Requirement 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="require"><p class="AdmonitionTitle">Requirement A-1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="require"><p class="AdmonitionTitle">Requirement A-2:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="require"><p class="AdmonitionTitle">Requirement A-3:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    </div>
    </div>
    </body>
    </html>
  OUTPUT
end

it "cross-references permissions" do
  expect(IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", true).gsub(%r{^.*<body}m, "<body").gsub(%r{</body>.*}m, "</body>")).to be_equivalent_to <<~"OUTPUT"
        <nist-standard xmlns="http://riboseinc.com/isoxml">
        <preface>
    <foreword id="fwd">
    <p>
    <xref target="N1"/>
    <xref target="N2"/>
    <xref target="N"/>
    <xref target="note1"/>
    <xref target="note2"/>
    <xref target="AN"/>
    <xref target="Anote1"/>
    <xref target="Anote2"/>
    </p>
    </foreword>
        <introduction id="intro">
        <permission id="N1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
  <clause id="xyz"><title>Preparatory</title>
        <permission id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <permission id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <permission id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
    <permission id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <permission id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
    </clause>
    <clause id="annex1b">
        <permission id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
    <permission id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
    </clause>
    </annex>
    </nist-standard>
INPUT
  #{HTML_HDR}
    <div id="fwd">
    <h1 class="ForewordTitle"/>
    <p>
    <a href="#N1">Introduction, Permission 1</a>
    <a href="#N2">Preparatory, Permission 2</a>
    <a href="#N">Section 1, Permission 3</a>
    <a href="#note1">Section 3.1, Permission 4</a>
    <a href="#note2">Section 3.1, Permission 5</a>
    <a href="#AN">Appendix A.1, Permission A-1</a>
    <a href="#Anote1">Appendix A.2, Permission A-2</a>
    <a href="#Anote2">Appendix A.2, Permission A-3</a>
    </p>
    </div>
    <div id="intro">
    <h1 class="IntroTitle"/>
    <div class="permission"><p class="AdmonitionTitle">Permission 1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="permission"><p class="AdmonitionTitle">Permission 2:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="permission"><p class="AdmonitionTitle">Permission 3:</p>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <p>
                 <a href="#N">Permission 3</a>
    </p>
    </div>
    <div id="widgets">
    <h1>3.&#160; Empty Clause</h1>
      </div>
    <div id="widgets">
    <h1>3.&#160; Widgets</h1>
      <div id="widgets1"><h2>3.1. </h2>
    <div class="permission"><p class="AdmonitionTitle">Permission 4:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="permission"><p class="AdmonitionTitle">Permission 5:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Permission 4</a> <a href="#note2">Permission 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="permission"><p class="AdmonitionTitle">Permission A-1:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="permission"><p class="AdmonitionTitle">Permission A-2:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="permission"><p class="AdmonitionTitle">Permission A-3:</p>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    </div>
    </div>
    </body>
    </html>
  OUTPUT
end

it "cleans up requirements" do
  expect(IsoDoc::NIST::HtmlConvert.new({}).cleanup(Nokogiri::XML(<<~"INPUT")).to_s).to be_equivalent_to <<~"OUTPUT"
    <html>
    <body>
      <div class="recommend">
        <p class="AdmonitionTitle"><i>Warning:</i></p>
        <p>Text</p>
      </div>
      <div class="require">
        <p class="AdmonitionTitle"><i>Warning:</i></p>
        <p>Text</p>
      </div>
      <div class="permission">
        <p class="AdmonitionTitle"><i>Warning:</i></p>
        <p>Text</p>
      </div>
    </body>
    </html>
    INPUT
           <?xml version="1.0"?>
       <html>
       <body>
         <div class="recommend">
   <p><b><i>Warning:</i></b> Text</p>
 </div>
 <div class="require">

   <p><b><i>Warning:</i></b> Text</p>
 </div>
 <div class="permission">
           <p><b><i>Warning:</i></b> Text</p>
         </div>

       </body>
       </html>
  OUTPUT
end

it "captions assets in the executive summary separately" do
    input = <<~"INPUT"
          <nist-standard xmlns="http://riboseinc.com/isoxml">
        <preface>
    <foreword id="fwd">
    <p>
        <permission id="N1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
        <permission id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
    </p>
    </foreword>
        <executivesummary id="intro">
        <permission id="N3">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
        <permission id="N4">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png"/>
  </permission>
  </executivesummary>
  </preface>
  </nist-standard>
INPUT

output = <<~"OUTPUT"
  #{HTML_HDR}
      <div id="fwd">
    <h1 class="ForewordTitle"/>
        <p>
      <div class="permission"><p class="AdmonitionTitle">Permission 1:</p>
<img src="rice_images/rice_image1.png" height="auto" width="auto"/>
</div>
      <div class="permission"><p class="AdmonitionTitle">Permission 2:</p>
<img src="rice_images/rice_image1.png" height="auto" width="auto"/>
</div>
  </p>
      </div>
      <div id="intro">
        <h1 class="NormalTitle"/>
        <div class="permission"><p class="AdmonitionTitle">Permission ES-1:</p>
<img src="rice_images/rice_image1.png" height="auto" width="auto"/>
</div>
        <div class="permission"><p class="AdmonitionTitle">Permission ES-2:</p>
<img src="rice_images/rice_image1.png" height="auto" width="auto"/>
</div>
      </div>
    </div>
  </body>
OUTPUT

expect(
      IsoDoc::NIST::HtmlConvert.new({}).
      convert("test", input, true).
      gsub(%r{^.*<body}m, "<body").
      gsub(%r{</body>.*}m, "</body>")
    ).to be_equivalent_to output

end

end
