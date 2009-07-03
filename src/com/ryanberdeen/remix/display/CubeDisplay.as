package com.ryanberdeen.remix.display {
  import com.ryanberdeen.cubes.Cubes;
  import com.ryanberdeen.nest.INestPlayer;
  import com.ryanberdeen.remix.Logger;
  import com.ryanberdeen.remix.player.IPlayer;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.utils.Timer;

  public class CubeDisplay extends Sprite implements IPlayerDisplay {
    private var _player:IPlayer;
    private var cubes:Cubes;

    private var startTimer:Timer;

    public function set player(player:IPlayer):void {
      _player = player;
      cubes = new Cubes();
      addChild(cubes);
      width = 0;
    }

    public function set nestPlayer(nestPlayer:INestPlayer):void {
      nestPlayer.options = {
        bars: {
          triggerStartHandler: cubes.barTriggerHandler,
          triggerStartOffset: -50
        },
        beats: {
          triggerStartHandler: cubes.beatTriggerHandler,
          triggerStartOffset: -100
        },
        tatums: {
          triggerStartHandler: cubes.tatumTriggerHandler,
          triggerStartOffset: -50
        }
      };
    }

    public function set data(data:Object):void {}

    public function handleSoundLoadProgress(e:ProgressEvent):void {
      // TODO should not be based on stage
      width = stage.stageWidth * (e.bytesLoaded / e.bytesTotal);
    }

    public function prepare():void {
      cubes.dropCubes();
      startTimer = new Timer(3000, 1);
      startTimer.addEventListener('timer', function(e:Event):void {
        _player.start();
      });
      startTimer.start();
    }
  }
}
