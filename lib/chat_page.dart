import 'dart:developer';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:open_ai_test/type_animation.dart';

import 'chat_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatModel> _chatModels = [];
  final TextEditingController _textEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    // OpenAI.instance.model.list().then((value) {
    //   value.forEach((element) {
    //      print(element.id);
    //   });
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat GPT"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: chatList(),
            ),
            textField(),
          ],
        ),
      ),
    );
  }

  Widget chatList() {
    final color = Theme.of(context).primaryColor.withOpacity(.1);
    return ListView.builder(
      itemBuilder: (_, index) {
        final chat = _chatModels[index];

        if (chat is LoaderChat) {
          return Align(
            alignment: Alignment.bottomLeft,
            child: TypingIndicator(
              bubbleColor: Theme.of(context).secondaryHeaderColor,
              flashingCircleBrightColor: Theme.of(context).primaryColor,
              flashingCircleDarkColor: Theme.of(context).primaryColorDark,
              showIndicator: true,
            ),
          );
        }

        return SizedBox(
          //color: Colors.redAccent,
          width: MediaQuery.sizeOf(context).width,
          child: Align(
            alignment: chat.isSendByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: chat.isSendByMe ? color : Colors.white,
              ),
              child:  chat.isSendByMe ? Text(chat.message) : AnimatedTextKit(animatedTexts: [
                TyperAnimatedText(chat.message),
              ], totalRepeatCount: 1,),
            ),
          ),
        );
      },
      itemCount: _chatModels.length,
    );
  }

  Widget textField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textEditingController,
            decoration: InputDecoration(
                hintText: 'Enter a message', border: OutlineInputBorder()),
          ),
        ),
        IconButton(
          onPressed: _handleTapSend,
          icon: const Icon(Icons.send),
        )
      ],
    );
  }

  void _handleTapSend() {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _textEditingController.clear();
    _chatModels.add(ChatModel.newText(text));
    _sendRequest(text);
    setState(() {});
  }

  _sendRequest(String message) async {

    // the user message that will be sent to the request.
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          message,
        ),

        // //! image url contents are allowed only for models with image support such gpt-4.
        // OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
        //   "https://placehold.co/600x400",
        // ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final loader =LoaderChat.get();
     _chatModels.add(loader);
     setState(() {

     });
     OpenAI.instance.chat.create(
      model: "gpt-4o",
      //responseFormat: {"type": "json_object"},
      seed: 6,
      messages: [
        userMessage
      ],
      temperature: 0.2,
      maxTokens: 40,

    ).then((chatCompletion) {
      _chatModels.remove(loader);
       chatCompletion.choices.first.message.content?.forEach((element) {
         if (element.text != null) {
           _chatModels.add(ChatModel.fromResponse(element.text ?? ''));
         }
       });
     }).whenComplete(() {
        setState(() {

        });
        _scrollDown();

     });
      //    .listen((chatCompletion) {
      // print(chatCompletion);
      // String s = "";
      // chatCompletion.choices.first.delta.content?.forEach((element) {
      //   if (element?.text != null) {
      //     s+="${element?.text} ";
      //     //_chatModels.add(ChatModel.fromResponse(element!.text!))
      //   }
      // });
      // if (s.isNotEmpty) {
      //   _chatModels.add(ChatModel.fromResponse(s));
      //   // setState(() {
      //   //
      //   // });
      //   // _scrollDown();
      // }
      //log(chatCompletion.choices.first.message.content.first.text, name: 'Choices');


   // });


    // ...




  }

  void _scrollDown() {
    //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    if (_scrollController.positions.isEmpty) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent+300,
      duration: const Duration(
        milliseconds: 200,
      ),
      curve: Curves.easeInOut,
    );
  }
}
