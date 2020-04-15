JavaによるAkkaトレーニング第3回 

## アクターとデータベースのシステム(イベント・ソーシング)

Akkaは状態を持つ非同期処理を実装するだけでなく、耐障害性をもったシステムを構築するのに有用なツールキットです。
[トレーニングの第2回](https://github.com/mvrck-inc/training-akka-java-1-preparation)ではアクターを用いたアプリケーションの作成方法を学びました。
今回はAkkaアクターを用いたアプリケーションとデータベースを接続する方法について学びます。


- [次回のトレーニング: アクターとデータベースのシステム(CQRS)](https://github.com/mvrck-inc/training-akka-java-4-cqrs)

## 課題

この課題をこなすことがトレーニングのゴールです。課題を通じて手を動かすとともに、トレーナーと対話することで学びを促進することが狙いです。

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
- データベースのセットアップをしてください
  - `CREATE TABLE`を走らせてください(リンク)
- curlでデータを挿入してください
  - レスポンスを確認してください
  - アプリケーション側のログを確認してください
- wrk -t2 -c4 -d5s -s wrk-scripts/order.lua http://localhost:8080/orders
  - t2: 2 threads, c4: 4 http connections, d5: test duration is 5 seconds
  - クライアント側とサーバー側の実行結果を確認してください
- チケット(在庫)とオーダーの整合性を保つ[シーケンス図](https://plantuml.com/sequence-diagram)を[確認してください](../)
- チケット(在庫)とオーダーの[状態遷移図](https://plantuml.com/state-diagram)を[確認してください](../)
  - [前回のトレーニング](https://github.com/mvrck-inc/training-akka-java-2-actor)と比較してください
- それぞれの状態の詳細な状態遷移図を見てコマンド、遷移可能状態、副作用を[確認してください](../)
- 状態遷移「表」を[確認してください](../)
- ソースコードのコマンドを[確認してください](../)
- ソースコードのイベントの定義を[確認してください](../)
- ソースコードの状態の定義を[確認してください](../)
- アクターの親子関係を定義する樹形図を[確認してください](../)
  - シーケンス図を複数アクターに拡大したものをを[確認してください](../)
- アクターの親子関係の樹形図をもとに、ソースコードでの実装を[確認してください](../)
- akka-persistenceのセットアップを[確認してください](../)
- jacksonによるSerializationをセットアップを[確認してください](../)
- akka-httpのセットアップを[確認してください](../)

### 発展的内容:

- 状態遷移図で売り切れ後のチケット追加販売を考えてください
- 状態遷移図でオーダーのキャンセルを考慮してください
- 状態遷移図でイベントの中止、払い戻しを考えてください
- 状態遷移図で先着と抽選の2通りを考えてください
- 状態遷移図で複数チケットの同時購入を考えてください
- 不正データのハンドリング、業務例外を考えてください
  - 不正なオーダーを弾いてください(年齢制限、不正なチケット種別の組み合わせ、などなど) 
  - 購入履歴と照らし合わせた不正な購入を防いでください
- asyncテストが必要となるテストケース例を考えてください
- コンサート以外に、スポーツや映画、入場券のみイベントを実現するテーブルを考えてください

## 説明

- [課題背景](./BACKGROUND.md)
- [課題提出方法](./SUBMIT.md)
- [課題手順の詳細](./DETAILES.md)

## 参考文献・資料

- https://plantuml.com/