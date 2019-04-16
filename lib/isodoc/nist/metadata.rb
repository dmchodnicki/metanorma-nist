require "isodoc"

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
        set(:docidentifier_long, docid_long)
        d = draft_prefix(isoxml) and set(:draft_prefix, d)
        d = iter_code(isoxml) and set(:iteration_code, d)
        set(:docnumber, docnumber)
      end

      def draft_prefix(isoxml)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        return nil unless docstatus && /^draft/.match(docstatus)
        iter = iter_code(isoxml)
        prefix = "DRAFT "
        iter and prefix += "(#{iter}) "
        prefix
      end

      def iter_code(isoxml)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        return nil unless docstatus == "draft-public"
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text || "1"
        return "IPD" if iter == "1"
        return "FPD" if iter.downcase == "final"
        "#{iter}PD"
      end

      def draftinfo(draft, revdate)
        draftinfo = ""
        if draft
          draftinfo = " #{@labels["draft_label"]} #{draft}"
        end
        IsoDoc::Function::I18n::l10n(draftinfo, @lang, @script)
      end

      def docstatus(isoxml, _out)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text
        set(:unpublished, !/^draft/.match(docstatus).nil?)
        set(:iteration, iter) if iter
        set(:status, status_print(docstatus || "final"))
      end

      def status_print(status)
        case status
        when "draft-internal" then "Internal Draft"
        when "draft-wip" then "Work In Progress Draft"
        when "draft-prelim" then "Preliminary Draft"
        when "draft-public" then "Public Draft"
        when "draft-retire" then "Retired Draft"
        when "draft-withdrawn" then "Withdrawn Draft"
        when "final" then "Final"
        when "final-review" then "Under Review"
        when "final-withdrawn" then "Withdrawn"
        end
      end

      def version(isoxml, _out)
        super
        set(:revision, isoxml&.at(ns("//bibdata/revision"))&.text)
        revdate = get[:revdate]
        set(:revdate_monthyear, monthyr(revdate))
      end

      def bibdate(isoxml, _out)
        super
        date = get[:publisheddate]
        date and date != "XXX" and
          set(:publisheddate_monthyear, monthyr(date))
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

      def relations1(isoxml, type)
        ret = []
        isoxml.xpath(ns("//bibdata/relation[@type = '#{type}']")).each do |x|
          id = x&.at(ns(".//docidentifier"))&.text and ret << id
        end
        ret
      end

      def relations(isoxml, _out)
        ret = relations1(isoxml, "obsoletes")
        set(:obsoletes, ret) unless ret.empty?
        ret = relations1(isoxml, "obsoletedBy")
        set(:obsoletedby, ret) unless ret.empty?
        ret = relations1(isoxml, "supersedes")
        set(:supersedes, ret) unless ret.empty?
        ret = relations1(isoxml, "supersededBy")
        set(:supersededby, ret) unless ret.empty?
      end
    end
  end
end
