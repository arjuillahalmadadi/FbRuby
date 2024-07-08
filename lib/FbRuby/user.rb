require 'uri'
require_relative 'posts.rb'
require_relative 'login.rb'
require_relative 'chats.rb'
require_relative 'exceptions.rb'

module FbRuby
  # class User di gunakan untuk parsing akun Facebook
  class User
    
    attr_reader :this_is_me, :user_info

    # Inisialisasi object User
    #
    # @param username [String] Nama atau id akun facebook
    # @param requests_sessions [Session] Object Session
    def initialize(username:, requests_sessions:)
      @username = username
      @sessions = requests_sessions
      @url = URI("https://mbasic.facebook.com")
      
      @req = @sessions.get(URI.join(@url, @username))
      @res = @req.parse_html
      
      raise FbRuby::Exceptions::PageNotFound.new("Akun dengan username #{@username} tidak di temukan") unless @res.at_xpath("//a[starts-with(@href,'/home.php?rand=')]").nil?
      
      @user_info = {"name"=>nil,"first_name"=>nil,"middle_name"=>nil,"last_name"=>nil,"alternate_name"=>nil,"about"=>nil,"username"=>nil,"id"=>nil,"contact_info"=>{},"profile_pict"=>nil,"basic_info"=>{},"education"=>[],"work"=>[],"living"=>{},"relationship"=>nil,"other_name"=>[],"family"=>[],"year_overviews"=>{},"quote"=>nil}
      
      img = @res.xpath_regex("//img[@alt~=/.*, profile.picture/]").first # Foto Profile Akun
      @user_info['profile_pict'] = img['src'] unless img.nil? # Link Foto Profile
      
      name = @res.css("strong[class]").last
      
      unless name.nil?
        alt_name = name.at_css("span.alternate_name") #("//span[@class=\"alternate_name\"]") # Nama Lain
        unless alt_name.nil?
          @user_info['alternate_name'] = alt_name.text.gsub(/\(|\)$/,'')
          pisah = name.text.sub(/\(.*\)/,"").strip.split(' ') # Hapus Nama Lain (Alternate Name)
        else
          pisah = name.text.split(' ')
        end
      else
        pisah = []
      end
      
      @user_info['name'] = pisah.join(' ') unless pisah.length.zero?
      @user_info['first_name'] = pisah[0] unless pisah.length.zero?
      @user_info['middle_name'] = pisah[1] if pisah.length > 2
      @user_info['last_name'] = pisah[-1] if pisah.length >= 2
      
      # Bio
      bio = @res.at_xpath("//div[@id=\"bio\"]")
      
      unless bio.nil?
        bio.xpath("//a[starts-with(@href, '/profile/edit')]").each{|e| e.remove}
        @user_info['about'] = bio.search('text()').map(&:text)[-1]
      end
      
      # Id Pengguna
      uid = @res.at_css("img[alt*='profile picture']").parent
      uid = @res.at_css("a[href^='/profile/picture/view']") if uid['href'].nil?
      
      unless uid.nil?
        cari_uid = uid['href'].match(/(?:&|;|profile_)id=(\d+)/)
        @user_info['id'] = cari_uid[-1] unless cari_uid.nil?
      else
        cari_uid = @req.body.match(/owner_id=(\d+)/)
        @user_info['id'] = cari_uid[1] unless cari_uid.nil?
      end
      
      # Nama Pengguna (username)
      unless @req.request.url.include? ('profile.php')
        username = @req.request.url.match(/^(?:https?:\/\/)?(?:www\.)?mbasic\.facebook\.com\/([a-zA-Z0-9.]+)/)
        @user_info['username'] = username[-1] unless username.nil?
      end
      
      # Informasi tentang sekolah
      sekolah = @res.at_xpath("//div[@id=\"education\"]")
      
      unless sekolah.nil?
        sekolah.xpath_regex("//a[@href~=/(\/editprofile\/eduwork\/add\/|\/profile\/edit)/]").map(&:remove)
        
        sekolah.css("img").map do |img|
          parent = img.parent.next_element
          next if parent.nil? or parent.name != 'div'
          arr_sekolah = parent.css('span').map(&:text).uniq
          hash_sekolah = {'name'=>nil,'type'=>nil,'study'=>nil,'time'=>nil}
          
          case arr_sekolah.length
            when 1 then hash_sekolah['name'] = arr_sekolah.first
            when 2 then hash_sekolah.update({'name'=>arr_sekolah.first,'time'=>arr_sekolah.last})
            when 3 then hash_sekolah.update({'name'=>arr_sekolah.first,'type'=>arr_sekolah[1],'time'=>arr_sekolah.last})
            when 4 then hash_sekolah.update({'name'=>arr_sekolah.first,'type'=>arr_sekolah[1], 'study'=>arr_sekolah[2], 'time'=>arr_sekolah.last})
          end
          
          @user_info['education'] << hash_sekolah
        end
      end
      
      # Informasi Tentang Pekerjaan
      kerja  = @res.at_xpath("//div[@id=\"work\"]")
      
      unless kerja.nil?
        loker = kerja.search('img').select{|met| met['alt'].to_s.match? (/(.*?), profile picture/)}
        
        for echa in loker
          moya = echa.parent.next_element
          next if moya.nil? or moya.name != 'div'
          
          # Alay dikit gak papa lah:v
          rahmat_sayang_khaneysia = moya.css('text()').map(&:text).uniq
          rahmat_cinta_khaneysia = rahmat_sayang_khaneysia.first # Nama pekerjaan
          love_you_khaneysia = rahmat_sayang_khaneysia.select{|echa| echa.match? (/^(\d{1}|\d{2}|\u200f)(\d{1}|\d{2}|\s)(.*?)\s-(.*?)$/)}.first
          # Heheh :>
          
          @user_info['work'] << {'name'=>rahmat_cinta_khaneysia,'time'=>love_you_khaneysia}
        end
      end
      
      # Informasi Tentang Tempat Tinggal
      rumah = @res.at_xpath("//div[@id=\"living\"]")
      
      unless rumah.nil?
        rumah.xpath("//a[starts-with(@href,\"editprofile.php\")]").map(&:remove)
        rumah_arr = rumah.css('text()').map(&:text)[1..]
        rumah_arr.each_slice(2){|key,val| @user_info['living'].update({key=>val})}
      end
      
      # Informasi Tentang Nama Lain
      other_name = @res.at_xpath("//div[@id=\"nicknames\"]")
      
      unless other_name.nil?
        other_name.xpath("//a[starts-with(@href,\"/profile/edit/info/nicknames\")]").map(&:remove)
        nama_ku = other_name.css('text()').map(&:text)[1..]
        nama_ku.each_slice(2){|key, val| @user_info['other_name'] << {key=>val}}
      end
      
      # Informasi Tentang Hubungan Percintaan
      cinta = @res.at_xpath("//div[@id=\"relationship\"]")
      
      unless cinta.nil?
        cinta.xpath("//a[starts-with(@href,\"/editprofile.php\")]").map(&:remove)
        cinta_ku = cinta.css('text()').map(&:text).map(&:strip)[1..]
        @user_info['relationship'] = cinta_ku.join(' ')
      end
      
      # Informasi Tentang Anggota keluarga
      # Harta Yang Paling Berharga Adalah Keluarga :) #
      keluarga = @res.at_xpath("//div[@id=\"family\"]")
      
      unless keluarga.nil?
        keluarga_ku = keluarga.css('img').select{|i| i['alt'].to_s.match(/(.*), profile picture/)}
        
        for family in keluarga_ku
          parent = family.parent.next_element
          name = parent.css('a').text
          profile_pict = family['src']
          designation = parent.css('h3')[-1].text
          
          @user_info['family'] << {'name'=>name,'profile_pict'=>profile_pict,'designation'=>designation}
        end
      end
      
      # Informasi Tentang Peristiwa Penting dalam Hidup
      kejadian = @res.at_xpath("//div[@id=\"year-overviews\"]")
      
      unless kejadian.nil?
        # 23-08-2021
        khaneysia = kejadian.at('div').css('text()').map(&:text)[1..]
        nabila = {}
        zahra = nil
        
        khaneysia.each do |element|
          if element.match?(/^\d+$/) # Jika elemen merupakan tahun
            zahra = element
            nabila[zahra] = []
          elsif zahra
            nabila[zahra] << element
          end
        end
        # 22/11/2021 #
        @user_info['year_overviews'].update(nabila)
      end
      
      # Kutipan Favorite
      kutipan = @res.at_xpath("//div[@id=\"quote\"]")
      
      unless kutipan.nil?
        kutipan.xpath("//a[starts-with(@href, \"/profile/edit/\")]").map(&:remove)
        content = kutipan.css('text()').map(&:text).map(&:strip)[1..]
        @user_info['quote'] = content.join(' ')
      end
      
      # Informasi Kontak
      contact = @res.at_xpath("//div[@id=\"contact-info\"]")
      
      unless contact.nil? then contact.css('text()').map(&:text).map(&:strip)[1..].each_slice(2){|k,v| @user_info['contact_info'].update({k=>v})}
      end
      
      # Informasi Umum
      basic_info = @res.at_xpath("//div[@id=\"basic-info\"]")
      
      unless basic_info.nil? then basic_info.css('text()').map(&:text).map(&:strip)[1..].each_slice(2){|k,v| @user_info['basic_info'].update({k=>v})}
      end
      
      my_id = @sessions.get_cookie_hash['c_user']
      
      unless my_id.nil?
        @this_is_me = my_id == @user_info['id']
      end
    end
    
    # Mengembalikan string representasi dari objek User.
    #
    # @return [String] Representasi string dari objek User.
    def to_s
      return "Facebook User : name=#{@user_info['name'].inspect} username=#{@user_info['username'].inspect} id=#{@user_info['id'].inspect}"
    end
    
    # Mengembalikan string representasi dari objek User.
    #
    # @return [String] Representasi string dari objek User.
    def inspect
      return self.to_s
    end
    
    def [](item)
      return @user_info[item]
    end
    
    def method_missing(method_name, *args)
      key = method_name.to_s
      if @user_info.key?(key)
        return @user_info[key]
      else
       super
     end
    end

    def respond_to_missing?(method_name, include_private = false)
      @user_info.key?(method_name.to_s) || super
    end

    # refresh page
    def refresh
      initialize(username:@username, requests_sessions:@sessions)
    end

    # Colek Orang ini
    def poke
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat melakukan poke ke diri sendiri") if @this_is_me
      colek = @res.at_xpath("//a[starts-with(@href,\"/pokes/inline\")]")
      
      unless colek.nil?
        req = @sessions.get(URI.join(@url, colek['href']))
        gagal = req.parse_html.at_css("div[text()^=\"#{@user_info['name']}\"]")
        raise FbRuby::Exceptions::FacebookError.new(gagal.text) unless gagal.nil?
        return req.ok?
      end
    end

    # Buat pesan baru dengan orang ini
    #
    # @return [Chats]
    def message
      chat_url = @res.at_css('a[href^="/messages/thread/"]')
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{@user_info['name']}") if chat_url.nil?
      
      return FbRuby::Chats.new(chats_url: URI.join(@url, chat_url['href']), request_session: @sessions)
    end

    # Shortcut untuk kirim pesan teks ke orang ini
    def send_text(text)
      return message.send_text(text)
    end

    # Blokir akun orang ini
    def block_user
      block_url = @res.at_css("a[href^='/privacy/touch/block/confirm/']")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat memblokir akun sendiri :)") if @this_is_me
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat memblokir akun #{self['name']}") if block_url.nil?
      
      req = @sessions.get(URI.join(@url, block_url['href']))
      res = req.parse_html
      
      form = res.at_css("form[action^='/privacy/touch/block']")
      data = {}
      form.css('input[type="hidden"]').each{|i| data[i['name']] = i['value']}
      data["confirmed"] = form.at_css('input[name="confirmed"]')['value']
      
      blok = @sessions.post(URI.join(@url, form['action']), data = data)
      res = blok.parse_html
      
      sukses = res.at_css("a[href^=\"/privacy/touch/block/?block_result=0\"]")
      
      return !sukses.nil?
    end

    # Tambahkan orang ini sebagai teman
    def add_friends
      action_user("/a/friends/profile/add")
    end

    # Batalkan permintaan pertemanan
    def cancel_friends_requests
      action_user("/a/friendrequest/cancel")
    end

    # Terima permintaan pertemanan
    def accept_friends_requests
      action_user_with_regex("/a\/friends\/profile\/add\/\?(.*)is_confirming/")
    end

    # Hapus permintaan pertemanan
    def delete_friends_requests
      action_user_with_regex("/\/a(.*?)friends\/reject/")
    end
    
    # Hapus pertemanan
    def remove_friends
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat melakukan tindakan yang anda minta!") if @this_is_me
      confirm = @res.at_css('a[href^="/removefriend.php?"]')
      
      unless confirm.nil?
        confirm_form = @sessions.get(URI.join(@url, confirm['href'])).parse_html.at_css('form[action^="/a/friends/remove/"]')
        confirm_data = {}
        unless confirm_form.nil?
          confirm_form.css('input[@type="hidden"]').each{|inp| confirm_data.update({inp['name']=>inp['value']})}
          confirm_data.update({"confirm"=>confirm_form.at_css('input[@name="confirm"]')['value']})
          confirm_submit = @sessions.post(URI.join(@url, confirm_form['action']), data = confirm_data)
          @res = confirm_submit.parse_html
          
          return confirm_submit.ok?
        end
      end
    end

    # Ikuti akun ini
    def follow
      action_user("/a/subscribe.php")
    end

    # Berhenti mengikuti akun ini
    def unfollow
      action_user("/a/subscriptions/remove")
    end

    # Dapatkan daftar teman
    #
    # @param limit [Integer] Batas maksimal atau jumblah yang ingin di dapatkan
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_friends(limit, return_hash = true)
      return getFriends("?v=friends",limit,return_hash)
    end

    # Dapatkan daftar teman yang memiliki kesamaan
    #
    # @param limit [Integer] Batas maksimal atau jumblah yang ingin di dapatkan
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_mutual_friends(limit, return_hash = true)
      return getFriends("?v=friends&mutual=1",limit,return_hash)
    end

    # Dapatkan Foto Dari Akun Pengguna
    #
    # @param limit[Integer] Jumblah foto yang akan di ambil
    # @param albums_url[String] Url dari album foto
    def get_photo(limit = 5, albums_url = nil)
      raise FbRuby::Exceptions::FacebookError.new("Format url album tidak valid!") if !albums_url.nil? and !albums_url.match?(/^https:\/\/(.*?)\.facebook\.com\/[a-zA-Z0-9_.-]+\/albums\/\d+\/(.*)/)
      myPhoto = []

      if albums_url.nil?
        html = @sessions.get(URI.join(@url, "#{@username}?v=photos")).parse_html
      else
        html = @sessions.get(albums_url).parse_html
      end

      while myPhoto.length < limit
        img = html.css("a[href^='/photo.php']")
        break if img.length < 2
        thread = FbRuby::Utils::ThreadPool.new(size: 5)
        img[1...].each do |i|
          thread.schedule do
            myPhoto << getImage(i)
          end
        end #Lanjut di sini
        thread.shutdown
        next_url = html.at_css("a[href*='/photoset'], a[href*='/albums'][href*='start_index']")
        break if myPhoto.length >= limit or next_url.nil?
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return myPhoto[0...limit]
    end

    # Dapatkan Album Dari Akun Pengguna
    #
    # @param limit[Integer] Jumblah maksimal album yang akan di ambil
    def get_albums(limit = 5)
      myalbums = []
      html = @sessions.get(URI.join(@url, "/#{@username}?v=albums")).parse_html
      album = html.css("a[href*='/albums']")
      album.each{|i| myalbums << {"albums_name"=>i.text, "albums_url"=>URI.join(@url, i['href']).to_s}}
      
      return myalbums[0...limit] 
    end

    # Dapatkan Postingan dari Akun Pengguna
    # @param limit[Integer] Jumblah maksimal Postingan yang akan di ambil
    def get_posts(limit = 5)
      myPosts = []
      html = @sessions.get(URI.join(@url, "#{@username}?v=timeline")).parse_html

      while myPosts.length < limit
        for post in html.css("div[role='article']")
          url = post.at_css("a[href^='/story.php'][href*='#footer_action_list']")
          next if url.nil?
          break if myPosts.length >= limit
          myPosts << FbRuby::Posts.new(post_url: URI.join(@url,url['href']).to_s, request_session: @sessions)
        end

        next_url = html.at_css("a[href^='/profile/timeline/stream']")
        break if myPosts.length >= limit or next_url.nil?
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return myPosts[0...limit]
    end

    # Buat Postingan di akun pengguna
    #
    # @param message[String] Caption dari postingan
    # @param file[String] Path dari foto (hanya bisa posting 1 foto)
    # @param location[String] Nama Kota / Nama tempat
    # @param feeling[String] Nama Perasaan
    # @param filter_type[String] Tipe Filter
    # Ada 3 tipe filter
    #  -1 Tanpa Filter
    #  2 Hitam Putih
    #  3 Retro
    def create_timeline(message, file: nil, location: nil,feeling: nil,filter_type: '-1', **kwargs)
      fullForm = @res.at_xpath("//form[starts-with(@action,'/composer/mbasic')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membuat postingan ke akun \"#{self.name}\" :(") if fullForm.nil?
      fullFormData = {}
      fullForm.css("input[type = 'hidden']").each{|i| fullFormData[i['name']] = i['value']}
      html = @sessions.post(URI.join(@url, fullForm['action']), data = fullFormData).parse_html
      return FbRuby::Utils::create_timeline(html,@sessions, message, file, location, feeling, filter_type, **kwargs)
    end

    private
      def getFriends(friends, limit = 25, return_hash = true)
        teman = []
        friendsUrl = URI.join(@url, @username, friends)

        while teman.length < limit
          neysia = @sessions.get(friendsUrl)
          moyaM = neysia.parse_html
          datas = moyaM.css('img').select{|img| img['alt'].to_s.match?(/(.*), profile picture/)}
          datas.delete_at(0) unless datas.length.zero?
          break if datas.length.zero?
        
          if return_hash
            datas.each do |elm|
              profile = get_profile_info(elm)
              next if profile.nil?
              teman << profile
            end
          else
            threadPool = FbRuby::Utils::ThreadPool.new(size: 5)

            datas.each do |elm|
              profile = get_profile_info(elm)
              next if profile.nil?
              threadPool.schedule {teman << FbRuby::User.new(username: profile['username'], requests_sessions: @sessions)}
            end
            
            threadPool.shutdown
          end
          next_url = moyaM.xpath_regex("//a[@href~=/^(\/profile\.php\?id=\d+(.*)v=friends)/]").first
          break if next_url.nil? or teman.length >= limit
          friendsUrl = URI.join(@url, next_url['href'])
        end  
        return teman
      end


      def action_user(first_url)
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat melakukan tindakan yang anda minta!") if @this_is_me
        moya = @res.at_css("a[href^='#{first_url}']")
 
        unless moya.nil?
          rahmat = @sessions.get_without_sessions(URI.join(@url, moya['href']))
          @res = rahmat.parse_html
        
          return rahmat.ok?
        else
          return false
        end
      end
    
      def action_user_with_regex(regex)
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat melakukan tindakan yang anda minta!") if @this_is_me
        moya = @res.xpath_regex("//a[@href~=#{regex}]").first
  
        unless moya.nil?
          neysia = {"jazoest"=>@res.at_css("input[name=\"jazoest\"]")['value'],"fb_dtsg"=>@res.at_css("input[name=\"fb_dtsg\"]")['value']}
          rahmat = @sessions.get(URI.join(@url, moya['href']), data = neysia)
          @res = rahmat.parse_html
          return rahmat.ok?
        else
          return false
        end
      end
    
      def get_profile_info(nokogiri_obj)
        parent = nokogiri_obj.parent
        pola = /^\/profile\.php\?id=(\d+)|^\/([a-zA-Z0-9_.-]+)/

        unless parent.nil?
          profile = parent.next_element.xpath_regex(".//a[@href~=/#{pola}/]").first
          profile_url = profile['href']
          username = profile_url.match(pola)
          return {"name"=>profile.text, "username"=>(username[1].nil?) ? username[2] : username[1], "profile_url"=>URI.join(@url, profile_url).to_s, "profile_pict"=>nokogiri_obj['src']}
        else
          return nil
        end
      end

      def getImage(nokogiriObj)
        data = {"thumbnail"=>nil,"photo"=>nil,"albums"=>nil,"albums_url"=>nil}

        begin
          thumbnail = nokogiriObj.at_css("img")
          photo = @sessions.get(URI.join(@url, nokogiriObj['href'])).parse_html
          albums = photo.at_css("a[href*='/albums']")
          fullImg = photo.xpath_regex("//img[@src~=/^https:\/\/(?:z-m-scontent|scontent)/]").first

          data["thumbnail"] = thumbnail['src'] unless thumbnail.nil?
          data["photo"] = fullImg["src"] unless fullImg.nil?

          unless albums.nil?
            data["albums"] = albums.text
            data["albums_url"] = URI.join(@url, albums['href']).to_s
          end
        ensure
          return data
        end
      end
  end
end
