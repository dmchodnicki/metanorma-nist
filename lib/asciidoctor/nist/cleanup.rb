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
        x.xpath("//clause[@preface]").each do |c|
          c.delete("preface")
          title = c&.at("./title")&.text.downcase
          c.name = "reviewernote" if title == "note to reviewers"
          c.name = "executivesummary" if title == "executive summary"
          preface.add_child c.remove
        end
      end

      def move_authority_into_preface(x, preface)
        if x.at("//authority")
          boilerplate = x.at("//authority")
          preface.add_child boilerplate.remove
        else
          preface.add_child boilerplate(x)
        end
      end

      def move_sections_into_preface(x, preface)
        abstract = x.at("//abstract") and preface.add_child abstract.remove
        move_authority_into_preface(x, preface)
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
    end
  end
end
