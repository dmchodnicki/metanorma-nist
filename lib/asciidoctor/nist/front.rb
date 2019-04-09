require "asciidoctor"
require "asciidoctor/standoc/converter"
require "fileutils"

module Asciidoctor
  module NIST

    # A {Converter} implementation that generates RSD output, and a document
    # schema encapsulation of the document for validation
    #
    class Converter < Standoc::Converter

      def datetypes
        super << "abandoned"
      end

      def title_subtitle(node, t, at)
        return unless node.attr("title-sub")
        t.title(**attr_code(at.merge(type: "subtitle"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-sub"))
        end
      end

      def title_document_class(node, t, at)
        return unless node.attr("title-document-class")
        t.title(**attr_code(at.merge(type: "document-class"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-document-class"))
        end
      end

      def title_main(node, t, at)
        t.title(**attr_code(at.merge(type: "main"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-main") || node.title)
        end
      end

      def title(node, xml)
        ["en"].each do |lang|
          at = { language: lang, format: "text/plain" }
          title_main(node, xml, at)
          title_subtitle(node, xml, at)
          title_document_class(node, xml, at)
        end
      end

      def metadata_id(node, xml)
        did = node.attr("docidentifier")
        dn = node.attr("docnumber")
        if did
          xml.docidentifier did, **attr_code(type: "nist")
          xml.docidentifier unabbreviate(did), **attr_code(type: "nist-long")
        else
          metadata_id_compose(node, xml, dn)
        end
        xml.docnumber node.attr("docnumber")
      end

      def unabbreviate(did)
        SERIES_ABBR.each { |k, v| did = did.sub(/^#{v} /, "#{k} ") }
        SERIES.each { |k, v| did = did.sub(/^#{k} /, "#{v} ") }
        did
      end

      def metadata_id_compose(node, xml, dn0)
        return unless dn0
        dn = add_id_parts(dn0, node.attr("series"), node.attr("edition"), false)
        dn_long = add_id_parts(dn0, node.attr("series"), node.attr("edition"),
                               true)
        xml.docidentifier dn, **attr_code(type: "nist")
        xml.docidentifier dn_long, **attr_code(type: "nist-long")
      end

      def add_id_parts(dn, series, edition, long)
        ed_delim = " Revision "
        series and series_name = long ? SERIES.dig(series.to_sym) :
          SERIES_ABBR.dig(series.to_sym)
        dn = (series_name || "NIST #{series}")  + " " + dn
        dn += "#{ed_delim}#{edition}" if edition
        dn
      end

      def metadata_author(node, xml)
        personal_author(node, xml)
      end

      def metadata_publisher(node, xml)
        xml.contributor do |c|
          c.role **{ type: "publisher" }
          c.organization do |a|
            a.name "NIST"
          end
        end
      end

      def metadata_committee(node, xml)
        xml.editorialgroup do |a|
          a.committee(node.attr("technical-committee"))
          node.attr("subcommittee") and
            a.subcommittee(node.attr("subcommittee"),
                           **attr_code(type: node.attr("subcommittee-type"),
                                       number: node.attr("subcommittee-number")))
          (node.attr("workgroup") || node.attr("workinggroup")) and
            a.workgroup(node.attr("workgroup") || node.attr("workinggroup"),
                        **attr_code(type: node.attr("workgroup-type"),
                                    number: node.attr("workgroup-number")))
        end
      end

      def metadata_status(node, xml)
        status = node.attr("status") || "final"
        xml.status do |s|
          s.stage status 
          s.iteration node.attr("iteration") if node.attr("iteration") 
        end
      end

      def metadata_copyright(node, xml)
        from = node.attr("copyright-year") || node.attr("copyrightyear") ||
          Date.today.year
        xml.copyright do |c|
          c.from from
          c.owner do |owner|
            owner.organization do |o|
              o.name "NIST"
            end
          end
        end
      end

      def metadata_keywords(node, xml)
        return unless node.attr("keywords")
        node.attr("keywords").split(/,[ ]*/).each do |kw|
          xml.keyword kw
        end
      end

      def metadata_source(node, xml)
        super
        node.attr("doc-email") && xml.uri(node.attr("doc-email"), type: "email")
        node.attr("doi") && xml.uri(node.attr("doi"), type: "doi")
      end

      def metadata_series(node, xml)
        series = node.attr("series")
        series || return
        series and xml.series **{ type: "main" } do |s|
          s.title (SERIES.dig(series.to_sym) || series)
          SERIES_ABBR.dig(series.to_sym) and
            s.abbreviation SERIES_ABBR.dig(series.to_sym)
        end
      end

      def metadata_commentperiod(node, xml)
        from = node.attr("comment-from") or return
        to = node.attr("comment-to")
        extended = node.attr("comment-extended")
        xml.commentperiod do |c|
          c.from from
          c.to to if to
          c.extended extended if extended
        end
      end

      def metadata_getrelation(node, xml, type)
        docs = node.attr(type) || return
        docs.split(/,/).each do |d|
          xml.relation **{ type: type.sub(/-by$/, "By") } do |r|
            fetch_ref(r, d, nil, {})
          end
        end
      end

      SERIES = {
        "nist-ams": "NIST Advanced Manufacturing Series",
        "building-science": "NIST Building Science Series",
        "nist-fips": "NIST Federal Information Processing Standards",
        "nist-gcr": "NIST Grant/Contract Reports",
        "nist-hb": "NIST Handbook",
        "itl-bulletin": "ITL Bulletin",
        "jpcrd": "Journal of Physical and Chemical Reference Data",
        "nist-jres": "NIST Journal of Research",
        "letter-circular": "NIST Letter Circular",
        "nist-monograph": "NIST Monograph",
        "nist-ncstar": "NIST National Construction Safety Team Act Reports",
        "nist-nsrds": "NIST National Standard Reference Data Series",
        "nistir": "NIST Interagency/Internal Report",
        "product-standards": "NIST Product Standards",
        "nist-sp": "NIST Special Publication",
        "nist-tn": "NIST Technical Note",
        "other": "NIST Other",
        "csrc-white-paper": "CSRC White Paper",
        "csrc-book": "CSRC Book",
        "csrc-use-case": "CSRC Use Case",
        "csrc-building-block": "CSRC Building Block",
      }.freeze

      SERIES_ABBR = {
        "nist-ams": "NIST AMS",
        "building-science": "NIST Building Science Series",
        "nist-fips": "NIST FIPS",
        "nist-gcr": "NISTGCR",
        "nist-hb": "NIST HB",
        "itl-bulletin": "ITL Bulletin",
        "jpcrd": "JPCRD",
        "nist-jres": "NIST JRES",
        "letter-circular": "NIST Letter Circular",
        "nist-monograph": "NIST MN",
        "nist-ncstar": "NIST NCSTAR",
        "nist-nsrds": "NIST NSRDS",
        "nistir": "NISTIR",
        "product-standards": "NIST Product Standards",
        "nist-sp": "NIST SP",
        "nist-tn": "NIST TN",
        "other": "NIST Other",
        "csrc-white-paper": "CSRC White Paper",
        "csrc-book": "CSRC Book",
        "csrc-use-case": "CSRC Use Case",
        "csrc-building-block": "CSRC Building Block",
      }.freeze

      def metadata(node, xml)
        super
        %w(obsoletes obsoleted-by supersedes superseded-by).each do |t|
          metadata_getrelation(node, xml, t)
        end
        metadata_series(node, xml)
        metadata_keywords(node, xml)
        metadata_commentperiod(node, xml)
      end
    end
  end
end
