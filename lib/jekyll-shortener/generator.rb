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

      @site = site
      @config ||= @site.config["shortener"] || {}

      # DO PLUGIN STUFF HERE

      cache = load_url_cache()

      get_page_list().each do |page|
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

    def get_page_list()
      @site.posts.docs
    end

    def get_short_url(cache, page)
      return cache.fetch(page.id) { |id| cache[id] = @methods[@config["method"]].call(cache, page) }
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

      digest = Digest::MD5.hexdigest(page.id)

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
  end
end
