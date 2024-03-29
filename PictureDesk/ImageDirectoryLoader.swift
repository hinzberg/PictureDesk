/*
* ImageDirectoryLoader.swift
* SlidesMagic
*
* Created by Gabriel Miro on Oct 2016.
* Copyright (c) 2016 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Cocoa

class ImageDirectoryLoader: NSObject {
  
  fileprivate var imageFiles = [ImageFile]()
  fileprivate(set) var numberOfSections = 1
  var singleSectionMode = true
  
  fileprivate struct SectionAttributes {
    var sectionOffset: Int  // the index of the first image of this section in the imageFiles array
    var sectionLength: Int  // number of images in the section
  }
  
  // sectionLengthArray - An array of randomly picked integers just for demo purposes. 
  // sectionLengthArray[0] is 7, i.e. put the first 7 images from the imageFiles array into section 0
  // sectionLengthArray[1] is 5, i.e. put the next 5 images from the imageFiles array into section 1
  // and so on...
  fileprivate var sectionLengthArray = [7, 5, 10, 2, 11, 7, 10, 12, 20, 25, 10, 3, 30, 25, 40]
  fileprivate var sectionsAttributesArray = [SectionAttributes]()
  
  func setupDataForUrls(_ urls: [URL]?) {
    
    if let urls = urls {                    // When new folder
      createImageFilesForUrls(urls)
    }
    
    if sectionsAttributesArray.count > 0
    {  // If not first time, clean old sectionsAttributesArray
      sectionsAttributesArray.removeAll()
    }
    
    numberOfSections = 1
    
    if singleSectionMode {
      setupDataForSingleSectionMode()
    } else {
      setupDataForMultiSectionMode()
    }
    
  }
  
  fileprivate func setupDataForSingleSectionMode() {
    let sectionAttributes = SectionAttributes(sectionOffset: 0, sectionLength: imageFiles.count)
    sectionsAttributesArray.append(sectionAttributes) // sets up attributes for first section
  }
  
  fileprivate func setupDataForMultiSectionMode() {
    
    let haveOneSection = singleSectionMode || sectionLengthArray.count < 2 || imageFiles.count <= sectionLengthArray[0]
    var realSectionLength = haveOneSection ? imageFiles.count : sectionLengthArray[0]
    var sectionAttributes = SectionAttributes(sectionOffset: 0, sectionLength: realSectionLength)
    sectionsAttributesArray.append(sectionAttributes) // sets up attributes for first section
    
    guard !haveOneSection else {return}
    
    var offset: Int
    var nextOffset: Int
    let maxNumberOfSections = sectionLengthArray.count
    for i in 1..<maxNumberOfSections {
      numberOfSections += 1
      offset = sectionsAttributesArray[i-1].sectionOffset + sectionsAttributesArray[i-1].sectionLength
      nextOffset = offset + sectionLengthArray[i]
      if imageFiles.count <= nextOffset {
        realSectionLength = imageFiles.count - offset
        nextOffset = -1 // signal this is last section for this collection
      } else {
        realSectionLength = sectionLengthArray[i]
      }
      sectionAttributes = SectionAttributes(sectionOffset: offset, sectionLength: realSectionLength)
      sectionsAttributesArray.append(sectionAttributes)
      if nextOffset < 0 {
        break
      }
    }
  }
  
  fileprivate func createImageFilesForUrls(_ urls: [URL]) {
    if imageFiles.count > 0 {   // When not initial folder
      imageFiles.removeAll()
    }
    for url in urls {
      if let imageFile = ImageFile(url: url) {
        imageFiles.append(imageFile)
      }
    }
  }
  
  fileprivate func getFilesURLFromFolder(_ folderURL: URL) -> [URL]? {
    
    let options: FileManager.DirectoryEnumerationOptions =
    [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
    let fileManager = FileManager.default
    let resourceValueKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey]
    
    guard let directoryEnumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: resourceValueKeys,
      options: options, errorHandler: { url, error in
        print("`directoryEnumerator` error: \(error).")
        return true
    }) else { return nil }
    
    var urls: [URL] = []
    for case let url as URL in directoryEnumerator {
      do {
        let resourceValues = try (url as NSURL).resourceValues(forKeys: resourceValueKeys)
        guard let isRegularFileResourceValue = resourceValues[URLResourceKey.isRegularFileKey] as? NSNumber else { continue }
        guard isRegularFileResourceValue.boolValue else { continue }
        guard let fileType = resourceValues[URLResourceKey.typeIdentifierKey] as? String else { continue }
        guard UTTypeConformsTo(fileType as CFString, "public.image" as CFString) else { continue }
        urls.append(url)
      }
      catch {
        print("Unexpected error occured: \(error).")
      }
    }
    return urls
  }
  
  func numberOfItemsInSection(_ section: Int) -> Int
  {
    return sectionsAttributesArray[section].sectionLength
  }
  
  func imageFileForIndexPath(_ indexPath: IndexPath) -> ImageFile
  {
    let imageIndexInImageFiles = sectionsAttributesArray[indexPath.section].sectionOffset + indexPath.item
    let imageFile = imageFiles[imageIndexInImageFiles]
    return imageFile
  }
  
  func loadDataForFolderWithUrl(_ folderURL: URL)
  {
    let urls = getFilesURLFromFolder(folderURL)
    if let urls = urls {
      print("\(urls.count) images found in directory \(folderURL.lastPathComponent)")
      for url in urls {
        print("\(url.lastPathComponent)")
      }
    }
    setupDataForUrls(urls)
  }
    
    func removeImagesByUrls(urls:[URL]?)
    {
        for url in urls!
        {
            var index = 0;
            for image in self.imageFiles
            {
                if image.fileURL == url
                {
                    self.imageFiles.remove(at: index)
                    // Ich habe nur eine Section
                    sectionsAttributesArray[0].sectionLength -= 1
                    break
                }
                index += 1
            }
        }
    }
    
    func removeImageAtIndexPath(indexPath: NSIndexPath) -> ImageFile
    {
        let imageIndexInImageFiles = sectionsAttributesArray[indexPath.section].sectionOffset + indexPath.item
        let imageFileRemoved = imageFiles.remove(at: imageIndexInImageFiles)
        let sectionToUpdate = indexPath.section
        sectionsAttributesArray[sectionToUpdate].sectionLength -= 1
        if sectionToUpdate < numberOfSections-1 {
            for i in sectionToUpdate+1...numberOfSections-1 {
                sectionsAttributesArray[i].sectionOffset -= 1
            }
        }
        return imageFileRemoved
    }
    
    func insertImage(image: ImageFile, atIndexPath: NSIndexPath)
    {
        let imageIndexInImageFiles = sectionsAttributesArray[atIndexPath.section].sectionOffset + atIndexPath.item
        imageFiles.insert(image, at: imageIndexInImageFiles)
        let sectionToUpdate = atIndexPath.section
        sectionsAttributesArray[sectionToUpdate].sectionLength += 1
        sectionLengthArray[sectionToUpdate] += 1
        if sectionToUpdate < numberOfSections-1 {
            for i in sectionToUpdate+1...numberOfSections-1 {
                sectionsAttributesArray[i].sectionOffset += 1
            }
        }
    }
    
    func moveImageFromIndexPath(indexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        let itemBeingDragged = removeImageAtIndexPath(indexPath: indexPath)
        
        let destinationIsLower = indexPath.compare(toIndexPath as IndexPath) == .orderedDescending
        var indexPathOfDestination: NSIndexPath
        if destinationIsLower
        {
            indexPathOfDestination = toIndexPath
        }
        else
        {
            indexPathOfDestination = NSIndexPath(forItem: toIndexPath.item-1, inSection: toIndexPath.section)
        }
 
        insertImage(image: itemBeingDragged, atIndexPath: indexPathOfDestination)
    }
    
  
}
