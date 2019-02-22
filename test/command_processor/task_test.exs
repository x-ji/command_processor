defmodule CommandProcessor.TaskTest do
  use ExUnit.Case, async: true
  alias CommandProcessor.Task

  @valid_task_attrs %{
    "name" => "task-4",
    "command" => "rm /tmp/file1",
    "requires" => [
      "task-2",
      "task-3"
    ]
  }

  @invalid_task_attrs %{}

  @valid_tasks [
    %{
      "name" => "task-1",
      "command" => "touch /tmp/file1"
    },
    %{
      "name" => "task-2",
      "command" => "cat /tmp/file1",
      "requires" => [
        "task-3"
      ]
    },
    %{
      "name" => "task-3",
      "command" => "echo 'Hello World!' > /tmp/file1",
      "requires" => [
        "task-1"
      ]
    },
    %{
      "name" => "task-4",
      "command" => "rm /tmp/file1",
      "requires" => [
        "task-2",
        "task-3"
      ]
    }
  ]

  @invalid_tasks [
    %{
      "name" => "task-1",
      "command" => "touch /tmp/file1"
    },
    %{
      "name" => 1234,
      "command" => "cat /tmp/file1",
      "requires" => [
        "task-3"
      ]
    }
  ]

  @sanitized_valid_tasks [
    %Task{
      name: "task-1",
      command: "touch /tmp/file1"
    },
    %Task{
      name: "task-2",
      command: "cat /tmp/file1",
      requires: [
        "task-3"
      ]
    },
    %Task{
      name: "task-3",
      command: "echo 'Hello World!' > /tmp/file1",
      requires: [
        "task-1"
      ]
    },
    %Task{
      name: "task-4",
      command: "rm /tmp/file1",
      requires: [
        "task-2",
        "task-3"
      ]
    }
  ]

  @tasks_with_cyclic_dependencies [
    %Task{
      name: "task-1",
      command: "touch /tmp/file1",
      requires: [
        "task-3"
      ]
    },
    %Task{
      name: "task-2",
      command: "cat /tmp/file1",
      requires: [
        "task-1"
      ]
    },
    %Task{
      name: "task-3",
      command: "echo 'Hello World!' > /tmp/file1",
      requires: [
        "task-2"
      ]
    }
  ]

  @single_task [
    %Task{
      name: "task-1",
      command: "touch /tmp/file1"
    }
  ]

  @tasks_with_independent_vertices [
    %Task{
      name: "task-1",
      command: "touch /tmp/file1"
    },
    %Task{
      name: "task-2",
      command: "cat /tmp/file1"
    },
    %Task{
      name: "task-3",
      command: "echo 'Hello World!' > /tmp/file1",
      requires: [
        "task-2"
      ]
    }
  ]

  describe "changeset/2" do
    test "changeset/2 with valid attributes" do
      changeset = Task.changeset(%Task{}, @valid_task_attrs)
      assert changeset.valid?
    end

    test "changeset/2 with invalid attributes" do
      changeset = Task.changeset(%Task{}, @invalid_task_attrs)
      refute changeset.valid?
    end

    test ":name is required" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_task_attrs, "name"))
      refute changeset.valid?
    end

    test ":command is required" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_task_attrs, "command"))
      refute changeset.valid?
    end

    test ":requires is optional" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_task_attrs, :requires))
      assert changeset.valid?
    end
  end

  describe "sanitize_tasks/1" do
    test "sanitize_tasks/1 produces list of sanitized tasks on valid list of task inputs" do
      assert Task.sanitize_tasks(@valid_tasks) == {:ok, @sanitized_valid_tasks}
    end

    test "sanitize_tasks/1 produces :error on a list which contains invalid tasks" do
      assert Task.sanitize_tasks(@invalid_tasks) == :error
    end

    test "sanitize_tasks/1 produces :error on non-list input" do
      assert Task.sanitize_tasks("notalist") == :error
    end
  end

  describe "sort_tasks/1" do
    test "sort_tasks/1 produces [] for []" do
      assert Task.sort_tasks([]) == {:ok, []}
    end

    test "sort_tasks/1 produces the correct order for a single task" do
      assert Task.sort_tasks(@single_task) == {:ok, ["task-1"]}
    end

    test "sort_tasks/1 produces the correct order of tasks when the dependencies are acyclic" do
      assert Task.sort_tasks(@sanitized_valid_tasks) ==
               {:ok, ["task-1", "task-3", "task-2", "task-4"]}
    end

    test "sort_tasks/1 produces :error when a cyclic graph occurs" do
      assert Task.sort_tasks(@tasks_with_cyclic_dependencies) == :error
    end

    test "sort_tasks/1 produces the correct order of tasks when there are independent tasks" do
      assert Task.sort_tasks(@tasks_with_independent_vertices) ==
               {:ok, ["task-2", "task-3", "task-1"]}
    end
  end
end
