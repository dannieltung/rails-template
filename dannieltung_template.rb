run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
########################################
inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem "bootstrap", "~> 5.2"
    gem "devise"
    gem "autoprefixer-rails"
    gem "font-awesome-sass", "~> 6.1"
    gem "simple_form", github: "heartcombo/simple_form"
    gem "sassc-rails"
  RUBY
end

inject_into_file "Gemfile", after: "group :development, :test do" do
  "\n  gem \"dotenv-rails\""
end

# Assets
########################################
run "rm -rf app/assets/stylesheets"
run "rm -rf vendor"
run "curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip && rm -f app/assets/rails-stylesheets-master/README.md"
run "mv app/assets/rails-stylesheets-master app/assets/stylesheets"

# Layout
########################################
gsub_file(
  "app/views/layouts/application.html.erb",
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">'
)

# Flashes
########################################
file "app/views/shared/_flashes.html.erb", <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
      <%= notice %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close">
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="btn-close" data-bs-dismiss="alert, aria-label="Close">
      </button>
    </div>
  <% end %>
HTML

run "curl -L https://raw.githubusercontent.com/lewagon/awesome-navbars/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb"

inject_into_file "app/views/layouts/application.html.erb", after: "<body>" do
  <<~HTML
    <%= render "shared/navbar" %>
    <%= render "shared/flashes" %>
  HTML
end

# README
########################################
markdown_file_content = <<~MARKDOWN
  Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
MARKDOWN
file "README.md", markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

# General Config
########################################
general_config = <<~RUBY
  config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"
RUBY

environment general_config

