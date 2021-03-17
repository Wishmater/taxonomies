import 'package:moor/moor_web.dart';

getPlatformDatabase(dynamic file, dynamic data){
  return WebDatabase('main.db', initializer: () async => data,);
}