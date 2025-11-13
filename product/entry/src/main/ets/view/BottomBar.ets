import { ChatInput } from "aichat"

@ComponentV2
export struct BottomBar {

  build() {
    Row() {
      ChatInput()
    }
    .width('100%')
    .position({bottom:0})
    .height(50)
    .position({bottom:0})
  }
}