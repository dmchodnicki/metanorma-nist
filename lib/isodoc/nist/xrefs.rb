require "isodoc"
require_relative "metadata"
require "fileutils"

module IsoDoc
  module NIST
    module BaseConvert
      SECTIONS_XPATH =
        "//foreword | //introduction | //reviewnote | //executivesummary | //annex | "\
        "//sections/clause | //bibliography/references | "\
        "//bibliography/clause".freeze

      def initial_anchor_names(d)
        d.xpath("//xmlns:boilerplate/child::* | //xmlns:preface/child::*").each do |c|
          preface_names(c)
        end
        @in_execsummary = true
        hierarchical_asset_names(d.xpath("//xmlns:executivesummary"), "ES")
        @in_execsummary = false
        clause_names(d, 0)
        middle_section_asset_names(d)
        termnote_anchor_names(d)
        termexample_anchor_names(d)
      end

      def back_anchor_names(docxml)
        docxml.xpath(ns("//annex")).each_with_index do |c, i|
          annex_names(c, (65 + i).chr.to_s)
        end
        docxml.xpath(ns("//bibliography/clause | "\
                        "//bibliography/references")).each do |b|
          preface_names(b)
        end
        docxml.xpath(ns("//bibitem[not(ancestor::bibitem)]")).each do |ref|
          reference_names(ref)
        end
      end

      def middle_section_asset_names(d)
        middle_sections = "//xmlns:preface/child::*[not(self::xmlns:executivesummary)] | "\
          "//xmlns:sections/child::*"
        sequential_asset_names(d.xpath(middle_sections))
      end

      def clause_names(docxml, sect_num)
        q = "//xmlns:sections/child::*"
        docxml.xpath(q).each_with_index do |c, i|
          section_names(c, (i + sect_num), 1)
        end
      end

      def annex_name_lbl(clause, num)
        l10n("<b>#{@annex_lbl} #{num}</b>")
      end

      def annex_name(annex, name, div)
        div.h1 **{ class: "Annex" } do |t|
          t << "#{anchor(annex['id'], :label)} &mdash; "
          t.b do |b|
            if @bibliographycount == 1 && annex.at(ns("./references"))
              b << "References"
            else
              name&.children&.each { |c2| parse(c2, b) }
            end
          end
        end
      end

      def hiersep
        "-"
      end

      def annex_names(clause, num)
        @anchors[clause["id"]] = { label: annex_name_lbl(clause, num), type: "clause",
                                   xref: "#{@annex_lbl} #{num}", level: 1 }
        clause.xpath(ns("./clause")).each_with_index do |c, i|
          annex_names1(c, "#{num}.#{i + 1}", 2)
        end
        clause.xpath(ns("./terms | ./term | ./references")).each_with_index do |c, i|
          annex_names1(c, "#{num}", 1)
        end
        hierarchical_asset_names(clause, num)
      end

      def annex_names1(clause, num, level)
        @anchors[clause["id"]] = { label: num, xref: "#{@annex_lbl} #{num}",
                                   level: level, type: "clause" }
        clause.xpath(ns("./clause | ./terms | ./term | ./references")).each_with_index do |c, i|
          annex_names1(c, "#{num}.#{i + 1}", level + 1)
        end
      end

      def terms_parse(node, out)
        out.div **attr_code(id: node["id"]) do |div|
          node.at(ns("./title")) and
            clause_parse_title(node, div, node.at(ns("./title")), out)
          term_defs_boilerplate(div, node.xpath(ns(".//termdocsource")),
                                node.at(ns(".//term")), node.at(ns("./p")))
          node.elements.each do |e|
            parse(e, div) unless %w{title source}.include? e.name
          end
        end
      end
    end
  end
end
