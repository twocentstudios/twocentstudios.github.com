# Title: Simple Image tag for Jekyll
# Author: Brandon Mathis http://brandonmathis.com
# Description: Easily output images with optional class names and title/alt attributes
#
# Syntax {% image [class name(s)] url [title text] %}
#
# Example:
# {% caption_img left half http://site.com/images/ninja.png Ninja Attack! %}
#
# Output:
# <image class='left' src="http://site.com/images/ninja.png" title="Ninja Attack!" alt="Ninja Attack!">
#

module Jekyll

  class CaptionImageTag < Liquid::Tag
    @img = nil
    @title = nil
    @class = 'caption'
    @width = ''
    @height = ''

    def initialize(tag_name, markup, tokens)
      if markup =~ /(\S.*\s+)?(https?:\/\/|\/)(\S+)(\s+\d+\s+\d+)?(\s+.+)?/i
        @class = $1 || 'caption'
        @img = $2 + $3
        if $5
          @title = $5.strip
        end
        if $4 =~ /\s*(\d+)\s+(\d+)/
          @width = $1
          @height = $2
        end
      end
      super
    end

    def render(context)
      output = super
      if @img
        "<div class='caption-wrapper'>" +
          "<img class='#{@class.rstrip}' src='#{@img}' width='#{@width}' height='#{@height}' alt='#{@title}' title='#{@title}'>" +
          "<div class='caption-text'>#{@title}</div>" +
        "</div>"
      else
        "Error processing input, expected syntax: {% img [class name(s)] /url/to/image [width height] [title text] %}"
      end
    end
  end
end

Liquid::Template.register_tag('caption_img', Jekyll::CaptionImageTag)