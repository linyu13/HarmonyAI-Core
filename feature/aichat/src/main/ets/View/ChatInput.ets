import chatControl  from "../controller/chatController"
@ComponentV2
export struct ChatInput {
  @Local request: string = ''
  @Consumer('textControl') controller: TextInputController = new TextInputController()

  build() {
    Row({ space: 5 }) {
      TextInput({ controller: this.controller ,text: this.request})
        .onChange((res) => {
          this.request = res;
        })
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.Block)
      Button('发送')
        .width(100)
        .onClick(() => {
          chatControl.request(this.request)
          this.request = ''
          this.controller.stopEditing()
        })
    }
    .height(50)
  }
}