package com.ryanberdeen.remix.player {
  import flash.utils.ByteArray;

  public interface ISampleSource {
    function extract(target:ByteArray, length:Number, startPosition:Number = -1):Number;
  }
}