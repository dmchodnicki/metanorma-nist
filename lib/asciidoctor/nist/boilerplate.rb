module Asciidoctor
  module NIST
    class Converter < Standoc::Converter
      CALL_FOR_PATENT_CLAIMS = <<~END.freeze
      <clause><title>Call for Patent Claims</title>
      <p>This public review includes a call for information on essential patent claims (claims whose use would be required for compliance with the guidance or requirements in this Information Technology Laboratory (ITL) draft publication). Such guidance and/or requirements may be directly stated in this ITL Publication or by reference to another publication. This call also includes disclosure, where known, of the existence of pending U.S. or foreign patent applications relating to this ITL draft publication and of any relevant unexpired U.S. or foreign patents.</p>

<p>ITL may require from the patent holder, or a party authorized to make assurances on its behalf, in written or electronic form, either:</p>

<ol type="arabic"><li><p>assurance in the form of a general disclaimer to the effect that such party does not hold and does not currently intend holding any essential patent claim(s); or</p></li>

<li><p>assurance that a license to such essential patent claim(s) will be made available to applicants desiring to utilize the license for the purpose of complying with the guidance or requirements in this ITL draft publication either:</p>

        <ol type="roman"><li><p>under reasonable terms and conditions that are demonstrably free of any unfair discrimination; or</p></li>

        <li><p>without compensation and under reasonable terms and conditions that are demonstrably free of any unfair discrimination.</p></li></ol>
</li></ol>

<p>Such assurance shall indicate that the patent holder (or third party authorized to make assurances on its behalf) will include in any documents transferring ownership of patents subject to the assurance, provisions sufficient to ensure that the commitments in the assurance are binding on the transferee, and that the transferee will similarly include appropriate provisions in the event of future transfers with the goal of binding each successor-in-interest.</p>

<p>The assurance shall also indicate that it is intended to be binding on successors-in-interest regardless of whether such provisions are included in the relevant transfer documents.</p>

<p>Such statements should be addressed to: ITL-POINT-OF_CONTACT.</p>
</clause>
      END

      PATENT_DISCLOSURE_NOTICE1 = <<~END.freeze
            <clause><title>Patent Disclosure Notice</title>
      <p>NOTICE: The Information Technology Laboratory (ITL) has requested that holders of patent claims whose use may be required for compliance with the guidance or requirements of this publication disclose such patent claims to ITL. However, holders of patents are not obligated to respond to ITL calls for patents and ITL has not undertaken a patent search in order to identify which, if any, patents may apply to this publication. </p>
<p>Following the ITL call for the identification of patent claims whose use may be required for compliance with the guidance or requirements of this publication, notice of one or more such claims has been received. </p>
<p>By publication, no position is taken by ITL with respect to the validity or scope of any patent claim or of any rights in connection therewith. The known patent holder(s) has (have), however, provided to NIST a letter of assurance stating either (1) a general disclaimer to the effect that it does (they do) not hold and does (do) not currently intend holding any essential patent claim(s), or (2) that it (they) will negotiate royalty-free or royalty-bearing licenses with other parties on a demonstrably nondiscriminatory basis with reasonable terms and conditions. </p>
<p>Details may be obtained from ITL-POINT-OF_CONTACT. </p>
<p>No representation is made or implied that this is the only license that may be required to avoid patent infringement in the use of this publication. </p>
</clause>
      END

      PATENT_DISCLOSURE_NOTICE2 = <<~END.freeze
            <clause><title>Patent Disclosure Notice</title>
      <p>NOTICE: ITL has requested that holders of patent claims whose use may be required for compliance with the guidance or requirements of this publication disclose such patent claims to ITL. However, holders of patents are not obligated to respond to ITL calls for patents and ITL has not undertaken a patent search in order to identify which, if any, patents may apply to this publication.</p>
<p>As of the date of publication and following call(s) for the identification of patent claims whose use may be required for compliance with the guidance or requirements of this publication, no such patent claims have been identified to ITL.</p>
<p>No representation is made or implied by ITL that licenses are not required to avoid patent infringement in the use of this publication.</p>
</clause>
      END

      def boilerplate(x_orig)
        x = x_orig.dup
        x.root.add_namespace(nil, EXAMPLE_NAMESPACE)
        x = Nokogiri::XML(x.to_xml)
        conv = IsoDoc::NIST::HtmlConvert.new({})
        conv.metadata_init("en", "Latn", {})
        conv.info(x, nil)
        conv.labels = {nist_division: @nistdivision,
                       nist_division_address: @nistdivisionaddress}
        file = @boilerplateauthority ? "#{@localdir}/#{@boilerplateauthority}" :
          File.join(File.dirname(__FILE__),"nist_intro.xml")
        conv.populate_template((File.read(file, encoding: "UTF-8")), nil)
      end
    end
  end
end
