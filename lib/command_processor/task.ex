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

    # We check for two things here:
    # First is whether there is any error discovered by Ecto.Changeset
    # Second is whether the name of the task is repeated within the input list, in which case the list is probably ill-defined (which task should we exactly execute?)
    # This can also be written in two separate functions, though that would probably require two passes over the tasks, which could be less efficient.
    valid_tasks =
      Enum.reduce_while(tasks, {true, MapSet.new()}, fn result, {valid, set_of_names} ->
        case result do
          {:error, _} ->
            {:halt, {false, set_of_names}}

          {:ok, task} ->
            case MapSet.member?(set_of_names, task.name) do
              true -> {:halt, {false, set_of_names}}
              false -> {:cont, {valid, MapSet.put(set_of_names, task.name)}}
            end
        end
      end)

    # The first element is the bool. The second element is the accumulator.
    valid_tasks = Kernel.elem(valid_tasks, 0)

    if valid_tasks do
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

  @doc """
  Sort the tasks according to the dependency/requirement order.
  """
  def sort_tasks(tasks) do
    case produce_task_order(tasks) do
      :error ->
        :error

      {:ok, order} ->
        tasks_with_names =
          Enum.reduce(tasks, %{}, fn task, acc ->
            Map.put(acc, task.name, task)
          end)

        sorted_tasks =
          Enum.map(order, fn name ->
            tasks_with_names[name]
          end)

        {:ok, sorted_tasks}
    end
  end

  @doc """
  Produces the order of the tasks in terms of their names, e.g. ["task-1", "task-3", "task-2", "task-4"]
  """
  defp produce_task_order(tasks) do
    graph =
      Enum.reduce(tasks, Graph.new(), fn task, g ->
        # First ensure that every task is added, since some tasks might not have requirements/edges whatsoever.
        g = Graph.add_vertex(g, task.name)

        if task.requires != nil do
          add_edges_from_task(g, task)
        else
          g
        end
      end)

    # If `Graph.topsort(g)` returns false, there is no topological ordering for the graph. Which task to execute first? Most likely the user made an error.
    sorted = Graph.topsort(graph)

    # This function returns `false` when there is no ordering, though IMO it should really have been :error. Dialyzer complains but there's nothing I can do about it.
    if sorted == false do
      :error
    else
      {:ok, sorted}
    end
  end

  defp add_edges_from_task(g, task) do
    self = task.name

    Enum.reduce(task.requires, g, fn parent, graph ->
      Graph.add_edge(graph, parent, self)
    end)
  end

  def prepare_json_output(sorted_tasks) do
    sorted_tasks
    |> Enum.map(fn task_struct ->
      %{"name" => task_struct.name, "command" => task_struct.command}
    end)
  end

  def prepare_script_output(sorted_tasks) do
    sorted_tasks
    |> Enum.reduce("#!/usr/bin/env bash\n\n", fn task, acc ->
      acc <> task.command <> "\n"
    end)
  end
end
