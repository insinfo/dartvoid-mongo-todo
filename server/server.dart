import 'dart:io';
import 'dart:async';

import 'package:bloodless/server.dart' as app;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:di/di.dart';
import 'package:logging/logging.dart';

import '../client/web/lib/item.dart';

var logger = new Logger("todo");

class DbConnManager {

  String uri;

  DbConnManager(String this.uri);

  Future<Db> connect() {
    Db conn = new Db(uri);
    return conn.open().then((_) => conn);
  }

  void close(Db conn) {
    conn.close();
  }

}

@app.Interceptor(r'/.+', chainIdx: 0)
createConn(DbConnManager connManager) {
  connManager.connect().then((Db dbConn) {
    app.request.attributes['dbConn'] = dbConn;
    app.chain.next(() => connManager.close(dbConn));
  }).catchError((e) {
    app.chain.interrupt(statusCode: HttpStatus.INTERNAL_SERVER_ERROR, 
        response: {"error": "DATABASE_UNAVAILABLE"});
  });
}

// Show database content for debugging/testing purposes 
@app.Interceptor(r'/.+', chainIdx: 1)
debugItems() {
  app.chain.next(() {
    Db dbConn = (app.request.attributes['dbConn'] as Db);
    return printItems(dbConn);
  });
}

@app.Group("/todos")
class Todo {

  static const String collectionName = "items";

  @app.Route('/list')
  list(@app.Attr() Db dbConn) {
    logger.info("Returing all items");

    var itemsColl = dbConn.collection(collectionName);
      
    itemsColl.find().toList().then((List<Map> items) {
      logger.info("Found ${items.length} item(s)");
      
      return items;
    }).catchError((e) {
      logger.warning("Unable to find any items: $e");
      return [];
    });
  }

  @app.Route('/add', methods: const [app.POST])
  add(@app.Attr() Db dbConn, @app.Body(app.JSON) Map item) {
    logger.info("Adding new item");

    // Parse item to make sure only objects of type "Item" is accepted 
    var newItem = new Item.fromJson(item);

    // Add item to database 
    var itemsColl = dbConn.collection(collectionName);
      
    itemsColl.insert(newItem.toJson()).then((dbRes) {
      logger.info("Mongodb: $dbRes");
      
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to insert new item: $e");
      return "error";
    });
  }

  @app.Route('/update', methods: const [app.POST])
  update(@app.Attr() Db dbConn, @app.Body(app.JSON) Map item) {
    // Parse item to make sure only objects of type "Item" is accepted 
    var updatedItem = new Item.fromJson(item);
    
    logger.info("Updating item ${updatedItem.id}");
    
    // Update item in database
    var itemsColl = dbConn.collection(collectionName);
      
    itemsColl.update({"id": updatedItem.id}, updatedItem.toJson()).then((dbRes) {
      logger.info("Mongodb: ${dbRes}");
      
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to update item: $e");
      return "error";
    }); 
  }

  @app.Route('/delete/:id', methods: const [app.DELETE])
  delete(@app.Attr() Db dbConn, String id) {
    logger.info("Deleting item $id");
    
    // Remove item from database 
    var itemsColl = dbConn.collection(collectionName);
      
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
Future printItems(Db dbConn) {
  
  // Fetch all items from database and print to console 
  var itemsColl = dbConn.collection(Todo.collectionName);

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

  app.addModule(new Module()
      ..bind(DbConnManager, toValue: new DbConnManager(dbUri)));

  var portEnv = Platform.environment['PORT'];

  app.start(address: '127.0.0.1', 
            port: portEnv != null ? int.parse(portEnv) : 8080, 
            staticDir: null);

}