

//import 'package:english_words/english_words.dart';
import 'dart:convert' as convert;
import 'package:flutter_class/command.dart';

int sessionid=0;
int mainhandle=0;
int audiohandle=0;
int videohandle=0;
int screenhandle=0;

enum SucessSeq{
  none,
  sessionSeq,
  mainhanleSeq,
  audiohandleSeq,
  videohandleSeq,
  screenhandleSeq,
  subscriberhandleSeq,
  createroomSeq,

}

enum EventSeq{
  none,
  ejoinSeq,
  esubmediaseq,
  epubmediaseq,

}

abstract class JsonHandle{
  void OnError(int error);
  SucessSeq OnSuccess(String json);
  EventSeq OnEvent(String json);
  String GetTransaction();
  String GetJsonString();
}

class JanusSession implements JsonHandle{
  createSession jsession;

  JanusSession(){
    jsession = createSession();
    sessionid = 0;
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("data")){
      Map<String,dynamic> ids = itemvalues["data"];
      if(ids.containsKey("id")){
        sessionid = ids["id"];
        print("session id ${sessionid}");
        mainhandle =0;
        audiohandle= 0;
        videohandle=0;
        screenhandle =0;
        return SucessSeq.sessionSeq;
      }
    }
    return SucessSeq.none;
  }
  EventSeq OnEvent(String json){
    return EventSeq.none;
  }
  String GetTransaction(){
    return jsession.transaction;
  }
  String GetJsonString() {
    return  convert.jsonEncode(jsession.toJson()) ;
  }
}

class KeepHandle implements JsonHandle{

  keepAlive alive;
  KeepHandle(){
    alive = keepAlive(sessionid);
  }
  SucessSeq OnSuccess(String jsonvalue){}
  void OnError(int error) {}
  EventSeq OnEvent(String json){
    return EventSeq.none;
  }
  String GetTransaction(){
    return alive.transaction;
  }
  String GetJsonString() {
    return  convert.jsonEncode(alive.toJson()) ;
  }

}


class JanusPlugin implements JsonHandle{
  pluginHandle pluginhandle;
  String mediatype;
  int feedid;

  JanusPlugin({this.mediatype,this.feedid}){
    pluginhandle = pluginHandle(sessionid,mediatype: this.mediatype,feedid: this.feedid);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("data")){
      Map<String,dynamic> ids = itemvalues["data"];
      if(ids.containsKey("id")){
        if(mainhandle==0){
          mainhandle=ids["id"];
          print("mainhanle:${mainhandle}");
          return SucessSeq.mainhanleSeq;
        }else if(audiohandle==0){
          audiohandle=ids["id"];
          print("audiohandle:${audiohandle}");
          return SucessSeq.audiohandleSeq;
        }
        else if(videohandle==0){
          videohandle=ids["id"];
          print("videohandle:${videohandle}");
          return SucessSeq.videohandleSeq;
        }
        else if(screenhandle==0){
          screenhandle=ids["id"];
          print("screenhandle:${screenhandle}");
          return SucessSeq.screenhandleSeq;
        }else {
          int subhanle=ids["id"];
          print("subscriber:${subhanle}");
          pluginhandle.handleId = subhanle;
          return SucessSeq.subscriberhandleSeq;
        }
      }
    }
    return SucessSeq.none;
  }
  EventSeq OnEvent(String json){
    return EventSeq.none;
  }
  String GetTransaction(){
    return pluginhandle.transaction;
  }
  String GetJsonString() {
    return  convert.jsonEncode(pluginhandle.toJson()) ;
  }
}



class CreteRoomHandle implements JsonHandle{
  CreateRoom roomhandle;
  int roomid;

