package com.ryanberdeen.remix.display {
  import com.ryanberdeen.nest.NestPlayer;
  import com.ryanberdeen.remix.player.Player;

  import flash.events.Event;
  import flash.events.ProgressEvent;

  public interface IPlayerDisplay {
    function handleSoundLoadProgress(e:ProgressEvent):void;

    function prepare():void;

    function set player(player:Player):void;

    function set data(data:Object):void;

    function set nestPlayer(nestPlayer:NestPlayer):void;
  }
}