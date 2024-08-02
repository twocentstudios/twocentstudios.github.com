module Jekyll
    class TagPageGenerator < Generator
      safe true
  
      def generate(site)
        site.tags.each do |tag, posts|
          tag_dir = File.join('blog/tags', tag.downcase.gsub(' ', '-'))
          site.pages << TagPage.new(site, site.source, tag_dir, tag, posts)
          site.pages << TagFeed.new(site, site.source, tag_dir, tag, posts)
        end
      end
    end
  
    class TagPage < Page
      def initialize(site, base, dir, tag, posts)
        @site = site
        @base = base
        @dir = dir
        @name = "index.html"
  
        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'tag.html')
        self.data['tag'] = tag
        self.data['title'] = "Posts tagged with #{tag}"
      end
    end

    class TagFeed < Page
      def initialize(site, base, dir, tag, posts)
        @site = site
        @base = base
        @dir = dir
        @name = "feed.xml"

        self.process(@name)
        self.read_yaml(File.join(base, '_layouts'), 'tag-feed.xml')
        self.data['tag'] = tag
        self.data['dir'] = dir
      end
    end
  end