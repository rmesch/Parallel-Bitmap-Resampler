# Parallel Bitmap-Resampler for Delphi

 High-quality and fast rescaling of VCL- and FMX-bitmaps, including parallel resampling routines.
 Supports Delphi 10.4 and up. The VCL-version should work with Delphi XE7 and up, but the FMX-version will probably not work with 10.3 or lower. 10.3 definitely had some problems with FMX-TBitmap in threads.
 Find this modern version in the folder BitmapScaling.
 
 !!! The FMX-version currently supports Windows32Bit and Windows64Bit only !!!

Now also contains a legacy-version suitable for Delphi 2006 and up. It is in the folder BitmapScaling_Legacy. Unit names have been appended by Legacy, otherwise usage is the same as explained below. The demo requires Windows 2000 or higher to run.

*New*: Parallel unsharp-mask routine for VCL and FMX-versions. Can be used for sharpening or blurring pictures. Uses Gaussian blur with variable pixel-radius. Has an extra demo Sharpen.dproj in Demos\DemosVCL. For FMX you can see effects in the ThreadsInThreadsFMX demo. There is not yet an unsharp-mask for the legacy-version.

Usage:

  VCL: Add the units uScale.pas and uScaleCommon.pas from the Resampler-folder to your project. 
       The usage of the resampling-routines is explained in uScale.pas.
       For some of the types used, see uScaleCommon.pas.
       Try the demos in Demos\DemosVCL

  FMX: Add the units uScaleFMX.pas and uScaleCommon.pas from the Resampler-folder to your project. 
       The usage of the resampling-routines is explained in uScaleFMX.pas. 
       For some of the types used, see uScaleCommon.pas.
       Try the demos in Demos\DemosFMX

My conclusion on the version for FMX: It was fun to make the parallel resampling work for FMX, and I learned quite a bit about FMX (though I'm probably still using it too much in the VCL-way). *But* I would probably not use it myself in an FMX-application. Though the resampling quality is better, the difference is almost unnoticeable in most use cases, and the speed of the GPU can't be matched by anything using the CPU. And to make the resampler truly cross-platform would be a lot of work. So I'll probably leave the FMX-version in its present state. 
