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
      rep = []
      for association in @restful_associations
        conditions.merge!(association.in(params)) if(association.is_in?(params))
        rep.push(association.in(params).to_s)
      end

      raise rep.to_s
      self.restful_find_by_keys(mode,params,conditions)
    end
    
    def add_restful_association(macro,name,options,class_name)
      case(macro)
      when :belongs_to
        raise name + " " + class_name
#          raise options if name == "fable"
          @restful_associations.push(RestfulAssociation.new(name,options[:class_name] || class_name))
      when :has_many:
          @restful_associations.push(RestfulAssociation.new(name,options[:class_name] || class_name))
      else
        puts "Warning... #{macro} not supported yet by restful additions"
      end
      
    end

    
    protected
    def restful_find_by_keys(mode,params,conditions)
      @restful_keys.each do |key|
        item = self.send("find_by_#{key}",params["id"],conditions)
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
      def initialize(owner_class,child_class)
        raise owner_class if( child_class == "Member")
        @link_name = child_class.downcase + "_id"
      end
      
      def in(params)
        { @link_name => params[@link_name] }
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
          reflec.klass.add_restful_association(macro,reflec.klass.to_s,options,name.to_s)
        rescue NameError
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

  def records_for_page(page,args = { })

    if page.class == Hash
      args = page
      page = nil
    end 
    page ||= self.parameters[:page] # paramaters[:page] returns flase if nil
    page = nil if not page

    args.merge!(:page => page)

    class_const = extract_record_class()
    class_const.paginate(args)
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
    class_const.restful_find(mode, self.parameters,:conditions => conditions)
  end
  
  def extract_record_class
    class_name = self.parameters[:controller].singularize.camelize
    class_name.constantize  
  end
end
