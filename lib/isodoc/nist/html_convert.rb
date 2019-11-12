require "isodoc"
require_relative "metadata"
require "fileutils"
require_relative "base_convert"

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
        @bibliographycount = docxml.xpath(ns("//bibliography/references | //annex/references | //bibliography/clause/references")).size
        #FileUtils.cp html_doc_path('logo.png'), "#{@localdir}/logo.png"
        #FileUtils.cp html_doc_path('commerce-logo-color.png'), "#{@localdir}/commerce-logo-color.png"
        #@files_to_delete << "#{@localdir}/logo.png"
        #@files_to_delete << "#{@localdir}/commerce-logo-color.png"
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

      def googlefonts
        <<~HEAD.freeze
    <link href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,600,600i" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css?family=Libre+Baskerville:400,400i,700,700i" rel="stylesheet">
        HEAD
      end

      def toclevel
        ret = toclevel_classes.map { |l| "#{l}:not(:empty):not(.TermNum):not(.noTOC):not(.AbstractTitle):not(.IntroTitle):not(.ForewordTitle)" }
      <<~HEAD.freeze
    function toclevel() { return "#{ret.join(',')}";}
      HEAD
    end

      def html_toc(docxml)
      idx = docxml.at("//div[@id = 'toc']") or return docxml
      toc = "<ul>"
      path = toclevel_classes.map do |l|
        "//main//#{l}[not(@class = 'TermNum')][not(@class = 'noTOC')][not(text())][not(@class = 'AbstractTitle')][not(@class = 'IntroTitle')][not(@class = 'ForewordTitle')]"
      end
      docxml.xpath(path.join(" | ")).each_with_index do |h, tocidx|
        h["id"] ||= "toc#{tocidx}"
        toc += html_toc_entry(h.name, h)
      end
      idx.children = "#{toc}</ul>"
      docxml
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

      def authority_cleanup(docxml)
        dest = docxml.at("//div[@id = 'authority']") || return
        auth = docxml.at("//div[@class = 'authority']") || return
        auth.xpath(".//h1 | .//h2").each { |h| h["class"] = "IntroTitle" }
        dest.replace(auth.remove)
        a = docxml.at("//div[@id = 'authority1']") and a["class"] = "authority1"
        a = docxml.at("//div[@id = 'authority2']") and a["class"] = "authority2"
        a = docxml.at("//div[@id = 'authority3']") and a["class"] = "authority3"
        a = docxml.at("//div[@id = 'authority3a']") and a["class"] = "authority3"
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

      def make_body3(body, docxml)
        body.div **{ class: "main-section" } do |div3|
          foreword docxml, div3
          abstract docxml, div3
          keywords docxml, div3
          boilerplate docxml, div3
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
          next unless prev and prev.name == "table" and prev["class"] == "terms_dl"
          d.children.each { |n| prev.add_child(n.remove) }
          d.remove
        end
        docxml
      end

      include BaseConvert
    end
  end
end
