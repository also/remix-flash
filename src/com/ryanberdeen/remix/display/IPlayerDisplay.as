package com.ryanberdeen.remix.display {
  import com.ryanberdeen.nest.INestPlayer;
  import com.ryanberdeen.remix.player.IPlayer;

  import flash.events.Event;
  import flash.events.ProgressEvent;

  public interface IPlayerDisplay {
    function handleSoundLoadProgress(e:ProgressEvent):void;

    function prepare():void;

    function set player(player:IPlayer):void;

    function set data(data:Object):void;

    function set nestPlayer(nestPlayer:INestPlayer):void;
  }
}
