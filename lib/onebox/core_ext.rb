# frozen_string_literal: true

# Minimal ActiveSupport-compatible extensions used throughout onebox.
# These are only defined if ActiveSupport is not already loaded.

unless Object.method_defined?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def present?
      !blank?
    end

    def presence
      self if present?
    end
  end

  class NilClass
    def blank?
      true
    end
  end

  class FalseClass
    def blank?
      true
    end
  end

  class TrueClass
    def blank?
      false
    end
  end

  class String
    def blank?
      empty? || !(/[[:^space:]]/ === self)
    end
  end

  class Numeric
    def blank?
      false
    end
  end

  class Array
    def blank?
      empty?
    end
  end

  class Hash
    def blank?
      empty?
    end
  end
end

unless Array.method_defined?(:exclude?)
  class Array
    def exclude?(object)
      !include?(object)
    end
  end
end

unless Hash.method_defined?(:deep_symbolize_keys)
  class Hash
    def deep_symbolize_keys
      each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? value.deep_symbolize_keys : value
        result[new_key] = new_value
      end
    end
  end
end
