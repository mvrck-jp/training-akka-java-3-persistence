### 事前準備:

MacBook前提。

- MySQL8.0.19をローカル開発環境にインストールしてください
  - `brew update`
  - `brew install mysql@8.0.19`
  - `mysql.Sever stop` //もし自分の環境で別のバージョンのMySQLが走っていたら
  - `/usr/local/opt/mysql@8.0/bin/mysql.Sever start`
- Mavenをインストールしてください
  - `brew install maven`

### 作業開始:

- このレポジトリをgit cloneしてください
  - `git clone git@github.com:mvrck-inc/training-akka-java-3-persistence.git`

この課題はgit clone下ソースコードをそのまま使うことで、自分で新たにソースコードを書くことなく実行できるようになっています。
もちろん、自分で書き方を覚えたい方や、最後の発展的内容に取り組みたい方はご自分でぜひソースコードを書いてみてください。

---
- データベースのセットアップをしてください ([setup.sql](./dbsetup/setup.sql)) - 参考: akka-persistence-jdbcプラグインのデフォルト・テーブル構成([リンク](https://github.com/akka/akka-persistence-jdbc/blob/v3.5.3/src/test/resources/schema/mysql/mysql-schema.sql))

`SELECT * FROM journal;`で以下のようなテーブルが出来ています。

| ordering | persistence_id | sequence_number | deleted | tags | message |
|----------|----------------|-----------------|---------|------|---------|

今回のトレーニングでは`snapshot`テーブルは利用しないので、そちらは無視します。

---
- アプリケーションを走らせてください
  - `mvn compile`
  - `mvn exec:java -Dexec.mainClass=org.mvrck.training.app.Main`

このコマンドでHTTP APIとアクターのバックエンドが一体になったプロセスが立ち上がります。

```
[INFO] Scanning for projects...
[INFO]
[INFO] -------------< org.mvrck.training:akka-java-3-persistence >-------------
[INFO] Building app 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- exec-maven-plugin:1.6.0:java (default-cli) @ akka-java-3-persistence ---
SLF4J: A number (1) of logging calls during the initialization phase have been intercepted and are
SLF4J: now being replayed. These are subject to the filtering rules of the underlying logging system.
SLF4J: See also http://www.slf4j.org/codes.html#replay
Server online at http://localhost:8080/
Press RETURN to stop...
```

---
- curlでデータを挿入してください
  - `curl -X POST -H "Content-Type: application/json" -d "{\"ticket_id\": 1, \"user_id\": 2, \"quantity\": 1}"  http://localhost:8080/orders`
  - クライアント側ログからレスポンスを確認してください
  - データベースでjournalテーブルを確認してください ([select.sql](./dbsetup/select.sql)) 
 
クライアント側ログで見えるレスポンスはこちら。

```
{"quantity":1,"success":true,"ticketId":1,"userId":2}
```

サーバー側ログには何も表示されません。

データベースの`journal`テーブルは以下のようになります。

| ordering | persistence_id                                  | sequence_number | deleted | tags | message |
|----------|-------------------------------------------------|-----------------|---------|------|---------|
| 4        | OrderActor-1fcba398-9331-45f5-8612-0617d973a99a | 1               | 0       | NULL | BLOB    |
| 3        | TicketStockActor-1                              | 1               | 0       | NULL | BLOB    |
| 2        | TicketStockActor-1                              | 1               | 0       | NULL | BLOB    |
| 1        | TicketStockActor-2                              | 1               | 0       | NULL | BLOB    |

- 一番上の`OrderActor-1fcba...`が`OrderActor`の`OrderCreated`イベント
- 真ん中の2つが`TicketStockActor`の`ticketId = 1`に対応する`TicketStockCreated`イベントと`OrderProcessed`イベント
- 一番下が`TicketStockActor`の`ticketId = 2`に対応する`TicketStockCreated`イベント

---
- wrkでベンチマークを走らせてください
  - `wrk -t2 -c4 -d5s -s wrk-scripts/order.lua http://localhost:8080/orders`
    - `-t2`: 2 threads
    - `-c4`: 4 http connections
    - `-d5`: 5 seconds of test duration
    - `wrk-scripts/order.lua` ([リンク](./wrk-scrips/order.lua))
    - クライアント側の実行結果を確認してください
    - データベースでjournalテーブルを確認してください ([select.sql](./dbsetup/select.sql))

<p align="center">
  <img width=450 src="https://user-images.githubusercontent.com/7414320/79639615-db8ac080-81c7-11ea-9ff8-123cba6c218c.jpg">
</p>

私のローカル環境で試したところ結果はこの様になりました。[第1回のトレーニング](https://github.com/mvrck-inc/training-akka-java-1-preparation/blob/master/INSTRUCTION.md)と比べても性能が向上していません…。
10倍くらいに性能上がるんじゃないかと期待していたから結構焦った。やはりちゃんと計測してみるのは大事ですねー。

```
Running 5s test @ http://localhost:8080/orders
  2 threads and 4 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    38.75ms   11.73ms  84.66ms   69.60%
    Req/Sec    51.57     11.00    80.00     54.00%
  518 requests in 5.03s, 95.10KB read
Requests/sec:    103.06
Transfer/sec:     18.92KB
```

おそらくパフォーマンスが変わらなかった理由は、下図のようにHTTPリクエストの度TicketStockActorとOrderActorの2つのアクターからデータベースにアクセスした後HTTPレスポンスを返しているからです。

<p align="center">
  <img width=450 src="https://user-images.githubusercontent.com/7414320/79852777-1710cf00-8402-11ea-8af7-384fb4a2d9c6.jpg">
</p>

しかし、Event Sourcingがデータベース・トランザクションによる排他制御に頼った非同期処理とパフォーマンスが変わらないかというと、そうではないと思います。
よりアプリケーションが複雑で大規模になると、Akkaがパフォーマンス面で有利になるのではないかと予測しています。
その理由はデータベース・トランザクションで排他制御を行っていると、アプリケーションの複雑化にともないロックするテーブルの数がふえるため、水平スケールしづらくなるからです。

最終的にはパフォーマンスに関しては、測ってみないとわからないですね。

---
- アプリケーション再起動後にcurlでGETしてアクターの内部状態が復元されていることを確認してください
  - `curl http://localhost:8080/orders/00fcca39-e162-4c3b-a171-613028772a24` 
  - orders以下のUUID部分はデータベースのテーブルから探して適当なものに置き換えてください
  
---
- akka-persistenceのセットアップを確認してください
  - [application.conf](./src/main/resources/application.conf) - 参考 akka-persistence-jdbcプラグインのデフォルト設定([リンク](https://github.com/akka/akka-persistence-jdbc/blob/v3.5.3/src/test/resources/mysql-application.conf))
  - [pom.xml](./pom.xml)
  - jacksonによるSerializationをセットアップを確認してください

---
- TicketStockActorとOrderActorの整合性を保つシーケンス図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuLBo20a9K70Cy5HIqBLJ2CbCpauj2Ix9JyvsJ2x9Bx9I22ZAJqujBlOlIaajuaANngubCqsXi3GnhoIpf5B1Ji40gowmUL3rpaMfYIMfO15avzZeegWAIYqkoCyhJkLoICrB0RaS0000) - ([参考リンク: PlantUML](https://plantuml.com/sequence-diagram))

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79866759-3c103c80-8418-11ea-96a4-8f95b10c4b18.png">
</p>

<details>
<summary>(<-を押して展開) PlantUMLのコード</summary>

```
@startuml
"HTTP API" -> TicketStockActor: ProcessOrder
TicketStockActor -> TicketStockActor: if quantity > 0
TicketStockActor -> OrderActor: CreateOrder
"HTTP API" <- OrderActor: Response
@enduml
```

</details>

---
- TicketStockActor

TicketStockActorとOrderActorのうち、TicketStockアクターのState, Command, Eventについて確認していきます。

- 状態遷移図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuUAArefLqDMrKqWiIypCIKpAIRLII2vAJIn9rT3aGX8hB4tCAyaigLImKp10YAFhLCXCKyXBBSUdEh-qn3yjk2G_ETiAGxKjK3MIFAe4bqDgNWhGoG00) - ([参考リンク: PlantUML](https://plantuml.com/state-diagram))

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79867374-38c98080-8419-11ea-9081-b4177bf2b7e1.png">
</p>

```
@startuml
left to right direction
[*] --> Initialized: create()
Initialized --> Available
Initialized: emptyState
Available: quantity > 0
Available --> Available:  if quantity > 0
Available --> OutOfStock: if quantity = 0
OutOfStock: quantity = 0
@enduml
```

- ソースコードのStateの定義をみて状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L155L180))
  - Initialized
  - Available
  - OutOfStock

- 詳細な状態遷移図を確認してください

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79868095-6105af00-841a-11ea-9370-413ba561994f.png">
</p>

([リンク](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuSf9JIjHACbNACfCpoXHICaiIaqkoSpFuuhMYbNGrRLJyCpBBCbCpCciIasnKd0kIaqiIGt9JCvEBGakoK_EvaAI1YjtB4lCp4bCoacrKa1I1j6NmkMGcfS2j1G0))

```
@startuml
left to right direction
[*] --> Initialized: CreateTicketStock
Initialized --> Available: TicketStockCreated
@enduml
```

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79876333-ddea5600-8425-11ea-82a5-b3ef7a5e4f20.png">
</p>

([リンク](http://www.plantuml.com/plantuml/uml/RS_12i8m40JGUxvYpqB1Sw6bnG-eu54zfCb6WsaMjrF1lrUBY1PlopAFOPeHLZ4DoIGE80XfF9r1FYexHCbclpfIKTJKtcnCjazSqbR5yJXswbdDvxzCKGnqdMn6n9rgMX_o3DwO_K9s4xgmWxXB-IEhFp8Bc7e1P209twKRPGkUuwynyz4wY59LcuQpVqvz0000))

```
@startuml
left to right direction
[*] --> Available: ProcessOrder
Available --> Available:  if quantity > 0\nOrderProcessed
Available --> OutOfStock: if quantity = 0\nOrderProcessed
note bottom of Available: CreateOrder to OrderActor => 
@enduml
```

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79877452-34a45f80-8427-11ea-9b27-904790146a5f.png">
</p>

([リンク](http://www.plantuml.com/plantuml/uml/NSz1oi8m40NWVKunwnyA_xfegIUesAMwI9k91jECPbu5Rsyh8jhLmF0-Pbwji1dZ44ra3u9G3gSpo8NCFO8ai_yxKb5KjBdR46qNkQHjbfvLc-mucyz-cQBWwJRQX807LVH_I2_mnkmMiXdH-1RINyeVkPvbAz5D0PC4J9q0Cf3uxskhWdQiLqdASmlbD3zNJsCgzmG0))

```
@startuml
left to right direction
[*] --> OutOfStock: *
@enduml
```

- ソースコードのコマンドを確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L85L112))
  - CreateTicketStock
  - ProcessOrder

- ソースコードのイベントを確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L114L153))
  - TicketStockCreated
  - OrderProcessed
  - SoldOut

- 状態遷移表を確認してください

|             | CreateTicketStock | ProcessOrder |
|-------------|-------------------|--------------|
| Initialized | handle            | -            |
| Available   | -                 | handle       |
| OutOfStock  | -                 | -            |

状態遷移図と合わせて状態遷移表も使うと、より状態とコマンドの組み合わせに関して抜け漏れがなくなります。
もちろん、実際のソースコードは更に細かい分岐が必要となる場合が多いです。

- ソースコードのコマンドハンドラとイベントハンドラを見て、詳細な状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java))
   
---
- OrderActor

TicketStockActorに続いて、OrderActorのState, Command, Eventについて確認していきます。

- 状態遷移図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuSf9JIjHACbNACfCpoXHICaiIaqkoSpFuuhMYbNGrRLJyCpBBCbCpCciIasnKaWkIaqiITNGv48I1Qjo1akaSA6eJiqjAAaCBW5AS3cavgK0RGC0) - ([参考リンク: PlantUML](https://plantuml.com/state-diagram))

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79878433-60741500-8428-11ea-8faa-3f138014c560.png">
</p>

```
@startuml
left to right direction
[*] --> Initialized: create()
Initialized --> Created
Initialized: emptyState
@enduml
```

- ソースコードの状態の定義をみて状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L110L127))
  - Initialized
  - Created

- 詳細な状態遷移図を確認してください

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79879079-35d68c00-8429-11ea-9978-d59cec911e56.png">
</p>

```
@startuml
left to right direction
[*] --> Initialized: CreateOrder
Initialized --> Created: OrderCreated
@enduml
```

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79879258-68808480-8429-11ea-869b-e76b26c08732.png">
</p>

```
@startuml
left to right direction
[*] --> Created: GetOrder
note bottom of Created: <= Response to sender
@enduml
```

- 状態遷移表を確認してください

|             | CreateOrder | GetOrder |
|-------------|-------------|----------|
| Initialized | handle      | -        |
| Created     | -           | handle   |

- ソースコードのコマンドを確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L64L91))
  - CreateOrder
  - GetOrder

