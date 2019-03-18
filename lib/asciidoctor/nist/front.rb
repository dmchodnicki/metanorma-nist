require "asciidoctor"
require "asciidoctor/standoc/converter"
require "fileutils"

module Asciidoctor
  module NIST

    # A {Converter} implementation that generates RSD output, and a document
    # schema encapsulation of the document for validation
    #
    class Converter < Standoc::Converter

      def title_subtitle(node, t, at)
        return unless node.attr("title-sub")
        t.title_sub(**attr_code(at)) do |t1|
          t1 << asciidoc_sub(node.attr("title-sub"))
        end
      end

      def title_main(node, t, at)
        t.title_main **attr_code(at) do |t1|
          t1 << asciidoc_sub(node.attr("title-main") || node.title)
        end
      end

      def title_part(node, t, at)
        return unless node.attr("title-part")
        t.title_part(**attr_code(at)) do |t1|
          t1 << asciidoc_sub(node.attr("title-part"))
        end
      end

      def title(node, xml)
        ["en"].each do |lang|
          xml.title do |t|
            at = { language: lang, format: "text/plain" }
            title_main(node, t, at)
            title_subtitle(node, t, at)
            title_part(node, t, at)
          end
        end
      end

      def metadata_id(node, xml)
        did = node.attr("docidentifier")
        dn = node.attr("docnumber")
        part = node.attr("partnumber")
        if did
          xml.docidentifier did, **attr_code(type: "nist", part: part)
          xml.docidentifier unabbreviate(did), **attr_code(type: "nist-long", part: part)
        else
          metadata_id_compose(node, xml, dn, part)
        end
        xml.docnumber node.attr("docnumber")
      end

      def unabbreviate(did)
        SERIES_ABBR.each { |k, v| did = did.sub(/^#{v} /, "#{k} ") }
        SERIES.each { |k, v| did = did.sub(/^#{k} /, "#{v} ") }
        did
      end

      def metadata_id_compose(node, xml, dn0, part)
        return unless dn0
        dn = add_id_parts(dn0, part, node.attr("series"),
                          node.attr("edition"), false)
        dn_long = add_id_parts(dn0, part, node.attr("series"),
                               node.attr("edition"), true)
        xml.docidentifier dn, **attr_code(type: "nist", part: part)
        xml.docidentifier dn_long, **attr_code(type: "nist-long", part: part)
      end

      def add_id_parts(dn, part, series, edition, long)
        ed_delim = part && edition ? " Rev. " : "-"
        part_delim = "-"
        series and series_name = long ? SERIES.dig(series.to_sym) :
          SERIES_ABBR.dig(series.to_sym)
        dn = (series_name || "NIST #{series}")  + " " + dn
        dn += "#{part_delim}#{part}" if part
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
        subseries = node.attr("subseries")
        series || subseries || return
        series and xml.series **{ type: "main" } do |s|
          s.title (SERIES.dig(series.to_sym) || series)
          SERIES_ABBR.dig(series.to_sym) and s.abbreviation SERIES_ABBR.dig(series.to_sym)
        end
        subseries and xml.series **{ type: "secondary" } do |s|
          s.title subseries.split(/-/).map{ |w| w.capitalize }.join(" ")
        end
      end

      def metadata_commentperiod(node, xml)
        from = node.attr("comment-from") or return
        to = node.attr("comment-to")
        xml.commentperiod do |c|
          c.from from
          c.to to if to
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
        metadata_series(node, xml)
        metadata_keywords(node, xml)
        metadata_commentperiod(node, xml)
      end
    end
  end
end
