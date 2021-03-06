# Contains Twitter4R Model API.

module Twitter
  # Mixin module for model classes.  Includes generic class methods like
  # unmarshal.
  # 
  # To create a new model that includes this mixin's features simply:
  #  class NewModel
  #    include Twitter::ModelMixin
  #  end
  # 
  # This mixin module automatically includes <tt>Twitter::ClassUtilMixin</tt>
  # features.
  # 
  # The contract for models to use this mixin correctly is that the class 
  # including this mixin must provide an class method named <tt>attributes</tt>
  # that will return an Array of attribute symbols that will be checked 
  # in #eql? override method.  The following would be sufficient:
  #  def self.attributes; @@ATTRIBUTES; end
  module ModelMixin #:nodoc:
    def self.included(base) #:nodoc:
      base.send(:include, Twitter::ClassUtilMixin)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    # Class methods defined for <tt>Twitter::ModelMixin</tt> module.
    module ClassMethods #:nodoc:
      # Unmarshal object singular or plural array of model objects
      # from JSON serialization.  Currently JSON is only supported 
      # since this is all <tt>Twitter4R</tt> needs.
      def unmarshal(raw)
        input = JSON.parse(raw) if raw.is_a?(String)

        def unmarshal_model(hash)
          self.new(hash)
        end
        return unmarshal_model(input) if input.is_a?(Hash) # singular case
        result = []
        input.each do |hash|
          model = unmarshal_model(hash) if hash.is_a?(Hash)
          result << model
        end if input.is_a?(Array)
        result # plural case
      end
    end
    
    # Instance methods defined for <tt>Twitter::ModelMixin</tt> module.
    module InstanceMethods #:nodoc:
      attr_accessor :client
      # Equality method override of Object#eql? default.
      # 
      # Relies on the class using this mixin to provide a <tt>attributes</tt>
      # class method that will return an Array of attributes to check are 
      # equivalent in this #eql? override.
      # 
      # It is by design that the #eql? method will raise a NoMethodError
      # if no <tt>attributes</tt> class method exists, to alert you that 
      # you must provide it for a meaningful result from this #eql? override.
      # Otherwise this will return a meaningless result.
      def eql?(other)
        attrs = self.class.attributes
        attrs.each do |att|
          return false unless self.send(att).eql?(other.send(att))
        end
        true
      end
      
      # Returns integer representation of model object instance.
      # 
      # For example,
      #  status = Twitter::Status.new(:id => 234343)
      #  status.to_i #=> 234343
      def to_i
        @id
      end
      
      # Returns string representation of model object instance.
      # 
      # For example,
      #  status = Twitter::Status.new(:text => 'my status message')
      #  status.to_s #=> 'my status message'
      # 
      # If a model class doesn't have a @text attribute defined 
      # the default Object#to_s will be returned as the result.
      def to_s
        self.respond_to?(:text) ? @text : super.to_s
      end
      
      # Returns hash representation of model object instance.
      # 
      # For example,
      #  u = Twitter::User.new(:id => 2342342, :screen_name => 'tony_blair_is_the_devil')
      #  u.to_hash #=> {:id => 2342342, :screen_name => 'tony_blair_is_the_devil'}
      # 
      # This method also requires that the class method <tt>attributes</tt> be 
      # defined to return an Array of attributes for the class.
      def to_hash
        attrs = self.class.attributes
        result = {}
        attrs.each do |att|
          value = self.send(att)
          value = value.to_hash if value.respond_to?(:to_hash)
          result[att] = value if value
        end
        result
      end
      
      # "Blesses" model object.
      # 
      # Should be overridden by model class if special behavior is expected
      # 
      # Expected to return blessed object (usually <tt>self</tt>)
      def bless(client)
        self.basic_bless(client)
      end
      
      protected
        # Basic "blessing" of model object 
        def basic_bless(client)
          self.client = client
          self
        end
    end
  end
  
  module AuthenticatedUserMixin
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
 	
    module InstanceMethods
      # Returns an Array of user objects that represents the authenticated
      # user's friends on Twitter.
      def followers(options = {})
        @client.my(:followers, options)
      end
      
      # Adds given user as a friend.  Returns user object as given by 
      # <tt>Twitter</tt> REST server response.
      # 
      # For <tt>user</tt> argument you may pass in the unique integer 
      # user ID, screen name or Twitter::User object representation.
      def befriend(user)
      	@client.friend(:add, user)
      end
      
      # Removes given user as a friend.  Returns user object as given by 
      # <tt>Twitter</tt> REST server response.
      # 
      # For <tt>user</tt> argument you may pass in the unique integer 
      # user ID, screen name or Twitter::User object representation.
      def defriend(user)
      	@client.friend(:remove, user)
      end
    end
  end

  # Represents a location in Twitter
  class Location
    include ModelMixin

    @@ATTRIBUTES = [:name, :woeid, :country, :url, :countryCode, :parentid, :placeType]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      def attributes; @@ATTRIBUTES; end
    end

    # Alias to +countryCode+ for those wanting to use consistent naming 
    # convention for attribute
    def country_code
      @countryCode
    end

    # Alias to +parentid+ for those wanting to use consistent naming 
    # convention for attribute
    def parent_id
      @parentid
    end

    # Alias to +placeType+ for those wanting to use consistent naming 
    # convention for attribute
    def place_type
      @place_type
    end

    # Convenience method to output meaningful representation to STDOUT as per 
    # Ruby convention
    def inspect
      "#{name} / #{woeid} / #{countryCode}\n#{url}\n"
    end

    protected
      def init
        puts @placeType
        @placeType = ::Twitter::PlaceType.new(:name => @placeType["name"], 
                                              :code => @placeType["code"]) if @placeType.is_a?(Hash)
      end
  end

  # Represents a type of a place.
  class PlaceType
    include ModelMixin

    @@ATTRIBUTES = [:name, :code]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      def attributes; @@ATTRIBUTES; end
    end
  end

  # Represents a sorted, dated and typed list of trends.
  #
  # To find out when this +Trendline+ was created query the +as_of+ attribute.
  # To find out what type +Trendline+ is use the +type+ attribute.
  # You can iterator over the trends in the +Trendline+ with +each+ or by 
  # index, whichever you prefer.
  class Trendline
    include ModelMixin
    include Enumerable
    include Comparable

    @@ATTRIBUTES = [:as_of, :type]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      def attributes; @@ATTRIBUTES; end
    end

    # Spaceship operator definition needed by Comparable mixin
    # for sort, etc.
    def <=>(other)
      self.type === other.type && self.as_of <=> other.as_of
    end

    # each definition needed by Enumerable mixin for first, ...
    def each
      trends.each do |t|
        yield t
      end
    end

    # index operator definition needed to iterate over trends 
    # in the +::Twitter::Trendline+ object using for or otherwise
    def [](index)
      trends[index]
    end

    protected
      attr_accessor(:trends)
      # Constructor callback
      def init
        @trends = @trends.collect do |trend|
          ::Twitter::Trend.new(trend) if trend.is_a?(Hash)
        end if @trends.is_a?(Array)
      end
  end

  class Trend
    include ModelMixin
    @@ATTRIBUTES = [:name, :url]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      def attributes; @@ATTRIBUTES; end
    end
  end

  # Represents a <tt>Twitter</tt> user
  class User
    include ModelMixin
    @@ATTRIBUTES = [:id, :name, :description, :location, :screen_name, :url, 
      :protected, :profile_image_url, :profile_background_color, 
      :profile_text_color, :profile_link_color, :profile_sidebar_fill_color, 
      :profile_sidebar_border_color, :profile_background_image_url, 
      :profile_background_tile, :utc_offset, :time_zone, 
      :following, :notifications, :favourites_count, :followers_count, 
      :friends_count, :statuses_count, :created_at ]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      # Used as factory method callback
      def attributes; @@ATTRIBUTES; end

      # Returns user model object with given <tt>id</tt> using the configuration
      # and credentials of the <tt>client</tt> object passed in.
      # 
      # You can pass in either the user's unique integer ID or the user's 
      # screen name.
      def find(id, client)
        client.user(id)
      end
    end
    
    # Override of ModelMixin#bless method.
    # 
    # Adds #followers instance method when user object represents 
    # authenticated user.  Otherwise just do basic bless.
    # 
    # This permits applications using <tt>Twitter4R</tt> to write 
    # Rubyish code like this:
    #  followers = user.followers if user.is_me?
    # Or:
    #  followers = user.followers if user.respond_to?(:followers)
    def bless(client)
      basic_bless(client)
      self.instance_eval(%{
      	self.class.send(:include, Twitter::AuthenticatedUserMixin)
      }) if self.is_me? and not self.respond_to?(:followers)
      self
    end
    
    # Returns whether this <tt>Twitter::User</tt> model object
    # represents the authenticated user of the <tt>client</tt>
    # that blessed it.
    def is_me?
      # TODO: Determine whether we should cache this or not?
      # Might be dangerous to do so, but do we want to support
      # the edge case where this would cause a problem?  i.e. 
      # changing authenticated user after initial use of 
      # authenticated API.
      # TBD: To cache or not to cache.  That is the question!
      # Since this is an implementation detail we can leave this for 
      # subsequent 0.2.x releases.  It doesn't have to be decided before 
      # the 0.2.0 launch.
      @screen_name == @client.instance_eval("@login")
    end
    
    # Returns an Array of user objects that represents the authenticated
    # user's friends on Twitter.
    def friends
      @client.user(@id, :friends)
    end
  end # User

  # Represents the entities from a <tt>Twitter</tt> post
  #
  # Can include media, user mentions, URLs and hashtags. For more details see:
  # https://dev.twitter.com/docs/tweet-entities
  #
  # Must enable include_entities as an option in the request to receive these.
  class Entities
    include ModelMixin
    @@ATTRIBUTES = [:urls, :media, :user_mentions, :hashtags ]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      # Used as factory method callback
      def attributes; @@ATTRIBUTES; end
    end

    protected
      # Constructor callback
      def init
        @urls = @urls.collect {|e| e.is_a?(Hash) ? Url.new(e) : e } if @urls.is_a?(Array)
        @media = @media.collect {|e| e.is_a?(Hash) ? Media.new(e) : e } if @media.is_a?(Array)
        @user_mentions = @user_mentions.collect {|e| e.is_a?(Hash) ? UserMention.new(e) : e } if @user_mentions.is_a?(Array)
        @hashtags = @hashtags.collect {|e| e.is_a?(Hash) ? HashTag.new(e) : e } if @hashtags.is_a?(Array)

      end    
  end 

