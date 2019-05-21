require "isodoc"
require_relative "metadata"
require "fileutils"

module IsoDoc
  module NIST
    module BaseConvert
      def abstract(isoxml, out)
        f = isoxml.at(ns("//preface/abstract")) || return
        #page_break(out)
        out.div **attr_code(id: f["id"]) do |s|
          clause_name(nil, @abstract_lbl, s, class: "AbstractTitle")
          f.elements.each { |e| parse(e, s) unless e.name == "title" }
        end
      end

      def keywords(_docxml, out)
        kw = @meta.get[:keywords]
        kw.empty? and return
        out.div **{ class: "Section3" } do |div|
          clause_name(nil, "Keywords", div,  class: "IntroTitle")
          div.p kw.sort.join("; ")
        end
      end

      FRONT_CLAUSE = "//*[parent::preface][not(local-name() = 'abstract' or local-name() = 'foreword')]".freeze

      # All "[preface]" sections should have class "IntroTitle" to prevent
      # page breaks
      # But for the Exec Summary
      def preface(isoxml, out)
        isoxml.xpath(ns(FRONT_CLAUSE)).each do |c|
          next if skip_render(c, isoxml)
          title = c&.at(ns("./title"))
          patent = ["Call for Patent Claims", "Patent Disclosure Notice"].include? title&.text
          out.div **attr_code(id: c["id"]) do |s|
            page_break(s) if patent
            clause_name(get_anchors[c['id']][:label], title&.content, s,
                        class: (c.name == "executivesummary") ? "NormalTitle" :
                        "IntroTitle")
            c.elements.reject { |c1| c1.name == "title" }.each do |c1|
              parse(c1, s)
            end
          end
        end
      end

      def skip_render(c, isoxml)
        return false unless c.name == "reviewernote"
        status = isoxml&.at(ns("//bibdata/status/stage"))&.text
        return true if status.nil?
        /^final/.match status
      end

      def term_defs_boilerplate(div, source, term, preface)
        if source.empty? && term.nil?
          div << @no_terms_boilerplate
        else
          div << term_defs_boilerplate_cont(source, term)
        end
      end

      def i18n_init(lang, script)
        super
      end

      def fileloc(loc)
        File.join(File.dirname(__FILE__), loc)
      end

      def requirement_cleanup(docxml)
        docxml.xpath("//div[@class = 'recommend' or @class = 'require' "\
                     "or @class = 'permission']").each do |d|
          title = d.at("./p[@class = 'AdmonitionTitle']") or next
          title.name = "b"
          title.delete("class")
          n = title.next_element
          n&.children&.first&.add_previous_sibling(" ")
          n&.children&.first&.add_previous_sibling(title.remove)
        end
        docxml
      end

      def figure_parse(node, out)
        return pseudocode_parse(node, out) if node["type"] == "pseudocode"
        super
      end

      def dl_parse(node, out)
        return glossary_parse(node, out) if node["type"] == "glossary"
        super
      end

      def glossary_parse(node, out)
        out.dl  **attr_code(id: node["id"], class: "glossary") do |v|
          node.elements.select { |n| dt_dd? n }.each_slice(2) do |dt, dd|
            v.dt **attr_code(id: dt["id"]) do |term|
              dt_parse(dt, term)
            end
            v.dd  **attr_code(id: dd["id"]) do |listitem|
              dd.children.each { |n| parse(n, listitem) }
            end
          end
        end
        node.elements.reject { |n| dt_dd? n }.each { |n| parse(n, out) }
      end

      def error_parse(node, out)
        case node.name
        when "nistvariable" then nistvariable_parse(node, out)
        when "recommendation" then recommendation_parse(node, out)
        when "requirement" then requirement_parse(node, out)
        when "permission" then permission_parse(node, out)
        when "errata" then errata_parse(node, out)
        when "legal-statement" then children_parse(node, out)
        when "feedback-statement" then children_parse(node, out)
        else
          super
        end
      end

      def boilerplate(node, out)
        boilerplate = node.at(ns("//boilerplate")) or return
        out.div **{class: "authority"} do |s|
          boilerplate.children.each do |n|
            if n.name == "title"
              s.h1 do |h|
                n.children.each { |nn| parse(nn, h) }
              end
            else
              parse(n, s)
            end
          end
        end
        page_break(out)
      end

      def children_parse(node, out)
        node.children.each do |n|
          parse(n, out)
        end
      end

      def nistvariable_parse(node, out)
        out.span **{class: "nistvariable"} do |s|
          node.children.each { |n| parse(n, s) }
        end
      end

      def errata_parse(node, out)
        out.a **{ name: "errata_XYZZY" }
        out.table **make_table_attr(node) do |t|
          errata_head(t)
          errata_body(t, node)
        end
      end

      def errata_head(t)
          t.thead do |h|
            h.tr do |tr|
              %w(Date Type Change Pages).each do |hdr|
                tr.th hdr
              end
            end
          end
      end

      def errata_body(t, node)
          t.tbody do |b|
            node.xpath(ns("./row")).each do |row|
              b.tr do |tr|
                %w{date type change pages}.each do |hdr|
                  tr.td do |td|
                    row&.at(ns("./#{hdr}"))&.children.each do |n|
                      parse(n, td)
                    end
                  end
                end
              end
            end
          end
      end

      MIDDLE_CLAUSE = "//clause[parent::sections] | "\
        "//terms[parent::sections]".freeze

      def middle(isoxml, out)
        # NIST documents don't repeat the title
        #middle_title(out)
        clause isoxml, out
        bibliography isoxml, out
        annex isoxml, out
      end

      def info(isoxml, out)
        @meta.keywords isoxml, out
        @meta.series isoxml, out
        @meta.commentperiod isoxml, out
        @meta.note isoxml, out
        super
      end

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

      def get_linkend(node)
        link = anchor_linkend(node, docid_l10n(node["target"] || "[#{node['citeas']}]"))
        link += eref_localities(node.xpath(ns("./locality")), link)
        contents = node.children.select { |c| c.name != "locality" }
        return link if contents.nil? || contents.empty?
        Nokogiri::XML::NodeSet.new(node.document, contents).to_xml
        # so not <origin bibitemid="ISO7301" citeas="ISO 7301">
        # <locality type="section"><reference>3.1</reference></locality></origin>
      end

      def load_yaml(lang, script)
        y = if @i18nyaml then YAML.load_file(@i18nyaml)
            elsif lang == "en"
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
            else
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
            end
        super.merge(y)
      end

      def annex_name_lbl(clause, num)
        l10n("<b>#{@annex_lbl} #{num}</b>")
      end

      def annex_name(annex, name, div)
        div.h1 **{ class: "Annex" } do |t|
          t << "#{get_anchors[annex['id']][:label]} &mdash; "
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

      def bibliography_parse(node, out)
        title = node&.at(ns("./title"))&.text || ""
        out.div do |div|
          node.parent.name == "annex" or
            div.h2 title, **{ class: "Section3" }
          node.elements.reject do |e|
            ["reference", "title", "bibitem"].include? e.name
          end.each { |e| parse(e, div) }
          biblio_list(node, div, true)
        end
      end

      NIST_PUBLISHER_XPATH = 
        "./contributor[xmlns:role/@type = 'publisher']/"\
        "organization[abbreviation = 'NIST' or xmlns:name = 'NIST']".freeze

      # we are taking the ref number/code out as prefix to reference
      def noniso_bibitem(list, b, ordinal, bibliography)
        list.p **attr_code(iso_bibitem_entry_attrs(b, bibliography)) do |r|
          if !b.at(ns("./formattedref"))
            nist_reference_format(b, r)
          else
            reference_format(b, r)
          end
        end
      end

      def reference_format(b, r)
        if ftitle = b.at(ns("./formattedref"))
          ftitle&.children&.each { |n| parse(n, r) }
        else
          title = b.at(ns("./title[@language = '#{@language}']")) || b.at(ns("./title"))
          r.i do |i|
            title&.children&.each { |n| parse(n, i) }
          end
        end
        r << "[#{iso_bibitem_ref_code(b)}] "
      end

      def omit_docid_prefix(prefix)
        return true if prefix.nil? || prefix.empty?
        return ["ISO", "IEC", "nist"].include? prefix
      end

      def nist_reference_format(b, r)
        bibitem = b.dup.to_xml
        r.parent.add_child ::Iso690Render.render(bibitem, true)
      end

      def pseudocode_parse(node, out)
        @in_figure = true
        name = node.at(ns("./name"))
        out.div **attr_code(id: node["id"], class: "pseudocode") do |div|
          node.children.each do |n|
            parse(n, div) unless n.name == "name"
          end
          figure_name_parse(node, div, name)
        end
        @in_figure = false
      end

      def foreword(isoxml, out)
        f = isoxml.at(ns("//foreword")) || return
        out.div **attr_code(id: f["id"]) do |s|
          title = f.at(ns("./title"))
          s.h1(**{ class: "ForewordTitle" }) do |h1|
            title and title.children.each { |e| parse(e, h1) }
          end
          f.elements.each { |e| parse(e, s) unless e.name == "title" }
        end
      end
    end
  end
end
