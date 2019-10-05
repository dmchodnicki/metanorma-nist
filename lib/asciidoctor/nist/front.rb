require "asciidoctor"
require "asciidoctor/standoc/converter"
require "fileutils"

module Asciidoctor
  module NIST
    # A {Converter} implementation that generates RSD output, and a document
    # schema encapsulation of the document for validation

    class Converter < Standoc::Converter
      def doctype(node)
        node.attr("doctype") || "sp-800"
      end

      def datetypes
        super + %w(abandoned superseded)
      end

      def metadata_version(node, xml)
        xml.edition node.attr("edition") if node.attr("edition")
        xml.edition "Revision #{node.attr("revision")}" if node.attr("revision")
        xml.version do |v|
          v.revision_date node.attr("revdate") if node.attr("revdate")
          v.draft node.attr("draft") if node.attr("draft")
        end
      end

      def title_subtitle(node, t, at)
        return unless node.attr("title-sub")
        t.title(**attr_code(at.merge(type: "subtitle"))) do |t1|
          t1 << Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-sub"))
        end
        node.attr("title-sub-short") and
          t.title(**attr_code(at.merge(type: "short-subtitle"))) do |t1|
          t1 << Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-sub-short"))
        end
      end

      def title_document_class(node, t, at)
        return unless node.attr("title-document-class")
        t.title(**attr_code(at.merge(type: "document-class"))) do |t1|
          t1 << Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-document-class"))
        end
      end

      def title_main(node, t, at)
        t.title(**attr_code(at.merge(type: "main"))) do |t1|
          t1 << Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-main") || node.title)
        end
        node.attr("title-main-short") and
          t.title(**attr_code(at.merge(type: "short-title"))) do |t1|
          t1 << Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-main-short"))
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
        dn = Iso690Render.MMMddyyyy(node.attr("issued-date")) if @series == "nist-cswp" and !dn
        if did
          xml.docidentifier did, **attr_code(type: "NIST")
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

      def id_args(node, dn0)
        {
          id: dn0,
          series: node.attr("series"),
          revision: node.attr("revision"),
          vol: node.attr("volume"),
          stage: node.attr("status") || node.attr("docstage"),
          iter: node.attr("iteration"),
          date: /^draft/.match(node.attr("status") || node.attr("docstage")) ?
          (node.attr("circulated-date") || node.attr("revdate")) :
          node.attr("updated-date")
        }
      end

      def metadata_id_compose(node, xml, dn0)
        return unless dn0
        args = id_args(node, dn0)
        xml.docidentifier add_id_parts(args, false), **attr_code(type: "NIST")
        xml.docidentifier add_id_parts(args, true),
          **attr_code(type: "nist-long")
        xml.docidentifier add_id_parts_mr(args), **attr_code(type: "nist-mr")
      end

      def MMMddyyyy(isodate)
        return nil if isodate.nil?
        Date.parse(isodate).strftime("%B %d, %Y")
      end

      def add_id_parts(args, long)
        vol_delim = " Volume "
        ed_delim = " Revision "
        args[:series] and series_name = long ?
          SERIES.dig(args[:series].to_sym) :
          SERIES_ABBR.dig(args[:series].to_sym)
        dn = (series_name || "NIST #{args[:series]}")  + " " + args[:id]
        dn += "#{vol_delim}#{args[:vol]}" if args[:vol]
        dn += "," if args[:vol] && args[:revision]
        dn += "#{ed_delim}#{args[:revision]}" if args[:revision]
        stage = IsoDoc::NIST::Metadata.new(nil, nil, {}).stage_abbr(args[:stage], args[:iter])
        dn += " (#{stage})" if stage
        dn += " (#{MMMddyyyy(args[:date])})" if args[:date]
        dn
      end

      def add_id_parts_mr(args)
        args[:series] and
          name = SERIES_ABBR.dig(args[:series].to_sym).sub(/^NIST /, "")
        "NIST.#{name}.#{args[:vol]}.#{args[:revision]}.#{args[:date]}"
      end

      def metadata_author(node, xml)
        personal_author(node, xml)
      end

      def metadata_publisher(node, xml)
        xml.contributor do |c|
          c.role **{ type: "publisher" }
          c.organization do |a|
            a.name "NIST"
            d = node.attr("nist-division") and a.subdivision d
          end
        end
      end

      def metadata_committee(node, xml)
        return unless node.attr("technical-committee") ||
          node.attr("subcommittee") ||
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
        status = node.attr("status") || node.attr("docstage") || "final"
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

      def metadata_source(node, xml)
        super
        node.attr("doc-email") && xml.uri(node.attr("doc-email"), type: "email")
        node.attr("doi") && xml.uri(node.attr("doi"), type: "doi")
      end

      def metadata_series(node, xml)
        series = node.attr("series") || "nist-sp"
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

      def metadata_superseding_doc(node, xml)
        xml.relation **{ type: "obsoletedBy" } do |r|
          r.bibitem do |b|
            metadata_superseding_titles(b, node)
            doi = node.attr("superseding-doi") and
              b.uri doi, **{ type: "doi" }
            url = node.attr("superseding-url") and
              b.uri url, **{ type: "uri" }
            metadata_superseding_ids(b, xml)
            metadata_superseding_authors(b, node)
            metadata_superseding_dates(b, node)
            b.status do |s|
              s.stage node.attr("superseding-status")
              iter = node.attr("superseding-iteration") and
                s.iteration iter
            end
          end
        end
      end

      def metadata_superseding_ids(b, xml)
        did = xml&.parent&.at("./ancestor::bibdata/docidentifier"\
                              "[@type = 'NIST']")&.text
        didl = xml&.parent&.at("./ancestor::bibdata/docidentifier"\
                               "[@type = 'nist-long']")&.text
        b.docidentifier did, **{ type: "NIST" }
        b.docidentifier didl, **{ type: "nist-long" }
      end

      def metadata_superseding_dates(b, node)
        cdate = node.attr("superseding-circulated-date") and
          b.date **{ type: "circulated" } do |d|
          d.on cdate
        end
        cdate = node.attr("superseding-issued-date") and
          b.date **{ type: "issued" } do |d|
          d.on cdate
        end
      end

      def metadata_superseding_titles(b, node)
        if node.attr("superseding-title")
          b.title Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("superseding-title")),
            **{ type: "main" }
          node.attr("superseding-subtitle") and
            b.title Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("superseding-subtitle")),
            **{ type: "subtitle" }
        else
          b.title Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-main") || node.title),
            **{ type: "main" }
          node.attr("title-sub") and
            b.title Asciidoctor::Standoc::Utils::asciidoc_sub(node.attr("title-sub")), **{ type: "subtitle" }
        end
      end

      def metadata_superseding_authors(b, node)
        node.attr("superseding-authors") and
          node.attr("superseding-authors").split(/,\s*/).each do |a|
          b.contributor do |c|
            c.role nil, **{ type: "author" }
            c.person do |p|
              p.name do |f|
                f.completename a
              end
            end
          end
        end
      end

      def metadata_note(node, xml)
        note = node.attr("bib-additional-note") and
          xml.note note, **{ type: "additional-note" }
        note = node.attr("bib-withdrawal-note") and
          xml.note note, **{ type: "withdrawal-note" }
        note = node.attr("bib-withdrawal-announcement-link") and
          xml.note note, **{ type: "withdrawal-announcement-link" }
      end

      def metadata_ext(node, xml)
        metadata_doctype(node, xml)
        metadata_committee(node, xml)
        metadata_commentperiod(node, xml)
      end
    end
  end
end
