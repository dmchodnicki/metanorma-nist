require "spec_helper"
require "fileutils"

RSpec.describe Asciidoctor::NIST do
  it "has a version number" do
    expect(Metanorma::NIST::VERSION).not_to be nil
  end

  it "generates output for the Rice document" do
    FileUtils.rm_f %w(spec/examples/rfc6350.doc spec/examples/rfc6350.html spec/examples/rfc6350.pdf)
    FileUtils.cd "spec/examples"
    Asciidoctor.convert_file "rfc6350.adoc", {:attributes=>{"backend"=>"nist"}, :safe=>0, :header_footer=>true, :requires=>["metanorma-nist"], :failure_level=>4, :mkdirs=>true, :to_file=>nil}
    FileUtils.cd "../.."
    expect(File.exist?("spec/examples/rfc6350.doc")).to be true
    expect(File.exist?("spec/examples/rfc6350.html")).to be true
    expect(File.exist?("spec/examples/rfc6350.pdf")).to be true
  end

  it "processes a blank document" do
    input = <<~"INPUT"
    #{ASCIIDOC_BLANK_HDR}
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
<sections/>
</nist-standard>
    OUTPUT

    expect(Asciidoctor.convert(input, backend: :nist, header_footer: true)).to be_equivalent_to output
  end

  it "converts a blank document" do
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

    FileUtils.rm_f "test.html"
    expect(Asciidoctor.convert(input, backend: :nist, header_footer: true)).to be_equivalent_to output
    expect(File.exist?("test.html")).to be true
  end

  it "processes default metadata" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :doctype: standard
      :edition: 2
      :revdate: 2000-01-01
      :draft: 3.4
      :technical-committee: TC
      :technical-committee-number: 1
      :technical-committee-type: A
      :technical-committee_2: TC1
      :technical-committee-number_2: 11
      :technical-committee-type_2: A1
      :subcommittee: SC
      :subcommittee-number: 2
      :subcommittee-type: B
      :workgroup: WG
      :workgroup-number: 3
      :workgroup-type: C
      :secretariat: SECRETARIAT
      :copyright-year: 2001
      :status: working-draft
      :iteration: 3
      :language: en
      :title: Main Title
      :security: Client Confidential
      :keywords: a, b, c
      :fullname: Fred Flintstone
      :role: author
      :surname_2: Rubble
      :givenname_2: Barney
      :role_2: editor
      :subtitle: Subtitle
      :email: email@example.com
    INPUT

    output = <<~"OUTPUT"
           <?xml version="1.0" encoding="UTF-8"?>
       <nist-standard xmlns="http://www.nist.gov/metanorma">
       <bibdata type="standard">
         <title language="en" format="text/plain">Main Title</title>
         <subtitle language="en" format="text/plain">Subtitle</subtitle>
        <source type="email">email@example.com</source>
         <docidentifier type="nist">NIST 1000(wd)</docidentifier>
         <docnumber>1000</docnumber>
         <edition>2</edition>
         <version>
           <revision-date>2000-01-01</revision-date>
           <draft>3.4</draft>
         </version>
         <contributor>
           <role type="author"/>
           <organization>
             <name>NIST</name>
           </organization>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
             <name>
               <completename>Fred Flintstone</completename>
             </name>
           </person>
         </contributor>
         <contributor>
           <role type="editor"/>
           <person>
             <name>
               <forename>Barney</forename>
               <surname>Rubble</surname>
             </name>
           </person>
         </contributor>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>NIST</name>
           </organization>
         </contributor>
         <language>en</language>
         <script>Latn</script>
         <status format="plain">working-draft</status>
         <copyright>
           <from>2001</from>
           <owner>
             <organization>
               <name>NIST</name>
             </organization>
           </owner>
         </copyright>
         <editorialgroup>
           <committee>TC</committee>
           <subcommittee type="B" number="2">SC</subcommittee>
           <workgroup type="C" number="3">WG</workgroup>
         </editorialgroup>
         <keyword>a</keyword>
         <keyword>b</keyword>
         <keyword>c</keyword>
       </bibdata>
       <sections/>
       </nist-standard>
    OUTPUT

    expect(Asciidoctor.convert(input, backend: :nist, header_footer: true)).to be_equivalent_to output
  end

      it "processes committee-draft" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true)).to be_equivalent_to <<~"OUTPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :doctype: standard
      :edition: 2
      :revdate: 2000-01-01
      :draft: 3.4
      :status: committee-draft
      :iteration: 3
      :language: en
      :title: Main Title
    INPUT
        <nist-standard xmlns="http://www.nist.gov/metanorma">
