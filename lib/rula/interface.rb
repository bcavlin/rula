module Rula

  attr_reader :selected_file
  class Interface
  end

  class ConsoleInterface < Interface
    def initialize()
      super
      Rula.log(Logger::DEBUG,"Calling initialize",self)
    end

    def read_command(prompt)
      readline(prompt, true)
    end

    def confirm(prompt)
      readline(prompt, false)
    end

    def finalize
    end

    def close
    end    

    def display_buffer(action=InternalFile::CONST[:forward],set_line=-1,active_buffer=-1)
      @selected_file = Rula.application.selected_file
      @selected_file.set_active_buffer(active_buffer) if active_buffer > -1

      count = 0
      start = 0
      buffer = []
        
      if action==InternalFile::CONST[:forward] then
        count = Rula.options[:page_length]
        start = @selected_file.get_active_buffer().last_displayed_line+1  
      elsif action==InternalFile::CONST[:skip] and !set_line.nil?   
        count = Rula.options[:page_length]
        start = set_line  
      else
        count = -(Rula.options[:page_length]*2)  
        start = @selected_file.get_active_buffer().last_displayed_line+1  
      end
           
      start = Rula.application.selected_file.file_lines if start > Rula.application.selected_file.file_lines and action==InternalFile::CONST[:backward]
      start = 1 if start < 0           
      buffer = @selected_file.get_buffer_data(action,start,count)
      
      if buffer[0].kind_of?(Array) then
        counter = 0
        displayed = 0
        Rula.log(Logger::DEBUG,"Loooking for start #{start} and count #{count}",self)
        adjusted_start = nil
        
        adjusted_start = buffer.index {|x| x[0].to_i>=start}
        Rula.log(Logger::DEBUG,"Adjusted start is #{adjusted_start}",self)
        adjusted_start = buffer.length if adjusted_start.nil? and action==InternalFile::CONST[:backward]
        Rula.log(Logger::DEBUG,"Adjusted start is #{adjusted_start}",self)   
        adjusted_start += count if count<0
        Rula.log(Logger::DEBUG,"Adjusted start is #{adjusted_start}",self)
        adjusted_start = 0 if !adjusted_start.nil? and adjusted_start<0
        Rula.log(Logger::DEBUG,"Adjusted start is #{adjusted_start}",self)
          
        if !adjusted_start.nil? then
          (adjusted_start...adjusted_start+Rula.options[:page_length]).each { |i|            
            break if buffer[i].nil? 
            current_line = buffer[i][0]          
            data = buffer[i][1]
            counter = current_line
            printf("\e[1;32m%#{@selected_file.file_lines.to_s.length}d\e[1;33m %s\n", current_line, wrap(data[0],Rula.options[:width],@selected_file.file_lines.to_s.length))
            displayed += 1
          } 

          Rula.log(Logger::DEBUG,"Displayed #{displayed} lines",self) unless buffer[1].nil?
          
          counter = Rula.application.selected_file.file_lines if counter > Rula.application.selected_file.file_lines
          counter = 0 if counter < 0
          
          @selected_file.get_active_buffer().last_displayed_line = counter
        end
      else
        Rula.log(Logger::DEBUG,"Last message is #{buffer[1]}",self) unless buffer[1].nil?
      end
    end

    private

    def wrap(txt, col, indent=0)
      return txt if !Rula.options[:wrap]
      line = 0
      addition = ' '*(indent+1)
      result = []
      txt.gsub(/(.{1,#{col}})( +|$)\n?|(.{#{col}})/,"\\1\\3\n").split(Rula.options[:line_separator]).each { |str|
        result.push(str) if line == 0
        result.push(addition+str) if line > 0
        line += 1
      }
      result.join(Rula.options[:line_separator])
    end

    begin
      def readline(prompt, hist)
        Readline::readline(prompt, hist)
      end
    rescue LoadError
      def readline(prompt, hist)
        STDOUT.print prompt
        STDOUT.flush
        line = STDIN.gets
        exit unless line
        line.chomp!
        line
      end
    end
  end

  class CursesInterface < Interface
    #TODO create interface
  end
end