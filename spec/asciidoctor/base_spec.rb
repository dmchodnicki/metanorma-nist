require "spec_helper"
require "fileutils"

RSpec.describe Asciidoctor::NIST do
  it "has a version number" do
    expect(Metanorma::NIST::VERSION).not_to be nil
  end

  #it "generates output for the Rice document" do
  #  FileUtils.rm_f %w(spec/examples/rfc6350.doc spec/examples/rfc6350.html spec/examples/rfc6350.pdf)
  #  FileUtils.cd "spec/examples"
  #  Asciidoctor.convert_file "rfc6350.adoc", {:attributes=>{"backend"=>"nist"}, :safe=>0, :header_footer=>true, :requires=>["metanorma-nist"], :failure_level=>4, :mkdirs=>true, :to_file=>nil}
  #  FileUtils.cd "../.."
  #  expect(File.exist?("spec/examples/rfc6350.doc")).to be true
  #  expect(File.exist?("spec/examples/rfc6350.html")).to be true
  #  expect(File.exist?("spec/examples/rfc6350.pdf")).to be true
  #end

  it "processes a blank document" do
    input = <<~"INPUT"
    #{ASCIIDOC_BLANK_HDR}
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
    <preface>
    #{AUTHORITY}
    </preface>
<sections/>
</nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
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
    <preface>
    #{AUTHORITY}
    </preface>
