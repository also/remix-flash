package com.ryanberdeen.remix.api {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.nest.api.TrackApi;
  import com.ryanberdeen.remix.player.DiscontinuousSampleSource;
  import com.ryanberdeen.remix.player.RemixPlayer;
  import com.ryanberdeen.remix.player.SoundSampleSource;

  import flash.display.Loader;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.DataEvent;
  import flash.events.HTTPStatusEvent;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.net.FileReference;
  import flash.net.URLLoader;
  import flash.net.URLRequest;

  [SWF(backgroundColor="#000000", frameRate="60", width="60", height="20")]
  public class Api extends Sprite {
    public static var options:Object;
    private var sound:Sound;
    private var analysisLoader:URLLoader;
    private var remixPlayer:RemixPlayer;
    private var analysis:Object;
    private var fileReference:FileReference;
    private var fileReferenceLoaded:Boolean;
    private var trackApi:TrackApi;

    public function Api():void{
      stage.addEventListener(MouseEvent.CLICK, clickHandler);
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.rootSwfUrl ||= 'http://localhost:3000/swfs';

      trackApi = new TrackApi();
      trackApi.apiKey = '';

      ExternalInterface.addCallback('loadSound', loadSound);
      ExternalInterface.addCallback('loadAnalysis', loadAnalysis);
      ExternalInterface.addCallback('setSampleRangesJson', setSampleRangesJson);
      ExternalInterface.addCallback('start', start);
      ExternalInterface.addCallback('stop', stop);
      ExternalInterface.addCallback('reset', reset);

      ExternalInterface.call('__remix_api.__swfLoadedHandler');
    }

    private function clickHandler(e:Event):void {
      if (fileReferenceLoaded) {
        uploadFile();
      }
      else {
        chooseFile()
      }
    }

    private function chooseFile():void {
      fileReference = new FileReference();
      fileReference.addEventListener(Event.SELECT, function(e:Event):void {
        fileReference.addEventListener(Event.COMPLETE, function(e:Event):void {
          fileReferenceLoaded = true;
        });
        fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, handleEvent);
        fileReference.addEventListener(ProgressEvent.PROGRESS, handleEvent);
        fileReference.addEventListener(IOErrorEvent.IO_ERROR, handleEvent);
        fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleEvent);
        fileReference.load();
      });
      fileReference.browse();
    }

    private function uploadFile():void {
      var request:URLRequest = trackApi.prepareFileDataUploadRequest(fileReference.data);
      var loader:URLLoader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, function(e:Event):void {
        ExternalInterface.call('__remix_api.log', loader.data);
      });
      loader.addEventListener(ProgressEvent.PROGRESS, handleEvent);
      loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleEvent);
      loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleEvent);
      loader.addEventListener(IOErrorEvent.IO_ERROR, handleEvent);

      loader.load(request);
    }

    private function handleEvent(e:Event):void {
      ExternalInterface.call('__remix_api.log', e.toString());
    }

    public function reset():void {
      resetSound();
      resetAnalysis();
      analysis = null;
    }

    public function loadSound(trackId:int):void {
      resetSound();

      sound = new Sound();
      sound.addEventListener(Event.COMPLETE, soundLoadedHandler);
      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));
    }

    private function soundLoadedHandler(e:Event):void {
      sound.removeEventListener(Event.COMPLETE, soundLoadedHandler);

      ExternalInterface.call('__remix_api.__loadSoundCompleteHandler');
    }

    public function resetSound():void {
      if (sound != null) {
        sound.removeEventListener(Event.COMPLETE, soundLoadedHandler);
        try {
          sound.close();
        }
        catch (e:Error) { /* don't care */ }
        ExternalInterface.call('__remix_api.__soundResetHandler');
      }

      sound = null;
      resetPlayer();
    }

    public function loadAnalysis(trackId:int):void {
      resetAnalysis();

      analysisLoader = new URLLoader();
      analysisLoader.addEventListener(Event.COMPLETE, analysisLoadedHandler);
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks/' + trackId + '/analysis');
      analysisLoader.load(request);
    }

    private function analysisLoadedHandler(e:Event):void {
      analysisLoader.removeEventListener(Event.COMPLETE, analysisLoadedHandler);

      analysis = JSON.decode(analysisLoader.data);
      ExternalInterface.call('__remix_api.__loadAnalysisCompleteHandler', analysis);
    }

    public function resetAnalysis():void {
      if (analysisLoader != null) {
        analysisLoader.removeEventListener(Event.COMPLETE, analysisLoadedHandler);
        try {
          analysisLoader.close();
        }
        catch (e:Error) { /* don't care */ }
        ExternalInterface.call('__remix_api.__analysisResetHandler');
      }

      analysisLoader = null;
      analysis = null;
    }

    public function setSampleRangesJson(sampleRangesJson:String):void {
      setSampleRanges(JSON.decode(sampleRangesJson));
    }

    public function setSampleRanges(sampleRanges:Array):void {
      if (!sound) {
        return;
      }

      resetPlayer();

      remixPlayer = new RemixPlayer();
      remixPlayer.addEventListener(Event.SOUND_COMPLETE, playerSoundCompleteHandler);
      var sampleSource:DiscontinuousSampleSource = new DiscontinuousSampleSource();
      sampleSource.sampleRanges = sampleRanges;
      sampleSource.sampleSource = new SoundSampleSource(sound);

      remixPlayer.sampleSource = sampleSource;
    }

    private function playerSoundCompleteHandler(e:Event):void {
      ExternalInterface.call('__remix_api.__soundCompleteHandler');
    }

    public function resetPlayer():void {
      if (remixPlayer != null) {
        remixPlayer.removeEventListener(Event.SOUND_COMPLETE, playerSoundCompleteHandler);
        remixPlayer.stop();
        ExternalInterface.call('__remix_api.__playerResetHandler');
      }

      remixPlayer = null;
    }

    public function start():void {
      if (remixPlayer != null) {
        remixPlayer.start();
      }
    }

    public function stop():void {
      if (remixPlayer != null) {
        remixPlayer.stop();
      }
    }
  }
}
