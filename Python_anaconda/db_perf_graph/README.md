# WindowsパフォーマンスコレクターのCSVロググラフ化
## 実行ファイル
.\scripts\exec_create_graph.py

## input
.\log<br>
配下のCSVログを整形、グラフ化

## output
.\tmp<br>
処理したファイル一覧


以下については、抽出、描画するメトリックに合わせて内容を変更すること<br>
.\output<br>
.\scripts\perf_extract_memory.pyでSQL serverのメモリ使用量を確認する際に必要な内容を抽出している

.\graph<br>
.\scripts\perf_extract_memory.pyでgraph作成時に指定したメトリックのみ抽出したグラフ

|グラフ|説明|
|:---|:---|
|01_SQL_Server_MaxMemory_Breakdown.png|MaxServerMemoryの内訳|
|02_Stolen_Server_Memory_Breakdown.png|01グラフのStolen_server_Memoryの内訳の一部(主にプランキャッシュ)|
|03_Cache_hit_ratio_and_Page_life(buffer_Cache)_Breakdown.png|キャッシュヒット率とbuffer_CacheのPage_life|

