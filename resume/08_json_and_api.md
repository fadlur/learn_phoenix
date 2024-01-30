## JSON and APIs

Dengan menggunakan Phoenix framework, kita bisa membuat web APIs, secara default Phoenix mendukung JSON tetapi kamu dapat merender format apapun.

**THE JSON API**

Mari kita buat simple JSON API untuk menyimpan link favorite, yang akan mendukung semua CRUD (Creat, Read, Update, Delete) out of the box.

Untuk panduan ini, kita akan menggunakan Phoenix generator untuk membangun infrastruktur API kita.

```elixir
mix phx.gen.json Urls Url url
s link:string title:string
* creating lib/learn_phoenix_web/controllers/url_controller.ex
* creating lib/learn_phoenix_web/controllers/url_json.ex
* creating lib/learn_phoenix_web/controllers/changeset_json.ex
* creating test/learn_phoenix_web/controllers/url_controller_test.exs
* creating lib/learn_phoenix_web/controllers/fallback_controller.ex
* creating lib/learn_phoenix/urls/url.ex
* creating priv/repo/migrations/20240129231225_create_urls.exs
* creating lib/learn_phoenix/urls.ex
* injecting lib/learn_phoenix/urls.ex
* creating test/learn_phoenix/urls_test.exs
* injecting test/learn_phoenix/urls_test.exs
* creating test/support/fixtures/urls_fixtures.ex
* injecting test/support/fixtures/urls_fixtures.ex

Add the resource to your :api scope in lib/learn_phoenix_web/router.ex:

    resources "/urls", UrlController, except: [:new, :edit]


Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

Kita akan memisahkan file itu menjadi 4 kategori:

- File di `lib/learn_phoenix_web` bertanggungjawab untuk merender json secara efektif.
- File di `lib/learn_phoenix` bertanggungjawab untuk mendefinisikan context kita dan logic untuk menyimpan link ke database
- File di `priv/repo/migrations` bertanggungjawab untuk mengupdate database kita.
- File di `test` untuk mengetes controllers dan contexts

Di dalam panduan ini, kita akan mengeksplore hanya kategori pertama. Untuk belajar lebih lanjut tentang bagaimana phoenix menyimpan dan memanage data, cek (Ecto guide)[https://hexdocs.pm/phoenix/ecto.html] dan (Context guide)[https://hexdocs.pm/phoenix/contexts.html] untuk info lebih lanjut. Kita juga punya sesi yang khusus untuk testing.

Pada bagian terakhir, generator meminta kita untuk menambahkan `/url` resource ke `:api` scope di dalam `lib/learn_phoenix_web/router.ex`:

```elixir
  scope "/api", LearnPhoenixWeb.Api, as: :api do
    pipe_through :api

    resources "/urls", UrlController, except: [:new, :edit]
  end
```

API scope menggunakan `:api` pipeline, yang akan menjalankan langkah-langkah spesifik seperti memastikan klien dapat menghandle JSON response.

Kemudian kita perlu mengupdate repository kita dengan menjalankan.

```elixir
mix ecto.migrate
```

**Trying out the JSON API**

Sebelum kita lanjut dan mengubah file itu, mari kita lihat bagaimana API kita merespon dari command line.

Pertama, kita perlu menjalankan server:

```elixir
mix phx.server
```

Kemudian, mari kita test API kita sudah berjalan dengan:

```elixir
curl -i http://localhost:4000/api/urls
```

Jika semua berjalan seperti yang kita rencanakan kita seharusnya mendapat response `200`:

```elixir
HTTP/1.1 200 OK
cache-control: max-age=0, private, must-revalidate
content-length: 11
content-type: application/json; charset=utf-8
date: Mon, 29 Jan 2024 23:24:50 GMT
server: Cowboy
x-request-id: F671AHVXL7rC6gwAAAAj

{"data":[]}
```

Kita tidak mendapatkan data apapun kecuali kita sudah mengumpulkan database. Jadi mari kita tambahkan beberapa link.

```elixir
curl -iX POST http://localhost:4000/api/urls \
   -H 'Content-Type: application/json' \
   -d '{"url": {"link":"https://phoenixframework.org", "title":"Phoenix Framework"}}'

curl -iX POST http://localhost:4000/api/urls \
   -H 'Content-Type: application/json' \
   -d '{"url": {"link":"https://elixir-lang.org", "title":"Elixir"}}'

```

Sekarang kita dapat mengambil semua link:

```elixir
curl -i http://localhost:4000/api/urls
```

Atau kita dapat hanya mengambil sebuah link berdasarkan idnya:

```elixir
curl -i http://localhost:4000/api/urls/1
```

Kemudian, kita dapat mengupdate sebuah link dengan:

```elixir
curl -iX PUT http://localhost:4000/api/urls/2 \
   -H 'Content-Type: application/json' \
   -d '{"url": {"title":"Elixir Programming Language"}}'

