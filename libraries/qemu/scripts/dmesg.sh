#!/bin/bash

dmesg | grep -i -e dma -e iommu -e vfio
