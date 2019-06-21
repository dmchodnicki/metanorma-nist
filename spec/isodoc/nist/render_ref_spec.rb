require "spec_helper"

RSpec.describe IsoDoc::NIST do

    it "formats a preformatted NIST SP reference" do
    input = <<~"INPUT"
  <nist-standard xmlns="http://riboseinc.com/isoxml">
  <preface><foreword>
  <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
  <eref bibitemid="ISO712"/>
  </p>
  </foreword>
  </preface>
  <bibliography><references id="_normative_references" obligation="informative"><title>Normative References</title>
  <bibitem id="ISO712" type="standard">
  <formattedref format="application/x-isodoc+xml">Homeland Security Presidential Directive 12, <em>Policy for a Common Identification Standard for Federal Employees and Contractors</em>, August 27, 2004. <link target="https://www.dhs.gov/homeland-security-presidential-directive-12"/> [accessed 5/16/18]</formattedref>
  <docidentifier>HSPD-12</docidentifier>
  </bibitem>
  </references>
  </bibliography>
  </nist-standard>
    INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
      <div>
    <h1 class="ForewordTitle"/>
        <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
         <a href="#ISO712">HSPD-12</a>
         </p>
             </div>
             <br/>
             <div>
               <h1 class="Section3">References</h1>
               <p id="ISO712" class="NormRef">Homeland Security Presidential Directive 12, <i>Policy for a Common Identification Standard for Federal Employees and Contractors</i>, August 27, 2004. <a href="https://www.dhs.gov/homeland-security-presidential-directive-12">https://www.dhs.gov/homeland-security-presidential-directive-12</a> [accessed 5/16/18] [HSPD-12] </p>
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

 it "formats a non-NIST reference" do
    input = <<~"INPUT"
  <nist-standard xmlns="http://riboseinc.com/isoxml">
  <preface><foreword>
  <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
  <eref bibitemid="ISO712"/>
  </p>
  </foreword>
  </preface>
  <bibliography><references id="_normative_references" obligation="informative"><title>Normative References</title>
  <bibitem id="ISO712" type="book">
 <title>Canada Remembers the Korean War</title>
  <docidentifier type="ISBN">0662674979</docidentifier>
  <date type="published"><on>2003</on></date>
  <contributor>
    <role type="author"/>
    <person><name>
      <surname>Giesler</surname> 
      <forename>Patricia</forename>
    </name></person>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>Veterans Affairs Canada</name>
    </organization> 
  </contributor>
  <place>Charlottetown, P.E.I.</place>
  <accessLocation>Library</accessLocation>
  <classification type="Dewey">971.06 GIE 2003</classification>
  </bibitem>
  </references>
  </bibliography>
  </nist-standard>
    INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
      <div>
    <h1 class="ForewordTitle"/>
        <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
         <a href="#ISO712">ISBN 0662674979</a>
         </p>
             </div>
             <br/>
             <div>
               <h1 class="Section3">References</h1>
               <p id="ISO712" class="NormRef">Giesler P (2003) <I>Canada Remembers the Korean War</I>. (Charlottetown, P.E.I.: Veterans Affairs Canada), 2003. ISBN 0662674979. At: Library.</p>
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



  it "formats a NIST SP reference" do
    input = <<~"INPUT"
  <nist-standard xmlns="http://riboseinc.com/isoxml">
  <preface><foreword>
  <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
  <eref bibitemid="ISO712"/>
  </p>
  </foreword>
  </preface>
  <bibliography><references id="_normative_references" obligation="informative"><title>Normative References</title>
  <bibitem id="ISO712" type="standard">
  <title language="en" format="text/plain" type="main">Guidelines for the Use of PIV Credentials in Facility Access</title>
  <title language="en" format="text/plain" type="document-class">Information Security</title>
  <uri>https://doi.org/10.6028/NIST.SP.800-116r1</uri>
  <uri type="email">piv_comments@nist.gov</uri>
  <docidentifier type="NIST">SP 800-116 (June 01, 2018)</docidentifier>
  <docidentifier type="nist-long">NIST Special Publication 800-116 (June 01, 2018)</docidentifier>
  <docidentifier type="nist-mr">NIST.SP...2018-06-01</docidentifier>
  <docnumber>800-116</docnumber>
  <date type="issued">
    <from>2018-06-01</from>
    <to>2018-06-02</to>
  </date>
  <date type="updated">
    <on>2018-11-13</on>
  </date>
  <contributor>
    <role type="author"/>
    <person>
      <name>
        <forename>Hildegard</forename>
        <surname>Ferraiolo</surname>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="author"/>
    <person>
      <name>
        <completename>Ketan Mehta</completename>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="author"/>
    <organization>
      <name>FEMA</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <edition>Revision 1</edition>
  <version>
    <revision-date>2018-06-01</revision-date>
  </version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>final</stage>
    <substage>active</substage>
  </status>
  <copyright>
    <from>2018</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <series type="main">
    <title>NIST Special Publication</title>
    <abbreviation>NIST SP</abbreviation>
  </series>
  <keyword>Conditioning functions</keyword>
  <keyword>entropy source</keyword>
  <keyword>health testing</keyword>
  <keyword>min-entropy</keyword>
  <keyword>noise source</keyword>
  <keyword>predictors</keyword>
  <keyword>random number generators</keyword>
