package com.ryanberdeen.remix {
  import flash.events.ProgressEvent;
  import flash.external.ExternalInterface;

  public class Logger {
    public function log(o:Object):void {
      ExternalInterface.call('console.log', o.toString());
    }
  }
}
