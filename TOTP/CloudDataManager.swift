//
//  ICloudKit.swift
//  TOTP
//
//  Created by Taras Markevych on 4/19/17.
//  Copyright © 2017 Taras Markevych. All rights reserved.
//

import UIKit
import CloudKit

class CloudDataManager {
    
    static let sharedInstance = CloudDataManager() 
    
    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
        
        static let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")

        static func tmpDocumentsURL() -> URL {
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            if !FileManager.default.fileExists(atPath: tmpDir.absoluteString) {
                do {
                    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("failed to create tmp dir", error)
                }
            }
            return tmpDir
        }
    }
    
    
    // Return the Document directory (Cloud OR Local)
    // To do in a background thread
    
    func getDocumentDiretoryURL() -> URL {
        if isCloudEnabled()  {
            return DocumentsDirectory.iCloudDocumentsURL!
        } else {
            return DocumentsDirectory.localDocumentsURL
        }
    }
    
    // Return true if iCloud is enabled
    
    func isCloudEnabled() -> Bool {
        if DocumentsDirectory.iCloudDocumentsURL != nil {
            return true
        } else {
            Alert.showAlert(title: "Error", message: "Please authorize to iCloud for using data backup")
            return false
        }
    }
    
    // Delete All files at UR
    
    func clearFolder() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let diskCacheStorageBaseUrl = myDocuments
        guard let filePaths = try? fileManager.contentsOfDirectory(at: diskCacheStorageBaseUrl, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
    }
    func deleteFilesInDirectory(url: URL?) {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: url!.path)
        while let file = enumerator?.nextObject() as? String {

            do {
                try fileManager.removeItem(at: url!.appendingPathComponent(file))
                print("Files deleted", file)
            } catch let error as NSError {
                print("Failed deleting files : \(error)")
            }
        }
    }

    // Copy local files to iCloud
    // iCloud will be cleared before any operation
    // No data merging
    
    func copyFileToCloud() {
        if isCloudEnabled() {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(atPath: DocumentsDirectory.localDocumentsURL.path)
            while let file = enumerator?.nextObject() as? String {
                do {
                    let sourceFile = DocumentsDirectory.localDocumentsURL.appendingPathComponent(file)
                    let tmpFile = DocumentsDirectory.tmpDocumentsURL().appendingPathComponent(String(file.split(separator: "/").last!))
                    let destFile = DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file)
                    var isDir:ObjCBool = false
                    if fileManager.fileExists(atPath: tmpFile.absoluteString, isDirectory: &isDir) {
                        try fileManager.removeItem(at: tmpFile)
                    }
                    //try fileManager.copyItem(at: sourceFile, to: tmpFile)
                    //try fileManager.replaceItemAt(destFile, withItemAt: tmpFile)
                    isDir = false
                    if fileManager.fileExists(atPath: sourceFile.absoluteString, isDirectory: &isDir) {
                        if isDir.boolValue {
                            try fileManager.createDirectory(at: destFile, withIntermediateDirectories: true, attributes: nil)
                        } else {
                            if !fileManager.fileExists(atPath: destFile.absoluteString, isDirectory: &isDir) {
                                try fileManager.copyItem(at: sourceFile, to: destFile)
                            } else {
                                try fileManager.copyItem(at: sourceFile, to: tmpFile)
                                let _ = try fileManager.replaceItemAt(destFile, withItemAt: tmpFile)
                            }
                        }
                    }
                    try fileManager.copyItem(at: sourceFile, to: destFile)
                } catch let error as NSError {
                    print("Failed to move file to Cloud : \(error)")
                }
            }
        }
    }
    
    // Copy iCloud files to local directory
    // Local dir will be cleared
    // No data merging
    
    func copyFileToLocal() {
        if isCloudEnabled() {
            clearFolder()
            let fileManager = FileManager.default
        
            let enumerator = fileManager.enumerator(atPath: DocumentsDirectory.iCloudDocumentsURL!.path)
            while let file = enumerator?.nextObject() as? String {
                
                do {
                    let sourceFile = DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file)
                    print(file, sourceFile)
                    let tmpFile = DocumentsDirectory.tmpDocumentsURL().appendingPathComponent(String(file.split(separator: "/").last!))
                    let destFile = DocumentsDirectory.localDocumentsURL.appendingPathComponent(file)
                    //var isDir:ObjCBool = false
                    //if fileManager.fileExists(atPath: tmpFile.absoluteString, isDirectory: &isDir) {
                    //    try fileManager.removeItem(at: tmpFile)
                    //}
                    try fileManager.copyItem(at: sourceFile, to: tmpFile)
                    let _ = try fileManager.replaceItemAt(destFile, withItemAt: tmpFile)
                    print("Moved to local dir", file)
                } catch let error as NSError {
                    print("Failed to move file to local dir : \(error)")
                }
            }
            Alert.showAlert(title: "Synchronized", message: "Data restored from backup. Please re-open application")
        }
    }
    
    
    
}
