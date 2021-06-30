import Config

config :kaffe,
  consumer: [
    endpoints: [localhost: 9092],
    topics: ["topic1"],
    # the consumer group for tracking offsets in Kafka
    consumer_group: "group1",
    message_handler: ExampleConsumer
  ]
