# リポジトリ運用ガイド

このドキュメントでは、本リポジトリの運用方法について説明します。

## リモートリポジトリの構成

本リポジトリは以下の2つのリモートリポジトリと連携しています：

1. **upstream** - オリジナルリポジトリ
   - URL: https://github.com/DeNA/dify-google-cloud-terraform.git
   - 用途: オリジナルのコードベースの取得

2. **origin** - フォークしたリポジトリ
   - URL: https://github.com/terisuke/forDify.git
   - 用途: 独自の変更の管理・公開

## 基本的なコマンド

### リモートの確認
```bash
git remote -v
```

### upstreamから最新のコードを取得
```bash
# upstreamの最新情報を取得
git fetch upstream

# ローカルのmainブランチにupstreamの変更を取り込む
git merge upstream/main

# または、rebaseを使用する場合
git rebase upstream/main
```

### 変更をoriginにプッシュ
```bash
# 変更をステージング
git add .

# 変更をコミット
git commit -m "コミットメッセージ"

# originにプッシュ
git push origin main
```

## 開発フロー

1. 新機能開発やバグ修正を行う場合：
   ```bash
   # 新しいブランチを作成
   git checkout -b feature/新機能名

   # 開発作業を行う
   ...

   # 変更をコミット
   git add .
   git commit -m "新機能の追加"

   # originに新しいブランチをプッシュ
   git push origin feature/新機能名
   ```

2. upstreamの更新を取り込む場合：
   ```bash
   # mainブランチに移動
   git checkout main

   # upstreamから更新を取得
   git fetch upstream
   git merge upstream/main

   # originに更新をプッシュ
   git push origin main
   ```

## 注意事項

1. **機密情報の扱い**
   - `.tfvars`ファイルには機密情報が含まれる可能性があるため、必ずGitの管理対象から除外してください
   - `.gitignore`に適切な除外設定が含まれていることを確認してください

2. **コンフリクトの解決**
   - upstreamの変更を取り込む際にコンフリクトが発生した場合は、慎重に解決してください
   - 不明な点がある場合は、upstreamのリポジトリのIssuesやDiscussionsを確認してください

3. **ブランチ管理**
   - mainブランチは常にupstreamと同期できる状態を保つようにしてください
   - 開発は必ず別ブランチで行い、完了後にmainブランチにマージしてください

## トラブルシューティング

### Q1: upstreamの変更を取り込む際にコンフリクトが発生した
```bash
# 現在の変更を一時的に退避
git stash

# upstreamの変更を取り込む
git fetch upstream
git merge upstream/main

# コンフリクトを解決後、変更をコミット
git add .
git commit -m "Resolve conflicts with upstream"

# 退避した変更を戻す
git stash pop
```

### Q2: 誤って機密情報をコミットしてしまった
```bash
# 直前のコミットを取り消し
git reset --soft HEAD^

# .gitignoreに該当ファイルを追加
echo "機密ファイル名" >> .gitignore

# 変更を再コミット
git add .gitignore
git commit -m "Remove sensitive information and update .gitignore"

# 強制プッシュ（注意: チーム開発の場合は要相談）
git push origin main --force
```

### Q3: Terraform destroyが削除保護と依存関係で失敗する

**問題**: `terraform destroy`を実行した際に、削除保護やリソースの依存関係に関するエラーが発生し、リソースを正常に削除できない。

**よくあるエラーメッセージ**:
```
Error: cannot destroy service without setting deletion_protection=false and running `terraform apply`
Error: Error, failed to deleteuser postgres in instance postgres-instance: googleapi: Error 400: Invalid request: failed to delete user postgres: . role "postgres" cannot be dropped because some objects depend on it
Error: Error deleting bucket: googleapi: Error 409: The bucket you tried to delete was not empty.
```

**根本原因**:
1. **削除保護**: Cloud SQLとCloud Runサービスに削除保護が有効になっている
2. **リソース依存関係**: 一部のリソースが他のリソースに依存しており、間違った順序で削除できない
3. **非空リソース**: Storageバケットにオブジェクトが含まれており、削除を妨げている
4. **データベース依存関係**: PostgreSQLユーザーがデータベースオブジェクトに依存している

