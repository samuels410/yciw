# config valid only for current version of Capistrano
lock '3.11.0'

set :application,   'yciw'
set :deploy_to,     '/var/deploy/capistrano/yciw'
set :scm,     :git
set :repo_url, 'https://github.com/samuels410/yciw.git'

set :user,    'sysadmin'
set :passenger_user, 'www-data'
set :use_sudo,      true
set :passenger_restart_with_sudo, true
set :pty, true

set :keep_releases, 5
set :bundle_flags, '--without=sqlite mysql --binstubs'

set :linked_dirs, %w{log tmp public/lesson}
set :linked_files, %w{config/database.yml config/delayed_jobs.yml config/cache_store.yml
                      config/logging.yml config/security.yml config/domain.yml
                      config/outgoing_mail.yml config/file_store.yml config/redis.yml
                     }

#db:migrate will be executed only when there is new migration file(s) in the db/migrate folder.
set :conditionally_migrate, true

set :passenger_restart_with_touch, true

#Custom hooks in the deployment steps.
before 'bundler:install', 'canvas:clone_analytics_gem'
after 'deploy:migrate', 'canvas:handle_compile_assets'
after 'passenger:restart', 'canvas:reload_delayed_jobs'
before 'deploy:cleanup', 'canvas:cleanup_permissions'

## Canavs-specific tasks
namespace :canvas do

  desc 'Clone analytics gem'
  task :clone_analytics_gem do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute "git clone -b stable https://github.com/instructure/analytics.git #{release_path}/gems/plugins/analytics"
        end
      end
    end
  end


  desc "Compile static assets"
  task :compile_assets do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute "sudo chown #{fetch(:passenger_user)}:#{fetch(:user)} #{shared_path}/log/#{fetch(:stage)}.log"
          execute "sudo chmod 664 #{shared_path}/log/#{fetch(:stage)}.log"
          #  execute "cd #{release_path} && npm install"
          execute "cd #{release_path} && RAILS_ENV=#{fetch(:stage)} bundle exec rake canvas:compile_assets"
        end
      end
    end
  end

  desc "Load new notification types"
  task :load_notifications do
    on roles(:delayed_job) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute "cd #{release_path} && RAILS_ENV=#{fetch(:stage)} bundle exec rake db:load_notifications"
        end
      end
    end
  end

  #RAILS_ENV has been commented in the canvas_init to make it work with all environments.
  desc "Restarted delayed jobs workers - with passenger_user"
  task :restart_jobs  do
    on roles(:delayed_job) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          begin
            execute "cd #{release_path} && touch tmp/restart.txt"
            execute "sudo -u #{fetch(:passenger_user)} -- sh -c 'export RAILS_ENV=#{fetch(:stage)}; /etc/init.d/canvas_init restart'"
          rescue Exception => error
            puts "canvas_init restart failed: " + error
          end
        end
      end
    end
  end

  desc "Generate Brand Configs css"
  task :generate_brandconfigs do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute "cd #{release_path} && RAILS_ENV=#{fetch(:stage)} bundle exec rake brand_configs:generate_and_upload_all"
        end
      end
    end
  end

  desc "Stop web server nginx"
  task :stop_nginx do
    on roles(:app) do
      begin
        execute "sudo service nginx stop"
      rescue Exception => error
        puts "nginx stop fails: " + error
      end

    end
  end

  desc "Start web server nginx"
  task :start_nginx do
    on roles(:app) do
      begin
        execute "sudo service nginx start"
      rescue Exception => error
        puts "nginx start fails: " + error
      end
    end
  end


  desc "change permission to passenger_user "
  task :canvasuser_permission do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          sudo "mkdir -p #{current_path}/log"
          sudo "mkdir -p #{current_path}/tmp/pids"
          sudo "mkdir -p #{current_path}/public/assets"
          sudo "mkdir -p #{current_path}/public/stylesheets/compiled"
          sudo "touch Gemfile.lock"

          sudo "chown #{fetch(:passenger_user)} #{current_path}/config/environment.rb"
          sudo "chown #{fetch(:passenger_user)} #{current_path}/Gemfile.lock"
          sudo "chown #{fetch(:passenger_user)} #{current_path}/config.ru"

          sudo "chown -R #{fetch(:passenger_user)} #{current_path}/log"
          sudo "chown -R #{fetch(:passenger_user)} #{current_path}/public"
          sudo "chown -R #{fetch(:passenger_user)} #{current_path}/public/assets"
          sudo "chown -R #{fetch(:passenger_user)} #{current_path}/public/stylesheets/compiled"
          sudo "chown -R #{fetch(:passenger_user)} #{current_path}/app"
          sudo "chown -R #{fetch(:passenger_user)}:#{fetch(:user)} #{release_path}/tmp/"

          sudo "chmod 777 -R #{release_path}/tmp/cache"
        end
      end
    end
  end

  desc "Clone QTIMigrationTool"
  task :clone_qtimigrationtool do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          sudo "mkdir -p -m 777 #{release_path}/vendor"
          execute "cd #{release_path}/vendor && git clone https://github.com/instructure/QTIMigrationTool.git QTIMigrationTool && chmod +x QTIMigrationTool/migrate.py"
        end
      end
    end
  end


  desc "Tasks that run after the deploy completes"
  task :handle_compile_assets do
    invoke 'canvas:clone_qtimigrationtool'
    invoke 'canvas:compile_assets'
    invoke 'canvas:generate_brandconfigs'
    invoke 'canvas:canvasuser_permission'
  end

  desc "Tasks which loads notification and restarts delayed_job"
  task :reload_delayed_jobs do
    invoke 'canvas:load_notifications'
    invoke 'canvas:restart_jobs'
  end


  desc 'Set permissions on old releases before cleanup'
  task :cleanup_permissions do
    on release_roles :all do |host|
      releases = capture(:ls, '-x', releases_path).split
      if releases.count >= fetch(:keep_releases)
        info "Cleaning permissions on old releases"
        directories = (releases - releases.last(1))
        if directories.any?
          directories.each do |release|
            within releases_path.join(release) do
              execute :sudo, :chown, '-R', fetch(:user), '.'
            end
          end
        else
          info t(:no_old_releases, host: host.to_s, keep_releases: fetch(:keep_releases))
        end
      end
    end
  end

end

#Monit tasks
namespace :monit do
  task :start do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          sudo 'monit'
        end
      end
    end
  end

  task :stop do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: "#{fetch(:stage)}" do
          sudo 'monit quit'
        end
      end
    end
  end
end
