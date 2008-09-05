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
      debug = []
      for association in @restful_associations
        conditions.merge!(association.in(params)) if(association.is_in?(params))
        debug.push(association.in(params))
      end

      self.restful_find_by_keys(mode,params,conditions)
    end

    def restful_paginate(params,args = { })
      args[:conditions] ||= { }
      for association in @restful_associations
        args[:conditions].merge!(association.in(params)) if(association.is_in?(params))
      end

      self.paginate(args)
    end
    
    def add_restful_association(name,target,options)
      @restful_associations.push(RestfulAssociation.new(name.to_s, target.to_s,options))     
    end

    
    protected
    def restful_find_by_keys(mode,params,conditions)

      if mode == :all
        return self.find(:all,:conditions => conditions)
      elsif mode == :first

        @restful_keys.each do |key|
          item = self.send("find_by_#{key}",params["id"],:conditions => conditions)
          return item unless item.nil? 
        end
        
      end
      return nil

    end
    
    # To fully understand the class read it like:
    # Class_name method paramsters
    # For isntance initialize is read like this
    # RestfulAssociation initialize link name to class
    class RestfulAssociation
      ## To class not used temporarily since belongs_to is only one currently
      def initialize(owner_class,child_class,options)
        @link_name_to_class_name = { child_class.downcase+"_id" => options[:class_name].downcase+"_id" }
        @link_name = child_class.downcase + "_id"
      end
      
      def in(params)
        { @link_name => params[@link_name] || params[@link_name_to_class_name[@link_name]] }
      end
      
      def is_in?(params)
        params.any? { |link,value| link == @link_name or link == @link_name_to_class_name[@link_name]}
      end
    end
  end
end

module ActiveRecord
  class Base
    extend RestfulAdditions::ModelBase
  end

  module Associations
    module ClassMethods
      alias old_create_belongs_to_reflection create_belongs_to_reflection
      def create_belongs_to_reflection(association_id, options)
        self.add_restful_association(self.name,association_id,options)
        old_create_belongs_to_reflection(association_id,options)
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

  def records_for_page(page,args = { })

    if page.class == Hash
      args = page
      page = nil
    end 
    page ||= self.parameters[:page] # paramaters[:page] returns flase if nil
    page = nil if not page

    args.merge!(:page => page)

    class_const = extract_record_class()
    class_const.restful_paginate(self.parameters,args)
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
    class_const = extract_record_class()
    class_const.restful_find(mode, self.parameters,conditions)
  end
  
  def extract_record_class
    class_name = self.parameters[:controller].singularize.camelize
    class_name.constantize  
  end
end
