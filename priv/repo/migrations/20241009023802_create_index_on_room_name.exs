defmodule Slax.Repo.Migrations.CreateIndexOnRoomName do
  use Ecto.Migration

  def change do
    create unique_index(:rooms, :name)
  end
end
