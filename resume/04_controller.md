## Controllers

Phoenix controller bertindak sebagai modul perantara. Function mereka dipanggil action - yang dipanggil oleh router sebagai response terhadap HTTP request. Action, pada gilirannya, mengumpulkan semua data yang dibutuhkan dan menjalankan langkah-langkah yang dibutuhkan sebelum memanggil view layer untuk membuat templat atau mengembalikan sebuah JSON response.

Phoenix controller juga dibuat di atas Plug package, and mereka sendiri adalah plug. Controller menyediakan function untuk melakukan hampir semua yang kita butuhkan di sebuah action. Jika kita menemukan diri kita mencari sesuai yang Phoenix controller tidak sediakan, kita mungkin menemukan bahwa kita mencarinya di Plug sendiri. Baca-baca lagi tenant plug [disini](https://hexdocs.pm/phoenix/plug.html).

Satu buah phoenix apps yang baru saja digenerate, mempunyai 1 buah controller dengan nama `PageController`, yang dapat kita temukan di `lib/learn_phoenix_web/controllers/page_controller.ex` yang terlihat seperti berikut:

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
```

Baris pertama di bawah module definisi memanggil macro `__using__/1` dari modul `LearnPhoenixWeb`, yang mengimport beberapa modul yang berguna.

`PageController` memberi kita `home` action untuk menampilkan Phoenix [welcome page](http://localhost:4000) yang diasosiasikan dengan default route yang didefinisikan di router.

**Action**
Controller action hanyalah functions. Kita dapat memberi nama mereka apapun yang kita suka sepanjang mereka mengikuti aturan nama Elixir. Requirement yang kita harus penuhi adalah nama action cocok dengan route yang didefinisikan di router.

Sebagai contoh, di `lib/learn_phoenix_web/router.ex` kita dapat mengubah nama action di default route dari `home`:

```elixir
get "/", PageController, :home
```

ke `index`

```elixir
get "/", PageController, :index
```

Sepanjang kita menbuah nama action di `PageController` menjadi `index` juga, [welcome page](http://localhost:4000) akan tetap tampil seperti sebelumnya.

```elixir
defmodule LearnPhoenixWeb.PageController do
  ...

  def index(conn, _params) do
    render(conn, :index)
  end
end
```

Saat kita dapat mengubah nama action menjadi apapun yang kita mau, ada conventions untuk nama action yang kita harus ikuti sebisa mungkin. Kita cek lagi materi di [routing guide](https://hexdocs.pm/phoenix/routing.html), tapi di sini kita akan melihat sekilas.

- index - membuat daftar semua item yang diberikan oleh resource type
- show - membuat 1 buah item berdasarkan ID
- new - membuat 1 form untuk membuat 1 item baru
- create - menerima parameter untuk 1 buah item dan menyimpannya ke data store
- edit - menerima 1 buah item berdasarkan ID dan menampilkannya di dalam form untuk editing
- update - menerima parameter untuk 1 item yang diedit dan menyimpannya ke data store
- delete - menerima sebuah ID untuk sebuah item dihapus, dan menghapusnya dari data store

Masing-masing action tadi mengambil 2 parameter, yang akan disedikan oleh phoenix di belakang layar.

parameter pertama selalu `conn`, sebuah struct yang memegang informasi tentang request seperti host, path element, port, query string dan banyak lagi. `conn` datang ke phoenix via plug Elxiir middleware framework. Lebih detail tenant `conn` dapat ditemukan di [Plug conn documentation](https://hexdocs.pm/plug/1.14.2/Plug.Conn.html).

Paramter kedua adalah `params`. Ini adalah sebuah map yang memegang parameter apapun yang dikirim bersama dengan HTTP request. Good practice untuk pattern match terhadap parameter di function signature untuk menyediakan data di sebuah simple package yang dapat kita teruskan untuk ditampilkan. Kita melihat ini di [request life cycle](https://hexdocs.pm/phoenix/request_lifecycle.html) ketika kita menambahkan sebuah messenger parameter ke route `show` di dalam `lib/learn_phoenix_web/controllers/hello_controller.ex`:

```elixir
defmodule LearnPhoenixWeb.HelloController do
  ...

  def show(conn, %{"messenger" => messenger}) do
    render(conn, :show, messenger: messenger)
  end
end

```

di router tambahkan route berikut:

```elixir
get "/hello/:messenger", HelloController, :show
```

di beberapa kasus - seringnya di action `index`, sebagai contoh - kita tidak peduli tentang parameter karena behaviou kita tidak tergantung padanya. Di kasus itu, kita tidak menggunakan parameter yang datang, dan kita cukup menambahkan underscore (`_params`). Ini akan menjaga compiler tidak complain tentang variable yang tidak digunakan sambil tetap menjaga arity yang benar.

**Rendering**
Controller dapat membuat content dengan beberapa cara. Cara paling sederhana adalah menampilkan beberapa text menggunakan function `text/2` yang Phoenix sediakan.

Sebagai contoh, mari kita tulis ulang `show` action dari `HelloController` menjadi text.

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    text(conn, "From messenger #{messenger}")
  end
end

```

Sekarang coba kita akses `hello/Frank` di browsermu harus menampilkan `From messenger Frank` sebagai text tanpa HTML apapun.

Sebuah langkah lebih lanjut adalah merender pure JSON dengan function `json/2`. Kita perlu memberikan sesuatu yang dapat didecode oleh [Jason library](https://hexdocs.pm/jason/1.4.0/Jason.html) menjadi JSON, seperti map. (Jason adalah salah satu dari Phoenix dependencies).

```elixir
  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    json(conn, %{id: messenger})
  end
```

Kemudian diakses lagi `hello/Frank` maka kita akan melihat satu buah blok JSON dengan key `id` dengan value `Frank`.

```elixir
{"id": "Frank"}
```

function `json/2` sanget berguna untuk membuat API dan ada juga function `html/2` untuk rendering HTML, tapi sering kali kita menggunakan Phoenix views untuk membuat response kita. Untuk ini, Phoenix mengikutkan function `render/3`. Khususnya untuk HTML response, karena Phoenix Views menyediakan performance dan security benefits.

Mari kita kembalikan action `show` seperti yang kita tulis [request life cycle](https://hexdocs.pm/phoenix/request_lifecycle.html)

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    # json(conn, %{id: messenger})
    render(conn, :show, messenger: messenger)
  end
end

```

Agar `render/3` bekerja dengan baik, controller dan view harus berbagi root name (di kasus ini adalah `Hello`), dan modul `HelloHTML` harus mengikutkan `embed_templates` untuk menentukan di mana tmeplate berada. Secara default controller, module view, dan template berada di folder yang sama yaitu folder controllers. Dengan kata lain, `HelloController` membutuhkan `HelloHTML`, dan `HelloHTML` membutuhkan keberadaan dari folder `lib/learn_phoenix_web/controllers/hello_html/`, yang harus berisi `show.html.heex` template.

`render/3` akan mengirim value yang `show` terima sebagai `messenger` dari parameter sesuai sebuah assign.

Jika kita perlu mengirim value ke template ketika menggunakan `render`, itu mudah saja. Kita dapat mengirim sebuah keyword seperti kita lihat di `messenger: messenger` atau kita dapat menggunakan `Plug.Conn.assign/3`, yang aturannya mengembalikan `conn`.

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    # json(conn, %{id: messenger})
    # render(conn, :show, messenger: messenger)
    conn
    |> Plug.Conn.assign(:messenger, messenger)
    |> render(:show)
  end
end

```

kemudian buat file `show.html.heex` di dalam folder `lib/learn_phoenix_web/controllers/hello_html/`

```elixir
<section>
  <h2><%= "Hello #{@messenger}" %></h2>
</section>

```

Catatan: Menggunakan `Phoenix.Controller` mengimport `Plug.Conn`, maka pendekkan panggilan ke `assign/3` bekerja dengan baik.

Mengirim lebih dari 1 value ke template kita akan sesederhana menyambungkan `assign/3` function bersama:

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    # json(conn, %{id: messenger})
    # render(conn, :show, messenger: messenger)
    # conn
    # |> Plug.Conn.assign(:messenger, messenger)
    # |> render(:show)

    conn
    |> assign(:messenger, messenger)
    |> assign(:receiver, "Dweezil")
    |> render(:show)
  end
end

```

Atau kamu dapat juga mengirim assign secara langsung ke `render`:

```elixir
defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    # json(conn, %{id: messenger})
    # render(conn, :show, messenger: messenger)
    # conn
    # |> Plug.Conn.assign(:messenger, messenger)
    # |> render(:show)

    # conn
    # |> assign(:messenger, messenger)
    # |> assign(:receiver, "Dweezil")
    # |> render(:show)

    render(conn, :show, messenger: messenger, receiver: "Dweezil")
  end
end

```

Secara umum, sekali semua assign sudah dikonfigurasi, kita memanggil view layer. View layer (`LearnPhoenixWeb.HelloHTML`) kemudian merender `show.html` bersama dengan layout dan sebuah response dikirim kembali ke browser.

[Componenet and HEEx templates](https://hexdocs.pm/phoenix/components.html) memiliki bagiannya sendiri di guide ini, jadi kita tidak menghabiskan banyak waktu di sini. Apa yang kita lihat adalah bagimana merender format berbeda dari dalam controller action.

**New rendering formats**

Merender HTML melalui sebuah template oke-oke saja, tapi bagaimana kalau kita ingin mengubah format rendering on the fly? Katakanlah suatu saat kita membutuhkan HTML, suatu saat kita membutuhkan text dan suatu saat kita membutuhkan JSON. kemudian apa?

Tugas view tidak hanya merender HTML template. View adalah tentang menyajikan data. Diberikan banyak data, tujuan view adalah untuk menyajikan dengan cara yang bermakna dengan beberapa format, bisa jadi HTML, JSON, CSV atau lainnya. Banyak aplikasi web sekarang ini mengembalikan JSON ke remote client, dan Phoenix views sangat hebat untuk JSON rendering.

Sebagai contoh, ambil actin `home` di `PageController` dari aplikasi yang baru digenerate. Di luar kota, ini memiliki view yang bener `PageHTML`, template yang diembed dari `lib/learn_phoenix_web/controllers/page_html` dan template yang sesuai untuk rendering HTML di (`home.html.heex`)

```elixir
def home(conn, _params) do
  render(conn, :home, layout: false)
end
```

Apa yang tidak dimiliki adalah view untuk rendering JSON. Phoenix controller menyerahkan kepada modul view untuk merender template, dan melakukannnya per format. Kita sudah memiliki view untuk HTML format, tapi kita perlu menginstruksikan Phoenix bagaimana cara merender JSON format juga. Secara default, anda dapat melihat format mana yang didukung di `lib/learn_phoenix_web.ex`:

```elixir
def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: LearnPhoenixWeb.Layouts]

      ...
    end
  end
```

Jadi out of the box Phoenix akan mencari sebuah `HTML` dan `JSON` module view berdasarkan request format dan controller name. Kita dapat juga secara eksplisit memberi tahu Phoenix di controller kita view mana digunakan untuk masing-masing format. Sebagai contoh, apa yang Phoenix lakukan secara default dapat secara eksplisit mengatur dengan plug berikut di controller:

```elixir
plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
```

Mari tambahkan sebuah `PageJSON` module view di `lib/learn_phoenix_web/controllers/page_json.ex`:

```elixir
defmodule LearnPhoenixWeb.PageJSON do
  def home(_assigns) do
    %{message: "this is some json"}
  end
end
```

Karena phoenix view layer adalah sebuah function yang controller render, mengirim connection assigns, kita dapat mendefinisikan sebuah function regular `home/1`dan mengembalikan sebuah map menjadi serialized seperti JSON.

Ada beberapa hal yang kita perlu lakukan untuk membuat ini bekerja. Karena kita ingin merender HTML dan JSON dari controller yang sama, kita perlu memberitahu router kita yang harus menerima `json` format. Kita melakukan itu dengan menambahkan `json` ke list format yang diterima di `:browser` pipeline. Mari kita buka `lib/learn_phoenix_web/router.ex` dan ubah plug `:accepts` untuk mengikutkan `json` seperti `html` seperti ini:

```elixir
defmodule LearnPhoenixWeb.Router do
  use LearnPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "json"]
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

Phoenix mengijinkan kita untuk mengubah format on the fly dengan `_format` query string parameter. Jika kita pergi ke `http://localhost:4000/?_format=json`, kita dapat melihat `%{"message": "this is some JSON"}`.

Pada praktiknya, bagaimanapun, aplikasi yang perlu merender dua format biasanya menggunakan 2 pipeline berbeda untuk masing-masing, seperti `pipeline :api` sudah didefinisikan di file router. Untuk mempelajari lebih lanjut. Buka [our JSON and API's guide](https://hexdocs.pm/phoenix/json_and_apis.html).

**Sending responses directly**
Jika tidak ada opsi rendering yang sesuai dengan yang kita butuhkan, kita dapat menyusun sendiri function yang `plug` berikan ke kita. katakanlah kita ingin mengirim sebuah response dengan status "201" dan tanpa "body". Kita dapat melakukan itu dengan `Plug.Conn.send_resp/3`

Edit `home` di `PageController` di `lib/learn_phoenix_web/controllers/page_controller.ex` menjadi berikut:

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    send_resp(conn, 201, "")
  end
end

```

Reload http://localhost:4000 dan halaman kosong yang tampil. Buka network tab di developer tool browser. harusnya memperlihatkan "201" status (created). Beberapa browser seperti safari akan mendownload response, karena content type tidak diset.

Untuk content type yang lebih spesifik, kita dapat menggunakan `put_resp_content_type/2` di konjungsi dengan `send_resp/3`

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(201, "")
  end
end

```

Menggunakan function `Plug` dengan cara ini, kita dapat membuat response yang kita inginkan.

**Setting the content type**
Analog ke `_format` query string param, kita dapat merender format apapun yang kita inginkan dengan memodifikasi HTTP Content-Type Header dan menyediakan template yang tepat.

Jika kita ingin merender sebuah XML version dari action `home`, kita harus mengimplementasi action seperti ini di `lib/learn_phoenix_web/page_controller.ex`:

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    # conn
    # |> put_resp_content_type("text/plain")
    # |> send_resp(201, "halo")

    conn
    |> put_resp_content_type("text/xml")
    |> render(:home, content: some_xml_content)
  end
end

```

Kita perlu menyediakan `home.xml.eex` template yang dibuat valid XML, dan kita bisa selesai.

List valida mime-type bisa dilihat di [MIME](https://hexdocs.pm/mime/2.0.5/MIME.html) library

**Setting HTTP Status**
Kita dapat juga mengatur HTTP status code dari sebuah response sama dengan cara kita mengeset content type. Modul `Plug.Conn` yang diimport ke semua controller, mempunyai sebuah `put_status/2` untuk melakukan ini.

`Plug.Conn.put_status/2` mengambil `conn` sebagai parameter pertama dan sebagai parameter kedua sebuah integer atau sebuah "friendly name" digunakan sebagai sebuah atom untuk status code yang kita inginkan. Daftar status code respresentasi atom dapat ditemukan di dokumentasi `Plug.Conn.Status.code/1`

mari kita ubah status dari action `home` di `PageController`:

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    # conn
    # |> put_resp_content_type("text/plain")
    # |> send_resp(201, "halo")

    conn
    |> put_status(202)
    |> render(:home, layout: false)
  end
end

```

Status code yang kita sediakan harus berupa nomer yang valid.

**Redirection**
Sering kita harus meredirect ke sebuah URL baru di tengah-tengah sebuah request. action `create` yang sukses, sebagai contohnya umumnya meredirect ke action `show` untuk resource yang baru kita buat. Alternatifnya, kita dapat meredirect ke action `index` untuk memperlihatkan semua hal yang mempunyai tipe yang sama. Ada banyak kasus lainnya di mana redirection sangat berguna juga.

Keadaan apapun, Phoenix controller menyediakan `redirect/2` untuk membuat redirection lebih mudah. Phoenix membedakan antara redireting ke sebuah path di dalam aplikasi dan redirecting ke URL keluar aplikasi.

Untuk lebih jelasnya, buat route baru di `lib/learn_phoenix_web/router.ex`:

```elixir
defmodule LearnPhoenixWeb.Router do
  ...

  scope "/", LearnPhoenixWeb do
    ...
    get "/", PageController, :home
    get "/redirect_test", PageController, :redirect_test
    ...
  end
end
```

Kemudian kita ubah action `home` di `PageController` untuk meredirect ke route yang baru.

```elixir
defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/redirect_test")
  end
end

```

Kita menggunakan `Phoenix.VerifiedRoutes.sigil_p/2` untuk membangun redirect path, yang mana adalah path di dalam aplikasi. Kita telah belajar tentang verified routes di [routing guide](https://hexdocs.pm/phoenix/routing.html)

Akhirnya, mari kita definisikan di dalam file yang sama action yang menghandle redirect kita. Isinya hanye merender home, tapi sekarang di bawah alamat baru:

```elixir
def redirect_test(conn, _params) do
  render(conn, :home, layout: false)
end
```

Ketika kita reload [welcome page](http://localhost:4000), kita melihat bahwa kita telah diredirect ke `/redirect_test` yang memperlihatkan halaman asli welcome page.

Jika kita cek di developer tool, di network tab. Kita lihat 2 request utama untuk halaman ini. `/` dengan sebuah status `302` dan `/rediret_test` dengan status `200`

Perhatikan bahwa redirect function mengambil `conn` seperti string yang merepresentasi sebuah relative path di dalam aplikasi kita. untuk alasan keamanan, `:to` option hanya dapat meredirect path di dalam aplikasi kita. Jika ingin redirect ke path full atau external URL, harus menggunakan `:external`:

```elixir
def home(conn, _params) do
  redirect(conn, external: "https://elixir-lang.org/")
end
```

**Flash messages**
Kadang kita perlu berkomunikasi dengan users selama melakukan suatu action. Mungkin ada error waktu update schema, atau mungkin sekedar memberi ucapan selamat datang. Untuk ini, kita punya flash messages.

`Phoenix.Controller` menyediakan `put_flash/3` untuk mengeset flash message seperti sebuah key-value pair dan menempatkan mereka ke dalam sebuah `@flash` assign di koneksi (conn). Mari kita set 2 flash message di `LearnPhoenixWeb.PageController`.

Modifikasi `home` seperti berikut:

```elixir
defmodule LearnPhoenixWeb.PageController do
  ...
  def home(conn, _params) do
    conn
    |> put_flash(:error, "Let's pretend we have an error.")
    |> render(:home, layout: false)
  end
end
```

Untuk melihat flash message, kita harus dapat menerima dan menampilkan mereka di template layout. Kita dapat melakukan ini dengan menggunakan `Phoenix.Flash.get/2` yang mengambil flash data dan key yang kita pedulikan. Kemudian mengembalikan value untuk key tersebut.

Untuk memudahkan kita, sebuah component `flash_group` sudah tersedia dan ditambahkan ke [welcome page](http://localhost:4000).

```elixir
<.flash_group flash={@flash} />
```

Ketika kita reload [welcome page](http://localhost:4000), pesan kita harus tampil di kanan atas halaman.

Flash functionality sangat praktis ketika dicampur dengan redirects. Mungkin kamu ingin meredirect ke sebuah halaman dengan informasi tambahan. Jika kita reuse action redirect dari sesi sebelumnya, kita dapat melakukan:

```elixir
  def home(conn, _params) do
    conn
    |> put_flash(:error, "Let's pretend we have an error.")
    |> redirect(to: ~p"/redirect_test")
  end
```

Sekarang kalau kita reload [welcome page](http://localhost:4000) akan diredirect dan flash message akan tampil sekali lagi.

Selain `put_flash/3`, `Phoenix.Controller` mempunyai function lainnya yang harus diketahui. `clear_flash/1` mengambil hanya `conn` dan menghapus flash apapun yang disimpan di session.

Phoenix tidak memaksa key mana yang distore di flash. Selama kita konsisten, semua akan baik-baik saja. `:info` dan `:error`, bagaimanapun umum dan dihandle secara default di template kita.

**Error pages**
Phoenix mempunyai 2 views yang dipanggil `ErrorHTML` dan `ErrorJSON` yang ada di `lib/learn_phoenix_web/controllers/`. Tujuan views ini adalah untuk menghandle errors secara umum untuk request HTML dan JSON. Sama dengan view yang kita bangun di panduan ini, error views dapat mengembalikan keduanya HTML dan JSON response. Lihat [Custom Error Pages How-To](https://hexdocs.pm/phoenix/custom_error_pages.html) untuk lebih lanjut.
