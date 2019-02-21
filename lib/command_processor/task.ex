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

  @doc """
  Sanitize and transform a list of tasks into a list of %Task structs.
  """
  def sanitize_tasks(tasks) when is_list(tasks) do
    tasks =
      tasks
      |> Enum.map(&sanitize_task(&1))

    all_valid =
      Enum.reduce_while(tasks, true, fn t, acc ->
        case t do
          {:error, _} -> {:halt, false}
          _ -> {:cont, acc}
        end
      end)

    if all_valid do
      # Get each task out of the {:ok, task} tuple.
      {:ok, Enum.map(tasks, fn {:ok, task} -> task end)}
    else
      # Better stop the procedure if any input is invalid, instead of producing an incomplete (and potentially surprising) set of commands to the user.
      :error
    end
  end

  # If it's not a list then just return :error
  def sanitize_tasks(_) do
    :error
  end

  defp sanitize_task(task) do
    %CommandProcessor.Task{}
    |> CommandProcessor.Task.changeset(task)
    |> Ecto.Changeset.apply_action(:insert)
  end
end
