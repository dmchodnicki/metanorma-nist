require "spec_helper"

RSpec.describe IsoDoc::NIST do

  it "processes default metadata" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
<title>
  <title-main language="en" format="plain">Main Title</title>
  <title-sub language="en" format="plain">Subtitle</title>
  </title>
  <docidentifier type="nist">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
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
      <org><name>Bedrock Inc.</name></org>
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
    <stage>internal-draft</stage>
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
  <series type="main"><title>NIST Federal Information Processing Standards</title>
  <abbreviation>NIST FIPS</abbreviation></series>
  <series type="secondary"><title>Information Security</title></series>
           <keyword>A</keyword>
         <keyword>B</keyword>
         <commentperiod>
         <from>2001-01-01</from>
         <to>2001-01-02</to>
         <extended>2001-01-03</extended>
         </commentperiod>
  <security>Client Confidential</security>
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>["Barney Rubble", "Fred Flintstone"], :authors_affiliations=>{"Bedrock Inc."=>["Barney Rubble"], ""=>["Fred Flintstone"]}, :comment_extended=>"2001-01-03", :comment_from=>"2001-01-01", :comment_to=>"2001-01-02", :confirmeddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"DRAFT (3rd) 1000(wd) Long", :docnumber=>"1000", :docsubtitle=>"Subtitle", :doctitle=>"Main Title", :doctype=>"Standard", :docyear=>"2001", :doi=>"http://www.example2.com", :draft=>"3.4", :draftinfo=>" draft 3.4", :edition=>"2", :editorialgroup=>[], :email=>"email@example.com", :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"3", :keywords=>["A", "B"], :obsoleteddate=>"XXX", :obsoletes=>nil, :obsoletes_part=>nil, :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_monthyear=>"January 2000", :sc=>"XXXX", :secretariat=>"XXXX", :series=>"NIST Federal Information Processing Standards", :status=>"Internal Draft", :subseries=>"Information Security", :tc=>"XXXX", :unpublished=>true, :updateddate=>"XXX", :url=>"http://www.example.com", :wg=>"XXXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

  it "processes initial public draft" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
<title>
  <title-main language="en" format="plain">Main Title</title>
  </title>
  <docidentifier type="nist">1000(wd)</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <contributor>
    <role type="author"/>
    <organization>
      <name>Acme</name>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>public-draft</stage>
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
</bibdata>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :confirmeddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>nil, :docnumber=>"1000", :doctitle=>"Main Title", :doctype=>"Standard", :docyear=>"2001", :draft=>"3.4", :draftinfo=>" draft 3.4", :edition=>"2", :editorialgroup=>[], :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"1", :keywords=>[], :obsoleteddate=>"XXX", :obsoletes=>nil, :obsoletes_part=>nil, :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_monthyear=>"January 2000", :sc=>"XXXX", :secretariat=>"XXXX", :status=>"Initial Public Draft", :tc=>"XXXX", :unpublished=>true, :updateddate=>"XXX", :wg=>"XXXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

    it "processes final public draft" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
<title>
  <title-main language="en" format="plain">Main Title</title>
  </title>
  <docidentifier type="nist">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
  <version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>public-draft</stage>
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
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :confirmeddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"DRAFT (final) 1000(wd) Long", :docnumber=>"1000", :doctitle=>"Main Title", :doctype=>"Standard", :docyear=>"2001", :draft=>"3.4", :draftinfo=>" draft 3.4", :edition=>"2", :editorialgroup=>[], :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :iteration=>"final", :keywords=>[], :obsoleteddate=>"XXX", :obsoletes=>nil, :obsoletes_part=>nil, :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_monthyear=>"January 2000", :sc=>"XXXX", :secretariat=>"XXXX", :status=>"Final Public Draft", :tc=>"XXXX", :unpublished=>true, :updateddate=>"XXX", :wg=>"XXXX"}
    OUTPUT

    docxml, filename, dir = csdc.convert_init(input, "test", true)
    expect(htmlencode(Hash[csdc.info(docxml, nil).sort].to_s)).to be_equivalent_to output
  end

        it "processes published" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
