package com.ryanberdeen.remix {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.cubes.Cubes;
  import com.ryanberdeen.nest.NestPlayer;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.utils.Timer;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
  public class Main extends Sprite {
    [Embed(mimeType="application/x-font", source="/fonts/HelveticaNeueLight.ttf", fontName="HelveticaNeueLight")]
    private var helveticaNeueUltraLightFontClass:Class;
    public static var options:Object;
    private var uploader:Uploader;
    private var loader:URLLoader;
    internal var trackId:int;
    private var player:NestPlayer;
    private var cubes:Cubes;

    private var startTimer:Timer;

    public function Main():void {
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.connectorHost ||= 'localhost';
      options.connectorPort ||= 1843;

      trackId = options.trackId;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      cubes = new Cubes();

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
        addChild(cubes);
        cubes.width = 0;
        loadSound();
        loadAnalysis();
      }
      else {
        uploader = new Uploader(this);
        addChild(uploader);
      }
    }

    public function loadSound():void {
      log('Loading sound');
      var sound:Sound = new Sound();
      if (!uploader) {
        sound.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
          cubes.width = stage.stageWidth * (event.bytesLoaded / event.bytesTotal);
        });
      }
      sound.addEventListener(Event.COMPLETE, function(e:Event):void {
        log('Sound loaded');
        player.sound = sound;
        if (player.data) {
          start();
        }
      });

      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));
    }

    public function loadAnalysis():void {
      log('Loading analysis');
      loader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, function(e:Event):void {
        log('Analysis loaded');
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
      log('Starting player');
      if (uploader) {
        addChild(cubes);
        removeChild(uploader);
      }

      cubes.dropCubes();
      startTimer = new Timer(3000, 1);
      startTimer.addEventListener('timer', function(e:Event):void {
        player.start();
      });
      startTimer.start();
    }

    public function log(o:Object):void {
      ExternalInterface.call('console.log', o.toString());
    }
  }
}
