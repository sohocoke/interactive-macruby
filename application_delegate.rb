require 'sweet/imrb_tool'
# require 'defaults'

TOPLEVEL_OBJECT = self

class ApplicationDelegate
	#include DefaultsAccess
	
  def newTopLevelObjectSession(sender)
		#	watch_if default( :console_on_launch ) do

			# global var for handy access when interactive.
			$tool ||= IRBTool.new

      # load irb files.
			@@irb_loaded_all ||= false
      unless @@irb_loaded_all
        $tool.load_all
        @@irb_loaded_all = true
      end

	    irb(TOPLEVEL_OBJECT, TOPLEVEL_BINDING.dup)
	    
	  # end
  end

end
