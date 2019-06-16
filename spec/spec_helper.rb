require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bundler/setup"
require "asciidoctor"
require "metanorma-nist"
require "asciidoctor/nist"
require "isodoc/nist/html_convert"
require "isodoc/nist/word_convert"
require "asciidoctor/standoc/converter"
require "rspec/matchers"
require "equivalent-xml"
require "htmlentities"
require "metanorma"
require "metanorma/nist"
require "relaton_nist"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def strip_guid(x)
  x.gsub(%r{ id="_[^"]+"}, ' id="_"').gsub(%r{ target="_[^"]+"}, ' target="_"')
end

def htmlencode(x)
  HTMLEntities.new.encode(x, :hexadecimal).gsub(/&#x3e;/, ">").gsub(/&#xa;/, "\n").
    gsub(/&#x22;/, '"').gsub(/&#x3c;/, "<").gsub(/&#x26;/, '&').gsub(/&#x27;/, "'").
    gsub(/\\u(....)/) { |s| "&#x#{$1.downcase};" }
end

ASCIIDOC_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:

HDR

VALIDATING_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

HDR

BLANK_HDR = <<~"HDR"
       <?xml version="1.0" encoding="UTF-8"?>
       <nist-standard xmlns="http://www.nist.gov/metanorma">
       <bibdata type="standard">
          <title type="main" language="en" format="text/plain">Document title</title> 
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>NIST</name>
           </organization>
         </contributor>
        <language>en</language>
         <script>Latn</script>
        <status> 
          <stage>final</stage> 
          <substage>active</substage> 
        </status> 
         <copyright>
           <from>#{Time.new.year}</from>
           <owner>
             <organization>
               <name>NIST</name>
             </organization>
           </owner>
         </copyright>
         <ext>
  <doctype>standard</doctype>
        </ext>
       </bibdata>
       HDR

AUTHORITY = <<~"HDR"
       <boilerplate>
       <legal-statement>
       <clause id="authority1" obligation="normative">
       <title>Authority</title>
       <p id="_">This publication has been developed by NIST in accordance with its statutory responsibilities under the Federal Information Security Modernization Act (FISMA) of 2014, 44 U.S.C. § 3551 <em>et seq.</em>, Public Law (P.L.) 113-283. NIST is responsible for developing information security standards and guidelines, including minimum requirements for federal information systems, but such standards and guidelines shall not apply to national security systems without the express approval of appropriate federal officials exercising policy authority over such systems. This guideline is consistent with the requirements of the Office of Management and Budget (OMB) Circular A-130.</p>

       <p id="_">Nothing in this publication should be taken to contradict the standards and guidelines made mandatory and binding on federal agencies by the Secretary of Commerce under statutory authority. Nor should these guidelines be interpreted as altering or superseding the existing authorities of the Secretary of Commerce, Director of the OMB, or any other federal official. This publication may be used by nongovernmental organizations on a voluntary basis and is not subject to copyright in the United States. Attribution would, however, be appreciated by NIST.</p>
       </clause>

       <clause id="authority2" obligation="normative">
       <p align="center" id="_">National Institute of Standards and Technology <br/>
       Natl. Inst. Stand. Technol. , () <br/>
       CODEN: NSPUE2</p>


       </clause>

       <clause id="authority3" obligation="normative">
       <p id="_">Any mention of commercial products or reference to commercial organizations is for information only; it does not imply recommendation or endorsement by the United States Government, nor does it imply that the products mentioned are necessarily the best available for the purpose.</p>

       <p id="_">There may be references in this publication to other publications currently under development by NIST in accordance with its assigned statutory responsibilities. The information in this publication, including concepts and methodologies, may be used by Federal agencies even before the completion of such companion publications. Thus, until each publication is completed, current requirements, guidelines, and procedures, where they exist, remain operative. For planning and transition purposes, Federal agencies may wish to closely follow the development of these new publications by NIST.</p>

       <p id="_">Organizations are encouraged to review all draft publications during public comment periods and provide feedback to NIST. Many NIST cybersecurity publications, other than the ones noted above, are available at <link target="https://csrc.nist.gov/publications"/>
       </p></clause>
       </legal-statement>

       <feedback-statement>
       <clause id="authority5" obligation="normative">
       <p align="center" id="_"><strong>Comments on this publication may be submitted to:</strong></p>

       <p align="center" id="_">National Institute of Standards and Technology <br/>
       Attn: Computer Security Division, Information Technology Laboratory <br/>
       100 Bureau Drive (Mail Stop 8930) Gaithersburg, MD 20899-8930 <br/>
       </p>

       <p align="center" id="_">All comments are subject to release under the Freedom of Information Act (FOIA).</p>
       </clause>
       </feedback-statement>
       </boilerplate>

HDR

HTML_HDR = <<~"HDR"
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
HDR