</bibitem>
  </references>
  </bibliography>
  </nist-standard>
    INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
      <div>
    <h1 class="ForewordTitle"/>
        <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
         <a href="#ISO712">SP 800-116 (June 01, 2018)</a>
         </p>
             </div>
             <br/>
             <div>
               <h1 class="Section3">References</h1>
               <p id="ISO712" class="NormRef">Ferraiolo H, Ketan Mehta, FEMA (June 01, 2018&#8211;June 02, 2018 (updated November 13, 2018)) <i>Guidelines for the Use of PIV Credentials in Facility Access</i>. (National Institute of Standards and Technology, Gaithersburg, MD),  NIST Special Publication (SP) 800-116 Rev. 1, June 01, 2018&#8211;June 02, 2018 (updated November 13, 2018). https://doi.org/10.6028/NIST.SP.800-116r1.</p>
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

    it "formats a draft NIST SP reference" do
    input = <<~"INPUT"
  <nist-standard xmlns="http://riboseinc.com/isoxml">
  <preface><foreword>
  <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
  <eref bibitemid="ISO712"/>
  </p>
  </foreword>
  </preface>
  <bibliography><references id="_normative_references" obligation="informative"><title>Normative References</title>
  <bibitem id="ISO712" type="standard">
  <title language="en" format="text/plain" type="main">Guidelines for the Use of PIV Credentials in Facility Access</title>
  <title language="en" format="text/plain" type="document-class">Information Security</title>
  <uri>https://doi.org/10.6028/NIST.SP.800-116r1</uri>
  <uri type="email">piv_comments@nist.gov</uri>
  <docidentifier type="NIST">SP 800-116 (3PD) (June 01, 2018)</docidentifier>
  <docidentifier type="nist-long">NIST Special Publication 800-116 (3PD) (June 01, 2018)</docidentifier>
  <docidentifier type="nist-mr">NIST.SP...2018-06-01</docidentifier>
  <docnumber>800-116</docnumber>
  <date type="circulated">
    <on>2018-06-01</on>
  </date>
  <contributor>
    <role type="editor"/>
    <person>
      <name>
        <initials>H.</initials>
        <initials>J.</initials>
        <surname>Ferraiolo</surname>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="editor"/>
    <person>
      <name>
        <completename>Ketan Mehta</completename>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <version>
    <revision-date>2018-06-01</revision-date>
  </version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>draft-public</stage>
    <substage>active</substage>
    <iteration>3</iteration>
  </status>
  <copyright>
    <from>2018</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <series type="main">
    <formattedref>NIST Special Publication (SP) 800-116 Rev. 1</formattedref>
  </series>
  <keyword>Conditioning functions</keyword>
  <keyword>entropy source</keyword>
  <keyword>health testing</keyword>
  <keyword>min-entropy</keyword>
  <keyword>noise source</keyword>
  <keyword>predictors</keyword>
  <keyword>random number generators</keyword>
</bibitem>
  </references>
  </bibliography>
  </nist-standard>
    INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
      <div>
    <h1 class="ForewordTitle"/>
        <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
         <a href="#ISO712">SP 800-116 (3PD) (June 01, 2018)</a>
         </p>
             </div>
             <br/>
             <div>
               <h1 class="Section3">References</h1>
               <p id="ISO712" class="NormRef">Ferraiolo HJ, Ketan Mehta (Eds.) (June 01, 2018) <I>Guidelines for the Use of PIV Credentials in Facility Access</I>. (National Institute of Standards and Technology, Gaithersburg, MD),  Draft (Third Public Draft) NIST Special Publication (SP) 800-116 Rev. 1, June 01, 2018. https://doi.org/10.6028/NIST.SP.800-116r1.</p>
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

  it "formats a NIST FIPS reference" do
    input = <<~"INPUT"
  <nist-standard xmlns="http://riboseinc.com/isoxml">
  <preface><foreword>
  <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
  <eref bibitemid="ISO712"/>
  </p>
  </foreword>
  </preface>
  <bibliography><references id="_normative_references" obligation="informative"><title>Normative References</title>
  <bibitem id="ISO712" type="standard">
  <title language="en" format="text/plain" type="main">Guidelines for the Use of PIV Credentials in Facility Access</title>
  <title language="en" format="text/plain" type="document-class">Information Security</title>
  <uri>https://doi.org/10.6028/NIST.SP.800-116r1</uri>
  <uri type="email">piv_comments@nist.gov</uri>
  <docidentifier type="NIST">SP 800-116 (June 01, 2018)</docidentifier>
  <docidentifier type="nist-long">NIST Special Publication 800-116 (June 01, 2018)</docidentifier>
  <docidentifier type="nist-mr">NIST.SP...2018-06-01</docidentifier>
  <docnumber>800-116</docnumber>
  <date type="issued">
    <on>2018-06-01</on>
  </date>
  <contributor>
    <role type="author"/>
    <person>
      <name>
        <forename>Hildegard</forename>
        <surname>Ferraiolo</surname>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="author"/>
    <person>
      <name>
        <completename>Ketan Mehta</completename>
      </name>
      <affiliation>
        <organization>
          <name>Computer Security Division, Information Technology Laboratory</name>
        </organization>
      </affiliation>
    </person>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>NIST</name>
    </organization>
  </contributor>
  <version>
    <revision-date>2018-06-01</revision-date>
  </version>
  <language>en</language>
  <script>Latn</script>
  <status>
    <stage>final</stage>
    <substage>active</substage>
  </status>
  <copyright>
    <from>2018</from>
    <owner>
      <organization>
        <name>NIST</name>
      </organization>
    </owner>
  </copyright>
  <series type="main">
    <title>NIST Federal Information Processing Standards</title>
    <abbreviation>FIPS</abbreviation>
    <number>800-116</number>
    <partnumber>1</partnumber>
  </series>
  <keyword>Conditioning functions</keyword>
  <keyword>entropy source</keyword>
  <keyword>health testing</keyword>
  <keyword>min-entropy</keyword>
  <keyword>noise source</keyword>
  <keyword>predictors</keyword>
  <keyword>random number generators</keyword>
</bibitem>
  </references>
  </bibliography>
  </nist-standard>
    INPUT

  output = <<~"OUTPUT"
  #{HTML_HDR}
      <div>
    <h1 class="ForewordTitle"/>
        <p id="_f06fd0d1-a203-4f3d-a515-0bdba0f8d83f">
         <a href="#ISO712">SP 800-116 (June 01, 2018)</a>
         </p>
             </div>
             <br/>
             <div>
               <h1 class="Section3">References</h1>
               <p id="ISO712" class="NormRef">National Institute of Standards and Technology (June 01, 2018) <I>Guidelines for the Use of PIV Credentials in Facility Access</I>. (U.S. Department of Commerce, Washington, D.C.),  NIST Federal Information Processing Standards (FIPS) 800-116.1, June 01, 2018. https://doi.org/10.6028/NIST.SP.800-116r1.</p>
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
