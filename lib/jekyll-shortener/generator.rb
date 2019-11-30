# frozen_string_literal: true

module JekyllFeed
  class Generator < Jekyll::Generator
    safe true
    priority :highest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @logger_prefix = "[jekyll-shortener]"

      @methods = {
        "internal" => lambda { |cache, post| get_internal_url(cache, post) }
      }

      ShortURL.valid_services.each do |sym|
        @methods[sym.id2name] = lambda { |cache, post| get_shorturl_url(cache, post, sym) }
      end

      @site = site
      @config = @site.config["shortener"] || {}

      @exclude = ((@config["exclude"] || []) << "^/$").map { |p| Regexp.new(p) }

      method = @config["method"]

      if method.nil?
        return
      elsif @methods[method].nil?
        log("error", "Invalid URL shortening method '#{method}'")

        return
      else
        @methodcb = @methods[method]
      end

      pages = get_page_list(@config["pages"] || false, @config["collections"] || [])

      if pages.length == 0
        log("error", "URL shortener is enabled but no pages are configured for shortening.")

        return
      end

      cache = load_url_cache()

      pages.each do |page|
        shorturl = get_short_url(cache, page)
        page.data["shorturl"] = shorturl
      end

      save_url_cache(cache)
    end

    private

    def log(type, message)
      debug = !!@config.dig("debug")

      if debug || %w(error msg).include?(type)
        type = "info" if type == "msg"

        Jekyll.logger.method(type).call("#{@logger_prefix} #{message}")
      end
    end

    def get_cache_file()
      cache_folder = @site.in_source_dir(@config["cache_folder"] || ".jekyll-cache")
      Dir.mkdir(cache_folder) unless File.exist?(cache_folder)

      file = Jekyll.sanitized_path(cache_folder, "shortener-cache")
      File.open(file, "wb") { |f| f.puts YAML.dump({}) } unless File.exist?(file)

      return file
    end

    def load_url_cache()
      SafeYAML.load_file(get_cache_file()) || {}
    end

    def save_url_cache(cache)
      File.open(get_cache_file(), "wb") { |f| f.puts YAML.dump(cache) }
    end

    def get_page_list(include_pages, collections)
      pages = []

      pages += @site.pages if (include_pages)

      pages += @site
        .collections
        .values
        .find_all { |collection| collections.include? collection.label }
        .map { |collection| collection.docs }
        .flatten

      return pages
        .find_all { |page| @exclude.none? { |regex| regex === page.url }  }
    end

    def get_short_url(cache, page)
      return cache.fetch(page.url) { |url| cache[url] = @methodcb.call(cache, page) }
    end

    def get_internal_url(cache, page)
      chars = [
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
        'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
        'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
        'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F',
        'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
        'W', 'X', 'Y', 'Z', '0', '1', '2', '3',
        '4', '5', '6', '7', '8', '9', '_'
      ]

      # This algorithm is stolen from the Perl library Algorithm-URL-Shorten
      #
      # Credit goes to Alessandro Ghedini!  Thank you!

      digest = Digest::MD5.hexdigest(page.url)

      candidates = digest.split("").each_slice(8).map do |chunk|
        val = chunk.join().to_i(16)

        URI.join(
          @config["shorturl"],
          (0..5).map { c = chars[0x3E & val]; val >>= 5; c }.join()
        ).to_s
      end

      # We get four candidates from the algorithm above, so now we select
      # the first unique option.
      candidates.find { |u| ! cache.key? u }
    end

    def get_shorturl_url(cache, page, service)
      ShortURL.shorten(URI.join(@site.config['url'], page.url).to_s, service)
    end
  end
end