<bibdata type="standard">
  <title language="en" format="text/plain">Main Title</title>
  <docidentifier type="nist">NIST 1000(cd)</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
<version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version> 
  <contributor>
    <role type="author"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status format="plain">committee-draft</status>
  <copyright>
    <from>#{Date.today.year}</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <committee/>
  </editorialgroup>
</bibdata>
<sections/>
</nist-standard>
        OUTPUT
    end

              it "processes draft-standard" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true)).to be_equivalent_to <<~"OUTPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :doctype: standard
      :edition: 2
      :revdate: 2000-01-01
      :draft: 3.4
      :status: draft-standard
      :iteration: 3
      :language: en
      :title: Main Title
    INPUT
        <nist-standard xmlns="http://www.nist.gov/metanorma">
<bibdata type="standard">
  <title language="en" format="text/plain">Main Title</title>
  <docidentifier type="nist">NIST 1000(d)</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
<version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>   <contributor>
    <role type="author"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status format="plain">draft-standard</status>
  <copyright>
    <from>#{Date.today.year}</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <committee/>
  </editorialgroup>
</bibdata>
<sections/>
</nist-standard>
OUTPUT
        end

                  it "ignores unrecognised status" do
        expect(Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true)).to be_equivalent_to <<~'OUTPUT'
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :doctype: standard
      :edition: 2
      :revdate: 2000-01-01
      :draft: 3.4
      :copyright-year: 2001
      :status: standard
      :iteration: 3
      :language: en
      :title: Main Title
    INPUT
    <nist-standard xmlns="http://www.nist.gov/metanorma">
<bibdata type="standard">
  <title language="en" format="text/plain">Main Title</title>
  <docidentifier type="nist">NIST 1000</docidentifier>
  <docnumber>1000</docnumber>
  <edition>2</edition>
<version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version> 
 <contributor>
    <role type="author"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status format="plain">standard</status>
  <copyright>
    <from>2001</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <committee/>
  </editorialgroup>
