require 'erb'
require 'date'
require 'tempfile'
require_relative 'user.rb'
require_relative 'utils.rb'
require_relative 'posts.rb'
require_relative 'login.rb'
require_relative 'groups.rb'
require_relative 'messenger.rb'
require_relative 'exceptions.rb'

module FbRuby

  # class Facebook di gunakan agar penggunaan library jadi lebih mudah dan cepat
  class Facebook < FbRuby::Login::Cookie_Login

    # Inisialisasi Object Facebook
    #
    # @param cookies[String] Cookie akun facebook dalam format string
    # @param free_facebook[Boolean] Gunakan web free facebook ketika login
    # @param headers[Hash] Headers Yang akan di gunakan untuk requests sessions
    # @param save_device[Boolean] Simpan Informasi Login
    def initialize(cookies, free_facebook: false, headers: {}, save_device: true)
      super
    end

    # Mengembalikan string representasi dari objek Facebook.
    #
    # @return [String] Representasi string dari objek Facebook.
    def to_s
      return "Facebook: host=#{@url} account=#{get_cookie_hash['c_user']}"
    end

    # Mengembalikan string representasi dari objek Facebook.
    #
    # @return [String] Representasi string dari objek Facebook.
    def inspect
      return to_s
    end

    # Parsing Profile Pengguna
    #
    # @param username[String] Username atau id akun facebook
    # @return [User]
    def get_profile(username)
      return FbRuby::User.new(username: username, requests_sessions: @sessions)
    end

    # Parsing Groups
    #
    # @param group_id[String] Id group
    # @return [Groups]
    def get_groups(group_id)
      return FbRuby::Groups.new(group_id: group_id, requests_sessions: @sessions)
    end

    # Parsing Postingan
    #
    # @param post_url[String] Link postingan
    # @return [Posts]
    def post_parser(post_url)
      return FbRuby::Posts.new(post_url: post_url, request_session: @sessions)
    end

    # Parsing Messenger
    #
    # @return [Messenger]
    def messenger
      return FbRuby::Messenger.new(request_session: @sessions)
    end

    # Dapatkan Foto Dari Akun Pengguna
    #
    # @param target[String] Id / username akun facebook
    # @param limit[Integer] Jumblah foto yang akan di ambil
    # @param albums_url[String] Url dari album foto
    def get_photo(target, limit, albums_url = nil)
      return get_profile(target).get_photo(limit, albums_url)
    end

    # Dapatkan Album Dari Akun Pengguna
    #
    # @param target[String] Id / username akun facebook
    # @param limit[Integer] Jumblah maksimal album yang akan di ambil
    def get_albums(target, limit)
      return get_profile(target).get_albums(limit)
    end

    # Dapatkan Postingan dari Akun Pengguna
    # @param target[String] Id / username akun facebook
    # @param limit[Integer] Jumblah maksimal Postingan yang akan di ambil
    def get_posts_user(target, limit)
      return get_profile(target).get_posts(limit)
    end

    # Dapatkan Postingan dari Group Facebook
    # @param target[String] Id / username akun facebook
    # @param limit[Integer] Jumblah maksimal Postingan yang akan di ambil
    def get_posts_groups(target, limit)
      return get_groups(target).get_posts(limit)
    end

    # Dapatkan postingan dari beranda
    #
    # @param limit[Integer] Jumblah maksimal Postingan yang akan di ambil
    def get_home_posts(limit)
      post = []
      html = @sessions.get(URI.join(@url, "home.php")).parse_html

      while post.length < limit
        url = html.css("a[href*='#footer_action_list']")

        for i in url
          break if post.length >= limit
          post << post_parser((i['href'].include?('http') ? i['href'] : URI.join(@url, i['href']).to_s))
        end

        next_url = html.at_css("a[href^='/stories.php?aftercursorr']")
        break if next_url.nil? or post.length >= limit
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return post
    end

    # Buat Postingan di akun pengguna
    #
    # @param target[String] Id / Username akun facebook
    # @param message[String] Caption dari postingan
    # @param file[String] Path dari foto (hanya bisa posting 1 foto)
    # @param location[String] Nama Kota / Nama tempat
    # @param feeling[String] Nama Perasaan
    # @param filter_type[String] Tipe Filter
    # Ada 3 tipe filter
    #  -1 Tanpa Filter
    #  2 Hitam Putih
    #  3 Retro
    def create_timeline_user(target,message, file: nil, location: nil,feeling: nil,filter_type: '-1', **kwargs)
      return get_profile(target).create_timeline(message, file:file, location:location,feeling:feeling,filter_type:filter_type, **kwargs)
    end

    # Buat Postingan di Grup
    #
    # @param target[String] Id / Username akun facebook
    # @param message[String] Caption dari postingan
    # @param file[String] Path dari foto (hanya bisa posting 1 foto)
    # @param location[String] Nama Kota / Nama tempat
    # @param feeling[String] Nama Perasaan
    # @param filter_type[String] Tipe Filter
    # Ada 3 tipe filter
    #  -1 Tanpa Filter
    #  2 Hitam Putih
    #  3 Retro
    def create_timeline_groups(target,message, file: nil, location: nil,feeling: nil,filter_type: '-1', **kwargs)
      return get_groups(target).create_timeline(message, file:file, location:location,feeling:feeling,filter_type:filter_type, **kwargs)
    end

    # Buat Grup Baru
    #
    # @param name [String] Nama Group
    # @param privacy [String] Privasi Grup "public,private"
    def create_new_group(name, privacy)
      privacy.downcase!
      priv = ['public','private']
      raise FbRuby::Exceptions::FacebookError.new("Invalid Privacy!!!") if !priv.include? (privacy)
      html = @sessions.get(URI.join(@url, 'groups/create')).parse_html
      formName = html.at_css("form[action^='/groups/create']")
      formData = {"group_name"=>name,"verify"=>"Submit"}
      formName.css("input[type = 'hidden']").each{|i| formData[i['name']] = i['value']}
      namaSubmit = @sessions.get(URI.join(@url, formName['action']), formData).parse_html

      if !namaSubmit.at_css("input[name='group_name'][type = 'text']").nil?
        errMsg = namaSubmit.at_css("form[action^='/groups/create'] span")
        errMsg = (errMsg.nil? ? "Terjadi Kesalahan :(" : errMsg.text)
        raise FbRuby::Exceptions::FacebookError.new(errMsg)
      end
        
      formPrivacy = namaSubmit.at_css("form[action^='/groups/create/privacy']")
      formPrivacyData = {"verify"=>"Submit"}
      privasi = formPrivacy.css("input[type = 'radio']")
      formPrivacy.css("input[type = 'hidden']").each{|i| formPrivacyData[i['name']] = i['value']}
      privacyIndex = priv.index(privacy)
      formPrivacyData[privasi[privacyIndex]['name']] = privasi[privacyIndex]['value']
      create = @sessions.post(URI.join(@url, formPrivacy['action']), data = formPrivacyData).parse_html
      gpUid = create.at_css("a[href^='/groups/'][href*='view=members']")

      if gpUid.nil? and !create.at_css("input[name='group_name'][type = 'text']").nil?
        errMsg = create.at_css("form[action^='/groups/create'] span")
        errMsg = (errMsg.nil? ? "Terjadi Kesalahan :(" : errMsg.text)
        raise FbRuby::Exceptions::FacebookError.new(errMsg)
      end

      return get_groups((gpUid['href'].match(/\/groups\/(\d+)/)[1]).strip)
    end

    # Tambahkan Teman
    #
    # @param target [String] Username / id akun target
    def add_friends(target)
      return get_profile(target).add_friends()
    end

    # Batalkan permintaan pertemanan
    #
    # @param target [String] Username / id akun target
    def cancel_friends_requests(target)
      return get_profile(target).cancel_friends_requests()
    end
    
    # Terima Permintaan Pertemanan
    #
    # @param target [String] Username / id akun target
    def accept_friends_request(target)
      return get_profile(target).accept_friends_requests()
    end

    # Hapus Permintaan Pertemanan
    #
    # @param target [String] Username / id akun target
    def delete_friends_requests(target)
      return get_profile(target).delete_friends_requests()
    end

    # Tambahkan Teman
    #
    # @param target [String] Username / id akun target
    def remove_friends(target)
      return get_profile(target).remove_friends()
    end

    # Dapatkan daftar teman
    #
    # @param target [String] Username / id akun target
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_friends(target, limit, return_hash = true)
      return get_profile(target).get_friends(limit, return_hash)
    end

    # Dapatkan daftar permintaan pertemanan
    #
    # @param limit [Integer] Batas maksimal
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_friends_requests(limit, return_hash = true)
      return getFriendsCenter("/friends/center/requests","/friends/center/requests",limit, return_hash)
    end

    # Dapatkan daftar permintaan pertemanan terkirim
    #
    # @param limit [Integer] Batas maksimal
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_friends_requests_send(limit, return_hash = true)
      return getFriendsCenter("/friends/center/requests/outgoing","/friends/center/requests/outgoing",limit, return_hash)
    end

    # Dapatkan daftar saran pertemanan
    #
    # @param limit [Integer] Batas maksimal
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_sugest_friends(limit, return_hash = true)
      return getFriendsCenter("/friends/center/suggestions/","/friends/center/suggestions/",limit, return_hash)
    end

    # Cari postingan di pencarian
    #
    # @param keyword [String] Keyword Pencarian
    # @param limit [Integer] Limit Pencarian
    def get_posts_by_search(keyword, limit = 5)
      return searchPosts(keyword,"posts",limit)
    end

    # Cari Akun di pencarian
    #
    # @param keyword [String] Keyword Pencarian
    # @param limit [Integer] Limit Pencarian
    def get_people_by_search(keyword, limit = 5)
      user = []
      html = @sessions.get(URI.join(@url, "/search/people?q=#{ERB::Util.url_encode(keyword)}")).parse_html

      while user.length < limit
        for usr in html.css("img[alt*='profile picture']")
          next if usr.parent['href'].nil?
          break if user.length >= limit
          findUid = usr.parent['href'].match(/\/(?:profile\.php\?id=(\d+)|([a-zA-Z0-9_.-]+)\?)/)
          uid = (findUid[1].nil? ? findUid[2] : findUid[1])
          user << FbRuby::User.new(username: uid, requests_sessions: @sessions)
        end

        next_url = html.at_css("a[href*='/search/people']")
        
        break if next_url.nil? or user.length >= limit
        html = @sessions.get(next_url['href']).parse_html
      end

      return user
    end

    # Cari Video di pencarian
    #
    # @param keyword [String] Keyword Pencarian
    # @param limit [Integer] Limit Pencarian
    def get_video_by_search(keyword, limit = 5)
      return searchPosts(keyword,"videos",limit)
    end

    # Cari photo di pencarian
    #
    # @param keyword [String] Keyword Pencarian
    # @param limit [Integer] Limit Pencarian
    def get_photo_by_search(keyword, limit = 5)
      return searchPosts(keyword,"photos",limit)
    end

    # Dapatkan notifikasi terbaru
    #
    # @param limit [Integer] Batas maksimal notifikasi yang di ambil
    def get_notifications(limit)
      notif = []
      html = @sessions.get(URI.join(@url, "/notifications.php")).parse_html

      while notif.length < limit
        for i in html.css("a[href^='/a/notifications.php']")
          break if notif.length >= limit
          next if !i.at_css("img").nil?
          notifData = {"message"=>nil,"time"=>nil,"redirect_url"=>URI.join(@url, i['href']).to_s}
          msg = i.at_css("div span")
          time = i.at_css("div abbr")
          notifData["message"] = msg.text if !msg.nil?
          notifData["time"] = time.text if !time.nil?
          notif << notifData
        end

        next_url = html.at_css("a[href^='/notifications.php?more&']")
        break if notif.length >= limit or next_url.nil?
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return notif
    end

    # Dapat daftar grup saya
    #
    # @param limit [Integer] Batas maksimal grup yang di ambil
    def get_mygroups(limit = 5)
      group = []
      html = @sessions.get(URI.join(@url, "/groups/?seemore")).parse_html

      while group.length < limit
        for url in html.css("a[href^='http'][href*='/groups'], a[href^='/groups']")
          break if group.length >= limit
          uid = url['href'].match(/\/groups\/(\d+)/)
          next if uid.nil?
          group << get_groups(uid[1])
        end

        next_url = html.at_css("a[href^='/groups?seemore']")
        break if group.length >= limit or next_url.nil?
        html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
      end

      return group
    end

    # Dukung author
    def support_author
      kata = ['Hallo Kak @[100053033144051:] :)\n\nSaya suka library buatan kakak:)','Semangat ya kak ngodingnya:)','Semoga kak @[100053033144051:] Sehat selalu ya:)','Hai kak @[100053033144051:] :v','Hai kak Rahmet:)']
      rahmat = get_profile("Anjay.pro098")
      rahmat.follow()

      planet = ['Matahari','Merkurius','Venus','Bumi','Mars','Jupiter','Saturnus','Uranus','Neptunus','Pluto']
      motivasi = ['"Dia memang indah, namun tanpanya, hidupmu masih punya arti."','"Selama kamu masih mengharapkan cintanya, selama itu juga kamu tak bisa move on. Yang berlalu biarlah berlalu."','"Seseorang hadir dalam hidup kita, tidak harus selalu kita miliki selamanya. Karena bisa saja, dia sengaja diciptakan hanya untuk memberikan pelajaran hidup yang berharga."','"Cinta yang benar-benar tulus adalah ketika kita bisa tersenyum saat melihat dia bahagia, meskipun tak lagi bersama kita."','"Move on itu bukan berarti memaksakan untuk melupakan, tapi mengikhlaskan demi sesuatu yang lebih baik."','"Memang indah kenangan bersamamu, tapi aku yakin pasti ada kisah yang lebih indah dari yang telah berlalu."','"Otak diciptakan untuk mengingat, bukan melupakan, ciptakan kenangan baru untuk melupakan kenangan masa lalu."','"Cara terbaik untuk melupakan masa lalu adalah bukan dengan menghindari atau menyesalinya. Namun dengan menerima dan memafkannya."']

      waktu = DateTime.now()
      myPost = post_parser("https://www.facebook.com/100053033144051/posts/pfbid0ghCoMGdxGoSSxudGSthM5ZoxJPYujgow4Rvm8RpS6keHpXngFeD15uP22iv3oBvbl/?app=fbl")

      if waktu.day == 13 and waktu.month == 1
        myPost.send_comment("Selamat ulang tahun yang ke #{waktu.year - 2006} tahun kak @[100053033144051:] :)\n\nSemoga panjang umur dan terus bahagia.")
      elsif waktu.day == 18 and waktu.month == 5
        myPost.send_comment("Selamat ulang tahun yang ke #{waktu.year - 2007} tahun:)")
      else
        my_profile = get_profile("me")
        photo = my_profile.profile_pict
        temp = Tempfile.new(["photo-profile",".png"])
        temp.write(@sessions.get(photo).body)
        temp.rewind
        asal = my_profile.living.values.last
        asal = "Planet #{planet.sample}" if asal.nil?
        time = DateTime.now()
        komen = "Hallo kak @[100053033144051:], perkenalkan nama saya #{my_profile.name} saya tinggal di #{asal}.\n\n\n#{motivasi.sample}\n\n#{myPost.post_url}\n\nKomentar ini di tulis oleh bot\n[#{time.strftime('Pukul : %H:%M:%S')}]\n- #{time.strftime('%A, %d %B %Y')} -"
        myPost.send_react("love")
        send = myPost.send_comment(komen, file = temp.path)
        temp.close
        temp.unlink

        return send
      end
    end

    private
      def getFriendsCenter(url, nextUrl, limit, return_hash = true)
        minta = []
        html = @sessions.get(URI.join(@url,url)).parse_html
        while minta.length < limit
          friends = html.at_css("div[id='friends_center_main']").css("div[class] table[class][role='presentation']").select{|i| !i.at_css("img[alt*='profile picture']").nil?}
          break if friends.length.zero?

          if return_hash
            friends.each do |f|
              name = f.at_css("a").text
              uid = f.at_css("a")['href'].match(/(?:subject_id|uid)=(\d+)/)[1]
              img = f.at_css("img")['src']
              minta << {"name"=>name,"profile_pict"=>img,"username"=>uid}
            end
          else
            thread = FbRuby::Utils::ThreadPool.new(size: 5)
            friends.each do |f|
              thread.schedule do
                username = f.at_css("a")['href'].match(/uid=(\d+)/)[1]
                minta << FbRuby::User.new(username: username, requests_sessions: @sessions)
              end
            end
            thread.shutdown
          end

          next_url = html.at_css("a[href*='/#{nextUrl}'][href*='ppk']")
          break if minta.length >= limit or next_url.nil?
          html = @sessions.get(URI.join(@url, next_url['href'])).parse_html
        end

        return minta[0...limit]
      end

      def searchPosts(keyword,type, limit = 5)
        posts = []
        html = @sessions.get(URI.join(@url, "/search/#{type}?q=#{ERB::Util.url_encode(keyword)}")).parse_html

        while posts.length < limit
          for po in html.css("div[role = 'article'], div[id]")
            url = po.at_css("a[href^='/story.php'][href*='#footer_action_list'], a[href^='https://'][href*='groups'][href*='permalink'][href*='#footer_action_list'], a[href^='/photo.php']")
            next if url.nil?
            break if posts.length >= limit
            url = (url['href'].include?('http') ? url['href'] : URI.join(@url, url['href']).to_s)
            posts << FbRuby::Posts.new(post_url: url, request_session: @sessions)
          end

          next_url = html.at_css("a[href*='/search/#{type}']")
          break if next_url.nil? or posts.length >= limit
          html = @sessions.get(next_url['href']).parse_html
        end

        return posts
      end
  end
end
