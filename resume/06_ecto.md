## Ecto

Kebanyakan aplikasi sekarang ini membutuhkan beberapa form validasi dan persistence data. Di ekosistem Elixir kita mempunya `Ecto` untuk melakukan ini. Sebelum kita terjun lebih dalam ke aplikasi yang didukung database, kita akan fokus dulu ke hal-hal mendetail dari Ecto untuk memberikan dasar yang solid untuk membangun fitur web kita di atasnya.

Database yang disupport Ecto:
- PostgreSQL (via `postgrex`)
- MySQL (via `myxql`)
- MSSQL (via `tds`)
- ETS (via `etso`)
- SQLite3 (via `ecto_sqlite3`)

Untuk aplikasi yang baru saja dibuat akan mengikutkan Ecto dengan PostgreSQL adapter secara default. Untuk mengubahnya tambahkan opsi `--database` atau `--no-ecto` flag untuk tidak mengikutkan ecto ke aplikasi.

** Using the schema and migration generator**
Setelah Ecto dan PostgreSQL diinstall dan dikonfigurasi, cara paling  mudah untuk menggunakan Ecto adalah dengan men-generate sebuah Ecto _schema_ melalui `phx.gen.schema`. Ecto schema adalah cara bagi kita untuk menentukan bagaimana Elixir data type memetakan ke dan dari external sources, seperti database table. Mari buat `User` schema dengan `name`, `email`, `bio`, dan `number_of_pets` field.

```elixir
mix phx.gen.schema User users name:string email:string \
bio:string number_of_pets:integer

* creating ./lib/hello/user.ex
* creating priv/repo/migrations/20170523151118_create_users.exs

Remember to update your repository by running migrations:

   $ mix ecto.migrate

```
Beberapa file telah dibuat dengan command ini. Pertama, kita punya `user.ex` file, berisi Ecto schema dengan schema defini dari field yang kita teruskan di command tadi. Kemudian, sebuah migration file yang digenerate di dalam `priv/repo/migration` yang akan membuat database table yang akan dipetakan oleh schema kita.

Sekarang kita jalan perintah migrate:

```elixir
>mix ecto.migrate
Compiling 8 files (.ex)
Generated learn_phoenix app

08:58:23.152 [info] == Running 20231215015715 LearnPhoenix.Repo.Migrations.CreateUsers.change/0 forward

08:58:23.154 [info] create table users

08:58:23.199 [info] == Migrated 20231215015715 in 0.0s
```
Mix mengasumsikan kita ada di environtment development sampai kita memberitahu sebaliknya dengan `MIX_ENV=prod mix ecto.migrate`

Jika kita login ke database server, dan terkoneksi ke database `learn_phoenix_dev`, kita bisa melihat table `users`. Ecto mengasumsikan bahwa kita ingin sebuah kolom integer dengan nama `id` sebagai primary key, jadi kita bisa melihatnya juga.

```elixir
# psql -U postgres
psql (16.1 (Debian 16.1-1.pgdg110+1))
Type "help" for help.

postgres=# \connect learn_phoenix_dev
You are now connected to database "learn_phoenix_dev" as user "postgres".
learn_phoenix_dev=# \d
                List of relations
 Schema |       Name        |   Type   |  Owner   
--------+-------------------+----------+----------
 public | schema_migrations | table    | postgres
 public | users             | table    | postgres
 public | users_id_seq      | sequence | postgres
(3 rows)

learn_phoenix_dev=# \q
# 
```

Jika kita melihat migration yang digenerate oleh `phx.gen.schema` di `priv/repo/migrations/`, kita akan melihat bahwa command itu akan menambhakan column yang kita tentukan. Itu juga akan menambahkan kolom timestamp untuk `inserted_at` dan `updated_at` yang datang dari function `timestamps/1`

```elixir
defmodule LearnPhoenix.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :bio, :string
      add :number_of_pets, :integer

      timestamps()
    end
  end
end

```
Dan ini adalah apa yang ditranslate ke table `users`:
```elixir
# psql -U postgres
psql (16.1 (Debian 16.1-1.pgdg110+1))
Type "help" for help.

postgres=# \connect learn_phoenix_dev
You are now connected to database "learn_phoenix_dev" as user "postgres".
learn_phoenix_dev=# \d users
                                            Table "public.users"
     Column     |              Type              | Collation | Nullable |              Default              
----------------+--------------------------------+-----------+----------+-----------------------------------
 id             | bigint                         |           | not null | nextval('users_id_seq'::regclass)
 name           | character varying(255)         |           |          | 
 email          | character varying(255)         |           |          | 
 bio            | character varying(255)         |           |          | 
 number_of_pets | integer                        |           |          | 
 inserted_at    | timestamp(0) without time zone |           | not null | 
 updated_at     | timestamp(0) without time zone |           | not null | 
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)

learn_phoenix_dev=# 
```
Perhatikan bahwa kita juga mendapatkan kolom `id` sebagai primary key secara default, meskipun itu tidak kitamasukkan sebagai field di migration.

