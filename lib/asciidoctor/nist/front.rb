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
        return unless dn = node.attr("docnumber")
        part = node&.attr("partnumber")
        dn = add_id_parts(dn, part, node&.attr("edition"))
        xml.docidentifier dn, **attr_code(type: "nist", part: part)
        xml.docnumber node.attr("docnumber")
      end

      def add_id_parts(dn, part, edition)
        ed_delim = part && edition ? " Rev. " : "-"
        part_delim = "-"
        dn = "NIST " + dn
        dn += "#{part_delim}#{part}" if part
        dn += "#{ed_delim}#{edition}" if edition
        dn
      end

      def metadata_author(node, xml)
        xml.contributor do |c|
          c.role **{ type: "author" }
          c.organization do |a|
            a.name "NIST"
          end
        end
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
      end

      def metadata(node, xml)
        super
        metadata_keywords(node, xml)
      end

    end
  end
end
