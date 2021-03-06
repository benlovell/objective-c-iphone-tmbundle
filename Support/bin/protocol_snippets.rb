$KCODE = 'u'

class ProtocolSnippetNotSupported < Exception; end

require "yaml"
require "ui"

class ProtocolSnippet
  attr_reader :protocol_class
  
  def initialize(protocol_class)
    @protocol_class = protocol_class.strip
    raise ProtocolSnippetNotSupported, protocol_class unless supported?
  end
  
  def supported?
    protocol_definition
  end
  
  def to_s
    header +
    render_required_methods + "\n" +
    render_optional_methods + "\n"
  end
  
  def header
    <<-OBJC
#pragma mark -
#pragma mark - #{@protocol_class} methods

    OBJC
  end
  
  def render_required_methods
    protocol_definition[:required].inject([]) do |mem, method_and_description|
      method      = method_and_description[:name]
      description = method_and_description[:description]
      mem << <<-OBJC
// #{description}
#{method}
{
  #{"$0" if mem.size == 0}
}
      OBJC
      mem
    end.join("\n")
  end
  
  def render_optional_methods
    protocol_definition[:optional].inject([]) do |mem, method_and_description|
      method      = method_and_description[:name]
      description = method_and_description[:description]
      mem << <<-OBJC
// #{description}
// #{method}
// {
//   
// }
      OBJC
      mem
    end.join("\n")
  end

  def protocol_definition
    @protocol_definition ||= begin
      self.class.protocol_definitions[protocol_class]
    end
  end
  
  def self.protocol_definitions
    @protocol_definitions ||= begin
      YAML.load(open(File.dirname(__FILE__) + "/../protocols.yml", "r"))
    end
  end
end

if __FILE__ == $0
  require ENV['TM_SUPPORT_PATH'] + "/lib/exit_codes"
  protocols = ProtocolSnippet.protocol_definitions.sort { |a, b| a.first <=> b.first }
  TextMate.exit_discard unless protocol_class = TextMate::UI.menu(protocols.map { |item| {"title" => item.first} })
  protocol_class = protocol_class["title"]
  puts ProtocolSnippet.new(protocol_class).to_s
end
