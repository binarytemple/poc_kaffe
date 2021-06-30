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










