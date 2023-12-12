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

