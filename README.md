# FbRuby

**FbRuby** adalah library sederhana yang di gunakan untuk scraping web Facebook.

# Informasi Library
*Author :* [**Rahmat adha**](https://facebook.com/Anjay.pro098)\
*Library :* [**FbRuby**](https://github.com/MR-X-Junior/fbruby)\
*License:* [**MIT License**](https://github.com/MR-X-junior/fbruby/blob/main/LICENSE)\
*Release:* 08/07/2024\
*Version :* **0.0.1**

Library ini merupakan remake dari library [fbthon](https://github.com/MR-X-Junior/fbthon)\
Di karenakan library ini masih versi pertama, pasti bakal banyak error/bug nya, jika menemukan error/bug pada library ini bisa langsung posting di [Issues](https://github.com/MR-X-junior/fbruby/issues) akun github saya :)

**Ini bukan dokumentasi full dari library FbRuby, masih banyal hal yang bisa di lakukan menggunakan library ini.**
**Dokumentasi ini hanya memuat fitur umum yang di gunakan untuk scraping web facebook**

## Contoh Cara Penggunaan

### Pertama-tama buat dulu object `Facebook` menggunakan cookie

```ruby
irb(main):001:0> require 'fbruby'
irb(main):002:0> fb = FbRuby::Facebook.new("datr=xxxx")
```

### Jika tidak tidak mempunyai Cookie akun facebook, kamu bisa coba cara di bawah ini

```ruby
irb(main):001:0> require 'fbruby'
irb(main):002:0> email = "example@gmail.com"
irb(main):003:0> password = "admin123#"
irb(main):004:0> login = FbRuby::Login::Web_Login.new(email,password)
irb(main):005:0> cookie = login.get_cookie_str() # Ini adalah cookie akun Facebook kamu
irb(main):006:0> fb = FbRuby::Facebook.new(cookie)
```

Cara di [atas](#Jika-tidak-tidak-mempunyai-Cookie-akun-facebook-kamu-bisa-coba-cara-di-bawah-ini) akan login ke akun facebook, cara ini mungkin akan membuat akun facebook kamu terkena checkpoint.

Untuk mengurangi risiko akun terkena checkpoint, kamu hanya perlu mengganti user-agent yang sama dengan perangkat yang terakhir kali di gunakan untuk login akun facebook.

```ruby
irb(main):001:0> require 'fbruby'
irb(main):002:0> user_agent = {'User-Agent'=>'Mozilla/5.0 (Linux; Android 6.0.1; SM-J510GN Build/MMB29M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.111 Mobile Safari/537.36'}
irb(main):003:0> email = "example@gmail.com"
irb(main):004:0> password = "admin123#"
irb(main):005:0> login = FbRuby::Login::Web_Login.new(email,password,headers: user_agent)
irb(main):006:0> cookie = login.get_cookie_str() # Ini adalah cookie akun Facebook kamu
irb(main):007:0> fb = FbRuby::Facebook.new(cookie)
```

#### Optional Parameter
*(Untuk `Web_Login` class)*.

- **email**: Email akun Facebook, kamu juga bisa menggunakan id atau username sebagai pengganti email
- **password**: Password akun Facebook
- **save_login**:  Menyimpan informasi login, default argument ini adalah `True`
- **free_facebook**: Gunakan `True` jika ingin menggukan web [free.facebook.com](https://free.facebook.com), default argument ini adalah `False`
- **headers**: ini  yang akan di gunakan untuk headers `requests`

### Extract Profile

Method `get_profile` dapat mengekstrak informasi dari akun facebook, Method ini akan mengembalikan object `User`

```ruby
irb(main):003:0> zuck = fb.get_profile("zuck")
irb(main):004:0> zuck.name
=> "Mark Zuckerberg"
irb(main):005:0> zuck.id
=> "4"
irb(main):006:0> zuck.user_info
=>
{"name"=>"Mark Zuckerberg",
 "first_name"=>"Mark",
 "middle_name"=>nil,
 "last_name"=>"Zuckerberg",
 "alternate_name"=>nil,
 "about"=>"I'm trying to make the world a more open place.",
 "username"=>"zuck",
 "id"=>"4",
 "contact_info"=>{"Facebook"=>"/zuck"},
 "profile_pict"=>
  "https://scontent.fsri1-1.fna.fbcdn.net/v/t39.30808-1/430796318_10115540567190571_8582399341104871939_n.jpg?stp=cp0_dst-jpg_e15_p74x74_q65&_nc_cat=1&ccb=1-7&_nc_sid=6738e8&efg=eyJpIjoiYiJ9&_nc_eui2=AeHQSiRakzAb_b4HMsaXKlBB3zoKFLy_VnHfOgoUvL9WcT8fYXzsEF17SuUlv21wIR24YwfaSCPTzB2o7sbKvnKv&_nc_ohc=VNHCRlcOVWYQ7kNvgHreskn&_nc_ht=scontent.fsri1-1.fna&oh=00_AYAVtyX9DcSjX7XVYPNiJzZe0DTCzrpd6CrkEcDleE7TlQ&oe=668F2433",
 "basic_info"=>
  {"Birthday"=>"May 14, 1984",
   "Gender"=>"Male",
   "Languages"=>"English language and Mandarin Chinese"},
 "education"=>
  [{"name"=>"Harvard University",
    "type"=>"Computer Science and Psychology",
    "study"=>nil,
    "time"=>"August 30, 2002 - April 30, 2004"},
   {"name"=>"Phillips Exeter Academy",
    "type"=>"Classics",
    "study"=>nil,
    "time"=>"Class of 2002"},
   {"name"=>"Ardsley High School",
    "type"=>"High school",
    "study"=>nil,
    "time"=>"September 1998 - June 2000"}],
 "work"=>
  [{"name"=>"Chan Zuckerberg Initiative", "time"=>nil},
   {"name"=>"Meta", "time"=>nil}],
 "living"=>
  {"Current city"=>"Palo Alto, California",
   "Hometown"=>"Dobbs Ferry, New York"},
 "relationship"=>"Married to Priscilla Chan since May 19, 2012",
 "other_name"=>[],
 "family"=>[],
 "year_overviews"=>
  {"2023"=>["Aurelia was born"],
   "2017"=>["August Was Born", "Harvard Degree"],
   "2015"=>
    ["Started New Job at Chan Zuckerberg Initiative", "Max Was Born"],
   "2012"=>["Married Priscilla Chan", "Other Life Event"],
   "2011"=>["Became a Vegetarian"],
   "2010"=>["Started Learning Mandarin Chinese"],
   "2009"=>["Wore a Tie for a Whole Year"],
   "2006"=>["Launched News Feed"],
   "2004"=>
    ["Launched the Wall",
     "Started New Job at Meta",
     "Left Harvard University"],
   "2002"=>
    ["Started School at Harvard University",
     "Graduated from Phillips Exeter Academy"],
   "2000"=>
    ["Started School at Phillips Exeter Academy",
     "Left Ardsley High School"],
   "1998"=>["Started School at Ardsley High School"]},
 "quote"=>
  "\"Fortune favors the bold.\" - Virgil, Aeneid X.284  \"All children are artists. The problem is how to remain an artist once you grow up.\" - Pablo Picasso  \"Make things as simple as possible but no simpler.\" - Albert Einstein"}
```

**Gunakan `me` jika ingin mengekstrak informasi dari akun kamu**\
**Contoh**: 

```ruby
irb(main):007:0> my_profile = fb.get_profile("me")
irb(main):008:0> my_profile.name
=> "Rahmat"
irb(main):009:0> my_profile.id
=> "100053033144051"
irb(main):010:0> my_profile.username
=> "Anjay.pro098"
irb(main):011:0> my_profile.user_info
=>
{"name"=>"Rahmat",
 "first_name"=>"Rahmat",
 "middle_name"=>nil,
 "last_name"=>nil,
 "alternate_name"=>"Mat",
 "about"=>nil,
 "username"=>"Anjay.pro098",
 "id"=>"100053033144051",
 "contact_info"=>
  {"Facebook"=>"/Anjay.pro098",
   "GitHub"=>"MR-X-Junior",
   "LinkedIn"=>"rahmat-adha"},
 "profile_pict"=>
  "https://scontent.fsri1-1.fna.fbcdn.net/v/t39.30808-1/279908382_524601785984255_7727931677642432211_n.jpg?stp=cp0_dst-jpg_e15_p74x74_q65&_nc_cat=109&ccb=1-7&_nc_sid=6738e8&efg=eyJpIjoiYiJ9&_nc_eui2=AeGk2lfxRnK2L8JQaHWHIjJ6oWFvcSuRApChYW9xK5ECkIOHPDgqB5OCJyHTOX3QEknK9IedKbAdZFqjICCthTjf&_nc_ohc=bJDHLPYQ914Q7kNvgEwvq13&_nc_ht=scontent.fsri1-1.fna&oh=00_AYCe1hLezYj5oKvA-6zjN5Suuu1Hjcq7ARhGx4bAvF5AGA&oe=668EFD8F",
 "basic_info"=>
  {"Birthday"=>"January 13, 2006",
   "Gender"=>"Male",
   "Languages"=>"Bahasa Indonesia"},
 "education"=>[],
 "work"=>[],
 "living"=>{},
 "relationship"=>nil,
 "other_name"=>[{"Nickname"=>"Mat"}, {"Nickname"=>"Met"}],
 "family"=>[],
 "year_overviews"=>{},
 "quote"=>"i know i'm not alone"}
```

### Extract Groups
Method `get_groups` dapat mengekstrak informasi dari groups facebook, Method ini akan mengembalikan object `Groups`

```ruby
irb(main):010:0> grup = fb.get_groups("1547113062220560")
irb(main):011:0> grup.name
=> "Python - Indonesian Programmers"
irb(main):013:0> grup.group_id
=> "1547113062220560"
irb(main):014:0> grup.total_members
=> 109119
```

### Update Profile Picture
Kamu bisa menggunakan function `UpdateProfilePicture` untuk mengganti poto profile akun Facebook kamu.

**Contoh:**

```ruby
irb(main):004:0> FbRuby::Settings.UpdateProfilePicture(fb, "/sdcard/IMG_20240610_055515.jpg")
=> true
```

#### Hasilnya

##### Sebelum 

![Before Update Profile Picture](https://i.ibb.co.com/SyD2B2C/Screenshot-20240706-214021.jpg)

##### Sesudah

![After Update Profile Picture](https://i.ibb.co.com/94YDVDG/Screenshot-20240706-214839.jpg)

### Update Cover Profile
Kamu bisa menggunakan function `UpdateCoverPicture` untuk mengganti poto profile akun Facebook kamu.

**Contoh:**

```ruby
irb(main):008:0> FbRuby::Settings.UpdateCoverPicture(fb, "/sdcard/cover.jpg")
=> true
```

#### Hasilnya

##### Sebelum

![Before Update Cover Picture](https://i.ibb.co.com/94YDVDG/Screenshot-20240706-214839.jpg)

##### Sesudah

![After Update Cover Picture](https://i.ibb.co.com/7QYtV3Q/Screenshot-20240706-220438.jpg)


### Get Notifications
Kamu bisa menggunakan method `get_notifications` untuk mendapatkan notifikasi terbaru dari akun Facebook.

```ruby
irb(main):016:0> fb.get_notifications(limit = 1)
=>
[{"message"=>
   "Welcome to Facebook! Tap here to find people you know and add them as friends.",
  "time"=>"46 minutes ago",
  "redirect_url"=>
   "https://mbasic.facebook.com/a/notifications.php?redir=%2Ffriends%2Fcenter%2Frequests%2F%3Feav%3DAfYfmGT4ELN6D-CzMS7ytUaBB88FEN5Mi8CZS3RbN84XsqHCbVEqb0kMBlPPXTNKydk%26paipv%3D0&seennotification=1720272846463938&eav=AfaG83DbRVDKwHTs8u9v8R9xLBlc41faflfaPLdB0LH31q5KueCpTHrgbC30Qo_lEQg&gfid=AQAwsSt-rcLzdWk8sHw&paipv=0&refid=48"}]
```

### Get Posts

#### User
Method `get_posts_user`, akan mengumpulkan postingan dan mengekstrak postingan tersebut, method ini akan mengembalikan `Array` yang di dalam nya terdapat sekumpulan object  `Posts`

```ruby
irb(main):004:1* for x in fb.get_posts_user("Anjay.pro098", limit = 2)
irb(main):005:1*   puts ("Author : #{x.author}")
irb(main):006:1*   puts ("Caption: #{x.caption}")
irb(main):007:1*   puts ("Upload Time : #{x.upload_time}\n")
irb(main):008:0> end
```

##### Output
```ruby
Author : Rahmat
Caption: Hello World 🌍
Upload Time : May 17, 2021 at 1:15 PM

Author : Rahmat
Caption: 🗿
Upload Time : September 21, 2021 at 7:09 PM
```

#### Groups
Method `get_posts_groups`, akan mengumpulkan postingan dari grup dan mengekstrak postingan tersebut, method ini akan mengembalikan `Array` yang di dalam nya terdapat sekumpulan object  `Posts`

```ruby
for x in fb.get_posts_groups("1547113062220560", limit = 2)
irb(main):005:1*   puts ("Author : #{x.author}")
irb(main):006:1*   puts ("Caption: #{x.caption}")
irb(main):007:1*   puts ("Upload Time : #{x.upload_time}\n")
irb(main):008:0> end
```

##### Output
```ruby
Author : Umar Alvaro
Captoon: The temperature here does anyone have a source code for identifying the disease of onion plants? 🙏
Upload Time : July 2 at 5:53 AM

Author : Andi Faqih
Captoon: Info guru yang sudah berpengalaman, kalau web panel yang tidak ada menu daftar dan kontak developernya gaada apakah ada trik untuk masuk ya? Kalau ada mungkin ada yg bisa bantu ada fee nya🙏🙏
Upload Time : July 2 at 5:53 AM
```

#### Beranda
Method `get_home_posts`, akan mengumpulkan postingan dari beranda method ini akan mengembalikan `Array` yang di dalam nya terdapat sekumpulan object  `Posts`

```ruby
irb(main):003:1* for post in fb.get_home_posts(limit = 3)
irb(main):004:1*   puts ("Author : #{post.author}")
irb(main):005:1*   puts ("Caption: #{post.caption}")
irb(main):006:1*   puts ("Upload Time : #{post.upload_time}\n\n")
irb(main):007:0> end
```

##### Output
```ruby
Author : Satoshi Jinomoto
Caption: Inikah namanya jepe.
Upload Time : July 4 at 8:54 AM

Author : Zanna Na
Caption: Foto terbaik sepanjang masa ❤️❤️❤️📷
Upload Time : July 1 at 5:35 PM

Author : Cewek Dayak
Caption: Palangkaraya
Upload Time : July 6 at 12:01 PM
```

### Post Parser

Method `post_parser` di gunakan untuk mengekstrak postingan, method ini akan mengembalikan object `Posts`

```ruby
irb(main):014:0> post = fb.post_parser("https://www.facebook.com/100053033144051/posts/pfbid02kW92DAKmVBu2tZ9eiBGCPqGdrKst9oYjN8ZE2XzFpYsdQdqwsjGEWYgx1adCGTBbl/?app=fbl")
irb(main):015:0> post.author
=> "Rahmat"
irb(main):016:0> post.author_url
=> #<URI::HTTPS https://mbasic.facebook.com/Anjay.pro098?eav=AfZMKVpAbkXW4Nxs8ZmPLIBBiWZQT8Uk-FzmF14eifN0CJqv7-KdWMTXLoN7qe6I4sw&__tn__=C-R&paipv=0>
irb(main):017:0> post.caption
=> "Hello World 🌍"
irb(main):018:0> post.post_file
=>
{"image"=>
  [{"link"=>
     "https://scontent.fsri1-1.fna.fbcdn.net/v/t39.30808-6/241434705_371774571266978_6844800659294160676_n.jpg?stp=cp0_dst-jpg_e15_p75x225_q65&_nc_cat=104&ccb=1-7&_nc_sid=e21142&efg=eyJpIjoiYiJ9&_nc_eui2=AeFMDu_ViT5NEX3O-d6gfn849HuYP8xaWmP0e5g_zFpaY3m1XYFSpHejMH0idJ8-Vsex6_8oqLj0Q8mB68nL9veo&_nc_ohc=imu3pxOh-RQQ7kNvgGOLueJ&tn=DX4SAjJgwj_VJcSD&_nc_zt=23&_nc_ht=scontent.fsri1-1.fna&oh=00_AYAy8jdcLSeJGLgWAjUOQREaTgjhcYNuMOEkGQZF-qottg&oe=668FA5CF",
    "id"=>"241434705_371774571266978_6844800659294160676",
    "preview"=>
     "https://scontent.fsri1-1.fna.fbcdn.net/v/t39.30808-6/241434705_371774571266978_6844800659294160676_n.jpg?stp=cp0_dst-jpg_e15_q65_s240x240&_nc_cat=104&ccb=1-7&_nc_sid=e21142&efg=eyJpIjoiYiJ9&_nc_eui2=AeFMDu_ViT5NEX3O-d6gfn849HuYP8xaWmP0e5g_zFpaY3m1XYFSpHejMH0idJ8-Vsex6_8oqLj0Q8mB68nL9veo&_nc_ohc=imu3pxOh-RQQ7kNvgGOLueJ&tn=DX4SAjJgwj_VJcSD&_nc_zt=23&_nc_ht=scontent.fsri1-1.fna&oh=00_AYCmr9nKE8jjhBi_UlnLe6vg6-KKBw92JawTVvXeTnAW5g&oe=668FA5CF",
    "content-type"=>"image"}],
 "video"=>[]}
irb(main):019:0> post.get_react()
=>
{"like"=>5847,
 "love"=>975,
 "care"=>9,
 "haha"=>7,
 "wow"=>884,
 "sad"=>0,
 "angry"=>1}
```

#### Mengirim Komentar

Kamu bisa menggunakan method `send_comment` untuk mengirim komentar.
Method `send_comment` akan mengembalikan `true` Jika berhasil mengirim komentar.

**Contoh:**

```ruby
irb(main):020:0> post.send_comment("Hallo Om #{post.author}, komentar ini di tulis menggunakan library FbRuby\nBaris 3\nBaris 4")
=> true
```

##### Hasilnya
**Liat Komentar paling bawah**

![Contoh cara mengirim komentar](https://i.ibb.co.com/RYyYLJL/IMG-20240707-081752.jpg)

Untuk menambahkan foto pada komentar, kamu bisa menggunakan argument `file`

**Contoh:**

```ruby
irb(main):004:0> post.send_comment("Komentar ini tidak di sertai dengan foto")
=> true
irb(main):005:0> post.send_comment("Komentar ini di sertai dengan foto", file = "/sdcard/cover.jpg")
=> true
```

##### Hasilnya

![Contoh cara mengirim komentar dengan foto](https://i.ibb.co.com/mtR4Nn2/IMG-20240707-091553.jpg)

#### Memberikan react pada postingan

Kamu bisa menggunakan method `send_react` untuk memberikan react pada postingan.
Method ini akan mengembalikan `True` jika berhasil memberikan react pada postingan.

```ruby
irb(main):006:1* post.send_react(react_type)
=> true
```

Terdapat 7 React Type, di antaranya : 
- Like
- Love
- Care
- Haha
- Wow
- Sad
- Angry

**Contoh Cara mengirim react:**
```ruby
irb(main):007:0> post.send_react("wow")
=> true
```

##### Hasilnya
![Contoh cara memberikan react ke postingan](https://i.ibb.co.com/5xSrzZF/IMG-20240707-092034.jpg)

##### Membagikan Postingan
Kamu bisa menggunakan method `share_post` untuk membagikan postingan seseorang ke akun Facebook kamu.

**Contoh (1):**

```ruby
irb(main):009:0> post.share_post()
=> true
```

##### Hasilnya

![Contoh cara membagikan postingan](https://i.ibb.co.com/j54XfGL/Screenshot-2024-0707-093043.png)

**Contoh (2):**

Kamu juga bisa menambahkan `message`,`location` dan `feeling` pada postingan yang di bagikan.

```ruby
irb(main):011:0> post.share_post("Postingan ini di bagikan menggunakan library FbRuby:)",location = "Samarinda", feeling = "Happy")
=> true
```

##### Hasilnya
![Contoh cara membagikan postingan dengan message,location, dan feeling](https://i.ibb.co.com/2NdxF7y/Screenshot-2024-0707-093804.png)

### Messenger

object `Messenger` bisa di gunakan untuk mengirim/menerima chat.\
Terdapat 2 cara untuk membuat Object `Messenger`

**Cara 1**

```ruby
irb(main):014:0> msg = fb.messenger
=> Facebook Messenger
```
**Cara 2**

```ruby
irb(main):013:0> msg = FbRuby::Messenger.new(request_session: login.sessions)
```

#### Mendapatkan Pesan Baru
Method `get_new_message` bisa di gunakan untuk mendapatkan pesan baru:)

```ruby
irb(main):023:1* for chat in msg.get_new_message(limit = 2)
irb(main):024:1*   puts ("Nama : #{chat['name']}")
irb(main):025:1*   puts ("Id Akun : #{chat['id']}")
irb(main):026:1*   puts ("Last Chat : #{chat['last_chat']}")
irb(main):027:1*   puts ("Time : #{chat['time']}\n\n")
irb(main):028:0> end
```

##### Output

```ruby
Nama : Rahmat
Id Akun : 100053033144051
Last Chat : Hallo Kak Rahmat:)
Time : 11 menit lalu

Nama : Mark Zuckerberg
Id Akun : 4
Last Chat : Ban Akun aku dong om                          
Time : 4 Mar
```

Method `get_new_chat` juga bisa di gunakan untuk mendapatkan pesan baru, tetapi method ini berbeda dengan method `get_new_message`

```ruby
irb(main):021:0> msg.get_new_message(limit = 3)
=>
[{"name"=>"Raven Rivera",
  "id"=>"61561488837481",                                               "last_chat"=>
   "You can now call each other and see information like Active Status and when you've read messages.",
  "chat_url"=>
   "https://mbasic.facebook.com/messages/read/?tid=cid.c.61561488837481%3A100086839940375&surface_hierarchy=unknown&eav=AfaVL0CWoprvEWrDytJxVPgWYSKf1qPc2R6mwIaxOEKCUd9jb1Rtuc3C3R7ioJnbaXE&paipv=0&refid=11#fua",
  "time"=>"4 minutes ago"},                                            {"name"=>"Tasiah",
  "id"=>"61561488837481",
  "last_chat"=>"tc",
  "chat_url"=>
   "https://mbasic.facebook.com/messages/read/?tid=cid.c.61561488837481%3A100088905378115&surface_hierarchy=unknown&eav=AfZPigYLcgSOeKbgGTWOEdODEj_xSyRZ6K1pcyLojIhbqE80bXBgxX8EWSsjHRIXirw&paipv=0&refid=11#fua",
  "time"=>"8 minutes ago"},
 {"name"=>"Welda Ningsih",                                              "id"=>"61561488837481",
  "last_chat"=>"You are now connected on Messenger",
  "chat_url"=>
   "https://mbasic.facebook.com/messages/read/?tid=cid.c.61561488837481%3A100000230663103&surface_hierarchy=unknown&eav=Afa-6wgOtq4fDJUYW1Srviky-fA7LIUQys3VE12JN48dOPiYzrqrKPI5JjZnTFyQWts&paipv=0&refid=11#fua",
  "time"=>"Jun 27"}]
irb(main):022:0> msg.get_new_chat(limit = 3)
=>
[Facebook Chats : name="Tasiah" id="100088905378115" chat_id="61561488837481:100088905378115" chat_type="user",
 Facebook Chats : name="Welda Ningsih" id="100000230663103" chat_id="61561488837481:100000230663103" chat_type="user",
 Facebook Chats : name="Raven Rivera" id="100086839940375" chat_id="61561488837481:100086839940375" chat_type="user"]
```

Dari code di atas kita sudah bisa menyimpulkan perbedaan method `get_new_message` dan method `get_new_chat`. 

Method `get_new_message` akan mengembalikan `Array` yang di dalam nya terdapat sekumpulan `Hash`, sedangkan method `get_new_chat` akan mengembalikan `Array` yang di dalam nya terdapat sekumpulan object `Chats`.

#### Mengirim Pesan

Kamu bisa menggunakan method `new_chat` untuk mengirim pesan, method ini akan mengembalikan object `Chats`

```ruby
irb(main):024:0> chat = msg.new_chat("zuck")
=> Facebook Chats : name="Mark Zuckerberg" id="4" chat_id=nil cha...
irb(main):025:0> chat.send_text('Assalamualaikum')
=> true
irb(main):026:0> chat.send_text("Hallo Om #{chat.name}")
=> true
irb(main):027:0> chat.send_text("Apa kabar?")
=> true
irb(main):028:0> chat.send_text("Pesan ini di kirim menggunakan library FbRuby\n\nTerima kasih sudah membaca chat saya")
=> true

```

##### Hasilnya
![Contoh Cara Mengirim Pesan](https://i.ibb.co.com/CvLSvYX/Screenshot-20240707-122431.jpg)

Kamu bisa menggunakan method `send_images` untuk mengirim chat dengan foto.

**Contoh:**

```ruby
irb(main):029:0> mat = msg.new_chat("Anjay.pro098")
=> Facebook Chats : name="Rahmat" id="100053033144051" chat_id=ni...
irb(main):030:0> mat.send_text("Hallo kak #{mat.name}")
=> true
irb(main):031:0> mat.send_text("Pesan ini di kirim menggunakan library FbRuby")
=> true
irb(main):032:0> mat.send_images(file = "/sdcard/cover.jpg","Tes")
=> true
```

##### Hasilnya
![Contoh Cara mengirim chat dengan foto](https://i.ibb.co.com/stFHy75/Screenshot-20240707-183417.jpg)

Untuk Mengirim foto dengan jumblah lebih dari 1 file, gunakan Array pada parameter `file`

**Contoh:**

```ruby
mat.send_images(file = ["/sdcard/1.jpg","/sdcard/2.jpg","/sdcard/3.jpg"])
=> true
```

##### Hasilnya
![Contoh cara kirim chat dengan lebih dari 1 foto](https://i.ibb.co.com/6s9sqtL/IMG-20240707-125130.jpg)

Untuk Mengirim Stiker kamu bisa menggunakan method `send_sticker`, method ini akan mengembalikan `true` jika berhasil mengirim stiker

**Secara bawaan library FbRuby mempunyai beberapa stiker:**

| Nama Stiker                    | ID Stiker         |
|--------------------------------|-------------------|
| smile                          | 529233727538989   |
| crying                         | 529233744205654   |
| angry                          | 529233764205652   |
| heart_eyes                     | 529233777538984   |
| happy_heart                    | 529233794205649   |
| laugh                          | 529233810872314   |
| fearful                        | 529233834205645   |
| sleeping                       | 529233847538977   |
| grimacing                      | 529233954205633   |
| creazy_face                    | 529233967538965   |
| smiling_face_with_sunglasses   | 529233864205642   |
| face_with_spiral_eyes          | 529233884205640   |
| face_blowing_a_kiss            | 529233917538970   |
| face_vomiting                  | 529233937538968   |
| face_screaming                 | 529233980872297   |

**Contoh:**

```ruby
irb(main):007:0> mat.send_sticker("smile")
=> true
irb(main):008:0> mat.send_sticker("crying")
=> true
```

##### Hasilnya
![Contoh cara mengirim stiker](https://i.ibb.co.com/VDfpc9q/Screenshot-2024-0708-011301.png)

## Membuat Postingan

### Akun Pengguna

method `create_timeline_user` bisa di gunakan untuk membuat postingan di akun pengguna, method ini akan mengembalikan `true` jika berhasil membuat postingan.

#### Membuat Postingan (Hanya Caption)

```ruby
irb(main):007:0> fb.create_timeline_user(target = "me", message = "Hallo Dunia^^")
=> true
```

##### Hasilnya
![Membuat Postingan (Hanya Caption)](https://i.ibb.co.com/WVs9p35/Screenshot-2024-0707-171710.png)

#### Membuat Postingan di akun teman
Untuk membuat postingan di akun teman, kamu hanya perlu mengganti argumen dari parameter `target` menjadi id atau username teman kamu:)

**Contoh:**

```python
irb(main):008:0> fb.create_timeline_user(target = "Id atau username akun teman", message = "Postingan ini di buat menggunakan library FbRuby\n\nHehe")
=> true
```

##### Hasilnya
![Membuat Postingan (Hanya caption) di akun teman Facebook](https://i.ibb.co.com/hm70cYd/Screenshot-2024-0707-172114.png)

#### Membuat Postingan (Tag Teman)
Untuk menandai teman pada postingan, kamu bisa menggunakan argumen `users_with`.

```ruby
irb(main):003:0> fb.create_timeline_user(target = "me", message = "Postingan ini di buat menggunakan library FbRuby", users_with: "id akun facebook teman")
=> true
```

##### Hasilnya
![Membuat Postingan (Tag Teman)](https://i.ibb.co.com/Sm3Gbjr/Screenshot-2024-0707-182642.png)

#### Membuat Postingan (Dengan Foto)
Kamu bisa menggunakan argumen `file` untuk menambahkan foto pada postingan:)

```ruby
irb(main):005:0> fb.create_timeline_user(target = "me", message= "Postingan ini di sertai dengan foto", file: "/sdcard/IMG_20240610_055515.jpg")
=> true
```

##### Hasilnya
![Membuat Postingan (Dengan Foto)](https://i.ibb.co.com/GngvyKY/Screenshot-20240707-190241.jpg)

Oh iya, kamu bisa menggunakan argumen `filter_type` untuk mengatur filter pada foto yang akan kamu upload.

```ruby
irb(main):007:0> fb.create_timeline_user(target = "me", message= "Postingan ini di sertai dengan foto", file: "/sdcard/IMG_20240610_055515.jpg", filter_type: '1')
=> true
```

Dan Ini hasil nya:

![Mengatur filter pada foto](https://i.ibb.co.com/vZjMgTK/Screenshot-20240707-190500.jpg)

**Ada beberapa tipe filter yang bisa kamu coba, di antaranya:**
- Tanpa Filter = -1
- Hitam Putih = 1
- Retro = 2

#### Membuat Postingan (Dengan Lokasi)
Kamu bisa menggunakan argumen `location` untuk menambahkan lokasi pada postingan

```ruby
irb(main):003:0> fb.create_timeline_user(target = "me", message= "Hallo", location: "Samarinda")
=> true
```

##### Hasilnya
![Membuat Postingan (Dengan Lokasi)](https://i.ibb.co.com/sPK8x2n/Screenshot-2024-0707-192621.png)

#### Membuat Postingan (Dengan Feeling)
Kamu bisa menggunakan argumen `feeling` untuk menambahkan feeling pada postingan

```ruby
irb(main):004:0> fb.create_timeline_user(target = "me", message= "Hallo", location: "Samarinda", feeling: "Happy")
=> true
```

##### Hasilnya
![Membuat Postingan (Dengan Feeling)](https://i.ibb.co.com/r2s6ygk/Screenshot-2024-0707-192926.png)

### Grup Facebook
method `create_timeline_groups` bisa di gunakan untuk membuat postingan di grup facebook, method ini akan mengembalikan `true` jika berhasil membuat postingan.\
Untuk cara penggunaan method ini sama seperti [create_timeline_user](###Akun-Pengguna)

**Contoh:**

```ruby
irb(main):006:0> fb.create_timeline_groups(target = "2127722334228965", message = "Tes", file: "/sdcard/cover.jpg", feeling: "Happy", users_with: "61562065351749")
=> true
```

##### Hasilnya
![Membuat postingan di grup](https://i.ibb.co.com/x359D32/Screenshot-20240707-200207.jpg)

### Temporary Mail

Kamu bisa menggunakan class `TempMail` untuk membuat email sementara

#### Membuat Email

**Cara membuat email sementara:**
```ruby
irb(main):007:0> tmpmail = FbRuby::TempMail.new
=> CryptoGmail : prefix=fNtWJAbFUKQB domain=chitthi.in emai...
irb(main):008:0> tmpmail.email
=> "fNtWJAbFUKQB@chitthi.in"
```

Sangat mudah bukan?

Untuk prefix dan domain email nya bisa di ganti lho

**Cara ganti prefix dan domain email:**
```ruby
irb(main):012:0> tmpmail = FbRuby::TempMail.new(prefix = "rahmat_adha072", domain = "any.pink")
=> CryptoGmail : prefix=rahmat_adha072 domain=any.pink emai...
irb(main):013:0> tmpmail.email
=> "rahmat_adha072@any.pink"
irb(main):014:0>
```

**Daftar domain email yang di dukung:**
- mailto.plus
- fexpost.com
- fexbox.org
- mailbox.in.ua
- rover.info
- chitthi.in
- fextemp.com
- any.pink
- merepost.com

*SELAIN DARI DOMAIN DI ATAS TIDAK AKAN BISA!*

#### Mendapatkan pesan email
Untuk mendapatkan pesan email yang masuk, kamu bisa menggunakan method `get_new_message`

**Contoh:**
```ruby
irb(main):022:0> tmpmail.get_new_message(limit = 1)
=>
{"count"=>1,
 "first_id"=>2294534389,
 "last_id"=>2294534389,
 "limit"=>1,
 "mail_list"=>
  [{"attachment_count"=>0,
    "first_attachment_name"=>"",
    "from_mail"=>"registration@facebookmail.com",
    "from_name"=>"Facebook",
    "is_new"=>true,
    "mail_id"=>2294534389,
    "subject"=>"81999 is your Facebook confirmation code",
    "time"=>"2024-07-07 16:14:21"}],
 "more"=>false,
 "result"=>true}
```

#### Lihat Isi Email
Untuk melihat pesan lengkap dari email yang masuk, kamu bisa menggunakan method `view_mail`\
method ini memerlukan argumen `mail_id`, untuk `mail_id` bisa kamu dapatkan dari method [get_new_message](#Mendapatkan-pesan-email)

**Contoh:**
```ruby
irb(main):024:0> tmpmail.view_mail("2294534389")
=>
{"attachments"=>[],
 "date"=>"Sun, 7 Jul 2024 06:14:08 -0700",
 "from"=>"\"Facebook\" <registration@facebookmail.com>",
 "from_is_local"=>false,
 "from_mail"=>"registration@facebookmail.com",
 "from_name"=>"Facebook",
 "html"=>
  "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional //EN\"><html><head><title>Facebook</title><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /><style nonce=\"sb7Yw3H4\">@media all and (max-width: 480px){*[class].ib_t{min-width:100% !important}*[class].ib_row{display:block !important}*[class].ib_ext{display:block !important;padding:10px 0 5px 0;vertical-align:top !important;width:100% !important}*[class].ib_img,*[class].ib_mid{vertical-align:top !important}*[class].mb_blk{display:block !important;padding-bottom:10px;width:100% !important}*[class].mb_hide{display:none !important}*[class].mb_inl{display:inline !important}*[class].d_mb_flex{display:block !important}}.d_mb_show{display:none}.d_mb_flex{display:flex}@media only screen and (max-device-width: 480px){.d_mb_hide{display:none !important}.d_mb_show{display:block !important}.d_mb_flex{display:block !important}}.mb_text h1,.mb_text h2,.mb_text h3,.mb_text h4,.mb_text h5,.mb_text h6{line-height:normal}.mb_work_text h1{font-size:18px;line-height:normal;margin-top:4px}.mb_work_text h2,.mb_work_text h3{font-size:16px;line-height:normal;margin-top:4px}.mb_work_text h4,.mb_work_text h5,.mb_work_text h6{font-size:14px;line-height:normal}.mb_work_text a{color:#1270e9}.mb_work_text p{margin-top:4px}</style></head><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr><td width=\"100%\" align=\"center\" style=\"\"><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" align=\"center\" style=\"border-collapse:collapse;\"><tr><td width=\"960\" align=\"center\" style=\"\"><body style=\"max-width:480px;margin:0 auto;\" dir=\"ltr\" bgcolor=\"#ffffff\"><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" align=\"center\" id=\"email_table\" style=\"border-collapse:collapse;max-width:480px;margin:0 auto;\"><tr><td id=\"email_content\" style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;background:#ffffff;\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\" colspan=\"3\">&nbsp;</td></tr><tr><td height=\"1\" colspan=\"3\" style=\"line-height:1px;\"><span style=\"color:#FFFFFF;font-size:1px;opacity:0;\">              Hi,   Someone tried to create a Facebook account with this email address. If it was you, please confirm your account.  </span></td></tr><tr><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr style=\"\"><td height=\"28\" style=\"line-height:28px;\">&nbsp;</td></tr><tr><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr style=\"\"><td height=\"15\" style=\"line-height:15px;\" colspan=\"3\">&nbsp;</td></tr><tr><td width=\"32\" align=\"left\" valign=\"middle\" style=\"height:32;line-height:0px;\"><a href=\"https://www.facebook.com/\" style=\"color:#1b74e4;text-decoration:none;\"><img width=\"32\" src=\"https://static.xx.fbcdn.net/rsrc.php/v3/yS/r/ZirYDPWh0YD.png\" height=\"32\" style=\"border:0;\" /></a></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td width=\"100%\" style=\"\"><a href=\"https://www.facebook.com/\" style=\"color:#1877f2;text-decoration:none;font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:19px;line-height:32px;\"></a></td></tr><tr style=\"border-bottom:solid 1px #e5e5e5;\"><td height=\"15\" style=\"line-height:15px;\" colspan=\"3\">&nbsp;</td></tr></table></td></tr><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\">&nbsp;</td></tr><tr><td style=\"\"><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\">&nbsp;</td></tr></td></tr><tr><td style=\"\"><span class=\"mb_text\" style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:16px;line-height:21px;color:#141823;\">Hi,</span></td></tr><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\">&nbsp;</td></tr><tr><td style=\"\"><span class=\"mb_text\" style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:16px;line-height:21px;color:#141823;\">Someone tried to create a Facebook account with this email address. If it was you, please confirm your account.</span></td></tr><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\">&nbsp;</td></tr></table></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td></tr><tr><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr style=\"\"><td height=\"0\" style=\"line-height:0px;\">&nbsp;</td></tr><tr><td align=\"middle\" style=\"\"><a href=\"https://www.facebook.com/n/?confirmemail.php&amp;e=rahmat_adha072%40any.pink&amp;c=98675&amp;cuid=AYglLuv8m8jcc_Qx0LGj-qvQUVlVdgpG4CtwrR7Z9WmL2Z_b2tYvSUDCSmRbOMz30LGiJ3P3eUbTzM0gTyjT4YBmQ-jtmIOSL1aVbVj2FLbWI05vNeJTS2Wz5OZnuu6iJtI&amp;aref=1720358048096581&amp;medium=email&amp;mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2&amp;bcode=2.1720358048.AbzarNaspfTvMqW8IAE&amp;n_m=rahmat_adha072%40any.pink\" style=\"color:#1b74e4;text-decoration:none;\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr><td style=\"border-collapse:collapse;border-radius:6px;text-align:center;display:block;background:#1877f2;padding:8px 20px 10px 20px;\"><a href=\"https://www.facebook.com/n/?confirmemail.php&amp;e=rahmat_adha072%40any.pink&amp;c=98675&amp;cuid=AYglLuv8m8jcc_Qx0LGj-qvQUVlVdgpG4CtwrR7Z9WmL2Z_b2tYvSUDCSmRbOMz30LGiJ3P3eUbTzM0gTyjT4YBmQ-jtmIOSL1aVbVj2FLbWI05vNeJTS2Wz5OZnuu6iJtI&amp;aref=1720358048096581&amp;medium=email&amp;mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2&amp;bcode=2.1720358048.AbzarNaspfTvMqW8IAE&amp;n_m=rahmat_adha072%40any.pink\" style=\"color:#1b74e4;text-decoration:none;display:block;\"><center><font size=\"4\"><span style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;white-space:nowrap;font-weight:bold;vertical-align:middle;color:#FFFFFF;text-shadow:none;font-weight:500;font-family:Roboto-Medium,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:18px;line-height:18px;\">Confirm&nbsp;your&nbsp;account</span></font></center></a></td></tr></table></a></td></tr><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\">&nbsp;</td></tr><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr></table></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td></tr><tr><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr><td style=\"\"><tr style=\"\"><td height=\"5\" style=\"line-height:5px;\">&nbsp;</td></tr></td></tr><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr><tr><td style=\"\"><span class=\"mb_text\" style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:16px;line-height:21px;color:#141823;\">You may be asked to enter this confirmation code:</span></td></tr><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr><tr><td style=\"\"><span class=\"mb_text\" style=\"font-family:Roboto-Medium,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:17px;line-height:21px;font-weight:500;color:#050505;\"><center>81999</center></span></td></tr><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr><tr><td style=\"\"><tr style=\"\"><td height=\"35\" style=\"line-height:35px;\">&nbsp;</td></tr></td></tr><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr></table></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td></tr><tr><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" align=\"left\" style=\"border-collapse:collapse;\"><tr style=\"border-top:solid 1px #e5e5e5;\"><td height=\"19\" style=\"line-height:19px;\">&nbsp;</td></tr><tr><td style=\"font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:11px;color:#8A8D91;line-height:16px;font-weight:400;\"><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;color:#8A8D91;text-align:center;font-size:12px;font-weight:400;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;\"><tr><td align=\"center\" style=\"font-size:12px;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;color:#8A8D91;text-align:center;font-weight:400;padding-bottom:6px;\">from</td></tr><tr><td align=\"center\" style=\"font-size:12px;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;color:#8A8D91;text-align:center;font-weight:400;padding-top:6px;padding-bottom:6px;\"><img width=\"74\" alt=\"Meta\" height=\"22\" src=\"https://facebook.com/images/email/meta_logo.png\" style=\"border:0;\" /></td></tr><tr><td align=\"center\" style=\"font-size:12px;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;color:#8A8D91;text-align:center;font-weight:400;padding-top:6px;padding-bottom:6px;\">Meta Platforms, Inc., Attention: Community Support, 1 Meta Way, Menlo Park, CA 94025</td></tr><tr><td align=\"center\" style=\"font-size:12px;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;color:#8A8D91;text-align:center;font-weight:400;padding-top:6px;\">This message was sent to <a style=\"color:#1b74e4;text-decoration:none;\" href=\"mailto:rahmat_adha072&#064;any.pink\">rahmat_adha072&#064;any.pink</a>.<br /></td></tr></table><tr style=\"\"><td height=\"10\" style=\"line-height:10px;\">&nbsp;</td></tr></td></tr></table></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td></tr><tr><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td><td style=\"\"><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-collapse:collapse;\"><tr><td style=\"color:#8A8D91;text-align:center;font-size:12px;font-weight:400;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;\"><span class=\"mb_text\" style=\"font-family:Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;font-size:16px;line-height:21px;color:#141823;;color:#8A8D91;text-align:center;font-size:12px;font-weight:400;font-family:Roboto-Regular,Roboto,-apple-system,BlinkMacSystemFont,Helvetica Neue,Helvetica,Lucida Grande,tahoma,verdana,arial,sans-serif;\">To help keep your account secure, please don&#039;t forward this email. <a style=\"color:#1b74e4;text-decoration:none;\" href=\"https://www.facebook.com/email_forward_notice/?mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2\">Learn more</a></span></td></tr></table></td><td width=\"15\" style=\"display:block;width:15px;\">&nbsp;&nbsp;&nbsp;</td></tr><tr style=\"\"><td height=\"20\" style=\"line-height:20px;\" colspan=\"3\">&nbsp;</td></tr></table><span style=\"\"><img src=\"https://www.facebook.com/email_open_log_pic.php?cn=z2gGQ8aOaq&amp;mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2\" style=\"border:0;width:1px;height:1px;\" /></span></td></tr></table></body></td></tr></table></td></tr></table></html>\n\n\n",
 "is_tls"=>true,
 "mail_id"=>2294534389,
 "message_id"=>
  "<cb26f25e-3c62-11ef-af80-c3ad352e0d89@facebookmail.com>",
 "result"=>true,
 "subject"=>"81999 is your Facebook confirmation code",
 "text"=>
  "========================================\nConfirm your account\nhttps://www.facebook.com/n/?confirmemail.php&e=rahmat_adha072%40any.pink&c=98675&cuid=AYjLEHaVqlPE2RuSkBsfuKx8aRwvb11FIDx33M6L-7K945m5rJDeM2cYx6ooVUyNFbdL7TNb9peISB-Pp0AHiKXQ4vvprAO9sNAZ4r4Yb1O9nD2YhDsakhRmqiSfsapy0Xw&aref=1720358048096581&medium=email&mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2&bcode=2.1720358048.AbzarNaspfTvMqW8IAE&n_m=rahmat_adha072%40any.pink\n\n========================================\n\nHi Ruby,\n\nHi,\n\nSomeone tried to create a Facebook account with this email address. If it was you, please confirm your account.\n\nThanks,\nThe Facebook team\n\n \n\nYou may be asked to enter this confirmation code:\n\n81999\n\n \n\n========================================\nThis message was sent to rahmat_adha072@any.pink at your request.\nMeta Platforms, Inc., Attention: Community Support, 1 Meta Way, Menlo Park, CA 94025\nTo help keep your account secure, please don't forward this email. Follow the link below to learn more.\nhttps://www.facebook.com/email_forward_notice/?mid=61ca7c8c1de73G37fd8391b1dcG61ca81257e145G3c2\n\n",
 "to"=>"Ruby Programmer <rahmat_adha072@any.pink>"}
```

### Create a facebook account
Kamu bisa menggunakan class `CreateAccount` untuk membuat akun Facebook.

**CATATAN: Fitur ini masih dalam tahap percobaan, jadi kemungkinan besar fitur ini tidak akan bekerja dengan baik.**

#### Contoh:

Di bawah ini adalah program sederhana untuk membuat akun Facebook.

```ruby
require "fbruby"

# Nama Depan
print ("[?] Nama Depan : ")
firstname = STDIN.gets.chomp

# Nama Belakang
print ("[?] Nama Belakang : ")
lastname = STDIN.gets.chomp

# Alamat email atau nomor hp
print ("[?] Email / Phone : ")
email = STDIN.gets.chomp

# Jenis kelamin
print ("[?] Gender (Male/Female): ")
gender = STDIN.gets.chomp

# Tanggal lahir
print ("[?] Tanggal Lahir (DD/MM/YYYY): ")
ultah = STDIN.gets.chomp

# Kata sandi akun facebook
print ("[?] Password : ")
password = STDIN.gets.chomp

create = FbRuby::CreateAccount.new(firstname: firstname, lastname: lastname, email: email, gender: gender, date_of_birth: ultah, password: password)

puts ("[+] Masukkan kode konfirmasi yang sudah di kirim ke \"#{email}\"")

loop do
  begin
    print ("[?] Kode Konfirmasi : ")
    kode = STDIN.gets.chomp
    create.confirm_account(kode)
    puts ("[✓] Berhasil membuat akun facebook")
    puts ("[+] Nama Akun : #{firstname} #{lastname}")
    puts ("[+] Id akun : #{create.get_cookie_hash['c_user']}")
    puts ("[+] Email/Phone: #{email}")
    puts ("[+] Jenis kelamin: #{gender}")
    puts ("[+] Tanggal Lahir: #{ultah}")
    puts ("[+] Password : #{password}")
    puts ("[+] Cookie Akun : #{create.get_cookie_str}")
    puts ("[+] Token Akun : #{create.get_token}")
    break
  rescue FbRuby::Exceptions => err
    puts ("[!] #{err}")
  end
end
```

###### Hasilnya 
Ini adalah akun yang di buat menggunakan library FbRuby

![Ini adalah akun Facebook yang di buat menggunakan library FbRuby](https://i.ibb.co.com/mcXMbnm/Screenshot-20240708-002744.jpg)

#### Optional Parameter
*(Untuk `CreateAccount` class)*.

- **firstname**: Nama Depan
- **lastname**: Nama Belakang
- **email**: Alamat email yang akan di gunakan untuk mendaftar akun facebook, kamu juga bisa menggunakan nomor ponsel sebagai pengganti alamat email.
- **gender**: Jenis kelamin (Male/Female)
- **date_of_birth**: Tanggal lahir, untuk format tanggal lahir nya adalah DD/MM/YYYY, Contoh: 13/01/2006
- **password**: Kata sandi yang akan di gunakan untuk membuat akun Facebook.


# Cara Install

**FbRuby** sudah tersedia di [RubyGems](https://rubygems.org/gems/fbruby)

```console
$ gem install fbruby
```

**FbRuby** bisa di install di Ruby versi 3.0.0+

# Donate
[![Donate for Rahmat adha](https://i.ibb.co/PwYMWsK/Saweria-Logo.png)](https://saweria.co/rahmatadha)
