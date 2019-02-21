defmodule CommandProcessor.TaskTest do
  use ExUnit.Case, async: true
  alias CommandProcessor.Task

  @valid_attrs %{
    "name" => "task-4",
    "command" => "rm /tmp/file1",
    "requires" => [
      "task-2",
      "task-3"
    ]
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "changeset/2 with valid attributes" do
      changeset = Task.changeset(%Task{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset/2 with invalid attributes" do
      changeset = Task.changeset(%Task{}, @invalid_attrs)
      refute changeset.valid?
    end

    test ":name is required" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_attrs, "name"))
      refute changeset.valid?
    end

    test ":command is required" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_attrs, "command"))
      refute changeset.valid?
    end

    test ":requires is optional" do
      changeset = Task.changeset(%Task{}, Map.delete(@valid_attrs, :requires))
      assert changeset.valid?
    end
  end
end
