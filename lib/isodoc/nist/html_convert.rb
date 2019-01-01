require "isodoc"
require_relative "metadata"
require "fileutils"

module IsoDoc
  module NIST

    # A {Converter} implementation that generates HTML output, and a document
    # schema encapsulation of the document for validation
    #
    class HtmlConvert < IsoDoc::HtmlConvert
      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
        FileUtils.cp html_doc_path('logo.png'), "logo.png"
        @files_to_delete << "logo.png"
      end

      def default_fonts(options)
        {
          bodyfont: (options[:script] == "Hans" ? '"SimSun",serif' : '"Overpass",sans-serif'),
          headerfont: (options[:script] == "Hans" ? '"SimHei",sans-serif' : '"Overpass",sans-serif'),
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
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Overpass:300,300i,600,900" rel="stylesheet">
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

      def annex_name(annex, name, div)
        div.h1 **{ class: "Annex" } do |t|
          t << "#{get_anchors[annex['id']][:label]} "
          t.br
          t.b do |b|
            name&.children&.each { |c2| parse(c2, b) }
          end
        end
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

      def cleanup(docxml)
        super
        term_cleanup(docxml)
      end

      def term_cleanup(docxml)
        docxml.xpath("//p[@class = 'Terms']").each do |d|
          h2 = d.at("./preceding-sibling::*[@class = 'TermNum'][1]")
          h2.add_child("&nbsp;")
          h2.add_child(d.remove)
        end
        docxml
      end

      def example_parse(node, out)
        return pseudocode_parse(node, out) if node["type"] == "pseudocode"
        super
      end

      def pseudocode_parse(node, out)
        out.div **attr_code(id: node["id"], class: "pseudocode") do |div|
          div.p { |p| p << example_label(node) }
          node.children.each do |n|
            parse(n, div)
          end
        end
      end

      def error_parse(node, out)
        case node.name
        when "nistvariable" then nistvariable_parse(node, out)
        else
          super
        end
      end

      def nistvariable_parse(node, out)
        out.span **{class: "nistvariable"} do |s|
          node.children.each { |n| parse(n, s) }
        end
      end

      MIDDLE_CLAUSE = "//clause[parent::sections]|//terms[parent::sections]".freeze

      def middle(isoxml, out)
        middle_title(out)
        clause isoxml, out
        annex isoxml, out
        bibliography isoxml, out
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
        middle_section_asset_names(d)
        clause_names(d, 0)
        termnote_anchor_names(d)
        termexample_anchor_names(d)
      end

      def middle_section_asset_names(d)
        middle_sections = "//xmlns:preface/child::* | //xmlns:sections/child::*"
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

    end
  end
end
