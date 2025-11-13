import { image } from "@kit.ImageKit";

export interface GaussianRe {
  kernel: number[]
  radius: number
}

export type RGBA = Uint8Array;

export interface ImageDataRGBA {
  buffer: RGBA;
  width: number;
  height: number;
  pixelMap: image.PixelMap;
}

export interface ImageTaskRe {
  width: number;
  height: number;
  out: RGBA;
}