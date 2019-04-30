require "asciidoctor" unless defined? Asciidoctor::Converter
require_relative "asciidoctor/nist/converter"
require_relative "isodoc/nist/html_convert"
require_relative "isodoc/nist/pdf_convert"
require_relative "isodoc/nist/word_convert"
require_relative "isodoc/nist/render"
require_relative "metanorma/nist/version"

if defined? Metanorma
  require_relative "metanorma/nist"
  Metanorma::Registry.instance.register(Metanorma::NIST::Processor)
end
