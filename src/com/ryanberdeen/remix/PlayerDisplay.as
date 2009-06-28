package com.ryanberdeen.remix {
  import com.ryanberdeen.nest.NestPlayer;

  import flash.events.Event;
  import flash.events.ProgressEvent;

  public interface PlayerDisplay {
    function handleSoundLoadProgress(e:ProgressEvent):void;

    function prepare():void;

    function set player(player:Player):void;

    function set data(data:Object):void;

    function set nestPlayer(nestPlayer:NestPlayer):void;
  }
}
