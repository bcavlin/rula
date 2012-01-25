module Rula

  # Implements debugger "help" command.
  class HelpCommand < Command
    
    def regexp
      /^h(?:elp)? (?:\s+(.+))?$/x
    end

    def execute
      Rula.log(Logger::DEBUG,"Calling execute",self)
      if @match[1]
        args = @match[1].split
        cmds = @processor.commands.select do |cmd| 
          [cmd.help_command].flatten.include?(args[0])
        end
      else
        args = @match[1]
        cmds = []
      end
      unless cmds.empty?
        help = cmds.map{ |cmd| cmd.help(args) }.join
        help = help.split("\n").map{|l| l.gsub(/^ +/, '')}
        help.shift if help.first && help.first.empty?
        help.pop if help.last && help.last.empty?
        print help.join("\n")
      else
        if args and args[0]          
          Rula.log(Logger::WARN,"Undefined command: \"#{args[0]}\".  Try \"help\".",self)
        else
          print "Type 'help <command-name>' for help on a specific command\n\n"
          print "Available commands:\n"
          cmds = @processor.commands.map{ |cmd| cmd.help_command }
          cmds = cmds.flatten.uniq.sort
          print columnize(cmds, Rula.options[:width])
        end
      end
      print "\n"
    end

    class << self
      def help_command
        'help'
      end

      def help(cmd)
        %{
          h[elp]\t\tprint this help
          h[elp] command\tprint help on command
        }
      end
    end
  end
end
