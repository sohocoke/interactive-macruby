require 'sweet/imrb_tool'
# require 'defaults'

TOPLEVEL_OBJECT = self

class ApplicationDelegate
	#include DefaultsAccess
	
  def newTopLevelObjectSession(sender)
		#	watch_if default( :console_on_launch ) do

			# global var for handy access when interactive.
			$tool ||= IRBTool.new

			@@irb_global_inited ||= false
      unless @@irb_global_inited
      	
      	# load irb files.
        $tool.load_all
        @@irb_global_inited = true
      
      	# watch for hotloading.
      	$tool.watch_src

      end

	    irb(TOPLEVEL_OBJECT, TOPLEVEL_BINDING.dup)
	    
	  # end
  end

end
