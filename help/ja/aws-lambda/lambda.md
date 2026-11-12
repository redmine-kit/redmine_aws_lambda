# AWS Lambda 上の Redmine

AWS Lambda では、「管理」›「AWS」›「ステータス」に、ページを返している Lambda 関数 (関数名、役割、バージョン、メモリ、リージョン、イメージ URI) と、「読み取り専用の設定」(Lambda で固定している Redmine の設定とその値) も表示します。

Lambda で固定している Redmine の設定 (「コミットを自動取得する」「リポジトリ管理用のWebサービスを有効にする」「受信メール用のWebサービスを有効にする」) は、Lambda では動かないため、「管理」›「設定」で無効になり、「この環境では設定できません」と表示されます。リポジトリの種類は Subversion と Git だけを表示します。

詳しくは [Redmine AWS Lambda の管理画面](https://redmine-kit.github.io/redmine_aws_lambda/ja/admin.html) を参照してください。
