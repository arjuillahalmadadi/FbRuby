require 'uri'
require 'date'
require_relative 'utils.rb'
require_relative 'login.rb'
require_relative 'exceptions.rb'

module FbRuby
  # class CreateAccount di gunakan untuk membuat akun facebook baru
  class CreateAccount < FbRuby::Login::Cookie_Login

    # Inisialisasi Object CreateAccount
    #
    # @param firstname[String] Nama Depan
    # @param lastname[String] Nama Belakang
    # @param email[String] Email atau nomor handphone yang di gunakan untuk mendaftar akun facebook
    # @param gender[String] Jenis Kelamin
    # @param date_of_birth[String<DateTime>, DateTime] Tanggal lahir, untuk format tanggal lahir nya adalah dd/mm/yyyy
    # @param password[String] Kata Sandi Akun Facebook
    # @param headers[Hash] Headers yang akan di gunakan untuk melakukan request saat pembuatan akun
    # @param save_login[Boolean] Simpan informasi login
    # @param free_facebook[Boolean] Gunakan Facebook Versi Gratis
    def initialize(firstname:, lastname:, email:, gender:, date_of_birth:, password:, headers: {}, save_login: true, free_facebook: false)
      @firstname = firstname
      @lastname = lastname
      @email = email
      @gender = gender.downcase
      @date_of_birth = (date_of_birth.kind_of?(DateTime) ? date_of_birth : DateTime.strptime(date_of_birth,"%d/%m/%Y"))
      @password = password
      @headers = headers
      @save_login = save_login
      @free_facebook = free_facebook
      @url = URI("https://mbasic.facebook.com/")
      @sessions = FbRuby::Utils::Session.new(@headers)

      gender_value = {'female'=>'1','male'=>'2','custom'=>'-1'}
      html = @sessions.get(@url).parse_html
      err_req = html.at_css("div[class][id = 'root'][role = 'main']")
      signup_form = html.at_css("form[action^='/login/device-based/regular']")

      if !err_req.nil? and signup_form.nil?
        err_div = err_req.at_css("div[class]")
        raise FbRuby::Exceptions::FacebookError.new(err_div.text)
      end

      signup_data = {"sign_up"=>"Submit"}
      signup_form.css("input[type = 'hidden']").each{|i| signup_data[i['name']] = i['value']}
      signup_value = signup_form.at_css("input[name = 'sign_up'][type = 'submit']")
      raise FbRuby::Exceptions::FacebookError.new('Untuk Saat ini fitur \"CreateAccount\" tidak mendukung pada facebook mobile, untuk mengatasi masalah ini coba ganti User-Agent yang sedang anda gunakan :)') if signup_value.nil?
      reg_html = @sessions.post(URI.join(@url, signup_form['action']), signup_data).parse_html
      reg_form = reg_html.at_css("form[action*='reg/submit']")
      reg_data = {}
      reg_form.css("input[type = 'hidden']").each{|i| reg_data[i['name']] = i['value']}

      if reg_html.at_css("input[name = 'lastname']").nil?
        reg_data["firstname"] = "#{@firstname} #{@lastname}"
      else
        reg_data["firstname"] = @firstname
        reg_data["lastname"] = @lastname
      end

      reg_data["reg_email__"] = @email
      reg_data["sex"] = (gender_value.member?(@gender) ? gender_value[@gender] : '1')
      reg_data["birthday_day"] = @date_of_birth.day
      reg_data["birthday_month"] = @date_of_birth.month
      reg_data["birthday_year"] = @date_of_birth.year
      reg_data["reg_passwd__"] = @password
      reg_data["submit"] = "submit"
      reg_submit = @sessions.post(URI.join(@url, reg_form['action']), data = reg_data)
      reg_res = reg_submit.parse_html
      reg_error = reg_res.at_css("div[id = 'registration-error']")

      File.write("out.html",reg_res.to_s)
      puts reg_submit.request.url
      raise FbRuby::Exceptions::FacebookError.new(reg_error.text) unless reg_error.nil?
      raise FbRuby::Exceptions::FacebookError.new("Gagal membuat akun Facebook, sepertinya anda sudah memiliki akun facebook dengan alamat email \"#{@email}\"") if (reg_submit.request.url.include?("/recover/code/") or reg_submit.request.url.include?('home.php')) and !reg_submit.request.url.include?("confirmemail")
      raise FbRuby::Exceptions::AccountCheckPoint.new("Akun Anda Terkena Checkpoint :(") if (reg_submit.request.url.include? ('checkpoint') or reg_submit.request.cookies.member?('checkpoint'))

      if save_login and reg_submit.request.url.include?('login/save-device/')
        saveLoginForm = reg_res.at_css("form[action^='/login/']")
        saveLoginData = {}
        saveLoginForm.css("input[type = 'hidden']").each{|i| saveLoginData[i['name']] = i['value']}
        @registerRequest = @sessions.post(URI.join(@url, saveLoginForm['action']), data = saveLoginData)
        @registerRespons = @registerRequest.parse_html
      elsif !save_login and reg_submit.request.url.include?('login/save-device/')
        cancel = reg_res.at_css("a[href^='/login/save-device/cancel']")
        @registerRequest = @sessions.get(URI.join(@url,cancel['href']))
        @registerRespons = @registerRequest.parse_html
      end
    end

    # Mengembalikan string representasi dari objek CreateAccount.
    #
    # @return [String] Representasi string dari objek CreateAccount.
    def to_s
      return "Facebook CreateAccount: firstname=#{@firstname}, lastname=#{@lastname}, email=#{@email} gender=#{@gender}, date_of_birth=#{@date_of_birth.strftime("%d/%m/%Y")}, password=#{@password}"
    end

    # Mengembalikan string representasi dari objek CreateAccount.
    #
    # @return [String] Representasi string dari objek CreateAccount.
    def inspect
      return to_s
    end

    # Konfirmasi Pembuatan Akun Facebook
    #
    # @param verification_code[String] Kode Konfirmasi yang di kirim ke email / nomor ponsel
    def confirm_account(verification_code)
      formConfirm = @registerRespons.at_css("form[action^='/confirmemail.php']")
      dataConfirm = {"c"=>verification_code}

      if @registerRequest.request.url.include?('confirmemail.php') and !formConfirm.nil?
        formConfirm.css("input[type = 'hidden']").each{|i| dataConfirm[i['name']] = i['value']}
        submitConfirm = @sessions.post(URI.join(@url, formConfirm['action']), data = dataConfirm)
        responConfirm = submitConfirm.parse_html
        errorConfirm = responConfirm.at_css("div[id = 'm_conf_cliff_root_id']")
        raise FbRuby::Exceptions::FacebookError.new(errorConfirm.text) unless errorConfirm.nil?
        super	
      else
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengkonfirmasi akun!")
      end
    end

    # Kirim ulang kode konfirmasi
    #
    # @return [Boolean]
    def resend_code
      resend = @registerRespons.at_css("input[class][type = 'submit']:not(name)")
      unless resend.nil?
        resendForm = @registerRespons.at_xpath("//form[starts-with(@action,'confirmemail.php')]")
        resendData = {}
        resendForm.css("input[type = 'hidden']").each{|i| resendData[i['name']] = i['value']}
        send = @sessions.post(URI.join(@url, resendForm["action"]), data = resendData)

        return send.ok?
      else
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengirim ulang kode konfirmasi :(")
      end
    end
  end
end

