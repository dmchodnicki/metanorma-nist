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

      def make_preface(x, s)
        super
        make_acknowledgements(x, s)
        make_conformancetesting(x, s)
      end

      def make_acknowledgements(x, s)
        if x.at("//acknowledgements")
          preface = s.at("//preface") || s.add_previous_sibling("<preface/>").first
          ack = x.at("//acknowledgements").remove
          preface.add_child ack.remove
        end
      end

      def make_conformancetesting(x, s)
        if x.at("//conformancetesting")
          preface = s.at("//preface") || s.add_previous_sibling("<preface/>").first
          ack = x.at("//conformancetesting").remove
          preface.add_child ack.remove
        end
      end

      def clause_parse(attrs, xml, node)
        clausetype = node&.attr("heading")&.downcase || node.title.downcase
        if clausetype == "acknowledgements" then acknowledgements_parse(attrs, xml, node)
        elsif clausetype == "conformance testing" then conformancetesting_parse(attrs, xml, node)
        else
          super
        end
      end

      def acknowledgements_parse(attrs, xml, node)
        xml.acknowledgements **attr_code(attrs) do |xml_section|
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
