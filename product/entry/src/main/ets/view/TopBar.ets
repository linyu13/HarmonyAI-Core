@ComponentV2
export struct TopBar{
  build() {
    Row(){
      Text('慧影')
        .fontColor(20)
    }

    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(50)
    .position({top:0})
  }
}