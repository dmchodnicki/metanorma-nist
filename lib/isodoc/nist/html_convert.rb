require "isodoc"
require_relative "metadata"
require "fileutils"

module IsoDoc
  module NIST
    # A {Converter} implementation that generates HTML output, and a document
    # schema encapsulation of the document for validation
    class HtmlConvert < IsoDoc::HtmlConvert
      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
      end

      def convert1(docxml, filename, dir)
        FileUtils.cp html_doc_path('logo.png'), "#{@localdir}/logo.png"
        FileUtils.cp html_doc_path('commerce-logo-color.png'), "#{@localdir}/commerce-logo-color.png"
        @files_to_delete << "#{@localdir}/logo.png"
        @files_to_delete << "#{@localdir}/commerce-logo-color.png"
        super
      end

      def default_fonts(options)
        {
          bodyfont: (options[:script] == "Hans" ? '"SimSun",serif' : '"Libre Baskerville",serif'),
          headerfont: (options[:script] == "Hans" ? '"SimHei",sans-serif' : '"Libre Baskerville",serif'),
          monospacefont: '"Space Mono",monospace'
        }
      end

      def default_file_locations(_options)
        {
          htmlstylesheet: html_doc_path("htmlstyle.scss"),
          htmlcoverpage: html_doc_path("html_nist_titlepage.html"),
          htmlintropage: html_doc_path("html_nist_intro.html"),
          scripts: html_doc_path("scripts.html"),
        }
      end

      def metadata_init(lang, script, labels)
        @meta = Metadata.new(lang, script, labels)
      end

      def html_head
        <<~HEAD.freeze
        <title>{{ doctitle }}</title>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>

    <!--TOC script import-->
    <script type="text/javascript" src="https://cdn.rawgit.com/jgallen23/toc/0.3.2/dist/toc.min.js"></script>

    <!--Google fonts-->
    <link href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,600,600i" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css?family=Libre+Baskerville:400,400i,700,700i" rel="stylesheet">

    <!--Font awesome import for the link icon-->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/solid.css" integrity="sha384-v2Tw72dyUXeU3y4aM2Y0tBJQkGfplr39mxZqlTBDUZAb9BGoC40+rdFCG0m10lXk" crossorigin="anonymous">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.8/css/fontawesome.css" integrity="sha384-q3jl8XQu1OpdLgGFvNRnPdj5VIlCvgsDQTQB6owSOHWlAurxul7f+JpUOVdAiJ5P" crossorigin="anonymous">
    <style class="anchorjs"></style>
        HEAD
      end

      def make_body(xml, docxml)
        body_attr = { lang: "EN-US", link: "blue", vlink: "#954F72", "xml:lang": "EN-US", class: "container" }
        xml.body **body_attr do |body|
          make_body1(body, docxml)
          make_body2(body, docxml)
          make_body3(body, docxml)
        end
      end

      def html_toc(docxml)
        docxml
      end

      def cleanup(docxml)
        super
        term_cleanup(docxml)
        requirement_cleanup(docxml)
      end

      def make_body3(body, docxml)
        body.div **{ class: "main-section" } do |div3|
          abstract docxml, div3
          keywords docxml, div3
          preface docxml, div3
          middle docxml, div3
          footnotes div3
          comments div3
        end
      end

      def bibliography(isoxml, out)
        f = isoxml.at(ns("//bibliography/clause | //bibliography/references")) || return
        page_break(out)
        isoxml.xpath(ns("//bibliography/clause | //bibliography/references")).each do |f|
          out.div do |div|
            div.h1 **{ class: "Section3" } do |h1|
              f&.at(ns("./title"))&.children.each { |n| parse(n, h1) }
            end
            f.elements.reject do |e|
              ["reference", "title", "bibitem"].include? e.name
            end.each { |e| parse(e, div) }
            biblio_list(f, div, false)
          end
        end
      end

      # common from here on

      def abstract(isoxml, out)
        f = isoxml.at(ns("//preface/abstract")) || return
        page_break(out)
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

      FRONT_CLAUSE = "//*[parent::preface][not(local-name() = 'abstract')]".freeze

      def preface(isoxml, out)
        isoxml.xpath(ns(FRONT_CLAUSE)).each do |c|
          foreword(isoxml, out) and next if c.name == "foreword"
          next if skip_render(c, isoxml)
          out.div **attr_code(id: c["id"]) do |s|
            clause_name(get_anchors[c['id']][:label],
                        c&.at(ns("./title"))&.content, s, nil)
            c.elements.reject { |c1| c1.name == "title" }.each do |c1|
              parse(c1, s)
            end
          end
        end
      end

      def skip_render(c, isoxml)
        return false unless c.name == "reviewernote"
        status = isoxml&.at(ns("//bibdata/status"))&.text
        return true if status.nil?
        return ["published", "withdrawn"].include? status
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
                     "or @class = 'permission'][title]").each do |d|
          title = d.at("./title")
          title.name = "b"
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

      def pseudocode_parse(node, out)
        @in_figure = true
        name = node.at(ns("./name"))
        out.div **attr_code(id: node["id"], class: "pseudocode") do |div|
          node.children.each do |n|
            parse(n, div) unless n.name == "name"
          end
          figure_name_parse(node, div, name) if name
        end
        @in_figure = false
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
        else
          super
        end
      end

      def nistvariable_parse(node, out)
        out.span **{class: "nistvariable"} do |s|
          node.children.each { |n| parse(n, s) }
        end
      end

      def recommendation_parse(node, out)
        name = node["type"]
        out.div **{ class: "recommend" } do |t|
          t.title { |b| b << "Recommendation #{get_anchors[node['id']][:label]}:" }
          node.children.each do |n|
            parse(n, t)
          end
        end
      end

      def requirement_parse(node, out)
        name = node["type"]
        out.div **{ class: "require" } do |t|
          t.title { |b| b << "Requirement #{get_anchors[node['id']][:label]}:" }
          node.children.each do |n|
            parse(n, t)
          end
        end
      end

      def permission_parse(node, out)
        name = node["type"]
        out.div **{ class: "permission" } do |t|
          t.title { |b| b << "Permission #{get_anchors[node['id']][:label]}:" }
          node.children.each do |n|
            parse(n, t)
          end
        end
      end

      def errata_parse(node, out)
        out.table **make_table_attr(node) do |t|
          t.thead do |h|
            h.tr do |tr|
              %w(Date Type Change Pages).each do |hdr|
                tr.th hdr
              end
            end
          end
          t.tbody do |b|
            node.xpath(ns("./row")).each do |row|
              b.tr do |tr|
                tr.td do |td|
                  row&.at(ns("./date"))&.children.each do |n|
                    parse(n, td)
                  end
                end
                tr.td do |td|
                  row&.at(ns("./type"))&.children.each do |n|
                    parse(n, td)
                  end
                end
                tr.td do |td|
                  row&.at(ns("./change"))&.children.each do |n|
                    parse(n, td)
                  end
                end
                tr.td do |td|
                  row&.at(ns("./pages"))&.children.each do |n|
                    parse(n, td)
                  end
                end
              end
            end
          end
        end
      end

      MIDDLE_CLAUSE = "//clause[parent::sections]|//terms[parent::sections]".freeze

      def middle(isoxml, out)
        middle_title(out)
        clause isoxml, out
        bibliography isoxml, out
        annex isoxml, out
      end

      def info(isoxml, out)
        @meta.keywords isoxml, out
        super
      end

      SECTIONS_XPATH =
        "//foreword | //introduction | //reviewnote | //execsummary | //annex | "\
        "//sections/clause | //bibliography/references | "\
        "//bibliography/clause".freeze

      def initial_anchor_names(d)
        d.xpath("//xmlns:preface/child::*").each do |c|
          preface_names(c)
        end
        sequential_asset_names(d.xpath("//xmlns:preface/child::*"))
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

