module ActiveRecord
  class Base
    class << self
      # * restful_key will add the given key to the list of
      # indexes restful_find will search
      def inherited(child)
        child.class_eval do
          @restful_keys = []
        end
        super(child)
      end
      # Call this in the model to set up the keys to search for
      # .:restful_key :title:. Will make restful_find to also try to find by the title
      #   if finding by id fails
      def restful_key key
        @restful_keys.push key unless @restful_keys.include? key
      end
      # Call this function to find a record when then key is not nessisarily known
      # * When visiting http://domain.com/posts/1 or http://domain.com/posts/first_post they should
      #   return the same post.
      # * restful_search is used to solve this problem.  For the previous case use
      #   post = Post.restful_find params[:id]
      #   --Note: the method (restful_key :tittle) must be called in the Post class
      def restful_find id
        begin
          self.find id
        rescue
          @restful_keys.each do |key|
            item = self.send "find_by_#{key}", id
            return item unless item.nil?
          end
          nil
        end
      end

      # Will return a record or nil
      # * Visiting http://domain.com/members/1/profile and
      #   http://domain.com/profiles/4 need to return the same profile
      # * Restful search is used to solve this problem.  For the previous
      #   case use @profile = Profile.restful_search_on :member_id, params and
      #   it will return the proper profile for either case
      def restful_search_on parent_key, params
        if params[parent_key]
          parent_class = parent_key.to_s.sub('_id','').camelize.constantize
          obj = parent_class.restful_find params[parent_key]
          #TODO Add a clause for restful_search_on to check for an id along with a parent_id
          #  this will handel the http://tellmeafable.com/members/daicoden/fables/2 where 2 is
          #  not the fable id but the 2nd fable? (Maybe this is not a good idea)
          obj.send(self.name.downcase)
        else
          self.restful_find params[:id]
        end
      end
    end
  end
end
