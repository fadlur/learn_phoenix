## Routing

Router adalah main hub di Phoenix apps. Mereka mencocokkan HTTP request ke controller actions, menyambungkan channel handlers secara real-time, mendefinisikan serangkaian transformasi pipeline dicakup dalam satu set route.

router file yang phoenix generate, ada di `lib/learn_phoenix_web/router.ex`:

```elixir
defmodule LearnPhoenixWeb.Router do
  use LearnPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LearnPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LearnPhoenixWeb.Plugs.Locale, "en"
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LearnPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/hello", HelloController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LearnPhoenixWeb do
  #   pipe_through :api
  # end
  ...
end
```

Nama router dan modul controller akan diprefix dengan nama yang diberikan ke aplikasi dengan ditambahkan `Web`.

Line pertama dari modul, `use LearnPhoenixWeb, :router`, sederhananya membuat function phoenix router tersedia di router khusus kita.

Scope (Cakupan) mempunyai sesi sendiri di guide ini, jadi kita tidak akan menghabiskan waktu di blok scope `scope "/", LearnPhoenixWeb`. Begitu juga `pipe_through :browser` akan dibahas sendiri di sesi "Pipeline". Sekarang, kita hanya perlu tau bahwa pipeline mengijinkan sebuah set plug untuk diaplikasikan ke set route berbeda.

Di dalam blok scope, bagaimanapun, kita mempunyai route pertama kita:

```elixir
get "/", PageController, :home
```

`get` adalah Phoenix macro yang sesuai korespondensi dengan HTTP verb GET. Macro yang mirip juga ada untuk HTTP verb yang lain, termasuk POST, PUT, PATCH, DELETE, OPTIONS, CONNECT, TRACE, dan HEAD.

**Examining routes**
Phoenix menyediakan sebuah tool yang sangat bagus untuk menginvestigasi route di sebuah aplikasi: `mix phx.routes`.

Waktu kita jalankan di terminal, akan keluar list routenya:

```console
 GET   /                                      LearnPhoenixWeb.PageController :home
```

route di atas memberitahu kita bahwa HTTP GET request apapun ke root dari aplikasi akan dihanle oleh `home` action dari `LearnPhoenixWeb.PageController`.

**Resources**

Router mendukung macro lainnya selain macro untuk HTTP verb seperti `get`, `post`, dan `put`. Yang paling penting di antara mereka adalah `resources`. Mari kita tambahkan resource ke `lib/learn_phoenix_web/router.ex`:

```elixir
  scope "/", LearnPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/hello", HelloController, :index
    resources "/users", UserController
  end
```

Jalankan `mix phx.routes` sekali lagi di terminal. Maka akan tampil route baru seperti berikut:

```
  GET     /users                                 LearnPhoenixWeb.UserController :index
  GET     /users/:id/edit                        LearnPhoenixWeb.UserController :edit
  GET     /users/new                             LearnPhoenixWeb.UserController :new
  GET     /users/:id                             LearnPhoenixWeb.UserController :show
  POST    /users                                 LearnPhoenixWeb.UserController :create
  PATCH   /users/:id                             LearnPhoenixWeb.UserController :update
  PUT     /users/:id                             LearnPhoenixWeb.UserController :update
  DELETE  /users/:id                             LearnPhoenixWeb.UserController :delete
```

Ini adalah matrix standard dari HTTP verbs, paths, dan controller actions. Untuk sementara, ini dikenal sebagai RESTful routes, tapi sebagian besar menganggap hal ini kekeliruan. Mari kita lihat satu-satu:

