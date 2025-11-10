import { IObserver} from 'type'

export class ChatObserver implements IObserver{
  public updateCallback: (data: string) => void;
  constructor(callback: (data: string) => void) {
    this.updateCallback = callback;
  }
  onEmit(data: string): void {
    this.updateCallback(data)
  }
}