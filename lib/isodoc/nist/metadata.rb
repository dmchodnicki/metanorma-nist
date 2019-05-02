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
        short = isoxml&.at(ns("//bibdata/title[@type = 'short-title']"))&.text
        set(:doctitle_short, short || main)
      end

      def subtitle(isoxml, _out)
        main = isoxml&.at(ns("//bibdata/title[@type = 'subtitle']"))&.text
        set(:docsubtitle, main) if main
        short = isoxml&.at(ns("//bibdata/title[@type = 'short-subtitle']"))&.text
        set(:docsubtitle_short, short || main) if (short || main)
        main = isoxml&.at(ns("//bibdata/title[@type = 'document-class']"))&.text
        set(:docclasstitle, main) if main
      end

      def author(isoxml, _out)
        tc = isoxml.at(ns("//bibdata/editorialgroup/committee"))
        set(:tc, tc.text.upcase) if tc
        personal_authors(isoxml)
        subdiv = isoxml.at(ns("//bibdata/contributor[role/@type = 'publisher']/organization/subdivision"))
        set(:nist_subdiv, subdiv.text) if subdiv
      end

      def docid(isoxml, _out)
        docid = isoxml.at(ns("//bibdata/docidentifier[@type = 'nist']"))&.text
        docid_long = isoxml.at(ns("//bibdata/docidentifier"\
                                  "[@type = 'nist-long']"))&.text
        docnumber = isoxml.at(ns("//bibdata/docnumber"))&.text
        set(:docidentifier, docid)
        set(:docidentifier_long, docid_long)
        set(:docidentifier_undated, stripdate(docid))
        set(:docidentifier_long_undated, stripdate(docid_long))
        d = draft_prefix(isoxml) and set(:draft_prefix, d)
        d = iter_code(isoxml) and set(:iteration_code, d)
        d = iter_ordinal(isoxml) and set(:iteration_ordinal, d)
        set(:docnumber, docnumber)
      end

      def stripdate(id)
        return if id.nil?
        id.sub(/ \((Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[^)]+\)$/, "")
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

      def iter_ordinal(isoxml)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        return nil unless docstatus == "draft-public"
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text || "1"
        return "Initial" if iter == "1"
        return "Final" if iter.downcase == "final"
        iter.to_i.localize.to_rbnf_s("SpelloutRules", "spellout-ordinal")
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
        set(:unpublished, !/^draft/.match(docstatus).nil?)
        substage = isoxml.at(ns("//bibdata/status/substage"))&.text
        substage and set(:substage, substage)
        iter = isoxml.at(ns("//bibdata/status/iteration"))&.text
        set(:iteration, iter) if iter
        set(:status, status_print(docstatus || "final"))
        set(:errata, true) if isoxml.at(ns("//errata"))
      end

      def status_print(status)
        case status
        when "draft-internal" then "Internal Draft"
        when "draft-wip" then "Work-in-Progress Draft"
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
        set(:revdate_MMMddyyyy, MMMddyyyy(revdate))
      end

      def bibdate(isoxml, _out)
        super
        isoxml.xpath(ns("//bibdata/date")).each do |d|
          val = Common::date_range(d)
          next if val == "XXX"
          set("#{d['type']}date_monthyear".to_sym, daterange_proc(val, :monthyr))
          set("#{d['type']}date_mmddyyyy".to_sym, daterange_proc(val, :mmddyyyy))
          set("#{d['type']}date_MMMddyyyy".to_sym, daterange_proc(val, :MMMddyyyy))
        end
        withdrawal_pending(isoxml)
        most_recent_date(isoxml)
      end

      def most_recent_date(isoxml)
        date = most_recent_date1(isoxml) || return
        val = Common::date_range(date)
        return if val == "XXX"
        set(:most_recent_date_monthyear, daterange_proc(val, :monthyr))
        set(:most_recent_date_mmddyyyy, daterange_proc(val, :mmddyyyy))
        set(:most_recent_date_MMMddyyyy, daterange_proc(val, :MMMddyyyy))
      end

      def most_recent_date1(isoxml)
        docstatus = isoxml.at(ns("//bibdata/status/stage"))&.text
        /^draft/.match(docstatus) ?
          (isoxml.at(ns("//bibdata/date[@type = 'circulated']")) ||
           isoxml.at(ns("//version/revision-date"))) :
        ( isoxml.at(ns("//bibdata/date[@type = 'issued']")))
      end

      def withdrawal_pending(isoxml)
        d = isoxml&.at(ns("//bibdata/date[@type = 'obsoleted']"))&.text or return
        date = Date.parse(d) or return
        set(:withdrawal_pending, true) if date > Date.today
      end

      def daterange_proc(val, fn)
        m = /^(?<date1>[^&]+)(?<ndash>\&ndash;)?(?<date2>.*)$/.match val
        val_monthyear = self.send(fn, m[:date1])
        val_monthyear += "&ndash;" if m[:ndash]
        val_monthyear += self.send(fn, m[:date2]) unless m[:date2].empty?
        val_monthyear
      end

      def series(isoxml, _out)
        series = isoxml.at(ns("//bibdata/series[@type = 'main']/title"))&.text
        set(:series, series) if series
        subseries = isoxml.at(ns("//bibdata/series[@type = 'secondary']/"\
                                 "title"))&.text
        set(:subseries, subseries) if subseries
      end

      def monthyr(isodate)
        return nil if isodate.nil?
        DateTime.parse(isodate).localize(:en).to_additional_s("yMMMM")
      end

      def mmddyyyy(isodate)
        return nil if isodate.nil?
        Date.parse(isodate).strftime("%m-%d-%Y")
      end

      def MMMddyyyy(isodate)
        return nil if isodate.nil?
        Date.parse(isodate).strftime("%B %d, %Y")
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
        superseding_doc(isoxml)
      end

      def superseding_doc(isoxml)
        d = isoxml.at(ns("//bibdata/relation[@type = 'obsoletedBy']/bibitem"))
        return unless d
        set(:superseding_status,
            status_print(d.at(ns("./status/stage"))&.text || "final"))
        superseding_iteration(d)
        docid = d.at(ns("./docidentifier[@type = 'nist']"))&.text and
          set(:superseding_docidentifier, docid)
        docid_long = d.at(ns("./docidentifier[@type = 'nist-long']"))&.text and
          set(:superseding_docidentifier_long, docid_long)
        superseding_dates(d)
        doi = d.at(ns("./uri[@type = 'doi']"))&.text and
          set(:superseding_doi, doi)
        uri = d.at(ns("./uri[@type = 'uri']"))&.text and
          set(:superseding_uri, uri)
        superseding_titles(isoxml, d)
        authors = d.xpath(ns("./contributor[role/@type = 'author']/person"))
        authors = isoxml.xpath(ns("//bibdata/contributor[role/@type = 'author']/person")) if authors.empty?
        set(:superseding_authors, extract_person_names(authors))
      end

      def superseding_titles(isoxml, d)
        title = d.at(ns("./title[@type = 'main']"))&.text
        if title
          set(:superseding_title, d.at(ns("./title[@type = 'main']"))&.text)
          set(:superseding_subtitle, d.at(ns("./title[@type = 'subtitle']"))&.text)
        else
          set(:superseding_title, isoxml.at(ns("//bibdata/title[@type = 'main']"))&.text)
          set(:superseding_subtitle, isoxml.at(ns("//bibdata/title[@type = 'subtitle']"))&.text)
        end
      end

      def superseding_iteration(d)
        return unless d.at(ns("./status/stage"))&.text == "draft-public"
        iter = d.at(ns("./status/iteration"))&.text || "1"
        case iter.downcase
        when "1"
          set(:superseding_iteration_ordinal, "Initial")
          set(:superseding_iteration_code, "IPD")
        when "final"
          set(:superseding_iteration_ordinal, "Final")
          set(:superseding_iteration_code, "FPD")
        else
          set(:superseding_iteration_ordinal,
              iter.to_i.localize.to_rbnf_s("SpelloutRules", "spellout-ordinal"))
          set(:superseding_iteration_code, "#{iter}PD")
        end
      end

      def superseding_dates(d)
        if cdate = d.at(ns("./date[@type = 'circulated']/on"))&.text
          set(:superseding_circulated_date, cdate)
          set(:superseding_circulated_date_monthyear, monthyr(cdate))
        end
        if cdate = d.at(ns("./date[@type = 'issued']/on"))&.text
          set(:superseding_issued_date, cdate)
          set(:superseding_issued_date_monthyear, monthyr(cdate))
        end
        if cdate = d.at(ns("./date[@type = 'updated']/on"))&.text
          set(:superseding_updated_date, cdate)
          set(:superseding_updated_date_monthyear, monthyr(cdate))
          set(:superseding_updated_date_MMMddyyyy, MMMddyyyy(cdate))
        end
      end

      def note(xml, _out)
        note = xml.at(ns("//bibdata/note[@type = 'additional-note']"))&.text and
          set(:additional_note, note)
        note = xml.at(ns("//bibdata/note[@type = 'withdrawal-note']"))&.text and
          set(:withdrawal_note, note)
        note = xml.at(ns("//bibdata/note[@type = 'withdrawal-announcement-link']"))&.text and
          set(:withdrawal_announcement_link, note)
      end
    end
  end
end
