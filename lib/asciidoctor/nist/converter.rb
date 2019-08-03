require "asciidoctor"
require "asciidoctor/nist"
require "asciidoctor/standoc/converter"
require "isodoc/nist/html_convert"
require "isodoc/nist/word_convert"
require_relative "front"
require_relative "boilerplate"
require_relative "validate"
require_relative "cleanup"
require "fileutils"

module Asciidoctor
  module NIST
    class Converter < Standoc::Converter

      register_for "nist"

      def example(node)
        role = node.role || node.attr("style")
        return pseudocode_example(node) if role == "pseudocode"
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
        role = node.role || node.attr("style")
        return errata(node) if role == "errata"
        super
      end

      def errata1(node)
        cols = []
        node.rows[:head][-1].each { |c| cols << c.text.downcase }
        table = []
        node.rows[:body].each do |r|
          row = {}
          r.each_with_index { |c, i| row[cols[i]] = c.content.join("") }
          table << row
        end
        table
      end

      def errata_row(row, entry)
        row.date { |x| x << entry["date"] }
        row.type { |x| x << entry["type"] }
        row.change { |x| x << entry["change"] }
        row.pages { |x| x << entry["pages"] }
      end

      def errata(node)
        table = errata1(node)
        noko do |xml|
          xml.errata do |errata|
            table.each do |entry|
              errata.row do |row|
                errata_row(row, entry)
              end
            end
          end
        end
      end

      def dlist(node)
        role = node.role || node.attr("style")
        return glossary(node) if role == "glossary"
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
        d = "standard" if d == "article" # article is Asciidoctor default
        d
      end

      def init(node)
        @callforpatentclaims = node.attr("call-for-patent-claims")
        @commitmenttolicence = node.attr("commitment-to-licence")
        @patentcontact = node.attr("patent-contact")
        @biblioasappendix = node.attr("biblio-as-appendix")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @nistdivision = node.attr("nist-division") ||
          "Computer Security Division, Information Technology Laboratory"
        @nistdivisionaddress = node.attr("nist-division-address") ||
          "100 Bureau Drive (Mail Stop 8930) Gaithersburg, MD 20899-8930"
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

      def clause_parse(attrs, xml, node)
        role = node.role || node.attr("style")
        attrs[:preface] = true if role == "preface"
        attrs[:executivesummary] = true if role == "executive-summary"
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
          #when "normative references" then norm_ref_parse(a, xml, node)
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

      NIST_PREFIX_REFS = "SP|FIPS"

      def refitem(xml, item, node)
        item.sub!(Regexp.new("^(<ref[^>]+>)\\[(#{NIST_PREFIX_REFS}) "),
                  "\\1[NIST \\2 ")
        super
      end
      
      def fetch_ref(xml, code, year, **opts)
        code.sub!(Regexp.new("^(#{NIST_PREFIX_REFS}) "), "NIST \\1 ")
        super
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
