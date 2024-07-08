require 'cgi'
require 'zlib'
require 'json'
require 'stringio'
require 'nokogiri'
require 'rest-client'
require_relative 'exceptions.rb'

# https://stackoverflow.com/a/34678301/14861946
Nokogiri::XML::Node.send(:define_method, 'xpath_regex') { |*args|
  xpath = args[0]
  rgxp = /\/([a-z]+)\[@([a-z\-]+)~=\/(.*?)\/\]/
  xpath.gsub!(rgxp) { |s| m = s.match(rgxp); "/#{m[1]}[regex(.,'#{m[2]}','#{m[3]}')]" }
  self.xpath(xpath, Class.new {
    def regex node_set, attr, regex
      node_set.find_all { |node| node[attr] =~ /#{regex}/ }
    end
  }.new)
}

class RestClient::Response
  
  #include RestClient::AbstractResponse
  
  def body(decompress = true)
    encoding = self.headers[:content_encoding]
    response = String.new(self)
    
    if encoding == "gzip" and decompress and !response.empty?
      return Zlib::GzipReader.new(StringIO.new(response)).read
    elsif encoding == "deflate" and decompress and !response.empty?
      return Zlib::Inflate.inflate(response)
    else
      return response
    end
  end
  
  def to_s
    return body
  end
  
  def ok?
    if (400..500).to_a.member? (code)
      return false
    else
      return true
    end
  end
  
  def parse_html
    return Nokogiri::HTML(body)
  end
  
  def parse_xml
    return Nokogiri::XML(body)
  end

  def json
    return JSON.parse(body)
  end
end

class RestClient::Payload::Multipart
  def create_file_field(s, k, v)
    begin
      s.write("Content-Disposition: form-data;")
      s.write(" name=\"#{k}\";") unless (k.nil? || k=='')
      s.write(" filename=\"#{v.respond_to?(:original_filename) ? v.original_filename : File.basename(v.path)}\"#{EOL}")
      s.write("Content-Type: #{v.respond_to?(:content_type) ? v.content_type : mime_for(v.path)}#{EOL}")
      s.write(EOL)
      while (data = v.read(8124))
        s.write(data)
      end
    rescue IOError
    ensure
      v.close if v.respond_to?(:close)
    end
  end
end

module FbRuby
  # utility
  module Utils
    # requests Session
    class Session
      
      @@default_user_agent = "Mozilla/5.0 (Linux; Android 9; SM-N976V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.89 Mobile Safari/537.36"
      @@headers = {'Accept-Encoding'=> 'gzip, deflate', 'Accept'=> '*/*', 'Connection'=> 'keep-alive'}
      @@facebook_exceptions = true
      
      class << self
        def default_user_agent
          return @@default_user_agent
        end
        
        def default_headers
          return @@headers
        end
        
        def facebook_exceptions
          return @@facebook_exceptions
        end
      end
      
      attr_reader :options, :headers, :cookies
      
      def initialize(headers = {}, cookies = {})
        @headers = headers.empty? ? @@headers : headers
        
        if cookies.instance_of?(Hash)
          @cookies = cookies
        else
          @cookies = FbRuby::Utils::parse_cookies_header(cookies)
        end
        
        @options = {
        verify_ssl: true,
        max_redirects: 10,
        timeout: 30,
        open_timeout: 30,
        user_agent: @headers.member?('user-agent') ? @headers['user-agent'] : @@default_user_agent,
        follow_redirect: true}
      end

      def get(url, params = {}, headers = {}, options = {})
        if params.length > 0
          url = URI(url.to_s)
          url.query = URI.encode_www_form(params.to_a)
        end

        request(:get, url, {}, headers, nil, options)
      end

      def post(url, data = {}, headers = {}, options = {})
        request(:post, url, {}, headers, data, options)
      end

      def put(url, data = {}, headers = {}, options = {})
        request(:put, url, {}, headers, data, options)
      end

      def delete(url, headers = {}, options = {})
        request(:delete, url, {}, headers, nil, options)
      end

      def head(url, headers = {}, options = {})
        request(:head, url, {}, headers, nil, options)
      end

      def get_without_sessions(url)
        return RestClient.get(url.to_s, cookies: @cookies)
      end

      def post_without_sessions(url, data = {})
        begin 
          return RestClient.post(url.to_s, data, cookies: @cookies)
        rescue RestClient::Found => err
          return get_without_sessions(err.response.headers[:location])
        end
      end
      
      def get_cookie_str
        return FbRuby::Utils::cookie_hash_to_str(@cookies)
      end
      
      def get_cookie_dict
        if @cookies.instance_of? (Hash)
          return @cookies
        else
          return FbRuby::Utils::parse_cookies_header(@cookies)
        end
      end
      
      def get_cookie_hash
        return get_cookie_dict
      end

      private

        def request(method, url, params = {}, headers = {}, data = nil, options = {})
          url = url.to_s if url.kind_of? (URI)
#          url = URI::DEFAULT_PARSER.escape(url)
          headers = @headers.merge(headers)
          headers['Cookies'] = @cookies.map { |k, v| "#{k}=#{v}" }.join('; ') unless @cookies.empty?
          
          begin
            response = RestClient::Request.execute(method: method,url: url,headers: headers,cookies: @cookies,payload: data,params: params,**@options.merge(options)) do |response|
              if [301,302, 307].include? (response.code)
#                request(method,response.headers[:location],params,headers,data,options)
                response.follow_redirection
              else
                response.return!
              end
            end
          rescue RestClient::MovedPermanently, RestClient::Found => req_err
            new_url = req_err.response.headers[:location]
            response = get(new_url)
          rescue RestClient::ExceptionWithResponse => req_err
            response = req_err.response
          end
          
          # Perbarui cookie setelah menerima respons
          update_cookies(response.cookies)
          
          if @@facebook_exceptions
            html = response.parse_html
            unless html.at_xpath("//a[starts-with(@href,\"/home.php?rand=\")]").nil?
              bugnub = html.xpath_regex("//a[@href~=/^\/bugnub\/\?(.*)=ErrorPage/]").first
              div_err = html.at_css('div#root')
              err_msg = "Terjadi Kesalahan :("
              div_err_msg = div_err.at_css('div[class]')
              err_msg = div_err_msg.css('text()').map(&:text).join(" ") unless div_err_msg.nil?

              if bugnub.nil?
                raise FbRuby::Exceptions::PageNotFound.new(err_msg)
              else
                raise FbRuby::Exceptions::FacebookError.new(err_msg)
              end
            end
            
            if !html.at_css('div#root[@role="main"]').nil? && !html.at_css('a[class][@target="_self"][@href^="/?"]').nil? #html.at_css("a[@href^=\"#{URI.join(@url, '/help/contact/')}\"]").nil?
              err_msg = html.at_css('div#root[@role="main"]')
              err_msg = err_msg.parent unless err_msg.parent.nil?
              
              raise FbRuby::Exceptions::AccountTemporaryBanned.new(err_msg.css('text()').map(&:text).join("\n"))
            end
            
            
          end
          
          return response
        end

        def update_cookies(cookie_header)
          return if cookie_header.nil? || cookie_header.empty?

          cookie_header.each do |key, value|
            @cookies[key] = value
          end
        end
      end
      
    class ThreadPool

      def initialize(size:)
        @size = size
        @jobs = Queue.new
        @pool = Array.new(size) do
          Thread.new do
            catch(:exit) do
              loop do
                job, args = @jobs.pop
                job.call(*args)
              end
            end
          end
        end
      end

      def schedule(*args, &block)
        @jobs << [block, args]
      end

      def shutdown
        @size.times do
          schedule { throw :exit }
        end
        
        @pool.map(&:join)
      end
    end

    def self.randomString(length)
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      return Array.new(length) { chars[rand(chars.size)] }.join
    end

    def self.parse_cookies_header(value)
      return {} unless value

      value.split(/; */n).each_with_object({}) do |cookie, cookies|
        next if cookie.empty?
        key, value = cookie.split('=', 2)
        cookies[key] = (unescape(value) rescue value) unless cookies.key?(key)
      end
    end
    
    def self.cookie_hash_to_str(cookie_hash, chomp = true, strip = true)
      if cookie_hash.instance_of? (Hash)
        cookies = cookie_hash.map{|key, value| "#{key}=#{value}"}.compact.join(';')
        cookies.strip! if strip
        cookies.chomp! if chomp
        
        return cookies
      end
    end
    
    def self.convert_file_size(size_in_bytes)
      units = %w[bytes KB MB GB TB PB EB]
      return "#{size_in_bytes} #{units[0]}" if size_in_bytes < 1024

      exponent = (Math.log(size_in_bytes) / Math.log(1024)).to_i
      converted_size = size_in_bytes.to_f / 1024 ** exponent
      converted_size = converted_size.round(2)
      return "#{converted_size} #{units[exponent]}"
    end

    def self.create_timeline(nokogiri_obj, request_session, message, file = nil, location = nil,feeling = nil,filter_type = '-1', **kwargs)
      host = URI("https://mbasic.facebook.com/")
      form = nokogiri_obj.at_xpath("//form[starts-with(@action,'/composer/mbasic')]")
      action = URI.join(host,form['action'])
      formData = {}
      form.css("input[type = 'hidden'][name][value]").each{|i| formData[i['name']] = i['value']}

      # lanjutkan nanti untuk foto
      unless file.nil?
        file_data = formData.clone
        file_data['view_photo'] = "Submit"
        formFile = request_session.post(action, data = file_data).parse_html.at_xpath("//form[starts-with(@action,'/composer/mbasic')]")
        dataFile = {"add_photo_done"=>"Submit","filter_type"=>filter_type}
        formFile.css("input[type = 'hidden']").each{|i| dataFile[i['name']] = i['value']}
        upload = FbRuby::Utils::upload_photo(request_session, URI.join(host,formFile['action']), file, dataFile)
        imgIds = []
        upload.each do |f|
          action = URI.join(host,f.parse_html.at_css('form')['action'])
          f.parse_html.css("input[type = 'hidden'][name][value]").each do |t|
            if t['name'] == "photo_ids[]"
              imgIds << t['value']
            else
              formData[t['name']] = t['value']
            end
            
          end
        end
        formData['photo_ids[]'] = imgIds.join(' , ')
      end

      unless location.nil?
        lok_data = formData.clone
        lok_data['view_location'] = "Submit"
        formLok = request_session.post(action, data = lok_data).parse_html.at_xpath("//form[starts-with(@action,'/places/selector')]")
        dataLok = {"query"=>location}
        formLok.css("input[type = 'hidden'][name][value]").each{|i| dataLok[i['name']] = i['value']}
        cari = request_session.get(URI.join(host,formLok['action']), params = dataLok).parse_html
        result = cari.at_xpath("//a[starts-with(@href,'/composer/mbasic') and contains(@href,'at=')] | //a[starts-with(@href,'%2Fcomposer%2Fmbasic') and contains(@href,'at=')]")
        raise FbRuby::Exceptions::FacebookError.new("Lokasi dengan nama #{location} tidak di temukan:(") if result.nil?
        formData['at'] = result['href'].match(/at=(\d+)/)[1]
      end

      unless feeling.nil?
        fel_data = formData.clone
        fel_data['view_minutiae'] = "Submit"
        felUrl = request_session.post(action, data = fel_data).parse_html.at_xpath("//a[starts-with(@href,'/composer/mbasic') and contains(@href,'ogaction')]")
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat menembahkan feeling:(") if felUrl.nil?
        felForm = request_session.get(URI.join(host,felUrl['href'])).parse_html.at_xpath("//form[starts-with(@action,'/composer/mbasic')]")
        felData = {"mnt_query"=>feeling}
        felForm.css("input[type = 'hidden'][name][value]").each{|i| felData[i['name']] = i['value']}
        cari = request_session.get(URI.join(host,felForm['action']), params = felData).parse_html
        result = cari.at_xpath("//a[starts-with(@href,'/composer/mbasic') and contains(@href,'ogaction')]")
        raise FbRuby::Exceptions::FacebookError.new("Feeling dengan nama #{feeling} tidak di temukan!") if result.nil?
        formData['ogaction'] = result['href'].match(/ogaction=(\d+)/)[1]
        formData['ogphrase'] = feeling
      end

      formData['view_post'] = "Submit"
      formData['xc_message'] = message
      formData.update(kwargs)

      begin
        posting = request_session.post(action, data = formData)
        return posting.ok?
      rescue FbRuby::Exceptions::PageNotFound
        return true
      end
    end
    
    def self.upload_photo(request_session, upload_url, files, data = {}, headers = {}, separator = '|', default_key = 'file', max_number = 3)
      max_size = 4194304 # Maksimal ukuran foto (4MB)
      support_file = ['.jpg','.png','.webp','.gif','.tiff','.heif','.jpeg']
      photo = []
      reqList = []

      unless files.kind_of?(Hash)
        number = 0
        files = files.split(separator) if files.kind_of? (String)
        files.each do |f|
          number = 0 if number >= max_number
          number += 1
          photo << {"#{default_key}#{number}"=>f}
        end
      else
        files.each{|k,v| photo << {k=>v}}
      end
      
      photo.each_slice(max_number.to_i) do |img|
        mydata = data.clone
        
        img.each do |khaneysia|
          key = khaneysia.keys.first
          path = khaneysia.values.first
          ext = File.extname(path)
          raise FbRuby::Exceptions::FacebookError.new("Ukuran file #{File.basename(path)} terlalu besar sehingga file tersebut tidak bisa di upload. File harus berukuran kurang dari #{FbRuby::Utils::convert_file_size(max_size)} :)") if File.size(path) > max_size
          raise FbRuby::Exceptions::FacebookError.new("Hanya bisa mengupload file dengan extensi #{support_file.join(', ')}, tidak bisa mengupload file dengan extensi #{ext}") unless support_file.include? (ext)
          mydata.update({key=>File.new(path,"rb")})
        end
        reqList << request_session.post(upload_url,mydata,headers)
      end
      
      return reqList
    end
  end
end
