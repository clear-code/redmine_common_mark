require "redmine/wiki_formatting/common_mark/formatter"
require "redmine/wiki_formatting/common_mark/helper"
require "redmine/wiki_formatting/common_mark/html_parser"

Redmine::Plugin.register :common_mark do
  name "CommonMark plugin"
  version "0.3.0"
  author "Kenji Okimoto"
  description "This plugin provides CommonMark notation"
  url "https://github.com/okkez/redmine_common_mark"
  author_url "https://github.com/okkez/redmine_common_mark"
  settings default: {
             parse_validate_utf8: "0",
             parse_smart: "0",
             parse_liberal_html_tag: "0",
             parse_footnotes: "0",
             parse_strikethrough_double_tilde: "0",
             render_sourcepos: "0",
             render_hardbreaks: "1",
             render_unsafe: "0",
             render_nobreaks: "0",
             render_github_pre_lang: "0",
             render_table_prefer_style_attributes: "0",
             render_full_info_string: "0",
             extension_table: "1",
             extension_strikethrough: "1",
             extension_autolink: "1",
             extension_tagfilter: "1"
           }, partial: "settings/common_mark"
end

Redmine::WikiFormatting.map do |format|
  format.register :commonmark,
                  Redmine::WikiFormatting::CommonMark::Formatter,
                  Redmine::WikiFormatting::CommonMark::Helper,
                  Redmine::WikiFormatting::CommonMark::HtmlParser,
                  label: "CommonMark"
end
