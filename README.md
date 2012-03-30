# Ne yapacaksınız?

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

	$ vim
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

# Kaynaklar

1. auth: <https://github.com/seyyah/auth-demo/blob/master/README.rdoc>