<title>
  <title-main language="en" format="plain">Main Title</title>
  </title>
  <docidentifier type="nist">1000(wd)</docidentifier>
  <docidentifier type="nist-long">1000(wd) Long</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
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
    {:accesseddate=>"XXX", :authors=>[], :authors_affiliations=>{}, :confirmeddate=>"XXX", :createddate=>"XXX", :docidentifier=>"1000(wd)", :docidentifier_long=>"1000(wd) Long", :docnumber=>"1000", :doctitle=>"Main Title", :doctype=>"Standard", :docyear=>"2001", :draft=>"3.4", :draftinfo=>" draft 3.4", :edition=>"2", :editorialgroup=>[], :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :keywords=>[], :obsoleteddate=>"XXX", :obsoletes=>nil, :obsoletes_part=>nil, :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_monthyear=>"January 2000", :sc=>"XXXX", :secretariat=>"XXXX", :status=>"Final", :tc=>"XXXX", :unpublished=>true, :updateddate=>"XXX", :wg=>"XXXX"}
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
             <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <pre>ABC</pre>
             </div>
             <p class="zzSTDTitle1"/>
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
             <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <span class="keyword">ABC</span>
             </div>
             <p class="zzSTDTitle1"/>
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
                          <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <div id="1" class="pseudocode">
       <ol type="a">
       <li>A B C
       <ol type="1"><li>D</li>
       <li>E</li>
       </ol>
       </li>
       </ol>
       <p class="FigureTitle" align="center">Figure 1&#160;&#8212; First figure</p>
       </div>
       </div>
             <p class="zzSTDTitle1"/>
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
                          <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <pre id="_" class="prettyprint ">&lt;xccdf:check system="<span class="nistvariable">http://oval.mitre.org/XMLSchema/oval-definitions-5</span>"&gt;</pre>
       </div>
             <p class="zzSTDTitle1"/>
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
             <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <table id="" class="MsoISOTable" border="1" cellspacing="0" cellpadding="0">
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
             <p class="zzSTDTitle1"/>
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
             <p class="zzSTDTitle1"></p>
             <br />
             <div id="_32d7b4db-f3fb-4a11-a418-74f365b96d4b" class="Section3">
               <h1 class="Annex"><b>Appendix A</b> &#x2014; <b>Glossary</b></h1>
               <div id="_normal_terms_2"><h2>A.1. Normal Terms 2</h2>
     <p>For the purposes of this document, the following terms and definitions apply.</p>
         <dl class="terms_dl"><dt>Normal Terms</dt><dd><p id="_4883de72-6054-4227-a111-b8966759b0f6">Definition</p>
       <div id="_f22bc30c-a5a6-45ae-8bea-0792d7109470" class="example"><p class="example-title">EXAMPLE</p>
         <p id="_16555fc3-3570-4b16-8fff-ac95941b62b1">Example</p>
       </div></dd><dt>Other Terms</dt><dd><p id="_4883de72-6054-4227-a111-b8966759b0f7">Definition</p>
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
      <p class="zzSTDTitle1"></p>
      <br />
      <div id="A" class="Section3">
        <h1 class="Annex"><b>Appendix A</b> &#x2014; <b>First Appendix</b></h1>
        <div id="B" class="example"><p class="example-title">EXAMPLE</p>
      <p id="C">Example</p>
    </div>
      </div>
      <br />
      <div id="D" class="Section3">
        <h1 class="Annex"><b>Appendix B</b> &#x2014; <b>Bibliography</b></h1>
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
             <br/>
             <div id="S1">
               <h1 class="AbstractTitle">Abstract</h1>
               <p id="AA">This is an Abstract</p>
             </div>
             <br/>
             <div id="S2">
               <h1 class="ForewordTitle">Foreword</h1>
               <p id="A">This is a preamble</p>
             </div>
             <div id="B">
               <h1>Introduction</h1>
               <div id="C"><h2>Introduction Subsection</h2>

          </div>
             </div>
             <div id="S3">
               <h1>Acknowlegdements</h1>
               <p id="AB">These are acknowledgements</p>
             </div>
             <div id="S4">
               <h1>Audience</h1>
               <p id="AD">This are audience</p>
             </div>
             <div id="S5">
               <h1>Conformance Testing</h1>
               <p id="AC">This is conformance testing</p>
             </div>
             <div id="S6">
               <h1>Executive Summary</h1>
               <p id="AC">This is an executive summary</p>
             </div>
             <p class="zzSTDTitle1"/>
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
             <div id="P" class="Section3">
               <h1 class="Annex"><b>Appendix A</b> &#8212;<b>Annex</b></h1>
               <div id="Q"><h2>A.1. Annex A.1</h2>

            <div id="Q1"><h3>A.1.1. Annex A.1a</h3>

            </div>
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
      <br/>
      <div>
        <h1 class="AbstractTitle">Abstract</h1>
        <p id="AA">This is an Abstract</p>
      </div>
      <p class="zzSTDTitle1"/>
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
      <br/>
      <div>
        <h1 class="AbstractTitle">Abstract</h1>
        <p id="AA">This is an Abstract</p>
      </div>
      <div>
  <h1>Note for Reviewers</h1>
  <p>Hello reviewer</p>
