import { AiMessage, IObserver, ISubject, NotifyEventType, ResData, UserMessage } from "type";
import AIResponseUtils from '../model/GetAIResponseModel'

class ChatController implements ISubject {
  private fullContent:string = ''
  private observers: IObserver[] = []

  request(reqContent: string){
    let requestBody: UserMessage = {
      content: reqContent,
      role: 'user'
    }
    this.notifyObserver(reqContent, NotifyEventType.CONTROL_USER_UPDATE)
    AIResponseUtils.requestChat(requestBody,(chunks: ResData[]) => {
      let curContent: string = ''
      chunks.map((chunk: ResData) => {
        if(chunk.choices[0].finish_reason == "stop"){
          let aiMessage: AiMessage = {
            content:this.fullContent,
            role: "assistant"
          }
          console.log('[chatController]' + this.fullContent)
          AIResponseUtils.requestOver(aiMessage)
        }else {
          curContent += chunk.choices[0].delta.content;
          this.notifyObserver(chunk.choices[0].delta.content || '',NotifyEventType.CONTROL_AI_UPDATE);
        }
      })
      this.fullContent += curContent;
    })

  }

  cancel(){
    AIResponseUtils.requestCancel()
  }

  registerObserver(observer: IObserver): void {
    if(!this.observers.includes(observer)){
      this.observers.push(observer)
    }
  }

  removeObserver(observer: IObserver): void {
    this.observers = this.observers.filter(item => item != observer)
  }
  notifyObserver(data: string ,eventType: NotifyEventType): void {
    this.observers.forEach( observer => {
      observer.onEmit(data,eventType);
    })
  }
}

export default new ChatController()