  CreteRoomHandle(int room){
    this.roomid = room;
    roomhandle = CreateRoom(room,sessionid,mainhandle);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("plugindata")){
      Map<String,dynamic> datas = itemvalues["plugindata"];
      if(datas.containsKey("data")){
        Map<String,dynamic> data =datas["data"];
        if(data.containsKey("videoroom")){
          String create =data["videoroom"];
          print("create room ${create=="created"}");
          return SucessSeq.createroomSeq;
        }
      }
    }
    return SucessSeq.none;
  }
  EventSeq OnEvent(String json){
    return EventSeq.none;
  }

  String GetTransaction(){
    return roomhandle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(roomhandle.toJson()) ;
  }
}





class JoinRoomHandle implements JsonHandle{
  JoinRoom joinhandle;
  int roomid;
  int selfid;
  String display_name;
  Map<int,JanusPublisher> roomMembers;
  List<JanusPublisher> publisherMembers;

  JoinRoomHandle(int room,String display){
    this.roomid = room;
    this.display_name = display;
    roomMembers = new Map<int,JanusPublisher>();
    publisherMembers = new List<JanusPublisher>();
    joinhandle = JoinRoom(room,sessionid,mainhandle,display);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("plugindata")){
      Map<String,dynamic> datas = itemvalues["plugindata"];
      if(datas.containsKey("data")){
        Map<String,dynamic> data =datas["data"];
        if(data.containsKey("videoroom")){
          String joined =data["videoroom"];
          print("joined room ${joined=="joined"}");
          if(joined=="joined"){
            List<dynamic> items = data["list"];
            items.forEach((element) {
              print(element['id']);
            });
          }
        }
      }
    }
    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("plugindata")){
      Map<String,dynamic> datas = itemvalues["plugindata"];
      if(datas.containsKey("data")){
        Map<String,dynamic> data =datas["data"];
        if(data.containsKey("error_code")){
          int joined =data["error_code"];
          print("joined room ${joined}");
          return EventSeq.none;
        }else if( data.containsKey("videoroom")){
          String joined =data["videoroom"];
          print("joined room ${joined=="joined"}");
          if(joined=="joined"){
            List<dynamic> list_items = data["list"];
            selfid = data["id"];
            list_items.forEach((element) {
              print("list:id:${element['id']},display:${element['display']}");
              JanusPublisher publisher;
              if(roomMembers.containsKey(element['id'])){
                publisher = roomMembers[element['id']];
              }else{
                publisher = new JanusPublisher(element['id'],element['display'], terminal:element['terminal']);
                publisher.is_audio = !element['muteaudio'];
                publisher.is_video = !element['mutevideo'];
                publisher.is_screen = element['screenshare'];
                roomMembers[element['id']] = publisher;
              }

            });
            List<dynamic> publish_items = data["publishers"];
            publish_items.forEach((element) {
              print("publisher:id:${element['id']},display:${element['display']},mediatype:${element['mediatype']}");
              var pub = new JanusPublisher(element['id'],element['display'],media_type:element['mediatype']);
              publisherMembers.add(pub);
            });
            return EventSeq.ejoinSeq;
          }
        }
      }
    }
    return EventSeq.none;

  }

  String GetTransaction(){
    return joinhandle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(joinhandle.toJson()) ;
  }
}

class JanusPublisher{
  int userid;
  bool is_audio;
  bool is_video;
  bool is_screen;
  String terminal;
  String display_name;
  String media_type;
  JanusPublisher(this.userid,this.display_name,{this.terminal,this.media_type}){

  }

}



class SubscriberMedia implements JsonHandle{
  Subscribers subhandle;
  int roomid;
  int feedid;
  int handleid;
  String mediatype;
  String jsep_type;
  String jsep_sdp;

