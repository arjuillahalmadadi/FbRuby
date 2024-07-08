require 'uri'
require_relative 'utils.rb'
require_relative 'posts.rb'
require_relative 'exceptions.rb'

module FbRuby
  # clsss Comments di gunakan untuk membaca dan membalas komentar
  class Comments

    attr_reader :author, :username, :comment_text, :user_tag, :media, :time

    # Inisialisasi Object Comments
    #
    # @param nokogiriObj[Object] Object dari tag Nokogiri
    # @param request_session [Session] Object Session
    def initialize(nokogiriObj:, request_session:)
      @html = nokogiriObj
      @url = URI("https://mbasic.facebook.com/")
      @sessions = request_session
      @author = @html.at_css("h3 a[href*='profile.php?id='], h3 a")
      @username = nil
      @comment_text = @html.at_css("h3")
      @user_tag = []
      @media = {}
      @time = @html.at_css("abbr")
      @time = @time.text unless @time.nil?

      unless @author.nil?
        usr = @author['href'].match(/^\/(([a-zA-Z0-9_.-]+)\?eav|profile\.php\?id=(\d+))/)
        @username = (@author['href'].include?('profile.php') ? usr[3] : usr[2]) unless usr.nil?
        @author = @author.text
      end

      unless @comment_text.nil?
        @comment_text = @comment_text.next_element
        for com in @comment_text.css('a')
          next unless com['class'].nil?
          u = com['href'].match(/^\/(([a-zA-Z0-9_.-]+)\?eav|profile\.php\?id=(\d+))/)
          u = com['href'].include?('profile.php') ? u[3] : u[2]
          @user_tag << {"name"=>com.text,"username"=>u}
        end
        @comment_text.css("br").each{|i| i.replace("\n")}
        @comment_text = @comment_text.text
      end

      @video = @html.at_css("a[href^='/video_redirect']")
      @image = @html.at_css("a[href^='/photo.php']")

      unless @video.nil?
        vidData = {"link"=>nil,"id"=>nil,"preview"=>nil,"content-type"=>"video"}
        vidUrl = URI.decode_www_form_component(@video['href']).match(/src=(.*)/)
        preview = @video.at_css('img')

        unless vidUrl.nil?
          vidData['link'] = vidUrl[1]
          vidData['id'] = vidUrl[1].match(/&id=(\d+)/)[1]
        end
        
        vidData['preview'] = preview['src'] unless preview.nil?
        @media.update(vidData)
      end

      unless @image.nil?
        imgData = {"link"=>nil,"id"=>nil,"preview"=>nil,"content-type"=>"image"}
        imgUrl = URI.join(@url, @image['href'])
        thubmnail = @image.at_css('img')
        fullPhoto = @sessions.get(imgUrl).parse_html.at_css("img[src^='https://scontent'], img[src^='https://z-m-scontent']")
        imgData["link"] = fullPhoto['src'] unless fullPhoto.nil?
        imgData["id"] = fullPhoto['src'].match(/(\d+_\d+_\d+)/)[1] unless fullPhoto.nil?
        imgData["preview"] = thubmnail['src'] unless thubmnail.nil?
        @media.update(imgData)
      end
    end

    # Mengembalikan string representasi dari objek Comments.
    #
    # @return [String] Representasi string dari objek Comments.
    def to_s
      return "Facebook Comments : author=#{@author} username=#{@username} comment_text=#{@comment_text} user_tag=#{@user_tag} time=#{@time}"
    end

    # Mengembalikan string representasi dari objek Comments.
    #
    # @return [String] Representasi string dari objek Comments.
    def inspect
      return to_s
    end

    # Membalas Komentar
    #
    # @param message [String] Balasan dari komentar
    # @return[Boolean] Mengembalikan true jika berhasil membalas komentar
    def reply(message)
      replyUrl = @html.at_css("a[href^='/comment/replies']")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membalas komentar ini:(") if replyUrl.nil?
      html = @sessions.get(URI.join(@url, replyUrl['href'])).parse_html
      form = html.at_css("form[action^='/a/comment.php']")
      formData = {"comment_text"=>message}
      form.css("input[type='hidden'][name][value]").each{|i| formData[i['name']] = i['value']}
      balas = @sessions.post(URI.join(@url, form['action']), data = formData)

      return balas.ok?
    end
    
    # Berikan Reaksi Ke Komentar
    #
    # @param react_type[String] Jenis Reaksi
    # List reaksi yang bisa di gunakan
    # - like
    # - love
    # - care
    # - haha
    # - wow
    # - sad
    # - angry
    # @return [Boolean]
    def send_react(react_type)
      react_type.downcase!
      react_list = FbRuby::Posts.REACT_LIST
      react_url = @html.at_css("a[href^='/reactions/picker']")
      raise FbRuby::Exceptions::FacebookError.new("Invalid React Type!!!") if !react_list.include?(react_type)
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat memberikan react ke komentar ini:(") if react_url.nil?
      html = @sessions.get(URI.join(@url, react_url['href'])).parse_html
      react = html.xpath("//a[starts-with(@href,'/ufi/reaction')]")

      begin      
        send = @sessions.get_without_sessions(URI.join(@url,react[react_list.index(react_type)]['href']))
        return send.ok?
      rescue RestClient::NotFound
        return true
      end
    end

    # Dapatkan balasan dari komentar
    # 
    # @param limit [Integer] Limit maksimal balasan yang akan di ambil
    # @return [Array<Comments>, C] 
    def get_reply(limit = 10)
      balasanList = []
      balasan = @html.at_xpath("//a[starts-with(@href,'/comment/replies') and contains(@href,'count')]")

      unless balasan.nil?
        html = @sessions.get(URI.join(@url,balasan['href'])).parse_html
        for i in html.css("h3:not([class])")[1...]
          div_comment = i.ancestors('div[class][id]').find { |div| div['id'] =~ /^\d+$/ }
          div_comment = i.ancestors.css('div:not([class]):not([id]:not([role]))')[2] if div_comment.nil?
          next if div_comment.nil?
          balasanList << FbRuby::Comments.new(nokogiriObj: div_comment, request_session: @sessions)
        end        
      end

      return balasanList
    end

    # Mendapatkan jumblah react yang di berikan terhadap komentar ini
    #
    # @return[Hash] mengembalikan Hash yang memuat informasi jenis react dan jumblah react
    def get_react
      reactData = {}
      FbRuby::Posts.REACT_LIST.each{|i| reactData[i] = 0}
      ufi = @html.at_css("a[href^='/ufi/reaction/profile']")

      unless ufi.nil?
        html = @sessions.get(URI.join(@url, ufi['href'])).parse_html
        reactUrl = html.xpath("//a[starts-with(@href,'/ufi/reaction/profile') and contains(@href,'total_count') and contains(@href,'reaction_type')]")
        reactUrl.each do |f|
          total = (f['href'].match(/total_count=(\d+)/)[1]).to_i
          type = f['href'].match(/reaction_type=(\d+)/)[1]
          next unless FbRuby::Posts.REACT_TYPE.include?(type)
          reactData[FbRuby::Posts.REACT_TYPE[type]] = total
        end
      end

      return reactData
    end
  end
end

