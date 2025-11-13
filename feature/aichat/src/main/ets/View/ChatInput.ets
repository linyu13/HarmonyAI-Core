import { IObserver, NotifyEventType } from "type"
import chatControl from "../controller/chatController"
import chatAiModel from "../model/GetAIResponseModel"
import { InputObserver } from "./InputObserver"

@ComponentV2
export struct ChatInput {
  @Local request: string = ''
  @Local curState: boolean = false
  @Consumer('textControl') controller: TextInputController = new TextInputController()
  private update = (data: string, eventType: NotifyEventType) => {
    if(eventType == NotifyEventType.CONTROL_AI_UPDATE){
      this.curState = true;
    }else if(eventType == NotifyEventType.MODEL){
      this.curState = false;
    }
  }
  private inputObserver: IObserver = new InputObserver(this.update)
  aboutToAppear(): void {
    chatControl.registerObserver(this.inputObserver)
    chatAiModel.registerObserver(this.inputObserver)
  }
  build() {
    Row({ space: 5 }) {
      TextInput({ controller: this.controller, text: this.request })
        .onChange((res) => {
          this.request = res;
        })
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.Block)
      Button({ stateEffect: true, type: ButtonType.Circle }) {
        if(this.curState == false){
          Image($r('app.media.send')).width(25).height(25).fillColor(Color.White).margin({top:4})
        }else{
          Image($r('app.media.stop')).width(22).height(22).fillColor(Color.White)
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Black)
      .margin({right:4})
      .onClick(() => {
        chatControl.request(this.request)
        this.request = ''
        this.controller.stopEditing()
      })
    }
    .height(50)
  }
}