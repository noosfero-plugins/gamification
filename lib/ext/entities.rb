module Noosfero
  module API
    module Entities
#FIXME See the correct way to include timestamp
#      def self.included(base)
#        base.extend(ClassMethods)
#      end
#
#      module ClassMethods

        class Badge < Entity
          root 'badges', 'badge'
          expose :name, :description, :title, :description, :level
#          expose :created_at, :format_with => :timestamp
        end

#      end
#
    end
  end

end
