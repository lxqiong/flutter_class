import 'package:english_words/english_words.dart';

String GenerateCommand(){
  final wordPair = new WordPair.random();
  return wordPair.toString();
}

class keepAlive {
  int sessionId;
  String janus;
  String transaction;

  keepAlive(this.sessionId);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['janus'] = "keepalive";
    this.transaction=GenerateCommand();
    data['transaction'] = this.transaction;
    return data;
  }
}


class createSession {
  String transaction;

  createSession();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['janus'] ="create";
    this.transaction=GenerateCommand();
    data['transaction'] = this.transaction;
    return data;
  }
}

class pluginHandle {
  int sessionId;
  int handleId;
  int feedid;
  String plugin;
  String transaction;
  String mediatype;

  pluginHandle(this.sessionId,{this.mediatype,this.feedid});
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['janus'] = "attach";
    data['plugin'] = "janus.plugin.videoroom";
    this.transaction=GenerateCommand();
    data['transaction'] = this.transaction;
    return data;
  }
}

class CreateRoom {
  int sessionId;
  int handleId;
  String transaction;
  int room;

  CreateRoom(this.room, this.sessionId,  this.handleId);


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    final Map<String, dynamic> body = new Map<String, dynamic>();
    body['description'] = "flutter on line";
    body['request'] = "create";
    body['room'] = this.room;
    body['notify_joining'] = true;
    body['publishers'] = 4;
    body['bitrate'] = 4096000;
    body['bitrate_cap'] = true;
    this.transaction=GenerateCommand();
    data['session_id'] = this.sessionId;
    data['janus'] = "message";
    data['body'] = body;
    data['handle_id'] = this.handleId;
    data['transaction'] = this.transaction;
    return data;
  }
}



class JoinRoom {
  int sessionId;
  int handleId;
  String transaction;
  int roomid;
  String display;
  JoinRoom(this.roomid,this.sessionId,this.handleId,this.display);
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['janus'] = "message";

    final Map<String, dynamic> body = new Map<String, dynamic>();
    body['request'] = "join";
    body['room'] = this.roomid;
    body['ptype'] = "publisher";
    body['display'] = this.display;
    body['terminal'] = "web";
    data['body'] =body;
    data['handle_id'] = this.handleId;
    this.transaction=GenerateCommand();
    data['transaction'] = this.transaction;
    return data;
  }
}



class Subscribers {
  int sessionId;
  int handleId;
  String transaction;
  int roomid;
  int feedid;
  String mediatype;
  Subscribers(this.roomid,this.sessionId,this.handleId,this.feedid,this.mediatype){

  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['janus'] = "message";
    final Map<String, dynamic> body = new Map<String, dynamic>();
    body['request'] = "join";
    body['room'] = this.roomid;
    body['ptype'] = "subscriber";
    body['feed'] = this.feedid;
    body['mediatype'] = this.mediatype;
    data['body'] = body;
    data['handle_id'] = this.handleId;
    this.transaction=GenerateCommand();

    data['transaction'] = this.transaction;
    return data;
  }
}


class SubAnswer {
  int sessionId;
  int handleId;
  int roomid;
  String type;
  String sdp;
  String transaction;

  SubAnswer(this.sessionId,this.handleId,this.roomid,this.type,this.sdp);

  SubAnswer.fromJson(Map<String, dynamic> json) {

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['janus'] = "message";
    data['session_id'] = this.sessionId;
    data['handle_id'] = this.handleId;

    this.transaction=GenerateCommand();

    data['transaction'] = this.transaction;
    final Map<String, dynamic> body = new Map<String, dynamic>();
    body['request'] = "start";
    body['room'] = this.roomid;
    data['body'] = body;
    final Map<String, dynamic> jsep = new Map<String, dynamic>();
    jsep['sdp'] = this.sdp;
    jsep['type'] = this.type;
    data['jsep'] = jsep;

    return data;
  }
}

class publishMedia {
  String transaction;
  int handleId;
  int sesssionId;
  String media;
  String sdp;
  bool audio=false;
  bool video=false;
  bool screen=false;

  publishMedia(this.sesssionId,this.handleId,this.media, this.sdp){
    if(media=="audio") {
      this.audio=true;
      this.video=false;
      this.screen=false;
    }else {
      this.audio=false;
      this.video=true;
      this.screen=(media=="screen");
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sesssionId;
    data['janus'] = "message";
    final Map<String, dynamic> jsep = new Map<String, dynamic>();
    jsep['type'] = "offer";
    jsep['sdp'] = this.sdp;
    data['jsep'] = jsep;
    final Map<String, dynamic> body = new Map<String, dynamic>();
    body['request'] = "configure";
    body['video'] = this.video;
    body['audio'] = this.audio;
    body['screen'] = this.screen;
    data['body'] = body;
    this.transaction=GenerateCommand();
    data['transaction'] = this.transaction;
    data['handle_id'] = this.handleId;
    return data;
  }
}


class Leaver {

  int sessionId;
  int handleId;
  String transaction;

  Leaver(this.sessionId,this.handleId);



  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['janus'] = "message";
    data['session_id'] = this.sessionId;
    data['handle_id'] = this.handleId;

    this.transaction=GenerateCommand();

    data['transaction'] = this.transaction;
    final Map<String, dynamic> leaverbody = new Map<String, dynamic>();
    leaverbody['request'] = "leave";
    data['body'] = leaverbody;

    return data;
  }
}



class unPublish {
  int sessionId,handleId;
  String transaction;
  String mediatype;
  unPublish(this.sessionId,this.handleId, this.mediatype);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['janus'] = "message";
    data['session_id'] = this.sessionId;
    data['handle_id'] = this.handleId;

    this.transaction=GenerateCommand();

    data['transaction'] = this.transaction;
    final Map<String, dynamic> unbody = new Map<String, dynamic>();
    unbody['request'] = "unpublish";
    data['body'] =unbody;

    return data;
  }
}



class mute {
  String transaction;
  bool bmute;
  int sessionId;
  int handleId;

  mute(this.sessionId,this.handleId,this.bmute);



  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['janus'] = "message";
    data['session_id'] = this.sessionId;
    data['handle_id'] = this.handleId;

    this.transaction=GenerateCommand();

    data['transaction'] = this.transaction;

    final Map<String, dynamic> muteBody = new Map<String, dynamic>();
    String request="muteAudio";
    if(this.bmute){
      request="muteAudio";
    }
    else {
      request="unmuteAudio";
    }

    muteBody['request'] = request;
    data['body'] = muteBody;

    return data;
  }
}