# Represents a URL entity.
  #
  # For details, see:
  # https://dev.twitter.com/docs/tweet-entities
  class Url
      include ModelMixin
      @@ATTRIBUTES = [:url, :display_url, :expanded_url, :indices ]
      attr_accessor(*@@ATTRIBUTES)

      class << self
        # Used as factory method callback
        def attributes; @@ATTRIBUTES; end
      end

      def to_s
        @display_url
      end
  end # Url

  # Represents a media entity.
  #
  # For details, see:
  # https://dev.twitter.com/docs/tweet-entities
  class Media
      include ModelMixin
      @@ATTRIBUTES = [:id, :id_str, :media_url, :media_url_https, :url, :display_url,
                      :expanded_url, :sizes, :type, :indices ]
      attr_accessor(*@@ATTRIBUTES)

      class << self
        # Used as factory method callback
        def attributes; @@ATTRIBUTES; end
      end
  end # Media

  # Represents a user mention entity.
  #
  # For details, see:
  # https://dev.twitter.com/docs/tweet-entities
  class UserMention
      include ModelMixin
      @@ATTRIBUTES = [:id, :id_str, :screen_name, :name, :indices ]
      attr_accessor(*@@ATTRIBUTES)

      class << self
        # Used as factory method callback
        def attributes; @@ATTRIBUTES; end
      end


      def to_s
        "@#{@screen_name}"
      end
  end # UserMention


  # Represents a hashtag entity.
  #
  # For details, see:
  # https://dev.twitter.com/docs/tweet-entities
  class HashTag
      include ModelMixin
      @@ATTRIBUTES = [:text, :indices ]
      attr_accessor(*@@ATTRIBUTES)

      class << self
        # Used as factory method callback
        def attributes; @@ATTRIBUTES; end
      end
  end # Hashtag

  # Represents a status posted to <tt>Twitter</tt> by a <tt>Twitter</tt> user.
  class Status
    include ModelMixin
    @@ATTRIBUTES = [:id, :id_str, :text, :source, :truncated, :created_at, :user, 
                    :from_user, :to_user, :favorited, :in_reply_to_status_id, 
                    :in_reply_to_user_id, :in_reply_to_screen_name, :geo, :entities]
    attr_accessor(*@@ATTRIBUTES)

    class << self
      # Used as factory method callback
      def attributes; @@ATTRIBUTES; end
      
      # Returns status model object with given <tt>status</tt> using the 
      # configuration and credentials of the <tt>client</tt> object passed in.
      def find(id, client)
        client.status(:get, id)
      end
      
      # Creates a new status for the authenticated user of the given 
      # <tt>client</tt> context.
      # 
      # You MUST include a valid/authenticated <tt>client</tt> context 
      # in the given <tt>params</tt> argument.
      # 
      # For example:
      #  status = Twitter::Status.create(
      #    :text => 'I am shopping for flip flops',
      #    :client => client)
      # 
      # An <tt>ArgumentError</tt> will be raised if no valid client context
      # is given in the <tt>params</tt> Hash.  For example,
      #  status = Twitter::Status.create(:text => 'I am shopping for flip flops')
      # The above line of code will raise an <tt>ArgumentError</tt>.
      # 
      # The same is true when you do not provide a <tt>:text</tt> key-value
      # pair in the <tt>params</tt> argument given.
      # 
      # The Twitter::Status object returned after the status successfully
      # updates on the Twitter server side is returned from this method.
      def create(params)
      	client, text = params[:client], params[:text]
      	raise ArgumentError, 'Valid client context must be provided' unless client.is_a?(Twitter::Client)
      	raise ArgumentError, 'Must provide text for the status to update' unless text.is_a?(String)
      	client.status(:post, text)
      end
    end

    def reply?
      !!@in_reply_to_status_id
    end

    # Convenience method to allow client developers to not have to worry about 
    # setting the +in_reply_to_status_id+ attribute or prefixing the status 
    # text with the +screen_name+ being replied to.
    def reply(reply)
      status_reply = "@#{user.screen_name} #{reply}"
      client.status(:reply, :status => status_reply, 
                    :in_reply_to_status_id => @id)
    end
    
    protected
      # Constructor callback
      def init
        @user = User.new(@user) if @user.is_a?(Hash)
        @entities = Entities.new(@entities) if @entities.is_a?(Hash)

        @created_at = Time.parse(@created_at) if @created_at.is_a?(String)
      end    
  end # Status
  
  # Represents a direct message on <tt>Twitter</tt> between <tt>Twitter</tt> users.
  class Message
    include ModelMixin
    @@ATTRIBUTES = [:id, :recipient, :sender, :text, :geo, :created_at]
    attr_accessor(*@@ATTRIBUTES)
    
    class << self
      # Used as factory method callback
      def attributes; @@ATTRIBUTES; end
      
      # Raises <tt>NotImplementedError</tt> because currently 
      # <tt>Twitter</tt> doesn't provide a facility to retrieve 
      # one message by unique ID.
      def find(id, client)
        raise NotImplementedError, 'Twitter has yet to implement a REST API for this.  This is not a Twitter4R library limitation.'
      end
      
      # Creates a new direct message from the authenticated user of the 
      # given <tt>client</tt> context.
      # 
      # You MUST include a valid/authenticated <tt>client</tt> context 
      # in the given <tt>params</tt> argument.
      # 
      # For example:
      #  status = Twitter::Message.create(
      #    :text => 'I am shopping for flip flops',
      #    :recipient => 'anotherlogin',
      #    :client => client)
      # 
      # An <tt>ArgumentError</tt> will be raised if no valid client context
      # is given in the <tt>params</tt> Hash.  For example,
      #  status = Twitter::Status.create(:text => 'I am shopping for flip flops')
      # The above line of code will raise an <tt>ArgumentError</tt>.
      # 
      # The same is true when you do not provide any of the following
      # key-value pairs in the <tt>params</tt> argument given:
      # * <tt>text</tt> - the String that will be the message text to send to <tt>user</tt>
      # * <tt>recipient</tt> - the user ID, screen_name or Twitter::User object representation of the recipient of the direct message
      # 
      # The Twitter::Message object returned after the direct message is 
      # successfully sent on the Twitter server side is returned from 
      # this method.
      def create(params)
      	client, text, recipient = params[:client], params[:text], params[:recipient]
      	raise ArgumentError, 'Valid client context must be given' unless client.is_a?(Twitter::Client)
      	raise ArgumentError, 'Message text must be supplied to send direct message' unless text.is_a?(String)
      	raise ArgumentError, 'Recipient user must be specified to send direct message' unless [Twitter::User, Integer, String].member?(recipient.class)
      	client.message(:post, text, recipient)
      end
    end
    
    protected
      # Constructor callback
      def init
        @sender = User.new(@sender) if @sender.is_a?(Hash)
        @recipient = User.new(@recipient) if @recipient.is_a?(Hash)
        @created_at = Time.parse(@created_at) if @created_at.is_a?(String)
      end
  end # Message
  
  # RateLimitStatus provides information about how many requests you have left 
  # and when you can resume more requests if your remaining_hits count is zero.
  class RateLimitStatus
    include ModelMixin
    @@ATTRIBUTES = [:remaining_hits, :hourly_limit, :reset_time_in_seconds, :reset_time]
    attr_accessor(*@@ATTRIBUTES)
    
    class << self
      # Used as factory method callback
      def attributes; @@ATTRIBUTES; end
    end
  end
end # Twitter
