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

Endpoints mengatur semua plug umum untuk setiap request, dan menerapkannya sebelum dikirim ke router dengan pipeline khusus. Kita menambahkan sebuah plug ke endpoint seperti ini:

```elixir
defmodule LearnPhoenixWeb.Endpoint do
  ...

  plug :introspect
  plug LearnPhoenixWeb.Router
```
default endpoint plug melakukan banyak hal, berikut urutannya:
- `Plug.Static` - menyediakan static assets. Karena plug datang sebelum logger, request untuk static assets tidak dilog.
- `Phoenix.LiveDashboard.RequestLogger` - mengatur _Request Logger_ untuk Phoenix LiveDashboard, ini akan mengijinkan kamu untuk mempunyai opsi untuk melewatkan sebuah query parameter ke request stream logs atau untuk enable/disable sebuah cookie yang mengalirkan request log untuk dashboardmu.
- `Plug.RequestId` - Men-generate unique request Id untuk masing-masing request
- `Plug.Telemetry` - Menambahkan poin instrumentasi sehingga Phoenix dapat meng-log request path, status code dan request time secara default.
- `Plug.Parsers` - parse request body ketika parser yang diketahui ada. Secara default, plug ini menghandle URL-encoded, multipart dan JSON content (dengan `Jason`). Sisa request body tidak disentuh jika request content-type tidak dapat diteruskan.
- `Plug.MethodOverride` - convert request method ke PUT, PATCH atau DELETE untuk POST request dengan sebuah valid parameter `_method`
- `Plug.Head` - convert HEAD request ke GET request dan menghapus response body.
- `Plug.Session` - sebuah plug yang mengatur session management. Perlu diperhatikan bahwa `fetch_session/2` harus tetap secara explisit dipanggil sebelum menggunakan session. Karena plug ini hanya mengatur bagaimana session diambil.

Di tengah endpoint, ada juga sebuah blok persyaratan:
```elixir
if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :learn_phoenix
  end
```
Blok ini hanya dieksekusi di development env. Blok ini mengenable:
- live reloading - jika kamu mengubah sebuah CSS file, mereka akan mengupdate di browser tanpa refresh halaman
- code reloading - Jadi kita dapat melihat perubahan ke aplikasi kita tanpa merestart server
- check repo status - yang memastikan database kita up to date, meningkatkan readable dan actionable error juga.

**Route plugs**
Di router, kita dapat mendeklarasikan plug di dalam pipeline:
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
  ...
end
```

Router didefinisikan di dalam scope dan scope mungkin "pipe" melalui multiple pipeline. Sekali sebuah route cocok, Phoenix memanggil semua plug yang didefinisikan di dalam semua pipeline yang diasosiasikan ke route tersebut. Sebagai contoh, mengakses "/" akan "pipe" melalui `:browser` pipeline, konsekuensinya memanggil semua plug-nya.

Seperti kita akan lihat di panduan routing, pipeline sendiri adalah plugs. Di sana, kita akan juga mendiskusikan semua plug di dalam `:browser` pipeline.

**Controller plugs**
Akhirnya, controller adalah plug juga, jadi kita dapat melakukan:
```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en"
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
```

Secara khusus, controller plug menyediakan sebuah fitur yang mengijinkan kita untuk menjalankan plug hanya di dalam action tertentu. Sebagai contoh:
```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
```

Dan plug hanya akan dijalankan untuk `index` action.

**Plugs as composition**
Dengan mematuhi kontrak plug, kita mengubah sebuah request aplikasi menjadi sebuah series dari transformasi explisit. Itu tidak berhenti di sama. Untuk benar-benar melihat bagaimana efektifnya desain plug kita, mari kita bayangkan skenario di mana kita perlu mengecek sebuah series dari persyaratan dan kemudian meneruskan atau menahan jika persyaratan gagal. Tanpa plug, kita akan berakhir seperti ini:
```elixir
defmodule LearnPhoenixWeb.MessageController do
  use LearnPhoenixWeb, :controller

  def show(conn, params) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        case find_message(params["id"]) do
          nil ->
            conn |> put_flash(:info, "That message wasn't found") |> redirect(to: ~p"/")
          message ->
            if Authorizer.can_access?(user, message) do
              render(conn, :show, page: message)
            else
              conn |> put_flash(:info, "You can't access that page") |> redirect(to: ~p"/")
            end
        end
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: ~p"/")
    end  
  end
end
```

Lihat bagaimana hanya sedikit langkah untuk otentikasi dan otorisasi membutuhkan nesting yang rumit dan duplication (berulang)? Mari kita improve dengan beberapa plugs.
```elixir
defmodule LearnPhoenixWeb.MessageController do
  use LearnPhoenixWeb, :controller

  plug :authenticate
  plug :fetch_message
  plug :authorize_message

  def show(conn, params) do
    render(conn, :show, page: conn.assigns[:message])
  end

  defp authenticate(conn, _) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        assign(conn, :user, user)
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: ~p"/") |> halt()
    end
  end

  defp fetch_message(conn, _) do
    case find_message(conn.params["id"]) do
      nil ->
        conn |> put_flash(:info, "That message wasn't found") |> redirect(to: ~p"/") |> halt()
      message ->
        assign(conn, :message, message)
    end
  end

  defp authorize_message(conn, _) do
    if Authorizer.can_access?(conn.assigns[:user], conn.assigns[:message]) do
      conn
    else
      conn |> put_flash(:info, "You can't access that page") |> redirect(to: ~p"/") |> halt()
    end
  end
end
```
Untuk membuat ini semua bekerja, kita menconvert nested block dari code dan menggunakan `halt(conn)` di manapun kita mencapai sebuah path yang gagal. function `halt(conn)` sangat penting di sini: `halt(conn)` memberitahu bahwa plug selanjutnya tidak boleh dipanggil.

Pada akhirnya, dengan mengganti nested block menjadi beberapa plug, kita dapat mencapai fungsional yang sama dengan lebih tertata, jelas dan reusable.

Untuk mempelajari lebih lanjut tentang plug. Baca dokumentasinya di [Plugs project](https://hexdocs.pm/plug/1.14.2/Plug.html) yang menyediakan lebih banyak built-in plug dan fungsi-fungsinya.
