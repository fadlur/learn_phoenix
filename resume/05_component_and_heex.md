## Components and HEEx

Phoenix endpoint pipeline mengambil request, mengarahkannya (routes) ke sebuah controller, dan memanggil modul view untuk merender sebuah template. View interface dari controller itu senderhana- Controller sebuah view function dengan connections assigns, dan function job adalah mengembalikan sebuah HEEx template. Kita memanggil function apapun yang menerima sebuah `assigns` parameter dan mengembalikan sebuah HEEx template dengan nama _function component_. Function component didefinisikan dengan bantuan module `Phoenix.Component`.

Function component building blok yang esensial untuk jenis apapun markup-based template rendering yang akan kamu lakukan di Phoenix. Mereka menyediakan sebuah shared abstraction untuk standard MVC controller-based application, LiveView application, layouts, dan UI yang lebih kecil melalui template lainnya.

Kita akan merecap apa yang kita gunakan di bab sebelumnya dan menemukan use case baru untuk mereka.

**Function components**
Di akhir bab Request life-cycle, kita membuat sebuah template di `lib/learn_phoenix_web/controllers/hello_html/show.html.eex`:

```elixir
<section>
  <h2>Hello World, from <%= @messenger %>!</h2>
</section>
```

Template ini, diembed sebagai bagian dari `HelloHTML`, di `lib/learn_phoenix_web/controllers/hello_html.ex`:

```elixir
defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  embed_templates "hello_html/*"
end
```

Cukup sederhana kan. Hanya ada 2 baris, `use LearnPhoenixWeb, :html`. Baris ini memanggil `html/0` function didefinisikan di `LearnPhoenixWeb` yang mengatur basic import dan konfigurasi untuk function component dan template kita.

Semua import dan alias yang kita buat di module kita akan ada juga di template kita. Itu karena template dikompile secara efektif menjadi function di dalam module mereka. Sebagai contoh, jika kamu mendefinisikan sebuah function di dalam modulemu, kamu akan dapat memanggilnya secara langsung dari template. Mari kita lihat di praktiknya.

Bayangkan kita mau merefactor `show.html.heex` untuk memindahkan rendering dari `<h2>Hello World, from <%= @messenger %>!</h2>` menjadi function sendiri. Kita dapat memindahkannya ke sebuah function component di dalam `HelloHTML`, mari kita coba:

```elixir
defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  # def index(assigns) do
  #   ~H"""
  #   Hello!
  #   """
  # end

  embed_templates "hello_html/*"

  attr :messenger, :string

  def greet(assigns) do
    ~H"""
    <h2>Hello World, from <%= @messenger %>!</h2>
    """
  end
end

```

Kita mendeklarasikan attributes yang kita terima via `attr` yang disediakan oleh `Phoenix.Component`, kemudian kita mendefinisikan `greet/1` function yang mengembalikan HEEx template.

Kemudian kita perlu mengupdate `show.html.heex` menjadi:

```elixir
<section>
  <.greet messenger={@messenger} />
</section>

```

Kemudian kita reload dan coba akses `http://localhost:4000/hello/Frank`, Hasilnya akan sama.

Karena template diembed di dalam modul `HelloHTML`, kita dapat memanggil view function sesederhana `<.greet messenger="..." />`

Jika component di definisikan di tempat lain, kita dapat juga memanggilnya seperti ini `<LearnPhoenixWeb.HelloHTML.greet messenger="..." />`

Dengan mendeklarasikan attribute, Phoenix akan mewarning jika kita memanggil `<.greet />` component tanpa melewatkan attributes. Jika attributes opsional, Kita dapat menentukan `:default` option dengan sebuah value:

```elixir
attr :messenger, :string, default: nil
```

Meskipun ini sample singkat, dapat terlihat perbedaan roles function component di Phoenix:

- Function component dapat didefinisikan sebagai function yang menerima `assigns` sebagai argument dan memanggil `~H` sigil, seperti yang kita lakukan di `greet/1`
- Function component dapat diembed dari template file, itu yang kita load `show.html.heex` ke `LearnPhoenixWeb.HelloHTML`
- Function component dapat mendeklarasikan yang attribut harapkan, yang divalidasi saat compilation time.
- Function component dapat secara langsung dirender dari controllers
- Function component dapat secara langsung dirender dari function component lainnya, seperti kita panggil `<.greet messenger={@messenger} />` dari `show.html.heex`

