defmodule CommandProcessorWeb.TaskControllerTest do
  use CommandProcessorWeb.ConnCase

  test "receive_tasks/2 produces the expected JSON response to valid tasks", %{conn: conn} do
    input =
      "test/fixtures/valid_tasks.json"
      |> File.read!()
      |> Jason.decode!()

    expected_response =
      "test/fixtures/valid_tasks_response.json"
      |> File.read!()
      |> Jason.decode!()

    conn = post(conn, "/api/sort_tasks/json", input)
    assert json_response(conn, 200) == expected_response
  end

  test "receive_tasks/2 produces the expected script response to valid tasks", %{conn: conn} do
    input =
      "test/fixtures/valid_tasks.json"
      |> File.read!()
      |> Jason.decode!()

    expected_response =
      "test/fixtures/valid_tasks_response.sh"
      |> File.read!()

    conn = post(conn, "/api/sort_tasks/script", input)
    assert text_response(conn, 200) == expected_response
  end

  test "receive_tasks/2 produces the expected script response to tasks with special characters",
       %{conn: conn} do
    input =
      "test/fixtures/tasks_with_special_chars.json"
      |> File.read!()
      |> Jason.decode!()

    expected_response =
      "test/fixtures/tasks_with_special_chars_response.sh"
      |> File.read!()

    conn = post(conn, "/api/sort_tasks/script", input)
    assert text_response(conn, 200) == expected_response
  end

  test "receive_tasks/2 responds with 400 to inputs with duplicate names", %{conn: conn} do
    input =
      "test/fixtures/tasks_with_duplicate_names.json"
      |> File.read!()
      |> Jason.decode!()

    conn = post(conn, "/api/sort_tasks/json", input)
    assert(response(conn, 400))

    conn = post(conn, "/api/sort_tasks/script", input)
    assert(response(conn, 400))
  end

  test "receive_tasks/2 responds with 400 to inputs with the wrong key", %{conn: conn} do
    input =
      "test/fixtures/malformed_tasks_1.json"
      |> File.read!()
      |> Jason.decode!()

    conn = post(conn, "/api/sort_tasks/json", input)
    assert(response(conn, 400))

    conn = post(conn, "/api/sort_tasks/script", input)
    assert(response(conn, 400))
  end

  test "receive_tasks/2 responds with 400 to inputs lacking \"test\" key", %{conn: conn} do
    input =
      "test/fixtures/malformed_tasks_2.json"
      |> File.read!()
      |> Jason.decode!()

    conn = post(conn, "/api/sort_tasks/json", %{"_json" => input})
    assert(response(conn, 400))

    conn = post(conn, "/api/sort_tasks/script", %{"_json" => input})
    assert(response(conn, 400))
  end

  test "receive_tasks/2 responds with 400 to requests to the wrong endpoint", %{conn: conn} do
    input =
      "test/fixtures/valid_tasks.json"
      |> File.read!()
      |> Jason.decode!()

    conn = post(conn, "/api/sort_tasks/wrong_endpoint", input)
    assert(response(conn, 400))
  end
end
