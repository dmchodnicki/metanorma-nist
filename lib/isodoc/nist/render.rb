require "nokogiri"
require "twitter_cldr"

module Iso690Render
=begin
  Out of scope: Provenance (differentiating elements by @source in rendering)
=end

  def self.render(bib, embedded = false)
    docxml = Nokogiri::XML(bib)
    docxml.remove_namespaces!
    parse(docxml.root, embedded)
  end

=begin
  def self.multiplenames_and(names)
    return "" if names.length == 0
    return names[0] if names.length == 1
    return "#{names[0]} and #{names[1]}" if names.length == 2
    names[0..-2].join(", ") + " and #{names[-1]}"
  end
=end

  def self.multiplenames(names)
    names.join(", ")
  end

  def self.extract_orgname(org)
    name = org.at("./name")
    name&.text || "--"
  end

  def self.frontname(given, initials)
    if given.empty? && initials.empty? then ""
    elsif initials.empty?
      given.map{ |m| m.text[0] }.join("")
    else
      initials.map{ |m| m.text[0] }.join("")
    end
  end

  def self.commajoin(a, b)
    return a unless b
    return b unless a
    #"#{a}, #{b}"
    "#{a} #{b}"
  end

  def self.extract_personname(person)
    completename = person.at("./name/completename")
    return completename.text if completename
    surname = person.at("./name/surname")
    initials = person.xpath("./name/initials")
    forenames = person.xpath("./name/forename")
    #given = []
    #forenames.each { |x| given << x.text }
    #given.empty? && initials.each { |x| given << x.text }
    commajoin(surname&.text, frontname(forenames, initials))
  end

  def self.extractname(contributor)
    org = contributor.at("./organization")
    person = contributor.at("./person")
    return extract_orgname(org) if org
    return extract_personname(person) if person
    "--"
  end

  def self.contributorRole(contributors)
    return "" unless contributors.length > 0
    if contributors[0]&.at("role/@type")&.text == "editor"
      return contributors.length > 1 ? " (Eds.)" : "(Ed.)"
    end
    ""
  end

  def self.creatornames(doc)
    cr = doc.xpath("./contributor[role/@type = 'author']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'performer']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'adapter']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'translator']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'editor']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'publisher']") 
    cr.empty? and cr = doc.xpath("./contributor[role/@type = 'distributor']") 
    cr.empty? and cr = doc.xpath("./contributor")
    cr.empty? and return ""
    ret = []
    cr.each do |x|
      ret << extractname(x)
    end
    multiplenames(ret) + contributorRole(cr)
  end

  def self.title(doc)
    doc&.at("./title")&.text
  end

  def self.medium(doc)
    doc&.at("./medium")&.text
  end

=begin
  def self.edition(doc)
    x = doc.at("./edition")
    return "" unless x
    return x.text unless /^\d+$/.match x.text
    x.text.to_i.localize.to_rbnf_s("SpelloutRules", "spellout-ordinal")
  end
