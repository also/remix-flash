package com.ryanberdeen.remix {
  import com.adobe.net.MimeTypeMap;
  import com.adobe.serialization.json.JSON;
  import com.elctech.S3UploadOptions;
  import com.elctech.S3UploadRequest;
  import com.ryanberdeen.connector.Connector;
  import com.ryanberdeen.cubes.Cubes;
  import com.ryanberdeen.nest.NestPlayer;

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.net.FileReference;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.utils.Timer;

  import gs.TweenMax;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
  public class Main extends Sprite {
    [Embed(mimeType="application/x-font", source="/fonts/HelveticaNeueLight.ttf", fontName="HelveticaNeueLight")]
    private var helveticaNeueUltraLightFontClass:Class;
    public static var options:Object;
    private var button:Button;
    private var uploadOptions:S3UploadOptions = new S3UploadOptions();
    private var fileReference:FileReference;
    private var loader:URLLoader;
    private var connector:Connector;
    private var trackId:int;
    private var player:NestPlayer;
    private var cubes:Cubes;
    private var statusSprite:Sprite;
    private var uploadProgressShape:Shape;
    private var downloadProgressShape:Shape;
    private var submissionProgressShape:Shape;
    private var submisionProgressTween:TweenMax;
    private var analyzeProgressShape:Shape;
    private var analyzeProgressTween:TweenMax;
    private var startTimer:Timer;

    public function Main():void {
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.connectorHost ||= 'localhost';
      options.connectorPort ||= 1843;

      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      opaqueBackground = 0xffffff;

      button = new Button('Select file…');
      button.addEventListener(MouseEvent.CLICK, browseClickHandler);
      addChild(button);

      connector = new Connector();
      connector.connect(options.connectorHost, options.connectorPort);
      connector.subscribe('remix_worker_event', this);

      statusSprite = new Sprite();
      statusSprite.x = (stage.stageWidth - 300) / 2;
      statusSprite.y = 100;
      with (statusSprite.graphics) {
        for (var i:int = 0; i < 3; i++) {
          beginFill(0xcccccc);
          drawRect(0, i * 60, 300, 50);
          endFill();
        }
      }
      addChild(statusSprite);

      uploadProgressShape = createProgressShape(0x555555);
      uploadProgressShape.alpha = .5;
      uploadProgressShape.scaleX = 0;
      statusSprite.addChild(uploadProgressShape);

      downloadProgressShape = createProgressShape(0x555555);
      downloadProgressShape.scaleX = 0;
      statusSprite.addChild(downloadProgressShape);

      submissionProgressShape = createProgressShape(0x555555);
      submissionProgressShape.y = 60;
      submissionProgressShape.alpha = 0;
      statusSprite.addChild(submissionProgressShape);

      analyzeProgressShape = createProgressShape(0x555555);
      analyzeProgressShape.y = 120;
      analyzeProgressShape.alpha = 0;
      statusSprite.addChild(analyzeProgressShape);
    }

    private function createProgressShape(color:uint):Shape {
      var result:Shape = new Shape();
      with (result.graphics) {
        beginFill(color);
        drawRect(0, 0, 300, 50);
        endFill();
      }
      return result;
    }

    public function browseClickHandler(e:MouseEvent):void {
      fileReference = new FileReference();
      fileReference.addEventListener(Event.SELECT, function(event:Event):void {
        uploadOptions.FileName = fileReference.name;
        uploadOptions.FileSize = fileReference.size.toString();

        var FileNameArray:Array = uploadOptions.FileName.split(/\./);
        var FileExtension:String = FileNameArray[FileNameArray.length - 1];
        uploadOptions.ContentType = new MimeTypeMap().getMimeType(FileExtension);
        upload();
      });
      fileReference.browse();
    }

    private function upload():void {
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks');
      loader = new URLLoader();
      var variables:URLVariables = new URLVariables();
      variables.file_name = uploadOptions.FileName;
      variables.file_size = uploadOptions.FileSize;
      variables.key = uploadOptions.key;
      variables.content_type = uploadOptions.ContentType;

      request.method = URLRequestMethod.POST;
      request.data = variables;
      loader.addEventListener(Event.COMPLETE, trackCreatedHandler);
      loader.load(request);
    }

    private function trackCreatedHandler(e:Event):void {
      var data:Object = JSON.decode(loader.data);
      uploadOptions.policy         = data.policy;
      uploadOptions.signature      = data.signature;
      uploadOptions.bucket         = data.bucket;
      uploadOptions.AWSAccessKeyId = data.access_key_id;
      uploadOptions.acl            = data.acl;
      uploadOptions.Expires        = data.expiration_date;
      uploadOptions.Secure         = 'false';
      uploadOptions.key = data.key;
      trackId = data.track_id;

      var request:S3UploadRequest = new S3UploadRequest(uploadOptions);

      request.addEventListener(Event.OPEN, function(event:Event):void {
        log(event);
      });
      request.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        uploadProgressShape.scaleX = event.bytesLoaded / event.bytesTotal;
      });
      request.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
        log(event);
      });
      request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
        log(event);
      });
      request.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:Event):void {
        connector.send('remix_worker add_uploaded_track ' + trackId);
        log(event);
      });

      try {
        request.upload(fileReference);
      }
      catch(e:Error) {
        log("An error occurred: " + e);
      }
    }

    public function handle_started(message:String):void {
      cubes = new Cubes();
      var args:Array = message.split(' ');
      var sound:Sound = new Sound();
      sound.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        downloadProgressShape.scaleX = event.bytesLoaded / event.bytesTotal;
      });

      sound.load(new URLRequest(args[1]));
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

      submisionProgressTween = TweenMax.to(submissionProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_submitted(message:String):void {
      submisionProgressTween.pause();
      submissionProgressShape.alpha = 1;
      analyzeProgressTween = TweenMax.to(analyzeProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_analysis_stored(message:String):void {
      loader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, nestDataCompleteHandler);
      var request:URLRequest = new URLRequest(message);
      loader.load(request);
    }

    private function nestDataCompleteHandler(e:Event):void {
      analyzeProgressTween.pause();
      analyzeProgressShape.alpha = 1;
      var data:Object = JSON.decode(loader.data);
      player.data = data;

      addChild(cubes);
      removeChild(statusSprite);
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

    private function log(o:Object):void {
      //ExternalInterface.call('console.log', o.toString());
    }
  }
}
