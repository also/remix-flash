package com.ryanberdeen.remix {
  import com.adobe.net.MimeTypeMap;
  import com.adobe.serialization.json.JSON;
  import com.elctech.S3UploadOptions;
  import com.elctech.S3UploadRequest;

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.net.FileReference;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;

  import gs.TweenMax;

  public class Uploader extends Sprite {
    private var main:Main;
    private var button:Button;
    private var loader:URLLoader;
    private var trackId:int;
    private var uploadOptions:S3UploadOptions = new S3UploadOptions();
    private var fileReference:FileReference;
    private var statusSprite:Sprite;
    private var uploadProgressShape:Shape;
    private var submissionProgressShape:Shape;
    private var submisionProgressTween:TweenMax;
    private var analyzeProgressShape:Shape;
    private var analyzeProgressTween:TweenMax;

    public function Uploader(main:Main):void {
      this.main = main;
      button = new Button('Select file…');
      button.addEventListener(MouseEvent.CLICK, browseClickHandler);
      addChild(button);

      statusSprite = new Sprite();
      statusSprite.x = (main.stage.stageWidth - 300) / 2;
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
      uploadProgressShape.scaleX = 0;
      statusSprite.addChild(uploadProgressShape);

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
      var request:URLRequest = new URLRequest(Main.options.rootUrl + '/tracks');
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
      main.trackId = trackId;

      var request:S3UploadRequest = new S3UploadRequest(uploadOptions);

      request.addEventListener(Event.OPEN, function(event:Event):void {
        main.log(event);
      });
      request.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        uploadProgressShape.scaleX = event.bytesLoaded / event.bytesTotal;
      });
      request.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
        main.log(event);
      });
      request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
        main.log(event);
      });
      request.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:Event):void {
        main.connector.send('remix_worker add_uploaded_track ' + trackId);
        main.log(event);
      });

      try {
        request.upload(fileReference);
      }
      catch(e:Error) {
        main.log("An error occurred: " + e);
      }
    }

    public function handle_started(message:String):void {
      var args:Array = message.split(' ');
      main.loadSound();

      submisionProgressTween = TweenMax.to(submissionProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_submitted(message:String):void {
      submisionProgressTween.pause();
      submissionProgressShape.alpha = 1;
      analyzeProgressTween = TweenMax.to(analyzeProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_analysis_stored(message:String):void {
      analyzeProgressTween.pause();
      analyzeProgressShape.alpha = 1;
      main.loadAnalysis();
    }
  }
}