<sections/>
</nist-standard>
    OUTPUT

    FileUtils.rm_f "test.html"
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
    expect(File.exist?("test.html")).to be true
  end

    it "includes Patent Disclosure Notice" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :call-for-patent-claims:
      :doc-email: x@example.com
      :docnumber: ABC
      :novalid:
    INPUT

    output = <<~"OUTPUT"
       <clause obligation="normative"><title>Patent Disclosure Notice</title>
             <p id="_">NOTICE: ITL has requested that holders of patent claims whose use may be required for compliance with the guidance or requirements of this publication disclose such patent claims to ITL. However, holders of patents are not obligated to respond to ITL calls for patents and ITL has not undertaken a patent search in order to identify which, if any, patents may apply to this publication.</p>
       <p id="_">As of the date of publication and following call(s) for the identification of patent claims whose use may be required for compliance with the guidance or requirements of this publication, no such patent claims have been identified to ITL.</p>
       <p id="_">No representation is made or implied by ITL that licenses are not required to avoid patent infringement in the use of this publication.</p>
       </clause>
       </preface><sections/>
       </nist-standard>

    OUTPUT

    FileUtils.rm_f "test.html"
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true)).
               sub(%r{^.*<clause obligation="normative"><title>Patent Disclosure Notice</title>}m, '<clause obligation="normative"><title>Patent Disclosure Notice</title>')).to be_equivalent_to output
    expect(File.exist?("test.html")).to be true
  end

  it "includes Patent Disclosure Notice with specific patent contact" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :call-for-patent-claims:
      :commitment-to-licence:
      :doc-email: x@example.com
      :docnumber: ABC
      :patent-contact: The Patent Office, NIST, (1) 555 6666
      :novalid:
    INPUT

    output = <<~"OUTPUT"
            <clause obligation="normative"><title>Patent Disclosure Notice</title>
             <p id="_">NOTICE: The Information Technology Laboratory (ITL) has requested that holders of patent claims whose use may be required for compliance with the guidance or requirements of this publication disclose such patent claims to ITL. However, holders of patents are not obligated to respond to ITL calls for patents and ITL has not undertaken a patent search in order to identify which, if any, patents may apply to this publication. </p>
       <p id="_">Following the ITL call for the identification of patent claims whose use may be required for compliance with the guidance or requirements of this publication, notice of one or more such claims has been received. </p>
       <p id="_">By publication, no position is taken by ITL with respect to the validity or scope of any patent claim or of any rights in connection therewith. The known patent holder(s) has (have), however, provided to NIST a letter of assurance stating either (1) a general disclaimer to the effect that it does (they do) not hold and does (do) not currently intend holding any essential patent claim(s), or (2) that it (they) will negotiate royalty-free or royalty-bearing licenses with other parties on a demonstrably nondiscriminatory basis with reasonable terms and conditions. </p>
       <p id="_">Details may be obtained from The Patent Office, NIST, (1) 555 6666. </p>
       <p id="_">No representation is made or implied that this is the only license that may be required to avoid patent infringement in the use of this publication. </p>
       </clause>
       </preface><sections/>
       </nist-standard>

    OUTPUT

    FileUtils.rm_f "test.html"
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true)).
                         sub(%r{^.*<clause obligation="normative"><title>Patent Disclosure Notice</title>}m, '<clause obligation="normative"><title>Patent Disclosure Notice</title>')).to be_equivalent_to output
    expect(File.exist?("test.html")).to be true
  end


        it "includes Patent Disclosure Notice when notice and commitment to license have been received by ITL" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :call-for-patent-claims:
      :commitment-to-licence:
      :doc-email: x@example.com
      :docnumber: ABC
      :novalid:
    INPUT

    output = <<~"OUTPUT"
            <clause obligation="normative"><title>Patent Disclosure Notice</title>
             <p id="_">NOTICE: The Information Technology Laboratory (ITL) has requested that holders of patent claims whose use may be required for compliance with the guidance or requirements of this publication disclose such patent claims to ITL. However, holders of patents are not obligated to respond to ITL calls for patents and ITL has not undertaken a patent search in order to identify which, if any, patents may apply to this publication. </p>
       <p id="_">Following the ITL call for the identification of patent claims whose use may be required for compliance with the guidance or requirements of this publication, notice of one or more such claims has been received. </p>
       <p id="_">By publication, no position is taken by ITL with respect to the validity or scope of any patent claim or of any rights in connection therewith. The known patent holder(s) has (have), however, provided to NIST a letter of assurance stating either (1) a general disclaimer to the effect that it does (they do) not hold and does (do) not currently intend holding any essential patent claim(s), or (2) that it (they) will negotiate royalty-free or royalty-bearing licenses with other parties on a demonstrably nondiscriminatory basis with reasonable terms and conditions. </p>
       <p id="_">Details may be obtained from x@example.com. </p>
       <p id="_">No representation is made or implied that this is the only license that may be required to avoid patent infringement in the use of this publication. </p>
       </clause>
       </preface><sections/>
       </nist-standard>

    OUTPUT

    FileUtils.rm_f "test.html"
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true)).
                         sub(%r{^.*<clause obligation="normative"><title>Patent Disclosure Notice</title>}m, '<clause obligation="normative"><title>Patent Disclosure Notice</title>')).to be_equivalent_to output
    expect(File.exist?("test.html")).to be true
  end

    it "includes Call for Patent Claims" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :call-for-patent-claims:
      :status: public-draft
      :doc-email: x@example.com
      :docnumber: ABC
      :novalid:
    INPUT

    output = <<~"OUTPUT"
           <clause obligation="normative"><title>Call for Patent Claims</title>
             <p id="_">This public review includes a call for information on essential patent claims (claims whose use would be required for compliance with the guidance or requirements in this Information Technology Laboratory (ITL) draft publication). Such guidance and/or requirements may be directly stated in this ITL Publication or by reference to another publication. This call also includes disclosure, where known, of the existence of pending U.S. or foreign patent applications relating to this ITL draft publication and of any relevant unexpired U.S. or foreign patents.</p>

       <p id="_">ITL may require from the patent holder, or a party authorized to make assurances on its behalf, in written or electronic form, either:</p>

       <ol><li><p id="_">assurance in the form of a general disclaimer to the effect that such party does not hold and does not currently intend holding any essential patent claim(s); or</p></li>

       <li><p id="_">assurance that a license to such essential patent claim(s) will be made available to applicants desiring to utilize the license for the purpose of complying with the guidance or requirements in this ITL draft publication either:</p>

       	<ol><li><p id="_">under reasonable terms and conditions that are demonstrably free of any unfair discrimination; or</p></li>

               <li><p id="_">without compensation and under reasonable terms and conditions that are demonstrably free of any unfair discrimination.</p></li></ol>
       </li></ol>

       <p id="_">Such assurance shall indicate that the patent holder (or third party authorized to make assurances on its behalf) will include in any documents transferring ownership of patents subject to the assurance, provisions sufficient to ensure that the commitments in the assurance are binding on the transferee, and that the transferee will similarly include appropriate provisions in the event of future transfers with the goal of binding each successor-in-interest.</p>

       <p id="_">The assurance shall also indicate that it is intended to be binding on successors-in-interest regardless of whether such provisions are included in the relevant transfer documents.</p>

       <p id="_">Such statements should be addressed to: x@example.com, with the Subject: ABC Call for Patent Claims.</p>
       </clause>
       </preface><sections/>
       </nist-standard>
    OUTPUT

    FileUtils.rm_f "test.html"
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true)).
                         sub(%r{^.*<clause obligation="normative"><title>Call for Patent Claims</title>}m, '<clause obligation="normative"><title>Call for Patent Claims</title>')).to be_equivalent_to output
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
      :edition: 3
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
      :status: public-draft
      :iteration: 3
      :language: en
      :security: Client Confidential
      :keywords: a, b, c
      :fullname: Fred Flintstone
      :role: author
      :surname_2: Rubble
      :givenname_2: Barney
      :role_2: editor
      :affiliation_2: Bedrock Inc.
      :title-main: Main Title
      :title-sub: Subtitle
      :title-part: Part
      :partnumber: 2
      :doc-email: email@example.com
      :uri: http://www.example.com
      :doi: http://www.example2.com
      :series: nist-fips
      :subseries: information-security
      :comment-from: 2010-01-01
      :comment-to: 2010-01-02
      :comment-extended: 2010-01-03
    INPUT

    output = <<~"OUTPUT"
           <?xml version="1.0" encoding="UTF-8"?>
       <nist-standard xmlns="http://www.nist.gov/metanorma">
       <bibdata type="standard">
       <title>
         <title-main language="en" format="text/plain">Main Title</title-main>
         <title-sub language="en" format="text/plain">Subtitle</title-sub>
         </title>
         <uri>http://www.example.com</uri>
        <uri type="email">email@example.com</uri>
        <uri type="doi">http://www.example2.com</uri>
         <docidentifier type="nist">NIST FIPS 1000-3</docidentifier>
         <docidentifier type="nist-long">NIST Federal Information Processing Standards 1000-3</docidentifier>
         <docnumber>1000</docnumber>
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
              <affiliation>
   <org>
     <name>Bedrock Inc.</name>
   </org>
 </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>NIST</name>
           </organization>
         </contributor>
         <edition>3</edition>
         <version>
           <revision-date>2000-01-01</revision-date>
           <draft>3.4</draft>
         </version>
         <language>en</language>
         <script>Latn</script>
        <status>
          <stage>public-draft</stage>
          <iteration>3</iteration>
         </status>
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
         <series type="main">
           <title>NIST Federal Information Processing Standards</title>
           <abbreviation>NIST FIPS</abbreviation>
         </series>
         <series type="secondary">
                <title>Information Security</title>
        </series>
         <keyword>a</keyword>
         <keyword>b</keyword>
         <keyword>c</keyword>
         <commentperiod>
           <from>2010-01-01</from>
           <to>2010-01-02</to>
           <extended>2010-01-03</extended>
         </commentperiod>
       </bibdata>
    OUTPUT

    expect(Asciidoctor.convert(input, backend: :nist, header_footer: true).sub(%r{</bibdata>.*}m, "</bibdata>")).to be_equivalent_to output
  end

    it "ignores unrecognised status, overrides docidentifier" do
        expect(Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true).sub(%r{</bibdata>.*}m, "</bibdata>")).to be_equivalent_to <<~'OUTPUT'
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docidentifier: NIST FIPS 1000-2
      :docnumber: 1000
      :doctype: standard
      :edition: 2
      :revdate: 2000-01-01
      :draft: 3.4
      :copyright-year: 2001
      :status: draft-standard
      :iteration: 3
      :language: en
      :title-main: Main Title
    INPUT
    <nist-standard xmlns="http://www.nist.gov/metanorma">