  SubscriberMedia(this.roomid, this.handleid,this.feedid,this.mediatype){
    subhandle = Subscribers(this.roomid,sessionid,this.handleid,this.feedid,this.mediatype);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("plugindata")){
      Map<String,dynamic> datas = itemvalues["plugindata"];
      if(datas.containsKey("data")){
        Map<String,dynamic> data =datas["data"];
        if(data.containsKey("videoroom")){
          String joined =data["videoroom"];
          print("joined room ${joined=="joined"}");
          if(joined=="joined"){
            List<dynamic> items = data["list"];
            items.forEach((element) {
              print(element['id']);
            });
          }
        }
      }
    }
    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("plugindata")){
      Map<String,dynamic> datas = itemvalues["plugindata"];
      if(datas.containsKey("data")){
        Map<String,dynamic> data =datas["data"];
        if(data.containsKey("error_code")){
          int joined =data["error_code"];
          print("subscriber ${joined}");
          return EventSeq.none;
        }else if( data.containsKey("videoroom")){
          String joined =data["videoroom"];
          print("subscriber  ${joined=="attached"}");
          if(joined=="attached"){
            if(itemvalues.containsKey("jsep")) {
              Map<String,dynamic> jseps =itemvalues["jsep"];
              jsep_type = jseps["type"];
              jsep_sdp = jseps["sdp"];
              return EventSeq.esubmediaseq;
            }

          }
        }
      }
    }
    return EventSeq.none;

  }

  String GetTransaction(){
    return subhandle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(subhandle.toJson()) ;
  }
}



class AnswerHandle implements JsonHandle{
  SubAnswer subhandle;
  int roomid;
  int handleid;
  String type;
  String sdp;

  AnswerHandle(this.handleid,this.roomid,this.type,this.sdp){
    subhandle = SubAnswer(sessionid,this.handleid,this.roomid,this.type,this.sdp);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){


    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){

    return EventSeq.none;

  }

  String GetTransaction(){
    return subhandle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(subhandle.toJson()) ;
  }
}


class publisherHandle implements JsonHandle{
  publishMedia pubmedia;
  int handleid;
  String mediatype;
  String jsep_sdp;
  String answersdp;

  publisherHandle(this.mediatype,this.jsep_sdp,this.handleid){
    pubmedia = publishMedia(sessionid,this.handleid,this.mediatype,this.jsep_sdp);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);


    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){
    print("pubMedia");
    Map<String,dynamic> itemvalues=convert.jsonDecode(jsonvalue);
    if(itemvalues.containsKey("jsep")){
      Map<String,dynamic> jseps = itemvalues["jsep"];
      if(jseps.containsKey("sdp")){
        answersdp =jseps["sdp"];
        print("publisher sdp ${answersdp}");
        return EventSeq.epubmediaseq;

      }
    }
    return EventSeq.none;


  }

  String GetTransaction(){
    return pubmedia.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(pubmedia.toJson()) ;
  }
}




class LeaveHandle implements JsonHandle{
  Leaver leavehandle;
  int roomid;
  int feedid;
  int handleid;
  String mediatype;
  String jsep_type;
  String jsep_sdp;

  LeaveHandle(){
    leavehandle = Leaver(sessionid,mainhandle);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){


    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){


    return EventSeq.none;

  }

  String GetTransaction(){
    return leavehandle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(leavehandle.toJson()) ;
  }
}




class unPublishHandle implements JsonHandle{
  unPublish unpublish;
  String  mediatype;

  unPublishHandle(this.mediatype){
 int handleid =mainhandle;
   if(mediatype=="audio"){
     handleid = audiohandle;
    }else if(mediatype=="video") {
     handleid = videohandle;
  }else if(mediatype=="screen"){
      handleid = screenhandle;
   }
    unpublish = unPublish(sessionid,handleid,this.mediatype);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){


    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){


    return EventSeq.none;

  }

  String GetTransaction(){
    return unpublish.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(unpublish.toJson()) ;
  }
}




class muteHandle implements JsonHandle{
  mute handle;
  bool bmute;

  muteHandle(this.bmute){
    handle = mute(sessionid,audiohandle,this.bmute);
  }
  void OnError(int error) {

  }
  SucessSeq OnSuccess(String jsonvalue){


    return SucessSeq.none;
  }
  EventSeq OnEvent(String jsonvalue){


    return EventSeq.none;

  }

  String GetTransaction(){
    return handle.transaction;
  }

  String GetJsonString() {
    return  convert.jsonEncode(handle.toJson()) ;
  }
}






