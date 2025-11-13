import {Markdown} from '@luvi/lv-markdown-in'
import { IMessage, NotifyEventType } from 'type'
import chatControl from '../controller/chatController'
import { ChatDateSource } from '../model/ChatDateSource'
import { ChatMessageItem } from './ChatMessageItem'
import { ChatObserver } from './ChatSubject'

@ComponentV2
export struct testView {
  @Local response: string = ''
  @Local request: string = ''
  private update = (data: string,eventType:NotifyEventType) => { this.response += data}
  private curMeg: IMessage = {content:' ',role:'user'}
  private chatObserver: ChatObserver = new ChatObserver(this.update)
  private chatDataSource: ChatDateSource = new ChatDateSource()
  private cout: number = 0;
  aboutToAppear(): void {
    chatControl.registerObserver(this.chatObserver)
    this.chatDataSource.setDataArr([])
  }

  build() {
    WaterFlow() {
      LazyForEach(this.chatDataSource,(item: IMessage) => {
        FlowItem(){
          Text(item.content as string)
        }
      },(item: IMessage) => JSON.stringify(item))
      FlowItem(){
        Column(){
          Button('push')
            .onClick(() => {
              this.chatDataSource.pushData(this.curMeg)
            })
          Button('change')
            .onClick(() => {
              this.curMeg.content += '123'
              this.chatDataSource.lastDataChange()
            })
          Button('init')
            .onClick(() => {
              this.curMeg = {content: `new${this.cout}`,role:'user'}
            })
        }
      }
    }
    .rowsGap(16)
  }
}
let arr: IMessage[] = [
  {content: '1234',role:'user'},
  {content: '1234',role:'assistant'},
  {content: '1234',role:'user'},
  {content: '1234',role:'assistant'},
  {content: '1234',role:'user'},
]