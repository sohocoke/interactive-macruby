require 'mrb-fsevent'
require 'mrb-fsevent/cli'

class IRBState

  # set up repl context appropriately to needs in files in the project folder matching name '*.rb-repl', and load using this method.
  # a sample in one of my projects:
  # $dc = { 
  # 	w: NSApp.windows[0], 
  # 	ad: NSApp.delegate
  # }
  def load_repl # RENAME load_repl_state
    load_results = Dir.glob('**/*.rb-repl').each do |f|
      load_verbose f
    end
    load_results
  end

  def load_rc
    load_verbose '~/.irbrc'
  end

  def load_verbose( f )
    puts "loading file #{f}..."
    load f
  end

  def load_all
    load_rc
    load_repl
  end

#=

  # AP history checkpointing. OMG it's so hacky

  HISTORY_FILE = '/tmp/InteractiveMacRuby-history.rb'

  def recall_set(history = nil)
    history = irb_history unless history

    text = history[0..-2].join "\n"
    File.open(HISTORY_FILE, 'w') { |f| f.write text }
    `open #{HISTORY_FILE}`
  end

  # doesn't evaluate yet - do that with eval_h after.
  def recall
    history_item_array = File.open(HISTORY_FILE).to_a
    irb_controller.instance_variable_set(:@history, history_item_array)

    # if i want to evaluate, i'd do it here.
    
    history_item_array.join "\n"
  end

  def eval_h
    irb_history.each do |h_item|
      eval h_item
    end
  end

  alias_method :ls, :load_src

  def irb_history
    history_item_array = irb_controller.history
  end

  def irb_controller
    controller = i(IRBViewController)
    controller.kind_of?(Array) ? controller.last : controller
  end

end

# global var for handy access
$irbs = IRBState.new


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