</div>
      <p class="zzSTDTitle1"/>
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
        <iso-standard xmlns="http://riboseinc.com/isoxml">
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
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
  <clause id="xyz"><title>Preparatory</title>
        <recommendation id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <recommendation id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <recommendation id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
    <recommendation id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <recommendation id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
    </clause>
    <clause id="annex1b">
        <recommendation id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
    <recommendation id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </recommendation>
    </clause>
    </annex>
    </iso-standard>
INPUT
#{HTML_HDR}
<br/>
    <div id="fwd">
    <h1 class="ForewordTitle">Foreword</h1>
    <p>
    <a href="#N1">Introduction, Recommendation 1</a>
    <a href="#N2">Preparatory, Recommendation 2</a>
    <a href="#N">Section 1, Recommendation 3</a>
    <a href="#note1">Section 3.1, Recommendation 4</a>
    <a href="#note2">Section 3.1, Recommendation 5</a>
    <a href="#AN">Appendix A.1, Recommendation A.1</a>
    <a href="#Anote1">Appendix A.2, Recommendation A.2</a>
    <a href="#Anote2">Appendix A.2, Recommendation A.3</a>
    </p>
    </div>
    <div id="intro">
    <h1/>
    <div class="recommend"><title>Recommendation 1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="recommend"><title>Recommendation 2:</title>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <p class="zzSTDTitle1"/>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="recommend"><title>Recommendation 3:</title>
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
    <div class="recommend"><title>Recommendation 4:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="recommend"><title>Recommendation 5:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Recommendation 4</a> <a href="#note2">Recommendation 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="recommend"><title>Recommendation A.1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="recommend"><title>Recommendation A.2:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="recommend"><title>Recommendation A.3:</title>
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
<sections/>
</nist-standard>
    OUTPUT

    expect(Asciidoctor.convert(input, backend: :nist, header_footer: true)).to be_equivalent_to output
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r{jquery\.min\.js})
    expect(html).to match(%r{Baskerville})
  end

    it "cross-references requirements" do
    expect(IsoDoc::NIST::HtmlConvert.new({}).convert("test", <<~"INPUT", true).gsub(%r{^.*<body}m, "<body").gsub(%r{</body>.*}m, "</body>")).to be_equivalent_to <<~"OUTPUT"
        <iso-standard xmlns="http://riboseinc.com/isoxml">
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
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
  <clause id="xyz"><title>Preparatory</title>
        <requirement id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <requirement id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <requirement id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
    <requirement id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <requirement id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
    </clause>
    <clause id="annex1b">
        <requirement id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
    <requirement id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </requirement>
    </clause>
    </annex>
    </iso-standard>
