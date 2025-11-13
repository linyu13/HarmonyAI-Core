import { IObserver, NotifyEventType } from "type";

export class InputObserver implements IObserver{
  public updateCallback: (data: string,eventType: NotifyEventType) => void;
  constructor(
    callback: (data:string,eventType: NotifyEventType) => void
  ) {
    this.updateCallback = callback;
  }

  onEmit(data: string, eventType: NotifyEventType): void {
    this.updateCallback(data,eventType)
  }
}