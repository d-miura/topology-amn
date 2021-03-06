require 'gli'
require 'pio'
require 'view/text'

# command-line options passed to topology-controller.rb
class CommandLine
  include GLI::App

  attr_reader :view
  attr_reader :destination_mac

  def initialize(logger)
    @logger = logger
  end

  def parse(args)
    program_desc 'Topology discovery controller'
    set_destination_mac_flag
    define_text_command
    define_graphviz_command
    define_visjs_command
    run args
  end

  private

  def set_destination_mac_flag
    flag [:d, :destination_mac]
    pre do |global_options, _command, _options, _args|
      destination_mac = global_options[:destination_mac]
      @destination_mac = Pio::Mac.new(destination_mac) if destination_mac
      true
    end
  end

  def define_text_command
    default_command :text
    desc 'Displays topology information (text mode)'
    command :text do |cmd|
      cmd.action(&method(:create_text_view))
    end
  end

  def define_graphviz_command
    desc 'Displays topology information (Graphviz mode)'
    arg_name 'output_file'
    command :graphviz do |cmd|
      cmd.action(&method(:create_graphviz_view))
    end
  end

  def define_visjs_command
    desc 'Displays topology information (visjs mode)'
    arg_name 'output_file'
    command :visjs do |cmd|
      cmd.action(&method(:create_visjs_view))
    end
  end

  private

  def create_text_view(_global_options, _options, _args)
    @view = View::Text.new(@logger)
  end

  def create_graphviz_view(_global_options, _options, args)
    require 'view/graphviz'
    if args.empty?
      @view = View::Graphviz.new
    else
      @view = View::Graphviz.new(args[0])
    end
  end

  def create_visjs_view(_global_options, _options, args)
    require 'view/vis'
    if args.empty?
      @view = View::Vis.new
    else
      @view = View::Vis.new(args[0])
    end
  end
end
