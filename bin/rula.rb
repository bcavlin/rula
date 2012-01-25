#!/usr/bin/env ruby
# encoding: UTF-8
require 'curses'
require 'optparse'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

def parse_options
  options = {:mode=>:console, :width=>140, :page_length=>50, :wrap=>false, :log_level=>:debug}

  if RUBY_PLATFORM =~ /mswin|.*mingw32/i
    options[:line_separator] = "\n"
  else
    options[:line_separator] = "\r"
  end

  opts = OptionParser.new do |opts|
    opts.banner = %s{  [Ru]by [L]og [A]nalyzer

  Usage:
    rula <options> <filename(s)>

  Options:}

    opts.on("-v", "--version","Show version"){
      require 'rula/version'
      puts "Rula version #{Rula::VERSION} (c) 2011 bcavlin"
      exit
    }

    opts.on("-h", "--help","Show Rula help") {
      puts opts
      exit
    }

    opts.on("-m", "--mode [curses|console]",[:curses,:console],"Run application in <curses> or <console> mode") { |p|
      options[:mode] = p
    }

    opts.on("-r", "--wrap [true|false]",[:true,:false],"Wrap columns (Default is false)") { |p|
      options[:wrap] = p
    }

    opts.on("-w", "--width [width]","Terminal width (Default is 80). Will work only if wrap is set to true") { |p|
      options[:width] = p
    }
    
    opts.on("-l", "--loglevel [debug|info]",[:debug,:info],"Log level set to debug or info") { |p|
      options[:log_level] = p
    }

    opts.on("-n", "--nolog","Do not create logs") {
      options[:no_log] = true
    }

  end

  opts.parse!

  if ARGV.empty?
    puts opts
    exit
  end

  options
end

#before we start application
@options = parse_options

#start application here
require 'rula'

app = Rula::Application.new(ARGV, @options)

app.run()
