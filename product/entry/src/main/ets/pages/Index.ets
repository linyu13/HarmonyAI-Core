import { ChatView, testView} from 'aichat'
import { BottomBar } from '../view/BottomBar'
import { TopBar } from '../view/TopBar'
import { KeyboardAvoidMode, UIContext } from '@kit.ArkUI';

let arr: number[] = []
for(let i = 0; i<100; i++){
  arr.push(i);
}

@Entry
@ComponentV2
struct Index {
  private inputController: TextInputController = new TextInputController()
  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET)
  }
  build() {

     Column(){
      TopBar()
        .width('100%')

       Scroll(){
         Column(){
           ForEach(arr,(item: number) => {
             Text(item.toString())
               .height(80)
           })
         }
         .width('100%')
         .backgroundColor(Color.Pink)
       }
       .layoutWeight(1)
       .width('100%')

       BottomBar({controller: this.inputController})
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