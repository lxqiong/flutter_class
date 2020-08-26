import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:flutter_class/customJson.dart';
import 'package:flutter_webrtc/webrtc.dart';

import 'package:flutter_class/IconTextButton.dart';

var keepAliveTimer;

int iroomid=12351;
var _peerConnections = new Map<int, RTCPeerConnection>();
List<RTCVideoRenderer> _remoteVideo = [RTCVideoRenderer(),RTCVideoRenderer(),RTCVideoRenderer()];
List<int> _remoteRender = [0,0,0];
RTCVideoRenderer _remoteScreen = RTCVideoRenderer();

class OnlinePage extends StatefulWidget {
  @override
  _WebSocketRouteState createState() => new _WebSocketRouteState();
}

class _WebSocketRouteState extends State<OnlinePage> {
  IOWebSocketChannel command_channel;
  Color _audiobk = Color.fromARGB(0xFF, 0x22, 0x22, 0x22);
  Color _cammerabk = Color.fromARGB(0xFF, 0x55, 0x55, 0x55);
  Color _screenbk = Color.fromARGB(0xFF, 0x55, 0x55, 0x55);
  Map<String,JsonHandle> _mapHandle;
  bool  bopenAudio=false;
  bool  bopenvideo=false;
  bool  bopenscreen=false;
  int _myid;




  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _audioconstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };
  final Map<String, dynamic> _videoconstraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };


  void sendData(String data)async{

    print("data:${data}");
    command_channel.sink.add(data);

  }

  JsonHandle GetJsonHandle(Map<String,dynamic> items){

    if(items.containsKey("transaction")){
      String code = items["transaction"];
      if(_mapHandle.containsKey(code)){
        JsonHandle handle = _mapHandle[code];
        return handle;
      }
    }
    return null;
  }

  Future<MediaStream> createStream(media, user_screen) async {
    final Map<String, dynamic> audioConstraints = {
      'audio': true,
      'video': false,
    };
    final Map<String, dynamic> videoConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth':
          '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    final Map<String, dynamic> screenConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth':
          '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    MediaStream stream=null;
    if(user_screen){
      stream = await navigator.getDisplayMedia(screenConstraints);
    }
    else if(media=="audio") {
      stream = await navigator.getUserMedia(audioConstraints);
    }
    else if(media=="video"){
      stream = await navigator.getUserMedia(videoConstraints);
    }


    return stream;
  }
  int _getvideounrender(){
    for(int i=0;i<_remoteRender.length;i++){
      if(_remoteRender[i]==0)
        return i;
    }
    return -1;
  }

  int _getvideorender(int id){
    for(int i=0;i<_remoteRender.length;i++){
      if(_remoteRender[i]==id)
        return i;
    }
    return -1;
  }

  _setvideorender(int index,int id){
    if(index>=0){
      _remoteRender[index]=id;
    }
  }

  _createPeerConnection(userid,handleid, media, user_screen,local) async {
      MediaStream stream;
      var pc = await createPeerConnection(_iceServers, _config);
      if(userid==_myid && local==true){
        if (media != 'data' ) {
          stream = await createStream(media, user_screen);
          if(media=="video"){
            int i=_getvideounrender();
            if(i>=0){
              _remoteVideo[i].srcObject = stream;
              _setvideorender(i, userid);
            }
          }
        }
        if (media != 'data') pc.addStream(stream);
      }



      pc.onIceCandidate = (candidate) {

      };

      pc.onIceConnectionState = (state) {};

      pc.onAddStream = (stream) {
        if(media=="video"){
          print("on add stream${media}");
          int i=_getvideounrender();
          if(i>=0){
            _remoteVideo[i].srcObject = stream;
            _setvideorender(i, userid);
          }
        }else if(media=="screen"){
          _remoteScreen.srcObject=stream;
        }

      };

      pc.onRemoveStream = (stream) {

      };

      pc.onDataChannel = (channel) {
      };

      return pc;
    }


  _createAnswer(int handleid, RTCPeerConnection pc, media) async {
    try {

      var _constraints =null;
      if(media=="audio"){
        _constraints=_audioconstraints;
      }
      else{
        _constraints= _videoconstraints;
      }
      RTCSessionDescription s = await pc.createAnswer( _constraints);

      AnswerHandle handleanswer =  AnswerHandle(handleid,iroomid,s.type,s.sdp);
      String jsonstring = handleanswer.GetJsonString();
      _mapHandle[handleanswer.GetTransaction()]=handleanswer;
      sendData(jsonstring);
      await pc.setLocalDescription(s);
    } catch (e) {
      print(e.toString());
    }
  }

  void leaving(){
    keepAliveTimer.cancel();
  }

  submedia(int userid,int handleid,String media_type,String sdp)async{
    print("sub media");
    var pc =await _createPeerConnection(userid,handleid,media_type,false,false);
    _peerConnections[handleid]=pc;
    if(pc==null){
      print("crete pc failed");
      return;
    }
    await pc.setRemoteDescription(new RTCSessionDescription(sdp, "offer"));
   // RTCSessionDescription s = await pc.createAnswer(_constraints);
    await _createAnswer(handleid,pc,media_type);

  }

  void subscriber_media(int userid,String media_type){
    JanusPlugin subscriber = JanusPlugin(mediatype: media_type,feedid: userid);
    String jsonstring = subscriber.GetJsonString();
    _mapHandle[subscriber.GetTransaction()]=subscriber;
    sendData(jsonstring);
  }
  void analyze_asyc(String async_message){
    Map<String,dynamic> items = json.decode(async_message);
    if(items.containsKey("janus")){
      String value = items["janus"];
      if(value=="event" ){
          if (items.containsKey("plugindata")){
            Map<String,dynamic>  plugins_data = items['plugindata'];
            if(plugins_data.containsKey("data")){
              Map<String,dynamic>  datas =plugins_data['data'];
              if(datas.containsKey("joining")){
                Map<String,dynamic>  joining = datas['joining'];
                print("joining ${joining['id']}");
                print("joining ${joining['display']}");
                print("joining ${joining['terminal']}");
              }else if(datas.containsKey("leaving")){
                int leave_id = datas['leaving'];
                print("leaving: ${leave_id}");
                leaving();
              }else if(datas.containsKey("unpublished")){
                int unpublish = datas['unpublished'];
                String media = datas['mediatype'];
                print("unpublish: ${unpublish} media:${media}");
                setState(() {
                  if(media=="video"){
                    int i=_getvideorender(unpublish);
                    if(i>=0){
                      _remoteVideo[i].srcObject=null;
                      _remoteRender[i]=0;
                    }
                  }else{
                    _remoteScreen.srcObject=null;
                  }
                });

              }else if(datas.containsKey("videoroom")){
                String evented = datas['videoroom'];
                if(evented=="destroyed"){
                  print("the room is destroyed");
                  leaving();
                }else if(evented=="event"){
                  if(datas.containsKey("publishers")){
                    List<dynamic>  publishers =datas['publishers'];
                    publishers.forEach((item) {
                      int feed = item['id'];
                      String name= item['display'];
                      String type = item['mediatype'];
                      print("${name}: ${feed} publishing ${type}");
                      subscriber_media(feed,type);
                    });
                  }
                }
              }

              if(datas.containsKey("type")){
                String type = datas['type'];
                if(type=="subscribed"){
                  Map<String,dynamic>  data = datas['data'];
                  if(data.containsKey("media_type")){
                    print("${type}:${data['media_type']}-${data['feed']}");
                  }
                }else if(type=="setupmedia"){
                  Map<String,dynamic>  data = datas['data'];
                  if(data.containsKey("media_type")){
                    print("${type}:${data['media_type']}");
                  }
                }
              }
            }
          }
      }


    }


  }

  void init()async{
    _mapHandle = Map<String,JsonHandle>();

    var httpheaders = {"Sec-WebSocket-Protocol":"janus-protocol"};
    command_channel = IOWebSocketChannel.connect("ws://s6-meeting.unicloud.com:8188",headers: httpheaders);
    if(command_channel == null){
      return;
    }
    JanusSession sessionHandle = JanusSession();
    sendData(sessionHandle.GetJsonString());
    _mapHandle[sessionHandle.GetTransaction()]=sessionHandle;

    command_channel.stream.listen((message){
      print(message);
      Map<String,dynamic> items = json.decode(message);
      JsonHandle handle = GetJsonHandle(items);
      if(handle == null){
        print("async event ${message}");
        analyze_asyc(message);
        return;
      }
      if(items.containsKey("janus")){
        String value = items["janus"];
        if(value=="success" ){
          SucessSeq seq=handle.OnSuccess(message);
          if(seq.index >=SucessSeq.sessionSeq.index && seq.index<SucessSeq.screenhandleSeq.index){
            if(seq==SucessSeq.sessionSeq){
              keepAliveTimer = Timer.periodic(Duration(milliseconds: 20000), (Void){
                print("send keep alive");
                KeepHandle keep = KeepHandle();
                sendData(keep.GetJsonString());
              });
            }
            JanusPlugin mainhandle = JanusPlugin();
            String jsonstring = mainhandle.GetJsonString();
            _mapHandle[mainhandle.GetTransaction()]=mainhandle;
            sendData(jsonstring);
          } else if(seq==SucessSeq.screenhandleSeq){
            CreteRoomHandle handle =  CreteRoomHandle(iroomid);
            String jsonstring = handle.GetJsonString();
            _mapHandle[handle.GetTransaction()]=handle;
            sendData(jsonstring);
          }else if(seq==SucessSeq.createroomSeq){
            JoinRoomHandle handle =  JoinRoomHandle(iroomid,"flutter_test");
            String jsonstring = handle.GetJsonString();
            _mapHandle[handle.GetTransaction()]=handle;
            sendData(jsonstring);
          }else if(seq == SucessSeq.subscriberhandleSeq){
            int handleid = (handle as JanusPlugin).pluginhandle.handleId;
            int feedid = (handle as JanusPlugin).pluginhandle.feedid;
            String mediatype =(handle as JanusPlugin).pluginhandle.mediatype;
            SubscriberMedia submedia = SubscriberMedia(iroomid,handleid,feedid,mediatype);
            String jsonstring = submedia.GetJsonString();
            _mapHandle[submedia.GetTransaction()]=submedia;
            sendData(jsonstring);

          }
        }else if(value=="event"){
          EventSeq eseq = handle.OnEvent(message);
          if(eseq==EventSeq.ejoinSeq){
            _myid = (handle as JoinRoomHandle).selfid;
            (handle as JoinRoomHandle).publisherMembers.forEach((element) {
              subscriber_media(element.userid, element.media_type);
            });
          }else if(eseq==EventSeq.esubmediaseq){
            String media=(handle as SubscriberMedia).mediatype;
            String jsep_type=(handle as SubscriberMedia).jsep_type;
            String jsep_sdp = (handle as SubscriberMedia).jsep_sdp;
            int handleid = (handle as SubscriberMedia).handleid;
            int userid = (handle as SubscriberMedia).feedid;
            print("media type:${media}");
            print("jsep type:${jsep_type}");
            print("sdp:${jsep_sdp}");
            submedia(userid,handleid,media,jsep_sdp);
          }else if(eseq==EventSeq.epubmediaseq){
            String jsep_sdp = (handle as publisherHandle).answersdp;
            int handleid = (handle as publisherHandle).handleid;
            if(_peerConnections.containsKey(handleid)){
              var pc = _peerConnections[handleid];
              var answerdes = RTCSessionDescription(jsep_sdp, "answer");
              pc.setRemoteDescription(answerdes);
            }

          }
        }
      }
    },onError:(error){

      print(error.toString());

    } ,onDone: (){
      print("Done");
    });


  }
  initRenderers() async {
    await _remoteScreen.initialize();
    await _remoteVideo.forEach((render)=> render.initialize());
  }

  @override
  void initState() {

    init();
    initRenderers();

  }

  _createOffer(int id, RTCPeerConnection pc, String media) async {
    try {
      var _constraints =null;
      if(media=="audio"){
        _constraints=_audioconstraints;
      }
      else{
        _constraints= _videoconstraints;
      }
      RTCSessionDescription s = await pc
          .createOffer(_constraints);
      pc.setLocalDescription(s);
      print("create offer:${s.type},sdp:${s.sdp}");

      publisherHandle publishhandle =  publisherHandle(media,s.sdp,id);
      String jsonstring = publishhandle.GetJsonString();
      _mapHandle[publishhandle.GetTransaction()]=publishhandle;
      sendData(jsonstring);


    } catch (e) {
      print(e.toString());
    }
  }

  void leaveRoom(){
    LeaveHandle handle = LeaveHandle();
    String jsonstring = handle.GetJsonString();
    _mapHandle[handle.GetTransaction()]=handle;
    sendData(jsonstring);
    leaving();
  }

  void muteAudio(bool mute){
    muteHandle handle = muteHandle(mute);
    String jsonstring = handle.GetJsonString();
    _mapHandle[handle.GetTransaction()]=handle;
    sendData(jsonstring);
    if(mute==false){
      return;
    }
    if(_peerConnections.containsKey(audiohandle)){
      var pc = _peerConnections[audiohandle];
      pc.getLocalStreams()[0].getAudioTracks()[0].setMicrophoneMute(true);
    }
  }

  void pubMedia(String media){
    int handleid=0;
    bool user_screen=false;
    if(media=="audio"){
      handleid = audiohandle;
      muteAudio(false);
    }
    else if(media=="video"){
      handleid = videohandle;
    }
    else if(media=="screen"){
      handleid = screenhandle;
      user_screen=true;
    }else{
      return;
    }
    _createPeerConnection(_myid,handleid, media, user_screen,true).then((pc){
      _peerConnections[handleid]=pc;
      _createOffer(handleid,pc,media);

    });
  }

  void unpubMedia(String media)async{
    int handleid=0;
    if(media=="audio"){
      handleid = audiohandle;
    }
    else if(media=="video"){
      handleid = videohandle;
    }
    else if(media=="screen"){
      handleid = screenhandle;
    }else{
      return;
    }
    if(_peerConnections.containsKey(handleid)){


      RTCPeerConnection pc =_peerConnections[handleid];
      var streams = pc.getLocalStreams();
      await streams[0].dispose();
      await pc.close();
      _peerConnections.remove(handleid);
      unPublishHandle(media);
    }

  }




  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      backgroundColor: Color.fromARGB(0xFF, 0x22, 0x22, 0x22),
      appBar: new AppBar(
        title: new Text("在线课堂",style: TextStyle(fontSize: 15),),
        backgroundColor: Color.fromARGB(0xFF, 0x22, 0x22, 0x22),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
        tooltip: "退出课堂",
        onPressed: (){
            print("退出课堂");
            Navigator.pop(context);
        },),
        actions: <Widget>[
          IconButton(
            icon: ImageIcon(AssetImage("lib/assets/images/chscreen.png")),
            tooltip: "屏幕切换",
            onPressed: (){
              print("屏幕切换");
            },),
        ],
      ),
      body:
      Column(
        mainAxisAlignment:MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height*0.5,
//            color: Colors.red,
          child: RTCVideoView(_remoteScreen),
          ),
          Container(
            height: MediaQuery.of(context).size.height*0.20,
            child: Flex(
              direction: Axis.horizontal,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.white,
                    child: RTCVideoView(_remoteVideo[0]),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.green,
                    child: RTCVideoView(_remoteVideo[1]),
                  ),
                ),
                Expanded(flex: 1,
                  child:  Container(
                    color: Colors.red,
                    child: RTCVideoView(_remoteVideo[2]),
                  ),
                ),

              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Align(
                      alignment: Alignment.center,
                      child: Material(
                        color: _audiobk,
                          shape: CircleBorder(
                              side: BorderSide(
                                  color: Color.fromARGB(0xFF, 0x22, 0x22, 0x22),
                                  width: 1,
                                  style: BorderStyle.solid)),
                          child: IconButton(
                              icon: ImageIcon(AssetImage("lib/assets/images/active_mic.png")),
                              iconSize: 50,
                              onPressed: () {
                                setState(() {
                                  if(bopenAudio){
                                    print("关闭音频");
                                    _audiobk = Color.fromARGB(0xFF, 0x22, 0x22, 0x22);
                                    bopenAudio=false;
                                    unpubMedia("audio");

                                  }else{
                                    print("打开音频");
                                    _audiobk = Color.fromARGB(0xFF, 0xF7, 0xF7, 0xF8);
                                    bopenAudio=true;
                                    pubMedia("audio");
                                  }
                                });

                              }))
                  ),
                  Align(
                      alignment: Alignment.center,
                          child: Text("麦克风",style: TextStyle(color: Colors.white),),),


                ],
              ),
              Column(
                children: <Widget>[
                  Align(
                      alignment: Alignment.center,
                      child: Material(
                          color: _cammerabk,
                          shape: CircleBorder(
                              side: BorderSide(
                                  color: Color.fromARGB(0xFF, 0x22, 0x22, 0x22),
                                  width: 1,
                                  style: BorderStyle.solid)),
                          child: IconButton(
                              icon: ImageIcon(AssetImage("lib/assets/images/active_cammera.png")),
                              iconSize: 50,
                              onPressed: () {
                                setState(() {
                                  if(bopenvideo){
                                    print("关闭视频");
                                    _cammerabk = Color.fromARGB(0xFF, 0x22, 0x22, 0x22);
                                    bopenvideo=false;
                                    unpubMedia("video");
                                    int i = _getvideorender(_myid);
                                    if(i>=0){
                                      _remoteVideo[i].srcObject=null;
                                      _remoteRender[i]=0;
                                    }
                                  }else{
                                    print("打开视频");
                                    _cammerabk = Color.fromARGB(0xFF, 0xF7, 0xF7, 0xF8);
                                    bopenvideo=true;
                                    pubMedia("video");
                                  }
                                });
                              }))
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text("摄像头",style: TextStyle(color: Colors.white),),),
                ],
              ),
              Column(
                children: <Widget>[
                  Align(
                      alignment: Alignment.center,
                      child: Material(
                          color: _screenbk,
                          shape: CircleBorder(
                              side: BorderSide(
                                  color: Color.fromARGB(0xFF, 0x22, 0x22, 0x22),
                                  width: 1,
                                  style: BorderStyle.solid)),
                          child: IconButton(
                              icon: ImageIcon(AssetImage("lib/assets/images/active_screen.png")),
                              iconSize: 50,
                              onPressed: () {
                                setState(() {
                                  if(bopenscreen){
                                    print("关闭桌面");
                                    _screenbk = Color.fromARGB(0xFF, 0x22, 0x22, 0x22);
                                    bopenscreen=false;
                                    unpubMedia("screen");
                                  }else{
                                    print("打开桌面");
                                    _screenbk = Color.fromARGB(0xFF, 0xF7, 0xF7, 0xF8);
                                    bopenscreen=true;
                                    pubMedia("screen");
                                  }
                                });
                              }))
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text("屏幕共享",style: TextStyle(color: Colors.white),),),
                ],
              ),
            ],
          ),
        ],
      ),





    );
  }



  JsonHandle createSession(){
    JanusSession session = JanusSession();
    return session;
  }

  void _sendMessage() {
    JsonHandle handle = createSession();
    String jsonstring = handle.GetJsonString();
    _mapHandle[handle.GetTransaction()]=handle;
    sendData(jsonstring);



  }

  @override
  void dispose() {
    print("退出实例");
    super.dispose();
    if(command_channel.sink != null){
      print("关闭wss链接");
      leaveRoom();
      command_channel.sink.close();
      command_channel = null;
    }

  }
}
class ClassNavigationBarItem {
  String ch;
  String eng;
  final TextStyle bottomTextStyle = TextStyle(
    color: Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
    fontSize: 10.0,
  );
  ClassNavigationBarItem(this.ch, this.eng);
  BottomNavigationBarItem createBarItem() {
    return BottomNavigationBarItem(
        activeIcon: Image.asset('lib/assets/images/active_${eng}.png'),
        icon: Image.asset('lib/assets/images/${eng}.png'),
        title: Text(
          ch,
          style: bottomTextStyle
        ));
  }
}