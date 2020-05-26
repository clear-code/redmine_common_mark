require "cgi/util"
require "commonmarker"

module Redmine
  module WikiFormatting
    module CommonMark
      class HTML < CommonMarker::HtmlRenderer
        include ActionView::Helpers::TagHelper
        include Redmine::Helpers::URL

        def link(node)
          url = escape_href(node.url)
          return unless uri_with_safe_scheme?(url)

          if url && url.start_with?("mailto:")
            out('<a href="', url, '"', '>', :children, '</a>')
          else
            out('<a href="', url.nil? ? '' : url, '"')
            if node.title && !node.title.empty?
              out(' title="', escape_html(node.title), '"')
            end
            unless url && url.start_with?("/")
              out(' class="external"')
            end
            out('>', :children, '</a>')
          end
        end

        def code_block(node)
          language = if node.fence_info && !node.fence_info.empty?
                       node.fence_info.split(/\s+/)[0]
                     else
                       nil
                     end
          source = node.string_content
          html = if language.present? && Redmine::SyntaxHighlighting.language_supported?(language)
                   "<pre><code class=\"#{escape_html(language)} syntaxhl\">" +
                     Redmine::SyntaxHighlighting.highlight_by_language(source, language) +
                     "</code></pre>"
                 else
                   "<pre>" + escape_html(source) + "</pre>"
                 end
          out(html)
        end

        def image(node)
          out('<img src="', escape_href(node.url), '"')
          plain do
            out(' alt="', :children, '"')
          end
          if node.title && !node.title.empty?
            out(' title="', escape_html(node.title), '"')
          end
          out('>')
        end
      end

      class Formatter < Redmine::WikiFormatting::Markdown::Formatter
        private

        def formatter
          @@formater = Redmine::WikiFormatting::CommonMark::FormatterWrapper.new
        end
      end

      class FormatterWrapper
        def initialize
          @renderer = Redmine::WikiFormatting::CommonMark::HTML.new(
            options: render_options,
            extensions: extensions
          )
        end

        def render(text)
          doc = CommonMarker.render_doc(text, parse_options, extensions)
          @renderer.render(doc)
        end

        private

        def settings
          settings = ActiveSupport::HashWithIndifferentAccess.new(Redmine::Plugin.find(:common_mark).settings[:default])
          settings.merge(Setting.plugin_common_mark.presence || {})
        end

        def parse_options
          options = CommonMarker::Config::Parse.keys.select do |key|
            name = "parse_#{key.to_s.downcase}"
            settings[name] == "1"
          end
          options.presence || [:DEFAULT]
        end

        def render_options
          options = CommonMarker::Config::Render.keys.select do |key|
            name = "render_#{key.to_s.downcase}"
            settings[name] == "1"
          end
          options.presence || [:DEFAULT]
        end

        def extensions
          CommonMarker.extensions.select do |extension|
            name = "extension_#{extension}"
            settings[name] == "1"
          end.map(&:to_sym)
        end
      end
    end
  end
end
