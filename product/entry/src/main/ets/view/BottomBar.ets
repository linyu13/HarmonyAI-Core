import { ChatInput } from "aichat"

@ComponentV2
export struct BottomBar {

  build() {
    Row() {
      ChatInput()
        .layoutWeight(1)
      Button('123')
        .width(50)
    }
    .width('100%')
    .position({bottom:0})
    .height(50)
    .position({bottom:0})
  }
}