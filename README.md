# PocKaffe


## Startup 

```
docker run -d --pull=always --name=redpanda-1 --rm \
-p 9092:9092 \
docker.vectorized.io/vectorized/redpanda:latest \
redpanda start \
--overprovisioned \
--smp 1  \
--memory 1G \
--reserve-memory 0M \
--node-id 0 \
--check=false
```

% docker exec -ti redpanda-1 rpk topic create -p 3 topic1

% docker exec -ti redpanda-1 rpk topic describe topic1    
  Name                topic1  
  Internal            false   
  Cleanup policy      delete  
  Config:             
  Name                Value   Read-only  Sensitive  
  partition_count     3       false      false      
  replication_factor  1       false      false      
  cleanup.policy      delete  false      false      
  Partitions          1 - 3 out of 3  
  Partition           Leader          Replicas   In-Sync Replicas  High Watermark  
  0                   0               [0]        [0]               0               
  1                   0               [0]        [0]               0               
  2                   0               [0]        [0]               0               



% docker exec -ti redpanda-1 rpk topic --brokers 127.0.0.1:9092 produce -k key1 topic1
Reading message... Press CTRL + D to send, CTRL + C to cancel.
test
Sent record to partition 2 at offset 0 with timestamp 2021-06-30 10:43:49.4754046 +0000 UTC m=+4.312555001.



% docker exec -ti redpanda-1 rpk topic describe topic1                                
  Name                topic1  
  Internal            false   
  Cleanup policy      delete  
  Config:             
  Name                Value   Read-only  Sensitive  
  partition_count     3       false      false      
  replication_factor  1       false      false      
  cleanup.policy      delete  false      false      
  Partitions          1 - 3 out of 3  
  Partition           Leader          Replicas   In-Sync Replicas  High Watermark  
  0                   0               [0]        [0]               0               
  1                   0               [0]        [0]               0               
  2                   0               [0]        [0]               1               



% docker exec -ti redpanda-1 rpk topic --brokers 127.0.0.1:9092 produce -k key1 topic1
Reading message... Press CTRL + D to send, CTRL + C to cancel.
test2
Sent record to partition 2 at offset 1 with timestamp 2021-06-30 10:44:34.2349549 +0000 UTC m=+3.500834201.


% docker exec -ti redpanda-1 rpk topic describe topic1                                
  Name                topic1  
  Internal            false   
  Cleanup policy      delete  
  Config:             
  Name                Value   Read-only  Sensitive  
  partition_count     3       false      false      
  replication_factor  1       false      false      
  cleanup.policy      delete  false      false      
  Partitions          1 - 3 out of 3  
  Partition           Leader          Replicas   In-Sync Replicas  High Watermark  
  0                   0               [0]        [0]               0               
  1                   0               [0]        [0]               0               
  2                   0               [0]        [0]               2               

Two messages on partition 2, so long as we keep producing messages with key = key1 (murmur hashes to partition 2), that partition will be the only one with messages


Lets try consuming, while specifying a consumer group  

% docker exec -ti redpanda-1 rpk topic consume -g group --brokers 127.0.0.1:9092 topic1 

{
 "key": "key1",
 "message": "test\n",
 "partition": 2,
 "offset": 0,
 "timestamp": "2021-06-30T10:43:49.475Z"
}
{
 "key": "key1",
 "message": "test2\n",
 "partition": 2,
 "offset": 1,
 "timestamp": "2021-06-30T10:44:34.234Z"
}


Specify a different group id, receive the same data again: 


% docker exec -ti redpanda-1 rpk topic consume -g group2 --brokers 127.0.0.1:9092 topic1 
{
 "key": "key1",
 "message": "test\n",
 "partition": 2,
 "offset": 0,
 "timestamp": "2021-06-30T10:43:49.475Z"
}
{
 "key": "key1",
 "message": "test2\n",
 "partition": 2,
 "offset": 1,
 "timestamp": "2021-06-30T10:44:34.234Z"
}


List the offsets, only works while consumer is active :

```
% docker exec -ti redpanda-1 rpk  cluster offsets                                        
  GROUP   TOPIC   PARTITION  LAG  LAG %  COMMITTED  LATEST  CONSUMER                                  CLIENT-HOST  CLIENT-ID  
  group2  topic1  0          -    -      -          0       rpk-be630db0-a7d8-47d0-a090-3ca6044c00a6  127.0.0.1    rpk        
  group2  topic1  1          -    -      -          0       rpk-be630db0-a7d8-47d0-a090-3ca6044c00a6  127.0.0.1    rpk        
  group2  topic1  2          -    -      -          2       rpk-be630db0-a7d8-47d0-a090-3ca6044c00a6  127.0.0.1    rpk      
```

