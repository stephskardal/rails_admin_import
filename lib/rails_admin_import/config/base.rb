module RailsAdminImport
  module Config
    class Base
      def initialize(parent_name = nil)
      end

      # Register an instance option for this object only
      def register_instance_option(option_name, &default)
        scope = class << self; self; end;
        self.class.register_instance_option(option_name, scope, &default)
      end

      # Register an instance option. Instance option is a configuration
      # option that stores its value within an instance variable and is
      # accessed by an instance method. Both go by the name of the option.
      def self.register_instance_option(option_name, scope = self, &default)
        unless options = scope.instance_variable_get("@config_options")
          options = scope.instance_variable_set("@config_options", {})
        end

        option_name = option_name.to_s

        options[option_name] = nil

        # If it's a boolean create an alias for it and remove question mark
        if "?" == option_name[-1, 1]
          scope.send(:define_method, "#{option_name.chop!}?") do
            send(option_name)
          end
        end

        # Define getter/setter by the option name
        scope.send(:define_method, option_name) do |*args, &block|
          if !args[0].nil? || block
            # Invocation with args --> This is the declaration of the option, i.e. setter
            instance_variable_set("@#{option_name}_registered", args[0].nil? ? block : args[0])
          else
            # Invocation without args nor block --> It's the use of the option, i.e. getter
            value = instance_variable_get("@#{option_name}_registered")
            case value
              when Proc
                # Track recursive invocation with an instance variable. This prevents run-away recursion
                # and allows configurations such as
                # label { "#{label}".upcase }
                # This will use the default definition when called recursively.
                if instance_variable_get("@#{option_name}_recurring")
                  value = instance_eval &default
                else
                  instance_variable_set("@#{option_name}_recurring", true)
                  value = instance_eval &value
                  instance_variable_set("@#{option_name}_recurring", false)
                end
              when nil
                value = instance_eval &default
            end
            value
          end
        end
      end
    end
  end
end
