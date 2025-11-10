@ComponentV2
export struct BottomBar {
  @Require @Param controller: TextInputController
  build() {
    Row({ space: 5 }) {
      TextInput({controller: this.controller})
        .onChange((res) => {

        })
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.Block)
      Button('发送')
        .width(100)
        .onClick(() => {

        })
    }
    .width('100%')
    .position({bottom:0})
    .height(50)
  }
}