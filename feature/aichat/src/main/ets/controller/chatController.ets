import { AiMessage, IObserver, ISubject, ResData, UserMessage } from "type";
import { AIResponseUtils } from "utils";

export class ChatController implements ISubject {
  private fullContent:string = ''
  private observers: IObserver[] = []

  request(reqContent: string){
    let requestBody: UserMessage = {
      content: reqContent,
      role: 'user'
    }
    AIResponseUtils.requestChat(requestBody,(chunks: ResData[]) => {
      let curContent: string = ''

      chunks.map((chunk: ResData) => {
        if(chunk.choices[0].finish_reason == "stop"){
          let aiMessage: AiMessage = {
            content:this.fullContent,
            role: "assistant"
          }
          AIResponseUtils.requestOver(aiMessage)
        }
        curContent += chunk.choices[0].delta.content;
        this.notifyObserver(chunk.choices[0].delta.content || '');
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
  notifyObserver(data: string): void {
    this.observers.forEach( observer => {
      observer.onEmit(data);
    })
  }
}