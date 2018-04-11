# Description:
#   PRレビューがアサインされたらSlackのチャンネルに通知する
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SLACK_TOKEN - SlackのIntegrationsから設定したHubot APIトークン。
#                       コミットに混ぜたくないので本リポジトリでは環境変数に登録しています
#   PORT - ポート番号 bin/hubotに9999を設定してある
#
# URLs:
#   /github/webhook - PRレビューがアサインされたらSlackのチャンネルに通知するgithub webhook
#
# Commands:
#   None
#
# Notes:
#   None
#
# Author:
#   harapeko

fs = require 'fs'
crypto = require 'crypto'
secret = process.env.GITHUB_WEBHOOK_SECRET

# 前回アサインされたレビュワーのログ
LOG_REVEIEWERS = './github_reviewers.log'

# githubリポジトリ名とSlackチャンネルIDの対応表
# "github user id": "slack id"
# NOTE:
# Slackのチャンネル右クリのCopyLinkでID取れる
MAP_SLACK_USER = {}
MAP_SLACK_USER.okeparah = process.env.SLACK_OKEPARAH
MAP_SLACK_USER.harapeko = process.env.SLACK_HARAPEKO

# SlackのチャンネルID
# NOTE:
# Slackのチャンネル右クリのCopyLinkでチャンネルID取れる
SLACK_CHANNEL = process.env.SLACK_CHANNEL


module.exports = (robot) ->
  # PRレビューがアサインされたらSlackのチャンネルに通知するgithub webhook
  robot.router.post '/github/webhook', (req, res) ->
    # ファイルがなければ作成する
    unless isExistFile(LOG_REVEIEWERS)
      writeFile(LOG_REVEIEWERS, '')

    # event type、body、action、リポジトリ名 取得する
    # 処理を続けるかの判断に使用する
    event_type = req.get 'X-Github-Event'
    signature = req.get 'X-Hub-Signature'
    data = req.body
    action = data.action
    repo_name = data.repository.name

    # [DEBUG]
    robot.logger.info "event_type is #{event_type}"
    robot.logger.info "signature is #{signature}"
    robot.logger.info "action is #{action}"
    robot.logger.info "repo_name is #{repo_name}"

    # github webhookのsecret認証とおらなければ401で終了する
    return res.status(401).send 'secretが未設定です' unless signature
    return res.status(401).send 'unauthorized' unless isCorrectSignature(signature, req.body)

    # review_request_removedだったら、ログファイルを空にする
    # 
    # why?：
    # 次回のreview_requestedで
    # 再度同じ人にメンションを送るためかもしれないから
    if (action == 'review_request_removed')
      writeFile(LOG_REVEIEWERS, '')


    # PR、review_requestedでなければ終了
    return res.status(200).send 'review_requestedではありません。何もせず終了します' unless (action == 'review_requested')
    return res.status(200).send 'review_requestedではありません。何もせず終了します' unless (event_type == 'pull_request')


    # PRのURL、レビュワーに関するデータ、レビュワーのSlackユーザ名を取得する
    pr_url = data.pull_request.html_url
    reviewers_data = data.pull_request.requested_reviewers
    slack_users = reviewers_data.map (reviewer) ->
      MAP_SLACK_USER[reviewer.login] ? reviewer.login
    slack_users = slack_users.join(',')
    # 前回ログファイル読み込み
    pre_data = fs.readFileSync(LOG_REVEIEWERS, 'utf8')
    current_data = pr_url + slack_users

    # [DEBUG]
    robot.logger.info "pr_url is #{pr_url}"
    robot.logger.info "slack_users is #{slack_users}"
    robot.logger.info "pre_data is #{pre_data}"
    robot.logger.info "current_data is #{current_data}"
    console.dir reviewers_data


    # 前回ログと差分があればhubotがslackチャンネルでメンションする
    # その際、メンションしたユーザをログに書き込む
    if pre_data != current_data
      robot.logger.info '差分あり'
      writeFile(LOG_REVEIEWERS, current_data)
      robot.adapter.client.web.chat.postMessage SLACK_CHANNEL, pr_url +  "\r\n" + slack_users + " レビュー依頼だよ！", {as_user: true, unfurl_links: false}
    else
      robot.logger.info '差分なし'

    res.status(200).send 'done'


  # エラー表示
  robot.error (err, res) ->
    robot.logger.error "ERROR: SOMETHING WRONG!!"


# ファイルの存在チェック関数
isExistFile = (path) ->
  try
    fs.statSync path
    return true

  catch err
    if err.code == 'ENOENT'
      return false


# ファイル書き込み関数
writeFile = (path, data) ->
  fs.writeFile path, data, (err) ->
    if err
      console.log err
      throw err

    console.info 'The file has been saved!'
    console.log data


# Secret認証
isCorrectSignature = (sign, body) ->
  pairs = sign.split '='
  digest_method = pairs[0]
  calculated_hash = crypto.createHmac(digest_method, secret).update(JSON.stringify(body)).digest('hex')
  calculated_signature = [digest_method, calculated_hash].join '='

  return sign == calculated_signature
