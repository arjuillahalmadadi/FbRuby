require 'uri'
require 'cgi'
require_relative 'utils.rb'
require_relative 'chats.rb'
require_relative 'exceptions.rb'

# Modul FbRuby untuk melakukan scraping web Facebook.
module FbRuby
  # Class Messenger untuk mengelola pesan di Facebook Messenger.
  class Messenger

    # Inisialisasi objek Messenger.
    #
    # @param request_session [Session] Sesi permintaan yang diperlukan untuk otentikasi.
    def initialize(request_session:)
      @url = URI("https://mbasic.facebook.com")
      @sessions = request_session
      @req = @sessions.get(URI.join(@url,"/messages"))
      @res = @req.parse_html
      
      @new_message = @res.at_xpath("//a[starts-with(@href, '/messages/')]")
      @message_pending = @res.at_xpath("//a[starts-with(@href,'/messages/?folder=pending')]")
      @message_filter = @res.at_xpath("//a[starts-with(@href,'/messages/?folder=other')]")
      @message_archive = @res.at_xpath("//a[starts-with(@href,'/messages/?folder=action') and contains(@href,'Aarchived')]")
      @message_unread = @res.at_xpath("//a[starts-with(@href,'/messages/?folder=unread')]")
      @message_spam = @res.at_xpath("//a[starts-with(@href,'/messages/?folder=spam')]")
    end

    # Mengembalikan string representasi dari objek Messenger.
    #
    # @return [String] Representasi string dari objek Messenger.
    def to_s
      return "Facebook Messenger"
    end

    # Mengembalikan string representasi dari objek Messenger.
    #
    # @return [String] Representasi string dari objek Messenger.
    def inspect
      return to_s
    end
    
    # Membuat chat baru dengan pengguna tertentu.
    #
    # @param username [String] Username pengguna Facebook.
    # @return [FbRuby::Chats] Objek chat baru.
    # @raise [FbRuby::Exceptions::PageNotFound] Jika pengguna tidak di temukan.
    # @raise [FbRuby::Exceptions::FacebookError] Jika ada masalah dalam proses membuat chat baru.
    #
    # @example Membuat chat baru
    #   messenger = FbRuby::Messenger.new(request_session: session)
    #   chat = messenger.new_chat('username')
    def new_chat(username)
      cek = @sessions.get(URI.join(@url,username)).parse_html
      raise FbRuby::Exceptions::PageNotFound.new("Akun dengan username #{@username} tidak di temukan") unless cek.at_xpath("//a[starts-with(@href,'/home.php?rand=')]").nil?
      chatUrl = cek.at_xpath("//a[starts-with(@href, '/messages/thread')]")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{cek.at_css('title').text}") if chatUrl.nil?
      return FbRuby::Chats.new(chats_url: URI.join(@url, chatUrl['href']), request_session: @sessions)
    end

    #Membuat grup chat baru dengan anggota tertentu.
    #
    # @param members [Array, String] Daftar anggota grup atau string yang dipisahkan koma.
    # @param exception [Boolean] Menentukan apakah akan mengangkat pengecualian jika gagal.
    # @param message [String] Pesan awal yang dikirim ke grup.
    # @return (Boolean)Method ini akan mengembalikan true jika berhasil membuat grup, dan akan mengembalikan false jika gagal membuat grup
    # @raise [FbRuby::Exceptions::FacebookError] Jika tidak dapat membuat grup chat.
    def new_group(members, exception: true, message: "Hello:)")
      members = members.split(",") if members.class == String
      urlGroup = @res.xpath_regex("//a[@href~=/^(\/friends\/selector)/]").last
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membuat grup chat:(") if urlGroup.nil?
      html = @sessions.get(URI.join(@url, urlGroup['href'])).parse_html
      suges = html.xpath("//input[@name = 'friend_ids[]']")
      raise FbRuby::Exceptions::FacebookError.new("Akun facebook kamu tidak memiliki teman, tambahkan teman agar bisa membuat pesan grup") if suges.length == 0
      form = html.xpath_regex("//form[@action~=/^(\/friends\/selector)/]").first
      formUrl = URI.join(@url, form['action'])
      formData = {}
      ids = []
      form.css("input[type = 'hidden']").each{|i| formData[i['name']] = i['value']}

      for name in members
        name = name.to_s if name.class != String
        name.strip!
        if !name.match(/^\d+$/)
          data = formData.clone
          data['search'] = 'Search'
          data['query'] = name
          cari = @sessions.post(formUrl, data = data).parse_html
          result = cari.xpath("//input[@name = 'friend_ids[]' and not(@checked)]")
          raise FbRuby::Exceptions::FacebookError.new("Akun dengan nama #{name}, tidak di temukan dari daftar teman:(") if result.length == 0 and exception
          ids << result.first['value'] if result.length > 0
        else
          ids << name
        end
      end

      formData['friend_ids[]'] = ids.join(' , ')
      formData['done'] = "Submit"
      buat = @sessions.post(formUrl, data = formData).parse_html
      buatForm = buat.xpath_regex("//form[@action~=/^(\/messages\/send)/]").first
      buatData = {}
      raise FbRuby::Exceptions::FacebookError.new("Gagal membuat grup chat:(") if buatForm.nil?
      buatForm.xpath("//input[@type = 'hidden']").each{|i| buatData[i['name']] = i['value']}
      ids.each{|i|
        puts i
        buatData["ids[#{i}]"] = i
        buatData["text_ids[#{i}]"] = i
      }
      buatData['body'] = message
      buatData['Send'] = 'Submit'
      action = @sessions.post(URI.join(@url, buatForm['action']), data = buatData)
      return action.ok?
    end
    
    # Mendapatkan chat yang perlu persetujuan
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_chat_pending(limit)
      return getChat(@message_pending, limit)
    end
    
    # Mendapatkan chat yang di filter
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_chat_filter(limit)
      return getChat(@message_filter, limit)
    end
    

    # Mendapatkan chat yang di arsip
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_chat_archive(limit)
      return getChat(@message_archive, limit)
    end


    # Mendapatkan chat yang belum di baca
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_chat_unread(limit)
      return getChat(@message_unread, limit)
    end
    

    # Mendapatkan chat yang ada di dalam folder spam
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_chat_spam(limit)
      return getChat(@message_spam, limit)
    end

    # Mendapatkan chat terbaru
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Chats>] method ini akan mengembalikan Array yang di dalamnya terdapat object Chats
    def get_new_chat(limit)
      return getChat(@new_message, limit)
    end
    
    # Mendapatkan pesan terbaru
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_new_message(limit)
      return getMessage(@new_message, limit)
    end
    
    # Mendapatkan pesan yang perlu persetujuan
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_message_pending(limit)
      return getMessage(@message_pending, limit)
    end

    # Mendapatkan pesan yang di filter
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_message_filter(limit)
      return getMessage(@message_filter, limit)
    end
    
    # Mendapatkan pesan yang di arsip
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_message_archive(limit)
      return getMessage(@message_archive, limit)
    end
    

    # Mendapatkan pesan yang belum di baca
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_message_unread(limit)
      return getMessage(@message_unread, limit)
    end

    # Mendapatkan pesan yang ada di folder spam
    #
    # @param limit [Integer] jumblah maksimal pesan yang di ambil, minimal limit adalah 1    
    # @return [Array<Hash>] method ini akan mengembalikan Array yang di dalamnya terdapat Hash yang memuat informasi chat
    def get_message_spam(limit)
      return getMessage(@message_spam, limit)
    end
    
    
    private
      # Private method untuk scraping chat html
      #
      # @param url [String] URL percakapan di Facebook Messenger.
      # @param limit [Integer] Jumlah maksimum pesan yang diambil.
      # @return [Array<Hash>] Array dari pesan yang diambil.
      def getMessage(url, limit)
        msgArray = []
        return msgArray if url.nil?
        msgUrl = URI.join(@url, url['href'])
        limit.times do
          html = @sessions.get(msgUrl).parse_html
          for data in html.css("a[href^='/messages/read'][href*='#fua']")
            chat_url = URI.join(@url, data['href']).to_s
            data = data.ancestors("div")
            name = data.at_css("a[href^='/messages/read']")
            message = data.at_css("span[class]")
            waktu = data.at_css("abbr")
            uid = nil

            uid = CGI.unescape(name['href']).match(/tid=cid\.(?:c|g)\.(\d+)/)[1] if !name.nil?
            message = message.text if !message.nil?
            waktu = waktu.text if !message.nil?
            name = name.text if !name.nil?

            msgArray << {"name"=>name,"id"=>uid,"last_chat"=>message,"chat_url"=>chat_url,"time"=>waktu}
            break if msgArray.length >= limit
          end
          next_url = html.xpath_regex("//a[@href~=/^(\/messages\/\?pageNum=\d(.*)selectable)/]").first
          break if next_url.nil? or msgArray.length >= limit
          msgUrl = URI.join(@url, next_url['href'])
        end

        return msgArray[0..limit]
      end

      # Mendapatkan chat dari percakapan tertentu.
      #
      # @param url [String] URL percakapan di Facebook Messenger.
      # @param limit [Integer] Jumlah maksimum chat yang diambil.
      # @return [Array<FbRuby::Chats>] Array dari chat yang diambil.
      def getChat(url, limit)
        chatsArray = []
        chatsRead  = getMessage(url,limit)

        th = FbRuby::Utils::ThreadPool.new(size: 6)
        chatsRead.each{|u|
          th.schedule{
            chatsArray << FbRuby::Chats.new(chats_url: u['chat_url'], request_session: @sessions)
          }
        }
        th.shutdown

        return chatsArray[0..limit]
      end
  end
end
