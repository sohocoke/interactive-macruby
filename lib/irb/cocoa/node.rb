module IRB
  module Cocoa
    DEFAULT_ATTRIBUTES = { NSFontAttributeName => NSFont.fontWithName("Menlo Regular", size: 11) }

    module Helper
      def attributedString(string)
        NSAttributedString.alloc.initWithString(string, attributes: DEFAULT_ATTRIBUTES)
      end
      module_function :attributedString
    end

    class BasicNode
      include Helper

      EMPTY_STRING = Helper.attributedString("")
      EMPTY_ARRAY = []

      attr_reader :value

      def initWithvalue(value)
        if init
          @value = value.is_a?(NSAttributedString) ? value : attributedString(value)
          self
        end
      end

      def initWithPrefix(prefix, value: value)
        if initWithvalue(value)
          @prefix = prefix.is_a?(NSAttributedString) ? prefix : attributedString(prefix)
          self
        end
      end

      def prefix
        @prefix || EMPTY_STRING
      end

      def expandable?
        false
      end

      def children
        EMPTY_ARRAY
      end

      def ==(other)
        other.class == self.class && other.prefix == prefix && other.value == value
      end

      def to_s
        value.string
      end

      def toElement(document)
        row    = document.createElement("tr")
        prefix = document.createElement("td")
        value  = document.createElement("td")
        prefix.send("setAttribute::", "class", "prefix")
        value.send("setAttribute::", "class", "value")
        if expandable?
          image = document.createElement("img")
          image.send("setAttribute::", "src", "images/disclosureTriangleSmallRight.png")
          prefix.appendChild(image)
        else
          prefix.innerText = self.prefix.string
        end
        value.innerText = self.value.string
        row.appendChild(prefix)
        row.appendChild(value)
        row
      end

      def dataCellTypeForColumn(column)
        NSTextFieldCell
      end

      def rowHeight
        #16
      end
    end

    class ExpandableNode < BasicNode
      attr_reader :object

      def initWithObject(object, value: value)
        if initWithvalue(value)
          @object = object
          self
        end
      end

      def expandable?
        true
      end

      def ==(other)
        super && other.object == object
      end
    end

    class ListNode < ExpandableNode
      def children
        @children ||= @object.map { |s| BasicNode.alloc.initWithvalue(s) }
      end
    end

    class BlockListNode < ExpandableNode
      def initWithBlockAndvalue(value, &block)
        if initWithvalue(value)
          @block = block
          self
        end
      end

      def children
        @children ||= @block.call
      end
    end

    # Object wrapper nodes

    class ObjectNode < ExpandableNode
      class << self
        def nodeForObject(object)
          klass = case object
          when Module then ModNode
          when NSImage then NSImageNode
          else
            ObjectNode
          end
          klass.alloc.initWithObject(object)
        end

        attr_accessor :children
      end

      self.children = [
        :descriptionNode,
        :classNode,
        :publicMethodsNode,
        :objcMethodsNode,
        :instanceVariablesNode
      ]

      def initWithObject(object)
        if init
          @object = object
          @showDescriptionNode = false
          self
        end
      end

      def initWithObject(object, value: value)
        if super
          @showDescriptionNode = true
          self
        end
      end

      def value
        @value ||= objectDescription
      end

      def objectDescription
        IRB.formatter.result(@object)
      end

      def children
        @children ||= self.class.children.map { |m| send(m) }.compact
      end

      def descriptionNode
        if @showDescriptionNode
          ListNode.alloc.initWithObject([objectDescription], value: "Description")
        end
      end

      def classNode
        ModNode.alloc.initWithObject(@object.class,
                        value: "Class: #{@object.class.name}")
      end

      def publicMethodsNode
        methods = @object.methods(false)
        unless methods.empty?
          ListNode.alloc.initWithObject(methods, value: "Public methods")
        end
      end

      def objcMethodsNode
        methods = @object.methods(false, true) - @object.methods(false)
        unless methods.empty?
          ListNode.alloc.initWithObject(methods, value: "Objective-C methods")
        end
      end

      def instanceVariablesNode
        variables = @object.instance_variables
        unless variables.empty?
          BlockListNode.alloc.initWithBlockAndvalue("Instance variables") do
            variables.map do |name|
              obj = @object.instance_variable_get(name)
              ObjectNode.alloc.initWithObject(obj, value: name)
            end
          end
        end
      end
    end

    class ModNode < ObjectNode
      self.children = [
        :modTypeNode,
        :ancestorNode,
        :publicMethodsNode,
        :objcMethodsNode,
        :instanceVariablesNode
      ]

      def modTypeNode
        BasicNode.alloc.initWithvalue("Type: #{@object.class == Class ? 'Class' : 'Module'}")
      end

      def ancestorNode
        BlockListNode.alloc.initWithBlockAndvalue("Ancestors") do
          @object.ancestors[1..-1].map do |mod|
            ModNode.alloc.initWithObject(mod, value: mod.name)
          end
        end
      end
    end

    class NSImageNode < ObjectNode
      self.children = [:classNode, :publicMethodsNode, :objcMethodsNode, :instanceVariablesNode]

      def value
        @object
      end

      def dataCellTypeForColumn(column)
        column == "value" ? NSImageCell : NSTextFieldCell
      end

      def rowHeight
        @rowHeight ||= begin
          height = @object.size.height.floor
          height > 100 ? 100 : height
        end
      end
    end
  end
end
