require "version"

module RSpec
  module Core
    module Set
      module ClassMethods
        # Set @variable_name in a before(:all) block and give access to it
        # via let(:variable_name)
        #
        # Example:
        #
        #   set(:transaction) { Factory(:address) }
        #
        #   it "should be valid" do
        #     transaction.should be_valid
        #   end
        #
        def set(variable_name, &block)
          before(:all) do
            # Create model
            model = instance_eval(&block)

            # Save the original attributes for a non-saved model
            if model.respond_to?(:new_record?) && model.new_record?
              self.class.send(:class_variable_set, "@@__rspec_set_#{variable_name}_attributes".to_sym, model.attributes)
            end

            self.class.send(:class_variable_set, "@@__rspec_set_#{variable_name}".to_sym, model)
          end

          before(:each) do
            model = send(variable_name)

            if model.is_a?(ActiveRecord::Base)
              if model.destroyed?
                # Reset destroyed model
                self.class.send(:class_variable_set, "@@__rspec_set_#{variable_name}".to_sym, model.class.find(model.id))
              elsif model.new_record?
                # Restore the changes on a non-saved model
                model.attributes = self.class.send(:class_variable_get, "@@__rspec_set_#{variable_name}_attributes".to_sym)
              else
                # Reload saved model
                model.reload
              end
            else
              warn "#{variable_name} is a #{model.class} - rspec-set works with ActiveRecord models only"
            end
          end

          define_method(variable_name) do
            self.class.send(:class_variable_get, "@@__rspec_set_#{variable_name}".to_sym)
          end
        end # set()

      end # ClassMethods

      def self.included(mod) # :nodoc:
        mod.extend ClassMethods
      end
    end # Set

    class ExampleGroup
      include Set
    end # ExampleGroup

  end # Core
end # RSpec
