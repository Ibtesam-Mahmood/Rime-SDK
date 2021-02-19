

///OrderedMap is a data structure that organizes the contnents of a map in a FIFO structure
///Each element is doubly linked and can access the element before and after it 
///allows for O(1) retreval of next and previous element items. 
///This is made possible due to the `QueueNode`
class OrderedMap<S, T>{

  ///The map of elements
  final Map<S, OrderedMapNode<S, T>> _map = {};

  ///The first elemnt
  S _first;

  //Default constructor
  OrderedMap();

  ///Creates a queue map by itterating through a list in a map
  factory OrderedMap.from(Map<S, T> map){
    if(map == null || map.isEmpty) return OrderedMap();
    
    OrderedMap qm = OrderedMap();

    //populates queuemap
    for(S key in map.keys) {qm.add(key, map[key]);}

    return qm;
  }

  ///Add an element to the end of the list
  void add(S key, T value, [bool override = false]) => insert(length, key, value, override);

  ///Inserts an element at an index, if override is true, the element at the old refrence key is replaced
  void insert(int index, S key, T value, [bool override = false]){

    assert(index >= 0);

    //If element with key exsists thorow erro if ovveride isnt true
    if(nodeAt(key) != null && !override){
      throw('Element with key already exsists');
    }

    //New node
    OrderedMapNode<S, T> newNode = OrderedMapNode(key, value);
    
    if(length == 0){
      //First addition
      _first = newNode.key;
    }
    else if(index >= length){
      //Add to the end
      OrderedMapNode<S, T> lastNode = last;
      lastNode.next = newNode;
      newNode.previous = lastNode;
    }
    else if(index == 0){
      //Add at the start of the list
      OrderedMapNode<S, T> firstNode = first;
      firstNode.previous = newNode;
      newNode.next = firstNode;
      _first = newNode.key;
    }
    else{
      //Add to the middle

      //Node at the current index
      OrderedMapNode<S, T> currentNode = nodeAt(index);
      //Next node
      OrderedMapNode<S, T> prevNode = currentNode?.previous;

      newNode.next = currentNode;
      newNode.previous = prevNode;

      currentNode.previous = newNode;
      prevNode.next = newNode;

    }

    if(nodeAt(key) != null){
      //Remove old item
      remove(key);
    }
    
    //Add item
    _map[key] = newNode;

  }

  ///Removes a node by the key
  OrderedMapNode<S, T> remove(S key){
    
    //Retreives the current node
    OrderedMapNode<S, T> currentNode = nodeAt(key);

    //Nothing to remove
    if(currentNode == null) return null;

    //Retreives the next and previous nodes
    OrderedMapNode<S, T> previousNode = currentNode.previous;
    OrderedMapNode<S, T> nextNode = currentNode.next;

    previousNode?.next = nextNode;
    nextNode?.previous = previousNode;

    //Current node is first node, set next node to first node
    if(currentNode.key == _first) _first = nextNode.key;

    //Remove from map
    _map.remove(key);

    //Return object
    return currentNode;

  }

  ///Returns the index of a key element
  int indexOf(S key){

    OrderedMapNode<S, T> current = first;
    int count = 0;

    while(current != null){
      
      if(current.key == key) return count;

      count++;
      current = current.next;

    }

    //Index not found
    return -1;

  }
  
  ///Retreive in indexed elemtn from the list
  OrderedMapNode<S, T> elementAt(int index){

    assert(index >= 0);

    int count = 0;
    OrderedMapNode<S, T> selected = first;
    while(selected != null && count != index){
      //Set elemnt and increment counter
      selected = selected.next;
      count++;
    }

    return selected;
  }

  ///Returns the queuenode refrenced by the key or index
  OrderedMapNode<S, T> nodeAt(dynamic index){
    if(index is S)
      {return _map[index];}
    else if(index is int)
      {return elementAt(index);}
    else
      {throw('Index index type error. The provided index is not the same type as the Key, or an int.');}
  }

  ///Returns the elemnt refrenced by the key or index
  T operator[](dynamic index) => nodeAt(index).value;

  ///Sets a queue node at a key, or inserts a new element at the end
  void operator[]= (S key, T value){
    if(this[key] != null){
      //Update old item
      _map[key].value = value;
    }
    else{
      //Add item
      add(key, value, true);
    }
  }

  ///Length of the list
  int get length => _map.length;

  ///If the orderedmap is empty
  bool get isEmpty => length == 0;

  ///If the ordered map is not empty
  bool get isNotEmpty => length > 0;

  ///The first element in the list
  OrderedMapNode<S, T> get first => _first == null ? null : _map[_first];

  OrderedMapNode<S, T> get last => nodeAt(length - 1);

}

///Internal data structure within the QueueMap, used to create a Doubley Linked List
class OrderedMapNode<S, T> {

  final S key;
  T value;
  OrderedMapNode<S, T> previous;
  OrderedMapNode<S, T> next;

  OrderedMapNode(this.key, this.value, {this.previous, this.next}) : assert(key != null);
  
  bool get hasNext => next != null;
  bool get hasPrev => previous != null;

}