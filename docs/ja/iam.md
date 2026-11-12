# IAM 権限

プラグインは自分では AWS の API を呼ばないので、プラグイン自身の権限は不要です。Lambda そのものの権限 (ログ、VPC の中での実行) は、[Serverless の iam.md](https://redmine-kit.github.io/serverless/ja/iam.html) にあります。

<a id="permissions"></a>

## 権限

| アクション | リソース | 理由 |
| --- | --- | --- |
| なし | — | 「ステータス」のタブと接続テストは [Redmine AWS](https://redmine-kit.github.io/redmine_aws/ja/iam.html) のもの。S3、SES、SQS の確認は、それぞれのプラグインの IAM 権限のページにある権限を使う |

<a id="example-policy"></a>

## ポリシーの例

ありません。

<a id="resource-based-policies"></a>

## リソースベースのポリシー

ありません。

<a id="not-checked-yet"></a>

## 未確認の事項

ありません。
