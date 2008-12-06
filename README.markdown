Restful Additions
=================

Restful Additions is an attempt to give services access to data without sacrificing the human friendly URLs.

_I lost the copy I was working on so thought I better post this backup, I believe restful\_find works but not in all of the cases below._

What it does...
---------------

Best for now is probably by example.

* http://copypastel.com/posts 

List of all posts paginated

* http://copypastel.com/posts/tada

Display of my post

* http://copypastel.com/posts/4

Display of my post

* http://copypsatel.com/members/daicoden/posts 

List of all of my posts paginated

* http://copypastel.com/members/daicoden/posts/tada

Display of my post

* http://copypastel.com/members/daicoden/posts/1

Display of my first post (notice it isn't 4 like the post id)

* http://copypastel.com/members/1/posts/

List of all of my posts paginated

* http://copypastel.com/members/1/posts/1

---
How it does it...
-----------------

	class PostsController < ApplicationController
	  def index
	    @posts = request.records_for_page
	  end
	
	  def show
	    @post = request.record
	  end
	
	  def new
	    @post = request.new_record
	  end
	
	  def edit
	    @post = request.record
	  end
	
	  def create
	    @post = request.new_record  #Actually creates the record with the params in mind
	
	    if @post.save then flash[:notice] = 'Post was successfully created.'
	    else                      flash[:error]   = @post.errors; end
	  end
	
	  def update
	   @post = request.update_record
	    if(@post.valid?) then flash[:notice] = 'Post was successfully updated.'
	    else                        flash[:error]    = @post.errors ; end
	  end
	
	  def destroy
	    @post = request.destroy_record
	  end
	end
	
	#Models
	class Post < ActiveRecord::Base
	  restful_key :url_title
	  restful_key :id
	 
	  belongs_to :author, :class_name => "Member"
	end
	
	class Member < ActiveRecord::Base
	  has_many :posts
	end
	
	#and lastly routes
	map.resources :posts
	map.resources :members, :has_many => [:posts]
