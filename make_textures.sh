#!/bin/bash
set -e

# Use Image Magick for converting SVG to DDS textures

convert () {
	in=$1
	out=$2
	shift 2
	magick \
		-background none \
		"svg/$in.svg" \
		-define dds:compression=dxt5 \
		$@ \
		"textures/DetectMarkerHUD/$out.dds"
}

convert	circle	marker
convert	paw	animal
convert	star	enchantment
convert	key	key
convert	arrow	up_arrow	-rotate   0
convert	arrow	right_arrow	-rotate  90
convert	arrow	down_arrow	-rotate 180
convert	arrow	left_arrow	-rotate 270
