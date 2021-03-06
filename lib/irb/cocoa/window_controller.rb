class IRBWindowController < NSWindowController

  def self.windowWithObjectAndBinding(args)
    object, binding = args
    instance = alloc.initWithObject(object, binding: binding)
    instance.showWindow(self)
    instance.rc if instance_methods.include? :rc
  end

  def initWithObject(object, binding: binding)
    # if keyWindow = NSApp.keyWindow
    #   # This has got to be easier
    #   keyWindowFrame  = keyWindow.frame
    #   point           = NSMakePoint(NSMinX(keyWindowFrame), NSMaxY(keyWindowFrame))
    #   point           = keyWindow.cascadeTopLeftFromPoint(point)
    #   point.y        -= NSHeight(keyWindowFrame)
    #   frame           = keyWindow.contentRectForFrameRect(keyWindowFrame)
    #   frame.origin.x  = point.x
    #   frame.origin.y  = point.y
    # else
      frame = NSMakeRect(0, 3000, 600, 400)
    # end

    window = NSWindow.alloc.initWithContentRect(frame,
                                     styleMask: NSResizableWindowMask | NSClosableWindowMask | NSTitledWindowMask,
                                       backing: NSBackingStoreBuffered,
                                         defer: false)

    if initWithWindow(window)
      @viewController = IRBViewController.alloc.initWithObject(object, binding: binding, delegate: self)
      window.contentView = @viewController.view
      receivedResult(@viewController)
      
      self
    end
  end

  def receivedResult(viewController)
    window.title = viewController.context.object.to_s[0..50]
  end

  # TODO properly set the view controller as first responder so we don't need to delegate any longer

  def clearConsole(sender)
    @viewController.clearConsole(sender)
  end

  def cancelOperation(sender)
    @viewController.toggleFullScreenMode(sender)
  end

  def toggleFullScreenMode(sender)
    @viewController.toggleFullScreenMode(sender)
  end

  def irbViewControllerTerminated(viewController)
    window.close
  end
end
