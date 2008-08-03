module RestfulAdditions
  # Gem will add all ModelBase methods to the Base of the database agent
  module ModelBase
    def self.extended(modelBase)
      modelBase.class_eval do
        def self.inherited(model)
          model.class_eval do
            @@restful_keys = []
            @@restful_assosiations = []
          end
        end
      end
    end
    
    def restful_key(key)
      # I'm too nice to you guys => the error checking
      @@restful_keys.push key unless @@restful_keys.include? key
    end
    
    def restful_find(mode, params = { },conditions = { })
      for association in @@restful_associations
        conditions.merge!(association.in(params)) if(association.is_in?(params))
      end
      #TODO clean this up...
     # mode       = nil unless mode_or_params.class == Symbol
     # params     = (mode.nil?) ? mode_or_params       : params_or_conditions
     # conditions = (mode.nil?) ? params_or_conditions : conditions
     # tmp = conditions.dup
     # condtions = { }
     # conditions[:first] = tmp.dup
     # conditions[:second] = tmp.dup

     # subset = nil #defined for scope
      # Contains _id if a subset is being accessed e.g. topic_id
      #TODO this only works if keys are strings... check bug
     # if params.any? { |key,value| (subset = key).include?("_id") }
     #   conditions[:first][subset] = params[subset]
     #   #subset.sub("_id",'')
     # end
     # if params[:id]
     #   self.restful_find_by_keys(mode,params,conditions)
     # else
     #   self.restful_find_by_conditions(mode,params,conditions)
      #end
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

    def add_restful_association(macro,name,options,klass)
      case(macro)
      when :blongs_to:
        @@restful_associations.push(Association.new(name,options[:class_name] || klass))
      end
    end
    
    protected
    def restful_find_by_keys(mode,params,conditions)
      @@restful_keys.each do |key|
        item = self.send("find_by_#{key}",params["id"],:conditions =>conditions)
        return item unless item.nil? 
      end
      return nil
    end

    def restful_find_by_conditions(mode,params,conditions)
    end
    
    def restful_find_by_subset(mode,params,conditions)    
    end
  end
end

module ActiveRecord
  class Base
    extend RestfulAdditions::ModelBase
  end

  module Associations
    class AssociationProxy
      def initialize(owner,reflection)
        raise reflection.class.to_s
      end
    end
    
    module ActiveRecord
      module Reflection # :nodoc:
        module ClassMethods
          def create_reflection(macro, name, options, active_record)
            super #It sure is super!
            @reflection.klass.add_restful_association(macro,name,options,@reflection.klass.to_s)
          end
        end
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
