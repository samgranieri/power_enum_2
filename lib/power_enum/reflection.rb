# Copyright (c) 2011 Artem Kuzko
# Copyright (c) 2013 Zach Belzer
# Copyright (c) 2013 Arthur Shagall
# Released under the MIT license.  See LICENSE for details.

# Used to patch ActiveRecord reflections.
module PowerEnum::Reflection
  extend ActiveSupport::Concern

  module ClassMethods
    def self.extended(base)
      class << base
        alias_method_chain :reflect_on_all_associations, :enumeration
        alias_method_chain :reflect_on_association, :enumeration
      end
    end

    def reflect_on_all_enumerated
      # Need to give it a full namespace to avoid getting Rails confused in development
      # mode where all objects are reloaded on every request.
      reflections.values.grep(PowerEnum::Reflection::EnumerationReflection)
    end

    def reflect_on_enumerated( enumerated )
      reflections[enumerated.to_sym].is_a?(PowerEnum::Reflection::EnumerationReflection) ? reflections[enumerated.to_sym] : nil
    end

    # Extend associations with enumerations, preferring enumerations
    def reflect_on_all_associations_with_enumeration(macro = nil)
      reflect_on_all_enumerated + reflect_on_all_associations_without_enumeration(macro)
    end

    # Extend associations with enumerations, preferring enumerations
    def reflect_on_association_with_enumeration( associated )
      reflect_on_enumerated(associated) || reflect_on_association_without_enumeration(associated)
    end
  end

  # Reflection class for enum reflections.  See ActiveRecord::Reflection
  class EnumerationReflection < ActiveRecord::Reflection::MacroReflection
    attr_reader :counter_cache_column

    def initialize( name, options, active_record )
      super :has_enumerated, name, options, active_record
    end
    
    def class_name
      @class_name ||= (@options[:class_name] || @name).to_s.camelize
    end
    
    def foreign_key
      @foreign_key ||= (@options[:foreign_key] || "#{@name}_id").to_s
    end
  end
end
