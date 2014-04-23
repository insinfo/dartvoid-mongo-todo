# Todo Demo build with Vane+Angular+Rest+Mongo 

This is an example Todo app that uses:
* AngularDart as a client side framework.
* Vane as a server side framework.
* Pure for CSS.
* Mongodb as a database for persistent storage of todo items.
* A REST interface to communicate between server and client.  

### AngularDart
AngularDart handles things like binding variables and classes directly to the 
UI and makes it possible to easily generate HTML in loops. In this example you
can for example see how we generate the items list with a loop at row 42 in
index.html. The loop is created with the Angular statment "ng-repeat". When you 
update a new item the values is read directly into an object with Angular's 
help and that data is later sent to the rest backend.

### Vane
Vane handles the server side part of the REST interface. The code in 
"client/web/items_backend.dart", "server/todo.dart" and some routing declarations 
in "app.yaml" make up the REST interface. A class called Todo is created by 
extending Vane. Then it's different handler functions are mapped to REST actions 
via the app.yaml declarations. The Vane class is in turn served by a Dart http
server generated with the http_server package (auto generated based on app.yaml). 

Inside the Todo handler functions a Mongodb database is accessed^1. Vane provides 
a database session/connection manager that makes sure that you can reuse your 
database connections for better performance and it also makes sure that unused 
connections are closed after enough time without any use. The top level "mongodb" 
getter returns a ready to use mongodb object connected to the database powered 
by the [mongo_dart package](http://pub.dartlang.org/packages/mongo_dart). 

^1 All apps on DartVoid automatically get their own Nginx instance, Dapp instance 
(Dart Application Server that runs your auto generated dart http_server or a 
server.dart file you provide) and a Mongodb database.

### Mongodb 
Mongodb is used store the data. To store items in the todo list an Item class 
is used. The item class can be found in "client/web/lib/item.dart". The class is 
shared by both the server and client side code and contains functions to convert
it to and from the json format. Mongodb use json as it's storage format, so 
adding and quering from the database becomes very easy. In this example we 
use a uniqe id that we create with the [uuid package](http://pub.dartlang.org/packages/uuid) to query for each item. 
### Pure CSS
To make it easier to create a resizeble grid we use the Pure CSS library developed 
by people at Yahoo. Pure CSS is CSS only so there is no difference in using it for 
Dart compared to JavaScript. 

### REST interface
The REST interface is built with these three files:
 * client/web/items_backend.dart
 * server/todo.dart
 * app.yaml
 
## Try it out 
The easiest way to try out this demo is to login to your [DartVoid account](manage.dartvoid.com) ([you need to signup first](http://www.dartvoid.com/)) and then choose this repo from the template list in the create view. Or you can fork/clone the repo here on Github and then choose it from your list of Dart repos, also in the create view. 

## Questions or suggestions?
If you have any questions or suggestions don't hesitate to contact us. The easiest way to reach us or to ask questions is on:
* [Our Beta HipChat Channel](http://www.hipchat.com/gdLik3cWq) (no account required)
* [Our Google Plus community](https://plus.google.com/u/1/communities/115539998363448858988)
* [Or on email](http://www.dartvoid.com/about/)

You can also send a pull request if you have any suggestion on how to improve the code!

## Links

#### AngularDart Links 
* https://angulardart.org/
* https://github.com/angular/angular.dart 

#### Vane Links 
* http://dartvoid.com/vane
* https://github.com/DartVoid/Vane

#### Pure CSS Links 
* http://purecss.io/ 
* https://github.com/yui/pure/

#### Mongodb Links  
* https://www.mongodb.org/
* https://github.com/mongodb/mongo
* http://pub.dartlang.org/packages/mongo_dart

#### REST Links  
* http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm

## Credits
This demo is loosly based on the todo demo from the Angular Dart repository 
that can be found [here](https://github.com/angular/angular.dart/blob/master/example).