</bibdata>
<sections/>
</nist-standard>
    OUTPUT
  end

  it "strips inline header" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      This is a preamble

      == Section 1
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
             <preface><foreword obligation="informative">
         <title>Foreword</title>
         <p id="_">This is a preamble</p>
       </foreword></preface><sections>
       <clause id="_" obligation="normative">
         <title>Section 1</title>
       </clause></sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "uses default fonts" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
    INPUT

    FileUtils.rm_f "test.html"
    Asciidoctor.convert(input, backend: :nist, header_footer: true)

    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r[\.Sourcecode[^{]+\{[^}]+font-family: "Space Mono", monospace;]m)
    expect(html).to match(%r[ div[^{]+\{[^}]+font-family: "Overpass", sans-serif;]m)
    expect(html).to match(%r[h1, h2, h3, h4, h5, h6 \{[^}]+font-family: "Overpass", sans-serif;]m)
  end

  it "uses Chinese fonts" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
    INPUT

    FileUtils.rm_f "test.html"
    Asciidoctor.convert(input, backend: :nist, header_footer: true)

    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r[\.Sourcecode[^{]+\{[^}]+font-family: "Space Mono", monospace;]m)
    expect(html).to match(%r[ div[^{]+\{[^}]+font-family: "SimSun", serif;]m)
    expect(html).to match(%r[h1, h2, h3, h4, h5, h6 \{[^}]+font-family: "SimHei", sans-serif;]m)
  end

  it "uses specified fonts" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
    INPUT

    FileUtils.rm_f "test.html"
    Asciidoctor.convert(input, backend: :nist, header_footer: true)

    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r[\.Sourcecode[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[ div[^{]+\{[^}]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1, h2, h3, h4, h5, h6 \{[^}]+font-family: Comic Sans;]m)
  end

  it "recognises preface sections" do
        input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      This is a preamble

      [abstract]
      == Abstract

      This is an abstract

      [preface]
      == Acknowledgements

      These are acknolwedgements
       
      [preface]
      == Note to Reviewers

      This is Note to Reviewers

      [preface]
      == Executive Summary

      This is an executive summary

      [preface]
      == Conformance Testing

      This is Conformance Testing

      == Clause

      This is a clause
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
    <preface><foreword obligation="informative">
  <title>Foreword</title>
  <p id="_">This is a preamble</p>
</foreword><clause id="_" obligation="normative">
  <title>Acknowledgements</title>
  <p id="_">These are acknolwedgements</p>
</clause><reviewernote id="_" obligation="normative">
  <title>Note to Reviewers</title>
  <p id="_">This is Note to Reviewers</p>
</reviewernote><clause id="_" obligation="normative">
  <title>Conformance Testing</title>
  <p id="_">This is Conformance Testing</p>
</clause><executivesummary id="_" obligation="normative">
  <title>Executive Summary</title>
  <p id="_">This is an executive summary</p>
</executivesummary>
<abstract id="_">
  <p id="_">This is an abstract</p>
</abstract></preface><sections>

       <clause id="_" obligation="normative">
         <title>Clause</title>
         <p id="_">This is a clause</p>
       </clause></sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "processes inline_quoted formatting" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      _emphasis_
      *strong*
      `monospace`
      "double quote"
      'single quote'
      super^script^
      sub~script~
      stem:[a_90]
      stem:[<mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">&#x391;</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math>]
      [keyword]#keyword#
      [strike]#strike#
      [smallcap]#smallcap#
    INPUT

    output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
        <p id="_"><em>emphasis</em>
       <strong>strong</strong>
       <tt>monospace</tt>
       “double quote”
       ‘single quote’
       super<sup>script</sup>
       sub<sub>script</sub>
       <stem type="AsciiMath">a_90</stem>
       <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub> <mrow> <mrow> <mi mathvariant="bold-italic">F</mi> </mrow> </mrow> <mrow> <mrow> <mi mathvariant="bold-italic">Α</mi> </mrow> </mrow> </msub> </math></stem>
       <keyword>keyword</keyword>
       <strike>strike</strike>
       <smallcap>smallcap</smallcap></p>
       </sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "processes pseudocode" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      
      .Label
      [pseudocode]
      ====
      _Input: S=(s1, sL)_

      _Output:_ Shuffled _S=(s1, sL)_

      . *for* _i_ *from* _L_ *downto* 1 *do*
      .. Generate a random integer _j_ such that 1 < _j_ < _i_
      .. Swap _s~j~_ and _s~i~_
      ====
    INPUT

        output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
         <figure id="_" type="pseudocode"><name>Label</name><p id="_">
  <em>Input: S=(s1, sL)</em>
</p>
<p id="_"><em>Output:</em> Shuffled <em>S=(s1, sL)</em></p>
<ol id="_" type="arabic">
  <li>
    <p id="_"><strong>for</strong> <em>i</em> <strong>from</strong> <em>L</em> <strong>downto</strong> 1 <strong>do</strong></p>
    <ol id="_" type="alphabet">
  <li>
    <p id="_">Generate a random integer <em>j</em> such that 1 &lt; <em>j</em> &lt; <em>i</em></p>
  </li>
  <li>
    <p id="_">Swap <em>s<sub>j</sub></em> and <em>s<sub>i</sub></em></p>
  </li>
</ol>
  </li>
</ol></figure>
       </sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

    it "processes recommendation" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [recommendation]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <recommendation id="_">
  <p id="_">I recommend this</p>
</recommendation>
       </sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

    it "processes requirement" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [requirement]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <requirement id="_">
  <p id="_">I recommend this</p>
</requirement>
       </sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

        it "processes permission" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [permission]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <permission id="_">
  <p id="_">I recommend this</p>
</permission>
       </sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "processes variables within sourcecode" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [source]
      ----
      <xccdf:check system="{{{http://oval.mitre.org/XMLSchema/oval-definitions-5}}}">
      ----
    INPUT

        output = <<~"OUTPUT"
            #{BLANK_HDR}
<sections>
  <sourcecode id="_">&lt;xccdf:check system="<nistvariable>http://oval.mitre.org/XMLSchema/oval-definitions-5</nistvariable>"&gt;</sourcecode>
</sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "processes errata" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [errata]
      |===
      |Pages |Change |Type |Date

      |12-13 |_Repaginate_ |Major |2012-01-01
      |9-12 |Revert |Minor |2012-01-02
      |===
    INPUT

        output = <<~"OUTPUT"
            #{BLANK_HDR}
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
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

    it "processes glossaries" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [glossary]
      a:: b
      c:: d
    INPUT

        output = <<~"OUTPUT"
            #{BLANK_HDR}
<sections>
  <dl id="_" type="glossary">
  <dt>a</dt>
  <dd>
    <p id="_">b</p>
  </dd>
  <dt>c</dt>
  <dd>
    <p id="_">d</p>
  </dd>
</dl>
</sections>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

end
