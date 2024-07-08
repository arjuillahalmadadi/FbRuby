require 'uri'
require_relative 'utils.rb'
require_relative 'comments.rb'
require_relative 'exceptions.rb'

module FbRuby
  # class Posts di gunakan untuk parsing postingan facebook
  class Posts

    @@REGEX_URL = Regexp.new(/https:\/\/((?:(?:.*?)\.facebook.com|facebook\.com)\/((\d+|groups|[a-zA-Z0-9_.-]+)\/(\d+|posts|videos|\w+)\/(?:\d+|permalink\/\d+|\w+)|story\.php\?story_fbid|photo\.php\?fbid=\w+|watch(?:\/\?|\?)v=\d+)|fb\.(?:gg|watch)\/\w+)/)
    @@REACT_TYPE = {"1"=>"like", "2"=>"love", "3"=>"wow", "4"=>"haha", "7"=>"sad", "8"=>"angry", "16"=>"care"}
    @@REACT_LIST = ["like", "love", "care", "haha", "wow", "sad", "angry"]
    attr_reader :post_url, :author, :author_url, :caption, :post_url, :post_file,  :upload_time, :can_comment

    def self.REACT_TYPE
      return @@REACT_TYPE
    end

    def self.REACT_LIST
      return @@REACT_LIST
    end

    # Inisialisasi object Posts
    #
    # @param post_url [String] Url postingan facebook
    # @param request_session [Session] Object Session
    def initialize(post_url:, request_session:)
      raise FbRuby::Exceptions::FacebookError.new("#{post_url} bukanlah url yang valid, silahkan cek lagi post url anda:)") unless @@REGEX_URL.match?(post_url)
      if post_url.to_s.match?(/https:\/\/fb\.watch\/(?:.*?)\//)
        vidId = post_url.to_s.match(/https:\/\/fb\.watch\/(.*?)\//)
        post_url = "https://fb.gg/v/#{vidId}/" unless vidId.nil?
      end

      @url = URI("https://mbasic.facebook.com/")
      @sessions = request_session
      @post_url = URI(post_url.to_s)
      @post_url.hostname = @url.hostname if @post_url.hostname != @url.hostname
      
      @html = @sessions.get(@post_url).parse_html
      @div_article = @html.at_xpath("//div[@role = 'article']")

      unless @div_article.nil?
        @html = @div_article
        url = @html.xpath_regex("//a[@href~=/(^\/story\.php(.*)footer_action_list|https:\/\/(.*)\.facebook\.com\/groups\/\d+\/permalink)/]").first
        @html = @sessions.get(URI.join(@url, url['href'])).parse_html unless url.nil?
      end
      
      @div_post = @html.at_xpath("//div[@data-ft and @id]")
      @div_post = @html if @div_post.nil?
      @post_file = {"image"=>[],"video"=>[]}
      @form_komen = @html.at_xpath("//form[starts-with(@action,'/a/comment.php')]")
      @like_action = @html.at_xpath("//a[starts-with(@href,'/a/like.php')]")
      @react_url = @html.at_xpath("//a[starts-with(@href,'/reactions/picker')]")
      @data = {}
      @html.css("input[type = 'hidden'][name][value]").each{|d| @data[d['name']] = d['value']}
      @auhor_url = nil
      @author = @div_post.at_xpath("//a[@class = 'actor-link']")
      @author = @div_post.at_css('a[href]:not([class])')
      @caption = @div_post.css('p').map(&:text).join("\n")
      @upload_time = @div_post.at_css('abbr')
      @upload_time = @upload_time.text unless @upload_time.nil?
      @can_comment = !@form_komen.nil?

      unless @author.nil?
        @author_url = URI.join(@url, @author['href'])
        @author = @author.text
      end

      for tiaraMaharani in @div_post.css("a[href^='/photo.php'], a[href*='photos']")
        yayaData = {"link"=>nil,"id"=>nil,"preview"=>nil,"content-type"=>"image"}
        photo = URI.join(@url, tiaraMaharani['href'])
        thubmnail = tiaraMaharani.at_css('img')
        fullPhoto = @sessions.get(photo).parse_html.xpath_regex("//img[@src~=/^https:\/\/(?:z-m-scontent|scontent)/]").first

        yayaData['link'] = fullPhoto['src'] unless fullPhoto.nil?
        yayaData['id'] = fullPhoto['src'].match(/(\d+_\d+_\d+)/)[1] unless fullPhoto.nil?
        yayaData['preview'] = thubmnail['src'] unless thubmnail.nil?
        @post_file['image'] << yayaData
      end

      for rahmatAdha in @div_post.css("a[href^='/video_redirect']")
        matData = {"link"=>nil,"id"=>nil,"preview"=>nil,"content-type"=>"video"}
        video = URI.decode_www_form_component(rahmatAdha['href']).match(/src=(.*)/)

        unless video.nil?
          matData['link'] = video[1]
          matData['id'] = matData['link'].match(/&id=(\d+)/)[1]
          matData['preview'] = rahmatAdha.at_css('img')['src']
        end

        @post_file['video'] << matData
      end
    end

    # Mengembalikan string representasi dari objek Posts.
    #
    # @return [String] Representasi string dari objek Posts.
    def to_s
      return "Facebook Posts : author=#{@author} upload_time=#{@upload_time} post_url=#{@post_url} can_comment=#{@can_comment}"
    end

    # Mengembalikan string representasi dari objek Posts.
    #
    # @return [String] Representasi string dari objek Posts.
    def inspect
      return to_s
    end

    # Refresh page Posts
    def refresh
      initialize(post_url: @post_url.to_s, request_session: @sessions)
    end

    # Kirim komentar ke post
    #
    # @param message [String] Isi komentar
    # @param file [String] Path file foto
    # @example Kirim Komentar tanpa foto
    #  post.send_comment("Ini komentar")
    # @example Kirim komentar dengan foto
    #  post.send_comment("Ini komentar dengan foto", "/sdcard/photo.jpg")
    def send_comment(message, file = nil)
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat memposting komentar ke postingan ini:(") unless @can_comment
      formData = {}
      @form_komen.css("input[type = 'hidden'][name][value]").each{|i| formData[i['name']] = i['value']}
      unless file.nil?
        formData['view_photo'] = "Submit"
        zHtml = @sessions.post(URI.join(@url, @form_komen['action']), data = formData).parse_html
        zForm = zHtml.xpath_regex("//form[@action~=/https:\/\/(z-upload\.facebook\.com|upload\.facebook\.com)/]").first
        zData = {"comment_text"=>message,"post"=>"Submit"}
        zForm.css("input[type = 'hidden']").each {|i| zData[i['name']] = i['value']}
        return FbRuby::Utils::upload_photo(@sessions, zForm["action"], files = file, data = zData, headers = {}, separator = "|", default_key = "photo", max_number = 1).last.ok?
      else
        formData['comment_text'] = message
        return @sessions.post(URI.join(@url, @form_komen['action']), data = formData).ok?
      end
    end

    # Berikan reaksi ke postingan
    #
    # @param react_type [String] Jenis reaksi
    def send_react(react_type)
      react_type.downcase!
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat memberikan react ke postingan ini:(") if @react_url.nil?
      raise FbRuby::Exceptions::FacebookError.new("Invalid React Type!!") if !@@REACT_LIST.include?(react_type)
      reactions = @sessions.get(URI.join(@url, @react_url['href'])).parse_html
      getReact = reactions.xpath("//a[starts-with(@href,'/ufi/reaction')]")
      send = @sessions.get_without_sessions(URI.join(@url,getReact[@@REACT_LIST.index(react_type)]['href']))
      return send.ok?
    end

    # Bagikan postingan ke profile
    #
    # @param message[String] Caption dari postingan
    # @param location[String] Nama Kota / Nama tempat
    # @param feeling[String] Nama Perasaan
    def share_post(message = '', location = nil, feeling = nil, **kwargs)
      shareUrl = @html.at_xpath("//a[starts-with(@href,'/composer/mbasic') and contains(@href,'c_src=share')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membagikan postingan ini") if shareUrl.nil?
      html = @sessions.get_without_sessions(URI.join(@url, shareUrl['href'])).parse_html
      return FbRuby::Utils::create_timeline(html, @sessions, message, nil, location, feeling, nil, **kwargs)
    end

    # Dapatkan Reaksi di postingan
    #
    # @return [Hash]
    def get_react
      reactData = {}
      @@REACT_LIST.each{|i| reactData[i] = 0}
      ufi = @html.at_xpath("//a[starts-with(@href,'/ufi/reaction/profile')]")

      unless ufi.nil?
        html = @sessions.get(URI.join(@url, ufi['href'])).parse_html
        reactUrl = html.xpath("//a[starts-with(@href,'/ufi/reaction/profile') and contains(@href,'total_count') and contains(@href,'reaction_type')]")
        reactUrl.each do |f|
          total = (f['href'].match(/total_count=(\d+)/)[1]).to_i
          type = f['href'].match(/reaction_type=(\d+)/)[1]
          next unless @@REACT_TYPE.include?(type)
          reactData[@@REACT_TYPE[type]] = total
        end
      end

      return reactData
    end

    # Dapatkan Reaksi di postingan dengan user
    #
    # @param limit [Integer] Jumblah maksimal reaksi yang di ambil
    # @return [Hash]
    def get_react_with_user(limit = 10)
      ufi = @html.at_xpath("//a[starts-with(@href,'/ufi/reaction/profile')]")
      yaya = {}
      result = []
      get_react.each{|i| yaya.update({i.first=>{"user"=>[],"total_count"=>i.last}})}

      unless ufi.nil?
        html = @sessions.get(URI.join(@url, ufi['href'])).parse_html
        reactUrl = html.xpath("//a[starts-with(@href,'/ufi/reaction/profile') and contains(@href,'total_count') and contains(@href,'reaction_type') and not(contains(@href,'reaction_type=0'))]")
        thread = FbRuby::Utils::ThreadPool.new(size: reactUrl.length)
        reactUrl.each do |url|
          thread.schedule do
            result << get_user_from_react(url,limit)
          end
        end

        thread.shutdown
        result.each do |r|
          yaya[@@REACT_TYPE[r['react_type']]]['user'].concat(r['user'])
        end
        return yaya
      end
    end

    # Dapatkan komentar di post
    #
    # @param limit [Integer] Jumblah maksimal komentar
    # @return [Array<Comments>]
    def get_comment(limit = 10)
      comment = []
      html = @html.clone

      while comment.length < limit
        for i in html.xpath_regex("//a[@href~=/^\/(profile\.php|[a-zA-Z0-9_.-]+\?eav)/]")
          next if i['class'].nil?
          div_comment = i.ancestors('div[class][id]').find { |div| div['id'] =~ /^\d+$/ }
          div_comment = i.ancestors.css('div:not([class]):not([id]:not([role]))')[2] if div_comment.nil?
          next if div_comment.nil?
          comment << FbRuby::Comments.new(nokogiriObj: div_comment, request_session: @sessions)
        end

        begin
          next_url = html.at_css("a[href^='/story.php'][href*='p=']")
          if next_url.nil?
            next_url = html.at_css("div[class][id^='see_next']")
            next_url = next_url.at_css("a")
          end
        rescue
          next_url = nil
        end
          
        break if next_url.nil? or comment.length >= limit
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return comment
    end

    private
      def get_user_from_react(url, limit)
        yaya = []
        react = url['href'].match(/reaction_type=(\d+)/)[1]
        while yaya.length < limit
          html = @sessions.get(URI.join(@url, url['href'])).parse_html
          user = html.xpath_regex("//a[@href~=/^\/([a-zA-Z0-9_.-]+\?eav|profile\.php)/]")
          user.each do |usr|
            uid = usr['href'].match(/^\/(([a-zA-Z0-9_.-]+)\?eav|profile\.php\?id=(\d+))/)
            yaya << {"name"=>usr.text,"username"=>(usr['href'].include?('profile.php') ? uid[3] : uid[2])}
          end

          url = html.at_xpath("//a[starts-with(@href,'/ufi/reaction/profile') and contains(@href,'shown_ids')]")
          break if yaya.length >= limit or url.nil?
        end

        return {"react_type"=>react,"user"=>yaya[0...limit]}
      end
  end
end
