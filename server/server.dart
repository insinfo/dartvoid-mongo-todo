import 'dart:io';

import 'package:redstone/server.dart' as app;
import 'package:redstone_mapper/plugin.dart';
import 'package:redstone_mapper_mongo/manager.dart';
import 'package:redstone_mapper_mongo/service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'package:shelf_static/shelf_static.dart';

import 'package:client/client.dart' show Item;

// Setup application log
var logger = new Logger("todo");

@app.Group("/todos")
class Todo extends MongoDbService<Item>{
  
  Todo() : super("items");

  @app.Route('/list')
  @Encode()
  list() {
    logger.info("List items");
    return find().then((items) {
      logger.info("Found ${items.length} item(s)");
      return items;
    });
  }

  @app.Route('/add', methods: const [app.POST])
  add(@Decode() Item item) {
    logger.info("Add new item");
    
    var err = item.validate();
    if (err != null) {
      logger.info("Invalid item!");
      throw new app.ErrorResponse(400, err);
    }
    
    // Add item to database 
    return insert(item).then((dbRes) {
      logger.info("Mongodb: $dbRes");
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to insert new item: $e");
      return "error";
    });
  }

  @app.Route('/update', methods: const [app.PUT])
  updateStatus(@Decode() Item item) {
    // Parse item to make sure only objects of type "Item" is accepted 
    logger.info("Updating item ${item.id}");
    
    // Update item in database
    return update({"_id": ObjectId.parse(item.id)}, item).then((dbRes) {
      logger.info("Mongodb: ${dbRes}");
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to update item: $e");
      return "error";
    }); 
  }

  @app.Route('/delete/:id', methods: const [app.DELETE])
  delete(String id) {
    logger.info("Deleting item $id");
    
    // Remove item from database 
    return remove({"_id": ObjectId.parse(id)}).then((dbRes) {
      logger.info("Mongodb: $dbRes");
      return "ok";
    }).catchError((e) {
      logger.warning("Unable to update item: $e");
      return "error";
    });
  }

}

void main() {
  // Server port assignment
  var PORT = Platform.environment['PORT'];
  var appPort = PORT != null ? int.parse(PORT) : 8080;
  
  // Database endpoint assignment
  var MONGODB_URI = Platform.environment['MONGODB_URI'];  
  var appDB = MONGODB_URI != null ? MONGODB_URI : "mongodb://localhost/dartvoidtodo"; 
    
  // Set connection pool size
  var poolSize = 3;
  
  // Setup database connection manager
  var dbManager = new MongoDbManager(appDB, poolSize: poolSize);

  // Setup server log
  app.setupConsoleLog();
  
  // Install redstone_mapper
  app.addPlugin(getMapperPlugin(dbManager));

  // app.setShelfHandler(createStaticHandler("../client/build/web", 
  //                                         defaultDocument: "index.html", 
  //                                         serveFilesOutsidePath: true));
  
  // Start server
  app.start(address: '127.0.0.1', port: appPort);
}

