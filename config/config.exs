import Config

config :kaffe,
  consumer: [
    endpoints: [localhost: 9092],
    topics: ["topic1"],
    consumer_group: "group1",
    message_handler: PocKaffe.ExampleConsumer,
    async_message_ack: true
  ]
