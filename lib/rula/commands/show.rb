module Rula
  module ShowFunctions # :nodoc:
    def show_setting(setting_name)
      case setting_name
      when /^files$/
        result = ""
        count = 0
        Rula.application.files.each { |file|
          result += "id:[#{count}] file:[#{file.filename}] lines:[#{file.file_lines}] size:[#{file.file_size/1024} KB] active:[#{file==Rula.application.selected_file}]\n"
        }        
        return result
      when /^buffers$/
#        result = "Available buffers: "
#        selected = Rula.application.selected_file.selected_buffer
#        Rula.application.selected_file.available_buffers.each { |buffer|      
#          data = (buffer.id==selected)?('['+buffer.name+']'):buffer.name
#          result += data + ' '
#        }        
#        return result + ' for file ' + Rula.application.selected_file.filename
        p Rula.application.selected_file.get_buffers()
        return ''
      when /^buffer/
        result = /^buffer (\d)$/.match(setting_name)
        if result and result[1] then
          set = false
          total = 0
          buffer = Rula.application.selected_file.get_buffer(result[1].to_i)
          display_search_array = buffer.regex_array.to_s.gsub(/\n/,"\\n").gsub(/\r/,"\\r")                
          puts "Buffer data> last_displayed_line:#{buffer.last_displayed_line}, loaded_data_size:#{buffer.loaded_data_size}, regex_array:#{display_search_array}"
          buffer.buffer_hash.each { |key, value|
            total += value[Rula::CONST[:buffer]].length  
            puts ">Key #{key} has #{value[Rula::CONST[:buffer]].length} lines:" if !value[Rula::CONST[:buffer]].empty? 
            value[Rula::CONST[:buffer]].each{ |line,data|
              if line.to_i>=buffer.last_displayed_line and !set then
                set = true
                if buffer.last_displayed_line==line.to_i then
                  puts "#{Rula.colorize('red','POS>>')}\t#{line} #{data}"
                else
                  puts "#{Rula.colorize('red','POS>>')}\t#{buffer.last_displayed_line} POSITION"
                  puts "\t#{line} #{data}"
                end
              else
                puts "\t#{line} #{data}"
              end                            
            }
          }
        end               
        return "Total lines in buffers: #{total}"
      when /^version$/
        return "Rula version #{Rula::VERSION} (c) 2011 bcavlin"
      when /^width$/
        return "width is #{Rula.options[:width]}."
      else
        return "Unknown show subcommand #{setting_name}."
      end
    end
  end

  class ShowCommand < Command
    Subcommands =
    [
      ['files',  1, "Show loaded files with file details"],
      ['buffers', 1, "Show available buffers"],
      ['buffer [n]', 2, "Show content of buffer n"],  
      ['version', 1, "Show program version"],
      ['width', 1, "Show the number of characters that are in the line"],
    ].map do |name, min, short_help, long_help|
      SubcmdStruct.new(name, min, short_help, long_help)
    end unless defined?(Subcommands)

    def regexp
      /^show (?: \s+ (.+) )?$/xi
    end

    def execute
      if not @match[1]
        print "\"show\" must be followed by the name of an show command:\n"
        print "List of show subcommands:\n\n"
        for subcmd in Subcommands do
          print "show #{subcmd.name} -- #{subcmd.short_help}\n"
        end
      else
        args = @match[1].strip.split(/[ \t]+/)        
        subcmd = find(Subcommands, args[0])
        if subcmd
          puts show_setting(@match[1])
        else
          Rula.log(Logger::WARN,"Unknown show command #{subcmd}",self)
        end
      end
    end

    class << self
      def help_command
        "show"
      end

      def help(args)
        if args[1]
          s = args[1]
          subcmd = Subcommands.find do |try_subcmd|
            (s.size >= try_subcmd.min) and
            (try_subcmd.name[0..s.size-1] == s)
          end
          if subcmd
            str = subcmd.short_help + '.'
            str += "\n" + subcmd.long_help if subcmd.long_help
            return str
          else
            return "Invalid 'show' subcommand '#{args[1]}'."
          end
        end
        s = "
              Generic command for showing things about the debugger.

              --
              List of show subcommands:
              --
            "
        for subcmd in Subcommands do
          s += "show #{subcmd.name} -- #{subcmd.short_help}\n"
        end
        return s
      end
    end
  end
end