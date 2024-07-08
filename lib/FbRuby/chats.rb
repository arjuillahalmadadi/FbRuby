require 'cgi'
require 'uri'

require_relative 'exceptions.rb'

module FbRuby
  # Class Chats di gunakan untuk mengirim pesan, dan menerima pesan
  class Chats

    # Daftar Nama Stiker Yang Tersedia
    #  Key  : Nama Stiker
    #  value: Id Stiker
    @@stiker_pack = {
        'smile'=> 529233727538989,
        'crying'=> 529233744205654,
        'angry'=> 529233764205652,
        'heart_eyes'=> 529233777538984,
        'happy_heart'=>529233794205649,
        'laugh'=>529233810872314,
        'fearful'=>529233834205645,
        'sleeping'=>529233847538977,
        'grimacing'=>529233954205633,
        'creazy_face'=>529233967538965,
        'smiling_face_with_sunglasses'=>529233864205642,
        'face_with_spiral_eyes'=>529233884205640,
        'face_blowing_a_kiss'=>529233917538970,
        'face_vomiting'=>529233937538968,
        'face_screaming'=>529233980872297,
      }
      
    class << self
      def stiker_pack
        return @@stiker_pack
      end
    end
      
    attr_reader :chats_url, :chat_info

    # inisialisasi Object Chats
    #
    # @param chats_url[String] Url Dari Chat
    # @param request_session[Session] Object Session
    def initialize(chats_url:, request_session:)
      @sessions = request_session
      @url = URI("https://mbasic.facebook.com")
      @chats_url = URI(chats_url)
      
      @chats_url.host = @url.host if @chats_url.host != @url.host
      
      @req = @sessions.get_without_sessions(@chats_url)
      @res = @req.parse_html
      @chat_info = {"name"=>nil,"id"=>nil,"chat_id"=>nil,"chats_url"=>@chats_url.to_s,"chat_type"=>"unknow","blocked"=>"unknow"}
      @data_other = {}
      @skip_data =  ['searech', 'search_source','query', 'like', 'send_photo','unread', 'delete', 'delete_selected', 'archive', 'ignore_messages', 'block_messages', 'message_frx','unarchive','unblock_messages','add_people','leave_conversation',nil]
      @message_form = @res.at_xpath("//form[starts-with(@action, \"/messages/send\")]")
      @message_data = {}
      
      unless @res.at_xpath("//a[starts-with(@href,'/messages/compose')]").nil?
        @chat_info['name'] = @res.at_xpath("//input[@type = 'hidden'and starts-with(@name,'text_ids')]")['value']
      else
        @chat_info['name'] = @res.at_css('title').text
      end
      
      unless @message_form.nil?
        @message_form.xpath("//input[@type=\"hidden\"]").each{|i| @message_data.update({i['name']=>i['value']})}
        message_submit = @message_form.at_xpath("//*[@type=\"submit\" and @name=\"send\"]")
        @message_data[message_submit['value']] = "submit" unless message_submit.nil?
        @message_data.each do |k,v|
          if k.match(/^ids\[\d+\]/)
            @chat_info['id'] = v
            break
          end
        end
      end
      
      @messages_redirect_form = @res.at_css("form[action^='/messages/action_redirect']")
      @messages_redirect_data = {}
      unless @messages_redirect_form.nil?
        @messages_redirect_form.css("input").each{|i| @messages_redirect_data.update({i['name']=>i['value']})}
        tid = CGI.unescape(@messages_redirect_form['action']).match(/tid=cid\.(.?)\.((\d+:\d+)|\d+)/)
        @chat_info['chat_id'] = tid[2] unless tid.nil?
        @chat_info['chat_type'] = (@messages_redirect_data.include? ('leave_conversation') or @messages_redirect_form['action'].include? ('cid.g.')) ? "group" : "user"
        @chat_info['blocked'] = @messages_redirect_data.include? ('unblock_messages')
      end
      
      @res.css('input[type="submit"]').each{|i| @data_other.update({i['name']=>i['value']}) if @skip_data.include? (i['name'])}
      @message_data.delete_if {|k,v| k.nil? or v.nil? or @skip_data.include? (k)}
      @link_stiker = @res.at_xpath("//a[starts-with(@href,\"/messages/sticker_picker/\")]")
    end

    # Mengembalikan string representasi dari objek Chats.
    #
    # @return [String] Representasi string dari objek Chats.
    def to_s
      return "Facebook Chats : name=#{@chat_info['name'].inspect} id=#{@chat_info['id'].inspect} chat_id=#{@chat_info['chat_id'].inspect} chat_type=#{@chat_info['chat_type'].inspect}"
    end
    
    # Mengembalikan string representasi dari objek Chats.
    #
    # @return [String] Representasi string dari objek Chats.
    def inspect
      return self.to_s
    end

    # Perbarui halaman
    def refresh
      initialize(chats_url: @chats_url, request_session: @sessions)
    end
    
    def [](item)
      return @chat_info[item]
    end
    
    def method_missing(method_name, *args)
      key = method_name.to_s
      if @chat_info.key?(key)
        return @chat_info[key]
      else
       super
     end
    end

    def respond_to_missing?(method_name, include_private = false)
      @chat_info.key?(method_name.to_s) || super
    end
    
    # Mendapatkan chat dari url
    #
    # @param chats_url[String] Chat url
    # @return [Hash] method ini akan mengembalikan Hash yang memuat informasi chat
    def get_messages(chats_url)
      data = {"chat"=>[], "previous_chats"=>nil}
      
      @req = @sessions.get(chats_url)
      @res = @req.parse_html
      prev_msg = @res.at_css('div#see_older')
      msg = @res.at_css('div#messageGroup')
      
      return data if msg.nil?
      
      unless prev_msg.nil?
        data['previous_chats'] = URI.join(@url,prev_msg.at_css('a')['href']).to_s
        prev_msg.remove
      end
      
      for moya in msg.css('div div a')
        echaa = moya.parent
        next if echaa.nil?
        profile = echaa.at_css('a')
        next unless profile['href'].match(/^\/([a-zA-Z0-9_.-]+|profile\.php)\?/)
        
        username = profile['href'].match(/^\/([a-zA-Z0-9_.-]+)\?/)
        chat_data = {"name"=>profile.text,"username"=>(username[1] if !username.nil? and !profile['href'].include?('profile.php')),"message"=>[],"file"=>[],"stiker"=>[],"time"=>nil}
        
        for pesan in echaa.css('span')
          next if (!pesan['class'].nil? or !pesan['aria-hidden'].nil? or !pesan['style'].nil? or pesan.text.empty?)
          chat_data['message'] << pesan.text.strip
        end
        
        for file in echaa.css('a[href^="/messages/attachment_preview/"], a[href^="/video_redirect"]')
          files = {"link"=>nil,"id"=>nil,"file_size"=>nil,"preview"=>nil,"content_type"=>nil,"content_length"=>nil}
          get_id = lambda {|url| x = url.match(/(\d+_\d+_\d+)/); return ((!x.nil?) ? x[0] : nil)}
          
          files['link'] = (file['href'].include?('/messages/attachment_preview')) ? file.at_css('img')['src'] : CGI.unescape(file['href']).match(/src=(.*)/)[1]
          files['id'] = get_id.call(files['link'])
          file_head = @sessions.head(files['link']).headers
          files['file_size'] = (file_head.member?(:content_length)) ? FbRuby::Utils::convert_file_size(file_head[:content_length].to_i) : nil
          files['preview'] = URI.join(@url, file['href']).to_s
          files['content_type'] = file_head[:content_type]
          files['content_length'] = file_head[:content_length].to_i
          chat_data['file'] << files
        end
        
        for stiker in echaa.css('img')
          next if (stiker['alt'].nil? or stiker['class'].nil?)
          chat_data['stiker'] << {"stiker_name"=>stiker['alt'], "stiker_url"=>stiker['src']}
        end
        
        waktu = echaa.parent.at_css('abbr')
        chat_data['time'] = waktu.text unless waktu.nil?
        
        data['chat'] << chat_data
      end
      return data
    end

    # Mendapatkan pesan di chat (Tanpa Url)
    #
    # @param limit [Integer] Jumblah maksimal pesan yang ingin di dapatkan
    # return[Array<Hash>] Method ini akan mengembalikan Array yang di dalam nya ada Hash yanb memuat daftar percakapan
    def get_message(limit)
      pesan = []
      url = self['chats_url']
      
      while pesan.length < limit
        dump = get_messages(url)
        pesan.concat(dump['chat'])
        break if dump['previous_chats'].nil?
        url = dump['previous_chats']
      end
      
      return pesan[0...limit]
    end

    # Kirim Pesan Teks
    #
    # @param message[String] Pesan yang akan di kirim
    # @return [Boolean] Method ini akan mengembalikan true jika berhasil mengirim pesan
    def send_text(message)
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{self.name} di karenakan anda telah memblokir akun tersebut!!!") if self.blocked == true
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{self.name} :(") if @message_form.nil?
      raise FbRuby::Exceptions::FacebookError.new("Panjang pesan minimal 1 karakter, dan harus di awali dengan non-white space character!") if message.strip.empty?

      data = @message_data.clone
      data.update({'body'=>message})
      kirim = @sessions.post(URI.join(@url,@message_form['action']), data = data)
      return kirim.ok?
    end

    # Kirim Pesan & Foto
    #
    # @param file[Array<String>, String] Lokasi Dari File Foto
    # @param message[String] Pesan yang akan di sertakan saat mengirim foto
    # @return [Boolean] Method ini akan mengembalikan true jika berhasil mengirim pesan
    # @example Kirim 1 foto
    #  chat.send_images("fotoku.jpg","Pesan")
    # @example Kirim lebih dari 1 foto
    #  chat.send_images(["foto1.jpg","foto2.jpg"], "Pesan")
    def send_images(file, message = nil)
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{self.name} di karenakan anda telah memblokir akun tersebut!!!") if self.blocked == true
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim pesan ke #{self.name} :(") if @message_form.nil?
      
      forms = @res.at_css('form[action^="https://"][action*="z-upload.facebook.com"], form[action^="https://"][action*="upload.facebook.com"]')
      
      if forms.nil?
        data = @message_data.clone
        data.delete(data.keys[data.values.index("submit")]) if data.values.include? ("submit")
        data.update({'send_photo'=> @data_other['send_photo']})
        moya = @sessions.post(URI.join(@url, @message_form['action']), data = data)
        forms = moya.parse_html.at_css('form[action^="https://"][action*="z-upload.facebook.com"], form[action^="https://"][action*="upload.facebook.com"]')
      end
      
      forms_data = {'body'=>message.to_s}
      forms.css('input[type="hidden"]').each{|i| forms_data.update({i['name']=>i['value']})}

      begin      
        return FbRuby::Utils::upload_photo(@sessions, forms['action'], files = file, data = forms_data).last.ok?
      rescue FbRuby::Exceptions::PageNotFound
        return true
      end
    end

    # Kirim Stiker Dengan ID
    #
    # @param sticker_id[String] Id dari Sticker
    # @return [Boolean] Method ini akan mengembalikan true jika berhasil mengirim stiker
    def send_stickers(sticker_id)
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim stiker ke \"#{self['name']}\" :(") if @link_stiker.nil?
      stiker_form = @sessions.get_without_sessions(URI.join(@url,@link_stiker['href'])).parse_html.at_css("form[action^=\"/messages/send\"]")
      data = {'sticker_id'=>sticker_id.to_s}
      stiker_form.css('input[type="hidden"]').each{|i| data.update({i['name']=>i['value']})}
      kirim = @sessions.post(URI.join(@url,stiker_form['action']), data = data)
      
      return kirim.ok?
    end

    # Kirim Stiker Dengan Nama
    #
    # @param stiker_name[String] Nama Dari Stiker
    # @return [Boolean] Method ini akan mengembalikan true jika berhasil mengirim stiker
    def send_sticker(stiker_name)
      stiker_name.downcase!
      if stiker_name == 'like'
        data = @message_data.clone
        data.update({'like'=>@res.at_xpath("//input[@name=\"like\"]")['value']})
        kirim = @sessions.post(URI.join(@url,@message_form['action']), data = data)
        
        return kirim.ok?
      else
        raise FbRuby::Exceptions::FacebookError.new("Stiker dengan nama #{stiker_name} tidak di temukan") unless @@stiker_pack.member?(stiker_name)
        send_stickers(@@stiker_pack[stiker_name])
      end
    end

    # Alias Untuk Mengirim Stiker Suka
    #
    # @return [Boolean] Method ini akan mengembalikan true jika berhasil mengirim stiker
    def send_like_stiker
      send_sticker('like')
    end

    # Tandai Chat Sebagai Belum Di Baca
    #
    # @return [Boolean]
    def mark_as_unread
      chat_action('unread')
    end

    # Arsip Chat
    #
    # @return [Boolean]
    def archive_chat
      chat_action('archive')
    end

    # Batalkan Pengarsipan Chat
    #
    # @return [Boolean]
    def unarchive_chat
      chat_action('unarchive')
    end

    # Hapus Semua Pesan
    #
    # @return [Boolean]
    def delete_chat
      chat_action_with_confirm('delete', '/messages/action/?mm_action=delete')
    end

    # Abaikan chat / Bisukan Pesan Ini
    #
    # @return [Boolean]
    def ignore_chat
      chat_action_with_confirm('ignore_messages', '/nfx/ignore_messages/confirm/')
    end

    # Blokir Chat
    #
    # @return [Boolean]
    def block_chat
      chat_action_with_confirm('block_messages', '/nfx/block_messages/confirm/')
    end

    # Buka Blokir Chat
    #
    # @return [Boolean]
    def unblock_chat
      chat_action_with_confirm('unblock_messages', '/nfx/unblock_messages/confirm/')
    end

    private 
      def chat_action(action)
        if !@messages_redirect_data.nil? && @messages_redirect_data.member?(action)
          data = {}
          @messages_redirect_form.css("input[type = 'hidden']").each{|i| data[i['name']] = i['value']}
          data[action] = @messages_redirect_data[action]
          submit = @sessions.post(URI.join(@url,@messages_redirect_form['action']), data = data)
          
          if block_given?
            yield(submit)
          else
            return submit.ok?
          end
        else
          return false
        end
      end
    
      def chat_action_with_confirm(action, url_confirm)
        chat_action(action) do |res|
          url = URI.join(@url, res.parse_html.at_css("a[href^='#{url_confirm}']")['href'])
          confirm = @sessions.get_without_sessions(url)
          
          return confirm.ok?
        end
      end

  end
end
