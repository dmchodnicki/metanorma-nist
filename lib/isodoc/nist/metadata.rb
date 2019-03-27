require "isodoc"
require "twitter_cldr"

module IsoDoc
  module NIST

    class Metadata < IsoDoc::Metadata
      def initialize(lang, script, labels)
        super
        set(:status, "XXX")
      end

      def title(isoxml, out)
        main = isoxml&.at(ns("//bibdata/title[@type = 'main']"))&.text
        set(:doctitle, main)
      end

      def subtitle(isoxml, _out)
        main = isoxml&.at(ns("//bibdata/title[@type = 'subtitle']"))&.text
        set(:docsubtitle, main) if main
        main = isoxml&.at(ns("//bibdata/title[@type = 'document-class']"))&.text
        set(:docclasstitle, main) if main
      end

      def author(isoxml, _out)
        tc = isoxml.at(ns("//bibdata/editorialgroup/committee"))
        set(:tc, tc.text.upcase) if tc
        personal_authors(isoxml)
      end

      def docid(isoxml, _out)
        docid = isoxml.at(ns("//bibdata/docidentifier[@type = 'nist']"))&.text
        docid_long = isoxml.at(ns("//bibdata/docidentifier"\
                                  "[@type = 'nist-long']"))&.text
        docnumber = isoxml.at(ns("//bibdata/docnumber"))&.text
        set(:docidentifier, docid)
        set(:docidentifier_long, draft_prefix(docid_long, isoxml))
        set(:docnumber, docnumber)
      end

      def draft_prefix(docidentifier_long, isoxml)
        return nil if docidentifier_long.nil?
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        return docidentifier_long unless docstatus && docstatus != "final"
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text
        prefix = "DRAFT "
        /^\d+$/.match iter and
          iter = iter.to_i.localize.to_rbnf_s("OrdinalRules", "digits-ordinal")
        prefix += "(#{iter}) " if iter
        prefix + docidentifier_long
      end

      def draftinfo(draft, revdate)
        draftinfo = ""
        if draft
          draftinfo = " #{@labels["draft_label"]} #{draft}"
          #draftinfo += ", #{revdate}" if revdate
        end
        IsoDoc::Function::I18n::l10n(draftinfo, @lang, @script)
      end

      def docstatus(isoxml, _out)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text
        docstatus = adjust_docstatus(docstatus, iter)
        set(:unpublished, docstatus != "final")
        set(:iteration, iter) if iter
        set(:status, status_print(docstatus || "final"))
      end

      def adjust_docstatus(status, iter)
        return unless iter and status
        status = "initial-public-draft" if status == "public-draft" &&
          (iter == "1" ||  iter == "initial")
        status = "final-public-draft" if status == "public-draft" &&
          (iter == "final")
        status
      end

      def version(isoxml, _out)
        super
        revdate = get[:revdate]
        set(:revdate_monthyear, monthyr(revdate))
      end

      def series(isoxml, _out)
        series = isoxml.at(ns("//bibdata/series[@type = 'main']/title"))&.text
        set(:series, series) if series
        subseries = isoxml.at(ns("//bibdata/series[@type = 'secondary']/"\
                                 "title"))&.text
        set(:subseries, subseries) if subseries
      end

      MONTHS = {
        "01": "January",
        "02": "February",
        "03": "March",
        "04": "April",
        "05": "May",
        "06": "June",
        "07": "July",
        "08": "August",
        "09": "September",
        "10": "October",
        "11": "November",
        "12": "December",
      }.freeze

      def monthyr(isodate)
        m = /(?<yr>\d\d\d\d)-(?<mo>\d\d)/.match isodate
        return isodate unless m && m[:yr] && m[:mo]
        return "#{MONTHS[m[:mo].to_sym]} #{m[:yr]}"
      end

      def keywords(isoxml, _out)
        keywords = []
        isoxml.xpath(ns("//bibdata/keyword")).each do |kw|
          keywords << kw.text
        end
        set(:keywords, keywords)
      end

      def commentperiod(isoxml, _out)
        from = isoxml.at(ns("//bibdata/commentperiod/from"))&.text
        to = isoxml.at(ns("//bibdata/commentperiod/to"))&.text
        extended = isoxml.at(ns("//bibdata/commentperiod/extended"))&.text
        set(:comment_from, from) if from
        set(:comment_to, to) if to
        set(:comment_extended, extended) if extended
      end

      def url(xml, _out)
        super
        a = xml.at(ns("//bibdata/uri[@type = 'email']")) and set(:email, a.text)
        a = xml.at(ns("//bibdata/uri[@type = 'doi']")) and set(:doi, a.text)
        a = xml.at(ns("//bibdata/uri[@type = 'uri' or not(@type)]")) and
          set(:url, a.text)
      end
    end
  end
end
