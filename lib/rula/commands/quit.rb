module Rula

  # Implements debugger "quit" command
  class QuitCommand < Command
    
    def regexp
      /^(?:q(?:uit)?|exit)\s*(!|\s+unconditionally)?\s*$/ix
    end

    def execute
      Rula.log(Logger::DEBUG,"Calling execute",self)
      if @match[1] or confirm("Really quit? (y/n) ") 
        @interface.finalize
        exit! 
      end
    end

    class << self
      def help_command
        %w[quit exit]
      end

      def help(cmd)
        %{
          q[uit] \texit from Rula. 
          exit[!]\talias to quit

          Normally we prompt before exiting. However if the parameter
          "unconditionally" or is given or suffixed with !, we stop
          without asking further questions.  
         }
     end
    end
  end
end
