package com.ryanberdeen.remix.display {
  import com.ryanberdeen.nest.NestPlayer;
  import com.ryanberdeen.nest.NestVis;
  import com.ryanberdeen.remix.player.Player;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;

  public class TimelineDisplay extends Sprite implements IPlayerDisplay {
    private var nestVis:NestVis;
    private var _player:Player;
    private var _nestPlayer:NestPlayer;

    public function set player(player:Player):void {
      _player = player;
    }

    public function set nestPlayer(nestPlayer:NestPlayer):void {
      _nestPlayer = nestPlayer;
    }

    public function set data(data:Object):void {
      nestVis = new NestVis(data, _player.stage.stageWidth);
      addChild(nestVis);
      _nestPlayer.positionListener = nestVis;
    }

    public function handleSoundLoadProgress(e:ProgressEvent):void {}

    public function prepare():void {
      _player.start();
    }
  }
}
