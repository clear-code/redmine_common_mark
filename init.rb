require "common_mark/formatter"
require "common_mark/helper"
require "common_mark/html_parser"

Redmine.plugin_register :common_mark do
  name "CommonMark plugin"
  author "Kenji Okimoto"
  description "This plugin provides CommonMark notation"
  url "https://github.com/okkez/redmine_common_mark"
  author_url "https://github.com/okkez/redmine_common_mark"
end

Rails.configuration.to_prepare do
  
end

Redmine::WikiFormatting.map do |format|
  format.register :commonmark, CommonMark::Formatter, CommonMark::Helper, CommonMark::HtmlParser
end
