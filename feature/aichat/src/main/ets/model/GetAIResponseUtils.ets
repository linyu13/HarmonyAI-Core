import { OpenAI } from '@iuroc/openai'
import { ChatCompletions, OnDataCallback } from '@iuroc/openai/src/main/ets/ChatCompletions'
import { ClientOptions } from '@iuroc/openai/src/main/ets/openai@4.73.1/index'
import { ChatCompletionChunk } from '@iuroc/openai/src/main/ets/openai@4.73.1/resources';
import { IMessage } from 'type';
import { rcp } from '@kit.RemoteCommunicationKit';


const baseOption: ClientOptions = {
  baseURL: 'https://api.zhizengzeng.com/v1/',
  apiKey:
    'sk-zk289e92ae5709e49834e71927d29be210668fa377c229e2'
  //'sk-zk23671daa73bc6f34fb47e781e45cac13368fa233d6dd81'
}

class GetAIResponseUtils {
  private openai: OpenAI;
  private chatManger: ChatCompletions;
  private messageArr: IMessage[] = []
  private chatSession?: rcp.Session

  constructor(option: ClientOptions) {
    this.openai = new OpenAI(option)
    this.chatManger = this.openai.chat.completions;
  }

  requestChat(message: IMessage, onData: OnDataCallback) {
    this.messageArr.push(message);
    this.chatSession = this.chatManger.create({
      model: 'gpt-3.5-turbo',
      stream: true,
      //max_tokens: 200,
      messages: this.messageArr
    }, {onData}).session
  }

  requestOver(message: IMessage){
    this.messageArr.push(message)
  }

  requestCancel(){
    if(this.chatSession){
      this.chatSession.cancel()
    }
  }
}
export default new GetAIResponseUtils(baseOption)