# Parallel Bitmap-Resampler for Delphi

 High-quality and fast rescaling of VCL- and FMX-bitmaps, including parallel resampling routines.
 Supports Delphi 10.4 and up. The VCL-version should work in several previous versions, but the FMX-version will probably not work with 10.3 or lower. 10.3 definitely had some problems with FMX-TBitmap in threads.
 
 !!! The FMX-version currently supports Windows32Bit and Windows64Bit only !!!

Usage:

  VCL: Add the units uScale.pas and uScaleCommon.pas from the Resampler-folder to your project. 
       The usage of the resampling-routines is explained in uScale.pas.
       For some of the types used, see uScaleCommon.pas.
       Try the demos in Demos\DemosVCL

  FMX: Add the units uScaleFMX.pas and uScaleCommon.pas from the Resampler-folder to your project. 
       The usage of the resampling-routines is explained in uScaleFMX.pas. 
       For some of the types used, see uScaleCommon.pas.
       Try the demos in Demos\DemosFMX
