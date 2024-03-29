# Jekyll::Shortener

Jekyll::Shortener is a [Jekyll](https://jekyllrb.com/) generator plugin that creates short URLs for Jekyll pages.  During operation the plugin:

1. Identifies the set of pages for which short URLs should be generated.
2. Checks to see if a short URL has already been generated for the page.
3. If a short URL needs to be generated, uses the configured URL shortener to generate the URL.
4. Populates the short URL in the page front matter with the key "shorturl".  This makes the short URL available for use in Liquid templates.

This plugin supports generating short URLs using external services supported by the [ShortURL](https://github.com/robbyrussell/shorturl) gem, and can also generate short URLs using an internal algorithm shamelesssly stolen from the Perl library [Algorithm-URL-Shorten](http://code.activestate.com/ppm/Algorithm-URL-Shorten/).

The function of this plugin is deliberately kept very simple and focused.  It's up to the site owner how to use these short URLs once they are generated.

## Installation

Add this plugin to your application's Gemfile:

```ruby
group :jekyll_plugins do
  gem "jekyll-shortener", git: "git@github.com:fancypantalons/jekyll-shortener.git"
end
```

And then execute:

    $ bundle

## Configuration

Without any additional configuration this plugin will **not** generate any short URLs.

The following is an example of a basic configuration:

```yaml
shortener:
  method: internal
  shorturl: "http://b-ark.ca"
  collections:
    - posts
```

### Method

The `method` key specifies the URL shortener to use.

The `internal` method instructs the plugin to generate URLs itself.  This setting must be used in conjunction with the `shorturl` key, which specifies the base for URLs generated by the plugin.

**NOTE:** The `internal` method only does the work of calculating a short URL for each page.  A server is still required to redirect browsers from those short URLs to the actual pages, and this work is left as an exercise to the reader.  One specific method is documented below in the section "Static URL shortener with Apache".

The `method` key also takes the name of any URL shorteners supported by the [ShortURL](https://github.com/robbyrussell/shorturl) gem.  For example, the following configuration uses tinyurl:

```yaml
shortener:
  method: tinyurl
  collections:
    - posts
```

### Page selection

The following setting control the pages the plugin selects for shortening:

- `pages` - A boolean setting that, if set to `true`, causes the plugin to generate short URLs for Jekyll pages.
- `collections` - A list of collection names.  The plugin will generate short URLs for the pages in these collections.
- `exclude` - A list of regular expressions.  Pages whose URLs match these regular expressions will **not** have short URLs generated for them.

For example:

```yaml
shortener:
  method: tinyurl
  pages: false
  collections:
    - posts
    - projects
  exclude:
    - ^gallery
```

### Caching

To avoid regenerating URLs for pages unnecessarily, the plugin maintains a cache file named `shortener-cache` in the configured cache directory, which by default is set to `.jekyll-cache`.

You can change the location of the cache file using the `cache_folder` setting.  For example:

```yaml
shortener:
  method: tinyurl
  cache_folder: .cache
  collections:
    - posts
```

Each entry in the cache file includes the URL of the page and the corresponding shortened URL.  If you want to trigger regeneration of some or all URLs, edit or delete this file as appropriate.

# Static URL shortener with Apache

This plugin was inspired by the blog post [Static Site URL Shortener](https://joeyhoer.com/static-site-url-shortener-3c0d454e) by Joey Hoer, as well as his supplied references at the bottom of that post.

In the post he demonstrates how to use Apache's [RewriteMap](https://httpd.apache.org/docs/2.4/rewrite/rewritemap.html) feature to create a simple, self-hosted URL shortener.  The technique is based on building a static mapping file that Apache can use to redirect browsers from a set of short URLs to their full length equivalents.

This plugin enables this technique by generating the short URLs needed to generate the rewrite map.  Assuming the following plugin configuration:

```yaml
shortener:
  method: internal
  shorturl: "http://b-ark.ca"
  collections:
    - posts
```

The plugin will calculate a short URL for each post and stick the result in the `shorturl` front matter property.  Using this property, you can then generate an Apache RewriteMap-compatible file using the following Liquid template:

```
---
---
{% for post in site.posts %}{{ post.shorturl | split: "/" | last }} {{ site.url }}{{ post.url }}
{% endfor %}
```

When the site is built, the plugin will calculate the short URLs, and then Jekyll will produce a mapping file in your configured site directory.  You can then configure Apache to use this mapping file to redirect the short URLs as follows:

```
RewriteMap shorturl "txt:/path/to/shorturls.txt

<Directory /path/to/webroot>
	...
	RewriteEngine on
	RewriteRule ^(.*)$ ${shorturl:$1|http://mysite.com} [R=302,L]
	...
</Directory>
```

# Thanks

* Joey Hoer for his excellent blog post!
* Robby Russell for his URL shortener gem.
* Alessandro Ghedini for his URL shortener Perl library, from which I shamelessly cribbed! 
