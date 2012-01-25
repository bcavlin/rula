module Rula
  class ListCommand < Command
    def regexp
      /^l(?:ist)? (?:\s*(-))? (?:\s*(\d+))? (?:\s*b(\d))?$/x
    end
    
    def execute 
      action = InternalFile::CONST[:forward]      
      action = InternalFile::CONST[:backward] if @match[1]
      line = @match[2].to_i if @match[2]
      action = InternalFile::CONST[:skip] if line        
      buffer = -1
      buffer = @match[3].to_i if @match[3]  
            
      @interface.display_buffer(action,line,buffer)      
    end

    class << self
      def help_command
        'list'
      end

      def help(cmd)
        %{    l[ist] -- list forward 1 page
              l[ist] - -- list backward 1 page
              l[ist] <number> -- skip tp <number and display lines>
              l[ist] b<buffer> -- list buffer <buffer> and make default < can be combined with other options
          }
      end
    end
  end
end