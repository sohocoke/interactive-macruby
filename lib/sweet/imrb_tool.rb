require 'rubygems'
require 'mrb-fsevent'
require 'mrb-fsevent/cli'
require 'fileutils'

module IRBLoader
  
  # set up repl context appropriately to needs in files in the project folder matching name '*.rb-repl', and load using this method.
  # a sample in one of my projects:
  # $dc = { 
  #   w: NSApp.windows[0], 
  #   ad: NSApp.delegate
  # }
  def load_rc # RENAME load_repl_state
    load_results = Dir.glob('**/*.rc.rb').each do |f|
      begin
        load_verbose f
      rescue Exception => e
        NSLog "while loading #{f}, got: #{e} #{caller}"        
      end
    end
    load_results
  end

  def load_global_rc
    load_verbose '~/.irbrc'
  end

  def load_verbose( f )
    puts "loading file #{f}..."
    load f
  end

  def load_all
    load_global_rc
    load_rc
  end

#=

  # reload source
  def load_src( src = nil )
    if src.to_s =~ /\.rb/
      load_rb src
    else
      # treat it as a resource
      relative_path = relative_path_given_src_dirs src
      copy_to_bundle relative_path if relative_path
    end
  end

  def load_rb( src )
    @irb_src_history ||= InteractiveHistory.load NSBundle.mainBundle.bundleIdentifier + ".hotloaded"

    if src
      if src.kind_of? Integer
        src = @irb_src_history.get(src)
      end
      
      @irb_src_history.add src

    else
      # print the guideline.
      puts "no args given. history: #{@irb_src_history.to_s}"
      
      return
    end

    # find the file in $project_src_dirs and load.
    raise "$project_src_dir undefined." if ! $project_src_dirs
    $project_src_dirs.each do |dir|
      file = File.join File.expand_path(dir), src.to_s
      file += ".rb" unless src.to_s =~ /\.rb$/
      if File.exists? file
        load file
        puts "loaded file #{file}"
        return
      end

      puts "couldn't load file #{file}"
    end
  end
  
  # sketch of an enhanced version that supports interactive mode:
  # > load_src
  # 3: file-x
  # 2: file-y
  # 1: file-z
  # select recent item or a new source file:
  # >> [choice or file] 
  # loaded.

  def copy_to_bundle( file )  # it's like it has a -p
    to_dir = NSBundle.mainBundle.resourcePath

    puts "copy #{file} to #{to_dir}" 
    FileUtils.cp file to_dir
  end


  # watch and reload changed source files
  def watch_src
    Dispatch::Queue.concurrent.async do
      raise "$project_src_dir undefined." if ! $project_src_dirs

      dirs = $project_src_dirs.map { |dir| dir.stringByExpandingTildeInPath }
      options = FSEvent::CLI.parse(dirs.dup << '--file-events')
      format = options[:format]

      notifier = FSEvent::Notifier.new
      options[:urls].each do |url|
        puts "watching #{url.path} with options #{options}"
        notifier.watch(url.path, *options[:create_flags], options) do |event_list|
          event_list.events.each do |event|
            puts "reload #{event.path}"
            self.load_src File.basename(event.path.to_s)

            if block_given?
              puts "yield to block"
              yield
            end
          end
        end
      end
      notifier.run
    end
  end
  
  alias_method :ls, :load_src

  # HACK
  def relative_path_given_src_dirs( path )
    $project_src_dirs.each do |src_dir|
      if path.include? src_dir
        return $`.gsub('^/', '') # string after match without preceding /
      end
    end

    puts "#{path} didn't match any path in $project_src_dirs" 
    nil
  end
end


#=

 # AP history checkpointing. OMG it's so hacky

module HistoryPersistence
  HISTORY_FILE = '/tmp/InteractiveMacRuby-history.rb'

  def recall_set(history = nil)
    history = last_history unless history

    text = history[0..-2].join "\n"
    File.open(HISTORY_FILE, 'w') { |f| f.write text }
    `open #{HISTORY_FILE}`
  end

  # doesn't evaluate yet - do that with eval_h after.
  def recall
    history_item_array = File.open(HISTORY_FILE).to_a
    last_controller.instance_variable_set(:@history, history_item_array)  # should be current controller FIXME

    # if i want to evaluate, i'd do it here.
    
    history_item_array.join "\n"
  end

  def eval_h
    last_history.each do |h_item|
      eval h_item
    end
  end


  def last_history
    last_controller.history
  end
  
  def last_controller
    controller = i(IRBViewController)
    controller.kind_of?(Array) ? controller.last : controller
  end

end


class InteractiveHistory
  
  def initialize(save_id = nil, data = nil)
    if data
      @items = data
    else
      @items = []
    end

    @save_id = save_id if save_id
  end

  def add(item)
    @items.uniq!
    @items << item.to_s
    
    self.save
  end

  def to_s
    descriptions = []
    @items.each_with_index { |item, i| descriptions << "#{i}: #{item.to_s}" }

    descriptions
  end

  def get(index = nil)
    begin
      unless index
        # solicit index
        input = gets
        index = input.to_i
      end

      return @items[index]
    rescue Exception => e
      puts "couldn't retrieve history item for index #{index}"
    end
  end
  
  def clear
    @items.clear!
    self.save
  end
      
  # a super naive version of saving in the appsupport folder.
  def save
    file_path = self.class.file_path(@save_id)
    File.open(file_path, 'w') { |file| 
      bytes = file.write @items.inspect
      if bytes > 0
        puts "saved to #{file_path}"
      else
        puts "save to #{file_path} failed"
      end
    }
  end

  def self.load( save_id )
    file_path = file_path(save_id)
    if File.exist?( file_path )
      data = File.open(file_path) {|file| file.read }
      data = eval(data)
      puts "open: #{data}"
    else
      data = nil
    end

    instance = self.new(save_id, data)
  end

  def self.file_path(save_id)
    app_support_dir + "/#{save_id}.txt"
  end

  def self.app_support_dir
    # STUB
    '/tmp'
  end

end


#=

class IRBTool
  include IRBLoader
  include HistoryPersistence
end



