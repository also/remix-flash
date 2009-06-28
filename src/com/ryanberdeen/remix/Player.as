package com.ryanberdeen.remix {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.nest.NestPlayer;

  import flash.display.Loader;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.media.Sound;
  import flash.net.URLLoader;
  import flash.net.URLRequest;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
  public class Player extends Sprite {
    private static var logger:Logger = new Logger();
    public static var options:Object;
    private var playerConnection:PlayerConnection;
    private var analysisLoader:URLLoader;
    internal var trackId:int;
    private var nestPlayer:NestPlayer;
    private var playerDisplay:PlayerDisplay;
    private var loader:Loader;

    public function Player():void {
      logger.log('Player loaded');
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.display ||= 'cubes';

      playerConnection = new PlayerConnection(this);
      playerConnection.connect('com.ryanberdeen.remix.Player');

      trackId = options.trackId;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      nestPlayer = new NestPlayer();

      loader = new Loader();
      var player:Player = this;
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
        playerDisplay = PlayerDisplay(loader.content);
        addChild(Sprite(playerDisplay));
        playerDisplay.player = player;
        playerDisplay.nestPlayer = nestPlayer;

        if (trackId) {
          loadSound();
          loadAnalysis();
        }
      });

      var request:URLRequest = new URLRequest('/swfs/' + options.display + '.swf');
      loader.load(request);
    }

    public function loadSound():void {
      logger.log('Loading sound');
      var sound:Sound = new Sound();
      sound.addEventListener(ProgressEvent.PROGRESS, playerDisplay.handleSoundLoadProgress);
      sound.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Sound loaded');
        nestPlayer.sound = sound;
        if (nestPlayer.data) {
          prepare();
        }
      });

      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));
    }

    public function loadAnalysis():void {
      logger.log('Loading analysis');
      analysisLoader = new URLLoader();
      analysisLoader.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Analysis loaded');
        var data:Object = JSON.decode(analysisLoader.data);
        nestPlayer.data = data;
        playerDisplay.data = data;
        if (nestPlayer.sound) {
          prepare();
        }
      });
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks/' + trackId + '/analysis');
      analysisLoader.load(request);
    }

    public function prepare():void {
      playerDisplay.prepare();
    }

    public function start():void {
      logger.log('Starting player');
      nestPlayer.start();
    }
  }
}
