require "isodoc"
require_relative "metadata"
require "fileutils"
require "sassc"
require_relative "base_convert"

module IsoDoc
  module NIST
    # A {Converter} implementation that generates Word output, and a document
    # schema encapsulation of the document for validation

    class WordConvert < IsoDoc::WordConvert
      def initialize(options)
        @libdir = File.dirname(__FILE__)
        super
      end

      def convert1(docxml, filename, dir)
        @bibliographycount = docxml.xpath(ns("//bibliography/references | //annex/references | //bibliography/clause/references")).size
        FileUtils.cp html_doc_path("logo.png"), "#{@localdir}/logo.png"
        FileUtils.cp html_doc_path("deptofcommerce.png"),
          "#{@localdir}/deptofcommerce.png"
        super
      end

      def default_fonts(options)
        {
          bodyfont: (options[:script] == "Hans" ? '"SimSun",serif' :
                     '"Times New Roman",serif'),
                     headerfont: (options[:script] == "Hans" ? '"SimHei",sans-serif' :
                                  '"Arial",sans-serif'),
                                  monospacefont: '"Courier New",monospace'
        }
      end

      def default_file_locations(_options)
        {
          wordstylesheet: html_doc_path("wordstyle.scss"),
          standardstylesheet: html_doc_path("nist.scss"),
          header: html_doc_path("header.html"),
          wordcoverpage: html_doc_path("word_nist_titlepage.html"),
          wordintropage: html_doc_path("word_nist_intro.html"),
          ulstyle: "l3",
          olstyle: "l2",
        }
      end

      def metadata_init(lang, script, labels)
        @meta = Metadata.new(lang, script, labels)
      end

      def make_body(xml, docxml)
        body_attr = { lang: "EN-US", link: "blue", vlink: "#954F72" }
        xml.body **body_attr do |body|
          make_body1(body, docxml)
          make_body2(body, docxml)
          make_body3(body, docxml)
        end
      end

      def make_body2(body, docxml)
        body.div **{ class: "WordSection2" } do |div2|
          @prefacenum = 0
          info docxml, div2
          abstract docxml, div2
          keywords docxml, div2
          boilerplate docxml, div2
          preface docxml, div2
          div2.p { |p| p << "&nbsp;" } # placeholder
        end
        section_break(body)
      end

      def authority_cleanup(docxml)
        insert = docxml.at("//div[@class = 'WordSection2']")
        auth = docxml&.at("//div[@class = 'authority']")&.remove || return
        insert.children.first.add_previous_sibling(auth)
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
        h1_cleanup(docxml)
        word_annex_cleanup(docxml) # need it earlier
        toc_insert(docxml, @wordToClevels)
      end

      # create fallback h1 class to deal with page breaks
      def h1_cleanup(docxml)
        docxml.xpath("//h1[not(@class)]").each do |h|
          h["class"] = "NormalTitle"
        end
      end

      def word_annex_cleanup1(docxml, i)
        docxml.xpath("//h#{i}[ancestor::*[@class = 'Section3']]").each do |h2|
          h2.name = "p"
          h2["class"] = "h#{i}Annex"
        end
      end

      def word_annex_cleanup(docxml)
        word_annex_cleanup1(docxml, 2)
        word_annex_cleanup1(docxml, 3)
        word_annex_cleanup1(docxml, 4)
        word_annex_cleanup1(docxml, 5)
        word_annex_cleanup1(docxml, 6)
      end

      def toc_insert(docxml, level)
        insertion = docxml.at("//div[h1 = 'Executive Summary']/"\
                              "preceding-sibling::div[h1][1]") ||
        docxml.at("//div[@class = 'WordSection2']/child::*[last()]")
        if docxml.at("//p[@class = 'TableTitle']")
          insertion.next = make_TableWordToC(docxml)
          insertion.next = %{<p class="TOCTitle">List of Tables</p>}
        end
        if docxml.at("//p[@class = 'FigureTitle']")
          insertion.next = make_FigureWordToC(docxml)
          insertion.next = %{<p class="TOCTitle">List of Figures</p>}
        end
        if docxml.at("//p[@class = 'h1Annex']")
          insertion.next = make_AppendixWordToC(docxml)
          insertion.next = %{<p class="TOCTitle">List of Appendices</p>}
        end
        insertion.next = make_WordToC(docxml, level)
        insertion.next = %{<p class="TOCTitle" style="page-break-before:
        always;">Table of Contents</p>}
        docxml
      end

      WORD_TOC_APPENDIX_PREFACE1 = <<~TOC.freeze
      <span lang="EN-GB"><span
        style='mso-element:field-begin'></span><span
        style='mso-spacerun:yes'>&#xA0;</span>TOC
        \\h \\z \\t &quot;h1Annex,1,h2Annex,2,h3Annex,3&quot; <span
        style='mso-element:field-separator'></span></span>
      TOC

      WORD_TOC_TABLE_PREFACE1 = <<~TOC.freeze
      <span lang="EN-GB"><span
        style='mso-element:field-begin'></span><span
        style='mso-spacerun:yes'>&#xA0;</span>TOC
        \\h \\z \\t &quot;TableTitle,1&quot; <span
        style='mso-element:field-separator'></span></span>
      TOC

      WORD_TOC_FIGURE_PREFACE1 = <<~TOC.freeze
      <span lang="EN-GB"><span
        style='mso-element:field-begin'></span><span
        style='mso-spacerun:yes'>&#xA0;</span>TOC
        \\h \\z \\t &quot;FigureTitle,1&quot; <span
        style='mso-element:field-separator'></span></span>
      TOC

      def header_strip(h)
        h = h.to_s.gsub(/<\/?p[^>]*>/, "")
        super
      end

      def make_TableWordToC(docxml)
        toc = ""
        docxml.xpath("//p[@class = 'TableTitle']").each do |h|
          toc += word_toc_entry(1, header_strip(h))
        end
        toc.sub(/(<p class="MsoToc1">)/,
                %{\\1#{WORD_TOC_TABLE_PREFACE1}}) +  WORD_TOC_SUFFIX1
      end

      def make_FigureWordToC(docxml)
        toc = ""
        docxml.xpath("//p[@class = 'FigureTitle']").each do |h|
          toc += word_toc_entry(1, header_strip(h))
        end
        toc.sub(/(<p class="MsoToc1">)/,
                %{\\1#{WORD_TOC_FIGURE_PREFACE1}}) +  WORD_TOC_SUFFIX1
      end

      def make_AppendixWordToC(docxml)
        toc = ""
        docxml.xpath("//p[@class = 'h1Annex'] | //p[@class = 'h2Annex'] | "\
                     "p[@class = 'h3Annex']").each do |h|
          toc += word_toc_entry(h["class"][1].to_i, header_strip(h))
        end
        toc.sub(/(<p class="MsoToc1">)/,
                %{\\1#{WORD_TOC_APPENDIX_PREFACE1}}) +  WORD_TOC_SUFFIX1
      end

      def word_preface_cleanup(docxml)
        docxml.xpath("//h1[@class = 'AbstractTitle'] | "\
                     "//h1[@class = 'IntroTitle'] |
                     //h1[parent::div/@class = 'authority']").each do |h2|
          h2.name = "p"
          h2["class"] = "h1Preface"
        end
        docxml.xpath("//h2[ancestor::div/@class = 'authority']").each do |h2|
          h2.name = "p"
          h2["class"] = "h2Preface"
        end
      end

      def word_cleanup(docxml)
        super
        word_preface_cleanup(docxml)
        authority_cleanup(docxml)
        docxml
      end

      def bibliography(isoxml, out)
        f = isoxml.at(ns("//bibliography/clause | "\
                         "//bibliography/references")) || return
        page_break(out)
        isoxml.xpath(ns("//bibliography/clause | "\
                        "//bibliography/references")).each do |f|
          out.div do |div|
            #div.p **{ class: "h1Annex" } do |h1|
            div.h1 do |h1|
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
        #out.div **{ class: "Section3" } do |div|
        out.div do |div|
          clause_name(nil, "Keywords", div,  class: "IntroTitle")
          div.p kw.sort.join("; ")
        end
      end

      def termdef_parse(node, out)
        pref = node.at(ns("./preferred"))
        out.table **{ class: "terms_dl" } do |dl|
          dl.tr do |tr|
            tr.td **{ valign: "top", align: "left" } do |dt|
              pref.children.each { |n| parse(n, dt) }
            end
            set_termdomain("")
            tr.td **{ valign: "top" } do |dd|
              node.children.each { |n| parse(n, dd) unless n.name == "preferred" }
            end
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

