defmodule CommandProcessorWeb.Router do
  use CommandProcessorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CommandProcessorWeb do
    pipe_through :api
  end
end