- A GET request ke `/users` akan memanggil `index` action untuk menampilkan semua users.
- A GET request ke `/users/:id/edit` akan memanggil `edit` action dengan sebuah ID untuk mengambil satu individu user dari data store dan menyajikan informasi di dalam form untuk editing.
- A GET request ke `/users/new` akan memanggil `new` action untuk menyajikan sebuah form untuk membuat satu user baru.
- A GET request ke `/users/:id` akan memanggil `show` action dengan sebuah id untuk menampilkan satu individu user diidentifikasi dengan ID tersebut.
- A POST request ke `/users` akan memanggil `create` action untuk menyimpan satu user baru ke data store.
- A PATCH request ke `/users/:id` akan memanggil `update` action dengan sebuah ID untuk menyimpan user yang telah diupdate ke data store.
- A PUT request ke `/users/:id` akan memanggil `update` action dengan sebuah ID untuk menyimpan user yang telah diupdate ke data store.
- A DELETE request ke `/users/:id` akan memanggil `delete` action dengan sebuah ID untuk menghapus satu individu user dari data store.

Jika kita tidak butuh semau dari routes ini, kita dapat memilih menggunakan `:only` dan `:except` option untuk memfilter spesifik action.

Katakanlah kita mempunya sebuah read-only post resource. Kita harus mendefinisikannya seperti ini:

```elixir
resources "/posts", PostController, only: [:index, :show]
```

Jalankan `mix phx.routes` memperlihatkan bahwa kita sekarang hanya mempunyai routes ke index dan show action:

```
  GET     /posts                                 LearnPhoenixWeb.PostController :index
  GET     /posts/:id                             LearnPhoenixWeb.PostController :show
```

Sama dengan post tadi, jika kita mempunyai sebuah comment resource, dan kita tidak ingin menyediakan sebuah route untuk delete, kita dapat mendefinisikan sebuah route seperti ini:

```elixir
resources "/comments", CommentController, except: [:delete]
```

Jalankan `mix phx.routes` memperlihatkan bahwa kita sekarang hanya mempunyai semua route ke comments kecuali delete:

```
  GET     /comments                              LearnPhoenixWeb.CommentController :index
  GET     /comments/:id/edit                     LearnPhoenixWeb.CommentController :edit
  GET     /comments/new                          LearnPhoenixWeb.CommentController :new
  GET     /comments/:id                          LearnPhoenixWeb.CommentController :show
  POST    /comments                              LearnPhoenixWeb.CommentController :create
  PATCH   /comments/:id                          LearnPhoenixWeb.CommentController :update
  PUT     /comments/:id                          LearnPhoenixWeb.CommentController :updat
```

macro `Phoenix.Router.resources/4` mendeskripsikan opsi tambahan untuk kustomisasi route resoource.

**Verified Routes**
Phoenix mengikutkan modul `Phoenix.VerifiedRoutes` yang menyediakan compile-time check dari router paths terhadap router kita menggunakan `~p` sigil. Sebagai contoh, kita dapat menulis paths di controllers, tests dan templates. Dan compiler akan memastikan route itu semua cocok di router kita.

Mari kita lihat di real actionnya. Jalankan `iex -S mix` di terminal, Kita akan mendefinisikan sample sekali pakai yang membangun beberapa `~p` route paths.

```elixir
defmodule RouteExample do
  use LearnPhoenixWeb, :verified_routes

  def example do
    ~p"/comments"
    ~p"/unknown/123"
  end
end
warning: no route path for LearnPhoenixWeb.Router matches "/unknown/123"
  iex:5: RouteExample.example/0

{:module, RouteExample, ...}

```

Lihat bagaimana panggilan pertama ke existing route, `~p"/comments"` tidak ada warning, tapi sebuah route path yang jelek `~p"/unknown/123"` memproduksi sebuah compiler warning, seperti seharusnya. Ini sangat signifikan, karena phoenix mengijinkan kita menulis hard-coded path dan compiler akan memberitahu kita kapanpun kita menulis bad route atau mengubah struktur routing kita.

Phoenix project meng-set out of the box untuk mengijinkan kita memverifikasi routes melalui web layer, termasuk test. Sebagai contoh, di template kita dapat merender link `~p`:

