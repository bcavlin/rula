module Rula
  class SearchCommand < Command
    def regexp
      /^s(?:earch)? (?:\s*\/(.*)\/) (?:\s*b(\d))?$/ix
    end

    def execute
      if @match[2] then
        buffer = @match[2].to_i
        buffer = (@match[2].to_i<1 or @match[2].to_i>5) ? 1 : buffer
        Rula.application.selected_file.set_active_buffer(buffer)
      else
        Rula.application.selected_file.set_active_buffer(1)
      end
      data_found = Rula.application.selected_file.search_data(@match[1])
    end

    class << self
      def help_command
        'search'
      end

      def help(cmd)
        %{ s[earch] </search data regex/> -- Search file using regex }
      end
    end
  end
end