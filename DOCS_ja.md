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