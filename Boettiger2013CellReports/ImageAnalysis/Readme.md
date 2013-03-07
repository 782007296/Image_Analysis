## Introduction
This folder contains the code used in my publication:

> Boettiger, A. N. & Levine, M. Rapid Transcription Fosters Coordinate snail Expression in the Drosophila Embryo. Cell reports 3, 8–15 (2013).

as it stood on the date of publication.  For version history, browse the version history of the parent directory Image_Analysis.

## Main Analysis Files
* imviewer\_LSM.fig  - GUI for extracting TIF Files from lsm image stacks
* Im\_nucseg.fig - GUI for extracting nuclear map and partitioning cytoplasm between nuclei.
* Unsupervised_DotFinding.m - script which proccesses the Tif stack indicated and counts all the mRNA spots detected

## Functions
* fxn\_nuc\_seg.m - subroutine of Im_nuc_seg.fig, identifies the nuclei in the image
* fxn\_nuc\_reg.m - subroutine of Image_nuc_seg.fig, performs cytoplasmic segmentation 
* dotfinder.m - subroutine of Unsupervised_DotFiding.m, localizes spots
* CheckDotUpDown.m - subroutine of Unsupervised_DtoFinding.m, links dots between Z-stacks
* jacquestiffread.m - subroutine of imviewer_LSM, parses Zeiss LSM headerfiles
* imreadfast.m - faster version of imread assumes image is a Tif file.  Used in several files
* makeuint.m - covert any data to uint of desired bit size and rescale pixel values to use max dynamic range.




*Note: This readme is written in markdown.  It should be text-readable as well, but will look better if you view it with a markdown compiler.  Github automatically compiles and renders markdown.  