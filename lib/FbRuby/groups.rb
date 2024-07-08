require_relative 'utils.rb'
require_relative 'user.rb'
require_relative 'posts.rb'
require_relative 'exceptions.rb'

module FbRuby
  # class Groups di gunakan untuk parsing grup facebook
  class Groups

    attr_reader :group_id, :name, :privacy, :total_members, :join

    # Inisialisasi Object Groups
    #
    # @param group_id [String] Id Dari Group Facebook
    # @param requests_sessions [Session] Object Session
    def initialize(group_id:, requests_sessions:)
      @group_id = group_id
      @sessions = requests_sessions
      @url = URI("https://mbasic.facebook.com/")
      @html = @sessions.get(URI.join(@url,"groups/#{group_id}")).parse_html
      @name = @html.at_xpath("//h1")
      @privacy = @name.nil? ? "unknow" : @name.next_element.text
      @name = @name.nil? ? "unknow" : @name.text
      @formJoin = @html.at_xpath("//form[starts-with(@action, '/a/group/join')]")
      @join = @formJoin.nil?
      @membersTag = @html.at_css("a[href^='/groups/'][href*='view=members']").ancestors("tr")
      @total_members = @membersTag.nil? ? "unknow" : @membersTag.at_css("span[class][id]").text.to_i 
    end

    # Mengembalikan string representasi dari objek Groups.
    #
    # @return [String] Representasi string dari objek Groups.
    def to_s
      return "Facebook Groups : name=#{@name} total_members=#{@total_members} privacy=#{@privacy}  id=#{@group_id} join=#{@join}"
    end

    # Mengembalikan string representasi dari objek Groups.
    #
    # @return [String] Representasi string dari objek Groups.
    def inspect
      return to_s
    end

    # Refresh Halaman dan update data
    def refresh
      initialize(group_id: @group_id, requests_sessions: @sessions)
    end

    # Undang Teman ke grup
    #
    # @param members [Array, String] Daftar anggota grup atau string yang dipisahkan koma
    # @param exceptions [Boolean] Menentukan apakah akan mengangkat pengecualian jika gagal.
    def invite_friends(members, exceptions: true)
      members = members.split(',') if members.class == String
      addTag = @html.at_xpath("//a[starts-with(@href,'/groups/members/search')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat invite teman ke group ini:(") if addTag.nil?
      html = @sessions.get(URI.join(@url, addTag['href'])).parse_html
      form = html.at_xpath("//form[starts-with(@action,'/groups/members/search')]")
      raise FbRuby::Exceptions::FacebookError.new("Terjadi kesalahan, coba lagi nanti") if form.nil?
      formData = {}
      friends = []
      form.css("input[@type = 'hidden']").each{|i| formData[i['name']] = i['value']}
      suges = html.xpath("//input[@type = 'checkbox' and starts-with(@name,'addees[') and not(@checked)]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak ada saran teman untuk di tambahkan ke grup, pastikan akun facebook kamu memiliki teman!") if suges.length.zero?

      for name in members
        name = name.to_s.strip
        if name.match?(/^\d+$/)
          friends << name
        else
          cariData = formData.clone
          cariData['query_term'] = name
          cari = @sessions.post(URI.join(@url,form['action']), data = cariData).parse_html
          result = cari.at_xpath("//input[@type = 'checkbox' and starts-with(@name,'addees[') and not(@checked)]")
          if (result.nil? or result.parent.text != name)
            raise FbRuby::Exceptions::FacebookError.new("Akun facebook dengan nama #{name} tidak di temukan") if exceptions
          else
            friends << result['value']
          end
        end
      end

      friends.each{|i| formData["addees[#{i}]"] = i}
      formData['add'] = 'Submit'
      invite = @sessions.post(URI.join(@url, form['action']), data = formData)

      return invite.ok?
    end

    # Gabung ke grup
    def join_groups
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat join ke grup ini, mungkin kamu sudah bergabung ke grup ini^^") if @join
      data = {}
      @formJoin.css("input[@type='hidden']").each{|i| data[i['name']] = i['value']}
      @sessions.post(URI.join(@url, @formJoin['action']), data = data).parse_html
      refresh()
      return @join
    end

    # Keluar Dari Grup
    def leave_groups
      raise FbRuby::Exceptions::FacebookError.new("Kamu belum bergabung ke group ini") if !@join
      html = @sessions.get(URI.join(@url,"#{@group_id}?view=info")).parse_html
      leaveUrl = html.at_xpath("//a[starts-with(@href,'/group/leave')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat keluar dari groups ini:(") if leaveUrl.nil?
      leaveHtml = @sessions.get(URI.join(@url, leaveUrl['href'])).parse_html
      leaveForm = leaveHtml.at_xpath("//form[starts-with(@action,'/a/group/leave')]")
      leaveData = {}
      leaveForm.css("input[type = 'hidden']").each{|i| leaveData[i['name']] = i['value']}
      leaveData['confirm'] = "Submit"
      submit = @sessions.post(URI.join(@url, leaveForm['action']), data = leaveData)
      return submit.ok?
    end

    # Ikuti Grup Ini
    def follow
      html = @sessions.get(URI.join(@url,"#{@group_id}?view=info")).parse_html
      followUrl = html.at_xpath("//a[starts-with(@href,'/a/subscriptions/add')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat follow grup ini, mungkin kamu sebelum nya sudah follow ke grup ini") if followUrl.nil?
      ikuti = @sessions.get(URI.join(@url, followUrl['href']))
      return ikuti.ok?
    end

    # Berhenti ikuti grup ini
    def unfollow
      html = @sessions.get(URI.join(@url,"#{@group_id}?view=info")).parse_html
      unfollowUrl = html.at_xpath("//a[starts-with(@href,'/a/subscriptions/remove')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat unfollow group ini") if unfollowUrl.nil?
      stop = @sessions.get(URI.join(@url, unfollowUrl['href']))
      return stop.ok?
    end

    # Dapatkan daftar admin dan moderator grup
    #
    # @param limit [Integer] Jumblah maksimal yang akan di ambil
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_admin_moderator(limit, return_hash = true)
      getProfile('list_admin_moderator',limit, return_hash)
    end

    # Dapatkan daftar member yang di undang
    #
    # @param limit [Integer] Jumblah maksimal yang akan di ambil
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_invited_members(limit, return_hash = true)
      getProfile('list_invited',limit,return_hash)
    end

    # Dapatkan daftar member selain dari teman
    #
    # @param limit [Integer] Jumblah maksimal yang akan di ambil
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_other_members(limit, return_hash = true)
      getProfile('list_nonfriend_nonadmin',limit,return_hash)
    end


    # Dapatkan daftar member yang berteman
    #
    # @param limit [Integer] Jumblah maksimal yang akan di ambil
    # @param return_hash [Boolean] Kembalikan Hash jika true
    def get_friends_members(limit, return_hash = true)
      getProfile('list_friend',limit, return_hash)
    end

    # Dapatkan pengumuman grup
    #
    # @return [Array<Posts>,Posts]
    def get_announcements
      posts = []
      html = @sessions.get(URI.join(@url,"/groups/#{@group_id}?view=announcements")).parse_html
      url = html.css("a[href^='https://'][href*='groups'][href*='permalink'][href*='#footer_action_list']")
      url.each{|i| posts << FbRuby::Posts.new(post_url: i['href'], request_session: @sessions)}

      return posts
    end

    # Dapatkan postingan dari grup
    #
    # @param limit [Integer] Jumblah postingan yang akan di ambil
    def get_posts(limit = 5)
      posts = []
      html = @html.clone

      while posts.length < limit
        url = html.css("a[href^='https://'][href*='groups'][href*='permalink'][href*='#footer_action_list']")
        url.each{|i| posts << FbRuby::Posts.new(post_url: i['href'], request_session: @sessions)}
        next_url = html.at_css("a[href^='/groups'][href*='bacr']")
        break if posts.length >= limit or next_url.nil?
        puts next_url['href']
        html = @sessions.get_without_sessions(URI.join(@url, next_url['href'])).parse_html
        
      end

      return posts[0...limit]
    end

    # Buat Postingan di Grup
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
      fullForm = @html.at_xpath("//form[starts-with(@action,'/composer/mbasic')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membuat postingan ke group ini :(") if fullForm.nil?
      fullFormData = {}
      fullForm.css("input[type = 'hidden']").each{|i| fullFormData[i['name']] = i['value']}
      html = @sessions.post(URI.join(@url, fullForm['action']), data = fullFormData).parse_html
      return FbRuby::Utils::create_timeline(html,@sessions, message, file, location, feeling, filter_type, **kwargs)      
    end

    private
      def getProfile(type, limit, return_hash)
        userList = []
        membersUrl = URI.join(@url,"/browse/group/members/?id=#{@group_id}&start=0&listType=#{type}")

        loop do
          tmpUsr = []
          html = @sessions.get(membersUrl).parse_html
          members = html.css('img[alt]')
          members.delete(members.first) if members.length > 1

          for user in members
            userTag = user.parent.parent.at_css('a')
            userUrl = URI.join(@url, userTag['href'])
            next if userUrl.to_s.match?(/\/home\.php/)
            imgUrl = user['src']
            findUid = userUrl.to_s.match(/\/(?:profile\.php\?id=(\d+)|([a-zA-Z0-9_.-]+)\?)/)
            username = (findUid[1].nil? ? findUid[2] : findUid[1])
            tmpUsr << {"name"=>userTag.text,"username"=>username,"profile_url"=>userUrl.to_s,"profile_pict"=>imgUrl}
          end

          if return_hash
            tmpUsr.each do |i|
              break if userList.length >= limit
              userList << i
            end
          else
            threadPool = FbRuby::Utils::ThreadPool.new(size: 5)
            tmpUsr[0...(limit - userList.length)].each do |profile|
              threadPool.schedule {userList << FbRuby::User.new(username: profile['username'], requests_sessions: @sessions)}
            end
            threadPool.shutdown
          end

          next_url = html.at_xpath("//a[starts-with(@href,'/browse/group/members')]")
          break if members.length >= limit or next_url.nil?
          membersUrl = URI.join(@url, next_url['href'])
        end

        return userList
      end
  end
end
