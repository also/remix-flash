package com.ryanberdeen.remix {
  import com.ryanberdeen.cubes.Cubes;
  import com.ryanberdeen.nest.NestPlayer;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.ProgressEvent;
  import flash.utils.Timer;

  public class CubeDisplay extends Sprite implements PlayerDisplay {
    private var _player:Player;
    private var cubes:Cubes;

    private var startTimer:Timer;

    public function set player(player:Player):void {
      _player = player;
      cubes = new Cubes();
      addChild(cubes);
      width = 0;
    }

    public function set nestPlayer(nestPlayer:NestPlayer):void {
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
      width = _player.stage.stageWidth * (e.bytesLoaded / e.bytesTotal);
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
