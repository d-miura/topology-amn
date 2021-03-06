# 第6回 (11/9)レポート2(team-amn:東野研)
## メンバー
* 今井 友揮
* 成元 椋祐
* 西村 友佑
* 原 佑輔
* 三浦 太樹

## グループ課題2: トポロジコントローラの拡張
### 0. 課題内容
>* スイッチの接続関係に加えて，ホストの接続関係を表示する
>* ブラウザで表示する機能を追加する．おすすめは [vis.js](https://github.com/almende/vis) です

### 1. ホストの接続関係の表示
#### 1.1 実装内容
`./lib/view/graphviz.rb`のコードに，
`./lib/topology.rb`に新たに追加したインスタンス変数`@host`の内容を取得し，出力に書き加える処理を追加することで，ホストの接続関係を表示させた．

`./lib/view/graphviz.rb`に追加したコードの内容は以下の通り．
```ruby
#added (2016.11.9) add ellipse with ip_address and link between host and switch
topology.hosts.each do |each|  #for all host
  host = gviz.add_nodes(each[1].to_s, shape: 'ellipse')  #add ellipse with ip_address(each[1])
  gviz.add_edges host, nodes[each[2]]  #add link between host and switch(each[2]:switch dpid)
end
```
#### 1.2 実行結果
`./triangle.conf`に以下のようにホストの設定を加え，tremaを実行してトポロジ画像を表示させた．
```
vswitch { dpid '0x1' }
vswitch { dpid '0x2' }
vswitch { dpid '0x3' }

vhost { ip '192.168.1.1'}
vhost { ip '192.168.1.2'}
vhost { ip '192.168.1.3'}

link '0x1', '0x2'
link '0x1', '0x3'
link '0x3', '0x2'
link '0x1', '192.168.1.1'
link '0x2', '192.168.1.2'
link '0x3', '192.168.1.3'
```
以下の画像が主力された．  
![1-2](./graphs/test.png)

### 2. ブラウザ表示機能
#### 2.1 実装方針
View::Graphvizクラスのコードを参考に，Vis.jsを使用してトポロジ画像をjavascriptとして埋め込んだhtmlファイルを出力するView::Visクラスを`./lib/view/vis.rb`に実装した．
#### 2.2 ソースコードで変更・追加した内容
##### 2.2.1 追加，変更，新規作成したファイルの一覧
* [lib/topology_controller.rb](./lib/topology_controller.rb)
 - 既存のファイルに，パケットを判別する処理を追加
 - 詳細は2.3を参照
* [lib/command_line.rb](./lib/command_line.rb)
 - 既存のファイルに処理を追加
 - ブラウザでトポロジ図を表示するためのサブコマンドを実装
* [lib/view/vis.rb](./lib/view/vis.rb)
 - 新規作成
 - トポロジが更新され，updateハンドラが呼び出されると，Topologyクラスの持つhost,switch,linkの内容を`./lib/view/topology.html`にトポロジの内容を埋め込んで`/index.html`に出力
* [lib/view/topology.html](./lib/view/topology.html)
 - 新規作成
 - 出力ファイルの雛形
* /lib/view/vis.js
 - 新規追加
 - vis.jsのソース
* /lib/view/vis-network.min.css
 - 新規追加
 - 出力するhtmlが参照するスタイルシート
* [index.html](./index.html)
 - 作成した機能の出力ファイル
* /images/host.png
 - 新規追加
 - ホストの画像ソース
* /images/switch.jpg
 - 新規追加
 - スイッチの画像ソース

##### 2.2.2 vis.rbのコード
vis.rbではRubyの標準添付ライブラリであるERBを使用して`/lib/view/topology.html`にTopologyクラスの持つ，スイッチ，ホスト，リンクの内容をjavascriptの書式に変換してから出力ファイルである`/index.html`に埋め込んでいる．
```Ruby
26: @topology = outtext
27: fhtml = open(@output, "w")
28: fhtml.write(ERB.new(File.open('lib/view/topology.html').read).result(binding))
```
ここで，updateハンドラのローカルな配列outtextの各要素は，最終的なhtml形式の出力ファイルに書き出されるスイッチ，リンク，ホストの一つ一つの内容がjavascriptの書式に変換されたものである．14〜25行目の処理では，スイッチ，リンク，ホストの順にsprintf()関数によってTopologyクラスのインスタンス変数の持つ値が変換指定子の書式で展開されたうえでouttextに記録される．
スイッチの部分を以下に示す．
```Ruby
14: nodes = topology.switches.each_with_object({}) do |each, tmp|
15:   outtext.push(sprintf("nodes.push({id: %d, label: '%#x', image:DIR+'switch.jpg', shape: 'image'});", each.to_i, each.to_hex))
16: end
```

26行目でouttextの内容はインスタンス変数@topologyに保存され，28行目でERBによって[lib/view/topology.html](./lib/view/topology.html)の34〜36行目に埋め込まれたRubyスクリプト片である
```html
34: <% @topology.each do |topology| %>
35: <%= topology %>
36: <% end %>
```
部分が実行される．35行目では，配列である@topologyの各要素が先頭から順に評価される．この結果がERBによって`./index.html`に添付されていき，最終的に出力ファイルが得られる．

##### 2.2.3 サブコマンドの実装
vis.jsを用いたブラウザ上でのトポロジ図の参照は，以下のコマンドで行えるように[lib/command_line.rb](./lib/command_line.rb)へ実装した．
```
$ ./bin/trema run ./lib/topology_controller.rb -- visjs index.html
```
以上のように実行することで，`./index.html`が生成され，これをwebブラウザで開くことでvis.jsを用いたトポロジ図が参照できる．
[lib/command_line.rb](./lib/command_line.rb)の実装は下記の通り．
```Ruby
52: def define_visjs_command
53:   desc 'Displays topology information (visjs mode)'
54:   arg_name 'output_file'
55:   command :visjs do |cmd|
56:     cmd.action(&method(:create_visjs_view))
57:   end
58: end
```

#### 2.3 実機スイッチにホストを接続した際に送信される，意図しないパケットへの対応
実機スイッチにホストを接続すると，LLDP，IPv4パケット，Arpによるパケットのいずれにも属さないパケット(以降，このパケットをゴミパケットと呼ぶ)
によるPacketInが発生する．
デフォルトのプログラムでは，LLDP以外のパケットは，ホストから送信されたパケットとみなし，トポロジにホストを追加する処理を
行っているが，ゴミパケットによるPacketInが発生すると，ホストの情報が取得できないため，プログラムが強制終了してしまうといった
問題が発生する．
この問題を解決するために，[lib/topology_controller.rb](./lib/topology_controller.rb)のプログラムのうち，パケットの判別に関する
処理の部分を以下のように修正した．
```ruby
46: def packet_in(dpid, packet_in)
47:    if packet_in.lldp?
48:      @topology.maybe_add_link Link.new(dpid, packet_in)
49:    elsif packet_in.data.is_a? Arp
50:      @topology.maybe_add_host(packet_in.source_mac,
51:                               packet_in.source_ip_address,
52:                               dpid,
53:                               packet_in.in_port)
54:    elsif packet_in.data.is_a? Parser::IPv4Packet
55:      if packet_in.source_ip_address.to_s != "0.0.0.0"
56:        @topology.maybe_add_host(packet_in.source_mac,
57:                                 packet_in.source_ip_address,
58:                                 dpid,
59:                                 packet_in.in_port)
60:      end
61:    end
62:  end
```
まず，PacketInの発生要因となったパケットが，LLDPパケットである場合は，リンクを追加する処理を実行する(47~48行目)．
ArpによるパケットやIPv4Packetである場合は，ホストを追加する処理を実行する(49~61行目)．
それ以外のパケット，つまりゴミパケットである場合は，何も処理をしない．
このようにプログラムを修正することで，ゴミパケットによる問題を解決した．

#### 2.4 実機スイッチを用いた動作の検証
VSI間で適当にイーサネットケーブルを配線し，2台のPCをホストとして接続した実機に対し，ブラウザ表示機能を用いてトポロジ図を表示させた．
実行時の様子と，実行結果の画面を以下に示す．  

|<figure><img src="./img_report/real_machine.jpg" height="320px"><br><figcaption>実行時の様子</figcaption></figure>|<figure><img src="./img_report/screenshot_real.png" height="320px"><br><figcaption>表示結果</figcaption></figure>|
|:--:|:--:|
