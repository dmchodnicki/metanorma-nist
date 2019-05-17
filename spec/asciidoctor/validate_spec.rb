require "spec_helper"
require "fileutils"

RSpec.describe Asciidoctor::NIST do

   it "Warns of illegal doctype" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/pizza is not a recognised document type/).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :doctype: pizza

  text
  INPUT
end

it "Warns of illegal status" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/pizza is not a recognised stage/).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :status: pizza

  text
  INPUT
end

it "Warns of illegal substage" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/pizza is not a recognised substage/).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :status: draft-public
  :substage: pizza

  text
  INPUT
end

it "Warns of illegal iteration" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/pizza is not a recognised iteration/).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :status: draft-public
  :iteration: pizza

  text
  INPUT
end

it "Warns of illegal series" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/pizza is not a recognised series/).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :series: pizza

  text
  INPUT
end

  it "warns that the references are not in the expected sequence" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/Reference clauses[^\n\r]*do not follow expected pattern in NIST/).to_stderr
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      [bibliography]
      == Normative References
    INPUT
  end

  it "does not warn that the references are not in the expected sequence when they are acceptable" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.not_to output(/Reference clauses[^\n\r]*do not follow expected pattern in NIST/).to_stderr
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == References
    INPUT
  end

  it "warns that first section in body is not Introduction" do
    expect { Asciidoctor.convert(<<~"INPUT", backend: :nist, header_footer: true) }.to output(/First section of document body should be Introduction, not Untroduction/).to_stderr
      #{VALIDATING_BLANK_HDR}

      [preface]
      == Preface

      == Untroduction

      [bibliography]
      == References
    INPUT
  end

end
