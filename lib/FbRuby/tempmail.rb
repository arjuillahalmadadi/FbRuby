require 'uri'
require_relative "utils.rb"

module FbRuby
  # class TempMail di gunakan untuk mendapatkan email sementara
  class TempMail

    @@domain = ["mailto.plus","fexpost.com","fexbox.org","mailbox.in.ua","rover.info","chitthi.in","fextemp.com","any.pink","merepost.com"].freeze
    attr_reader :domain, :sessions, :email

    def self.domain
      return @@domain
    end

    # Inisialisasi object TempMail
    #
    # @param prefix [String] Nama awalan email
    # @param domain [String] Domain email
    def initialize(prefix = nil, domain = nil)
      raise ArgumentError.new("Invalid Domain") if !domain.nil? and !@@domain.include? (domain)
      @sessions = FbRuby::Utils::Session.new
      @prefix = (prefix.nil? ? FbRuby::Utils::randomString(12) : prefix.strip)
      @domain = (domain.nil? ? @@domain.sample : domain.strip)
      @email = "#{@prefix}@#{@domain}"
      @host = URI("https://tempmail.plus/api/")
    end

    # Dapatkan pesan email baru
    #
    # @param limit [Integer] Jumblah pesan yang ingin di ambil
    def get_new_message(limit = 10)
      return @sessions.get(URI.join(@host,"mails?email=#{@email}&limit=#{limit}")).json
    end

    # Lihat pesan email
    #
    # @param mail_id [String] Id dari pesan email
    def view_mail(mail_id)
      return @sessions.get(URI.join(@host, "mails/#{mail_id}?email=#{@email}")).json
    end

    # Mengembalikan string representasi dari objek TempMail.
    #
    # @return [String] Representasi string dari objek TempMail.
    def to_s
      return "CryptoGmail : prefix=#{@prefix} domain=#{@domain} email=#{@email}"
    end

    # Mengembalikan string representasi dari objek TempMail.
    #
    # @return [String] Representasi string dari objek TempMail.
    def inspect
      return to_s
    end
  end
end
