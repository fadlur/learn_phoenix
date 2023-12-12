## Plug

Plug hidup di jantungnya HTTP layer Phoenix, dan Phoenix menaruh Plug di depan dan tengah. Kita berinteraksi dengan plug di setiap langkah dari request life-cycle, dan inti Phoenix component seperti endpoint, router dan controller adalah plug di dalamnya. Mari kita cek apa yang membuat Plug sangat spesial.

Plug adalah spesifikasi untuk modul yang dapat disusun di antara web aplikasi. Plug juga merupakan abstraksi layer untuk koneksi adapter dari web server berbeda. Ide dasar dari Plug adalah menyatukan konsep dari sebuah koneksi yang kita operasikan. Ini berbeda dari HTTP middleware layer lainnya seperti Rack, di mana request dan response dipisahkan middleware stack.

Di level paling sederhana, Spesifikasi datang dengan 2 rasa: function plugs dan module plugs.

**Function plugs**

Agar dapat berfungsi seperti plug, sebuah function harus:

1. Menerima struct koneksi (`%Plug.Conn{}`) sebagai argument pertama, dan opsi koneksi sebagai argumen kedua.
2. Mengembalikan sebuah connection struct (struct koneksi)

Function apapun dapat sesuai 2 kriteria tersebut. Ini contohnya:

```elixir
def introspect(conn, _opts) do
    IO.puts """
    Verb: #{inspect(conn.method)}
    Host: #{inspect(conn.host)}
    Headers: #{inspect(conn.req_headers)}
    """

    conn
end
```

Function ini melakukan hal berikut:

1. Function itu menerima sebuah koneksi dan opsi (yang tidak kita gunakan)
2. Function itu mencetak beberapa informasi koneksi ke terminal
3. Function mengembalikan koneksi (conn)

Sederhana bukan? Sekarang kita tambahkan function ke endpoint kita di `lib/learn_phoenix_web/endpoint.ex`. Kita dapat menambahkan plug di manapun, mari kita sisipkan `plug:introspect` sebelum kita mendelegasikan request ke router:

```elixir
defmodule LearnPhoenixWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :learn_phoenix
  ...

  plug :introspect
  plug LearnPhoenixWeb.Router

  def introspect(conn, _opts) do
    IO.puts """
    Verb: #{inspect(conn.method)}
    Host: #{inspect(conn.host)}
    Headers: #{inspect(conn.req_headers)}
    """

    conn
  end
end
```

Sekarang kita coba akses http://localhost:4000. Harusnya sekarang di terminal tampil seperti yang kita tambahkan di plug.

```
Verb: "GET"
Host: "localhost"
Headers: []
```

Plug kita secara sederhana mencetak informasi dari koneksi. Meskipun plug kita sangat sederhana, kamu dapat melakukan apapun secara virtual di dalamnya.

Sekarang kita lihat jenis plug lainnya, module plugs.

**Module plugs**

Module plug adalah jenis lainnya yang mengijinkan kita untuk mendefinisikan sebuah transformasi koneksi di sebuah modul. Modul hanya perlu mengimplement 2 function:

- `init/1` yang menginisialisasi argument apapun atau option untuk diteruskan ke `call/2`
- `call/2` yang membawa transformasi koneksi. `call/2` hanya sebuah function plug yang kita lihat sebelumnya.

Mari kita tulis sebuah module plug yang menempatkan key dan value `:locale` ke koneksi untuk penggunaan downstream (hilir) di plug lain, controller actions dan views kita. Tempatkan kode di bawah ini ke `lib/learn_phoenix_web/plugs/locale.ex`:

```elixir
defmodule LearnPhoenixWeb.Plugs.Locale do
  import Plug.Conn

  @locales ["en", "fr", "de"]

  def init(default), do: default

  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    assign(conn, :locale, loc)
  end

  def call(conn, default) do
    assign(conn, :locale, default)
  end
end

```

Sekarang tambahkan modul plug ke router kita, dengan menambahkan `plug LearnPhoenixWeb.Locale, "en"` ke pipeline `:browser` di `lib/learn_phoenix_web/router.ex`:

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
  ...
end
```

Di dalam callback `init/1`, kita meneruskan sebuah default locale jika tidak ada di dalam params. Kita juga menggunakan pattern matching untuk mendefinisikan multiple function `call/2` untuk menvalidasi locale di params, dan kembali ke `"en"` kalo tidak ada yang cocok. `assign/3` adalah bagian dari modul `Plug.Conn` dan bagaimana kita menyimpan nilai (values) di dalam data struktur `conn`.

Untuk melihat apa yang dilakukan assign, tambahkan kode berikut ke `lib/learn_phoenix_web/controllers/page_html/home.html.heex`:

```elixir
<p>Locale: <%= @locale %></p>
```

Sekarang coba akses http://localhost:4000 kemudian ganti ke http://localhost:4000/?locale=fr

Kalau parameter locale tidak ada, maka `"en"` akan tampil sebagai locale dan kalo pake`?locale=fr` maka akan tampil `"fr"`. Seseorang dapat menggunakan informasi ini bersama dengan `Gettext` untuk menyediakan fungsi internationalized web application.

Hanya itu yang ada pada Plug. Phoenix embraces (merangkut) desain plug untuk transformasi yang dapat dikomposisikan hingga ke atas dan ke bawah stack. Mari kita lihat beberapa contoh:

**Where to plug**

Endpoint, router, dan controllers di Phoenix menerima plugs.

**Endpoint plugs**

Endpoints mengatut semua plug umum untuk setiap request, dan menerapkannya sebelum dikirim ke router dengan pipeline khusus. Kita menambahkan sebuah plug ke endpoint seperti ini:

```elixir
defmodule LearnPhoenixWeb.Endpoint do
  ...

  plug :introspect
  plug LearnPhoenixWeb.Router
```
