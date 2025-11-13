import { ChatView, testView } from 'aichat'
import { BottomBar } from '../view/BottomBar'
import { TopBar } from '../view/TopBar'
@Entry
@ComponentV2
struct Index {
  @Provider('textControl') inputController: TextInputController = new TextInputController()
  build() {

     Column(){
      TopBar()
        .width('100%')
       //对话列表
       Column(){
        ChatView()
         //testView()
       }
       .layoutWeight(1)
       .width('100%')
       BottomBar()
        .width('100%')
    }
    .height('100%')
    .width('100%')
    .padding({left:10,right:10})
    .onTouch(() => {
      this.inputController.stopEditing()
    })
  }
}