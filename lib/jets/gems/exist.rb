require 'open-uri'

module Jets::Gems
  class Exist
    def initialize(options)
      @options = options
    end

    # We check all the availability before even downloading so we can provide a
    # full list of gems they might want to research all at once instead of incrementally
    #
    # Examples:
    #
    #   check(single_gem)
    #   check(list, of, gems)
    def check(*gem_names)
      gem_names = gem_names.flatten
      exists = gem_names.inject({}) do |hash, gem_name|
        exist = url_exists?(gem_url(gem_name))
        hash[gem_name] = exist
        hash.merge(hash)
      end

      exists.values.all? {|v| v } # all_exist
    end

    # Example url:
    #   https://gems2.lambdagems.com/gems/2.5.0/byebug/byebug-9.1.0.zip
    def url_exists?(url)
      url = URI.parse(url)
      req = Net::HTTP.new(url.host, url.port).tap do |http|
        http.use_ssl = true
      end
      res = req.request_head(url.path)
      res.code == "200"
    rescue SocketError, OpenURI::HTTPError, OpenSSL::SSL::SSLError
      false
    end

    def source_url
      @options[:source_url] || s3_url
    end

    # gem_name: byebug-9.1.0
    # Example url:
    #   https://gems2.lambdagems.com/gems/2.5.0/byebug/byebug-9.1.0.zip
    def gem_url(gem_name)
      folder = gem_name.gsub(/-(\d+\.\d+\.\d+.*)/,'') # folder: byebug
      "#{source_url}/gems/#{Jets::Gems.ruby_folder}/#{folder}/#{gem_name}.zip"
    end

    def ruby_folder
      Jets::Gems.ruby_folder
    end
  end
end