require "metanorma/processor"

module Metanorma
  module NIST
    class Processor < Metanorma::Processor

      def initialize
        @short = :nist
        @input_format = :asciidoc
        @asciidoctor_backend = :nist
      end

      def output_formats
        super.merge(
          html: "html",
          doc: "doc",
          pdf: "pdf"
        )
      end

      def version
        "Metanorma::NIST #{Metanorma::NIST::VERSION}"
      end

      def input_to_isodoc(file, filename)
        Metanorma::Input::Asciidoc.new.process(file, filename, @asciidoctor_backend)
      end

      def output(isodoc_node, outname, format, options={})
        case format
        when :html
          IsoDoc::NIST::HtmlConvert.new(options).convert(outname, isodoc_node)
        when :doc
          IsoDoc::NIST::WordConvert.new(options).convert(outname, isodoc_node)
        when :pdf
          IsoDoc::NIST::PdfConvert.new(options).convert(outname, isodoc_node)
        else
          super
        end
      end
    end
  end
end
