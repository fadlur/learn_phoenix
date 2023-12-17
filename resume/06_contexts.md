## Contexts

Sejauh ini kita telah membuat halaman-halaman, menyambungkan action controller melalui router kita, dan belajar bagaimana Ecto memungkinkan data untuk divalidasi dan disimpan. Sekarang waktunya untuk merangkai semua menjadi sebuah aplikasi web yang berinteraksi dengan aplikasi Elixir kita.

Ketika membangun project phoenix, kita pertama-tama membangun aplikasi Elixir. Tugas phoenix adalah menyediakan sebuah web interface ke aplikasi Elixir. Biasanya, kita menyusun aplikasi kita dengan module dan function, tapi hanya mendefinisikan modul dengan beberapa function tidaklah cukup dengan mendesain aplikasi. Kita perlu mempertimbangkan batasan antara module dan bagaimana mengelompokkan functionalitynya. Dengan kata lain, Sangat penting untuk berpikir tentang desain aplikasi saat menulis kode.

**Thinking about design**
Context adalah modul khusus yang mengekspose dan mengelompokkan functionality yang terkait. Sebagai contoh, kapanpun kamu memanggil standard library Elixir, bisa jadi `Logger.info/` atau `Stream.map/2`, kamu sedang mengakses context yang berbeda. Secara internal, Elixir logger dibuat dari beberapa modul, tapi kita tidak pernah berinteraksi dengan module tersebut secara langsung. Kita memanggil context modul `Logger`, Pastinya karena context itu mengekspos dan mengelompokkan semua functionality dari logging.

Dengan memberi nama context pada modul yang mengekspos dan mengelompookan functionality yang terkait, kamu membantu developer mengidentifikasi pattern ini dan membicarakannya. Pada akhirnya, context hanyalah module, seperti halnya controller, view dll.

Di Phoenix, context sering kali merangkum data access dan data validation. Mereka seringkali berhubungan dengan database atau APIs. Secara keseluruhan, anggaplah context adalah batasan untuk memisahkan dan mengisolasi bagian-bagian dari aplikasimu. mari kita gunakan ide-ide ini untuk membangun aplikasi web kita. Tujuan kita adalah untuk membangun sebuah sistem ecommerce dimana kita memamerkan produk, mengizinkan user untuk menambahkan produk ke keranjang mereka, dan menyelesaikan orderan mereka.

**Adding a Catalog Context**
Platform ecommerce mempunya keterkaitan yang luas di seluruh codebase, jadi penting untuk memikirkan tentang penulisan antarmuka yang terdefinisi dengan baik. Dengan pemikiran tersebut, tujuan kita adalah untuk membangun API katalog produk yang menghandle createing, updating, dan deleting ketersediaan produk di sistem kita. Kita akan memulai dengan fitur dasar untuk menampilkan produk kita, dan kita akan menambhkan fitur shopping cart kemudian. Kita akan melihat bagaimana memulai dengan fondasi yang kuat dengan batasan yang terisolasi memungkinkan kita untuk mengembangkan aplikasi kita secara alami saat kita menambahkan functionality.

Phonix menyertakan generator `mix phx.gen.html`, `mix phx.gen.json`, `min phx.gen.live`, dan `mix phx.gen.context` yang mengaplikasikan isolasi functionality di aplikasi kita menjadi context. Generator ini cara yang bagus untuk memulai sementara Phoenix mendorong anda ke arah yang benar untuk mengembangkan aplikasi anda. Mari kita gunakan alat ini untuk context katalog produk baru kita.

Untuk menjalankan context generator, kita perlu membuat nama modul yang mengelompokkan functionality terkait yang kita bangun. Dengan panduan Ecto, kita melihat bagaimana kita dapat menggunakan Changeset dan Repo untuk memvalidasi dan mempertahankan user schema, tapi kita tidak mengintegrasikan ini dengan aplikasi kita secara luas. Bahkan, kita sama sekali tidak memikirkan di mana "user" di aplikasi kita seharusnya berada. Mari kita mundur selangkah dan berpikir tentang berbagai bagian dari sistem kita. Kita tahu bahwa kita akan mempunyai produk untuk dipamerkan di halaman untuk dijual, bersama dengan description, harga dll. Bersama dengan menjual produk, kita tahu kita akan perlu mendukung keranjang, checkout dan sebagainya. Meskipun produk yang dibeli terkait dengan keranjang dan checkout proses, memamerkan produk dan mengelola pameran produk kita jelas berbeda dengan melacak user mana yang meletakkan produk ke keranjang dan bagimana order dilakukan. `Context` katalog adalah tempat yang alami untuk mengelola detail produk kita dan menampilkan produk yang kita jual.

