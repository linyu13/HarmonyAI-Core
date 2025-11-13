import { ChatDateSource } from '../model/ChatDateSource'
import { ChatIntroduce } from './Chatintroduce'
import model from '../model/GetAIResponseModel'
import { ChatMessageItem } from './ChatMessageItem'
import { BaseDataSource } from 'utils'
import { IMessage, IObserver, NotifyEventType } from 'type'
import { ChatMessageList } from './ChatMessageList'
import { ChatObserver } from './ChatObserver'
import chatControl from '../controller/chatController'

@ComponentV2
export struct ChatView{
  @Local isStart: boolean = true;
  @Local curMeg: IMessage = {content:' ',role:'assistant'};
  private chatDataSource: ChatDateSource = new ChatDateSource()
  private scrollerControl: Scroller = new Scroller()
  private update = (data: string, eventType: NotifyEventType) => {
    this.isStart = false;
    if(eventType == NotifyEventType.CONTROL_AI_UPDATE){
      this.curMeg.content += data;
      this.chatDataSource.lastDataChange()
      this.scrollerControl.scrollEdge(Edge.Bottom)
    }else if(eventType == NotifyEventType.CONTROL_USER_UPDATE){
      let userMeg: IMessage = {content: data, role: 'user'}
      this.chatDataSource.pushData(userMeg)
      this.chatDataSource.pushData(this.curMeg)
    }else if(eventType == NotifyEventType.MODEL){
      this.curMeg = {content:' ',role:'assistant'};
    }
  }
  private observer: IObserver = new ChatObserver(this.update)
  aboutToAppear(): void {
    let megList = model.getMegList()
    this.isStart = megList.length == 0;
    this.chatDataSource.setDataArr(megList);
    model.registerObserver(this.observer)
    chatControl.registerObserver(this.observer)
  }

  build() {
    if(this.isStart){
      ChatIntroduce()
    }else {
     ChatMessageList({
       dataSource: this.chatDataSource,
       scrollerControl: this.scrollerControl
     })
    }
  }
}

