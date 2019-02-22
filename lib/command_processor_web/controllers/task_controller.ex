defmodule CommandProcessorWeb.TaskController do
  use CommandProcessorWeb, :controller
  alias CommandProcessor.Task

  @doc """
  Receive an array of tasks under the "tasks" key
  """
  def receive_tasks(conn, %{"format" => format, "tasks" => tasks})
      when format in ["json", "script"] and is_list(tasks) do
    with {:ok, sanitized_tasks} <- Task.sanitize_tasks(tasks),
         {:ok, sorted_tasks} <- Task.sort_tasks(sanitized_tasks) do
      case format do
        "json" ->
          json_output = Task.prepare_json_output(sorted_tasks)

          conn
          |> json(json_output)

        "script" ->
          script_output = Task.prepare_script_output(sorted_tasks)

          conn
          |> text(script_output)
      end
    else
      _ ->
        conn
        |> resp(
          400,
          "Bad request. Please check the JSON is well-formatted, there are no duplicate keys, and there isn't any cycle in the task dependencies."
        )
    end
  end

  def receive_tasks(conn, _) do
    conn
    |> resp(
      400,
      "Bad request. Please post a JSON with a key \"tasks\" containing an array of tasks, to the endpoint /api/sort_tasks/json or /api/sort_tasks/script"
    )
  end
end