Untuk memulai context katalog kita, kita akan menggunakan `mix phx.gen.html` yang membuat sebuah modul context yang membungkus Ecto access untuk creating, updating, dan deleting product, bersama dengan file web seperti controller dan template untuk web interface ke context kita.

Jalankan command di project root:

```elixir
mix phx.gen.html Catalog Product products titl
e:string description:string price:decimal views:integer
* creating lib/learn_phoenix_web/controllers/product_controller.ex
* creating lib/learn_phoenix_web/controllers/product_html/edit.html.heex
* creating lib/learn_phoenix_web/controllers/product_html/index.html.heex
* creating lib/learn_phoenix_web/controllers/product_html/new.html.heex
* creating lib/learn_phoenix_web/controllers/product_html/show.html.heex
* creating lib/learn_phoenix_web/controllers/product_html/product_form.html.heex
* creating lib/learn_phoenix_web/controllers/product_html.ex
* creating test/learn_phoenix_web/controllers/product_controller_test.exs
* creating lib/learn_phoenix/catalog/product.ex
* creating priv/repo/migrations/20231217024754_create_products.exs
* creating lib/learn_phoenix/catalog.ex
* injecting lib/learn_phoenix/catalog.ex
* creating test/learn_phoenix/catalog_test.exs
* injecting test/learn_phoenix/catalog_test.exs
* creating test/support/fixtures/catalog_fixtures.ex
* injecting test/support/fixtures/catalog_fixtures.ex

Add the resource to your browser scope in lib/learn_phoenix_web/router.ex:

    resources "/products", ProductController


Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

Phoenix men-generate file web seperti yang diharapkan di `lib/learn_phoenix_web/`. Kita dapat juga melihat context yang digenerate di dalam `lib/learn_phoenix/catalog.ex` dan product schema ada di dalam folder dengan nama yang sama. Perhatikan perbedaan antara `lib/learn_phoenix` dan `lib/learn_phoenix_web`. Kita punya module `Catalog` untuk menyediakan public API untuk product catalog functionality, seperti sebuah struct `Catalog.Product`, yang mana Ecto schema untuk casting dan validating product data. Phoenix juga menyediakan web dan context test untuk kita, termasuk helpers untuk membuat entiti via context `LearnPhoenix.Catalog`, yang akan kita lihat nanti, Sekarang, ikuti instruksi dan tambahkan route merujuk instruksi di console, di `lib/learn_phoenix_web/router.ex`:

```elixir
  scope "/", LearnPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :index
+   resources "/products", ProductController
  end