<bibdata type="standard">
<title>
  <title-main language="en" format="text/plain">Main Title</title-main>
</title>
  <docidentifier type="nist">NIST FIPS 1000-2</docidentifier>
  <docidentifier type="nist-long">NIST Federal Information Processing Standards 1000-2</docidentifier>
  <docnumber>1000</docnumber>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <edition>2</edition>
<version>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version> 
  <language>en</language>
  <script>Latn</script>
  <status> 
  <stage>draft-standard</stage> 
  <iteration>3</iteration> 
  </status>
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
             <preface>
             #{AUTHORITY}
        <foreword obligation="informative">
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
    expect(html).to match(%r[ div[^{]+\{[^}]+font-family: "Libre Baskerville", serif;]m)
    expect(html).to match(%r[h1, h2, h3, h4, h5, h6 \{[^}]+font-family: "Libre Baskerville", serif;]m)
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

  it "populates boilerplate from file" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :boilerplate-authority: spec/assets/authority.xml
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
             <preface>
<authority>ABC</authority>
</preface><sections/>
</nist-standard>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output

  end

  it "populates initial boilerplate" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :docnumber: ABC
      :revdate: 2013-01-01
      :uri: http://www.example.com
      :comment-from: 2010-01-01
      :comment-to: 2010-01-02
      :comment-extended: 2010-01-03
      :doc-email: email@example.com
    INPUT

    output = <<~"OUTPUT"
      <nist-standard xmlns="http://www.nist.gov/metanorma">
<bibdata type="standard">
  <title>
    <title-main language="en" format="text/plain">Document title</title-main>
  </title>
  <uri>http://www.example.com</uri>
  <uri type="email">email@example.com</uri>
  <docidentifier type="nist">NIST  ABC</docidentifier>
  <docidentifier type="nist-long">NIST  ABC</docidentifier>
  <docnumber>ABC</docnumber>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <version>
    <revision-date>2013-01-01</revision-date>
  </version>
  <language>en</language>
  <script>Hans</script>
  <status>
    <stage>final</stage>
  </status>
  <copyright>
    <from>2019</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <committee/>
  </editorialgroup>
  <commentperiod>
    <from>2010-01-01</from>
    <to>2010-01-02</to>
    <extended>2010-01-03</extended>
  </commentperiod>
</bibdata>
<preface><authority>
       <title>Authority</title>

       <authority1>
       <p id="_">This publication has been developed by NIST in accordance with its statutory responsibilities under the Federal Information Security Modernization Act (FISMA) of 2014, 44 U.S.C. § 3551 <em>et seq.</em>, Public Law (P.L.) 113-283. NIST is responsible for developing information security standards and guidelines, including minimum requirements for federal information systems, but such standards and guidelines shall not apply to national security systems without the express approval of appropriate federal officials exercising policy authority over such systems. This guideline is consistent with the requirements of the Office of Management and Budget (OMB) Circular A-130.</p>

       <p id="_">Nothing in this publication should be taken to contradict the standards and guidelines made mandatory and binding on federal agencies by the Secretary of Commerce under statutory authority. Nor should these guidelines be interpreted as altering or superseding the existing authorities of the Secretary of Commerce, Director of the OMB, or any other federal official. This publication may be used by nongovernmental organizations on a voluntary basis and is not subject to copyright in the United States. Attribution would, however, be appreciated by NIST.</p>
       </authority1>

       <authority2>
       <p align="center" id="_">National Institute of Standards and Technology ABC <br/>
       Natl. Inst. Stand. Technol. ABC, () <br/>
       CODEN: NSPUE2</p>


       <p align="center" id="_">This publication is available free of charge from: <br/>
         <link target="http://www.example.com"/></p>

       </authority2>

       <authority3>
       <p id="_">Any mention of commercial products or reference to commercial organizations is for information only; it does not imply recommendation or endorsement by the United States Government, nor does it imply that the products mentioned are necessarily the best available for the purpose.</p>

       <p id="_">There may be references in this publication to other publications currently under development by NIST in accordance with its assigned statutory responsibilities. The information in this publication, including concepts and methodologies, may be used by Federal agencies even before the completion of such companion publications. Thus, until each publication is completed, current requirements, guidelines, and procedures, where they exist, remain operative. For planning and transition purposes, Federal agencies may wish to closely follow the development of these new publications by NIST.</p>

       <p id="_">Organizations are encouraged to review all draft publications during public comment periods and provide feedback to NIST. Many NIST cybersecurity publications, other than the ones noted above, are available at <link target="https://csrc.nist.gov/publications"/>
       </p></authority3>

       <authority4>

       <p align="center" id="_">[2010-01-03: Comment period extended]</p>



       <p align="center" id="_"><strong>Public comment period: <em>2010-01-01</em> through <em>2010-01-02</em></strong></p>

       </authority4>

       <authority5>
       <title>Comments on this publication may be submitted to:</title>

       <p align="center" id="_">National Institute of Standards and Technology <br/>
       Attn: Computer Security Division, Information Technology Laboratory <br/>
       100 Bureau Drive (Mail Stop 8930) Gaithersburg, MD 20899-8930 <br/>
       Email: <link target="mailto:email@example.com"/></p>

       <p align="center" id="_">All comments are subject to release under the Freedom of Information Act (FOIA).</p>
       </authority5>
       </authority>
       </preface>

<sections/>
</nist-standard>

    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "recognises preface sections" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      .Reports on Computer Systems Technology
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
    <preface>
    <abstract id="_">
         <p id="_">This is an abstract</p>
       </abstract>
    #{AUTHORITY}
<foreword obligation="informative">
  <title>Reports on Computer Systems Technology</title>
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
</preface><sections>

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
             <preface>
    #{AUTHORITY}
         </preface>
       <sections>
        <p id="_"><em>emphasis</em>
       <strong>strong</strong>
       <tt>monospace</tt>
       “double quote”
       ‘single quote’
       super<sup>script</sup>
       sub<sub>script</sub>
       <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>a</mi><mn>90</mn></msub></math></stem> 
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
             <preface>
    #{AUTHORITY}
         </preface>
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
             <preface>
    #{AUTHORITY}
         </preface>
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
             <preface>
    #{AUTHORITY}
         </preface>
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

      [appendix]
      == Glossary

      === Normal Terms

      Definition

      ====
      Example
      ====
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
             <preface>
    #{AUTHORITY}
         </preface>
         <sections>

</sections><annex id="_" obligation="normative">
  <title>Glossary</title>
    <terms id="_" obligation="normative">
  <term id="_"><preferred>Normal Terms</preferred><definition><p id="_">Definition</p></definition>
<termexample id="_">
  <p id="_">Example</p>
</termexample></term>
</terms>
</annex>
</nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "processes nested glossaries" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      == Glossary

      === Normal Terms

      ==== Normal Terms

      Definition

      ====
      Example
      ====
    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
            <preface>
    #{AUTHORITY}
         </preface>
         <sections>

</sections><annex id="_" obligation="normative">
  <title>Glossary</title>
    <terms id="_" obligation="normative">
  <title>Normal Terms</title>
  <term id="_"><preferred>Normal Terms</preferred><definition><p id="_">Definition</p></definition>
<termexample id="_">
  <p id="_">Example</p>
</termexample></term>
</terms>
</annex>
</nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end

  it "warns that the references are not in the expected sequence" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/Reference clauses[^\n\r]*do not follow expected pattern in NIST/).to_stderr
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      [bibliography]
      == Normative References
    INPUT
  end

  it "does not warn that the references are not in the expected sequence when they are acceptable" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.not_to output(/Reference clauses[^\n\r]*do not follow expected pattern in NIST/).to_stderr
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == References
    INPUT
  end

  it "processes bibliographies as appendixes in legacy format" do
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :biblio-as-appendix:

      [appendix]
      == First Appendix

      ====
      Example
      ====

      [bibliography]
      == References

      [appendix]
      == Second Appendix

      ====
      Example
      ====

    INPUT

    output = <<~"OUTPUT"
    #{BLANK_HDR}
         <preface>
    #{AUTHORITY}
         </preface>
         <sections/>

         <annex id="_" obligation="normative">
         <title>First Appendix</title>
         <example id="_">
         <p id="_">Example</p>
       </example>
       </annex><annex id="_" obligation="normative">
         <title>Bibliography</title>
         <references id="_" obligation="informative"/>
       </annex><annex id="_" obligation="normative">
         <title>Second Appendix</title>
         <example id="_">
         <p id="_">Example</p>
       </example>
       </annex>
       </nist-standard>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :nist, header_footer: true))).to be_equivalent_to output
  end


end
