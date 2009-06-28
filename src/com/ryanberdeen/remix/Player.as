package com.ryanberdeen.remix {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.cubes.Cubes;
  import com.ryanberdeen.nest.NestPlayer;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.media.Sound;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.utils.Timer;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
  public class Player extends Sprite {
    private static var logger:Logger = new Logger();
    public static var options:Object;
    private var playerConnection:PlayerConnection;
    private var loader:URLLoader;
    internal var trackId:int;
    private var player:NestPlayer;
    private var cubes:Cubes;

    private var startTimer:Timer;

    public function Player():void {
      logger.log('Player loaded');
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';

      playerConnection = new PlayerConnection(this);
      playerConnection.connect('com.ryanberdeen.remix.Player');

      trackId = options.trackId;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      cubes = new Cubes();
      addChild(cubes);
      cubes.width = 0;

      player = new NestPlayer({
        bars: {
          triggerStartHandler: cubes.barTriggerHandler,
          triggerStartOffset: -50
        },
        beats: {
          triggerStartHandler: cubes.beatTriggerHandler,
          triggerStartOffset: -100
        },
        tatums: {
          triggerStartHandler: cubes.tatumTriggerHandler,
          triggerStartOffset: -50
        }
      });

      if (trackId) {
        loadSound();
        loadAnalysis();
      }
    }

    public function loadSound():void {
      logger.log('Loading sound');
      var sound:Sound = new Sound();
      sound.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        cubes.width = stage.stageWidth * (event.bytesLoaded / event.bytesTotal);
      });
      sound.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Sound loaded');
        player.sound = sound;
        if (player.data) {
          start();
        }
      });

      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));
    }

    public function loadAnalysis():void {
      logger.log('Loading analysis');
      loader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, function(e:Event):void {
        logger.log('Analysis loaded');
        var data:Object = JSON.decode(loader.data);
        player.data = data;
        if (player.sound) {
          start();
        }
      });
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks/' + trackId + '/analysis');
      loader.load(request);
    }

    public function start():void {
      logger.log('Starting player');

      cubes.dropCubes();
      startTimer = new Timer(3000, 1);
      startTimer.addEventListener('timer', function(e:Event):void {
        player.start();
      });
      startTimer.start();
    }
  }
}