```elixir
<.link href={~p"/"}>Welcome Page!</.link>
<.link href={~p"/comments"}>View Comments</.link>
```

Atau di controller, membuat sebuah redirect:

```elixir
redirect(conn, to: ~p"/comments/#{comment}")
```

Menggunakan `~p` untuk route path memastikan path aplikasi kita dan URL tetep up to date dengan router. Compiler akan menangkap bug untuk kita, dan memberitahu kita kapan kita mengubah route yang direferensikan di tempat lain dalam aplikasi kita.

**More on verified routes**
Bagaimana dengan query string? Kamu dapat menambahkan query strin gkey values secara langsung, atau menyediakan sebuah dictionary key-value pairs, contohnya:

```elixir
~p"/users/17?admin=true&active&false"
"/users/17?admin=true&active=false"

~p"/users/17?#{[admin: true]}"
"/users/17?admin=true"
```

Bagaimana jika kita ingin full URL dibandingkan sebuah path? Cukup bungkus path-mu dengan sebuah panggilan (call) ke `Phoenix.VerifiedRoutes.url/1`, yang diimport dimanapun di mana `~p` tersedia:

```elixir
url(~p"/users")
"http://localhost:4000/users"
```

`url` calls akan mendapatkan host, port, proxy port, dan informasi SSL yang dibutuhkan untuk membangun full URL dari konfigurasi parameter set untuk masing-masing environment. Kita akan membahas tentang konfigurasi lebih detail. Untuk sekarang, kamu dapat melihat di `config/dev.exs` untuk melihat nilai-nilai itu.

**Nested resources**
Mungkin juga menyarangkan (nest) resources di Phoenix router. Katakanlah kita juga mempunyai sebuah `posts` resources yang mempunyai many-to-one relationship dengan `users`. Dapat dikatakan seorang user bisa membuat banyak posts, dan masing-masing post dimiliki oleh seorang user. Kita dapat mewakili hal tersebut dengan menambahkan sebuah nested route di `lib/learn_phoenix_web/router.ex` seperti ini:

```elixir
resources "/users", UserController do
  resources "/posts", PostController
end
```

Ketika kita menjalankan `mix phx.routes` sekarang, sebagai tambahan ke routes kita melihat untuk `users` di atas, kita mendapatkan set routes seperti berikut:

```elixir
  GET     /users/:user_id/posts                  LearnPhoenixWeb.PostController :index
  GET     /users/:user_id/posts/:id/edit         LearnPhoenixWeb.PostController :edit
  GET     /users/:user_id/posts/new              LearnPhoenixWeb.PostController :new
  GET     /users/:user_id/posts/:id              LearnPhoenixWeb.PostController :show
  POST    /users/:user_id/posts                  LearnPhoenixWeb.PostController :create
  PATCH   /users/:user_id/posts/:id              LearnPhoenixWeb.PostController :update
  PUT     /users/:user_id/posts/:id              LearnPhoenixWeb.PostController :update
  DELETE  /users/:user_id/posts/:id              LearnPhoenixWeb.PostController :delete
```

Kita lihat bahwa masing-masing cakupan route posts ke satu user ID. Untuk pertama kali, kita akan memanggil `PostController`'s `index` action, tapi kita akan melewatkan satu `user_id`. Ini menyiratkan bahwa kita akan menampilkan semua post untuk masing-masing users saja. Cakupan yang sama berlaku untuk semua route ini.

Ketika membangun paths untuk nested routes, kita akan menginterpolasi `ID` dimana mereka berada dalam definisi route. Untuk route `show` route, `42` adalah `user_id` dan `17` adalah `post_id`.

```elixir
user_id = 42
post_id = 17
~p"/users/#{user_id}/posts/#{post_id}"
"/users/42/posts/17"
```

Verified routes juga mendukup `Phoenix.Param` protokol, tapi kita tidak perlu concern ke elixir protocol dulu. Cukup tahu bahwa sekali kita mulai membangun aplikasi kita dengan struct seperti `%User{}` dan `%Post{}`, kita akan dapat interpolasi data struktur itu secara langsung ke `~p` path dan phoenix akan mengambil field yang bener untuk digunakan di route.

