package com.ryanberdeen.remix {
  import flash.net.LocalConnection;

  internal class PlayerConnection extends LocalConnection {
    private var player:Player;

    public function PlayerConnection(player:Player):void {
      this.player = player;
    }

    public function setTrackId(trackIdString:String):void {
      player.trackId = new Number(trackIdString);
    }

    public function loadSound():void {
      player.loadSound();
    }

    public function loadAnalysis():void {
      player.loadAnalysis();
    }
  }
}