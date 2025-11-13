
@Component
export struct testView {
  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 使用Gauge组件并裁剪为半圆
      Gauge({ value: 50, min: 0, max: 100 })
        .width(200)
        .height(100)
        .clip(true)  // 裁剪底部半圆
        .colors([[Color.Blue, 1]])
        .startAngle(270) // 起始角度为270度（正下方）
        .endAngle(90)    // 结束角度为90度（正上方）
    }
    .height(100)  // 裁剪为半圆高度
  }
}