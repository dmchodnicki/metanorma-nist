require "asciidoctor"
require "asciidoctor/nist"
require "asciidoctor/standoc/converter"
require "isodoc/nist/html_convert"
require "isodoc/nist/word_convert"
require_relative "front"
require "fileutils"

module Asciidoctor
  module NIST

    # A {Converter} implementation that generates RSD output, and a document
    # schema encapsulation of the document for validation
    #
    class Converter < Standoc::Converter

      register_for "nist"

      def title_validate(root)
        nil
      end

      def example(node)
        return pseudocode_example(node) if node.attr("style") == "pseudocode"
        return recommendation(node) if node.attr("style") == "recommendation"
        return requirement(node) if node.attr("style") == "requirement"
        return permission(node) if node.attr("style") == "permission"
        super
      end

      def pseudocode_example(node)
        noko do |xml|
          xml.example **{id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node), 
                         type: "pseudocode"} do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def recommendation(node)
        noko do |xml|
          xml.recommendation **id_attr(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def requirement(node)
        noko do |xml|
          xml.requirement **id_attr(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def permission(node)
        noko do |xml|
          xml.permission **id_attr(node) do |ex|
            wrap_in_para(node, ex)
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

      def makexml(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>\n<nist-standard>"]
        @draft = node.attributes.has_key?("draft")
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</nist-standard>"
        result = textcleanup(result.flatten * "\n")
        ret1 = cleanup(Nokogiri::XML(result))
        validate(ret1)
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
          c.name = "reviewernote" if c&.at("./title")&.text.downcase == "note to reviewers"
          c.name = "executivesummary" if c&.at("./title")&.text.downcase == "executive summary"
          preface.add_child c.remove
        end
      end

      def make_preface(x, s)
        if x.at("//foreword | //introduction | //abstract | //preface")
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
          else
            if @term_def then term_def_subclause_parse(a, xml, node)
            elsif @biblio then bibliography_parse(a, xml, node)
            elsif node.attr("style") == "bibliography" && node.level == 1
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
