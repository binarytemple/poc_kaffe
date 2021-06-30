defmodule PocKaffe do
end

defmodule PocKaffe.Application do
  use Application

  def start(_type, args) do
    import Supervisor.Spec

    children = [
      worker(Kaffe.Consumer, [])
    ]

    opts = [strategy: :one_for_one, name: PocKaffe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule PocKaffe.ExampleConsumer do
  def handle_message(%{key: key, value: value} = message) do
    IO.inspect(message)
    IO.puts("#{key}: #{value}")
    :ok
  end
end
