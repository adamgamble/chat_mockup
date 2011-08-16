require "action_view"

module Sprockets
  module Helpers
    module RailsHelper
      extend ActiveSupport::Concern
      include ActionView::Helpers::AssetTagHelper

      def asset_paths
        @asset_paths ||= begin
          config     = self.config if respond_to?(:config)
          config   ||= Rails.application.config
          controller = self.controller if respond_to?(:controller)
          paths = RailsHelper::AssetPaths.new(config, controller)
          paths.asset_environment = asset_environment
          paths.asset_prefix      = asset_prefix
          paths
        end
      end

      def javascript_include_tag(*sources)
        options = sources.extract_options!
        debug = options.key?(:debug) ? options.delete(:debug) : debug_assets?
        body  = options.key?(:body)  ? options.delete(:body)  : false

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'js')
            asset.to_a.map { |dep|
              javascript_include_tag(dep, :debug => false, :body => true)
            }.join("\n").html_safe
          else
            tag_options = {
              'type' => "text/javascript",
              'src'  => asset_path(source, 'js', body)
            }.merge(options.stringify_keys)

            content_tag 'script', "", tag_options
          end
        end.join("\n").html_safe
      end

      def stylesheet_link_tag(*sources)
        options = sources.extract_options!
        debug = options.key?(:debug) ? options.delete(:debug) : debug_assets?
        body  = options.key?(:body)  ? options.delete(:body)  : false

        sources.collect do |source|
          if debug && asset = asset_paths.asset_for(source, 'css')
            asset.to_a.map { |dep|
              stylesheet_link_tag(dep, :debug => false, :body => true)
            }.join("\n").html_safe
          else
            tag_options = {
              'rel'   => "stylesheet",
              'type'  => "text/css",
              'media' => "screen",
              'href'  => asset_path(source, 'css', body, :request)
            }.merge(options.stringify_keys)

            tag 'link', tag_options
          end
        end.join("\n").html_safe
      end

      def asset_path(source, default_ext = nil, body = false, protocol = nil)
        source = source.logical_path if source.respond_to?(:logical_path)
        path = asset_paths.compute_public_path(source, 'assets', default_ext, true, protocol)
        body ? "#{path}?body=1" : path
      end

    private
      def debug_assets?
        params[:debug_assets] == '1' ||
          params[:debug_assets] == 'true'
      rescue NoMethodError
        false
      end

      # Override to specify an alternative prefix for asset path generation.
      # When combined with a custom +asset_environment+, this can be used to
      # implement themes that can take advantage of the asset pipeline.
      #
      # If you only want to change where the assets are mounted, refer to
      # +config.assets.prefix+ instead.
      def asset_prefix
        Rails.application.config.assets.prefix
      end

      # Override to specify an alternative asset environment for asset
      # path generation. The environment should already have been mounted
      # at the prefix returned by +asset_prefix+.
      def asset_environment
        Rails.application.assets
      end

      class AssetPaths < ::ActionView::AssetPaths #:nodoc:
        attr_accessor :asset_environment, :asset_prefix

        def compute_public_path(source, dir, ext=nil, include_host=true, protocol=nil)
          super(source, asset_prefix, ext, include_host, protocol)
        end

        # Return the filesystem path for the source
        def compute_source_path(source, ext)
          asset_for(source, ext)
        end

        def asset_for(source, ext)
          source = source.to_s
          return nil if is_uri?(source)
          source = rewrite_extension(source, nil, ext)
          asset_environment[source]
        end

        def rewrite_asset_path(source, dir)
          if source[0] == ?/
            source
          else
            asset_environment.path(source, performing_caching?, dir)
          end
        end

        def rewrite_extension(source, dir, ext)
          if ext && File.extname(source).empty?
            "#{source}.#{ext}"
          else
            source
          end
        end

        # When included in Sprockets::Context, we need to ask the top-level config as the controller is not available
        def performing_caching?
          config.action_controller.present? ? config.action_controller.perform_caching : config.perform_caching
        end
      end
    end
  end
end
