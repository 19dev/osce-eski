# Ne yapacaksınız?

Depoyu clone'layın

	$ git clone ...
	$ git checkout login
	$ bundle
	$ rake db:migrate
	$ rake db:seed
	$ rails s

# Nasıl?

Çalışmamda amacım bir login sayfasıyla erişilebilen blog yapmak. Agile
ilerleyeceğim, küçük ama çevik adımlar.

1) Bununla alakalı bir `login` dalı oluşturmakla başladım,

	$ cd osce/
	$ git checkout master
	$ git checkout -b login

2) Önce basitte olsa bir blog oluşturalım,

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

Bu adımı commitleyelim,

	$ git add .
	$ git commit -a -m "scaffold:posts"

3) Login'in ilk aşaması `user` tablosunu/modelini oluşturmaktan geçiyor,

	$ rails g model user username:string password_digest:string

bu komut iki şey üretir (+ testleri üretir): model(user), migration. Migration'u
aktive etmek için,

	$ rake db:migrate

Login için parolaları şifreli saklamak istediğimizden dolayı, class içerisine

	$ vim app/models/user.rb
	has_secure_password

yazıyoruz. Bu aşamayı da commit'leyelim,

	$ git add .
	$ git commit -a -m "model:user"

4) İkinci aşamada kullanıcının giriş yapıp yapmadığını denetlemek takip etmek
   için oturum yönetimini aktive etmek. Bununla alakalı `session` controlleru
   oluşturacağız,

   	$ rails g controller sessions new

Bu komut controller, view ve route ekler. Yeni oturum başlatmayı bunun üzerinden
yapacağız. Önce login formunu tasarlayalım,

	$ vim app/views/sessions/new.html.erb
	<h1>Login</h1>
	<%= form_tag sessions_path do %>
	<div class="field">
		<%= label_tag "Username" %>
		<%= text_field_tag :username, params[:username] %>
	</div>
	<div class="field">
		<%= label_tag :password %>
		<%= password_field_tag :password %>
	</div>
	<div class="actions">
		<%= submit_tag "Login" %>
	</div>
	<% end %>

form kullanıcı adı ve parola isteyecek. Yönlendirme tablosunu güncelleyelim,

	$ vim config/routes.rb
	resources :sessions
	get "login" => "sessions#new", :as => "login"

böylelikle url'de `login` girildiğinde controller üzerinden `sessions->new`
çağrılacak. Yönlendirme tablosunun son durumunu şöyle görebiliriz,

	$ rake routes

Test için http://1.2.3.4:3001/login sayfasına gidelim. Kullanıcı adı ve parola
girebileceğimiz bir form karşılamalıdır. Login düğmesine tıklanınca CRUD'un
`create` yöntemi tetiklenir. Buna yanıt verecek olan ise controller'da `create`
yöntemi olacaktır,

	$ vim app/controllers/sessions_controller.rb
	def create
	  user = User.find_by_username(params[:username])
	  if user && user.authenticate(params[:password])
	    session[:user_id] = user.id
	    redirect_to posts_path
	  else
	    flash.now.alert = "Invalid username or password"
	    render "new"
	  end
	end

Giriş yapmaya çalışınca gem paket eksikliğinden dem vuruyor

	Gem::LoadError in SessionsController#create
	bcrypt-ruby is not part of the bundle. Add it to Gemfile.

Bunu sağlamak için,

	$ vim Gemfile
	gem 'bcrypt-ruby', '~> 3.0.0'
	$ bundle

Sunucuyu tekrardan başlatmak gerekiyor,

	$ rails s --binding=1.2.3.4 --port=3001

Her şey güzelde, kullanıcı kaydını nasıl yapacağız. Elle yapmamız gerekiyor,
bunu ise rails console'unda yapacağız,

	$ rails c
	> User.create(:username => "seyyah", :password => "secret",
	   :password_confirmation => "secret")
	> quit

Evet testi tekrarlayalım http://1.2.3.4:3001/login sayfasına girip,
"seyyah:secret" çiftini deneyelim. Başarılı girişin ardından posts sayfasına
yönlendirileceksiniz. Başarılı/başarısız durumunda henüz flash mesaj üstte
görülmüyor. Bunu eklemek için layout dosyasına gitmek gerek,

	$ vim app/views/layouts/application.html.erb
	<div class="container" style="margin-bottom: 80px;" >
	   <div class="content">
	     <div class="row">
   	       <div class="span9">
		<% [:notice, :error, :alert].each do |level| %>
		  <% unless flash[level].blank? %>
		    <div data-alert="alert" class="alert alert-<%= level %> fade in">
			<a class="close" data-dismiss="alert" href="#">&times;</a>
			<%= content_tag :p, simple_format(flash[level]) %>
		    </div>
		   <% end %>
		<% end %>
	       </div>
	   </div>
	</div>

Evet her şey yolunda gözüküyor.

Bu durumu commit'leyelim,

	$ git add .
	$ git commit -a -m "auth:ok"

5) Şimdi erişimi kısıtlayalım. Yani posts sayfasına sadece login yapanlar
   girsin. Bunun için kullanacağımız gem file `cancan` olacak,

   	$ vim Gemfile
	gem 'cancan'
	$ bundle

cancan'i kullanarak yetkileri oluşturmaya başlayalım,

	$ rails g cancan:ability
	create  app/models/ability.rb

