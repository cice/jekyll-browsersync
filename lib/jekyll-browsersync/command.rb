require 'pty'

module Mlo
  module Jekyll
    module BrowserSync
      class Command < ::Jekyll::Command
        class << self
          DEFAULT_BROWSERSYNC_PATH = 'node_modules/.bin/browser-sync'
          COMMAND_OPTIONS = {
            "https"              => ["--https", "Use HTTPS"],
            "host"               => ["host", "-H", "--host [HOST]", "Host to bind to"],
            "open_url"           => ["-o", "--open-url", "Launch your site in a browser"],
            "port"               => ["-P", "--port [PORT]", "Port to listen on"],
            "show_dir_listing"   => ["--show-dir-listing",
              "Show a directory listing instead of loading your index file."],
            "skip_initial_build" => ["skip_initial_build", "--skip-initial-build",
              "Skips the initial site build which occurs before the server is started."],
            "ui_port"            => ["--ui-port [PORT]",
              "The port for Browsersync UI to run on"],
            "browsersync"        => ["--browser-sync [PATH]",
              "Specify the path to the Browsersync binary if in custom location."],
            "bs_config"          => ["--bs-config [PATH]",
              "Use a bs-config.js file instead of cli args for browser-sync. " +
                "If no PATH is given, a temporary file is generated and deleted on exit. " +
                "If a PATH is given, and the file does not exist, it will be generated."],
          }.freeze

          def init_with_program(prog)
            prog.command("browser-sync") do |cmd|
              cmd.syntax "browser-sync [options]"
              cmd.description 'Serve a Jekyll site using Browsersync.'
              cmd.alias :browsersync
              cmd.alias :bs

              add_build_options(cmd)

              COMMAND_OPTIONS.each do |key, val|
                cmd.option key, *val
              end

              cmd.action do |_, opts|
                opts['serving'] = true
                opts['watch'] = true unless opts.key?('watch')
                opts['incremental'] = true unless opts.key?('incremental')
                opts['port'] = 4000 unless opts.key?('port')
                opts['host'] = '127.0.0.1' unless opts.key?('host')
                opts['ui_port'] = 3001 unless opts.key?('ui_port')
                opts['browsersync'] = locate_browsersync unless opts.key?('browsersync')

                if opts.key?('bs_config')
                  unless opts['bs_config']
                    # Use a random, temporary bs-config file
                    opts['bs_config'] = ".bs-config.#{SecureRandom.hex(10)}.js"
                    opts['bs_config_temporary'] = true
                  end
                  opts['bs_config_generate'] = !File.exists?(opts['bs_config'])
                end

                validate!(opts)

                config = opts['config']
                ::Jekyll::Commands::Build.process(opts)
                opts['config'] = config
                Command.process(opts)
              end
            end
          end

          def process(opts)
            opts = configuration_from_options(opts)
            destination = opts['destination']

            cmd = if opts['bs_config']
              if opts['bs_config_generate']
                generate_config_file(destination, opts)
              end
              get_browsersync_cmd_with_config_file(opts['browsersync'], opts['bs_config'])
            else
              get_browsersync_cmd(destination, opts)
            end

            PTY.spawn(cmd.join(' ')) do |stdout, stdin, pid|
              trap("INT") do
                Process.kill 'INT', pid
                if opts['bs_config_temporary']
                  ::Jekyll.logger.info "Deleting temporary browser-sync config file:", opts['bs_config']
                  File.delete opts['bs_config']
                end
              end

              ::Jekyll.logger.info "Server address:", server_address(opts)
              ::Jekyll.logger.info "UI address:", server_address(opts, 'ui')

              begin
                stdout.each { |line| ::Jekyll.logger.debug line.rstrip }
              rescue
              end
            end
          end

          def generate_config_file(destination, opts)
            config_file = opts['bs_config']

            # Set the default configuration
            options = {
              server: {
                baseDir: destination,
              },
              files: destination,
              port: opts['port'],
              host: opts['host'],
              ui: {
                port: opts['ui_port']
              }
            }

            # Check if there is a base url set, and add a route for it
            base_url = opts['baseurl']
            if base_url && base_url.strip != ''
              options[:server][:routes] = {
                base_url => destination
              }
            end
            options[:https] = true if opts['https']
            options[:open] = opts['open_url'] ? 'local' : false
            options[:server][:directory] = true if opts['show_dir_listing']
            options[:logLevel] = 'debug' if opts['verbose']

            config_js = <<-JS.strip
              module.exports = #{options.to_json};
            JS

            ::Jekyll.logger.info "Generating browser-sync config file:", config_file
            ::Jekyll.logger.debug "Configuration for browser-sync:", options.inspect
            File.write config_file, config_js
          end

          def get_browsersync_cmd_with_config_file(browsersync, config_file)
            [
              browsersync,
              'start',
              "--config #{config_file}",
            ]
          end

          def get_browsersync_cmd(destination, opts)
            cmd = [
              opts['browsersync'],
              'start',
              "--server #{destination}",
              "--files #{destination}",
              "--port #{opts['port']}",
              "--host #{opts['host']}",
              "--ui-port #{opts['ui_port']}",
            ]

            cmd << '--https' if opts['https']
            cmd << '--no-open' unless opts['open_url']
            cmd << '--directory' if opts['show_dir_listing']
            cmd
          end

          private

          def locate_browsersync
            return DEFAULT_BROWSERSYNC_PATH if File.exists?(DEFAULT_BROWSERSYNC_PATH)
            return which('browser-sync')
          end

          # Validate command options
          def validate!(opts)
            browsersync_version = `#{opts['browsersync']} --version 2>/dev/null`

            raise RuntimeError.new('Unable to locate browser-sync binary.') if browsersync_version.empty?
          end

          def server_address(opts, server = nil)
            format("%{protocol}://%{address}:%{port}%{baseurl}", {
              protocol: opts['https'] ? 'https' : 'http',
              address: opts['host'],
              port: server == 'ui' ? opts['ui_port'] : opts['port'],
              baseurl: opts['baseurl'] ? "#{opts["baseurl"]}/" : '',
            })
          end

          # Cross-platform way of finding an executable in the $PATH.
          #
          # See: http://stackoverflow.com/a/5471032/1264736
          #
          #   which('ruby') #=> /usr/bin/ruby
          def which(cmd)
            exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
            ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
              exts.each { |ext|
                exe = File.join(path, "#{cmd}#{ext}")
                return exe if File.executable?(exe) && !File.directory?(exe)
              }
            end
            return nil
          end
        end
      end
    end
  end
end
