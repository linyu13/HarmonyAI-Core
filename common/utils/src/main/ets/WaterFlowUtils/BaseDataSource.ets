export abstract class BaseDataSource<T> implements IDataSource{
  protected listeners: DataChangeListener[] = []
  protected dataArr: T[] = [];

  abstract notifyDataReload(): void;

  public setDataArr(data: T[]){
    this.dataArr = data;
    this.notifyDataReload();
  }
  public totalCount(): number {
    return this.dataArr.length;
  }
  public getData(index: number): T {
    return this.dataArr[index];
  }
  public registerDataChangeListener(listener: DataChangeListener): void {
    if(this.listeners.indexOf(listener) < 0){
      this.listeners.push(listener);
    }
  }
  public unregisterDataChangeListener(listener: DataChangeListener): void {
    let index = this.listeners.indexOf(listener);
    if(index >= 0){
      this.listeners.splice(index,1);
    }
  }
}