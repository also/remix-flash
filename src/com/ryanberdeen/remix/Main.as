package com.ryanberdeen.remix {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.connector.Connector;
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
    internal var connector:Connector;
    internal var trackId:int;
    private var player:NestPlayer;
    private var cubes:Cubes;

    private var startTimer:Timer;

    public function Main():void {
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.connectorHost ||= 'localhost';
      options.connectorPort ||= 1843;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      uploader = new Uploader(this);
      addChild(uploader);

      connector = new Connector();
      connector.connect(options.connectorHost, options.connectorPort);
      connector.subscribe('remix_worker_event', uploader);
    }

    public function loadSound():void {
      var sound:Sound = new Sound();
      sound.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        //
      });

      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));

      cubes = new Cubes();
      player = new NestPlayer(sound, {
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
    }

    public function loadAnalysis():void {
      loader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, nestDataCompleteHandler);
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks/' + trackId + '/analysis');
      loader.load(request);
    }

    private function nestDataCompleteHandler(e:Event):void {
      var data:Object = JSON.decode(loader.data);
      player.data = data;

      addChild(cubes);
      removeChild(uploader);
      cubes.dropCubes();
      startTimer = new Timer(2, 1);
      startTimer.addEventListener('timer', function(e:Event):void {
        player.start();
      });
      startTimer.start();
    }

    public function handleSubscribedMessage(message:String):void {
      log(message);
    }

    public function log(o:Object):void {
      //ExternalInterface.call('console.log', o.toString());
    }
  }
}
