require "isodoc"
require_relative "metadata"
require "fileutils"
require_relative "base_convert"

module IsoDoc
  module NIST
    # A {Converter} implementation that generates PDF HTML output, and a
    # document schema encapsulation of the document for validation
    class PdfConvert < IsoDoc::PdfConvert
      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
      end

      def convert1(docxml, filename, dir)
        @bibliographycount = docxml.xpath(ns("//bibliography/references | //annex/references | //bibliography/clause/references")).size
        FileUtils.cp html_doc_path('logo.png'), File.join(@localdir, "logo.png")
        FileUtils.cp html_doc_path('commerce-logo-color.png'), File.join(@localdir, "commerce-logo-color.png")
        @files_to_delete << File.join(@localdir, "logo.png")
        @files_to_delete << File.join(@localdir, "commerce-logo-color.png")
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
          scripts_pdf: html_doc_path("scripts.pdf.html"),
        }
      end

      def metadata_init(lang, script, labels)
        @meta = Metadata.new(lang, script, labels)
      end

      def html_head()
        <<~HEAD.freeze
        <title>{{ doctitle }}</title>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>

    <!--TOC script import-->
    <script type="text/javascript"  src="https://cdn.rawgit.com/jgallen23/toc/0.3.2/dist/toc.min.js"></script>
    <script type="text/javascript">
    function toclevel() { var i; var text = "";
      for(i = 1; i <= #{@htmlToClevels}; i++) {
        if (i > 1) { text += ","; } text += "h" + i + ":not(.TermNum)"; } }
    </script>

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

      def make_body3(body, docxml)
        body.div **{ class: "main-section" } do |div3|
          abstract docxml, div3
          keywords docxml, div3
          boilerplate docxml, div3
          preface docxml, div3
          middle docxml, div3
          footnotes div3
          comments div3
        end
      end

      def authority_cleanup(docxml)
        dest = docxml.at("//div[@id = 'authority']") || return
        auth = docxml.at("//div[@class = 'authority']") || return
        dest.replace(auth.remove)
                a = docxml.at("//div[@id = 'authority1']") and a["class"] = "authority1"
        a = docxml.at("//div[@id = 'authority2']") and a["class"] = "authority2"
        a = docxml.at("//div[@id = 'authority3']") and a["class"] = "authority3"
        a = docxml.at("//div[@id = 'authority4']") and a["class"] = "authority4"
        a = docxml.at("//div[@id = 'authority5']") and a["class"] = "authority5"
      end

      def cleanup(docxml)
        super
        term_cleanup(docxml)
        requirement_cleanup(docxml)
      end

      def html_preface(docxml)
        super
        authority_cleanup(docxml)
        docxml
      end

      def bibliography(isoxml, out)
        f = isoxml.at(ns("//bibliography/clause | //bibliography/references")) || return
        page_break(out)
        isoxml.xpath(ns("//bibliography/clause | //bibliography/references")).each do |f|
          out.div do |div|
            div.h1 **{ class: "Section3" } do |h1|
              if @bibliographycount == 1
                h1 << "References"
              else
                f&.at(ns("./title"))&.children.each { |n| parse(n, h1) }
              end
            end
            f.elements.reject do |e|
              ["reference", "title", "bibitem"].include? e.name
            end.each { |e| parse(e, div) }
            biblio_list(f, div, false)
          end
        end
      end

      def keywords(_docxml, out)
        kw = @meta.get[:keywords]
        kw.empty? and return
        out.div **{ class: "Section3" } do |div|
          out.div do |div|
            clause_name(nil, "Keywords", div,  class: "IntroTitle")
            div.p kw.sort.join("; ")
          end
        end
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
        docxml.xpath("//table[@class = 'terms_dl']").each do |d|
          prev = d.previous_element
          next unless prev.name == "table" and prev["class"] == "terms_dl"
          d.children.each { |n| prev.add_child(n.remove) }
          d.remove
        end
        docxml
      end

      include BaseConvert
    end
  end
end

