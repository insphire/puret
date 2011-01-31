module Puret
  module ActiveRecordExtensions
    module ClassMethods
      # Configure translation model dependency.
      # Eg:
      #   class PostTranslation < ActiveRecord::Base
      #     puret_for :post
      #   end
      def puret_for(model)
        belongs_to model
        validates_presence_of model, :locale
        validates_uniqueness_of :locale, :scope => "#{model}_id"
      end

      # Configure translated attributes.
      # Eg:
      #   class Post < ActiveRecord::Base
      #     puret :title, :description
      #   end
      def puret(*attributes)
        make_it_puret! unless included_modules.include?(InstanceMethods)

        attributes.each do |attribute|
          
          #
          # translated attribute setter eg. translated_title
          #
          define_method "translated_#{attribute}=" do |value|
            # find a translation for the current locale
            translation = translations.detect { |t| t.locale.to_sym == I18n.locale }
            if translation.nil?
              # create a new translation for the current locale
              # setting association with parent to cater for child validating presence association 
              translations.build(self.class.name.underscore.downcase.to_sym => self, :locale => I18n.locale, attribute.to_sym => value)
            else
              # set the value of the existing translation
              translation[attribute] = value
            end
          end

          #
          # translated attribute getter eg. translated_title
          #
          define_method "translated_#{attribute}" do
            # Return of translated text is dependent upon enabled option
            # When translations enabled then following lookup chain is used:
            # (1) translation for the current locale
            # (2) standard text (as long as method exists)
            # (3) translation for the default locale
            # (4) first translation
            if puret_translations_enabled?
              translation = translations.detect { |t| t.locale.to_sym == I18n.locale }
              return translation[attribute] unless translation.nil?
              
              return self[attribute] if respond_to?(attribute)
            
              translation = translations.detect { |t| t.locale.to_sym == puret_default_locale }
              return translation[attribute] unless translation.nil?
            
              translation = translations.first
              return translation[attribute] unless translation.nil?
            else
              return self[attribute] if respond_to?(attribute)
            end  

            # fall-back
            return nil
            
          end
        end
      end

      private

      # configure model
      def make_it_puret!
        include InstanceMethods

        has_many :translations, :class_name => "#{self.to_s}Translation", :dependent => :destroy, :order => "created_at DESC"
        accepts_nested_attributes_for :translations, :allow_destroy => true
      end
      
    end

    module InstanceMethods
      
      def puret_default_locale
        return default_locale.to_sym if respond_to?(:default_locale)
        return self.class.default_locale.to_sym if self.class.respond_to?(:default_locale)
        I18n.default_locale
      end
      
      def puret_translations_enabled?
        return translations_enabled? if respond_to?(:translations_enabled?)
        return self.class.translations_enabled? if self.class.respond_to?(:translations_enabled?)
        return true
      end
      
    end
  end
end

ActiveRecord::Base.extend Puret::ActiveRecordExtensions::ClassMethods
