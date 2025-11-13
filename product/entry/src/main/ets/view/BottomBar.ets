import { ChatInput } from 'aichat'
import { router } from '@kit.ArkUI'
import 'imagefilters/src/main/ets/view/ImagePicker'

@ComponentV2
export struct BottomBar {
  build() {
    Row() {
      ChatInput()
        .layoutWeight(1)
      Button("111")
        .onClick(() => {
          this.getUIContext().getRouter().pushNamedRoute({
            name: 'ImagePicker'
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
              return;
            }
            console.info('Invoke pushUrl succeeded.');
          })
        })
    }
    .width('100%')
    .position({ bottom: 0 })
    .height(50)
    .position({ bottom: 0 })
  }
}