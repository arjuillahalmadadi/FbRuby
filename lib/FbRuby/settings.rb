require 'uri'
require 'date'
require_relative 'utils.rb'
require_relative 'exceptions.rb'

$url = URI("https://mbasic.facebook.com/")


module FbRuby
  module Settings
    # Kunci Profile akun facebook
    #
    # @param fbobj [Facebook] Facebook object
    # @param locked [Boolean] Kunci profile
    def self.LockProfile(fbobj,locked = true)
      html = fbobj.sessions.get(URI.join($url, "me")).parse_html
      lock = html.at_css("a[href^='/private_sharing/home_view']")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengunci / membuka kunci profile anda!") if lock.nil?
      html = fbobj.sessions.get(URI.join($url, lock['href']))
      form = html.parse_html.at_css("form[action^='/private_sharing_mutation']")
      if !form.nil? and locked
        data = {}
        form.css("input[type = 'hidden']").each{|i| data[i['name']] = i['value']}
        submit = fbobj.sessions.post_without_sessions(URI.join($url, form['action']))

        return submit.ok?
      elsif form.nil? and !locked
        unlock = html.parse_html.at_css("a[href^='/private_sharing/revert/unlock_profile']")
        buka = fbobj.sessions.get(URI.join($url, unlock['href'])).parse_html
        unlockForm = buka.at_css("form[action^='/private_sharing/unlock_profile_rpp']")
        unlockData = {}
        unlockForm.css("input[type = 'hidden']").each{|i| unlockData[i['name']] = i['value']}
        unlockAction = fbobj.sessions.post(URI.join($url, unlockForm['action']), data = unlockData)
      
        return unlockAction.ok?
      elsif !form.nil? and !locked
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat membuka kunci profile, karena anda belum mengunci profile tersebut!")
      elsif form.nil? and locked
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengunci profile, karena profile ini sudah di kunci!!!m")
      end
    end

    # Atur bahasa facebook
    #
    # @param fbobj [Facebook] Facebook object
    # @param locale [String] Locale bahasa yang ingin di ganti
    def self.SetLanguage(fbobj, locale)
      html = fbobj.sessions.get(URI.join($url, "/language")).parse_html
      form = html.at_css("form[action^='/intl/save_locale'][action*='loc=#{locale}']")
      data = {}
      raise FbRuby::Exceptions::FacebookError.new("Invalid Locale!!!") if form.nil?
      form.css("input[type = 'hidden']").each{|i| data[i['name']] = i['value']}
      begin
        ganti = fbobj.sessions.post_without_sessions(URI.join($url, form['action']), data = data)
        return ganti.ok?
      rescue RestClient::Found
        return true
      end
    end

    # Dapatkan locale bahasa
    # @param fbobj [Facebook] Facebook object
    def self.GetLocale(fbobj = nil)
      locale = {}
      sessions = (fbobj.nil? ? FbRuby::Utils::Session.new : fbobj.sessions)
      html = sessions.get(URI.join($url, "/language")).parse_html
      loc = html.css("form[action^='/intl/save_locale/'][action*='loc']")

      for lang in loc
        locale[lang['action'].match(/loc=(\w+)/)[1]] = lang.at_css("input[type = 'submit']")['value']
      end

      return locale
    end

    # Ganti kata sandi akun
    #
    # @param fbobj [Facebook] Facebook object
    # @param old_pass [String] Kata sandi lama
    # @param new_pass [String] Kata sandi baru
    # @param keep_session [Boolean] Keep Session
    def self.ChangePassword(fbobj, old_pass, new_pass, keep_session = false)
      html = fbobj.sessions.get(URI.join($url, "/settings/security/password")).parse_html
      form = html.at_css("form[action^='/password/change']")
      data = {"password_old"=>old_pass,"password_new"=>new_pass,"password_confirm"=>new_pass}
      form.css("input[name][value]").each{|i| data[i['name']] = i['value']}
      ganti = fbobj.sessions.post(URI.join($url, form['action']), data = data)
      gantiHtml = ganti.parse_html

      if ganti.request.url.include? ('/settings/security/password') or ganti.request.url.include?('secured_action/block/')
        err = "Terjadi Kesalahan :("
        div_err = gantiHtml.at_css("div[id = 'root'][class], div[id = 'root'][role = 'main']")
        err = div_err.at_css("div[class]").text if !div_err.nil?

        raise FbRuby::Exceptions::FacebookError.new(err)
      else
        formSession = gantiHtml.at_css("form[action^='/settings/account/password/survey']")
        dataSession = {"session_invalidation_options"=>(keep_session ? 'keep_sessions' : 'review_sessions')}
        formSession.css("input[type = 'hidden']").each{|i| dataSession[i['name']] = i['value']}
        submit = fbobj.sessions.post_without_sessions(URI.join($url, formSession['action'])).parse_html

        if keep_session
          return submit.ok?
        else
          review = submit.at_css("a[href^='/settings/security_login/sessions/log_out_all/confirm']")
          return fbobj.sessions.get(URI.join($url, review['href'])).ok?
        end
      end
    end

    # Atur Facebook site
    #
    # @param fbobj [Facebook] Facebook Object
    # @param set_to [String] Versi Facebook "reguler" atau "basic"
    def self.SetFacebookSite(fbobj, set_to)
      site_list = ['reguler','basic']
      raise FbRuby::Exceptions::FacebookError.new("Facebook site tidak valid!!") if !site_list.include?(set_to)

      begin
        html = fbobj.sessions.get(URI.join($url, "/settings/site")).parse_html
      rescue then html = fbobj.sessions.get_without_sessions(URI.join($url, "/settings/site")).parse_html
      end

      form = html.at_css("form[action^='/a/preferences.php']")
      data = {}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      basic = form.css("input[name = 'basic_site_devices']")
      index = site_list.index(set_to)
      data[basic[index]['name']] = basic[index]['value']
      return fbobj.sessions.post(URI.join($url, form['action']), data = data).ok? 
    end

    
    # Ganti Foto Profile akun
    #
    # @param fbobj [Facebook] Facebook object
    # @param profile_picture [String] Path foto 
    def self.UpdateProfilePicture(fbobj, profile_picture)
      html = fbobj.sessions.get(URI.join($url, "/me?v=info")).parse_html
      gantiUrl = html.at_css("a[href^='/profile_picture']")
      if gantiUrl.nil?
        gantiUrl = html.at_css("a[href^='/photo.php'][id]")
        raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengganti foto profile!") if gantiUrl.nil?
        photo = fbobj.sessions.get(URI.join($url, gantiUrl['href'])).parse_html.at_css("a[href^='/photos/change/profile_picture']")
        imgHtml = fbobj.sessions.get(URI.join($url, photo['href'])).parse_html
      else
        imgHtml = fbobj.sessions.get(URI.join($url, gantiUrl['href'])).parse_html
      end

      uploadForm = imgHtml.at_css("form[action*='z-upload'], form[action*='upload.facebook.com']")
      uploadData = {}
      uploadForm.css("input[type = 'hidden']").each{|i| uploadData[i['name']] = i['value']}
      fileName = uploadForm.at_css("input[type = 'file']")['name']

      return FbRuby::Utils::upload_photo(fbobj.sessions, URI.join($url,uploadForm['action']), profile_picture, uploadData).last.ok?
    end

    # Ganti Foto Sampul akun
    #
    # @param fbobj [Facebook] Facebook object
    # @param cover_picture [String] Path foto sampul
    def self.UpdateCoverPicture(fbobj, cover_picture)
      html = fbobj.sessions.get(URI.join($url, "me")).parse_html
      coverUrl = html.at_css("a[href^='/cover_photo']")
      raise FbRuby::Exceptions::FacebookError.new("Tidak dapat mengganti foto sampul :(") if coverUrl.nil?
      coverHtml = fbobj.sessions.get(URI.join($url, coverUrl['href'])).parse_html
      pilihCover = coverHtml.at_css("a[href^='/photos/upload'][href*='cover_photo']")
      coverHtml = fbobj.sessions.get(URI.join($url, pilihCover['href'])).parse_html unless pilihCover.nil?
      coverForm = coverHtml.at_css("form[action^='/timeline/cover/upload']")
      coverData = {}
      coverForm.css("input[type = 'hidden']").each{|i| coverData[i['name']] = i['value']}

      begin
        return FbRuby::Utils::upload_photo(fbobj.sessions, URI.join($url,coverForm['action']), cover_picture, coverData).last.ok?
      rescue FbRuby::Exceptions::PageNotFound
        return true
      end
    end

    # Perbarui bio akun facebook
    #
    # @param fbobj [Facebook] Facebook Object
    # @param bio [String] Bio, maksimal jumblah karakter adalah 101
    # @param publish_feed [Boolean] Publish update ke beranda
    def self.UpdateBio(fbobj, bio, publish_feed = false)
      raise FbRuby::Exceptions::FacebookError.new("Bio facebook maksimal 101 karakter!!") if bio.length > 101
      raise FbRuby::Exceptions::FacebookError.new("Bio facebook minimal 1 karakter") if bio.length.zero?
      html = fbobj.sessions.get(URI.join($url, "/profile/basic/intro/bio/")).parse_html
      form = html.at_css("form[action^='/profile/intro/bio/save']")
      data = {"bio"=>bio}
      data["publish_to_feed"] = "on" if publish_feed
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      return fbobj.sessions.post(URI.join($url, form['action']), data = data).ok?
    end

    # Perbarui Kutipan Favorit
    #
    # @param fbobj [Facebook] Facebook Object
    # @param quote [String] Kutipan Favorit
    def self.UpdateQuote(fbobj, quote)
      raise FbRuby::Exceptions::FacebookError.new("Panjang Quote minimal adalah 1 karakter!") if quote.length.zero?
      html = fbobj.sessions.get(URI.join($url, 'profile/edit/infotab/section/forms/?section=quote')).parse_html
      form = html.at_css("form[action^='/profile/edit/quote']")
      data = {"quote"=>quote,"save"=>"submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      return fbobj.sessions.post(URI.join($url, form["action"]), data = data).ok?
    end

    # Perbarui status hubungan
    #
    # @param fbobj [Facebook] Facebook Object
    # @param status [String] Status hubungan
    # @param partner [String] Id akun facebook dari pasangan
    def self.UpdateRelationship(fbobj, status, partner = nil)
      status.downcase!
      action = ["none","single","in a relationship","in an open relationship","married","engaged","it's complicated","widowed","separated","divorced","in a civil union","in a domestic partnership"]
      raise FbRuby::Exceptions::FacebookError.new("Status hubungan tidak valid!!!") unless action.include?(status)
      html = fbobj.sessions.get(URI.join($url, "/editprofile.php?type=basic&edit=relationship&action=#{action.index(status)}")).parse_html
      form = html.at_css("form[action^='/a/editprofile.php']")
      data = {"save"=>"submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      data["id"] = partner unless partner.nil?
      return fbobj.sessions.post(URI.join($url, form['action']), data = data).ok?
    end

    # Perbarui Anniversary
    #
    # @param fbobj [Facebook] Facebook Object
    # @param date [String, DateTime] Tanggal Anniversary, format nya adalah dd/mm/yyyy
    def self.UpdateAnniversary(fbobj, date)
      date = (date.kind_of?(DateTime) ? date : DateTime.strptime(date, "%d/%m/%Y"))
      raise FbRuby::Exceptions::FacebookError.new("Format tanggal tidak valid!!!") if date > DateTime.now
      html = fbobj.sessions.get(URI.join($url, '/editprofile.php?type=basic&edit=anniversary')).parse_html
      form = html.at_css("form[action^='/a/editprofile.php']")
      data = {"month"=>date.mon,"day"=>date.day,"year"=>date.year,"save"=>"Submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      return fbobj.sessions.post(URI.join($url, form["action"]), data = data).ok?
    end

    # Perbarui About me
    #
    # @param fbobj [Facebook] Facebook Object
    # @param aboutme [String] About me
    def self.UpdateAboutme(fbobj, aboutme)
      raise FbRuby::Exceptions::FacebookError.new("Panjang minimal about me adalah 1 karakter!") if aboutme.length.zero?
      html = fbobj.sessions.get(URI.join($url, '/profile/edit/infotab/section/forms/?section=bio')).parse_html
      form = html.at_css("form[action^='/profile/edit/aboutme']")
      data = {"bio"=>aboutme,"save"=>"submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      return fbobj.sessions.post(URI.join($url, form['action']), data = data).ok?
    end

    # Perbarui kota saat ini
    #
    # @param fbobj [Facebook] Facebook Object
    # @param newcity [String] Kota saat ini
    def self.UpdateCurrentCity(fbobj,newcity)
      html = fbobj.sessions.get(URI.join($url, '/editprofile.php?type=basic&edit=current_city')).parse_html
      form = html.at_css("form[action^='/a/editprofile.php']")
      data = {"current_city[]"=>newcity,"save"=>"submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      submit = fbobj.sessions.post(URI.join($url, form['action']), data = data)
      raise FbRuby::Exceptions::FacebookError.new("Kota dengan nama #{newcity} tidak di temukan!") if !submit.parse_html.at_css("form[action^='/a/editprofile.php']").nil?
      return submit.ok?
    end

    # Perbarui Kota Asal
    #
    # @param fbobj [Facebook] Facebook Object
    # @param hometown [String] Kota asal
    def self.UpdateHometown(fbobj, hometown)
      html = fbobj.sessions.get(URI.join($url, '/editprofile.php?type=basic&edit=hometown')).parse_html
      form = html.at_css("form[action^='/a/editprofile.php']")
      data = {"hometown[]"=>hometown,"save"=>"submit"}
      form.css("input[type = 'hidden'][name][value]").each{|i| data[i['name']] = i['value']}
      submit = fbobj.sessions.post(URI.join($url, form['action']), data = data)
      raise FbRuby::Exceptions::FacebookError.new("Kota dengan nama #{newcity} tidak di temukan!") if !submit.parse_html.at_css("form[action^='/a/editprofile.php']").nil?
      return submit.ok?
    end
  end
end

