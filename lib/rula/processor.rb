require_relative 'interface'
require_relative 'command'

module Rula
  class Processor # :nodoc
    attr_reader :commands, :interface
    
    def initialize(interface)
      @commands = nil
      @interface = interface
    end
  end

  class ConsoleCommandProcessor < Processor # :nodoc:
    def initialize(interface)
      super(interface)
      Rula.log(Logger::DEBUG,"Calling initialize",self)
    end

    def process_commands()
      Rula.log(Logger::DEBUG,"Calling process_commands",self)
      @commands = Command.commands.select      
      control_commands = @commands.map{|cmd| cmd.new(@interface, self) }

      while input = @interface.read_command('rula>') #Rula.colorize('cyan','rula>')
        if cmd = control_commands.find{|c| c.match(input.strip) }
          cmd.execute
        else
          Rula.log(Logger::WARN,"Unknown command #{input}",self)
        end
      end
    ensure
      @interface.close
    end    
  end
end