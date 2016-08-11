# SQL Server DBCC MEMORYSTATUS関連のメトリック
<br>

### Memory Manager

|メトリック|単位|備考|
|:---|:---|:---|
|VM Reserved|KB|SQL serverが予約している仮想アドレス空間(VAS)の全体量|
|VM Commited|KB|SQL serverがコミットしている仮想アドレス空間(VAS)の全体量|
|AWE Allocated|KB|32bit版SQL serverでAWE機構によって割り当てられたメモリの全体量 or 64bit版SQL serverでロックされたページによって消費されるメモリの全体量  |
|Reserved Memory |KB|用管理者接続 (DAC) 用に予約されたメモリ|
|Reserved Memory In Use |KB|使用中の予約されたメモリ|

### 各Memory nodeのメモリ使用量
|メトリック|単位|備考|
|:---|:---|:---|
|VM Reserved|KB|このノードで実行中のスレッドによって予約された VAS |
|VM Commited|KB|このノードで実行中のスレッドによってコミットされた VAS |
|AWE Allocated|KB|32bit版SQL serverでAWE機構によって割り当てられたメモリの全体量 or 64bit版SQL serverでロックされたページによって消費されるメモリの全体量  |
|MultiPage Allocator|KB|このノードで実行中のスレッドによって、マルチページ アロケータ経由で割り当てられたメモリ（バッファプール外）|
|SinglePage Allocator|KB|このノードで実行中のスレッドによって、シングルページ アロケータ経由で割り当てられたメモリ（バッファープール内）|


### 集計メモリ（各Clerkタイプ及び各NUMAノードの集計メモリ情報）
##MEMORYCLERK_SQLGENERAL
|メトリック|単位|備考|
|:---|:---|:---|
|Stolen|page(8k)|"Stolen (使用された) メモリ" とは、さまざまな目的でサーバーが使用する 8 KB バッファのことです。これらのバッファは、汎用的なメモリ ストア割り当てとして機能します。サーバーのさまざまなコンポーネントが、これらのバッファを使用して内部データ構造を格納します。lazywriter プロセスは、Stolen バッファをバッファ プールからフラッシュすることはできない|
|Free |page(8k)|現在使用されていない、コミットされたバッファ|
|Cached |page(8k)|キャッシュ用に使用されるバッファ|
|Database (clean)|page(8k)|変更されていないバッファ|
|Database (dirty) |page(8k)|変更されているバッファ|
|I/O |page(8k)|保留中の I/O 処理で待機しているバッファ|
|Latched |page(8k)|ラッチ済みバッファ|




<br>
## Buffer Pool
以下はバッファープール内の8KBバッファの配分を示す

### Buffer Counts 

|メトリック|単位|備考|
|:---|:---|:---|
|Committed |page(8k)|コミットされたバッファの合計|
|Target |page(8k)|バッファ プールのターゲット サイズ。Target 値が Committed 値より大きい場合、バッファ プールは増加中を示す|
|Hashed |page(8k)|バッファ プールに格納されたデータ ページ数とインデックス ページ数|
|Stolen Potential |page(8k)|バッファ プールから使用できる最大ページ数|
|ExternalReservation|page(8k)|並べ替え操作またはハッシュ操作を実行するクエリ用に予約されている未使用ページ数|
|Min Free|page(8k)|バッファ プールがフリー リストで保持しようとしているページ数|
|Visible|page(8k)|同時に表示可能なバッファ|
|Available Paging File|page(8k)|コミット可能なメモリ量|


### プロシージャ キャッシュ(SQL server 2005)
### Procedure Cache  
|メトリック|単位|備考|
|:---|:---|:---|
|TotalProcs|page(8k)|現在プロシージャ キャッシュにあるキャッシュされたオブジェクトの合計(sys.dm_exec_cached_plans)|
|TotalPages|page(8k)|プロシージャ キャッシュにすべてのキャッシュされたオブジェクトを格納するために保持する必要がある合計ページ数|
|InUsePages|page(8k)|現在実行中のプロシージャに属しているプロシージャ キャッシュのページ数|

### プラン キャッシュ(SQL server 2012)
### Palan Cache  
|メトリック|単位|備考|
|:---|:---|:---|
|Cache Hit Ratio|%|Sql Plans : パラメータ化クエリ /アドホッククエリ<br>Object Plans : ストアド プロシージャ/関数/トリガー|
|Cache Object Counts|||
|Cache Object in use|||
|Cache Pages|page(8k)|||



### グローバル メモリ オブジェクト
### Global Memory Objects
|メトリック|単位|備考|
|:---|:---|:---|
|Locks|page(8k)|ロック マネージャによって使用されるメモリ|
|XDES|page(8k)|トランザクション マネージャによって使用されるメモリ|
|SETLS|page(8k)|スレッド ローカル ストレージを使用する、ストレージ エンジン固有のスレッドごとの構造体を割り当てるために使用されるメモリ|
|SE Dataset Allocators|page(8k)|"アクセス メソッド" 設定によってテーブル アクセス用の構造体を割り当てるために使用されるメモリ|
|SubpDesc Allocators|page(8k)|クエリの並列実行、バックアップ操作、復元操作、データベース操作、ファイル操作、ミラーリング、および非同期カーソル用のサブプロセスを管理するために使用されるメモリ（並列プロセス）|
|SE SchemaManager|page(8k)|ストレージ エンジン固有のメタデータを格納するためにスキーマ マネージャによって使用されるメモリ|
|SQLCache|page(8k)|アドホック ステートメントおよび準備されたステートメントのテキストを格納するために使用されるメモリ|
|Replication|page(8k)|内部レプリケーション サブシステム用にサーバーによって使用されるメモリ|
|ServerGlobal|page(8k)|いくつかのサブシステムによって汎用的に使用されるグローバル サーバー メモリ オブジェクト|
|XP Global|page(8k)|拡張ストアド プロシージャによって使用されるメモリ|
|Sort Tables|page(8k)|並べ替えテーブルによって使用されるメモリ

### クエリ メモリ オブジェクト
### Query Memory Objects 

|メトリック|単位|備考|
|:---|:---|:---|
|Grants||メモリが割り当てられた実行中のクエリ|
|Waiting||メモリの割り当てを待っているクエリ|
|Available||ハッシュと並べ替えのワークスペースとしてクエリで使用できるバッファ|
|Maximum||すべてのクエリでワークスペースとして使用できるバッファの合計|
|Limit||大きいクエリ用のキューのクエリ実行対象|
|Next Request||次の待機中クエリ用のメモリ要求のサイズ (バッファ数) |
|Waiting For||Next Request 値で参照されているクエリを実行するために使用可能であることが必要なメモリ量|
|Cost||次の待機中クエリのコスト|
|Timeout|sec|次の待機中クエリのタイムアウト時間 (秒) |
|Wait Time|ms|次の待機中クエリがキューに挿入されてからの経過時間 (ミリ秒) |
|Last Target||クエリ実行用のメモリ全体に対する制限|

