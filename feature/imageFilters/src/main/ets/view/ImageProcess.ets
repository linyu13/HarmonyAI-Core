import { image } from '@kit.ImageKit';
import { photoAccessHelper, PhotoPickerComponent, PickerController, ReminderMode } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { copyImg2Sandbox, pixelMap2File } from '../utils/Utils';
import { taskpool } from '@kit.ArkTS';
import { ImageDataRGBA, ImageTaskRe } from 'type';
import { applyBufferToNewPixelMap, GetRGBAFromPixelMap } from '../utils/helper';
import { colorBalance } from '../controller/imageFilters';

@ComponentV2
export struct ImageProcessSheet {
  @Trace store: ImageStore = ImageStore.connect();
  @Trace processing: boolean = false;

  async processImage() {
    try {
      this.processing = true;
      const imgData: ImageDataRGBA = await GetRGBAFromPixelMap(this.store.sandboxPath);

      const task = new taskpool.Task(colorBalance, imgData.width, imgData.height, imgData.buffer);
      const result = await taskpool.execute(task);
      const reImage = result as ImageTaskRe;

      const newPixel = await applyBufferToNewPixelMap(reImage.width, reImage.height, reImage.out);
      this.store.setProcessedImage(newPixel);

      await pixelMap2File(newPixel, this.store.sandboxPath);

      const context = this.getUIContext().getHostContext();
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const assetChangeRequest = photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(context, this.store.sandboxPath);
      await phAccessHelper.applyChanges(assetChangeRequest);

      this.processing = false;
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