=end

  def self.is_nist(doc)
    publisher = doc&.at("./contributor[role/@type = 'publisher']/organization/name")&.text
    abbr = doc&.at("./contributor[role/@type = 'publisher']/organization/abbreviation")&.text
    publisher == "NIST" || abbr == "NIST" ||
      publisher == "National Institute of Standards and Technology"
  end

  def self.placepub(doc)
    place = doc&.at("./place")&.text
    publisher = doc&.at("./contributor[role/@type = 'publisher']/organization/name")&.text
    abbr = doc&.at("./contributor[role/@type = 'publisher']/organization/abbreviation")&.text
    series = series_title(doc)
    series == "NIST Federal Information Processing Standards" and
      return "U.S. Department of Commerce, Washington, D.C."
    is_nist(doc) and
      return "National Institute of Standards and Technology, Gaithersburg, MD"
    ret = ""
    ret += place if place
    ret += ": " if place && publisher
    ret += publisher if publisher
    ret
  end

  def self.date1(date)
    return nil if date.nil?
    on = date&.at("./on")&.text
    from = date&.at("./from")&.text
    to = date&.at("./to")&.text
    return MMMddyyyy(on) if on
    return "#{MMMddyyyy(from)}&ndash;#{MMMddyyyy(to)}" if from
    nil
  end

  def self.date(doc)
    updated = date1(doc&.at("./date[@type = 'updated']"))
    pub = date1(doc&.at("./date[@type = 'issued']"))
    if pub
      ret = pub
      ret += " (updated #{updated})" if updated
      return ret
    end
    pub = date1(doc&.at("./date[@type = 'circulated']")) and
      return pub
    date1(doc&.at("./date"))
  end

  def self.year(date)
    return nil if date.nil?
    date.sub(/^(\d\d\d\d).*$/, "\\1")
  end

  def self.series_title(doc)
    s = doc.at("./series[@type = 'main']") ||
      doc.at("./series[not(@type)]") ||
      doc.at("./series")
    s&.at("./title")&.text
  end

  def self.series(doc, type)
    s = doc.at("./series[@type = 'main']") || 
      doc.at("./series[not(@type)]") ||
      doc.at("./series")
    return "" unless s
    f = s.at("./formattedref")
    return f.text if f
    t = s.at("./title")
    a = s.at("./abbreviation")
    n = s.at("./number")
    p = s.at("./partnumber")
    dn = doc.at("./docnumber")
    rev = doc&.at(".//edition")&.text&.sub(/^Revision /, "")
    ret = ""
    if t
      title = included(type) ? wrap(t.text, " <I>", "</I>") : wrap(t.text, " ", "")
      ret += title
      ret += " (#{a.text.sub(/^NIST /, "")})" if a
    end
    if n || p
      ret += " #{n.text}" if n
      ret += ".#{p.text}" if p
    elsif dn && is_nist(doc)
      ret += " #{dn.text}"
      ret += " Rev. #{rev}" if rev
    end
    ret
  end

  def self.standardidentifier(doc)
    ret = []
    doc.xpath("./docidentifier").each do |id|
      next if %w(nist-mr nist-long).include? id["type"]
      ret << standardidentifier1(id)
    end
    ret.join(". ")
  end

  def self.standardidentifier1(id)
    r = ""
    r += "#{id['type']} " if id["type"] and
      !%w(ISO IEC NIST).include? id["type"]
    r += id.text
    r
  end

  def self.uri(doc)
    uri = doc.at("./uri[@type = 'doi']") ||
      doc.at("./uri[@type = 'uri']") ||
      doc.at("./uri")
    uri&.text
  end

  def self.accessLocation(doc)
    s = doc.at("./accessLocation") or return ""
    s.text
  end

  def self.included(type)
    ["article", "inbook", "incollection", "inproceedings"].include? type
  end

  def self.wrap(text, startdelim = " ", enddelim = ".")
    return "" if text.nil? || text.empty?
    "#{startdelim}#{text}#{enddelim}"
  end

  def self.type(doc)
    type = doc.at("./@type") and return type&.text
    doc.at("./includedIn") and return "inbook"
    "book"
  end

  def self.extent1(type, from, to)
    ret = ""
    case type 
    when "page" then type = to ? "pp." : "p."
    when "volume" then type = to ? "Vols." : "Vol."
    end
    ret += "#{type} "
    ret += from.text if from
    ret += "&ndash;#{to.text}" if to
    ret
  end

  def self.extent(localities)
    ret = []
    localities.each do |l|
      ret << extent1(l["type"] || "page", 
                     l.at("./referenceFrom"), l.at("./referenceTo"))
    end
    ret.join(", ")
  end

=begin
  def self.monthyr(isodate)
    return nil if isodate.nil?
    arr = isodate.split("-")
    date = if arr.size == 2
      DateTime.new(*arr.map(&:to_i))
    else
      DateTime.parse(isodate)
    end
    date.localize(:en).to_additional_s("yMMMM")
  end

  def self.mmddyyyy(isodate)
    return nil if isodate.nil?
    arr = isodate.split("-")
    date = if arr.size == 1 and (/^\d+$/.match isodate)
             Date.new(*arr.map(&:to_i)).strftime("%Y")
      elsif arr.size == 2
      Date.new(*arr.map(&:to_i)).strftime("%m-%Y")
    else
      Date.parse(isodate).strftime("%m-%d-%Y")
    end
  end
