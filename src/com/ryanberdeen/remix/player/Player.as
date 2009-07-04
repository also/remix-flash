package com.ryanberdeen.remix.player {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.nest.NestPlayer;
  import com.ryanberdeen.nest.SoundPositionSource;
  import com.ryanberdeen.nest.TimePositionSource;
  import com.ryanberdeen.remix.Logger;
  import com.ryanberdeen.remix.display.IPlayerDisplay;

  import flash.display.Loader;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.net.URLLoader;
  import flash.net.URLRequest;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
  public class Player extends Sprite implements IPlayer {
    private static var logger:Logger = new Logger();
    public static var options:Object;
    private var playerConnection:PlayerConnection;
    private var analysisLoader:URLLoader;
    internal var trackId:int;
    private var nestPlayer:NestPlayer;
    private var playerDisplay:IPlayerDisplay;
    private var loader:Loader;
    private var sound:Sound;

    public function Player():void {
      logger.log('Player loaded');
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.rootSwfUrl ||= 'http://localhost:3000/swfs';
      options.display ||= 'cubes';
      options.playSound = options.playSound != 'false' ? true : false;

      playerConnection = new PlayerConnection(this);
      playerConnection.connect('com.ryanberdeen.remix.Player');

      trackId = options.trackId;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      nestPlayer = new NestPlayer();

      loadDisplay();
    }

    private function loadDisplay():void {
      loader = new Loader();
      var player:Player = this;
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Display loaded');
        playerDisplay = IPlayerDisplay(loader.content);
        addChild(Sprite(playerDisplay));
        playerDisplay.player = player;
        playerDisplay.nestPlayer = nestPlayer;

        if (trackId) {
          loadSound();
          loadAnalysis();
        }
      });

      logger.log('Loading display');
      var request:URLRequest = new URLRequest(options.rootSwfUrl + '/' + options.display + '.swf');
      loader.load(request);
    }

    public function loadSound():void {
      if (!options.playSound) {
        return;
      }

      logger.log('Loading sound');
      sound = new Sound();
      sound.addEventListener(ProgressEvent.PROGRESS, playerDisplay.handleSoundLoadProgress);
      sound.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Sound loaded');
        nestPlayer.positionSource = new SoundPositionSource(sound);
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

        ExternalInterface.call('setAnalysis', data);

        if (!options.playSound) {
          nestPlayer.positionSource = new TimePositionSource(data.duration * 1000);
          prepare();
        }
        else if (sound && sound.bytesLoaded == sound.bytesTotal) {
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
