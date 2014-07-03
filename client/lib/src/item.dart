part of client;

class Item extends Schema {
  
  @Id()
  String id;
  
  @Field()
  @NotEmpty()
  String text;
  
  @Field()
  bool done;
  
  @Field()
  bool archived;
  
  Item([this.id, this.text = "", this.done = false, this.archived = false]);
  
}

