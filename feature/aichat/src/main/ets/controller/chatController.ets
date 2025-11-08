import { AiMessage, ResData, UserMessage } from "type";
import { AIResponseUtils } from "utils";

export class ChatController{
  private fullContent:string = ''
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
      })
      this.fullContent += curContent;
    })
  }
  cancel(){

  }
}