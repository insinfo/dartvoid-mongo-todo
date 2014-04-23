import 'dart:async';
import 'package:vane/vane.dart';
import '../client/web/lib/item.dart';

class Todo extends Vane {
  /// Setup middleware handlers that should run 
  init() {
    // Log requests to console for debugging (run pre/before handler function)
    pre.add(new Log());
    
    // Enable Cors for easier local development (run pre/before handler function)
    // Note: You also need to change the urls in client/web/backend.dart if 
    // you want to run the app with cors locally  
//    pre.add(new Cors());
  }
  
  /// Get all items in list 
  Future getAll() {
    log.info("Returing all items");
    
    mongodb.then((mongodb) {
      var itemsColl = mongodb.collection("items");
      
      itemsColl.find().toList().then((List<Map> items) {
        log.info("Found ${items.length} item(s)");
        
        // Show database content for debugging/testing purposes 
        printItems();
        
        close(items);
      }).catchError((e) {
        log.warning("Unable to find any items: ${e}");
        close(new List());
      });
    }).catchError((e) {
      log.warning("Unable to find any items: ${e}");
      close(new List());
    });

    return end;
  }
  
  /// Add a new item 
  Future add() {
    log.info("Adding new item");

    // Parse item to make sure only objects of type "Item" is accepted 
    var newItem = new Item.fromJson(json);
    
    // Add item to database 
    mongodb.then((mongodb) {
      var itemsColl = mongodb.collection("items");
      
      itemsColl.insert(newItem.toJson()).then((dbRes) {
        log.info("Mongodb: ${dbRes}");
        
        // Show database content for debugging/testing purposes 
        printItems();
        
        close("ok");
      }).catchError((e) {
        log.warning("Unable to insert new item: ${e}");
        close("error");
      });
    }).catchError((e) {
      log.warning("Unable to insert new item: ${e}");
      close("error");
    });
    
    return end;
  }

  /// Update existing item 
  Future update() {
    // Parse item to make sure only objects of type "Item" is accepted 
    var updatedItem = new Item.fromJson(json);
    
    log.info("Updating item ${updatedItem.id}");
    
    // Add item to database 
    mongodb.then((mongodb) {
      var itemsColl = mongodb.collection("items");
      
      itemsColl.update({"id": updatedItem.id}, updatedItem.toJson()).then((dbRes) {
        log.info("Mongodb: ${dbRes}");
        
        // Show database content for debugging/testing purposes 
        printItems();
        
        close("ok");
      }).catchError((e) {
        log.warning("Unable to update item: ${e}");
        close("error");
      });
    }).catchError((e) {
      log.warning("Unable to update item: ${e}");
      close("error");
    });
    
    return end;
  }
  
  /// Delete item from list 
  Future delete() {
    log.info("Deleting item ${path[1]}");
    
    // Add item to database 
    mongodb.then((mongodb) {
      var itemsColl = mongodb.collection("items");
      
      itemsColl.remove({"id": path[1]}).then((dbRes) {
        log.info("Mongodb: ${dbRes}");
        
        // Show database content for debugging/testing purposes 
        printItems();
        
        close("ok");
      }).catchError((e) {
        log.warning("Unable to update item: ${e}");
        close("error");
      });
    }).catchError((e) {
      log.warning("Unable to update item: ${e}");
      close("error");
    });
    
    return end;
  }
  
  /// Helper function printing all content of the database collection   
  void printItems() {
    
    // Fetch all items from database and print to console 
    mongodb.then((mongodb) {
      var itemsColl = mongodb.collection("items");

      itemsColl.find().toList().then((List<Map> items) {
        print("Todo items in the database:");
        for(var i = 0; i < items.length; i++) {
          print(' ${i+1}. ${items[i]["text"]}, done = ${items[i]["done"]}');
        }
        print("");
      });
    });
  }
}

