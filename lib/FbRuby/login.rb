require 'uri'
require 'json'
require 'digest'
require 'nokogiri'
require 'rest-client'
require_relative 'utils.rb'
require_relative 'exceptions.rb'

module FbRuby
  # Login Ke Akun Facebook
  module Login
    # Login ke akun menggunakan metode Cookie
    class Cookie_Login
      
      attr_reader :cookies, :headers, :sessions, :req, :res, :url
      attr_accessor :free_facebook

      # Inisialisasi Object Cookie_Login
      #
      # @param cookies[String] Cookie akun facebook dalam format string
      # @param free_facebook[Boolean] Gunakan web free facebook ketika login
      # @param headers[Hash] Headers Yang akan di gunakan untuk requests sessions
      # @param save_device[Boolean] Simpan Informasi Login
      def initialize(cookies, free_facebook: false, headers: {}, save_device: true)
        @url = URI(free_facebook ? "https://free.facebook.com" : "https://mbasic.facebook.com")
        @cookies = cookies
        @free_facebook = free_facebook
        @headers = headers
        @save_device = save_device

        @sessions = FbRuby::Utils::Session.new(@headers, cookies)
        @login_url = URI.join(@url, get_cookie_dict.member?("c_user") ? "/login.php?next=#{URI.join(@url, '/' + get_cookie_dict['c_user'])}" : "/login.php")
        @req = @sessions.get(@login_url)
        @res = @req.parse_html
        
        if not @res.at_xpath("//form[starts-with(@action,\"/login/device-based/validate-pin\")]").nil?
          raise FbRuby::Exceptions::SessionExpired.new("Waktu sesi sudah kadaluarsa")
        elsif @req.request.url.include? ('checkpoint')
          raise FbRuby::Exceptions::AccountCheckPoint.new("Akun Facebook anda terkena checkpoint")
        elsif @req.request.url.include? ('login.php')
          raise FbRuby::Exceptions::InvalidCookies.new("Cookie tidak valid atau waktu sesi sudah habis")
        end
        
        if @save_device and @req.request.url.include? ('login/save-device/')
          save_device_form = @res.at_xpath("//form[starts-with(@action,\"/login\")]")
          save_device_action = URI.join(@url,save_device_form['action'])
          save_device_data  = {}
          save_device_form.xpath("//input[@type=\"hidden\"]").each{|inp| save_device_data[inp['name']] = inp['value']}
          save_device_data[save_device_form.at_xpath("//input[@type=\"submit\"] | //button[@type=\"submit\"]")['value']] = "submit"
          
          @sessions.post(save_device_action, save_device_data)
          
        elsif not @save_device and @req.request.url.include? ('login/save-device')
          @sessions.get(URI.join(@url, @res.at_xpath("//a[starts-with(@href, \"/login/save-device/cancel\")]")['href']))
        end
        
        form_zero = @res.at_xpath("//form[starts-with(@action,\"/zero/optin/write\")]")
        data_zero = {}
        
        unless form_zero.nil?
          form_zero.xpath("//input[@type=\"hidden\"]").each {|element| data_zero[element['name']] = element['value']}
               
          if free_facebook
            action = URI.join(@url,form_zero['action'])
            button = form_zero.at_xpath("//input[@type=\"submit\"]")
            data_zero[button['value']] = button['type'] unless button.nil?
            @sessions.post(action, data = data_zero)
          else
            data_mode = @sessions.get(URI.join(@url, form_zero.at_xpath("//a[starts-with(@href, \"/zero/optin/write\")]")['href'])).parse_html
            data_form = data_mode.at_xpath("//form[starts-with(@action, \"/zero/optin/write\")]")
            
            unless data_form.nil?
              data_form.xpath("//input[@type=\"hidden\"]").each {|element| data_zero[element['name']] = element['value']}
              button = data_form.at_xpath("//input[@type=\"submit\"]")
              data_zero[button['value']] = button['type'] unless button.nil?
              @sessions.post(URI.join(@url, data_form['action']), data = data_zero)
            end
          end
        end
      end

      # Mengembalikan string representasi dari objek Cookie_Login.
      #
      # @return [String] Representasi string dari objek Cookie_Login.
      def to_s
        return "Facebook Cookie_Login: cookies='#{cookies}' free_facebook=#{free_facebook}" 
      end
      
      # Mengembalikan string representasi dari objek Cookie_Login.
      #
      # @return [String] Representasi string dari objek Cookie_Login.
      def inspect
        return self.to_s
      end

      # Dapatkan cookie dalam format string      
      def get_cookie_str
        if @cookies.instance_of? (Hash)
          return FbRuby::Utils::cookie_hash_to_str
        else
          return @cookies
        end
      end

      # Dapatkan cookie dalam format Hash
      def get_cookie_dict
        unless @cookies.instance_of? (Hash)
          return FbRuby::Utils::parse_cookies_header(@cookies)
        else
          return @cookies
        end
      end

      # Alias untuk get_cookie_dict
      def get_cookie_hash
        return get_cookie_dict
      end

      # Dapatkan akses token pengguna
      def get_token
        data = {'user-agent'=>@headers.member?('user-agent') ? @headers['user-agent'] : FbRuby::Utils::Session.default_user_agent,'referer'=>'https://www.facebook.com/','host'=>'business.facebook.com','origin'=>'https://business.facebook.com','upgrade-insecure-requests'=>'1','accept-language'=>'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7','cache-control'=>'max-age=0','accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8','content-type'=>'text/html; charset=utf-8'}
        req = @sessions.get("https://business.facebook.com/business_locations", data = data, cookies = get_cookie_dict)
        token = req.body.match(/(EAAG\w+)/)
        
        return token[0]
      end

      # Keluar Dari Akun Facebook
      # @param save_device [Boolean] Simpan informasi login
      def logout(save_device = true)
        data = {}
        case @url.host
          when /(mbasic|free)\.facebook\.com/
            req = @sessions.get(URI.join(@url, '/menu/bookmarks'))
            res = req.parse_html
            link = res.at_css("//a#mbasic_logout_button")
            
            unless link.nil?
              link = URI.join(@url, link['href'])
              keluar = @sessions.get(link)
              form_logout = keluar.parse_html.css('//form')
              baye = save_device ? form_logout[0] : form_logout[-1]
              baye_data = {}
              baye_submit = baye.at_xpath("//input[@type=\"submit\"]")
              baye.xpath("//input[@type=\"hidden\"]").each{|inp| baye_data[inp['name']] = inp['value']}
              baye_data[baye_submit['value']] = "submit"
              kirim = @sessions.post(URI.join(@url, baye['action']), data = baye_data)
              
              return kirim.ok?
            end
        end
      end
    end
    
    # Login ke akun facebook menggunakan web mbasic
    class Web_Login < Cookie_Login
      
      attr_reader :url, :email, :password, :free_facebook, :headers, :save_device, :sessions

      # Inisialisasi object Web_Login
      #
      # @param email [String] Email akun facebook, kamu juga bisa menggunakan id atau nama pengguna
      # @param password [String] Kata sandi akun facebook
      # @param free_facebook[Boolean] Gunakan web free facebook ketika login
      # @param headers[Hash] Headers Yang akan di gunakan untuk requests sessions
      # @param save_device[Boolean] Simpan Informasi Login
      def initialize(email,password, free_facebook: false, headers: {}, save_device: true)
        @url = URI(free_facebook ? "https://free.facebook.com" : "https://mbasic.facebook.com")
        @email = email
        @password = password
        @free_facebook = free_facebook
        @headers = headers
        @save_device = save_device
        @sessions = FbRuby::Utils::Session.new(@headers)
        
        @req = @sessions.get(@url)
        @res = @req.parse_html
        
        login_form = @res.at_xpath("//form[starts-with(@action,'/login/device-based/regular')]")
        login_data = {"email"=>@email,"pass"=>@password,"login"=>"submit"}
        login_action = URI.join(@url, login_form['action'])
        login_form.css("input[type = 'hidden'][name][value]").each{|inp| login_data[inp['name']] = inp['value']}

        @submit = @sessions.post(login_action.to_s,login_data)
        @submit_res = @submit.parse_html
        @formSelect = @submit_res.at_css("form[action^='/login/device-based/validate-pin']")

        if !@formSelect.nil?
          dataSelect = {}
          @formSelect.css("input[type = 'hidden']").each{|i| dataSelect[i['name']] = i['value']}
          @click = @sessions.post(URI.join(@url, @formSelect['action']), data = dataSelect).parse_html
          @logForm = @click.at_css("form[action^='/login/device-based/validate-password']")
          @logData = {"pass"=>@password}
          @logForm.css("input[type = 'hidden']").each{|i| @logData[i['name']] = i['value']}
          @submit = @sessions.post(URI.join(@url, @logForm['action']), data = @logData)
          @submit_res = @submit.parse_html
        end
        
        if @submit.request.url.include? ('checkpoint')
          raise FbRuby::Exceptions::AccountCheckPoint.new("Akun Facebook anda terkena checkpoint :(")
        elsif !@submit.request.cookies.member? ('c_user')
          raise FbRuby::Exceptions::LoginFailed.new("Gagal login ke akun, pastikan email dan password anda sudah benar :)")
        end
        
        if @save_device and @submit.request.url.include? ('login/save-device/')
          save_device_form = @submit_res.at_xpath("//form[starts-with(@action,\"/login\")]")
          save_device_action = URI.join(@url,save_device_form['action'])
          save_device_data  = {}
          save_device_form.xpath("//input[@type=\"hidden\"]").each{|inp| save_device_data[inp['name']] = inp['value']}
          save_device_data[save_device_form.at_xpath("//input[@type=\"submit\"] | //button[@type=\"submit\"]")['value']] = "submit"
          
          @res = @sessions.post(save_device_action, save_device_data)
          
        elsif !@save_device and @submit.request.url.include? ('login/save-device/')
          unsave_device_url = URI.join(@url, @submit_res.at_xpath("//a[starts-with(@href, \"/login/save-device/cancel\")]")['href'])
          
          @res = @sessions.get(unsave_device_url)
        end
        
        super(cookies = @sessions.get_cookie_str, free_facebook: @free_facebook, headers: @headers, save_device: @save_device)
      end

      
      # Mengembalikan string representasi dari objek Web_Login.
      #
      # @return [String] Representasi string dari objek Web_Login.
      def to_s
        return "Facebook Web_Login: email='#{@email}' password='#{@password}' free_facebook=#{@free_facebook} save_device=#{@save_device}"
      end
    
      # Mengembalikan string representasi dari objek Web_Login.
      #
      # @return [String] Representasi string dari objek Web_Login.
      def inspect
        return self.to_s
      end
    end

    # Login ke akun facebook menggunakan metode api
    class Api_Login < Cookie_Login

      attr_reader :email, :password

      # Inisialisasi object Api_Login
      #
      # @param email [String] Email akun facebook, kamu juga bisa menggunakan id atau nama pengguna
      # @param password [String] Kata sandi akun facebook
      # @param headers[Hash] Headers Yang akan di gunakan untuk requests sessions
      def initialize(email,password,headers = {})
        @email = email
        @password = password
        @headers = headers
        @sessions = FbRuby::Utils::Session.new(@headers)
        @access_token = nil
        @cookies = nil

        a = 'api_key=882a8490361da98702bf97a021ddc14dcredentials_type=passwordemail=' + email + 'format=JSONgenerate_machine_id=1generate_session_cookies=1locale=en_USmethod=auth.loginpassword=' + password + 'return_ssl_resources=0v=1.062f8ce9f74b12f84c123cc23437a4a32'
        b = {'api_key'=> '882a8490361da98702bf97a021ddc14d', 'credentials_type'=> 'password', 'email': email, 'format'=> 'JSON', 'generate_machine_id'=> '1', 'generate_session_cookies'=> '1', 'locale'=> 'en_US', 'method'=> 'auth.login', 'password'=> password, 'return_ssl_resources'=> '0', 'v'=> '1.0'}
        c = Digest::MD5.new
        c.update(a)
        d = c.hexdigest
        b.update({'sig': d})
        uri = URI("https://api.facebook.com/restserver.php")
        login = JSON.parse(@sessions.get(uri, params = b).body)

        if login.key?("access_token")
          @cookies = login['session_cookies'].map {|i| "#{i['name']}=#{i['value']};"}.join
          @access_token = login['access_token']
          super(cookies = @cookies, free_facebook: false, headers: @headers, save_device: true)
        elsif ((login.key? ('error_msg')) and (login['error_msg'].include? ('www.facebook.com') or login['error_msg'].include? ('SMS')))
          raise FbRuby::Exceptions::AccountCheckPoint.new("Akun Facebook kamu terkena checkpoin:(")
        else
          raise FbRuby::Exceptions::LoginFailed.new(login['error_msg'])
        end
      end

      # Dapatkan token akses pengguna
      def get_token
        return @access_token
      end

      # Mengembalikan string representasi dari objek Api_Login.
      #
      # @return [String] Representasi string dari objek Api_Login.
      def to_s
        return "Facebook Api_Login: email='#{@email}' password='#{@password}'"
      end

      # Mengembalikan string representasi dari objek Api_Login.
      #
      # @return [String] Representasi string dari objek Api_Login.
      def inspect
        return to_s
      end
    end
  end
end
