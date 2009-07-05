package com.ryanberdeen.remix.player {
  import com.ryanberdeen.nest.IPositionSource;
  import com.ryanberdeen.remix.Logger;

  import gs.TweenMax;

  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.SampleDataEvent;
  import flash.external.ExternalInterface;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundTransform;
  import flash.utils.ByteArray;

  public class RemixPlayer extends EventDispatcher {
    private static const BUFFER_SIZE:int = 8192;
    private var sourceSound:Sound;
    private var outputSound:Sound;
    private var soundChannel:SoundChannel;
    private var playing:Boolean;
    private var _sampleRanges:Array;
    private var sampleRangeIndex:int;

    private var _sampleCount:Number;

    private var startSample:Number;
    private var endSample:Number;
    private var currentSample:Number;
    private var finished:Boolean;

    public function RemixPlayer(sourceSound:Sound):void {
      this.sourceSound = sourceSound;
      outputSound = new Sound();

      _sampleCount = sourceSound.length / 44.1;

      outputSound.addEventListener(SampleDataEvent.SAMPLE_DATA, function(e:SampleDataEvent):void {
        var samplesRead:int = 0;
        while (!finished && samplesRead < BUFFER_SIZE) {
          var samplesLeft:int = endSample - currentSample;
          var samplesToRead:int = Math.min(samplesLeft, BUFFER_SIZE - samplesRead);
          var bytes:ByteArray = new ByteArray();
          sourceSound.extract(bytes, samplesToRead, currentSample);
          e.data.writeBytes(bytes);

          samplesRead += samplesToRead;
          currentSample += samplesToRead;
          if (currentSample == endSample) {
            sampleRangeIndex++;
            if (sampleRangeIndex == _sampleRanges.length) {
              finished = true;
            }
            else {
              startSample = _sampleRanges[sampleRangeIndex][0];
              endSample = _sampleRanges[sampleRangeIndex][1];
              currentSample = startSample;
            }
          }
        }
      });
    }

    public function get sampleCount():Number {
      return _sampleCount;
    }

    public function set sampleRanges(sampleRanges:Array):void {
      _sampleRanges = sampleRanges;

      sampleRangeIndex = 0;

      startSample = _sampleRanges[sampleRangeIndex][0];
      endSample = _sampleRanges[sampleRangeIndex][1];
      currentSample = startSample;
    }

    public function start():void {
      if (soundChannel != null) {
        soundChannel.removeEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
      }

      soundChannel = outputSound.play();
      soundChannel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
      playing = true;
    }

    public function stop():void {
      soundChannel.stop();
      playing = false;
    }

    public function get position():Number {
      return soundChannel.position;
    }

    private function soundCompleteHandler(e:Event):void {
      dispatchEvent(new Event(Event.COMPLETE));
    }
  }
}
