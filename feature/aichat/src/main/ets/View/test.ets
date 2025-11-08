import {IObserver} from 'type'
import { ChatController } from '../controller/chatController'
import { ChatObserver } from './ChatSubject'

@ComponentV2
export struct testView {
  @Local response: string = ''
  @Local request: string = ''
  private update = (data: string) => { this.response += data}
  private controller: ChatController = new ChatController()
  private chatObserver: ChatObserver = new ChatObserver(this.update)

  aboutToAppear(): void {
    this.controller.registerObserver(this.chatObserver)
  }

  build() {
    Column() {
      Column({ space: 16 }) {
        Row({ space: 5 }) {
          TextInput()
            .onChange((res) => {
              this.request = res;
            })
            .layoutWeight(1)
          Button('发送')
            .width(100)
            .onClick(() => {
              this.controller.request(this.request)
            })
        }
        .width('100%')

        Row() {
          Text(this.response)
        }
        .width('100%')
        //MainPage({ dataPreferences: dataPreferences_, getRdbStore: getRdbStore })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Center)
    }
  }
}