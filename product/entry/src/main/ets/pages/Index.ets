import {testView} from 'aichat'

@Entry
@ComponentV2
struct Index {
  build() {
    Column(){
      testView()
    }
    .height('100%')
    .width('100%')
  }
}