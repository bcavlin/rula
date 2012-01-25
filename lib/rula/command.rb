module Rula
  RUCO_DIR = File.expand_path(File.dirname(__FILE__)) unless defined?(RUCO_DIR)
  class Command
    SubcmdStruct=Struct.new(:name, :min, :short_help, :long_help) unless defined?(SubcmdStruct)
    
    include Columnize
    
    def find(subcmds, param)
      Rula.log(Logger::DEBUG,"Looking up command with params #{param}",self)
      param.downcase!
      for try_subcmd in subcmds do        
        if (param.size >= try_subcmd.min) and (try_subcmd.name =~ /^#{param}/)
          Rula.log(Logger::DEBUG,"Found #{try_subcmd.name}",self)       
          return try_subcmd
        end
      end
      Rula.log(Logger::DEBUG,"Found nil",self)
      return nil
    end
    
    attr_accessor :interface, :processor
    
    def initialize(interface, command_processor)
      @interface = interface
      @processor = command_processor
    end

    def match(input)
      @match = regexp.match(input)
    end

    def confirm(msg)
      @interface.confirm(msg) == 'y'
    end

    class << self
      def commands
        @commands ||= []
      end

      def inherited(klass)
        Rula.log(Logger::DEBUG,"Adding command #{klass}",self)
        commands << klass
      end

      def load_commands
        Rula.log(Logger::DEBUG,"Loading commands",self)
        Dir[File.join(Rula.const_get(:RUCO_DIR), 'commands', '*')].each do |file|
          require file if file =~ /\.rb$/
        end
        Rula.constants.grep(/Functions$/).map { |name| Rula.const_get(name) }.each do |mod|
          include mod
        end
      end

    end
  end
end