```elxiir
~p"/users/#{user}/posts/#{post}"
"/users/42/posts/17"
```

Perhatikan bagaimana kita tidak perlu menginterpolasi `user.id` atau 'post.id'? Ini secara khusus bagus jika kita memutuskan nanti kita ingin membuat URL kita lebih cakep dan mulai menggunakan slugs.
Kita tidak perlu mengubah apapun dari `~p`!

**Scoped routes**
Scope adalah cara untuk mengelompokkan route di bawah prefix path umum dan scope set dari plugs. Kita mungkin ingin melakukan ini untuk fungsi admin, API, dan khususnya untuk versioned APIs. Katakanlah kita mempunya user-generated review di sebuah situs, dan review itu harus diapprove oleh administrator. Semantik dari resources ini cukup berbeda, dan mereka mungkin tidak berbagi controller yang sama. Scope memungkinkan kita untuk memisahkan rute-rute ini.

Path untuk user-facing review akan terlihat seperti resource standart:

```elixir
/reviews
/reviews/1234
/reviews/1234/edit
...

```

Administration review path dapat diawali dengan `/admin`

```elixir
/admin/reviews
/admin/reviews/1234
/admin/reviews/1234/edit
...

```

Kita dapat membuat ini dengan sebuah scope route yang membuat sebuah path option ke `/admin` seperti ini. Kita dapat mengelompokkan scope ini di dalam scope yang lain. Mari kita buat sendiri di root, dengan menambahkan ke `lib/learn_phoenix_web/router.ex`:

```elixir
  scope "/admin", LearnPhoenixWeb.Admin do
    pipe_through :browser

    resources "/reviews", ReviewController
  end
```

Kita mendifinisikan sebuah scope baru di mana semua routes diawali dengan `/admin` dan semua controller di bawah `LearnPhoenixWeb.Admin` namespace.

Jalankan `mix phx.routes` lagi, kita akan punya tambahan route berikut:

```elixir
...
GET     /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :index
GET     /admin/reviews/:id/edit  LearnPhoenixWeb.Admin.ReviewController :edit
GET     /admin/reviews/new       LearnPhoenixWeb.Admin.ReviewController :new
GET     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :show
POST    /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :create
PATCH   /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
PUT     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
DELETE  /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :delete
...

```

Terlihat bagus, tapi ada sedikit masalah di sini, Ingat bahwa kita ingin kedua user-facing review routes `/reviews` dan admin `/admin/reviews`. Jika kita sekarang menambahkan user-facing reviews di route kita di bawah root scope seperti ini:

```elixir
scope "/", LearnPhoenixWeb do
  pipe_through :browser

  ...
  resources "/reviews", ReviewController
end

scope "/admin", LearnPhoenixWeb.Admin do
  pipe_through :browser

  resources "/reviews", ReviewController
end
```

Jalankan `mix phx.routes` lagi, kita akan punya tambahan route berikut:

```elixir
...
GET     /reviews                 LearnPhoenixWeb.ReviewController :index
GET     /reviews/:id/edit        LearnPhoenixWeb.ReviewController :edit
GET     /reviews/new             LearnPhoenixWeb.ReviewController :new
GET     /reviews/:id             LearnPhoenixWeb.ReviewController :show
POST    /reviews                 LearnPhoenixWeb.ReviewController :create
PATCH   /reviews/:id             LearnPhoenixWeb.ReviewController :update
PUT     /reviews/:id             LearnPhoenixWeb.ReviewController :update
DELETE  /reviews/:id             LearnPhoenixWeb.ReviewController :delete
...
GET     /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :index
GET     /admin/reviews/:id/edit  LearnPhoenixWeb.Admin.ReviewController :edit
GET     /admin/reviews/new       LearnPhoenixWeb.Admin.ReviewController :new
GET     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :show
POST    /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :create
PATCH   /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
PUT     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
DELETE  /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :delete

```

