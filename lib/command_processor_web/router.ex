defmodule CommandProcessorWeb.Router do
  use CommandProcessorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CommandProcessorWeb do
    pipe_through :api
    post "/sort_tasks/:format", TaskController, :receive_tasks
  end
end