=begin
      def prefaceprefix(nodes)
        i = 0
        nodes.each do |n|
          case n.name
          when "executivesummary" then @anchors[n["id"]][:prefix] = "ES"
          when "abstract" then @anchors[n["id"]][:prefix] = "ABS"
          when "reviewernote" then @anchors[n["id"]][:prefix] = "NTR"
          else
            @anchors[n["id"]][:prefix] = "PR" + i.to_s
            i += 1
          end
        end
      end

      def middle_section_asset_names(d)
        prefaceprefix(d.xpath("//xmlns:preface/child::*"))
        d.xpath("//xmlns:preface/child::*").each do |s|
          hierarchical_asset_names(s, @anchors[s["id"]][:prefix])
        end
        d.xpath("//xmlns:sections/child::*").each do |s|
          hierarchical_asset_names(s, @anchors[s["id"]][:label])
        end
      end
=end

      def middle_section_asset_names(d)
        middle_sections = 
          "//xmlns:preface/child::* | //xmlns:sections/child::*"
        sequential_asset_names(d.xpath(middle_sections))
      end

      def sequential_asset_names(clause)
        super
        sequential_permission_names(clause)
        sequential_requirement_names(clause)
        sequential_recommendation_names(clause)
      end

      def sequential_permission_names(clause)
        clause.xpath(ns(".//permission")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct(i + 1, t, "Permission", "permission")
        end
      end

      def sequential_requirement_names(clause)
        clause.xpath(ns(".//requirement")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct(i + 1, t, "Requirement", "requirement")
        end
      end

      def sequential_recommendation_names(clause)
        clause.xpath(ns(".//recommendation")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct(i + 1, t, "Recommendation", "recommendation")
        end
      end


      def hierarchical_asset_names(clause, num)
        super
        hierarchical_permission_names(clause, num)
        hierarchical_requirement_names(clause, num)
        hierarchical_recommendation_names(clause, num)
      end

      def hierarchical_permission_names(clause, num)
        clause.xpath(ns(".//permission")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct("#{num}.#{i + 1}",
                                            t, "Permission", "permission")
        end
      end

      def hierarchical_requirement_names(clause, num)
        clause.xpath(ns(".//requirement")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct("#{num}.#{i + 1}",
                                            t, "Requirement", "requirement")
        end
      end

      def hierarchical_recommendation_names(clause, num)
        clause.xpath(ns(".//recommendation")).each_with_index do |t, i|
          next if t["id"].nil? || t["id"].empty?
          @anchors[t["id"]] = anchor_struct("#{num}.#{i + 1}",
                                            t, "Recommendation", "recommendation")
        end
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
            name&.children&.each { |c2| parse(c2, b) }
          end
        end
      end

      def hiersep
        "-"
      end

      def annex_names(clause, num)
        @anchors[clause["id"]] = { label: annex_name_lbl(clause, num), type: "clause",
                                   xref: "#{@annex_lbl} #{num}", level: 1 }
        clause.xpath(ns("./clause | ./terms | ./term")).each_with_index do |c, i|
          annex_names1(c, "#{num}.#{i + 1}", 2)
        end
        hierarchical_asset_names(clause, num)
      end

      def annex_names1(clause, num, level)
        @anchors[clause["id"]] = { label: num, xref: "#{@annex_lbl} #{num}",
                                   level: level, type: "clause" }
        clause.xpath(ns("./clause | ./terms | ./term")).each_with_index do |c, i|
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

      def termdef_parse(node, out)
        pref = node.at(ns("./preferred"))
        out.dl **{ class: "terms_dl" } do |dl|
          dl.dt do |dt|
            pref.children.each { |n| parse(n, dt) }
          end
          set_termdomain("")
          dl.dd do |dd|
            node.children.each { |n| parse(n, dd) unless n.name == "preferred" }
          end
        end
      end

      def term_cleanup(docxml)
        docxml.xpath("//dl[@class = 'terms_dl']").each do |d|
          prev = d.previous_element
          next unless prev.name == "dl" and prev["class"] == "terms_dl"
          d.children.each { |n| prev.add_child(n.remove) }
          d.remove
        end
        docxml
      end
    end
  end
end
