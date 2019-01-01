require "spec_helper"

RSpec.describe IsoDoc::NIST do

  it "processes default metadata" do
    csdc = IsoDoc::NIST::HtmlConvert.new({})
    input = <<~"INPUT"
<nist-standard xmlns="https://open.ribose.com/standards/example">
<bibdata type="standard">
  <title language="en" format="plain">Main Title</title>
  <subtitle language="en" format="plain">Subtitle</subtitle>
  <docidentifier>1000(wd)</docidentifier>
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
  <language>en</language>
  <script>Latn</script>
  <status format="plain">working-draft</status>
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
  <source type="email">email@example.com</source>
           <keyword>A</keyword>
         <keyword>B</keyword>
  <security>Client Confidential</security>
</bibdata><version>
  <edition>2</edition>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
<sections/>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    {:accesseddate=>"XXX", :confirmeddate=>"XXX", :createddate=>"XXX", :docnumber=>"1000(wd)", :docsubtitle=>"Subtitle", :doctitle=>"Main Title", :doctype=>"Standard", :docyear=>"2001", :draft=>"3.4", :draftinfo=>" (draft 3.4, 2000-01-01)", :editorialgroup=>[], :email=>"email@example.com", :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :keywords=>["A", "B"], :obsoleteddate=>"XXX", :obsoletes=>nil, :obsoletes_part=>nil, :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2000-01-01", :revdate_monthyear=>"January 2000", :sc=>"XXXX", :secretariat=>"XXXX", :status=>"Working Draft", :tc=>"XXXX", :unpublished=>false, :updateddate=>"XXX", :wg=>"XXXX"}
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
<example id="1" type="pseudocode">
<ol>
<li>A B C
<ol><li>D</li>
<li>E</li>
</ol>
</li>
</ol>
</example>
</foreword></preface>
</nist-standard>
    INPUT

    output = <<~"OUTPUT"
    #{HTML_HDR}
                          <br/>
             <div>
               <h1 class="ForewordTitle">Foreword</h1>
               <div id="1" class="pseudocode"><p>EXAMPLE</p>
       <ol type="a">
       <li>A B C
       <ol type="1"><li>D</li>
       <li>E</li>
       </ol>
       </li>
       </ol>
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
               <p id="_" class="Sourcecode">&lt;xccdf:check system="<span class="nistvariable">http://oval.mitre.org/XMLSchema/oval-definitions-5</span>"&gt;</p>
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
  <status format="plain">working-draft</status>
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
    expect(html).to match(%r{Overpass})
  end

end