```

Response harusnya menjadi sebuah `200` dengan link yang telah diupdate di dalam body.

Akhirnya, kita perlu mencoba untuk menghapus sebuah link.

```elixir
curl -iX DELETE http://localhost:4000/api/urls/2 \
   -H 'Content-Type: application/json'

```

Sebuah response `204` harus dikembalikan untuk mengindikasikan penghapusan link sudah berhasil.

**Rendering JSON**
Untuk memahami bagaimana untuk merender JSON, mari mulai dengan action `index` dari `UrlController` yang didefinisikan di `lib/learn_phoenix_web/controllers/url_controller.ex`:

```elixir
  def index(conn, _params) do
    urls = Urls.list_urls()
    render(conn, :index, urls: urls)
  end
```

Seperti yang dapat kita lihat, tidak ada bedanya dengan bagaimana Phoenix merender HTML templates. Kita memanggil `render/3`, melewatkan connection (conn), template yang kita inginkan views merendernya (`:index`), dan data yang kita inginkan untuk ada di dalam views.

Phoenix biasanya menggunakan 1 view per format rendering. Ketika merender HTML, kita akan menggunakan `HelloHTML`. Sekarang kita merender JSON, kita akan menemukan sebuah `UrlJSON` view ditempatkan dengan template di `lib/learn_phoenix_web/controllers/url_json.ex`. Mari kita buka:

```elixir
defmodule LearnPhoenixWeb.UrlJSON do
  alias LearnPhoenix.Urls.Url

  @doc """
  Renders a list of urls.
  """
  def index(%{urls: urls}) do
    %{data: for(url <- urls, do: data(url))}
  end

  @doc """
  Renders a single url.
  """
  def show(%{url: url}) do
    %{data: data(url)}
  end

  defp data(%Url{} = url) do
    %{
      id: url.id,
      link: url.link,
      title: url.title
    }
  end
end

```

View ini sangat sederhana, function `index` menerima semua urls, dan mengubahnya menjadi sebuah list map. Map tersebut menaruh data key di dalam root, persis seperti kita lihat ketika menginterface dengan aplikasi kita dari `cURL`. Dengan kata lain, JSON view kita mengubah struktur komplek data menjadi data-struktur elixir sederhana. Phoenix menggunakan `Jason` library untuk encode JSON dan mengirim response ke klien.

Jika kita explore sisa controller, kita akan mempelajari action `show` mirip dengan `index`. Untuk action `create`, `update`, dan `delete`. Phoenix menggunakan sebuah fitur penting lainnya, "Action fallback"

**Action fallback**
Action fallback mengijinkan kita untuk melakukan sentralisasi error handling di dalam plugs, yang akan dipanggil ketika sebuah controller gagal mengembalikan struct `%Plug.Conn{}`. Plug ini menerima kedua `conn` yang secara original dilewatkan ke action controller bersama dengan value return dari action.

Katakanlah kita mempunya sebuah action `show` yang menggunakan `with` untuk mengambil sebuah blog post dan kemudian mengotorisasi current user untuk melihat blog post itu. Di dalam contoh itu kita mengharapkan `fetch_post/1` untuk mengembalikan `{:error, :not_found}` jika post tidak ditemukan dan `authorize_user/3` mungkin mengembalikan `{:error, :unauthorized}` jika user tidak diotorisasi. Kita dapat menggunakan `ErrorHTML` dan `ErrorJSON` view yang digenerate oleh Phoenix setiap kali aplikasi baru untuk menghandle error ini:

```elixir
defmodule LearnPhoenixWeb.MyController do
  use Phoenix.Controller

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- fetch_post(id),
         :ok <- authorize_user(current_user, :view, post) do
      render(conn, :show, post: post)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(html: LearnPhoenixWeb.ErrorHTML, json: LearnPhoenixWeb.ErrorJSON)
        |> render(:"404")

      {:error, :unauthorized} ->
        conn
        |> put_status(403)
        |> put_view(html: LearnPhoenixWeb.ErrorHTML, json: LearnPhoenixWeb.ErrorJSON)
        |> render(:"403")
    end
  end
end
```

Sekarang banyangkan kamu mungkin perlu mengimplement logic yang sama untuk setiap controller dan action yang menghandle API-mu. Ini akan menghasilkan di banyak repetisi.

Bukannya kita dapat mendefinisikan sebuah module plug yang tahu bagaimana untuk menghandle error cases ini secara signifikan. Karena controllers adalah module plugs, mari kita definisikan plug kita di dalam controller:

```elixir
defmodule LearnPhoenixWeb.MyFallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: LearnPhoenixWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(json: LearnPhoenixWeb.ErrorJSON)
    |> render(:"403")
  end
