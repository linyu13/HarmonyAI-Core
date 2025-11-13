import { NotifyEventType } from "./NotifyEventType";

export interface IObserver{
  onEmit(data: string, eventType: NotifyEventType): void;
}

export interface ISubject{
  registerObserver(observer: IObserver): void;

  removeObserver(observer: IObserver):void;

  notifyObserver(data: string, eventType: NotifyEventType): void;
}
