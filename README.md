Flutter上で大量のデータを管理・検索しようと思ったため、SQLiteを使ってみます。

生のSQL文を書くより、ORマッパーを使いたいと思ったため、アクティブレコードパターンっぽくレコードを扱える sqfentity ライブラリを使います。

SQLiteのDBファイルの作成、DDL文の発行などはすべてライブラリがやってくれますので、生SQLを一切触らずにアプリで利用できます。


# sqfentity

https://pub.dev/packages/sqfentity

依存ライブラリに build_runner が入っています。このライブラリは、テーブルの定義を書いて、そこからbuild_runner でモデルコードを生成し、アプリでそれを使います。

最初は、ひと手間かかる感じが少し面倒そうだったのでコードジェネレートに少し抵抗があったのですが、生成済みのコードは機能リファレンスのように使えるため、なかなか使い勝手は良いです。

なお、DBの内容はアプリを再起動しても消えませんが、アプリをアンインストールすると消えます。

# セットアップ
## 新規 Flutterプロジェクトの作成

空のリポジトリを作成し、その中に新たな Flutter プロジェクトを作ります。

```
mkdir todo-sqf-flutter
cd todo-sqf-flutter

flutter create app
```

作った todo-sqf-flutter ディレクトリを、Flutter プラグイン組み込み済みの Android Studio で開きます。


右上 Add Configuration

![Screenshot 2019-12-10 11.56.14.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/68302/2496e208-8623-3a9f-891f-fdbfafcdd3db.png)

`+` → ○ more items → Flutter

![Screenshot 2019-12-10 11.56.39.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/68302/12d18c58-f4f5-f164-35d5-ec7057dc6265.png)


dart entry point は app/lib/main.dart

![Run_Debug_Configurations.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/68302/297ad7dd-16c9-24e5-cf5f-c908327396a2.png)


Dart SDK Not found になる場合は、 Fix → Flutterプラグインの場所を指定  (Dart でなくてよい)

虫マークをクリックして起動

カウントアップのデモアプリが起動する。


## SQFEntity の組み込み

pubspeck.yaml に 追加

```yaml:pubspeck.yaml
dependencies:
  ...

  sqfentity: ^1.2.2+10
  sqfentity_gen: ^1.2.0+8

dev_dependencies:
  ...

  build_runner: ^1.6.5
  build_verify: ^1.1.0
```

インストール

```
flutter pub get
```

# モデルの作成

lib/models.dart を作成

```dart:lib/models.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sqfentity/sqfentity.dart';
import 'package:sqfentity_gen/sqfentity_gen.dart';

part 'models.g.dart';


@SqfEntityBuilder(todoDbModel)
const todoDbModel = SqfEntityModel(
    modelName: 'TodoDbModel', // optional
    databaseName: 'todo.db',
    databaseTables: [todo],
    bundledDatabasePath: null
);


const todo = SqfEntityTable(
    tableName: 'todo',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    fields: [
      SqfEntityField('title', DbType.text),
      SqfEntityField('active', DbType.bool, defaultValue: true),
    ]);
```

フィールドに、id (PK) と title を持つ、単純なモデルです。

(active というフィールドを作りましたがでもアプリ内では結局使いませんでした)


# コードの生成

```
flutter packages pub run build_runner build --delete-conflicting-outputs
```

このようなモデルを含むコードが生成されます

```dart:lib/models.g.dart
// BEGIN ENTITIES
// region Todo
class Todo {
  Todo({this.id, this.title, this.active, this.isDeleted}) {
    _setDefaultValues();
  }
  Todo.withFields(this.title, this.active, this.isDeleted) {
    _setDefaultValues();
  }
  Todo.withId(this.id, this.title, this.active, this.isDeleted) {
    _setDefaultValues();
  }
  Todo.fromMap(Map<String, dynamic> o) {
    id = o['id'] as int;
    title = o['title'] as String;
    active = o['active'] != null ? o['active'] == 1 : null;
    isDeleted = o['isDeleted'] != null ? o['isDeleted'] == 1 : null;
  }
  ...
```

## アプリに組み込む

### main.dart を修正

使用前に、initializeDB をコールします。

```
void main() async {
  final bool isInitialized = await MyDbModel().initializeDB();
  if (isInitialized == true) {
    runApp(MyApp());
  }
}
```

起動します。ログは、起動時に毎回出ます

```
Syncing files to device iPhone 7...
flutter: init() -> modelname: null, tableName:todo
flutter: >>>>>>>>>>>>>>>>>>>>>>>>>>>> SqfEntityTableBase of [todo](id) init() successfuly
flutter: todo.db created successfully
flutter: SQFENTITIY: Table named [todo] was initialized successfuly (created table)
flutter: SQFENTITIY: The database is ready for use
flutter: SQFENTITIY: Table named [todo] was initialized successfuly (No added new columns)
flutter: SQFENTITIY: The database is ready for use
```


### Insert

```dart
Todo(title: textEditingController.text, active: true).save();
```

リアクティブではないので、実施後手動でウィジェットのリビルドが必要そうです。

### Update

```dart
Todo(id: widget.todoId, title: textEditingController.text,
     active: true).save();
```

save() メソッドは、UPSERT として機能します

### Select


```dart
Todo().select().orderByDesc('id').toList()
```

空引数でクラスインスタンスを作ってから絞り込んでいきます。

戻り値はFuture ですので、単純にウィジェットに表示するだけなら、 FutureBuilder や StreamBuilder 使うと良さそうです。

### Delete

```dart
Todo().select().id.equals(widget.todoId).delete()
```

# スキーママイグレーション

models.dart を修正し、build_runner してアプリを再起動すれば、自動的に ALTER TABLE してくれる。データは消えない。


```
flutter: init() -> modelname: null, tableName:todo
flutter: >>>>>>>>>>>>>>>>>>>>>>>>>>>> SqfEntityTableBase of [todo](id) init() successfuly
flutter: SQFENTITIY: alterTableQuery => [ALTER TABLE todo ADD COLUMN created datetime]
flutter: SQFENTITIY: Table named [todo] was initialized successfuly (Added new columns)
flutter: SQFENTITIY: The database is ready for use
flutter: SQFENTITIY: Table named [todo] was initialized successfuly (No added new columns)
flutter: SQFENTITIY: The database is ready for use
```

その他、公式APIドキュメントに豊富な機能が紹介されています。

https://pub.dev/documentation/sqfentity/latest/
