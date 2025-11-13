@ComponentV2
export struct TopBar {
  build() {
    Stack({alignContent: Alignment.Center}){
      Row() {
        Image($r('app.media.menu'))
          .width(25)
          .height(25)
        Row({ space: 16 }) {
          Image($r('app.media.sound'))
            .width(25)
            .height(25)
          Image($r('app.media.new_chat'))
            .width(25)
            .height(25)
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceBetween)
      Row(){
        Text('慧影')
          .fontColor(20)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    //.padding({top:})
    .position({ top: 0 })
    .height(50)
  }
}