module Rula
  class Application

    attr_reader :selected_file, :files
    def initialize(args, options)   
      Rula.application = self
      Rula.options = OptionAccessor.new(options)
      Rula.setup() #this will setup logging
      Rula.log(Logger::DEBUG,"Executing initialize",self)
      Command.load_commands()
      load_files(args)
      @selected_file = @files.first
      @interface = Rula::ConsoleInterface.new
      @command_processor = Rula::ConsoleCommandProcessor.new(@interface)
    end

    def run()
      if @selected_file then
        @selected_file.count_lines()
        @command_processor.process_commands()
      else
        Rula.log(Logger::ERROR,"No files for processing have been found!",self)
      end
    end

    private

    def load_files(args)
      Rula.log(Logger::DEBUG,"Loading arguments #{args}",self)
      @files = Array.new
      args.each { |arg|
        Rula.log(Logger::DEBUG,"Verifying file #{arg}",self)
        if File.exist?(arg) then
          @files.push(Rula::InternalFile.new(arg))
          Rula.log(Logger::DEBUG,"File #{arg} verified",self)
        end
      } unless args == nil
    end
  end
end