INPUT
#{HTML_HDR}
<br/>
    <div id="fwd">
    <h1 class="ForewordTitle">Foreword</h1>
    <p>
    <a href="#N1">Introduction, Requirement 1</a>
    <a href="#N2">Preparatory, Requirement 2</a>
    <a href="#N">Section 1, Requirement 3</a>
    <a href="#note1">Section 3.1, Requirement 4</a>
    <a href="#note2">Section 3.1, Requirement 5</a>
    <a href="#AN">Appendix A.1, Requirement A.1</a>
    <a href="#Anote1">Appendix A.2, Requirement A.2</a>
    <a href="#Anote2">Appendix A.2, Requirement A.3</a>
    </p>
    </div>
    <div id="intro">
    <h1/>
    <div class="require"><title>Requirement 1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="require"><title>Requirement 2:</title>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <p class="zzSTDTitle1"/>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="require"><title>Requirement 3:</title>
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
    <div class="require"><title>Requirement 4:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="require"><title>Requirement 5:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Requirement 4</a> <a href="#note2">Requirement 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="require"><title>Requirement A.1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="require"><title>Requirement A.2:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="require"><title>Requirement A.3:</title>
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
        <iso-standard xmlns="http://riboseinc.com/isoxml">
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
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
  <clause id="xyz"><title>Preparatory</title>
        <permission id="N2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
</clause>
    </introduction>
    </preface>
    <sections>
    <clause id="scope"><title>Scope</title>
        <permission id="N">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
<p><xref target="N"/></p>
    </clause>
    <clause id="widgets"><title>Empty Clause</title></clause>
    <clause id="widgets"><title>Widgets</title>
    <clause id="widgets1">
        <permission id="note1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
    <permission id="note2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
  <p>    <xref target="note1"/> <xref target="note2"/> </p>
    </clause>
    </clause>
    </sections>
    <annex id="annex1">
    <clause id="annex1a">
        <permission id="AN">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
    </clause>
    <clause id="annex1b">
        <permission id="Anote1">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
    <permission id="Anote2">
  <image src="rice_images/rice_image1.png" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" imagetype="PNG"/>
  </permission>
    </clause>
    </annex>
    </iso-standard>
INPUT
#{HTML_HDR}
<br/>
    <div id="fwd">
    <h1 class="ForewordTitle">Foreword</h1>
    <p>
    <a href="#N1">Introduction, Permission 1</a>
    <a href="#N2">Preparatory, Permission 2</a>
    <a href="#N">Section 1, Permission 3</a>
    <a href="#note1">Section 3.1, Permission 4</a>
    <a href="#note2">Section 3.1, Permission 5</a>
    <a href="#AN">Appendix A.1, Permission A.1</a>
    <a href="#Anote1">Appendix A.2, Permission A.2</a>
    <a href="#Anote2">Appendix A.2, Permission A.3</a>
    </p>
    </div>
    <div id="intro">
    <h1/>
    <div class="permission"><title>Permission 1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
               <div id="xyz"><h2>Preparatory</h2>
               <div class="permission"><title>Permission 2:</title>
         <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
       </div>
             </div>
             <p class="zzSTDTitle1"/>
             <div id="scope">
               <h1>1.&#160; Scope</h1>
               <div class="permission"><title>Permission 3:</title>
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
    <div class="permission"><title>Permission 4:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="permission"><title>Permission 5:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
         </div>
         <p>    <a href="#note1">Permission 4</a> <a href="#note2">Permission 5</a> </p>
    </div>
    </div>
    <br/>
    <div id="annex1" class="Section3">
    <div id="annex1a"><h2>A.1. </h2>
    <div class="permission"><title>Permission A.1:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    </div>
    <div id="annex1b"><h2>A.2. </h2>
    <div class="permission"><title>Permission A.2:</title>
    <img src="rice_images/rice_image1.png" height="auto" width="auto"/>
    </div>
    <div class="permission"><title>Permission A.3:</title>
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
        <title><i>Warning:</i></title>
        <p>Text</p>
      </div>
      <div class="require">
        <title><i>Warning:</i></title>
        <p>Text</p>
      </div>
      <div class="permission">
        <title><i>Warning:</i></title>
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


end
