package com.ryanberdeen.remix.display {
  import com.ryanberdeen.nest.INestPlayer;
  import com.ryanberdeen.nest.NestVis;
  import com.ryanberdeen.remix.player.IPlayer;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;

  public class TimelineDisplay extends Sprite implements IPlayerDisplay {
    private var nestVis:NestVis;
    private var _player:IPlayer;
    private var _nestPlayer:INestPlayer;

    public function set player(player:IPlayer):void {
      _player = player;
    }

    public function set nestPlayer(nestPlayer:INestPlayer):void {
      _nestPlayer = nestPlayer;
    }

    public function set data(data:Object):void {
      // TODO should not depend on stage
      nestVis = new NestVis(data, stage.stageWidth);
      addChild(nestVis);
      _nestPlayer.positionListener = nestVis;
    }

    public function handleSoundLoadProgress(e:ProgressEvent):void {}

    public function prepare():void {
      _player.start();
    }
  }
}
