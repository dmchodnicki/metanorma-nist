require "asciidoctor"
require "asciidoctor/nist"
require "asciidoctor/standoc/converter"
require "isodoc/nist/html_convert"
require "isodoc/nist/word_convert"
require_relative "front"
require "fileutils"

module Asciidoctor
  module NIST
    class Converter < Standoc::Converter

      register_for "nist"

      def title_validate(root)
        nil
      end

      def example(node)
        return pseudocode_example(node) if node.attr("style") == "pseudocode"
        super
      end

      def pseudocode_example(node)
        noko do |xml|
          xml.figure **{id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node), 
                        type: "pseudocode"} do |ex|
            figure_title(node, ex)
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def table(node)
        return errata(node) if node.attr("style") == "errata"
        super
      end

      def errata(node)
        cols = []
        node.rows[:head][-1].each { |c| cols << c.text.downcase }
        table = []
        node.rows[:body].each do |r|
          row = {}
          r.each_with_index do |c, i|
            row[cols[i]] = c.content.join("")
          end
          table << row
        end
        noko do |xml|
          xml.errata do |errata|
            table.each do |entry|
              errata.row do |row|
                row.date { |x| x << entry["date"] }
                row.type { |x| x << entry["type"] }
                row.change { |x| x << entry["change"] }
                row.pages { |x| x << entry["pages"] }
              end
            end
          end
        end
      end

      def dlist(node)
        return glossary(node) if node.attr("style") == "glossary"
        super
      end

      def glossary(node)
        noko do |xml|
          xml.dl **{id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node),
                    type: "glossary"} do |xml_dl|
            node.items.each do |terms, dd|
              dt(terms, xml_dl)
              dd(dd, xml_dl)
            end
          end
        end.join("\n")
      end

      def cleanup(xmldoc)
        sourcecode_cleanup(xmldoc)
        super
      end

      def nistvariable_insert(n)
        acc = []
        n.text.split(/((?<!\{)\{{3}(?!\{)|(?<!\})\}{3}(?!\}))/).each_slice(4).
          map do |a|
          acc << Nokogiri::XML::Text.new(a[0], n.document)
          next unless a.size == 4
          acc << Nokogiri::XML::Node.new("nistvariable", n)
          acc[-1].content = a[2]
        end
        acc
      end

      def sourcecode_cleanup(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          x.traverse do |n|
            next unless n.text?
            n.replace(Nokogiri::XML::NodeSet.new(n.document, 
                                                 nistvariable_insert(n)))
          end
        end
      end

      # skip annex/terms/terms, which is empty node
       def termdef_subclause_cleanup(xmldoc)
        xmldoc.xpath("//terms[terms]").each do |t|
          next if t.parent.name == "terms"
          t.children.each { |n| n.parent = t.parent }
          t.remove
        end
      end

      def makexml(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>\n<nist-standard>"]
        @draft = node.attributes.has_key?("draft")
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</nist-standard>"
        result = textcleanup(result)
        ret1 = cleanup(Nokogiri::XML(result))
        validate(ret1) unless @novalid
        ret1.root.add_namespace(nil, EXAMPLE_NAMESPACE)
        ret1
      end

      def doctype(node)
        d = node.attr("doctype")
        unless %w{policy-and-procedures best-practices 
          supporting-document report legal directives proposal 
          standard}.include? d
          warn "#{d} is not a legal document type: reverting to 'standard'"
          d = "standard"
        end
        d
      end

      def init(node)
        @callforpatentclaims = node.attr("call-for-patent-claims")
        @commitmenttolicence = node.attr("commitment-to-licence")
        @patentcontact = node.attr("patent-contact")
        @biblioasappendix = node.attr("biblio-as-appendix")
        super
      end

      def document(node)
        init(node)
        ret1 = makexml(node)
        ret = ret1.to_xml(indent: 2)
        unless node.attr("nodoc") || !node.attr("docfile")
          filename = node.attr("docfile").gsub(/\.adoc/, ".xml").
            gsub(%r{^.*/}, "")
          File.open(filename, "w") { |f| f.write(ret) }
          html_converter(node).convert filename unless node.attr("nodoc")
          word_converter(node).convert filename unless node.attr("nodoc")
          pdf_converter(node).convert filename unless node.attr("nodoc")
        end
        @files_to_delete.each { |f| FileUtils.rm f }
        ret
      end

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "nist.rng"))
      end

      def sections_cleanup(x)
        super
        x.xpath("//*[@inline-header]").each do |h|
          h.delete("inline-header")
        end
      end

      def move_sections_into_preface(x, preface)
        abstract = x.at("//abstract")
        preface.add_child abstract.remove if abstract
        foreword = x.at("//foreword")
        preface.add_child foreword.remove if foreword
        introduction = x.at("//introduction")
        preface.add_child introduction.remove if introduction
        x.xpath("//clause[@preface]").each do |c|
          c.delete("preface")
          title = c&.at("./title")&.text.downcase
          c.name = "reviewernote" if title == "note to reviewers"
          c.name = "executivesummary" if title == "executive summary"
          preface.add_child c.remove
        end
        callforpatentclaims(x, preface)
      end

      CALL_FOR_PATENT_CLAIMS = <<~END.freeze
      <clause><title>Call for Patent Claims</title>
      <p>This public review includes a call for information on essential patent claims (claims whose use would be required for compliance with the guidance or requirements in this Information Technology Laboratory (ITL) draft publication). Such guidance and/or requirements may be directly stated in this ITL Publication or by reference to another publication. This call also includes disclosure, where known, of the existence of pending U.S. or foreign patent applications relating to this ITL draft publication and of any relevant unexpired U.S. or foreign patents.</p>

