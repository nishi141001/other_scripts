# WindowsパフォーマンスコレクターのCSVロググラフ化
## 実行ファイル
.\scripts\exec_create_graph.py

## input
.\log
配下のサブディレクトリを含むCSVログを整形、グラフ化


## output
.\tmp
処理したファイル一覧です。

以下については、抽出、描画するメトリックに合わせて内容を変更すること
.\output
.\scripts\perf_extract.pyのcsv作成時に指定したメトリックのみ抽出したログサマリ

.\graph
.\scripts\perf_extract.pyでgraph作成時に指定したメトリックのみ抽出した積み上げ面グラフ