end
```

Kemudian kita dapat mereferensi controller baru kita sebagai `action_fallback` dan menghapus `else` block dari `with` kita:

```elixir
defmodule LearnPhoenixWeb.MyController do
  use Phoenix.Controller

  action_fallback LearnPhoenixWeb.MyFallbackController

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- fetch_post(id),
         :ok <- authorize_user(current_user, :view, post) do
      render(conn, :show, post: post)
    end
  end
end
```

Kapanpun `with` conditions tidak cocok, `LearnPhoenixWeb.MyFallbackController` akan menerima `conn` seperti result dari action dan response.

**FallbackController and ChangesetJSON**

Dengan pengetahuan di tangan, kita dapat mengexplore `FallbackController` (`lib/learn_phoenix_web/controllers/fallback_controller.ex`) digenerate oleh `mix phx.gen.json`. Biasanya, menghandle satu klausa (lainnya digenerate sebagai sebuah contoh):

```elixir
def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
  conn
  |> put_status(:unprocessable_entity)
  |> put_view(json: LearnPhoenixWeb.ChangesetJSON)
  |> render(:error, changeset: changeset)
end
```

Gol dari klausa ini adalah untuk menghandle `{:error, changeset}` mengembalikan type dari `LearnPhoenixWeb.Urls` context dan merender ke error render via `ChangesetJSON` view. Mari kita buka `lib/learn_phoenix_web/controllers/changeset_json.ex` untuk mempelajarinya lebih lanjut:

```elixir
defmodule LearnPhoenixWeb.ChangesetJSON do
    @doc """
    Renders changeset errors.
    """
    def error(%{changeset: changeset}) do
        # when encoded, the changeset returns its errors
        # as a JSON object, So we just pass it forward.
        %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
    end
end
```

Seperti dapat kita lihat, itu akan mengkonvert errors menjadi data struktur, yang akan dirender sebagai JSON. Changeset adalah sebuah data struktur yang bertanggungjawab untuk casting dan memvalidasi data. Sebagai contoh, didefinisikan di dalam `LearnPhoenix.Urls.Url.changeset/1` mari kita buka `lib/learn_phoenix/urls/url.ex` dan lihat definisinya:

```elixir
@doc false
def changeset(url, attrs) do
  url
  |> cast(attrs, [:link, :title])
  |> validate_required([:link, :title])
end
```

Seperti yang dapat kita lihat, changeset requires keduanya (link dan title) untuk diberikan. Ini berarti kita dapat mencoba posting sebuah url dengan tanpa link dan title dan lihat bagaimana API kita merespon:

```elixir
curl -iX POST http://localhost:4000/api/urls \
   -H 'Content-Type: application/json' \
   -d '{"url": {}}'

{"errors": {"link": ["can't be blank"], "title": ["can't be blank"]}}

```

Coba saja nanti modifikasi `changeset` function dan lihat bagaimana API merespon.

**API-only applications**
Semisal kita mau membuat aplikasi phoenix yang khusus untuk API, kita dapat memberi beberapa options ketika memanggil `mix phx.new`. Mari kita cek dengan `--no-*` flags kita dapat menggunakannya untuk mengenerate scaffolding yang tidak diperlukan di aplikasi Phoenix kita untuk REST API.

Dari terminal kita jalankan:

```elixir
mix help phx.new
```

Outpunya harusnya berisi:

```elixir
  • --no-assets - equivalent to --no-esbuild and --no-tailwind
  • --no-dashboard - do not include Phoenix.LiveDashboard
  • --no-ecto - do not generate Ecto files
  • --no-esbuild - do not include esbuild dependencies and
    assets. We do not recommend setting this option, unless for API
    only applications, as doing so requires you to manually add and
    track JavaScript dependencies
  • --no-gettext - do not generate gettext files
  • --no-html - do not generate HTML views
  • --no-live - comment out LiveView socket setup in
    assets/js/app.js. Automatically disabled if --no-html is given
  • --no-mailer - do not generate Swoosh mailer files
  • --no-tailwind - do not include tailwind dependencies and
    assets. The generated markup will still include Tailwind CSS
    classes, those are left-in as reference for the subsequent
    styling of your layout and components
```

`--no-html` adalah yang ingin kita gunakan ketika membuat aplikasi Phoenix untuk sebuah API untuk meninggalkan HTML yang tidak diperlukan. Kamu mungkin juga menambahkan `--no-assets`, jika kamu tidak ingin asset management apapun, `--no-gettext` jika kamu tidak ingin support internationalization, dan lainnya.