**Repo configuration**
Module `LearnPhoenix.Repo` kita adalah pondasi yang kita buuthkan untuk bekerja dengan database di aplikasi phoenix. Phoenix men-generatenya untuk kita di `lib/learn_phoenix/repo.ex` dan ini yang dapat kita lihat:
```elixir
defmodule LearnPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :learn_phoenix,
    adapter: Ecto.Adapters.Postgres
end

```

Itu dimulai dengan mendefinisikan module repository, kemudian mengkonfigurasi nama `otp_app` dan `Postgres`-`adapter`, untuk kasus ini.

Repo mempunyai 3 tugas utama:
1. untuk memasukkan semua function query dari [`Ecto.Repo`]
2. untuk mengeset nama `otp_app` sama dengan nama aplikasi kita,
3. untuk mengkonfigurasi database adapter kita.

Kita akan membahasnya tentang bagaimana menggunakan `LearnPhoenix.Repo` sedikit.

Ketika `phx.new` men-generate aplikasi kita, itu mengikutkan beberapa basic konfigurasi repository juga. Sekarang kita cek `config/dev.exs`

```elixir
# Configure your database
config :learn_phoenix, LearnPhoenix.Repo,
  username: "postgres",
  password: "147789",
  hostname: "localhost",
  database: "learn_phoenix_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
...

```
Kita juga mempunyai konfigurasi yang mirip di `config/test.exs` dan `config/runtime.exs` (tadinya namanya `config/prod.secret.exs`) yang dapat juga kita ubah sesuai credential yang benar.

**Schema**
Ecto schema bertanggungjawab untuk memetakan values Elixir ke datasource luar, seperti memetakan external data kembali ke Elixir data struktur. Kita dapat juga mendefinisikan hubungan (relationship) ke schema yang laini di aplikasi kita. Sebagai contoh, schema `User` mungkin mempunya banyak posts, dan masing-masing post harus dimiliki oleh satu user. Ecto handle data validasi dan type casting dengan changesets, yang akan kita diskusikan sebentar lagi.

Di sini adalah schema `User` yang phoenix generate untuk kita:
```elixir
defmodule LearnPhoenix.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :bio, :string
    field :number_of_pets, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio, :number_of_pets])
  end
end

```
Ecto shema pada intinya adalah Elixir struct. `schema` blok kita adalah apa yang memberitahu Ecto bagaimana untuk memerankan (cast) struct field `%User{}`  dari dan ke external table `users`. Seringkali, kemampunan untuk hanya cast data ke dan dari database tidak cukup dan diperlukan validasi data tambahan. Di sinilah peran dari Ecto changeset.

**Changsets and validations**
Changeset mendefinisikan sebuah pipeline transformasi data harus dilalui oleh data kita sebelum siap digunakan oleh aplikasi kita. Transformasi ini dapat mencakup type-casting (pengecekan type), user input validation, dan menyaring parameter yang tidak relevan. Sering kali kita menggunakan changeset untuk menvalidasi user input sebelum menuliskannya ke database. Ecto repositories juga bersifat changeset-aware, yang mengijinkan mereka tidak hanya untuk menolak invalid data, tapi juga melakukan update data seminimal mungkin dengan memeriksa changeset untuk mengetahui field mana yang berubah.

Berikut adalah default changeset kita:
```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio, :number_of_pets])
  end
```
Sekarang, kita punya 2 buah transformasi di pipeline kita. Di panggilan pertama, kita memanggil `Ecto.Changeset.cast/3`, memasukkan parameter external kita dan menandai field mana yang diperlukan untuk validation.

`cast/3` pertama mengambil sebuah struct, kemudian parameter, dan kemudian field terakhir adalah list dari kolom yang perlu diupdate. `cast/3` juga hanya akan mengambil field yang ada di schema.
Kemudian, `Ecto.Changeset.validate_required/3` mengecek bahwa list field ini ada di dalam changeset yang dikembalikan oleh `cast/3`. Secara default dengan generator, semua field diperlukan (required).

