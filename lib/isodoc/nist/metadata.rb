require "isodoc"

module IsoDoc
  module NIST

    class Metadata < IsoDoc::Metadata
      def initialize(lang, script, labels)
        super
        set(:status, "XXX")
      end

      def title(isoxml, _out)
        main = isoxml&.at(ns("//bibdata/title[@language='en']"))&.text
        set(:doctitle, main)
      end

      def subtitle(isoxml, _out)
        main = isoxml&.at(ns("//bibdata/subtitle[@language='en']"))&.text
        set(:docsubtitle, main)
      end

      def author(isoxml, _out)
        tc = isoxml.at(ns("//bibdata/editorialgroup/committee"))
        set(:tc, tc.text) if tc
        authors = isoxml.xpath(ns("//bibdata/contributor[role/@type = 'author' "\
                                  "or xmlns:role/@type = 'editor']/person/name"))
        set(:authors, extract_person_names(authors))
      end

            def extract_person_names(authors)
        ret = []
        authors.each do |a|
          if a.at(ns("./completename"))
            ret << a.at(ns("./completename")).text
          else
            fn = []
            forenames = a.xpath(ns("./forename"))
            forenames.each { |f| fn << f.text }
            surname = a&.at(ns("./surname"))&.text
            ret << fn.join(" ") + " " + surname
          end
        end
        ret
      end

      def docid(isoxml, _out)
        docnumber_node = isoxml.at(ns("//bibdata/docidentifier"))
        docnumber = docnumber_node&.text
        set(:docnumber, docnumber)
        # TODO: for NIST SPs only!!!
        set(:docnumber_long, docnumber.gsub("NIST SP", "NIST Special Publication"))
      end

      def status_abbr(status)
        case status
        when "working-draft" then "wd"
        when "committee-draft" then "cd"
        when "draft-standard" then "d"
        else
          ""
        end
      end

      def version(isoxml, _out)
        super
        revdate = get[:revdate]
        set(:revdate_monthyear, monthyr(revdate))
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

      def url(xml, _out)
        super
        a = xml.at(ns("//bibdata/source[@type = 'email']")) and set(:email, a.text)
      end

    end
  end
end
