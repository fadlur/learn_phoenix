## Request Life Cycle

Goal dari materi ini adalah biar kita memahami request life-cycle di phoenix. Biar lebih jelas, kita mulai aja.

**Adding a new page**
Ketika akses http://localhost:4000, http mengirim request ke service yang berjalan di alamat itu. Di kasus ini phoenix app kita. HTTP request terdiri dari sebuah verb dan sebuah path, sebagai contoh:

| **BROWSER ADDRESS BAR**           | **VERB** | **PATH**     |
| --------------------------------- | -------- | ------------ |
| http://localhost:4000/            | GET      | /            |
| http://localhost:4000/hello       | GET      | /hello       |
| http://localhost:4000/hello/world | GET      | /hello/world |

Ada verb http lainnya, semisal submit sebuah form biasanya menggunakan POST.

Aplikasi web biasanya menghandle request dengan mapping masing-masing pasangan verb/path ke sebuah bagian spesifik dari aplikasimu yang dihandle oleh router. sebagai contoh, kita map "/article" ke sebuah porsi dari aplikasi kita yang menunjukkan seluruh artikel. Sedangkan untuk menambahkan sebuah halaman baru, tugas pertama kita adalah menambahkan sebuah route baru.

**A new route**
Router memetakan masangan verb/path HTTP yang unik ke controller/action yang akan menghandlenya. Controller di Phoenix sederhananya adalah modul Elixir. Action adalah function yang didefinisikan di dalam controller ini. Konsep ini sering kita temui di framework yang menggunakan MVC.

Phoenix membuat sebuah file router buat kita di `lib/learn_phoenix_web/router.ex`.

Route untuk halaman "Welcome to Phoenix!" ada di:

```elixir
get "/", PageController, :home
```

Dari kode di atas, bisa kita baca kalau alamat http://localhost:4000 mengeluarkan sebuah HTTP `GET` request ke root path. Semua request seperti ini akan dihandle oleh function `home/2` di modul `HelloWeb.PageController` yang didefinisikan di `lib/learn_phoenix_web/controllers/page_controller.ex`.

Halaman yang akan kita buat akan menampilkan "Hello World, from Phoenix!" di mana kita mengarahkan browser kita ke alamat http://localhost:4000/hello

Langkah pertama yang akan kita lakukan adalah membuat halaman baru di router. buka lagi file `lib/learn_phoenix_web/router.ex` dan di bawah:

```elixir
get "/", PageController, :home
```

kita tambahkan route baru

```elixir
get "/hello", HelloController, :index
```

sehingga hasil akhirny akan menjadi seperti berikut:

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

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:learn_phoenix, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LearnPhoenixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
```

**A new controller**
Controller adalah Elixir modul, dan actions adalah Elixir function yang didefinisikan di dalamnya. Tujuan dari action adalah mengumpulkan data dan melakukan tugas yang dibutuhkan untuk rendering. Route kita menentukan bahwa kita butuh sebuah `HelloWeb.HelloController` modul dengan sebuah function `index/2`

Sekarang buat file baru dengan nama `lib/learn_phoenix_web/hello_controller.ex` dan buat menjadi seperti berikut:

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
```

Semua controller action mengambil 2 argument. Yang pertama adalah `conn`, sebuah struct yang memegang banyak data tentang request. Dan yang kedua adalah `params` yang mana isinya adalah sebuah request parameter. Di sini, kita tidak menggunakan `params` dan kita menghindari warning dari compiler dengan menambahkan `_` di depan `params`

Inti dari action ini adalah `render(conn, :index)`. Itu memberitahu Phoenix untuk merender `index` template. Modul yang bertanggungjawab untuk rendering dinamakan views. Secara default, Phoenix views dinamakan setelah contoller (`HelloController`) dan format (`HTML` di kasus ini), Jadi phoenix mengharapkan sebuah `LearnPhoenixWeb.HelloHTML` untuk ada dan mendefinisikan sebuah function `index/1`.

**A new view**
Phoenix views bertindak sebagai lapisan presentasi. Sebagai contoh, kita mengaharapkan output dari rendering `index` untuk menjadi sebuah halaman HTML utuh. Untuk membuat hidup kita lebih gampang, kita sering menggunakan template untuk membuat halaman HTML tersebut.

Mari kita buat sebuah halaman baru. Buat file baru di `lib/learn_phoenix_web/controllers/hello_html.ex` dan edit isinya menjadi seperti berikut:

```elixir
defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html
end

```

Untuk menambahkan template ke view ini, kita dapat mendefinisikan mereka sebagai sebuah function componenet di module atau di file terpisah.

Mari kita mulai dengan mendefinisikan sebuah function component:

```elixir
defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  def index(assigns) do
    ~H"""
    Hello!
    """
  end
end
```

Catatan: jangan lupa, html-nya menggunakan huruf kapital. HelloHTML

Kita mendefinisikan sebuah function yang menerima `assigns` sebagai argument dan menggunakan `~H` sigil untuk menaruh isi yang ingin kita render. Di dalam `~H` sigil, kita menggunakan templating language yang bernama HEEx, atau "HTML+EEx". `EEx` adalah sebuah library untuk embeddeing Elixir bawaan dari Elixir itu sendiri. "HTML+EEx" adalah sebuah Phoenix extension dari EEx yang support HTML validation, components, dan automatic escaping of values. Yang kemudian hari akan melindungimu dari celah security seperti Cross-Site-Scripting tanpa kerja extra di sisi developer.

Sebuah template file bekerja dengan cara yang sama. Function component sangat bagus untuk template yang lebih kecil dan file terpisah bagus ketika kamu memiliki banyak markup atau functionmu mulai terasa tidak dapat dimanage.

Mari kita coba dengan mendefinisikan sebuah template di dalam file itu sendiri. Pertama delete functions `def index(assigns)` dan gantikan dengan sebuah deklarasi `embed_templates`.

```elixir
defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  # def index(assigns) do
  #   ~H"""
  #   Hello!
  #   """
  # end

  embed_templates "hello_html/*"
end
```

Kita memberitahu `Phoenix.Component` untuk mengembed semua `.heex` template yang ditemukan di dalam directory `hello_html` ke module kita sebagai function.

Kemudian, kita butuh menambahkan file ke folder `lib/learn_phoenix_web/controllers/hello_html.

Sebagai catatan, nama controller (`HelloController`), dan nama view (`HelloHTML`), dan folder template (`hello_html`) semua mengikuti naming convention yang sama dan dinamakan setelahnya satu sama lain. Mereka juga ditempatkan bersama di dalam directory tree.

```elixir
lib/learn_phoenix_web
├── controllers
│   ├── hello_controller.ex
│   ├── hello_html.ex
│   ├── hello_html
|       ├── index.html.heex
```

Sebuah template file mempunyai struktur: `NAME.FORMAT.TEMPLATING_LANGUAGE`. di kasus kita, kita membuat sebuah file `index.html.heex` di dalam `lib/learn_phoenix_web/controllers/hello_html/index.html.heex`:

```elixir
<section>
    <h2>Hello world, from Phoenix!</h2>
</section>
```

template file akan dikompil ke dalam modul sebagai function components. tidak ada perbedaan runtime atau performance di antara dua style ini.

Sekarang kita sudah paham route, controller, view dan template. Mari kita coba jalankan dengan command `mix phx.server`
