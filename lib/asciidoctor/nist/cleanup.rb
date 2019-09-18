module Asciidoctor
  module NIST
    class Converter < Standoc::Converter
      def cleanup(xmldoc)
        sourcecode_cleanup(xmldoc)
        super
      end

      def sourcecode_cleanup(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          x.traverse do |n|
            next unless n.text?
            n.replace(Nokogiri::XML::NodeSet.new(n.document,
                                                 nistvariable_insert(n)))
          end
        end
      end

      # skip annex/terms/terms, which is empty node
      def termdef_subclause_cleanup(xmldoc)
        xmldoc.xpath("//terms[terms]").each do |t|
          next if t.parent.name == "terms"
          t.children.each { |n| n.parent = t.parent }
          t.remove
        end
      end

      def sections_cleanup(x)
        super
        x.xpath("//*[@inline-header]").each do |h|
          h.delete("inline-header")
        end
      end

      def move_clauses_into_preface(x, preface)
        move_clauses_into_preface1(x, preface)
        move_execsummary_into_preface(x, preface)
      end

       def move_clauses_into_preface1(x, preface)
        x.xpath("//clause[@preface]").each do |c|
          c.delete("preface")
          title = c&.at("./title")&.text.downcase
          c.name = "reviewernote" if title == "note to reviewers"
          c.name = "executivesummary" if title == "executive summary"
          preface.add_child c.remove
        end
       end

       def move_execsummary_into_preface(x, preface)
        x.xpath("//clause[@executivesummary]").each do |c|
          c.delete("executivesummary")
          title = c&.at("./title")&.text.downcase
          c.name = "executivesummary"
          preface.add_child c.remove
        end
      end

      def move_authority_before_preface(x, preface)
        if x.at("//boilerplate")
          boilerplate = x.at("//boilerplate")
          preface.previous = boilerplate.remove
        else
          preface.previous = boilerplate(x)
        end
      end

      def move_sections_into_preface(x, preface)
        move_authority_before_preface(x, preface)
        abstract = x.at("//abstract") and preface.add_child abstract.remove
        foreword = x.at("//foreword") and preface.add_child foreword.remove
        intro = x.at("//introduction") and preface.add_child intro.remove
        move_clauses_into_preface(x, preface)
        callforpatentclaims(x, preface)
      end

      def callforpatentclaims(x, preface)
        if @callforpatentclaims
          docemail = x&.at("//uri[@type = 'email']")&.text || "???"
          docnumber = x&.at("//docnumber")&.text || "???"
          status = x&.at("//bibdata/status/stage")&.text
          published = status.nil? || /^final/.match(status)
          preface.add_child patent_text(published, docemail, docnumber)
        end
      end

      def patent_text(published, docemail, docnumber)
        patent = (!published ? CALL_FOR_PATENT_CLAIMS :
                  (@commitmenttolicence ? PATENT_DISCLOSURE_NOTICE1 :
                   PATENT_DISCLOSURE_NOTICE2)).clone
        patent.gsub(/ITL-POINT-OF_CONTACT/, published ?
                    (@patentcontact || docemail) :
                    (@patentcontact ||
                     "#{docemail}, with the Subject: #{docnumber} "\
                     "Call for Patent Claims"))
      end

      def make_preface(x, s)
        preface = s.add_previous_sibling("<preface/>").first
        move_sections_into_preface(x, preface)
        summ = x.at("//executivesummary") and preface.add_child summ.remove
        #end
      end


      # handle NIST references separately
      # doc identifier format, NIST: NIST SP 800-87-1 {Vol./Volume 8}|
      # {Rev./Revision 8}|(Month YYYY)
      def reference_names(docxml)
        super
        ret = get_all_nist_refs(docxml)
        tallies = ret.inject(Hash.new(0)) do |memo, (k, v)|
          memo[v[:trunc]] += 1
          memo
        end
        ret.each do |k, v|
          tallies[v[:trunc]] == 1 and @anchors[k][:xref] = v[:trunc]
          @anchors[k][:xref].sub!(/^NIST /, "")
        end
      end

      def truncate_nist_ref(text)
        #text.sub(/\s\((January|February|March|April|May|June|July|August|
        #                September|October|November|December)\s\d\d\d\d\).*$/x, "")
        text
      end

      def get_all_nist_refs(docxml)
        ret = {}
        docxml.xpath("//bibitem[not(ancestor::bibitem)]").each do |ref|
          #next unless ref.at("./docidentifier[@type = 'NIST']")
          ret[ref["id"]] = {}
          ret[ref["id"]][:xref] = ref&.at("./docidentifier[not(@type = 'DOI')]")&.text or next
          ret[ref["id"]][:trunc] = truncate_nist_ref(ret[ref["id"]][:xref])
        end
        ret
      end

      TERM_CLAUSE = "//sections/terms | "\
        "//sections/clause[descendant::terms] | "\
        "//annex/terms | "\
        "//annex/clause[descendant::terms] ".freeze

      def boilerplate_cleanup(xmldoc)
        isodoc = IsoDoc::Convert.new({})
        @lang = xmldoc&.at("//bibdata/language")&.text
        @script = xmldoc&.at("//bibdata/script")&.text
        isodoc.i18n_init(@lang, @script)
        f = xmldoc.at(self.class::TERM_CLAUSE) and
          term_defs_boilerplate(f.at("../title"),
                                xmldoc.xpath(".//termdocsource"),
                                f.at(".//term"), f.at(".//p"), isodoc)
      end

      def sort_biblio(bib)
        @citation_order = {}
        bib.document.xpath("//xref | //origin").each_with_index do |x, i|
          cit = x["target"] || x["bibitemid"]
          next unless refid? cit
          @citation_order[cit] ||= i
        end
        bib.sort do |a, b|
          sort_biblio_key(a) <=> sort_biblio_key(b)
        end
      end

      # if numeric citation, order by appearance. if alphanumeric, sort alphabetically
      # if identifier, zero-pad numeric component for NIST ids
      def sort_biblio_key(bib)
        if metaid = bib&.at("./docidentifier[@type = 'metanorma']")&.text&.gsub(%r{[\[\]]}, "")
          key = /^\[\d+\]$/.match(metaid) ? ( @citation_order[metaid] % "09%d" ) : metaid
        elsif metaid = bib&.at("./docidentifier[@type = 'NIST']")&.text
          key = metaid.sub(/-(\d+)/) {|m| sprintf "-%09d", ($1.to_i) }
        else
          metaid = bib&.at("./docidentifier[not(@type = 'DOI' or "\
                           "@type = 'metanorma' or @type = 'ISSN' or @type = 'ISBN')]")&.text
          key = metaid.sub(/-(\d+)/) {|m| sprintf "-%09d", ($1.to_i) }
        end
        title = bib&.at("./title[@type = 'main']")&.text ||
          bib&.at("./title")&.text || bib&.at("./formattedref")&.text
        "#{key} :: #{title}"
      end
    end
  end
end
