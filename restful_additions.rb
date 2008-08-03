module RestfulAdditions
  # Gem will add all ModelBase methods to the Base of the database agent
  module ModelBase
    def self.extended(modelBase)
      modelBase.class_eval do
        def self.inherited(model)
          model.class_eval do
            @restful_keys = []
            @restful_associations = []
          end
        end
      end
    end
    
    def restful_key(key)
      # I'm too nice to you guys => the error checking
      @restful_keys.push key unless @restful_keys.include? key
    end

    # * Restful_find uses the paramaters from params that will influence the models that should be found
    # * For instance if a post belongs_to a topic then visiting http://blog.com/topic/1/posts would yeild
    # params to contain topic_id => 1 which can then be used to find all the posts for that topic
    def restful_find(mode, params = { },conditions = { })
      for association in @restful_associations
        conditions.merge!(association.in(params)) if(association.is_in?(params))
      end
      self.restful_find_by_keys(mode,params,conditions)
    end
    
    def add_restful_association(macro,name,options,klass)
      case(macro)
      when :blongs_to:
          raise "BALLS"
          @restful_associations.push(Association.new(name,options[:class_name] || klass))
      end

    end
    
    protected
    def restful_find_by_keys(mode,params,conditions)
      @restful_keys.each do |key|
        item = self.send("find_by_#{key}",params["id"],:conditions =>conditions)
        return item unless item.nil? 
      end
      return nil
    end

    def restful_find_by_conditions(mode,params,conditions)
    end
    
    def restful_find_by_subset(mode,params,conditions)    
    end

    # To fully understand the class read it like:
    # Class_name method paramsters
    # For isntance initialize is read like this
    # RestfulAssociation initialize link name to class
    class RestfulAssociation
      ## To class not used temporarily since belongs_to is only one currently
      def initialize(link_name,to_class)
        @link_name = link_name
      end
      
      def in(params)
        { @link_name => params[link_name] }
      end
      
      def is_in?(params)
        params.any? { |link,value| link == @link_name}
      end
    end
  end
end

module ActiveRecord
  class Base
    extend RestfulAdditions::ModelBase
  end

  module Reflection # :nodoc:
    module ClassMethods
      alias old_create_reflection create_reflection
      def create_reflection(macro,name,options,active_record)
        reflec = old_create_reflection(macro,name,options,active_record)
        begin
          reflec.klass.add_restful_association(macro,name,options,reflec.klass.to_s)
        rescue
        end
        reflec
      end
    end
  end
end
 

class ActionController::AbstractRequest
  
  def records
    extract_records(:all)
  end
  
  def records_with(conditions = { })
    extract_records(:all,conditions)
  end
    
  def record
    extract_records(:first)
  end
  
  def record_with(conditions = { })
    extract_records(:first,conditions)
  end
  
  alias first_record record

  def last_record
    extract_records(:last)
  end
private
  #Returns single
  def extract_records(mode = :first, conditions = { })
    class_name = self.parameters[:controller].singularize.camelize
    class_const = class_name.constantize  
    class_const.restful_find(:mode, self.paramaters,:conditions => conditions)
  end  
end