Kita dapat memverifikasi function ini di `IEx`. Sekarang kita jalankan `iex -S mix`, untuk meminimalisir ngetik-ngetik, kita alias aja struct `LearnPhoenix.User`.

```elixir
iex.bat -S mix
Erlang/OTP 26 [erts-14.0.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]

Interactive Elixir (1.15.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> alias LearnPhoenix.User
LearnPhoenix.User
```
Kemudian, buat sebuah changeset dari schema kita dengan struct kosong `User`, dan sebuah empty map dari parameter.

```elixir
iex(2)> changeset = User.changeset(%User{}, %{})
#Ecto.Changeset<
  action: nil,  
  changes: %{}, 
  errors: [
    name: {"can't be blank", [validation: :required]},
    email: {"can't be blank", [validation: :required]},
    bio: {"can't be blank", [validation: :required]},
    number_of_pets: {"can't be blank", [validation: :required]}
  ],
  data: #LearnPhoenix.User<>,
  valid?: false
>
```

Setelah kita mempunyai sebuah changeset, kita dapat mengecek jika itu valid ato ndak.

```elixir
iex(3)> changeset.valid?
false
```

Karena ini tidak valid, kita dapat meminta errorsnya apa?

```elixir
iex(4)> changeset.errors
[
  name: {"can't be blank", [validation: :required]},
  email: {"can't be blank", [validation: :required]},
  bio: {"can't be blank", [validation: :required]},
  number_of_pets: {"can't be blank", [validation: :required]}
]
```

Sekarang, kita update `number_of_pets` jadi opsional. Untuk melakukan ini, kita hanya perlu menghapusnya ari list di dalam function `changeset/2`, di `LearnPhoenix.User`

```elixir
|> validate_required([:name, :email, :bio])
```

Sekarang casting changeset harus memberitahu kita hanya `name`, `email`, dan `bio` yang tidak boleh kosong. Kita dapat mengetesnya dengan menjalankan `recompile()` di dalam IEx dan kemudian rebuilding changeset kita.

```elixir
iex(5)> recompile()
Compiling 1 file (.ex)
:ok
iex(6)> changeset = User.changeset(%User{}, %{})
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [
    name: {"can't be blank", [validation: :required]},
    email: {"can't be blank", [validation: :required]},
    bio: {"can't be blank", [validation: :required]}
  ],
  data: #LearnPhoenix.User<>,
  valid?: false
>
iex(7)> changeset.errors
[
  name: {"can't be blank", [validation: :required]},
  email: {"can't be blank", [validation: :required]},
  bio: {"can't be blank", [validation: :required]}
]
```

Apa yang terjadi kalo kita memberikan key-value yang tidak didefinisikan di dalam schema atau tidak diperlukan?

Di dalam IEx shell, mari kita buat `params` map dengan valid values plus extra `random_key`:`random_value`.

```elixir
iex(9)> params = %{name: "Joe Example", email: "joe@example.com", bio: "An example to all", number_of_pets: 5, random_key: "random value"}
%{
  name: "Joe Example",
  bio: "An example to all",
  email: "joe@example.com",
  number_of_pets: 5,
  random_key: "random value"
}
```

Sekarang kita gunakan map `params` baru kita untuk membuat changeset.

```elixir
iex(10)> changeset = User.changeset(%User{}, params)
#Ecto.Changeset<
  action: nil,
  changes: %{
    name: "Joe Example",
    bio: "An example to all",
    email: "joe@example.com",
    number_of_pets: 5
  },
  errors: [],
  data: #LearnPhoenix.User<>,
  valid?: true
>
```
Ternyata changeset baru kita valid.
```elixir
iex(11)> changeset.valid?
true
```
Kita juga dapat mengecek perubahan (changes) changeset, map yang kita dapatkan setelah transformasi adalah komplit.

```elixir
iex(12)> changeset.changes
%{
  name: "Joe Example",
  bio: "An example to all",
  email: "joe@example.com",
  number_of_pets: 5
}
```

Perhatikan `random_key` dan `random_value` kita dihapus dari changeset final. Changeset mengijinkan kita untuk cast external data, seperti user input di web form, atau data dari CSV file ke valid data di sistem kita. Invalid parameter akan dihapus dan data jelek yang tidak dapat di-cast menurut schema kita akan dihightlight di changeset errors.

Kita dapat memvalidasi tidak hanya field mana yang diperlukan atau tidak. mari kita lihat beberapa validasi yang lebih halus.