# After bundle
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command "db:drop db:create db:migrate"
  generate("simple_form:install")
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")

  # Routes
  ########################################
  route 'root to: "pages#home"'

  # Gitignore
  ########################################
  append_file ".gitignore", <<~TXT
    # Ignore .env file containing credentials.
    .env*

    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate("devise:install")
  generate("devise", "User")

  # Application controller
  ########################################
  run "rm app/controllers/application_controller.rb"
  file "app/controllers/application_controller.rb", <<~RUBY
    class ApplicationController < ActionController::Base
      before_action :authenticate_user!
    end
  RUBY

  # Migrate + devise views
  ########################################
  rails_command "db:migrate"
  generate("devise:views")

  # Pages Controller
  ########################################
  run "rm app/controllers/pages_controller.rb"
  file "app/controllers/pages_controller.rb", <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home ]

      def home
      end
    end
  RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: "development"
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: "production"

  # Bootstrap & Popper
  ########################################
  append_file "config/importmap.rb", <<~RUBY
    pin "bootstrap", to: "bootstrap.min.js", preload: true
    pin "@popperjs/core", to: "popper.js", preload: true
  RUBY

  append_file "config/initializers/assets.rb", <<~RUBY
    Rails.application.config.assets.precompile += %w(bootstrap.min.js popper.js)
  RUBY

  append_file "app/javascript/application.js", <<~JS
    import "@popperjs/core"
    import "bootstrap"
  JS

  append_file "app/assets/config/manifest.js", <<~JS
    //= link popper.js
    //= link bootstrap.min.js
  JS

  # Heroku
  ########################################
  run "bundle lock --add-platform x86_64-linux"

  # Dotenv
  ########################################
  run "touch '.env'"

  # Rubocop
  ########################################
  run "curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml"

  # Modify config/initializers/assets.rb
  ########################################
  file 'config/initializers/assets.rb', force: true do
    <<~RUBY
      Rails.application.config.assets.version = "1.0"
      Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
      Rails.application.config.assets.precompile += %w( .svg .eot .woff .ttf)
      Rails.application.config.assets.paths << Rails.root.join("node_modules")
    RUBY
  end

  # Download and setup fonts
  ########################################
  run "mkdir -p app/assets/fonts"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/DMSans-Bold.ttf -o app/assets/fonts/DMSans-Bold.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/NotoSans-Regular.ttf -o app/assets/fonts/NotoSans-Regular.ttf"

  # Roboto font family
  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Black.ttf -o app/assets/fonts/Roboto-Black.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-BlackItalic.ttf -o app/assets/fonts/Roboto-BlackItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Bold.ttf -o app/assets/fonts/Roboto-Bold.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-BoldItalic.ttf -o app/assets/fonts/Roboto-BoldItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Italic.ttf -o app/assets/fonts/Roboto-Italic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Light.ttf -o app/assets/fonts/Roboto-Light.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-LightItalic.ttf -o app/assets/fonts/Roboto-LightItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Medium.ttf -o app/assets/fonts/Roboto-Medium.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-MediumItalic.ttf -o app/assets/fonts/Roboto-MediumItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Regular.ttf -o app/assets/fonts/Roboto-Regular.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-Thin.ttf -o app/assets/fonts/Roboto-Thin.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Roboto-ThinItalic.ttf -o app/assets/fonts/Roboto-ThinItalic.ttf"

  # Rubik font family
  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Black.ttf -o app/assets/fonts/Rubik-Black.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-BlackItalic.ttf -o app/assets/fonts/Rubik-BlackItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Bold.ttf -o app/assets/fonts/Rubik-Bold.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-BoldItalic.ttf -o app/assets/fonts/Rubik-BoldItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-ExtraBold.ttf -o app/assets/fonts/Rubik-ExtraBold.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-ExtraBoldItalic.ttf -o app/assets/fonts/Rubik-ExtraBoldItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Italic-VariableFont_wght.ttf -o app/assets/fonts/Rubik-Italic-VariableFont_wght.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Italic.ttf -o app/assets/fonts/Rubik-Italic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Light.ttf -o app/assets/fonts/Rubik-Light.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-LightItalic.ttf -o app/assets/fonts/Rubik-LightItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Medium.ttf -o app/assets/fonts/Rubik-Medium.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-MediumItalic.ttf -o app/assets/fonts/Rubik-MediumItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-Regular.ttf -o app/assets/fonts/Rubik-Regular.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-SemiBold.ttf -o app/assets/fonts/Rubik-SemiBold.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-SemiBoldItalic.ttf -o app/assets/fonts/Rubik-SemiBoldItalic.ttf"

  run "curl -L https://raw.githubusercontent.com/dannieltung/rails-template/master/app/assets/fonts/Rubik-VariableFont_wght.ttf -o app/assets/fonts/Rubik-VariableFont_wght.ttf"

  # Git
  ########################################
  git :init
  git add: "."
  git commit: "-m 'Initial commit with devise template from https://github.com/lewagon/rails-templates and some customizations'"

  # Get the current branch name and rename it to 'main'
  current_branch = `git branch --show-current`.strip
  default_branch =  `git config --global init.defaultBranch`.strip
  default_branch = "master" if default_branch.empty?

  if current_branch != "main" && default_branch != "main"
    run "git branch -m #{current_branch} main"
  end

  # Create or replace custom _colors.scss in the stylesheets/config directory
  file 'app/assets/stylesheets/config/_colors.scss', force: true do
    <<~SCSS
      $amarelo-0: #fffae4;
      $amarelo-100: #fff3c3;
      $amarelo-200: #ffe88a;
      $amarelo-300: #ffdb4c;
      $amarelo-400: #ffcc00;
      $amarelo-500: #e0b300;
      $blue: #0d6efd;
      $gray: #0e0000;
      $gray-2: #4f4f4f;
      $green: #016340;
      $light-gray: #f4f4f4;
      $neutro-0: #fcfdff;
      $neutro-100: #f7f8fb;
      $neutro-200: #e8eaee;
      $neutro-300: #cfd1d6;
      $neutro-400: #abadb1;
      $neutro-500: #7f8084;
      $neutro-600: #505153;
      $neutro-700: #222324;
      $orange: #e67e22;
      $red: #fd1015;
      $roxo-0: #eae7f9;
      $roxo-100: #bbaff9;
      $roxo-200: #6e52ff;
      $roxo-300: #4728e3;
      $roxo-400: #1b00a3;
      $roxo-500: #0b0042;
      $state-green: #219653;
      $state-red: #c92121;
      $yellow: #ffc65a;
    SCSS
  end

  # Ensure the application.scss imports the custom colors
  inject_into_file 'app/assets/stylesheets/application.scss', before: '*/' do
    "@import 'config/colors';\n"
  end

  # Create or replace custom _fonts.scss in the stylesheets/config directory
  file 'app/assets/stylesheets/config/_fonts.scss', force: true do
    <<~SCSS
      // Import Google fonts
      @import url("https://fonts.googleapis.com/css?family=Nunito:400,700|Work+Sans:400,700&display=swap");

      // To use a font file
      @font-face {
        font-family: "Roboto";
        src: font-url("Roboto-Regular.ttf") format("truetype");
        font-weight: normal;
        font-style: normal;
      }

      @font-face {
        font-family: "Roboto";
        src: font-url("Roboto-Bold.ttf") format("truetype");
        font-weight: bold;
        font-style: normal;
      }

      @font-face {
        font-family: "Rubik";
        src: font-url("Rubik-Medium.ttf") format("truetype");
        font-weight: 500;
        font-style: normal;
      }

      @font-face {
        font-family: "Rubik";
        src: font-url("Rubik-Regular.ttf") format("truetype");
        font-weight: 400; // Regular weight
        font-style: normal;
      }

      @font-face {
        font-family: "DM Sans";
        src: url("DMSans-Bold.ttf") format("truetype");
        font-weight: 700;
        font-style: normal;
      }

      @font-face {
        font-family: "Noto Sans";
        src: url("NotoSans-Regular.ttf") format("truetype");
        font-weight: 300;
        font-style: normal;
      }

      // Define fonts for body and headers
      $body-font: "Rubik", "Roboto", "Helvetica", "sans-serif";
      $headers-font: "Rubik", "Roboto", "Helvetica", "sans-serif";
    SCSS
  end

  # Ensure the application.scss imports the custom fonts
  inject_into_file 'app/assets/stylesheets/application.scss', before: '*/' do
    "@import 'config/fonts';\n"
  end

  # Create or ensure the components director exists
  run "mkdir -p app/assets/stylesheets/components"

  # Create the _default_btn.scss file with some default button styles
  file 'app/assets/stylesheets/components/_default_btn.scss', force: true do
    <<~SCSS
      .default-btn {
        /* Appearance */
        border-radius: 8px;
        cursor: pointer;
        border: 1px solid $roxo-300;
        background-color: $roxo-300;
        color: $neutro-0;

        /* Sizing and Layout */
        width: 100%;
        height: 45px;
        padding: 10px 8px;
        display: flex; /* Enable flexbox for centering */
        justify-content: center;
        align-items: center;
        flex-shrink: 0; /* Prevent shrinking */

        /* Typography */
        font-size: 14px;
        font-weight: 500;
        line-height: 16px; /* 114.286% */
        text-align: center;
        text-transform: uppercase;
        font-feature-settings: "liga" off, "clig" off;

        /* Disabled State */
        &.disabled,
        &[disabled] {
          border: 1px solid $roxo-100;
          background-color: $roxo-100;
          color: $roxo-0;
          cursor: default; /* Update cursor for disabled state */
        }
      }
    SCSS
  end

  # Append the import statement to the existing components/_index.scss
  append_to_file 'app/assets/stylesheets/components/_index.scss', "\n@import 'default_btn';\n"
end
