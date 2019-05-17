module Asciidoctor
  module NIST
    class Converter < Standoc::Converter
      def title_validate(root)
        nil
      end

      def content_validate(doc)
        super
        bibdata_validate(doc.root)
      end

      def bibdata_validate(doc)
        doctype_validate(doc)
        stage_validate(doc)
        substage_validate(doc)
        iteration_validate(doc)
        series_validate(doc)
      end

      def doctype_validate(xmldoc)
        doctype = xmldoc&.at("//bibdata/ext/doctype")&.text
        %w(standard).include? doctype or
          warn "Document Attributes: #{doctype} is not a recognised document type"
      end

      def stage_validate(xmldoc)
        stage = xmldoc&.at("//bibdata/status/stage")&.text
        %w(draft-internal draft-wip draft-prelim draft-public draft-approval
        final final-review).include? stage or
        warn "Document Attributes: #{stage} is not a recognised stage"
      end

      def substage_validate(xmldoc)
        substage = xmldoc&.at("//bibdata/status/substage")&.text or return
        %w(active retired withdrawn).include? substage or
          warn "Document Attributes: #{substage} is not a recognised substage"
      end

      def iteration_validate(xmldoc)
        iteration = xmldoc&.at("//bibdata/status/iteration")&.text or return
        %w(final).include? iteration.downcase or /^\d+$/.match(iteration) or
          warn "Document Attributes: #{iteration} is not a recognised iteration"
      end

      def series_validate(xmldoc)
        series = xmldoc&.at("//bibdata/series/title")&.text or return
        found = false
        SERIES.each { |_, v| found = true if v == series }
        found or
          warn "Document Attributes: #{series} is not a recognised series"
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
