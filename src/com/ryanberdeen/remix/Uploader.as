package com.ryanberdeen.remix {
  import com.adobe.net.MimeTypeMap;
  import com.adobe.serialization.json.JSON;
  import com.elctech.S3UploadOptions;
  import com.elctech.S3UploadRequest;
  import com.ryanberdeen.connector.Connector;

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.external.ExternalInterface;
  import flash.net.FileReference;
  import flash.net.LocalConnection;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.text.TextField;
  import flash.text.TextFormat;

  import gs.TweenMax;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="60")]
  public class Uploader extends Sprite {
    private static var logger:Logger = new Logger();
    [Embed(mimeType="application/x-font", source="/fonts/HelveticaNeueLight.ttf", fontName="HelveticaNeueLight")]
    private var helveticaNeueLightFontClass:Class;

    [Embed(mimeType="application/x-font", source="/fonts/HelveticaNeue.ttf", fontName="HelveticaNeue")]
    private var HelveticaNeueBoldFontClass:Class;

    private var options:Object;
    private var connector:Connector;
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
    private var localConnection:LocalConnection;

    public function Uploader():void {
      stage.scaleMode = 'noScale';
      stage.align = 'TL';

      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.connectorHost ||= 'localhost';
      options.connectorPort ||= 1843;

      localConnection = new LocalConnection();

      connector = new Connector();
      connector.connect(options.connectorHost, options.connectorPort);
      connector.subscribe('remix_worker_event', this);

      button = new Button('Select file…', 0x42ffbc, 0x444444);
      button.y = 60 - button.height;
      button.addEventListener(MouseEvent.CLICK, browseClickHandler);
      addChild(button);

      statusSprite = new Sprite();
      statusSprite.x = button.width + 1;
      addChild(statusSprite);

      with (statusSprite.graphics) {
        for (var i:int = 0; i < 3; i++) {
          beginFill(0xcccccc);
          drawRect(i * 301, 0, 300, 60);
          endFill();
        }

        beginFill(0xaaaaaa);
        drawRect(903, 60 - button.height, stage.stageWidth - 903, 60);
        endFill();
      }

      uploadProgressShape = createProgressShape(0x555555);
      uploadProgressShape.scaleX = 0;
      statusSprite.addChild(uploadProgressShape);

      var uploadStepDescriptionSprite:Sprite = createStepDescriptionSprite(1, 'Upload');
      statusSprite.addChild(uploadStepDescriptionSprite);

      submissionProgressShape = createProgressShape(0x555555);
      submissionProgressShape.x = 301;
      submissionProgressShape.alpha = 0;
      statusSprite.addChild(submissionProgressShape);

      var submissionStepDescriptionSprite:Sprite = createStepDescriptionSprite(2, 'Submit');
      submissionStepDescriptionSprite.x = 301;
      statusSprite.addChild(submissionStepDescriptionSprite);

      analyzeProgressShape = createProgressShape(0x555555);
      analyzeProgressShape.x = 602;
      analyzeProgressShape.alpha = 0;
      statusSprite.addChild(analyzeProgressShape);

      var analyzeStepDescriptionSprite:Sprite = createStepDescriptionSprite(3, 'Analyze');
      analyzeStepDescriptionSprite.x = 602;
      statusSprite.addChild(analyzeStepDescriptionSprite);
    }

    private function createProgressShape(color:uint):Shape {
      var result:Shape = new Shape();
      with (result.graphics) {
        beginFill(color);
        drawRect(0, 0, 300, 60);
        endFill();
      }
      return result;
    }

    private function createStepDescriptionSprite(number:Number, description:String):Sprite {
      var sprite:Sprite = new Sprite();
      var numberFormat:TextFormat = new TextFormat();
      numberFormat.font = 'HelveticaNeue';
      numberFormat.size = 24;
      var numberTextField:TextField = new TextField();
      numberTextField.antiAliasType = 'advanced';
      numberTextField.embedFonts = true;
      numberTextField.defaultTextFormat = numberFormat;
      numberTextField.text = number.toString();
      numberTextField.x = 5;
      sprite.addChild(numberTextField);
      var descriptionFormat:TextFormat = new TextFormat();
      descriptionFormat.font = 'HelveticaNeueLight';
      descriptionFormat.size = 18;
      var descriptionTextField:TextField = new TextField();
      descriptionTextField.antiAliasType = 'advanced';
      descriptionTextField.embedFonts = true;
      descriptionTextField.defaultTextFormat = descriptionFormat;
      descriptionTextField.text = description;
      descriptionTextField.x = 5;
      descriptionTextField.y = 30;
      sprite.addChild(descriptionTextField);
      return sprite;
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
      logger.log('Creating track');
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
      logger.log('Track created');
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
      localConnection.send('com.ryanberdeen.remix.Player', 'setTrackId', trackId);

      var request:S3UploadRequest = new S3UploadRequest(uploadOptions);

      request.addEventListener(Event.OPEN, function(event:Event):void {
        logger.log(event);
      });
      request.addEventListener(ProgressEvent.PROGRESS, function(event:ProgressEvent):void {
        uploadProgressShape.scaleX = event.bytesLoaded / event.bytesTotal;
      });
      request.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
        logger.log(event);
      });
      request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
        logger.log(event);
      });
      request.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:Event):void {
        logger.log('Track uploaded');
        localConnection.send('com.ryanberdeen.remix.Player', 'loadSound');
        logger.log('Submitting track');
        connector.send('remix_worker add_uploaded_track ' + trackId);
        logger.log(event);
      });

      try {
        logger.log('Uploading track');
        request.upload(fileReference);
      }
      catch(e:Error) {
        logger.log("An error occurred: " + e);
      }
    }

    public function handle_started(message:String):void {
      var args:Array = message.split(' ');

      submisionProgressTween = TweenMax.to(submissionProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_submitted(message:String):void {
      logger.log('Track submitted');
      submisionProgressTween.pause();
      submissionProgressShape.alpha = 1;
      analyzeProgressTween = TweenMax.to(analyzeProgressShape, 1, {alpha: 1, yoyo: 0});
    }

    public function handle_track_analysis_stored(message:String):void {
      logger.log('Track analyzed');
      analyzeProgressTween.pause();
      analyzeProgressShape.alpha = 1;
      localConnection.send('com.ryanberdeen.remix.Player', 'loadAnalysis');
      ExternalInterface.call('handleTrackAnalyzed');
    }
  }
}