Bagaimana jika kita mempunyai requirement yang semua biografi di sistem kita harus berisi paling tidak 2 karakter? Kita dapat menambahkan transformasi lainnya ke pipeline di changeset kita yang memvalidasi panjang dari `bio` field.

```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length([:bio, min: 2])
  end
```

Sekarang, kita coba untuk cast data yang berisi sebuah value `"A"` untuk `bio` users. Kita dapat melihat validasi gagal di changeset errors.

```elixir
iex(14)> recompile()
Compiling 1 file (.ex)
:ok
iex(15)> changeset = User.changeset(%User{}, %{bio: "A"})
#Ecto.Changeset<
  action: nil,
  changes: %{bio: "A"},
  errors: [
    bio: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]},
    name: {"can't be blank", [validation: :required]},
    email: {"can't be blank", [validation: :required]}
  ],
  data: #LearnPhoenix.User<>,
  valid?: false
>
iex(16)> changeset.errors
[
  bio: {"should be at least %{count} character(s)",
   [count: 2, validation: :length, kind: :min, type: :string]},
  name: {"can't be blank", [validation: :required]},
  email: {"can't be blank", [validation: :required]}
]
```

Jika kita juga mempunyai sebuah requirement untuk maximum length yang bio punyai. Kita dapat menambahkan validasi tambahan.

```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length(:bio, min: 2)
    |> validate_length(:bio, max: 140)
  end
```

Katakanlah kita mau membuat setidaknya beberapa validasi format yang belum lengkap (rudimentary) untuk field `email`. Kita ingin mengecek keberadaan `@`. Functon `Ecto.Changeset.validate_format/3` adalah yang kita butuhkan.

```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length(:bio, min: 2)
    |> validate_length(:bio, max: 140)
    |> validate_format(:email, ~r/@/)
  end
```

Jika kita coba cast sebuah user dengan sebuah email `"example.com"`, maka kita akan melihat errors seperti berikut:

```elixir
iex(17)> recompile()
Compiling 1 file (.ex)
:ok
iex(18)> changeset = User.changeset(%User{}, %{email: "example.com"})
#Ecto.Changeset<
  action: nil,
  changes: %{email: "example.com"},
  errors: [
    email: {"has invalid format", [validation: :format]},
    name: {"can't be blank", [validation: :required]},
    bio: {"can't be blank", [validation: :required]}
  ],
  data: #LearnPhoenix.User<>,
  valid?: false
>
iex(19)> changeset.errors
[
  email: {"has invalid format", [validation: :format]},
  name: {"can't be blank", [validation: :required]},
  bio: {"can't be blank", [validation: :required]}
]
```

