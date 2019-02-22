<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->

**Table of Contents**

- [CommandProcessor](#commandprocessor)
  - [Installation, Configuration and Usage Instructions](#installation-configuration-and-usage-instructions)
  - [Description](#description)
  - [Discussion](#discussion)
  - [Potential Improvements](#potential-improvements)

<!-- markdown-toc end -->

# CommandProcessor

This app was tested on Arch Linux with Elixir 1.8.0, Phoenix 1.4.0

## Installation, Configuration and Usage Instructions

To run the app under `:dev` environment:

1. Clone the repo
2. `mix deps.get`
3. `mix deps.compile`
4. `mix phx.server`

Use `mix test` to run the tests.

To get the output as JSON, perform a HTTP POST request to the endpoint `/api/sort_tasks/json`, e.g.:

```
$ curl -H "Content-Type: application/json" -d @test/fixtures/valid_tasks.json http://localhost:4000/api/sort_tasks/json

  [{"command":"touch /tmp/file1","name":"task-1"},{"command":"echo 'Hello World!' > /tmp/file1","name":"task-3"},{"command":"cat /tmp/file1","name":"task-2"},{"command":"rm /tmp/file1","name":"task-4"}]
```

To get the output as a bash script, perform a HTTP POST request to the endpoint `/api/sort_tasks/script`, e.g.:

```
$ curl -H "Content-Type: application/json" -d @test/fixtures/valid_tasks.json http://localhost:4000/api/sort_tasks/script | bash

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed
  100   500  100   100  100   400  11111  44444 --:--:-- --:--:-- --:--:-- 55555
  Hello World!
```

The two endpoints accept the same type of input. They only differ by their output formats.

## Description

The main functionalities of the app are in the two modules: `CommandProcessor.Task`(`lib/command_processor/task.ex`) and `lib/command_processor_web/controllers/task_controller.ex`.

- The `CommandProcessor.Task` module takes care of everything related to input data sanitization and transformation.

  - A struct `%Task` is defined via `Ecto.Schema`. Incoming data is validated via `Ecto.Changeset` for any errors or duplicate task names.
  - The library [libgraph](https://hex.pm/packages/libgraph) is used to form a graph from the task dependencies. A _required_ task will have an edge pointing to a task that requires it. After all tasks have been processed, a topological sort is performed to ensure that the order is correct.
    - If a cycle is detected (i.e. no topological ordering possible), an `:error` atom will be produced.
    - There is no ordering guarantee in the final output for tasks that don't have any outgoing or incoming edges. This should be fine since those independent tasks should be able to executed either before or after any other task.

- The `CommandProcessor.TaskController` module is responsible for interfacing with the outside request.
  - It accepts the JSON input and ask `CommandProcessor.Task` module to process it.
    - If any error occurred, it will return a `400` status code.
    - If the output is successfully produced, it will encode and return the output in the appropriate format.

## Discussion

- I still used the Phoenix bootstraper, but with the `--no-html`, `--no-webpack` and `--no-ecto` flags. Phoenix provides an `:api` pipeline by default, which makes my job a bit easier.

- I added a plug for CORS, even though it isn't necessarily needed for the current setup.

- In the description, the originally single-quoted `'Hello World'` became double-quoted in the output. However, as [single quotes and double quotes have different meanings in shell scripts](https://stackoverflow.com/questions/6697753/difference-between-single-and-double-quotes-in-bash), I chose to preserve the original quoting of the incoming JSON file. If the user wants double quotes, they'd need to specify it as `\"` in the JSON file.

- In the description, the shell command is `curl -d @mytasks.json http://localhost:4000/...`. However, [curl sends the data as `application/x-www-form-urlencoded` by default](https://stackoverflow.com/questions/7172784/how-to-post-json-data-with-curl-from-terminal-commandline-to-test-spring-rest). Therefore, I added `-H "Content-Type: application/json"` for such `curl` commands.

## Potential Improvements

- Phoenix might be a bit overblown for an API project and [Maru](https://github.com/elixir-maru/maru) could be an interesting alternative, or even just create a plain Mix project. It's just that I'm still most familiar with Phoenix's default routing structure.

- If the requirement for output format gets more complicated, it might make sense to extract the functions for generating the JSON output and the bash script into their own `TaskView` module.

- The task description also mentions "deployment strategy" though I haven't had time to focus on that. I just added distillery as a dependency and I was able to produce and run releases successfully. Improvements would include further containerizing the app for Docker and Kubernetes.

- After I started, I realized that `Task` might not be a very good module name since there is also a built-in `Task` module already. Our module is prefixed by `CommandProcessor.`, but it might still have been better to use a different name.

- Normally in Phoenix, most functions would live in a context module instead of the `CommandProcessor.Task` module itself. That also makes the code more modular and clearer. It's just that in this task there is only one data type to deal with, so I just put all the functions within the same module.

- There could always be more edge cases for incoming data and especially for command line commands. I covered some error cases with my tests, though in a production app one might want to add even more tests. Property-based testing might also help.
