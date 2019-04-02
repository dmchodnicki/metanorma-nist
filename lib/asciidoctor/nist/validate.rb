module Asciidoctor
  module NIST
    class Converter < Standoc::Converter
       def title_validate(root)
        nil
      end

       def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "nist.rng"))
      end

       def introduction_validate(doc)
        intro = doc.at("//sections/clause/title")
        intro&.text == "Introduction" or
          warn "First section of document body should be Introduction, "\
          "not #{intro&.text}"
      end

       REF_SECTIONS_TO_VALIDATE = "//references[not(parent::clause)]/title | "\
        "//clause[descendant::references][not(parent::clause)]/title".freeze

      def section_validate(doc)
        super
        introduction_validate(doc)
        references_validate(doc)
      end

      def references_validate(doc)
        f = doc.xpath(REF_SECTIONS_TO_VALIDATE)
        names = f.map { |s| s&.text }
        return if names.empty?
        return if names == ["References"]
        return if names == ["Bibliography"]
        return if names == ["References", "Bibliography"]
        warn "Reference clauses #{names.join(', ')} do not follow expected "\
          "pattern in NIST"
      end
    end
  end
end