bu dosya yardımıyla yetkilerimizi ayarlayacağız ama önce Post tablosuna/modeline
bu girdiyi yapan kullanıcı bilgisini ekleyelim. Bunun için tabloya yeni bir
sütun eklemeyi sağlayacak migrasyonu yapmalıyız,

	$ rails g migration AddUserOnPosts
	invoke  active_record
	create    db/migrate/20120330065912_add_user_on_posts.rb

(Not: rails isimlendirmeleri zekice davranır. AddUserOnPosts ->
add_user_on_posts gibi. Tablo ismi `posts` model ismi `Post`. Çoğul/tekil,
büyük/küçük harf ayrımlarına dikkat)

Bu migrasyonla yapılacak görevi tanımlayalım,

	$ vim db/migrate/XXX_add_user_on_posts.rb
	def up
		add_column :posts, :user_id, :integer
	end

Db'yi reset atıp, sonra migrasyon daha temiz olacaktır (başka yöntemleri de
var),

	$ rake db:reset
	$ rake db:migrate

Test kullanıcısını oluşturalım fakat bunu db'ye otomatik koymanın yolunu da
sunalım,

	$ vim db/seeds.rb
	User.create(:username => "seyyah", :password => "secret",
	 :password_confirmation = "secret")

dosyaya bu satırı ekledikten sonra,

	$ rake db:seed

`user_id`'ın espirisi posts tablosuna eklenecek sütun, aslında users tablosunun
id'sidir. Bunu Post modeline de söyleyelim: "Post modeli/tablosu user'a aittir"
ingilizcesiyle "Post belongs to user" Rails'cesiyle,

	$ vim app/models/post.rb
	belongs_to :user

Erişimi kısıtlamanın zamanıdır,

	$ vim app/controllers/post_controller.rb
	load_and_authorize_resource
	...
	def create
		@post = Post.new(params[:post])
		@post.user = current_user
		...
	end
	def update
		@post = Post.find(params[:post])
		@post.user = current_user
		...
	end

Authorize (yetki) o/almaksızın kaynağa (resource) erişmeye izin verme
(`load_and_authorize_resource`) ve post oluşturulurken (create) ve
güncellenirken (upadate) bunu yapanı (current_user) tabloya ekle (`@post.user =
current_user`).

`current_user` yöntemini tanımlayalım,

	$ vim app/controllers/application_controller.rb
	def current_user
		session[:user_id] ? @current_user ||= User.find(session[:user_id]) : nil
	end

Kullanıcıya ability üzerinden yetenek kazandıralım,

	$ vim app/models/ability.rb
	def initialize(user)
		user ||= User.new # guest user (not logged in)

		if user.persisted?
			can :read, Post
			can :manage, Post, :user_id => user.id
		else
			# Guest user are not allowed
		end
	end

Post listesinde ve ayrıntılarının gösterildiği sayfada post'u göndereni degösterelim,

	$ vim app/views/posts/index.html.erb
	<th>Owner</th>
	<td><%= post.user.username %></td>

	$ vim app/views/posts/show.html.erb
	<p>
		<b>Owner:</b>
		<%= @post.user.username %>
	</p>

Hatırlarsanız Post modeline ait posts tablosuna `user_id` sütunu eklemiştik,
bunun `users` tablosuna aitliğini de ayrıca belirtmiştik (`belongs_to`). Bunları
yaptığımızda artık `@post.user` ile `posts` tablosundan `users` tablosuna
geçebiliyoruz.

Eğer bir kişi Post'u üretense sadece o düzenleyebilir, login yapmış herhangi bir
kişi ise CRUD yeteneğine sahiptir. Bunu ability'de şöyle söyledik,

	if user.persisted?

kullanıcı login olmuşsa

	if user.persisted?
		can :read, Post

tüm Post'ları okuyabilir,

	if user.persisted?
		can :read, Post
		can :manage, Post, :user_id => user.id

Kendi oluşturduklarını da manage (sil, düzenle, + read, + new) edebilir.

Yetkisi olmayanlara linkleri göstermeyelim,

	$ vim app/views/posts/index.html.erb
	<% if can? :edit, post %>
	  <%= link_to 'Edit', edit_post_path(post) %>
	<% end %>
	<% if can? :destroy, post %>
	  <%= link_to 'Destroy', post, confirm: 'Are you sure?', method: :delete %>
	<% end %>

	$ vim app/views/posts/show.html.erb
	<% if can? :edit, @post %>
	  <%= link_to 'Edit', edit_post_path(@post) %> |
	<% end %>

Yani `if can? :edit, post` bu post'u düzenlemeye yetkiliyse...

Sunucuyu tekrardan başlatalım ve login sayfasına gidelim, ardından Post
üzerinde CRUD'u deneyelim. Her şey yolunda olmalı.

Bu aşamayı commit'leyelim,

	$ git add .
	$ git commit -a -m "cancan: ok"

# Kaynaklar

1. auth: <https://github.com/seyyah/auth-demo/blob/master/README.rdoc>

2. Simple auth:
   <http://jeremyjbarth.blogspot.com/2011/10/rails-31-simple-custom-authentication.html>

3. NebJ: devise+cancan:
   <http://github.com/NebJ/demo-devise-cancan/blob/master/README.rdoc>