Dan ada banyak lagi. Sekarang kita pahami dulu apa itu HEEx.

**HEEx**
Function component dan template file powered oleh [HEEx template language](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2) yang mempunyai kepanjangan "HTML+EEx". EEx adalah library elixir yang menggunakan `<%= expression %>` untuk mengeksekusi Elixir expression dan interpolasi hasilnya menjadi template. Ini sering digunakan untuk menampilkan assigns yang telah kita set dengan shortcut `@`. Di controller, jika dipanggil:

```elixir
render(conn, :show, username: "joe")
```

Kemudian kamu dapat mengakses username di dalam template `<%= @username %>`. sebagai tambahan untuk menampilkan assign dan function, kita dapat menggunakan Elixir expression. Sebagai contoh, kita memiliki persyaratan (conditional):

```elixir
<%= if some_condition? do %>
    <p>Some condition is true for user: <%= @username %></p>
<% else %>
    <p>Some condition is false for user: <%= @username %></p>
<% end %>
```

atau loop:

```elixir
<table>
    <tr>
        <td>Number</td>
        <td>Power</td>
    </tr>
    <%= for number <- 1..10 do %>
    <tr>
        <td><%= number %></td>
        <td><%= number * number %></td>
    </tr>
    <% end %>
</table>
```

Perbedaan dari `<%= %>` vs `<% %>`? Semua ekspresi yang mengeluarkan sesuatu ke template harus menggunakan tanda sama dengan (`=`). Jika ini tidak diikutkan, kode akan tetap dieksekusi tapi tidak akan menyisipkan apapun ke dalam template.

HEEx juga datang dengan HTML extension yang akan kita pelajari kemudian.

**HTML extension**
Selain mengijinkan interpolasi via `<%= %>`, `.heex` template datang dengan juga dengan extension HTML-aware (melek). Sebagai contoh, lihat apa yang terjadi jika kamu melakukan interpolasi sebuah nilai dengan "<" atau ">" di dalamnya, yang akan menjadi HTML injection:

```elixir
<%= "<b>Bold?</b>" %>
```

Setelah kamu render templatenya, kamu akan melihat literal `<b>` di halaman. Ini berarti users tidak dapat menginject HTML content ke halaman. Jika kamu ingin mengijinkan inject ke HTML, kamu dapat memanggil `raw`, tapi tetap lakukan dengan hati-hati:

```elixir
<%= raw "<b>Bold?</b>" %>
```

Super power lain dari HEEx template adalah validasi dari HTML dan sintaks lean interpolasi dari attribut. Kamu dapat menulis:

```elixir
<div title="My div" class={@class}>
    <p>Hello <%= @username %></p>
</div>
```

Perhatikan, bagaimana kamu dapat dengan sederhana menggunakan `key={value}`. HEEx akan secara otomatis menghandle spesial value seperti `false` untuk menghapus attribut atau sebuah list dari class.

Untuk menginterpolasi sejumlah attribut dinamik di keyword list atau map:

```elixir
<div title="My div" {@many_attributes}>
    <p>Hello <%= @username %></p>
</div>
```

coba juga menghapus closing `</div>` atau rename menjadi `</div -typo>`. HEEx template akan memberi tahu tentang errornya.

HEEx juga mendukung syntaks shorthand untuk `if` dan `for` expression via attribut `:if` dan `:for`, sebagai contoh.
Daripada kayak gini:

```elixir
<%= if @some_condition do %>
 <div>...</div>
<% end %>
```

Mending gini:

```elixir
 <div :if={@some_condition}>...</div>
```

Demikian juga, untuk comprehension bisa ditulis gini:

```elixir
<ul>
    <li :for={item <- @item}><%= item.name %></li>
</ul>
```

**Layouts**
Layout hanyalah sebuah function compoenent. Mereka didefinisikan di dalam sebuah modul, seperti function component template lainnya. Di aplikasi yang baru digenerate, ada di sini.
`lib/learn_phoenix_web/components/layouts.ex`. Kamu akan menemukan di sebuah `layouts` folder dengan 2 built-in layouts yang digenerate oleh Phoenix. Default root layout dipanggil `root.html.heex` dan itu adalah layout untuk semua template akan dirender secara default. Yang kedua adalah app layout, dinamakan `app.html.heex` yang dirender di dalam root layout dan semua konten kita.

