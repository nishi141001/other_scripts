# ログのstartとendの差分をとる
下記のようなログのstartとendの差分を取りたいけど、
複数startに対するendがなく紐づけられないため、
とりあえずキー毎のtimestampの昇順にstart-endを
紐づけることを想定

|timestamp|status|jobname|
|:---|:---|:---|
|08:00|start|job1|
|08:01|start|job1|
|08:10|end|job1|
|08:10|start|job2|
|08:20|end|job1|
|08:23|end|job2|




## 実行ファイル
.\scripts\exec_log_rownumber.py

## input
.\log
配下のサブディレクトリを含むTSVログ


## output
.\tmp
処理したファイル一覧

以下については、grepしたい内容に合わせて内容を変更すること
.\scripts\log_grep_diff.py
