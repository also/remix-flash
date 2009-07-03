package com.ryanberdeen.remix {
  import flash.display.Sprite;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class Button extends Sprite {
    private var textField:TextField;
    public function Button(text:String, color:uint = 0xaaaaaa, textColor:uint = 0x000000):void {
      buttonMode = true;
      mouseChildren = false;
      tabChildren = false;

      var format:TextFormat = new TextFormat();
      format.font = 'HelveticaNeueLight';
      format.size = 24;

      textField = new TextField();
      textField.antiAliasType = 'advanced';
      textField.textColor = textColor;
      textField.embedFonts = true;
      textField.defaultTextFormat = format;
      textField.text = text;
      textField.width = textField.textWidth + 5;
      textField.height = textField.textHeight + 5;

      var height:Number = textField.textHeight + 10;
      textField.x = 5;

      with (graphics) {
        beginFill(color);
        drawRect(0, 0, textField.textWidth + 10, height);
        endFill();
      }
      addChild(textField);
    }
  }
}
