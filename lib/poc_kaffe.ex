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

  def handle_message(pid, %{key: key, value: value} = message) do
    IO.puts("handling message..")
    IO.inspect(message)
    IO.puts("#{key}: #{value}")
    # this can be anywhere in the system...
    # we could for example spawn a process or call to a pool of processes
    # in this example we ack then return :ok (blocking pattern)
    Kaffe.Consumer.ack(pid, message)
    :ok
  end
end
