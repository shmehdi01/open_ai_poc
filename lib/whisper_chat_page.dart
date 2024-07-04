import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_ai_test/audio_player.dart';
import 'package:open_ai_test/recorder.dart';
import 'package:open_ai_test/silence_detector.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_model.dart';
import 'type_animation.dart';

class WishperChatPage extends StatefulWidget {
  final bool speech;
  const WishperChatPage({super.key, this.speech  =false});

  @override
  State<WishperChatPage> createState() => _WishperChatPageState();
}

class _WishperChatPageState extends State<WishperChatPage> {
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
            Text("If current amplitude is less more than ${RecorderState.kSilenceThreshold}, it is silence", style: TextStyle(
              fontSize: 12
            ),),
            Expanded(
              child: chatList(),
            ),
            SizedBox(
              height: 110,
              child: Recorder(onStop: (path) {
                final file = File(path);
             _handleTapSend(file);
              }),
            ),
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

        if (chat is AnalyzingAudio) {
          return Text("Analyzing Audio...", style: TextStyle(fontSize: 12),);
        }


        bool isLast = index == _chatModels.length-1;

        return SizedBox(
          //color: Colors.redAccent,
          width: MediaQuery.sizeOf(context).width,
          child: Align(
            alignment:
                chat.isSendByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: chat.isSendByMe ? color : Colors.white,
              ),
              child: chat.isSendByMe
                  ? Text(chat.message)
                  : chat is WishperChat ? AudioPlayer(source: chat.file.path, onDelete: (){}, autoPlay: isLast,) : AnimatedTextKit(
                      animatedTexts: [
                        TyperAnimatedText(chat.message),
                      ],
                      totalRepeatCount: 1,
                    ),
            ),
          ),
        );
      },
      itemCount: _chatModels.length,
    );
  }


  void _handleTapSend(File file) async {
    // final text = _textEditingController.text.trim();
    // if (text.isEmpty) {
    //   return;
    // }
    // ByteData data = await rootBundle.load("assets/hey.mp3");
    // List<int> bytes =
    //     data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    //print("BYTES $bytes");

    // Directory tempDir = await getApplicationSupportDirectory();
    // String tempPath = tempDir.path;
    //
    // final file = await File(tempPath + "/hey.mp3").writeAsBytes(bytes);

    //_textEditingController.clear();
    
    _sendRequest(file);
    setState(() {});
  }

  _sendRequest(File file) async {
    // the user message that will be sent to the request.

    final analyzing = AnalyzingAudio.get();
    _chatModels.add(analyzing);
    setState(() {

    });
    OpenAIAudioModel transcription =
        await OpenAI.instance.audio.createTranscription(
      file: file,
      model: "whisper-1",
      responseFormat: OpenAIAudioResponseFormat.json,
    );

    if (transcription.text.isEmpty) {
      print("No transscript");
      _chatModels.add(ChatModel.newText("Did not detected Audio"));
      return;
    }

    _chatModels.add(ChatModel.newText(transcription.text));

    print("TRANS: ${transcription.text}");

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          transcription.text,
        ),

        // //! image url contents are allowed only for models with image support such gpt-4.
        // OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
        //   "https://placehold.co/600x400",
        // ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final loader =LoaderChat.get();
    _chatModels.remove(analyzing);
    _chatModels.add(loader);
    setState(() {

    });
  final chatCompletion = await OpenAI.instance.chat
        .create(
      model: "gpt-4o",
      //responseFormat: {"type": "json_object"},
      seed: 6,
      messages: [userMessage],
      temperature: 0.2,
      maxTokens: 40,
    );


    chatCompletion.choices.first.message.content?.forEach((element) async{

      if (element.text != null) {
        _chatModels.remove(loader);

        if (widget.speech) {
          final file = await _createSpeech(element.text!);
          _chatModels.add(WishperChat(element.text!, false, DateTime.now(), file: file));
        }
        else {
          _chatModels.add(ChatModel.fromResponse(element.text ?? ''));
        }
        setState(() {});
        _scrollDown();

      }
    });

  }

  void _scrollDown() {
    //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    if (_scrollController.positions.isEmpty) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300,
      duration: const Duration(
        milliseconds: 200,
      ),
      curve: Curves.easeInOut,
    );
  }

  Future<File> _createSpeech(String text) async{
    File speechFile = await OpenAI.instance.audio.createSpeech(
        model: "tts-1",
        input: text,
        voice: "echo",
        responseFormat: OpenAIAudioSpeechResponseFormat.mp3,
        outputDirectory: await getApplicationDocumentsDirectory(),
        outputFileName: "syed",
    );

    return speechFile;
  }
}
