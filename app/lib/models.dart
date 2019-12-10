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