Kamu pasti bingung kan, string yang dihasilkan dari render view bisa masuk ke layout. Itu pertanyaannya. Mari kita lihat di `lib/learn_phoenix_web/components/layouts/root.html.heex` persis di atas `<body>`, kita akan menemukan.

```elixir
<%= @inner_content %>
```

Dengan kata lain, setelah merender halaman, hasilnya ditempatkan di dalam assign `@inner_content`.

Phoenix menyediakan semua jenis kemudahan untuk mengontrol yang layout perlu render. Sebagai contoh, modul `Phoenix.Controller` menyediakan function `put_root_layout/2` untuk kita untuk mengganti _root_ layouts. Ini mengambil `conn` sebagai argument pertama dan sebuah keyword list dari format dan layout mereka. Kamu dapat mengatur ke `false` untuk mendisable semua layout sama sekali.

Coba edit action `index` di `HelloController` di `lib/learn_phoenix_web/controllers/hello_controller.ex` menjadi seperti:

```elixir
def index(conn, _params) do
    # render(conn, :index)
    conn
    |> put_root_layout(html: false)
    |> render(:index)
  end
```

Setelah reloading http://localhost:4000/hello, kita bisa melihat sebuah halaman yang sangat berbeda, tanpa title/css sama sekali.

Untuk mengcustom layout aplikasi, kita memanggil function yang sama dengan nama `put_layout/2`. Buat layout lainnya, dan render index template ke situ. Katakanlah sebuah layot dengan nama admin yang tanpa logo.

Caranya copy paste `app.html.heex` dan rename menjadi `admin.html.heex` di folder yang sama di `lib/learn_phoenix_web/component/layouts`, kemudian edit2 dikitlah, biar kelihatan beda.

Sekarang, di dalam action `index` dari controller di `lib/learn_phoenix_web/controllers/hello_controller.ex`, ubah menjadi berikut:

```elixir
def index(conn, _params) do
    # render(conn, :index)
    conn
    |> put_layout(html: :admin)
    |> render(:index)
  end
```

Setelah direload harusnya akan ada perbedaan layout dari yang sebelumnya.

Sampai sini, bingungkan kenapa phoenix mempunyai 2 layout?

Pertama, itu memberikan fleksibilitas. Pada praktiknya, kita akan sulit mempunyai banyak root layouts, karena mereka terdiri dari banyak HTML headers. Ini mengijinkan kita fokus pada layout aplikasi liannya dengan hanya bagian yang berubah di antara mereka.
Kedua, Phoenix punya fitur namanya LIveView, yang mengijinkan kita membangun rich and rela-time experience dengan server-rendered HTML. LiveView bisa secara dinamis mengubah konten halaman, tapi hanya mengubah app layout, tidak dengan root layout. Check out [LiveView documentation](https://hexdocs.pm/phoenix_live_view).

**Core Component**
Di aplikasi phoenix yang baru dibuat, kamu juga akan menemukan `core_components.ex` di dalam `component` folder. Modul ini contoh yang bagus dari function component yang didefinisikan menjadi reused di dalam aplikasi kita. Ini menjamin kita, karena aplikasi kita berubah, component tampilannya tetep konsisten.

Jika kita lihat `def html` di `LearnPhoenixWeb` di `lib/learn_phoenix_web.ex` kamu akan melihat bahwa `CoreComponents` secara otomatis diimport ke semua HTML views via `use LearnPhoenixWeb, :html`. Ini alasan kenapa `CoreComponent` menjalankan `use Phoenix.Component` dibanding `use LearnPhoenixWeb, :html` di bagiaan atas, Melakukan yang terakhir akan menyebabkan deadlock karena kita mengimport `CoreComponent` ke dirinya sendiri.

CoreComponent melakukan peran penting di Phoneix code generator, karena code generator mengasumsikan component itu ada untuk membuat aplikasi kita secara cepat. Lebih detailnya:

- Explore modul `CoreComponent` dari contoh
- Baca dokumentasi [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- Baca dokumentasi untuk [HEEx dan ~H sigils](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2)
