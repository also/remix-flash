package com.ryanberdeen.remix.api {
  import com.adobe.serialization.json.JSON;
  import com.ryanberdeen.remix.Logger;
  import com.ryanberdeen.remix.player.RemixPlayer;

  import flash.display.Loader;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.net.URLLoader;
  import flash.net.URLRequest;

  [SWF(backgroundColor="#FFFFFF", frameRate="60", width="0", height="0")]
  public class Api extends Sprite {
    public static var options:Object;
    private var sound:Sound;
    private var remixPlayer:RemixPlayer;
    private var analysis:Object;

    public function Api():void{
      options = root.loaderInfo.parameters;
      options.rootUrl ||= 'http://localhost:3000';
      options.rootSwfUrl ||= 'http://localhost:3000/swfs';

      ExternalInterface.addCallback('loadSound', loadSound);
      ExternalInterface.addCallback('loadAnalysis', loadAnalysis);
      ExternalInterface.addCallback('remix', remix);

      ExternalInterface.call('__remix_api.__swfLoadedHandler');
    }

    public function reset():void {
      sound = null;
      if (remixPlayer != null) {
        remixPlayer.stop();
      }
      remixPlayer = null;
      analysis = null;
    }

    public function loadSound(trackId:int):void {
      if (remixPlayer != null) {
        remixPlayer.stop();
      }

      sound = new Sound();
      sound.addEventListener(Event.COMPLETE, function(e:Event):void {
        ExternalInterface.call('__remix_api.__loadSoundCompleteHandler');
      });

      sound.load(new URLRequest(options.rootUrl + '/tracks/' + trackId + '/original'));
    }

    public function loadAnalysis(trackId:int):void {
      var analysisLoader:URLLoader = new URLLoader();
      analysisLoader.addEventListener(Event.COMPLETE, function(e:Event):void {
        analysis = JSON.decode(analysisLoader.data);

        ExternalInterface.call('__remix_api.__loadAnalysisCompleteHandler', analysis);
      });
      var request:URLRequest = new URLRequest(options.rootUrl + '/tracks/' + trackId + '/analysis');
      analysisLoader.load(request);
    }

    public function remix(sampleRangesJson:String):void {
      var sampleRanges:Array = JSON.decode(sampleRangesJson);
      if (!sound) {
        return;
      }

      remixPlayer = new RemixPlayer(sound);

      remixPlayer.sampleRanges = sampleRanges;
      remixPlayer.start();
    }
  }
}