Ada banyak lagi validasi dan transformasi yang dapat kita gunakan di dalam changeset. Cek [Ecto Changeset documentation](https://hexdocs.pm/ecto/Ecto.Changeset.html) untuk lebih jelasnya.

**Data persistence**

Kita telah mengexplore migration dan schema, tapi kita belum persisted apapun dari schema dan changesets. Kita telah melihat repository kita di `lib/learn_phoenix/repo.ex` dan sekarang adalah waktunya untuk menggunakannya.

Ecto repository adalah interface ke sistem storage, bisa sebuah database seperti PostgreSQL, atau external service lainnya seperti RESTful API. Tujuan dari module `Repo` adalah untuk mengambil detail yang lebih baik dari persistence dan data query untuk kita. Sebagai pemanggil (caller), kita hanya peduli terhadap mengambil dan persisting data. module `Repo` yang menangani komunasi adapter database yang mendasari, penyatuan koneksi (connecton pooling), dan penerjemahan kesalahan untuk pelanggaran batasan database.

Mari kembali lagi ke IEx dengan `iex -S mix` dan masukkan beberapa data users ke database.

```elixir
iex(1)> alias LearnPhoenix.{Repo, User}
[LearnPhoenix.Repo, LearnPhoenix.User]
iex(2)> Repo.insert(%User{email: "user1@example.com"})
[debug] QUERY OK source="users" db=44.7ms decode=1.9ms queue=3.5ms idle=951.6ms
INSERT INTO "users" ("email","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["user1@example.com", ~N[2023-12-15 03:18:34], ~N[2023-12-15 03:18:34]]
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
{:ok,
 %LearnPhoenix.User{
   __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
   id: 1,
   name: nil,
   email: "user1@example.com",
   bio: nil,
   number_of_pets: nil,
   inserted_at: ~N[2023-12-15 03:18:34],
   updated_at: ~N[2023-12-15 03:18:34]
 }}
 iex(3)> Repo.insert(%User{email: "user2@example.com"})
[debug] QUERY OK source="users" db=5.3ms queue=2.1ms idle=934.4ms
INSERT INTO "users" ("email","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["user2@example.com", ~N[2023-12-15 03:19:15], ~N[2023-12-15 03:19:15]]
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
{:ok,
 %LearnPhoenix.User{
   __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
   id: 2,
   name: nil,
   email: "user2@example.com",
   bio: nil,
   number_of_pets: nil,
   inserted_at: ~N[2023-12-15 03:19:15],
   updated_at: ~N[2023-12-15 03:19:15]
 }}
```

Kita mulai dengan aliasing `User` dan `Repo` module untuk easy access. Kemudian kita panggil `Repo.insert/2` dengan sebuah User struct. Karena kita di `dev` environtment, kita dapat melihat debug log untuk performance query repository kita ketika memasukkan data `%User{}`. Kita menerima sebuah 2 element tuple `{:ok, %User{}}`, yang memberitahu kita bahwa insertion berhasil.

Kita dapat juga mengisi sebuah user dengan memberikan sebuah changset ke `Repo.insert/2`. Jika changeset valid, repository akan menggunakan query database yang dioptimasi untuk mengisi data (record), dan mengembalikan sebuah 2-elemen tuple seperti di atas. Jika changeset tidak valid, kita akan menerima sebuah 2 elemen tuple berisi `:error` plus invalid changeset.

Dengan sepasang user yang dimasukkan, mari kita ambil lagi mereka dari repo.

```elixir
iex(4)> Repo.all(User)
[debug] QUERY OK source="users" db=2.1ms queue=2.3ms idle=1137.3ms
SELECT u0."id", u0."name", u0."email", u0."bio", u0."number_of_pets", u0."inserted_at", u0."updated_at" FROM "users" AS u0 []
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
[
  %LearnPhoenix.User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    id: 1,
    name: nil,
    email: "user1@example.com",
    bio: nil,
    number_of_pets: nil,
    inserted_at: ~N[2023-12-15 03:18:34],
    updated_at: ~N[2023-12-15 03:18:34]
  },
  %LearnPhoenix.User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    id: 2,
    name: nil,
    email: "user2@example.com",
    bio: nil,
    number_of_pets: nil,
    inserted_at: ~N[2023-12-15 03:19:15],
    updated_at: ~N[2023-12-15 03:19:15]
  }
]
```

Mudah bukan? `Repo.all/1` mengambil sebuah data source, `User` schema di kasus ini, dan menerjemahkannya menjadi SQL query terhadap database kita. Setelah mengambil data, Repo kemudian menggunakan Ecto schema untuk mapping database value kembali ke Elixir data struktur berdasarkan schema `User`. Kita tidak hanya membatasi basic query - Ecto menyertakan DSL query yang lengkap untuk pembuatan SQL tingkat lanjut. Selain DSL Elixir yang alami, Query engine Ecto memberikan kita fitur-fitur hebat, seperti SQL injection protection dan pengoptimalan waktu kompilasi query. Mari kita coba.

```elixir
iex(5)> import Ecto.Query
Ecto.Query
iex(6)> Repo.all(from u in User, select: u.email)
[debug] QUERY OK source="users" db=1.3ms queue=2.0ms idle=1054.9ms
SELECT u0."email" FROM "users" AS u0 []
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
["user1@example.com", "user2@example.com"]
```

Pertama kita import [`Ecto.Query`], yang mengimport macro `from/2` dari Query DSL Ecto. Kemudian kita membuat sebuah query select all email di table users kita. Mari kita coba lainnya:

```elixir
iex(8)> Repo.one(from u in User, where: ilike(u.email, "%1%"), select: count(u.id))
[debug] QUERY OK source="users" db=3.0ms queue=0.1ms idle=1250.6ms
SELECT count(u0."id") FROM "users" AS u0 WHERE (u0."email" ILIKE '%1%') []
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
1
```

Sekarang kita mulai mencicipi kemampuan querying yang kaya dari Ecto. Kita menggunakan `Repo.one/2` untuk mendapatkan jumlah dari semua users dengan email yang ada `1`nya. dan menerima jumlah yang diinginkan di kembaliannya (return). Ini hanyalah goresan di permukaan query interface Ecto, dan banyak lagi yang disupport seperti sub-querying, interval queries, dan advanced select statements. Sebagai contoh, kita buat seubh query untuk mengambil sebuah map dari semua user id terhadap emailnya.

```elixir
iex(9)> Repo.all(from u in User, select: %{u.id => u.email})
[debug] QUERY OK source="users" db=1.3ms queue=1.6ms idle=1613.4ms
SELECT u0."id", u0."email" FROM "users" AS u0 []
↳ anonymous fn/4 in :elixir.eval_external_handler/1, at: src/elixir.erl:376
[%{1 => "user1@example.com"}, %{2 => "user2@example.com"}]
```

Itu query yang sedikit memberi hasil yang besar. Query ini mengambil semua email dari database dan secara efisien membuat map dari hasil dalam sekali jalan. Buka [Ecto.Query](https://hexdocs.pm/ecto/Ecto.Query.html#content) utnuk melihat luasnya fitur query yang didukung.

Sebagai tambahan untuk insert, kita dapat juga melakukan updates dan deletes dengan `Repo.update/2` dan `Repo.delete/2` untuk update dan delete sebuah schema. Ecto juga mendukung bulk persistence dengan `Repo.insert_all/3`, `Repo.update_all/3`, dan `Repo.delete_all/3`.

Ada banyak lagi yagn Ecto dapat lakukan, dan kita hanya baru permukaannya aja. Dengan fondasi Ecto, kita dapat siap untuk lanjut membuat app kita dan integrasikan web-facing application dengan persistence backend. Selanjutnya kita akan memperluas pengetahuan tentang Ecto dan mempelajari cara mengisolasi antarmuka web kita dari detail yang mendasari sistem kita. Buka [Ecto documentasi](https://hexdocs.pm/ecto/) untuk lebih jelasnya.

Di [context guide](https://hexdocs.pm/phoenix/contexts.html), kita akan menemukan bagaimana membungkus Ecto access dan bisnis logic dibalik module yang mengelompokkan functionality yang terhubung. Kita akan melihat bagaimana Phoenix membantu kita membangun aplikasi yang maintainable dan kita dapat tahu bagaimana Fitur Ecto yang lainnya.

**Using MySQL**
Karena bawaannya adalah PostgreSQL, maka kalau kita mau menggunakan mysql kita dapat menambahkan flag `--database mysql` ke `phx.new` dan semua akan dikonfigurasi dengan benar.

```elixir
mix phx.new hello_phoenix --database mysql

```

Untuk pindah dari PostgreSQL ke MySQL, kita perlu menghapus Postgrex dependency dan menambahkan Myxql.

Buka file `mix.exs` dan update seperti berikut:

```elixir
defmodule LearnPhoenix.MixProject do
  use Mix.Project

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:myxql, ">= 0.0.0"},
      ...
    ]
  end
end
```

Kemudian update `config/dev.exs`:
```elixir
config :learn_phoenix, LearnPhoenix.Repo,
username: "root",
password: "",
database: "learn_phoenix_dev"
```

Jika kita sudah mempunyai blok konfigurasi yang udah ada untuk `LearnPhoenix.Repo`, kita dapat mengubah nilainya untuk mencocokkan dengan yang baru. Begitu juga di `config/test.exs` dan `config/runtime.exs` (tadinya namanya `config/prod.secret.exs`)

Yang terakhir update `lib/learn_phoenix/repo.ex` dan pastikan `:adapter` ke `Ecto.Adapters.MyXQL`

Sekarang kita bisa jalankan command ini untuk dependency baru kita.

```elixir
mix deps.get

```

Dan create database dengan command:

```elixir
mix ecto.create

```

Dan terakhir jangan lupa migrate migration yang ada.

```elixir
mix ecto.migrate
```

**Other options**
Ketika phoenix menggunakan `ecto` untuk berinteraksi dengan data access layer, ada banyak lagi data access options, beberapa bahkan bawaan dari Erlang standart library. [ETS](https://www.erlang.org/doc/man/ets.html) - available di Ecto via `etso` - dan [DETS](https://www.erlang.org/doc/man/dets.html) adalah key-value data store yang dibangun di atas [OTP](https://www.erlang.org/doc/). OTP juga menyediakan sebuah relational database dengan nama [Mnesia](https://www.erlang.org/doc/man/mnesia.html) dengan bahasa querynya sendiri dengan nama QLC. Berdua Elixir dan Erlang juga mempunya sejumlah library untuk bekerja dengan banyak data store terkenal.

The data world is your oyster, but we won't be covering these options in these guides