On to the Elixir application 

https://elixirschool.com/blog/elixir-kaffe-codealong/




-----

### General notes



Very good overview of Kafka Topic/Partition relationship and the underlying mechanism. Touches upon the 
guaranteed message ordering per Partiton but not by Topic.
https://medium.com/@durgaswaroop/a-practical-introduction-to-kafka-storage-internals-d5b544f6925f
This post goes into more detail about effective Topic partitioning 
https://newrelic.com/blog/best-practices/effective-strategies-kafka-topic-partitioning
This stackoverflow post goes into detail about the benefits of sending messages to specific Partition based upon message key (examples in Java)
https://stackoverflow.com/a/64099991
We can ensure related messages are sent to the same Topic by specifying a message key in the producer
C# API (Message) provides the means to specify the Message ID 
https://github.com/mhowlett/confluent-kafka-dotnet/blob/6b6efb985317e02923fcd0066be1e1f3a61b9082/src/Confluent.Kafka/Message.cs#L37
The Message ID, as mentioned earlier, is used by the Broker, to assign messages to partitions. 
Looks like SyXServices/SyXServices/UOFData/Repository/KafkaProducer.cs is setup to produce messages with an Id specified into Kafka broker.
https://github.com/bet01/SyXServices/blob/6aee30dfe669ad9f7efea14dcdeee6f4d4cc4db3/SyXServices/UOFData/Repository/KafkaProducer.cs#L63-L64
And when invoking KafkaProducer, we are doing so while specifying a message id 
https://github.com/bet01/SyXServices/blob/baa5087b6ae7691add3e1d79415538d2bf69619f/SyXServices/UOFProducerService/Worker.cs#L510-L528
If we used a mechanism whereby we incremented the message id (and maintained state of message id generator) in SyXServices that would not work because the messages would be sent to different partitions for every message. 
Kaffe imports the message record definition from brod 
https://github.com/spreedly/kaffe/blob/6d7b860670a612fe754c7ce88e37925103360434/lib/kaffe/consumer.ex#L23
which is kpro:message (kpro is the protocol definition layer) 
https://github.com/kafka4beam/brod/blob/b243263678f07cf92aff12dd66855107a8255f29/src/brod.erl#L209
           , {kafka_protocol, "https://github.com/kafka4beam/kafka_protocol.git"}
https://github.com/kafka4beam/kafka_protocol/blob/293551fb6c1a2d0a6e06a19691eb60e96c75a5f5/src/kpro.erl#L184
-type message() :: #kafka_message{}.
.... one more jump hopefully.... 
and finally ... 
-record(kafka_message,
        { offset :: kpro:offset()
        , key :: kpro:bytes()
        , value :: kpro:bytes()
        , ts_type :: undefined %% magic 0
                   | kpro:timestamp_type()  %% since magic 1
        , ts :: undefined %% magic 0
              | kpro:int64() %% since magic 1
        , headers = [] :: kpro:headers() %% since magic 2
        }).
https://github.com/kafka4beam/kafka_protocol/blob/293551fb6c1a2d0a6e06a19691eb60e96c75a5f5/include/kpro_public.hrl#L18-L27
So... we have a key which can be unique per event -> which we can use to ensure that all messages relating to an event are ordered with a monotonically incrementing 'ts' 


----

Boot the elixir application and try to get it to consume messages... 

% docker exec -ti redpanda-1 rpk topic --brokers 127.0.0.1:9092 produce -k key1 topic1
Reading message... Press CTRL + D to send, CTRL + C to cancel.
a test message Sent record to partition 2 at offset 2 with timestamp 2021-06-30 11:08:32.0117013 +0000 UTC m=+10.576630401.


