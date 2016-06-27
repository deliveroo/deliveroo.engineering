# Table of Contents

* [Developing Rails applications](#developing-rails-applications)
    * [Configuration](#configuration)
    * [Routing](#routing)
    * [Controllers](#controllers)
    * [Models](#models)
    * [Migrations](#migrations)
    * [Views](#views)
    * [Internationalization](#internationalization)
    * [Assets](#assets)
    * [Mailers](#mailers)
    * [Bundler](#bundler)
    * [Priceless Gems](#priceless-gems)
    * [Flawed Gems](#flawed-gems)
    * [Managing processes](#managing-processes)
* [Testing Rails applications](#testing-rails-applications)
    * [Cucumber](#cucumber)
    * [RSpec](#rspec)

# Developing Rails applications

## Configuration

* Put custom initialization code in `config/initializers`. The code in
  initializers executes on application startup.
* Keep initialization code for each gem in a separate file
  with the same name as the gem, for example `carrierwave.rb`,
  `active_admin.rb`, etc.
* Adjust accordingly the settings for development, test and production
  environment (in the corresponding files under `config/environments/`)
  * Mark additional assets for precompilation (if any):

        ```Ruby
        # config/environments/production.rb
        # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
        config.assets.precompile += %w( rails_admin/rails_admin.css rails_admin/rails_admin.js )
        ```

* Keep configuration that's applicable to all environments in the `config/application.rb` file.
* Create an additional `staging` environment that closely resembles
the `production` one.

## Routing

* When you need to add more actions to a RESTful resource (do you
  really need them at all?) use `member` and `collection` routes.

    ```Ruby
    # bad
    get 'subscriptions/:id/unsubscribe'
    resources :subscriptions

    # good
    resources :subscriptions do
      get 'unsubscribe', on: :member
    end

    # bad
    get 'photos/search'
    resources :photos

    # good
    resources :photos do
      get 'search', on: :collection
    end
    ```

* If you need to define multiple `member/collection` routes use the
  alternative block syntax.

    ```Ruby
    resources :subscriptions do
      member do
        get 'unsubscribe'
        # more routes
      end
    end

    resources :photos do
      collection do
        get 'search'
        # more routes
      end
    end
    ```

* Use nested routes to express better the relationship between
  ActiveRecord models.

    ```Ruby
    class Post < ActiveRecord::Base
      has_many :comments
    end

    class Comments < ActiveRecord::Base
      belongs_to :post
    end

    # routes.rb
    resources :posts do
      resources :comments
    end
    ```

* Use namespaced routes to group related actions.

    ```Ruby
    namespace :admin do
      # Directs /admin/products/* to Admin::ProductsController
      # (app/controllers/admin/products_controller.rb)
      resources :products
    end
    ```

* Never use the legacy wild controller route. This route will make all
  actions in every controller accessible via GET requests.

    ```Ruby
    # very bad
    match ':controller(/:action(/:id(.:format)))'
    ```

* Don't use `match` to define any routes. It's removed from Rails 4.

## Controllers

* Keep the controllers skinny - they should only retrieve data for the
  view layer and shouldn't contain any business logic (all the
  business logic should naturally reside in the model).
* Each controller action should (ideally) invoke only one method other
  than an initial find or new.
* Share no more than two instance variables between a controller and a view.

## Models

* Introduce non-ActiveRecord model classes freely.
* Name the models with meaningful (but short) names without
abbreviations.
* If you need model objects that support ActiveRecord behavior(like
  validation) use the
  [ActiveAttr](https://github.com/cgriego/active_attr) gem.

    ```Ruby
    class Message
      include ActiveAttr::Model

      attribute :name
      attribute :email
      attribute :content
      attribute :priority

      attr_accessible :name, :email, :content

      validates :name, presence: true
      validates :email, format: { with: /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i }
      validates :content, length: { maximum: 500 }
    end
    ```

    For a more complete example refer to the
    [RailsCast on the subject](http://railscasts.com/episodes/326-activeattr).

### ActiveRecord

* Avoid altering ActiveRecord defaults (table names, primary key, etc)
  unless you have a very good reason (like a database that's not under
  your control).

    ```Ruby
    # bad - don't do this if you can modify the schema
    class Transaction < ActiveRecord::Base
      self.table_name = 'order'
      ...
    end
    ```

* Group macro-style methods (`has_many`, `validates`, etc) in the
  beginning of the class definition.

    ```Ruby
    class User < ActiveRecord::Base
      # keep the default scope first (if any)
      default_scope { where(active: true) }

      # constants come up next
      GENDERS = %w(male female)

      # afterwards we put attr related macros
      attr_accessor :formatted_date_of_birth

      attr_accessible :login, :first_name, :last_name, :email, :password

      # followed by association macros
      belongs_to :country

      has_many :authentications, dependent: :destroy

      # and validation macros
      validates :email, presence: true
      validates :username, presence: true
      validates :username, uniqueness: { case_sensitive: false }
      validates :username, format: { with: /\A[A-Za-z][A-Za-z0-9._-]{2,19}\z/ }
      validates :password, format: { with: /\A\S{8,128}\z/, allow_nil: true}

      # next we have callbacks
      before_save :cook
      before_save :update_username_lower

      # other macros (like devise's) should be placed after the callbacks

      ...
    end
    ```

* Prefer `has_many :through` to `has_and_belongs_to_many`. Using `has_many
:through` allows additional attributes and validations on the join model.

    ```Ruby
    # using has_and_belongs_to_many
    class User < ActiveRecord::Base
      has_and_belongs_to_many :groups
    end

    class Group < ActiveRecord::Base
      has_and_belongs_to_many :users
    end

    # prefered way - using has_many :through
    class User < ActiveRecord::Base
      has_many :memberships
      has_many :groups, through: :memberships
    end

    class Membership < ActiveRecord::Base
      belongs_to :user
      belongs_to :group
    end

    class Group < ActiveRecord::Base
      has_many :memberships
      has_many :users, through: :memberships
    end
    ```

* Prefer `self[:attribute]` over `read_attribute(:attribute)`.

    ```Ruby
    # bad
    def amount
      read_attribute(:amount) * 100
    end

    # good
    def amount
      self[:amount] * 100
    end
    ```

* Always use the new
  ["sexy" validations](http://thelucid.com/2010/01/08/sexy-validation-in-edge-rails-rails-3/).

    ```Ruby
    # bad
    validates_presence_of :email

    # good
    validates :email, presence: true
    ```

* When a custom validation is used more than once or the validation is
some regular expression mapping, create a custom validator file.

    ```Ruby
    # bad
    class Person
      validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
    end

    # good
    class EmailValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        record.errors[attribute] << (options[:message] || 'is not a valid email') unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      end
    end

    class Person
      validates :email, email: true
    end
    ```

* Keep custom validators under `app/validators`.
* Consider extracting custom validators to a shared gem if you're
  maintaining several related apps or the validators are generic
  enough.
* Use named scopes freely.

    ```Ruby
    class User < ActiveRecord::Base
      scope :active, -> { where(active: true) }
      scope :inactive, -> { where(active: false) }

      scope :with_orders, -> { joins(:orders).select('distinct(users.id)') }
    end
    ```

* Wrap named scopes in `lambdas` to initialize them lazily (this is only a prescription in Rails 3, but is mandatory in Rails 4).

    ```Ruby
    # bad
    class User < ActiveRecord::Base
      scope :active, where(active: true)
      scope :inactive, where(active: false)

      scope :with_orders, joins(:orders).select('distinct(users.id)')
    end

    # good
    class User < ActiveRecord::Base
      scope :active, -> { where(active: true) }
      scope :inactive, -> { where(active: false) }

      scope :with_orders, -> { joins(:orders).select('distinct(users.id)') }
    end
    ```

* When a named scope defined with a lambda and parameters becomes too
complicated, it is preferable to make a class method instead which serves
the same purpose of the named scope and returns an
`ActiveRecord::Relation` object. Arguably you can define even simpler
scopes like this.

    ```Ruby
    class User < ActiveRecord::Base
      def self.with_orders
        joins(:orders).select('distinct(users.id)')
      end
    end
    ```

* Beware of the behavior of the `update_attribute` method. It doesn't
  run the model validations (unlike `update_attributes`) and could easily corrupt the model state. The method was finally deprecated in Rails 3.2.7 and does not exist in Rails 4.
* Use user-friendly URLs. Show some descriptive attribute of the model in the URL rather than its `id`.
There is more than one way to achieve this:
  * Override the `to_param` method of the model. This method is used by Rails for constructing a URL to the object.
  The default implementation returns the `id` of the record as a String.
  It could be overridden to include another human-readable attribute.

        ```Ruby
        class Person
          def to_param
            "#{id} #{name}".parameterize
          end
        end
        ```

    In order to convert this to a URL-friendly value, `parameterize` should be called on the string. The `id` of the
    object needs to be at the beginning so that it can be found by the `find` method of ActiveRecord.

  * Use the `friendly_id` gem. It allows creation of human-readable URLs by using some descriptive attribute of the model instead of its `id`.

        ```Ruby
        class Person
          extend FriendlyId
          friendly_id :name, use: :slugged
        end
        ```

  Check the [gem documentation](https://github.com/norman/friendly_id) for more information about its usage.

* Use `find_each` to iterate over a collection of AR objects. Looping
   through a collection of records from the database (using the `all`
   method, for example) is very inefficient since it will try to
   instantiate all the objects at once. In that case, batch processing
   methods allow you to work with the records in batches, thereby
   greatly reducing memory consumption.


    ```Ruby
    # bad
    Person.all.each do |person|
      person.do_awesome_stuff
    end

    Person.where("age > 21").each do |person|
      person.party_all_night!
    end

    # good
    Person.all.find_each do |person|
      person.do_awesome_stuff
    end

    Person.where("age > 21").find_each do |person|
      person.party_all_night!
    end
    ```

## Migrations

* Keep the `schema.rb` (or `structure.sql`) under version control.
* Use `rake db:schema:load` instead of `rake db:migrate` to initialize
an empty database.
* Use `rake db:test:prepare` to update the schema of the test database.
* Enforce default values in the migrations themselves instead of in
  the application layer.

    ```Ruby
    # bad - application enforced default value
    def amount
      self[:amount] or 0
    end
    ```

    While enforcing table defaults only in Rails is suggested by many
    Rails developers, it's an extremely brittle approach that
    leaves your data vulnerable to many application bugs.  And you'll
    have to consider the fact that most non-trivial apps share a
    database with other applications, so imposing data integrity from
    the Rails app is impossible.

* Enforce foreign-key constraints. While ActiveRecord does not support
them natively, there some great third-party gems like
[schema_plus](https://github.com/lomba/schema_plus) and [foreigner](https://github.com/matthuhiggins/foreigner).

* When writing constructive migrations (adding tables or columns), use
  the new Rails 3.1 way of doing the migrations - use the `change`
  method instead of `up` and `down` methods.


    ```Ruby
    # the old way
    class AddNameToPeople < ActiveRecord::Migration
      def up
        add_column :people, :name, :string
      end

      def down
        remove_column :people, :name
      end
    end

    # the new prefered way
    class AddNameToPeople < ActiveRecord::Migration
      def change
        add_column :people, :name, :string
      end
    end
    ```

* Don't use model classes in migrations. The model classes are
constantly evolving and at some point in the future migrations that
used to work might stop, because of changes in the models used.

## Views

* Never call the model layer directly from a view.
* Never make complex formatting in the views, export the formatting to
  a method in the view helper or the model.
* Mitigate code duplication by using partial templates and layouts.

## Internationalization

* No strings or other locale specific settings should be used in the views,
models and controllers. These texts should be moved to the locale files in
the `config/locales` directory.
* When the labels of an ActiveRecord model need to be translated,
use the `activerecord` scope:

    ```
    en:
      activerecord:
        models:
          user: Member
        attributes:
          user:
            name: "Full name"
    ```

    Then `User.model_name.human` will return "Member" and
    `User.human_attribute_name("name")` will return "Full name". These
    translations of the attributes will be used as labels in the views.

* Separate the texts used in the views from translations of ActiveRecord
attributes. Place the locale files for the models in a folder `models` and
the texts used in the views in folder `views`.
  * When organization of the locale files is done with additional
  directories, these directories must be described in the `application.rb`
  file in order to be loaded.

        ```Ruby
        # config/application.rb
        config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
        ```

* Place the shared localization options, such as date or currency formats, in
files
under
the root of the `locales` directory.
* Use the short form of the I18n methods: `I18n.t` instead of `I18n.translate`
and `I18n.l` instead of `I18n.localize`.
* Use "lazy" lookup for the texts used in views. Let's say we have the
following structure:

    ```
    en:
      users:
        show:
          title: "User details page"
    ```

    The value for `users.show.title` can be looked up in the template
    `app/views/users/show.html.haml` like this:

    ```Ruby
    = t '.title'
    ```

* Use the dot-separated keys in the controllers and models instead of
specifying the `:scope` option. The dot-separated call is easier to read and
trace the hierarchy.

    ```Ruby
    # use this call
    I18n.t 'activerecord.errors.messages.record_invalid'

    # instead of this
    I18n.t :record_invalid, :scope => [:activerecord, :errors, :messages]
    ```

* More detailed information about the Rails i18n can be found in the [Rails
Guides]
(http://guides.rubyonrails.org/i18n.html)

## Assets

Use the [assets pipeline](http://guides.rubyonrails.org/asset_pipeline.html) to leverage organization within
your application.

* Reserve `app/assets` for custom stylesheets, javascripts, or images.
* Use `lib/assets` for your own libraries, that doesn’t really fit into the scope of the application.
* Third party code such as [jQuery](http://jquery.com/) or [bootstrap](http://twitter.github.com/bootstrap/)
  should be placed in `vendor/assets`.
* When possible, use gemified versions of assets (e.g. [jquery-rails](https://github.com/rails/jquery-rails), [jquery-ui-rails](https://github.com/joliss/jquery-ui-rails), [bootstrap-sass](https://github.com/thomas-mcdonald/bootstrap-sass), [zurb-foundation](https://github.com/zurb/foundation)).

## Mailers

* Name the mailers `SomethingMailer`. Without the Mailer suffix it
  isn't immediately apparent what's a mailer and which views are
  related to the mailer.
* Provide both HTML and plain-text view templates.
* Enable errors raised on failed mail delivery in your development environment. The errors are disabled by default.

    ```Ruby
    # config/environments/development.rb

    config.action_mailer.raise_delivery_errors = true
    ```

* Use a local SMTP server like [Mailcatcher](https://github.com/sj26/mailcatcher) in the development environment.

    ```Ruby
    # config/environments/development.rb

    config.action_mailer.smtp_settings = {
      address: 'localhost',
      port: 1025,
      # more settings
    }
    ```

* Provide default settings for the host name.

    ```Ruby
    # config/environments/development.rb
    config.action_mailer.default_url_options = { host: "#{local_ip}:3000" }


    # config/environments/production.rb
    config.action_mailer.default_url_options = { host: 'your_site.com' }

    # in your mailer class
    default_url_options[:host] = 'your_site.com'
    ```

* If you need to use a link to your site in an email, always use the
  `_url`, not `_path` methods. The `_url` methods include the host
  name and the `_path` methods don't.

    ```Ruby
    # wrong
    You can always find more info about this course
    = link_to 'here', url_for(course_path(@course))

    # right
    You can always find more info about this course
    = link_to 'here', url_for(course_url(@course))
    ```

* Format the from and to addresses properly. Use the following format:

    ```Ruby
    # in your mailer class
    default from: 'Your Name <info@your_site.com>'
    ```

* Make sure that the e-mail delivery method for your test environment is set to `test`:

    ```Ruby
    # config/environments/test.rb

    config.action_mailer.delivery_method = :test
    ```

* The delivery method for development and production should be `smtp`:

    ```Ruby
    # config/environments/development.rb, config/environments/production.rb

    config.action_mailer.delivery_method = :smtp
    ```

* When sending html emails all styles should be inline, as some mail clients
  have problems with external styles. This however makes them harder to
  maintain and leads to code duplication. There are two similar gems that
  transform the styles and put them in the corresponding html tags:
  [premailer-rails](https://github.com/fphilipe/premailer-rails) and
  [roadie](https://github.com/Mange/roadie).

* Sending emails while generating page response should be avoided. It causes
  delays in loading of the page and request can timeout if multiple email are
  sent. To overcome this emails can be sent in background process with the help
  of [sidekiq](https://github.com/mperham/sidekiq) gem.

## Bundler

* Put gems used only for development or testing in the appropriate group in the Gemfile.
* Use only established gems in your projects. If you're contemplating
on including some little-known gem you should do a careful review of
its source code first.
* OS-specific gems will by default result in a constantly changing `Gemfile.lock`
for projects with multiple developers using different operating systems.
Add all OS X specific gems to a `darwin` group in the Gemfile, and all Linux
specific gems to a `linux` group:

    ```Ruby
    # Gemfile
    group :darwin do
      gem 'rb-fsevent'
      gem 'growl'
    end

    group :linux do
      gem 'rb-inotify'
    end
    ```

    To require the appropriate gems in the right environment, add the
    following to `config/application.rb`:

    ```Ruby
    platform = RUBY_PLATFORM.match(/(linux|darwin)/)[0].to_sym
    Bundler.require(platform)
    ```

* Do not remove the `Gemfile.lock` from version control. This is not
  some randomly generated file - it makes sure that all of your team
  members get the same gem versions when they do a `bundle install`.

## Priceless Gems

One of the most important programming principles is "Don't reinvent
the wheel!". If you're faced with a certain task you should always
look around a bit for existing solutions, before rolling your
own. Here's a list of some "priceless" gems (all of them Rails 3.1
compliant) that are useful in many Rails projects:

* [active_admin](https://github.com/gregbell/active_admin) - With ActiveAdmin
  the creation of admin interface for your Rails app is child's play. You get a
  nice dashboard, CRUD UI and lots more. Very flexible and customizable.
* [better_errors](https://github.com/charliesome/better_errors) - Better Errors replaces
  the standard Rails error page with a much better and more useful error page. It is also
  usable outside of Rails in any Rack app as Rack middleware.
* [bullet](https://github.com/flyerhzm/bullet) - The Bullet gem is designed to
  help you increase your application’s performance by reducing the number of
  queries it makes. It will watch your queries while you develop your
  application and notify you when you should add eager loading (N+1 queries),
  when you’re using eager loading that isn’t necessary and when you should use
  counter cache.
* [cancan](https://github.com/ryanb/cancan) - CanCan is an authorization gem that
  lets you restrict users access to resources. All permissions are defined in a
  single file (ability.rb) and convenient methods for checking and ensuring
  permissions are available throughout the application.
* [capybara](https://github.com/jnicklas/capybara) - Capybara aims to simplify
  the process of integration testing Rack applications, such as Rails, Sinatra
  or Merb. Capybara simulates how a real user would interact with a web
  application. It is agnostic about the driver running your tests and currently
  comes with Rack::Test and Selenium support built in. HtmlUnit, WebKit and
  env.js are supported through external gems. Works great in combination with
  RSpec & Cucumber.
* [carrierwave](https://github.com/jnicklas/carrierwave) - the ultimate file
  upload solution for Rails. Support both local and cloud storage for the
  uploaded files (and many other cool things). Integrates great with
  ImageMagick for image post-processing.
* [compass-rails](https://github.com/chriseppstein/compass) - Great gem that
  adds support for some css frameworks. Includes collection of sass mixins that
  reduces code of css files and help fight with browser incompatibilities.
* [cucumber-rails](https://github.com/cucumber/cucumber-rails) - Cucumber is
  the premium tool to develop feature tests in Ruby. cucumber-rails provides
  Rails integration for Cucumber.
* [devise](https://github.com/plataformatec/devise) - Devise is full-featured
  authentication solution for Rails applications. In most cases it's preferable
  to use devise to rolling your own custom authentication solution.
* [fabrication](http://fabricationgem.org/) - a great fixture replacement
  (editor's choice).
* [factory_girl](https://github.com/thoughtbot/factory_girl) - an alternative
  to fabrication. Nice and mature fixture replacement. Spiritual ancestor of
  fabrication.
* [ffaker](https://github.com/EmmanuelOga/ffaker) - handy gem to generate dummy data
  (names, addresses, etc).
* [feedzirra](https://github.com/pauldix/feedzirra) - Very fast and flexible
  RSS/Atom feed parser.
* [friendly_id](https://github.com/norman/friendly_id) - Allows creation of
  human-readable URLs by using some descriptive attribute of the model instead
  of its id.
* [globalize](https://github.com/globalize/globalize) - Rails I18n de-facto standard
  library for ActiveRecord model/data translation. Globalize for Rails and is targeted
  at ActiveRecord version 4.x. It is compatible with and builds on the new I18n API in
  Ruby on Rails and adds model translations to ActiveRecord. For ActiveRecord 3.x users,
  check on the [3-0-stable branch](https://github.com/globalize/globalize/tree/3-0-stable).
* [guard](https://github.com/guard/guard) - fantastic gem that monitors file
  changes and invokes tasks based on them. Loaded with lots of useful
  extension. Far superior to autotest and watchr.
* [haml-rails](https://github.com/indirect/haml-rails) - haml-rails provides
  Rails integration for Haml.
* [haml](http://haml-lang.com) - HAML is a concise templating language,
  considered by many (including yours truly) to be far superior to Erb.
* [kaminari](https://github.com/amatsuda/kaminari) - Great paginating solution.
* [machinist](https://github.com/notahat/machinist) - Fixtures aren't fun.
  Machinist is.
* [rspec-rails](https://github.com/rspec/rspec-rails) - RSpec is a replacement
  for Test::MiniTest. I cannot recommend highly enough RSpec. rspec-rails
  provides Rails integration for RSpec.
* [sidekiq](https://github.com/mperham/sidekiq) - Sidekiq is probably
  the easiest and most scalable way to run background jobs in your
  Rails app.
* [simple_form](https://github.com/plataformatec/simple_form) - once you've
  used simple_form (or formtastic) you'll never want to hear about Rails's
  default forms. It has a great DSL for building forms and no opinion on
  markup.
* [simplecov-rcov](https://github.com/fguillen/simplecov-rcov) - RCov formatter
  for SimpleCov. Useful if you're trying to use SimpleCov with the Hudson
  contininous integration server.
* [simplecov](https://github.com/colszowka/simplecov) - code coverage tool.
  Unlike RCov it's fully compatible with Ruby 1.9. Generates great reports.
  Must have!
* [slim](http://slim-lang.com) - Slim is a concise templating language,
  considered by many far superior to HAML (not to mention Erb). The only thing
  stopping me from using Slim massively is the lack of good support in major
  editors/IDEs. Its performance is phenomenal.
* [spork](https://github.com/sporkrb/spork) - A DRb server for testing
  frameworks (RSpec / Cucumber currently) that forks before each run to ensure
  a clean testing state. Simply put it preloads a lot of test environment and
  as consequence the startup time of your tests in greatly decreased. Absolute
  must have!
* [sunspot](https://github.com/sunspot/sunspot) - SOLR powered full-text search
  engine.

This list is not exhaustive and other gems might be added to it along
the road. All of the gems on the list are field tested, have active
development and community and are known to be of good code quality.

## Flawed Gems

This is a list of gems that are either problematic or superseded by
other gems. You should avoid using them in your projects.

* [rmagick](http://rmagick.rubyforge.org/) - this gem is notorious for its memory consumption. Use
[minimagick](https://github.com/probablycorey/mini_magick) instead.
* [autotest](http://www.zenspider.com/ZSS/Products/ZenTest/) - old solution for running tests automatically. Far
inferior to [guard](https://github.com/guard/guard) and [watchr](https://github.com/mynyml/watchr).
* [rcov](https://github.com/relevance/rcov) - code coverage tool, not
  compatible with Ruby 1.9. Use
  [SimpleCov](https://github.com/colszowka/simplecov) instead.
* [therubyracer](https://github.com/cowboyd/therubyracer) - the use of
  this gem in production is strongly discouraged as it uses a very large amount of
  memory. I'd suggest using `node.js` instead.

This list is also a work in progress. Please, let me know if you know
other popular, but flawed gems.

## Managing processes

* If your projects depends on various external processes use
  [foreman](https://github.com/ddollar/foreman) to manage them.

