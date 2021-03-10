import 'package:flutter/material.dart';
import 'package:flash_chat/constrants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;


class ChatScreen extends StatefulWidget {

  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try{
      final user =  _auth.currentUser;
      if(user!=null){
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e){
      print(e);
    }
  }
  
  // void getMessages() async{
  //   final messages = await _firestore.collection('messages').get();
  //   for(var msg in messages.docs){
  //     print(msg.data());
  //   }
  // }

  void messageStream() async{
   await for(var  snapshot in _firestore.collection('messages').snapshots()){
     for(var msg in snapshot.docs){
       print(msg.data());
     }
   }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: (){
              _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value){
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: (){
                      messageTextController.clear();
                      var now = DateTime.now().microsecondsSinceEpoch;
                      _firestore.collection('messages').doc(now.toString()).set({'text':messageText,'sender':loggedInUser.email});
                    },
                    child: Text(
                      "Send",
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot){
        if(snapshot.hasData){
          final messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageBubbles=[];
          for(var msg in messages){
            final messageText = msg.data()['text'];
            final messageSender = msg.data()['sender'];
            final currUser = loggedInUser.email;

            final messageBubble =MessageBubble(text: messageText,sender: messageSender,isMe: currUser==messageSender,);
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 20.0),
              children: messageBubbles,
            ),
          );
        }
        else{
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      },
    );
  }
}



class MessageBubble extends StatelessWidget {

  MessageBubble({this.sender,this.text, this.isMe});
  final String sender;
  final String text;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender,style: TextStyle(color: Colors.white70,fontSize: 12.0),),
          Material(
            elevation: 12.0,
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30.0),bottomLeft: Radius.circular(30.0),topRight: Radius.circular(30.0)):BorderRadius.only(topLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0),topRight: Radius.circular(30.0)),
            color: isMe ? Colors.green.shade900 : Colors.blueGrey,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0,horizontal: 22.0),
              child: Text(
                '$text',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


