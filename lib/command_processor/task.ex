defmodule CommandProcessor.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field(:name, :string)
    field(:command, :string)
    field(:requires, {:array, :string})
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :command, :requires])
    |> validate_required([:name, :command])
  end
end