```

12:08:32.593 [error] GenServer #PID<0.281.0> terminating
** (UndefinedFunctionError) function ExampleConsumer.handle_message/1 is undefined (module ExampleConsumer is not available)
    ExampleConsumer.handle_message(%{headers: [], key: "key1", offset: 2, partition: 2, topic: "topic1", ts: 1625051312011, ts_type: :create, value: "a test message "})
    (kaffe 1.20.0) lib/kaffe/consumer.ex:133: Kaffe.Consumer.handle_message/4
    (brod 3.15.6) /Users/b/repos/bryanhuntesl/poc_kaffe/deps/brod/src/brod_group_subscriber.erl:530: :brod_group_subscriber.handle_messages/4
    (brod 3.15.6) /Users/b/repos/bryanhuntesl/poc_kaffe/deps/brod/src/brod_group_subscriber.erl:323: :brod_group_subscriber.handle_info/2
    (stdlib 3.15) gen_server.erl:695: :gen_server.try_dispatch/4
    (stdlib 3.15) gen_server.erl:771: :gen_server.handle_msg/6
    (stdlib 3.15) proc_lib.erl:226: :proc_lib.init_p_do_apply/3
Last message: {#PID<0.255.0>, {:kafka_message_set, "topic1", 2, 3, [{:kafka_message, 2, "key1", "a test message ", :create, 1625051312011, []}]}}
State: {:state, :group1, #Reference<0.3222208718.2129657864.7791>, "group1", "nonode@nohost/<0.282.0>-4d0d29bd-ebf7-464d-91f2-7e0647e2ef66", 7, #PID<0.282.0>, [{:consumer, {"topic1", 0}, #PID<0.253.0>, #Reference<0.3222208718.2129657864.7813>, :undefined, :undefined, :undefined}, {:consumer, {"topic1", 1}, #PID<0.254.0>, #Reference<0.3222208718.2129657864.7815>, :undefined, :undefined, :undefined}, {:consumer, {"topic1", 2}, #PID<0.255.0>, #Reference<0.3222208718.2129657866.10598>, :undefined, :undefined, :undefined}], [auto_start_producers: false, allow_topic_auto_creation: false, begin_offset: -1], false, #Reference<0.3222208718.2129657866.10599>, Kaffe.Consumer, %Kaffe.Consumer.State{async: false, message_handler: ExampleConsumer}, :message}

12:08:32.593 [info]  Group member (group1,coor=#PID<0.282.0>,cb=#PID<0.281.0>,generation=7):
Leaving group, reason: {:undef,
 [
   {ExampleConsumer, :handle_message,
    [
      %{
        headers: [],
        key: "key1",
        offset: 2,
        partition: 2,
        topic: "topic1",
        ts: 1625051312011,
        ts_type: :create,
        value: "a test message "
      }
    ], []},
   {Kaffe.Consumer, :handle_message, 4,
    [file: 'lib/kaffe/consumer.ex', line: 133]},
   {:brod_group_subscriber, :handle_messages, 4,
    [
      file: '/Users/b/repos/bryanhuntesl/poc_kaffe/deps/brod/src/brod_group_subscriber.erl',
      line: 530
    ]},
   {:brod_group_subscriber, :handle_info, 2,
    [
      file: '/Users/b/repos/bryanhuntesl/poc_kaffe/deps/brod/src/brod_group_subscriber.erl',
      line: 323
    ]},
   {:gen_server, :try_dispatch, 4, [file: 'gen_server.erl', line: 695]},
   {:gen_server, :handle_msg, 6, [file: 'gen_server.erl', line: 771]},
   {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 226]}
 ]}


12:08:32.595 [info]  Application poc_kaffe exited: shutdown
```

Stupid misconfiguration on my part, correct the consumer name and try again... 

```
% docker exec -ti redpanda-1 rpk topic --brokers 127.0.0.1:9092 produce -k key1 topic1
Reading message... Press CTRL + D to send, CTRL + C to cancel.
test
Sent record to partition 2 at offset 3 with timestamp 2021-06-30 11:11:05.3301008 +0000 UTC m=+4.908713201.
```

results in ...

```
iex(3)> %{
  headers: [],
  key: "key1",
  offset: 3,
  partition: 2,
  topic: "topic1",
  ts: 1625051465330,
  ts_type: :create,
  value: "test\n"
}
key1: test
```

So.. lets produce and consume another message... 

```
%{
  headers: [],
  key: "key1",
  offset: 4,
  partition: 2,
  topic: "topic1",
  ts: 1625051581049,
  ts_type: :create,
  value: "test2\n"
}
key1: test2
```

We can see that the ts has incremented again: 


% echo $(( 1625051581049 - 1625051465330))
115719

It is the nature of the consensus groups used by Kafka to ensure consistent sharding/shard reads that the timestamp will always monotonically increase.

We could use this characteristic for CAS (compare and set) operation to database/data store. 

For example : 

1. We set a unique constraint on an object field for event id 
2. We insert to cockroachdb, using a similar statement to what we used on XXXStrike
insert into events (id, kafkatsvalue, field1,field2,...) on conflict existing e ... 
if e.kafkatsvalue  < new.kafkatsvalue ... then store the data ... otherwise NOP..




























