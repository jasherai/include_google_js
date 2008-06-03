module IncludeGoogleJs
  
  @@javascript_expansions = { :defaults => ActionView::Helpers::AssetTagHelper::JAVASCRIPT_DEFAULT_SOURCES.dup }
  
  module Config
    mattr_accessor :include_google_js
  end
  
  IncludeGoogleJs::Config.include_google_js ||= true
  
  def self.included(base) 
    alias_method_chain :javascript_include_tag, :google_js
    alias_method_chain :expand_javascript_sources, :google_js
  end
  
  def javascript_include_tag_with_google_js(*sources)
    options = sources.extract_options!.stringify_keys
    cache   = options.delete("cache")

    if ActionController::Base.perform_caching && cache
      joined_javascript_name = (cache == true ? "all" : cache) + ".js"
      joined_javascript_path = File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, joined_javascript_name)

      write_asset_file_contents(joined_javascript_path, compute_javascript_paths(sources))
      javascript_src_tag(joined_javascript_name, options)
    else
      html = expand_javascript_sources(sources).collect { |source| javascript_src_tag(source, options) }.join("\n")
      html = %Q{
        <script src='http://www.google.com/jsapi'></script>
        <script>
          google.load("prototype", "1");
          google.load("scriptaculous", "1");
        </script>
        #{html}
        } if IncludeGoogleJs::Config.include_google_js && (sources.include?(:defaults) || sources.include?(:all))
        return html
    end
  end

  def expand_javascript_sources_with_google_js(sources)
    if sources.include?(:all)
      all_javascript_files = Dir[File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, '*.js')].collect { |file| File.basename(file).gsub(/\.\w+$/, '') }.sort
      if IncludeGoogleJs::Config.include_google_js
        ActionView::Helpers::AssetTagHelper::JAVASCRIPT_DEFAULT_SOURCES.each do |file|
          all_javascript_files.delete(file)
        end
      end
      @@all_javascript_sources ||= ((determine_source(:defaults, @@javascript_expansions).dup & all_javascript_files) + all_javascript_files).uniq
    else
      expanded_sources = []
      expanded_sources = sources.collect do |source|
        determine_source(source, @@javascript_expansions)
      end.flatten unless IncludeGoogleJs::Config.include_google_js && sources.include?(:defaults)
      expanded_sources << "application" if sources.include?(:defaults) && file_exist?(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "application.js"))
      expanded_sources
    end
  end
end