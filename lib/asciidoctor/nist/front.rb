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

      def metadata_version(node, xml)
        xml.edition node.attr("edition") if node.attr("edition")
        xml.revision node.attr("revision") if node.attr("revision")
        xml.version do |v|
          v.revision_date node.attr("revdate") if node.attr("revdate")
          v.draft node.attr("draft") if node.attr("draft")
        end
      end

      def title_subtitle(node, t, at)
        return unless node.attr("title-sub")
        t.title(**attr_code(at.merge(type: "subtitle"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-sub"))
        end
        node.attr("title-sub-short") and
          t.title(**attr_code(at.merge(type: "short-subtitle"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-sub-short"))
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
        node.attr("title-main-short") and
          t.title(**attr_code(at.merge(type: "short-title"))) do |t1|
          t1 << asciidoc_sub(node.attr("title-main-short"))
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
        s = node.attr("series")
        e = node.attr("revision")
        v = node.attr("volume")
        xml.docidentifier add_id_parts(dn0, s, e, v, false),
          **attr_code(type: "nist")
        xml.docidentifier add_id_parts(dn0, s, e, v, true),
          **attr_code(type: "nist-long")
        xml.docidentifier add_id_parts_mr(dn0, s, e, v, node.attr("revdate")),
          **attr_code(type: "nist-mr")
      end

      def add_id_parts(dn, series, revision, vol, long)
        vol_delim = " Volume "
        ed_delim = " Revision "
        series and series_name = long ? SERIES.dig(series.to_sym) :
          SERIES_ABBR.dig(series.to_sym)
        dn = (series_name || "NIST #{series}")  + " " + dn
        dn += "#{vol_delim}#{vol}" if vol
        dn += "," if vol && revision
        dn += "#{ed_delim}#{revision}" if revision
        dn
      end

      def add_id_parts_mr(dn, series, revision, vol, revdate)
        series and series_name = SERIES_ABBR.dig(series.to_sym).sub(/^NIST /, "")
        "NIST.#{series_name}.#{vol}.#{revision}.#{revdate}"
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
        return unless node.attr("technical-committee") || node.attr("subcommittee") ||
          node.attr("workgroup") || node.attr("workinggroup")
        xml.editorialgroup do |a|
          node.attr("technical-committee") and
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
          s.substage (node.attr("substage") || "active")
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

      def relaton_relations
        super + %w(obsoletes obsoleted-by supersedes superseded-by)
      end

      def metadata_getrelation(node, xml, type)
        if type == "obsoleted-by" and node.attr("superseding-status")
          metadata_superseding_doc(node, xml)
        else
          super
        end
      end

      # currently specific to drafts
      def metadata_superseding_doc(node, xml)
        xml.relation **{ type: "obsoletedBy" } do |r|
          r.bibitem do |b|
            b.title asciidoc_sub(node.attr("superseding-title") ||
                                 node.attr("title-main") || node.title)
            doi = node.attr("superseding-doi") and
              b.uri doi, **{ type: "doi" }
            url = node.attr("superseding-url") and
              b.uri url, **{ type: "uri" }
            did = xml&.parent&.at("./ancestor::bibdata/docidentifier[@type = 'nist']")&.text
            didl = xml&.parent&.at("./ancestor::bibdata/docidentifier[@type = 'nist-long']")&.text
            b.docidentifier did, **{ type: "nist" }
            b.docidentifier didl, **{ type: "nist-long" }
            cdate = node.attr("superseding-circulated-date") and
              b.date cdate, **{ type: "circulated" }
            b.status do |s|
              s.stage node.attr("superseding-status")
              iter = node.attr("superseding-iteration") and
                s.iteration iter
            end
          end
        end
      end

      def metadata(node, xml)
        super
        metadata_series(node, xml)
        metadata_keywords(node, xml)
        metadata_commentperiod(node, xml)
      end
    end
  end
end
