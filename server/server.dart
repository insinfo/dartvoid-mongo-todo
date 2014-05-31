import 'dart:io';
import 'dart:async';

import 'package:redstone/server.dart' as app;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connection_pool/connection_pool.dart';
import 'package:di/di.dart';
import 'package:logging/logging.dart';

import '../client/web/lib/item.dart';

var logger = new Logger("todo");

class MongoDbPool extends ConnectionPool<Db> {

  String uri;

  MongoDbPool(String this.uri, int poolSize) : super(poolSize);

  @override
  void closeConnection(Db conn) {
    conn.close();
  }

  @override
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}

@app.Interceptor(r'/services/.+', chainIdx: 0)
dbInterceptor(MongoDbPool pool) {
  pool.getConnection().then((managedConnection) {
    app.request.attributes["conn"] = managedConnection.conn;
    app.chain.next(() {
      if (app.chain.error is ConnectionException) {
        pool.releaseConnection(managedConnection, markAsInvalid: true);
      } else {
        pool.releaseConnection(managedConnection);
      }
    });
  });
}

// Show database content for debugging/testing purposes 
@app.Interceptor(r'/.+', chainIdx: 1)
debugItems() {
  app.chain.next(() {
    Db conn = (app.request.attributes['conn'] as Db);
    return printItems(conn);
  });
}

@app.Group("/todos")
class Todo {

  static const String collectionName = "items";

  @app.Route('/list')
  list(@app.Attr() Db conn) {
    logger.info("Returing all items");

    var itemsColl = conn.collection(collectionName);
      
    itemsColl.find().toList().then((List<Map> items) {
      logger.info("Found ${items.length} item(s)");
      
      return items;
    }).catchError((e) {
      logger.warning("Unable to find any items: $e");
      return [];
    });
  }

  @app.Route('/add', methods: const [app.POST])
  add(@app.Attr() Db conn, @app.Body(app.JSON) Map item) {
    logger.info("Adding new item");

    // Parse item to make sure only objects of type "Item" is accepted 
    var newItem = new Item.fromJson(item);

    // Add item to database 
    var itemsColl = conn.collection(collectionName);
      
    itemsColl.insert(newItem.toJson()).then((dbRes) {
      logger.info("Mongodb: $dbRes");
      
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to insert new item: $e");
      return "error";
    });
  }

  @app.Route('/update', methods: const [app.POST])
  update(@app.Attr() Db conn, @app.Body(app.JSON) Map item) {
    // Parse item to make sure only objects of type "Item" is accepted 
    var updatedItem = new Item.fromJson(item);
    
    logger.info("Updating item ${updatedItem.id}");
    
    // Update item in database
    var itemsColl = conn.collection(collectionName);
      
    itemsColl.update({"id": updatedItem.id}, updatedItem.toJson()).then((dbRes) {
      logger.info("Mongodb: ${dbRes}");
      
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to update item: $e");
      return "error";
    }); 
  }

  @app.Route('/delete/:id', methods: const [app.DELETE])
  delete(@app.Attr() Db conn, String id) {
    logger.info("Deleting item $id");
    
    // Remove item from database 
    var itemsColl = conn.collection(collectionName);
      
    itemsColl.remove({"id": id}).then((dbRes) {
      logger.info("Mongodb: $dbRes");
      
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to update item: $e");
      return "error";
    });
  }

}

/// Helper function printing all content of the database collection   
Future printItems(Db conn) {
  
  // Fetch all items from database and print to console 
  var itemsColl = conn.collection(Todo.collectionName);

  return itemsColl.find().toList().then((List<Map> items) {
    print("Todo items in the database:");
    for(var i = 0; i < items.length; i++) {
      print(' ${i+1}. ${items[i]["text"]}, done = ${items[i]["done"]}');
    }
    print("");
  });
}

main() {

  app.setupConsoleLog();

  var dbUri = Platform.environment['MONGODB_URI'];
  if (dbUri == null) {
    dbUri = "mongodb://localhost/todo";
  }

  var poolSize = 3;

  app.addModule(new Module()
      ..bind(MongoDbPool, toValue: new MongoDbPool(dbUri, poolSize)));

  var portEnv = Platform.environment['PORT'];

  app.start(address: '127.0.0.1', 
            port: portEnv != null ? int.parse(portEnv) : 8080);

}