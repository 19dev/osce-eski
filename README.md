# Ne yapacaksınız?

# Nasıl?

Çalışmamda amacım bir login sayfasıyla erişilebilen blog yapmak. Bununla alakalı
bir `login` dalı oluşturmakla başladım,

	$ cd osce/
	$ git checkout master
	$ git checkout -b login

Önce basitte olsa bir blog oluşturalım,

	$ rails g scaffold post title:string content:text

Bu bizim yerimize CRUD desteği veren formu ve `config/routes` gerekli eklentiyi
yapar,

	resources :posts

Veritabanını, migration üzerinden oluşturur:
`db/migrate/20120330054405_create_posts.rb`. Bunu aktive etmek için,

	$ rake db:migrate

Test etmek için sunucuyu başlatalım,

	$ rails s --binding=1.2.3.4 --port=3001

burada `1.2.3.4` sanal makinenin IP adresi, host/fiziksel makinede web
tarayıcıyı açalım ve http://1.2.3.4:3001/posts adresine gidelim, CRUD imkanımız
var fakat herkes bunu yapabilir henüz login olanağımız yok.

# Kaynaklar

1. auth: <https://github.com/seyyah/auth-demo/blob/master/README.rdoc>
