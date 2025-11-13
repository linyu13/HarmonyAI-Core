import { IMessage } from "type";
import { BaseDataSource } from "utils";

export class ChatDateSource extends BaseDataSource<IMessage>{

  pushData(item: IMessage){
    this.dataArr.push(item)
    this.notifyDataAdd(this.dataArr.length - 1);
  }
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }
  notifyDataAdd(index: number){
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }
  lastDataChange(){
    this.listeners.forEach(listener => {
      listener.onDataChange(this.dataArr.length - 1)
    })
  }
}