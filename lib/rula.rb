require 'rubygems'
require 'logger'
require 'win32console'
require 'columnize'
require 'readline'
require 'rula/core_ext/object'
require 'rula/option_accessor'
require 'rula/application'
require 'rula/version'
require 'rula/interface'
require 'rula/command'
require 'rula/processor'
require 'rula/internal_file_buffer'
require 'rula/internal_file'

include Win32::Console::ANSI

module Rula

  @@DEFALUT_COLOR = "\e[1;33m" #"\e[0m" means reset

  CONST = {
    :prev_hash_id=>0,
    :next_hash_id=>1,
    :last_line=>2,
    :buffer=>3,
    :buffer_has_data=>4,
    :buffer_buffer_line_number=>0,
    :buffer_buffer_code_line_number=>0,
    :buffer_data=>1
  }.freeze

  class << self

    attr_accessor :application, :options

    def setup()
      if @options[:mode]==:console then
        @logger = Logger.new(STDOUT)
        @logger = Logger.new(STDERR)
      else #:curses
        @logger = Logger.new('rula_log.log')
      end

      if @options[:log_level]==:debug then
        @logger.level = Logger::DEBUG
      else
        @logger.level = Logger::INFO
      end
    end

    def log(level, message, klass=self)
      if @options[:no_log] then
        return
      end

      class_name = klass
      class_name = klass.class.to_s+' ' if klass!=nil
      case level
      when Logger::DEBUG then @logger.debug(class_name) {message} if @logger.debug?
      when Logger::INFO then @logger.info(class_name) {message} if @logger.info?
      when Logger::WARN then @logger.warn(class_name) {message} if @logger.warn?
      when Logger::ERROR then @logger.error(class_name) {message} if @logger.warn?
      when Logger::FATAL then @logger.fatal(class_name) {message} if @logger.fatal?
      else @logger.unknown(class_name) {message}
      end
    end

    def colorize(color,text)
      case color
      when 'red' then "\e[1;31m"+text+@@DEFALUT_COLOR
      when 'green' then "\e[1;32m"+text+@@DEFALUT_COLOR
      when 'blue' then "\e[1;34m"+text+@@DEFALUT_COLOR
      when 'yellow' then "\e[1;33m"+text+@@DEFALUT_COLOR
      when 'cyan' then "\e[1;36m"+text+@@DEFALUT_COLOR
      else text
      end
    end
  end

  def self.configure(&block)
    application.instance_exec(&block)
  end

end
