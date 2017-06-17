module ActionDispatch
  class Flash
    Flashes = %i[ alert info notice warn inverse ]

    module Flashier
      extend ActiveSupport::Concern

      included do
        Flashes.each do |flash|
          namespace = flash.to_s.pluralize.to_sym
          define_method flash do |message|
            send(namespace) << message
            message
          end
          alias_method "#{flash}=", flash
          define_method(namespace) { self[flash] ||= Array(self[flash]) }
        end
      end
    end

    class FlashHash
      include Flashier
    end

    class FlashNow
      include Flashier
    end
  end
end
