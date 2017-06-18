# 選択されたパスとファイルのみ同じ構造コピペするbatを作るだけ<br>
個人利用用。ソース群から必要な分のみ同じ構造で抽出する。<br>
batを作るところまで。<br>
作ったbatの中を確認してOKなら手動で叩いて使う。<br>
必要な情報は、conf配下のconfig.jsonに記載。<br>

## ソース群<br>
コピペしたいソース群は.\source配下へ格納しておく

## コピー先<br>
生成されたbatを叩くと、.\target配下へinput配下のファイルに入力されている一覧を同じ構造でコピペします。


## input<br>
excelからそのままコピペしてinputを作成することを想定して区切りは\t

path_copy.txt
|path|filename|
|:---|:---|
|test_script\folder01\folder0a\folder1a|test01.txt|


## output<br>
そのまま叩けばファイルコピーを実行するbatが生成される<br>
中身はただのechoとxcopyのコマンドです。

## 実行ファイル
.\scripts\create_cmd.py