Bagaimana jika kita mempunya sejumlah resources yang semua dihandle oleh admins? Kita bisa taruh semua di dalam scope yang sama seperti ini:

```elixir
  scope "/admin", LearnPhoenixWeb.Admin do
  pipe_through :browser

  resources "/images",  ImageController
  resources "/reviews", ReviewController
  resources "/users",   UserController
end
```

Jalankan `mix phx.routes` lagi, kita akan punya tambahan route berikut:

```elixir
...
GET     /admin/images            LearnPhoenixWeb.Admin.ImageController :index
GET     /admin/images/:id/edit   LearnPhoenixWeb.Admin.ImageController :edit
GET     /admin/images/new        LearnPhoenixWeb.Admin.ImageController :new
GET     /admin/images/:id        LearnPhoenixWeb.Admin.ImageController :show
POST    /admin/images            LearnPhoenixWeb.Admin.ImageController :create
PATCH   /admin/images/:id        LearnPhoenixWeb.Admin.ImageController :update
PUT     /admin/images/:id        LearnPhoenixWeb.Admin.ImageController :update
DELETE  /admin/images/:id        LearnPhoenixWeb.Admin.ImageController :delete
GET     /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :index
GET     /admin/reviews/:id/edit  LearnPhoenixWeb.Admin.ReviewController :edit
GET     /admin/reviews/new       LearnPhoenixWeb.Admin.ReviewController :new
GET     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :show
POST    /admin/reviews           LearnPhoenixWeb.Admin.ReviewController :create
PATCH   /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
PUT     /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :update
DELETE  /admin/reviews/:id       LearnPhoenixWeb.Admin.ReviewController :delete
GET     /admin/users             LearnPhoenixWeb.Admin.UserController :index
GET     /admin/users/:id/edit    LearnPhoenixWeb.Admin.UserController :edit
GET     /admin/users/new         LearnPhoenixWeb.Admin.UserController :new
GET     /admin/users/:id         LearnPhoenixWeb.Admin.UserController :show
POST    /admin/users             LearnPhoenixWeb.Admin.UserController :create
PATCH   /admin/users/:id         LearnPhoenixWeb.Admin.UserController :update
PUT     /admin/users/:id         LearnPhoenixWeb.Admin.UserController :update
DELETE  /admin/users/:id         LearnPhoenixWeb.Admin.UserController :delete

```

Sekarang bagus, seperti yang kita inginkan. Perhatikan bagaimana masing-masing route dan controller diberi nama dengan benar.

Scope juga dapat disarangkan secara sembarang, tapi kamu juga harus melakukannya dengan hati-hati karena penyarangan kode kita kadang membingungkan dan kurang jelas. Dengan demikian, anggaplah kita mempunya versioned API dengan resources yang didefinisikan untuk images, reviews dan users. Maka secara teknis, kita dapat mengatur route untuk versioned API seperti ini:

Coba cek lagi routes yang baru, dengan menjalankan perintah `mix phx.routes`

Menariknya, kita dapat menggunakan multiple scope dengan path yang sama sepanjang kita hati-hati tidak menduplikasi route. Route berikut ini bekerja dengan baik dengan 2 scope didefinisikan untuk path yang sama:

```elixir
defmodule LearnPhoenixWeb.Router do
  use Phoenix.Router
  ...
  scope "/", LearnPhoenixWeb do
    pipe_through :browser

    resources "/users", UserController
  end

  scope "/", AnotherAppWeb do
    pipe_through :browser

    resources "/posts", PostController
  end
  ...
end
```

Kalau kita menduplikasi sebuah route yang berarti 2 route mempunyai path yang sama. kita akan mendapatkan warning berikut:

```
warning: this clause cannot match because a previous clause at line 16 always matches

```
