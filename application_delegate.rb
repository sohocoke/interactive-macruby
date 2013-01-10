require 'sweet/imrb_tool'
# require 'defaults'

TOPLEVEL_OBJECT = self

class ApplicationDelegate
	#include DefaultsAccess
	
	# TODO if app not customised yet, create a new session on app load.
	
  def newTopLevelObjectSession(sender)
  	# TODO refactor into a more variation-friendly place, like IRBWindowController.rc

		# global var for handy access when interactive.
		$tool ||= IRBTool.new

		@@irb_global_inited ||= false
    unless @@irb_global_inited
    	
    	# load irb files.
      $tool.load_all
      @@irb_global_inited = true
    
    	# watch for hotloading.
			begin
				$tool.watch_src
			rescue Exception => e
				qb_report e
				puts "not watching folder due to last exception."
			end

    end

    irb(TOPLEVEL_OBJECT, TOPLEVEL_BINDING.dup)
  end

end
