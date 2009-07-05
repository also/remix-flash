package com.ryanberdeen.remix.player {
  import flash.media.Sound;
  import flash.utils.ByteArray;

  public class SpeedChangingSampleSource implements ISampleSource {
    private var _sampleSource:ISampleSource;
    private var _playbackSpeed:Number = 1;
    private var _phase:Number = 0;

    public function set sampleSource(sampleSource:ISampleSource):void {
      _sampleSource = sampleSource;
    }

    public function set playbackSpeed(playbackSpeed:Number):void {
      if (playbackSpeed < 0) {
        throw new ArgumentError('Playback speed must be positive');
      }
      _playbackSpeed = playbackSpeed;
    }

    public function extract(target:ByteArray, length:Number, x:Number = -1):Number {
      var l:Number;
      var r:Number;
      var p:int;

      var loadedSamples:ByteArray = new ByteArray();
      var startPosition:int = int(_phase);
      _sampleSource.extract(loadedSamples, length * _playbackSpeed, startPosition);
      loadedSamples.position = 0;

      while (loadedSamples.bytesAvailable > 0) {
        p = int(_phase - startPosition) * 8;

        if (p < loadedSamples.length - 8 && target.length <= length * 8) {
          loadedSamples.position = p;

          target.writeBytes(loadedSamples, p, 8);
        }
        else {
          loadedSamples.position = loadedSamples.length;
        }

        _phase += _playbackSpeed;
      }

      return target.length / 8;
    }
  }
}
