require "cgi/util"
require "commonmarker"

module Redmine
  module WikiFormatting
    module CommonMark
      class HTML < CommonMarker::HtmlRenderer
        include ActionView::Helpers::TagHelper
        include Redmine::Helpers::URL

        def link(node)
          return unless uri_with_safe_scheme?(node.url)

          out('<a href="', node.url.nil? ? '' : escape_href(node.url), '"')
          if node.title && !node.title.empty?
            out(' title="', escape_html(node.title), '"')
          end
          unless node.url && node.url.start_with?("/")
            out(' class="external"')
          end
          out('>', :children, '</a>')
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

        # Copy from Redmine::Helpers::URL
        # Make robust.
        # This monkey patch can be removed after merge http://www.redmine.org/issues/27114
        def uri_with_safe_scheme?(uri, schemes = ['http', 'https', 'ftp', 'mailto', nil])
          # URLs relative to the current document or document root (without a protocol
          # separator, should be harmless
          return true unless uri.to_s.include? ":"

          # Other URLs need to be parsed
          schemes.include? URI.parse(uri).scheme
        rescue URI::Error
          false
        end
      end

      class Formatter < Redmine::WikiFormatting::Markdown::Formatter
        private

        def formatter
          @@formater = Redmine::WikiFormatting::CommonMark::FormatterWrapper.new
        end
      end

      class FormatterWrapper
        EXTENSIONS = %i[autolink table strikethrough]

        def initialize
          @renderer = Redmine::WikiFormatting::CommonMark::HTML.new(
            options: %i[DEFAULT HARDBREAKS],
            extensions: EXTENSIONS
          )
        end

        def render(text)
          doc = CommonMarker.render_doc(text, :DEFAULT, EXTENSIONS)
          @renderer.render(doc)
        end
      end
    end
  end
end
