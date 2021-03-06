require "active_support/core_ext/class/attribute"

module Idcf
  module Ilb
    module Validators
      # Base validator class
      class Base
        class_attribute :valid_attributes

        class << self
          # Validate requeste attributes.
          # If there are invalid attributes, error occurs.
          #
          # @param attributes [Hash] request attributes
          # @param action [Symbol] request method
          def validate_attributes!(attributes, action = nil)
            validate_presence!(attributes, action)
            validate_absence!(attributes, action)
            validate_any!(attributes, action)
            attributes.each do |name, value|
              validate_attribute!(name, value)
            end
          end

          private

          def required_attributes(action)
            return [] unless action
            valid_attributes.select do |_, validator|
              validator[action] == :required
            end.keys
          end

          def any_attributes(action)
            return [] unless action
            valid_attributes.select do |_, validator|
              validator[action].to_s =~ /any_+/
            end.keys
          end

          def valid_attribute?(value, valid_type)
            case valid_type
            when Array
              valid_type.any? { |t| valid_attribute?(value, t) }
            when Regexp
              if value.is_a?(String)
                valid_type =~ value
              else
                false
              end
            else
              value.is_a?(valid_type)
            end
          end

          def validate_absence!(attributes, action)
            if action
              attributes.each do |name, value|
                next unless !valid_attributes[name] || !valid_attributes[name][action]
                raise(UnnecessaryAttribute, "`#{name}` is unnecessary in #{action} action")
              end
            end
          end

          def validate_attribute!(name, value)
            validate_attribute_name!(name)
            validate_attribute_type!(name, value)
          end

          def validate_attribute_name!(name)
            return true if valid_attributes.key?(name.to_sym)
            raise(InvalidAttributeName, "`#{name}` is invalid attribute name")
          end

          def validate_attribute_type!(name, value)
            valid_type = valid_attributes[name.to_sym][:type]
            return true if valid_attribute?(value, valid_type)
            raise(InvalidAttributeType, "`#{name}` is required to be a #{valid_type}")
          end

          def validate_presence!(attributes, action)
            required_attributes(action).each do |name|
              unless attributes.key?(name)
                raise(MissingAttribute, "`#{name}` is required in #{action} action")
              end
            end
          end

          def validate_any!(attributes, action)
            check_keys = any_attributes(action)
            if check_keys.empty?
            else
              unless attributes.values_at(*check_keys).flatten!.any?
                raise(
                  MissingAttribute,
                  "[`#{check_keys.join(', ')}`], any attribute required in #{action} action"
                )
              end
            end
          end
        end
      end
    end
  end
end