<p>ITL may require from the patent holder, or a party authorized to make assurances on its behalf, in written or electronic form, either:</p>

<ol><li><p>assurance in the form of a general disclaimer to the effect that such party does not hold and does not currently intend holding any essential patent claim(s); or</p></li>

<li><p>assurance that a license to such essential patent claim(s) will be made available to applicants desiring to utilize the license for the purpose of complying with the guidance or requirements in this ITL draft publication either:</p>

        <ol><li><p>under reasonable terms and conditions that are demonstrably free of any unfair discrimination; or</p></li>

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

      def callforpatentclaims(x, preface)
        if @callforpatentclaims
          docemail = x&.at("//uri[@type = 'email']")&.text || "???"
          docnumber = x&.at("//docnumber")&.text || "???"
          status = x&.at("//bibdata/status/stage")&.text 
          published = status.nil? || status == "final"
          preface.add_child patent_text(published, docemail, docnumber)
        end
      end

      def patent_text(published, docemail, docnumber)
        patent = (!published ? CALL_FOR_PATENT_CLAIMS :
                  (@commitmenttolicence ? PATENT_DISCLOSURE_NOTICE1 :
                   PATENT_DISCLOSURE_NOTICE2)).clone
        patent.gsub(/ITL-POINT-OF_CONTACT/, published ?
                    (@patentcontact || docemail) :
                    (@patentcontact ||
                     "#{docemail}, with the Subject: #{docnumber} "\
                     "Call for Patent Claims"))
      end

      def make_preface(x, s)
        if x.at("//foreword | //introduction | //abstract | //preface") ||
            @callforpatentclaims
          preface = s.add_previous_sibling("<preface/>").first
          move_sections_into_preface(x, preface)
          summ = x.at("//executivesummary") and preface.add_child summ.remove
        end
      end

      def clause_parse(attrs, xml, node)
        attrs[:preface] = true if node.attr("style") == "preface"
        super
      end

      def acknowledgements_parse(attrs, xml, node)
        xml.acknowledgements **attr_code(attrs) do |xml_section|
          xml_section << node.content
        end
      end

      def audience_parse(attrs, xml, node)
        xml.audience **attr_code(attrs) do |xml_section|
          xml_section << node.content
        end
      end

      def conformancetesting_parse(attrs, xml, node)
        xml.conformancetesting **attr_code(attrs) do |xml_section|
          xml_section << node.content
        end
      end

      def style(n, t)
        return
      end

      def section(node)
        a = { id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node) }
        noko do |xml|
          case sectiontype(node)
          when "normative references" then norm_ref_parse(a, xml, node)
          when "glossary", "terminology"
            if node.attr("style") == "appendix" && node.level == 1
              @term_def = true
              terms_annex_parse(a, xml, node)
              @term_def = false
            else
              clause_parse(a, xml, node)
            end
          else
            if @term_def 
              term_def_subclause_parse(a, xml, node)
            elsif @biblio then bibliography_parse(a, xml, node)
            elsif node.attr("style") == "bibliography"
              bibliography_parse(a, xml, node)
            elsif node.attr("style") == "abstract"
              abstract_parse(a, xml, node)
            elsif node.attr("style") == "appendix" && node.level == 1
              annex_parse(a, xml, node)
            else
              clause_parse(a, xml, node)
            end
          end
        end.join("\n")
      end

      def bibliography_parse(a, xml, node)
        @biblioasappendix and node.level == 1 and
          return bibliography_annex_parse(a, xml, node)
        super
      end

      def bibliography_annex_parse(attrs, xml, node)
        attrs1 = attrs.merge(id: "_" + UUIDTools::UUID.random_create)
        xml.annex **attr_code(attrs1) do |xml_section|
          xml_section.title { |t| t << "Bibliography" }
          @biblio = true
          xml.references **attr_code(attrs) do |xml_section|
            xml_section << node.content
          end
        end
        @biblio = false
      end

      def terms_annex_parse(attrs, xml, node)
        attrs1 = attrs.merge(id: "_" + UUIDTools::UUID.random_create)
        xml.annex **attr_code(attrs1) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section.terms **attr_code(attrs) do |terms|
            (s = node.attr("source")) && s.split(/,/).each do |s1|
              terms.termdocsource(nil, **attr_code(bibitemid: s1))
            end
            terms << node.content
          end
        end
      end

      SECTIONS_TO_VALIDATE = "//references[not(parent::clause)]/title | "\
        "//clause[descendant::references][not(parent::clause)]/title".freeze

      def section_validate(doc)
        super
        f = doc.xpath(SECTIONS_TO_VALIDATE)
        names = f.map { |s| s&.text }
        return if names.empty?
        return if names == ["References"]
        return if names == ["Bibliography"]
        return if names == ["References", "Bibliography"]
        warn "Reference clauses #{names.join(', ')} do not follow expected "\
          "pattern in NIST"
      end

      def sections_order_cleanup(x)
        s = x.at("//sections")
        make_preface(x, s)
        x.xpath("//sections/annex").reverse_each { |r| s.next = r.remove }
      end

      def html_converter(node)
        IsoDoc::NIST::HtmlConvert.new(html_extract_attributes(node))
      end

      def word_converter(node)
        IsoDoc::NIST::WordConvert.new(doc_extract_attributes(node))
      end

      def pdf_converter(node)
        IsoDoc::NIST::PdfConvert.new(html_extract_attributes(node))
      end
    end
  end
end
