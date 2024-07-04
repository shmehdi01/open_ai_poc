import 'dart:io';

class ChatModel {
  final String message;
  final bool isSendByMe;
  final DateTime dateTime;

  ChatModel(this.message, this.isSendByMe, this.dateTime);

  factory ChatModel.newText(String message) {
    return ChatModel(message, true, DateTime.now());
  }

  factory ChatModel.fromResponse(String message) {
    return ChatModel(message, false, DateTime.now());
  }
}


class WishperChat extends ChatModel {
  final File file;
  WishperChat(super.message, super.isSendByMe, super.dateTime, {required this.file});

  factory WishperChat.newChat(File file) {
    return WishperChat('Audio', true, DateTime.now(), file: file);
  }

}

class LoaderChat extends ChatModel {
  LoaderChat(super.message, super.isSendByMe, super.dateTime);

  factory LoaderChat.get() {
    return LoaderChat('', false, DateTime.now());
  }
}

class AnalyzingAudio extends ChatModel {
  AnalyzingAudio(super.message, super.isSendByMe, super.dateTime);

  factory AnalyzingAudio.get() {
    return AnalyzingAudio('', false, DateTime.now());
  }
}
