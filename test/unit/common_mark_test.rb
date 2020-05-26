# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../../../../test/test_helper', __FILE__)

# This test is copied from Redmine
class Redmine::WikiFormatting::CommonMarkFormatterTest < ActionView::TestCase
  def setup
    @formatter = Redmine::WikiFormatting::CommonMark::Formatter
  end

  def test_syntax_error_in_image_reference_should_not_raise_exception
    assert @formatter.new("!>[](foo.png)").to_html
  end

  def test_empty_image_should_not_raise_exception
    assert @formatter.new("![]()").to_html
  end

  # re-using the formatter after getting above error crashes the
  # ruby interpreter. This seems to be related to
  # https://github.com/vmg/redcarpet/issues/318
  def test_should_not_crash_redcarpet_after_syntax_error
    @formatter.new("!>[](foo.png)").to_html rescue nil
    assert @formatter.new("![](foo.png)").to_html.present?
  end

  def test_inline_style
    assert_equal "<p><strong>foo</strong></p>", @formatter.new("**foo**").to_html.strip
  end

  def test_not_set_intra_emphasis
    assert_equal "<p>foo_bar_baz</p>", @formatter.new("foo_bar_baz").to_html.strip
  end

  def test_wiki_links_should_be_preserved
    text = 'This is a wiki link: [[Foo]]'
    assert_include '[[Foo]]', @formatter.new(text).to_html
  end

  def test_redmine_links_with_double_quotes_should_be_preserved
    text = 'This is a redmine link: version:"1.0"'
    assert_include 'version:"1.0"', @formatter.new(text).to_html
  end

  def test_should_support_syntax_highligth
    text = <<~STR
      ~~~ruby
      def foo
      end
      ~~~
    STR
    assert_select_in @formatter.new(text).to_html, 'pre code.ruby.syntaxhl' do
      assert_select 'span.k', :text => 'def'
    end
  end

  def test_should_not_allow_invalid_language_for_code_blocks
    text = <<~STR
      ~~~foo
      test
      ~~~
    STR
    assert_equal "<pre>test\n</pre>", @formatter.new(text).to_html
  end

  def test_external_links_should_have_external_css_class
    text = 'This is a [link](http://example.net/)'
    assert_equal '<p>This is a <a href="http://example.net/" class="external">link</a></p>', @formatter.new(text).to_html.strip
  end

  def test_locals_links_should_not_have_external_css_class
    text = 'This is a [link](/issues)'
    assert_equal '<p>This is a <a href="/issues">link</a></p>', @formatter.new(text).to_html.strip
  end


  def test_markdown_should_not_require_surrounded_empty_line
    text = <<~STR
      This is a list:
      * One
      * Two
    STR
    assert_equal "<p>This is a list:</p>\n<ul>\n<li>One</li>\n<li>Two</li>\n</ul>", @formatter.new(text).to_html.strip
  end

  def test_footnotes
    text = <<~STR
      This is some text[^1].

      [^1]: This is the foot note
    STR
    expected = <<~EXPECTED
      <p>This is some text<sup class="footnote-ref"><a href="#fn1" id="fnref1">1</a></sup>.</p>
      <section class="footnotes">
      <ol>
      <li id="fn1">
      <p>This is the foot note <a href="#fnref1" class="footnote-backref">↩</a></p>
      </li>
      </ol>
      </section>
    EXPECTED
    with_settings(plugin_common_mark: {"parse_footnotes" => "1"}) do
      assert_equal expected.gsub(%r{[\r\n\t]}, ''), @formatter.new(text).to_html.gsub(%r{[\r\n\t]}, '')
    end
  end

  STR_WITH_PRE = [
    # 0
    <<~STR.chomp,
      # Title

      Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.
    STR
    # 1
    <<~STR.chomp,
      ## Heading 2

      ~~~ruby
        def foo
        end
      ~~~

      Morbi facilisis accumsan orci non pharetra.

      ~~~ ruby
      def foo
      end
      ~~~

      ```
      Pre Content:

      ## Inside pre

      <tag> inside pre block

      Morbi facilisis accumsan orci non pharetra.
      ```
    STR
    # 2
    <<~STR.chomp,
      ### Heading 3

      Nulla nunc nisi, egestas in ornare vel, posuere ac libero.
    STR
  ]

  def test_get_section_should_ignore_pre_content
    text = STR_WITH_PRE.join("\n\n")

    assert_section_with_hash STR_WITH_PRE[1..2].join("\n\n"), text, 2
    assert_section_with_hash STR_WITH_PRE[2], text, 3
  end

  def test_update_section_should_not_escape_pre_content_outside_section
    text = STR_WITH_PRE.join("\n\n")
    replacement = "New text"

    assert_equal [STR_WITH_PRE[0..1], "New text"].flatten.join("\n\n"),
      @formatter.new(text).update_section(3, replacement)
  end

  # Incompatible with Redmine's Markdown.
  def test_should_support_underscored_text
    text = 'This _text_ should be emphasized'
    assert_equal '<p>This <em>text</em> should be emphasized</p>', @formatter.new(text).to_html.strip
  end

  def test_url
    text = 'http://www.example.com: example'
    assert_equal '<p><a href="http://www.example.com" class="external">http://www.example.com</a>: example</p>',
                 @formatter.new(text).to_html.strip
  end

  def test_url_with_multibyte
    text = 'http://www.example.com/ほげ: はげ'
    assert_equal '<p><a href="http://www.example.com/%E3%81%BB%E3%81%92" class="external">http://www.example.com/ほげ</a>: はげ</p>',
                 @formatter.new(text).to_html.strip
  end

  def test_user_with_atmark_in_login
    User.generate!(login: "user@example.com")
    text = 'Hey @user@example.com !'
    assert_equal '<p>Hey @user@example.com !</p>',
                 @formatter.new(text).to_html.strip
  end

  def test_emoji
    text = ':pray: :nonexistent:'
    assert_equal '<p>🙏 :nonexistent:</p>',
                 @formatter.new(text).to_html.strip
  end

  private

  def assert_section_with_hash(expected, text, index)
    result = @formatter.new(text).get_section(index)

    assert_kind_of Array, result
    assert_equal 2, result.size
    assert_equal expected, result.first, "section content did not match"
    assert_equal Digest::MD5.hexdigest(expected), result.last, "section hash did not match"
  end
end
