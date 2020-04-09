JavaによるAkkaトレーニング第3回 

## アクターとデータベースのシステム

Akkaは状態を持つ非同期処理を実装するだけでなく、耐障害性をもったシステムを構築するのに有用なツールキットです。
[トレーニングの第2回](https://github.com/mvrck-inc/training-akka-java-1-preparation)ではアクターを用いたアプリケーションの作成方法を学びました。
今回はアクターを用いたアプリケーションのバックエンドにデータベースを導入する方法について学びます。

以下に課題を用意したので、それをこなすことがこのトレーニングのゴールです。
課題の提出方法は後ほど紹介しますが、課題を通じて手を動かすとともに、トレーナーと対話することで学びを促進することが狙いです。

- [課題提出トレーニングのポリシー](./POLICIES.md)
- [次回のトレーニング: Akkaアクターを用いた非同期処理](https://github.com/mvrck-inc/training-akka-java-3-event-sourcing)

## この課題で身につく能力

- 状態遷移図とEventSourceBehaviorの対応関係がわかる
- akka-persistence-jdbcとSerializerの動作がわかる、設定ができる
- パフォーマンスを計測

## 課題

MacBook前提。

## 課題


### 事前準備:

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
- akka-persistenceをセットアップしてください
- チケット(在庫)とオーダーの[整合性](https://plantuml.com/sequence-diagram)を保つシーケンス図を書いてください
- チケット(在庫)とオーダーの[状態遷移図](https://plantuml.com/state-diagram)を書いてください
  - その際中身が空の「初期状態」をつくってください、これはソースコードを書く際EventSourcedActorおemptyStateをoverrideするために必要です
- それぞれの状態毎に詳細な状態遷移図を描き、コマンド、イベント、遷移可能状態、副作用をまとめてください
  - 状態遷移「表」をあわせて作ってください
- ソースコードにCommandを定義してください
- ソースコードにEventを定義してください
- ソースコードにStateを定義してください
- 状態遷移図をEventSourcedActorを継承したアクターの実装に落とし込んでください
- データベースのセットアップをしてください
  - `CREATE TABLE`を走らせてください(リンク)
- jacksonによるSerializationをセットアップしてください
- ガーディアンアクターから樹形図を作成し、チケット(在庫)アクターとオーダーアクターを親子関係の中に配置してください
  - シーケンス図を複数アクターに拡大したものを作成してください
- 親子関係の樹形図をもとに、ガーディアンアクターなどを実装してください
- akka-httpをセットアップしてください
- wrk -t2 -c4 -d5s -s wrk-scripts/order.lua http://localhost:8080/orders
  - t2: 2 threads, c4: 4 http connections, d5: test duration is 5 seconds
  - クライアント側とサーバー側の実行結果を確認してください

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