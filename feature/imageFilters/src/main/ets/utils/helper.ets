import { GaussianRe, ImageDataRGBA, RGBA } from 'type';
import { image } from "@kit.ImageKit";


/**
 * 读取 PixelMap 到 RGBA buffer
 */
export async function loadImageToRGBA(filePath: string): Promise<ImageDataRGBA> {
  const imageSource = image.createImageSource(filePath);
  const pixelMap = await imageSource.createPixelMap();

  const info: image.ImageInfo = await pixelMap.getImageInfo();
  const width = info.size.width;
  const height = info.size.height;

  // 创建一个存储像素的 buffer（RGBA_8888）
  const buffer = new Uint8Array(width * height * 4);

  // ✅ 实际从 pixelMap 读取像素数据
  await pixelMap.readPixelsToBuffer(buffer.buffer);

  console.info(`PixelMap loaded: ${width}x${height}, pixelFormat=${info.pixelFormat}`);

  return { buffer, width, height, pixelMap };
}

/**
 * 第一个图像增强算法：亮度/对比度增强
 */
export function enhanceBrightnessContrast(
  buffer: RGBA,
  width: number,
  height: number,
  alpha: number,
  beta: number
): RGBA {
  const out = new Uint8Array(buffer.length);
  const n = width * height;

  for (let i = 0; i < n; i++) {
    const r = buffer[i * 4];
    const g = buffer[i * 4 + 1];
    const b = buffer[i * 4 + 2];
    const a = buffer[i * 4 + 3];

    // 🔸亮度对比度公式（常规写法）
    const nr = Math.min(255, Math.max(0, (r - 128) * alpha + 128 + beta));
    const ng = Math.min(255, Math.max(0, (g - 128) * alpha + 128 + beta));
    const nb = Math.min(255, Math.max(0, (b - 128) * alpha + 128 + beta));

    out[i * 4] = nr;
    out[i * 4 + 1] = ng;
    out[i * 4 + 2] = nb;
    out[i * 4 + 3] = a; // 保留透明度
  }

  return out;
}

/**
 * 创建新的空 PixelMap，用于写入增强结果
 */
export async function createEditablePixelMap(width: number, height: number): Promise<image.PixelMap> {
  const initOpts: image.InitializationOptions = {
    editable: true,
    pixelFormat: image.PixelMapFormat.RGBA_8888, // 输出 RGBA
    srcPixelFormat: image.PixelMapFormat.RGBA_8888,
    alphaType: image.AlphaType.PREMUL,
    size: { width, height },
  };

  // 空 buffer 初始化
  const emptyBuffer = new Uint8Array(width * height * 4);
  const newPixelMap = await image.createPixelMap(emptyBuffer.buffer, initOpts);
  return newPixelMap;
}

/**
 * 将增强后的 buffer 写回新 PixelMap
 */
export async function applyBufferToNewPixelMap(width: number, height: number, buffer: RGBA): Promise<image.PixelMap> {
  const newPixelMap = await createEditablePixelMap(width, height);

  try {
    await newPixelMap.writeBufferToPixels(buffer.buffer);
    console.info("Enhanced buffer successfully written to new PixelMap.");
  } catch (error) {
    console.error("Failed to write enhanced buffer:", error);
  }

  return newPixelMap;
}

/**
 * 完整流程示例
 */
export async function GetRGBAFromPixelMap(filePath: string): Promise<ImageDataRGBA> {
  const imgData: ImageDataRGBA = await loadImageToRGBA(filePath);
  const buffer: RGBA = imgData.buffer;
  const width: number = imgData.width;
  const height: number = imgData.height;
  const pixelMap: image.PixelMap = imgData.pixelMap

  return {buffer, width, height, pixelMap};
}
export async function runFirstEnhance(filePath: string, alpha: number, beta: number): Promise<image.PixelMap> {
  // 1️⃣ 读取 PixelMap 和 RGBA buffer
  const imgData: ImageDataRGBA = await loadImageToRGBA(filePath);
  const buffer: RGBA = imgData.buffer;
  const width: number = imgData.width;
  const height: number = imgData.height;

  // 2️⃣ 执行增强算法
  const enhancedBuffer: RGBA = enhanceBrightnessContrast(buffer, width, height, alpha, beta);

  // 3️⃣ 写入新 PixelMap（不在原图上修改）
  const newPixelMap = await applyBufferToNewPixelMap(width, height, enhancedBuffer);

  // 4️⃣ 返回增强后的 PixelMap
  return newPixelMap;
}

/**
 * 使用示例
 * runFirstEnhance('/data/storage/el2/base/haps/entry/files/test.jpg', 1.5, 40)
 *   .then(pm => { /* 显示 PixelMap */ /* })
 *   .catch(err => console.error(err));
 */
export function clampToU8(v: number): number {
  if (v < 0) return 0;
  if (v > 255) return 255;
  return Math.round(v);
}


export function rgbaToGrayUint8(buffer: RGBA, width: number, height: number): Uint8Array {
  const n = width * height;
  const gray = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    const r = buffer[i * 4];
    const g = buffer[i * 4 + 1];
    const b = buffer[i * 4 + 2];
    gray[i] = clampToU8(0.299 * r + 0.587 * g + 0.114 * b);
  }
  return gray;
}


export function makeGaussianKernel1D(sigma: number): GaussianRe {
  const radius = Math.ceil(sigma * 3);
  const len = radius * 2 + 1;
  const kernel: number[] = new Array(len);
  const sigma2 = sigma * sigma;
  let sum = 0;
  for (let i = -radius; i <= radius; i++) {
    const v = Math.exp(-(i * i) / (2 * sigma2));
    kernel[i + radius] = v;
    sum += v;
  }
  for (let i = 0; i < len; i++) kernel[i] /= sum;
  return { kernel, radius };
}