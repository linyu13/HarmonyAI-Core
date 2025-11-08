
export interface IObserver{
  onEmit(data: string): void;
}

export interface ISubject{
  registerObserver(observer: IObserver): void;

  removeObserver(observer: IObserver):void;

  notifyObserver(data: string): void;
}
