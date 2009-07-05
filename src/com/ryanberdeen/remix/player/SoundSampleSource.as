package com.ryanberdeen.remix.player {
  import flash.media.Sound;
  import flash.utils.ByteArray;

  public class SoundSampleSource implements ISampleSource {
    private var sound:Sound;

    public function SoundSampleSource(sound:Sound):void {
      this.sound = sound;
    }

    public function extract(target:ByteArray, length:Number, startPosition:Number = -1):Number {
      return sound.extract(target, length, startPosition);
    }
  }
}