=end

  def self.MMMddyyyy(isodate)
    return nil if isodate.nil?
    arr = isodate.split("-")
    date = if arr.size == 1 and (/^\d+$/.match isodate)
             Date.new(*arr.map(&:to_i)).strftime("%Y")
           elsif arr.size == 2
             Date.new(*arr.map(&:to_i)).strftime("%B %Y")
           else
             Date.parse(isodate).strftime("%B %d, %Y")
           end
  end

  def self.draft(doc)
    return nil unless is_nist(doc)
    dr = doc&.at("./status/stage")&.text
    iter = doc&.at("./status/iteration")&.text
    return nil unless /^draft/.match(dr)
    iterord = iter_ordinal(doc)
    status = status_print(dr)
    status = "#{iterord} #{status}" if iterord
    status
  end

  def self.iter_ordinal(isoxml)
    docstatus = isoxml.at(("./status/stage"))&.text
    return nil unless docstatus == "draft-public"
    iter = isoxml.at(("./status/iteration"))&.text || "1"
    return "Initial" if iter == "1"
    return "Final" if iter.downcase == "final"
    iter.to_i.localize.to_rbnf_s("SpelloutRules", "spellout-ordinal").capitalize
  end

  def self.status_print(status)
    case status
    when "draft-internal" then "Internal Draft"
    when "draft-wip" then "Work-in-Progress Draft"
    when "draft-prelim" then "Preliminary Draft"
    when "draft-public" then "Public Draft"
    when "draft-approval" then "Approval Draft"
    when "final" then "Final"
    when "final-review" then "Under Review"
    end
  end

  def self.parse(doc, embedded = false)
    ret = ""
    f = doc.at("./formattedref") and 
      return embedded ? f.children.to_xml : "<p>#{f.children.to_xml}</p>"

    type = type(doc)
    container = doc.at("./relation[@type='includedIn']")
    if container && !date(doc) && date(container&.at("./bibitem"))
      doc << 
      ( container&.at("./bibitem/date[@type = 'issued' or @type = 'published' or @type = 'circulated']")&.remove )
    end
    ser = series_title(doc)
    dr = draft(doc)

    # NIST has seen fit to completely change rendering based on the type of publication.
    if ser == "NIST Federal Information Processing Standards"
      ret += "National Institute of Standards and Technology"
    else
      ret += embedded ? wrap(creatornames(doc), "", "") : wrap(creatornames(doc), "", "")
    end

    if dr
      mdy = MMMddyyyy(date(doc)) and ret += wrap(mdy, " (", ")")
    else
      yr = year(date(doc)) and ret += wrap(yr, " (", ")")
    end
    ret += included(type) ? wrap(title(doc)) : wrap(title(doc), " <I>", "</I>.")
    ret += wrap(medium(doc), " [", "].")
    #ret += wrap(edition(doc), "", " edition.")
    s = series(doc, type)
    ret += wrap(placepub(doc), " (", "),")
    if dr
      ret += " Draft (#{dr})"
    end
    ret += wrap(series(doc, type), " ", "")
    ret += "," if !series(doc, type).empty? && date(doc)
    ret += wrap(date(doc))
    ret += wrap(standardidentifier(doc)) unless is_nist(doc)
    ret += wrap(uri(doc))
    ret += wrap(accessLocation(doc), " At: ", ".")
    if container 
      ret += wrap(parse(container.at("./bibitem"), true), " In: ", "")
      locality = container.xpath("./locality")
      locality.empty? and locality = doc.xpath("./extent")
      ret += wrap(extent(locality))
    else
      ret += wrap(extent(doc.xpath("./extent")))
    end
    embedded ? ret : "<p>#{ret}</p>"
  end
end
