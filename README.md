# PRレビューがアサインされたらSlackのチャンネルに通知する
## 設定

### 本リポジトリを外部に公開しておく
[ngrok](https://ngrok.com/)を使う場合

```zsh
% ngrok http 9999
```

### github webhook
Githubリポジトリ → Settings → Webhooks

- `Payload URL`に入力する。<br>
例：`http://example.com/github/webhook`
- `Content type`はapplication/jsonに設定する
- `Let me select individual events.`は`Pull requests`にチェックする

### Slack
- hubotをslackに追加する。[https://slack.com/apps](検索からhubotと検索するのが早い)
- Slackでhubotをチャンネルに招待する。
- チャンネルIDとユーザIDを`scripts/github.coffee`に書き込む<br>
(githubでのID：SlackでのIDを対応表に書き込む)

## Running
```zsh
% bin/hubot --adapter slack
```

# 実行結果
![2018-04-13 5 24 34](https://user-images.githubusercontent.com/1858578/38702225-03b43410-3edb-11e8-9460-b6d9c59d87e0.png)

# MEMO
- [Hubot のログ情報 (`Robot#logger`) まとめ](https://qiita.com/bouzuya/items/40b54e511d57954c9338)
- `fish shell`じゃ動かないぞ！(自分向け)