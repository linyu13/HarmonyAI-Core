import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { taskpool } from '@kit.ArkTS';
import { ImageDataRGBA, ImageTaskRe } from 'type';
import { applyBufferToNewPixelMap, GetRGBAFromPixelMap } from '../utils/helper';
import { colorBalance } from '../controller/imageFilters';

@ComponentV2
export struct ImageProcessSheet {
  @Local processing: boolean = false;

  async processImage() {
    try {
      // this.processing = true;
      const path = AppStorage.get<string>("sandBoxPath") as string
      const imgData: ImageDataRGBA = await GetRGBAFromPixelMap(path);

      const task = new taskpool.Task(colorBalance, imgData.width, imgData.height, imgData.buffer);
      const result = await taskpool.execute(task);
      const reImage = result as ImageTaskRe;

      const newPixel = await applyBufferToNewPixelMap(reImage.width, reImage.height, reImage.out);

      // await pixelMap2File(newPixel, this.sandboxPath);

      const context = this.getUIContext().getHostContext();
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);

      // this.processing = false;
      this.getUIContext().getPromptAction().showToast({ message: '图片增强完成！' });
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PROCESS', `处理失败：${err.message}`);
      this.processing = false;
    }
  }

  build() {
    Column() {
      if (!this.processing) {
        Button('开始增强图片')
          .width('100%')
          .onClick(() => this.processImage());
      } else {
        Text('处理中，请稍候...')
          .fontSize(16)
          .fontColor('#666');
      }
    }
    .width('100%')
    .height(300)
    .padding(16);
  }
}