**解決策**: リポジトリが以下の改善により更新されました：

1. **削除保護の自動無効化**:
   - Cloud SQL: terraform.tfvarsで`deletion_protection = false`
   - Cloud Run: モジュール設定で`deletion_protection = false`
   - Storage: モジュール設定で`force_destroy = true`

2. **適切なリソース依存関係**:
   - 正しい削除順序を保証する`depends_on`関係を追加
   - `create_before_destroy = true`を含む`lifecycle`ブロックを追加

3. **リソースクリーンアップ順序**:
   - Cloud Run → Cloud SQL → Redis → Filestore → Network → Storage

**予防策**: 以下の設定が常に適切に行われていることを確認してください：

```hcl
# terraform.tfvars
db_deletion_protection = false

# modules/cloudrun/main.tf
resource "google_cloud_run_v2_service" "dify_service" {
  deletion_protection = false
  # ... その他の設定
}

# modules/storage/main.tf
resource "google_storage_bucket" "dify_bucket" {
  force_destroy = true
  # ... その他の設定
}
```

**手動クリーンアップ（必要な場合）**:
```bash
# 削除保護を手動で無効化
gcloud sql instances patch postgres-instance --no-deletion-protection

# Cloud Runサービスを手動で削除
gcloud run services delete dify-service --region=asia-northeast1 --quiet
gcloud run services delete dify-sandbox --region=asia-northeast1 --quiet

# Storageバケットを空にして削除
gsutil -m rm -r gs://your-bucket-name/*

# 手動で削除した場合はTerraformの状態から削除
terraform state rm module.cloudsql.google_sql_database_instance.postgres_instance

### Q4: Serverless VPC Access予約によりVPC関連リソースが削除できない

**問題**: `terraform destroy`を実行した後、VPCネットワークとサブネットリソースが残存する。これはServerless VPC Access予約によって使用されているため、簡単に削除できない。

**よくあるエラーメッセージ**:
```
ERROR: (gcloud.compute.networks.subnets.delete) Could not fetch resource:
 - The subnetwork resource is already being used by 'projects/xxx/regions/xxx/addresses/serverless-ipv4-xxx'

ERROR: (gcloud.compute.addresses.delete) Could not fetch resource:
 - The address resource is already being used by '//serverless.googleapis.com/projects/xxx/locations/xxx/addressReservations/serverless-ipv4-xxx'
```

**根本原因**:
1. **Serverless VPC Access予約**: Serverless VPC Accessによって自動的に作成されるIPアドレス予約
2. **権限の問題**: 現在のアカウントがServerless VPC Accessの管理権限を持っていない可能性
3. **自動リソース作成**: これらの予約は自動的に作成され、手動で削除するのが困難

**解決策**: 以下のアプローチを使用できます：

1. **自動クリーンアップを待つ**: 数時間後に予約が自動的に解放される場合がある
2. **プロジェクト管理者に依頼**: プロジェクト管理者にServerless VPC Access予約の削除を依頼
3. **リソースを残す**: VPCリソースの費用影響は最小限のため、削除が重要でない場合は残すことも可能

**手動クリーンアップの試行**:
```bash
# Serverless VPC Accessコネクタを削除（存在する場合）
gcloud compute networks vpc-access connectors list --region=asia-northeast1 --project=your-project-id

# IPアドレス予約を削除
gcloud compute addresses delete serverless-ipv4-xxx --region=asia-northeast1 --project=your-project-id

# サブネットとネットワークを削除（予約が存在する場合は失敗）
gcloud compute networks subnets delete dify-subnet --region=asia-northeast1 --project=your-project-id
gcloud compute networks delete dify-vpc --project=your-project-id
```

**費用影響**: VPCネットワークとサブネットの費用は最小限（通常月額$1未満）のため、残しておいても問題ありません。 