```

Dengan route baru, Phoenix mengingatkan kita untuk update repo dengan menjalankan `mix ecto.migrate`, tapi pertama kita perlu sedikit tweak untuk migration yang digenerate di `priv/repo/migrations/*_create_products.exs`:

```elixir
defmodule LearnPhoenix.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :title, :string
      add :description, :string
      add :price, :decimal, precision: 15, scale: 6, null: false
      add :views, :integer, default: 0, null: false

      timestamps()
    end
  end
end

```

Kita memodifikasi kolom price ke spesific precision 15, scale 6, bersama dengan batasan not-null. Ini memastikan kita menyimpan mata uang dengan presisi yang tepat untuk operasi matematika yang kita lakukan. Selanjutnya kita menambhkan default value dan batasan not-null pada jumlah views. Dengan perubahan yang telah dilakukan, kita siap untuk migrate ke database kita. Mari kita jalankan sekarang:

```elixir
mix ecto.migrate

10:11:46.203 [info] == Running 20231217024754 LearnPhoenix.Repo.Migrations.CreateProducts.change/0 forward

10:11:46.204 [info] create table products

10:11:46.220 [info] == Migrated 20231217024754 in 0.0s
```

Sebelum kita melompat ke kode yang digenerate, kita mulai dengan menjalankan server dengan `mix phx.server` dan buka halaman http://localhost:4000/products. Sekarang kita coba buat produk baru tanpa mengisi apapun. Kita harus diberi pesan berikut:

```elixir
Oops, something went wrong! Please check the errors below.
```

Ketika kita submit form, kita dapat melihat semua validasi error inline dengan inputs. Bagus! out of the box, context generator menyertakan schema field di template form kita dan kita dapat melihat validasi default kita untuk required input. Mari kita masukkan beberapa contoh produk data dan resubmit the form.

```elixir
Product created successfully.

Title: Metaprogramming Elixir
Description: Write Less Code, Get More Done (and Have Fun!)
Price: 15.000000
Views: 0
```

Jika kita ikuti link "Back", kita akan melihat list products, yang harus berisi satu produk yang baru kita buat. Demikian juga, kita dapat update data ini atau menghapusnya. Sekarang kita sudah melihat bagaimana ini bekerja di browser, sekarnag waktunya untuk melihat kode yang digenerate.

**Starting With Generators**
command `mix phx.gen.html` menghasilkan hasil yang besar. Kita mempunya banyak functionality out-of-the-box untuk creating, updating,dan deleting product di catalog kita. Ini masih jauh dari full-fitur aplikasi kita, tapi ingat, generator adalah learning tools yang pertama dan titik awal untuk anda untuk memulai membangun real features. Code generation tidak dapat mengatasi seluruh masalahmu, tapi dapat mengajari ins dan outs dari Phoenix dan mendorongmu kedepan dan proper mindset ketika mendesain aplikasimu.

Mari cek `ProductController` yang digenerate di `lib/learn_phoenix_web/controllers/product_controller.ex`:

```elixir
defmodule LearnPhoenixWeb.ProductController do
  use LearnPhoenixWeb, :controller

  alias LearnPhoenix.Catalog
  alias LearnPhoenix.Catalog.Product

  def index(conn, _params) do
    products = Catalog.list_products()
    render(conn, :index, products: products)
  end

  def new(conn, _params) do
    changeset = Catalog.change_product(%Product{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"product" => product_params}) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product created successfully.")
        |> redirect(to: ~p"/products/#{product}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    render(conn, :show, product: product)
  end

  def edit(conn, %{"id" => id}) do
    product = Catalog.get_product!(id)
    changeset = Catalog.change_product(product)
    render(conn, :edit, product: product, changeset: changeset)
  end
  ...
end
```

Kita dapat melihat bagaimana controller bekerja di [controller guide](https://hexdocs.pm/phoenix/controllers.html), Jadi kode mungkin tidak terlalu mengejutkan. Apa yang harus diperhatikan adalah bagaimana controller memanggil `Catalog` context. Kita dapat melihat action `index` mengambil sebuah list products dengan `Catalog.list_products/0`, dan bagaimana products disimpan di action `create` dengan `Catalog.create_product/1`. Kita belum melihat context Catalog, jadi kita belum tahu bagaimana product diambil dan pembuatan terjadi di balik layar. Phoenix controller adalah web interface ke aplikasi yang lebih besar. Seharusnya tidak perlu pedulu dengan detail bagaimana product diambil dari database atau disimpan ke dalam penyimpanan. Kita perlu memerintahkan aplikasi kita untuk melakukan beberapa pekerjaan untuk kita. Ini sangat bagus karena bisnis logic dan penyaimpanan kita terpisah dari web layer aplikasi kita. Jika kita pindah ke mesin penyimpanan text lengkap nanti untuk mengambil products alih-alih SQL query, controller kita tidak perlu diubah. Demikian pula,kita dapat menggunakan kembali kode context dari interface lain di aplikasi kita, baik itu channel, mix task, atau long-running process importing data CSV.

Di kasus action `create`, ketika kita sukses membuat sebuah produk, kita menggunakan `Phoenix.Controller.put_flash/3` untuk menunjukkan pesan sukses, dan kemudian kita redirect ke halaman detail product. Sebaliknya, jika `Catalog.create_product/1` gagal, kita akan merender template `new.html` kita dan meneruskan Ecto changeset untuk template untuk menaikkan pesan error.

Selanjutnya, mari kita gali lebih dalam dan checkout context `Catalog` di `lib/learn_phoenix/catalog.ex`:

```elixir
defmodule LearnPhoenix.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias LearnPhoenix.Repo

  alias LearnPhoenix.Catalog.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end
  ...
end
```

Modul ini akan menjadi public API untuk semua functionality product catalog di sistem kita. Sebagai contoh, untuk tambahan product detail menajement, kita mungkin juga menghandle klasifikasi category product dan product varian untuk hal seperti optional sizing, trims dll. Jika kita lihat di function `list_products/0`, kita dapat melihat detail dari mengambil product. Dan itu sangat sederhana. Kita mempunyai sebuah panggilan ke `Repo.all(Product)`. Kita melihat bagaimana Ecto repo query bekerja di [Ecto guide](https://hexdocs.pm/phoenix/ecto.html), jadi call ini terlihat familiar. Function `list_products` adalah nama function umum yang menentukan maksdu dari kode kita, yaitu membuat daftar produk.Detail dari maksud tersebut di mana kita menggunakan Repo kita untuk mengambil products dari PostgreSQL kita disembunyikan dari pemanggil kita. Ini adalah tema umum yang akan kita lihat diulang-ulang saat kita menggunakan generator Phoenix. Phoenix akan mendorong kita untuk berpikir tentang dimana kita mempunyai tanggungjawab berbeda di aplikasi kita, dan kemudian untuk membungkus area-area yang berbeda tersebut dibalik modul dan function yang diberi nama dengan baik yang membuat maksud dari baris kode jelas, sambil merangkum detilnya.

Sekarang kita tahu bagaimana data diambil, tapi bagaimana produk disimpan? mari kita lihat function `Catalog.create_product/1`:

```elixir
  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end
```

Ada lebih banyak dokumentasi dibanding kode disini, tapi beberapa hal perlu di highlight. Pertama, kamu dapat melihat lagi bahwa Ecto repo kita digunakan di balik layar untuk akses database. Kamu mungkin juga memperhatikan panggilan ke `Product.changeset/2`. Kita berbicara tentang changesets sebelumnya, dan sekarang kita melihatnya bekerja di context.

Jika kita buka `Product` di schema `lib/learn_phoenix/catalog/product.ex`, kita akan langsung familiar:

```elixir
defmodule LearnPhoenix.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :price, :decimal
    field :views, :integer

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :description, :price, :views])
    |> validate_required([:title, :description, :price, :views])
  end
end

```

Ini persis sperti yang kita lihat waktu kita menjalankan `mix phx.gen.schema`, kecuali di sini kita melihat sebuah `@doc false` di atas function `changeset/2`. Ini memberitahu kita bahwa ketika function ini dapat dipanggil secara public, function ini bukan bagian dari public API context. Pemanggil yang membangun changeset melakukannya juga via context API. Sebagai contoh, `Catalog.create_product/1` memanggil ke `Product.changeset/2` kita untuk membangung changeset dari user input. Pemanggil, seperti action controller, tidak mengakses `Product.changeset/2` secara langsung. Semua interaksi dengan product changeset dilakukan melalui public contect `Catalog`.

**Addinig catalog functions**
Seperti sudah kita lihat, modul context adalah modul khusus yang mengekspose dan mengelompokkan functionality yang terkait. Phoenix men-generate function umum, seperti `list_products` dan `update_products`, tai mereka hanya menyediakan seperti sebuah basis untuk untuk mengembangkan bisnis logic dan aplikasi. Mari tambahkan satu lagi fitur dasar dari catalog kita dengan mentracting total view halaman product.

Untuk sistem ecommerce apapun, kemampuan untuk mentract berapa kali sebuah halaman product dilihat sangat penting untuk marketing, saran, ranking dll. Ketika kita dapat mencoba menggunakan function `Catalog.update_product` yang ada, bersama dengan baris `Catalog.update_product(product, %{views: product.views + 1})` tidak hanya memotong race conditions, tapi juga memerlukan pemanggil untuk tahu terlalu banyak tentang sistem Catalog. Untuk melihat kenapa _race condition_ ada, mari kita lihat kemungkinan eksekusi dari event:

Secara intuitive, kamu mungkin mengasumsikan event berikut:

1. user 1 buka halaman product dengan jumlah view 13
2. user 1 menyimpan halaman product dengan jumlah view 14
3. user 2 buka halaman product dengan jumlah view 14
4. user 2 menyimpan halaman product dengan jumlah view 15

Padahal pada praktiknya, ini yang terjadi:

1. user 1 buka halaman product dengan jumlah view 13
1. user 2 buka halaman product dengan jumlah view 13
1. user 1 menyimpan halaman product dengan jumlah view 14
1. user 2 menyimpan halaman product dengan jumlah view 14

Race condition akan membuat hal ini cara yang tidak dapat diandalkan untuk mengupdate table yang ada karena banyak pemanggil mungkin mengupdate nilai view yang udah kadaluarsa. Ada cara yang lebih baik.

Coba pikirkan sebuah function yang mendeskripsikan apa yang kita ingin capai. Di sini bagaimana kita seharunsya menggunakan itu:

```elixir
product = Catalog.inc_page_views(product)
```

Itu terlihat bagus, pemanggil kita tidak akan bingung tentang apa yang function ini lakukan, dan kita dapat membungkus increment di sebuah operasi atom untuk menghindari race condition.

Buka catalog di `lib/learn_phoenix/catalog.ex` dan tambahkan function ini:

```elixir
  def inc_page_views(%Product{} = product) do
    {1, [%Product{views: views}]} =
      from(p in Product, where: p.id == ^product.id, select: [:views])
      |> Repo.update_all(inc: [views: 1])

      put_in(product.views, views)
  end
```

Kita membangung sebuah query untuk mengambil product saat ini berdasarkan ID yang diberikan yang kita oper ke `Repo.update_all`. `Repo.update_all` mengijinkan kita untuk melakukan update terhadap database, dan sempurna untuk secara atom mengupdate value, seperti incrementing views count kita. Hasil dari repo operation menghasilkan total data yang diupdate, bersama dengan schema value yang dipilih ditentukan oleh `select` option. Ketika kita menerima view product baru, kita menggunakan `put_in(product.views, views)` untuk menempatkan view count yang baru ke product struct.

Sekarang saatnya menggunakannya di product controller kita, Update action `show` di `lib/learn_phoenix_web/controllers/product_controller.ex` untuk memanggil function baru kita:

```elixir
  def show(conn, %{"id" => id}) do
    product =
      id
      |> Catalog.get_product!()
      |> Catalog.inc_page_views()

    # product = Catalog.get_product!(id)
    render(conn, :show, product: product)
  end
```

Kita modifikasi action `show` kita untuk pipe product yang kita ambil ke `Catalog.inc_page_views/1`, yang akan mengembalikan product yang telah diupdate. Kemudian kita merender template kita seperti sebelumnya. Mari kita coba, refresh salah satu halaman produk beberapa kali, dan perhatikan total count view yang bertambah.

Kita dapat juga melihat atomic update kita bekerja di ecto debug log:

```elixir
[debug] QUERY OK source="products" db=3.9ms idle=315.7ms
UPDATE "products" AS p0 SET "views" = p0."views" + $1 WHERE (p0."id" = $2) RETURNING p0."views" [1, 1]
```

Seperti kita lihat, mendesain dengan context memberimu fondasi yang solid untuk mengembangkan aplikasimu. Menggunakan API yang terdefinisikan dengan baik dan terpisah yang mengekspos maksud dari sistemmu memungkinkan kamu untuk menulis aplikasi lebih mudah dimaintainance dengan kode yang dapat digunakan kembali. Sekarang kita tahu, bagaimana memperluas API context kita, mari kita explore cara handling relationship dengan sebuah context.

**In-context Relationships**
Fitur dasar catalog udah bagus, tapi mari kita buat lebih bagus lagi dengan mengkategorikan product. Banyak solusi ecommeerce mengijinkan product dikategorikan di cara yang berbeda, seperti sebuah product ditandai sebagai fashion, power tool dll. Mulai dari one-to-one relationship antara product dan category, akan menyebabkan banyak perubahan kode nantinya kalau kite perlu mulai mendukung banyak category. Mari kita setup asosiasi category yang akan memungkinkan kita untuk memulai tracking single category per product, tapi dengan mudah mendukung lebih nantinya kalau kita mengembangkan fiturnya.

Sekarang, category akan berisi hanya informasi textual. Urutan pertama adalah menentukan dimana kategori berada di aplikasi. Kita sudah punya context `Catalog` , yang mengelola product kita. Kategorisasi product secara alami cocok di sini. Phoenix juga cukup cerdas untk men-generate kode di dalam context telah ada, yang membuat menambahkan resource baru ke context sangat mudah. Jalankan command berikut:

```elixir
mix phx.gen.context Catalog Category categorie
s title:string:unique
You are generating into an existing context.

The LearnPhoenix.Catalog context currently has 7 functions and 1 file in its directory.

  * It's OK to have multiple resources in the same context as long as they are closely related. But if a context grows too large, consider breaking it apart

  * If they are not closely related, another context probably works better

The fact two entities are related in the database does not mean they belong to the same context.

If you are not sure, prefer creating a new context over adding to the existing one.
Would you like to proceed? [Yn] y
* creating lib/learn_phoenix/catalog/category.ex
* creating priv/repo/migrations/20231217060108_create_categories.exs
* injecting lib/learn_phoenix/catalog.ex
* injecting test/learn_phoenix/catalog_test.exs
* injecting test/support/fixtures/catalog_fixtures.ex

Remember to update your repository by running migrations:

    $ mix ecto.migrate

```

Kali ini, kita menggunakan `mix phx.gen.context` yang seperti `mix phx.gen.html` hanya saja tidak men-generate file web untuk kita. Karena kita sudah mempunyai controller san template untuk mengelola product, kita dapat mengintegrasikan fitur new category ke existing web form, dan halaman product show. Kita dapat melihat, sekarang kita mempunyai sebuah `Category` schema baru bersama dengan schema lainnya di `lib/learn_phoenix/catalog/category.ex`. Dan phoenix memberi tahu kita baru saja menginject function baru ke context Catalog yang sudah ada untuk functionality category. function yang baru diinject terlihat mirip dengan product function kita, dengan new function seperti `create_category`, `list_category` dan lainnya. Sebelum kita migrate, kita perlu melakukan sedikit code generation. Category schema yang sekarang sudah cukup untuk merepressentasikan individual category di sistem, tapi kita perlu mendukung juga sebuah many-to-many relationship antara product dan category. Untungnya, ecto mengijinkan kita untuk melakukan ini dengan mudah dengan sebuah join table, jadi mari kita generate untuk skarang dengan command `ecto.gen.migration`:

```elixir
mix ecto.gen.migration create_product_categori
es
* creating priv/repo/migrations/20231217061724_create_product_categories.exs
```

Kemudian, buka migration yang baru saja dibuat dan tambahkan kode ke `change` function:

```elixir
defmodule LearnPhoenix.Repo.Migrations.CreateProductCategories do
  use Ecto.Migration

  def change do
    create table(:product_categories, primary_key: false) do
      add :product_id, references(:products, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :delete_all)
    end

    create index(:product_categories, [:product_id])
    create unique_index(:product_categories, [:category_id, :product_id])
  end
end

```

Kita telah membuat `product_categories` table dan menggunakan `primary_key: false` option karena join table kita tidak membutuhkan primary key. Kemudian kita mendefinisikan field `:product_id` dan `:category_id` foreign key, dan menambahkan `on_delete: :delete_all` untuk memastikan database menghapus data join table kita jika product atau category yang tersambung telah dihapus. Dengan menggunakna sebuah contraint database, kita memaksa data integrity di database level, dibandingkan menggantungkan ke ad-hoc dan error-prone di application logic.

Selanjutnya, kita membuat index untuk foreign key kita, satu diantaranya adalah unique index untuk memastikan sebuah product tidak mempunyai data duplikat. Perhatikan bahwa kita tidak perlu index kolom tunggal untuk category_id karena index ini berada di awalan paling kiri dari index multikolom, yang sudah cukup untk pengoptimal database. Sebaliknya, menambahkan index yang berlebihan hanya akan menambah overhead saat penulisan.

Sekarang kita migrate:

```elixir
mix ecto.migrate

13:20:16.331 [info] == Running 20231217060108 LearnPhoenix.Repo.Migrations.CreateCategories.change/0 forward

13:20:16.333 [info] create table categories

13:20:16.348 [info] create index categories_title_index

13:20:16.352 [info] == Migrated 20231217060108 in 0.0s

13:20:16.376 [info] == Running 20231217061724 LearnPhoenix.Repo.Migrations.CreateProductCategories.change/0 forward

13:20:16.376 [info] create table product_categories

13:20:16.381 [info] create index product_categories_product_id_index

13:20:16.383 [info] create index product_categories_category_id_product_id_index

13:20:16.385 [info] == Migrated 20231217061724 in 0.0s
```

Sekarang kita mempunyai sebuah schema `Catalog.Product` dan sebuah join table untuk asosiasi products dan categori, kita hampir siap untuk memulai melakukan wiring fitur baru kita. Sebelum kita melihat lebih lanjut, kita membutuhkan real categori untuk dipilih di web UI. Mari kita buat seed beberapa category di aplikasi. Tambahkan kode untuk seed file di `priv/repo/seeds.exs`:

```elixir
for title <- ["Home Improvement", "Power Tools", "Gardening", "Books", "Education"] do
  {:ok, _} = LearnPhoenix.Catalog.create_category(%{title: title})
end
```

Kita cukup enumerate sebuah list dari title category dan menggunakan function yang telah digenerate `create_category/1` dari context catalog untuk menyimpan data. Kita dapat menjalankan seeds dengan `mix run`:

```elixir
mix run priv/repo/seeds.exs
[debug] QUERY OK source="categories" db=2.9ms decode=0.6ms queue=24.9ms idle=0.0ms
INSERT INTO "categories" ("title","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["Home Improvement", ~N[2023-12-17 06:34:03], ~N[2023-12-17 06:34:03]]
↳ anonymous fn/1 in :elixir_compiler_1.__FILE__/1, at: priv/repo/seeds.exs:13
[debug] QUERY OK source="categories" db=0.9ms queue=1.0ms idle=11.8ms
INSERT INTO "categories" ("title","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["Power Tools", ~N[2023-12-17 06:34:03], ~N[2023-12-17 06:34:03]]
↳ anonymous fn/1 in :elixir_compiler_1.__FILE__/1, at: priv/repo/seeds.exs:13
[debug] QUERY OK source="categories" db=0.8ms queue=0.8ms idle=13.8ms
INSERT INTO "categories" ("title","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["Gardening", ~N[2023-12-17 06:34:03], ~N[2023-12-17 06:34:03]]
↳ anonymous fn/1 in :elixir_compiler_1.__FILE__/1, at: priv/repo/seeds.exs:13
[debug] QUERY OK source="categories" db=0.8ms queue=0.8ms idle=15.5ms
INSERT INTO "categories" ("title","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["Books", ~N[2023-12-17 06:34:03], ~N[2023-12-17 06:34:03]]
↳ anonymous fn/1 in :elixir_compiler_1.__FILE__/1, at: priv/repo/seeds.exs:13
[debug] QUERY OK source="categories" db=0.9ms queue=0.8ms idle=17.2ms
INSERT INTO "categories" ("title","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["Education", ~N[2023-12-17 06:34:03], ~N[2023-12-17 06:34:03]]
↳ anonymous fn/1 in :elixir_compiler_1.__FILE__/1, at: priv/repo/seeds.exs:13
```

Sebelum kita mengintegrasikan categories di web layer, kita perlu memberi tahu context tahu bagaimana mengasosiasikan product dan categori. Pertama, buka `lib/learn_phoenix/catalog/product.ex` dan tambahkan asosiasi berikut:
