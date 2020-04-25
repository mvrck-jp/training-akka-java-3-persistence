JavaによるAkkaトレーニング第3回 

## アクターとデータベースのシステム(イベント・ソーシング)

Akkaは状態を持つ非同期処理を実装するだけでなく、耐障害性をもったシステムを構築するのに有用なツールキットです。
[トレーニングの第2回](https://github.com/mvrck-inc/training-akka-java-1-preparation)ではアクターを用いたアプリケーションの作成方法を学びました。
今回はAkkaアクターを用いたアプリケーションとデータベースを接続する方法について学びます。

- [第1回のトレーニング: リレーショナル・データベースのトランザクションによる排他制御](https://github.com/mvrck-inc/training-akka-java-1-preparation)
- [第2回のトレーニング: アクターによる非同期処理](https://github.com/mvrck-inc/training-akka-java-2-actor)
- [第3回のトレーニング: アクターとデータベースのシステム(イベント・ソーシング)](https://github.com/mvrck-inc/training-akka-java-3-persistence)
- [第4回のトレーニング: アクターとデータベースのシステム(CQRS)](https://github.com/mvrck-inc/training-akka-java-4-cqrs)
- [第5回のトレーニング: クラスタリング](https://github.com/mvrck-inc/training-akka-java-5-clustering)

## 課題

この課題をこなすことがトレーニングのゴールです。
独力でも手を動かしながら進められるようようになっていますが、可能ならトレーナーと対話しながらすすめることでより効果的に学べます。

- [課題提出トレーニングのポリシー](https://github.com/mvrck-inc/training-akka-java-1-preparation/blob/master/POLICIES.md)

## この課題で身につく能力

- 状態遷移図とEventSourceBehaviorの対応関係がわかる
- akka-persistence-jdbcとSerializerの動作がわかる、設定ができる
- パフォーマンスを計測

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
- データベースのセットアップをしてください ([setup.sql](./dbsetup/setup.sql)) - 参考: akka-persistence-jdbcプラグインのデフォルト・テーブル構成([リンク](https://github.com/akka/akka-persistence-jdbc/blob/v3.5.3/src/test/resources/schema/mysql/mysql-schema.sql))
- アプリケーションを走らせてください
  - `mvn compile`
  - `mvn exec:java -Dexec.mainClass=org.mvrck.training.app.Main`
- curlでデータを挿入してください
  - `curl -X POST -H "Content-Type: application/json" -d "{\"ticket_id\": 1, \"user_id\": 2, \"quantity\": 1}"  http://localhost:8080/orders`
  - クライアント側ログからレスポンスを確認してください
  - データベースでjournalテーブルを確認してください ([select.sql](./dbsetup/select.sql)) 
- wrkでベンチマークを走らせてください
  - `wrk -t2 -c4 -d5s -s wrk-scripts/order.lua http://localhost:8080/orders`
    - `-t2`: 2 threads
    - `-c4`: 4 http connections
    - `-d5`: 5 seconds of test duration
    - `wrk-scripts/order.lua` ([リンク](./wrk-scrips/order.lua))
    - クライアント側の実行結果を確認してください
    - データベースでjournalテーブルを確認してください ([select.sql](./dbsetup/select.sql))
- アプリケーション再起動後にcurlでGETしてアクターの内部状態が復元されていることを確認してください
  - `curl http://localhost:8080/orders/00fcca39-e162-4c3b-a171-613028772a24` 
  - orders以下のUUID部分はデータベースのテーブルから探して適当なものに置き換えてください
- akka-persistenceのセットアップを確認してください
  - [application.conf](./src/main/resources/application.conf) - 参考 akka-persistence-jdbcプラグインのデフォルト設定([リンク](https://github.com/akka/akka-persistence-jdbc/blob/v3.5.3/src/test/resources/mysql-application.conf))
  - [pom.xml](./pom.xml)
  - jacksonによるSerializationをセットアップを確認してください
- TicketStockActorとOrderActorの整合性を保つシーケンス図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuLBo20a9K70Cy5HIqBLJ2CbCpauj2Ix9JyvsJ2x9Bx9I22ZAJqujBlOlIaajuaANngubCqsXi3GnhoIpf5B1Ji40gowmUL3rpaMfYIMfO15avzZeegWAIYqkoCyhJkLoICrB0RaS0000) - ([参考リンク: PlantUML](https://plantuml.com/sequence-diagram))
- TicketStockActor
  - 状態遷移図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuUAArefLqDMrKqWiIypCIKpAIRLII2vAJIn9rT3aGX8hB4tCAyaigLImKp10YAFhLCXCKyXBBSUdEh-qn3yjk2G_ETiAGxKjK3MIFAe4bqDgNWhGoG00) - ([参考リンク: PlantUML](https://plantuml.com/state-diagram))
  - ソースコードのStateの定義をみて状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L155L180))
  - 詳細な状態遷移図を確認してください
  - ソースコードのコマンドを確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L85L112))
  - ソースコードのイベントを確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java#L114L153))
  - 状態遷移表を確認してください
  - ソースコードのコマンドハンドラとイベントハンドラを見て、詳細な状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/TicketStockActor.java)) 
- OrderActor
  - 状態遷移図を[確認してください](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuSf9JIjHACbNACfCpoXHICaiIaqkoSpFuuhMYbNGrRLJyCpBBCbCpCciIasnKaWkIaqiITNGv48I1Qjo1akaSA6eJiqjAAaCBW5AS3cavgK0RGC0) - ([参考リンク: PlantUML](https://plantuml.com/state-diagram))
  - ソースコードの状態の定義をみて状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L110L127))
  - 詳細な状態遷移図を確認してください
  - ソースコードのコマンドを確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L64L91))
  - ソースコードのイベントを確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java#L93L108))
  - 状態遷移表を確認してください
  - ソースコードのコマンドハンドラとイベントハンドラを見て、詳細な状態遷移図との対応を確認してください([リンク](./src/main/java/org/mvrck/training/actor/OrderActor.java))
- ガーディアンアクター以下親子関係のから樹形図を確認してください ([リンク](http://www.plantuml.com/plantuml/uml/SoWkIImgAStDuUBAJyfAJIvHS2zDB4h9JCo3yKCoaxDJIu9ByfEp0nABKlDAO1B-HIcfHL0XJBM6MCICKBGQel1GvOnHU2PSN31NAUJhwc8w2KKQnM4OIj4DC2Iin8WBoKI43OROXN6eDiOkRCBba9gN0Wn_0000))

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

## 説明

- [課題背景](./BACKGROUND.md)
- [課題手順の詳細](./.md)

## 参考文献・資料

- https://plantuml.com/