- ソースコードのイベントを確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L93L108))
  - OrderCreated

- ソースコードのコマンドハンドラとイベントハンドラを見て、詳細な状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java))

---
- ガーディアンアクター以下親子関係のから樹形図を確認してください ([リンク](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuUBAJyfAJIvHS2zDB4h9JCo3yKCoaxDJIu9ByfEp0nABKlDAO1B-HIcfHL0XJBM6MCICKBGQel1GvOnHU2PSN31NAUJhwc8w2KKQnM4OIj4DC2Iin8WBoKI43OROXN6eDiOkRCBba9gN0Wn_0000))

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79877689-84832680-8427-11ea-8264-a8ca7ea30c8c.png">
</p>

```
@startuml
object Guardian
object TicketStockParent
object OrderParent
object TicketStock1
object TicketStock2
object Order1
object Order2
object Order3
object Order4

Guardian o-- TicketStockParent
Guardian o-- OrderParent
TicketStockParent o-- TicketStock1
TicketStockParent o-- TicketStock2
OrderParent o-- Order1
OrderParent o-- Order2
OrderParent o-- Order3
OrderParent o-- Order4
@enduml
```

TicketStockParentとOrderParentも考慮したシーケンス図はこちらです。

<p align="center">
  <img src="https://user-images.githubusercontent.com/7414320/79879679-fceae700-8429-11ea-9bbd-d01b904f200e.png">
</p>

```
@startuml
"Client"   -> "HTTP API": curl -x POST
"HTTP API" -> TicketStockParentActor: ProcessOrder
TicketStockParentActor -> TicketStockActor: ProcessOrder
TicketStockActor -> OrderParentActor: CreateOrder
OrderParentActor -> OrderActor: CreateOrder
"HTTP API" <- OrderActor: Response
Client <- "HTTP API" : HTTP response
@enduml
```

### 発展的内容:

- 状態遷移図で売り切れ後のチケット追加販売を考えてください
- 状態遷移図でオーダーのキャンセルを考慮してください
- 状態遷移図でイベントの中止、払い戻しを考えてください
- 状態遷移図で先着と抽選の2通りを考えてください
- 状態遷移図で複数チケットの同時購入を考えてください
- 不正データのハンドリング、業務例外を考えてください
  - 不正なオーダーを弾いてください(年齢制限、不正なチケット種別の組み合わせ、などなど) 
  - 購入履歴と照らし合わせた不正な購入を防いでください
- asyncテストが必要となるテストケース例を考えてINSTRUCTIONください
- コンサート以外に、スポーツや映画、入場券のみイベントを実現するテーブルを考えてください
