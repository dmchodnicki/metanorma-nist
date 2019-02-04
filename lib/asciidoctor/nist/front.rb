require "asciidoctor"
require "asciidoctor/standoc/converter"
require "fileutils"

module Asciidoctor
  module NIST

    # A {Converter} implementation that generates RSD output, and a document
    # schema encapsulation of the document for validation
    #
    class Converter < Standoc::Converter

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

      def metadata_id(node, xml)
        docstatus = node.attr("status")
        dn = node.attr("docnumber")
        if docstatus
          abbr = IsoDoc::NIST::Metadata.new("en", "Latn", {}).
            status_abbr(docstatus)
          dn = "#{dn}(#{abbr})" unless abbr.empty?
        end
        dn and dn = "NIST " + dn
        xml.docidentifier dn, **{type: "nist"}
        xml.docnumber { |i| i << node.attr("docnumber") }
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
        status = node.attr("status") || "published"
        xml.status(**{ format: "plain" }) { |s| s << status }
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

      def title(node, xml)
        super
        subtitle(node, xml)
      end

      def subtitle(node, xml)
        return unless node.attr("subtitle")
        ["en"].each do |lang|
          at = { language: lang, format: "text/plain" }
          xml.subtitle **attr_code(at) do |t|
            t << asciidoc_sub(node.attr("subtitle"))
          end
        end
      end

      def metadata(node, xml)
        super
        metadata_keywords(node, xml)
      end

    end
  end
end
